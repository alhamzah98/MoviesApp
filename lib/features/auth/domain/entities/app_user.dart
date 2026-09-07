import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.email,
    this.name,
    this.phoneNumber,
    this.photoUrl,
    this.avatarId,
    this.isEmailVerified = false,
    this.createdAt,
    this.updatedAt,
    this.providerIds = const [],
  });

  final String uid;
  final String? name;
  final String email;
  final String? phoneNumber;
  final String? photoUrl;
  final String? avatarId;
  final bool isEmailVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> providerIds;

  bool get hasPasswordProvider => providerIds.contains('password');
  bool get hasGoogleProvider => providerIds.contains('google.com');

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? phoneNumber,
    String? photoUrl,
    String? avatarId,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? providerIds,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      avatarId: avatarId ?? this.avatarId,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      providerIds: providerIds ?? this.providerIds,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    name,
    email,
    phoneNumber,
    photoUrl,
    avatarId,
    isEmailVerified,
    createdAt,
    updatedAt,
    providerIds,
  ];
}
