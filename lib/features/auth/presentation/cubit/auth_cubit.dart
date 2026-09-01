import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/auth/domain/entities/app_user.dart';
import 'package:movies_app/features/auth/domain/use_cases/observe_auth_state.dart';
import 'package:movies_app/features/auth/domain/use_cases/register_with_email.dart';
import 'package:movies_app/features/auth/domain/use_cases/sign_in_with_email.dart';
import 'package:movies_app/features/auth/domain/use_cases/sign_in_with_google.dart';
import 'package:movies_app/features/auth/domain/use_cases/sign_out.dart';
import 'package:movies_app/features/auth/presentation/cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required ObserveAuthState observeAuthState,
    required SignInWithEmail signInWithEmail,
    required RegisterWithEmail registerWithEmail,
    required SignInWithGoogle signInWithGoogle,
    required SignOut signOut,
  })  : _observeAuthState = observeAuthState,
        _signInWithEmail = signInWithEmail,
        _registerWithEmail = registerWithEmail,
        _signInWithGoogle = signInWithGoogle,
        _signOut = signOut,
        super(const AuthState());

  final ObserveAuthState _observeAuthState;
  final SignInWithEmail _signInWithEmail;
  final RegisterWithEmail _registerWithEmail;
  final SignInWithGoogle _signInWithGoogle;
  final SignOut _signOut;

  StreamSubscription<AppUser?>? _authSubscription;

  void startListening() {
    if (_authSubscription != null) {
      return;
    }

    emit(state.copyWith(status: AuthStatus.checking, clearErrorMessage: true));

    _authSubscription = _observeAuthState().listen(
      (user) {
        if (user == null) {
          emit(
            state.copyWith(
              status: AuthStatus.unauthenticated,
              clearUser: true,
              clearErrorMessage: true,
            ),
          );
          return;
        }

        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            clearErrorMessage: true,
          ),
        );
      },
      onError: (Object error) {
        emit(
          state.copyWith(
            status: AuthStatus.failure,
            errorMessage: _messageFrom(error),
            clearUser: true,
          ),
        );
      },
    );
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (state.isSubmitting) {
      return;
    }

    emit(
      state.copyWith(
        status: AuthStatus.submitting,
        clearErrorMessage: true,
      ),
    );

    try {
      final user = await _signInWithEmail(
        email: email,
        password: password,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: _messageFrom(error),
        ),
      );
    }
  }

  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String phoneNumber,
    required String avatarId,
  }) async {
    if (state.isSubmitting) {
      return;
    }

    emit(
      state.copyWith(
        status: AuthStatus.submitting,
        clearErrorMessage: true,
      ),
    );

    try {
      final user = await _registerWithEmail(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        phoneNumber: phoneNumber,
        avatarId: avatarId,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: _messageFrom(error),
        ),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    if (state.isSubmitting) {
      return;
    }

    emit(
      state.copyWith(
        status: AuthStatus.submitting,
        clearErrorMessage: true,
      ),
    );

    try {
      final user = await _signInWithGoogle();
      if (user == null) {
        // Cancellation is not treated as an authentication failure.
        emit(
          state.copyWith(
            status: state.user == null
                ? AuthStatus.unauthenticated
                : AuthStatus.authenticated,
            clearErrorMessage: true,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: _messageFrom(error),
        ),
      );
    }
  }

  Future<void> signOut() async {
    if (state.isSubmitting) {
      return;
    }

    emit(
      state.copyWith(
        status: AuthStatus.submitting,
        clearErrorMessage: true,
      ),
    );

    try {
      await _signOut();
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: _messageFrom(error),
        ),
      );
    }
  }

  String _messageFrom(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Authentication failed. Please try again.';
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    _authSubscription = null;
    return super.close();
  }
}
