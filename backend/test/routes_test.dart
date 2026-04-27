import 'dart:convert';

import 'package:intelligent_waste_backend/src/routes.dart';
import 'package:intelligent_waste_backend/src/services/in_memory_waste_data_service.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  test('GET / returns service metadata and endpoint list', () async {
    final service = InMemoryWasteDataService.seeded();
    final router = buildRouter(service);

    final response = await router(Request('GET', Uri.parse('http://localhost/')));
    final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 200);
    expect(body['service'], 'EcoSort AI Backend');
    expect(body['status'], 'running');
    expect(body['endpoints'], contains('GET /health'));
    expect(body['endpoints'], contains('POST /classify'));
  });
}
