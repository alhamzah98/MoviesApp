import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/library/data/data_sources/library_remote_data_source.dart';
import 'package:movies_app/features/library/data/library_error_mapper.dart';
import 'package:movies_app/features/library/data/models/library_movie_model.dart';
import 'package:movies_app/features/library/domain/entities/library_movie.dart';

class LibraryFirestoreDataSource implements LibraryRemoteDataSource {
  LibraryFirestoreDataSource({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firebaseFirestore,
  })  : _firebaseAuth = firebaseAuth,
        _firebaseFirestore = firebaseFirestore;

  static const String _usersCollection = 'users';
  static const String _watchlistCollection = 'watchlist';
  static const String _historyCollection = 'history';

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firebaseFirestore;

  @override
  Stream<List<LibraryMovie>> observeWatchlist() {
    return _observeCollection(
      collectionName: _watchlistCollection,
      orderByField: 'addedAt',
    );
  }

  @override
  Stream<bool> observeIsInWatchlist(int movieId) {
    try {
      final doc = _watchlistDoc(_requireUid(), movieId);
      return _mapStreamErrors(
        doc.snapshots().map((snapshot) => snapshot.exists),
      );
    } on AppException catch (error) {
      return Stream<bool>.error(error);
    } catch (error) {
      return Stream<bool>.error(LibraryErrorMapper.fromError(error));
    }
  }

  @override
  Future<void> addToWatchlist(LibraryMovie movie) {
    return _run(() async {
      final uid = _requireUid();
      final doc = _watchlistDoc(uid, movie.movieId);
      final existing = await doc.get();
      final payload = <String, dynamic>{
        ...LibraryMovieModel.fromEntity(movie).toWatchlistWriteMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!existing.exists) {
        payload['addedAt'] = FieldValue.serverTimestamp();
      }

      await doc.set(payload, SetOptions(merge: true));
    });
  }

  @override
  Future<void> removeFromWatchlist(int movieId) {
    return _run(() async {
      final uid = _requireUid();
      try {
        await _watchlistDoc(uid, movieId).delete();
      } on FirebaseException catch (error) {
        if (error.code == 'not-found') {
          return;
        }
        rethrow;
      }
    });
  }

  @override
  Stream<List<LibraryMovie>> observeHistory() {
    return _observeCollection(
      collectionName: _historyCollection,
      orderByField: 'lastViewedAt',
    );
  }

  @override
  Future<void> recordHistory(LibraryMovie movie) {
    return _run(() async {
      final uid = _requireUid();
      final payload = <String, dynamic>{
        ...LibraryMovieModel.fromEntity(movie).toHistoryWriteMap(),
        'lastViewedAt': FieldValue.serverTimestamp(),
        'viewCount': FieldValue.increment(1),
      };

      await _historyDoc(uid, movie.movieId).set(
        payload,
        SetOptions(merge: true),
      );
    });
  }

  Stream<List<LibraryMovie>> _observeCollection({
    required String collectionName,
    required String orderByField,
  }) {
    try {
      final uid = _requireUid();
      final query = _firebaseFirestore
          .collection(_usersCollection)
          .doc(uid)
          .collection(collectionName)
          .orderBy(orderByField, descending: true);

      return _mapStreamErrors(
        query.snapshots().map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => LibraryMovieModel.fromMap(
                  doc.data(),
                  documentId: doc.id,
                ).toEntity(),
              )
              .toList(growable: false);
        }),
      );
    } on AppException catch (error) {
      return Stream<List<LibraryMovie>>.error(error);
    } catch (error) {
      return Stream<List<LibraryMovie>>.error(
        LibraryErrorMapper.fromError(error),
      );
    }
  }

  DocumentReference<Map<String, dynamic>> _watchlistDoc(String uid, int movieId) {
    return _firebaseFirestore
        .collection(_usersCollection)
        .doc(uid)
        .collection(_watchlistCollection)
        .doc(movieId.toString());
  }

  DocumentReference<Map<String, dynamic>> _historyDoc(String uid, int movieId) {
    return _firebaseFirestore
        .collection(_usersCollection)
        .doc(uid)
        .collection(_historyCollection)
        .doc(movieId.toString());
  }

  String _requireUid() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AppException(
        'Please sign in to use your watchlist and history.',
        code: 'unauthenticated',
      );
    }
    return user.uid;
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on AppException {
      rethrow;
    } on FirebaseException catch (error) {
      throw LibraryErrorMapper.fromCode(
        error.code,
        originalError: error,
      );
    } catch (error) {
      throw LibraryErrorMapper.fromError(
        error,
        fallbackMessage: 'Unable to update your library. Please try again.',
      );
    }
  }

  Stream<T> _mapStreamErrors<T>(Stream<T> stream) {
    return stream.handleError((Object error, StackTrace stackTrace) {
      final mapped = LibraryErrorMapper.fromError(
        error,
        fallbackMessage: 'Unable to load your library. Please try again.',
      );
      Error.throwWithStackTrace(mapped, stackTrace);
    });
  }
}
