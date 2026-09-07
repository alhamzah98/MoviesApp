import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:movies_app/core/auth/auth_coordinator.dart';
import 'package:movies_app/core/localization/app_localizations.dart';
import 'package:movies_app/core/theme/app_colors.dart';
import 'package:movies_app/features/library/domain/entities/library_movie.dart';
import 'package:movies_app/features/library/presentation/cubit/history_cubit.dart';
import 'package:movies_app/features/library/presentation/cubit/watchlist_cubit.dart';
import 'package:movies_app/features/library/presentation/cubit/watchlist_state.dart';
import 'package:movies_app/features/movie_details/presentation/widgets/cast_section.dart';
import 'package:movies_app/features/movie_details/presentation/widgets/genres_section.dart';
import 'package:movies_app/features/movie_details/presentation/widgets/hero_header.dart';
import 'package:movies_app/features/movie_details/presentation/widgets/movie_identity_header.dart';
import 'package:movies_app/features/movie_details/presentation/widgets/screenshots_section.dart';
import 'package:movies_app/features/movie_details/presentation/widgets/similar_movies_section.dart';
import 'package:movies_app/features/movie_details/presentation/widgets/statistics_row.dart';
import 'package:movies_app/features/movie_details/presentation/widgets/summary_section.dart';
import 'package:movies_app/features/movie_details/presentation/widgets/watch_button.dart';
import 'package:movies_app/features/movie_details/services/trailer_launcher.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';
import 'package:movies_app/features/movies/domain/use_cases/get_movie_details.dart';
import 'package:movies_app/features/movies/domain/use_cases/get_movie_suggestions.dart';
import 'package:movies_app/features/movies/presentation/cubit/movie_details_cubit.dart';
import 'package:movies_app/features/movies/presentation/cubit/movie_details_state.dart';

class MovieDetailsScreen extends StatefulWidget {
  const MovieDetailsScreen({
    required this.movieId,
    required this.getMovieDetails,
    required this.getMovieSuggestions,
    this.watchlistCubit,
    this.historyCubit,
    this.coordinator,
    this.urlLauncher,
    super.key,
  });

  final int? movieId;
  final GetMovieDetails getMovieDetails;
  final GetMovieSuggestions getMovieSuggestions;
  final WatchlistCubit? watchlistCubit;
  final HistoryCubit? historyCubit;
  final AuthCoordinator? coordinator;
  final UrlLauncherCallback? urlLauncher;

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  MovieDetailsCubit? _cubit;
  int? _recordedHistoryMovieId;
  late final TrailerLauncher _trailerLauncher;
  bool _isTrailerLaunching = false;

  WatchlistCubit? get _effectiveWatchlistCubit =>
      widget.watchlistCubit ?? widget.coordinator?.watchlistCubit;

  HistoryCubit? get _effectiveHistoryCubit =>
      widget.historyCubit ?? widget.coordinator?.historyCubit;

  @override
  void initState() {
    super.initState();
    _trailerLauncher = TrailerLauncher(launcher: widget.urlLauncher);
    if (_isValidMovieId) {
      _cubit = MovieDetailsCubit(
        getMovieDetails: widget.getMovieDetails,
        getMovieSuggestions: widget.getMovieSuggestions,
      )..load(widget.movieId!);
    }
  }

