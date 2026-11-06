import 'package:bcreative_ems/features/employees/models/employee_model.dart';
import 'package:bcreative_ems/features/notifications/models/app_notification_model.dart';
import 'package:bcreative_ems/features/notifications/repositories/notification_repository.dart';
import 'package:bcreative_ems/features/payroll/models/payroll_record_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class PayrollRepository {
  PayrollRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
    NotificationRepository? notifications,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _notifications =
           notifications ?? NotificationRepository(firestore: firestore);

  static const _maxSlipSizeBytes = 10 * 1024 * 1024;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final NotificationRepository _notifications;

  CollectionReference<Map<String, dynamic>> get _employees =>
      _firestore.collection('employees');
  CollectionReference<Map<String, dynamic>> get _records =>
      _firestore.collection('payroll_records');

  Stream<List<EmployeeModel>> watchEmployees() => _employees.snapshots().map((
    snapshot,
  ) {
    final employees = snapshot.docs
        .map(EmployeeModel.fromFirestore)
        .toList(growable: false);
    employees.sort(
      (first, second) =>
          first.fullName.toLowerCase().compareTo(second.fullName.toLowerCase()),
    );
    return employees;
  });

  Stream<List<PayrollRecordModel>> watchRecords(String periodKey) => _records
      .where('periodKey', isEqualTo: periodKey)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(PayrollRecordModel.fromFirestore)
            .toList(growable: false),
      );

  Stream<List<PayrollRecordModel>> watchEmployeeRecords(String employeeId) =>
      _records.where('employeeId', isEqualTo: employeeId).snapshots().map((
        snapshot,
      ) {
        final records = snapshot.docs
            .map(PayrollRecordModel.fromFirestore)
            .toList(growable: false);
        records.sort(
          (first, second) => second.periodKey.compareTo(first.periodKey),
        );
        return records;
      });

  Future<void> createRecords(List<PayrollRecordModel> records) async {
    if (records.isEmpty) return;
    final actorUid = _auth.currentUser?.uid;
    if (actorUid == null) throw StateError('You must be signed in.');
    final notifications = [
      for (final record in records)
        (
          _notifications.newDocument(),
          _notifications.employeeNotification(
            employeeId: record.employeeId,
            actorId: actorUid,
            type: AppNotificationType.payrollPaid,
            title: 'Salary paid',
            body:
                'Your salary for ${record.periodKey} has been marked as paid.',
            referenceId: record.id,
          ),
        ),
    ];
    await _firestore.runTransaction((transaction) async {
      final references = records.map((record) => _records.doc(record.id));
      for (final reference in references) {
        if ((await transaction.get(reference)).exists) {
          throw StateError('A payroll record already exists for this month.');
        }
      }
      for (final record in records) {
        transaction.set(
          _records.doc(record.id),
          record.toJson(includeCreatedAt: true),
        );
      }
      for (final notification in notifications) {
        transaction.set(notification.$1, notification.$2.toJson());
      }
    });
  }

  Future<void> attachSalarySlip({
    required PayrollRecordModel record,
    required PlatformFile file,
  }) async {
    _validateSalarySlip(file);
    final fileName = file.name.trim();
    final storageReference = _storage.ref(
      'payroll_slips/${record.employeeId}/${record.periodKey}/'
      '${record.id}/${DateTime.now().microsecondsSinceEpoch}-$fileName',
    );
    final upload = storageReference.putData(
      file.bytes!,
      SettableMetadata(contentType: _contentTypeFor(fileName)),
    );

    try {
      await upload;
      await _records.doc(record.id).update({
        'slipFileName': fileName,
        'slipStoragePath': storageReference.fullPath,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      try {
        await storageReference.delete();
      } catch (_) {
        // Preserve the original upload/database error for the caller.
      }
      rethrow;
    }

    final oldPath = record.slipStoragePath;
    if (oldPath != null &&
        oldPath.isNotEmpty &&
        oldPath != storageReference.fullPath) {
      try {
        await _storage.ref(oldPath).delete();
      } on FirebaseException catch (error) {
        if (error.code != 'object-not-found') rethrow;
      }
    }
  }

  Future<String?> getSalarySlipDownloadUrl(PayrollRecordModel record) async {
    final path = record.slipStoragePath;
    if (path == null || path.isEmpty) return null;
    return _storage.ref(path).getDownloadURL();
  }

  void _validateSalarySlip(PlatformFile file) {
    final bytes = file.bytes;
    if (bytes == null || bytes.lengthInBytes > _maxSlipSizeBytes) {
      throw ArgumentError('Choose a salary slip smaller than 10 MB.');
    }
    if (_contentTypeFor(file.name) == null) {
      throw ArgumentError('Only PDF, PNG, and JPG salary slips are allowed.');
    }
  }

  String? _contentTypeFor(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.pdf')) return 'application/pdf';
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
    return null;
  }
}
