import 'package:bcreative_ems/features/employees/repositories/employee_repository.dart';
import 'package:bcreative_ems/features/employees/viewmodels/employee_form_controller.dart';
import 'package:bcreative_ems/features/employees/viewmodels/employee_list_controller.dart';
import 'package:bcreative_ems/features/shell/viewmodels/shell_controller.dart';
import 'package:get/get.dart';

class EmployeeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(ShellController.new);
    Get.lazyPut(EmployeeRepository.new);
    Get.lazyPut(() => EmployeeListController(Get.find<EmployeeRepository>()));
    Get.lazyPut(
      () => EmployeeFormController(Get.find<EmployeeRepository>()),
      tag: 'employeeComposer',
    );
  }
}
