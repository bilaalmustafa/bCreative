import 'package:bcreative_ems/features/auth/viewmodels/auth_controller.dart';
import 'package:bcreative_ems/features/shell/viewmodels/shell_controller.dart';
import 'package:bcreative_ems/features/tasks/repositories/task_repository.dart';
import 'package:bcreative_ems/features/tasks/viewmodels/task_controller.dart';
import 'package:get/get.dart';

class TaskBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(ShellController.new);
    Get.lazyPut(TaskRepository.new);
    Get.lazyPut(
      () => TaskController(
        Get.find<TaskRepository>(),
        Get.find<AuthController>(),
      ),
    );
  }
}
