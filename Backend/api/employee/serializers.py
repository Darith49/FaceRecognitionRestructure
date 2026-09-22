from rest_framework import serializers
from .models import Employee


class EmployeeSerializer(serializers.ModelSerializer):
    branch_name = serializers.CharField(source='branch.name', read_only=True, allow_null=True)
    department_name = serializers.CharField(source='department.name', read_only=True, allow_null=True)
    reporting_to_name = serializers.CharField(source='reporting_to.fullname', read_only=True, allow_null=True)
    has_face_registered = serializers.SerializerMethodField()

    class Meta:
        model = Employee
        fields = [
            'id', 'firebase_uid', 'employee_id', 'fullname', 'email',
            'phone_number', 'reporting_to', 'reporting_to_name',
            'role', 'branch', 'branch_name', 'department', 'department_name',
            'status', 'section1_start', 'section1_end', 'section2_start', 'section2_end',
            'work_days', 'has_face_registered', 'created_by', 'created_at'
        ]
        read_only_fields = [
            'id', 'firebase_uid', 'created_by', 'created_at',
            'branch_name', 'department_name', 'reporting_to_name', 'has_face_registered'
        ]

    def get_has_face_registered(self, obj):
        return hasattr(obj, 'face_registration') and obj.face_registration is not None


class CreateEmployeeSerializer(serializers.Serializer):
    """Payload for inviting/creating an employee via Firebase Admin + SQLite."""
    fullname = serializers.CharField(max_length=200)
    email = serializers.EmailField()
    phone_number = serializers.CharField(max_length=30, required=False, allow_blank=True)
    role = serializers.ChoiceField(choices=Employee.ROLE_CHOICES, default='employee')
    branch_id = serializers.IntegerField(required=False, allow_null=True)
    department_id = serializers.IntegerField(required=False, allow_null=True)
    reporting_to_id = serializers.IntegerField(required=False, allow_null=True)
    employee_id = serializers.CharField(max_length=50, required=False, allow_blank=True)
    section1_start = serializers.TimeField(required=False, default='07:00:00')
    section1_end = serializers.TimeField(required=False, default='11:00:00')
    section2_start = serializers.TimeField(required=False, default='13:00:00')
    section2_end = serializers.TimeField(required=False, default='17:00:00')
    work_days = serializers.CharField(max_length=100, required=False, default='mon,tue,wed,thu,fri')

    def validate(self, data):
        s1_start = data.get('section1_start')
        s1_end = data.get('section1_end')
        s2_start = data.get('section2_start')
        s2_end = data.get('section2_end')

        if s1_start and s1_end and s1_start >= s1_end:
            raise serializers.ValidationError({"section1_end": "Section 1 end time must be after start time."})
        if s2_start and s2_end and s2_start >= s2_end:
            raise serializers.ValidationError({"section2_end": "Section 2 end time must be after start time."})
        if s1_end and s2_start and s1_end > s2_start:
            raise serializers.ValidationError({"section2_start": "Section 2 cannot start before Section 1 ends."})

        return data
