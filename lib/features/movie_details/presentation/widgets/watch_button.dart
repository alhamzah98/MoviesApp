import 'package:flutter/material.dart';
import 'package:movies_app/core/localization/app_localizations.dart';
import 'package:movies_app/core/theme/app_colors.dart';
import 'package:movies_app/features/movie_details/services/trailer_launcher.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';

class WatchButton extends StatelessWidget {
  const WatchButton({
    required this.movie,
    this.onWatchTrailer,
    this.isLoading = false,
    super.key,
  });

  final Movie movie;
  final VoidCallback? onWatchTrailer;
  final bool isLoading;

  static const Color redWatchColor = Color(0xFFE50914);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasTrailer = TrailerLauncher.hasValidTrailerCode(movie.youtubeTrailerCode);
    final isEnabled = hasTrailer && !isLoading && onWatchTrailer != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: isEnabled ? onWatchTrailer : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: redWatchColor,
            disabledBackgroundColor: redWatchColor.withValues(alpha: 0.35),
            foregroundColor: AppColors.onBackground,
            disabledForegroundColor:
                AppColors.onBackground.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onBackground,
                  ),
                )
              else
                Icon(
                  Icons.play_arrow_rounded,
                  size: 24,
                  color: isEnabled
                      ? AppColors.onBackground
                      : AppColors.onBackground.withValues(alpha: 0.5),
                ),
              const SizedBox(width: 8),
              Text(
                hasTrailer ? l10n.watchTrailer : l10n.trailerUnavailable,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
