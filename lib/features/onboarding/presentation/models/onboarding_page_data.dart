import 'package:flutter/material.dart';
import 'package:movies_app/core/theme/app_colors.dart';

class OnboardingPageData {
  const OnboardingPageData({
    required this.backgroundAssetPath,
    required this.title,
    required this.primaryButtonLabel,
    required this.showBackButton,
    required this.pageIndex,
    required this.usesBottomSheet,
    required this.titleFontSize,
    required this.titleFontWeight,
    this.description,
    this.overlayColor = AppColors.background,
  });

  final String backgroundAssetPath;
  final String title;
  final String? description;
  final String primaryButtonLabel;
  final bool showBackButton;
  final int pageIndex;
  final bool usesBottomSheet;
  final double titleFontSize;
  final FontWeight titleFontWeight;
  final Color overlayColor;

  static const List<OnboardingPageData> pages = [
    OnboardingPageData(
      backgroundAssetPath: 'assets/images/onboarding/onboarding_01.png',
      title: 'Find Your Next Favorite Movie Here',
      description:
          'Get access to a huge library of movies to suit all tastes. You will surely like it.',
      primaryButtonLabel: 'Explore Now',
      showBackButton: false,
      pageIndex: 0,
      usesBottomSheet: false,
      titleFontSize: 36,
      titleFontWeight: FontWeight.w500,
      overlayColor: AppColors.background,
    ),
    OnboardingPageData(
      backgroundAssetPath: 'assets/images/onboarding/onboarding_02.png',
      title: 'Discover Movies',
      description:
          'Explore a vast collection of movies in all qualities and genres. Find your next favorite film with ease.',
      primaryButtonLabel: 'Next',
      showBackButton: false,
      pageIndex: 1,
      usesBottomSheet: true,
      titleFontSize: 24,
      titleFontWeight: FontWeight.w700,
      overlayColor: AppColors.background,
    ),
    OnboardingPageData(
      backgroundAssetPath: 'assets/images/onboarding/onboarding_03.png',
      title: 'Explore All Genres',
      description:
          'Discover movies from every genre, in all available qualities. Find something new and exciting to watch every day.',
      primaryButtonLabel: 'Next',
      showBackButton: true,
      pageIndex: 2,
      usesBottomSheet: true,
      titleFontSize: 24,
      titleFontWeight: FontWeight.w700,
      overlayColor: AppColors.onboardingOverlayRed,
    ),
    OnboardingPageData(
      backgroundAssetPath: 'assets/images/onboarding/onboarding_04.png',
      title: 'Create Watchlists',
      description:
          'Save movies to your watchlist to keep track of what you want to watch next. Enjoy films in various qualities and genres.',
      primaryButtonLabel: 'Next',
      showBackButton: true,
      pageIndex: 3,
      usesBottomSheet: true,
      titleFontSize: 24,
      titleFontWeight: FontWeight.w700,
      overlayColor: AppColors.background,
    ),
    OnboardingPageData(
      backgroundAssetPath: 'assets/images/onboarding/onboarding_05.png',
      title: 'Rate, Review, and Learn',
      description:
          "Share your thoughts on the movies you've watched. Dive deep into film details and help others discover great movies with your reviews.",
      primaryButtonLabel: 'Next',
      showBackButton: true,
      pageIndex: 4,
      usesBottomSheet: true,
      titleFontSize: 24,
      titleFontWeight: FontWeight.w700,
      overlayColor: AppColors.background,
    ),
    OnboardingPageData(
      backgroundAssetPath: 'assets/images/onboarding/onboarding_06.png',
      title: 'Start Watching Now',
      primaryButtonLabel: 'Finish',
      showBackButton: true,
      pageIndex: 5,
      usesBottomSheet: true,
      titleFontSize: 24,
      titleFontWeight: FontWeight.w700,
      overlayColor: AppColors.background,
    ),
  ];
}
