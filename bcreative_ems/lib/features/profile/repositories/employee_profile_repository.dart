import 'package:bcreative_ems/features/profile/models/employee_profile_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeProfileRepository {
  EmployeeProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<EmployeeProfileModel?> getProfile(String employeeId) async {
    final document = await _firestore
        .collection('employee_profiles')
        .doc(employeeId)
        .get();
    if (!document.exists) return null;
    return EmployeeProfileModel.fromFirestore(document);
  }

  Stream<EmployeeProfileModel?> watchProfile(String employeeId) => _firestore
      .collection('employee_profiles')
      .doc(employeeId)
      .snapshots()
      .map(
        (document) => document.exists
            ? EmployeeProfileModel.fromFirestore(document)
            : null,
      );
}
