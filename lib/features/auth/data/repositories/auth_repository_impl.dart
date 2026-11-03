import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/app_company.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/login_company.dart';
import '../../domain/login_user.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<LoginUser>> fetchUsers() async {
    try {
      final response = await _dio.get('/users');
      final data = response.data;
      if (data is! List) {
        throw const AppException('No users were returned by the API.');
      }

      final users = <LoginUser>[];
      for (final item in data) {
        if (item is Map) {
          users.add(_mapLoginUser(Map<String, dynamic>.from(item)));
        }
      }
      return users;
    } on AppException {
      rethrow;
    } on DioException catch (error) {
      throw AppException(_dioMessage(error));
    } catch (error) {
      throw AppException('Could not load users. $error');
    }
  }

  @override
  Future<AuthResult> loginWithUsername(String username) async {
    final trimmedUsername = username.trim();
    if (trimmedUsername.isEmpty) {
      throw const AppException('Please select a user to log in.');
    }

    final users = await fetchUsers();
    LoginUser? matchedUser;
    for (final user in users) {
      if (user.username.toLowerCase() == trimmedUsername.toLowerCase()) {
        matchedUser = user;
        break;
      }
    }

    if (matchedUser == null) {
      throw const AppException('Selected user was not found in the API data.');
    }

    // JSONPlaceholder has no real auth. We only store the user id and username.
    final appUser = _toAppUser(matchedUser);
    return AuthResult(
      userId: appUser.id,
      username: appUser.username,
    );
  }

  LoginUser _mapLoginUser(Map<String, dynamic> json) {
    final companyJson = json['company'];
    Map<String, dynamic> companyMap = const {};
    if (companyJson is Map) {
      companyMap = Map<String, dynamic>.from(companyJson);
    }

    return LoginUser(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      website: json['website'] as String,
      company: LoginCompany(
        name: companyMap['name'] as String? ?? '',
        catchPhrase: companyMap['catchPhrase'] as String? ?? '',
        bs: companyMap['bs'] as String? ?? '',
      ),
    );
  }

  AppUser _toAppUser(LoginUser user) {
    return AppUser(
      id: user.id,
      name: user.name,
      username: user.username,
      email: user.email,
      phone: user.phone,
      website: user.website,
      company: AppCompany(
        name: user.company.name,
        catchPhrase: user.company.catchPhrase,
        bs: user.company.bs,
      ),
    );
  }

  String _dioMessage(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'The request timed out. Please try again.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Could not connect to the API. Check your internet connection.';
    }
    return 'Could not load users from the API.';
  }
}
