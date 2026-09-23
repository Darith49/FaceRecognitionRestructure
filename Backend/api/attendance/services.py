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

    @classmethod
    def get_monthly_summary(cls, employee, year=None, month=None):
        """
        Calculates comprehensive monthly schedule and performance metrics:
        - days_goal: total scheduled work days in the month
        - days_worked: days with completed attendance check-ins/outs
        - days_absent: work days past or ended without check-in/out or approved leave
        - on_time_rate: percentage of on-time check-ins
        - days_remaining: remaining days to meet goal
        - calendar_days: day-by-day status map (workday, dayOff, worked, absent, leave, overtime)
        - work_schedule: configured shifts and work/holiday breakdown
        """
        import calendar
        import datetime
        from api.request.models import LeaveRequest, PermissionRequest, RequestStatus

        today = timezone.localdate()
        now_time = timezone.localtime().time()

        target_year = int(year) if year else today.year
        target_month = int(month) if month else today.month

        _, num_days = calendar.monthrange(target_year, target_month)
        month_name = calendar.month_name[target_month]

        def _to_time(val):
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

        s1_start = _to_time(getattr(employee, 'section1_start', None)) or datetime.time(7, 0)
        s1_end = _to_time(getattr(employee, 'section1_end', None)) or datetime.time(11, 0)
        s2_start = _to_time(getattr(employee, 'section2_start', None)) or datetime.time(13, 0)
        s2_end = _to_time(getattr(employee, 'section2_end', None)) or datetime.time(17, 0)

        # Workdays allowed
        weekday_map = {0: 'mon', 1: 'tue', 2: 'wed', 3: 'thu', 4: 'fri', 5: 'sat', 6: 'sun'}
        weekday_full_map = {
            'mon': ('Mon', 'Monday'),
            'tue': ('Tue', 'Tuesday'),
            'wed': ('Wed', 'Wednesday'),
            'thu': ('Thu', 'Thursday'),
            'fri': ('Fri', 'Friday'),
            'sat': ('Sat', 'Saturday'),
            'sun': ('Sun', 'Sunday'),
        }
        allowed_days = [
            d.strip().lower()
            for d in (getattr(employee, 'work_days', '') or 'mon,tue,wed,thu,fri').split(',')
            if d.strip()
        ]

        # Fetch month's attendance records
        start_date = datetime.date(target_year, target_month, 1)
        end_date = datetime.date(target_year, target_month, num_days)

        attendances = Attendance.objects.filter(
            employee=employee,
            date__range=[start_date, end_date],
        ).order_by('check_in_time')

        # Index attendances by date string YYYY-MM-DD
        att_by_date = {}
        for att in attendances:
            d_str = att.date.isoformat()
            att_by_date.setdefault(d_str, []).append(att)

        # Fetch approved leaves and permissions
        approved_leaves = LeaveRequest.objects.filter(
            employee=employee,
            status=RequestStatus.APPROVED,
            from_date__lte=end_date,
            to_date__gte=start_date,
        )

        approved_perms = PermissionRequest.objects.filter(
            employee=employee,
            status=RequestStatus.APPROVED,
            date__range=[start_date, end_date],
        )

        # Map approved leaves by date and session (0=full day, 1=section 1, 2=section 2)
        leave_by_date = {}
        leave_records = []
        for l in approved_leaves:
            sess = getattr(l, 'session', 0)
            leave_records.append({
                "id": l.id,
                "session": sess,
                "leave_mode": getattr(l, 'leave_mode', 'full_section'),
                "leave_type": l.leave_type,
                "day_type": l.day_type,
                "from_date": l.from_date.isoformat(),
                "to_date": l.to_date.isoformat(),
                "reason": l.reason,
                "status": l.status,
            })
            cur = max(start_date, l.from_date)
            finish = min(end_date, l.to_date)
            while cur <= finish:
                leave_by_date.setdefault(cur.isoformat(), set()).add(sess)
                cur += datetime.timedelta(days=1)

        perm_by_date = {}
        for p in approved_perms:
            d_str = p.date.isoformat()
            if p.permission_type == 'stop_section_1':
                perm_by_date.setdefault(d_str, set()).add(1)
            elif p.permission_type == 'stop_section_2':
                perm_by_date.setdefault(d_str, set()).add(2)
            else:
                perm_by_date.setdefault(d_str, set()).add(0)

        days_goal = 0
        days_worked = 0
        days_absent = 0
        days_leave = 0
        total_checkins = 0
        on_time_checkins = 0

        calendar_days = {}

        for day_num in range(1, num_days + 1):
            day_date = datetime.date(target_year, target_month, day_num)
            date_str = day_date.isoformat()
            day_code = weekday_map[day_date.weekday()]
            is_workday = day_code in allowed_days

            records_today = att_by_date.get(date_str, [])
            rec1 = next((r for r in records_today if r.session == 1), None)
            rec2 = next((r for r in records_today if r.session == 2), None)
            if not rec1 and not rec2 and records_today:
                rec1 = records_today[0]

            excused = leave_by_date.get(date_str, set()) | perm_by_date.get(date_str, set())
            has_full_leave = 0 in excused or (1 in excused and 2 in excused)
            has_s1_leave = 1 in excused or has_full_leave
            has_s2_leave = 2 in excused or has_full_leave
            has_any_leave = len(excused) > 0

            day_status = 'none'
            late_minutes = 0
            is_early_checkout = False

            if not is_workday:
                day_status = 'dayOff'
            else:
                days_goal += 1

                # Check check-in timeliness
                for r in records_today:
                    if r.status in ('checked_in', 'checked_out') and r.check_in_time:
                        total_checkins += 1
                        check_in_local = timezone.localtime(r.check_in_time).time()
                        target_start = s1_start if r.session == 1 else s2_start
                        if check_in_local <= target_start:
                            on_time_checkins += 1
                        else:
                            diff_sec = (datetime.datetime.combine(day_date, check_in_local) - datetime.datetime.combine(day_date, target_start)).total_seconds()
                            diff_min = max(0, int(diff_sec // 60))
                            late_minutes += diff_min

                # Check early checkout
                for r in records_today:
                    if r.status == 'checked_out' and r.check_out_time:
                        check_out_local = timezone.localtime(r.check_out_time).time()
                        target_end = s1_end if r.session == 1 else s2_end
                        if check_out_local < target_end:
                            # If approved leave covered this section, it's excused
                            sec_excused = (r.session == 1 and has_s1_leave) or (r.session == 2 and has_s2_leave)
                            if not sec_excused:
                                is_early_checkout = True

                # Determine status
                has_completed_work = (
                    (rec1 and rec1.status == 'checked_out') or
                    (rec2 and rec2.status == 'checked_out') or
                    (records_today and any(r.status == 'checked_in' for r in records_today))
                )

                if has_full_leave and not has_completed_work:
                    day_status = 'leave'
                    days_leave += 1
                elif has_completed_work:
                    day_status = 'worked'
                    days_worked += 1
                elif has_any_leave and not has_completed_work:
                    # Partial leave (e.g. Section 1 excused)
                    # If Section 2 has not passed yet, it's currently an excused leave / pending section
                    if day_date == today and now_time <= s2_end:
                        day_status = 'leave'
                        days_leave += 1
                    elif day_date < today or (day_date == today and now_time > s2_end):
                        # Afternoon passed without check-in
                        day_status = 'absent'
                        days_absent += 1
                    else:
                        day_status = 'leave'
                        days_leave += 1
                elif day_date < today or (day_date == today and now_time > s2_end):
                    day_status = 'absent'
                    days_absent += 1
                else:
                    # Scheduled future workday or open workday
                    day_status = 'workday'

            calendar_days[date_str] = {
                "date": date_str,
                "day": day_num,
                "weekday": day_code,
                "is_workday": is_workday,
                "status": day_status,
                "late_minutes": late_minutes,
                "is_early_checkout": is_early_checkout,
            }

        on_time_rate = round((on_time_checkins / total_checkins) * 100) if total_checkins > 0 else 100
        days_remaining = max(0, days_goal - days_worked)

        # Work Schedule shifts definition
        s1_hours = max(0, int((datetime.datetime.combine(today, s1_end) - datetime.datetime.combine(today, s1_start)).total_seconds() // 3600))
        s2_hours = max(0, int((datetime.datetime.combine(today, s2_end) - datetime.datetime.combine(today, s2_start)).total_seconds() // 3600))
        total_hours = s1_hours + s2_hours

        s1_str = f"{s1_start.strftime('%I:%M %p')} – {s1_end.strftime('%I:%M %p')}"
        s2_str = f"{s2_start.strftime('%I:%M %p')} – {s2_end.strftime('%I:%M %p')}"

        work_schedule_days = []
        holidays_days = []

        all_day_codes = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']
        for code in all_day_codes:
            short_name, full_name = weekday_full_map[code]
            if code in allowed_days:
                work_schedule_days.append({
                    "short": short_name,
                    "full": full_name,
                    "shifts": [
                        {"startHour": s1_start.hour, "endHour": s1_end.hour, "range": s1_str},
                        {"startHour": s2_start.hour, "endHour": s2_end.hour, "range": s2_str},
                    ],
                    "totalHours": total_hours,
                })
            else:
                holidays_days.append({
                    "short": short_name,
                    "full": full_name,
                    "reason": "Scheduled Day Off",
                })

        return {
            "year": target_year,
            "month": target_month,
            "month_name": month_name,
            "days_goal": days_goal,
            "days_worked": days_worked,
            "days_absent": days_absent,
            "days_leave": days_leave,
            "absence_limit": 8,
            "on_time_rate": on_time_rate,
            "days_remaining": days_remaining,
            "shifts": {
                "section1": {"start": s1_start.strftime('%H:%M:%S'), "end": s1_end.strftime('%H:%M:%S'), "range": s1_str},
                "section2": {"start": s2_start.strftime('%H:%M:%S'), "end": s2_end.strftime('%H:%M:%S'), "range": s2_str},
            },
            "schedule": work_schedule_days,
            "holidays": holidays_days,
            "leaves": leave_records,
            "calendar_days": calendar_days,
        }

    @classmethod
    def get_department_attendance_summary(cls, user, department_query=None, month=None, year=None):
        """
        Calculates session attendance statistics for a given department:
        - absent: scheduled workday sessions missed without approved permission
        - waive: waived sessions
        - absentWithPermission: sessions covered by approved permission requests or leave
        """
        import calendar
        import datetime
        from api.department.models import Department
        from api.employee.models import Employee
        from api.request.models import LeaveRequest, PermissionRequest, RequestStatus

        today = timezone.localdate()
        now_time = timezone.localtime().time()

        all_dept_names = list(Department.objects.values_list('name', flat=True).distinct())

        user_dept_name = user.department.name if getattr(user, 'department', None) else (all_dept_names[0] if all_dept_names else 'IT')

        target_dept_name = (department_query or '').strip()
        if not target_dept_name:
            target_dept_name = user_dept_name

        dept_obj = Department.objects.filter(name__iexact=target_dept_name).first()
        if dept_obj:
            employees = Employee.objects.filter(department=dept_obj)
        else:
            if getattr(user, 'department', None):
                employees = Employee.objects.filter(department=user.department)
            else:
                employees = Employee.objects.filter(status='active')

        target_year = None
        target_month = None
        if year is not None:
            try:
                y = int(year)
                if y > 0:
                    target_year = y
            except (ValueError, TypeError):
                pass

        if month is not None:
            try:
                m = int(month)
                if 1 <= m <= 12:
                    target_month = m
            except (ValueError, TypeError):
                pass

        if target_year and target_month:
            _, num_days = calendar.monthrange(target_year, target_month)
            start_date = datetime.date(target_year, target_month, 1)
            end_date = datetime.date(target_year, target_month, num_days)
        elif target_year:
            start_date = datetime.date(target_year, 1, 1)
            end_date = datetime.date(target_year, 12, 31)
        elif target_month:
            current_year = today.year
            _, num_days = calendar.monthrange(current_year, target_month)
            start_date = datetime.date(current_year, target_month, 1)
            end_date = datetime.date(current_year, target_month, num_days)
        else:
            target_year = today.year
            target_month = today.month
            _, num_days = calendar.monthrange(target_year, target_month)
            start_date = datetime.date(target_year, target_month, 1)
            end_date = datetime.date(target_year, target_month, num_days)

        eval_end = min(end_date, today)

        attendances = Attendance.objects.filter(
            employee__in=employees,
            date__range=[start_date, eval_end],
        )
        att_map = {}
        for a in attendances:
            att_map[(a.employee_id, a.date.isoformat(), a.session)] = a

        perms = PermissionRequest.objects.filter(
            employee__in=employees,
            status=RequestStatus.APPROVED,
            date__range=[start_date, eval_end],
        )
        perm_map = {}
        for p in perms:
            perm_map[(p.employee_id, p.date.isoformat(), p.session)] = p
            if not p.session:
                perm_map[(p.employee_id, p.date.isoformat(), 1)] = p
                perm_map[(p.employee_id, p.date.isoformat(), 2)] = p

        leaves = LeaveRequest.objects.filter(
            employee__in=employees,
            status=RequestStatus.APPROVED,
            from_date__lte=eval_end,
            to_date__gte=start_date,
        )
        leave_map = {}
        for l in leaves:
            cur = max(start_date, l.from_date)
            finish = min(eval_end, l.to_date)
            while cur <= finish:
                leave_map[(l.employee_id, cur.isoformat())] = l
                cur += datetime.timedelta(days=1)

        weekday_map = {0: 'mon', 1: 'tue', 2: 'wed', 3: 'thu', 4: 'fri', 5: 'sat', 6: 'sun'}

        records = []
        cur_d = start_date
        while cur_d <= eval_end:
            d_str = cur_d.isoformat()
            code = weekday_map[cur_d.weekday()]

            for emp in employees:
                allowed = [d.strip().lower() for d in (emp.work_days or 'mon,tue,wed,thu,fri').split(',') if d.strip()]
                if code not in allowed:
                    continue

                def _to_t(val, fallback):
                    if val is None:
                        return fallback
                    if isinstance(val, datetime.time):
                        return val
                    if isinstance(val, str):
                        try:
                            return datetime.time.fromisoformat(val)
                        except ValueError:
                            parts = [int(p) for p in val.split(':')]
                            return datetime.time(*parts)
                    return fallback

                s1_s = _to_t(emp.section1_start, datetime.time(7, 0))
                s1_e = _to_t(emp.section1_end, datetime.time(11, 0))
                s2_s = _to_t(emp.section2_start, datetime.time(13, 0))
                s2_e = _to_t(emp.section2_end, datetime.time(17, 0))

                s1_sched = f"{s1_s.strftime('%H:%M')}-{s1_e.strftime('%H:%M')}"
                s2_sched = f"{s2_s.strftime('%H:%M')}-{s2_e.strftime('%H:%M')}"

                for sess_num, s_start, s_end, s_sched in [
                    (1, s1_s, s1_e, s1_sched),
                    (2, s2_s, s2_e, s2_sched),
                ]:
                    if cur_d == today and now_time < s_end:
                        continue

                    perm = perm_map.get((emp.id, d_str, sess_num))
                    leave = leave_map.get((emp.id, d_str))
                    att = att_map.get((emp.id, d_str, sess_num))

                    if perm or leave:
                        records.append({
                            "department": target_dept_name,
                            "date": d_str,
                            "schedule": perm.schedule_time if (perm and perm.schedule_time) else s_sched,
                            "type": "absentWithPermission",
                            "employee_name": emp.fullname,
                        })
                    elif att:
                        if att.status == 'waived':
                            records.append({
                                "department": target_dept_name,
                                "date": d_str,
                                "schedule": s_sched,
                                "type": "waive",
                                "employee_name": emp.fullname,
                            })
                    else:
                        records.append({
                            "department": target_dept_name,
                            "date": d_str,
                            "schedule": s_sched,
                            "type": "absent",
                            "employee_name": emp.fullname,
                        })

            cur_d += datetime.timedelta(days=1)

        records.reverse()

        absent_count = sum(1 for r in records if r["type"] == "absent")
        waive_count = sum(1 for r in records if r["type"] == "waive")
        ap_count = sum(1 for r in records if r["type"] == "absentWithPermission")

        return {
            "department": target_dept_name,
            "departments": all_dept_names if all_dept_names else [target_dept_name],
            "user_department": user_dept_name,
            "month": target_month or 0,
            "year": target_year or today.year,
            "absent_count": absent_count,
            "waive_count": waive_count,
            "permission_count": ap_count,
            "records": records[:200],
        }


