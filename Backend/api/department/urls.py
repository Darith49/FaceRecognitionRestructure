from django.urls import path
from . import views

urlpatterns = [
    path('', views.department_list_create, name='department_list_create'),
    path('<int:pk>/', views.department_detail, name='department_detail'),
]
