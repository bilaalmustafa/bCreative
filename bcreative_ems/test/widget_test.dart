import 'package:bcreative_ems/app/constants/roles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UserRole.fromClaim maps known roles', () {
    expect(UserRole.fromClaim('super_admin'), UserRole.superAdmin);
    expect(UserRole.fromClaim('employee'), UserRole.employee);
    expect(UserRole.fromClaim(null), UserRole.unknown);
  });
}
