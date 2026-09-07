import 'package:equatable/equatable.dart';

enum DeleteAccountStatus {
  success,
  cancelled,
  failedPreCleanup,
  partialFailure,
}

class DeleteAccountResult extends Equatable {
  const DeleteAccountResult({
    required this.status,
    this.errorMessage,
    this.details,
  });

  final DeleteAccountStatus status;
  final String? errorMessage;
  final String? details;

  bool get isSuccess => status == DeleteAccountStatus.success;
  bool get isCancelled => status == DeleteAccountStatus.cancelled;
  bool get isFailedPreCleanup => status == DeleteAccountStatus.failedPreCleanup;
  bool get isPartialFailure => status == DeleteAccountStatus.partialFailure;

  static const DeleteAccountResult success =
      DeleteAccountResult(status: DeleteAccountStatus.success);

  static const DeleteAccountResult cancelled =
      DeleteAccountResult(status: DeleteAccountStatus.cancelled);

  factory DeleteAccountResult.failedPreCleanup({String? errorMessage}) =>
      DeleteAccountResult(
        status: DeleteAccountStatus.failedPreCleanup,
        errorMessage: errorMessage,
      );

  factory DeleteAccountResult.partialFailure({
    String? errorMessage,
    String? details,
  }) =>
      DeleteAccountResult(
        status: DeleteAccountStatus.partialFailure,
        errorMessage: errorMessage,
        details: details,
      );

  @override
  List<Object?> get props => [status, errorMessage, details];
}
