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
    final upload = _parseAuthorizeUpload(auth);
    final uploadUri = Uri.parse('https://${upload.bucket}.${upload.endpoint}/');

    final classicFields = <String, String>{
      'OSSAccessKeyId': upload.accessKeyId,
      'policy': upload.encodedPolicy,
      'Signature': upload.signature,
      'key': upload.objectKey,
      'success_action_status': '200',
      if (upload.securityToken.isNotEmpty)
        'x-oss-security-token': upload.securityToken,
    };

    final modernFields = <String, String>{
      'x-oss-access-key-id': upload.accessKeyId,
      'policy': upload.encodedPolicy,
      'signature': upload.signature,
      'key': upload.objectKey,
      'success_action_status': '200',
      if (upload.securityToken.isNotEmpty)
        'x-oss-security-token': upload.securityToken,
    };

    final classicAttempt = await _uploadToOss(
      uploadUri: uploadUri,
      fields: classicFields,
      imageBytes: imageBytes,
      fileName: fileName,
    );
    if (classicAttempt.ok) {
      return 'https://${upload.bucket}.${upload.endpoint}/${upload.objectKey}';
    }

    final modernAttempt = await _uploadToOss(
      uploadUri: uploadUri,
      fields: modernFields,
      imageBytes: imageBytes,
      fileName: fileName,
    );
    if (modernAttempt.ok) {
      return 'https://${upload.bucket}.${upload.endpoint}/${upload.objectKey}';
    }

    throw StateError(
      'OSS upload failed. '
      'classic=${classicAttempt.statusCode}:${classicAttempt.body} '
      'modern=${modernAttempt.statusCode}:${modernAttempt.body}',
    );
  }

  _AuthorizeUploadResult _parseAuthorizeUpload(Map<String, dynamic> auth) {
    Map<String, dynamic> data = const {};
    final rawData = auth['Data'];
    if (rawData is Map) {
      data = rawData.cast<String, dynamic>();
    }

    String pick(List<String> keys) {
      for (final key in keys) {
        final value = auth[key] ?? data[key];
        final text = value?.toString().trim() ?? '';
        if (text.isNotEmpty) {
          return text;
        }
      }
      return '';
    }

    final accessKeyId = pick(['AccessKeyId', 'OSSAccessKeyId']);
    final securityToken = pick(['SecurityToken', 'StsToken', 'Token']);
    final bucket = pick(['Bucket', 'OssBucket']);
    final endpoint = pick(['Endpoint', 'OssEndpoint']);
    final objectKey = pick(['ObjectKey', 'Key']);
    final encodedPolicy = pick(['EncodedPolicy', 'Policy', 'policy']);
    final signature = pick(['Signature', 'signature']);

    if (accessKeyId.isEmpty ||
        bucket.isEmpty ||
        endpoint.isEmpty ||
        objectKey.isEmpty ||
        encodedPolicy.isEmpty ||
        signature.isEmpty) {
      final topKeys = auth.keys.toList(growable: false)..sort();
      final dataKeys = data.keys.toList(growable: false)..sort();
      throw StateError(
        'AuthorizeFileUpload returned incomplete fields. '
        'topKeys=$topKeys dataKeys=$dataKeys',
      );
    }

    return _AuthorizeUploadResult(
      accessKeyId: accessKeyId,
      securityToken: securityToken,
      bucket: bucket,
      endpoint: endpoint,
      objectKey: objectKey,
      encodedPolicy: encodedPolicy,
      signature: signature,
    );
  }

  Future<_UploadAttempt> _uploadToOss({
    required Uri uploadUri,
    required Map<String, String> fields,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final boundary = '----EcoSortBoundary${_nonce()}';
    final bytes = _buildMultipartBody(
      boundary: boundary,
      fields: fields,
      imageBytes: imageBytes,
      fileName: _safeFileName(fileName),
    );

    final response = await _http.post(
      uploadUri,
      headers: {
        'Content-Type': 'multipart/form-data; boundary=$boundary',
        'Content-Length': bytes.length.toString(),
      },
      body: bytes,
    );
    final body = response.body;
    final ok =
        response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204;
    return _UploadAttempt(
      ok: ok,
      statusCode: response.statusCode,
      body: body,
    );
  }

  List<int> _buildMultipartBody({
    required String boundary,
    required Map<String, String> fields,
    required Uint8List imageBytes,
    required String fileName,
  }) {
    final builder = BytesBuilder();
    void writeText(String value) => builder.add(utf8.encode(value));

    for (final entry in fields.entries) {
      writeText('--$boundary\r\n');
      writeText('Content-Disposition: form-data; name="${entry.key}"\r\n\r\n');
      writeText('${entry.value}\r\n');
    }

    final contentType = _guessContentType(fileName);
    writeText('--$boundary\r\n');
    writeText(
      'Content-Disposition: form-data; name="file"; filename="$fileName"\r\n',
    );
    writeText('Content-Type: $contentType\r\n\r\n');
    builder.add(imageBytes);
    writeText('\r\n');
    writeText('--$boundary--\r\n');

    return builder.takeBytes();
  }

  String _guessContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.bmp')) {
      return 'image/bmp';
    }
    return 'image/jpeg';
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

    try {
      return await _callRpcWithMethod(
        endpoint: endpoint,
        method: 'POST',
        params: params,
      );
    } on _AliyunApiError catch (error) {
      // Some Aliyun RPC gateways only allow GET for specific actions.
      if (error.code == 'UnsupportedHTTPMethod') {
        return _callRpcWithMethod(
          endpoint: endpoint,
          method: 'GET',
          params: params,
        );
      }
      throw StateError('Aliyun API error [${error.code}]: ${error.message}');
    }
  }

  Future<Map<String, dynamic>> _callRpcWithMethod({
    required String endpoint,
    required String method,
    required Map<String, String> params,
  }) async {
    final upperMethod = method.toUpperCase();
    final signature = _sign(params, method: upperMethod);
    final allParams = <String, String>{...params, 'Signature': signature};

    late final http.Response response;
    if (upperMethod == 'GET') {
      final uri = Uri.parse('https://$endpoint/?${_formEncode(allParams)}');
      response = await _http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );
    } else if (upperMethod == 'POST') {
      response = await _http.post(
        Uri.https(endpoint, '/'),
        headers: const {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: _formEncode(allParams),
      );
    } else {
      throw StateError('Unsupported RPC method: $upperMethod');
    }

    final responseBody = response.body;
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Unexpected RPC response: $responseBody');
    }

    if (decoded.containsKey('Code') || response.statusCode >= 400) {
      final code = (decoded['Code'] ?? response.statusCode).toString();
      final message = (decoded['Message'] ?? 'Unknown error').toString();
      throw _AliyunApiError(code: code, message: message);
    }

    return decoded;
  }

  String _sign(Map<String, String> params, {required String method}) {
    final canonical = _canonicalQuery(params);
    final stringToSign =
        '${method.toUpperCase()}&%2F&${_percentEncode(canonical)}';
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

class _AliyunApiError implements Exception {
  const _AliyunApiError({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;
}

class _AuthorizeUploadResult {
  const _AuthorizeUploadResult({
    required this.accessKeyId,
    required this.securityToken,
    required this.bucket,
    required this.endpoint,
    required this.objectKey,
    required this.encodedPolicy,
    required this.signature,
  });

  final String accessKeyId;
  final String securityToken;
  final String bucket;
  final String endpoint;
  final String objectKey;
  final String encodedPolicy;
  final String signature;
}

class _UploadAttempt {
  const _UploadAttempt({
    required this.ok,
    required this.statusCode,
    required this.body,
  });

  final bool ok;
  final int statusCode;
  final String body;
}
