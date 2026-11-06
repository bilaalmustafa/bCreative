import 'dart:async';

import 'package:bcreative_ems/core/errors/failure_mapper.dart';
import 'package:bcreative_ems/features/attendance/models/attendance_record_model.dart';
import 'package:bcreative_ems/features/attendance/repositories/attendance_repository.dart';
import 'package:bcreative_ems/features/auth/viewmodels/auth_controller.dart';
import 'package:bcreative_ems/features/profile/models/employee_profile_model.dart';
import 'package:bcreative_ems/features/profile/repositories/employee_profile_repository.dart';
import 'package:get/get.dart';

/// Self-service attendance state. Firebase stores the employee's actual
/// check-in/out records; this controller fills past dates with an Absent row
/// for the selected month so the employee can see a complete month summary.
class EmployeeAttendanceController extends GetxController {
  EmployeeAttendanceController(
    this._attendanceRepository,
    this._profileRepository,
    this._authController,
  );

  final AttendanceRepository _attendanceRepository;
  final EmployeeProfileRepository _profileRepository;
  final AuthController _authController;

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final Rxn<EmployeeProfileModel> profile = Rxn<EmployeeProfileModel>();
  final Rxn<AttendanceRecordModel> todayRecord = Rxn<AttendanceRecordModel>();
  final RxList<AttendanceRecordModel> recentRecords =
      <AttendanceRecordModel>[].obs;
  final RxList<AttendanceRecordModel> monthlyRecords =
      <AttendanceRecordModel>[].obs;
  final Rx<DateTime> selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  ).obs;
  final Rxn<DateTime> dateFilter = Rxn<DateTime>();
  final Rxn<AttendanceStatus> statusFilter = Rxn<AttendanceStatus>();

  StreamSubscription<EmployeeProfileModel?>? _profileSubscription;
  StreamSubscription<AttendanceRecordModel?>? _todaySubscription;
  StreamSubscription<List<AttendanceRecordModel>>? _recentSubscription;
  StreamSubscription<List<AttendanceRecordModel>>? _monthlySubscription;

  String get employeeId => _authController.session.value?.employeeId ?? '';
  bool get canCheckIn => todayRecord.value == null;
  bool get canCheckOut =>
      todayRecord.value?.checkIn != null && todayRecord.value?.checkOut == null;
  bool get hasCheckedOut => todayRecord.value?.checkOut != null;

  DateTime get monthStart =>
      DateTime(selectedMonth.value.year, selectedMonth.value.month);
  DateTime get monthEnd =>
      DateTime(selectedMonth.value.year, selectedMonth.value.month + 1, 0);

  List<EmployeeAttendanceDay> get monthlyDays => _daysForRange(
    start: monthStart,
    end: _earlierDate(monthEnd, _today),
    records: _mergeTodayRecord(monthlyRecords),
  );

  List<EmployeeAttendanceDay> get filteredMonthlyDays => monthlyDays
      .where((day) {
        final matchesDate =
            dateFilter.value == null || _sameDay(day.date, dateFilter.value!);
        final matchesStatus =
            statusFilter.value == null || day.status == statusFilter.value;
        return matchesDate && matchesStatus;
      })
      .toList(growable: false);

  /// Exactly the current day plus six preceding calendar dates.
  List<EmployeeAttendanceDay> get recentDays => _daysForRange(
    start: _today.subtract(const Duration(days: 6)),
    end: _today,
    records: _mergeTodayRecord(recentRecords),
  );

  int get presentDays =>
      monthlyDays.where((day) => day.status == AttendanceStatus.present).length;
  int get lateDays =>
      monthlyDays.where((day) => day.status == AttendanceStatus.late).length;
  int get absentDays =>
      monthlyDays.where((day) => day.status == AttendanceStatus.absent).length;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// The one-day stream is the quickest source after a check-in/out. Merging
  /// it into both history lists avoids waiting for the range-query snapshot to
  /// arrive before Today's status and time are visible in Recent Attendance.
  List<AttendanceRecordModel> _mergeTodayRecord(
    List<AttendanceRecordModel> records,
  ) {
    final today = todayRecord.value;
    if (today == null) return records;
    return [
      ...records.where((record) => !_sameDay(record.date, today.date)),
      today,
    ];
  }

  @override
  void onInit() {
    super.onInit();
    if (employeeId.isEmpty) {
      isLoading.value = false;
      return;
    }
    _watchProfile();
    _watchToday();
    _watchRecentDays();
    _watchSelectedMonth();
  }

  void _watchProfile() {
    _profileSubscription = _profileRepository
        .watchProfile(employeeId)
        .listen(
          (value) {
            profile.value = value;
            isLoading.value = false;
          },
          onError: (Object error) {
            isLoading.value = false;
            Get.snackbar('Profile unavailable', FailureMapper.message(error));
          },
        );
  }

  void _watchToday() {
    _todaySubscription = _attendanceRepository
        .watchRecord(employeeId: employeeId, date: _today)
        .listen(
          (value) {
            todayRecord.value = value;
            isLoading.value = false;
          },
          onError: (Object error) {
            isLoading.value = false;
            Get.snackbar(
              'Attendance unavailable',
              FailureMapper.message(error),
            );
          },
        );
  }

  void _watchRecentDays() {
    _recentSubscription?.cancel();
    _recentSubscription = _attendanceRepository
        .watchEmployeeRecordsForRange(
          employeeId,
          from: _today.subtract(const Duration(days: 6)),
          to: _today,
        )
        .listen(
          recentRecords.assignAll,
          onError: (Object error) => Get.snackbar(
            'Attendance history unavailable',
            FailureMapper.message(error),
          ),
        );
  }

  void _watchSelectedMonth() {
    _monthlySubscription?.cancel();
    _monthlySubscription = _attendanceRepository
        .watchEmployeeRecordsForRange(
          employeeId,
          from: monthStart,
          to: monthEnd,
        )
        .listen(
          monthlyRecords.assignAll,
          onError: (Object error) => Get.snackbar(
            'Monthly attendance unavailable',
            FailureMapper.message(error),
          ),
        );
  }

  void previousMonth() {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month - 1,
    );
    dateFilter.value = null;
    _watchSelectedMonth();
  }

  void nextMonth() {
    final next = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month + 1,
    );
    if (next.isAfter(DateTime(_today.year, _today.month))) return;
    selectedMonth.value = next;
    dateFilter.value = null;
    _watchSelectedMonth();
  }

  void setDateFilter(DateTime? value) => dateFilter.value = value == null
      ? null
      : DateTime(value.year, value.month, value.day);
  void setStatusFilter(AttendanceStatus? value) => statusFilter.value = value;
  void resetFilters() {
    dateFilter.value = null;
    statusFilter.value = null;
  }

  Future<void> checkIn() async {
    if (employeeId.isEmpty) {
      Get.snackbar(
        'Attendance unavailable',
        'Your employee account is not linked to an employee record.',
      );
      return;
    }
    if (!canCheckIn || isSaving.value) return;
    isSaving.value = true;
    try {
      await _attendanceRepository.checkIn(
        employeeId: employeeId,
        employeeName: profile.value?.fullName ?? 'Employee',
        at: DateTime.now(),
      );
      Get.snackbar('Checked in', 'Your attendance has been recorded.');
    } catch (error) {
      Get.snackbar('Check-in unavailable', FailureMapper.message(error));
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> checkOut() async {
    if (employeeId.isEmpty) {
      Get.snackbar(
        'Attendance unavailable',
        'Your employee account is not linked to an employee record.',
      );
      return;
    }
    if (!canCheckOut || isSaving.value) return;
    isSaving.value = true;
    try {
      await _attendanceRepository.checkOut(
        employeeId: employeeId,
        employeeName: profile.value?.fullName ?? 'Employee',
        at: DateTime.now(),
      );
      Get.snackbar('Checked out', 'Working hours have been calculated.');
    } catch (error) {
      Get.snackbar('Check-out unavailable', FailureMapper.message(error));
    } finally {
      isSaving.value = false;
    }
  }

  List<EmployeeAttendanceDay> _daysForRange({
    required DateTime start,
    required DateTime end,
    required List<AttendanceRecordModel> records,
  }) {
    final joiningDate = profile.value?.joiningDate;
    final firstDate = joiningDate != null && joiningDate.isAfter(start)
        ? DateTime(joiningDate.year, joiningDate.month, joiningDate.day)
        : start;
    if (firstDate.isAfter(end)) return const <EmployeeAttendanceDay>[];
    final recordsByDate = <String, AttendanceRecordModel>{
      for (final record in records) _dateKey(record.date): record,
    };
    final days = <EmployeeAttendanceDay>[];
    for (
      var date = end;
      !date.isBefore(firstDate);
      date = date.subtract(const Duration(days: 1))
    ) {
      days.add(
        EmployeeAttendanceDay(
          date: date,
          record: recordsByDate[_dateKey(date)],
        ),
      );
    }
    return days;
  }

  bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  DateTime _earlierDate(DateTime first, DateTime second) =>
      first.isBefore(second) ? first : second;

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  void onClose() {
    _profileSubscription?.cancel();
    _todaySubscription?.cancel();
    _recentSubscription?.cancel();
    _monthlySubscription?.cancel();
    super.onClose();
  }
}

class EmployeeAttendanceDay {
  const EmployeeAttendanceDay({required this.date, this.record});

  final DateTime date;
  final AttendanceRecordModel? record;

  AttendanceStatus get status => record?.status ?? AttendanceStatus.absent;
  DateTime? get checkIn => record?.checkIn;
  DateTime? get checkOut => record?.checkOut;
  String get workHoursLabel => record?.workHoursLabel ?? '—';
}
