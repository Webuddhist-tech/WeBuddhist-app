import 'package:flutter_pecha/features/group_profile/data/models/group_join_request_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GroupJoinRequestsPageModel', () {
    test('parses a pending join request page', () {
      final page =
          GroupJoinRequestsPageModel.fromJson({
            'requests': [
              {
                'id': '427d2a34-289a-4640-81d9-6a38ac7a3fca',
                'user_id': 'c9957b3d-43ea-4f37-bd60-a7dd37a10c6a',
                'user_name': 'Dhakar Chris',
                'email': 'dhakar@webuddhist.com',
                'user_avatar_url': 'https://example.com/avatar.webp',
                'message': 'testing…..',
                'status': 'PENDING',
                'created_at': '2026-09-22T06:57:18.652500Z',
              },
            ],
            'skip': 0,
            'limit': 20,
            'total': 1,
          }).toEntity();

      expect(page.skip, 0);
      expect(page.limit, 20);
      expect(page.total, 1);
      expect(page.requests, hasLength(1));

      final request = page.requests.single;
      expect(request.id, '427d2a34-289a-4640-81d9-6a38ac7a3fca');
      expect(request.userId, 'c9957b3d-43ea-4f37-bd60-a7dd37a10c6a');
      expect(request.userName, 'Dhakar Chris');
      expect(request.userAvatarUrl, 'https://example.com/avatar.webp');
      expect(request.email, 'dhakar@webuddhist.com');
      expect(request.message, 'testing…..');
      expect(request.status, GroupJoinRequestStatus.pending);
      expect(request.createdAt, DateTime.utc(2026, 9, 22, 6, 57, 18, 652, 500));
    });

    test('keeps the pagination window the server reported', () {
      final page =
          GroupJoinRequestsPageModel.fromJson({
            'requests': [
              {
                'id': 'a',
                'user_id': 'u',
                'user_name': 'A',
                'status': 'PENDING',
              },
            ],
            'skip': 0,
            'limit': 1,
            'total': 3,
          }).toEntity();

      expect(page.skip, 0);
      expect(page.limit, 1);
      expect(page.total, 3);
      expect(page.requests, hasLength(1));
    });

    test('drops a blank avatar and an unparseable date', () {
      final request =
          GroupJoinRequestModel.fromJson({
            'id': 'a9181d26-7e76-4962-83af-77382d5c55ff',
            'user_id': 'e247aaf9-dd29-4a63-9623-c52d9b0e61f1',
            'user_name': 'Tenzin pal',
            'email': 'tenzpalden6322@gmail.com',
            'user_avatar_url': '',
            'message': null,
            'status': 'PENDING',
            'created_at': 'not-a-date',
          }).toEntity();

      expect(request.userName, 'Tenzin pal');
      expect(request.email, 'tenzpalden6322@gmail.com');
      expect(request.userAvatarUrl, isNull);
      expect(request.message, isEmpty);
      expect(request.createdAt, isNull);
      expect(request.status, GroupJoinRequestStatus.pending);
    });
  });

  group('GroupJoinRequestDecisionModel', () {
    test('parses an approved decision', () {
      final decision =
          GroupJoinRequestDecisionModel.fromJson({
            'id': '67e53393-a734-4408-9fc1-8b0101647de6',
            'status': 'APPROVED',
          }).toEntity();

      expect(decision.id, '67e53393-a734-4408-9fc1-8b0101647de6');
      expect(decision.status, GroupJoinRequestStatus.approved);
    });

    test('parses a rejected decision', () {
      final decision =
          GroupJoinRequestDecisionModel.fromJson({
            'id': '427d2a34-289a-4640-81d9-6a38ac7a3fca',
            'status': 'REJECTED',
          }).toEntity();

      expect(decision.id, '427d2a34-289a-4640-81d9-6a38ac7a3fca');
      expect(decision.status, GroupJoinRequestStatus.rejected);
    });

    test('rejects an unknown status', () {
      expect(
        () => GroupJoinRequestDecisionModel.fromJson({
          'id': 'a',
          'status': 'MAYBE',
        }),
        throwsFormatException,
      );
    });
  });
}
