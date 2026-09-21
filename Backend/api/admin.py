from django.contrib import admin
from .models import Branch, Department, Employee, FaceRegistration, Attendance


@admin.register(Branch)
class BranchAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'latitude', 'longitude', 'radius', 'created_at')
    search_fields = ('name',)


@admin.register(Department)
class DepartmentAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'branch', 'created_at')
    list_filter = ('branch',)
    search_fields = ('name', 'branch__name')


@admin.register(Employee)
class EmployeeAdmin(admin.ModelAdmin):
    list_display = ('id', 'fullname', 'email', 'role', 'status', 'branch', 'department', 'created_at')
    list_filter = ('role', 'status', 'branch', 'department')
    search_fields = ('fullname', 'email', 'employee_id', 'firebase_uid')


@admin.register(FaceRegistration)
class FaceRegistrationAdmin(admin.ModelAdmin):
    list_display = ('id', 'employee', 'created_at', 'updated_at')
    search_fields = ('employee__fullname', 'employee__email')


@admin.register(Attendance)
class AttendanceAdmin(admin.ModelAdmin):
    list_display = ('id', 'employee', 'branch', 'status', 'check_in_time', 'check_out_time', 'date')
    list_filter = ('status', 'branch', 'date')
    search_fields = ('employee__fullname', 'employee__email', 'branch__name')
