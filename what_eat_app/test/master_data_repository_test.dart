import 'package:flutter_test/flutter_test.dart';
import 'package:what_eat_app/models/master_data_model.dart';

void main() {
  test('MasterDataModel parses minimal map', () {
    final map = {
      'cuisines': [
        {'id': 'vn', 'name': 'Việt'},
      ],
      'meal_types': [
        {'id': 'soup', 'name': 'Món nước'},
      ],
      'flavors': [
        {'id': 'spicy', 'name': 'Cay'},
      ],
      'allergens': [
        {'id': 'peanut', 'name': 'Đậu phộng'},
      ],
    };

    final model = MasterDataModel.fromMap(map);

    expect(model.cuisines.first.id, 'vn');
    expect(model.mealTypes.first.id, 'soup');
    expect(model.flavors.first.name, 'Cay');
    expect(model.allergens.first.id, 'peanut');
  });
}

