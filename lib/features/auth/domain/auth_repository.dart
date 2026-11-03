import 'auth_result.dart';
import 'login_user.dart';

abstract class AuthRepository {
  Future<List<LoginUser>> fetchUsers();

  Future<AuthResult> loginWithUsername(String username);
}
