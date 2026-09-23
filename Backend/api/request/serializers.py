from rest_framework import serializers
from api.request.models import (
    LeaveRequest,
    OvertimeRequest,
    Suggestion,
    PermissionRequest,
    Notification,
)


class LeaveRequestSerializer(serializers.ModelSerializer):
    employee_name = serializers.CharField(source='employee.fullname', read_only=True)
    employee_id_code = serializers.CharField(source='employee.employee_id', read_only=True)
    reviewer_name = serializers.CharField(source='reviewed_by.fullname', read_only=True, default='')

    class Meta:
        model = LeaveRequest
        fields = [
            'id',
            'employee',
            'employee_name',
            'employee_id_code',
            'session',
            'leave_mode',
            'early_leave_time',
            'leave_type',
            'day_type',
            'from_date',
            'to_date',
            'from_time',
            'to_time',
            'reason',
            'attachment',
            'attachment_url',
            'status',
            'reviewed_by',
            'reviewer_name',
            'review_notes',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'employee', 'status', 'reviewed_by', 'created_at', 'updated_at']


class OvertimeRequestSerializer(serializers.ModelSerializer):
    employee_name = serializers.CharField(source='employee.fullname', read_only=True)
    employee_id_code = serializers.CharField(source='employee.employee_id', read_only=True)
    reviewer_name = serializers.CharField(source='reviewed_by.fullname', read_only=True, default='')

    class Meta:
        model = OvertimeRequest
        fields = [
            'id',
            'employee',
            'employee_name',
            'employee_id_code',
            'date',
            'from_time',
            'to_time',
            'reason',
            'attachment',
            'attachment_url',
            'status',
            'reviewed_by',
            'reviewer_name',
            'review_notes',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'employee', 'status', 'reviewed_by', 'created_at', 'updated_at']


class SuggestionSerializer(serializers.ModelSerializer):
    sender_name = serializers.SerializerMethodField()
    reader_name = serializers.CharField(source='read_by.fullname', read_only=True, default='')

    class Meta:
        model = Suggestion
        fields = [
            'id',
            'employee',
            'sender_name',
            'is_anonymous',
            'message',
            'is_read',
            'read_by',
            'reader_name',
            'read_at',
            'created_at',
        ]
        read_only_fields = ['id', 'employee', 'is_read', 'read_by', 'read_at', 'created_at']

    def get_sender_name(self, obj):
        if obj.is_anonymous or not obj.employee:
            return 'Anonymous'
        return obj.employee.fullname


class PermissionRequestSerializer(serializers.ModelSerializer):
    employee_name = serializers.CharField(source='employee.fullname', read_only=True)
    employee_id_code = serializers.CharField(source='employee.employee_id', read_only=True)
    reviewer_name = serializers.CharField(source='reviewed_by.fullname', read_only=True, default='')

    class Meta:
        model = PermissionRequest
        fields = [
            'id',
            'employee',
            'employee_name',
            'employee_id_code',
            'permission_type',
            'date',
            'reason',
            'status',
            'reviewed_by',
            'reviewer_name',
            'review_notes',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'employee', 'status', 'reviewed_by', 'created_at', 'updated_at']


class NotificationSerializer(serializers.ModelSerializer):
    sender_name = serializers.CharField(source='sender.fullname', read_only=True, default='System')

    class Meta:
        model = Notification
        fields = [
            'id',
            'recipient',
            'sender',
            'sender_name',
            'title',
            'message',
            'notification_type',
            'reference_id',
            'is_read',
            'created_at',
        ]
        read_only_fields = ['id', 'recipient', 'sender', 'created_at']
