import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/vpn_config.dart';
import '../repositories/vpn_config_repository.dart';

@injectable
class GetAllConfigs {
  final VpnConfigRepository repository;

  GetAllConfigs(this.repository);

  Future<Either<Failure, List<VpnConfig>>> call() async {
    return await repository.getAllConfigs();
  }
}