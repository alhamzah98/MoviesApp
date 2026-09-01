import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:movies_app/core/theme/app_colors.dart';

class MoviePosterImage extends StatelessWidget {
  const MoviePosterImage({
    required this.imageUrl,
    this.borderRadius = 16,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String imageUrl;
  final double borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final trimmed = imageUrl.trim();
    final hasUrl = trimmed.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: ColoredBox(
        color: AppColors.inputFill,
        child: hasUrl
            ? CachedNetworkImage(
                imageUrl: trimmed,
                fit: fit,
                width: double.infinity,
                height: double.infinity,
                placeholder: (_, _) => const _PosterPlaceholder(
                  icon: Icons.local_movies_outlined,
                ),
                errorWidget: (_, _, _) => const _PosterPlaceholder(
                  icon: Icons.broken_image_outlined,
                ),
              )
            : const _PosterPlaceholder(
                icon: Icons.broken_image_outlined,
              ),
      ),
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.inputFill,
      child: Center(
        child: Icon(
          icon,
          color: AppColors.onBackgroundSecondary,
          size: 28,
        ),
      ),
    );
  }
}
