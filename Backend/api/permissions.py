import logging
from rest_framework.authentication import BaseAuthentication, get_authorization_header
from rest_framework.exceptions import AuthenticationFailed
from rest_framework.permissions import BasePermission

from .models import Employee
from .services.firebase_service import verify_id_token

logger = logging.getLogger(__name__)


class FirebaseAuthentication(BaseAuthentication):
    """
    DRF Authentication using Firebase ID Tokens.
    Client sends: 'Authorization: Bearer <firebase_id_token>'
    Validates token and maps to an Employee in SQLite.
    """

    def authenticate(self, request):
        auth_header = get_authorization_header(request).decode('utf-8')
        if not auth_header:
            return None

        parts = auth_header.split()
        if len(parts) != 2 or parts[0].lower() != 'bearer':
            return None

        id_token = parts[1]

        try:
            decoded = verify_id_token(id_token)
        except Exception as e:
            raise AuthenticationFailed(str(e))

        firebase_uid = decoded.get('uid')
        if not firebase_uid:
            raise AuthenticationFailed('Token does not contain a valid Firebase UID.')

        email = decoded.get('email', '')
        fullname = decoded.get('name') or email.split('@')[0] if email else 'User'

        # Query Firestore for profile role if available
        firestore_role = None
        try:
            import firebase_admin.firestore as firestore
            db = firestore.client()
            doc = db.collection('users').document(firebase_uid).get()
            if doc.exists:
                data = doc.to_dict() or {}
                firestore_role = data.get('role')
                if data.get('fullname'):
                    fullname = data.get('fullname')
        except Exception as e:
            logger.debug("Firestore profile lookup skipped: %s", e)

        # Look up or bootstrap employee
        employee = Employee.objects.select_related('branch', 'department').filter(
            firebase_uid=firebase_uid
        ).first()

        if not employee:
            # Bootstrap: use Firestore role if set, otherwise first user is CEO
            is_first_user = not Employee.objects.exists()
            role = firestore_role or ('ceo' if is_first_user else 'employee')
            status = 'active'

            employee = Employee.objects.create(
                firebase_uid=firebase_uid,
                fullname=fullname,
                email=email,
                role=role,
                status=status,
                employee_id='EMP-001' if role == 'ceo' else '',
            )
            logger.info("Auto-registered employee for Firebase UID %s with role %s", firebase_uid, role)
        else:
            # Sync role from Firestore if it differs
            if firestore_role and employee.role != firestore_role:
                employee.role = firestore_role
                employee.save(update_fields=['role'])
                logger.info("Synced role for employee %s to %s from Firestore", employee.email, firestore_role)

        request.employee = employee
        # request.user is set to employee for DRF compatibility
        return (employee, id_token)


class IsCEO(BasePermission):
    """Allows access only to users with role == 'ceo'."""
    def has_permission(self, request, view):
        return bool(
            request.user and
            getattr(request.user, 'role', None) == 'ceo'
        )


class IsManagerOrAbove(BasePermission):
    """Allows access to CEO and Manager."""
    def has_permission(self, request, view):
        return bool(
            request.user and
            getattr(request.user, 'role', None) in ['ceo', 'manager']
        )


class IsLeaderOrAbove(BasePermission):
    """Allows access to CEO, Manager, and Leader."""
    def has_permission(self, request, view):
        return bool(
            request.user and
            getattr(request.user, 'role', None) in ['ceo', 'manager', 'leader']
        )


class IsActiveEmployee(BasePermission):
    """Allows access only to active employees."""
    def has_permission(self, request, view):
        return bool(
            request.user and
            getattr(request.user, 'status', None) == 'active'
        )
