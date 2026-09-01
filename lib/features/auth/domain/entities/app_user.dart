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
      ];
}
