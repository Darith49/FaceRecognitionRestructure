from rest_framework import serializers
from .models import Branch, Department, Employee, FaceRegistration, Attendance


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


class DepartmentSerializer(serializers.ModelSerializer):
    branch_name = serializers.CharField(source='branch.name', read_only=True)

    class Meta:
        model = Department
        fields = ['id', 'name', 'branch', 'branch_name', 'created_by', 'created_at']
        read_only_fields = ['id', 'created_by', 'created_at', 'branch_name']


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
        read_only_fields = ['id', 'firebase_uid', 'created_by', 'created_at', 'branch_name', 'department_name', 'has_face_registered']

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


class FaceRegistrationSerializer(serializers.ModelSerializer):
    employee_name = serializers.CharField(source='employee.fullname', read_only=True)

    class Meta:
        model = FaceRegistration
        fields = ['id', 'employee', 'employee_name', 'created_at', 'updated_at']


class AttendanceSerializer(serializers.ModelSerializer):
    employee_name = serializers.CharField(source='employee.fullname', read_only=True)
    branch_name = serializers.CharField(source='branch.name', read_only=True)

    class Meta:
        model = Attendance
        fields = [
            'id', 'employee', 'employee_name', 'branch', 'branch_name',
            'check_in_time', 'check_in_latitude', 'check_in_longitude',
            'check_out_time', 'check_out_latitude', 'check_out_longitude',
            'status', 'date', 'created_at'
        ]
        read_only_fields = [
            'id', 'employee', 'employee_name', 'branch_name',
            'check_in_time', 'check_out_time', 'date', 'created_at'
        ]
