import 'package:equatable/equatable.dart';

enum PasswordResetStatus {
  initial,
  submitting,
  success,
  failure,
}

class PasswordResetState extends Equatable {
  const PasswordResetState({
    this.status = PasswordResetStatus.initial,
    this.errorMessage,
  });

  final PasswordResetStatus status;
  final String? errorMessage;

  bool get isSubmitting => status == PasswordResetStatus.submitting;

  PasswordResetState copyWith({
    PasswordResetStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return PasswordResetState(
      status: status ?? this.status,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
