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
    final fileEnv = _readDotEnvFile();
    String? pick(String key) {
      final fromProcess = env[key]?.trim();
      if (fromProcess != null && fromProcess.isNotEmpty) {
        return fromProcess;
      }
      final fromFile = fileEnv[key]?.trim();
      if (fromFile != null && fromFile.isNotEmpty) {
        return fromFile;
      }
      return null;
    }

    final regionId = pick('ALIYUN_REGION_ID') ?? 'cn-shanghai';
    return AliyunConfig(
      accessKeyId: pick('ALIYUN_ACCESS_KEY_ID') ?? '',
      accessKeySecret: pick('ALIYUN_ACCESS_KEY_SECRET') ?? '',
      regionId: regionId,
    );
  }

  bool get isConfigured =>
      accessKeyId.trim().isNotEmpty && accessKeySecret.trim().isNotEmpty;
}

Map<String, String> _readDotEnvFile() {
  final cwdFile = File('.env.local');
  final backendFile = File('backend/.env.local');
  final target = cwdFile.existsSync()
      ? cwdFile
      : (backendFile.existsSync() ? backendFile : null);
  if (target == null) {
    return const <String, String>{};
  }

  final lines = target.readAsLinesSync();
  final env = <String, String>{};
  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }
    final index = line.indexOf('=');
    if (index <= 0) {
      continue;
    }
    final key = line.substring(0, index).trim();
    var value = line.substring(index + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      if (value.length >= 2) {
        value = value.substring(1, value.length - 1);
      }
    }
    if (key.isNotEmpty) {
      env[key] = value;
    }
  }
  return env;
}
