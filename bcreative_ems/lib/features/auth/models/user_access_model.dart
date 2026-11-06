import 'package:cloud_firestore/cloud_firestore.dart';

/// Minimal access record used for accounts provisioned without an Admin SDK.
///
/// Firebase custom claims cannot be written from a Flutter client. Super Admin
/// accounts still use their existing custom claim, while employee accounts use
/// this protected document to resolve their application role and profile ID.
class UserAccessModel {
  const UserAccessModel({
    required this.id,
    required this.role,
    required this.employeeId,
    required this.email,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String role;
  final String employeeId;
  final String email;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserAccessModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return UserAccessModel(
      id: document.id,
      role: data['role'] as String? ?? '',
      employeeId: data['employeeId'] as String? ?? '',
      email: data['email'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson({bool includeCreatedAt = false}) => {
    'role': role,
    'employeeId': employeeId,
    'email': email.trim().toLowerCase(),
    'isActive': isActive,
    if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
