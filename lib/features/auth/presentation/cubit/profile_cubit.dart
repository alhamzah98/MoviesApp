import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/auth/domain/use_cases/delete_account.dart';
import 'package:movies_app/features/auth/domain/use_cases/get_current_user.dart';
import 'package:movies_app/features/auth/domain/use_cases/update_profile.dart';
import 'package:movies_app/features/auth/presentation/cubit/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required GetCurrentUser getCurrentUser,
    required UpdateProfile updateProfile,
    required DeleteAccount deleteAccount,
  })  : _getCurrentUser = getCurrentUser,
        _updateProfile = updateProfile,
        _deleteAccount = deleteAccount,
        super(const ProfileState());

  final GetCurrentUser _getCurrentUser;
  final UpdateProfile _updateProfile;
  final DeleteAccount _deleteAccount;

  Future<void> loadCurrentUser() async {
    emit(
      state.copyWith(
        status: ProfileStatus.loading,
        clearErrorMessage: true,
      ),
    );

    try {
      final user = await _getCurrentUser();
      if (user == null) {
        emit(
          state.copyWith(
            status: ProfileStatus.failure,
            clearUser: true,
            errorMessage: 'Please sign in again to manage your profile.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: ProfileStatus.ready,
          user: user,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: _messageFrom(error),
        ),
      );
    }
  }

  Future<void> updateProfile({
    required String name,
    required String phoneNumber,
    required String avatarId,
  }) async {
    if (state.isSubmitting) {
      return;
    }

    emit(
      state.copyWith(
        status: ProfileStatus.submitting,
        clearErrorMessage: true,
      ),
    );

    try {
      final user = await _updateProfile(
        name: name,
        phoneNumber: phoneNumber,
        avatarId: avatarId,
      );
      emit(
        state.copyWith(
          status: ProfileStatus.ready,
          user: user,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: _messageFrom(error),
        ),
      );
    }
  }

  Future<void> deleteAccount() async {
    if (state.isSubmitting) {
      return;
    }

    emit(
      state.copyWith(
        status: ProfileStatus.submitting,
        clearErrorMessage: true,
      ),
    );

    try {
      await _deleteAccount();
      emit(
        state.copyWith(
          status: ProfileStatus.deleted,
          clearUser: true,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: _messageFrom(error),
        ),
      );
    }
  }

  String _messageFrom(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Unable to update your profile. Please try again.';
  }
}
