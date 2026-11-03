import 'package:equatable/equatable.dart';

import '../app_company.dart';

class AppUser extends Equatable {
  const AppUser({
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
  final AppCompany company;

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
