import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/auth/domain/entities/app_user.dart';
import 'package:movies_app/features/auth/domain/use_cases/delete_account.dart';
import 'package:movies_app/features/auth/domain/use_cases/get_current_user.dart';
import 'package:movies_app/features/auth/domain/use_cases/update_profile.dart';
import 'package:movies_app/features/auth/presentation/cubit/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required GetCurrentUser getCurrentUser,
    required UpdateProfile updateProfile,
    required DeleteAccount deleteAccount,
  }) : _getCurrentUser = getCurrentUser,
       _updateProfile = updateProfile,
       _deleteAccount = deleteAccount,
       super(const ProfileState());

  final GetCurrentUser _getCurrentUser;
  final UpdateProfile _updateProfile;
  final DeleteAccount _deleteAccount;

  int _sessionGeneration = 0;
  String? _expectedUid;

  void reset() {
    _sessionGeneration++;
    _expectedUid = null;
    emit(const ProfileState());
  }

  Future<void> loadCurrentUser({String? expectedUid}) async {
    final generation = ++_sessionGeneration;
    if (expectedUid != null) {
      _expectedUid = expectedUid;
    }
    emit(
      state.copyWith(status: ProfileStatus.loading, clearErrorMessage: true),
    );

    try {
      final user = await _getCurrentUser();
      if (isClosed || generation != _sessionGeneration) {
        return;
      }
      if (_expectedUid != null && user != null && user.uid != _expectedUid) {
        return;
      }
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
      if (isClosed || generation != _sessionGeneration) {
        return;
      }
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: _messageFrom(error),
        ),
      );
    }
  }

  /// Updates profile data.
  ///
  /// Returns the updated [AppUser] on success, or `null` on failure.
  /// This provides callers with an unambiguous success contract.
  Future<AppUser?> updateProfile({
    required String name,
    required String phoneNumber,
    required String avatarId,
  }) async {
    if (state.isSubmitting) {
      return null;
    }

    final generation = ++_sessionGeneration;
    emit(
      state.copyWith(status: ProfileStatus.submitting, clearErrorMessage: true),
    );

    try {
      final user = await _updateProfile(
        name: name,
        phoneNumber: phoneNumber,
        avatarId: avatarId,
      );
      if (isClosed || generation != _sessionGeneration) {
        return null;
      }
      if (_expectedUid != null && user.uid != _expectedUid) {
        return null;
      }
      emit(
        state.copyWith(
          status: ProfileStatus.ready,
          user: user,
          clearErrorMessage: true,
        ),
      );
      return user;
    } catch (error) {
      if (isClosed || generation != _sessionGeneration) {
        return null;
      }
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: _messageFrom(error),
        ),
      );
      return null;
    }
  }

  Future<void> deleteAccount() async {
    if (state.isSubmitting) {
      return;
    }

    final generation = ++_sessionGeneration;
    emit(
      state.copyWith(status: ProfileStatus.submitting, clearErrorMessage: true),
    );

    try {
      await _deleteAccount();
      if (isClosed || generation != _sessionGeneration) {
        return;
      }
      emit(
        state.copyWith(
          status: ProfileStatus.deleted,
          clearUser: true,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      if (isClosed || generation != _sessionGeneration) {
        return;
      }
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
