import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/vpn_config.dart';

abstract class VpnConfigRepository {
  Future<Either<Failure, List<VpnConfig>>> getAllConfigs();
  Future<Either<Failure, VpnConfig>> getConfigById(String id);
  Future<Either<Failure, Unit>> saveConfig(VpnConfig config);
  Future<Either<Failure, Unit>> updateConfig(VpnConfig config);
  Future<Either<Failure, Unit>> deleteConfig(String id);
  Future<Either<Failure, VpnConfig?>> getLastConnectedConfig();
  Future<Either<Failure, Unit>> setLastConnectedConfig(String configId);
  Future<Either<Failure, Unit>> clearLastConnectedConfig();
  Stream<List<VpnConfig>> watchConfigs();
}