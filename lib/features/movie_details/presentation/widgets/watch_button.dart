import 'package:flutter/material.dart';
import 'package:movies_app/core/theme/app_colors.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';

class WatchButton extends StatelessWidget {
  const WatchButton({required this.movie, super.key});

  final Movie movie;

  static const Color redWatchColor = Color(0xFFE50914);

  void _onPressed(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trailer playback will be enabled in the integration phase.'),
        backgroundColor: AppColors.inputFill,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasTrailer = movie.youtubeTrailerCode != null &&
        movie.youtubeTrailerCode!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: hasTrailer ? () => _onPressed(context) : null,
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
              Icon(
                Icons.play_arrow_rounded,
                size: 24,
                color: hasTrailer
                    ? AppColors.onBackground
                    : AppColors.onBackground.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              const Text(
                'Watch',
                style: TextStyle(
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
