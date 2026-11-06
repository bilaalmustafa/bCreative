import 'package:bcreative_ems/features/attendance/repositories/attendance_repository.dart';
import 'package:bcreative_ems/features/attendance/viewmodels/attendance_controller.dart';
import 'package:bcreative_ems/features/attendance/viewmodels/employee_attendance_controller.dart';
import 'package:bcreative_ems/features/auth/viewmodels/auth_controller.dart';
import 'package:bcreative_ems/features/profile/repositories/employee_profile_repository.dart';
import 'package:bcreative_ems/features/shell/viewmodels/shell_controller.dart';
import 'package:get/get.dart';

class AttendanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(ShellController.new);
    Get.lazyPut(AttendanceRepository.new);
    Get.lazyPut(() => AttendanceController(Get.find<AttendanceRepository>()));
  }
}

class EmployeeAttendanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(ShellController.new);
    Get.lazyPut(AttendanceRepository.new);
    Get.lazyPut(EmployeeProfileRepository.new);
    Get.lazyPut(
      () => EmployeeAttendanceController(
        Get.find<AttendanceRepository>(),
        Get.find<EmployeeProfileRepository>(),
        Get.find<AuthController>(),
      ),
    );
  }
}
