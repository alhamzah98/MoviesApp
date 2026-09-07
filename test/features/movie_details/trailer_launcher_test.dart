import 'package:flutter_test/flutter_test.dart';
import 'package:movies_app/features/movie_details/services/trailer_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  group('TrailerLauncher - URI Construction & Validation', () {
    test('buildUri constructs valid HTTPS YouTube watch URI', () {
      const code = 'dQw4w9WgXcQ';
      final uri = TrailerLauncher.buildUri(code);

      expect(uri, isNotNull);
      expect(uri!.scheme, equals('https'));
      expect(uri.host, equals('www.youtube.com'));
      expect(uri.path, equals('/watch'));
      expect(uri.queryParameters, equals({'v': 'dQw4w9WgXcQ'}));
    });

    test('buildUri trims whitespace from video ID', () {
      const code = '   aB12_-xyZ   ';
      final uri = TrailerLauncher.buildUri(code);

      expect(uri, isNotNull);
      expect(uri!.queryParameters['v'], equals('aB12_-xyZ'));
    });

    test('buildUri rejects null, empty, or blank strings', () {
      expect(TrailerLauncher.buildUri(null), isNull);
      expect(TrailerLauncher.buildUri(''), isNull);
      expect(TrailerLauncher.buildUri('    '), isNull);
      expect(TrailerLauncher.hasValidTrailerCode(null), isFalse);
      expect(TrailerLauncher.hasValidTrailerCode(''), isFalse);
    });

    test('buildUri rejects full URLs or arbitrary injected parameters', () {
      expect(TrailerLauncher.buildUri('https://evil.com/video'), isNull);
      expect(TrailerLauncher.buildUri('dQw4w9WgXcQ?extra=injected'), isNull);
      expect(TrailerLauncher.buildUri('<script>alert(1)</script>'), isNull);
      expect(TrailerLauncher.buildUri('id with spaces'), isNull);
    });
  });

  group('TrailerLauncher - Injected Launch Execution', () {
    test('successful launch forwards externalApplication mode and returns true', () async {
      Uri? capturedUri;
      LaunchMode? capturedMode;

      final launcher = TrailerLauncher(
        launcher: (uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          capturedUri = uri;
          capturedMode = mode;
          return true;
        },
      );

      final result = await launcher.launchTrailer('validCode123');

      expect(result, isTrue);
      expect(capturedUri, isNotNull);
      expect(capturedUri!.queryParameters['v'], equals('validCode123'));
      expect(capturedMode, equals(LaunchMode.externalApplication));
    });

    test('returns false when external application launcher returns false', () async {
      final launcher = TrailerLauncher(
        launcher: (uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          return false;
        },
      );

      final result = await launcher.launchTrailer('validCode123');

      expect(result, isFalse);
    });

    test('catches exceptions gracefully and returns false without rethrowing', () async {
      final launcher = TrailerLauncher(
        launcher: (uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          throw Exception('ActivityNotFoundException: No activity found to handle Intent');
        },
      );

      final result = await launcher.launchTrailer('validCode123');

      expect(result, isFalse);
    });

    test('returns false immediately for invalid ID without calling launcher callback', () async {
      var wasCalled = false;

      final launcher = TrailerLauncher(
        launcher: (uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          wasCalled = true;
          return true;
        },
      );

      final result = await launcher.launchTrailer('invalid code with spaces');

      expect(result, isFalse);
      expect(wasCalled, isFalse);
    });
  });
}
