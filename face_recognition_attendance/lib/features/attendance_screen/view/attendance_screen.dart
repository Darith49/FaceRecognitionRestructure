import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/attendance_screen/controller/attendance_controller.dart';
import 'package:face_recognition_attendance/features/attendance_screen/model/attendance_record.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const Color _absentColor = Color(0xFFF15B5B);
const Color _waiveColor = Color(0xFF3AA6F0);
const Color _permissionColor = Color(0xFFC59500);
const Color _lineColor = Color(0xFFE8B93C);

/// Attendance overview: pick Department, Month and Year to see the session totals.
class AttendanceScreen extends GetView<AttendanceController> {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: 'attendance_title'.tr,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle('Overview'),
          const SizedBox(height: 10),
          const _Caption('Department'),
          Obx(
            () {
              final deptList = controller.departments.isNotEmpty
                  ? controller.departments.toList()
                  : (controller.department.value.isNotEmpty
                      ? [controller.department.value]
                      : ['General']);
              final currentVal = controller.department.value.isNotEmpty &&
                      deptList.contains(controller.department.value)
                  ? controller.department.value
                  : deptList.first;
              return RequestDropdownField<String>(
                value: currentVal,
                fillColor: RequestColors.softSurface,
                icon: Icons.keyboard_arrow_down_rounded,
                items: deptList
                    .map(
                      (name) => DropdownMenuItem<String>(
                        value: name,
                        child: Text(name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (name) {
                  controller.department.value = name;
                  controller.fetchDepartmentSummary();
                },
              );
            },
          ),
          const SizedBox(height: 16),
          const _Caption('Date'),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => RequestDropdownField<int>(
                    value: controller.month.value == 0
                        ? null
                        : controller.month.value,
                    hint: 'Month',
                    fillColor: RequestColors.softSurface,
                    icon: Icons.keyboard_arrow_down_rounded,
                    items: [
                      const DropdownMenuItem<int>(
                        value: 0,
                        child: Text('All months'),
                      ),
                      for (var m = 1; m <= 12; m++)
                        DropdownMenuItem<int>(
                          value: m,
                          child: Text(DateText.monthName(m)),
                        ),
                    ],
                    onChanged: (m) {
                      controller.month.value = m;
                      controller.fetchDepartmentSummary();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => RequestDropdownField<int>(
                    value: controller.year.value == 0
                        ? null
                        : controller.year.value,
                    hint: 'Year',
                    fillColor: RequestColors.softSurface,
                    icon: Icons.keyboard_arrow_down_rounded,
                    items: [
                      const DropdownMenuItem<int>(
                        value: 0,
                        child: Text('All years'),
                      ),
                      for (final y in controller.years)
                        DropdownMenuItem<int>(value: y, child: Text('$y')),
                    ],
                    onChanged: (y) {
                      controller.year.value = y;
                      controller.fetchDepartmentSummary();
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionTitle('Total Sessions'),
          const SizedBox(height: 10),
          Obx(
            () => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _CountCard(
                    title: 'Absent',
                    code: 'A',
                    codeColor: _absentColor,
                    count: controller.countOf(AttendanceType.absent),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CountCard(
                    title: 'Waive',
                    code: 'W',
                    codeColor: _waiveColor,
                    count: controller.countOf(AttendanceType.waive),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => _CountCard(
              title: 'Absent with Permission',
              code: 'AP',
              codeColor: _permissionColor,
              count: controller.countOf(AttendanceType.absentWithPermission),
              centered: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: RequestColors.textPrimary,
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: RequestColors.textPrimary,
        ),
      ),
    );
  }
}

/// Card with a title, a colored code (A / W / AP), a gold line and the session count.
class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.title,
    required this.code,
    required this.codeColor,
    required this.count,
    this.centered = false,
  });

  final String title;
  final String code;
  final Color codeColor;
  final int count;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: RequestColors.softSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: centered
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: RequestColors.textPrimary,
                  ),
                ),
              ),
              Text(
                code,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: codeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(height: 2, color: _lineColor),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$count',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(text: count == 1 ? ' Session' : ' Sessions'),
              ],
            ),
            style: const TextStyle(
              fontSize: 12,
              color: RequestColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
