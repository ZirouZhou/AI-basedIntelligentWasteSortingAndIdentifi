// ------------------------------------------------------------------------------------------------
// EcoSort AI Flutter App - REST API Client
// ------------------------------------------------------------------------------------------------
//
// [ApiClient] communicates with the EcoSort AI backend through the `http`
// package, which works across Android, desktop, and web builds.
// ------------------------------------------------------------------------------------------------

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/app_user.dart';
import '../models/eco_action.dart';
import '../models/forum_post.dart';
import '../models/message_thread.dart';
import '../models/reward.dart';
import '../models/waste_category.dart';

/// Communicates with the EcoSort AI backend via HTTP.
class ApiClient {
  ApiClient({http.Client? httpClient, Duration? timeout})
      : _http = httpClient ?? http.Client(),
        _timeout = timeout ?? AppConfig.apiTimeout;

  final http.Client _http;
  final Duration _timeout;

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

  /// Fetches the current user's profile.
  Future<AppUser> fetchProfile(String userId) async {
    final body = await _get('/profile');
    return AppUser.fromJson(jsonDecode(body) as Map<String, dynamic>);
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

  /// Fetches the message threads for the current user.
  Future<List<MessageThread>> fetchMessages(String userId) async {
    final body = await _get('/messages');
    final list = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
    return list
        .map((map) => MessageThread.fromJson(map))
        .toList(growable: false);
  }

  Future<String> _get(String path) async {
    final uri = Uri.parse('${AppConfig.baseUrl}$path');
    final response = await _http.get(
      uri,
      headers: {'Accept': 'application/json'},
    ).timeout(_timeout);

    if (response.statusCode != 200) {
      throw http.ClientException(
          'GET $path returned ${response.statusCode}', uri);
    }

    return response.body;
  }

  Future<String> _postJson(String path, Map<String, dynamic> payload) async {
    final uri = Uri.parse('${AppConfig.baseUrl}$path');
    final response = await _http
        .post(
          uri,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
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
}
