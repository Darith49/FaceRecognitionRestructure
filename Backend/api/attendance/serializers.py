from rest_framework import serializers
from .models import Attendance


class AttendanceSerializer(serializers.ModelSerializer):
    employee_name = serializers.CharField(source='employee.fullname', read_only=True)
    branch_name = serializers.CharField(source='branch.name', read_only=True)

    class Meta:
        model = Attendance
        fields = [
            'id', 'employee', 'employee_name', 'branch', 'branch_name',
            'check_in_time', 'check_in_latitude', 'check_in_longitude',
            'check_out_time', 'check_out_latitude', 'check_out_longitude',
            'status', 'session', 'date', 'created_at'
        ]
        read_only_fields = [
            'id', 'employee', 'employee_name', 'branch_name',
            'check_in_time', 'check_out_time', 'session', 'date', 'created_at'
        ]
