import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/app_company.dart';
import '../../domain/auth_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/geo_location.dart';
import '../../domain/user_address.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<AppUser>> fetchUsers() async {
    try {
      final response = await _dio.get('/users');
      final data = response.data;
      if (data is! List) {
        throw const AppException('No users were returned by the API.');
      }

      final users = <AppUser>[];
      for (final item in data) {
        if (item is Map) {
          users.add(_mapUser(Map<String, dynamic>.from(item)));
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

  /// Mock auth: one field may match either JSONPlaceholder username or email.
  @override
  AppUser findUserByLogin(List<AppUser> users, String login) {
    final trimmedLogin = login.trim();
    if (trimmedLogin.isEmpty) {
      throw const AppException('Please enter a username or email.');
    }

    final normalized = trimmedLogin.toLowerCase();
    for (final user in users) {
      if (user.username.toLowerCase() == normalized ||
          user.email.toLowerCase() == normalized) {
        return user;
      }
    }

    throw const AppException('Invalid username or email.');
  }

  AppUser _mapUser(Map<String, dynamic> json) {
    final companyJson = json['company'];
    Map<String, dynamic> companyMap = const {};
    if (companyJson is Map) {
      companyMap = Map<String, dynamic>.from(companyJson);
    }

    final addressJson = json['address'];
    Map<String, dynamic> addressMap = const {};
    if (addressJson is Map) {
      addressMap = Map<String, dynamic>.from(addressJson);
    }

    final geoJson = addressMap['geo'];
    Map<String, dynamic> geoMap = const {};
    if (geoJson is Map) {
      geoMap = Map<String, dynamic>.from(geoJson);
    }

    return AppUser(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: UserAddress(
        street: addressMap['street'] as String? ?? '',
        suite: addressMap['suite'] as String? ?? '',
        city: addressMap['city'] as String? ?? '',
        zipcode: addressMap['zipcode'] as String? ?? '',
        geo: GeoLocation(
          lat: geoMap['lat'] as String? ?? '',
          lng: geoMap['lng'] as String? ?? '',
        ),
      ),
      phone: json['phone'] as String? ?? '',
      website: json['website'] as String? ?? '',
      company: AppCompany(
        name: companyMap['name'] as String? ?? '',
        catchPhrase: companyMap['catchPhrase'] as String? ?? '',
        bs: companyMap['bs'] as String? ?? '',
      ),
    );
  }

  String _dioMessage(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'The request timed out. Please try again.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'No internet connectivity. Check your connection and try again.';
    }
    return 'Could not load users from the API.';
  }
}
