import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../vpn_config/domain/entities/vpn_config.dart';
import '../../domain/entities/vpn_connection_status.dart';
import '../../domain/usecases/connect_vpn.dart';
import '../../domain/usecases/disconnect_vpn.dart';
import '../../domain/usecases/get_connection_status.dart';

part 'vpn_connection_event.dart';
part 'vpn_connection_state.dart';

@injectable
class VpnConnectionBloc extends Bloc<VpnConnectionEvent, VpnConnectionState> {
  final ConnectVpn _connectVpn;
  final DisconnectVpn _disconnectVpn;
  final GetConnectionStatus _getConnectionStatus;

  StreamSubscription<VpnConnectionStatus>? _statusSubscription;

  VpnConnectionBloc(
    this._connectVpn,
    this._disconnectVpn,
    this._getConnectionStatus,
  ) : super(const VpnConnectionState()) {
    on<ConnectToVpn>(_onConnect);
    on<DisconnectFromVpn>(_onDisconnect);
    on<LoadConnectionStatus>(_onLoadStatus);
    on<ConnectionStatusChanged>(_onStatusChanged);

    // Start watching connection status
    _startWatchingStatus();
  }

  void _startWatchingStatus() {
    _statusSubscription = _getConnectionStatus.watchStatus().listen(
      (status) => add(ConnectionStatusChanged(status)),
    );
  }

  Future<void> _onConnect(
    ConnectToVpn event,
    Emitter<VpnConnectionState> emit,
  ) async {
    print('🔵 VpnConnectionBloc: Received connect event for ${event.config.name}');
    emit(state.copyWith(isLoading: true, errorMessage: null));

    print('🔵 VpnConnectionBloc: Calling ConnectVpn use case...');
    final result = await _connectVpn(ConnectVpnParams(config: event.config));

    result.fold(
      (failure) {
        print('🔴 VpnConnectionBloc: Connection failed - ${failure.message}');
        emit(state.copyWith(
          isLoading: false,
          errorMessage: failure.message ?? 'Failed to connect',
        ));
      },
      (_) {
        print('🟢 VpnConnectionBloc: Connection use case completed successfully');
        emit(state.copyWith(isLoading: false));
      },
    );
  }

  Future<void> _onDisconnect(
    DisconnectFromVpn event,
    Emitter<VpnConnectionState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final result = await _disconnectVpn();

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message ?? 'Failed to disconnect',
      )),
      (_) => emit(state.copyWith(isLoading: false)),
    );
  }

  Future<void> _onLoadStatus(
    LoadConnectionStatus event,
    Emitter<VpnConnectionState> emit,
  ) async {
    final result = await _getConnectionStatus();

    result.fold(
      (failure) => emit(state.copyWith(
        errorMessage: failure.message ?? 'Failed to load status',
      )),
      (status) => emit(state.copyWith(
        status: status,
        errorMessage: null,
      )),
    );
  }

  void _onStatusChanged(
    ConnectionStatusChanged event,
    Emitter<VpnConnectionState> emit,
  ) {
    print('🔵 VpnConnectionBloc: Status changed to ${event.status.status}');
    if (event.status.configName != null) {
      print('🔵 VpnConnectionBloc: Config: ${event.status.configName}');
    }

    emit(state.copyWith(
      status: event.status,
      isLoading: event.status.status.isTransitioning ? state.isLoading : false,
    ));
  }

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    return super.close();
  }
}