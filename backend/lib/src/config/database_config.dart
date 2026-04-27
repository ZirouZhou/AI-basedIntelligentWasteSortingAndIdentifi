import 'dart:io';

import 'package:mysql1/mysql1.dart';

/// Database connection settings for MySQL.
///
/// Values are loaded from environment variables first, then fall back to the
/// project defaults provided by the user.
class DatabaseConfig {
  const DatabaseConfig({
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.database,
    required this.charset,
  });

  /// MySQL server host.
  final String host;

  /// MySQL server port.
  final int port;

  /// Username used for authentication.
  final String user;

  /// Password used for authentication.
  final String password;

  /// Target database schema name.
  final String database;

  /// Character set used by schema and connections.
  final String charset;

  /// Builds config from environment variables with sensible defaults.
  ///
  /// Supported variables:
  /// - `DB_HOST`
  /// - `DB_PORT`
  /// - `DB_USER`
  /// - `DB_PASSWORD`
  /// - `DB_NAME`
  /// - `DB_CHARSET`
  factory DatabaseConfig.fromEnvironment() {
    final env = Platform.environment;

    return DatabaseConfig(
      host: env['DB_HOST'] ?? 'localhost',
      port: int.tryParse(env['DB_PORT'] ?? '') ?? 3308,
      user: env['DB_USER'] ?? 'root',
      password: env['DB_PASSWORD'] ?? '123456',
      database:
          env['DB_NAME'] ??
          '20260419_ai_intelligent_waste_sorting_identification_app',
      charset: env['DB_CHARSET'] ?? 'utf8',
    );
  }

  /// Builds a connection settings object for schema-level operations.
  ///
  /// Use this for creating the database itself (`CREATE DATABASE ...`), where
  /// no default schema should be pre-selected.
  ConnectionSettings toServerConnectionSettings() {
    return ConnectionSettings(
      host: host,
      port: port,
      user: user,
      password: password,
    );
  }

  /// Builds a connection settings object for normal app queries.
  ConnectionSettings toDatabaseConnectionSettings() {
    return ConnectionSettings(
      host: host,
      port: port,
      user: user,
      password: password,
      db: database,
    );
  }
}
