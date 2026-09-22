from django.db import models
from api.branch.models import Branch


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
        app_label = 'api'
        ordering = ['-created_at']
        unique_together = ('branch', 'name')

    def __str__(self):
        return f"{self.name} ({self.branch.name})"
