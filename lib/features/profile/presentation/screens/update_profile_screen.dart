import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movies_app/core/auth/auth_coordinator.dart';
import 'package:movies_app/core/constants/route_constants.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/core/theme/app_colors.dart';
import 'package:movies_app/features/auth/domain/auth_validators.dart';
import 'package:movies_app/features/auth/domain/entities/app_user.dart';
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
                const Text(
                  'Choose Avatar',
                  style: TextStyle(
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
    if (_isSubmitting) {
      return;
    }

    if (_currentUser == null) {
      _showMessage('Please sign in to update your profile.');
      return;
    }

    final name = _nameController.text;
    final phone = _phoneController.text;

    try {
      AuthValidators.validateName(name);
      AuthValidators.validatePhoneNumber(phone);
      AuthValidators.validateAvatarId(_selectedAvatarId);
    } on AppException catch (e) {
      _showMessage(e.message);
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
          _showMessage('Profile updated successfully.');
          Navigator.of(context).pop();
        } else {
          _showMessage(
            profileCubit.state.errorMessage ??
                'Failed to update profile. Please try again.',
          );
        }
      } catch (_) {
        if (mounted) {
          _showMessage('Failed to update profile. Please try again.');
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
      return;
    }

    if (widget.onUpdateProfile == null) {
      _showMessage(
        'Profile update integration will be enabled in the upcoming phase.',
      );
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
      _showMessage('Profile updated successfully.');
      Navigator.of(context).pop();
    } on AppException catch (e) {
      if (!mounted) {
        return;
      }
      _showMessage(e.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('Failed to update profile.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
        title: const Text(
          'Update Profile',
          style: TextStyle(
            color: AppColors.onBackground,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: user == null ? _buildUnavailableState() : _buildFormState(),
      ),
    );
  }

  Widget _buildUnavailableState() {
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
            const Text(
              'Profile Unavailable',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.onBackground,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please sign in to view and update your profile.',
              textAlign: TextAlign.center,
              style: TextStyle(
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
                label: 'Sign In',
                onPressed: () => context.push(RouteConstants.login),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormState() {
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
            child: const Text(
              'Change Avatar',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
          AuthTextField(
            controller: _nameController,
            hintText: 'Name',
            prefixIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _phoneController,
            hintText: 'Phone Number',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.push(RouteConstants.forgotPassword),
              icon: const Icon(
                Icons.lock_reset_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              label: const Text(
                'Reset Password',
                style: TextStyle(
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
              label: 'Update Data',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _handleUpdate,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: null,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error.withValues(alpha: 0.4),
                size: 20,
              ),
              label: Text(
                'Delete Account (Unavailable)',
                style: TextStyle(
                  color: AppColors.error.withValues(alpha: 0.4),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Account deletion is currently unavailable pending Watch List and History cleanup coordination.',
            textAlign: TextAlign.center,
            style: TextStyle(
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
