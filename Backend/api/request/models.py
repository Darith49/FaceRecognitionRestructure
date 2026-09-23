from django.db import models
from api.employee.models import Employee


class RequestStatus(models.TextChoices):
    PENDING = 'pending', 'Pending'
    APPROVED = 'approved', 'Approved'
    REJECTED = 'rejected', 'Rejected'


class LeaveType(models.TextChoices):
    EARLY_CHECKOUT = 'early_checkout', 'Early Checkout'
    MORNING_SECTION = 'morning_section', 'Morning Section'
    AFTERNOON_SECTION = 'afternoon_section', 'Afternoon Section'
    FULL_DAY = 'full_day', 'Full Day'
    CUSTOM = 'custom', 'Custom'


class LeaveSession(models.IntegerChoices):
    FULL_DAY = 0, 'Full Day'
    SECTION_1 = 1, 'Section 1 (Morning)'
    SECTION_2 = 2, 'Section 2 (Afternoon)'


class LeaveMode(models.TextChoices):
    FULL_SECTION = 'full_section', 'Full Section'
    EARLY_LEAVE = 'early_leave', 'Early Leave'


class LeaveRequest(models.Model):
    """
    Leave Request submitted by employee/leader/manager.
    Supports early checkout, section leave, or multi-day leave.
    """
    employee = models.ForeignKey(
        Employee,
        on_delete=models.CASCADE,
        related_name='leave_requests',
    )
    session = models.IntegerField(
        choices=LeaveSession.choices,
        default=LeaveSession.SECTION_1,
    )
    leave_mode = models.CharField(
        max_length=20,
        choices=LeaveMode.choices,
        default=LeaveMode.FULL_SECTION,
    )
    early_leave_time = models.TimeField(null=True, blank=True)
    leave_type = models.CharField(
        max_length=30,
        choices=LeaveType.choices,
        default=LeaveType.EARLY_CHECKOUT,
    )
    day_type = models.CharField(max_length=50, default='Section 1 (Morning)')
    from_date = models.DateField()
    to_date = models.DateField()
    from_time = models.TimeField(null=True, blank=True)
    to_time = models.TimeField(null=True, blank=True)
    reason = models.TextField()
    attachment = models.FileField(upload_to='leave_attachments/', null=True, blank=True)
    attachment_url = models.CharField(max_length=500, blank=True, default='')
    status = models.CharField(
        max_length=20,
        choices=RequestStatus.choices,
        default=RequestStatus.PENDING,
    )
    reviewed_by = models.ForeignKey(
        Employee,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='reviewed_leaves',
    )
    review_notes = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        app_label = 'api'
        ordering = ['-created_at']

    def __str__(self):
        return f"LeaveRequest #{self.id} by {self.employee.fullname} ({self.status})"


class OvertimeRequest(models.Model):
    """
    Overtime request for working additional hours beyond regular shifts.
    """
    employee = models.ForeignKey(
        Employee,
        on_delete=models.CASCADE,
        related_name='overtime_requests',
    )
    date = models.DateField()
    from_time = models.TimeField()
    to_time = models.TimeField()
    reason = models.TextField()
    attachment = models.FileField(upload_to='overtime_attachments/', null=True, blank=True)
    attachment_url = models.CharField(max_length=500, blank=True, default='')
    status = models.CharField(
        max_length=20,
        choices=RequestStatus.choices,
        default=RequestStatus.PENDING,
    )
    reviewed_by = models.ForeignKey(
        Employee,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='reviewed_overtimes',
    )
    review_notes = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        app_label = 'api'
        ordering = ['-created_at']

    def __str__(self):
        return f"OvertimeRequest #{self.id} by {self.employee.fullname} ({self.status})"


class Suggestion(models.Model):
    """
    Suggestion Box message submitted by employee.
    Default is anonymous submission; viewable and readable by CEO & Managers.
    """
    employee = models.ForeignKey(
        Employee,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='suggestions',
    )
    is_anonymous = models.BooleanField(default=True)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    read_by = models.ForeignKey(
        Employee,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='read_suggestions',
    )
    read_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        app_label = 'api'
        ordering = ['-created_at']

    def __str__(self):
        sender = 'Anonymous' if self.is_anonymous or not self.employee else self.employee.fullname
        return f"Suggestion #{self.id} from {sender} (read: {self.is_read})"


class PermissionType(models.TextChoices):
    STOP_SECTION_1 = 'stop_section_1', 'Stop Section 1'
    STOP_SECTION_2 = 'stop_section_2', 'Stop Section 2'
    STOP_FULL_DAY = 'stop_full_day', 'Stop Full Day'


class PermissionRequest(models.Model):
    """
    Permission request to pause or excuse attendance for a section or full day.
    When approved, excuses absence and marks attendance as authorized leave.
    """
    employee = models.ForeignKey(
        Employee,
        on_delete=models.CASCADE,
        related_name='permission_requests',
    )
    permission_type = models.CharField(
        max_length=30,
        choices=PermissionType.choices,
        default=PermissionType.STOP_SECTION_1,
    )
    date = models.DateField()
    reason = models.TextField()
    status = models.CharField(
        max_length=20,
        choices=RequestStatus.choices,
        default=RequestStatus.PENDING,
    )
    reviewed_by = models.ForeignKey(
        Employee,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='reviewed_permissions',
    )
    review_notes = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        app_label = 'api'
        ordering = ['-created_at']

    def __str__(self):
        return f"PermissionRequest #{self.id} for {self.employee.fullname} ({self.status})"


class Notification(models.Model):
    """
    In-app notification delivered to employee/manager/CEO upon request submission or review.
    """
    recipient = models.ForeignKey(
        Employee,
        on_delete=models.CASCADE,
        related_name='notifications',
    )
    sender = models.ForeignKey(
        Employee,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='sent_notifications',
    )
    title = models.CharField(max_length=200)
    message = models.TextField()
    notification_type = models.CharField(max_length=50, default='general')
    reference_id = models.CharField(max_length=100, blank=True, default='')
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        app_label = 'api'
        ordering = ['-created_at']

    def __str__(self):
        return f"Notification to {self.recipient.fullname}: {self.title} (read: {self.is_read})"
