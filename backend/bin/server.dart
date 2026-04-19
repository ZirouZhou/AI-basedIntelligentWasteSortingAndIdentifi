import 'package:intelligent_waste_backend/src/server.dart';

Future<void> main(List<String> args) async {
  final port = int.tryParse(
        const String.fromEnvironment('PORT', defaultValue: '8080'),
      ) ??
      8080;

  await startServer(port: port);
}
