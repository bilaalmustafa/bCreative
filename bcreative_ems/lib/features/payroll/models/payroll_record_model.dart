import 'package:cloud_firestore/cloud_firestore.dart';

enum PayrollStatus {
  paid('paid', 'Paid');

  const PayrollStatus(this.value, this.label);
  final String value;
  final String label;

  // Existing records that were saved as `pending` are treated as paid too.
  // Payroll is now finalized as paid at the moment it is created.
  static PayrollStatus fromValue(String? value) => PayrollStatus.paid;
}

class PayrollRecordModel {
  const PayrollRecordModel({
    required this.id,
    required this.employeeId,
    required this.periodKey,
    required this.basicSalary,
    required this.houseAllowance,
    required this.transportAllowance,
    required this.otherAllowances,
    required this.taxDeduction,
    required this.loanDeduction,
    required this.otherDeductions,
    required this.status,
    this.slipFileName,
    this.slipStoragePath,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String employeeId;
  final String periodKey;
  final double basicSalary;
  final double houseAllowance;
  final double transportAllowance;
  final double otherAllowances;
  final double taxDeduction;
  final double loanDeduction;
  final double otherDeductions;
  final PayrollStatus status;
  final String? slipFileName;
  final String? slipStoragePath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get totalAllowances =>
      houseAllowance + transportAllowance + otherAllowances;
  double get totalDeductions => taxDeduction + loanDeduction + otherDeductions;
  double get netSalary => basicSalary + totalAllowances - totalDeductions;
  bool get hasSalarySlip =>
      (slipFileName?.isNotEmpty ?? false) &&
      (slipStoragePath?.isNotEmpty ?? false);

  factory PayrollRecordModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return PayrollRecordModel(
      id: document.id,
      employeeId: data['employeeId'] as String? ?? '',
      periodKey: data['periodKey'] as String? ?? '',
      basicSalary: _amount(data['basicSalary']),
      houseAllowance: _amount(data['houseAllowance']),
      transportAllowance: _amount(data['transportAllowance']),
      otherAllowances: _amount(data['otherAllowances']),
      taxDeduction: _amount(data['taxDeduction']),
      loanDeduction: _amount(data['loanDeduction']),
      otherDeductions: _amount(data['otherDeductions']),
      status: PayrollStatus.fromValue(data['status'] as String?),
      slipFileName: data['slipFileName'] as String?,
      slipStoragePath: data['slipStoragePath'] as String?,
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toJson({bool includeCreatedAt = false}) => {
    'employeeId': employeeId,
    'periodKey': periodKey,
    'basicSalary': basicSalary,
    'houseAllowance': houseAllowance,
    'transportAllowance': transportAllowance,
    'otherAllowances': otherAllowances,
    'taxDeduction': taxDeduction,
    'loanDeduction': loanDeduction,
    'otherDeductions': otherDeductions,
    'status': status.value,
    if (slipFileName != null) 'slipFileName': slipFileName,
    if (slipStoragePath != null) 'slipStoragePath': slipStoragePath,
    if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static double _amount(dynamic value) => (value as num?)?.toDouble() ?? 0;

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
