from django.db import models
from api.employee.models import Employee


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

    class Meta:
        app_label = 'api'

    def __str__(self):
        return f"Face: {self.employee.fullname}"
