import 'dart:async';

import 'package:bcreative_ems/core/errors/failure_mapper.dart';
import 'package:bcreative_ems/features/employees/models/employee_model.dart';
import 'package:bcreative_ems/features/projects/models/project_model.dart';
import 'package:bcreative_ems/features/projects/repositories/project_repository.dart';
import 'package:bcreative_ems/features/tasks/models/employee_task_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProjectController extends GetxController {
  ProjectController(this._repository);

  final ProjectRepository _repository;

  final projects = <ProjectModel>[].obs;
  final employees = <EmployeeModel>[].obs;
  final tasks = <EmployeeTaskModel>[].obs;
  final isLoading = true.obs;
  final isSaving = false.obs;
  final isEditorOpen = false.obs;
  final selectedProjectId = RxnString();
  final editingProjectId = RxnString();

  final searchQuery = ''.obs;
  final departmentFilter = RxnString();
  final statusFilter = Rxn<ProjectStatus>();
  final priorityFilter = Rxn<ProjectPriority>();

  final projectNameController = TextEditingController();
  final searchController = TextEditingController();
  final clientController = TextEditingController();
  final descriptionController = TextEditingController();
  final categoryController = TextEditingController();
  final formDepartment = RxnString();
  final formPriority = ProjectPriority.medium.obs;
  final formStatus = ProjectStatus.inProgress.obs;
  final startDate = Rxn<DateTime>();
  final endDate = Rxn<DateTime>();
  final assignedEmployeeIds = <String>{}.obs;

  StreamSubscription<List<ProjectModel>>? _projectsSubscription;
  StreamSubscription<List<EmployeeTaskModel>>? _tasksSubscription;
  StreamSubscription<List<EmployeeModel>>? _employeesSubscription;

  @override
  void onInit() {
    super.onInit();
    _listenToProjects();
    _listenToTasks();
    _listenToEmployees();
  }

  List<String> get departments {
    final values = <String>{
      ...employees.map((employee) => employee.department?.trim() ?? ''),
      ...projects.map((project) => project.department.trim()),
    }..removeWhere((value) => value.isEmpty);
    final result = values.toList()..sort();
    return result;
  }

  List<ProjectModel> get filteredProjects {
    final term = searchQuery.value.trim().toLowerCase();
    return projects.where((project) {
      final matchText =
          term.isEmpty ||
          project.name.toLowerCase().contains(term) ||
          project.client.toLowerCase().contains(term) ||
          project.description.toLowerCase().contains(term) ||
          project.department.toLowerCase().contains(term);
      return matchText &&
          (departmentFilter.value == null ||
              project.department == departmentFilter.value) &&
          (statusFilter.value == null ||
              effectiveStatus(project) == statusFilter.value) &&
          (priorityFilter.value == null ||
              project.priority == priorityFilter.value);
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

  int get totalProjects => projects.length;

  int get activeProjects => projects
      .where(
        (project) => switch (effectiveStatus(project)) {
          ProjectStatus.inProgress || ProjectStatus.notStarted => true,
          _ => false,
        },
      )
      .length;

  int get completedProjects => projects
      .where((project) => effectiveStatus(project) == ProjectStatus.completed)
      .length;

  int get onHoldProjects => projects
      .where((project) => effectiveStatus(project) == ProjectStatus.onHold)
      .length;

  List<EmployeeTaskModel> tasksFor(ProjectModel project) =>
      tasks.where((task) => task.projectId == project.id).toList();

  int taskCountFor(ProjectModel project) => tasksFor(project).length;

  int completedTaskCountFor(ProjectModel project) =>
      tasksFor(project)
          .where((task) => task.status == EmployeeTaskStatus.completed)
          .length;

  int progressFor(ProjectModel project) {
    final projectTasks = tasksFor(project);
    if (projectTasks.isEmpty) return 0;
    return ((projectTasks
                    .where(
                      (task) => task.status == EmployeeTaskStatus.completed,
                    )
                    .length /
                projectTasks.length) *
            100)
        .round();
  }

  /// Task completion is the source of truth for project progress. A paused or
  /// cancelled project retains its manual state; a fully completed task set
  /// automatically appears completed in the dashboard.
  ProjectStatus effectiveStatus(ProjectModel project) {
    if (project.status == ProjectStatus.onHold ||
        project.status == ProjectStatus.cancelled) {
      return project.status;
    }
    final total = taskCountFor(project);
    if (total > 0 && progressFor(project) == 100) {
      return ProjectStatus.completed;
    }
    if (project.status == ProjectStatus.completed) {
      return total == 0 ? ProjectStatus.notStarted : ProjectStatus.inProgress;
    }
    return project.status;
  }

  void setQuery(String value) => searchQuery.value = value;

  void setDepartmentFilter(String? value) => departmentFilter.value = value;

  void setStatusFilter(ProjectStatus? value) => statusFilter.value = value;

  void setPriorityFilter(ProjectPriority? value) =>
      priorityFilter.value = value;

  void resetFilters() {
    searchQuery.value = '';
    searchController.clear();
    departmentFilter.value = null;
    statusFilter.value = null;
    priorityFilter.value = null;
  }

  void selectProject(ProjectModel project) {
    selectedProjectId.value = project.id;
    isEditorOpen.value = false;
  }

  void openCreateProject() {
    editingProjectId.value = null;
    selectedProjectId.value = null;
    projectNameController.clear();
    clientController.clear();
    descriptionController.clear();
    categoryController.clear();
    formDepartment.value = null;
    formPriority.value = ProjectPriority.medium;
    formStatus.value = ProjectStatus.inProgress;
    startDate.value = DateTime.now();
    endDate.value = null;
    assignedEmployeeIds.clear();
    isEditorOpen.value = true;
  }

  void openEditProject(ProjectModel project) {
    editingProjectId.value = project.id;
    selectedProjectId.value = project.id;
    projectNameController.text = project.name;
    clientController.text = project.client;
    descriptionController.text = project.description;
    categoryController.text = project.category;
    formDepartment.value = project.department.isEmpty
        ? null
        : project.department;
    formPriority.value = project.priority;
    formStatus.value = project.status;
    startDate.value = project.startDate;
    endDate.value = project.endDate;
    assignedEmployeeIds.assignAll(project.employeeIds);
    isEditorOpen.value = true;
  }

  void closeEditor() {
    isEditorOpen.value = false;
    editingProjectId.value = null;
  }

  void toggleEmployee(String employeeId, bool selected) {
    if (selected) {
      assignedEmployeeIds.add(employeeId);
    } else {
      assignedEmployeeIds.remove(employeeId);
    }
    assignedEmployeeIds.refresh();
  }

  Future<void> pickStartDate(BuildContext context) async {
    final picked = await _pickDate(context, startDate.value ?? DateTime.now());
    if (picked == null) return;
    startDate.value = picked;
    if (endDate.value != null && endDate.value!.isBefore(picked)) {
      endDate.value = null;
    }
  }

  Future<void> pickEndDate(BuildContext context) async {
    final picked = await _pickDate(
      context,
      endDate.value ?? startDate.value ?? DateTime.now(),
      firstDate: startDate.value,
    );
    if (picked != null) endDate.value = picked;
  }

  Future<void> saveProject() async {
    final name = projectNameController.text.trim();
    final department = formDepartment.value?.trim() ?? '';
    if (name.isEmpty || department.isEmpty) {
      Get.snackbar(
        'Missing details',
        'Project name and department are required.',
      );
      return;
    }
    if (endDate.value != null &&
        startDate.value != null &&
        endDate.value!.isBefore(startDate.value!)) {
      Get.snackbar('Check dates', 'End date must be after the start date.');
      return;
    }

    final memberIds = assignedEmployeeIds.toList();
    final memberLookup = {
      for (final employee in employees) employee.id: employee,
    };
    final members = memberIds.where(memberLookup.containsKey).map((id) {
      final employee = memberLookup[id]!;
      return ProjectTeamMember(
        employeeId: employee.id,
        name: employee.fullName,
        jobTitle: employee.jobTitle,
        department: employee.department,
        profilePhotoUrl: employee.displayPhotoUrl,
      );
    }).toList();

    final editingId = editingProjectId.value;
    final existing = selectedProject;
    final project = ProjectModel(
      id: editingId ?? '',
      name: name,
      client: clientController.text,
      description: descriptionController.text,
      department: department,
      category: categoryController.text,
      priority: formPriority.value,
      status: formStatus.value,
      employeeIds: memberIds,
      teamMembers: members,
      startDate: startDate.value,
      endDate: endDate.value,
      createdBy: existing?.createdBy,
      createdAt: existing?.createdAt,
    );

    isSaving.value = true;
    try {
      if (editingId == null) {
        await _repository.createProject(project);
        Get.snackbar('Project created', 'Team members can now see their work.');
      } else {
        await _repository.updateProject(project);
        Get.snackbar('Project updated', 'Project details were saved.');
      }
      isEditorOpen.value = false;
    } catch (error) {
      Get.snackbar('Project not saved', FailureMapper.message(error));
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> removeProject(ProjectModel project) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete project?'),
        content: Text(
          '"${project.name}" will be removed. Existing tasks are kept.',
        ),
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
      await _repository.deleteProject(project.id);
      if (selectedProjectId.value == project.id) selectedProjectId.value = null;
      Get.snackbar('Project deleted', 'The project was removed.');
    } catch (error) {
      Get.snackbar('Project not deleted', FailureMapper.message(error));
    }
  }

  void _listenToProjects() {
    _projectsSubscription = _repository.watchAllProjects().listen(
      (items) {
        projects.assignAll(items);
        final selected = selectedProjectId.value;
        if (selected != null &&
            !items.any((project) => project.id == selected)) {
          selectedProjectId.value = null;
        }
        isLoading.value = false;
      },
      onError: (Object error) {
        isLoading.value = false;
        Get.snackbar('Projects unavailable', FailureMapper.message(error));
      },
    );
  }

  void _listenToTasks() {
    _tasksSubscription = _repository.watchAllTasks().listen(
      tasks.assignAll,
      onError: (Object error) => Get.snackbar(
        'Task progress unavailable',
        FailureMapper.message(error),
      ),
    );
  }

  void _listenToEmployees() {
    _employeesSubscription = _repository.watchActiveEmployees().listen(
      employees.assignAll,
      onError: (Object error) =>
          Get.snackbar('Employees unavailable', FailureMapper.message(error)),
    );
  }

  Future<DateTime?> _pickDate(
    BuildContext context,
    DateTime initialDate, {
    DateTime? firstDate,
  }) => showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate ?? DateTime(2020),
    lastDate: DateTime(2100),
  );

  @override
  void onClose() {
    _projectsSubscription?.cancel();
    _tasksSubscription?.cancel();
    _employeesSubscription?.cancel();
    projectNameController.dispose();
    searchController.dispose();
    clientController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    super.onClose();
  }
}
