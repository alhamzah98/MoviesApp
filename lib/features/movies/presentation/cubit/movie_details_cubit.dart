import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/movies/domain/use_cases/get_movie_details.dart';
import 'package:movies_app/features/movies/domain/use_cases/get_movie_suggestions.dart';
import 'package:movies_app/features/movies/presentation/cubit/movie_details_state.dart';

class MovieDetailsCubit extends Cubit<MovieDetailsState> {
  MovieDetailsCubit({
    required GetMovieDetails getMovieDetails,
    required GetMovieSuggestions getMovieSuggestions,
  }) : _getMovieDetails = getMovieDetails,
       _getMovieSuggestions = getMovieSuggestions,
       super(const MovieDetailsState());

  final GetMovieDetails _getMovieDetails;
  final GetMovieSuggestions _getMovieSuggestions;
  int _activeLoadRequestId = 0;

  Future<void> load(int movieId) async {
    final requestId = ++_activeLoadRequestId;

    if (movieId <= 0) {
      emit(
        state.copyWith(
          status: MovieDetailsStatus.failure,
          errorMessage: 'Invalid movie ID.',
          isLoadingSuggestions: false,
        ),
      );
      return;
    }

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
      if (isClosed || requestId != _activeLoadRequestId) {
        return;
      }
      emit(
        state.copyWith(
          status: MovieDetailsStatus.success,
          movie: movie,
          clearErrorMessage: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed || requestId != _activeLoadRequestId) {
        return;
      }
      emit(
        state.copyWith(
          status: MovieDetailsStatus.failure,
          errorMessage: error.message,
          isLoadingSuggestions: false,
        ),
      );
      return;
    } catch (_) {
      if (isClosed || requestId != _activeLoadRequestId) {
        return;
      }
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
      if (isClosed || requestId != _activeLoadRequestId) {
        return;
      }
      emit(
        state.copyWith(
          suggestions: suggestions,
          isLoadingSuggestions: false,
          clearSuggestionsErrorMessage: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed || requestId != _activeLoadRequestId) {
        return;
      }
      emit(
        state.copyWith(
          isLoadingSuggestions: false,
          suggestionsErrorMessage: error.message,
        ),
      );
    } catch (_) {
      if (isClosed || requestId != _activeLoadRequestId) {
        return;
      }
      emit(
        state.copyWith(
          isLoadingSuggestions: false,
          suggestionsErrorMessage: 'Failed to load movie suggestions.',
        ),
      );
    }
  }

  Future<void> retrySuggestions(int movieId) async {
    if (state.isLoadingSuggestions) {
      return;
    }

    final targetMovieId = state.movie?.id ?? movieId;
    if (targetMovieId <= 0) {
      return;
    }

    final requestId = _activeLoadRequestId;

    emit(
      state.copyWith(
        isLoadingSuggestions: true,
        clearSuggestionsErrorMessage: true,
      ),
    );

    try {
      final suggestions = await _getMovieSuggestions(targetMovieId);
      if (isClosed || requestId != _activeLoadRequestId) {
        return;
      }
      emit(
        state.copyWith(
          suggestions: suggestions,
          isLoadingSuggestions: false,
          clearSuggestionsErrorMessage: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed || requestId != _activeLoadRequestId) {
        return;
      }
      emit(
        state.copyWith(
          isLoadingSuggestions: false,
          suggestionsErrorMessage: error.message,
        ),
      );
    } catch (_) {
      if (isClosed || requestId != _activeLoadRequestId) {
        return;
      }
      emit(
        state.copyWith(
          isLoadingSuggestions: false,
          suggestionsErrorMessage: 'Failed to load movie suggestions.',
        ),
      );
    }
  }
}
