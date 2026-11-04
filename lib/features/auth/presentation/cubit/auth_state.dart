import 'package:equatable/equatable.dart';

import '../../domain/entities/app_user.dart';

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
    this.errorMessage,
  });

  final List<AppUser> users;
  final String? errorMessage;

  AuthUsersLoaded copyWith({
    List<AppUser>? users,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AuthUsersLoaded(
      users: users ?? this.users,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [users, errorMessage];
}

class AuthSuccess extends AuthState {
  const AuthSuccess(this.user);

  final AppUser user;

  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
