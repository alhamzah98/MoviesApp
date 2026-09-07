import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:movies_app/core/localization/app_localizations.dart';
import 'package:movies_app/core/localization/locale_cubit.dart';
import 'package:movies_app/core/theme/app_colors.dart';

/// Compact, accessible language selector widget designed for Login and Register screens.
///
/// Matches the dimensions of the original design asset (92x38) while providing
/// interactive switching between English ('en') and Arabic ('ar').
class AuthLanguageSwitch extends StatelessWidget {
  const AuthLanguageSwitch({super.key});

  Future<void> _selectLanguage(BuildContext context, String code) async {
    final cubit = context.read<LocaleCubit?>() ??
        (context.findAncestorStateOfType<State>()?.context.read<LocaleCubit?>());
    if (cubit == null) return;

    final success = await cubit.setLocale(code);
    if (!success && context.mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.languageSaveFailed),
          backgroundColor: AppColors.inputFill,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Locale activeLocale = const Locale('en');
    try {
      final cubit = context.watch<LocaleCubit?>();
      if (cubit != null) {
        activeLocale = cubit.state;
      }
    } catch (_) {
      // Fallback to English if no cubit in context (e.g. isolated widget tests)
    }

    final isArabic = activeLocale.languageCode == 'ar';

    return Container(
      width: 92,
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        textDirection: TextDirection.ltr, // Keep English on left, Arabic on right
        children: [
          Expanded(
            child: Semantics(
              label: 'English language',
              selected: !isArabic,
              button: true,
              child: GestureDetector(
                onTap: () => _selectLanguage(context, 'en'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: !isArabic ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'EN',
                    style: TextStyle(
                      color: !isArabic
                          ? AppColors.onPrimary
                          : AppColors.onBackgroundSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Semantics(
              label: 'اللغة العربية',
              selected: isArabic,
              button: true,
              child: GestureDetector(
                onTap: () => _selectLanguage(context, 'ar'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: isArabic ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'AR',
                    style: TextStyle(
                      color: isArabic
                          ? AppColors.onPrimary
                          : AppColors.onBackgroundSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

