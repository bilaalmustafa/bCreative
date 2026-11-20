import 'dart:async';

import 'package:bcreative_ems/core/errors/failure_mapper.dart';
import 'package:bcreative_ems/features/attendance/models/attendance_record_model.dart';
import 'package:bcreative_ems/features/dashboard/repositories/dashboard_repository.dart';
import 'package:bcreative_ems/features/employees/models/employee_model.dart';
import 'package:bcreative_ems/features/payroll/models/payroll_record_model.dart';
import 'package:bcreative_ems/features/projects/models/project_model.dart';
import 'package:bcreative_ems/features/tasks/models/employee_task_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardController extends GetxController {
  DashboardController(this._repository);

  final DashboardRepository _repository;

  final isLoading = true.obs;
  final errorMessage = RxnString();
  final selectedRange = _currentMonthRange().obs;
  final employees = <EmployeeModel>[].obs;
  final attendanceRecords = <AttendanceRecordModel>[].obs;
  final payrollRecords = <PayrollRecordModel>[].obs;
  final projects = <ProjectModel>[].obs;
  final tasks = <EmployeeTaskModel>[].obs;

  final Set<String> _loadedSources = <String>{};
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  List<EmployeeModel> get activeEmployees =>
      employees.where((employee) => employee.isActive).toList(growable: false);

  int get totalEmployees => employees.length;
  int get eligibleEmployeeCount => activeEmployees.length;
  int get activeProjects => projects
      .where((project) => project.status == ProjectStatus.inProgress)
      .length;
  int get totalTasks => tasks.length;

  String get selectedPeriodKey =>
      '${selectedRange.value.start.year.toString().padLeft(4, '0')}-'
      '${selectedRange.value.start.month.toString().padLeft(2, '0')}';

  double get selectedMonthPayroll => payrollRecords
      .where((record) => record.periodKey == selectedPeriodKey)
      .fold<double>(0, (total, record) => total + record.netSalary);

  int get checkedInToday {
    final today = _day(DateTime.now());
    return attendanceRecords
        .where(
          (record) => _sameDay(record.date, today) && record.checkIn != null,
        )
        .map((record) => record.employeeId)
        .toSet()
        .length;
  }

  List<ProjectProgressItem> get projectProgress => projects
      .map((project) {
        final linkedTasks = tasks
            .where((task) => task.projectId == project.id)
            .toList(growable: false);
        final complete = linkedTasks
            .where((task) => task.status == EmployeeTaskStatus.completed)
            .length;
        return ProjectProgressItem(
          project: project,
          completedTasks: complete,
          totalTasks: linkedTasks.length,
        );
      })
      .toList(growable: false);

  TaskStatusSummary get taskStatus {
    final today = _day(DateTime.now());
    final overdueIds = tasks
        .where((task) {
          final dueDate = task.dueDate;
          return task.status != EmployeeTaskStatus.completed &&
              dueDate != null &&
              _day(dueDate).isBefore(today);
        })
        .map((task) => task.id)
        .toSet();
    return TaskStatusSummary(
      completed: tasks
          .where((task) => task.status == EmployeeTaskStatus.completed)
          .length,
      inProgress: tasks
          .where(
            (task) =>
                task.status == EmployeeTaskStatus.inProgress &&
                !overdueIds.contains(task.id),
          )
          .length,
      pending: tasks
          .where(
            (task) =>
                task.status == EmployeeTaskStatus.assigned &&
                !overdueIds.contains(task.id),
          )
          .length,
      overdue: overdueIds.length,
    );
  }

  AttendanceSummary get attendanceSummary {
    final range = selectedRange.value;
    return _attendanceForPeriod(
      _day(range.start),
      _latestAvailableDate(range.end),
    );
  }

  List<AttendanceTrendPoint> get attendanceTrend {
    final range = selectedRange.value;
    final end = _latestAvailableDate(range.end);
    final start = _day(range.start);
    if (end.isBefore(start)) return const [];

    final firstDate = end.subtract(const Duration(days: 6));
    final visibleStart = firstDate.isBefore(start) ? start : firstDate;
    final dayCount = end.difference(visibleStart).inDays + 1;
    return List<AttendanceTrendPoint>.generate(dayCount, (index) {
      final date = visibleStart.add(Duration(days: index));
      final summary = _attendanceForDate(date);
      return AttendanceTrendPoint(
        date: date,
        checkedIn: summary.attended,
        totalEmployees: summary.records,
      );
    });
  }

  int projectStatusCount(ProjectStatus status) =>
      projects.where((project) => project.status == status).length;

  void setDateRange(DateTimeRange range) {
    final start = _day(range.start);
    final end = _day(range.end);
    if (!end.isBefore(start)) {
      selectedRange.value = DateTimeRange(start: start, end: end);
    }
  }

  void resetToCurrentMonth() => selectedRange.value = _currentMonthRange();

  @override
  void onInit() {
    super.onInit();
    _watch<EmployeeModel>(
      'employees',
      _repository.watchEmployees(),
      employees.assignAll,
    );
    _watch<AttendanceRecordModel>(
      'attendance',
      _repository.watchAttendanceRecords(),
      attendanceRecords.assignAll,
    );
    _watch<PayrollRecordModel>(
      'payroll',
      _repository.watchPayrollRecords(),
      payrollRecords.assignAll,
    );
    _watch<ProjectModel>(
      'projects',
      _repository.watchProjects(),
      projects.assignAll,
    );
    _watch<EmployeeTaskModel>(
      'tasks',
      _repository.watchTasks(),
      tasks.assignAll,
    );
  }

  void _watch<T>(
    String source,
    Stream<List<T>> stream,
    void Function(List<T>) update,
  ) {
    _subscriptions.add(
      stream.listen(
        (items) {
          update(items);
          _loadedSources.add(source);
          if (_loadedSources.length == 5) isLoading.value = false;
        },
        onError: (Object error) {
          _loadedSources.add(source);
          errorMessage.value = FailureMapper.message(error);
          if (_loadedSources.length == 5) isLoading.value = false;
        },
      ),
    );
  }

  /// Builds the dashboard figures from the same employee/day status used by
  /// Attendance Management. A missing record is an absence, so the pie does
  /// not incorrectly report 100% attendance just because absent staff do not
  /// have Firestore documents for that day.
  AttendanceSummary _attendanceForPeriod(DateTime start, DateTime end) {
    if (end.isBefore(start)) return AttendanceSummary.empty;

    var present = 0;
    var late = 0;
    var absent = 0;
    for (
      var date = start;
      !date.isAfter(end);
      date = date.add(const Duration(days: 1))
    ) {
      final daily = _attendanceForDate(date);
      present += daily.present;
      late += daily.late;
      absent += daily.absent;
    }
    return AttendanceSummary(present: present, late: late, absent: absent);
  }

  AttendanceSummary _attendanceForDate(DateTime date) {
    final eligible = _eligibleEmployeesOn(date);
    if (eligible.isEmpty) return AttendanceSummary.empty;

    final eligibleIds = eligible.map((employee) => employee.id).toSet();
    final recordsByEmployee = <String, AttendanceRecordModel>{
      for (final record in attendanceRecords)
        if (_sameDay(record.date, date) &&
            eligibleIds.contains(record.employeeId))
          record.employeeId: record,
    };

    var present = 0;
    var late = 0;
    var absent = 0;
    for (final employee in eligible) {
      switch (recordsByEmployee[employee.id]?.status) {
        case AttendanceStatus.present:
          present++;
        case AttendanceStatus.late:
          late++;
        case AttendanceStatus.absent:
        case null:
          absent++;
      }
    }
    return AttendanceSummary(present: present, late: late, absent: absent);
  }

  List<EmployeeModel> _eligibleEmployeesOn(DateTime date) {
    final day = _day(date);
    return activeEmployees
        .where((employee) {
          final joiningDate = employee.joiningDate;
          return joiningDate == null || !_day(joiningDate).isAfter(day);
        })
        .toList(growable: false);
  }

  static DateTime _latestAvailableDate(DateTime rangeEnd) {
    final today = _day(DateTime.now());
    final end = _day(rangeEnd);
    return end.isAfter(today) ? today : end;
  }

  static DateTimeRange _currentMonthRange() {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month),
      end: DateTime(now.year, now.month + 1, 0),
    );
  }

  static DateTime _day(DateTime date) =>
      DateTime(date.year, date.month, date.day);
  static bool _sameDay(DateTime first, DateTime second) =>
      _day(first) == _day(second);

  @override
  void onClose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.onClose();
  }
}

