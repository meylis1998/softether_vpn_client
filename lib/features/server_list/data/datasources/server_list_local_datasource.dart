import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/vpn_server_model.dart';

abstract class ServerListLocalDataSource {
  Future<List<VpnServerModel>> getCachedServerList();
  Future<void> cacheServerList(List<VpnServerModel> servers);
  Future<void> clearCache();
  Future<DateTime?> getLastUpdateTime();
  Future<void> setLastUpdateTime(DateTime time);
}

@LazySingleton(as: ServerListLocalDataSource)
class ServerListLocalDataSourceImpl implements ServerListLocalDataSource {
  final SharedPreferences sharedPreferences;

  ServerListLocalDataSourceImpl(this.sharedPreferences);

  static const String _cachedServersKey = 'CACHED_VPN_SERVERS';
  static const String _lastUpdateKey = 'SERVER_LIST_LAST_UPDATE';

  @override
  Future<List<VpnServerModel>> getCachedServerList() async {
    try {
      final jsonString = sharedPreferences.getString(_cachedServersKey);
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => VpnServerModel.fromJson(json)).toList();
    } catch (e) {
      throw CacheException('Failed to load cached server list: $e');
    }
  }

  @override
  Future<void> cacheServerList(List<VpnServerModel> servers) async {
    try {
      final jsonList = servers.map((server) => server.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await sharedPreferences.setString(_cachedServersKey, jsonString);
    } catch (e) {
      throw CacheException('Failed to cache server list: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await sharedPreferences.remove(_cachedServersKey);
      await sharedPreferences.remove(_lastUpdateKey);
    } catch (e) {
      throw CacheException('Failed to clear server list cache: $e');
    }
  }

  @override
  Future<DateTime?> getLastUpdateTime() async {
    try {
      final timestamp = sharedPreferences.getInt(_lastUpdateKey);
      if (timestamp == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> setLastUpdateTime(DateTime time) async {
    try {
      await sharedPreferences.setInt(_lastUpdateKey, time.millisecondsSinceEpoch);
    } catch (e) {
      throw CacheException('Failed to set last update time: $e');
    }
  }
}