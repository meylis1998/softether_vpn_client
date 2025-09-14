import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/vpn_config.dart';
import '../repositories/vpn_config_repository.dart';

@injectable
class SaveConfig {
  final VpnConfigRepository repository;

  SaveConfig(this.repository);

  Future<Either<Failure, Unit>> call(SaveConfigParams params) async {
    return await repository.saveConfig(params.config);
  }
}

class SaveConfigParams extends Equatable {
  final VpnConfig config;

  const SaveConfigParams({required this.config});

  @override
  List<Object> get props => [config];
}