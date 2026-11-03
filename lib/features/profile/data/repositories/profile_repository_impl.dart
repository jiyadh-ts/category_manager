import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/profile_company.dart';
import '../../domain/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<UserProfile> getUserProfile(int userId) async {
    try {
      final response = await _dio.get('/users/$userId');
      final data = response.data;
      if (data is! Map) {
        throw const AppException('The profile API returned no data.');
      }
      return _mapProfile(Map<String, dynamic>.from(data));
    } on AppException {
      rethrow;
    } on DioException catch (error) {
      throw AppException(_dioMessage(error));
    } catch (error) {
      throw AppException('Could not load the profile. $error');
    }
  }

  UserProfile _mapProfile(Map<String, dynamic> json) {
    final companyJson = json['company'];
    Map<String, dynamic> companyMap = const {};
    if (companyJson is Map) {
      companyMap = Map<String, dynamic>.from(companyJson);
    }

    return UserProfile(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      website: json['website'] as String,
      company: ProfileCompany(
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
      return 'Could not connect to the API. Check your internet connection.';
    }
    return 'Could not load the profile from the API.';
  }
}
