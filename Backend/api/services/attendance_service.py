import math
from datetime import date
from django.utils import timezone
from rest_framework.exceptions import ValidationError, PermissionDenied

from ..models import Attendance, FaceRegistration
from .face_service import FaceService


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
            raise ValidationError("Face not registered. Please register your face first.")

        # 5. Extract and verify face
        file_name, temp_path = FaceService.save_temp_file(image_file, "checkin")
        try:
            new_embedding = FaceService.extract_embedding(temp_path)
            if new_embedding is None:
                raise ValidationError("No face detected in image. Please take a clear photo.")

            dist, conf, is_match = FaceService.compare_embeddings(face_reg.embedding, new_embedding)
            if not is_match:
                raise PermissionDenied(
                    f"Face does not match. Confidence: {conf}%. "
                    f"Only {employee.fullname}'s face can check in for this account."
                )

            # 6. Validate geofence
            is_in_range, dist_meters = cls.validate_location(latitude, longitude, branch)
            if not is_in_range:
                raise PermissionDenied(
                    f"You are {dist_meters}m away from {branch.name}. "
                    f"Maximum allowed distance is {branch.radius:.0f}m."
                )

            # 7. Check for duplicate active check-in today
            today = date.today()
            existing = Attendance.objects.filter(
                employee=employee,
                date=today,
                status='checked_in'
            ).first()

            if existing:
                raise ValidationError("You already have an active check-in today. Please check out first.")

            # 8. Create attendance record
            record = Attendance.objects.create(
                employee=employee,
                branch=branch,
                check_in_latitude=latitude,
                check_in_longitude=longitude,
                status='checked_in',
            )

            return {
                "success": True,
                "message": "Checked in successfully!",
                "confidence": conf,
                "distance_meters": dist_meters,
                "check_in_time": timezone.localtime(record.check_in_time).isoformat(),
                "record_id": record.id,
            }
        finally:
            FaceService.cleanup_file(file_name)

    @classmethod
    def process_check_out(cls, employee, image_file, latitude: float, longitude: float):
        """
        Coordinates check-out flow:
        Role validation -> Active check-in lookup -> Face verification -> Geofence check -> Update.
        """
        if employee.role == 'ceo':
            raise PermissionDenied("CEO is not required to check out.")

        if employee.status != 'active':
            raise PermissionDenied("Only active employees can check out.")

        if not employee.branch:
            raise ValidationError("You are not assigned to any branch.")

        branch = employee.branch

        # Find active check-in for today
        today = date.today()
        record = Attendance.objects.filter(
            employee=employee,
            date=today,
            status='checked_in'
        ).first()

        if not record:
            raise ValidationError("No active check-in found for today. Please check in first.")

        # Face registration
        try:
            face_reg = employee.face_registration
        except FaceRegistration.DoesNotExist:
            raise ValidationError("Face not registered.")

        # Extract and verify face
        file_name, temp_path = FaceService.save_temp_file(image_file, "checkout")
        try:
            new_embedding = FaceService.extract_embedding(temp_path)
            if new_embedding is None:
                raise ValidationError("No face detected in image. Please take a clear photo.")

            dist, conf, is_match = FaceService.compare_embeddings(face_reg.embedding, new_embedding)
            if not is_match:
                raise PermissionDenied(
                    f"Face does not match. Confidence: {conf}%. "
                    f"Only {employee.fullname}'s face can check out for this account."
                )

            # Geofence check
            is_in_range, dist_meters = cls.validate_location(latitude, longitude, branch)
            if not is_in_range:
                raise PermissionDenied(
                    f"You are {dist_meters}m away from {branch.name}. "
                    f"Maximum allowed distance is {branch.radius:.0f}m."
                )

            # Update attendance record
            record.check_out_time = timezone.now()
            record.check_out_latitude = latitude
            record.check_out_longitude = longitude
            record.status = 'checked_out'
            record.save()

            return {
                "success": True,
                "message": "Checked out successfully!",
                "confidence": conf,
                "distance_meters": dist_meters,
                "check_out_time": timezone.localtime(record.check_out_time).isoformat(),
                "record_id": record.id,
            }
        finally:
            FaceService.cleanup_file(file_name)
