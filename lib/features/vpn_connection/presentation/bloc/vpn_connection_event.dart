part of 'vpn_connection_bloc.dart';

sealed class VpnConnectionEvent extends Equatable {
  const VpnConnectionEvent();

  @override
  List<Object?> get props => [];
}

class ConnectToVpn extends VpnConnectionEvent {
  final VpnConfig config;

  const ConnectToVpn(this.config);

  @override
  List<Object> get props => [config];
}

class DisconnectFromVpn extends VpnConnectionEvent {
  const DisconnectFromVpn();
}

class LoadConnectionStatus extends VpnConnectionEvent {
  const LoadConnectionStatus();
}

class ConnectionStatusChanged extends VpnConnectionEvent {
  final VpnConnectionStatus status;

  const ConnectionStatusChanged(this.status);

  @override
  List<Object> get props => [status];
}