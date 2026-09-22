from django.urls import path
from . import views

urlpatterns = [
    path('register/', views.register_face, name='register_face'),
    path('status/', views.face_status, name='face_status'),
]
