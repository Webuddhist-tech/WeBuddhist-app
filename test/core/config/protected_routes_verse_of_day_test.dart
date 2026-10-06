import 'package:flutter_pecha/core/config/protected_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProtectedRoutes verse-of-day / language', () {
    test('verse-of-day/today is optional auth, not required', () {
      expect(ProtectedRoutes.isOptional('/verse-of-day/today'), isTrue);
      expect(ProtectedRoutes.isProtected('/verse-of-day/today'), isFalse);
    });

    test('verse likes and comment delete are protected', () {
      expect(ProtectedRoutes.isProtected('/verse-of-day/v1/likes'), isTrue);
      expect(ProtectedRoutes.isProtected('/verse-of-day/comments/c1'), isTrue);
    });

    test('verse likers list and comment likes are protected', () {
      expect(
        ProtectedRoutes.isProtected('/verse-of-day/v1/likes/users'),
        isTrue,
      );
      expect(
        ProtectedRoutes.isProtected('/verse-of-day/comments/c1/likes'),
        isTrue,
      );
    });

    test('verse comments list is optional auth', () {
      expect(ProtectedRoutes.isOptional('/verse-of-day/v1/comments'), isTrue);
      expect(ProtectedRoutes.isProtected('/verse-of-day/v1/comments'), isFalse);
      expect(
        ProtectedRoutes.isOptional('/verse-of-day/v1/comments/c1'),
        isTrue,
      );
    });

    test('users/me/language is protected via /users/me/ prefix', () {
      expect(ProtectedRoutes.isProtected('/users/me/language'), isTrue);
    });

    test('community chat REST is protected via /chat/ prefix', () {
      expect(ProtectedRoutes.isProtected('/chat/rooms'), isTrue);
      expect(ProtectedRoutes.isProtected('/chat/groups/g1/messages'), isTrue);
    });
  });
}
