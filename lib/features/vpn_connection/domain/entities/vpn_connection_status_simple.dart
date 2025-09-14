import 'package:equatable/equatable.dart';

enum VpnStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

class VpnConnectionStatus extends Equatable {
  final VpnStatus status;
  final String? configId;
  final String? configName;
  final String? errorMessage;
  final DateTime? connectedAt;
  final String? ipAddress;
  final int? bytesReceived;
  final int? bytesSent;
  final Duration? duration;

  const VpnConnectionStatus({
    required this.status,
    this.configId,
    this.configName,
    this.errorMessage,
    this.connectedAt,
    this.ipAddress,
    this.bytesReceived,
    this.bytesSent,
    this.duration,
  });

  VpnConnectionStatus copyWith({
    VpnStatus? status,
    String? configId,
    String? configName,
    String? errorMessage,
    DateTime? connectedAt,
    String? ipAddress,
    int? bytesReceived,
    int? bytesSent,
    Duration? duration,
  }) {
    return VpnConnectionStatus(
      status: status ?? this.status,
      configId: configId ?? this.configId,
      configName: configName ?? this.configName,
      errorMessage: errorMessage ?? this.errorMessage,
      connectedAt: connectedAt ?? this.connectedAt,
      ipAddress: ipAddress ?? this.ipAddress,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      bytesSent: bytesSent ?? this.bytesSent,
      duration: duration ?? this.duration,
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
        duration,
      ];
}