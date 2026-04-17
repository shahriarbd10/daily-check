import 'server_discovery_stub.dart'
    if (dart.library.io) 'server_discovery_io.dart' as impl;

Future<String?> discoverApiBaseUrl({
  int port = 5000,
  String apiPath = '/api',
}) {
  return impl.discoverApiBaseUrl(port: port, apiPath: apiPath);
}

