import 'dart:async';

import 'package:bcreative_ems/core/errors/failure_mapper.dart';
import 'package:bcreative_ems/features/employees/models/employee_model.dart';
import 'package:bcreative_ems/features/employees/models/employment_enums.dart';
import 'package:bcreative_ems/features/employees/repositories/employee_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum EmployeeComposerMode { create, view, edit }

class EmployeeListController extends GetxController {
  EmployeeListController(this._repository);

  final EmployeeRepository _repository;

  static const int pageSize = 10;

  final searchController = TextEditingController();
  final RxList<EmployeeModel> employees = <EmployeeModel>[].obs;
  final RxList<EmployeeModel> _allEmployees = <EmployeeModel>[].obs;
  final RxBool isLoading = true.obs;
  final Rxn<EmploymentStatus> statusFilter = Rxn<EmploymentStatus>();
  final RxnString departmentFilter = RxnString();
  final Rxn<EmploymentType> employmentTypeFilter = Rxn<EmploymentType>();
  final Rxn<EmployeeOverviewStats> overview = Rxn<EmployeeOverviewStats>();
  final RxInt currentPage = 0.obs;
  final RxBool isComposerOpen = true.obs;
  final RxBool composerWasRequested = false.obs;
  final RxInt composerTab = 0.obs;
  final Rx<EmployeeComposerMode> composerMode = EmployeeComposerMode.create.obs;
  final Rxn<EmployeeModel> selectedEmployee = Rxn<EmployeeModel>();

  StreamSubscription<List<EmployeeModel>>? _employeesSubscription;
  StreamSubscription<EmployeeOverviewStats>? _overviewSubscription;
  Timer? _searchDebounce;

