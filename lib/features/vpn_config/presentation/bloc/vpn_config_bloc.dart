import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/vpn_config.dart';
import '../../domain/usecases/delete_config.dart';
import '../../domain/usecases/get_all_configs.dart';
import '../../domain/usecases/save_config.dart';

part 'vpn_config_event.dart';
part 'vpn_config_state.dart';

@injectable
class VpnConfigBloc extends Bloc<VpnConfigEvent, VpnConfigState> {
  final GetAllConfigs _getAllConfigs;
  final SaveConfig _saveConfig;
  final DeleteConfig _deleteConfig;

  VpnConfigBloc(
    this._getAllConfigs,
    this._saveConfig,
    this._deleteConfig,
  ) : super(VpnConfigInitial()) {
    on<LoadConfigs>(_onLoadConfigs);
    on<SaveConfigEvent>(_onSaveConfig);
    on<DeleteConfigEvent>(_onDeleteConfig);
    on<SelectConfig>(_onSelectConfig);
  }

  Future<void> _onLoadConfigs(
    LoadConfigs event,
    Emitter<VpnConfigState> emit,
  ) async {
    emit(VpnConfigLoading());

    final result = await _getAllConfigs();

    result.fold(
      (failure) => emit(VpnConfigError(failure.message ?? 'Failed to load configurations')),
      (configs) => emit(VpnConfigLoaded(
        configs: configs,
        selectedConfig: state is VpnConfigLoaded
            ? (state as VpnConfigLoaded).selectedConfig
            : null,
      )),
    );
  }

  Future<void> _onSaveConfig(
    SaveConfigEvent event,
    Emitter<VpnConfigState> emit,
  ) async {
    if (state is! VpnConfigLoaded) return;

    final currentState = state as VpnConfigLoaded;
    emit(currentState.copyWith(isSaving: true));

    final result = await _saveConfig(SaveConfigParams(config: event.config));

    result.fold(
      (failure) {
        emit(currentState.copyWith(
          isSaving: false,
          errorMessage: failure.message ?? 'Failed to save configuration',
        ));
      },
      (_) {
        // Reload configurations after saving
        add(const LoadConfigs());
      },
    );
  }

  Future<void> _onDeleteConfig(
    DeleteConfigEvent event,
    Emitter<VpnConfigState> emit,
  ) async {
    if (state is! VpnConfigLoaded) return;

    final currentState = state as VpnConfigLoaded;
    emit(currentState.copyWith(isDeleting: true));

    final result = await _deleteConfig(DeleteConfigParams(configId: event.configId));

    result.fold(
      (failure) {
        emit(currentState.copyWith(
          isDeleting: false,
          errorMessage: failure.message ?? 'Failed to delete configuration',
        ));
      },
      (_) {
        // Clear selection if deleted config was selected
        final newSelectedConfig = currentState.selectedConfig?.id == event.configId
            ? null
            : currentState.selectedConfig;

        // Reload configurations after deleting
        add(const LoadConfigs());

        if (newSelectedConfig != currentState.selectedConfig) {
          add(SelectConfig(newSelectedConfig));
        }
      },
    );
  }

  void _onSelectConfig(
    SelectConfig event,
    Emitter<VpnConfigState> emit,
  ) {
    if (state is VpnConfigLoaded) {
      emit((state as VpnConfigLoaded).copyWith(
        selectedConfig: event.config,
      ));
    }
  }
}