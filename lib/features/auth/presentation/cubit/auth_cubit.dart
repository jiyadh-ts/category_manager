import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/session_storage.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_result.dart';
import '../../domain/entities/app_user.dart';
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
      return AuthSuccess(
        AppUser.session(
          id: savedSession.userId,
          username: savedSession.username,
        ),
      );
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

  Future<void> login(String username) async {
    final currentState = state;
    if (currentState is! AuthUsersLoaded) {
      return;
    }

    try {
      final user = _repository.findUserByLogin(currentState.users, username);
      await _sessionStorage.saveSession(
        AuthResult(userId: user.id, username: user.username),
      );
      emit(AuthSuccess(user));
    } on AppException catch (error) {
      emit(currentState.copyWith(errorMessage: error.message));
    } catch (error) {
      emit(currentState.copyWith(errorMessage: _errorMessage(error)));
    }
  }

  void clearErrorMessage() {
    final currentState = state;
    if (currentState is AuthUsersLoaded && currentState.errorMessage != null) {
      emit(currentState.copyWith(clearErrorMessage: true));
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
    return 'Something went wrong. Please try again.';
  }
}
