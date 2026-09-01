import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/library/domain/entities/library_movie.dart';
import 'package:movies_app/features/library/domain/use_cases/add_to_watchlist.dart';
import 'package:movies_app/features/library/domain/use_cases/observe_watchlist.dart';
import 'package:movies_app/features/library/domain/use_cases/remove_from_watchlist.dart';
import 'package:movies_app/features/library/presentation/cubit/watchlist_state.dart';

class WatchlistCubit extends Cubit<WatchlistState> {
  WatchlistCubit({
    required ObserveWatchlist observeWatchlist,
    required AddToWatchlist addToWatchlist,
    required RemoveFromWatchlist removeFromWatchlist,
  })  : _observeWatchlist = observeWatchlist,
        _addToWatchlist = addToWatchlist,
        _removeFromWatchlist = removeFromWatchlist,
        super(const WatchlistState());

  final ObserveWatchlist _observeWatchlist;
  final AddToWatchlist _addToWatchlist;
  final RemoveFromWatchlist _removeFromWatchlist;

  StreamSubscription<List<LibraryMovie>>? _subscription;

  void startObserving() {
    if (_subscription != null) {
      return;
    }

    emit(
      state.copyWith(
        status: WatchlistStatus.loading,
        clearErrorMessage: true,
      ),
    );

    _subscription = _observeWatchlist().listen(
      (movies) {
        if (isClosed) {
          return;
        }
        emit(
          state.copyWith(
            status: WatchlistStatus.ready,
            movies: movies,
            clearErrorMessage: true,
          ),
        );
      },
      onError: (Object error) {
        if (isClosed) {
          return;
        }
        emit(
          state.copyWith(
            status: WatchlistStatus.failure,
            errorMessage: _messageFrom(error),
          ),
        );
      },
    );
  }

  Future<void> addMovie(LibraryMovie movie) async {
    if (state.isPending(movie.movieId)) {
      return;
    }

    emit(
      state.copyWith(
        pendingMovieIds: [...state.pendingMovieIds, movie.movieId],
        clearErrorMessage: true,
      ),
    );

    try {
      await _addToWatchlist(movie);
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          pendingMovieIds: _withoutPending(movie.movieId),
        ),
      );
    } catch (error) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: WatchlistStatus.failure,
          pendingMovieIds: _withoutPending(movie.movieId),
          errorMessage: _messageFrom(error),
        ),
      );
    }
  }

  Future<void> removeMovie(int movieId) async {
    if (state.isPending(movieId)) {
      return;
    }

    emit(
      state.copyWith(
        pendingMovieIds: [...state.pendingMovieIds, movieId],
        clearErrorMessage: true,
      ),
    );

    try {
      await _removeFromWatchlist(movieId);
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          pendingMovieIds: _withoutPending(movieId),
        ),
      );
    } catch (error) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: WatchlistStatus.failure,
          pendingMovieIds: _withoutPending(movieId),
          errorMessage: _messageFrom(error),
        ),
      );
    }
  }

  Future<void> toggleMovie(LibraryMovie movie) {
    if (containsMovie(movie.movieId)) {
      return removeMovie(movie.movieId);
    }
    return addMovie(movie);
  }

  bool containsMovie(int movieId) => state.containsMovie(movieId);

  List<int> _withoutPending(int movieId) {
    return state.pendingMovieIds.where((id) => id != movieId).toList();
  }

  String _messageFrom(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Unable to update your watchlist. Please try again.';
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    return super.close();
  }
}
