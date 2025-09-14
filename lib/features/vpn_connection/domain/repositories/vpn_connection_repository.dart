import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../vpn_config/domain/entities/vpn_config.dart';
import '../entities/vpn_connection_status.dart';

abstract class VpnConnectionRepository {
  Future<Either<Failure, Unit>> connect(VpnConfig config);
  Future<Either<Failure, Unit>> disconnect();
  Future<Either<Failure, VpnConnectionStatus>> getStatus();
  Stream<VpnConnectionStatus> watchStatus();
  Future<Either<Failure, bool>> checkVpnPermission();
  Future<Either<Failure, bool>> requestVpnPermission();
}