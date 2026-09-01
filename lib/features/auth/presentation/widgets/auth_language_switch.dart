import 'package:flutter/material.dart';

class AuthLanguageSwitch extends StatelessWidget {
  const AuthLanguageSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/auth/language_switch.png',
      width: 91,
      height: 38,
      fit: BoxFit.contain,
    );
  }
}
