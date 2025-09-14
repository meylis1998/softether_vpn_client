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
    // Check permissions first
    final permissionResult = await repository.checkVpnPermission();
    return permissionResult.fold(
      (failure) => Left(failure),
      (hasPermission) async {
        if (!hasPermission) {
          final requestResult = await repository.requestVpnPermission();
          return requestResult.fold(
            (failure) => Left(failure),
            (granted) async {
              if (!granted) {
                return const Left(PermissionFailure('VPN permission denied'));
              }
              return await repository.connect(params.config);
            },
          );
        }
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