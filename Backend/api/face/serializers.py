from rest_framework import serializers
from .models import FaceRegistration


class FaceRegistrationSerializer(serializers.ModelSerializer):
    employee_name = serializers.CharField(source='employee.fullname', read_only=True)

    class Meta:
        model = FaceRegistration
        fields = ['id', 'employee', 'employee_name', 'created_at', 'updated_at']
