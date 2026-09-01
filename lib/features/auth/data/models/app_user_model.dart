import 'package:firebase_auth/firebase_auth.dart';
import 'package:movies_app/core/utils/json_parsers.dart';
import 'package:movies_app/features/auth/domain/entities/app_user.dart';

class AppUserModel {
  const AppUserModel({
    required this.uid,
    required this.email,
    this.name,
    this.phoneNumber,
    this.photoUrl,
    this.avatarId,
    this.isEmailVerified = false,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
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
  final DateTime? lastLoginAt;

  factory AppUserModel.fromMap(Map<String, dynamic> map) {
    return AppUserModel(
      uid: JsonParsers.asStringOrEmpty(map['uid']),
      name: _nullableTrimmed(JsonParsers.asString(map['name'])),
      email: JsonParsers.asStringOrEmpty(map['email']),
      phoneNumber: _nullableTrimmed(JsonParsers.asString(map['phoneNumber'])),
      photoUrl: _nullableTrimmed(JsonParsers.asString(map['photoUrl'])),
      avatarId: _nullableTrimmed(JsonParsers.asString(map['avatarId'])),
      isEmailVerified: JsonParsers.asBool(map['isEmailVerified']) ?? false,
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),
      lastLoginAt: parseDateTime(map['lastLoginAt']),
    );
  }

  factory AppUserModel.fromFirebaseUser(
    User user, {
    String? avatarId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return AppUserModel.fromAuthUser(
      uid: user.uid,
      email: user.email ?? '',
      name: user.displayName,
      phoneNumber: user.phoneNumber,
      photoUrl: user.photoURL,
      avatarId: avatarId,
      isEmailVerified: user.emailVerified,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastLoginAt: lastLoginAt,
    );
  }

  factory AppUserModel.fromAuthUser({
    required String uid,
    required String email,
    String? name,
    String? phoneNumber,
    String? photoUrl,
    String? avatarId,
    bool isEmailVerified = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return AppUserModel(
      uid: uid,
      email: email,
      name: _nullableTrimmed(name),
      phoneNumber: _nullableTrimmed(phoneNumber),
      photoUrl: _nullableTrimmed(photoUrl),
      avatarId: _nullableTrimmed(avatarId),
      isEmailVerified: isEmailVerified,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastLoginAt: lastLoginAt,
    );
  }

  static DateTime? parseDateTime(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }

    // Firestore Timestamp duck-typing without importing Firebase in tests.
    try {
      final dynamic dynamicValue = value;
      final toDate = dynamicValue.toDate;
      if (toDate is Function) {
        final result = toDate.call();
        if (result is DateTime) {
          return result;
        }
      }
      final millis = dynamicValue.millisecondsSinceEpoch;
      if (millis is int) {
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  AppUser toEntity() {
    return AppUser(
      uid: uid,
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      photoUrl: photoUrl,
      avatarId: avatarId,
      isEmailVerified: isEmailVerified,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toFirestoreMap({
    required Object createdAtValue,
    required Object updatedAtValue,
    Object? lastLoginAtValue,
    bool includeLastLoginAt = false,
  }) {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'avatarId': avatarId,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAtValue,
      'updatedAt': updatedAtValue,
      if (includeLastLoginAt) 'lastLoginAt': lastLoginAtValue,
    };
  }

  static String? _nullableTrimmed(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
