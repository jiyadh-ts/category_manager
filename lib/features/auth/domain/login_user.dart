import 'package:equatable/equatable.dart';

import 'login_company.dart';

class LoginUser extends Equatable {
  const LoginUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.website,
    required this.company,
  });

  final int id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String website;
  final LoginCompany company;

  @override
  List<Object?> get props => [
        id,
        name,
        username,
        email,
        phone,
        website,
        company,
      ];
}
