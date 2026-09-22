import logging
from django.db import connection
from rest_framework import status
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

logger = logging.getLogger(__name__)


@api_view(['GET'])
@authentication_classes([])
@permission_classes([AllowAny])
def health_check(request):
    """
    Unauthenticated health check endpoint for Docker, load balancers, and monitoring.
    Verifies that the application process is running and SQLite database is accessible.
    """
    db_status = "healthy"
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1;")
            cursor.fetchone()
    except Exception as exc:
        logger.error("Health check database probe failed: %s", exc)
        db_status = f"unhealthy: {exc}"

    is_healthy = db_status == "healthy"
    return Response(
        {
            "status": "ok" if is_healthy else "degraded",
            "database": db_status,
            "service": "attendance-backend-api",
        },
        status=status.HTTP_200_OK if is_healthy else status.HTTP_503_SERVICE_UNAVAILABLE,
    )
