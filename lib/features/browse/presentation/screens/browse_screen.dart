import 'package:flutter/material.dart';
import 'package:movies_app/core/theme/app_colors.dart';

/// Temporary Browse tab container. Full Browse UI is intentionally deferred.
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: Key('browse_screen'),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Text(
            'Browse',
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
