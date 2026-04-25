// ------------------------------------------------------------------------------------------------
// EcoSort AI Flutter App — REST API Client
// ------------------------------------------------------------------------------------------------
//
// [ApiClient] is a lightweight HTTP client that communicates with the EcoSort
// AI backend. It uses Dart's built-in [HttpClient] (via the `dart:io` library)
// to avoid extra package dependencies.
//
// Endpoints consumed:
//   GET  /api/categories          – list of waste categories
//   GET  /api/classify?q=<item>   – classify a waste item
//   GET  /api/user/:id/profile    – user profile data
//   GET  /api/eco-actions/:userId – eco actions for a user
//   GET  /api/rewards             – reward store items
//   GET  /api/forum/posts         – community forum posts
//   GET  /api/messages/:userId    – user's message threads
//
// Every method returns a domain model instance parsed from the JSON response.
// Network errors are caught by callers (e.g. in [ClassifyPage]) to trigger
// the local fallback path.
// ------------------------------------------------------------------------------------------------

import 'dart:convert';
import 'dart:io';

import '../config/app_config.dart';
import '../models/app_user.dart';
import '../models/eco_action.dart';
import '../models/forum_post.dart';
import '../models/message_thread.dart';
import '../models/reward.dart';
import '../models/waste_category.dart';

/// Communicates with the EcoSort AI backend via HTTP.
///
/// Instantiate once and reuse for the lifecycle of the app. Call [dispose]
/// when the client is no longer needed to free resources.
class ApiClient {
  final HttpClient _http = HttpClient();
  final Duration _timeout;

  /// Creates an [ApiClient] with an optional per-request [timeout].
  ///
  /// Defaults to [AppConfig.apiTimeout] (5 seconds).
  ApiClient({Duration? timeout}) : _timeout = timeout ?? AppConfig.apiTimeout;

  /// Closes the underlying HTTP client and releases resources.
  void dispose() {
    _http.close();
  }

  // ----------------------------------------------------------------------------------------------
  // Public API methods
  // ----------------------------------------------------------------------------------------------

  /// Fetches the full list of waste sorting categories.
  Future<List<WasteCategory>> fetchCategories() async {
    final body = await _get('/api/categories');
    final list = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
    return list
        .map((map) => WasteCategory.fromJson(map))
        .toList(growable: false);
  }

  /// Classifies [itemName] by asking the backend's keyword classifier.
  ///
  /// Returns a [ClassificationResult] that includes the predicted category,
  /// confidence score, and disposal suggestions.
  Future<ClassificationResult> classifyWaste(String itemName) async {
    final encoded = Uri.encodeQueryComponent(itemName);
    final body = await _get('/api/classify?q=$encoded');
    return ClassificationResult.fromJson(
      jsonDecode(body) as Map<String, dynamic>,
    );
  }

  /// Fetches the profile for the user with the given [userId].
  Future<AppUser> fetchProfile(String userId) async {
    final body = await _get('/api/user/$userId/profile');
    return AppUser.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }

  /// Fetches the eco actions for a specific user.
  Future<List<EcoAction>> fetchEcoActions(String userId) async {
    final body = await _get('/api/eco-actions/$userId');
    final list = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
    return list
        .map((map) => EcoAction.fromJson(map))
        .toList(growable: false);
  }

  /// Fetches the reward store items.
  Future<List<Reward>> fetchRewards() async {
    final body = await _get('/api/rewards');
    final list = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
    return list
        .map((map) => Reward.fromJson(map))
        .toList(growable: false);
  }

  /// Fetches community forum posts.
  Future<List<ForumPost>> fetchForumPosts() async {
    final body = await _get('/api/forum/posts');
    final list = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
    return list
        .map((map) => ForumPost.fromJson(map))
        .toList(growable: false);
  }

  /// Fetches the message threads for a specific user.
  Future<List<MessageThread>> fetchMessages(String userId) async {
    final body = await _get('/api/messages/$userId');
    final list = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
    return list
        .map((map) => MessageThread.fromJson(map))
        .toList(growable: false);
  }

  // ----------------------------------------------------------------------------------------------
  // Internal helpers
  // ----------------------------------------------------------------------------------------------

  /// Performs an HTTP GET request to [path] on the configured [AppConfig.baseUrl].
  ///
  /// Throws on network errors, non-200 status codes, or timeout.
  Future<String> _get(String path) async {
    final uri = Uri.parse('${AppConfig.baseUrl}$path');
    final request = await _http.getUrl(uri);
    request.headers.set('Accept', 'application/json');
    final response = await request.close().timeout(_timeout);

    if (response.statusCode != 200) {
      throw HttpException(
        'GET $path returned ${response.statusCode}',
        uri: uri,
      );
    }

    return response.transform(utf8.decoder).join();
  }
}
