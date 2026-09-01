import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:movies_app/core/theme/app_colors.dart';
import 'package:movies_app/features/browse/presentation/screens/browse_screen.dart';
import 'package:movies_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:movies_app/features/home/presentation/screens/home_screen.dart';
import 'package:movies_app/features/main/presentation/widgets/movies_bottom_navigation_bar.dart';
import 'package:movies_app/features/movies/domain/use_cases/get_movies.dart';
import 'package:movies_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:movies_app/features/search/presentation/screens/search_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({
    required this.getMovies,
    super.key,
  });

  final GetMovies getMovies;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late final HomeCubit _homeCubit;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _homeCubit = HomeCubit(getMovies: widget.getMovies)..load();
  }

  @override
  void dispose() {
    _homeCubit.close();
    super.dispose();
  }

  void _selectTab(int index) {
    final next = index.clamp(0, MoviesBottomNavigationBar.tabCount - 1);
    if (next == _selectedIndex) {
      return;
    }
    setState(() => _selectedIndex = next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('main_shell_screen'),
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                BlocProvider.value(
                  value: _homeCubit,
                  child: HomeScreen(
                    onSeeMore: () => _selectTab(2),
                  ),
                ),
                const SearchScreen(),
                const BrowseScreen(),
                const ProfileScreen(),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: MoviesBottomNavigationBar(
              currentIndex: _selectedIndex,
              onChanged: _selectTab,
            ),
          ),
        ],
      ),
    );
  }
}
