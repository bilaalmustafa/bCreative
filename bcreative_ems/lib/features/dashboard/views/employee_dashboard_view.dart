import 'package:bcreative_ems/features/attendance/viewmodels/employee_attendance_controller.dart';
import 'package:bcreative_ems/features/attendance/views/employee_attendance_view.dart';
import 'package:bcreative_ems/features/shell/views/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EmployeeDashboardView extends GetView<EmployeeAttendanceController> {
  const EmployeeDashboardView({super.key});

  @override
  Widget build(BuildContext context) => AppShell(
    title: 'My Dashboard',
    body: EmployeeAttendanceDashboard(controller: controller),
  );
}
