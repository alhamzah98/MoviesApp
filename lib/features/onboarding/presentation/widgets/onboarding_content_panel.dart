import 'package:flutter/material.dart';
import 'package:movies_app/core/theme/app_colors.dart';
import 'package:movies_app/features/onboarding/presentation/models/onboarding_page_data.dart';
import 'package:movies_app/shared/widgets/movies_outlined_button.dart';
import 'package:movies_app/shared/widgets/movies_primary_button.dart';

class OnboardingContentPanel extends StatelessWidget {
  const OnboardingContentPanel({
    required this.page,
    required this.onPrimaryPressed,
    required this.onBackPressed,
    super.key,
  });

  final OnboardingPageData page;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback onBackPressed;

  static const double horizontalPadding = 16;
  static const double bottomSheetRadius = 40;

  @override
  Widget build(BuildContext context) {
    final content = _OnboardingCopyAndActions(
      page: page,
      onPrimaryPressed: onPrimaryPressed,
      onBackPressed: onBackPressed,
    );

    if (!page.usesBottomSheet) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              24,
            ),
            child: content,
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(bottomSheetRadius),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              horizontalPadding,
              27,
              horizontalPadding,
              24,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _OnboardingCopyAndActions extends StatelessWidget {
  const _OnboardingCopyAndActions({
    required this.page,
    required this.onPrimaryPressed,
    required this.onBackPressed,
  });

  final OnboardingPageData page;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    final description = page.description;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          page.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.onBackground,
            fontSize: page.titleFontSize,
            fontWeight: page.titleFontWeight,
            height: page.usesBottomSheet ? null : 1.15,
          ),
        ),
        if (description != null) ...[
          SizedBox(height: page.usesBottomSheet ? 8 : 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: page.usesBottomSheet
                  ? AppColors.onBackground
                  : AppColors.onBackgroundSecondary,
              fontSize: 20,
              fontWeight: FontWeight.w400,
              height: 32 / 20,
            ),
          ),
        ],
        SizedBox(height: page.usesBottomSheet ? 16 : 24),
        MoviesPrimaryButton(
          label: page.primaryButtonLabel,
          onPressed: onPrimaryPressed,
        ),
        if (page.showBackButton) ...[
          const SizedBox(height: 16),
          MoviesOutlinedButton(
            label: 'Back',
            onPressed: onBackPressed,
          ),
        ],
      ],
    );
  }
}
