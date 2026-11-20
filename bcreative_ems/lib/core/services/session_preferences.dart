import 'package:shared_preferences/shared_preferences.dart';

/// Stores only the identity that opted into restoring a Firebase session.
/// Authentication credentials and tokens remain managed by Firebase Auth.
class SessionPreferences {
  SessionPreferences({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _activeUserIdKey = 'auth.active_user_id';
  static const _employeeProfilesSchemaVersionKey =
      'migration.employee_profiles.schema_version';

  final SharedPreferencesAsync _preferences;

  Future<void> rememberUser(String uid) =>
      _preferences.setString(_activeUserIdKey, uid);

  Future<String?> activeUserId() => _preferences.getString(_activeUserIdKey);

  Future<void> clearRememberedUser() => _preferences.remove(_activeUserIdKey);

  /// Keeps one-time, local migration markers. The data migration itself is
  /// still performed against Firestore; this only prevents repeating a costly
  /// backfill every time a screen receives a live snapshot.
  Future<bool> hasEmployeeProfilesSchemaVersion(int version) async =>
      (await _preferences.getInt(_employeeProfilesSchemaVersionKey) ?? 0) >=
      version;

  Future<void> markEmployeeProfilesSchemaVersion(int version) =>
      _preferences.setInt(_employeeProfilesSchemaVersionKey, version);
}
