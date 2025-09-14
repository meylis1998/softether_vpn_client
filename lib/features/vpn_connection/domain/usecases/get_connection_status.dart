import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/vpn_connection_status.dart';
import '../repositories/vpn_connection_repository.dart';

@injectable
class GetConnectionStatus {
  final VpnConnectionRepository repository;

  GetConnectionStatus(this.repository);

  Future<Either<Failure, VpnConnectionStatus>> call() async {
    return await repository.getStatus();
  }

  Stream<VpnConnectionStatus> watchStatus() {
    return repository.watchStatus();
  }
}