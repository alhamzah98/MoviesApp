import 'package:flutter_test/flutter_test.dart';
import 'package:movies_app/features/library/data/models/library_movie_model.dart';
import 'package:movies_app/features/library/domain/entities/library_movie.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';

void main() {
  group('LibraryMovieModel.fromMap', () {
    test('parses a complete library document', () {
      final model = LibraryMovieModel.fromMap({
        'movieId': 42,
        'title': 'Dune',
        'year': 2021,
        'rating': 8.4,
        'genres': ['Sci-Fi', 'Adventure'],
        'summary': 'A desert planet.',
        'mediumCoverImage': 'https://example.com/medium.jpg',
        'largeCoverImage': 'https://example.com/large.jpg',
        'backgroundImage': 'https://example.com/background.jpg',
        'addedAt': '2026-01-01T10:00:00.000Z',
        'lastViewedAt': '2026-01-02T10:00:00.000Z',
        'viewCount': 3,
      });

      final entity = model.toEntity();

      expect(entity.movieId, 42);
      expect(entity.title, 'Dune');
      expect(entity.year, 2021);
      expect(entity.rating, 8.4);
      expect(entity.genres, ['Sci-Fi', 'Adventure']);
      expect(entity.summary, 'A desert planet.');
      expect(entity.mediumCoverImage, 'https://example.com/medium.jpg');
      expect(entity.largeCoverImage, 'https://example.com/large.jpg');
      expect(entity.backgroundImage, 'https://example.com/background.jpg');
      expect(entity.addedAt, DateTime.parse('2026-01-01T10:00:00.000Z'));
      expect(entity.lastViewedAt, DateTime.parse('2026-01-02T10:00:00.000Z'));
      expect(entity.viewCount, 3);
    });

    test('uses safe defaults for missing optional fields', () {
      final model = LibraryMovieModel.fromMap({
        'movieId': 7,
        'title': 'Untitled',
      });

      final entity = model.toEntity();

      expect(entity.movieId, 7);
      expect(entity.title, 'Untitled');
      expect(entity.year, 0);
      expect(entity.rating, 0);
      expect(entity.genres, isEmpty);
      expect(entity.summary, isEmpty);
      expect(entity.mediumCoverImage, isNull);
      expect(entity.largeCoverImage, isNull);
      expect(entity.backgroundImage, isNull);
      expect(entity.addedAt, isNull);
      expect(entity.lastViewedAt, isNull);
      expect(entity.viewCount, 0);
    });

    test('converts integer, double, and string ratings', () {
      expect(LibraryMovieModel.fromMap({'movieId': 1, 'title': 'A', 'rating': 8}).rating, 8);
      expect(
        LibraryMovieModel.fromMap({'movieId': 1, 'title': 'A', 'rating': 7.5}).rating,
        7.5,
      );
      expect(
        LibraryMovieModel.fromMap({'movieId': 1, 'title': 'A', 'rating': '6.25'}).rating,
        6.25,
      );
    });

    test('ignores invalid genre elements', () {
      final model = LibraryMovieModel.fromMap({
        'movieId': 1,
        'title': 'A',
        'genres': ['Action', 12, '', null, 'Drama', true],
      });

      expect(model.genres, ['Action', 'Drama']);
    });

    test('parses millisecond timestamps safely', () {
      final millis = DateTime.utc(2026, 3, 1).millisecondsSinceEpoch;
      final model = LibraryMovieModel.fromMap({
        'movieId': 1,
        'title': 'A',
        'addedAt': millis,
        'lastViewedAt': millis.toDouble(),
      });

      expect(model.addedAt, DateTime.fromMillisecondsSinceEpoch(millis));
      expect(model.lastViewedAt, DateTime.fromMillisecondsSinceEpoch(millis));
    });

    test('falls back to the document id when movieId is missing', () {
      final model = LibraryMovieModel.fromMap(
        {'title': 'A'},
        documentId: '99',
      );

      expect(model.movieId, 99);
    });
  });

  group('LibraryMovieModel conversions and write maps', () {
    test('converts from the Movies Movie entity', () {
      const movie = Movie(
        id: 15,
        title: 'Inception',
        year: 2010,
        rating: 8.8,
        genres: ['Action', 'Sci-Fi'],
        summary: 'A dream within a dream.',
        descriptionFull: 'Ignored when summary exists.',
        youtubeTrailerCode: 'abc',
        likeCount: 100,
        mediumCoverImage: 'medium.jpg',
        largeCoverImage: 'large.jpg',
        backgroundImage: 'background.jpg',
      );

      final model = LibraryMovieModel.fromMovie(movie);
      final entity = LibraryMovie.fromMovie(movie);

      expect(model.movieId, 15);
      expect(model.title, 'Inception');
      expect(model.year, 2010);
      expect(model.rating, 8.8);
      expect(model.genres, ['Action', 'Sci-Fi']);
      expect(model.summary, 'A dream within a dream.');
      expect(model.mediumCoverImage, 'medium.jpg');
      expect(model.largeCoverImage, 'large.jpg');
      expect(model.backgroundImage, 'background.jpg');
      expect(entity.movieId, 15);
      expect(entity.viewCount, 0);
      expect(entity.addedAt, isNull);
      expect(entity.lastViewedAt, isNull);
    });

    test('watchlist write map excludes history-only fields', () {
      final map = LibraryMovieModel.fromEntity(
        const LibraryMovie(
          movieId: 1,
          title: 'Dune',
          lastViewedAt: null,
          viewCount: 4,
        ),
      ).toWatchlistWriteMap();

      expect(map.containsKey('lastViewedAt'), isFalse);
      expect(map.containsKey('viewCount'), isFalse);
      expect(map['movieId'], 1);
      expect(map['title'], 'Dune');
    });

    test('history write map excludes watchlist-only fields', () {
      final addedAt = DateTime.utc(2026, 1, 1);
      final map = LibraryMovieModel.fromEntity(
        LibraryMovie(
          movieId: 1,
          title: 'Dune',
          addedAt: addedAt,
        ),
      ).toHistoryWriteMap();

      expect(map.containsKey('addedAt'), isFalse);
      expect(map.containsKey('updatedAt'), isFalse);
      expect(map['movieId'], 1);
      expect(map['title'], 'Dune');
    });
  });
}
