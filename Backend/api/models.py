from django.db import models


class Branch(models.Model):
    """A physical office location with GPS coordinates and radius in meters."""
    name = models.CharField(max_length=200)
    latitude = models.FloatField()
    longitude = models.FloatField()
    radius = models.FloatField(default=100.0)  # In meters
    created_by = models.CharField(max_length=200, blank=True)  # Firebase UID of creator
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name_plural = 'Branches'
        ordering = ['-created_at']

    def __str__(self):
        return self.name


class Department(models.Model):
    """A department belonging to a specific Branch."""
    name = models.CharField(max_length=200)
    branch = models.ForeignKey(
        Branch,
        on_delete=models.CASCADE,
        related_name='departments',
    )
    created_by = models.CharField(max_length=200, blank=True)  # Firebase UID of creator
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        unique_together = ('branch', 'name')

    def __str__(self):
        return f"{self.name} ({self.branch.name})"


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
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    created_by = models.CharField(max_length=200, blank=True)  # Firebase UID of creator
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
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


class FaceRegistration(models.Model):
    """Stores exactly one registered face embedding per employee."""
    employee = models.OneToOneField(
        Employee,
        on_delete=models.CASCADE,
        related_name='face_registration',
    )
    embedding = models.JSONField()  # 512-dim ArcFace embedding vector
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Face: {self.employee.fullname}"


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
    date = models.DateField(auto_now_add=True, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-check_in_time']

    def __str__(self):
        return f"{self.employee.fullname} - {self.status} - {self.date}"
