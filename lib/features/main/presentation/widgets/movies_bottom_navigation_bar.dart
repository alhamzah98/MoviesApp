import 'package:flutter/material.dart';
import 'package:movies_app/core/theme/app_colors.dart';

class MoviesBottomNavigationBar extends StatelessWidget {
  const MoviesBottomNavigationBar({
    required this.currentIndex,
    required this.onChanged,
    super.key,
  });

  static const int tabCount = 4;

  static const List<String> tabKeys = [
    'home_tab',
    'search_tab',
    'browse_tab',
    'profile_tab',
  ];

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeIndex = currentIndex.clamp(0, tabCount - 1);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 0, 9, 10),
        child: Container(
          height: 61,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(
                key: const Key('home_tab'),
                icon: Icons.home_rounded,
                selected: safeIndex == 0,
                onTap: () => onChanged(0),
              ),
              _NavItem(
                key: const Key('search_tab'),
                icon: Icons.search_rounded,
                selected: safeIndex == 1,
                onTap: () => onChanged(1),
              ),
              _NavItem(
                key: const Key('browse_tab'),
                icon: Icons.explore_outlined,
                selected: safeIndex == 2,
                onTap: () => onChanged(2),
              ),
              _NavItem(
                key: const Key('profile_tab'),
                icon: Icons.person_outline_rounded,
                selected: safeIndex == 3,
                onTap: () => onChanged(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: '',
      splashRadius: 24,
      icon: Icon(
        icon,
        size: 26,
        color: selected ? AppColors.primary : AppColors.onBackgroundSecondary,
      ),
    );
  }
}
