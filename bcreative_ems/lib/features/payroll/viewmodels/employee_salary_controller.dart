import 'dart:async';

import 'package:bcreative_ems/core/errors/failure_mapper.dart';
import 'package:bcreative_ems/features/auth/viewmodels/auth_controller.dart';
import 'package:bcreative_ems/features/payroll/models/payroll_record_model.dart';
import 'package:bcreative_ems/features/payroll/repositories/payroll_repository.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class EmployeeSalaryController extends GetxController {
  EmployeeSalaryController(this._repository, this._auth);

  final PayrollRepository _repository;
  final AuthController _auth;

  final RxBool isLoading = true.obs;
  final RxList<PayrollRecordModel> records = <PayrollRecordModel>[].obs;
  final Rxn<DateTime> selectedMonth = Rxn<DateTime>();
  final RxnString selectedRecordId = RxnString();
  final RxString detailTab = 'salary'.obs;
  final RxBool isOpeningSlip = false.obs;

  StreamSubscription<List<PayrollRecordModel>>? _subscription;

  String? get employeeId => _auth.session.value?.employeeId;
  String get selectedMonthLabel => selectedMonth.value == null
      ? 'All months'
      : _monthLabel(selectedMonth.value!);
  String get selectedMonthKey {
    final month = selectedMonth.value;
    if (month == null) return '';
    return '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
  }

  List<PayrollRecordModel> get filteredRecords {
    final key = selectedMonthKey;
    if (key.isEmpty) return records;
    return records
        .where((record) => record.periodKey == key)
        .toList(growable: false);
  }

  PayrollRecordModel? get selectedRecord => filteredRecords.firstWhereOrNull(
    (record) => record.id == selectedRecordId.value,
  );
  double get totalPaid =>
      filteredRecords.fold(0, (total, record) => total + record.netSalary);
  int get slipCount =>
      filteredRecords.where((record) => record.hasSalarySlip).length;

  @override
  void onInit() {
    super.onInit();
    final id = employeeId;
    if (id == null || id.isEmpty) {
      isLoading.value = false;
      Get.snackbar(
        'Salary unavailable',
        'Your employee profile could not be found.',
      );
      return;
    }
    _subscription = _repository
        .watchEmployeeRecords(id)
        .listen(
          (items) {
            records.assignAll(items);
            _ensureSelectedRecord();
            isLoading.value = false;
          },
          onError: (Object error) {
            isLoading.value = false;
            Get.snackbar('Salary unavailable', FailureMapper.message(error));
          },
        );
  }

  void previousMonth() {
    final base = selectedMonth.value ?? DateTime.now();
    selectedMonth.value = DateTime(base.year, base.month - 1);
    _ensureSelectedRecord();
  }

  void nextMonth() {
    final base = selectedMonth.value ?? DateTime.now();
    selectedMonth.value = DateTime(base.year, base.month + 1);
    _ensureSelectedRecord();
  }

  void selectRecord(PayrollRecordModel record) {
    selectedRecordId.value = record.id;
    detailTab.value = 'salary';
  }

  void setDetailTab(String value) => detailTab.value = value;

  Future<void> previewSelectedSalarySlip() async {
    final record = selectedRecord;
    if (record == null || !record.hasSalarySlip || isOpeningSlip.value) return;
    isOpeningSlip.value = true;
    try {
      final url = await _repository.getSalarySlipDownloadUrl(record);
      if (url == null || !await launchUrl(Uri.parse(url))) {
        Get.snackbar(
          'Preview unavailable',
          'The salary slip could not be opened.',
        );
      }
    } catch (error) {
      Get.snackbar('Preview unavailable', FailureMapper.message(error));
    } finally {
      isOpeningSlip.value = false;
    }
  }

  void _ensureSelectedRecord() {
    final visible = filteredRecords;
    if (visible.isEmpty) {
      selectedRecordId.value = null;
      return;
    }
    final selectedExists = visible.any(
      (record) => record.id == selectedRecordId.value,
    );
    if (!selectedExists) selectedRecordId.value = visible.first.id;
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}

String _monthLabel(DateTime value) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[value.month - 1]} ${value.year}';
}
