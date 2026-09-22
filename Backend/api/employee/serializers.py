from rest_framework import serializers
from .models import Employee


class EmployeeSerializer(serializers.ModelSerializer):
    branch_name = serializers.CharField(source='branch.name', read_only=True, allow_null=True)
    department_name = serializers.CharField(source='department.name', read_only=True, allow_null=True)
    has_face_registered = serializers.SerializerMethodField()

    class Meta:
        model = Employee
        fields = [
            'id', 'firebase_uid', 'employee_id', 'fullname', 'email',
            'role', 'branch', 'branch_name', 'department', 'department_name',
            'status', 'has_face_registered', 'created_by', 'created_at'
        ]
        read_only_fields = [
            'id', 'firebase_uid', 'created_by', 'created_at',
            'branch_name', 'department_name', 'has_face_registered'
        ]

    def get_has_face_registered(self, obj):
        return hasattr(obj, 'face_registration') and obj.face_registration is not None


class CreateEmployeeSerializer(serializers.Serializer):
    """Payload for inviting/creating an employee via Firebase Admin + SQLite."""
    fullname = serializers.CharField(max_length=200)
    email = serializers.EmailField()
    role = serializers.ChoiceField(choices=Employee.ROLE_CHOICES, default='employee')
    branch_id = serializers.IntegerField(required=False, allow_null=True)
    department_id = serializers.IntegerField(required=False, allow_null=True)
    employee_id = serializers.CharField(max_length=50, required=False, allow_blank=True)
