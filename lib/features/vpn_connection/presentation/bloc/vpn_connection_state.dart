part of 'vpn_connection_bloc.dart';

class VpnConnectionState extends Equatable {
  final VpnConnectionStatus status;
  final bool isLoading;
  final String? errorMessage;

  const VpnConnectionState({
    this.status = const VpnConnectionStatus(
      status: VpnStatus.disconnected,
    ),
    this.isLoading = false,
    this.errorMessage,
  });

  VpnConnectionState copyWith({
    VpnConnectionStatus? status,
    bool? isLoading,
    String? errorMessage,
  }) {
    return VpnConnectionState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, isLoading, errorMessage];
}