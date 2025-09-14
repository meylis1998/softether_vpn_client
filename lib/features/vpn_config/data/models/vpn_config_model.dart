import 'package:equatable/equatable.dart';
import '../../domain/entities/vpn_config.dart';

class VpnConfigModel extends Equatable {
  final String id;
  final String name;
  final String serverAddress;
  final int serverPort;
  final String protocol;
  final String username;
  final String password;
  final String? presharedKey;
  final String? hubName;
  final String? ovpnConfig;
  final bool autoConnect;
  final DateTime? createdAt;
  final DateTime? lastConnectedAt;

  const VpnConfigModel({
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

  factory VpnConfigModel.fromJson(Map<String, dynamic> json) {
    return VpnConfigModel(
      id: json['id'] as String,
      name: json['name'] as String,
      serverAddress: json['serverAddress'] as String,
      serverPort: json['serverPort'] as int,
      protocol: json['protocol'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      presharedKey: json['presharedKey'] as String?,
      hubName: json['hubName'] as String?,
      ovpnConfig: json['ovpnConfig'] as String?,
      autoConnect: json['autoConnect'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      lastConnectedAt: json['lastConnectedAt'] != null
          ? DateTime.parse(json['lastConnectedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'serverAddress': serverAddress,
      'serverPort': serverPort,
      'protocol': protocol,
      'username': username,
      'password': password,
      'presharedKey': presharedKey,
      'hubName': hubName,
      'ovpnConfig': ovpnConfig,
      'autoConnect': autoConnect,
      'createdAt': createdAt?.toIso8601String(),
      'lastConnectedAt': lastConnectedAt?.toIso8601String(),
    };
  }

  factory VpnConfigModel.fromEntity(VpnConfig entity) {
    return VpnConfigModel(
      id: entity.id,
      name: entity.name,
      serverAddress: entity.serverAddress,
      serverPort: entity.serverPort,
      protocol: entity.protocol.identifier,
      username: entity.username,
      password: entity.password,
      presharedKey: entity.presharedKey,
      hubName: entity.hubName,
      ovpnConfig: entity.ovpnConfig,
      autoConnect: entity.autoConnect,
      createdAt: entity.createdAt,
      lastConnectedAt: entity.lastConnectedAt,
    );
  }

  VpnConfig toEntity() {
    return VpnConfig(
      id: id,
      name: name,
      serverAddress: serverAddress,
      serverPort: serverPort,
      protocol: _parseProtocol(protocol),
      username: username,
      password: password,
      presharedKey: presharedKey,
      hubName: hubName,
      ovpnConfig: ovpnConfig,
      autoConnect: autoConnect,
      createdAt: createdAt,
      lastConnectedAt: lastConnectedAt,
    );
  }

  VpnProtocol _parseProtocol(String protocolString) {
    return VpnProtocol.values.firstWhere(
      (e) => e.identifier == protocolString,
      orElse: () => VpnProtocol.l2tpIpsec,
    );
  }

  VpnConfigModel copyWith({
    String? id,
    String? name,
    String? serverAddress,
    int? serverPort,
    String? protocol,
    String? username,
    String? password,
    String? presharedKey,
    String? hubName,
    String? ovpnConfig,
    bool? autoConnect,
    DateTime? createdAt,
    DateTime? lastConnectedAt,
  }) {
    return VpnConfigModel(
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