class ProjectProgressItem {
  const ProjectProgressItem({
    required this.project,
    required this.completedTasks,
    required this.totalTasks,
  });

  final ProjectModel project;
  final int completedTasks;
  final int totalTasks;

  double get progress =>
      totalTasks == 0 ? 0 : completedTasks.clamp(0, totalTasks) / totalTasks;
}

class TaskStatusSummary {
  const TaskStatusSummary({
    required this.completed,
    required this.inProgress,
    required this.pending,
    required this.overdue,
  });

  final int completed;
  final int inProgress;
  final int pending;
  final int overdue;

  int get total => completed + inProgress + pending + overdue;
}

class AttendanceSummary {
  const AttendanceSummary({
    required this.present,
    required this.late,
    required this.absent,
  });

  static const empty = AttendanceSummary(present: 0, late: 0, absent: 0);

  final int present;
  final int late;
  final int absent;

  int get records => present + late + absent;
  int get attended => present + late;
  double get percentage => records == 0 ? 0 : (attended / records) * 100;
}

class AttendanceTrendPoint {
  const AttendanceTrendPoint({
    required this.date,
    required this.checkedIn,
    required this.totalEmployees,
  });

  final DateTime date;
  final int checkedIn;
  final int totalEmployees;

  double get percentage =>
      totalEmployees == 0 ? 0 : (checkedIn / totalEmployees) * 100;
}
