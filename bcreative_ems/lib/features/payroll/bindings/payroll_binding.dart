import 'package:bcreative_ems/features/payroll/repositories/payroll_repository.dart';
import 'package:bcreative_ems/features/payroll/viewmodels/employee_salary_controller.dart';
import 'package:bcreative_ems/features/payroll/viewmodels/payroll_controller.dart';
import 'package:bcreative_ems/features/auth/viewmodels/auth_controller.dart';
import 'package:bcreative_ems/features/shell/viewmodels/shell_controller.dart';
import 'package:get/get.dart';

class PayrollBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(ShellController.new);
    Get.lazyPut(PayrollRepository.new);
    Get.lazyPut(() => PayrollController(Get.find<PayrollRepository>()));
  }
}

class EmployeeSalaryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(ShellController.new);
    Get.lazyPut(PayrollRepository.new);
    Get.lazyPut(
      () => EmployeeSalaryController(
        Get.find<PayrollRepository>(),
        Get.find<AuthController>(),
      ),
    );
  }
}
