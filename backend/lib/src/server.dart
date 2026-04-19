import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'routes.dart';
import 'services/waste_data_service.dart';

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
