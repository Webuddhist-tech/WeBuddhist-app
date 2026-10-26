import 'package:flutter_pecha/features/auth/data/models/user_model.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses display_name and prefers it over first and last name', () {
    final user =
        UserModel.fromJson({
          'id': 'u1',
          'firstname': 'Tenzin',
          'lastname': 'Dhakar',
          'display_name': 'Tenzin Dhakar',
          'username': 'chris',
        }).toEntity();

    expect(user.displayName, 'Tenzin Dhakar');
    expect(user.visibleName, 'Tenzin Dhakar');
  });

  test('falls back to first and last name when display_name is missing', () {
    const user = User(firstName: 'Tenzin', lastName: 'Dhakar');

    expect(user.visibleName, 'Tenzin Dhakar');
    expect(user.fullName, 'Tenzin Dhakar');
  });

  test('round-trips display_name through local cache json', () {
    final encoded =
        UserModel.fromEntity(
          const User(id: 'u1', displayName: 'Tenzin Dhakar', username: 'chris'),
        ).toJson();

    expect(encoded['display_name'], 'Tenzin Dhakar');
    expect(UserModel.fromJson(encoded).toEntity().visibleName, 'Tenzin Dhakar');
  });
}
