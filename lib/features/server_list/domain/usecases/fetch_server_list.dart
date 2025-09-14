import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/vpn_server.dart';
import '../repositories/server_list_repository.dart';

@injectable
class FetchServerList {
  final ServerListRepository repository;

  FetchServerList(this.repository);

  Future<Either<Failure, List<VpnServer>>> call() async {
    return await repository.fetchServerList();
  }
}