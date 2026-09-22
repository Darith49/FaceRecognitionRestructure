from rest_framework import serializers
from .models import Branch


class BranchSerializer(serializers.ModelSerializer):
    employee_count = serializers.SerializerMethodField()
    department_count = serializers.SerializerMethodField()

    class Meta:
        model = Branch
        fields = [
            'id', 'name', 'latitude', 'longitude', 'radius',
            'created_by', 'created_at', 'employee_count', 'department_count'
        ]
        read_only_fields = ['id', 'created_by', 'created_at', 'employee_count', 'department_count']

    def get_employee_count(self, obj):
        return obj.employees.count()

    def get_department_count(self, obj):
        return obj.departments.count()
