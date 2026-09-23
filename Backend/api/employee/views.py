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
            section1_start=data.get('section1_start', '07:00:00'),
            section1_end=data.get('section1_end', '11:00:00'),
            section2_start=data.get('section2_start', '13:00:00'),
            section2_end=data.get('section2_end', '17:00:00'),
            work_days=data.get('work_days', 'mon,tue,wed,thu,fri'),
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
            'section1Start': str(employee.section1_start),
            'section1End': str(employee.section1_end),
            'section2Start': str(employee.section2_start),
            'section2End': str(employee.section2_end),
            'workDays': employee.work_days,
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


@api_view(['GET', 'PATCH'])
def employee_me(request):
    """Returns or updates the current authenticated employee's profile."""
    if request.method == 'GET':
        serializer = EmployeeSerializer(request.user)
        return Response(serializer.data)
    elif request.method == 'PATCH':
        serializer = EmployeeSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            updated = serializer.save()
            if 'profile_url' in request.data:
                sync_firestore_user_profile(updated.firebase_uid, {'profileUrl': updated.profile_url})
            return Response(EmployeeSerializer(updated).data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
def my_team_view(request):
    """
    Returns the team structure customized for the authenticated user:
    - CEO: Pinned CEO card, [Managers] and [Branches] tabs
    - Manager: Pinned Manager card, [My Leaders] and [Team] tabs
    - Leader: Pinned Leader card, [My Employees] and [Other Leaders] tabs
    - Employee: Pinned Leader card, [My Leader] and [My Department] tabs
    """
    user = request.user
    role = getattr(user, 'role', 'employee').lower()
    search = request.query_params.get('search', '').strip().lower()

    pinned_members = []
    tabs = []

    def filter_emp_data(emp_list):
        if not search:
            return emp_list
        return [
            e for e in emp_list
            if search in (e.get('fullname') or '').lower()
            or search in (e.get('role') or '').lower()
            or search in (e.get('department_name') or '').lower()
            or search in (e.get('branch_name') or '').lower()
        ]

    if role == 'ceo':
        pinned_members.append(EmployeeSerializer(user).data)

        managers = Employee.objects.filter(role='manager').select_related('branch', 'department').order_by('fullname')
        managers_data = filter_emp_data(EmployeeSerializer(managers, many=True).data)

        branches = Branch.objects.prefetch_related('employees', 'departments').all().order_by('name')
        branches_data = []
        for b in branches:
            manager = b.employees.filter(role='manager').first()
            branch_item = {
                'id': b.id,
                'name': b.name,
                'latitude': b.latitude,
                'longitude': b.longitude,
                'radius': b.radius,
                'manager_name': manager.fullname if manager else 'No Manager Assigned',
                'manager_phone': manager.phone_number if manager else '',
                'total_employees': b.employees.count(),
                'total_departments': b.departments.count(),
            }
            if not search or search in b.name.lower() or (manager and search in manager.fullname.lower()):
                branches_data.append(branch_item)

        tabs = [
            {
                'key': 'managers',
                'title': 'Managers',
                'badge': str(len(managers_data)),
                'items': managers_data,
                'is_branch_list': False,
            },
            {
                'key': 'branches',
                'title': 'Branches',
                'badge': str(len(branches_data)),
                'items': branches_data,
                'is_branch_list': True,
            }
        ]

    elif role == 'manager':
        pinned_members.append(EmployeeSerializer(user).data)
        ceo = Employee.objects.filter(role='ceo').first()
        if ceo:
            pinned_members.append(EmployeeSerializer(ceo).data)

        leaders_qs = Employee.objects.filter(role='leader')
        if user.branch:
            leaders_qs = leaders_qs.filter(branch=user.branch)
        leaders = leaders_qs.select_related('branch', 'department').order_by('fullname')
        leaders_data = filter_emp_data(EmployeeSerializer(leaders, many=True).data)

        other_mgrs_qs = Employee.objects.filter(role='manager').exclude(id=user.id)
        other_mgrs = other_mgrs_qs.select_related('branch', 'department').order_by('fullname')
        other_mgrs_data = filter_emp_data(EmployeeSerializer(other_mgrs, many=True).data)

        team_qs = Employee.objects.exclude(id=user.id)
        if user.branch:
            team_qs = team_qs.filter(branch=user.branch)
        team = team_qs.select_related('branch', 'department').order_by('role', 'fullname')
        team_data = filter_emp_data(EmployeeSerializer(team, many=True).data)

        tabs = [
            {
                'key': 'my_leaders',
                'title': 'My Leaders',
                'badge': str(len(leaders_data)),
                'items': leaders_data,
                'is_branch_list': False,
            },
            {
                'key': 'other_managers',
                'title': 'Other Managers',
                'badge': str(len(other_mgrs_data)),
                'items': other_mgrs_data,
                'is_branch_list': False,
            },
            {
                'key': 'team',
                'title': 'Team',
                'badge': str(len(team_data)),
                'items': team_data,
                'is_branch_list': False,
            }
        ]

    elif role == 'leader':
        pinned_members.append(EmployeeSerializer(user).data)
        mgr = None
        if user.branch:
            mgr = Employee.objects.filter(role='manager', branch=user.branch).first()
        if mgr:
            pinned_members.append(EmployeeSerializer(mgr).data)

        emp_qs = Employee.objects.filter(role='employee')
        if user.department:
            emp_qs = emp_qs.filter(department=user.department)
        elif user.branch:
            emp_qs = emp_qs.filter(branch=user.branch)
        employees = emp_qs.select_related('branch', 'department').order_by('fullname')
        employees_data = filter_emp_data(EmployeeSerializer(employees, many=True).data)

        other_qs = Employee.objects.filter(role='leader').exclude(id=user.id)
        if user.branch:
            other_qs = other_qs.filter(branch=user.branch)
        other_leaders = other_qs.select_related('branch', 'department').order_by('fullname')
        other_leaders_data = filter_emp_data(EmployeeSerializer(other_leaders, many=True).data)

        tabs = [
            {
                'key': 'my_employees',
                'title': 'My Employees',
                'badge': str(len(employees_data)),
                'items': employees_data,
                'is_branch_list': False,
            },
            {
                'key': 'other_leaders',
                'title': 'Other Leaders',
                'badge': str(len(other_leaders_data)),
                'items': other_leaders_data,
                'is_branch_list': False,
            }
        ]

    else:
        # role == 'employee'
        leader = None
        if user.department:
            leader = Employee.objects.filter(role='leader', department=user.department).select_related('branch', 'department').first()
        if not leader and user.branch:
            leader = Employee.objects.filter(role='manager', branch=user.branch).select_related('branch', 'department').first()
            if not leader:
                leader = Employee.objects.filter(role='leader', branch=user.branch).select_related('branch', 'department').first()

        if leader:
            pinned_members.append(EmployeeSerializer(leader).data)

        leader_list = filter_emp_data([EmployeeSerializer(leader).data]) if leader else []

        colleagues_qs = Employee.objects.filter(role='employee').exclude(id=user.id)
        if user.department:
            colleagues_qs = colleagues_qs.filter(department=user.department)
        elif user.branch:
            colleagues_qs = colleagues_qs.filter(branch=user.branch)
        colleagues = colleagues_qs.select_related('branch', 'department').order_by('fullname')
        colleagues_data = filter_emp_data(EmployeeSerializer(colleagues, many=True).data)

        tabs = [
            {
                'key': 'my_leader',
                'title': 'My Leader',
                'badge': str(len(leader_list)),
                'items': leader_list,
                'is_branch_list': False,
            },
            {
                'key': 'my_department',
                'title': 'My Department',
                'badge': str(len(colleagues_data)),
                'items': colleagues_data,
                'is_branch_list': False,
            }
        ]

    return Response({
        'role': role,
        'user': EmployeeSerializer(user).data,
        'pinned': pinned_members,
        'tabs': tabs,
    }, status=status.HTTP_200_OK)


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
        updater_role = getattr(request.user, 'role', 'employee').lower()
        shift_fields = {'section1_start', 'section1_end', 'section2_start', 'section2_end', 'work_days', 'role', 'status'}
        if any(f in request.data for f in shift_fields):
            if updater_role not in ['ceo', 'manager', 'leader']:
                return Response({"error": "Only CEO or administrators can update session times and shift schedules."}, status=status.HTTP_403_FORBIDDEN)

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
                'section1Start': str(updated_emp.section1_start),
                'section1End': str(updated_emp.section1_end),
                'section2Start': str(updated_emp.section2_start),
                'section2End': str(updated_emp.section2_end),
                'workDays': updated_emp.work_days,
                'profileUrl': updated_emp.profile_url,
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
