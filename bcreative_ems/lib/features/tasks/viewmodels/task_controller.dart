import 'dart:async';

import 'package:bcreative_ems/core/errors/failure_mapper.dart';
import 'package:bcreative_ems/features/auth/viewmodels/auth_controller.dart';
import 'package:bcreative_ems/features/employees/models/employee_model.dart';
import 'package:bcreative_ems/features/projects/models/project_model.dart';
import 'package:bcreative_ems/features/tasks/models/employee_task_model.dart';
import 'package:bcreative_ems/features/tasks/repositories/task_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TaskController extends GetxController {
  TaskController(this._repository, this._auth);

  final TaskRepository _repository;
  final AuthController _auth;

  final tasks = <EmployeeTaskModel>[].obs;
  final employees = <EmployeeModel>[].obs;
  final projects = <ProjectModel>[].obs;
  final isLoading = true.obs;
  final isSaving = false.obs;
  final isEditorOpen = false.obs;
  final selectedTaskId = RxnString();
  final editingTaskId = RxnString();

  final searchQuery = ''.obs;
  final projectFilter = RxnString();
  final employeeFilter = RxnString();
  final priorityFilter = Rxn<TaskPriority>();
  final statusFilter = Rxn<EmployeeTaskStatus>();
  final overdueOnly = false.obs;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final taskTypeController = TextEditingController();
  final labelsController = TextEditingController();
  final estimatedHoursController = TextEditingController();
  final searchController = TextEditingController();
  final formProjectId = RxnString();
  final formEmployeeId = RxnString();
  final formPriority = TaskPriority.medium.obs;
  final formStatus = EmployeeTaskStatus.assigned.obs;
  final formProgress = 0.obs;
  final dueDate = Rxn<DateTime>();

  StreamSubscription<List<EmployeeTaskModel>>? _tasksSubscription;
  StreamSubscription<List<EmployeeModel>>? _employeesSubscription;
  StreamSubscription<List<ProjectModel>>? _projectsSubscription;

  bool get isAdmin => _auth.role.isSuperAdmin;
  String? get employeeId => _auth.session.value?.employeeId;

  @override
  void onInit() {
    super.onInit();
    _watchTasks();
    if (isAdmin) {
      _watchAssignableEmployees();
      _watchAssignableProjects();
    }
  }

  List<EmployeeTaskModel> get filteredTasks {
    final term = searchQuery.value.trim().toLowerCase();
    return tasks.where((task) {
      final matchText =
          term.isEmpty ||
          task.title.toLowerCase().contains(term) ||
          task.description.toLowerCase().contains(term) ||
          (projectName(task.projectId) ?? '').toLowerCase().contains(term) ||
          employeeName(task.employeeId).toLowerCase().contains(term);
      return matchText &&
          (projectFilter.value == null ||
              task.projectId == projectFilter.value) &&
          (employeeFilter.value == null ||
              task.employeeId == employeeFilter.value) &&
          (priorityFilter.value == null ||
              task.priority == priorityFilter.value) &&
          (statusFilter.value == null || task.status == statusFilter.value) &&
          (!overdueOnly.value || isOverdue(task));
    }).toList();
  }

  EmployeeTaskModel? get selectedTask {
    final id = selectedTaskId.value;
    if (id == null) return null;
    for (final task in tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  ProjectModel? projectForId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final project in projects) {
      if (project.id == id) return project;
    }
    return null;
  }

  List<EmployeeModel> get assignableEmployees {
    final project = projectForId(formProjectId.value);
    if (project == null) return const [];
    return employees
        .where((employee) => project.employeeIds.contains(employee.id))
        .toList();
  }

  int get totalTasks => tasks.length;
  int get pendingTasks =>
      tasks.where((task) => task.status == EmployeeTaskStatus.assigned).length;
  int get inProgressTasks => tasks
      .where((task) => task.status == EmployeeTaskStatus.inProgress)
      .length;
  int get completedTasks =>
      tasks.where((task) => task.status == EmployeeTaskStatus.completed).length;
  int get overdueTasks => tasks.where(isOverdue).length;

  bool isOverdue(EmployeeTaskModel task) {
    final due = task.dueDate;
    if (due == null || task.status == EmployeeTaskStatus.completed) {
      return false;
    }
    final today = DateUtils.dateOnly(DateTime.now());
    return DateUtils.dateOnly(due).isBefore(today);
  }

  String employeeName(String id) {
    return employeeForId(id)?.fullName ?? 'Employee';
  }

  EmployeeModel? employeeForId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final employee in employees) {
      if (employee.id == id) return employee;
    }
    return null;
  }

  String? projectName(String? id) => projectForId(id)?.name;

  void setQuery(String value) => searchQuery.value = value;
  void setProjectFilter(String? value) => projectFilter.value = value;
  void setEmployeeFilter(String? value) => employeeFilter.value = value;
  void setPriorityFilter(TaskPriority? value) => priorityFilter.value = value;
  void setStatusFilter(EmployeeTaskStatus? value) => statusFilter.value = value;

  void resetFilters() {
    searchController.clear();
    searchQuery.value = '';
    projectFilter.value = null;
    employeeFilter.value = null;
    priorityFilter.value = null;
    statusFilter.value = null;
    overdueOnly.value = false;
  }

  void selectTask(EmployeeTaskModel task) {
    selectedTaskId.value = task.id;
    isEditorOpen.value = false;
  }

  void openCreateTask() {
    editingTaskId.value = null;
    selectedTaskId.value = null;
    titleController.clear();
    descriptionController.clear();
    taskTypeController.clear();
    labelsController.clear();
    estimatedHoursController.clear();
    formProjectId.value = null;
    formEmployeeId.value = null;
    formPriority.value = TaskPriority.medium;
    formStatus.value = EmployeeTaskStatus.assigned;
    formProgress.value = 0;
    dueDate.value = DateTime.now().add(const Duration(days: 7));
    isEditorOpen.value = true;
  }

  void openEditTask(EmployeeTaskModel task) {
    editingTaskId.value = task.id;
    selectedTaskId.value = task.id;
    titleController.text = task.title;
    descriptionController.text = task.description;
    taskTypeController.text = task.taskType ?? '';
    labelsController.text = task.labels.join(', ');
    estimatedHoursController.text = task.estimatedHours?.toString() ?? '';
    formProjectId.value = task.projectId;
    formEmployeeId.value = task.employeeId;
    formPriority.value = task.priority;
    formStatus.value = task.status;
    formProgress.value = task.progress;
    dueDate.value = task.dueDate;
    isEditorOpen.value = true;
  }

  void closeEditor() {
    editingTaskId.value = null;
    isEditorOpen.value = false;
  }

  void setFormProject(String? projectId) {
    formProjectId.value = projectId;
    final assignedIds =
        projectForId(projectId)?.employeeIds ?? const <String>[];
    if (!assignedIds.contains(formEmployeeId.value)) {
      formEmployeeId.value = null;
    }
  }

  void setFormStatus(EmployeeTaskStatus? status) {
    if (status == null) return;
    formStatus.value = status;
    switch (status) {
      case EmployeeTaskStatus.assigned:
        formProgress.value = 0;
      case EmployeeTaskStatus.inProgress:
        if (formProgress.value == 0 || formProgress.value == 100) {
          formProgress.value = 50;
        }
      case EmployeeTaskStatus.completed:
        formProgress.value = 100;
    }
  }

  void setFormProgress(double value) {
    final progress = value.round().clamp(0, 100);
    formProgress.value = progress;
    if (progress == 0) {
      formStatus.value = EmployeeTaskStatus.assigned;
    } else if (progress == 100) {
      formStatus.value = EmployeeTaskStatus.completed;
    } else {
      formStatus.value = EmployeeTaskStatus.inProgress;
    }
  }

  Future<void> pickDueDate(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: dueDate.value ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) dueDate.value = selected;
  }

  Future<void> saveTask() async {
    final project = projectForId(formProjectId.value);
    final employeeId = formEmployeeId.value;
    if (titleController.text.trim().isEmpty ||
        project == null ||
        employeeId == null ||
        employeeId.isEmpty) {
      Get.snackbar(
        'Missing details',
        'Add a title, project, and assigned employee.',
      );
      return;
    }
    if (!project.employeeIds.contains(employeeId)) {
      Get.snackbar(
        'Choose a team member',
        'Only employees assigned to this project can receive its tasks.',
      );
      return;
    }
    final estimatedHours = num.tryParse(estimatedHoursController.text.trim());
    if (estimatedHours != null && estimatedHours < 0) {
      Get.snackbar('Check hours', 'Estimated hours cannot be negative.');
      return;
    }
    final labels = labelsController.text
        .split(',')
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toSet()
        .toList();
    final task = EmployeeTaskModel(
      id: editingTaskId.value ?? '',
      title: titleController.text,
      description: descriptionController.text,
      employeeId: employeeId,
      assignedBy: selectedTask?.assignedBy ?? '',
      projectId: project.id,
      priority: formPriority.value,
      status: formStatus.value,
      progress: formProgress.value,
      taskType: taskTypeController.text,
      labels: labels,
      estimatedHours: estimatedHours,
      dueDate: dueDate.value,
    );

    isSaving.value = true;
    try {
      if (editingTaskId.value == null) {
        await _repository.createTask(task);
        Get.snackbar('Task created', 'The assignee can now see this task.');
      } else {
        await _repository.updateTask(task);
        Get.snackbar('Task updated', 'Task details were saved.');
      }
      isEditorOpen.value = false;
    } catch (error) {
      Get.snackbar('Task not saved', FailureMapper.message(error));
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteTask(EmployeeTaskModel task) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete task?'),
        content: Text('"${task.title}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.deleteTask(task.id);
      if (selectedTaskId.value == task.id) selectedTaskId.value = null;
      Get.snackbar('Task deleted', 'The task was removed.');
    } catch (error) {
      Get.snackbar('Task not deleted', FailureMapper.message(error));
    }
  }

  Future<void> updateOwnProgress(EmployeeTaskModel task, double value) async {
    final progress = value.round().clamp(0, 100);
    final status = switch (progress) {
      0 => EmployeeTaskStatus.assigned,
      100 => EmployeeTaskStatus.completed,
      _ => EmployeeTaskStatus.inProgress,
    };
    try {
      await _repository.updateTaskProgress(
        task: task,
        status: status,
        progress: progress,
      );
    } catch (error) {
      Get.snackbar('Progress not updated', FailureMapper.message(error));
    }
  }

  Future<void> updateOwnStatus(
    EmployeeTaskModel task,
    EmployeeTaskStatus status,
  ) async {
    final progress = switch (status) {
      EmployeeTaskStatus.assigned => 0,
      EmployeeTaskStatus.inProgress => task.progress.clamp(1, 99),
      EmployeeTaskStatus.completed => 100,
    };
    try {
      await _repository.updateTaskProgress(
        task: task,
        status: status,
        progress: progress,
      );
    } catch (error) {
      Get.snackbar('Status not updated', FailureMapper.message(error));
    }
  }

  void _watchTasks() {
    final stream = isAdmin
        ? _repository.watchAll()
        : _repository.watchForEmployee(employeeId ?? '');
    _tasksSubscription = stream.listen(
      (items) {
        tasks.assignAll(items);
        isLoading.value = false;
      },
      onError: (Object error) {
        isLoading.value = false;
        Get.snackbar('Tasks unavailable', FailureMapper.message(error));
      },
    );
  }

  void _watchAssignableEmployees() {
    _employeesSubscription = _repository.watchAssignableEmployees().listen(
      employees.assignAll,
      onError: (Object error) =>
          Get.snackbar('Employees unavailable', FailureMapper.message(error)),
    );
  }

  void _watchAssignableProjects() {
    _projectsSubscription = _repository.watchAssignableProjects().listen(
      projects.assignAll,
      onError: (Object error) =>
          Get.snackbar('Projects unavailable', FailureMapper.message(error)),
    );
  }

  @override
  void onClose() {
    _tasksSubscription?.cancel();
    _employeesSubscription?.cancel();
    _projectsSubscription?.cancel();
    titleController.dispose();
    descriptionController.dispose();
    taskTypeController.dispose();
    labelsController.dispose();
    estimatedHoursController.dispose();
    searchController.dispose();
    super.onClose();
  }
}
