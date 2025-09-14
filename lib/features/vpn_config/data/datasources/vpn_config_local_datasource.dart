import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/vpn_config_model.dart';

abstract class VpnConfigLocalDataSource {
  Future<List<VpnConfigModel>> getAllConfigs();
  Future<VpnConfigModel> getConfigById(String id);
  Future<void> saveConfig(VpnConfigModel config);
  Future<void> updateConfig(VpnConfigModel config);
  Future<void> deleteConfig(String id);
  Future<VpnConfigModel?> getLastConnectedConfig();
  Future<void> setLastConnectedConfig(String configId);
  Future<void> clearLastConnectedConfig();
}

@LazySingleton(as: VpnConfigLocalDataSource)
class VpnConfigLocalDataSourceImpl implements VpnConfigLocalDataSource {
  final SharedPreferences sharedPreferences;

  VpnConfigLocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<List<VpnConfigModel>> getAllConfigs() async {
    try {
      final configsJson = sharedPreferences.getStringList(AppConstants.configsKey) ?? [];
      return configsJson
          .map((json) => VpnConfigModel.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      throw CacheException('Failed to load configurations: $e');
    }
  }

  @override
  Future<VpnConfigModel> getConfigById(String id) async {
    try {
      final configs = await getAllConfigs();
      final config = configs.firstWhere(
        (config) => config.id == id,
        orElse: () => throw CacheException('Configuration not found'),
      );
      return config;
    } catch (e) {
      throw CacheException('Failed to get configuration: $e');
    }
  }

  @override
  Future<void> saveConfig(VpnConfigModel config) async {
    try {
      final configs = await getAllConfigs();

      // Remove existing config with same ID
      configs.removeWhere((c) => c.id == config.id);
      configs.add(config);

      await _saveConfigs(configs);
    } catch (e) {
      throw CacheException('Failed to save configuration: $e');
    }
  }

  @override
  Future<void> updateConfig(VpnConfigModel config) async {
    try {
      final configs = await getAllConfigs();
      final index = configs.indexWhere((c) => c.id == config.id);

      if (index == -1) {
        throw CacheException('Configuration not found for update');
      }

      configs[index] = config;
      await _saveConfigs(configs);
    } catch (e) {
      throw CacheException('Failed to update configuration: $e');
    }
  }

  @override
  Future<void> deleteConfig(String id) async {
    try {
      final configs = await getAllConfigs();
      configs.removeWhere((c) => c.id == id);
      await _saveConfigs(configs);

      // Clear last connected config if it matches deleted config
      final lastConnectedId = sharedPreferences.getString(AppConstants.lastConnectedConfigKey);
      if (lastConnectedId == id) {
        await clearLastConnectedConfig();
      }
    } catch (e) {
      throw CacheException('Failed to delete configuration: $e');
    }
  }

  @override
  Future<VpnConfigModel?> getLastConnectedConfig() async {
    try {
      final configId = sharedPreferences.getString(AppConstants.lastConnectedConfigKey);
      if (configId == null) return null;

      return await getConfigById(configId);
    } catch (e) {
      // If last connected config doesn't exist, clear it
      await clearLastConnectedConfig();
      return null;
    }
  }

  @override
  Future<void> setLastConnectedConfig(String configId) async {
    try {
      await sharedPreferences.setString(AppConstants.lastConnectedConfigKey, configId);
    } catch (e) {
      throw CacheException('Failed to set last connected configuration: $e');
    }
  }

  @override
  Future<void> clearLastConnectedConfig() async {
    try {
      await sharedPreferences.remove(AppConstants.lastConnectedConfigKey);
    } catch (e) {
      throw CacheException('Failed to clear last connected configuration: $e');
    }
  }

  Future<void> _saveConfigs(List<VpnConfigModel> configs) async {
    final configsJson = configs
        .map((config) => jsonEncode(config.toJson()))
        .toList();

    await sharedPreferences.setStringList(AppConstants.configsKey, configsJson);
  }
}