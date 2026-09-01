import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/auth/data/auth_error_mapper.dart';
import 'package:movies_app/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:movies_app/features/auth/data/models/app_user_model.dart';
import 'package:movies_app/features/auth/domain/entities/app_user.dart';

class AuthFirebaseDataSource implements AuthRemoteDataSource {
  AuthFirebaseDataSource({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firebaseFirestore,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _firebaseFirestore = firebaseFirestore,
        _googleSignIn = googleSignIn;

  static const String _usersCollection = 'users';

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firebaseFirestore;
  final GoogleSignIn _googleSignIn;

  Future<void>? _googleInitializationFuture;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firebaseFirestore.collection(_usersCollection);

  @override
  Stream<AppUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        return null;
      }
      return _loadOrCreateProfileForAuthUser(user, updateLastLogin: false);
    });
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return null;
    }
    return _loadOrCreateProfileForAuthUser(user, updateLastLogin: false);
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AppException(
          'Unable to sign in. Please try again.',
          code: 'unknown',
        );
      }
      return _loadOrCreateProfileForAuthUser(user, updateLastLogin: true);
    } on AppException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw AuthErrorMapper.fromCode(error.code, originalError: error);
    } catch (error) {
      throw AuthErrorMapper.fromCode(
        null,
        originalError: error,
        fallbackMessage: 'Unable to sign in. Please try again.',
      );
    }
  }

  @override
  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String avatarId,
  }) async {
    User? createdUser;
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      createdUser = credential.user;
      if (createdUser == null) {
        throw const AppException(
          'Unable to create your account. Please try again.',
          code: 'unknown',
        );
      }

      await createdUser.updateDisplayName(name);

      final model = AppUserModel.fromAuthUser(
        uid: createdUser.uid,
        email: email,
        name: name,
        phoneNumber: phoneNumber,
        avatarId: avatarId,
        isEmailVerified: createdUser.emailVerified,
      );

      try {
        await _users.doc(createdUser.uid).set(
              model.toFirestoreMap(
                createdAtValue: FieldValue.serverTimestamp(),
                updatedAtValue: FieldValue.serverTimestamp(),
                lastLoginAtValue: FieldValue.serverTimestamp(),
                includeLastLoginAt: true,
              ),
            );
      } catch (profileError) {
        await _bestEffortDeleteAuthUser(createdUser);
        throw _mapFirestoreError(
          profileError,
          fallbackMessage:
              'Your account was created, but saving your profile failed. Please try again.',
        );
      }

      return await _readUserProfile(createdUser.uid) ?? model.toEntity();
    } on AppException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw AuthErrorMapper.fromCode(error.code, originalError: error);
    } catch (error) {
      throw AuthErrorMapper.fromCode(
        null,
        originalError: error,
        fallbackMessage: 'Unable to create your account. Please try again.',
      );
    }
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw AuthErrorMapper.fromCode(
          'google-config',
          fallbackMessage:
              'Google Sign-In did not return a valid ID token. Please check configuration.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw const AppException(
          'Unable to complete Google sign-in. Please try again.',
          code: 'unknown',
        );
      }

      return _mergeGoogleProfile(user, account);
    } on AppException {
      rethrow;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      throw AuthErrorMapper.fromCode(
        'google-config',
        originalError: error,
        fallbackMessage: 'Google sign-in failed. Please try again.',
      );
    } on FirebaseAuthException catch (error) {
      throw AuthErrorMapper.fromCode(error.code, originalError: error);
    } catch (error) {
      throw AuthErrorMapper.fromCode(
        null,
        originalError: error,
        fallbackMessage: 'Google sign-in failed. Please try again.',
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      throw AuthErrorMapper.fromCode(error.code, originalError: error);
    } catch (error) {
      throw AuthErrorMapper.fromCode(
        null,
        originalError: error,
        fallbackMessage: 'Unable to send the reset email. Please try again.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    Object? primaryError;

    try {
      await _firebaseAuth.signOut();
    } catch (error) {
      primaryError = error;
    }

    try {
      await _ensureGoogleSignInInitialized();
      await _googleSignIn.signOut();
    } catch (_) {
      // Google sign-out should not mask Firebase sign-out failures.
    }

    if (primaryError != null) {
      throw AuthErrorMapper.fromCode(
        null,
        originalError: primaryError,
        fallbackMessage: 'Unable to sign out. Please try again.',
      );
    }
  }

  @override
  Future<AppUser> updateProfile({
    required String name,
    required String phoneNumber,
    required String avatarId,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AppException(
        'Please sign in again before updating your profile.',
        code: 'requires-recent-login',
      );
    }

    try {
      await user.updateDisplayName(name);
      await _users.doc(user.uid).set(
        {
          'uid': user.uid,
          'name': name,
          'phoneNumber': phoneNumber,
          'avatarId': avatarId,
          'email': user.email ?? '',
          'isEmailVerified': user.emailVerified,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final profile = await _readUserProfile(user.uid);
      if (profile == null) {
        throw const AppException(
          'Unable to update your profile. Please try again.',
          code: 'unknown',
        );
      }
      return profile;
    } on AppException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw AuthErrorMapper.fromCode(error.code, originalError: error);
    } catch (error) {
      throw _mapFirestoreError(
        error,
        fallbackMessage: 'Unable to update your profile. Please try again.',
      );
    }
  }

  @override
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AppException(
        'Please sign in again before deleting your account.',
        code: 'requires-recent-login',
      );
    }

    try {
      await _users.doc(user.uid).delete();
    } catch (error) {
      throw _mapFirestoreError(
        error,
        fallbackMessage: 'Unable to delete your account data. Please try again.',
      );
    }

    try {
      await user.delete();
    } on FirebaseAuthException catch (error) {
      throw AuthErrorMapper.fromCode(error.code, originalError: error);
    } catch (error) {
      throw AuthErrorMapper.fromCode(
        null,
        originalError: error,
        fallbackMessage: 'Unable to delete your account. Please try again.',
      );
    }

    try {
      await _ensureGoogleSignInInitialized();
      await _googleSignIn.signOut();
    } catch (_) {
      // Best-effort Google cleanup after account deletion.
    }
  }

  Future<void> _ensureGoogleSignInInitialized() {
    return _googleInitializationFuture ??= _googleSignIn.initialize();
  }

  Future<AppUser> _loadOrCreateProfileForAuthUser(
    User user, {
    required bool updateLastLogin,
  }) async {
    final existing = await _readUserProfile(user.uid);
    if (existing != null) {
      if (updateLastLogin) {
        await _users.doc(user.uid).set(
          {
            'lastLoginAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'isEmailVerified': user.emailVerified,
          },
          SetOptions(merge: true),
        );
        return await _readUserProfile(user.uid) ?? existing;
      }
      return existing;
    }

    final model = AppUserModel.fromFirebaseUser(user);

    await _users.doc(user.uid).set(
          model.toFirestoreMap(
            createdAtValue: FieldValue.serverTimestamp(),
            updatedAtValue: FieldValue.serverTimestamp(),
            lastLoginAtValue: FieldValue.serverTimestamp(),
            includeLastLoginAt: updateLastLogin,
          ),
          SetOptions(merge: true),
        );

    return await _readUserProfile(user.uid) ?? model.toEntity();
  }

  Future<AppUser> _mergeGoogleProfile(
    User user,
    GoogleSignInAccount account,
  ) async {
    final snapshot = await _users.doc(user.uid).get();
    final existingData = snapshot.data();

    final existingName = _nonEmptyString(existingData?['name']);
    final existingPhone = _nonEmptyString(existingData?['phoneNumber']);
    final existingPhoto = _nonEmptyString(existingData?['photoUrl']);
    final existingAvatar = _nonEmptyString(existingData?['avatarId']);

    final payload = <String, dynamic>{
      'uid': user.uid,
      'email': user.email ?? account.email,
      'isEmailVerified': user.emailVerified,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    };

    final name = existingName ??
        _nonEmptyString(user.displayName) ??
        _nonEmptyString(account.displayName);
    final phoneNumber = existingPhone ?? _nonEmptyString(user.phoneNumber);
    final photoUrl = existingPhoto ??
        _nonEmptyString(user.photoURL) ??
        _nonEmptyString(account.photoUrl);

    if (name != null) {
      payload['name'] = name;
    }
    if (phoneNumber != null) {
      payload['phoneNumber'] = phoneNumber;
    }
    if (photoUrl != null) {
      payload['photoUrl'] = photoUrl;
    }
    if (existingAvatar != null) {
      payload['avatarId'] = existingAvatar;
    }

    if (!snapshot.exists) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }

    await _users.doc(user.uid).set(payload, SetOptions(merge: true));
    final profile = await _readUserProfile(user.uid);
    if (profile == null) {
      throw const AppException(
        'Unable to complete Google sign-in. Please try again.',
        code: 'unknown',
      );
    }
    return profile;
  }

  Future<AppUser?> _readUserProfile(String uid) async {
    try {
      final snapshot = await _users.doc(uid).get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      final model = AppUserModel.fromMap(data);
      if (model.uid.isEmpty) {
        return AppUserModel.fromMap({...data, 'uid': uid}).toEntity();
      }
      return model.toEntity();
    } catch (error) {
      throw _mapFirestoreError(
        error,
        fallbackMessage: 'Unable to load your profile. Please try again.',
      );
    }
  }

  Future<void> _bestEffortDeleteAuthUser(User user) async {
    try {
      await user.delete();
    } catch (_) {
      // Do not mask the original profile-creation failure.
    }
  }

  AppException _mapFirestoreError(
    Object error, {
    required String fallbackMessage,
  }) {
    if (error is FirebaseException) {
      return AuthErrorMapper.fromCode(
        error.code,
        originalError: error,
        fallbackMessage: fallbackMessage,
      );
    }
    return AuthErrorMapper.fromCode(
      null,
      originalError: error,
      fallbackMessage: fallbackMessage,
    );
  }

  String? _nonEmptyString(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
