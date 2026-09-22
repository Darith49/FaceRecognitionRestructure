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
        app_label = 'api'
        verbose_name_plural = 'Branches'
        ordering = ['-created_at']

    def __str__(self):
        return self.name
