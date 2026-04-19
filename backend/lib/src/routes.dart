import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'services/waste_data_service.dart';

Router buildRouter(WasteDataService service) {
  final router = Router();

  router.get('/health', (Request request) {
    return _jsonResponse({
      'status': 'ok',
      'service': 'EcoSort AI Backend',
      'version': '0.1.0',
    });
  });

  router.get('/categories', (Request request) {
    return _jsonResponse(service.categories.map((item) => item.toJson()).toList());
  });

  router.post('/classify', (Request request) async {
    final body = await request.readAsString();
    final data = body.isEmpty ? <String, dynamic>{} : jsonDecode(body);

    if (data is! Map<String, dynamic>) {
      return _jsonResponse({'error': 'Invalid request body.'}, statusCode: 400);
    }

    final itemName = data['itemName'] as String?;
    if (itemName == null || itemName.trim().isEmpty) {
      return _jsonResponse({'error': 'itemName is required.'}, statusCode: 400);
    }

    return _jsonResponse(service.classify(itemName).toJson());
  });

  router.get('/eco-actions', (Request request) {
    return _jsonResponse(service.ecoActions.map((item) => item.toJson()).toList());
  });

  router.get('/rewards', (Request request) {
    return _jsonResponse(service.rewards.map((item) => item.toJson()).toList());
  });

  router.get('/forum-posts', (Request request) {
    return _jsonResponse(service.forumPosts.map((item) => item.toJson()).toList());
  });

  router.get('/messages', (Request request) {
    return _jsonResponse(service.messages.map((item) => item.toJson()).toList());
  });

  router.get('/profile', (Request request) {
    return _jsonResponse(service.profile.toJson());
  });

  router.all('/<ignored|.*>', (Request request) {
    return _jsonResponse({'error': 'Route not found.'}, statusCode: 404);
  });

  return router;
}

Response _jsonResponse(Object body, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(body),
    headers: {'Content-Type': 'application/json'},
  );
}
