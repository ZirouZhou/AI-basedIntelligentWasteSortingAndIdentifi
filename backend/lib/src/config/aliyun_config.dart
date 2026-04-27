import 'dart:io';

/// Runtime config for Alibaba Cloud Image Recognition integration.
///
/// Credentials are intentionally read from environment variables instead of
/// source code to avoid leaking secrets into version control.
class AliyunConfig {
  const AliyunConfig({
    required this.accessKeyId,
    required this.accessKeySecret,
    required this.regionId,
  });

  final String accessKeyId;
  final String accessKeySecret;
  final String regionId;

  factory AliyunConfig.fromEnvironment() {
    final env = Platform.environment;
    final regionId = env['ALIYUN_REGION_ID'] ?? 'cn-shanghai';
    return AliyunConfig(
      accessKeyId: env['ALIYUN_ACCESS_KEY_ID'] ?? '',
      accessKeySecret: env['ALIYUN_ACCESS_KEY_SECRET'] ?? '',
      regionId: regionId,
    );
  }

  bool get isConfigured =>
      accessKeyId.trim().isNotEmpty && accessKeySecret.trim().isNotEmpty;
}

