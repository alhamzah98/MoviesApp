import 'package:equatable/equatable.dart';
import 'package:movies_app/features/auth/domain/entities/app_user.dart';
import 'package:movies_app/features/auth/domain/entities/delete_account_result.dart';

enum ProfileStatus {
  initial,
  loading,
  ready,
  submitting,
  deleted,
  partialFailure,
  failure,
}

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.user,
    this.errorMessage,
    this.lastDeleteResult,
  });

  final ProfileStatus status;
  final AppUser? user;
  final String? errorMessage;
  final DeleteAccountResult? lastDeleteResult;

  bool get isSubmitting => status == ProfileStatus.submitting;
  bool get isDeleted => status == ProfileStatus.deleted;
  bool get isPartialFailure => status == ProfileStatus.partialFailure;

  ProfileState copyWith({
    ProfileStatus? status,
    AppUser? user,
    String? errorMessage,
    DeleteAccountResult? lastDeleteResult,
    bool clearUser = false,
    bool clearErrorMessage = false,
    bool clearDeleteResult = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      lastDeleteResult: clearDeleteResult
          ? null
          : (lastDeleteResult ?? this.lastDeleteResult),
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage, lastDeleteResult];
}
