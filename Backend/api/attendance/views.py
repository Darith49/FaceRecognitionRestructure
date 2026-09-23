import logging
from django.utils import timezone
from rest_framework import status
from rest_framework.decorators import api_view, parser_classes
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied, ValidationError

from .models import Attendance
from .serializers import AttendanceSerializer
from .services import AttendanceService

logger = logging.getLogger(__name__)


@api_view(['POST'])
@parser_classes([MultiPartParser, FormParser])
def check_in(request):
    """
    Face-verified, GPS geofenced check-in.
    Expects multipart POST: image, latitude, longitude, optional session.
    """
    image = request.FILES.get('image')
    latitude = request.POST.get('latitude')
    longitude = request.POST.get('longitude')
    session = request.POST.get('session')

    if not image:
        return Response({"error": "Face photo is required for check-in."}, status=status.HTTP_400_BAD_REQUEST)
    if latitude is None or longitude is None:
        return Response({"error": "Latitude and longitude are required."}, status=status.HTTP_400_BAD_REQUEST)

    try:
        lat = float(latitude)
        lon = float(longitude)
    except (ValueError, TypeError):
        return Response({"error": "Invalid GPS coordinates."}, status=status.HTTP_400_BAD_REQUEST)

    try:
        result = AttendanceService.process_check_in(request.user, image, lat, lon, session=session)
        return Response(result, status=status.HTTP_200_OK)
    except PermissionDenied as e:
        return Response({"success": False, "error": str(e)}, status=status.HTTP_403_FORBIDDEN)
    except ValidationError as e:
        return Response({"success": False, "error": str(e)}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        logger.error("[check_in] unexpected error: %s", e)
        return Response({"success": False, "error": f"Check-in error: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@parser_classes([MultiPartParser, FormParser])
def check_out(request):
    """
    Face-verified, GPS geofenced check-out.
    Expects multipart POST: image, latitude, longitude, optional session.
    """
    image = request.FILES.get('image')
    latitude = request.POST.get('latitude')
    longitude = request.POST.get('longitude')
    session = request.POST.get('session')

    if not image:
        return Response({"error": "Face photo is required for check-out."}, status=status.HTTP_400_BAD_REQUEST)
    if latitude is None or longitude is None:
        return Response({"error": "Latitude and longitude are required."}, status=status.HTTP_400_BAD_REQUEST)

    try:
        lat = float(latitude)
        lon = float(longitude)
    except (ValueError, TypeError):
        return Response({"error": "Invalid GPS coordinates."}, status=status.HTTP_400_BAD_REQUEST)

    try:
        result = AttendanceService.process_check_out(request.user, image, lat, lon, session=session)
        return Response(result, status=status.HTTP_200_OK)
    except PermissionDenied as e:
        return Response({"success": False, "error": str(e)}, status=status.HTTP_403_FORBIDDEN)
    except ValidationError as e:
        return Response({"success": False, "error": str(e)}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        logger.error("[check_out] unexpected error: %s", e)
        return Response({"success": False, "error": f"Check-out error: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def attendance_status(request):
    """
    Returns today's attendance status for Section 1 and Section 2,
    including absence detection and schedule configuration.
    """
    employee = request.user
    today = timezone.localdate()
    now_time = timezone.localtime().time()

    # Workday check
    weekday_names = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']
    today_code = weekday_names[today.weekday()]
    allowed_days = [d.strip().lower() for d in (getattr(employee, 'work_days', '') or 'mon,tue,wed,thu,fri').split(',') if d.strip()]
    is_work_day = today_code in allowed_days

    # Fetch today's records (order newest first for accurate status)
    records = Attendance.objects.filter(employee=employee, date=today)
    rec1 = records.filter(session=1).order_by('-check_in_time').first()
    rec2 = records.filter(session=2).order_by('-check_in_time').first()

    # If legacy records without session exist:
    if not rec1 and not rec2 and records.exists():
        rec1 = records.order_by('-check_in_time').first()

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

    s1_start = _to_time(getattr(employee, 'section1_start', None))
    s1_end = _to_time(getattr(employee, 'section1_end', None))
    s2_start = _to_time(getattr(employee, 'section2_start', None))
    s2_end = _to_time(getattr(employee, 'section2_end', None))

    # Section 1 status
    if rec1:
        s1_status = 'completed' if rec1.status == 'checked_out' else 'checked_in'
    elif is_work_day and s1_end and now_time > s1_end:
        s1_status = 'absent'
    elif s1_start and s1_end and s1_start <= now_time <= s1_end:
        s1_status = 'open'
    else:
        s1_status = 'upcoming'

    # Section 2 status
    if rec2:
        s2_status = 'completed' if rec2.status == 'checked_out' else 'checked_in'
    elif is_work_day and s2_end and now_time > s2_end:
        s2_status = 'absent'
    elif s2_start and s2_end and s2_start <= now_time <= s2_end:
        s2_status = 'open'
    elif rec1 and rec1.status == 'checked_out' and s2_end and now_time <= s2_end:
        # Section 1 is finished, Section 2 is open for early check-in until it ends
        s2_status = 'open'
    else:
        s2_status = 'upcoming'

    latest_record = records.order_by('-check_in_time').first()
    active_record = records.filter(status='checked_in').order_by('-check_in_time').first()

    return Response({
        "is_checked_in": active_record is not None,
        "record": AttendanceSerializer(latest_record).data if latest_record else None,
        "session1": {
            "status": s1_status,
            "record": AttendanceSerializer(rec1).data if rec1 else None,
        },
        "session2": {
            "status": s2_status,
            "record": AttendanceSerializer(rec2).data if rec2 else None,
        },
        "schedule": {
            "section1_start": str(s1_start) if s1_start else '07:00:00',
            "section1_end": str(s1_end) if s1_end else '11:00:00',
            "section2_start": str(s2_start) if s2_start else '13:00:00',
            "section2_end": str(s2_end) if s2_end else '17:00:00',
            "work_days": getattr(employee, 'work_days', 'mon,tue,wed,thu,fri'),
            "is_work_day_today": is_work_day,
        }
    })


@api_view(['GET'])
def attendance_records(request):
    """Returns attendance records with optional filtering."""
    queryset = Attendance.objects.select_related('employee', 'branch').all()

    if getattr(request.user, 'role', '') == 'employee':
        queryset = queryset.filter(employee=request.user)

    branch_id = request.query_params.get('branch_id')
    date_from = request.query_params.get('date_from')
    date_to = request.query_params.get('date_to')

    if branch_id:
        queryset = queryset.filter(branch_id=branch_id)
    if date_from:
        queryset = queryset.filter(date__gte=date_from)
    if date_to:
        queryset = queryset.filter(date__lte=date_to)

    serializer = AttendanceSerializer(queryset[:100], many=True)
    return Response(serializer.data)


@api_view(['GET'])
def monthly_summary(request):
    """
    Returns monthly attendance metrics, work shifts, holidays, and day-by-day status.
    Supports query parameters: ?year=YYYY&month=MM&employee_id=ID
    """
    target_employee = request.user
    emp_id = request.query_params.get('employee_id')
    if emp_id and getattr(request.user, 'role', '') in ('ceo', 'manager', 'leader'):
        from api.employee.models import Employee
        found = Employee.objects.filter(id=emp_id).first()
        if found:
            target_employee = found

    year = request.query_params.get('year')
    month = request.query_params.get('month')

    summary = AttendanceService.get_monthly_summary(target_employee, year=year, month=month)
    return Response(summary, status=status.HTTP_200_OK)


@api_view(['GET'])
def department_summary(request):
    """
    Returns department attendance breakdown: Absent (A), Waive (W), Absent with Permission (AP).
    Supports filters: ?department=NAME&month=MM&year=YYYY
    """
    dept = request.query_params.get('department')
    month = request.query_params.get('month')
    year = request.query_params.get('year')

    summary = AttendanceService.get_department_attendance_summary(
        request.user,
        department_query=dept,
        month=month,
        year=year,
    )
    return Response(summary, status=status.HTTP_200_OK)


