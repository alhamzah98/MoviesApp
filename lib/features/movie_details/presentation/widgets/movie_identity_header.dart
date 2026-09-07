import 'package:flutter/material.dart';
import 'package:movies_app/core/theme/app_colors.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';

class MovieIdentityHeader extends StatelessWidget {
  const MovieIdentityHeader({required this.movie, super.key});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final title = movie.title.trim();
    final hasYear = movie.year > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            title.isNotEmpty ? title : 'Untitled',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.onBackground,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          if (hasYear) ...[
            const SizedBox(height: 6),
            Text(
              movie.year.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.onBackgroundSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
