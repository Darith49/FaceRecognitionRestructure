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
    Expects multipart POST: image, latitude, longitude.
    """
    image = request.FILES.get('image')
    latitude = request.POST.get('latitude')
    longitude = request.POST.get('longitude')

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
        result = AttendanceService.process_check_in(request.user, image, lat, lon)
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
    Expects multipart POST: image, latitude, longitude.
    """
    image = request.FILES.get('image')
    latitude = request.POST.get('latitude')
    longitude = request.POST.get('longitude')

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
        result = AttendanceService.process_check_out(request.user, image, lat, lon)
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
    """Checks whether the authenticated employee is currently checked in today."""
    employee = request.user
    today = timezone.localdate()

    record = Attendance.objects.filter(
        employee=employee,
        date=today,
    ).order_by('-check_in_time').first()

    if record:
        serializer = AttendanceSerializer(record)
        return Response({
            "is_checked_in": record.status == 'checked_in',
            "record": serializer.data
        })
    return Response({
        "is_checked_in": False,
        "record": None
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
