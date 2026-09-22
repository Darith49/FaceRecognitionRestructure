import logging
from django.utils import timezone
from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response

from api.branch.models import Branch
from api.department.models import Department
from api.common.services.firebase_service import (
    create_firebase_user,
    update_firebase_user,
    generate_password_setup_link,
    sync_firestore_user_profile,
)
from .models import Employee
from .serializers import EmployeeSerializer, CreateEmployeeSerializer

logger = logging.getLogger(__name__)


@api_view(['GET', 'POST'])
def employee_list_create(request):
    """
    GET: List employees with optional filters (?branch=, ?department=, ?role=, ?status=).
    POST: Create & invite a new employee using Firebase Admin SDK + SQLite.
    """
    if request.method == 'GET':
        queryset = Employee.objects.select_related('branch', 'department').all().order_by('-created_at')

        branch = request.query_params.get('branch')
        department = request.query_params.get('department')
        role = request.query_params.get('role')
        emp_status = request.query_params.get('status')

        if branch:
            queryset = queryset.filter(branch_id=branch)
        if department:
            queryset = queryset.filter(department_id=department)
        if role:
            queryset = queryset.filter(role=role)
        if emp_status:
            queryset = queryset.filter(status=emp_status)

        serializer = EmployeeSerializer(queryset, many=True)
        return Response(serializer.data)

    elif request.method == 'POST':
        creator_role = getattr(request.user, 'role', '')
        if creator_role == 'employee':
            return Response({"error": "Employees cannot create new users."}, status=status.HTTP_403_FORBIDDEN)

        serializer = CreateEmployeeSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        target_role = data['role']

        # Hierarchy validation
        allowed_roles = {
            'ceo': ['manager', 'leader', 'employee'],
            'manager': ['leader', 'employee'],
            'leader': ['employee'],
        }

        if target_role not in allowed_roles.get(creator_role, []):
            return Response(
                {"error": f"{creator_role.upper()} cannot create a {target_role.upper()}."},
                status=status.HTTP_403_FORBIDDEN
            )

        branch = None
        department = None
        if data.get('branch_id'):
            try:
                branch = Branch.objects.get(pk=data['branch_id'])
            except Branch.DoesNotExist:
                return Response({"error": "Branch does not exist."}, status=status.HTTP_400_BAD_REQUEST)

        if data.get('department_id'):
            try:
                department = Department.objects.get(pk=data['department_id'])
                if branch and department.branch_id != branch.id:
                    return Response({"error": "Department does not belong to selected branch."}, status=status.HTTP_400_BAD_REQUEST)
            except Department.DoesNotExist:
                return Response({"error": "Department does not exist."}, status=status.HTTP_400_BAD_REQUEST)

        email = data['email'].strip().lower()
        fullname = data['fullname'].strip()

        if Employee.objects.filter(email=email).exists():
            return Response({"error": "An employee with this email already exists."}, status=status.HTTP_400_BAD_REQUEST)

        emp_id = data.get('employee_id', '').strip()
        if emp_id and Employee.objects.filter(employee_id=emp_id).exists():
            return Response({"error": f"An employee with ID '{emp_id}' already exists."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            firebase_uid = create_firebase_user(email=email, fullname=fullname)
        except Exception as e:
            return Response({"error": f"Firebase user creation failed: {str(e)}"}, status=status.HTTP_400_BAD_REQUEST)

        invitation_link = generate_password_setup_link(email)

        employee_id = data.get('employee_id') or f"EMP-{Employee.objects.count() + 1:04d}"
        employee = Employee.objects.create(
            firebase_uid=firebase_uid,
            employee_id=employee_id,
            fullname=fullname,
            email=email,
            role=target_role,
            branch=branch,
            department=department,
            status='pending',
            created_by=request.user.firebase_uid,
        )

        firestore_payload = {
            'uid': firebase_uid,
            'employeeId': employee_id,
            'email': email,
            'fullname': fullname,
            'role': target_role,
            'branchId': str(branch.id) if branch else '',
            'departmentId': str(department.id) if department else '',
            'status': 'pending',
            'createdBy': request.user.firebase_uid,
            'createdAt': timezone.now(),
            'invitationStatus': 'pending',
        }
        sync_firestore_user_profile(firebase_uid, firestore_payload)

        return Response({
            "message": f"Employee invited successfully as {target_role.upper()}.",
            "employee": EmployeeSerializer(employee).data,
            "invitation_link": invitation_link,
        }, status=status.HTTP_201_CREATED)


@api_view(['GET'])
def employee_me(request):
    """Returns the current authenticated employee's profile."""
    serializer = EmployeeSerializer(request.user)
    return Response(serializer.data)


@api_view(['GET', 'PATCH'])
def employee_detail(request, pk):
    """Retrieve or update employee info."""
    try:
        employee = Employee.objects.select_related('branch', 'department').get(pk=pk)
    except Employee.DoesNotExist:
        return Response({"error": "Employee not found"}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        serializer = EmployeeSerializer(employee)
        return Response(serializer.data)

    elif request.method == 'PATCH':
        serializer = EmployeeSerializer(employee, data=request.data, partial=True)
        if serializer.is_valid():
            updated_emp = serializer.save()
            new_email = request.data.get('email')
            new_name = request.data.get('fullname')
            if new_email or new_name:
                update_firebase_user(
                    employee.firebase_uid,
                    email=new_email.strip().lower() if new_email else None,
                    fullname=new_name.strip() if new_name else None,
                )
            firestore_payload = {
                'fullname': updated_emp.fullname,
                'email': updated_emp.email,
                'role': updated_emp.role,
                'branchId': str(updated_emp.branch.id) if updated_emp.branch else '',
                'departmentId': str(updated_emp.department.id) if updated_emp.department else '',
                'employeeId': updated_emp.employee_id,
            }
            sync_firestore_user_profile(updated_emp.firebase_uid, firestore_payload)
            return Response(EmployeeSerializer(updated_emp).data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
def resend_employee_invitation(request, pk):
    """
    Resends password reset/setup invitation email for the specified employee.
    Requires CEO, Manager, or Leader role.
    """
    creator_role = getattr(request.user, 'role', '')
    if creator_role == 'employee':
        return Response({"error": "Employees cannot resend invitations."}, status=status.HTTP_403_FORBIDDEN)

    try:
        employee = Employee.objects.get(pk=pk)
    except Employee.DoesNotExist:
        return Response({"error": "Employee not found"}, status=status.HTTP_404_NOT_FOUND)

    invitation_link = generate_password_setup_link(employee.email)
    return Response({
        "message": f"Invitation link generated for {employee.fullname} ({employee.email}).",
        "invitation_link": invitation_link,
    }, status=status.HTTP_200_OK)
