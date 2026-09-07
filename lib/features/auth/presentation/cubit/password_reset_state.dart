import 'package:equatable/equatable.dart';

enum PasswordResetStatus { initial, submitting, success, failure }

class PasswordResetState extends Equatable {
  const PasswordResetState({
    this.status = PasswordResetStatus.initial,
    this.errorMessage,
    this.errorCode,
  });

  final PasswordResetStatus status;
  final String? errorMessage;
  final String? errorCode;

  bool get isSubmitting => status == PasswordResetStatus.submitting;

  PasswordResetState copyWith({
    PasswordResetStatus? status,
    String? errorMessage,
    String? errorCode,
    bool clearErrorMessage = false,
    bool clearErrorCode = false,
  }) {
    return PasswordResetState(
      status: status ?? this.status,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      errorCode: clearErrorCode
          ? null
          : (errorCode ?? this.errorCode),
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, errorCode];
}
