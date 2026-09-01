import 'package:flutter_test/flutter_test.dart';
import 'package:movies_app/app/app.dart';
import 'package:movies_app/core/di/app_dependencies.dart';
import 'package:movies_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app starts on the Splash screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final dependencies = AppDependencies.create();

    await tester.pumpWidget(MoviesApp(dependencies: dependencies));
    await tester.pump();

    expect(find.byKey(SplashScreen.screenKey), findsOneWidget);
  });
}
