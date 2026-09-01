import 'package:flutter/material.dart';

class MovieDetailsScreen extends StatelessWidget {
  const MovieDetailsScreen({
    super.key,
    this.movieId,
  });

  final int? movieId;

  @override
  Widget build(BuildContext context) {
    final detailsText = movieId == null
        ? 'Movie Details\nInvalid movie ID'
        : 'Movie Details\nID: $movieId';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Details'),
      ),
      body: Center(
        child: Text(
          detailsText,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
