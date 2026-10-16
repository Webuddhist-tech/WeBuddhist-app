import 'package:flutter_pecha/core/config/protected_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feedback is protected, so the token is always attached', () {
    // Without the token the backend answers 403 "Not authenticated".
    expect(ProtectedRoutes.isProtected('/feedback'), isTrue);
    expect(ProtectedRoutes.isOptional('/feedback'), isFalse);
  });
}
