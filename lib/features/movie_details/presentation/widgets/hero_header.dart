import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:movies_app/core/theme/app_colors.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';

class HeroHeader extends StatelessWidget {
  const HeroHeader({
    required this.movie,
    required this.onBack,
    this.bookmarkAction,
    super.key,
  });

  final Movie movie;
  final VoidCallback onBack;
  final Widget? bookmarkAction;

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
        const Positioned.fill(
          child: Center(
            child: _PlayIndicator(),
          ),
        ),
        Positioned(
          top: topPadding + 8,
          left: 16,
          child: _BackButton(onBack: onBack),
        ),
        if (bookmarkAction != null)
          Positioned(
            top: topPadding + 8,
            right: 16,
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
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.onBackground,
          size: 18,
        ),
      ),
    );
  }
}

class _PlayIndicator extends StatelessWidget {
  const _PlayIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.play_arrow_rounded,
          color: AppColors.onPrimary,
          size: 38,
        ),
      ),
    );
  }
}
