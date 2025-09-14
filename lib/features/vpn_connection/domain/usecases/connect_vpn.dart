import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../vpn_config/domain/entities/vpn_config.dart';
import '../repositories/vpn_connection_repository.dart';

@injectable
class ConnectVpn {
  final VpnConnectionRepository repository;

  ConnectVpn(this.repository);

  Future<Either<Failure, Unit>> call(ConnectVpnParams params) async {
    print('🔵 ConnectVpn UseCase: Starting connection for ${params.config.name}');

    // Check permissions first
    print('🔵 ConnectVpn UseCase: Checking VPN permissions...');
    final permissionResult = await repository.checkVpnPermission();
    return permissionResult.fold(
      (failure) {
        print('🔴 ConnectVpn UseCase: Permission check failed - ${failure.message}');
        return Left(failure);
      },
      (hasPermission) async {
        print('🔵 ConnectVpn UseCase: Permission check result - $hasPermission');

        if (!hasPermission) {
          print('🔵 ConnectVpn UseCase: Requesting VPN permissions...');
          final requestResult = await repository.requestVpnPermission();
          return requestResult.fold(
            (failure) {
              print('🔴 ConnectVpn UseCase: Permission request failed - ${failure.message}');
              return Left(failure);
            },
            (granted) async {
              print('🔵 ConnectVpn UseCase: Permission request result - $granted');
              if (!granted) {
                print('🔴 ConnectVpn UseCase: VPN permission denied by user');
                return const Left(PermissionFailure('VPN permission denied'));
              }
              print('🔵 ConnectVpn UseCase: Proceeding with connection after permission grant...');
              return await repository.connect(params.config);
            },
          );
        }

        print('🔵 ConnectVpn UseCase: Proceeding with connection (permission already granted)...');
        return await repository.connect(params.config);
      },
    );
  }
}

class ConnectVpnParams extends Equatable {
  final VpnConfig config;

  const ConnectVpnParams({required this.config});

  @override
  List<Object> get props => [config];
}