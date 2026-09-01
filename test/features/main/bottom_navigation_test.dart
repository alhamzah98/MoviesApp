import 'package:flutter_test/flutter_test.dart';
import 'package:movies_app/core/constants/route_constants.dart';
import 'package:movies_app/features/main/presentation/widgets/movies_bottom_navigation_bar.dart';

void main() {
  group('MoviesBottomNavigationBar', () {
    test('keeps the required tab order and count', () {
      expect(MoviesBottomNavigationBar.tabCount, 4);
      expect(MoviesBottomNavigationBar.tabKeys, [
        'home_tab',
        'search_tab',
        'browse_tab',
        'profile_tab',
      ]);
    });

    test('clamps selected indexes into a valid range', () {
      expect((-1).clamp(0, MoviesBottomNavigationBar.tabCount - 1), 0);
      expect(0.clamp(0, MoviesBottomNavigationBar.tabCount - 1), 0);
      expect(2.clamp(0, MoviesBottomNavigationBar.tabCount - 1), 2);
      expect(99.clamp(0, MoviesBottomNavigationBar.tabCount - 1), 3);
    });
  });

  group('RouteConstants.movieDetailsPath', () {
    test('builds a movie details path from a real movie id', () {
      expect(RouteConstants.movieDetailsPath(15), '/movie/15');
      expect(RouteConstants.movieDetailsPath(1), '/movie/1');
    });
  });
}
