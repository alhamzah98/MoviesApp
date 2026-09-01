import 'package:flutter_test/flutter_test.dart';
import 'package:movies_app/features/movies/data/models/movie_model.dart';
import 'package:movies_app/features/movies/data/models/movie_page_model.dart';
import 'package:movies_app/features/movies/domain/entities/movies_query.dart';

void main() {
  group('MovieModel.fromJson', () {
    test('parses a complete movie payload', () {
      final model = MovieModel.fromJson({
        'id': 10,
        'title': 'Inception',
        'title_english': 'Inception',
        'title_long': 'Inception (2010)',
        'year': 2010,
        'rating': 8.8,
        'runtime': 148,
        'genres': ['Action', 'Sci-Fi'],
        'summary': 'A thief steals secrets.',
        'description_full': 'Full description',
        'yt_trailer_code': 'YoHD9XEInc0',
        'language': 'en',
        'mpa_rating': 'PG-13',
        'like_count': 100,
        'download_count': 200,
        'background_image': 'https://example.com/bg.jpg',
        'background_image_original': 'https://example.com/bg-original.jpg',
        'small_cover_image': 'https://example.com/small.jpg',
        'medium_cover_image': 'https://example.com/medium.jpg',
        'large_cover_image': 'https://example.com/large.jpg',
        'cast': [
          {
            'name': 'Leonardo DiCaprio',
            'character_name': 'Cobb',
            'url_small_image': 'https://example.com/cast.jpg',
            'imdb_code': 'nm0000138',
          },
        ],
      });

      final entity = model.toEntity();

      expect(entity.id, 10);
      expect(entity.title, 'Inception');
      expect(entity.titleEnglish, 'Inception');
      expect(entity.year, 2010);
      expect(entity.rating, 8.8);
      expect(entity.genres, ['Action', 'Sci-Fi']);
      expect(entity.youtubeTrailerCode, 'YoHD9XEInc0');
      expect(entity.largeCoverImage, 'https://example.com/large.jpg');
      expect(entity.cast, hasLength(1));
      expect(entity.cast.first.name, 'Leonardo DiCaprio');
      expect(entity.cast.first.characterName, 'Cobb');
    });

    test('uses safe defaults for missing optional fields', () {
      final model = MovieModel.fromJson({
        'id': 11,
        'title': 'Arrival',
      });

      final entity = model.toEntity();

      expect(entity.id, 11);
      expect(entity.title, 'Arrival');
      expect(entity.titleEnglish, isEmpty);
      expect(entity.summary, isEmpty);
      expect(entity.genres, isEmpty);
      expect(entity.cast, isEmpty);
      expect(entity.rating, 0);
      expect(entity.year, 0);
      expect(entity.youtubeTrailerCode, isNull);
      expect(entity.largeCoverImage, isNull);
    });

    test('converts integer rating values to double', () {
      final model = MovieModel.fromJson({
        'id': 12,
        'title': 'Interstellar',
        'rating': 8,
      });

      expect(model.rating, 8.0);
      expect(model.toEntity().rating, 8.0);
    });

    test('ignores invalid list elements safely', () {
      final model = MovieModel.fromJson({
        'id': 13,
        'title': 'Dune',
        'genres': ['Action', null, 42, 'Drama', ''],
        'cast': [
          {
            'name': 'Timothee Chalamet',
            'character_name': 'Paul',
          },
          'invalid-cast',
          {
            'character_name': 'Missing name',
          },
          null,
        ],
      });

      expect(model.genres, ['Action', 'Drama']);
      expect(model.cast, hasLength(1));
      expect(model.cast.first.name, 'Timothee Chalamet');
    });
  });

  group('MoviePageModel.fromJson', () {
    test('parses pagination fields and movie list', () {
      final page = MoviePageModel.fromJson({
        'movie_count': 40,
        'limit': 20,
        'page_number': 2,
        'movies': [
          {'id': 1, 'title': 'Movie One'},
          {'id': 2, 'title': 'Movie Two'},
        ],
      }).toEntity();

      expect(page.movieCount, 40);
      expect(page.limit, 20);
      expect(page.pageNumber, 2);
      expect(page.movies, hasLength(2));
      expect(page.hasReachedEnd, isFalse);
    });

    test('handles empty or missing movies list', () {
      final emptyPage = MoviePageModel.fromJson({
        'movie_count': 0,
        'limit': 20,
        'page_number': 1,
      }).toEntity();

      expect(emptyPage.movies, isEmpty);
      expect(emptyPage.movieCount, 0);
      expect(emptyPage.hasReachedEnd, isTrue);

      final missingMoviesPage = MoviePageModel.fromJson({
        'movie_count': 5,
        'limit': 20,
        'page_number': 1,
        'movies': null,
      }).toEntity();

      expect(missingMoviesPage.movies, isEmpty);
    });
  });

  group('MoviesQuery', () {
    test('excludes null optional parameters from query map', () {
      const query = MoviesQuery(
        limit: 20,
        page: 1,
        queryTerm: 'batman',
        genre: null,
        quality: null,
      );

      final parameters = query.toQueryParameters();

      expect(parameters['limit'], 20);
      expect(parameters['page'], 1);
      expect(parameters['query_term'], 'batman');
      expect(parameters.containsKey('genre'), isFalse);
      expect(parameters.containsKey('quality'), isFalse);
      expect(parameters.containsKey('minimum_rating'), isFalse);
      expect(parameters.containsKey('sort_by'), isFalse);
      expect(parameters.containsKey('order_by'), isFalse);
      expect(parameters.containsKey('with_rt_ratings'), isFalse);
    });

    test('copyWith preserves unchanged values', () {
      const original = MoviesQuery(
        limit: 20,
        page: 1,
        queryTerm: 'matrix',
        genre: 'Action',
        sortBy: 'rating',
        orderBy: 'desc',
        withRtRatings: true,
      );

      final updated = original.copyWith(page: 3, queryTerm: 'matrix reloaded');

      expect(updated.limit, 20);
      expect(updated.page, 3);
      expect(updated.queryTerm, 'matrix reloaded');
      expect(updated.genre, 'Action');
      expect(updated.sortBy, 'rating');
      expect(updated.orderBy, 'desc');
      expect(updated.withRtRatings, isTrue);
    });
  });
}
