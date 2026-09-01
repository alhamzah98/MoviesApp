import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/movies/domain/use_cases/get_movie_details.dart';
import 'package:movies_app/features/movies/domain/use_cases/get_movie_suggestions.dart';
import 'package:movies_app/features/movies/presentation/cubit/movie_details_state.dart';

class MovieDetailsCubit extends Cubit<MovieDetailsState> {
  MovieDetailsCubit({
    required GetMovieDetails getMovieDetails,
    required GetMovieSuggestions getMovieSuggestions,
  })  : _getMovieDetails = getMovieDetails,
        _getMovieSuggestions = getMovieSuggestions,
        super(const MovieDetailsState());

  final GetMovieDetails _getMovieDetails;
  final GetMovieSuggestions _getMovieSuggestions;

  Future<void> load(int movieId) async {
    emit(
      state.copyWith(
        status: MovieDetailsStatus.loading,
        clearErrorMessage: true,
        clearSuggestionsErrorMessage: true,
        clearMovie: true,
        suggestions: const [],
        isLoadingSuggestions: true,
      ),
    );

    try {
      final movie = await _getMovieDetails(movieId);
      emit(
        state.copyWith(
          status: MovieDetailsStatus.success,
          movie: movie,
          clearErrorMessage: true,
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          status: MovieDetailsStatus.failure,
          errorMessage: error.message,
          isLoadingSuggestions: false,
        ),
      );
      return;
    } catch (_) {
      emit(
        state.copyWith(
          status: MovieDetailsStatus.failure,
          errorMessage: 'Failed to load movie details.',
          isLoadingSuggestions: false,
        ),
      );
      return;
    }

    try {
      final suggestions = await _getMovieSuggestions(movieId);
      emit(
        state.copyWith(
          suggestions: suggestions,
          isLoadingSuggestions: false,
          clearSuggestionsErrorMessage: true,
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          isLoadingSuggestions: false,
          suggestionsErrorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoadingSuggestions: false,
          suggestionsErrorMessage: 'Failed to load movie suggestions.',
        ),
      );
    }
  }
}
