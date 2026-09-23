from django.urls import path
from . import views

urlpatterns = [
    path('check-in/', views.check_in, name='check_in'),
    path('check-out/', views.check_out, name='check_out'),
    path('status/', views.attendance_status, name='attendance_status'),
    path('records/', views.attendance_records, name='attendance_records'),
    path('monthly-summary/', views.monthly_summary, name='monthly_summary'),
    path('department-summary/', views.department_summary, name='department_summary'),
]

