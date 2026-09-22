from django.test import TestCase
from api.employee.models import Employee
from api.employee.serializers import EmployeeSerializer


class EmployeeSessionTimeSerializerTest(TestCase):
    def setUp(self):
        self.employee = Employee.objects.create(
            firebase_uid='test_uid_123',
            employee_id='EMP-TEST-01',
            fullname='Test User',
            email='testuser@example.com',
            role='employee',
            section1_start='07:00:00',
            section1_end='11:00:00',
            section2_start='13:00:00',
            section2_end='17:00:00',
            work_days='mon,tue,wed,thu,fri',
        )

    def test_valid_session_time_update(self):
        serializer = EmployeeSerializer(
            self.employee,
            data={
                'section1_start': '08:00:00',
                'section1_end': '12:00:00',
                'section2_start': '13:30:00',
                'section2_end': '17:30:00',
                'work_days': 'mon,tue,wed,thu,fri,sat',
            },
            partial=True,
        )
        self.assertTrue(serializer.is_valid(), serializer.errors)
        updated = serializer.save()
        self.assertEqual(str(updated.section1_start), '08:00:00')
        self.assertEqual(str(updated.section1_end), '12:00:00')
        self.assertEqual(str(updated.section2_start), '13:30:00')
        self.assertEqual(str(updated.section2_end), '17:30:00')
        self.assertEqual(updated.work_days, 'mon,tue,wed,thu,fri,sat')

    def test_invalid_session1_order(self):
        serializer = EmployeeSerializer(
            self.employee,
            data={'section1_start': '11:00:00', 'section1_end': '08:00:00'},
            partial=True,
        )
        self.assertFalse(serializer.is_valid())
        self.assertIn('section1_end', serializer.errors)

    def test_invalid_session_overlap(self):
        serializer = EmployeeSerializer(
            self.employee,
            data={'section1_end': '14:00:00', 'section2_start': '13:00:00'},
            partial=True,
        )
        self.assertFalse(serializer.is_valid())
        self.assertIn('section2_start', serializer.errors)

    def test_invalid_session2_order(self):
        serializer = EmployeeSerializer(
            self.employee,
            data={'section2_start': '18:00:00', 'section2_end': '17:00:00'},
            partial=True,
        )
        self.assertFalse(serializer.is_valid())
        self.assertIn('section2_end', serializer.errors)
