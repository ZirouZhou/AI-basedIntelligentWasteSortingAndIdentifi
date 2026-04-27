import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../config/aliyun_config.dart';
import '../models/vision_models.dart';

/// Thin Alibaba Cloud RPC client for OpenPlatform + ImageRecog APIs.
///
/// Flow used for local image recognition:
/// 1) `AuthorizeFileUpload` to obtain temporary upload policy
/// 2) Upload image bytes to OSS temp bucket
/// 3) `ClassifyingRubbish` with uploaded image URL
class AliyunVisionClient {
  AliyunVisionClient(this._config, {http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final AliyunConfig _config;
  final http.Client _http;

  void close() {
    _http.close();
  }

  String get _imageRecogEndpoint => 'imagerecog.${_config.regionId}.aliyuncs.com';

  Future<AliyunRubbishResponse> classifyRubbishByImageBytes({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final imageUrl = await _uploadImageToTempOss(
      imageBytes: imageBytes,
      fileName: fileName,
    );

    final payload = await _callRpc(
      endpoint: _imageRecogEndpoint,
      action: 'ClassifyingRubbish',
      version: '2019-09-30',
      extraParams: {
        'RegionId': _config.regionId,
        'ImageURL': imageUrl,
      },
    );

    final data = (payload['Data'] as Map?)?.cast<String, dynamic>() ?? const {};
    final elementsRaw =
        (data['Elements'] as List?)?.cast<Map>().map((item) => item.cast<String, dynamic>()).toList() ??
            const <Map<String, dynamic>>[];

    final elements = elementsRaw.map(AliyunRubbishElement.fromJson).toList(growable: false);
    return AliyunRubbishResponse(
      requestId: (payload['RequestId'] ?? '').toString(),
      sensitive: data['Sensitive'] == true,
      elements: elements,
      imageUrl: imageUrl,
      rawPayload: payload,
    );
  }

  Future<String> _uploadImageToTempOss({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final auth = await _callRpc(
      endpoint: 'openplatform.aliyuncs.com',
      action: 'AuthorizeFileUpload',
      version: '2019-12-19',
      extraParams: {
        'Product': 'imagerecog',
        'RegionId': _config.regionId,
      },
    );

    final accessKeyId = (auth['AccessKeyId'] ?? '').toString();
    final bucket = (auth['Bucket'] ?? '').toString();
    final endpoint = (auth['Endpoint'] ?? '').toString();
    final objectKey = (auth['ObjectKey'] ?? '').toString();
    final encodedPolicy = (auth['EncodedPolicy'] ?? '').toString();
    final signature = (auth['Signature'] ?? '').toString();

    if (accessKeyId.isEmpty ||
        bucket.isEmpty ||
        endpoint.isEmpty ||
        objectKey.isEmpty ||
        encodedPolicy.isEmpty ||
        signature.isEmpty) {
      throw StateError('AuthorizeFileUpload returned incomplete fields.');
    }

    final uploadUri = Uri.parse('http://$bucket.$endpoint/');
    final request = http.MultipartRequest('POST', uploadUri)
      ..fields['OSSAccessKeyId'] = accessKeyId
      ..fields['policy'] = encodedPolicy
      ..fields['Signature'] = signature
      ..fields['key'] = objectKey
      ..fields['success_action_status'] = '201'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: _safeFileName(fileName),
        ),
      );

    final streamed = await _http.send(request);
    if (streamed.statusCode != 201 && streamed.statusCode != 204) {
      final body = await streamed.stream.bytesToString();
      throw StateError(
        'OSS upload failed with status ${streamed.statusCode}: $body',
      );
    }

    return 'http://$bucket.$endpoint/$objectKey';
  }

  Future<Map<String, dynamic>> _callRpc({
    required String endpoint,
    required String action,
    required String version,
    required Map<String, String> extraParams,
  }) async {
    final params = <String, String>{
      'Action': action,
      'Format': 'JSON',
      'Version': version,
      'AccessKeyId': _config.accessKeyId,
      'SignatureMethod': 'HMAC-SHA1',
      'Timestamp': _iso8601NowUtc(),
      'SignatureVersion': '1.0',
      'SignatureNonce': _nonce(),
      ...extraParams,
    };

    final signature = _sign(params);
    final allParams = <String, String>{
      ...params,
      'Signature': signature,
    };

    final response = await _http.post(
      Uri.https(endpoint, '/'),
      headers: const {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: _formEncode(allParams),
    );

    final responseBody = response.body;
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Unexpected RPC response: $responseBody');
    }

    if (decoded.containsKey('Code') || response.statusCode >= 400) {
      final code = (decoded['Code'] ?? response.statusCode).toString();
      final message = (decoded['Message'] ?? 'Unknown error').toString();
      throw StateError('Aliyun API error [$code]: $message');
    }

    return decoded;
  }

  String _sign(Map<String, String> params) {
    final canonical = _canonicalQuery(params);
    final stringToSign = 'POST&%2F&${_percentEncode(canonical)}';
    final key = utf8.encode('${_config.accessKeySecret}&');
    final digest = Hmac(sha1, key).convert(utf8.encode(stringToSign));
    return base64Encode(digest.bytes);
  }

  String _canonicalQuery(Map<String, String> params) {
    final keys = params.keys.toList()..sort();
    return keys
        .map((key) => '${_percentEncode(key)}=${_percentEncode(params[key] ?? '')}')
        .join('&');
  }

  String _formEncode(Map<String, String> params) {
    final keys = params.keys.toList()..sort();
    return keys
        .map((key) => '${_percentEncode(key)}=${_percentEncode(params[key] ?? '')}')
        .join('&');
  }

  String _percentEncode(String value) {
    return Uri.encodeQueryComponent(value)
        .replaceAll('+', '%20')
        .replaceAll('*', '%2A')
        .replaceAll('%7E', '~');
  }

  String _iso8601NowUtc() {
    return DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceFirst(RegExp(r'\.\d+Z$'), 'Z');
  }

  String _nonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final buffer = StringBuffer();
    for (final b in bytes) {
      buffer.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  String _safeFileName(String original) {
    final trimmed = original.trim();
    if (trimmed.isEmpty) {
      return 'upload.jpg';
    }
    return trimmed.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }
}
