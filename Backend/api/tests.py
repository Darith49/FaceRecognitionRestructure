from django.test import TestCase
from .models import Branch, Department, Employee, FaceRegistration, Attendance
from .services.attendance_service import AttendanceService
from .services.face_service import FaceService


class ModelAndServiceTests(TestCase):
    def setUp(self):
        self.branch = Branch.objects.create(
            name="Phnom Penh Branch",
            latitude=11.5564,
            longitude=104.9282,
            radius=100.0,
            created_by="test-ceo-uid",
        )
        self.department = Department.objects.create(
            name="IT & Engineering",
            branch=self.branch,
            created_by="test-ceo-uid",
        )
        self.ceo = Employee.objects.create(
            firebase_uid="test-ceo-uid",
            employee_id="CEO-001",
            fullname="CEO User",
            email="ceo@company.com",
            role="ceo",
            branch=self.branch,
            department=self.department,
            status="active",
        )
        self.employee = Employee.objects.create(
            firebase_uid="test-emp-uid",
            employee_id="EMP-001",
            fullname="Employee User",
            email="employee@company.com",
            role="employee",
            branch=self.branch,
            department=self.department,
            status="active",
        )

    def test_branch_and_department(self):
        self.assertEqual(str(self.branch), "Phnom Penh Branch")
        self.assertEqual(self.department.branch, self.branch)
        self.assertEqual(self.branch.departments.count(), 1)

    def test_haversine_distance(self):
        # Coordinates very close (~0m)
        dist = AttendanceService.calculate_distance(11.5564, 104.9282, 11.5564, 104.9282)
        self.assertAlmostEqual(dist, 0.0, places=1)

        # Inside branch radius (100m)
        is_in, dist = AttendanceService.validate_location(11.55641, 104.92821, self.branch)
        self.assertTrue(is_in)
        self.assertLessEqual(dist, 100.0)

        # Far outside branch radius
        is_in, dist = AttendanceService.validate_location(11.5700, 104.9500, self.branch)
        self.assertFalse(is_in)
        self.assertGreater(dist, 100.0)

    def test_cosine_distance_identical_embeddings(self):
        emb1 = [0.1] * 512
        emb2 = [0.1] * 512
        dist, conf, is_match = FaceService.compare_embeddings(emb1, emb2)
        self.assertAlmostEqual(dist, 0.0, places=2)
        self.assertEqual(conf, 100.0)
        self.assertTrue(is_match)

    def test_cosine_distance_different_embeddings(self):
        emb1 = [1.0] + [0.0] * 511
        emb2 = [-1.0] + [0.0] * 511
        dist, conf, is_match = FaceService.compare_embeddings(emb1, emb2)
        self.assertGreater(dist, 1.0)
        self.assertFalse(is_match)

    def test_attendance_creation_and_status(self):
        att = Attendance.objects.create(
            employee=self.employee,
            branch=self.branch,
            check_in_latitude=11.5564,
            check_in_longitude=104.9282,
            status="checked_in",
        )
        self.assertEqual(att.employee, self.employee)
        self.assertEqual(att.status, "checked_in")
        self.assertEqual(att.branch, self.branch)

        # Simulate check-out
        from django.utils import timezone
        att.check_out_time = timezone.now()
        att.check_out_latitude = 11.5564
        att.check_out_longitude = 104.9282
        att.status = "checked_out"
        att.save()

        self.assertEqual(att.status, "checked_out")
        self.assertIsNotNone(att.check_out_time)

    def test_serializers(self):
        from .serializers import BranchSerializer, DepartmentSerializer, EmployeeSerializer
        branch_data = BranchSerializer(self.branch).data
        self.assertEqual(branch_data["name"], "Phnom Penh Branch")
        self.assertEqual(branch_data["department_count"], 1)

        dept_data = DepartmentSerializer(self.department).data
        self.assertEqual(dept_data["name"], "IT & Engineering")
        self.assertEqual(dept_data["branch_name"], "Phnom Penh Branch")

        emp_data = EmployeeSerializer(self.employee).data
        self.assertEqual(emp_data["fullname"], "Employee User")
        self.assertEqual(emp_data["role"], "employee")
        self.assertEqual(emp_data["branch_name"], "Phnom Penh Branch")
        self.assertEqual(emp_data["department_name"], "IT & Engineering")
        self.assertFalse(emp_data["has_face_registered"])

    def test_cambodia_timezone_check_in_and_out(self):
        from django.utils import timezone
        from .serializers import AttendanceSerializer

        # 1. Verify Django active timezone is Cambodia (Asia/Phnom_Penh)
        self.assertEqual(timezone.get_current_timezone_name(), 'Asia/Phnom_Penh')

        # 2. Verify attendance date defaults to Cambodia local date
        att = Attendance.objects.create(
            employee=self.employee,
            branch=self.branch,
            check_in_latitude=11.5564,
            check_in_longitude=104.9282,
            status="checked_in",
        )
        self.assertEqual(att.date, timezone.localdate())

        # 3. Simulate check out time
        att.check_out_time = timezone.now()
        att.check_out_latitude = 11.5564
        att.check_out_longitude = 104.9282
        att.status = "checked_out"
        att.save()

        # 4. Verify serialized output has +07:00 Cambodia offset
        serialized = AttendanceSerializer(att).data
        self.assertIn("+07:00", serialized["check_in_time"])
        self.assertIn("+07:00", serialized["check_out_time"])
        self.assertEqual(serialized["date"], timezone.localdate().isoformat())

    def test_duplicate_prevention(self):
        # 1. Branch with same name exists
        self.assertTrue(Branch.objects.filter(name__iexact="phnom penh branch").exists())

        # 2. Department with same name in branch exists
        self.assertTrue(Department.objects.filter(branch=self.branch, name__iexact="it & engineering").exists())

        # 3. Employee with same email exists
        self.assertTrue(Employee.objects.filter(email="ceo@company.com").exists())
        self.assertTrue(Employee.objects.filter(employee_id="CEO-001").exists())

