import 'package:flutter/material.dart';
import 'package:movies_app/core/theme/app_colors.dart';

/// Temporary Profile tab container. Full Profile UI is intentionally deferred.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: Key('profile_screen'),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Text(
            'Profile',
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
