import 'package:flutter/material.dart';
import 'package:movies_app/features/home/presentation/widgets/home_movie_card.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';

class HomeFeaturedCarousel extends StatefulWidget {
  const HomeFeaturedCarousel({
    required this.movies,
    required this.onMovieTap,
    required this.onPageChanged,
    this.height = 360,
    super.key,
  });

  final List<Movie> movies;
  final ValueChanged<Movie> onMovieTap;
  final ValueChanged<int> onPageChanged;
  final double height;

  @override
  State<HomeFeaturedCarousel> createState() => _HomeFeaturedCarouselState();
}

class _HomeFeaturedCarouselState extends State<HomeFeaturedCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.58);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.movies.isEmpty) {
      return SizedBox(height: widget.height);
    }

    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.movies.length,
        onPageChanged: (index) {
          setState(() => _currentPage = index);
          widget.onPageChanged(index);
        },
        itemBuilder: (context, index) {
          final movie = widget.movies[index];
          final isCenter = index == _currentPage;

          return AnimatedScale(
            scale: isCenter ? 1 : 0.82,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: Center(
              child: HomeMovieCard(
                movie: movie,
                width: isCenter ? 234 : 184,
                height: isCenter ? 351 : 277,
                borderRadius: 20,
                showShadow: isCenter,
                onTap: () => widget.onMovieTap(movie),
              ),
            ),
          );
        },
      ),
    );
  }
}
