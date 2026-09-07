import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:movies_app/core/constants/route_constants.dart';
import 'package:movies_app/core/localization/app_localizations.dart';
import 'package:movies_app/core/theme/app_colors.dart';
import 'package:movies_app/features/browse/presentation/constants/browse_genres.dart';
import 'package:movies_app/features/browse/presentation/cubit/browse_cubit.dart';
import 'package:movies_app/features/browse/presentation/cubit/browse_state.dart';
import 'package:movies_app/features/home/presentation/widgets/home_movie_card.dart';
import 'package:movies_app/features/home/presentation/widgets/home_section_error.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';
import 'package:movies_app/features/movies/domain/use_cases/get_movies.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({
    required this.getMovies,
    this.initialGenre = BrowseGenres.defaultGenre,
    super.key,
  });

  final GetMovies getMovies;
  final String initialGenre;

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  late final BrowseCubit _browseCubit;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _browseCubit = BrowseCubit(
      getMovies: widget.getMovies,
      initialGenre: widget.initialGenre,
    )..loadInitial();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _browseCubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      _browseCubit.loadNextPage();
    }
  }

  void _openMovie(Movie movie) {
    if (movie.id <= 0) {
      return;
    }
    context.push(RouteConstants.movieDetailsPath(movie.id));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomNavReserve = 61 + 18 + bottomInset;

    return BlocProvider.value(
      value: _browseCubit,
      child: Scaffold(
        key: const Key('browse_screen'),
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              BlocBuilder<BrowseCubit, BrowseState>(
                buildWhen: (previous, current) =>
                    previous.selectedGenre != current.selectedGenre,
                builder: (context, state) {
                  return _GenreChipsBar(
                    selectedGenre: state.selectedGenre,
                    onGenreSelected: (genre) => _browseCubit.selectGenre(genre),
                  );
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: BlocBuilder<BrowseCubit, BrowseState>(
                  builder: (context, state) {
                    return RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.inputFill,
                      onRefresh: () => _browseCubit.refresh(),
                      child: _buildBody(context, state, bottomNavReserve),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    BrowseState state,
    double bottomNavReserve,
  ) {
    final l10n = AppLocalizations.of(context);

    if (state.isInitialLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.status == BrowseStatus.failure && !state.hasMovies) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 24, 16, bottomNavReserve),
          child: _BrowseErrorView(
            message: state.errorMessage ?? l10n.failedToLoadGenre,
            onRetry: () => _browseCubit.retry(),
          ),
        ),
      );
    }

    if (state.isEmptySuccess) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 24, 16, bottomNavReserve),
          child: _BrowseEmptyView(genre: state.selectedGenre),
        ),
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.68,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final movie = state.movies[index];
                return HomeMovieCard(
                  movie: movie,
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 16,
                  onTap: () => _openMovie(movie),
                );
              },
              childCount: state.movies.length,
            ),
          ),
        ),
        if (state.isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          ),
        if (state.paginationErrorMessage != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: HomeSectionError(
                message: l10n.failedToLoadMovies,
                onRetry: () => _browseCubit.loadNextPage(),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: SizedBox(height: bottomNavReserve),
        ),
      ],
    );
  }
}

class _GenreChipsBar extends StatelessWidget {
  const _GenreChipsBar({
    required this.selectedGenre,
    required this.onGenreSelected,
  });

  final String selectedGenre;
  final ValueChanged<String> onGenreSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: BrowseGenres.all.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final genre = BrowseGenres.all[index];
          final isSelected =
              genre.toLowerCase() == selectedGenre.toLowerCase();
          return _GenreChip(
            genre: genre,
            isSelected: isSelected,
            onTap: () => onGenreSelected(genre),
          );
        },
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({
    required this.genre,
    required this.isSelected,
    required this.onTap,
  });

  final String genre;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            l10n.translateGenre(genre),
            style: TextStyle(
              color: isSelected ? AppColors.onPrimary : AppColors.onBackground,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _BrowseErrorView extends StatelessWidget {
  const _BrowseErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 56,
          color: AppColors.error,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.onBackground,
            fontSize: 15,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            l10n.tryAgain,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _BrowseEmptyView extends StatelessWidget {
  const _BrowseEmptyView({required this.genre});

  final String genre;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.local_movies_outlined,
          size: 64,
          color: AppColors.onBackgroundSecondary,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.noMoviesFoundForGenre(genre),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.onBackground,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.tryAnotherGenre,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.onBackgroundSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
