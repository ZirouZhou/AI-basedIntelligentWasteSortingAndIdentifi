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
import '../models/eco_action.dart';
import '../models/eco_reward_models.dart';
import '../models/forum_post.dart';
import '../models/message_thread.dart';
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
    final body = await _get('/eco-actions/history?userId=$userId&limit=$limit');
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
      'userId': userId,
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
    final body = await _get('/badges?userId=$userId');
    final list = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
    return list.map(BadgeItem.fromJson).toList(growable: false);
  }

  /// Redeems one badge.
  Future<BadgeRedeemResult> redeemBadge({
    required String userId,
    required String badgeId,
  }) async {
    final body = await _postJson('/badges/redeem', {
      'userId': userId,
      'badgeId': badgeId,
    });
    return BadgeRedeemResult.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }

  /// Fetches eco reward dashboard summary.
  Future<EcoDashboard> fetchEcoDashboard({required String userId}) async {
    final body = await _get('/eco-dashboard?userId=$userId');
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
