from django.apps import AppConfig

class ApiConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'api'

    def ready(self):
        # Initialize Firebase Admin SDK safely
        from .services.firebase_service import initialize_firebase
        initialize_firebase()
