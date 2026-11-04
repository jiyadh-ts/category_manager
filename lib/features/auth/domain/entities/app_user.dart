import 'package:equatable/equatable.dart';

import '../app_company.dart';
import '../geo_location.dart';
import '../user_address.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.address,
    required this.phone,
    required this.website,
    required this.company,
  });

  /// Session restore only has id and username until Profile loads the rest.
  const AppUser.session({
    required this.id,
    required this.username,
  })  : name = '',
        email = '',
        address = const UserAddress(
          street: '',
          suite: '',
          city: '',
          zipcode: '',
          geo: GeoLocation(lat: '', lng: ''),
        ),
        phone = '',
        website = '',
        company = const AppCompany(
          name: '',
          catchPhrase: '',
          bs: '',
        );

  final int id;
  final String name;
  final String username;
  final String email;
  final UserAddress address;
  final String phone;
  final String website;
  final AppCompany company;

  @override
  List<Object?> get props => [
        id,
        name,
        username,
        email,
        address,
        phone,
        website,
        company,
      ];
}
