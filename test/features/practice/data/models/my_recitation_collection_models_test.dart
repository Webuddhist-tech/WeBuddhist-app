import 'package:flutter_pecha/features/practice/data/models/my_recitation_collection_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MyRecitationCollectionItemModel', () {
    test('preserves fractional display_order values', () {
      final item = MyRecitationCollectionItemModel.fromJson({
        'id': 'item-1',
        'text_id': 'text-1',
        'title': 'Morning chant',
        'display_order': 1.4,
      });

      expect(item.displayOrder, 1.4);
    });
  });

  group('UpdateMyRecitationCollectionItemDisplayOrderRequest', () {
    test('serializes display_order for the PATCH endpoint', () {
      const request = UpdateMyRecitationCollectionItemDisplayOrderRequest(
        displayOrder: 2.5,
      );

      expect(request.toJson(), {'display_order': 2.5});
    });
  });
}
