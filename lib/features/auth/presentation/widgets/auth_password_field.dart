import 'package:flutter/material.dart';
import 'package:movies_app/core/theme/app_colors.dart';
import 'package:movies_app/features/auth/presentation/widgets/auth_text_field.dart';

class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    required this.controller,
    required this.hintText,
    this.textInputAction,
    this.textDirection,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputAction? textInputAction;
  final TextDirection? textDirection;

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AuthTextField.height,
      child: TextField(
        controller: widget.controller,
        obscureText: _obscureText,
        textInputAction: widget.textInputAction,
        textDirection: widget.textDirection,
        style: const TextStyle(
          color: AppColors.onBackground,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.2,
        ),
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(
            color: AppColors.onBackground,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.2,
          ),
          prefixIcon: const Icon(
            Icons.lock_outline,
            color: AppColors.onBackground,
            size: 24,
          ),
          suffixIcon: IconButton(
            onPressed: () => setState(() => _obscureText = !_obscureText),
            icon: Icon(
              _obscureText
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.onBackground,
              size: 24,
            ),
          ),
          filled: true,
          fillColor: AppColors.inputFill,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AuthTextField.borderRadius),
            borderSide: const BorderSide(color: AppColors.inputFill),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AuthTextField.borderRadius),
            borderSide: const BorderSide(color: AppColors.inputFill),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AuthTextField.borderRadius),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
