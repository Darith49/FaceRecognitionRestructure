from api.branch.serializers import BranchSerializer
from api.department.serializers import DepartmentSerializer
from api.employee.serializers import EmployeeSerializer, CreateEmployeeSerializer
from api.face.serializers import FaceRegistrationSerializer
from api.attendance.serializers import AttendanceSerializer

__all__ = [
    'BranchSerializer',
    'DepartmentSerializer',
    'EmployeeSerializer',
    'CreateEmployeeSerializer',
    'FaceRegistrationSerializer',
    'AttendanceSerializer',
]
