import 'package:equatable/equatable.dart';

class AuthResult extends Equatable {
  const AuthResult({
    required this.userId,
    required this.username,
  });

  final int userId;
  final String username;

  @override
  List<Object?> get props => [userId, username];
}
