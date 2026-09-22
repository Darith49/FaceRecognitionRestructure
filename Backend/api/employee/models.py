from django.db import models
from api.branch.models import Branch
from api.department.models import Department


class Employee(models.Model):
    """
    Company business identity connecting Firebase Auth to organizational data.
    Single model representing CEO, Manager, Leader, and Employee.
    """
    ROLE_CHOICES = [
        ('ceo', 'CEO'),
        ('manager', 'Manager'),
        ('leader', 'Leader'),
        ('employee', 'Employee'),
    ]

    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('active', 'Active'),
        ('inactive', 'Inactive'),
    ]

    firebase_uid = models.CharField(max_length=200, unique=True, db_index=True)
    employee_id = models.CharField(max_length=50, blank=True)
    fullname = models.CharField(max_length=200)
    email = models.EmailField(unique=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='employee')
    branch = models.ForeignKey(
        Branch,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='employees',
    )
    department = models.ForeignKey(
        Department,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='employees',
    )
    phone_number = models.CharField(max_length=30, blank=True, default='')
    reporting_to = models.ForeignKey(
        'self',
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='subordinates',
    )
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    # Scheduled Work Sections and Work Days
    section1_start = models.TimeField(default='07:00:00')
    section1_end = models.TimeField(default='11:00:00')
    section2_start = models.TimeField(default='13:00:00')
    section2_end = models.TimeField(default='17:00:00')
    work_days = models.CharField(max_length=100, default='mon,tue,wed,thu,fri')
    profile_url = models.TextField(blank=True, default='')
    created_by = models.CharField(max_length=200, blank=True)  # Firebase UID of creator
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        app_label = 'api'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.fullname} ({self.get_role_display()}) - {self.email}"

    @property
    def is_active(self):
        return self.status == 'active'

    @property
    def is_authenticated(self):
        # DRF compatibility for request.user
        return True
