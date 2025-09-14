part of 'vpn_config_bloc.dart';

sealed class VpnConfigEvent extends Equatable {
  const VpnConfigEvent();

  @override
  List<Object?> get props => [];
}

class LoadConfigs extends VpnConfigEvent {
  const LoadConfigs();
}

class SaveConfigEvent extends VpnConfigEvent {
  final VpnConfig config;

  const SaveConfigEvent(this.config);

  @override
  List<Object> get props => [config];
}

class DeleteConfigEvent extends VpnConfigEvent {
  final String configId;

  const DeleteConfigEvent(this.configId);

  @override
  List<Object> get props => [configId];
}

class SelectConfig extends VpnConfigEvent {
  final VpnConfig? config;

  const SelectConfig(this.config);

  @override
  List<Object?> get props => [config];
}