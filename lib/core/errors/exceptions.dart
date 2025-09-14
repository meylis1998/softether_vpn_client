class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
}

class VpnConnectionException implements Exception {
  final String message;
  const VpnConnectionException(this.message);
}

class ConfigurationException implements Exception {
  final String message;
  const ConfigurationException(this.message);
}

class PermissionException implements Exception {
  final String message;
  const PermissionException(this.message);
}