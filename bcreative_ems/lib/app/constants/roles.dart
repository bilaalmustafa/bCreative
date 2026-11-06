/// Application roles — exactly two: Super Admin and Employee.
abstract final class AppRoles {
  static const String superAdmin = 'super_admin';
  static const String employee = 'employee';

  static const String claimRole = 'role';
  static const String claimEmployeeId = 'employeeId';
}

enum UserRole {
  superAdmin,
  employee,
  unknown;

  static UserRole fromClaim(String? value) {
    switch (value) {
      case AppRoles.superAdmin:
        return UserRole.superAdmin;
      case AppRoles.employee:
        return UserRole.employee;
      default:
        return UserRole.unknown;
    }
  }

  bool get isSuperAdmin => this == UserRole.superAdmin;
  bool get isEmployee => this == UserRole.employee;
}