  @override
  void didUpdateWidget(covariant MovieDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movieId != widget.movieId) {
      _recordedHistoryMovieId = null;
      _cubit?.close();
      if (_isValidMovieId) {
        _cubit = MovieDetailsCubit(
          getMovieDetails: widget.getMovieDetails,
          getMovieSuggestions: widget.getMovieSuggestions,
        )..load(widget.movieId!);
      } else {
        _cubit = null;
      }
    }
  }

  @override
  void dispose() {
    _cubit?.close();
    super.dispose();
  }

  bool get _isValidMovieId => widget.movieId != null && widget.movieId! > 0;

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _maybeRecordViewingHistory(Movie movie) {
    if (!_isValidMovieId || movie.id != widget.movieId) {
      return;
    }
    if (_recordedHistoryMovieId == movie.id) {
      return;
    }
    final isAuthenticated = widget.coordinator?.isAuthenticated ?? true;
    if (!isAuthenticated) {
      return;
    }
    _recordedHistoryMovieId = movie.id;
    final historyCubit = _effectiveHistoryCubit;
    if (historyCubit != null) {
      historyCubit.recordMovieView(LibraryMovie.fromMovie(movie));
    }
  }

  Future<void> _handleWatchTrailer(Movie movie) async {
    if (_isTrailerLaunching) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    final hasTrailer =
        TrailerLauncher.hasValidTrailerCode(movie.youtubeTrailerCode);
    if (!hasTrailer) {
      _showFeedback(l10n.trailerUnavailable);
      return;
    }

    setState(() => _isTrailerLaunching = true);

    try {
      final success =
          await _trailerLauncher.launchTrailer(movie.youtubeTrailerCode);
      if (!mounted) return;

      if (!success) {
        _showFeedback(l10n.trailerLaunchFailed);
      }
    } catch (_) {
      if (mounted) {
        _showFeedback(l10n.trailerLaunchFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isTrailerLaunching = false);
      }
    }
  }

  void _showFeedback(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.inputFill,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (!_isValidMovieId) {
      return _buildInvalidIdScaffold(l10n);
    }

    final watchlistCubit = _effectiveWatchlistCubit;

    Widget content = Scaffold(
      key: const Key('movie_details_screen'),
      backgroundColor: AppColors.background,
      body: BlocConsumer<MovieDetailsCubit, MovieDetailsState>(
        listener: (context, state) {
          if (state.movie != null && state.movie!.id == widget.movieId) {
            _maybeRecordViewingHistory(state.movie!);
          }
        },
        builder: (context, state) {
          if (state.status == MovieDetailsStatus.loading &&
              state.movie == null) {
            return _buildLoadingView();
          }

          if (state.status == MovieDetailsStatus.failure &&
              state.movie == null) {
            return _buildFailureView(
              state.errorMessage ?? l10n.failedToLoadDetails,
              l10n,
            );
          }

          if (state.movie != null) {
            return _buildContentView(context, state.movie!, state);
          }

          return _buildLoadingView();
        },
      ),
    );

    if (watchlistCubit != null) {
      content = BlocListener<WatchlistCubit, WatchlistState>(
        bloc: watchlistCubit,
        listener: (context, watchlistState) {
          if (watchlistState.status == WatchlistStatus.failure &&
              watchlistState.errorMessage != null) {
            _showFeedback(watchlistState.errorMessage!);
          }
        },
        child: content,
      );
    }

    return BlocProvider.value(
      value: _cubit!,
      child: content,
    );
  }

  Widget _buildInvalidIdScaffold(AppLocalizations l10n) {
    final isArabic = l10n.isArabic;

    return Scaffold(
      key: const Key('movie_details_invalid_screen'),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Transform.scale(
            scaleX: isArabic ? -1.0 : 1.0,
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.onBackground,
            ),
          ),
          onPressed: _handleBack,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.invalidMovieIdTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.onBackground,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.invalidMovieIdMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.onBackgroundSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    final topPadding = MediaQuery.paddingOf(context).top;
    final isArabic = AppLocalizations.of(context).isArabic;

    return Stack(
      children: [
        const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        PositionedDirectional(
          top: topPadding + 8,
          start: 16,
          child: InkWell(
            onTap: _handleBack,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Center(
                child: Transform.scale(
                  scaleX: isArabic ? -1.0 : 1.0,
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.onBackground,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFailureView(String errorMessage, AppLocalizations l10n) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final isArabic = l10n.isArabic;

    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 56,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.onBackground,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _cubit?.load(widget.movieId!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    l10n.tryAgain,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        PositionedDirectional(
          top: topPadding + 8,
          start: 16,
          child: InkWell(
            onTap: _handleBack,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Center(
                child: Transform.scale(
                  scaleX: isArabic ? -1.0 : 1.0,
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.onBackground,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentView(
    BuildContext context,
    Movie movie,
    MovieDetailsState state,
  ) {
    final hasDescription = movie.descriptionFull.trim().isNotEmpty ||
        movie.summary.trim().isNotEmpty;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: HeroHeader(
            movie: movie,
            onBack: _handleBack,
            bookmarkAction: _buildBookmarkButton(context, movie),
            onWatchTrailer: () => _handleWatchTrailer(movie),
            isTrailerLoading: _isTrailerLaunching,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: MovieIdentityHeader(movie: movie),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(
          child: WatchButton(
            movie: movie,
            onWatchTrailer: () => _handleWatchTrailer(movie),
            isLoading: _isTrailerLaunching,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(
          child: StatisticsRow(movie: movie),
        ),
        if (movie.screenshotUrls.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: ScreenshotsSection(screenshotUrls: movie.screenshotUrls),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(
          child: SimilarMoviesSection(
            currentMovieId: movie.id,
            suggestions: state.suggestions,
            isLoading: state.isLoadingSuggestions,
            errorMessage: state.suggestionsErrorMessage,
            onRetry: () => _cubit?.retrySuggestions(movie.id),
          ),
        ),
        if (hasDescription) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: SummarySection(movie: movie),
          ),
        ],
        if (movie.cast.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: CastSection(cast: movie.cast),
          ),
        ],
        if (movie.genres.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: GenresSection(genres: movie.genres),
          ),
        ],
        SliverToBoxAdapter(
          child: SizedBox(height: 32 + bottomInset),
        ),
      ],
    );
  }

  Widget _buildBookmarkButton(BuildContext context, Movie movie) {
    final watchlistCubit = _effectiveWatchlistCubit;
    if (watchlistCubit == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);

    return BlocBuilder<WatchlistCubit, WatchlistState>(
      bloc: watchlistCubit,
      builder: (context, watchlistState) {
        final isReady = watchlistState.status == WatchlistStatus.ready ||
            watchlistState.movies.isNotEmpty;
        final isPending = watchlistState.isPending(movie.id);
        final isSaved = watchlistState.containsMovie(movie.id);
        final isAuthenticated = widget.coordinator?.isAuthenticated ?? true;

        final isEnabled = _isValidMovieId && !isPending && isReady;

        final tooltip = !isAuthenticated
            ? l10n.signInToSaveTooltip
            : (!isReady
                ? l10n.checkingWatchListStatus
                : (isSaved
                    ? l10n.removeFromWatchList
                    : l10n.saveToWatchList));

        return Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: isEnabled
                ? () {
                    if (!isAuthenticated) {
                      _showFeedback(l10n.signInToBookmark);
                      return;
                    }
                    watchlistCubit.toggleMovie(LibraryMovie.fromMovie(movie));
                  }
                : null,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Center(
                child: isPending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : (!isReady
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary.withValues(alpha: 0.7),
                            ),
                          )
                        : Icon(
                            isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: isSaved
                                ? AppColors.primary
                                : AppColors.onBackground,
                            size: 20,
                          )),
              ),
            ),
          ),
        );
      },
    );
  }
}
