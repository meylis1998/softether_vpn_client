// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:softether_vpn_client/core/di/injection_container.dart' as _i233;
import 'package:softether_vpn_client/core/network/network_info.dart' as _i649;
import 'package:softether_vpn_client/features/vpn_config/data/datasources/vpn_config_local_datasource.dart'
    as _i988;
import 'package:softether_vpn_client/features/vpn_config/data/repositories/vpn_config_repository_impl.dart'
    as _i327;
import 'package:softether_vpn_client/features/vpn_config/domain/repositories/vpn_config_repository.dart'
    as _i94;
import 'package:softether_vpn_client/features/vpn_config/domain/usecases/delete_config.dart'
    as _i853;
import 'package:softether_vpn_client/features/vpn_config/domain/usecases/get_all_configs.dart'
    as _i870;
import 'package:softether_vpn_client/features/vpn_config/domain/usecases/save_config.dart'
    as _i902;
import 'package:softether_vpn_client/features/vpn_config/presentation/bloc/vpn_config_bloc.dart'
    as _i333;
import 'package:softether_vpn_client/features/vpn_connection/data/datasources/vpn_connection_datasource.dart'
    as _i575;
import 'package:softether_vpn_client/features/vpn_connection/data/repositories/vpn_connection_repository_impl.dart'
    as _i769;
import 'package:softether_vpn_client/features/vpn_connection/domain/repositories/vpn_connection_repository.dart'
    as _i678;
import 'package:softether_vpn_client/features/vpn_connection/domain/usecases/connect_vpn.dart'
    as _i413;
import 'package:softether_vpn_client/features/vpn_connection/domain/usecases/disconnect_vpn.dart'
    as _i640;
import 'package:softether_vpn_client/features/vpn_connection/domain/usecases/get_connection_status.dart'
    as _i6;
import 'package:softether_vpn_client/features/vpn_connection/presentation/bloc/vpn_connection_bloc.dart'
    as _i843;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    final networkModule = _$NetworkModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.sharedPreferences,
      preResolve: true,
    );
    gh.lazySingleton<_i895.Connectivity>(() => networkModule.connectivity);
    gh.lazySingleton<_i649.NetworkInfo>(
      () => _i649.NetworkInfoImpl(gh<_i895.Connectivity>()),
    );
    gh.lazySingleton<_i575.VpnConnectionDataSource>(
      () => _i575.VpnConnectionDataSourceImpl(),
    );
    gh.lazySingleton<_i988.VpnConfigLocalDataSource>(
      () => _i988.VpnConfigLocalDataSourceImpl(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i678.VpnConnectionRepository>(
      () => _i769.VpnConnectionRepositoryImpl(
        gh<_i575.VpnConnectionDataSource>(),
      ),
    );
    gh.lazySingleton<_i94.VpnConfigRepository>(
      () => _i327.VpnConfigRepositoryImpl(gh<_i988.VpnConfigLocalDataSource>()),
    );
    gh.factory<_i413.ConnectVpn>(
      () => _i413.ConnectVpn(gh<_i678.VpnConnectionRepository>()),
    );
    gh.factory<_i640.DisconnectVpn>(
      () => _i640.DisconnectVpn(gh<_i678.VpnConnectionRepository>()),
    );
    gh.factory<_i6.GetConnectionStatus>(
      () => _i6.GetConnectionStatus(gh<_i678.VpnConnectionRepository>()),
    );
    gh.factory<_i853.DeleteConfig>(
      () => _i853.DeleteConfig(gh<_i94.VpnConfigRepository>()),
    );
    gh.factory<_i870.GetAllConfigs>(
      () => _i870.GetAllConfigs(gh<_i94.VpnConfigRepository>()),
    );
    gh.factory<_i902.SaveConfig>(
      () => _i902.SaveConfig(gh<_i94.VpnConfigRepository>()),
    );
    gh.factory<_i843.VpnConnectionBloc>(
      () => _i843.VpnConnectionBloc(
        gh<_i413.ConnectVpn>(),
        gh<_i640.DisconnectVpn>(),
        gh<_i6.GetConnectionStatus>(),
      ),
    );
    gh.factory<_i333.VpnConfigBloc>(
      () => _i333.VpnConfigBloc(
        gh<_i870.GetAllConfigs>(),
        gh<_i902.SaveConfig>(),
        gh<_i853.DeleteConfig>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i233.RegisterModule {}

class _$NetworkModule extends _i649.NetworkModule {}
