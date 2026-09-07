import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:movies_app/core/localization/app_localizations.dart';
import 'package:movies_app/core/theme/app_colors.dart';

class ScreenshotsSection extends StatelessWidget {
  const ScreenshotsSection({required this.screenshotUrls, super.key});

  final List<String> screenshotUrls;

  @override
  Widget build(BuildContext context) {
    if (screenshotUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayedUrls = screenshotUrls.take(3).toList();
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.screenshots,
            style: const TextStyle(
              color: AppColors.onBackground,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          for (final url in displayedUrls) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const ColoredBox(
                    color: AppColors.inputFill,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (_, _, _) => const ColoredBox(
                    color: AppColors.inputFill,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.onBackgroundSecondary,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
