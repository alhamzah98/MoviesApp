import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movies_app/app/app_router.dart';
import 'package:movies_app/core/di/app_dependencies.dart';
import 'package:movies_app/core/theme/app_theme.dart';

class MoviesApp extends StatefulWidget {
  const MoviesApp({
    required this.dependencies,
    this.disposeDependenciesOnUnmount = true,
    super.key,
  });

  final AppDependencies dependencies;
  final bool disposeDependenciesOnUnmount;

  @override
  State<MoviesApp> createState() => _MoviesAppState();
}

class _MoviesAppState extends State<MoviesApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.create(widget.dependencies);
  }

  @override
  void dispose() {
    if (widget.disposeDependenciesOnUnmount) {
      widget.dependencies.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Movies App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}
