import 'dart:async';

import 'package:bcreative_ems/core/errors/failure_mapper.dart';
import 'package:bcreative_ems/features/auth/viewmodels/auth_controller.dart';
import 'package:bcreative_ems/features/projects/models/project_model.dart';
import 'package:bcreative_ems/features/projects/repositories/project_repository.dart';
import 'package:bcreative_ems/features/tasks/models/employee_task_model.dart';
import 'package:get/get.dart';

class EmployeeProjectsController extends GetxController {
  EmployeeProjectsController(this._repository, this._auth);

  final ProjectRepository _repository;
  final AuthController _auth;

  final projects = <ProjectModel>[].obs;
  final tasks = <EmployeeTaskModel>[].obs;
  final isLoading = true.obs;
  final searchQuery = ''.obs;
  final statusFilter = Rxn<ProjectStatus>();
  final selectedProjectId = RxnString();

  StreamSubscription<List<ProjectModel>>? _projectsSubscription;
  StreamSubscription<List<EmployeeTaskModel>>? _tasksSubscription;

  String get employeeId => _auth.session.value?.employeeId ?? '';

  @override
  void onInit() {
    super.onInit();
    _projectsSubscription = _repository
        .watchProjectsForEmployee(employeeId)
        .listen(
          (items) {
            projects.assignAll(items);
            if (selectedProjectId.value != null &&
                !items.any(
                  (project) => project.id == selectedProjectId.value,
                )) {
              selectedProjectId.value = null;
            }
            isLoading.value = false;
          },
          onError: (Object error) {
            isLoading.value = false;
            Get.snackbar('Projects unavailable', FailureMapper.message(error));
          },
        );
    _tasksSubscription = _repository
        .watchTasksForEmployee(employeeId)
        .listen(
          tasks.assignAll,
          onError: (Object error) =>
              Get.snackbar('Tasks unavailable', FailureMapper.message(error)),
        );
  }

  List<ProjectModel> get visibleProjects {
    final query = searchQuery.value.trim().toLowerCase();
    return projects.where((project) {
      return (query.isEmpty ||
              project.name.toLowerCase().contains(query) ||
              project.client.toLowerCase().contains(query) ||
              project.department.toLowerCase().contains(query)) &&
          (statusFilter.value == null ||
              effectiveStatus(project) == statusFilter.value);
    }).toList();
  }

  ProjectModel? get selectedProject {
    final id = selectedProjectId.value;
    if (id == null) return null;
    for (final project in projects) {
      if (project.id == id) return project;
    }
    return null;
  }

  List<EmployeeTaskModel> tasksFor(ProjectModel project) =>
      tasks.where((task) => task.projectId == project.id).toList();

  int progressFor(ProjectModel project) {
    final relatedTasks = tasksFor(project);
    if (relatedTasks.isEmpty) return 0;
    return ((relatedTasks
                    .where(
                      (task) => task.status == EmployeeTaskStatus.completed,
                    )
                    .length /
                relatedTasks.length) *
            100)
        .round();
  }

  ProjectStatus effectiveStatus(ProjectModel project) {
    if (project.status == ProjectStatus.onHold ||
        project.status == ProjectStatus.cancelled) {
      return project.status;
    }
    final relatedTasks = tasksFor(project);
    if (relatedTasks.isNotEmpty && progressFor(project) == 100) {
      return ProjectStatus.completed;
    }
    if (project.status == ProjectStatus.completed) {
      return relatedTasks.isEmpty
          ? ProjectStatus.notStarted
          : ProjectStatus.inProgress;
    }
    return project.status;
  }

  int get activeProjectCount => projects
      .where(
        (project) => switch (effectiveStatus(project)) {
          ProjectStatus.inProgress || ProjectStatus.notStarted => true,
          _ => false,
        },
      )
      .length;

  int get completedProjectCount => projects
      .where((project) => effectiveStatus(project) == ProjectStatus.completed)
      .length;

  int get myTaskCount => tasks.length;

  void selectProject(ProjectModel project) =>
      selectedProjectId.value = project.id;

  void resetFilters() {
    searchQuery.value = '';
    statusFilter.value = null;
  }

  @override
  void onClose() {
    _projectsSubscription?.cancel();
    _tasksSubscription?.cancel();
    super.onClose();
  }
}
