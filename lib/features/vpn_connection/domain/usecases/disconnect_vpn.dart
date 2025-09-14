import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/vpn_connection_repository.dart';

@injectable
class DisconnectVpn {
  final VpnConnectionRepository repository;

  DisconnectVpn(this.repository);

  Future<Either<Failure, Unit>> call() async {
    return await repository.disconnect();
  }
}