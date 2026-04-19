import 'package:intelligent_waste_backend/src/services/waste_data_service.dart';
import 'package:test/test.dart';

void main() {
  test('classifies batteries as hazardous waste', () {
    final service = WasteDataService.seeded();

    final result = service.classify('battery');

    expect(result.category.id, 'hazardous');
    expect(result.confidence, greaterThan(0.9));
  });

  test('classifies banana peels as organic waste', () {
    final service = WasteDataService.seeded();

    final result = service.classify('banana peel');

    expect(result.category.id, 'organic');
  });
}
