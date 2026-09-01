import 'package:flutter_test/flutter_test.dart';
import 'package:movies_app/features/library/data/library_error_mapper.dart';

void main() {
  group('LibraryErrorMapper', () {
    test('maps Firestore codes to friendly messages', () {
      expect(
        LibraryErrorMapper.fromCode('permission-denied').message,
        'You do not have permission to update your library.',
      );
      expect(
        LibraryErrorMapper.fromCode('unauthenticated').code,
        'unauthenticated',
      );
      expect(
        LibraryErrorMapper.fromCode('unavailable').message,
        'The library service is temporarily unavailable. Please try again.',
      );
    });
  });
}
