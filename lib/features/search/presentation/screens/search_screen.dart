import 'package:flutter/material.dart';
import 'package:movies_app/core/theme/app_colors.dart';

/// Temporary Search tab container. Full Search UI is intentionally deferred.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: Key('search_screen'),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Text(
            'Search',
            style: TextStyle(
              color: AppColors.onBackground,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
