import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/domain/auth_result.dart';

class SessionStorage {
  SessionStorage(this._prefs);

  static const _userIdKey = 'user_id';
  static const _usernameKey = 'username';

  final SharedPreferences _prefs;

  AuthResult? readSession() {
    final userId = _prefs.getInt(_userIdKey);
    final username = _prefs.getString(_usernameKey);

    if (userId == null || username == null || username.isEmpty) {
      return null;
    }

    return AuthResult(userId: userId, username: username);
  }

  Future<void> saveSession(AuthResult result) async {
    await _prefs.setInt(_userIdKey, result.userId);
    await _prefs.setString(_usernameKey, result.username);
  }

  Future<void> clearSession() async {
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_usernameKey);
  }
}
