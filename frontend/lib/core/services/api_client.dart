// ------------------------------------------------------------------------------------------------
// EcoSort AI Flutter App - REST API Client
// ------------------------------------------------------------------------------------------------
//
// [ApiClient] communicates with the EcoSort AI backend through the `http`
// package, which works across Android, desktop, and web builds.
// ------------------------------------------------------------------------------------------------

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/app_user.dart';
import '../models/chat_models.dart';
import '../models/eco_action.dart';
import '../models/eco_reward_models.dart';
import '../models/forum_post.dart';
import '../models/profile_history_models.dart';
import '../models/reward.dart';
import '../models/weather_info.dart';
import '../models/waste_category.dart';

/// Communicates with the EcoSort AI backend via HTTP.
class ApiClient {
  ApiClient({http.Client? httpClient, Duration? timeout})
      : _http = httpClient ?? http.Client(),
        _timeout = timeout ?? AppConfig.apiTimeout;

  final http.Client _http;
  final Duration _timeout;
  static String? _sharedAuthToken;

  String? get authToken => _sharedAuthToken;

  void setAuthToken(String? token) {
    _sharedAuthToken = token?.trim();
  }

  void clearAuthToken() {
    _sharedAuthToken = null;
  }

  Future<AuthSessionModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final body = await _postJson('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    }, includeAuth: false);
    final session = AuthSessionModel.fromJson(
      jsonDecode(body) as Map<String, dynamic>,
    );
    return session;
  }

  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    final body = await _postJson('/auth/login', {
      'email': email,
      'password': password,
    }, includeAuth: false);
    final session = AuthSessionModel.fromJson(
      jsonDecode(body) as Map<String, dynamic>,
    );
    setAuthToken(session.token);
    return session;
  }

  /// Closes the underlying HTTP client and releases resources.
  void dispose() {
    _http.close();
  }

  /// Fetches the full list of waste sorting categories.
  Future<List<WasteCategory>> fetchCategories() async {
    final body = await _get('/categories');
    final list = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
    return list
        .map((map) => WasteCategory.fromJson(map))
        .toList(growable: false);
  }

  /// Classifies [itemName] by asking the backend's keyword classifier.
  Future<ClassificationResult> classifyWaste(String itemName) async {
    final body = await _postJson('/classify', {'itemName': itemName});
    return ClassificationResult.fromJson(
      jsonDecode(body) as Map<String, dynamic>,
    );
  }

  /// Classifies waste from image bytes via backend cloud-vision endpoint.
  Future<ClassificationResult> classifyWasteImage({
    required Uint8List imageBytes,
    required String fileName,
    String? submittedBy,
  }) async {
    final body = await _postJson('/classify-image', {
      'imageBase64': base64Encode(imageBytes),
      'fileName': fileName,
      'submittedBy': submittedBy,
    });
    return ClassificationResult.fromJson(
      jsonDecode(body) as Map<String, dynamic>,
    );
  }

  /// Fetches the current user's profile.
  Future<AppUser> fetchProfile(String userId) async {
    final body = await _get('/profile');
    return AppUser.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }

  Future<AppUser> updateProfile({
    required String userId,
    required String name,
    required String email,
    required String city,
  }) async {
    final body = await _postJson('/profile/update', {
      'name': name,
      'email': email,
      'city': city,
    });
    return AppUser.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }

  Future<void> updateAvatar({
    required String userId,
    required String avatarUrl,
  }) async {
    await _postJson('/profile/avatar', {
      'avatarUrl': avatarUrl,
    });
  }

  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _postJson('/profile/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<List<RecognitionHistoryRecord>> fetchRecognitionHistory({
    required String userId,
    int limit = 50,
  }) async {
    final body = await _get('/profile/recognition-history?limit=$limit');
    final list = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
    return list
        .map(RecognitionHistoryRecord.fromJson)
        .toList(growable: false);
  }

  Future<List<PointHistoryRecord>> fetchPointHistory({
    required String userId,
    int limit = 50,
  }) async {
    final body = await _get('/profile/point-history?limit=$limit');
    final list = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
    return list.map(PointHistoryRecord.fromJson).toList(growable: false);
  }

  Future<List<BadgeHistoryRecord>> fetchBadgeHistory({
    required String userId,
    int limit = 50,
  }) async {
    final body = await _get('/profile/badge-history?limit=$limit');
    final list = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
    return list.map(BadgeHistoryRecord.fromJson).toList(growable: false);
  }

  Future<List<ForumPost>> fetchUserForumPosts({
    required String userId,
    int limit = 50,
  }) async {
    final body = await _get('/profile/forum-posts?limit=$limit');
    final list = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
    return list.map(ForumPost.fromJson).toList(growable: false);
  }

  /// Fetches the eco actions for the current user.
  Future<List<EcoAction>> fetchEcoActions(String userId) async {
    final body = await _get('/eco-actions');
    final list = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
    return list.map((map) => EcoAction.fromJson(map)).toList(growable: false);
  }

  /// Fetches the reward store items.
  Future<List<Reward>> fetchRewards() async {
    final body = await _get('/rewards');
    final list = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
    return list.map((map) => Reward.fromJson(map)).toList(growable: false);
  }

  /// Fetches community forum posts.
  Future<List<ForumPost>> fetchForumPosts() async {
    final body = await _get('/forum-posts');
    final list = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
    return list.map((map) => ForumPost.fromJson(map)).toList(growable: false);
  }

  /// Creates a new forum post.
  Future<ForumPost> createForumPost({
    required String authorId,
    required String title,
    required String content,
    required String tag,
  }) async {
    final body = await _postJson('/forum-posts', {
      'authorId': authorId,
      'title': title,
      'content': content,
      'tag': tag,
    });
    return ForumPost.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }

  /// Toggles like for one forum post.
  Future<ForumPost> toggleForumPostLike({
    required String postId,
    required String userId,
  }) async {
    final body = await _postJson('/forum-posts/$postId/like', {'userId': userId});
    return ForumPost.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }

  /// Fetches nested comments for one post.
  Future<List<ForumComment>> fetchForumComments({
    required String postId,
    required String userId,
  }) async {
    final body = await _get('/forum-posts/$postId/comments?userId=$userId');
    final list = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
    return list.map(ForumComment.fromJson).toList(growable: false);
  }

  /// Creates a comment or reply comment for one post.
  Future<ForumComment> createForumComment({
    required String postId,
    required String authorId,
    required String content,
    String? parentCommentId,
  }) async {
    final body = await _postJson('/forum-posts/$postId/comments', {
      'authorId': authorId,
      'content': content,
      if (parentCommentId != null && parentCommentId.trim().isNotEmpty)
        'parentCommentId': parentCommentId,
    });
    return ForumComment.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }

  /// Toggles like for one comment.
  Future<ForumComment> toggleForumCommentLike({
    required String commentId,
    required String userId,
  }) async {
    final body = await _postJson('/forum-comments/$commentId/like', {
      'userId': userId,
    });
    return ForumComment.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }

  /// Fetches chat conversation summaries for one user.
  Future<List<ChatConversationSummary>> fetchChatConversations({
    required String userId,
  }) async {
    final body = await _get('/chat/conversations');
    final list = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
    return list
        .map(ChatConversationSummary.fromJson)
        .toList(growable: false);
  }

  /// Creates (or returns) direct conversation id for two users.
  Future<String> getOrCreateDirectConversation({
    required String userId,
    required String peerUserId,
  }) async {
    final body = await _postJson('/chat/conversations/direct', {
      'peerUserId': peerUserId,
    });
    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['conversationId'] as String;
  }

  /// Fetches chat messages in ascending order.
  Future<List<ChatMessage>> fetchChatMessages({
    required String userId,
    required String conversationId,
    int? afterMessageId,
    int limit = 50,
  }) async {
    final afterPart = afterMessageId == null ? '' : '&afterMessageId=$afterMessageId';
    final body = await _get(
      '/chat/messages?conversationId=$conversationId&limit=$limit$afterPart',
    );
    final list = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
    return list.map(ChatMessage.fromJson).toList(growable: false);
  }

  /// Sends a text message.
  Future<ChatMessage> sendChatTextMessage({
    required String userId,
    required String conversationId,
    required String content,
  }) async {
    final body = await _postJson('/chat/messages/text', {
      'conversationId': conversationId,
      'content': content,
    });
    return ChatMessage.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }

  /// Sends an image message with URL payload.
  Future<ChatMessage> sendChatImageMessage({
    required String userId,
    required String conversationId,
    required String imageUrl,
  }) async {
    final body = await _postJson('/chat/messages/image', {
      'conversationId': conversationId,
      'imageUrl': imageUrl,
    });
    return ChatMessage.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }

  /// Marks one conversation as read for one user.
  Future<void> markChatConversationRead({
    required String userId,
    required String conversationId,
  }) async {
    await _postJson('/chat/conversations/read', {
      'conversationId': conversationId,
    });
  }

  /// Fetches eco-action evaluation catalog.
  Future<List<EcoActionCatalogItem>> fetchEcoActionCatalog() async {
    final body = await _get('/eco-action-catalog');
    final list = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
    return list
        .map((item) => EcoActionCatalogItem.fromJson(item))
        .toList(growable: false);
  }

  /// Fetches user eco-action evaluation history.
  Future<List<EcoActionRecord>> fetchEcoActionHistory({
    required String userId,
    int limit = 20,
  }) async {
    final body = await _get('/eco-actions/history?limit=$limit');
    final list = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
    return list
        .map((item) => EcoActionRecord.fromJson(item))
        .toList(growable: false);
  }

  /// Evaluates one eco behavior and awards points.
  Future<EcoActionEvaluationResult> evaluateEcoAction({
    required String userId,
    required String catalogActionId,
    required double quantity,
    String? note,
  }) async {
    final body = await _postJson('/eco-actions/evaluate', {
      'catalogActionId': catalogActionId,
      'quantity': quantity,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
    return EcoActionEvaluationResult.fromJson(
      jsonDecode(body) as Map<String, dynamic>,
    );
  }

  /// Fetches redeemable/redeemed badges for one user.
  Future<List<BadgeItem>> fetchBadges({required String userId}) async {
    final body = await _get('/badges');
    final list = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
    return list.map(BadgeItem.fromJson).toList(growable: false);
  }

  /// Redeems one badge.
  Future<BadgeRedeemResult> redeemBadge({
    required String userId,
    required String badgeId,
  }) async {
    final body = await _postJson('/badges/redeem', {
      'badgeId': badgeId,
    });
    return BadgeRedeemResult.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }

  /// Fetches eco reward dashboard summary.
  Future<EcoDashboard> fetchEcoDashboard({required String userId}) async {
    final body = await _get('/eco-dashboard');
    return EcoDashboard.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }

  /// Fetches live weather from AMap for the UK.
  ///
  /// AMap weather data may not cover overseas regions in all cases. When no
  /// live data is returned, this method throws [WeatherNoDataException].
  Future<WeatherInfo> fetchUkLiveWeather() async {
    final uri = Uri.https('restapi.amap.com', '/v3/weather/weatherInfo', {
      'city': AppConfig.ukWeatherCityQuery,
      'key': AppConfig.amapWeatherKey,
      'extensions': 'base',
    });

    final response = await _http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw http.ClientException(
        'GET AMap weather returned ${response.statusCode}',
        uri,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final status = json['status']?.toString() ?? '0';
    if (status != '1') {
      throw WeatherNoDataException(
        message: json['info']?.toString() ?? 'AMap weather request failed',
      );
    }

    final lives = (json['lives'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    if (lives.isEmpty) {
      throw const WeatherNoDataException(
        message: 'No live weather data is currently available for the UK.',
      );
    }

    final live = lives.first;
    return WeatherInfo(
      locationName: _pickValue(
        live,
        keys: const ['city', 'province'],
        fallback: AppConfig.ukWeatherCountryLabel,
      ),
      weather: _pickValue(live, keys: const ['weather'], fallback: 'Unknown'),
      temperatureCelsius: _pickValue(
        live,
        keys: const ['temperature', 'temperature_float'],
        fallback: '--',
      ),
      humidityPercent: _pickValue(
        live,
        keys: const ['humidity', 'humidity_float'],
        fallback: '--',
      ),
      windDirection: _pickValue(
        live,
        keys: const ['winddirection'],
        fallback: '--',
      ),
      windPower: _pickValue(live, keys: const ['windpower'], fallback: '--'),
      reportTime: _pickValue(live, keys: const ['reporttime'], fallback: '--'),
    );
  }

  Future<String> _get(String path, {bool includeAuth = true}) async {
    final uri = Uri.parse('${AppConfig.baseUrl}$path');
    final headers = <String, String>{'Accept': 'application/json'};
    if (includeAuth && _sharedAuthToken != null && _sharedAuthToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_sharedAuthToken';
    }
    final response = await _http.get(
      uri,
      headers: headers,
    ).timeout(_timeout);

    if (response.statusCode != 200) {
      throw http.ClientException(
          'GET $path returned ${response.statusCode}', uri);
    }

    return response.body;
  }

  Future<String> _postJson(
    String path,
    Map<String, dynamic> payload, {
    bool includeAuth = true,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (includeAuth && _sharedAuthToken != null && _sharedAuthToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_sharedAuthToken';
    }
    final response = await _http
        .post(
          uri,
          headers: headers,
          body: jsonEncode(payload),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw http.ClientException(
        'POST $path returned ${response.statusCode}',
        uri,
      );
    }

    return response.body;
  }

  String _pickValue(
    Map<String, dynamic> map, {
    required List<String> keys,
    required String fallback,
  }) {
    for (final key in keys) {
      final value = map[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return fallback;
  }
}

/// Exception used when weather request succeeds but has no usable live data.
class WeatherNoDataException implements Exception {
  const WeatherNoDataException({required this.message});

  final String message;

  @override
  String toString() => message;
}

class AuthSessionModel {
  const AuthSessionModel({
    required this.token,
    required this.expiresAt,
    required this.user,
  });

  final String token;
  final String expiresAt;
  final AppUser user;

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      token: json['token'] as String,
      expiresAt: json['expiresAt'] as String? ?? '',
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
