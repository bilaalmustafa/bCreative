import 'package:shared_preferences/shared_preferences.dart';

/// Stores only the identity that opted into restoring a Firebase session.
/// Authentication credentials and tokens remain managed by Firebase Auth.
class SessionPreferences {
  SessionPreferences({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _activeUserIdKey = 'auth.active_user_id';

  final SharedPreferencesAsync _preferences;

  Future<void> rememberUser(String uid) =>
      _preferences.setString(_activeUserIdKey, uid);

  Future<String?> activeUserId() => _preferences.getString(_activeUserIdKey);

  Future<void> clearRememberedUser() => _preferences.remove(_activeUserIdKey);
}
