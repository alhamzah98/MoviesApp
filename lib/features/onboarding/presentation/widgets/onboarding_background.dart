import 'package:flutter/material.dart';
import 'package:movies_app/features/onboarding/presentation/models/onboarding_page_data.dart';

class OnboardingBackground extends StatelessWidget {
  const OnboardingBackground({required this.page, super.key});

  final OnboardingPageData page;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          page.backgroundAssetPath,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
        if (page.usesBottomSheet)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  page.overlayColor.withValues(alpha: 0),
                  page.overlayColor,
                ],
              ),
            ),
          ),
      ],
    );
  }
}
