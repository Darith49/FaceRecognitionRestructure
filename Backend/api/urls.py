from django.urls import path
from . import views

urlpatterns = [
    # Branch Endpoints
    path('branches/', views.branch_list_create, name='branch_list_create'),
    path('branches/<int:pk>/', views.branch_detail, name='branch_detail'),

    # Department Endpoints
    path('departments/', views.department_list_create, name='department_list_create'),
    path('departments/<int:pk>/', views.department_detail, name='department_detail'),

    # Employee Endpoints
    path('employees/', views.employee_list_create, name='employee_list_create'),
    path('employees/me/', views.employee_me, name='employee_me'),
    path('employees/<int:pk>/', views.employee_detail, name='employee_detail'),
    path('employees/<int:pk>/resend-invitation/', views.resend_employee_invitation, name='employee_resend_invitation'),

    # Face Endpoints
    path('face/register/', views.register_face, name='register_face'),
    path('face/status/', views.face_status, name='face_status'),

    # Attendance Endpoints
    path('attendance/check-in/', views.check_in, name='check_in'),
    path('attendance/check-out/', views.check_out, name='check_out'),
    path('attendance/status/', views.attendance_status, name='attendance_status'),
    path('attendance/records/', views.attendance_records, name='attendance_records'),
]
