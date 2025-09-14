import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/vpn_config.dart';
import '../../domain/repositories/vpn_config_repository.dart';
import '../datasources/vpn_config_local_datasource.dart';
import '../models/vpn_config_model.dart';

@LazySingleton(as: VpnConfigRepository)
class VpnConfigRepositoryImpl implements VpnConfigRepository {
  final VpnConfigLocalDataSource localDataSource;
  final StreamController<List<VpnConfig>> _configsController =
      StreamController<List<VpnConfig>>.broadcast();

  VpnConfigRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<VpnConfig>>> getAllConfigs() async {
    try {
      final configModels = await localDataSource.getAllConfigs();
      final configs = configModels.map((model) => model.toEntity()).toList();

      // Update stream
      _configsController.add(configs);

      return Right(configs);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, VpnConfig>> getConfigById(String id) async {
    try {
      final configModel = await localDataSource.getConfigById(id);
      return Right(configModel.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveConfig(VpnConfig config) async {
    try {
      final configModel = VpnConfigModel.fromEntity(config);
      await localDataSource.saveConfig(configModel);

      // Trigger configs reload
      await getAllConfigs();

      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateConfig(VpnConfig config) async {
    try {
      final configModel = VpnConfigModel.fromEntity(config);
      await localDataSource.updateConfig(configModel);

      // Trigger configs reload
      await getAllConfigs();

      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteConfig(String id) async {
    try {
      await localDataSource.deleteConfig(id);

      // Trigger configs reload
      await getAllConfigs();

      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, VpnConfig?>> getLastConnectedConfig() async {
    try {
      final configModel = await localDataSource.getLastConnectedConfig();
      return Right(configModel?.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> setLastConnectedConfig(String configId) async {
    try {
      await localDataSource.setLastConnectedConfig(configId);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearLastConnectedConfig() async {
    try {
      await localDataSource.clearLastConnectedConfig();
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Stream<List<VpnConfig>> watchConfigs() {
    // Load initial configs
    getAllConfigs();
    return _configsController.stream;
  }

  void dispose() {
    _configsController.close();
  }
}