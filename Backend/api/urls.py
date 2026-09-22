from django.urls import path, include
from api.health import health_check

urlpatterns = [
    path('health/', health_check, name='health-check'),
    path('branches/', include('api.branch.urls')),
    path('departments/', include('api.department.urls')),
    path('employees/', include('api.employee.urls')),
    path('face/', include('api.face.urls')),
    path('attendance/', include('api.attendance.urls')),
]

