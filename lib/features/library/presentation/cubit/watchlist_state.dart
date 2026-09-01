import 'package:equatable/equatable.dart';
import 'package:movies_app/features/library/domain/entities/library_movie.dart';

enum WatchlistStatus {
  initial,
  loading,
  ready,
  failure,
}

class WatchlistState extends Equatable {
  const WatchlistState({
    this.status = WatchlistStatus.initial,
    this.movies = const [],
    this.pendingMovieIds = const [],
    this.errorMessage,
  });

  final WatchlistStatus status;
  final List<LibraryMovie> movies;
  final List<int> pendingMovieIds;
  final String? errorMessage;

  bool containsMovie(int movieId) {
    return movies.any((movie) => movie.movieId == movieId);
  }

  bool isPending(int movieId) => pendingMovieIds.contains(movieId);

  WatchlistState copyWith({
    WatchlistStatus? status,
    List<LibraryMovie>? movies,
    List<int>? pendingMovieIds,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return WatchlistState(
      status: status ?? this.status,
      movies: movies ?? this.movies,
      pendingMovieIds: pendingMovieIds ?? this.pendingMovieIds,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, movies, pendingMovieIds, errorMessage];
}
