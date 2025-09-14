part of 'vpn_config_bloc.dart';

sealed class VpnConfigState extends Equatable {
  const VpnConfigState();

  @override
  List<Object?> get props => [];
}

class VpnConfigInitial extends VpnConfigState {}

class VpnConfigLoading extends VpnConfigState {}

class VpnConfigLoaded extends VpnConfigState {
  final List<VpnConfig> configs;
  final VpnConfig? selectedConfig;
  final bool isSaving;
  final bool isDeleting;
  final String? errorMessage;

  const VpnConfigLoaded({
    required this.configs,
    this.selectedConfig,
    this.isSaving = false,
    this.isDeleting = false,
    this.errorMessage,
  });

  VpnConfigLoaded copyWith({
    List<VpnConfig>? configs,
    VpnConfig? selectedConfig,
    bool? isSaving,
    bool? isDeleting,
    String? errorMessage,
  }) {
    return VpnConfigLoaded(
      configs: configs ?? this.configs,
      selectedConfig: selectedConfig ?? this.selectedConfig,
      isSaving: isSaving ?? this.isSaving,
      isDeleting: isDeleting ?? this.isDeleting,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        configs,
        selectedConfig,
        isSaving,
        isDeleting,
        errorMessage,
      ];
}

class VpnConfigError extends VpnConfigState {
  final String message;

  const VpnConfigError(this.message);

  @override
  List<Object> get props => [message];
}