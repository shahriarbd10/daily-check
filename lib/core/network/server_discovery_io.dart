import 'dart:async';
import 'dart:io';

bool _isPrivateV4(String ip) {
  if (ip.startsWith('10.')) return true;
  if (ip.startsWith('192.168.')) return true;
  if (ip.startsWith('172.')) {
    final parts = ip.split('.');
    if (parts.length > 1) {
      final second = int.tryParse(parts[1]) ?? -1;
      return second >= 16 && second <= 31;
    }
  }
  return false;
}

String? _prefixOf(String ip) {
  final parts = ip.split('.');
  if (parts.length != 4) return null;
  return '${parts[0]}.${parts[1]}.${parts[2]}';
}

Future<bool> _probeHealth(String host, int port) async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(milliseconds: 350);
  try {
    final uri = Uri.parse('http://$host:$port/api/health');
    final request = await client.getUrl(uri).timeout(
      const Duration(milliseconds: 350),
    );
    final response = await request.close().timeout(
      const Duration(milliseconds: 450),
    );
    return response.statusCode == 200;
  } catch (_) {
    return false;
  } finally {
    client.close(force: true);
  }
}

Future<String?> _scanSubnetPrefix(
  String prefix,
  int port, {
  String apiPath = '/api',
}) async {
  final preferred = <int>[1, 2, 10, 20, 50, 100, 101, 150, 162, 200, 254];
  for (final octet in preferred) {
    final host = '$prefix.$octet';
    if (await _probeHealth(host, port)) {
      return 'http://$host:$port$apiPath';
    }
  }

  // Full fallback scan in batches for robust device-network auto detection.
  const batchSize = 24;
  for (var start = 1; start <= 254; start += batchSize) {
    final end = (start + batchSize - 1).clamp(1, 254);
    final futures = <Future<MapEntry<String, bool>>>[];
    for (var i = start; i <= end; i++) {
      final host = '$prefix.$i';
      futures.add(
        _probeHealth(host, port).then((ok) => MapEntry(host, ok)),
      );
    }
    final results = await Future.wait(futures);
    for (final result in results) {
      if (result.value) {
        return 'http://${result.key}:$port$apiPath';
      }
    }
  }
  return null;
}

Future<String?> discoverApiBaseUrl({
  int port = 5000,
  String apiPath = '/api',
}) async {
  // Emulator/common local candidates first.
  final commonHosts = <String>[
    '10.0.2.2',
    '127.0.0.1',
    'localhost',
  ];
  for (final host in commonHosts) {
    if (await _probeHealth(host, port)) {
      return 'http://$host:$port$apiPath';
    }
  }

  final interfaces = await NetworkInterface.list(
    includeLoopback: false,
    type: InternetAddressType.IPv4,
  );
  final prefixes = <String>{};
  for (final iface in interfaces) {
    for (final addr in iface.addresses) {
      final ip = addr.address;
      if (!_isPrivateV4(ip)) continue;
      final prefix = _prefixOf(ip);
      if (prefix != null) prefixes.add(prefix);
    }
  }

  for (final prefix in prefixes) {
    final found = await _scanSubnetPrefix(prefix, port, apiPath: apiPath);
    if (found != null) return found;
  }

  return null;
}

