from rest_framework import serializers
from .models import Department


class DepartmentSerializer(serializers.ModelSerializer):
    branch_name = serializers.CharField(source='branch.name', read_only=True)

    class Meta:
        model = Department
        fields = ['id', 'name', 'branch', 'branch_name', 'created_by', 'created_at']
        read_only_fields = ['id', 'created_by', 'created_at', 'branch_name']
