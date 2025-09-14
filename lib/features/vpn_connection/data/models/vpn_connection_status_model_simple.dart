import 'package:equatable/equatable.dart';
import '../../domain/entities/vpn_connection_status.dart';

class VpnConnectionStatusModel extends Equatable {
  final String status;
  final String? configId;
  final String? configName;
  final String? errorMessage;
  final DateTime? connectedAt;
  final String? ipAddress;
  final int? bytesReceived;
  final int? bytesSent;
  final int? durationSeconds;

  const VpnConnectionStatusModel({
    required this.status,
    this.configId,
    this.configName,
    this.errorMessage,
    this.connectedAt,
    this.ipAddress,
    this.bytesReceived,
    this.bytesSent,
    this.durationSeconds,
  });

  factory VpnConnectionStatusModel.fromJson(Map<String, dynamic> json) {
    return VpnConnectionStatusModel(
      status: json['status'] as String,
      configId: json['configId'] as String?,
      configName: json['configName'] as String?,
      errorMessage: json['errorMessage'] as String?,
      connectedAt: json['connectedAt'] != null
          ? DateTime.parse(json['connectedAt'] as String)
          : null,
      ipAddress: json['ipAddress'] as String?,
      bytesReceived: json['bytesReceived'] as int?,
      bytesSent: json['bytesSent'] as int?,
      durationSeconds: json['durationSeconds'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'configId': configId,
      'configName': configName,
      'errorMessage': errorMessage,
      'connectedAt': connectedAt?.toIso8601String(),
      'ipAddress': ipAddress,
      'bytesReceived': bytesReceived,
      'bytesSent': bytesSent,
      'durationSeconds': durationSeconds,
    };
  }

  factory VpnConnectionStatusModel.fromEntity(VpnConnectionStatus entity) {
    return VpnConnectionStatusModel(
      status: entity.status.name,
      configId: entity.configId,
      configName: entity.configName,
      errorMessage: entity.errorMessage,
      connectedAt: entity.connectedAt,
      ipAddress: entity.ipAddress,
      bytesReceived: entity.bytesReceived,
      bytesSent: entity.bytesSent,
      durationSeconds: entity.duration?.inSeconds,
    );
  }

  VpnConnectionStatus toEntity() {
    return VpnConnectionStatus(
      status: _parseStatus(status),
      configId: configId,
      configName: configName,
      errorMessage: errorMessage,
      connectedAt: connectedAt,
      ipAddress: ipAddress,
      bytesReceived: bytesReceived,
      bytesSent: bytesSent,
      duration: durationSeconds != null ? Duration(seconds: durationSeconds!) : null,
    );
  }

  VpnStatus _parseStatus(String statusString) {
    return VpnStatus.values.firstWhere(
      (e) => e.name == statusString,
      orElse: () => VpnStatus.disconnected,
    );
  }

  VpnConnectionStatusModel copyWith({
    String? status,
    String? configId,
    String? configName,
    String? errorMessage,
    DateTime? connectedAt,
    String? ipAddress,
    int? bytesReceived,
    int? bytesSent,
    int? durationSeconds,
  }) {
    return VpnConnectionStatusModel(
      status: status ?? this.status,
      configId: configId ?? this.configId,
      configName: configName ?? this.configName,
      errorMessage: errorMessage ?? this.errorMessage,
      connectedAt: connectedAt ?? this.connectedAt,
      ipAddress: ipAddress ?? this.ipAddress,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      bytesSent: bytesSent ?? this.bytesSent,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  @override
  List<Object?> get props => [
        status,
        configId,
        configName,
        errorMessage,
        connectedAt,
        ipAddress,
        bytesReceived,
        bytesSent,
        durationSeconds,
      ];
}