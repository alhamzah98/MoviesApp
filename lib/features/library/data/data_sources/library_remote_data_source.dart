import 'package:movies_app/features/library/domain/entities/library_movie.dart';

abstract class LibraryRemoteDataSource {
  Stream<List<LibraryMovie>> observeWatchlist();

  Stream<bool> observeIsInWatchlist(int movieId);

  Future<void> addToWatchlist(LibraryMovie movie);

  Future<void> removeFromWatchlist(int movieId);

  Stream<List<LibraryMovie>> observeHistory();

  Future<void> recordHistory(LibraryMovie movie);
}
