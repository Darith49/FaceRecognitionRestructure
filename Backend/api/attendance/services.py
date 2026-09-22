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
    def process_check_in(cls, employee, image_file, latitude: float, longitude: float, session=None):
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

        # 4. Check scheduled workday
        today = timezone.localdate()
        weekday_names = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']
        today_code = weekday_names[today.weekday()]
        allowed_days = [d.strip().lower() for d in (employee.work_days or 'mon,tue,wed,thu,fri').split(',') if d.strip()]
        if today_code not in allowed_days:
            raise ValidationError("Today is your scheduled day off. Check-in is not permitted.")

        # 5. Check scheduled section time window & resolve session number
        def _to_time(val):
            import datetime
            if val is None:
                return None
            if isinstance(val, datetime.time):
                return val
            if isinstance(val, str):
                try:
                    return datetime.time.fromisoformat(val)
                except ValueError:
                    parts = [int(p) for p in val.split(':')]
                    return datetime.time(*parts)
            return None

        now_time = timezone.localtime().time()
        s1_start = _to_time(employee.section1_start) or datetime.time(7, 0)
        s1_end = _to_time(employee.section1_end) or datetime.time(11, 0)
        s2_start = _to_time(employee.section2_start) or datetime.time(13, 0)
        s2_end = _to_time(employee.section2_end) or datetime.time(17, 0)

        # Check existing records for today
        s1_record = Attendance.objects.filter(
            employee=employee,
            date=today,
            session=1,
        ).order_by('-check_in_time').first()

        s2_record = Attendance.objects.filter(
            employee=employee,
            date=today,
            session=2,
        ).order_by('-check_in_time').first()

        # Parse requested session if provided
        requested_session = None
        if session is not None:
            try:
                requested_session = int(session)
            except (ValueError, TypeError):
                requested_session = None

        # Determine target session number:
        if requested_session in (1, 2):
            session_number = requested_session
        elif s1_record and s1_record.status == 'checked_out':
            # Section 1 is completed -> automatically progress to Section 2
            session_number = 2
        elif s1_start <= now_time <= s1_end:
            session_number = 1
        elif s2_start <= now_time <= s2_end:
            session_number = 2
        elif s1_record is not None and not s2_record:
            session_number = 2
        else:
            session_number = 1

        # Validate time window for the resolved session
        s1_str = f"{s1_start.strftime('%I:%M %p')} - {s1_end.strftime('%I:%M %p')}"
        s2_str = f"{s2_start.strftime('%I:%M %p')} - {s2_end.strftime('%I:%M %p')}"
        now_str = now_time.strftime('%I:%M %p')

        if session_number == 1:
            if not (s1_start <= now_time <= s1_end):
                raise ValidationError(
                    f"Check-in is only permitted during scheduled work sections:\n"
                    f"• Section 1: {s1_str}\n"
                    f"• Section 2: {s2_str}\n"
                    f"Current time is {now_str}."
                )
        elif session_number == 2:
            # For section 2: allow check-in if within Section 2 window,
            # or if Section 1 is already checked out and we haven't passed Section 2 end time
            is_s1_done = s1_record is not None and s1_record.status == 'checked_out'
            in_s2_window = s2_start <= now_time <= s2_end
            after_s1_checkout = is_s1_done and now_time <= s2_end

            if not (in_s2_window or after_s1_checkout):
                raise ValidationError(
                    f"Check-in is only permitted during scheduled work sections:\n"
                    f"• Section 1: {s1_str}\n"
                    f"• Section 2: {s2_str}\n"
                    f"Current time is {now_str}."
                )

        # 6. Check face registration
        try:
            face_reg = employee.face_registration
        except FaceRegistration.DoesNotExist:
            raise ValidationError("No registered face found. Please complete face registration first.")

        # 7. Extract and verify face embedding
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

        # 8. Validate geofencing
        in_range, distance_m = cls.validate_location(latitude, longitude, branch)
        if not in_range:
            raise ValidationError(
                f"You are {distance_m:.1f}m away from '{branch.name}'. "
                f"You must be within {branch.radius:.0f}m to check in."
            )

        # 9. Check existing active check-in today
        existing_active = Attendance.objects.filter(
            employee=employee,
            date=today,
            status='checked_in',
        ).first()

        if existing_active:
            raise ValidationError("You are already checked in. Please check out first.")

        # 10. Check if already checked in for this section today
        existing_session = Attendance.objects.filter(
            employee=employee,
            date=today,
            session=session_number,
        ).first()

        if existing_session:
            raise ValidationError(f"You have already checked in for Section {session_number} today.")

        # 11. Create attendance record
        attendance = Attendance.objects.create(
            employee=employee,
            branch=branch,
            check_in_latitude=latitude,
            check_in_longitude=longitude,
            status='checked_in',
            session=session_number,
            date=today,
        )

        return {
            "success": True,
            "message": f"Welcome, {employee.fullname}! Section {session_number} check-in recorded at {branch.name}.",
            "attendance_id": attendance.id,
            "session": session_number,
            "check_in_time": attendance.check_in_time.isoformat(),
            "branch": branch.name,
            "distance_meters": distance_m,
            "confidence": confidence,
        }

    @classmethod
    def process_check_out(cls, employee, image_file, latitude: float, longitude: float, session=None):
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
        open_records = Attendance.objects.filter(
            employee=employee,
            date=today,
            status='checked_in',
        )

        attendance = None
        if session is not None:
            try:
                requested_session = int(session)
                attendance = open_records.filter(session=requested_session).order_by('-check_in_time').first()
            except (ValueError, TypeError):
                attendance = None

        if not attendance:
            attendance = open_records.order_by('-check_in_time').first()

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
            "session": attendance.session,
            "check_in_time": attendance.check_in_time.isoformat(),
            "check_out_time": attendance.check_out_time.isoformat(),
            "hours_worked": round(hours, 2),
            "branch": branch.name,
            "distance_meters": distance_m,
            "confidence": confidence,
        }
