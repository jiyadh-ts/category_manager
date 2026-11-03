import 'package:equatable/equatable.dart';

import '../../domain/auth_result.dart';
import '../../domain/login_user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthUsersLoaded extends AuthState {
  const AuthUsersLoaded({
    required this.users,
    this.selectedUsername,
    this.validationMessage,
  });

  final List<LoginUser> users;
  final String? selectedUsername;
  final String? validationMessage;

  AuthUsersLoaded copyWith({
    List<LoginUser>? users,
    String? selectedUsername,
    String? validationMessage,
    bool clearValidationMessage = false,
  }) {
    return AuthUsersLoaded(
      users: users ?? this.users,
      selectedUsername: selectedUsername ?? this.selectedUsername,
      validationMessage: clearValidationMessage
          ? null
          : validationMessage ?? this.validationMessage,
    );
  }

  @override
  List<Object?> get props => [users, selectedUsername, validationMessage];
}

class AuthSuccess extends AuthState {
  const AuthSuccess(this.result);

  final AuthResult result;

  @override
  List<Object?> get props => [result];
}

class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
