from django.db import models
from django.utils import timezone
from api.employee.models import Employee
from api.branch.models import Branch


class Attendance(models.Model):
    """Attendance log for check-in and check-out."""
    STATUS_CHOICES = [
        ('checked_in', 'Checked In'),
        ('checked_out', 'Checked Out'),
    ]

    employee = models.ForeignKey(
        Employee,
        on_delete=models.CASCADE,
        related_name='attendance_records',
    )
    branch = models.ForeignKey(
        Branch,
        on_delete=models.CASCADE,
        related_name='attendance_records',
    )
    check_in_time = models.DateTimeField(auto_now_add=True)
    check_in_latitude = models.FloatField()
    check_in_longitude = models.FloatField()
    check_out_time = models.DateTimeField(null=True, blank=True)
    check_out_latitude = models.FloatField(null=True, blank=True)
    check_out_longitude = models.FloatField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='checked_in')
    date = models.DateField(default=timezone.localdate, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        app_label = 'api'
        ordering = ['-check_in_time']

    def __str__(self):
        return f"{self.employee.fullname} - {self.date} ({self.get_status_display()})"
