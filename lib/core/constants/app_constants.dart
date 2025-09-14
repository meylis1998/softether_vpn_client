class AppConstants {
  static const String appName = 'SoftEther VPN Client';
  static const String configsKey = 'vpn_configs';
  static const String lastConnectedConfigKey = 'last_connected_config';
  static const int connectionTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;
}

class VpnProtocolConstants {
  static const String l2tpIpsec = 'L2TP/IPSec';
  static const String openVpn = 'OpenVPN';
  static const String sslVpn = 'SSL-VPN';
}

class ErrorMessages {
  static const String connectionFailed = 'Failed to establish VPN connection';
  static const String configurationInvalid = 'Invalid VPN configuration';
  static const String networkUnavailable = 'Network connection unavailable';
  static const String permissionDenied = 'VPN permission denied';
  static const String configNotFound = 'Configuration not found';
  static const String generalError = 'An unexpected error occurred';
}