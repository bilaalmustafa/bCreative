import 'dart:async';

import 'package:bcreative_ems/core/errors/failure_mapper.dart';
import 'package:bcreative_ems/features/auth/viewmodels/auth_controller.dart';
import 'package:bcreative_ems/features/profile/models/employee_profile_model.dart';
import 'package:bcreative_ems/features/profile/repositories/employee_profile_repository.dart';
import 'package:get/get.dart';

/// Read-only state for the authenticated employee's own profile.
class EmployeeProfileController extends GetxController {
  EmployeeProfileController(this._repository, this._authController);

  final EmployeeProfileRepository _repository;
  final AuthController _authController;

  final profile = Rxn<EmployeeProfileModel>();
  final isLoading = true.obs;
  final errorMessage = RxnString();
  StreamSubscription<EmployeeProfileModel?>? _profileSubscription;
  Worker? _sessionWorker;
  String? _listenedEmployeeId;

  /// Employee records provisioned by this app use the Firebase Auth uid as
  /// their document id. [employeeId] keeps older custom-claim accounts
  /// compatible while falling back to that authenticated uid.
  String get employeeId {
    final session = _authController.session.value;
    final claimedEmployeeId = session?.employeeId?.trim();
    if (claimedEmployeeId != null && claimedEmployeeId.isNotEmpty) {
      return claimedEmployeeId;
    }
    return session?.uid ?? '';
  }

  @override
  void onInit() {
    super.onInit();
    _sessionWorker = ever(_authController.session, (_) {
      if (employeeId != _listenedEmployeeId) _watchProfile();
    });
    _watchProfile();
  }

  /// Allows the screen to recover after a temporary connection or rules
  /// refresh without requiring the employee to sign out and back in.
  void retry() => _watchProfile();

  void _watchProfile() {
    final id = employeeId;
    _profileSubscription?.cancel();
    _profileSubscription = null;
    _listenedEmployeeId = id;
    if (id.isEmpty) {
      profile.value = null;
      errorMessage.value = 'Your employee account could not be identified.';
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    _profileSubscription = _repository
        .watchProfile(id)
        .listen(
          (value) {
            profile.value = value;
            isLoading.value = false;
          },
          onError: (Object error) {
            errorMessage.value = FailureMapper.message(error);
            isLoading.value = false;
          },
        );
  }

  @override
  void onClose() {
    _profileSubscription?.cancel();
    _sessionWorker?.dispose();
    super.onClose();
  }
}
