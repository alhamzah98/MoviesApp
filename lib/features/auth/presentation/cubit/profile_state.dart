import 'package:equatable/equatable.dart';
import 'package:movies_app/features/auth/domain/entities/app_user.dart';

enum ProfileStatus {
  initial,
  loading,
  ready,
  submitting,
  deleted,
  failure,
}

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.user,
    this.errorMessage,
  });

  final ProfileStatus status;
  final AppUser? user;
  final String? errorMessage;

  bool get isSubmitting => status == ProfileStatus.submitting;

  ProfileState copyWith({
    ProfileStatus? status,
    AppUser? user,
    String? errorMessage,
    bool clearUser = false,
    bool clearErrorMessage = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage];
}
