import 'package:flutter/material.dart';
import 'package:movies_app/core/localization/app_localizations.dart';
import 'package:movies_app/core/theme/app_colors.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';

class StatisticsRow extends StatelessWidget {
  const StatisticsRow({required this.movie, super.key});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final hasLikes = movie.likeCount > 0;
    final hasRuntime = movie.runtime > 0;
    final hasRating = movie.rating > 0;

    if (!hasLikes && !hasRuntime && !hasRating) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final ratingString = movie.rating == movie.rating.roundToDouble()
        ? movie.rating.toStringAsFixed(0)
        : movie.rating.toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasLikes)
            Expanded(
              child: _StatCard(
                icon: Icons.favorite_rounded,
                label: movie.likeCount.toString(),
              ),
            ),
          if (hasLikes && (hasRuntime || hasRating))
            const SizedBox(width: 12),
          if (hasRuntime)
            Expanded(
              child: _StatCard(
                icon: Icons.access_time_filled_rounded,
                label: '${movie.runtime} ${l10n.minutesShort}',
              ),
            ),
          if (hasRuntime && hasRating)
            const SizedBox(width: 12),
          if (hasRating)
            Expanded(
              child: _StatCard(
                icon: Icons.star_rounded,
                label: ratingString,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.onBackground,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
