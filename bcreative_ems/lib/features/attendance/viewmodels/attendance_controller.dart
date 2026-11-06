import 'dart:async';

import 'package:bcreative_ems/core/errors/failure_mapper.dart';
import 'package:bcreative_ems/features/attendance/models/attendance_record_model.dart';
import 'package:bcreative_ems/features/attendance/repositories/attendance_repository.dart';
import 'package:bcreative_ems/features/employees/models/employee_model.dart';
import 'package:get/get.dart';

/// Live, admin-only attendance management state. It deliberately creates an
/// empty row for active employees without a record, so an absent employee is
/// visible in the daily directory rather than silently missing from the table.
class AttendanceController extends GetxController {
  AttendanceController(this._repository);

  final AttendanceRepository _repository;

  static const int pageSize = 10;

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxList<EmployeeModel> employees = <EmployeeModel>[].obs;
  final RxList<AttendanceRecordModel> records = <AttendanceRecordModel>[].obs;
  final RxList<AttendanceRecordModel> todayRecords =
      <AttendanceRecordModel>[].obs;
  final RxList<AttendanceListRow> visibleRows = <AttendanceListRow>[].obs;
  final RxnString employeesError = RxnString();
  final RxnString attendanceError = RxnString();
  final Rx<DateTime> selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  ).obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxnString departmentFilter = RxnString();
  final RxnString employeeFilter = RxnString();
  final Rxn<AttendanceStatus> statusFilter = Rxn<AttendanceStatus>();
  final RxnString selectedEmployeeId = RxnString();
  final RxString detailTab = 'attendance'.obs;
  final RxInt currentPage = 0.obs;

  StreamSubscription<List<EmployeeModel>>? _employeesSubscription;
  StreamSubscription<List<AttendanceRecordModel>>? _recordsSubscription;
  StreamSubscription<List<AttendanceRecordModel>>? _todayRecordsSubscription;

  List<String> get departments =>
      employees
          .map((employee) => employee.department?.trim() ?? '')
          .where((department) => department.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

  List<EmployeeModel> get activeEmployees =>
      employees.where((employee) => employee.isActive).toList(growable: false);

  DateTime get rangeStart =>
      DateTime(selectedMonth.value.year, selectedMonth.value.month);
  DateTime get rangeEnd =>
      DateTime(selectedMonth.value.year, selectedMonth.value.month + 1, 0);
  DateTime get _recordsWatchStart =>
      rangeStart.subtract(const Duration(days: 6));
  int get pageCount =>
      (filteredRows.length / pageSize).ceil().clamp(1, 99999).toInt();
  bool get hasNextPage => currentPage.value < pageCount - 1;
  bool get hasPreviousPage => currentPage.value > 0;
  int get showingStart =>
      filteredRows.isEmpty ? 0 : currentPage.value * pageSize + 1;
  int get showingEnd => (currentPage.value * pageSize + visibleRows.length)
      .clamp(0, filteredRows.length)
      .toInt();

  List<AttendanceListRow> get filteredRows {
    final recordsByEmployee = <String, AttendanceRecordModel>{
      for (final record in records)
        if (_sameDay(record.date, selectedDate.value))
          record.employeeId: record,
    };
    final items =
        activeEmployees
            .where(
              (employee) =>
                  departmentFilter.value == null ||
                  employee.department?.trim() == departmentFilter.value,
            )
            .map(
              (employee) => AttendanceListRow(
                employee: employee,
                record: recordsByEmployee[employee.id],
              ),
            )
            .where((row) {
              final matchesEmployee =
                  employeeFilter.value == null ||
                  row.employee.id == employeeFilter.value;
              final matchesStatus =
                  statusFilter.value == null ||
                  row.effectiveStatus == statusFilter.value;
              return matchesEmployee && matchesStatus;
            })
            .toList()
          ..sort((a, b) => a.employee.fullName.compareTo(b.employee.fullName));
    return items;
  }

  int get totalEmployees => activeEmployees.length;
  int get presentToday => todayRecords
      .where((record) => record.status == AttendanceStatus.present)
      .length;
  int get lateToday => todayRecords
      .where((record) => record.status == AttendanceStatus.late)
      .length;
  int get absentToday =>
      (totalEmployees - presentToday - lateToday).clamp(0, totalEmployees);
  EmployeeModel? get selectedEmployee => employeeFor(selectedEmployeeId.value);
  AttendanceRecordModel? get selectedDayRecord {
    final employeeId = selectedEmployeeId.value;
    if (employeeId == null) return null;
    return _recordFor(employeeId, selectedDate.value);
  }

  List<AttendanceRecordModel> get selectedEmployeeMonthlyRecords {
    final employeeId = selectedEmployeeId.value;
    if (employeeId == null) return const [];
    final items =
        records
            .where(
              (record) =>
                  record.employeeId == employeeId &&
                  !record.date.isBefore(rangeStart) &&
                  !record.date.isAfter(rangeEnd),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  List<AttendanceRecordModel> get selectedEmployeeRecentRecords =>
      selectedEmployeeMonthlyRecords.take(7).toList(growable: false);

  List<AttendanceRecordModel?> get selectedEmployeeLastSevenDays {
    final employeeId = selectedEmployeeId.value;
    if (employeeId == null) return const [];
    return List<AttendanceRecordModel?>.generate(7, (index) {
      final date = selectedDate.value.subtract(Duration(days: index));
      return _recordFor(employeeId, date);
    });
  }

  int get selectedEmployeePresentDays => selectedEmployeeRecentRecords
      .where((record) => record.status == AttendanceStatus.present)
      .length;

  int get selectedEmployeeLateDays => selectedEmployeeRecentRecords
      .where((record) => record.status == AttendanceStatus.late)
      .length;

  int get selectedEmployeeWorkMinutes => selectedEmployeeRecentRecords.fold(
    0,
    (total, record) => total + record.workMinutes,
  );

  @override
  void onInit() {
    super.onInit();
    retryLiveData();
  }

  /// Restarts all Firestore listeners. The screen keeps its employee rows even
  /// when only the attendance-record query is unavailable.
  void retryLiveData() {
    _watchEmployees();
    _watchMonthRecords();
    _watchTodayRecords();
  }

  void _watchEmployees() {
    _employeesSubscription?.cancel();
    _employeesSubscription = _repository.watchEmployees().listen(
      (items) {
        employeesError.value = null;
        employees.assignAll(items);
        selectedEmployeeId.value ??= activeEmployees.isEmpty
            ? null
            : activeEmployees.first.id;
        isLoading.value = false;
        _applyFilters();
      },
      onError: (Object error) {
        employeesError.value = FailureMapper.message(error);
        isLoading.value = false;
        Get.snackbar('Employees unavailable', FailureMapper.message(error));
      },
    );
  }

  void _watchMonthRecords() {
    _recordsSubscription?.cancel();
    _recordsSubscription = _repository
        .watchRecords(from: _recordsWatchStart, to: rangeEnd)
        .listen(
          (items) {
            attendanceError.value = null;
            records.assignAll(items);
            final selectedExists =
                selectedEmployeeId.value != null &&
                employees.any(
                  (employee) =>
                      employee.isActive &&
                      employee.id == selectedEmployeeId.value,
                );
            if (!selectedExists && activeEmployees.isNotEmpty) {
              selectedEmployeeId.value = activeEmployees.first.id;
            }
            _applyFilters();
            isLoading.value = false;
          },
          onError: (Object error) {
            attendanceError.value = FailureMapper.message(error);
            isLoading.value = false;
            Get.snackbar(
              'Attendance unavailable',
              FailureMapper.message(error),
            );
          },
        );
  }

  void _watchTodayRecords() {
    final today = DateTime.now();
    _todayRecordsSubscription?.cancel();
    _todayRecordsSubscription = _repository
        .watchRecords(from: today, to: today)
        .listen(
          (items) {
            attendanceError.value = null;
            todayRecords.assignAll(items);
          },
          onError: (Object error) {
            attendanceError.value = FailureMapper.message(error);
          },
        );
  }

  void previousMonth() {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month - 1,
    );
    selectedDate.value = selectedMonth.value;
    currentPage.value = 0;
    _watchMonthRecords();
  }

  void nextMonth() {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month + 1,
    );
    selectedDate.value = selectedMonth.value;
    currentPage.value = 0;
    _watchMonthRecords();
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
    final record = records.firstWhereOrNull(
      (item) => _sameDay(item.date, date),
    );
    if (record != null) selectedEmployeeId.value = record.employeeId;
    currentPage.value = 0;
    _applyFilters();
  }

  void selectRow(AttendanceListRow row) {
    selectedEmployeeId.value = row.employee.id;
  }

  void setDepartmentFilter(String? value) {
    departmentFilter.value = value;
    currentPage.value = 0;
    _applyFilters();
  }

  void setEmployeeFilter(String? value) {
    employeeFilter.value = value;
    currentPage.value = 0;
    _applyFilters();
  }

  void setStatusFilter(AttendanceStatus? value) {
    statusFilter.value = value;
    currentPage.value = 0;
    _applyFilters();
  }

  void resetFilters() {
    departmentFilter.value = null;
    employeeFilter.value = null;
    statusFilter.value = null;
    currentPage.value = 0;
    _applyFilters();
  }

  void setDetailTab(String value) => detailTab.value = value;

  void goToPage(int page) {
    currentPage.value = page.clamp(0, pageCount - 1).toInt();
    _applyFilters();
  }

  Future<bool> saveAttendance({
    required String employeeId,
    required DateTime date,
    required AttendanceStatus status,
    DateTime? checkIn,
    DateTime? checkOut,
  }) async {
    final minutes =
        checkIn != null && checkOut != null && checkOut.isAfter(checkIn)
        ? checkOut.difference(checkIn).inMinutes
        : 0;
    isSaving.value = true;
    try {
      await _repository.saveRecord(
        AttendanceRecordModel(
          id: '',
          employeeId: employeeId,
          date: date,
          status: status,
          checkIn: status == AttendanceStatus.absent ? null : checkIn,
          checkOut: status == AttendanceStatus.absent ? null : checkOut,
          workMinutes: status == AttendanceStatus.absent ? 0 : minutes,
        ),
      );
      Get.snackbar(
        'Attendance saved',
        'The attendance record is now up to date.',
      );
      return true;
    } catch (error) {
      Get.snackbar('Attendance not saved', FailureMapper.message(error));
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  EmployeeModel? employeeFor(String? employeeId) =>
      employees.firstWhereOrNull((employee) => employee.id == employeeId);

  AttendanceRecordModel? recordForEmployeeOnSelectedDate(String employeeId) =>
      _recordFor(employeeId, selectedDate.value);

  AttendanceRecordModel? _recordFor(String employeeId, DateTime date) =>
      records.firstWhereOrNull(
        (record) =>
            record.employeeId == employeeId && _sameDay(record.date, date),
      );

  void _applyFilters() {
    final items = filteredRows;
    final maxPage = (items.length / pageSize).ceil() - 1;
    if (currentPage.value > maxPage && maxPage >= 0) {
      currentPage.value = maxPage;
    }
    final start = currentPage.value * pageSize;
    visibleRows.assignAll(
      start >= items.length
          ? const <AttendanceListRow>[]
          : items.skip(start).take(pageSize),
    );
  }

  bool sameDay(DateTime first, DateTime second) => _sameDay(first, second);

  bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  @override
  void onClose() {
    _employeesSubscription?.cancel();
    _recordsSubscription?.cancel();
    _todayRecordsSubscription?.cancel();
    super.onClose();
  }
}

class AttendanceListRow {
  const AttendanceListRow({required this.employee, this.record});

  final EmployeeModel employee;
  final AttendanceRecordModel? record;

  AttendanceStatus get effectiveStatus =>
      record?.status ?? AttendanceStatus.absent;
}
