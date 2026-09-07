import 'package:equatable/equatable.dart';
import 'package:movies_app/features/auth/domain/entities/app_user.dart';

enum AuthStatus {
  initial,
  checking,
  unauthenticated,
  submitting,
  authenticated,
  failure,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.errorCode,
  });

  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;
  final String? errorCode;

  bool get isSubmitting => status == AuthStatus.submitting;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? errorMessage,
    String? errorCode,
    bool clearUser = false,
    bool clearErrorMessage = false,
    bool clearErrorCode = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      errorCode: clearErrorCode
          ? null
          : (errorCode ?? this.errorCode),
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage, errorCode];
}
