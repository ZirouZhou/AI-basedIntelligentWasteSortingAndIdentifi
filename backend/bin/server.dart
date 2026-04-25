// ------------------------------------------------------------------------------------------------
// EcoSort AI Backend — Application Entry Point
// ------------------------------------------------------------------------------------------------
//
// This file bootstraps the backend server for the EcoSort AI intelligent waste
// sorting platform. It reads the desired port number from the `PORT` environment
// variable (defaulting to 8080) and delegates all server setup to the
// [startServer] function defined in `lib/src/server.dart`.
//
// Run with:
//   dart run bin/server.dart
//   PORT=9090 dart run bin/server.dart  (custom port)
// ------------------------------------------------------------------------------------------------

import 'package:intelligent_waste_backend/src/server.dart';

/// Entry point of the EcoSort AI Backend application.
///
/// Reads the [PORT] environment variable and starts an HTTP server that exposes
/// the REST API endpoints used by the EcoSort mobile client.
Future<void> main(List<String> args) async {
  final port = int.tryParse(
        const String.fromEnvironment('PORT', defaultValue: '8080'),
      ) ??
      8080;

  await startServer(port: port);
}
