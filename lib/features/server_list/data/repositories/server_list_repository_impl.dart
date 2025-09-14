import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/vpn_server.dart';
import '../../domain/repositories/server_list_repository.dart';
import '../datasources/server_list_local_datasource.dart';
import '../datasources/server_list_remote_datasource.dart';

@LazySingleton(as: ServerListRepository)
class ServerListRepositoryImpl implements ServerListRepository {
  final ServerListRemoteDataSource remoteDataSource;
  final ServerListLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  ServerListRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<VpnServer>>> fetchServerList() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteServers = await remoteDataSource.fetchServerList();
        await localDataSource.cacheServerList(remoteServers);
        await localDataSource.setLastUpdateTime(DateTime.now());
        return Right(remoteServers);
      } on ServerException catch (e) {
        // If remote fetch fails, try to return cached data
        try {
          final cachedServers = await localDataSource.getCachedServerList();
          if (cachedServers.isNotEmpty) {
            return Right(cachedServers);
          }
        } catch (_) {}

        return Left(ServerFailure(e.message));
      }
    } else {
      try {
        final cachedServers = await localDataSource.getCachedServerList();
        if (cachedServers.isNotEmpty) {
          return Right(cachedServers);
        } else {
          return Left(NetworkFailure('No internet connection and no cached data available'));
        }
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, List<VpnServer>>> getCachedServerList() async {
    try {
      final cachedServers = await localDataSource.getCachedServerList();
      return Right(cachedServers);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> refreshServerList() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteServers = await remoteDataSource.fetchServerList();
        await localDataSource.cacheServerList(remoteServers);
        await localDataSource.setLastUpdateTime(DateTime.now());
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  Future<bool> shouldRefreshCache() async {
    try {
      final lastUpdate = await localDataSource.getLastUpdateTime();
      if (lastUpdate == null) return true;

      final now = DateTime.now();
      final difference = now.difference(lastUpdate);

      // Refresh if older than 10 minutes
      return difference.inMinutes >= 10;
    } catch (e) {
      return true;
    }
  }
}