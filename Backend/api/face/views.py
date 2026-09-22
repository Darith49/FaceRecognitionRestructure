import logging
from rest_framework import status
from rest_framework.decorators import api_view, parser_classes
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.response import Response

from .models import FaceRegistration
from .services import FaceService

logger = logging.getLogger(__name__)


@api_view(['POST'])
@parser_classes([MultiPartParser, FormParser])
def register_face(request):
    """
    Register or update face embedding for the authenticated employee.
    Expects multipart POST with 'image'.
    """
    image = request.FILES.get('image')
    if not image:
        return Response({"error": "No image provided"}, status=status.HTTP_400_BAD_REQUEST)

    employee = request.user

    file_name, full_path = FaceService.save_temp_file(image, "face_reg")
    try:
        embedding = FaceService.extract_embedding(full_path)
        if embedding is None:
            return Response(
                {"error": "No face detected in image. Please provide a clear, centered face photo."},
                status=status.HTTP_400_BAD_REQUEST
            )

        face_reg, created = FaceRegistration.objects.update_or_create(
            employee=employee,
            defaults={'embedding': embedding}
        )

        if employee.status == 'pending':
            employee.status = 'active'
            employee.save(update_fields=['status'])

        action = "registered" if created else "updated"
        return Response({
            "registered": True,
            "message": f"Face {action} successfully for '{employee.fullname}'.",
            "employee_id": employee.id,
            "employee_name": employee.fullname,
        }, status=status.HTTP_200_OK)

    except Exception as e:
        logger.error("[register_face] error: %s", e)
        return Response({"error": f"Registration error: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    finally:
        FaceService.cleanup_file(file_name)


@api_view(['GET'])
def face_status(request):
    """
    Check whether the authenticated employee has a registered face.
    Returns: {"registered": bool, "employee_id": int, "employee_name": str}
    """
    employee = request.user
    exists = FaceRegistration.objects.filter(employee=employee).exists()
    return Response({
        "registered": exists,
        "employee_id": employee.id,
        "employee_name": employee.fullname,
    })
