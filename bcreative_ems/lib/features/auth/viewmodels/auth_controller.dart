import 'dart:async';

import 'package:bcreative_ems/app/constants/roles.dart';
import 'package:bcreative_ems/app/routes/app_routes.dart';
import 'package:bcreative_ems/features/auth/repositories/auth_repository.dart';
import 'package:bcreative_ems/core/services/session_preferences.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  AuthController(this._repository, this._sessionPreferences);

  final AuthRepository _repository;
  final SessionPreferences _sessionPreferences;

  final Rxn<AuthSession> session = Rxn<AuthSession>();
  final RxBool isLoading = false.obs;
  final RxBool isBootstrapping = true.obs;

  StreamSubscription? _authSub;

  bool get isAuthenticated =>
      session.value != null && session.value!.isAuthenticated;

  UserRole get role => session.value?.role ?? UserRole.unknown;

  @override
  void onInit() {
    super.onInit();
    _authSub = _repository.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(dynamic user) async {
    if (user == null) {
      await _clearRememberedUser();
      session.value = const AuthSession(
        uid: '',
        email: null,
        role: UserRole.unknown,
      );
      isBootstrapping.value = false;
      return;
    }
    try {
      final restoredSession = await _repository.currentSession(
        forceRefresh: true,
      );
      if (restoredSession.role == UserRole.unknown) {
        await _clearRememberedUser();
        session.value = const AuthSession(
          uid: '',
          email: null,
          role: UserRole.unknown,
        );
        return;
      }
      session.value = restoredSession;
      await _rememberUser(restoredSession.uid);
    } catch (_) {
      await _clearRememberedUser();
      session.value = const AuthSession(
        uid: '',
        email: null,
        role: UserRole.unknown,
      );
    } finally {
      isBootstrapping.value = false;
    }
  }

  Future<void> refreshSession() async {
    final refreshedSession = await _repository.currentSession(
      forceRefresh: true,
    );
    await setAuthenticatedSession(refreshedSession);
  }

  Future<void> setAuthenticatedSession(AuthSession authenticatedSession) async {
    session.value = authenticatedSession;
    if (authenticatedSession.role == UserRole.unknown) {
      await _clearRememberedUser();
      return;
    }
    await _rememberUser(authenticatedSession.uid);
  }

  Future<void> signOut() async {
    await _repository.signOut();
    await _clearRememberedUser();
    session.value = const AuthSession(
      uid: '',
      email: null,
      role: UserRole.unknown,
    );
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> _rememberUser(String uid) async {
    try {
      await _sessionPreferences.rememberUser(uid);
    } catch (_) {
      // Firebase remains the source of truth if local preference storage fails.
    }
  }

  Future<void> _clearRememberedUser() async {
    try {
      await _sessionPreferences.clearRememberedUser();
    } catch (_) {
      // Local cleanup must not block Firebase authentication state updates.
    }
  }

  String get homeRoute {
    return switch (role) {
      UserRole.superAdmin => AppRoutes.adminDashboard,
      UserRole.employee => AppRoutes.employeeDashboard,
      UserRole.unknown => AppRoutes.login,
    };
  }

  @override
  void onClose() {
    _authSub?.cancel();
    super.onClose();
  }
}
