import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:movies_app/core/constants/route_constants.dart';
import 'package:movies_app/core/localization/app_localizations.dart';
import 'package:movies_app/core/theme/app_colors.dart';
import 'package:movies_app/features/home/presentation/widgets/home_movie_card.dart';
import 'package:movies_app/features/home/presentation/widgets/home_section_error.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';
import 'package:movies_app/features/movies/domain/use_cases/get_movies.dart';
import 'package:movies_app/features/search/presentation/cubit/search_cubit.dart';
import 'package:movies_app/features/search/presentation/cubit/search_state.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({required this.getMovies, super.key});

  final GetMovies getMovies;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final SearchCubit _searchCubit;
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  Timer? _debounceTimer;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _searchCubit = SearchCubit(getMovies: widget.getMovies);
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchCubit.close();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    final trimmed = query.trim();
    final hasText = trimmed.isNotEmpty;
    if (_hasText != hasText) {
      setState(() => _hasText = hasText);
    }

    _debounceTimer?.cancel();
    if (!hasText) {
      _searchCubit.clearSearch();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchCubit.search(trimmed);
    });
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() => _hasText = false);
    _searchCubit.clearSearch();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      _searchCubit.loadNextPage();
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
      value: _searchCubit,
      child: Scaffold(
        key: const Key('search_screen'),
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: _SearchBar(
                  controller: _searchController,
                  hasText: _hasText,
                  onChanged: _onQueryChanged,
                  onClear: _clearSearch,
                ),
              ),
              Expanded(
                child: BlocBuilder<SearchCubit, SearchState>(
                  builder: (context, state) {
                    return _buildBody(context, state, bottomNavReserve);
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
    SearchState state,
    double bottomNavReserve,
  ) {
    final l10n = AppLocalizations.of(context);

    if (state.isInitial) {
      return Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 24, 16, bottomNavReserve),
          child: const _SearchInitialView(),
        ),
      );
    }

    if (state.isInitialLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.status == SearchStatus.failure && !state.hasMovies) {
      return Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 24, 16, bottomNavReserve),
          child: _SearchErrorView(
            message: state.errorMessage ?? l10n.failedToSearch,
            onRetry: () => _searchCubit.retry(),
          ),
        ),
      );
    }

    if (state.isEmptySuccess) {
      return Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 24, 16, bottomNavReserve),
          child: _SearchEmptyView(query: state.query),
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
                onRetry: () => _searchCubit.loadNextPage(),
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

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.hasText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: AppColors.onBackgroundSecondary,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: AppColors.primary,
              style: const TextStyle(
                color: AppColors.onBackground,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                hintStyle: const TextStyle(
                  color: AppColors.onBackgroundSecondary,
                  fontSize: 16,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (hasText)
            IconButton(
              onPressed: onClear,
              tooltip: l10n.clearSearchTooltip,
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.onBackgroundSecondary,
                size: 20,
              ),
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

class _SearchInitialView extends StatelessWidget {
  const _SearchInitialView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.local_movies_outlined,
          size: 72,
          color: AppColors.onBackgroundSecondary.withValues(alpha: 0.45),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.searchMoviesTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.onBackground,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.searchMoviesSubtitle,
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

class _SearchEmptyView extends StatelessWidget {
  const _SearchEmptyView({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.search_off_rounded,
          size: 64,
          color: AppColors.onBackgroundSecondary,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.noMoviesFoundForQuery(query),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.onBackground,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.searchCheckSpelling,
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

class _SearchErrorView extends StatelessWidget {
  const _SearchErrorView({
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
