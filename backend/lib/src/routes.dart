/// API route definitions for the EcoSort AI Backend.
///
/// This file defines all REST API endpoints using the [shelf_router] package.
/// Each route delegates business logic to the [WasteDataService] and returns
/// JSON-encoded responses.
library;

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'services/waste_data_service.dart';

/// Builds and returns a [Router] with all application routes registered.
///
/// The [service] parameter provides the data layer used by each endpoint to
/// fetch, classify, and return waste-related information.
Router buildRouter(WasteDataService service) {
  final router = Router();

  // ---------------------------------------------------------------------------
  // API root endpoint - returns basic service metadata and available endpoints.
  // ---------------------------------------------------------------------------
  router.get('/', (Request request) {
    return _jsonResponse({
      'status': 'running',
      'service': 'EcoSort AI Backend',
      'version': '0.1.0',
      'endpoints': [
        'GET /health',
        'GET /categories',
        'POST /classify',
        'GET /eco-actions',
        'GET /rewards',
        'GET /forum-posts',
        'GET /messages',
        'GET /profile',
      ],
    });
  });

  // ---------------------------------------------------------------------------
  // Health check endpoint – used by monitoring tools or load balancers to
  // verify that the service is running.
  // ---------------------------------------------------------------------------
  router.get('/health', (Request request) async {
    final dbConnected = await service.pingDatabase();
    return _jsonResponse({
      'status': dbConnected ? 'ok' : 'degraded',
      'service': 'EcoSort AI Backend',
      'version': '0.1.0',
      'database': {
        'connected': dbConnected,
      },
    });
  });

  // ---------------------------------------------------------------------------
  // GET /categories
  // Returns the full list of waste categories (e.g. Recyclable, Kitchen Waste,
  // Hazardous, Other) with their descriptions and disposal tips.
  // ---------------------------------------------------------------------------
  router.get('/categories', (Request request) async {
    final categories = await service.getCategories();
    return _jsonResponse(categories.map((item) => item.toJson()).toList());
  });

  // ---------------------------------------------------------------------------
  // POST /classify
  // Accepts a JSON body with an "itemName" field and returns the predicted
  // waste category for that item.
  // ---------------------------------------------------------------------------
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

    final result = await service.classify(itemName);
    return _jsonResponse(result.toJson());
  });

  // ---------------------------------------------------------------------------
  // GET /eco-actions
  // Returns a list of suggested eco-friendly actions that users can take to
  // reduce waste and live more sustainably.
  // ---------------------------------------------------------------------------
  router.get('/eco-actions', (Request request) async {
    final actions = await service.getEcoActions();
    return _jsonResponse(actions.map((item) => item.toJson()).toList());
  });

  // ---------------------------------------------------------------------------
  // GET /rewards
  // Returns the available rewards that users can redeem using points earned
  // through waste-sorting activities.
  // ---------------------------------------------------------------------------
  router.get('/rewards', (Request request) async {
    final rewards = await service.getRewards();
    return _jsonResponse(rewards.map((item) => item.toJson()).toList());
  });

  // ---------------------------------------------------------------------------
  // GET /forum-posts
  // Returns community forum posts where users can discuss waste sorting and
  // environmental topics.
  // ---------------------------------------------------------------------------
  router.get('/forum-posts', (Request request) async {
    final posts = await service.getForumPosts();
    return _jsonResponse(posts.map((item) => item.toJson()).toList());
  });

  // ---------------------------------------------------------------------------
  // GET /messages
  // Returns the user's message threads for in-app communication.
  // ---------------------------------------------------------------------------
  router.get('/messages', (Request request) async {
    final messages = await service.getMessages();
    return _jsonResponse(messages.map((item) => item.toJson()).toList());
  });

  // ---------------------------------------------------------------------------
  // GET /profile
  // Returns the current user's profile information including points, badges,
  // and activity history.
  // ---------------------------------------------------------------------------
  router.get('/profile', (Request request) async {
    final profile = await service.getProfile();
    return _jsonResponse(profile.toJson());
  });

  // ---------------------------------------------------------------------------
  // Catch-all route – returns a 404 JSON error for any unrecognized path.
  // ---------------------------------------------------------------------------
  router.all('/<ignored|.*>', (Request request) {
    return _jsonResponse({'error': 'Route not found.'}, statusCode: 404);
  });

  return router;
}

/// Helper that builds a JSON [Response] with the given [body] and [statusCode].
///
/// The [Content-Type] header is automatically set to `application/json`.
Response _jsonResponse(Object body, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(body),
    headers: {'Content-Type': 'application/json'},
  );
}
