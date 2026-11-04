import 'package:category_manager/core/storage/session_storage.dart';
import 'package:category_manager/features/auth/domain/auth_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saves and restores a login session', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = SessionStorage(prefs);

    await storage.saveSession(
      const AuthResult(userId: 1, username: 'Bret'),
    );

    final session = storage.readSession();
    expect(session, isNotNull);
    expect(session!.userId, 1);
    expect(session.username, 'Bret');
  });

  test('clears the login session on logout', () async {
    SharedPreferences.setMockInitialValues({
      'user_id': 1,
      'username': 'Bret',
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = SessionStorage(prefs);

    await storage.clearSession();

    expect(storage.readSession(), isNull);
  });
}
