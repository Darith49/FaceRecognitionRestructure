import logging
from api.employee.models import Employee
from api.request.models import Notification

logger = logging.getLogger(__name__)


def find_supervisors_for(employee: Employee):
    """
    Resolves the approval chain for an employee:
    - Employee -> Leader of Department/Branch (or Manager, or CEO)
    - Leader -> Manager of Branch (or CEO)
    - Manager -> CEO
    - CEO -> No supervisor (self-approved or oversight)
    """
    if employee.reporting_to:
        return [employee.reporting_to]

    role = getattr(employee, 'role', 'employee').lower()
    supervisors = []

    if role == 'employee':
        # Look for a leader in the same department
        if employee.department:
            leader = Employee.objects.filter(
                department=employee.department,
                role='leader',
                status='active',
            ).exclude(id=employee.id).first()
            if leader:
                supervisors.append(leader)

        # Fallback to leader in same branch
        if not supervisors and employee.branch:
            leader = Employee.objects.filter(
                branch=employee.branch,
                role='leader',
                status='active',
            ).exclude(id=employee.id).first()
            if leader:
                supervisors.append(leader)

        # Fallback to branch manager
        if not supervisors and employee.branch:
            manager = Employee.objects.filter(
                branch=employee.branch,
                role='manager',
                status='active',
            ).first()
            if manager:
                supervisors.append(manager)

    elif role == 'leader':
        # Look for manager in the same branch
        if employee.branch:
            manager = Employee.objects.filter(
                branch=employee.branch,
                role='manager',
                status='active',
            ).exclude(id=employee.id).first()
            if manager:
                supervisors.append(manager)

    elif role == 'manager':
        # Directly goes to CEO
        pass

    # If no local supervisor was found, fall back to CEO
    if not supervisors and role != 'ceo':
        ceo = Employee.objects.filter(role='ceo', status='active').first()
        if ceo:
            supervisors.append(ceo)

    return supervisors


def send_notification(recipient: Employee, title: str, message: str, notif_type: str = 'general', ref_id: str = '', sender: Employee = None):
    """Creates a notification for the recipient."""
    try:
        return Notification.objects.create(
            recipient=recipient,
            sender=sender,
            title=title,
            message=message,
            notification_type=notif_type,
            reference_id=str(ref_id),
        )
    except Exception as e:
        logger.error("Failed to create notification: %s", e)
        return None
