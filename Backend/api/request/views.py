import logging
from django.utils import timezone
from rest_framework import status
from rest_framework.decorators import api_view, parser_classes
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.response import Response

from api.employee.models import Employee
from api.request.models import (
    LeaveRequest,
    OvertimeRequest,
    Suggestion,
    PermissionRequest,
    Notification,
    RequestStatus,
)
from api.request.serializers import (
    LeaveRequestSerializer,
    OvertimeRequestSerializer,
    SuggestionSerializer,
    PermissionRequestSerializer,
    NotificationSerializer,
)
from api.request.services import find_supervisors_for, send_notification

logger = logging.getLogger(__name__)


# ==============================================================================
# LEAVE REQUESTS
# ==============================================================================

@api_view(['GET', 'POST'])
@parser_classes([MultiPartParser, FormParser, JSONParser])
def leave_list_create(request):
    user = request.user

    if request.method == 'GET':
        status_filter = request.query_params.get('status')
        queryset = LeaveRequest.objects.filter(employee=user).select_related('employee', 'reviewed_by')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        serializer = LeaveRequestSerializer(queryset, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    elif request.method == 'POST':
        data = request.data.copy()
        serializer = LeaveRequestSerializer(data=data)
        if serializer.is_valid():
            leave = serializer.save(employee=user)
            # Detail description for notifications
            if leave.session in (1, 2):
                sec_str = "Section 1 (Morning)" if leave.session == 1 else "Section 2 (Afternoon)"
                if leave.leave_mode == 'early_leave' and leave.early_leave_time:
                    time_str = leave.early_leave_time.strftime('%I:%M %p') if hasattr(leave.early_leave_time, 'strftime') else str(leave.early_leave_time)
                    detail_desc = f"{sec_str} leave early at {time_str}"
                else:
                    detail_desc = f"{sec_str} full section leave"
            elif leave.session == 0:
                detail_desc = "Full Day leave"
            else:
                detail_desc = leave.day_type

            # Notify supervisors
            supervisors = find_supervisors_for(user)
            for s in supervisors:
                send_notification(
                    recipient=s,
                    sender=user,
                    title=f"New Leave Request from {user.fullname}",
                    message=f"{user.fullname} requested {detail_desc} on {leave.from_date}: {leave.reason}",
                    notif_type='leave_request',
                    ref_id=str(leave.id),
                )
            return Response(LeaveRequestSerializer(leave).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
def leave_review(request, pk):
    user = request.user
    role = getattr(user, 'role', '').lower()
    if role not in ('ceo', 'manager', 'leader'):
        return Response({"error": "You do not have authority to review requests."}, status=status.HTTP_403_FORBIDDEN)

    leave = LeaveRequest.objects.filter(pk=pk).select_related('employee').first()
    if not leave:
        return Response({"error": "Leave request not found."}, status=status.HTTP_404_NOT_FOUND)

    action = request.data.get('status', '').lower()
    if action not in ('approved', 'rejected'):
        return Response({"error": "Status must be 'approved' or 'rejected'."}, status=status.HTTP_400_BAD_REQUEST)

    leave.status = action
    leave.reviewed_by = user
    leave.review_notes = request.data.get('review_notes', '')
    leave.save()

    sec_desc = "Section 1" if leave.session == 1 else ("Section 2" if leave.session == 2 else "Full Day")
    # Notify employee
    send_notification(
        recipient=leave.employee,
        sender=user,
        title=f"Leave Request {action.capitalize()}",
        message=f"Your leave request ({sec_desc}) for {leave.from_date} has been {action} by {user.fullname}." + (f" Note: {leave.review_notes}" if leave.review_notes else ""),
        notif_type=f'leave_{action}',
        ref_id=str(leave.id),
    )

    return Response(LeaveRequestSerializer(leave).data, status=status.HTTP_200_OK)


@api_view(['GET', 'PATCH', 'DELETE'])
def leave_detail(request, pk):
    user = request.user
    role = getattr(user, 'role', '').lower()
    leave = LeaveRequest.objects.filter(pk=pk).select_related('employee').first()
    if not leave:
        return Response({"error": "Leave request not found."}, status=status.HTTP_404_NOT_FOUND)

    if leave.employee != user and role not in ('ceo', 'manager', 'leader'):
        return Response({"error": "Forbidden."}, status=status.HTTP_403_FORBIDDEN)

    if request.method == 'GET':
        return Response(LeaveRequestSerializer(leave).data, status=status.HTTP_200_OK)

    if leave.employee != user:
        return Response({"error": "Only the request owner can update or cancel this request."}, status=status.HTTP_403_FORBIDDEN)

    if request.method == 'DELETE':
        leave.delete()
        return Response({"message": "Leave request cancelled successfully."}, status=status.HTTP_200_OK)

    elif request.method == 'PATCH':
        serializer = LeaveRequestSerializer(leave, data=request.data, partial=True)
        if serializer.is_valid():
            updated = serializer.save()
            if leave.status == RequestStatus.APPROVED:
                updated.status = RequestStatus.PENDING
                updated.reviewed_by = None
                updated.review_notes = ''
                updated.save()
            return Response(LeaveRequestSerializer(updated).data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)



# ==============================================================================
# OVERTIME REQUESTS
# ==============================================================================

@api_view(['GET', 'POST'])
@parser_classes([MultiPartParser, FormParser, JSONParser])
def overtime_list_create(request):
    user = request.user

    if request.method == 'GET':
        status_filter = request.query_params.get('status')
        queryset = OvertimeRequest.objects.filter(employee=user).select_related('employee', 'reviewed_by')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        serializer = OvertimeRequestSerializer(queryset, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    elif request.method == 'POST':
        data = request.data.copy()
        serializer = OvertimeRequestSerializer(data=data)
        if serializer.is_valid():
            ot = serializer.save(employee=user)
            # Notify supervisors
            supervisors = find_supervisors_for(user)
            for s in supervisors:
                send_notification(
                    recipient=s,
                    sender=user,
                    title=f"New Overtime Request from {user.fullname}",
                    message=f"{user.fullname} requested overtime on {ot.date} ({ot.from_time} - {ot.to_time}): {ot.reason}",
                    notif_type='overtime_request',
                    ref_id=str(ot.id),
                )
            return Response(OvertimeRequestSerializer(ot).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
def overtime_review(request, pk):
    user = request.user
    role = getattr(user, 'role', '').lower()
    if role not in ('ceo', 'manager', 'leader'):
        return Response({"error": "You do not have authority to review requests."}, status=status.HTTP_403_FORBIDDEN)

    ot = OvertimeRequest.objects.filter(pk=pk).select_related('employee').first()
    if not ot:
        return Response({"error": "Overtime request not found."}, status=status.HTTP_404_NOT_FOUND)

    action = request.data.get('status', '').lower()
    if action not in ('approved', 'rejected'):
        return Response({"error": "Status must be 'approved' or 'rejected'."}, status=status.HTTP_400_BAD_REQUEST)

    ot.status = action
    ot.reviewed_by = user
    ot.review_notes = request.data.get('review_notes', '')
    ot.save()

    # Notify employee
    send_notification(
        recipient=ot.employee,
        sender=user,
        title=f"Overtime Request {action.capitalize()}",
        message=f"Your overtime request for {ot.date} has been {action} by {user.fullname}." + (f" Note: {ot.review_notes}" if ot.review_notes else ""),
        notif_type=f'overtime_{action}',
        ref_id=str(ot.id),
    )

    return Response(OvertimeRequestSerializer(ot).data, status=status.HTTP_200_OK)


@api_view(['GET', 'PATCH', 'DELETE'])
def overtime_detail(request, pk):
    user = request.user
    role = getattr(user, 'role', '').lower()
    ot = OvertimeRequest.objects.filter(pk=pk).select_related('employee').first()
    if not ot:
        return Response({"error": "Overtime request not found."}, status=status.HTTP_404_NOT_FOUND)

    if ot.employee != user and role not in ('ceo', 'manager', 'leader'):
        return Response({"error": "Forbidden."}, status=status.HTTP_403_FORBIDDEN)

    if request.method == 'GET':
        return Response(OvertimeRequestSerializer(ot).data, status=status.HTTP_200_OK)

    if ot.employee != user:
        return Response({"error": "Only the request owner can update or cancel this request."}, status=status.HTTP_403_FORBIDDEN)

    if request.method == 'DELETE':
        ot.delete()
        return Response({"message": "Overtime request cancelled successfully."}, status=status.HTTP_200_OK)

    elif request.method == 'PATCH':
        serializer = OvertimeRequestSerializer(ot, data=request.data, partial=True)
        if serializer.is_valid():
            updated = serializer.save()
            if ot.status == RequestStatus.APPROVED:
                updated.status = RequestStatus.PENDING
                updated.reviewed_by = None
                updated.review_notes = ''
                updated.save()
            return Response(OvertimeRequestSerializer(updated).data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)



# ==============================================================================
# SUGGESTION BOX
# ==============================================================================

@api_view(['GET', 'POST'])
def suggestion_list_create(request):
    user = request.user
    role = getattr(user, 'role', '').lower()

    if request.method == 'GET':
        if role in ('ceo', 'manager'):
            # Executives see all suggestions
            queryset = Suggestion.objects.all().select_related('employee', 'read_by')
        else:
            # Regular staff see only their own suggestions
            queryset = Suggestion.objects.filter(employee=user).select_related('employee', 'read_by')

        serializer = SuggestionSerializer(queryset, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    elif request.method == 'POST':
        message = request.data.get('message', '').strip()
        if not message:
            return Response({"error": "Message cannot be empty."}, status=status.HTTP_400_BAD_REQUEST)

        is_anon = request.data.get('is_anonymous', True)
        if isinstance(is_anon, str):
            is_anon = is_anon.lower() in ('true', '1', 'yes')

        sugg = Suggestion.objects.create(
            employee=user,
            is_anonymous=is_anon,
            message=message,
        )

        # Notify CEO and Branch Manager
        recipients = list(Employee.objects.filter(role__in=['ceo', 'manager'], status='active'))
        sender_label = 'Anonymous' if is_anon else user.fullname
        for r in recipients:
            send_notification(
                recipient=r,
                sender=None if is_anon else user,
                title="New Suggestion Submitted",
                message=f"Suggestion from {sender_label}: {message[:120]}...",
                notif_type='suggestion',
                ref_id=str(sugg.id),
            )

        return Response(SuggestionSerializer(sugg).data, status=status.HTTP_201_CREATED)


@api_view(['PATCH', 'POST'])
def suggestion_mark_read(request, pk):
    user = request.user
    role = getattr(user, 'role', '').lower()
    if role not in ('ceo', 'manager'):
        return Response({"error": "Only CEO and Managers can mark suggestions as read."}, status=status.HTTP_403_FORBIDDEN)

    sugg = Suggestion.objects.filter(pk=pk).first()
    if not sugg:
        return Response({"error": "Suggestion not found."}, status=status.HTTP_404_NOT_FOUND)

    sugg.is_read = True
    sugg.read_by = user
    sugg.read_at = timezone.now()
    sugg.save()

    return Response(SuggestionSerializer(sugg).data, status=status.HTTP_200_OK)


# ==============================================================================
# PERMISSION REQUESTS
# ==============================================================================

@api_view(['GET', 'POST'])
def permission_list_create(request):
    user = request.user

    if request.method == 'GET':
        status_filter = request.query_params.get('status')
        queryset = PermissionRequest.objects.filter(employee=user).select_related('employee', 'reviewed_by')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        serializer = PermissionRequestSerializer(queryset, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    elif request.method == 'POST':
        data = request.data.copy()
        serializer = PermissionRequestSerializer(data=data)
        if serializer.is_valid():
            perm = serializer.save(employee=user)
            # Notify supervisors
            supervisors = find_supervisors_for(user)
            for s in supervisors:
                send_notification(
                    recipient=s,
                    sender=user,
                    title=f"New Permission Request from {user.fullname}",
                    message=f"{user.fullname} requested permission ({perm.get_permission_type_display()}) for {perm.date}: {perm.reason}",
                    notif_type='permission_request',
                    ref_id=str(perm.id),
                )
            return Response(PermissionRequestSerializer(perm).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
def permission_review(request, pk):
    user = request.user
    role = getattr(user, 'role', '').lower()
    if role not in ('ceo', 'manager', 'leader'):
        return Response({"error": "You do not have authority to review requests."}, status=status.HTTP_403_FORBIDDEN)

    perm = PermissionRequest.objects.filter(pk=pk).select_related('employee').first()
    if not perm:
        return Response({"error": "Permission request not found."}, status=status.HTTP_404_NOT_FOUND)

    action = request.data.get('status', '').lower()
    if action not in ('approved', 'rejected'):
        return Response({"error": "Status must be 'approved' or 'rejected'."}, status=status.HTTP_400_BAD_REQUEST)

    perm.status = action
    perm.reviewed_by = user
    perm.review_notes = request.data.get('review_notes', '')
    perm.save()

    # Notify employee
    send_notification(
        recipient=perm.employee,
        sender=user,
        title=f"Permission Request {action.capitalize()}",
        message=f"Your permission request for {perm.date} has been {action} by {user.fullname}." + (f" Note: {perm.review_notes}" if perm.review_notes else ""),
        notif_type=f'permission_{action}',
        ref_id=str(perm.id),
    )

    return Response(PermissionRequestSerializer(perm).data, status=status.HTTP_200_OK)


@api_view(['GET', 'PATCH', 'DELETE'])
def permission_detail(request, pk):
    user = request.user
    role = getattr(user, 'role', '').lower()
    perm = PermissionRequest.objects.filter(pk=pk).select_related('employee').first()
    if not perm:
        return Response({"error": "Permission request not found."}, status=status.HTTP_404_NOT_FOUND)

    if perm.employee != user and role not in ('ceo', 'manager', 'leader'):
        return Response({"error": "Forbidden."}, status=status.HTTP_403_FORBIDDEN)

    if request.method == 'GET':
        return Response(PermissionRequestSerializer(perm).data, status=status.HTTP_200_OK)

    if perm.employee != user:
        return Response({"error": "Only the request owner can update or cancel this request."}, status=status.HTTP_403_FORBIDDEN)

    if request.method == 'DELETE':
        perm.delete()
        return Response({"message": "Permission request cancelled successfully."}, status=status.HTTP_200_OK)

    elif request.method == 'PATCH':
        serializer = PermissionRequestSerializer(perm, data=request.data, partial=True)
        if serializer.is_valid():
            updated = serializer.save()
            if perm.status == RequestStatus.APPROVED:
                updated.status = RequestStatus.PENDING
                updated.reviewed_by = None
                updated.review_notes = ''
                updated.save()
            return Response(PermissionRequestSerializer(updated).data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)



# ==============================================================================
# INCOMING PENDING REQUESTS (CEO, MANAGER, LEADER)
# ==============================================================================

@api_view(['GET'])
def incoming_requests(request):
    """
    Returns pending requests routed to the current supervisor:
    - CEO sees requests from Managers (or company-wide).
    - Manager sees requests from Leaders & branch employees.
    - Leader sees requests from department employees.
    """
    user = request.user
    role = getattr(user, 'role', 'employee').lower()

    if role == 'employee':
        return Response({"pending_leaves": [], "pending_overtimes": [], "pending_permissions": []}, status=status.HTTP_200_OK)

    # Filter candidates based on organizational hierarchy
    if role == 'ceo':
        subordinates = Employee.objects.exclude(id=user.id)
    elif role == 'manager':
        subordinates = Employee.objects.filter(branch=user.branch).exclude(id=user.id)
    elif role == 'leader':
        subordinates = Employee.objects.filter(department=user.department).exclude(id=user.id)
    else:
        subordinates = Employee.objects.none()

    pending_leaves = LeaveRequest.objects.filter(
        employee__in=subordinates,
        status=RequestStatus.PENDING,
    ).select_related('employee')

    pending_overtimes = OvertimeRequest.objects.filter(
        employee__in=subordinates,
        status=RequestStatus.PENDING,
    ).select_related('employee')

    pending_permissions = PermissionRequest.objects.filter(
        employee__in=subordinates,
        status=RequestStatus.PENDING,
    ).select_related('employee')

    return Response({
        "role": role,
        "total_pending": pending_leaves.count() + pending_overtimes.count() + pending_permissions.count(),
        "leaves": LeaveRequestSerializer(pending_leaves, many=True).data,
        "overtimes": OvertimeRequestSerializer(pending_overtimes, many=True).data,
        "permissions": PermissionRequestSerializer(pending_permissions, many=True).data,
    }, status=status.HTTP_200_OK)


# ==============================================================================
# NOTIFICATIONS
# ==============================================================================

@api_view(['GET'])
def notification_list(request):
    """Returns list of notifications for the authenticated user and unread count."""
    user = request.user
    notifications = Notification.objects.filter(recipient=user).select_related('sender').order_by('-created_at')[:50]
    unread_count = Notification.objects.filter(recipient=user, is_read=False).count()

    return Response({
        "unread_count": unread_count,
        "results": NotificationSerializer(notifications, many=True).data,
    }, status=status.HTTP_200_OK)


@api_view(['PATCH', 'POST'])
def notification_mark_read(request, pk):
    """Marks a single notification as read."""
    user = request.user
    notif = Notification.objects.filter(pk=pk, recipient=user).first()
    if not notif:
        return Response({"error": "Notification not found."}, status=status.HTTP_404_NOT_FOUND)

    notif.is_read = True
    notif.save(update_fields=['is_read'])
    return Response(NotificationSerializer(notif).data, status=status.HTTP_200_OK)


@api_view(['POST'])
def notification_mark_all_read(request):
    """Marks all notifications for the user as read."""
    user = request.user
    updated = Notification.objects.filter(recipient=user, is_read=False).update(is_read=True)
    return Response({"success": True, "marked_count": updated}, status=status.HTTP_200_OK)
