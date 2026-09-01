import 'package:equatable/equatable.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';

enum HomeStatus {
  initial,
  loading,
  success,
  partialSuccess,
  empty,
  failure,
}

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.availableNowMovies = const [],
    this.actionMovies = const [],
    this.availableNowError,
    this.actionError,
  });

  final HomeStatus status;
  final List<Movie> availableNowMovies;
  final List<Movie> actionMovies;
  final String? availableNowError;
  final String? actionError;

  bool get isLoading => status == HomeStatus.loading;

  bool get hasAnyMovies =>
      availableNowMovies.isNotEmpty || actionMovies.isNotEmpty;

  HomeState copyWith({
    HomeStatus? status,
    List<Movie>? availableNowMovies,
    List<Movie>? actionMovies,
    String? availableNowError,
    String? actionError,
    bool clearAvailableNowError = false,
    bool clearActionError = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      availableNowMovies: availableNowMovies ?? this.availableNowMovies,
      actionMovies: actionMovies ?? this.actionMovies,
      availableNowError: clearAvailableNowError
          ? null
          : (availableNowError ?? this.availableNowError),
      actionError:
          clearActionError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => [
        status,
        availableNowMovies,
        actionMovies,
        availableNowError,
        actionError,
      ];
}
