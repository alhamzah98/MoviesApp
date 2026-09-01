import 'package:equatable/equatable.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';

enum MovieDetailsStatus {
  initial,
  loading,
  success,
  failure,
}

class MovieDetailsState extends Equatable {
  const MovieDetailsState({
    this.status = MovieDetailsStatus.initial,
    this.movie,
    this.suggestions = const [],
    this.errorMessage,
    this.suggestionsErrorMessage,
    this.isLoadingSuggestions = false,
  });

  final MovieDetailsStatus status;
  final Movie? movie;
  final List<Movie> suggestions;
  final String? errorMessage;
  final String? suggestionsErrorMessage;
  final bool isLoadingSuggestions;

  MovieDetailsState copyWith({
    MovieDetailsStatus? status,
    Movie? movie,
    List<Movie>? suggestions,
    String? errorMessage,
    String? suggestionsErrorMessage,
    bool? isLoadingSuggestions,
    bool clearErrorMessage = false,
    bool clearSuggestionsErrorMessage = false,
    bool clearMovie = false,
  }) {
    return MovieDetailsState(
      status: status ?? this.status,
      movie: clearMovie ? null : (movie ?? this.movie),
      suggestions: suggestions ?? this.suggestions,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      suggestionsErrorMessage: clearSuggestionsErrorMessage
          ? null
          : (suggestionsErrorMessage ?? this.suggestionsErrorMessage),
      isLoadingSuggestions: isLoadingSuggestions ?? this.isLoadingSuggestions,
    );
  }

  @override
  List<Object?> get props => [
        status,
        movie,
        suggestions,
        errorMessage,
        suggestionsErrorMessage,
        isLoadingSuggestions,
      ];
}
