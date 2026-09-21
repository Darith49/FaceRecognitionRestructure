import logging
from django.utils import timezone
from rest_framework import status
from rest_framework.decorators import api_view, parser_classes, permission_classes
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied, ValidationError

from .models import Branch, Department, Employee, FaceRegistration, Attendance
from .serializers import (
    BranchSerializer,
    DepartmentSerializer,
    EmployeeSerializer,
    CreateEmployeeSerializer,
    FaceRegistrationSerializer,
    AttendanceSerializer,
)
from .permissions import IsCEO, IsLeaderOrAbove, IsManagerOrAbove
from .services.firebase_service import (
    create_firebase_user,
    update_firebase_user,
    generate_password_setup_link,
    sync_firestore_user_profile,
)
from .services.face_service import FaceService
from .services.attendance_service import AttendanceService

logger = logging.getLogger(__name__)


# ═══════════════════════════════════════════════════════════════════
#  BRANCH VIEWS
# ═══════════════════════════════════════════════════════════════════

@api_view(['GET', 'POST'])
def branch_list_create(request):
    """
    GET: List all branches.
    POST: Create a branch (CEO only).
    """
    if request.method == 'GET':
        branches = Branch.objects.all().order_by('-created_at')
        serializer = BranchSerializer(branches, many=True)
        return Response(serializer.data)

    elif request.method == 'POST':
        if getattr(request.user, 'role', '') != 'ceo':
            return Response({"error": "Only CEO can create branches."}, status=status.HTTP_403_FORBIDDEN)

        name = request.data.get('name', '').strip()
        if not name:
            return Response({"error": "Branch name is required."}, status=status.HTTP_400_BAD_REQUEST)
        if Branch.objects.filter(name__iexact=name).exists():
            return Response({"error": f"A branch with the name '{name}' already exists."}, status=status.HTTP_400_BAD_REQUEST)

        serializer = BranchSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(created_by=request.user.firebase_uid)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'PATCH', 'DELETE'])
