import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:http/http.dart' as http;
import '../../../../core/errors/exceptions.dart';
import '../models/vpn_server_model.dart';

abstract class ServerListRemoteDataSource {
  Future<List<VpnServerModel>> fetchServerList();
}

@LazySingleton(as: ServerListRemoteDataSource)
class ServerListRemoteDataSourceImpl implements ServerListRemoteDataSource {
  final http.Client client;

  ServerListRemoteDataSourceImpl(this.client);

  static const String vpnGateApiUrl = 'https://www.vpngate.net/api/iphone/';

  @override
  Future<List<VpnServerModel>> fetchServerList() async {
    try {
      final response = await client.get(
        Uri.parse(vpnGateApiUrl),
        headers: {
          'User-Agent': 'SoftEtherVPNClient/1.0',
        },
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed to fetch server list: ${response.statusCode}');
      }

      return _parseServerListCsv(response.body);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Network error: $e');
    }
  }

  List<VpnServerModel> _parseServerListCsv(String csvData) {
    final List<VpnServerModel> servers = [];
    final lines = const LineSplitter().convert(csvData);

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Skip header lines and empty lines
      if (line.isEmpty || line.startsWith('#') || line.startsWith('*vpn_servers')) {
        continue;
      }

      try {
        final server = VpnServerModel.fromCsvLine(line);

        // Only add servers with valid OpenVPN config
        if (server.openVpnConfigData.isNotEmpty && server.ip.isNotEmpty) {
          servers.add(server);
        }
      } catch (e) {
        // Skip malformed lines
        continue;
      }
    }

    // Sort by score (higher is better)
    servers.sort((a, b) => b.score.compareTo(a.score));

    return servers;
  }
}