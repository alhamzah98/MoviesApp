import 'package:flutter/material.dart';
import 'package:movies_app/core/theme/app_colors.dart';

class AvatarSelector extends StatelessWidget {
  const AvatarSelector({
    required this.avatarAssetPaths,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<String> avatarAssetPaths;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const double _largeSize = 158;
  static const double _smallSize = 94;

  @override
  Widget build(BuildContext context) {
    assert(avatarAssetPaths.length == 3);
    assert(selectedIndex >= 0 && selectedIndex < avatarAssetPaths.length);

    return Column(
      children: [
        SizedBox(
          height: _largeSize,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(avatarAssetPaths.length, (index) {
              final selected = index == selectedIndex;
              return _AvatarOption(
                assetPath: avatarAssetPaths[index],
                size: selected ? _largeSize : _smallSize,
                onTap: () => onSelected(index),
              );
            }),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Avatar',
          style: TextStyle(
            color: AppColors.onBackground,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _AvatarOption extends StatelessWidget {
  const _AvatarOption({
    required this.assetPath,
    required this.size,
    required this.onTap,
  });

  final String assetPath;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: size,
        height: size,
        child: ClipOval(
          child: Image.asset(assetPath, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
