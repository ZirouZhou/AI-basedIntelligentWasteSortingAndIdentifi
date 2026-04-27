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
        'POST /classify-image',
        'GET /vision-logs?limit=20',
        'GET /eco-actions',
        'GET /eco-action-catalog',
        'GET /eco-actions/history?userId=u1',
        'POST /eco-actions/evaluate',
        'GET /badges?userId=u1',
        'POST /badges/redeem',
        'GET /eco-dashboard?userId=u1',
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
  // POST /classify-image
  // Accepts base64 encoded image data and uses cloud vision service for
  // garbage classification.
  // ---------------------------------------------------------------------------
  router.post('/classify-image', (Request request) async {
    final body = await request.readAsString();
    final data = body.isEmpty ? <String, dynamic>{} : jsonDecode(body);
    if (data is! Map<String, dynamic>) {
      return _jsonResponse({'error': 'Invalid request body.'}, statusCode: 400);
    }

    final imageBase64 = (data['imageBase64'] as String?)?.trim() ?? '';
    final fileName = ((data['fileName'] as String?)?.trim() ?? 'upload.jpg');
    final submittedBy = (data['submittedBy'] as String?)?.trim();

    if (imageBase64.isEmpty) {
      return _jsonResponse({'error': 'imageBase64 is required.'}, statusCode: 400);
    }

    List<int> imageBytes;
    try {
      // Support both plain base64 and data-url payloads.
      final payload = imageBase64.contains(',')
          ? imageBase64.substring(imageBase64.indexOf(',') + 1)
          : imageBase64;
      imageBytes = base64Decode(payload);
    } catch (_) {
      return _jsonResponse(
        {'error': 'imageBase64 is not valid base64.'},
        statusCode: 400,
      );
    }

    if (imageBytes.isEmpty) {
      return _jsonResponse({'error': 'Decoded image is empty.'}, statusCode: 400);
    }

    try {
      final result = await service.classifyImage(
        imageBytes: imageBytes,
        fileName: fileName,
        submittedBy: submittedBy,
      );
      return _jsonResponse(result.toJson());
    } on StateError catch (error) {
      return _jsonResponse({'error': error.message}, statusCode: 400);
    }
  });

  // ---------------------------------------------------------------------------
  // GET /vision-logs?limit=20
  // Returns latest raw vision logs for diagnostics.
  // ---------------------------------------------------------------------------
  router.get('/vision-logs', (Request request) async {
    final limit =
        int.tryParse(request.requestedUri.queryParameters['limit'] ?? '') ?? 20;
    final logs = await service.getRecentVisionLogs(limit: limit);
    final json = logs
        .map(
          (item) => {
            'requestId': item.requestId,
            'sensitive': item.sensitive,
            'imageUrl': item.imageUrl,
            'elements': item.elements.map((e) => e.toJson()).toList(),
            'rawPayload': item.rawPayload,
          },
        )
        .toList(growable: false);
    return _jsonResponse(json);
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
  // GET /eco-action-catalog
  // Returns configurable eco behavior types used for carbon reduction
  // evaluation and points calculation.
  // ---------------------------------------------------------------------------
  router.get('/eco-action-catalog', (Request request) async {
    final catalog = await service.getEcoActionCatalog();
    return _jsonResponse(catalog.map((item) => item.toJson()).toList());
  });

  // ---------------------------------------------------------------------------
  // GET /eco-actions/history?userId=u1&limit=20
  // Returns recently evaluated eco action records for one user.
  // ---------------------------------------------------------------------------
  router.get('/eco-actions/history', (Request request) async {
    final userId =
        request.requestedUri.queryParameters['userId']?.trim() ?? '';
    if (userId.isEmpty) {
      return _jsonResponse({'error': 'userId is required.'}, statusCode: 400);
    }

    final limit =
        int.tryParse(request.requestedUri.queryParameters['limit'] ?? '') ?? 20;
    final history = await service.getEcoActionHistory(userId: userId, limit: limit);
    return _jsonResponse(history.map((item) => item.toJson()).toList());
  });

  // ---------------------------------------------------------------------------
  // POST /eco-actions/evaluate
  // Evaluates carbon reduction and awards points for a submitted eco action.
  // ---------------------------------------------------------------------------
  router.post('/eco-actions/evaluate', (Request request) async {
    final body = await request.readAsString();
    final data = body.isEmpty ? <String, dynamic>{} : jsonDecode(body);
    if (data is! Map<String, dynamic>) {
      return _jsonResponse({'error': 'Invalid request body.'}, statusCode: 400);
    }

    final userId = (data['userId'] as String?)?.trim() ?? '';
    final catalogActionId = (data['catalogActionId'] as String?)?.trim() ?? '';
    final quantityRaw = data['quantity'];
    final quantity = quantityRaw is num ? quantityRaw.toDouble() : null;
    final note = data['note'] as String?;

    if (userId.isEmpty) {
      return _jsonResponse({'error': 'userId is required.'}, statusCode: 400);
    }
    if (catalogActionId.isEmpty) {
      return _jsonResponse(
        {'error': 'catalogActionId is required.'},
        statusCode: 400,
      );
    }
    if (quantity == null || quantity <= 0) {
      return _jsonResponse(
        {'error': 'quantity must be a positive number.'},
        statusCode: 400,
      );
    }

    try {
      final result = await service.evaluateEcoAction(
        userId: userId,
        catalogActionId: catalogActionId,
        quantity: quantity,
        note: note,
      );
      return _jsonResponse(result.toJson());
    } on StateError catch (error) {
      return _jsonResponse({'error': error.message}, statusCode: 400);
    }
  });

  // ---------------------------------------------------------------------------
  // GET /badges?userId=u1
  // Returns badge redemption status and redeemability for the user.
  // ---------------------------------------------------------------------------
  router.get('/badges', (Request request) async {
    final userId =
        request.requestedUri.queryParameters['userId']?.trim() ?? '';
    if (userId.isEmpty) {
      return _jsonResponse({'error': 'userId is required.'}, statusCode: 400);
    }

    try {
      final badges = await service.getBadges(userId: userId);
      return _jsonResponse(badges.map((item) => item.toJson()).toList());
    } on StateError catch (error) {
      return _jsonResponse({'error': error.message}, statusCode: 400);
    }
  });

  // ---------------------------------------------------------------------------
  // POST /badges/redeem
  // Redeems one badge if user has enough points.
  // ---------------------------------------------------------------------------
  router.post('/badges/redeem', (Request request) async {
    final body = await request.readAsString();
    final data = body.isEmpty ? <String, dynamic>{} : jsonDecode(body);
    if (data is! Map<String, dynamic>) {
      return _jsonResponse({'error': 'Invalid request body.'}, statusCode: 400);
    }

    final userId = (data['userId'] as String?)?.trim() ?? '';
    final badgeId = (data['badgeId'] as String?)?.trim() ?? '';
    if (userId.isEmpty) {
      return _jsonResponse({'error': 'userId is required.'}, statusCode: 400);
    }
    if (badgeId.isEmpty) {
      return _jsonResponse({'error': 'badgeId is required.'}, statusCode: 400);
    }

    try {
      final result = await service.redeemBadge(userId: userId, badgeId: badgeId);
      return _jsonResponse(result.toJson());
    } on StateError catch (error) {
      return _jsonResponse({'error': error.message}, statusCode: 400);
    }
  });

  // ---------------------------------------------------------------------------
  // GET /eco-dashboard?userId=u1
  // Returns point balance + cumulative carbon-reduction summary.
  // ---------------------------------------------------------------------------
  router.get('/eco-dashboard', (Request request) async {
    final userId =
        request.requestedUri.queryParameters['userId']?.trim() ?? '';
    if (userId.isEmpty) {
      return _jsonResponse({'error': 'userId is required.'}, statusCode: 400);
    }

    try {
      final dashboard = await service.getEcoDashboard(userId: userId);
      return _jsonResponse(dashboard.toJson());
    } on StateError catch (error) {
      return _jsonResponse({'error': error.message}, statusCode: 400);
    }
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