def branch_detail(request, pk):
    """Retrieve, update, or delete a branch."""
    try:
        branch = Branch.objects.get(pk=pk)
    except Branch.DoesNotExist:
        return Response({"error": "Branch not found"}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        serializer = BranchSerializer(branch)
        return Response(serializer.data)

    if getattr(request.user, 'role', '') != 'ceo':
        return Response({"error": "Only CEO can modify or delete branches."}, status=status.HTTP_403_FORBIDDEN)

    if request.method == 'PATCH':
        serializer = BranchSerializer(branch, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    elif request.method == 'DELETE':
        branch.delete()
        return Response({"message": "Branch deleted successfully"}, status=status.HTTP_200_OK)


# ═══════════════════════════════════════════════════════════════════
#  DEPARTMENT VIEWS
# ═══════════════════════════════════════════════════════════════════

@api_view(['GET', 'POST'])
def department_list_create(request):
    """
    GET: List all departments (optional filter: ?branch_id=).
    POST: Create a department (CEO or Manager).
    """
    if request.method == 'GET':
        queryset = Department.objects.select_related('branch').all().order_by('-created_at')
        branch_id = request.query_params.get('branch_id')
        if branch_id:
            queryset = queryset.filter(branch_id=branch_id)
        serializer = DepartmentSerializer(queryset, many=True)
        return Response(serializer.data)

    elif request.method == 'POST':
        if getattr(request.user, 'role', '') not in ['ceo', 'manager']:
            return Response({"error": "Only CEO or Manager can create departments."}, status=status.HTTP_403_FORBIDDEN)

        branch_id = request.data.get('branch')
        if not branch_id:
            return Response({"error": "Branch is required."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            branch = Branch.objects.get(pk=branch_id)
        except Branch.DoesNotExist:
            return Response({"error": "Selected branch does not exist."}, status=status.HTTP_400_BAD_REQUEST)

        name = request.data.get('name', '').strip()
        if not name:
            return Response({"error": "Department name is required."}, status=status.HTTP_400_BAD_REQUEST)

        if Department.objects.filter(branch=branch, name__iexact=name).exists():
            return Response({"error": f"A department named '{name}' already exists in this branch."}, status=status.HTTP_400_BAD_REQUEST)

        serializer = DepartmentSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(created_by=request.user.firebase_uid, branch=branch)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'PATCH', 'DELETE'])
def department_detail(request, pk):
    """Retrieve, update, or delete a department."""
    try:
        department = Department.objects.select_related('branch').get(pk=pk)
    except Department.DoesNotExist:
        return Response({"error": "Department not found"}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        serializer = DepartmentSerializer(department)
        return Response(serializer.data)

    if getattr(request.user, 'role', '') not in ['ceo', 'manager']:
        return Response({"error": "Only CEO or Manager can modify departments."}, status=status.HTTP_403_FORBIDDEN)

    if request.method == 'PATCH':
        serializer = DepartmentSerializer(department, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    elif request.method == 'DELETE':
        department.delete()
        return Response({"message": "Department deleted successfully"}, status=status.HTTP_200_OK)


# ═══════════════════════════════════════════════════════════════════
#  EMPLOYEE VIEWS
# ═══════════════════════════════════════════════════════════════════

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
        # Check creator role
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
            'manager': ['leader'],
            'leader': ['employee'],
        }

        if target_role not in allowed_roles.get(creator_role, []):
            return Response(
                {"error": f"{creator_role.upper()} cannot create a {target_role.upper()}."},
                status=status.HTTP_403_FORBIDDEN
            )

        # Validate branch and department
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

        # Check for existing email in SQLite
        if Employee.objects.filter(email=email).exists():
            return Response({"error": "An employee with this email already exists."}, status=status.HTTP_400_BAD_REQUEST)

        emp_id = data.get('employee_id', '').strip()
        if emp_id and Employee.objects.filter(employee_id=emp_id).exists():
            return Response({"error": f"An employee with ID '{emp_id}' already exists."}, status=status.HTTP_400_BAD_REQUEST)

        # 1. Create Firebase Auth account via Firebase Admin SDK
        try:
            firebase_uid = create_firebase_user(email=email, fullname=fullname)
        except Exception as e:
            return Response({"error": f"Firebase user creation failed: {str(e)}"}, status=status.HTTP_400_BAD_REQUEST)

        # 2. Generate password setup/reset link
        invitation_link = generate_password_setup_link(email)

        # 3. Create Employee record in SQLite
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

        # 4. Sync profile to Firestore 'users' collection for Flutter UserModel compatibility
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


# ═══════════════════════════════════════════════════════════════════
#  FACE MANAGEMENT VIEWS
# ═══════════════════════════════════════════════════════════════════

@api_view(['POST'])
@parser_classes([MultiPartParser, FormParser])
def register_face(request):
    """
    Register or update face embedding for the authenticated employee.
    Expects multipart POST with 'image'.
    """
    image = request.FILES.get('image')
    if not image:
        return Response({"error": "No image provided"}, status=status.HTTP_400_BAD_REQUEST)

    employee = request.user

    file_name, full_path = FaceService.save_temp_file(image, "face_reg")
    try:
        embedding = FaceService.extract_embedding(full_path)
        if embedding is None:
            return Response(
                {"error": "No face detected in image. Please provide a clear, centered face photo."},
                status=status.HTTP_400_BAD_REQUEST
            )

        face_reg, created = FaceRegistration.objects.update_or_create(
            employee=employee,
            defaults={'embedding': embedding}
        )

        # Mark employee active upon face registration if pending
        if employee.status == 'pending':
            employee.status = 'active'
            employee.save(update_fields=['status'])

        action = "registered" if created else "updated"
        return Response({
            "registered": True,
            "message": f"Face {action} successfully for '{employee.fullname}'.",
            "employee_id": employee.id,
            "employee_name": employee.fullname,
        }, status=status.HTTP_200_OK)

    except Exception as e:
        logger.error("[register_face] error: %s", e)
        return Response({"error": f"Registration error: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    finally:
        FaceService.cleanup_file(file_name)


@api_view(['GET'])
def face_status(request):
    """
    Check whether the authenticated employee has a registered face.
    Returns: {"registered": bool, "employee_id": int, "employee_name": str}
    """
    employee = request.user
    exists = FaceRegistration.objects.filter(employee=employee).exists()
    return Response({
        "registered": exists,
        "employee_id": employee.id,
        "employee_name": employee.fullname,
    })


# ═══════════════════════════════════════════════════════════════════
#  ATTENDANCE VIEWS
# ═══════════════════════════════════════════════════════════════════

@api_view(['POST'])
@parser_classes([MultiPartParser, FormParser])
def check_in(request):
    """
    Face-verified, GPS geofenced check-in.
    Expects multipart POST: image, latitude, longitude.
    """
    image = request.FILES.get('image')
    latitude = request.POST.get('latitude')
    longitude = request.POST.get('longitude')

    if not image:
        return Response({"error": "Face photo is required for check-in."}, status=status.HTTP_400_BAD_REQUEST)
    if latitude is None or longitude is None:
        return Response({"error": "Latitude and longitude are required."}, status=status.HTTP_400_BAD_REQUEST)

    try:
        lat = float(latitude)
        lon = float(longitude)
    except (ValueError, TypeError):
        return Response({"error": "Invalid GPS coordinates."}, status=status.HTTP_400_BAD_REQUEST)

    try:
        result = AttendanceService.process_check_in(request.user, image, lat, lon)
        return Response(result, status=status.HTTP_200_OK)
    except PermissionDenied as e:
        return Response({"success": False, "error": str(e)}, status=status.HTTP_403_FORBIDDEN)
    except ValidationError as e:
        return Response({"success": False, "error": str(e)}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        logger.error("[check_in] unexpected error: %s", e)
        return Response({"success": False, "error": f"Check-in error: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@parser_classes([MultiPartParser, FormParser])
def check_out(request):
    """
    Face-verified, GPS geofenced check-out.
    Expects multipart POST: image, latitude, longitude.
    """
    image = request.FILES.get('image')
    latitude = request.POST.get('latitude')
    longitude = request.POST.get('longitude')

    if not image:
        return Response({"error": "Face photo is required for check-out."}, status=status.HTTP_400_BAD_REQUEST)
    if latitude is None or longitude is None:
        return Response({"error": "Latitude and longitude are required."}, status=status.HTTP_400_BAD_REQUEST)

    try:
        lat = float(latitude)
        lon = float(longitude)
    except (ValueError, TypeError):
        return Response({"error": "Invalid GPS coordinates."}, status=status.HTTP_400_BAD_REQUEST)

    try:
        result = AttendanceService.process_check_out(request.user, image, lat, lon)
        return Response(result, status=status.HTTP_200_OK)
    except PermissionDenied as e:
        return Response({"success": False, "error": str(e)}, status=status.HTTP_403_FORBIDDEN)
    except ValidationError as e:
        return Response({"success": False, "error": str(e)}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        logger.error("[check_out] unexpected error: %s", e)
        return Response({"success": False, "error": f"Check-out error: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def attendance_status(request):
    """Checks whether the authenticated employee is currently checked in today."""
    employee = request.user
    today = timezone.localdate()

    record = Attendance.objects.filter(
        employee=employee,
        date=today,
    ).order_by('-check_in_time').first()

    if record:
        serializer = AttendanceSerializer(record)
        return Response({
            "is_checked_in": record.status == 'checked_in',
            "record": serializer.data
        })
    return Response({
        "is_checked_in": False,
        "record": None
    })


@api_view(['GET'])
def attendance_records(request):
    """Returns attendance records with optional filtering."""
    queryset = Attendance.objects.select_related('employee', 'branch').all()

    # Employees can only see their own attendance records unless manager/CEO
    if getattr(request.user, 'role', '') == 'employee':
        queryset = queryset.filter(employee=request.user)

    branch_id = request.query_params.get('branch_id')
    date_from = request.query_params.get('date_from')
    date_to = request.query_params.get('date_to')

    if branch_id:
        queryset = queryset.filter(branch_id=branch_id)
    if date_from:
        queryset = queryset.filter(date__gte=date_from)
    if date_to:
        queryset = queryset.filter(date__lte=date_to)

    serializer = AttendanceSerializer(queryset[:100], many=True)
    return Response(serializer.data)
