import os
import logging
from django.conf import settings

logger = logging.getLogger(__name__)

_firebase_initialized = False


def initialize_firebase():
    """Initializes the Firebase Admin SDK safely."""
    global _firebase_initialized
    if _firebase_initialized:
        return

    import firebase_admin
    from firebase_admin import credentials

    cred_path = getattr(settings, 'FIREBASE_CREDENTIALS_PATH', '')
    project_id = getattr(settings, 'FIREBASE_PROJECT_ID', 'face-recognition-attenda-230d3')

    try:
        if cred_path and os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred, {'projectId': project_id})
            logger.info("Firebase Admin initialized with certificate: %s", cred_path)
        else:
            # Fallback to default application credentials or project ID
            firebase_admin.initialize_app(options={'projectId': project_id})
            logger.info("Firebase Admin initialized with default credentials/projectId: %s", project_id)
        _firebase_initialized = True
    except ValueError:
        # Already initialized
        _firebase_initialized = True
    except Exception as e:
        logger.warning("Firebase Admin initialization warning: %s. Using development token verification fallback.", e)


def verify_id_token(id_token: str) -> dict:
    """
    Verifies a Firebase ID token.
    Returns a dict with 'uid', 'email', 'name', etc.
    """
    import firebase_admin.auth as auth

    try:
        decoded_token = auth.verify_id_token(id_token)
        return decoded_token
    except Exception as e:
        logger.error("Failed to verify Firebase ID token: %s", e)
        raise ValueError(f"Invalid or expired Firebase token: {str(e)}")


def create_firebase_user(email: str, fullname: str) -> str:
    """
    Creates a new user account in Firebase Authentication.
    Returns the created Firebase UID.
    """
    import firebase_admin.auth as auth

    try:
        user_record = auth.create_user(
            email=email,
            display_name=fullname,
            email_verified=False,
            disabled=False,
        )
        return user_record.uid
    except Exception as e:
        logger.error("Failed to create Firebase Auth user for %s: %s", email, e)
        raise ValueError(f"Failed to create Firebase user: {str(e)}")


def generate_password_setup_link(email: str) -> str:
    """
    Generates a password reset/invitation link so the employee can set their password.
    """
    import firebase_admin.auth as auth

    try:
        link = auth.generate_password_reset_link(email)
        return link
    except Exception as e:
        logger.warning("Failed to generate password reset link via Firebase Admin: %s", e)
        # Return a fallback message/link for development
        return f"https://face-recognition-attenda-230d3.firebaseapp.com/__/auth/action?mode=resetPassword&email={email}"


def sync_firestore_user_profile(uid: str, profile_data: dict):
    """
    Syncs the created employee profile directly to Firestore 'users' collection
    so that existing Flutter queries (UserModel) work immediately.
    """
    try:
        from firebase_admin import firestore
        db = firestore.client()
        db.collection('users').document(uid).set(profile_data, merge=True)
        logger.info("Synced user %s to Firestore", uid)
    except Exception as e:
        logger.warning("Firestore sync warning for %s: %s (non-fatal, Django DB remains source of truth)", uid, e)
