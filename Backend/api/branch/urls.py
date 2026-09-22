from django.urls import path
from . import views

urlpatterns = [
    path('', views.branch_list_create, name='branch_list_create'),
    path('<int:pk>/', views.branch_detail, name='branch_detail'),
]
