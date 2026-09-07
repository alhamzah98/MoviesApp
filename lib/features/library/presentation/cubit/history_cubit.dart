import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/library/domain/entities/library_movie.dart';
import 'package:movies_app/features/library/domain/use_cases/observe_history.dart';
import 'package:movies_app/features/library/domain/use_cases/record_history.dart';
import 'package:movies_app/features/library/presentation/cubit/history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit({
    required ObserveHistory observeHistory,
    required RecordHistory recordHistory,
  }) : _observeHistory = observeHistory,
       _recordHistory = recordHistory,
       super(const HistoryState());

  final ObserveHistory _observeHistory;
  final RecordHistory _recordHistory;

  StreamSubscription<List<LibraryMovie>>? _subscription;

  void startObserving({bool force = false}) {
    if (force) {
      _subscription?.cancel();
      _subscription = null;
    } else if (_subscription != null) {
      return;
    }

    emit(
      state.copyWith(status: HistoryStatus.loading, clearErrorMessage: true),
    );

    _subscription = _observeHistory().listen(
      (movies) {
        if (isClosed) {
          return;
        }
        emit(
          state.copyWith(
            status: HistoryStatus.ready,
            movies: movies,
            clearErrorMessage: true,
          ),
        );
      },
      onError: (Object error) {
        _subscription?.cancel();
        _subscription = null;
        if (isClosed) {
          return;
        }
        emit(
          state.copyWith(
            status: HistoryStatus.failure,
            errorMessage: _messageFrom(error),
          ),
        );
      },
    );
  }

  /// Retries the observation stream, cancelling any stale subscription.
  void retry() {
    startObserving(force: true);
  }

  /// Clears in-memory library data and cancels active subscriptions (e.g. on sign-out/UID change).
  void reset() {
    _subscription?.cancel();
    _subscription = null;
    emit(const HistoryState());
  }

  Future<void> recordMovieView(LibraryMovie movie) async {
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
      await _recordHistory(movie);
      if (isClosed) {
        return;
      }
      emit(state.copyWith(pendingMovieIds: _withoutPending(movie.movieId)));
    } catch (error) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: HistoryStatus.failure,
          pendingMovieIds: _withoutPending(movie.movieId),
          errorMessage: _messageFrom(error),
        ),
      );
    }
  }

  List<int> _withoutPending(int movieId) {
    return state.pendingMovieIds.where((id) => id != movieId).toList();
  }

  String _messageFrom(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Unable to update your viewing history. Please try again.';
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    return super.close();
  }
}
