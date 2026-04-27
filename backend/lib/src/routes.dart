/// API route definitions for the EcoSort AI Backend.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'models/app_models.dart';
import 'services/waste_data_service.dart';

Router buildRouter(WasteDataService service) {
  final router = Router();

  router.get('/', (Request request) {
    return _jsonResponse({
      'status': 'running',
      'service': 'EcoSort AI Backend',
      'version': '0.1.0',
      'endpoints': [
        'GET /health',
        'POST /auth/register',
        'POST /auth/login',
        'GET /categories',
        'POST /classify',
        'POST /classify-image',
        'GET /vision-logs?limit=20',
        'GET /eco-actions',
        'GET /eco-action-catalog',
        'GET /eco-actions/history',
        'POST /eco-actions/evaluate',
        'GET /badges',
        'POST /badges/redeem',
        'GET /eco-dashboard',
        'GET /rewards',
        'GET /forum-posts',
        'POST /forum-posts',
        'POST /forum-posts/:postId/like',
        'GET /forum-posts/:postId/comments',
        'POST /forum-posts/:postId/comments',
        'POST /forum-comments/:commentId/like',
        'GET /chat/conversations',
        'POST /chat/conversations/direct',
        'GET /chat/messages',
        'POST /chat/messages/text',
        'POST /chat/messages/image',
        'POST /chat/conversations/read',
        'GET /chat/stream',
        'GET /profile',
        'POST /profile/update',
        'POST /profile/avatar',
        'POST /profile/change-password',
        'GET /profile/recognition-history',
        'GET /profile/point-history',
        'GET /profile/badge-history',
        'GET /profile/forum-posts',
      ],
    });
  });

  router.get('/health', (Request request) async {
    final dbConnected = await service.pingDatabase();
    return _jsonResponse({
      'status': dbConnected ? 'ok' : 'degraded',
      'service': 'EcoSort AI Backend',
      'version': '0.1.0',
      'database': {'connected': dbConnected},
    });
  });

  router.post('/auth/register', (Request request) async {
    final data = await _readBodyAsMap(request);
    if (data == null) {
      return _jsonResponse({'error': 'Invalid request body.'}, statusCode: 400);
    }
    final name = (data['name'] as String?)?.trim() ?? '';
    final email = (data['email'] as String?)?.trim() ?? '';
    final password = (data['password'] as String?)?.trim() ?? '';
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      return _jsonResponse(
        {'error': 'name, email and password are required.'},
        statusCode: 400,
      );
    }

    try {
      final session = await service.register(
        name: name,
        email: email,
        password: password,
      );
      return _jsonResponse(session.toJson());
    } on StateError catch (error) {
      return _jsonResponse({'error': error.message}, statusCode: 400);
    }
  });

  router.post('/auth/login', (Request request) async {
    final data = await _readBodyAsMap(request);
    if (data == null) {
      return _jsonResponse({'error': 'Invalid request body.'}, statusCode: 400);
    }
    final email = (data['email'] as String?)?.trim() ?? '';
    final password = (data['password'] as String?)?.trim() ?? '';
    if (email.isEmpty || password.isEmpty) {
      return _jsonResponse(
        {'error': 'email and password are required.'},
        statusCode: 400,
      );
    }

    try {
      final session = await service.login(email: email, password: password);
      return _jsonResponse(session.toJson());
    } on StateError catch (error) {
      return _jsonResponse({'error': error.message}, statusCode: 400);
    }
  });

  router.get('/categories', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final categories = await service.getCategories();
    return _jsonResponse(categories.map((item) => item.toJson()).toList());
  });

  router.post('/classify', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }

    final data = await _readBodyAsMap(request);
    if (data == null) {
      return _jsonResponse({'error': 'Invalid request body.'}, statusCode: 400);
    }
    final itemName = (data['itemName'] as String?)?.trim() ?? '';
    if (itemName.isEmpty) {
      return _jsonResponse({'error': 'itemName is required.'}, statusCode: 400);
    }

    final result = await service.classify(itemName);
    return _jsonResponse(result.toJson());
  });

  router.post('/classify-image', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final user = auth.user!;

    final data = await _readBodyAsMap(request);
    if (data == null) {
      return _jsonResponse({'error': 'Invalid request body.'}, statusCode: 400);
    }

    final imageBase64 = (data['imageBase64'] as String?)?.trim() ?? '';
    final fileName = ((data['fileName'] as String?)?.trim() ?? 'upload.jpg');
    if (imageBase64.isEmpty) {
      return _jsonResponse({'error': 'imageBase64 is required.'}, statusCode: 400);
    }

    List<int> imageBytes;
    try {
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
        submittedBy: user.id,
      );
      return _jsonResponse(result.toJson());
    } on StateError catch (error) {
      return _jsonResponse({'error': error.message}, statusCode: 400);
    }
  });

  router.get('/vision-logs', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }

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

  router.get('/eco-actions', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final actions = await service.getEcoActions();
    return _jsonResponse(actions.map((item) => item.toJson()).toList());
  });

  router.get('/eco-action-catalog', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final catalog = await service.getEcoActionCatalog();
    return _jsonResponse(catalog.map((item) => item.toJson()).toList());
  });

  router.get('/eco-actions/history', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final user = auth.user!;

    final limit =
        int.tryParse(request.requestedUri.queryParameters['limit'] ?? '') ?? 20;
    final history = await service.getEcoActionHistory(userId: user.id, limit: limit);
    return _jsonResponse(history.map((item) => item.toJson()).toList());
  });

  router.post('/eco-actions/evaluate', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final user = auth.user!;

    final data = await _readBodyAsMap(request);
    if (data == null) {
      return _jsonResponse({'error': 'Invalid request body.'}, statusCode: 400);
    }

    final catalogActionId = (data['catalogActionId'] as String?)?.trim() ?? '';
    final quantityRaw = data['quantity'];
    final quantity = quantityRaw is num ? quantityRaw.toDouble() : null;
    final note = data['note'] as String?;

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
        userId: user.id,
        catalogActionId: catalogActionId,
        quantity: quantity,
        note: note,
      );
      return _jsonResponse(result.toJson());
    } on StateError catch (error) {
      return _jsonResponse({'error': error.message}, statusCode: 400);
    }
  });

  router.get('/badges', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final user = auth.user!;

    try {
      final badges = await service.getBadges(userId: user.id);
      return _jsonResponse(badges.map((item) => item.toJson()).toList());
    } on StateError catch (error) {
      return _jsonResponse({'error': error.message}, statusCode: 400);
    }
  });

  router.post('/badges/redeem', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final user = auth.user!;

    final data = await _readBodyAsMap(request);
    if (data == null) {
      return _jsonResponse({'error': 'Invalid request body.'}, statusCode: 400);
    }
    final badgeId = (data['badgeId'] as String?)?.trim() ?? '';
    if (badgeId.isEmpty) {
      return _jsonResponse({'error': 'badgeId is required.'}, statusCode: 400);
    }

    try {
      final result = await service.redeemBadge(userId: user.id, badgeId: badgeId);
      return _jsonResponse(result.toJson());
    } on StateError catch (error) {
      return _jsonResponse({'error': error.message}, statusCode: 400);
    }
  });

  router.get('/eco-dashboard', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final user = auth.user!;

    try {
      final dashboard = await service.getEcoDashboard(userId: user.id);
      return _jsonResponse(dashboard.toJson());
    } on StateError catch (error) {
      return _jsonResponse({'error': error.message}, statusCode: 400);
    }
  });

  router.get('/rewards', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final rewards = await service.getRewards();
    return _jsonResponse(rewards.map((item) => item.toJson()).toList());
  });

  router.get('/forum-posts', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final posts = await service.getForumPosts();
    return _jsonResponse(posts.map((item) => item.toJson()).toList());
  });

  router.post('/forum-posts', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final user = auth.user!;

    final data = await _readBodyAsMap(request);
    if (data == null) {
      return _jsonResponse({'error': 'Invalid request body.'}, statusCode: 400);
    }

    final title = (data['title'] as String?)?.trim() ?? '';
    final content = (data['content'] as String?)?.trim() ?? '';
    final tag = (data['tag'] as String?)?.trim() ?? 'General';
    if (title.isEmpty || content.isEmpty) {
      return _jsonResponse(
        {'error': 'title and content are required.'},
        statusCode: 400,
      );
    }

    try {
      final post = await service.createForumPost(
        authorId: user.id,
        title: title,
        content: content,
        tag: tag,
      );
      return _jsonResponse(post.toJson());
    } on StateError catch (error) {
      return _jsonResponse({'error': error.message}, statusCode: 400);
    }
  });

  router.post('/forum-posts/<postId>/like', (Request request, String postId) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final user = auth.user!;

    try {
      final post = await service.toggleForumPostLike(postId: postId, userId: user.id);
      return _jsonResponse(post.toJson());
    } on StateError catch (error) {
      return _jsonResponse({'error': error.message}, statusCode: 400);
    }
  });

  router.get('/forum-posts/<postId>/comments', (
    Request request,
    String postId,
  ) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final user = auth.user!;

    final comments = await service.getForumComments(postId: postId, userId: user.id);
    return _jsonResponse(comments.map((item) => item.toJson()).toList());
  });

  router.post('/forum-posts/<postId>/comments', (
    Request request,
    String postId,
  ) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final user = auth.user!;

    final data = await _readBodyAsMap(request);
    if (data == null) {
      return _jsonResponse({'error': 'Invalid request body.'}, statusCode: 400);
    }

    final content = (data['content'] as String?)?.trim() ?? '';
    final parentCommentId = (data['parentCommentId'] as String?)?.trim();
    if (content.isEmpty) {
      return _jsonResponse({'error': 'content is required.'}, statusCode: 400);
    }

    try {
      final comment = await service.createForumComment(
        postId: postId,
        authorId: user.id,
        content: content,
        parentCommentId: parentCommentId,
      );
      return _jsonResponse(comment.toJson());
    } on StateError catch (error) {
      return _jsonResponse({'error': error.message}, statusCode: 400);
    }
  });

  router.post('/forum-comments/<commentId>/like', (
    Request request,
    String commentId,
  ) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final user = auth.user!;

    try {
      final comment = await service.toggleForumCommentLike(
        commentId: commentId,
        userId: user.id,
      );
      return _jsonResponse(comment.toJson());
    } on StateError catch (error) {
      return _jsonResponse({'error': error.message}, statusCode: 400);
    }
  });

  router.get('/messages', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final messages = await service.getMessages();
    return _jsonResponse(messages.map((item) => item.toJson()).toList());
  });

  router.get('/chat/conversations', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final user = auth.user!;

    try {
      final conversations = await service.getChatConversations(userId: user.id);
      return _jsonResponse(conversations.map((item) => item.toJson()).toList());
    } on StateError catch (error) {
      return _jsonResponse({'error': error.message}, statusCode: 400);
    }
  });

  router.post('/chat/conversations/direct', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final user = auth.user!;

    final data = await _readBodyAsMap(request);
    if (data == null) {
      return _jsonResponse({'error': 'Invalid request body.'}, statusCode: 400);
    }
    final peerUserId = (data['peerUserId'] as String?)?.trim() ?? '';
    if (peerUserId.isEmpty) {
      return _jsonResponse({'error': 'peerUserId is required.'}, statusCode: 400);
    }

    try {
      final conversationId = await service.getOrCreateDirectConversation(
        userId: user.id,
        peerUserId: peerUserId,
      );
      return _jsonResponse({'conversationId': conversationId});
    } on StateError catch (error) {
      return _jsonResponse({'error': error.message}, statusCode: 400);
    }
  });

  router.get('/chat/messages', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final user = auth.user!;

    final qp = request.requestedUri.queryParameters;
    final conversationId = qp['conversationId']?.trim() ?? '';
    final afterMessageId = int.tryParse(qp['afterMessageId'] ?? '');
    final limit = int.tryParse(qp['limit'] ?? '') ?? 50;
    if (conversationId.isEmpty) {
      return _jsonResponse(
        {'error': 'conversationId is required.'},
        statusCode: 400,
      );
    }

    try {
      final messages = await service.getChatMessages(
        userId: user.id,
        conversationId: conversationId,
        afterMessageId: afterMessageId,
        limit: limit,
      );
      return _jsonResponse(messages.map((item) => item.toJson()).toList());
    } on StateError catch (error) {
      return _jsonResponse({'error': error.message}, statusCode: 400);
    }
  });

  router.post('/chat/messages/text', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final user = auth.user!;

    final data = await _readBodyAsMap(request);
    if (data == null) {
      return _jsonResponse({'error': 'Invalid request body.'}, statusCode: 400);
    }

    final conversationId = (data['conversationId'] as String?)?.trim() ?? '';
    final content = (data['content'] as String?)?.trim() ?? '';
    if (conversationId.isEmpty || content.isEmpty) {
      return _jsonResponse(
        {'error': 'conversationId and content are required.'},
        statusCode: 400,
      );
    }

    try {
      final message = await service.sendChatTextMessage(
        userId: user.id,
        conversationId: conversationId,
        content: content,
      );
      return _jsonResponse(message.toJson());
    } on StateError catch (error) {
      return _jsonResponse({'error': error.message}, statusCode: 400);
    }
  });

  router.post('/chat/messages/image', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final user = auth.user!;

    final data = await _readBodyAsMap(request);
    if (data == null) {
      return _jsonResponse({'error': 'Invalid request body.'}, statusCode: 400);
    }

    final conversationId = (data['conversationId'] as String?)?.trim() ?? '';
    final imageUrl = (data['imageUrl'] as String?)?.trim() ?? '';
    if (conversationId.isEmpty || imageUrl.isEmpty) {
      return _jsonResponse(
        {'error': 'conversationId and imageUrl are required.'},
        statusCode: 400,
      );
    }

    try {
      final message = await service.sendChatImageMessage(
        userId: user.id,
        conversationId: conversationId,
        imageUrl: imageUrl,
      );
      return _jsonResponse(message.toJson());
    } on StateError catch (error) {
      return _jsonResponse({'error': error.message}, statusCode: 400);
    }
  });

  router.post('/chat/conversations/read', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final user = auth.user!;

    final data = await _readBodyAsMap(request);
    if (data == null) {
      return _jsonResponse({'error': 'Invalid request body.'}, statusCode: 400);
    }
    final conversationId = (data['conversationId'] as String?)?.trim() ?? '';
    if (conversationId.isEmpty) {
      return _jsonResponse(
        {'error': 'conversationId is required.'},
        statusCode: 400,
      );
    }

    try {
      await service.markConversationRead(
        userId: user.id,
        conversationId: conversationId,
      );
      return _jsonResponse({'ok': true});
    } on StateError catch (error) {
      return _jsonResponse({'error': error.message}, statusCode: 400);
    }
  });

  router.get('/chat/stream', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final user = auth.user!;

    final qp = request.requestedUri.queryParameters;
    final conversationId = qp['conversationId']?.trim() ?? '';
    var afterMessageId = int.tryParse(qp['afterMessageId'] ?? '') ?? 0;
    if (conversationId.isEmpty) {
      return _jsonResponse(
        {'error': 'conversationId is required.'},
        statusCode: 400,
      );
    }

    final controller = StreamController<List<int>>();
    Timer? timer;

    Future<void> emitPing() async {
      controller.add(utf8.encode('event: ping\ndata: {"ok":true}\n\n'));
    }

    Future<void> emitNewMessages() async {
      try {
        final messages = await service.getChatMessages(
          userId: user.id,
          conversationId: conversationId,
          afterMessageId: afterMessageId > 0 ? afterMessageId : null,
          limit: 100,
        );
        for (final message in messages) {
          afterMessageId = message.id;
          final payload = jsonEncode(message.toJson());
          controller.add(utf8.encode('event: message\ndata: $payload\n\n'));
        }
      } catch (error) {
        controller.add(
          utf8.encode('event: error\ndata: ${jsonEncode({'error': '$error'})}\n\n'),
        );
      }
    }

    timer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (controller.isClosed) {
        return;
      }
      await emitNewMessages();
      await emitPing();
    });

    controller.onListen = () async {
      await emitPing();
      await emitNewMessages();
    };
    controller.onCancel = () {
      timer?.cancel();
    };

    return Response.ok(
      controller.stream,
      headers: {
        HttpHeaders.contentTypeHeader: 'text/event-stream',
        HttpHeaders.cacheControlHeader: 'no-cache',
        HttpHeaders.connectionHeader: 'keep-alive',
      },
    );
  });

  router.get('/profile', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final user = auth.user!;

    final profile = await service.getProfile(userId: user.id);
    return _jsonResponse(profile.toJson());
  });

  router.post('/profile/update', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final user = auth.user!;

    final data = await _readBodyAsMap(request);
    if (data == null) {
      return _jsonResponse({'error': 'Invalid request body.'}, statusCode: 400);
    }
    final name = (data['name'] as String?)?.trim() ?? '';
    final email = (data['email'] as String?)?.trim() ?? '';
    final city = (data['city'] as String?)?.trim() ?? '';
    if (name.isEmpty || email.isEmpty || city.isEmpty) {
      return _jsonResponse(
        {'error': 'name, email and city are required.'},
        statusCode: 400,
      );
    }

    try {
      final updated = await service.updateProfile(
        userId: user.id,
        name: name,
        email: email,
        city: city,
      );
      return _jsonResponse(updated.toJson());
    } on StateError catch (error) {
      return _jsonResponse({'error': error.message}, statusCode: 400);
    }
  });

  router.post('/profile/avatar', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final user = auth.user!;

    final data = await _readBodyAsMap(request);
    if (data == null) {
      return _jsonResponse({'error': 'Invalid request body.'}, statusCode: 400);
    }
    final avatarUrl = (data['avatarUrl'] as String?)?.trim() ?? '';
    if (avatarUrl.isEmpty) {
      return _jsonResponse({'error': 'avatarUrl is required.'}, statusCode: 400);
    }

    try {
      await service.updateAvatar(userId: user.id, avatarUrl: avatarUrl);
      return _jsonResponse({'ok': true});
    } on StateError catch (error) {
      return _jsonResponse({'error': error.message}, statusCode: 400);
    } catch (_) {
      return _jsonResponse(
        {'error': 'Failed to update avatar. Please try a smaller image.'},
        statusCode: 500,
      );
    }
  });

  router.post('/profile/change-password', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final user = auth.user!;

    final data = await _readBodyAsMap(request);
    if (data == null) {
      return _jsonResponse({'error': 'Invalid request body.'}, statusCode: 400);
    }
    final currentPassword = (data['currentPassword'] as String?)?.trim() ?? '';
    final newPassword = (data['newPassword'] as String?)?.trim() ?? '';
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      return _jsonResponse(
        {'error': 'currentPassword and newPassword are required.'},
        statusCode: 400,
      );
    }

    try {
      await service.changePassword(
        userId: user.id,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return _jsonResponse({'ok': true});
    } on StateError catch (error) {
      return _jsonResponse({'error': error.message}, statusCode: 400);
    }
  });

  router.get('/profile/recognition-history', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final user = auth.user!;
    final limit =
        int.tryParse(request.requestedUri.queryParameters['limit'] ?? '') ?? 50;
    final list = await service.getRecognitionHistory(userId: user.id, limit: limit);
    return _jsonResponse(list.map((item) => item.toJson()).toList());
  });

  router.get('/profile/point-history', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final user = auth.user!;
    final limit =
        int.tryParse(request.requestedUri.queryParameters['limit'] ?? '') ?? 50;
    final list = await service.getPointHistory(userId: user.id, limit: limit);
    return _jsonResponse(list.map((item) => item.toJson()).toList());
  });

  router.get('/profile/badge-history', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final user = auth.user!;
    final limit =
        int.tryParse(request.requestedUri.queryParameters['limit'] ?? '') ?? 50;
    final list = await service.getBadgeHistory(userId: user.id, limit: limit);
    return _jsonResponse(list.map((item) => item.toJson()).toList());
  });

  router.get('/profile/forum-posts', (Request request) async {
    final auth = await _authorize(request, service);
    if (auth.response != null) {
      return auth.response!;
    }
    final user = auth.user!;
    final limit =
        int.tryParse(request.requestedUri.queryParameters['limit'] ?? '') ?? 50;
    final list = await service.getUserForumPosts(userId: user.id, limit: limit);
    return _jsonResponse(list.map((item) => item.toJson()).toList());
  });

  router.all('/<ignored|.*>', (Request request) {
    return _jsonResponse({'error': 'Route not found.'}, statusCode: 404);
  });

  return router;
}

Future<Map<String, dynamic>?> _readBodyAsMap(Request request) async {
  final body = await request.readAsString();
  if (body.isEmpty) {
    return <String, dynamic>{};
  }
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    return null;
  }
  return decoded;
}

Future<_AuthResult> _authorize(
  Request request,
  WasteDataService service,
) async {
  final authHeader = request.headers[HttpHeaders.authorizationHeader] ?? '';
  if (!authHeader.startsWith('Bearer ')) {
    return _AuthResult(
      response: Response(
        401,
        body: '{"error":"Unauthorized. Missing Bearer token."}',
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }
  final token = authHeader.substring(7).trim();
  if (token.isEmpty) {
    return _AuthResult(
      response: Response(
        401,
        body: '{"error":"Unauthorized. Missing Bearer token."}',
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  try {
    final user = await service.requireUserByToken(token);
    return _AuthResult(user: user);
  } on StateError catch (error) {
    return _AuthResult(
      response: _jsonResponse({'error': error.message}, statusCode: 401),
    );
  }
}

Response _jsonResponse(Object body, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(body),
    headers: {'Content-Type': 'application/json'},
  );
}

class _AuthResult {
  const _AuthResult({
    this.user,
    this.response,
  });

  final AppUser? user;
  final Response? response;
}
