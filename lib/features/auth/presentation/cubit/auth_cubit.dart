import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/session_storage.dart';
import '../../domain/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required AuthRepository repository,
    required SessionStorage sessionStorage,
  })  : _repository = repository,
        _sessionStorage = sessionStorage,
        super(_initialState(sessionStorage));

  final AuthRepository _repository;
  final SessionStorage _sessionStorage;

  static AuthState _initialState(SessionStorage sessionStorage) {
    final savedSession = sessionStorage.readSession();
    if (savedSession != null) {
      return AuthSuccess(savedSession);
    }
    return const AuthInitial();
  }

  Future<void> loadUsers() async {
    if (state is AuthSuccess) {
      return;
    }

    emit(const AuthLoading());
    try {
      final users = await _repository.fetchUsers();
      emit(AuthUsersLoaded(users: users));
    } catch (error) {
      emit(AuthError(_errorMessage(error)));
    }
  }

  void selectUsername(String? username) {
    final currentState = state;
    if (currentState is! AuthUsersLoaded) {
      return;
    }

    emit(
      currentState.copyWith(
        selectedUsername: username,
        clearValidationMessage: true,
      ),
    );
  }

  Future<void> login() async {
    final currentState = state;
    if (currentState is! AuthUsersLoaded) {
      return;
    }

    final username = currentState.selectedUsername;
    if (username == null || username.trim().isEmpty) {
      emit(
        currentState.copyWith(
          validationMessage: 'Please select a user to continue.',
        ),
      );
      return;
    }

    emit(const AuthLoading());
    try {
      final result = await _repository.loginWithUsername(username);
      await _sessionStorage.saveSession(result);
      emit(AuthSuccess(result));
    } catch (error) {
      emit(AuthError(_errorMessage(error)));
    }
  }

  Future<void> logout() async {
    await _sessionStorage.clearSession();
    emit(const AuthInitial());
  }

  String _errorMessage(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Login failed. Please try again.';
  }
}
