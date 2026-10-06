import 'package:flutter_pecha/features/plans/data/models/plan_video_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips through json', () {
    final json = {
      'id': 'v1',
      'url': 'https://youtu.be/dQw4w9WgXcQ',
      'video_id': 'dQw4w9WgXcQ',
      'title': 'Session 1',
      'display_order': 2,
    };

    final model = PlanVideoModel.fromJson(json);

    expect(model.id, 'v1');
    expect(model.videoId, 'dQw4w9WgXcQ');
    expect(model.title, 'Session 1');
    expect(model.displayOrder, 2);
    expect(
      model.thumbnailUrl,
      'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
    );
    expect(model.toJson(), json);
  });

  test('a missing video_id parses as empty instead of throwing', () {
    final model = PlanVideoModel.fromJson({
      'id': 'v1',
      'url': 'https://youtu.be/dQw4w9WgXcQ',
      'video_id': null,
      'title': null,
    });

    expect(model.videoId, '');
    expect(model.displayOrder, 0);
  });
}
