import 'dart:async';

import 'package:bcreative_ems/core/errors/failure_mapper.dart';
import 'package:bcreative_ems/features/employees/models/employee_model.dart';
import 'package:bcreative_ems/features/payroll/models/payroll_record_model.dart';
import 'package:bcreative_ems/features/payroll/repositories/payroll_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class PayrollController extends GetxController {
  PayrollController(this._repository);

  final PayrollRepository _repository;

  static const pageSize = 10;

  final RxBool isLoading = true.obs;
  final RxBool isCreating = false.obs;
  final RxList<EmployeeModel> employees = <EmployeeModel>[].obs;
  final RxList<PayrollRecordModel> records = <PayrollRecordModel>[].obs;
  final Rx<DateTime> selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  ).obs;
  final RxString query = ''.obs;
  final RxnString departmentFilter = RxnString();
  final RxnString selectedEmployeeId = RxnString();
  final RxInt currentPage = 0.obs;
  final RxBool isCreatePanelOpen = false.obs;
  final RxInt createStep = 1.obs;
  final RxInt draftRevision = 0.obs;
  final RxString detailTab = 'payroll'.obs;
  final RxnString draftEmployeeId = RxnString();
  final Rx<DateTime> draftPaymentDate = DateTime.now().obs;
  final Rxn<PlatformFile> draftSlipFile = Rxn<PlatformFile>();
  final RxBool isOpeningSlip = false.obs;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController basicSalaryController = TextEditingController();
  final TextEditingController overtimeController = TextEditingController(
    text: '0',
  );
  final TextEditingController houseAllowanceController = TextEditingController(
    text: '0',
  );
  final TextEditingController transportAllowanceController =
      TextEditingController(text: '0');
  final TextEditingController otherAllowancesController = TextEditingController(
    text: '0',
  );
  final TextEditingController taxDeductionController = TextEditingController(
    text: '0',
  );
  final TextEditingController loanDeductionController = TextEditingController(
    text: '0',
  );
  final TextEditingController otherDeductionsController = TextEditingController(
    text: '0',
  );

  StreamSubscription<List<EmployeeModel>>? _employeesSubscription;
  StreamSubscription<List<PayrollRecordModel>>? _recordsSubscription;

  String get periodKey =>
      '${selectedMonth.value.year.toString().padLeft(4, '0')}-${selectedMonth.value.month.toString().padLeft(2, '0')}';
  String get displayMonth => _monthLabel(selectedMonth.value);
  List<EmployeeModel> get activeEmployees =>
      employees.where((employee) => employee.isActive).toList(growable: false);
  List<String> get departments =>
      activeEmployees
          .map((employee) => employee.department?.trim() ?? '')
          .where((department) => department.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

  List<PayrollListItem> get allItems {
    final recordByEmployee = <String, PayrollRecordModel>{
      for (final record in records) record.employeeId: record,
    };
    return activeEmployees
        .map(
          (employee) => PayrollListItem(
            employee: employee,
            record: recordByEmployee[employee.id],
            periodKey: periodKey,
          ),
        )
        .toList(growable: false);
  }

  List<PayrollListItem> get filteredItems {
    final term = query.value.trim().toLowerCase();
    final items =
        allItems
            .where((item) {
              final employee = item.employee;
              final matchesQuery =
                  term.isEmpty ||
                  employee.fullName.toLowerCase().contains(term) ||
                  employee.employeeCode.toLowerCase().contains(term) ||
                  (employee.department?.toLowerCase().contains(term) ?? false);
              final matchesDepartment =
                  departmentFilter.value == null ||
                  employee.department?.trim() == departmentFilter.value;
              return matchesQuery && matchesDepartment;
            })
            .toList(growable: false)
          ..sort(
            (first, second) =>
                first.employee.fullName.compareTo(second.employee.fullName),
          );
    return items;
  }

  List<PayrollListItem> get visibleItems {
    final start = currentPage.value * pageSize;
    return start >= filteredItems.length
        ? const <PayrollListItem>[]
        : filteredItems.skip(start).take(pageSize).toList(growable: false);
  }

  int get pageCount =>
      (filteredItems.length / pageSize).ceil().clamp(1, 9999).toInt();
  bool get hasNextPage => currentPage.value < pageCount - 1;
  bool get hasPreviousPage => currentPage.value > 0;
  int get showingStart =>
      filteredItems.isEmpty ? 0 : currentPage.value * pageSize + 1;
  int get showingEnd => (currentPage.value * pageSize + visibleItems.length)
      .clamp(0, filteredItems.length)
      .toInt();

  PayrollListItem? get selectedItem => allItems.firstWhereOrNull(
    (item) => item.employee.id == selectedEmployeeId.value,
  );
  EmployeeModel? get draftEmployee => activeEmployees.firstWhereOrNull(
    (employee) => employee.id == draftEmployeeId.value,
  );
  double get draftBasicSalary => _readAmount(basicSalaryController);
  double get draftHouseAllowance => _readAmount(houseAllowanceController);
  double get draftTransportAllowance =>
      _readAmount(transportAllowanceController);
  double get draftOtherAllowances => _readAmount(otherAllowancesController);
  double get draftTaxDeduction => _readAmount(taxDeductionController);
  double get draftLoanDeduction => _readAmount(loanDeductionController);
  double get draftOtherDeductions => _readAmount(otherDeductionsController);
  double get draftTotalAllowances =>
      draftHouseAllowance +
      draftTransportAllowance +
      draftOtherAllowances +
      _readAmount(overtimeController);
  double get draftTotalDeductions =>
      draftTaxDeduction + draftLoanDeduction + draftOtherDeductions;
  double get draftNetSalary =>
      draftBasicSalary + draftTotalAllowances - draftTotalDeductions;
  int get totalEmployees => activeEmployees.length;
  int get paidEmployees => allItems.where((item) => item.record != null).length;
  int get salarySlipCount =>
      records.where((record) => record.hasSalarySlip).length;
  double get totalPayroll =>
      allItems.fold(0, (total, item) => total + item.netSalary);
  double get totalDeductions =>
      allItems.fold(0, (total, item) => total + item.totalDeductions);

  @override
  void onInit() {
    super.onInit();
    _employeesSubscription = _repository.watchEmployees().listen(
      (items) {
        employees.assignAll(items);
        final active = activeEmployees;
        if (selectedEmployeeId.value == null && active.isNotEmpty) {
          selectedEmployeeId.value = active.first.id;
        }
        _clampPage();
        isLoading.value = false;
      },
      onError: (Object error) {
        isLoading.value = false;
        Get.snackbar('Employees unavailable', FailureMapper.message(error));
      },
    );
    _watchRecords();
  }

  void _watchRecords() {
    _recordsSubscription?.cancel();
    _recordsSubscription = _repository
        .watchRecords(periodKey)
        .listen(
          (items) {
            records.assignAll(items);
            _clampPage();
            isLoading.value = false;
          },
          onError: (Object error) {
            isLoading.value = false;
            Get.snackbar('Payroll unavailable', FailureMapper.message(error));
          },
        );
  }

  void previousMonth() {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month - 1,
    );
    currentPage.value = 0;
    _watchRecords();
  }

  void nextMonth() {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month + 1,
    );
    currentPage.value = 0;
    _watchRecords();
  }

  void setQuery(String value) {
    query.value = value;
    currentPage.value = 0;
  }

  void setDepartmentFilter(String? value) {
    departmentFilter.value = value;
    currentPage.value = 0;
  }

  void resetFilters() {
    query.value = '';
    searchController.clear();
    departmentFilter.value = null;
    currentPage.value = 0;
  }

  void selectItem(PayrollListItem item) {
    selectedEmployeeId.value = item.employee.id;
    detailTab.value = 'payroll';
  }

  void setDetailTab(String value) => detailTab.value = value;

  void goToPage(int page) {
    currentPage.value = page.clamp(0, pageCount - 1).toInt();
  }

  void openCreatePayroll() {
    final employee = selectedItem?.employee ?? activeEmployees.firstOrNull;
    if (employee == null) {
      Get.snackbar(
        'No employees',
        'Add an active employee before creating payroll.',
      );
      return;
    }
    draftEmployeeId.value = employee.id;
    draftPaymentDate.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month + 1,
      0,
    );
    createStep.value = 1;
    draftSlipFile.value = null;
    _prefillDraft(employee);
    isCreatePanelOpen.value = true;
  }

  void closeCreatePayroll() => isCreatePanelOpen.value = false;

  void setDraftEmployee(String? employeeId) {
    if (employeeId == null) return;
    draftEmployeeId.value = employeeId;
    final employee = draftEmployee;
    if (employee != null) _prefillDraft(employee);
    refreshDraft();
  }

  void nextCreateStep() {
    if (draftEmployee == null) {
      Get.snackbar('Employee required', 'Select an employee for this payroll.');
      return;
    }
    if (createStep.value < 5) createStep.value++;
  }

  void previousCreateStep() {
    if (createStep.value > 1) createStep.value--;
  }

  void refreshDraft() => draftRevision.value++;

  Future<void> pickDraftSalarySlip() async {
    final file = await _pickSalarySlip();
    if (file == null) return;
    draftSlipFile.value = file;
    refreshDraft();
  }

  Future<void> saveDraftPayroll() async {
    final employee = draftEmployee;
    if (employee == null || isCreating.value) return;
    final salarySlip = draftSlipFile.value;
    if (records.any((record) => record.employeeId == employee.id)) {
      Get.snackbar(
        'Payroll exists',
        'A payroll record already exists for this employee in $displayMonth.',
      );
      return;
    }
    isCreating.value = true;
    try {
      final record = PayrollRecordModel(
        id: '${employee.id}-$periodKey',
        employeeId: employee.id,
        periodKey: periodKey,
        basicSalary: draftBasicSalary,
        houseAllowance: draftHouseAllowance,
        transportAllowance: draftTransportAllowance,
        otherAllowances: draftOtherAllowances + _readAmount(overtimeController),
        taxDeduction: draftTaxDeduction,
        loanDeduction: draftLoanDeduction,
        otherDeductions: draftOtherDeductions,
        status: PayrollStatus.paid,
      );
      await _repository.createRecords([record]);
      if (salarySlip != null) {
        try {
          await _repository.attachSalarySlip(record: record, file: salarySlip);
        } catch (_) {
          selectedEmployeeId.value = employee.id;
          isCreatePanelOpen.value = false;
          Get.snackbar(
            'Payroll created',
            'The paid payroll was created, but its selected salary slip could not upload.',
          );
          return;
        }
      }
      selectedEmployeeId.value = employee.id;
      isCreatePanelOpen.value = false;
      Get.snackbar(
        'Payroll created',
        '${employee.fullName} payroll created for $displayMonth.',
      );
    } on StateError {
      Get.snackbar(
        'Payroll exists',
        'A payroll record already exists for this employee in $displayMonth.',
      );
    } catch (error) {
      Get.snackbar('Payroll not created', FailureMapper.message(error));
    } finally {
      isCreating.value = false;
    }
  }

  Future<void> previewSelectedSalarySlip() async {
    final record = selectedItem?.record;
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

  Future<PlatformFile?> _pickSalarySlip() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.single;
  }

  void _prefillDraft(EmployeeModel employee) {
    basicSalaryController.text = (employee.salary?.toDouble() ?? 0)
        .toStringAsFixed(0);
    overtimeController.text = '0';
    houseAllowanceController.text = '0';
    transportAllowanceController.text = '0';
    otherAllowancesController.text = '0';
    taxDeductionController.text = '0';
    loanDeductionController.text = '0';
    otherDeductionsController.text = '0';
  }

  double _readAmount(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;

  void _clampPage() {
    if (currentPage.value >= pageCount) currentPage.value = pageCount - 1;
    final selectedExists =
        selectedEmployeeId.value != null &&
        activeEmployees.any(
          (employee) => employee.id == selectedEmployeeId.value,
        );
    if (!selectedExists && activeEmployees.isNotEmpty) {
      selectedEmployeeId.value = activeEmployees.first.id;
    }
  }

  @override
  void onClose() {
    _employeesSubscription?.cancel();
    _recordsSubscription?.cancel();
    searchController.dispose();
    basicSalaryController.dispose();
    overtimeController.dispose();
    houseAllowanceController.dispose();
    transportAllowanceController.dispose();
    otherAllowancesController.dispose();
    taxDeductionController.dispose();
    loanDeductionController.dispose();
    otherDeductionsController.dispose();
    super.onClose();
  }
}

class PayrollListItem {
  const PayrollListItem({
    required this.employee,
    required this.record,
    required this.periodKey,
  });

  final EmployeeModel employee;
  final PayrollRecordModel? record;
  final String periodKey;

  double get basicSalary =>
      record?.basicSalary ?? (employee.salary?.toDouble() ?? 0);
  double get houseAllowance => record?.houseAllowance ?? 0;
  double get transportAllowance => record?.transportAllowance ?? 0;
  double get otherAllowances => record?.otherAllowances ?? 0;
  double get taxDeduction => record?.taxDeduction ?? 0;
  double get loanDeduction => record?.loanDeduction ?? 0;
  double get otherDeductions => record?.otherDeductions ?? 0;
  double get totalAllowances =>
      houseAllowance + transportAllowance + otherAllowances;
  double get totalDeductions => taxDeduction + loanDeduction + otherDeductions;
  double get netSalary => basicSalary + totalAllowances - totalDeductions;
  PayrollStatus? get status => record?.status;
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
