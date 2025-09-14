import 'package:equatable/equatable.dart';

enum VpnProtocol {
  l2tpIpsec,
  openVpn,
  sslVpn,
}

extension VpnProtocolExtension on VpnProtocol {
  String get displayName {
    switch (this) {
      case VpnProtocol.l2tpIpsec:
        return 'L2TP/IPSec';
      case VpnProtocol.openVpn:
        return 'OpenVPN';
      case VpnProtocol.sslVpn:
        return 'SSL-VPN';
    }
  }

  String get identifier {
    switch (this) {
      case VpnProtocol.l2tpIpsec:
        return 'l2tp_ipsec';
      case VpnProtocol.openVpn:
        return 'openvpn';
      case VpnProtocol.sslVpn:
        return 'ssl_vpn';
    }
  }
}

class VpnConfig extends Equatable {
  final String id;
  final String name;
  final String serverAddress;
  final int serverPort;
  final VpnProtocol protocol;
  final String username;
  final String password;
  final String? presharedKey;
  final String? hubName;
  final String? ovpnConfig;
  final bool autoConnect;
  final DateTime? createdAt;
  final DateTime? lastConnectedAt;

  const VpnConfig({
    required this.id,
    required this.name,
    required this.serverAddress,
    required this.serverPort,
    required this.protocol,
    required this.username,
    required this.password,
    this.presharedKey,
    this.hubName,
    this.ovpnConfig,
    this.autoConnect = false,
    this.createdAt,
    this.lastConnectedAt,
  });

  VpnConfig copyWith({
    String? id,
    String? name,
    String? serverAddress,
    int? serverPort,
    VpnProtocol? protocol,
    String? username,
    String? password,
    String? presharedKey,
    String? hubName,
    String? ovpnConfig,
    bool? autoConnect,
    DateTime? createdAt,
    DateTime? lastConnectedAt,
  }) {
    return VpnConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      serverAddress: serverAddress ?? this.serverAddress,
      serverPort: serverPort ?? this.serverPort,
      protocol: protocol ?? this.protocol,
      username: username ?? this.username,
      password: password ?? this.password,
      presharedKey: presharedKey ?? this.presharedKey,
      hubName: hubName ?? this.hubName,
      ovpnConfig: ovpnConfig ?? this.ovpnConfig,
      autoConnect: autoConnect ?? this.autoConnect,
      createdAt: createdAt ?? this.createdAt,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        serverAddress,
        serverPort,
        protocol,
        username,
        password,
        presharedKey,
        hubName,
        ovpnConfig,
        autoConnect,
        createdAt,
        lastConnectedAt,
      ];
}