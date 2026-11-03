import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository) : super(const ProfileInitial());

  final ProfileRepository _repository;
  int? _userId;

  Future<void> loadProfile(int userId) async {
    _userId = userId;
    emit(const ProfileLoading());
    try {
      final profile = await _repository.getUserProfile(userId);
      emit(ProfileLoaded(profile));
    } catch (error) {
      emit(ProfileError(_errorMessage(error)));
    }
  }

  Future<void> retry() async {
    final userId = _userId;
    if (userId == null) {
      emit(const ProfileError('No logged-in user was found.'));
      return;
    }
    await loadProfile(userId);
  }

  String _errorMessage(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Could not load the profile. Please try again.';
  }
}
