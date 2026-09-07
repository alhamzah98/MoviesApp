import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movies_app/core/auth/auth_coordinator.dart';
import 'package:movies_app/core/constants/route_constants.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/core/localization/app_localizations.dart';
import 'package:movies_app/core/theme/app_colors.dart';
import 'package:movies_app/features/auth/domain/auth_validators.dart';
import 'package:movies_app/features/auth/domain/entities/app_user.dart';
import 'package:movies_app/features/auth/domain/entities/delete_account_result.dart';
import 'package:movies_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:movies_app/features/profile/presentation/constants/avatar_constants.dart';
import 'package:movies_app/shared/widgets/movies_primary_button.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({
    this.user,
    this.coordinator,
    this.onUpdateProfile,
    this.onDeleteAccount,
    super.key,
  });

  final AppUser? user;
  final AuthCoordinator? coordinator;
  final Future<void> Function({
    required String name,
    required String phoneNumber,
    required String avatarId,
  })? onUpdateProfile;
  final Future<void> Function()? onDeleteAccount;

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late String _selectedAvatarId;
  String? _activeUid;
  bool _isSubmitting = false;
  bool _isDeleting = false;
  bool _hasIncompleteDeletion = false;

  AppUser? get _currentUser {
    if (widget.coordinator != null) {
      final coordinatorUser = widget.coordinator!.currentUser;
      if (coordinatorUser == null) {
        return null;
      }
      if (widget.user != null && widget.user!.uid == coordinatorUser.uid) {
        return widget.user;
      }
      return coordinatorUser;
    }
    return widget.user;
  }

  @override
  void initState() {
    super.initState();
    final user = _currentUser;
    _activeUid = user?.uid;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController =
        TextEditingController(text: user?.phoneNumber ?? '');
    _selectedAvatarId = user?.avatarId ?? ProfileAvatars.defaultAvatarId;
  }

  @override
  void didUpdateWidget(UpdateProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final user = _currentUser;
    if (user?.uid != _activeUid) {
      _activeUid = user?.uid;
      _nameController.text = user?.name ?? '';
      _phoneController.text = user?.phoneNumber ?? '';
      _selectedAvatarId = user?.avatarId ?? ProfileAvatars.defaultAvatarId;
      _hasIncompleteDeletion = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(RouteConstants.home);
    }
  }

  void _openAvatarBottomSheet() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1F1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.chooseAvatar,
                  style: const TextStyle(
                    color: AppColors.onBackground,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ProfileAvatars.allIds.map((avatarId) {
                    final isSelected = avatarId == _selectedAvatarId;
                    final assetPath = ProfileAvatars.assetPathFor(avatarId);

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedAvatarId = avatarId);
                        Navigator.of(modalContext).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: SizedBox(
                            width: 72,
                            height: 72,
                            child: Image.asset(assetPath, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    );
                  }).toList(growable: false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleUpdate() async {
    final l10n = AppLocalizations.of(context);

    if (_isSubmitting) {
      return;
    }

    if (_currentUser == null) {
      _showMessage(l10n.profileUnavailableSubtitle);
      return;
    }

    final name = _nameController.text;
    final phone = _phoneController.text;

    try {
      AuthValidators.validateName(name);
      AuthValidators.validatePhoneNumber(phone);
      AuthValidators.validateAvatarId(_selectedAvatarId);
    } on AppException catch (e) {
      _showMessage(l10n.translateError(errorCode: e.code, fallback: e.message));
      return;
    }

    final profileCubit = widget.coordinator?.profileCubit;
    if (profileCubit != null) {
      setState(() => _isSubmitting = true);
      try {
        final updatedUser = await profileCubit.updateProfile(
          name: AuthValidators.normalizeName(name),
          phoneNumber: AuthValidators.normalizePhone(phone),
          avatarId: _selectedAvatarId.trim(),
        );

        if (!mounted) return;

        if (updatedUser != null) {
          widget.coordinator?.updateSharedUser(updatedUser);
          _showMessage(l10n.profileUpdatedSuccess);
          Navigator.of(context).pop();
        } else {
          _showMessage(
            profileCubit.state.errorMessage ?? l10n.profileUpdateFailed,
          );
        }
      } catch (_) {
        if (mounted) {
          _showMessage(l10n.profileUpdateFailed);
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
      return;
    }

    if (widget.onUpdateProfile == null) {
      _showMessage(l10n.profileUpdateFailed);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onUpdateProfile!(
        name: AuthValidators.normalizeName(name),
        phoneNumber: AuthValidators.normalizePhone(phone),
        avatarId: _selectedAvatarId.trim(),
      );
      if (!mounted) {
        return;
      }
      _showMessage(l10n.profileUpdatedSuccess);
      Navigator.of(context).pop();
    } on AppException catch (e) {
      if (!mounted) {
        return;
      }
      _showMessage(l10n.translateError(errorCode: e.code, fallback: e.message));
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage(l10n.profileUpdateFailed);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final l10n = AppLocalizations.of(context);

    if (_isSubmitting || _isDeleting) {
      return;
    }

    final user = _currentUser;
    if (user == null) {
      _showMessage(l10n.profileUnavailableSubtitle);
      return;
    }

    // Step 1: Explicit Confirmation Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1F1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            l10n.deleteAccountConfirmTitle,
            style: const TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            l10n.deleteAccountConfirmMessage,
            style: const TextStyle(
              color: AppColors.onBackground,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                l10n.cancel,
                style: const TextStyle(color: AppColors.onBackgroundSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.deleteAccountConfirmAction),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    // Step 2: Determine Reauthentication Requirements
    String? password;
    bool useGoogle = false;

    if (user.hasPasswordProvider || (user.providerIds.isEmpty && user.email.isNotEmpty)) {
      final inputPassword = await _showPasswordReauthDialog(l10n);
      if (inputPassword == null || inputPassword.isEmpty) {
        return;
      }
      password = inputPassword;
    } else if (user.hasGoogleProvider) {
      useGoogle = true;
    } else {
      _showMessage(l10n.unsupportedReauthProvider);
      return;
    }

    // Step 3: Trigger Account Deletion
    setState(() => _isDeleting = true);

    try {
      DeleteAccountResult? result;
      final profileCubit = widget.coordinator?.profileCubit;

      if (profileCubit != null) {
        result = await profileCubit.deleteAccount(
          password: password,
          useGoogle: useGoogle,
        );
      } else if (widget.onDeleteAccount != null) {
        await widget.onDeleteAccount!();
        result = DeleteAccountResult.success;
      }

      if (!mounted) {
        return;
      }

      if (result != null) {
        if (result.isSuccess) {
          if (mounted) {
            setState(() => _hasIncompleteDeletion = false);
          }
          _showMessage(l10n.accountDeletedSuccess);
        } else if (result.isCancelled) {
          // Cancelled cleanly; preserve incomplete deletion status if earlier attempt failed
        } else if (result.isPartialFailure) {
          if (mounted) {
            setState(() => _hasIncompleteDeletion = true);
          }
          await _showPartialFailureDialog(
            l10n,
            l10n.accountDeletionPartialFailure,
          );
        } else {
          _showMessage(result.errorMessage ?? l10n.accountDeletionFailed);
        }
      }
    } catch (_) {
      if (mounted) {
        _showMessage(l10n.accountDeletionFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<String?> _showPasswordReauthDialog(AppLocalizations l10n) async {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    try {
      final entered = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (ctx, setDialogState) {
              return AlertDialog(
                backgroundColor: const Color(0xFF1E1F1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  l10n.reauthenticateTitle,
                  style: const TextStyle(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.reauthenticatePasswordPrompt,
                      style: const TextStyle(
                        color: AppColors.onBackgroundSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      autofocus: true,
                      style: const TextStyle(color: AppColors.onBackground),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.inputFill,
                        hintText: l10n.password,
                        hintStyle: const TextStyle(
                          color: AppColors.onBackgroundSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.onBackgroundSecondary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: AppColors.onBackgroundSecondary,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(null),
                    child: Text(
                      l10n.cancel,
                      style: const TextStyle(
                        color: AppColors.onBackgroundSecondary,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      final text = passwordController.text;
                      if (text.isNotEmpty) {
                        Navigator.of(dialogContext).pop(text);
                      }
                    },
                    child: Text(l10n.deleteAccount),
                  ),
                ],
              );
            },
          );
        },
      );
      return entered;
    } finally {
      passwordController.clear();
      passwordController.dispose();
    }
  }

  Future<void> _showPartialFailureDialog(
    AppLocalizations l10n,
    String message,
  ) async {
    final shouldRetry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1F1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            l10n.accountDeletionPartialFailureTitle,
            style: const TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: AppColors.onBackground,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                l10n.cancel,
                style: const TextStyle(color: AppColors.onBackgroundSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.tryAgain),
            ),
          ],
        );
      },
    );

    if (shouldRetry == true) {
      _handleDeleteAccount();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.inputFill,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = _currentUser;

    return Scaffold(
      key: const Key('update_profile_screen'),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.onBackground,
            size: 20,
          ),
          onPressed: _handleBack,
        ),
        title: Text(
          l10n.updateProfile,
          style: const TextStyle(
            color: AppColors.onBackground,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: user == null
            ? _buildUnavailableState(l10n)
            : _buildFormState(l10n),
      ),
    );
  }

  Widget _buildUnavailableState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_circle_outlined,
              size: 72,
              color: AppColors.onBackgroundSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.profileUnavailableTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.onBackground,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.profileUnavailableSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.onBackgroundSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              height: 48,
              child: MoviesPrimaryButton(
                label: l10n.signIn,
                onPressed: () => context.push(RouteConstants.login),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormState(AppLocalizations l10n) {
    final avatarPath = ProfileAvatars.assetPathFor(_selectedAvatarId);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _openAvatarBottomSheet,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: Image.asset(avatarPath, fit: BoxFit.cover),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: AppColors.onPrimary,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _openAvatarBottomSheet,
            child: Text(
              l10n.changeAvatar,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
          AuthTextField(
            controller: _nameController,
            hintText: l10n.name,
            prefixIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _phoneController,
            hintText: l10n.phoneNumber,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => context.push(RouteConstants.forgotPassword),
              icon: const Icon(
                Icons.lock_reset_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              label: Text(
                l10n.resetPassword,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: MoviesPrimaryButton(
              label: l10n.updateData,
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _handleUpdate,
            ),
          ),
          if (_hasIncompleteDeletion ||
              (widget.coordinator?.profileCubit?.state.isPartialFailure ??
                  false)) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.accountDeletionPartialFailureTitle,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.accountDeletionPartialFailure,
                    style: const TextStyle(
                      color: AppColors.onBackground,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: (_isSubmitting ||
                      _isDeleting ||
                      (widget.coordinator != null &&
                          !widget.coordinator!.isAvailable))
                  ? null
                  : _handleDeleteAccount,
              icon: _isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.error),
                      ),
                    )
                  : const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
              label: Text(
                _isDeleting
                    ? l10n.deletingAccount
                    : ((_hasIncompleteDeletion ||
                            (widget.coordinator?.profileCubit?.state
                                    .isPartialFailure ??
                                false))
                        ? l10n.retryAccountDeletion
                        : l10n.deleteAccount),
                style: TextStyle(
                  color: (_isSubmitting || _isDeleting)
                      ? AppColors.error.withValues(alpha: 0.4)
                      : AppColors.error,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: (_isSubmitting || _isDeleting)
                      ? AppColors.error.withValues(alpha: 0.4)
                      : AppColors.error,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.deleteAccountWarning,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.onBackgroundSecondary,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
