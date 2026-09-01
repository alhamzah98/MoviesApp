import 'package:flutter/material.dart';
import 'package:movies_app/app/app.dart';
import 'package:movies_app/core/di/app_dependencies.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = AppDependencies.create();
  runApp(MoviesApp(dependencies: dependencies));
}
