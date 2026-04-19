import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/app_user.dart';
import '../models/eco_action.dart';
import '../models/forum_post.dart';
import '../models/message_thread.dart';
import '../models/reward.dart';
import '../models/waste_category.dart';

class ApiClient {
  ApiClient({
    this.baseUrl = AppConfig.apiBaseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  void dispose() {
    _httpClient.close();
  }

  Future<List<WasteCategory>> fetchCategories() async {
    final json = await _getJsonList('/categories');
    return json.map(WasteCategory.fromJson).toList();
  }

  Future<ClassificationResult> classifyWaste(String itemName) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/classify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'itemName': itemName}),
    );
    final json = _decodeJsonObject(response);
    return ClassificationResult.fromJson(json);
  }

  Future<List<EcoAction>> fetchEcoActions() async {
    final json = await _getJsonList('/eco-actions');
    return json.map(EcoAction.fromJson).toList();
  }

  Future<List<Reward>> fetchRewards() async {
    final json = await _getJsonList('/rewards');
    return json.map(Reward.fromJson).toList();
  }

  Future<List<ForumPost>> fetchForumPosts() async {
    final json = await _getJsonList('/forum-posts');
    return json.map(ForumPost.fromJson).toList();
  }

  Future<List<MessageThread>> fetchMessages() async {
    final json = await _getJsonList('/messages');
    return json.map(MessageThread.fromJson).toList();
  }

  Future<AppUser> fetchProfile() async {
    final response = await _httpClient.get(Uri.parse('$baseUrl/profile'));
    return AppUser.fromJson(_decodeJsonObject(response));
  }

  Future<List<Map<String, dynamic>>> _getJsonList(String path) async {
    final response = await _httpClient.get(Uri.parse('$baseUrl$path'));
    final decoded = _decodeResponse(response);
    if (decoded is! List) {
      throw ApiException('Expected a JSON list from $path.');
    }
    return decoded.cast<Map<String, dynamic>>();
  }

  Map<String, dynamic> _decodeJsonObject(http.Response response) {
    final decoded = _decodeResponse(response);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Expected a JSON object.');
    }
    return decoded;
  }

  Object? _decodeResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'Request failed with status ${response.statusCode}: ${response.body}',
      );
    }
    return jsonDecode(response.body);
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => 'ApiException: $message';
}
