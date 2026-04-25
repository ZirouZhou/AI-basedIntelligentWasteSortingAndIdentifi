// ------------------------------------------------------------------------------------------------
// EcoSort AI Backend — Server Setup & Middleware
// ------------------------------------------------------------------------------------------------
//
// This module assembles the HTTP server using the [shelf] package. It:
//   1. Seeds a [WasteDataService] with canned demo data (see [WasteDataService.seeded]).
//   2. Builds a [shelf_router] via [buildRouter] that maps URL paths to handlers.
//   3. Wraps the router in a pipeline that adds request logging and CORS headers.
//   4. Starts listening on `0.0.0.0:<port>` so the mobile frontend can reach it.
// ------------------------------------------------------------------------------------------------

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'routes.dart';
import 'services/waste_data_service.dart';

/// Starts the EcoSort HTTP server on the given [port].
///
/// Creates a [WasteDataService] with demo data, wires it into the router, and
/// serves requests on all network interfaces (`0.0.0.0`).
Future<void> startServer({required int port}) async {
  final service = WasteDataService.seeded();
  final router = buildRouter(service);
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware())
      .addHandler(router.call);

  final server = await shelf_io.serve(handler, '0.0.0.0', port);
  // ignore: avoid_print
  print('EcoSort backend running at http://${server.address.host}:${server.port}');
}

/// Returns a [Middleware] that adds permissive CORS headers to every response.
///
/// This allows the Flutter mobile client (running on a different origin) to
/// call the backend APIs without being blocked by the browser / WebView.
Middleware _corsMiddleware() {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
  };

  return (innerHandler) {
    return (request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: headers);
      }

      final response = await innerHandler(request);
      return response.change(headers: {
        ...response.headers,
        ...headers,
      });
    };
  };
}
