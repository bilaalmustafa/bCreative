import 'package:bcreative_ems/features/attendance/models/attendance_record_model.dart';
import 'package:bcreative_ems/features/employees/models/employee_model.dart';
import 'package:bcreative_ems/features/notifications/models/app_notification_model.dart';
import 'package:bcreative_ems/features/notifications/repositories/notification_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendanceRepository {
  AttendanceRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    NotificationRepository? notifications,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _notifications =
           notifications ?? NotificationRepository(firestore: firestore);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final NotificationRepository _notifications;

  CollectionReference<Map<String, dynamic>> get _records =>
      _firestore.collection('attendance_records');

  /// Sorting on-device deliberately includes older employee documents which
  /// were created before `fullNameLower` existed. An `orderBy` query silently
  /// omits documents missing that field, leaving the attendance register empty
  /// even though the employee directory contains people.
  Stream<List<EmployeeModel>> watchEmployees() =>
      _firestore.collection('employees').snapshots().map((snapshot) {
        final employees = snapshot.docs
            .map(EmployeeModel.fromFirestore)
            .toList(growable: false);
        employees.sort(
          (first, second) => first.fullName.toLowerCase().compareTo(
            second.fullName.toLowerCase(),
          ),
        );
        return employees;
      });

  Stream<List<AttendanceRecordModel>> watchRecords({
    required DateTime from,
    required DateTime to,
  }) {
    final startKey = _dateKey(from);
    final endKey = _dateKey(to);
    return _records
        .where('dateKey', isGreaterThanOrEqualTo: startKey)
        .where('dateKey', isLessThanOrEqualTo: endKey)
        .orderBy('dateKey', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AttendanceRecordModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<AttendanceRecordModel?> watchRecord({
    required String employeeId,
    required DateTime date,
  }) => _records
      .doc('$employeeId-${_dateKey(date)}')
      .snapshots()
      .map(
        (snapshot) => snapshot.exists
            ? AttendanceRecordModel.fromFirestore(snapshot)
            : null,
      );

  Stream<List<AttendanceRecordModel>> watchEmployeeRecords(
    String employeeId, {
    int limit = 14,
  }) => _records
      .where('employeeId', isEqualTo: employeeId)
      .orderBy('dateKey', descending: true)
      .limit(limit)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(AttendanceRecordModel.fromFirestore)
            .toList(growable: false),
      );

  /// Streams just one employee's records for a bounded calendar range. This
  /// keeps the self-service monthly history live without downloading every
  /// attendance document the employee has ever created.
  Stream<List<AttendanceRecordModel>> watchEmployeeRecordsForRange(
    String employeeId, {
    required DateTime from,
    required DateTime to,
  }) => _records
      .where('employeeId', isEqualTo: employeeId)
      .where('dateKey', isGreaterThanOrEqualTo: _dateKey(from))
      .where('dateKey', isLessThanOrEqualTo: _dateKey(to))
      .orderBy('dateKey', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(AttendanceRecordModel.fromFirestore)
            .toList(growable: false),
      );

  Future<void> saveRecord(AttendanceRecordModel record) {
    final documentId = '${record.employeeId}-${record.dateKey}';
    return _records
        .doc(documentId)
        .set(record.toJson(includeCreatedAt: true), SetOptions(merge: true));
  }

  /// Creates the one allowed attendance document for an employee's local day.
  /// The fixed document id, transaction, and Firestore rules together prevent
  /// a second check-in from replacing the first one.
  Future<void> checkIn({
    required String employeeId,
    required String employeeName,
    required DateTime at,
  }) async {
    final actorUid = _requireActorUid();
    final date = DateTime(at.year, at.month, at.day);
    final reference = _records.doc('$employeeId-${_dateKey(date)}');
    final notification = _notifications.newDocument();
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) {
        throw StateError('You have already checked in for today.');
      }
      final status = _isLate(at)
          ? AttendanceStatus.late
          : AttendanceStatus.present;
      transaction.set(
        reference,
        AttendanceRecordModel(
          id: reference.id,
          employeeId: employeeId,
          date: date,
          status: status,
          checkIn: at,
        ).toJson(includeCreatedAt: true),
      );
      transaction.set(
        notification,
        _notifications
            .adminNotification(
              id: notification.id,
              actorId: actorUid,
              type: AppNotificationType.attendanceCheckIn,
              title: '${_displayName(employeeName)} checked in',
              body: 'A check-in was recorded for today.',
              referenceId: reference.id,
            )
            .toJson(),
      );
    });
  }

  /// Completes today's existing record once. The check-in timestamp is kept
  /// immutable, so working hours are calculated from the original check-in.
  Future<void> checkOut({
    required String employeeId,
    required String employeeName,
    required DateTime at,
  }) async {
    final actorUid = _requireActorUid();
    final date = DateTime(at.year, at.month, at.day);
    final reference = _records.doc('$employeeId-${_dateKey(date)}');
    final notification = _notifications.newDocument();
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) {
        throw StateError('Check in before checking out.');
      }
      final record = AttendanceRecordModel.fromFirestore(snapshot);
      if (record.checkOut != null) {
        throw StateError('You have already checked out for today.');
      }
      if (record.checkIn == null || !at.isAfter(record.checkIn!)) {
        throw StateError('Check-out time must be after check-in.');
      }
      transaction.update(reference, {
        'checkOut': Timestamp.fromDate(at),
        'workMinutes': at.difference(record.checkIn!).inMinutes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(
        notification,
        _notifications
            .adminNotification(
              id: notification.id,
              actorId: actorUid,
              type: AppNotificationType.attendanceCheckOut,
              title: '${_displayName(employeeName)} checked out',
              body: 'Today\'s attendance record has been completed.',
              referenceId: reference.id,
            )
            .toJson(),
      );
    });
  }

  String _requireActorUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('You must be signed in.');
    return uid;
  }

  String _displayName(String value) {
    final name = value.trim();
    return name.isEmpty ? 'An employee' : name;
  }

  bool _isLate(DateTime value) =>
      value.hour > 9 || (value.hour == 9 && value.minute > 15);

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
