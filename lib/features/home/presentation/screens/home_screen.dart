import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:movies_app/core/constants/route_constants.dart';
import 'package:movies_app/core/localization/app_localizations.dart';
import 'package:movies_app/core/theme/app_colors.dart';
import 'package:movies_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:movies_app/features/home/presentation/cubit/home_state.dart';
import 'package:movies_app/features/home/presentation/widgets/home_featured_carousel.dart';
import 'package:movies_app/features/home/presentation/widgets/home_movie_card.dart';
import 'package:movies_app/features/home/presentation/widgets/home_section_error.dart';
import 'package:movies_app/features/home/presentation/widgets/home_section_header.dart';
import 'package:movies_app/features/home/presentation/widgets/movie_poster_image.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.onSeeMore, super.key});

  final VoidCallback onSeeMore;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _featuredIndex = 0;

  void _openMovie(Movie movie) {
    if (movie.id <= 0) {
      return;
    }
    context.push(RouteConstants.movieDetailsPath(movie.id));
  }

  String _backgroundUrl(HomeState state) {
    if (state.availableNowMovies.isEmpty) {
      return '';
    }
    final index = _featuredIndex.clamp(0, state.availableNowMovies.length - 1);
    final movie = state.availableNowMovies[index];
    final background = movie.backgroundImageOriginal?.trim().isNotEmpty == true
        ? movie.backgroundImageOriginal!.trim()
        : movie.backgroundImage?.trim();
    if (background != null && background.isNotEmpty) {
      return background;
    }
    return movie.bestCoverImage;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      key: const Key('home_screen'),
      backgroundColor: AppColors.background,
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final scale = (constraints.maxWidth / 430).clamp(0.85, 1.15);
              final bottomInset = MediaQuery.paddingOf(context).bottom;
              final bottomNavReserve = 61 + 18 + bottomInset;

              return RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.inputFill,
                onRefresh: () => context.read<HomeCubit>().refresh(),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _HomeBackground(imageUrl: _backgroundUrl(state)),
                    ),
                    CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: EdgeInsets.only(top: 8 * scale),
                              child: HomeScriptHeading(
                                l10n.availableNow,
                                fontSize: 46 * scale,
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: _AvailableNowSection(
                            state: state,
                            scale: scale,
                            onMovieTap: _openMovie,
                            onPageChanged: (index) {
                              setState(() => _featuredIndex = index);
                            },
                            onRetry: () =>
                                context.read<HomeCubit>().retryAvailableNow(),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 8 * scale),
                            child: HomeScriptHeading(
                              l10n.watchNow,
                              fontSize: 52 * scale,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(child: SizedBox(height: 18 * scale)),
                        SliverToBoxAdapter(
                          child: HomeSectionHeader(
                            title: l10n.translateGenre('Action'),
                            actionLabel: l10n.seeMore,
                            onActionPressed: widget.onSeeMore,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: _ActionSection(
                            state: state,
                            scale: scale,
                            onMovieTap: _openMovie,
                            onRetry: () =>
                                context.read<HomeCubit>().retryAction(),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(height: bottomNavReserve),
                        ),
                      ],
                    ),
                    if (state.isLoading && !state.hasAnyMovies)
                      const Positioned.fill(
                        child: ColoredBox(
                          color: Color(0x66121312),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HomeBackground extends StatelessWidget {
  const _HomeBackground({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl.trim().isNotEmpty)
          Opacity(
            opacity: 0.45,
            child: MoviePosterImage(imageUrl: imageUrl, borderRadius: 0),
          )
        else
          const ColoredBox(color: AppColors.background),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xB3121312),
                Color(0xE6121312),
                AppColors.background,
              ],
              stops: [0, 0.45, 1],
            ),
          ),
        ),
      ],
    );
  }
}

class _AvailableNowSection extends StatelessWidget {
  const _AvailableNowSection({
    required this.state,
    required this.scale,
    required this.onMovieTap,
    required this.onPageChanged,
    required this.onRetry,
  });

  final HomeState state;
  final double scale;
  final ValueChanged<Movie> onMovieTap;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (state.availableNowError != null && state.availableNowMovies.isEmpty) {
      return HomeSectionError(
        message: l10n.failedToLoadFeatured,
        onRetry: onRetry,
      );
    }

    if (state.availableNowMovies.isEmpty) {
      if (state.isLoading) {
        return SizedBox(height: 360 * scale);
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Text(
          l10n.noMoviesAvailable,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.onBackgroundSecondary),
        ),
      );
    }

    return Column(
      children: [
        HomeFeaturedCarousel(
          movies: state.availableNowMovies,
          height: 360 * scale,
          onMovieTap: onMovieTap,
          onPageChanged: onPageChanged,
        ),
        if (state.availableNowError != null)
          HomeSectionError(
            message: l10n.failedToLoadFeatured,
            onRetry: onRetry,
          ),
      ],
    );
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.state,
    required this.scale,
    required this.onMovieTap,
    required this.onRetry,
  });

  final HomeState state;
  final double scale;
  final ValueChanged<Movie> onMovieTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (state.actionError != null && state.actionMovies.isEmpty) {
      return HomeSectionError(
        message: l10n.failedToLoadMovies,
        onRetry: onRetry,
      );
    }

    if (state.actionMovies.isEmpty) {
      if (state.isLoading) {
        return SizedBox(height: 220 * scale);
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          l10n.noActionMoviesFound,
          style: const TextStyle(color: AppColors.onBackgroundSecondary),
        ),
      );
    }

    final cardWidth = 146 * scale;
    final cardHeight = 220 * scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        SizedBox(
          height: cardHeight,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: state.actionMovies.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final movie = state.actionMovies[index];
              return HomeMovieCard(
                movie: movie,
                width: cardWidth,
                height: cardHeight,
                borderRadius: 16,
                onTap: () => onMovieTap(movie),
              );
            },
          ),
        ),
        if (state.actionError != null)
          HomeSectionError(
            message: l10n.failedToLoadMovies,
            onRetry: onRetry,
          ),
        if (state.status == HomeStatus.failure && !state.hasAnyMovies)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Center(
              child: TextButton(
                onPressed: () => context.read<HomeCubit>().refresh(),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                child: Text(l10n.tryAgain),
              ),
            ),
          ),
      ],
    );
  }
}
