import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/vpn_config_repository.dart';

@injectable
class DeleteConfig {
  final VpnConfigRepository repository;

  DeleteConfig(this.repository);

  Future<Either<Failure, Unit>> call(DeleteConfigParams params) async {
    return await repository.deleteConfig(params.configId);
  }
}

class DeleteConfigParams extends Equatable {
  final String configId;

  const DeleteConfigParams({required this.configId});

  @override
  List<Object> get props => [configId];
}