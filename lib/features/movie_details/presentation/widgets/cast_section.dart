import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:movies_app/core/localization/app_localizations.dart';
import 'package:movies_app/core/theme/app_colors.dart';
import 'package:movies_app/features/movies/domain/entities/cast_member.dart';

class CastSection extends StatelessWidget {
  const CastSection({required this.cast, super.key});

  final List<CastMember> cast;

  @override
  Widget build(BuildContext context) {
    final validCast = cast
        .where((c) => c.name.trim().isNotEmpty)
        .toList(growable: false);

    if (validCast.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.cast,
            style: const TextStyle(
              color: AppColors.onBackground,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          for (final member in validCast) ...[
            _CastItem(member: member),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _CastItem extends StatelessWidget {
  const _CastItem({required this.member});

  final CastMember member;

  @override
  Widget build(BuildContext context) {
    final imageUrl = member.urlSmallImage?.trim() ?? '';
    final hasImage = imageUrl.isNotEmpty;
    final hasCharacter = member.characterName.trim().isNotEmpty;

    return Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: 48,
            height: 48,
            child: hasImage
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const _CastAvatarFallback(),
                    errorWidget: (_, _, _) => const _CastAvatarFallback(),
                  )
                : const _CastAvatarFallback(),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.name,
                style: const TextStyle(
                  color: AppColors.onBackground,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (hasCharacter) ...[
                const SizedBox(height: 2),
                Text(
                  member.characterName,
                  style: const TextStyle(
                    color: AppColors.onBackgroundSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CastAvatarFallback extends StatelessWidget {
  const _CastAvatarFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.inputFill,
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: AppColors.onBackgroundSecondary,
          size: 26,
        ),
      ),
    );
  }
}
