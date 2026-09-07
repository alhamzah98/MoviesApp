import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/auth/data/auth_error_mapper.dart';
import 'package:movies_app/features/auth/data/data_sources/account_deletion_orchestrator.dart';
import 'package:movies_app/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:movies_app/features/auth/data/models/app_user_model.dart';
import 'package:movies_app/features/auth/domain/entities/app_user.dart';
import 'package:movies_app/features/auth/domain/entities/delete_account_result.dart';

class _PendingRegistration {
  final Completer<AppUser?> completer = Completer<AppUser?>();
  String? createdUid;
}

class AuthFirebaseDataSource implements AuthRemoteDataSource {
  AuthFirebaseDataSource({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firebaseFirestore,
    required GoogleSignIn googleSignIn,
    Future<void> Function(String uid)? onPauseCompetingWrites,
    void Function(String uid)? onResumeCompetingWrites,
    AccountDeletionOrchestrator? deletionOrchestrator,
  }) : _firebaseAuth = firebaseAuth,
       _firebaseFirestore = firebaseFirestore,
       _googleSignIn = googleSignIn,
       _onPauseCompetingWrites = onPauseCompetingWrites,
       _onResumeCompetingWrites = onResumeCompetingWrites {
    _deletionOrchestrator = deletionOrchestrator ??
        AccountDeletionOrchestrator(
          getCurrentUid: () => _firebaseAuth.currentUser?.uid,
          reauthenticate: ({String? password, bool useGoogle = false}) =>
              _reauthenticateCurrentUser(
                password: password,
                useGoogle: useGoogle,
              ),
          deleteWatchlistBatch: ({
            required int batchSize,
            void Function()? onDestructiveSubmitting,
          }) =>
              _deleteCollectionBatch(
                collection: _users
                    .doc(_firebaseAuth.currentUser?.uid)
                    .collection('watchlist'),
                batchSize: batchSize,
                onDestructiveSubmitting: onDestructiveSubmitting,
              ),
          deleteHistoryBatch: ({
            required int batchSize,
            void Function()? onDestructiveSubmitting,
          }) =>
              _deleteCollectionBatch(
                collection: _users
                    .doc(_firebaseAuth.currentUser?.uid)
                    .collection('history'),
                batchSize: batchSize,
                onDestructiveSubmitting: onDestructiveSubmitting,
              ),
          deleteUserProfile: () async {
            final uid = _firebaseAuth.currentUser?.uid;
            if (uid != null) {
              await _users.doc(uid).delete();
            }
          },
          deleteAuthUser: () async {
            final user = _firebaseAuth.currentUser;
            if (user != null) {
              await user.delete();
            }
          },
          signOutGoogle: () async {
            try {
              await _ensureGoogleSignInInitialized();
              await _googleSignIn.signOut();
            } catch (_) {}
          },
          onPauseCompetingWrites: (uid) async {
            if (_onPauseCompetingWrites != null) {
              await _onPauseCompetingWrites!(uid);
            }
            await _awaitInFlightProfileWrites();
          },
          onResumeCompetingWrites: (uid) {
            _onResumeCompetingWrites?.call(uid);
          },
        );
  }

  static const String _usersCollection = 'users';

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firebaseFirestore;
  final GoogleSignIn _googleSignIn;
  final Future<void> Function(String uid)? _onPauseCompetingWrites;
  final void Function(String uid)? _onResumeCompetingWrites;
  late final AccountDeletionOrchestrator _deletionOrchestrator;

  Future<void>? _googleInitializationFuture;
  final List<_PendingRegistration> _activeRegistrations =
      <_PendingRegistration>[];
  final Set<Completer<void>> _inFlightProfileWrites = <Completer<void>>{};

  bool _isSuspended(String uid) => _deletionOrchestrator.isUidSuspended(uid);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firebaseFirestore.collection(_usersCollection);

