import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movies_app/core/constants/route_constants.dart';
import 'package:movies_app/core/localization/app_localizations.dart';
import 'package:movies_app/core/theme/app_colors.dart';
import 'package:movies_app/features/home/presentation/widgets/home_movie_card.dart';
import 'package:movies_app/features/home/presentation/widgets/home_section_error.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';

class SimilarMoviesSection extends StatelessWidget {
  const SimilarMoviesSection({
    required this.currentMovieId,
    required this.suggestions,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    super.key,
  });

  final int currentMovieId;
  final List<Movie> suggestions;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final validSuggestions = suggestions
        .where((m) => m.id > 0 && m.id != currentMovieId)
        .toList(growable: false);

    if (!isLoading && errorMessage == null && validSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            l10n.similarMovies,
            style: const TextStyle(
              color: AppColors.onBackground,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (errorMessage != null && validSuggestions.isEmpty)
          HomeSectionError(
            message: errorMessage!,
            onRetry: onRetry,
          )
        else
          SizedBox(
            height: 220,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: validSuggestions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final movie = validSuggestions[index];
                return HomeMovieCard(
                  movie: movie,
                  width: 146,
                  height: 220,
                  borderRadius: 16,
                  onTap: () {
                    context.pushReplacement(
                      RouteConstants.movieDetailsPath(movie.id),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
