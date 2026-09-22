from django.urls import path
from . import views

urlpatterns = [
    path('', views.employee_list_create, name='employee_list_create'),
    path('me/', views.employee_me, name='employee_me'),
    path('<int:pk>/', views.employee_detail, name='employee_detail'),
    path('<int:pk>/resend-invitation/', views.resend_employee_invitation, name='employee_resend_invitation'),
]
