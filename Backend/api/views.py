from api.branch.views import branch_list_create, branch_detail
from api.department.views import department_list_create, department_detail
from api.employee.views import (
    employee_list_create,
    employee_me,
    employee_detail,
    resend_employee_invitation,
)
from api.face.views import register_face, face_status
from api.attendance.views import (
    check_in,
    check_out,
    attendance_status,
    attendance_records,
)

__all__ = [
    'branch_list_create',
    'branch_detail',
    'department_list_create',
    'department_detail',
    'employee_list_create',
    'employee_me',
    'employee_detail',
    'resend_employee_invitation',
    'register_face',
    'face_status',
    'check_in',
    'check_out',
    'attendance_status',
    'attendance_records',
]
