import 'package:bcreative_ems/features/auth/viewmodels/auth_controller.dart';
import 'package:bcreative_ems/features/projects/repositories/project_repository.dart';
import 'package:bcreative_ems/features/projects/viewmodels/employee_projects_controller.dart';
import 'package:bcreative_ems/features/projects/viewmodels/project_controller.dart';
import 'package:bcreative_ems/features/shell/viewmodels/shell_controller.dart';
import 'package:get/get.dart';

class ProjectBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(ShellController.new);
    Get.lazyPut(ProjectRepository.new);
    Get.lazyPut(() => ProjectController(Get.find<ProjectRepository>()));
  }
}

class EmployeeProjectsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(ShellController.new);
    Get.lazyPut(ProjectRepository.new);
    Get.lazyPut(
      () => EmployeeProjectsController(
        Get.find<ProjectRepository>(),
        Get.find<AuthController>(),
      ),
    );
  }
}
