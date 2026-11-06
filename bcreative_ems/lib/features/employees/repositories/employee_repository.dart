import 'package:bcreative_ems/app/constants/roles.dart';
import 'package:bcreative_ems/core/errors/app_exception.dart';
import 'package:bcreative_ems/features/auth/models/user_access_model.dart';
import 'package:bcreative_ems/features/employees/models/employee_model.dart';
import 'package:bcreative_ems/features/employees/models/employment_enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

import '../../../firebase_options.dart';

class EmployeePage {
  const EmployeePage({
    required this.items,
    this.lastDocument,
    this.hasMore = false,
  });

  final List<EmployeeModel> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;
}

class EmployeeOverviewStats {
  const EmployeeOverviewStats({
    required this.total,
    required this.active,
    required this.onLeave,
    required this.inactive,
  });

  final int total;
  final int active;
  final int onLeave;
  final int inactive;
}

class EmployeeRepository {
  EmployeeRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? FirebaseStorage.instance;

  static const int pageSize = 20;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _employees =>
      _firestore.collection('employees');

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection('employee_profiles');

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _auditLogs =>
      _firestore.collection('audit_logs');

  Stream<List<EmployeeModel>> watchAll() => _employees
      .orderBy('fullNameLower')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(EmployeeModel.fromFirestore)
            .toList(growable: false),
      );

  /// Updates the employee-safe projection used by the read-only employee
  /// portal. This also backfills fields added after existing employees were
  /// originally provisioned, without exposing the private `employees` data to
  /// an employee account.
  Future<void> synchronizeProfileProjections(
    Iterable<EmployeeModel> employees,
  ) async {
    final items = employees.toList(growable: false);
    for (var start = 0; start < items.length; start += 400) {
      final batch = _firestore.batch();
      final end = (start + 400).clamp(0, items.length).toInt();
      for (final employee in items.sublist(start, end)) {
        batch.set(
          _profiles.doc(employee.id),
          employee.toProfileJson(),
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    }
  }

  Stream<EmployeeOverviewStats> watchOverview() =>
      _employees.snapshots().map((snapshot) {
        final employees = snapshot.docs
            .map(EmployeeModel.fromFirestore)
            .toList(growable: false);
        return EmployeeOverviewStats(
          total: employees.length,
          active: employees
              .where(
                (employee) =>
                    employee.employmentStatus == EmploymentStatus.active,
              )
              .length,
          onLeave: employees
              .where(
                (employee) =>
                    employee.employmentStatus == EmploymentStatus.onLeave,
              )
              .length,
          inactive: employees
              .where(
                (employee) =>
                    employee.employmentStatus == EmploymentStatus.inactive ||
                    employee.employmentStatus == EmploymentStatus.terminated,
              )
              .length,
        );
      });

  Future<EmployeePage> fetchPage({
    EmploymentStatus? statusFilter,
    String searchQuery = '',
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _employees.orderBy('fullNameLower');

    if (statusFilter != null) {
      query = query.where('employmentStatus', isEqualTo: statusFilter.value);
    }

    final term = searchQuery.trim().toLowerCase();
    if (term.isNotEmpty) {
      query = query
          .where('fullNameLower', isGreaterThanOrEqualTo: term)
          .where('fullNameLower', isLessThan: '$term\uf8ff');
    }

    if (startAfter != null) query = query.startAfterDocument(startAfter);

    final snapshot = await query.limit(pageSize + 1).get();
    final hasMore = snapshot.docs.length > pageSize;
    final pageDocuments = hasMore
        ? snapshot.docs.sublist(0, pageSize)
        : snapshot.docs;

    return EmployeePage(
      items: pageDocuments.map(EmployeeModel.fromFirestore).toList(),
      lastDocument: pageDocuments.isEmpty ? null : pageDocuments.last,
      hasMore: hasMore,
    );
  }

  Future<EmployeeModel?> getById(String id) async {
    final document = await _employees.doc(id).get();
    return document.exists ? EmployeeModel.fromFirestore(document) : null;
  }

  /// Provisions the Firebase Auth account in a secondary app so the signed-in
  /// Super Admin is not logged out, then creates all application records in a
  /// single Firestore batch. No password is ever written to Firestore.
  Future<String> createEmployee(
    EmployeeModel draft, {
    required String temporaryPassword,
  }) async {
    final actorUid = _requireActorUid();
    final appName =
        'employee-provision-${DateTime.now().microsecondsSinceEpoch}';
    final provisioningApp = await Firebase.initializeApp(
      name: appName,
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final provisioningAuth = FirebaseAuth.instanceFor(app: provisioningApp);
    User? provisionedUser;

    try {
      final credential = await provisioningAuth.createUserWithEmailAndPassword(
        email: draft.email.trim(),
        password: temporaryPassword,
      );
      provisionedUser = credential.user;
      if (provisionedUser == null) {
        throw const AuthException(
          'Firebase Auth could not create this employee.',
        );
      }
      await provisionedUser.updateDisplayName(draft.fullName.trim());

      final employeeReference = _employees.doc(provisionedUser.uid);
      final employee = draft.withFirestoreIdentity(
        id: employeeReference.id,
        employeeCode: _employeeCodeFor(employeeReference.id),
      );

      final batch = _firestore.batch();
      batch.set(employeeReference, employee.toJson(includeCreatedAt: true));
      batch.set(_profiles.doc(employee.id), {
        ...employee.toProfileJson(includeUpdatedAt: false),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(
        _users.doc(employee.id),
        UserAccessModel(
          id: employee.id,
          role: AppRoles.employee,
          employeeId: employee.id,
          email: employee.email,
          isActive: employee.isActive,
        ).toJson(includeCreatedAt: true),
      );
      _writeAuditLog(
        batch,
        action: 'employee_created',
        actorUid: actorUid,
        employeeId: employee.id,
      );
      await batch.commit();
      return employee.id;
    } catch (_) {
      if (provisionedUser != null) {
        try {
          await provisionedUser.delete();
        } catch (_) {
          // The account may have been used before the Firestore write failed.
        }
      }
      rethrow;
    } finally {
      await provisioningAuth.signOut();
      await provisioningApp.delete();
    }
  }

  Future<void> updateEmployee(EmployeeModel employee) async {
    final actorUid = _requireActorUid();
    final batch = _firestore.batch();
    batch.update(_employees.doc(employee.id), employee.toJson());
    batch.set(_profiles.doc(employee.id), employee.toProfileJson());
    _writeAuditLog(
      batch,
      action: 'employee_updated',
      actorUid: actorUid,
      employeeId: employee.id,
    );
    await batch.commit();
  }

  Future<String> uploadProfilePhoto({
    required String employeeId,
    required PlatformFile file,
  }) async {
    final bytes = file.bytes;
    final extension = _photoExtension(file.name);
    if (bytes == null ||
        bytes.isEmpty ||
        bytes.lengthInBytes > 2 * 1024 * 1024) {
      throw const ValidationException(
        'Choose a JPG or PNG image smaller than 2 MB.',
      );
    }
    if (extension == null) {
      throw const ValidationException(
        'Profile photos must be JPG or PNG images.',
      );
    }

    // Keep every upload at a unique path. Reusing `profile.jpg` lets browser
    // image caches retain an old (or failed) response even though Firestore
    // has already received a newer download URL.
    final photoVersion = DateTime.now().microsecondsSinceEpoch;
    final reference = _storage.ref(
      'employee_photos/$employeeId/profile_$photoVersion.$extension',
    );
    await reference.putData(
      bytes,
      SettableMetadata(
        contentType: extension == 'png' ? 'image/png' : 'image/jpeg',
      ),
    );
    final url = await reference.getDownloadURL();
    final batch = _firestore.batch();
    batch.update(_employees.doc(employeeId), {
      'profilePhotoUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // Employees cannot read the private `employees` collection. Keep the
    // employee-safe projection in sync so their My Profile avatar updates
    // immediately after an admin uploads a photo.
    batch.set(_profiles.doc(employeeId), {
      'profilePhotoUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
    return url;
  }

  Future<void> deactivate(String employeeId) =>
      _setEmployeeActiveState(employeeId, isActive: false);

  Future<void> reactivate(String employeeId) =>
      _setEmployeeActiveState(employeeId, isActive: true);

  Future<void> _setEmployeeActiveState(
    String employeeId, {
    required bool isActive,
  }) async {
    final actorUid = _requireActorUid();
    final accessDocument = await _users.doc(employeeId).get();
    final batch = _firestore.batch();
    batch.update(_employees.doc(employeeId), {
      'isActive': isActive,
      'employmentStatus': isActive ? 'active' : 'inactive',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_profiles.doc(employeeId), {
      'isActive': isActive,
      'employmentStatus': isActive ? 'active' : 'inactive',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (accessDocument.exists) {
      batch.update(_users.doc(employeeId), {
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    _writeAuditLog(
      batch,
      action: isActive ? 'employee_reactivated' : 'employee_deactivated',
      actorUid: actorUid,
      employeeId: employeeId,
    );
    await batch.commit();
  }

  void _writeAuditLog(
    WriteBatch batch, {
    required String action,
    required String actorUid,
    required String employeeId,
  }) {
    batch.set(_auditLogs.doc(), {
      'action': action,
      'actorUid': actorUid,
      'employeeId': employeeId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String _requireActorUid() {
    final actorUid = _auth.currentUser?.uid;
    if (actorUid == null) {
      throw const AuthException('You must be signed in to manage employees.');
    }
    return actorUid;
  }

  String _employeeCodeFor(String documentId) =>
      'EMP-${documentId.substring(0, 8).toUpperCase()}';

  String? _photoExtension(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.png')) return 'png';
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'jpg';
    return null;
  }
}
