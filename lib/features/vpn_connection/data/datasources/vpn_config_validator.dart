class VpnConfigValidator {
  static bool validateOpenVPNConfig(String? config) {
    if (config == null || config.trim().isEmpty) {
      return false;
    }

    // Check for essential OpenVPN directives
    final lines = config.split('\n');
    bool hasClient = false;
    bool hasRemote = false;
    bool hasProto = false;

    for (final line in lines) {
      final trimmed = line.trim().toLowerCase();
      if (trimmed.startsWith('client')) hasClient = true;
      if (trimmed.startsWith('remote ')) hasRemote = true;
      if (trimmed.startsWith('proto ')) hasProto = true;
    }

    return hasClient && hasRemote && hasProto;
  }

  static String? getOpenVPNValidationError(String? config) {
    if (config == null || config.trim().isEmpty) {
      return 'OpenVPN configuration is empty';
    }

    final lines = config.split('\n');
    bool hasClient = false;
    bool hasRemote = false;
    bool hasProto = false;

    for (final line in lines) {
      final trimmed = line.trim().toLowerCase();
      if (trimmed.startsWith('client')) hasClient = true;
      if (trimmed.startsWith('remote ')) hasRemote = true;
      if (trimmed.startsWith('proto ')) hasProto = true;
    }

    if (!hasClient) return 'Missing "client" directive in OpenVPN config';
    if (!hasRemote) return 'Missing "remote" directive in OpenVPN config';
    if (!hasProto) return 'Missing "proto" directive in OpenVPN config';

    return null; // Valid config
  }

  static bool validateL2TPConfig(String server, String username, String password) {
    if (server.trim().isEmpty) return false;
    if (username.trim().isEmpty) return false;
    if (password.trim().isEmpty) return false;

    // Basic server validation (should be IP or domain)
    final serverRegex = RegExp(r'^[a-zA-Z0-9.-]+$');
    return serverRegex.hasMatch(server);
  }

  static String? getL2TPValidationError(String server, String username, String password) {
    if (server.trim().isEmpty) return 'Server address is required';
    if (username.trim().isEmpty) return 'Username is required';
    if (password.trim().isEmpty) return 'Password is required';

    final serverRegex = RegExp(r'^[a-zA-Z0-9.-]+$');
    if (!serverRegex.hasMatch(server)) {
      return 'Invalid server address format';
    }

    return null; // Valid config
  }
}