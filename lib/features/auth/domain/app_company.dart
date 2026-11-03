import 'package:equatable/equatable.dart';

class AppCompany extends Equatable {
  const AppCompany({
    required this.name,
    required this.catchPhrase,
    required this.bs,
  });

  final String name;
  final String catchPhrase;
  final String bs;

  @override
  List<Object?> get props => [name, catchPhrase, bs];
}
