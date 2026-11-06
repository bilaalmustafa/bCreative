import 'package:bcreative_ems/app/constants/roles.dart';
import 'package:bcreative_ems/core/services/auth_service.dart';
import 'package:bcreative_ems/features/auth/models/user_access_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthSession {
  const AuthSession({
    required this.uid,
    required this.email,
    required this.role,
    this.employeeId,
  });

  final String uid;
  final String? email;
  final UserRole role;
  final String? employeeId;

  bool get isAuthenticated => uid.isNotEmpty;
}

class AuthRepository {
  AuthRepository(this._authService, {FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final AuthService _authService;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _authService.signInWithEmailPassword(
      email: email,
      password: password,
    );
    return _sessionFromUser(credential.user!, forceRefresh: true);
  }

  Future<void> signOut() => _authService.signOut();

  Future<void> resetPassword(String email) =>
      _authService.sendPasswordResetEmail(email);

  Future<AuthSession> currentSession({bool forceRefresh = false}) async {
    final user = _authService.currentUser;
    if (user == null) {
      return const AuthSession(uid: '', email: null, role: UserRole.unknown);
    }
    return _sessionFromUser(user, forceRefresh: forceRefresh);
  }

  Future<AuthSession> _sessionFromUser(
    User user, {
    required bool forceRefresh,
  }) async {
    final claims = await _authService.getCustomClaims(
      forceRefresh: forceRefresh,
    );
    final roleValue = claims[AppRoles.claimRole] as String?;
    final employeeId = claims[AppRoles.claimEmployeeId] as String?;
    final claimedRole = UserRole.fromClaim(roleValue);

    if (claimedRole != UserRole.unknown) {
      return AuthSession(
        uid: user.uid,
        email: user.email,
        role: claimedRole,
        // Employee documents created by this app use the Auth uid as their
        // document id. Older employee custom claims can be missing
        // `employeeId`, so keep self-service modules working for them too.
        employeeId: claimedRole == UserRole.employee
            ? (employeeId?.isNotEmpty == true ? employeeId : user.uid)
            : employeeId,
      );
    }

    final accessDocument = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();
    if (!accessDocument.exists) {
      return AuthSession(
        uid: user.uid,
        email: user.email,
        role: UserRole.unknown,
      );
    }
    final access = UserAccessModel.fromFirestore(accessDocument);
    return AuthSession(
      uid: user.uid,
      email: user.email,
      role: access.isActive
          ? UserRole.fromClaim(access.role)
          : UserRole.unknown,
      employeeId: access.employeeId,
    );
  }
}
