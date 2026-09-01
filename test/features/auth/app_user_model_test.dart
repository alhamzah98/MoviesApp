import 'package:flutter_test/flutter_test.dart';
import 'package:movies_app/features/auth/data/models/app_user_model.dart';

void main() {
  group('AppUserModel.fromMap', () {
    test('parses a complete profile map', () {
      final model = AppUserModel.fromMap({
        'uid': 'user-1',
        'name': 'John Safwat',
        'email': 'john@example.com',
        'phoneNumber': '01200000000',
        'photoUrl': 'https://example.com/photo.jpg',
        'avatarId': 'avatar_01',
        'isEmailVerified': true,
        'createdAt': '2026-01-01T10:00:00.000Z',
        'updatedAt': '2026-01-02T10:00:00.000Z',
        'lastLoginAt': '2026-01-03T10:00:00.000Z',
      });

      final entity = model.toEntity();

      expect(entity.uid, 'user-1');
      expect(entity.name, 'John Safwat');
      expect(entity.email, 'john@example.com');
      expect(entity.phoneNumber, '01200000000');
      expect(entity.photoUrl, 'https://example.com/photo.jpg');
      expect(entity.avatarId, 'avatar_01');
      expect(entity.isEmailVerified, isTrue);
      expect(entity.createdAt, DateTime.parse('2026-01-01T10:00:00.000Z'));
      expect(entity.updatedAt, DateTime.parse('2026-01-02T10:00:00.000Z'));
      expect(model.lastLoginAt, DateTime.parse('2026-01-03T10:00:00.000Z'));
    });

    test('uses safe defaults for missing optional fields', () {
      final model = AppUserModel.fromMap({
        'uid': 'user-2',
        'email': 'jane@example.com',
      });

      final entity = model.toEntity();

      expect(entity.uid, 'user-2');
      expect(entity.email, 'jane@example.com');
      expect(entity.name, isNull);
      expect(entity.phoneNumber, isNull);
      expect(entity.photoUrl, isNull);
      expect(entity.avatarId, isNull);
      expect(entity.isEmailVerified, isFalse);
      expect(entity.createdAt, isNull);
      expect(entity.updatedAt, isNull);
      expect(model.lastLoginAt, isNull);
    });

    test('parses millisecond timestamps safely', () {
      final millis = DateTime.utc(2026, 3, 1).millisecondsSinceEpoch;
      final model = AppUserModel.fromMap({
        'uid': 'user-3',
        'email': 'time@example.com',
        'createdAt': millis,
        'updatedAt': millis.toDouble(),
      });

      expect(model.createdAt, DateTime.fromMillisecondsSinceEpoch(millis));
      expect(model.updatedAt, DateTime.fromMillisecondsSinceEpoch(millis));
    });
  });
}
