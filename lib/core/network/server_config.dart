import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

const String _configuredServerBaseUrl = String.fromEnvironment(
  'ENGLISH_AI_SERVER_BASE_URL',
);

String get serverBaseUrl {
  final configured = _normalizeBaseUrl(_configuredServerBaseUrl);
  if (configured != null) {
    return configured;
  }
  if (kIsWeb) {
    return 'http://127.0.0.1:8000';
  }
  try {
    if (Platform.isAndroid) {
      // Android real devices need an explicit host such as
      // --dart-define=ENGLISH_AI_SERVER_BASE_URL=http://192.168.x.x:8000.
      return 'http://10.0.2.2:8000';
    }
  } catch (_) {}
  return 'http://127.0.0.1:8000';
}

Uri serverWebSocketUri(String path) {
  final baseUri = Uri.parse(serverBaseUrl);
  final wsScheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
  return baseUri.replace(
    scheme: wsScheme,
    path: _joinUriPath(baseUri.path, path),
  );
}

String? _normalizeBaseUrl(String raw) {
  var normalized = raw.trim();
  if (normalized.isEmpty) {
    return null;
  }
  final parsed = Uri.tryParse(normalized);
  if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
    return null;
  }
  while (normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}

String _joinUriPath(String basePath, String path) {
  final trimmedBase = basePath.endsWith('/')
      ? basePath.substring(0, basePath.length - 1)
      : basePath;
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  if (trimmedBase.isEmpty || trimmedBase == '/') {
    return normalizedPath;
  }
  return '$trimmedBase$normalizedPath';
}
