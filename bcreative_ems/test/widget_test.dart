import 'package:bcreative_ems/app/constants/roles.dart';
import 'package:bcreative_ems/core/errors/failure_mapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UserRole.fromClaim maps known roles', () {
    expect(UserRole.fromClaim('super_admin'), UserRole.superAdmin);
    expect(UserRole.fromClaim('employee'), UserRole.employee);
    expect(UserRole.fromClaim(null), UserRole.unknown);
  });

  test('FailureMapper keeps attendance errors actionable', () {
    expect(
      FailureMapper.message(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      ),
      contains('Permission was denied'),
    );
    expect(
      FailureMapper.message(StateError('Check in before checking out.')),
      'Check in before checking out.',
    );
    expect(
      FailureMapper.message(
        Exception('FirebaseError: Missing or insufficient permissions.'),
      ),
      contains('Permission was denied'),
    );
  });
}
