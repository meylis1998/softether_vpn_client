import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/vpn_server.dart';

abstract class ServerListRepository {
  Future<Either<Failure, List<VpnServer>>> fetchServerList();
  Future<Either<Failure, List<VpnServer>>> getCachedServerList();
  Future<Either<Failure, void>> refreshServerList();
}