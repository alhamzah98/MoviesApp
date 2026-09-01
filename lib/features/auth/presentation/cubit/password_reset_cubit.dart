import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/auth/domain/use_cases/send_password_reset_email.dart';
import 'package:movies_app/features/auth/presentation/cubit/password_reset_state.dart';

class PasswordResetCubit extends Cubit<PasswordResetState> {
  PasswordResetCubit(this._sendPasswordResetEmail)
      : super(const PasswordResetState());

  final SendPasswordResetEmail _sendPasswordResetEmail;

  Future<void> submit(String email) async {
    if (state.isSubmitting) {
      return;
    }

    emit(
      state.copyWith(
        status: PasswordResetStatus.submitting,
        clearErrorMessage: true,
      ),
    );

    try {
      await _sendPasswordResetEmail(email);
      emit(
        state.copyWith(
          status: PasswordResetStatus.success,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PasswordResetStatus.failure,
          errorMessage: error is AppException
              ? error.message
              : 'Unable to send the reset email. Please try again.',
        ),
      );
    }
  }
}
