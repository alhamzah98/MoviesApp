import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:movies_app/core/constants/route_constants.dart';
import 'package:movies_app/core/theme/app_colors.dart';
import 'package:movies_app/features/auth/domain/entities/app_user.dart';
import 'package:movies_app/features/home/presentation/widgets/home_movie_card.dart';
import 'package:movies_app/features/library/domain/entities/library_movie.dart';
import 'package:movies_app/features/library/presentation/cubit/history_cubit.dart';
import 'package:movies_app/features/library/presentation/cubit/history_state.dart';
import 'package:movies_app/features/library/presentation/cubit/watchlist_cubit.dart';
import 'package:movies_app/features/library/presentation/cubit/watchlist_state.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';
import 'package:movies_app/features/profile/presentation/constants/avatar_constants.dart';
import 'package:movies_app/shared/widgets/movies_primary_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    this.user,
    this.watchlistCubit,
    this.historyCubit,
    this.watchlistMovies,
    this.historyMovies,
    this.isLoading = false,
    this.errorMessage,
    this.onEditProfile,
    this.onLogout,
    super.key,
  });

  final AppUser? user;
  final WatchlistCubit? watchlistCubit;
  final HistoryCubit? historyCubit;
  final List<LibraryMovie>? watchlistMovies;
  final List<LibraryMovie>? historyMovies;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onEditProfile;
  final VoidCallback? onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTabIndex = 0; // 0 = Watch List, 1 = History

  void _handleEditProfile() {
    if (widget.onEditProfile != null) {
      widget.onEditProfile!();
    } else {
      context.push(RouteConstants.updateProfile, extra: widget.user);
    }
  }

  void _handleLogout() {
    if (widget.onLogout != null) {
      _showLogoutConfirmationDialog();
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Authentication integration will be enabled in the upcoming phase.',
          ),
          backgroundColor: AppColors.inputFill,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showLogoutConfirmationDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1F1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              color: AppColors.onBackground,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out of your account?',
            style: TextStyle(
              color: AppColors.onBackgroundSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.onBackgroundSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                widget.onLogout!();
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openMovie(int movieId) {
    if (movieId <= 0) return;
    context.push(RouteConstants.movieDetailsPath(movieId));
  }

  Movie _libraryToMovie(LibraryMovie libraryMovie) {
    return Movie(
      id: libraryMovie.movieId,
      title: libraryMovie.title,
      year: libraryMovie.year,
      rating: libraryMovie.rating,
      genres: libraryMovie.genres,
      summary: libraryMovie.summary,
      mediumCoverImage: libraryMovie.mediumCoverImage,
      largeCoverImage: libraryMovie.largeCoverImage,
      backgroundImage: libraryMovie.backgroundImage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomNavReserve = 61 + 18 + bottomInset;

    if (widget.watchlistCubit != null && widget.historyCubit != null) {
      return BlocBuilder<WatchlistCubit, WatchlistState>(
        bloc: widget.watchlistCubit,
        builder: (context, watchlistState) {
          return BlocBuilder<HistoryCubit, HistoryState>(
            bloc: widget.historyCubit,
            builder: (context, historyState) {
              return _buildScaffold(
                bottomNavReserve,
                watchlistState: watchlistState,
                historyState: historyState,
              );
            },
          );
        },
      );
    }

    if (widget.watchlistCubit != null) {
      return BlocBuilder<WatchlistCubit, WatchlistState>(
        bloc: widget.watchlistCubit,
        builder: (context, watchlistState) {
          return _buildScaffold(
            bottomNavReserve,
            watchlistState: watchlistState,
          );
        },
      );
    }

    if (widget.historyCubit != null) {
      return BlocBuilder<HistoryCubit, HistoryState>(
        bloc: widget.historyCubit,
        builder: (context, historyState) {
          return _buildScaffold(
            bottomNavReserve,
            historyState: historyState,
          );
        },
      );
    }

    return _buildScaffold(bottomNavReserve);
  }

  Widget _buildScaffold(
    double bottomNavReserve, {
    WatchlistState? watchlistState,
    HistoryState? historyState,
  }) {
    final int? watchlistCount;
    if (watchlistState != null) {
      final isKnown = watchlistState.status == WatchlistStatus.ready ||
          watchlistState.movies.isNotEmpty;
      watchlistCount = isKnown ? watchlistState.movies.length : null;
    } else {
      watchlistCount = widget.watchlistMovies?.length;
    }

    final int? historyCount;
    if (historyState != null) {
      final isKnown = historyState.status == HistoryStatus.ready ||
          historyState.movies.isNotEmpty;
      historyCount = isKnown ? historyState.movies.length : null;
    } else {
      historyCount = widget.historyMovies?.length;
    }

    return Scaffold(
      key: const Key('profile_screen'),
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: _ProfileHeader(
                  user: widget.user,
                  onEditProfile: _handleEditProfile,
                  onLogout: _handleLogout,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _StatsSummaryRow(
                  watchlistCount: watchlistCount,
                  historyCount: historyCount,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _ProfileTabBar(
                  selectedIndex: _selectedTabIndex,
                  onTabChanged: (index) =>
                      setState(() => _selectedTabIndex = index),
                ),
              ),
            ),
            _buildTabContent(
              bottomNavReserve,
              watchlistState: watchlistState,
              historyState: historyState,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(
    double bottomNavReserve, {
    WatchlistState? watchlistState,
    HistoryState? historyState,
  }) {
    if (widget.isLoading) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 48, 16, bottomNavReserve),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    if (widget.errorMessage != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 36, 16, bottomNavReserve),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              Text(
                widget.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.onBackground,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isWatchlist = _selectedTabIndex == 0;

    if (isWatchlist && watchlistState != null) {
      if (watchlistState.status == WatchlistStatus.loading &&
          watchlistState.movies.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 48, 16, bottomNavReserve),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        );
      }

      if (watchlistState.status == WatchlistStatus.failure &&
          watchlistState.movies.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 36, 16, bottomNavReserve),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 56,
                  color: AppColors.error,
                ),
                const SizedBox(height: 12),
                Text(
                  watchlistState.errorMessage ??
                      'Unable to load your watch list.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.onBackground,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => widget.watchlistCubit?.retry(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        );
      }

      if (watchlistState.status == WatchlistStatus.ready &&
          watchlistState.movies.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 36, 16, bottomNavReserve),
            child: const _EmptyListView(
              title: 'Your Watch List is Empty',
              subtitle: 'Movies you add to your watch list will appear here.',
              icon: Icons.bookmark_border_rounded,
            ),
          ),
        );
      }

      if (watchlistState.movies.isNotEmpty) {
        return _buildMoviesGrid(
          watchlistState.movies,
          bottomNavReserve,
          isWatchlist: true,
          watchlistState: watchlistState,
        );
      }
    }

    if (!isWatchlist && historyState != null) {
      if (historyState.status == HistoryStatus.loading &&
          historyState.movies.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 48, 16, bottomNavReserve),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        );
      }

      if (historyState.status == HistoryStatus.failure &&
          historyState.movies.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 36, 16, bottomNavReserve),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 56,
                  color: AppColors.error,
                ),
                const SizedBox(height: 12),
                Text(
                  historyState.errorMessage ??
                      'Unable to load your watch history.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.onBackground,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => widget.historyCubit?.retry(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        );
      }

      if (historyState.status == HistoryStatus.ready &&
          historyState.movies.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 36, 16, bottomNavReserve),
            child: const _EmptyListView(
              title: 'No History Recorded',
              subtitle: 'Movies you have viewed will appear here.',
              icon: Icons.history_rounded,
            ),
          ),
        );
      }

      if (historyState.movies.isNotEmpty) {
        return _buildMoviesGrid(
          historyState.movies,
          bottomNavReserve,
          isWatchlist: false,
        );
      }
    }

    // Fallback path for manually provided list inputs
    final movies =
        isWatchlist ? widget.watchlistMovies : widget.historyMovies;

    if (movies == null) {
      final isSignedIn = widget.user != null;
      final subtitle = isWatchlist
          ? (isSignedIn
              ? 'Watch list sync is currently unavailable and will be integrated in an upcoming phase.'
              : 'Sign in to sync and view your saved watch list.')
          : (isSignedIn
              ? 'Watch history tracking is currently unavailable and will be integrated in an upcoming phase.'
              : 'Sign in to track and view your watch history.');

      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 36, 16, bottomNavReserve),
          child: _UnavailableView(
            title:
                isWatchlist ? 'Watch List Unavailable' : 'History Unavailable',
            subtitle: subtitle,
          ),
        ),
      );
    }

    if (movies.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 36, 16, bottomNavReserve),
          child: _EmptyListView(
            title: isWatchlist
                ? 'Your Watch List is Empty'
                : 'No History Recorded',
            subtitle: isWatchlist
                ? 'Movies you add to your watch list will appear here.'
                : 'Movies you have watched will appear here.',
            icon: isWatchlist
                ? Icons.bookmark_border_rounded
                : Icons.history_rounded,
          ),
        ),
      );
    }

    return _buildMoviesGrid(
      movies,
      bottomNavReserve,
      isWatchlist: isWatchlist,
    );
  }

  Widget _buildMoviesGrid(
    List<LibraryMovie> movies,
    double bottomNavReserve, {
    required bool isWatchlist,
    WatchlistState? watchlistState,
  }) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomNavReserve),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.68,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final libraryMovie = movies[index];
            final movie = _libraryToMovie(libraryMovie);
            final isPending = isWatchlist &&
                (watchlistState?.isPending(libraryMovie.movieId) ?? false);

            return Stack(
              children: [
                Positioned.fill(
                  child: HomeMovieCard(
                    movie: movie,
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 16,
                    onTap: () => _openMovie(libraryMovie.movieId),
                  ),
                ),
                if (isWatchlist && widget.watchlistCubit != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Tooltip(
                      message: 'Remove from Watch List',
                      child: InkWell(
                        onTap: isPending
                            ? null
                            : () => widget.watchlistCubit!
                                .removeMovie(libraryMovie.movieId),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Center(
                            child: isPending
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : const Icon(
                                    Icons.bookmark_remove_rounded,
                                    color: AppColors.primary,
                                    size: 16,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
          childCount: movies.length,
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.onEditProfile,
    required this.onLogout,
  });

  final AppUser? user;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final avatarPath = ProfileAvatars.assetPathFor(user?.avatarId);
    final displayName = user?.name?.trim().isNotEmpty == true
        ? user!.name!.trim()
        : (user != null ? 'User' : 'Guest User');
    final email = user?.email.trim() ?? 'Not signed in';

    return Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: 80,
            height: 80,
            child: Image.asset(avatarPath, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.onBackground,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.onBackgroundSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: onEditProfile,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 36,
                    child: OutlinedButton.icon(
                      onPressed: onLogout,
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 16,
                        color: AppColors.error,
                      ),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsSummaryRow extends StatelessWidget {
  const _StatsSummaryRow({
    required this.watchlistCount,
    required this.historyCount,
  });

  final int? watchlistCount;
  final int? historyCount;

  @override
  Widget build(BuildContext context) {
    final watchlistLabel =
        watchlistCount != null ? watchlistCount.toString() : '-';
    final historyLabel =
        historyCount != null ? historyCount.toString() : '-';

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.bookmark_rounded,
            count: watchlistLabel,
            title: 'Watch List',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.history_rounded,
            count: historyLabel,
            title: 'History',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.count,
    required this.title,
  });

  final IconData icon;
  final String count;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: const TextStyle(
                  color: AppColors.onBackground,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.onBackgroundSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileTabBar extends StatelessWidget {
  const _ProfileTabBar({
    required this.selectedIndex,
    required this.onTabChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              title: 'Watch List',
              icon: Icons.bookmark_outline_rounded,
              isSelected: selectedIndex == 0,
              onTap: () => onTabChanged(0),
            ),
          ),
          Expanded(
            child: _TabButton(
              title: 'History',
              icon: Icons.history_rounded,
              isSelected: selectedIndex == 1,
              onTap: () => onTabChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color:
                  isSelected ? AppColors.onPrimary : AppColors.onBackgroundSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color:
                    isSelected ? AppColors.onPrimary : AppColors.onBackground,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnavailableView extends StatelessWidget {
  const _UnavailableView({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.cloud_off_rounded,
          size: 64,
          color: AppColors.onBackgroundSecondary,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.onBackground,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.onBackgroundSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _EmptyListView extends StatelessWidget {
  const _EmptyListView({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 64,
          color: AppColors.onBackgroundSecondary,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.onBackground,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.onBackgroundSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
