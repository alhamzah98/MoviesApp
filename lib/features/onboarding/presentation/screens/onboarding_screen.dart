import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movies_app/core/constants/route_constants.dart';
import 'package:movies_app/core/storage/app_preferences.dart';
import 'package:movies_app/core/theme/app_colors.dart';
import 'package:movies_app/features/onboarding/presentation/models/onboarding_page_data.dart';
import 'package:movies_app/features/onboarding/presentation/widgets/onboarding_background.dart';
import 'package:movies_app/features/onboarding/presentation/widgets/onboarding_content_panel.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    required this.preferences,
    super.key,
  });

  final AppPreferences preferences;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _isCompletingOnboarding = false;

  static const _pages = OnboardingPageData.pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToNextPage() async {
    if (_currentPage >= _pages.length - 1) {
      await _completeOnboarding();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToPreviousPage() {
    if (_currentPage <= 0) {
      return;
    }

    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _completeOnboarding() async {
    if (_isCompletingOnboarding) {
      return;
    }

    setState(() => _isCompletingOnboarding = true);

    try {
      await widget.preferences.setOnboardingCompleted();
      if (!mounted) {
        return;
      }
      context.go(RouteConstants.login);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _isCompletingOnboarding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save onboarding progress. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageView.builder(
        controller: _pageController,
        itemCount: _pages.length,
        onPageChanged: (index) {
          setState(() => _currentPage = index);
        },
        itemBuilder: (context, index) {
          final page = _pages[index];
          return Stack(
            fit: StackFit.expand,
            children: [
              OnboardingBackground(page: page),
              OnboardingContentPanel(
                page: page,
                onPrimaryPressed: _isCompletingOnboarding ? null : _goToNextPage,
                onBackPressed: _goToPreviousPage,
              ),
            ],
          );
        },
      ),
    );
  }
}