  @override
  Stream<AppUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        return null;
      }
      final active = _activeRegistrations
          .cast<_PendingRegistration?>()
          .firstWhere(
            (reg) =>
                reg != null &&
                (reg.createdUid == user.uid || reg.createdUid == null),
            orElse: () => null,
          );

      if (active != null) {
        active.createdUid ??= user.uid;
        final result = await active.completer.future;
        if (result == null || _firebaseAuth.currentUser?.uid != user.uid) {
          return null;
        }
        return result;
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
    final registration = _PendingRegistration();
    _activeRegistrations.add(registration);

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final createdUser = credential.user;
      if (createdUser == null) {
        throw const AppException(
          'Unable to create your account. Please try again.',
          code: 'unknown',
        );
      }

      registration.createdUid = createdUser.uid;

      try {
        await createdUser.updateDisplayName(name);
      } catch (_) {
        // Fall back gracefully; Firestore document remains authoritative.
      }

      final model = AppUserModel.fromAuthUser(
        uid: createdUser.uid,
        email: createdUser.email ?? email,
        name: name,
        phoneNumber: phoneNumber,
        avatarId: avatarId,
        isEmailVerified: createdUser.emailVerified,
      );

      try {
        await _users
            .doc(createdUser.uid)
            .set(
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

      final savedUser =
          await _readUserProfile(createdUser.uid, authUser: createdUser) ??
              model.toEntity();
      if (!registration.completer.isCompleted) {
        registration.completer.complete(savedUser);
      }
      return savedUser;
    } on AppException {
      if (!registration.completer.isCompleted) {
        registration.completer.complete(null);
      }
      rethrow;
    } on FirebaseAuthException catch (error) {
      if (!registration.completer.isCompleted) {
        registration.completer.complete(null);
      }
      throw AuthErrorMapper.fromCode(error.code, originalError: error);
    } catch (error) {
      if (!registration.completer.isCompleted) {
        registration.completer.complete(null);
      }
      throw AuthErrorMapper.fromCode(
        null,
        originalError: error,
        fallbackMessage: 'Unable to create your account. Please try again.',
      );
    } finally {
      if (!registration.completer.isCompleted) {
        registration.completer.complete(null);
      }
      _activeRegistrations.remove(registration);
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
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
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
    try {
      await _ensureGoogleSignInInitialized();
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignored: Best effort Google sign out
    }

    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (error) {
      throw AuthErrorMapper.fromCode(error.code, originalError: error);
    } catch (error) {
      throw AuthErrorMapper.fromCode(
        null,
        originalError: error,
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
        'Please sign in again to update your profile.',
        code: 'unauthenticated',
      );
    }

    if (_isSuspended(user.uid)) {
      throw const AppException(
        'Account deletion in progress. Profile modifications are suspended.',
        code: 'operation-in-progress',
      );
    }

    final completer = Completer<void>();
    _inFlightProfileWrites.add(completer);

    try {
      await user.updateDisplayName(name);
      await _users.doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'phoneNumber': phoneNumber,
        'avatarId': avatarId,
        'email': user.email ?? '',
        'isEmailVerified': user.emailVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final profile = await _readUserProfile(user.uid, authUser: user);
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
    } finally {
      if (!completer.isCompleted) {
        completer.complete();
      }
      _inFlightProfileWrites.remove(completer);
    }
  }

  @override
  Future<DeleteAccountResult> deleteAccount({
    String? password,
    bool useGoogle = false,
  }) {
    return _deletionOrchestrator.execute(
      password: password,
      useGoogle: useGoogle,
    );
  }

  Future<void> _reauthenticateCurrentUser({
    String? password,
    bool useGoogle = false,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AppException(
        'Please sign in again before deleting your account.',
        code: 'unauthenticated',
      );
    }

    final providerIds = user.providerData
        .map((info) => info.providerId)
        .where((id) => id.isNotEmpty)
        .toSet();

    try {
      if (useGoogle ||
          (password == null &&
              providerIds.contains('google.com') &&
              !providerIds.contains('password'))) {
        if (!providerIds.contains('google.com')) {
          throw const AppException(
            'This account was not created with Google.',
            code: 'provider-not-supported',
          );
        }

        await _ensureGoogleSignInInitialized();
        final account = await _googleSignIn.authenticate();
        final idToken = account.authentication.idToken;
        if (idToken == null || idToken.isEmpty) {
          throw const AppException(
            'Google Sign-In did not return a valid credential.',
            code: 'invalid-credential',
          );
        }

        // Verify the selected Google account matches the currently logged in user
        if (user.email != null &&
            user.email!.isNotEmpty &&
            account.email.trim().toLowerCase() !=
                user.email!.trim().toLowerCase()) {
          throw const AppException(
            'The selected Google account does not match the active user session.',
            code: 'user-mismatch',
          );
        }

        final credential = GoogleAuthProvider.credential(idToken: idToken);
        await user.reauthenticateWithCredential(credential);
      } else if (password != null) {
        if (!providerIds.contains('password')) {
          throw const AppException(
            'This account does not use password authentication.',
            code: 'provider-not-supported',
          );
        }
        if (user.email == null || user.email!.isEmpty) {
          throw const AppException(
            'Account email is required for password reauthentication.',
            code: 'invalid-email',
          );
        }

        // Pass password EXACTLY as entered - do not trim, lowercase, or alter.
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      } else {
        if (providerIds.contains('password')) {
          throw const AppException(
            'Password is required to confirm account deletion.',
            code: 'password-required',
          );
        }
        throw const AppException(
          'The sign-in method for this account is not supported for account deletion.',
          code: 'provider-not-supported',
        );
      }
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AppException(
          'Google reauthentication cancelled.',
          code: 'cancelled',
        );
      }
      throw AuthErrorMapper.fromCode(
        'google-config',
        originalError: error,
        fallbackMessage: 'Google reauthentication failed. Please try again.',
      );
    } on FirebaseAuthException catch (error) {
      throw AuthErrorMapper.fromCode(error.code, originalError: error);
    }
  }

  Future<int> _deleteCollectionBatch({
    required CollectionReference<Map<String, dynamic>> collection,
    required int batchSize,
    void Function()? onDestructiveSubmitting,
  }) async {
    final snapshot = await collection
        .limit(batchSize)
        .get(const GetOptions(source: Source.server));

    if (snapshot.docs.isEmpty) {
      return 0;
    }

    final batch = _firebaseFirestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    // Mark destructive submission right before committing to the network.
    onDestructiveSubmitting?.call();

    await batch.commit();
    return snapshot.docs.length;
  }

  Future<void> _awaitInFlightProfileWrites({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_inFlightProfileWrites.isEmpty) {
      return;
    }
    try {
      await Future.wait(
        _inFlightProfileWrites.map((c) => c.future),
      ).timeout(timeout, onTimeout: () => const []);
    } catch (_) {}
  }

  Future<void> _ensureGoogleSignInInitialized() {
    return _googleInitializationFuture ??= _googleSignIn.initialize();
  }

  Future<AppUser> _loadOrCreateProfileForAuthUser(
    User user, {
    required bool updateLastLogin,
  }) async {
    if (_isSuspended(user.uid)) {
      final existing = await _readUserProfile(user.uid, authUser: user);
      return existing ?? AppUserModel.fromFirebaseUser(user).toEntity();
    }

    final existing = await _readUserProfile(user.uid, authUser: user);
    if (existing != null) {
      if (updateLastLogin) {
        await _users.doc(user.uid).set({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isEmailVerified': user.emailVerified,
        }, SetOptions(merge: true));
        return await _readUserProfile(user.uid, authUser: user) ?? existing;
      }
      return existing;
    }

    final model = AppUserModel.fromFirebaseUser(user);

    await _users
        .doc(user.uid)
        .set(
          model.toFirestoreMap(
            createdAtValue: FieldValue.serverTimestamp(),
            updatedAtValue: FieldValue.serverTimestamp(),
            lastLoginAtValue: FieldValue.serverTimestamp(),
            includeLastLoginAt: updateLastLogin,
          ),
          SetOptions(merge: true),
        );

    return await _readUserProfile(user.uid, authUser: user) ?? model.toEntity();
  }

  Future<AppUser> _mergeGoogleProfile(
    User user,
    GoogleSignInAccount account,
  ) async {
    if (_isSuspended(user.uid)) {
      final existing = await _readUserProfile(user.uid, authUser: user);
      return existing ?? AppUserModel.fromFirebaseUser(user).toEntity();
    }

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

    final name =
        existingName ??
        _nonEmptyString(user.displayName) ??
        _nonEmptyString(account.displayName);
    final phoneNumber = existingPhone ?? _nonEmptyString(user.phoneNumber);
    final photoUrl =
        existingPhoto ??
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
    final profile = await _readUserProfile(user.uid, authUser: user);
    if (profile == null) {
      throw const AppException(
        'Unable to complete Google sign-in. Please try again.',
        code: 'unknown',
      );
    }
    return profile;
  }

  Future<AppUser?> _readUserProfile(String uid, {User? authUser}) async {
    try {
      final snapshot = await _users.doc(uid).get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      final model = AppUserModel.fromMap(data);
      AppUser userEntity = model.uid.isEmpty
          ? AppUserModel.fromMap({...data, 'uid': uid}).toEntity()
          : model.toEntity();

      // Authoritative provider identity sourced from Firebase Auth providerData.
      final currentAuth = authUser ??
          ((_firebaseAuth.currentUser?.uid == uid)
              ? _firebaseAuth.currentUser
              : null);

      if (currentAuth != null) {
        final authoritativeProviders = currentAuth.providerData
            .map((info) => info.providerId)
            .where((id) => id.isNotEmpty)
            .toList(growable: false);
        if (authoritativeProviders.isNotEmpty) {
          userEntity = userEntity.copyWith(providerIds: authoritativeProviders);
        }
      }

      return userEntity;
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
