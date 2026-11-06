import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus {
  present('present', 'Present'),
  absent('absent', 'Absent'),
  late('late', 'Late');

  const AttendanceStatus(this.value, this.label);

  final String value;
  final String label;

  static AttendanceStatus fromValue(String? value) =>
      AttendanceStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => AttendanceStatus.present,
      );
}

class AttendanceRecordModel {
  const AttendanceRecordModel({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.workMinutes = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String employeeId;
  final DateTime date;
  final AttendanceStatus status;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int workMinutes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get dateKey =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String get workHoursLabel {
    if (workMinutes <= 0) return '—';
    final hours = workMinutes ~/ 60;
    final minutes = workMinutes % 60;
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  factory AttendanceRecordModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return AttendanceRecordModel(
      id: document.id,
      employeeId: data['employeeId'] as String? ?? '',
      date: _readDate(data['date']) ?? DateTime.now(),
      status: AttendanceStatus.fromValue(data['status'] as String?),
      checkIn: _readDate(data['checkIn']),
      checkOut: _readDate(data['checkOut']),
      workMinutes: (data['workMinutes'] as num?)?.toInt() ?? 0,
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toJson({bool includeCreatedAt = false}) => {
    'employeeId': employeeId,
    'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
    'dateKey': dateKey,
    'status': status.value,
    'checkIn': checkIn == null ? null : Timestamp.fromDate(checkIn!),
    'checkOut': checkOut == null ? null : Timestamp.fromDate(checkOut!),
    'workMinutes': workMinutes,
    if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
