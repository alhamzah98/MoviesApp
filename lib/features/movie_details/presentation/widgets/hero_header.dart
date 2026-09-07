import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:movies_app/core/localization/app_localizations.dart';
import 'package:movies_app/core/theme/app_colors.dart';
import 'package:movies_app/features/movie_details/services/trailer_launcher.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';

class HeroHeader extends StatelessWidget {
  const HeroHeader({
    required this.movie,
    required this.onBack,
    this.bookmarkAction,
    this.onWatchTrailer,
    this.isTrailerLoading = false,
    super.key,
  });

  final Movie movie;
  final VoidCallback onBack;
  final Widget? bookmarkAction;
  final VoidCallback? onWatchTrailer;
  final bool isTrailerLoading;

  String _resolveHeroUrl() {
    final original = movie.backgroundImageOriginal?.trim();
    if (original != null && original.isNotEmpty) return original;
    final bg = movie.backgroundImage?.trim();
    if (bg != null && bg.isNotEmpty) return bg;
    final large = movie.largeCoverImage?.trim();
    if (large != null && large.isNotEmpty) return large;
    final medium = movie.mediumCoverImage?.trim();
    if (medium != null && medium.isNotEmpty) return medium;
    final small = movie.smallCoverImage?.trim();
    if (small != null && small.isNotEmpty) return small;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final heroUrl = _resolveHeroUrl();
    final topPadding = MediaQuery.paddingOf(context).top;
    final l10n = AppLocalizations.of(context);
    final hasTrailer =
        TrailerLauncher.hasValidTrailerCode(movie.youtubeTrailerCode);
    final canPlayTrailer =
        hasTrailer && !isTrailerLoading && onWatchTrailer != null;

    return Stack(
      children: [
        SizedBox(
          height: 380,
          width: double.infinity,
          child: heroUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: heroUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (_, _) => const ColoredBox(
                    color: AppColors.inputFill,
                    child: Center(
                      child: Icon(
                        Icons.local_movies_outlined,
                        color: AppColors.onBackgroundSecondary,
                        size: 48,
                      ),
                    ),
                  ),
                  errorWidget: (_, _, _) => const ColoredBox(
                    color: AppColors.inputFill,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.onBackgroundSecondary,
                        size: 48,
                      ),
                    ),
                  ),
                )
              : const ColoredBox(
                  color: AppColors.inputFill,
                  child: Center(
                    child: Icon(
                      Icons.local_movies_outlined,
                      color: AppColors.onBackgroundSecondary,
                      size: 48,
                    ),
                  ),
                ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                  AppColors.background.withValues(alpha: 0.8),
                  AppColors.background,
                ],
                stops: const [0.0, 0.35, 0.75, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: _PlayIndicator(
              isEnabled: canPlayTrailer,
              isLoading: isTrailerLoading,
              tooltip: hasTrailer ? l10n.watchTrailer : l10n.trailerUnavailable,
              onTap: canPlayTrailer ? onWatchTrailer : null,
            ),
          ),
        ),
        PositionedDirectional(
          top: topPadding + 8,
          start: 16,
          child: _BackButton(onBack: onBack),
        ),
        if (bookmarkAction != null)
          PositionedDirectional(
            top: topPadding + 8,
            end: 16,
            child: bookmarkAction!,
          ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLocalizations.of(context).isArabic;

    return InkWell(
      onTap: onBack,
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
    );
  }
}

class _PlayIndicator extends StatelessWidget {
  const _PlayIndicator({
    required this.isEnabled,
    required this.isLoading,
    required this.tooltip,
    this.onTap,
  });

  final bool isEnabled;
  final bool isLoading;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: isEnabled
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.4),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isEnabled ? 0.45 : 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.onPrimary,
                      strokeWidth: 2.5,
                    ),
                  )
                : Icon(
                    Icons.play_arrow_rounded,
                    color: isEnabled
                        ? AppColors.onPrimary
                        : AppColors.onPrimary.withValues(alpha: 0.5),
                    size: 38,
                  ),
          ),
        ),
      ),
    );
  }
}
