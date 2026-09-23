from django.urls import path
from api.request import views

urlpatterns = [
    # Leave
    path('leave/', views.leave_list_create, name='leave_list_create'),
    path('leave/<int:pk>/', views.leave_detail, name='leave_detail'),
    path('leave/<int:pk>/review/', views.leave_review, name='leave_review'),

    # Overtime
    path('overtime/', views.overtime_list_create, name='overtime_list_create'),
    path('overtime/<int:pk>/', views.overtime_detail, name='overtime_detail'),
    path('overtime/<int:pk>/review/', views.overtime_review, name='overtime_review'),

    # Suggestions
    path('suggestions/', views.suggestion_list_create, name='suggestion_list_create'),
    path('suggestions/<int:pk>/read/', views.suggestion_mark_read, name='suggestion_mark_read'),

    # Permissions
    path('permissions/', views.permission_list_create, name='permission_list_create'),
    path('permissions/<int:pk>/', views.permission_detail, name='permission_detail'),
    path('permissions/<int:pk>/review/', views.permission_review, name='permission_review'),

    # Supervisor incoming requests
    path('incoming/', views.incoming_requests, name='incoming_requests'),
]
