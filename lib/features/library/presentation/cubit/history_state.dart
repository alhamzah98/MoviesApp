import 'package:equatable/equatable.dart';
import 'package:movies_app/features/library/domain/entities/library_movie.dart';

enum HistoryStatus {
  initial,
  loading,
  ready,
  failure,
}

class HistoryState extends Equatable {
  const HistoryState({
    this.status = HistoryStatus.initial,
    this.movies = const [],
    this.pendingMovieIds = const [],
    this.errorMessage,
  });

  final HistoryStatus status;
  final List<LibraryMovie> movies;
  final List<int> pendingMovieIds;
  final String? errorMessage;

  bool isPending(int movieId) => pendingMovieIds.contains(movieId);

  HistoryState copyWith({
    HistoryStatus? status,
    List<LibraryMovie>? movies,
    List<int>? pendingMovieIds,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return HistoryState(
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
