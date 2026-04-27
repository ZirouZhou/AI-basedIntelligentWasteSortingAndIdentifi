import 'package:intelligent_waste_backend/src/services/in_memory_waste_data_service.dart';
import 'package:test/test.dart';

void main() {
  test('classifies batteries as hazardous waste', () async {
    final service = InMemoryWasteDataService.seeded();

    final result = await service.classify('battery');

    expect(result.category.id, 'hazardous');
    expect(result.confidence, greaterThan(0.9));
  });

  test('classifies banana peels as organic waste', () async {
    final service = InMemoryWasteDataService.seeded();

    final result = await service.classify('banana peel');

    expect(result.category.id, 'organic');
  });
}