  List<String> get departments =>
      _allEmployees
          .map((employee) => employee.department?.trim() ?? '')
          .where((department) => department.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

  int get filteredCount => _filteredEmployees().length;
  List<EmployeeModel> get filteredEmployees => _filteredEmployees();
  int get pageCount =>
      (filteredCount / pageSize).ceil().clamp(1, 999999).toInt();
  bool get hasMore => currentPage.value < pageCount - 1;
  bool get hasPrevious => currentPage.value > 0;
  int get showingStart =>
      filteredCount == 0 ? 0 : currentPage.value * pageSize + 1;
  int get showingEnd => (currentPage.value * pageSize + employees.length)
      .clamp(0, filteredCount)
      .toInt();

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
    _employeesSubscription = _repository.watchAll().listen(
      (items) {
        _allEmployees.assignAll(items);
        _refreshSelectedEmployee(items);
        _applyFilters();
        isLoading.value = false;
        unawaited(_synchronizeProfileProjections(items));
      },
      onError: (Object error) {
        isLoading.value = false;
        Get.snackbar('Employees unavailable', FailureMapper.message(error));
      },
    );
    _overviewSubscription = _repository.watchOverview().listen(
      (stats) => overview.value = stats,
      onError: (Object error) => Get.snackbar(
        'Employee totals unavailable',
        FailureMapper.message(error),
      ),
    );
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      currentPage.value = 0;
      _applyFilters();
    });
  }

  Future<void> _synchronizeProfileProjections(List<EmployeeModel> items) async {
    try {
      await _repository.synchronizeProfileProjections(items);
    } catch (_) {
      // This is a non-blocking backfill. Employee management stays usable if
      // a projection sync is temporarily unavailable.
    }
  }

  void setStatusFilter(EmploymentStatus? status) {
    statusFilter.value = status;
    currentPage.value = 0;
    _applyFilters();
  }

  void setDepartmentFilter(String? department) {
    departmentFilter.value = department?.trim().isEmpty ?? true
        ? null
        : department!.trim();
    currentPage.value = 0;
    _applyFilters();
  }

  void setEmploymentTypeFilter(EmploymentType? type) {
    employmentTypeFilter.value = type;
    currentPage.value = 0;
    _applyFilters();
  }

  void clearFilters() {
    searchController.clear();
    statusFilter.value = null;
    departmentFilter.value = null;
    employmentTypeFilter.value = null;
    currentPage.value = 0;
    _applyFilters();
  }

  void goToPage(int page) {
    final target = page.clamp(0, pageCount - 1).toInt();
    currentPage.value = target;
    _applyFilters();
  }

  void nextPage() => goToPage(currentPage.value + 1);
  void previousPage() => goToPage(currentPage.value - 1);

  void openComposer({int tab = 0}) {
    selectedEmployee.value = null;
    composerMode.value = EmployeeComposerMode.create;
    composerTab.value = tab;
    composerWasRequested.value = true;
    isComposerOpen.value = true;
  }

  void closeComposer() {
    isComposerOpen.value = false;
    composerWasRequested.value = false;
    selectedEmployee.value = null;
    composerMode.value = EmployeeComposerMode.create;
  }

  void selectComposerTab(int index) => composerTab.value = index;

  bool get isViewingEmployee => composerMode.value == EmployeeComposerMode.view;
  bool get isEditingEmployee => composerMode.value == EmployeeComposerMode.edit;
  bool get hasSelectedEmployee => selectedEmployee.value != null;

  void viewEmployee(EmployeeModel employee, {int tab = 0}) {
    selectedEmployee.value = employee;
    composerMode.value = EmployeeComposerMode.view;
    composerTab.value = tab;
    composerWasRequested.value = true;
    isComposerOpen.value = true;
  }

  void editSelectedEmployee() {
    if (selectedEmployee.value == null) return;
    composerMode.value = EmployeeComposerMode.edit;
  }

  void showSelectedEmployee() {
    if (selectedEmployee.value == null) return;
    composerMode.value = EmployeeComposerMode.view;
  }

  void _refreshSelectedEmployee(List<EmployeeModel> items) {
    final selected = selectedEmployee.value;
    if (selected == null) return;
    for (final employee in items) {
      if (employee.id == selected.id) {
        selectedEmployee.value = employee;
        return;
      }
    }
    selectedEmployee.value = null;
    if (composerMode.value != EmployeeComposerMode.create) {
      closeComposer();
    }
  }

  void _applyFilters() {
    final filtered = _filteredEmployees();
    final maxPage = (filtered.length / pageSize).ceil() - 1;
    if (currentPage.value > maxPage && maxPage >= 0) {
      currentPage.value = maxPage;
    }
    final start = currentPage.value * pageSize;
    employees.assignAll(
      start >= filtered.length
          ? const <EmployeeModel>[]
          : filtered.skip(start).take(pageSize),
    );
  }

  List<EmployeeModel> _filteredEmployees() {
    final searchTerm = searchController.text.trim().toLowerCase();
    return _allEmployees
        .where((employee) {
          final matchesSearch =
              searchTerm.isEmpty ||
              employee.fullNameLower.contains(searchTerm) ||
              employee.email.toLowerCase().contains(searchTerm) ||
              (employee.employeeCode.toLowerCase().contains(searchTerm)) ||
              (employee.department?.toLowerCase().contains(searchTerm) ??
                  false) ||
              (employee.jobTitle?.toLowerCase().contains(searchTerm) ?? false);
          final matchesStatus =
              statusFilter.value == null ||
              employee.employmentStatus == statusFilter.value;
          final matchesDepartment =
              departmentFilter.value == null ||
              employee.department?.trim() == departmentFilter.value;
          final matchesType =
              employmentTypeFilter.value == null ||
              employee.employmentType == employmentTypeFilter.value;
          return matchesSearch &&
              matchesStatus &&
              matchesDepartment &&
              matchesType;
        })
        .toList(growable: false);
  }

  @override
  void onClose() {
    _employeesSubscription?.cancel();
    _overviewSubscription?.cancel();
    _searchDebounce?.cancel();
    searchController.dispose();
    super.onClose();
  }
}
