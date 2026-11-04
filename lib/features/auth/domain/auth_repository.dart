import 'entities/app_user.dart';

abstract class AuthRepository {
  Future<List<AppUser>> fetchUsers();

  AppUser findUserByLogin(List<AppUser> users, String login);
}
