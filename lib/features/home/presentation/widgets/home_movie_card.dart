import 'package:flutter/material.dart';
import 'package:movies_app/core/theme/app_colors.dart';
import 'package:movies_app/features/home/presentation/widgets/movie_poster_image.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';

class HomeMovieCard extends StatelessWidget {
  const HomeMovieCard({
    required this.movie,
    required this.width,
    required this.height,
    required this.onTap,
    this.borderRadius = 16,
    this.showShadow = false,
    super.key,
  });

  final Movie movie;
  final double width;
  final double height;
  final VoidCallback onTap;
  final double borderRadius;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: showShadow
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              )
            : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MoviePosterImage(
              imageUrl: movie.bestCoverImage,
              borderRadius: borderRadius,
            ),
            Positioned(
              top: 10,
              left: 10,
              child: _RatingChip(rating: movie.rating),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final label = rating == rating.roundToDouble()
        ? rating.toStringAsFixed(0)
        : rating.toStringAsFixed(1);

    return Container(
      width: 58,
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xCC121312),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.onBackground,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.star_rounded,
            color: AppColors.primary,
            size: 16,
          ),
        ],
      ),
    );
  }
}
