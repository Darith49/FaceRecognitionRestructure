import math
from django.utils import timezone
from rest_framework.exceptions import ValidationError, PermissionDenied

from .models import Attendance
from api.face.models import FaceRegistration
from api.face.services import FaceService


class AttendanceService:
    @staticmethod
    def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """
        Calculates the great-circle distance in metres between two GPS points
        using the Haversine formula.
        """
        R = 6371000.0  # Earth radius in metres
        phi1 = math.radians(lat1)
        phi2 = math.radians(lat2)
        d_phi = math.radians(lat2 - lat1)
        d_lambda = math.radians(lon2 - lon1)

        a = (
            math.sin(d_phi / 2.0) ** 2 +
            math.cos(phi1) * math.cos(phi2) * math.sin(d_lambda / 2.0) ** 2
        )
        c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
        return R * c

    @classmethod
    def validate_location(cls, latitude: float, longitude: float, branch):
        """
        Validates whether GPS (latitude, longitude) is within branch radius.
        Returns (is_valid, distance_meters).
        """
        distance = cls.calculate_distance(
            latitude, longitude, branch.latitude, branch.longitude
        )
        return distance <= branch.radius, round(distance, 1)

    @classmethod
    def process_check_in(cls, employee, image_file, latitude: float, longitude: float):
        """
        Coordinates full check-in flow:
        Role validation -> Face verification -> Geofence check -> Duplicate check -> Save.
        """
        # 1. CEO does not check in
        if employee.role == 'ceo':
            raise PermissionDenied("CEO is not required to check in.")

        # 2. Check active employee
        if employee.status != 'active':
            raise PermissionDenied("Only active employees can check in. Current status: " + employee.status)

        # 3. Check branch assignment
        if not employee.branch:
            raise ValidationError("You are not assigned to any branch. Please contact your manager/CEO.")

        branch = employee.branch

        # 4. Check face registration
        try:
            face_reg = employee.face_registration
        except FaceRegistration.DoesNotExist:
            raise ValidationError("No registered face found. Please complete face registration first.")

        # 5. Extract and verify face embedding
        file_name, full_path = FaceService.save_temp_file(image_file, "checkin")
        try:
            query_embedding = FaceService.extract_embedding(full_path)
            if query_embedding is None:
                raise ValidationError("No face detected in the photo. Please capture a clear, well-lit photo.")

            distance, confidence, is_match = FaceService.compare_embeddings(
                query_embedding, face_reg.embedding
            )

            if not is_match:
                raise ValidationError(
                    f"Face verification failed. Confidence: {confidence}%. Please try again in better lighting."
                )
        finally:
            FaceService.cleanup_file(file_name)

        # 6. Validate geofencing
        in_range, distance_m = cls.validate_location(latitude, longitude, branch)
        if not in_range:
            raise ValidationError(
                f"You are {distance_m:.1f}m away from '{branch.name}'. "
                f"You must be within {branch.radius:.0f}m to check in."
            )

        # 7. Check existing active check-in today
        today = timezone.localdate()
        existing = Attendance.objects.filter(
            employee=employee,
            date=today,
            status='checked_in',
        ).first()

        if existing:
            raise ValidationError("You are already checked in. Please check out first.")

        # 8. Create attendance record
        attendance = Attendance.objects.create(
            employee=employee,
            branch=branch,
            check_in_latitude=latitude,
            check_in_longitude=longitude,
            status='checked_in',
            date=today,
        )

        return {
            "success": True,
            "message": f"Welcome, {employee.fullname}! Check-in recorded at {branch.name}.",
            "attendance_id": attendance.id,
            "check_in_time": attendance.check_in_time.isoformat(),
            "branch": branch.name,
            "distance_meters": distance_m,
            "confidence": confidence,
        }

    @classmethod
    def process_check_out(cls, employee, image_file, latitude: float, longitude: float):
        """Coordinates full check-out flow."""
        if employee.role == 'ceo':
            raise PermissionDenied("CEO is not required to check out.")

        if employee.status != 'active':
            raise PermissionDenied("Only active employees can check out.")

        if not employee.branch:
            raise ValidationError("You are not assigned to any branch.")

        branch = employee.branch

        # Find today's open check-in
        today = timezone.localdate()
        attendance = Attendance.objects.filter(
            employee=employee,
            date=today,
            status='checked_in',
        ).order_by('-check_in_time').first()

        if not attendance:
            raise ValidationError("No active check-in found for today. Please check in first.")

        # Verify face
        try:
            face_reg = employee.face_registration
        except FaceRegistration.DoesNotExist:
            raise ValidationError("No registered face found.")

        file_name, full_path = FaceService.save_temp_file(image_file, "checkout")
        try:
            query_embedding = FaceService.extract_embedding(full_path)
            if query_embedding is None:
                raise ValidationError("No face detected in the photo.")

            distance, confidence, is_match = FaceService.compare_embeddings(
                query_embedding, face_reg.embedding
            )

            if not is_match:
                raise ValidationError(f"Face verification failed ({confidence}% match).")
        finally:
            FaceService.cleanup_file(file_name)

        # Validate geofence
        in_range, distance_m = cls.validate_location(latitude, longitude, branch)
        if not in_range:
            raise ValidationError(
                f"You are {distance_m:.1f}m away from '{branch.name}'. "
                f"You must be within {branch.radius:.0f}m to check out."
            )

        now = timezone.now()
        attendance.check_out_time = now
        attendance.check_out_latitude = latitude
        attendance.check_out_longitude = longitude
        attendance.status = 'checked_out'
        attendance.save()

        duration = attendance.check_out_time - attendance.check_in_time
        hours = duration.total_seconds() / 3600.0

        return {
            "success": True,
            "message": f"Goodbye, {employee.fullname}! Check-out recorded at {branch.name}.",
            "attendance_id": attendance.id,
            "check_in_time": attendance.check_in_time.isoformat(),
            "check_out_time": attendance.check_out_time.isoformat(),
            "hours_worked": round(hours, 2),
            "branch": branch.name,
            "distance_meters": distance_m,
            "confidence": confidence,
        }
