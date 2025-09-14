import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../vpn_config/domain/entities/vpn_config.dart';
import '../../domain/entities/vpn_connection_status.dart';
import '../../domain/repositories/vpn_connection_repository.dart';
import '../datasources/vpn_connection_datasource.dart';

@LazySingleton(as: VpnConnectionRepository)
class VpnConnectionRepositoryImpl implements VpnConnectionRepository {
  final VpnConnectionDataSource dataSource;

  VpnConnectionRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, Unit>> connect(VpnConfig config) async {
    try {
      await dataSource.connect(config);
      return const Right(unit);
    } on VpnConnectionException catch (e) {
      return Left(VpnConnectionFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(VpnConnectionFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> disconnect() async {
    try {
      await dataSource.disconnect();
      return const Right(unit);
    } on VpnConnectionException catch (e) {
      return Left(VpnConnectionFailure(e.message));
    } catch (e) {
      return Left(VpnConnectionFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, VpnConnectionStatus>> getStatus() async {
    try {
      final statusModel = await dataSource.getStatus();
      return Right(statusModel.toEntity());
    } catch (e) {
      return Left(VpnConnectionFailure('Failed to get status: $e'));
    }
  }

  @override
  Stream<VpnConnectionStatus> watchStatus() {
    return dataSource.watchStatus().map((model) => model.toEntity());
  }

  @override
  Future<Either<Failure, bool>> checkVpnPermission() async {
    try {
      final hasPermission = await dataSource.checkVpnPermission();
      return Right(hasPermission);
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } catch (e) {
      return Left(PermissionFailure('Failed to check permission: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> requestVpnPermission() async {
    try {
      final granted = await dataSource.requestVpnPermission();
      return Right(granted);
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } catch (e) {
      return Left(PermissionFailure('Failed to request permission: $e'));
    }
  }
}