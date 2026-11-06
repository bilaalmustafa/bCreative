import 'package:bcreative_ems/features/auth/viewmodels/auth_controller.dart';
import 'package:bcreative_ems/features/profile/repositories/employee_profile_repository.dart';
import 'package:bcreative_ems/features/profile/viewmodels/employee_profile_controller.dart';
import 'package:bcreative_ems/features/shell/viewmodels/shell_controller.dart';
import 'package:get/get.dart';

class EmployeeProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(ShellController.new);
    Get.lazyPut(EmployeeProfileRepository.new);
    Get.lazyPut(
      () => EmployeeProfileController(
        Get.find<EmployeeProfileRepository>(),
        Get.find<AuthController>(),
      ),
    );
  }
}
