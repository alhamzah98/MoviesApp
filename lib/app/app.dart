import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movies_app/app/app_router.dart';
import 'package:movies_app/core/di/app_dependencies.dart';
import 'package:movies_app/core/theme/app_theme.dart';

class MoviesApp extends StatelessWidget {
  MoviesApp({
    required AppDependencies dependencies,
    super.key,
  }) : router = AppRouter.create(dependencies);

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Movies App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
