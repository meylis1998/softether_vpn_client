import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:http/http.dart' as http;
import '../../../../core/errors/exceptions.dart';
import '../models/vpn_server_model.dart';
import '../models/softether_server_model.dart';
import 'softether_ddns_datasource.dart';

abstract class ServerListRemoteDataSource {
  Future<List<VpnServerModel>> fetchServerList();
}

@LazySingleton(as: ServerListRemoteDataSource)
class ServerListRemoteDataSourceImpl implements ServerListRemoteDataSource {
  final http.Client client;
  final SoftEtherDdnsDataSource softEtherDdnsDataSource;

  ServerListRemoteDataSourceImpl(this.client, this.softEtherDdnsDataSource);

  @override
  Future<List<VpnServerModel>> fetchServerList() async {
    print('🔵 Server Discovery: Starting SoftEther DDNS-based server fetching');

    try {
      // Use SoftEther DDNS protocol instead of VPN Gate CSV API
      final softEtherServers = await softEtherDdnsDataSource.fetchSoftEtherServers();

      // Convert SoftEther servers to VPN server models for compatibility
      final vpnServers = softEtherServers.map((server) => _convertToVpnServerModel(server)).toList();

      print('🟢 Server Discovery: Successfully converted ${vpnServers.length} SoftEther servers');

      // Sort by score (higher is better) - this gives us the best servers first
      vpnServers.sort((a, b) => b.score.compareTo(a.score));

      return vpnServers;

    } catch (e) {
      print('🔴 Server Discovery: SoftEther DDNS failed, falling back to VPN Gate API: $e');

      // Fallback to VPN Gate API if SoftEther DDNS fails
      return _fetchVpnGateServers();
    }
  }

  Future<List<VpnServerModel>> _fetchVpnGateServers() async {
    const String vpnGateApiUrl = 'https://www.vpngate.net/api/iphone/';

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

  VpnServerModel _convertToVpnServerModel(SoftEtherServerModel softEtherServer) {
    // Convert SoftEther server model to VPN server model for UI compatibility
    return VpnServerModel(
      hostName: softEtherServer.hostname,
      ip: softEtherServer.ip,
      score: softEtherServer.score,
      ping: softEtherServer.ping,
      speed: 0, // Not available in SoftEther DDNS
      countryLong: softEtherServer.country,
      countryShort: _getCountryCode(softEtherServer.country),
      numVpnSessions: 0, // Not available in SoftEther DDNS
      uptime: 0, // Will be calculated based on lastUpdated
      totalUsers: 0, // Not available in SoftEther DDNS
      totalTraffic: 0, // Not available in SoftEther DDNS
      logType: 'No Logging',
      operator: softEtherServer.operator,
      message: softEtherServer.message,
      openVpnConfigData: base64Encode(utf8.encode(softEtherServer.openVpnConfig)),
    );
  }

  String _getCountryCode(String countryName) {
    final countryMap = {
      'Japan': 'JP',
      'United States': 'US',
      'South Korea': 'KR',
      'China': 'CN',
      'Taiwan': 'TW',
      'Hong Kong': 'HK',
      'Singapore': 'SG',
      'Thailand': 'TH',
      'Malaysia': 'MY',
      'Indonesia': 'ID',
      'Philippines': 'PH',
      'Vietnam': 'VN',
      'India': 'IN',
      'Australia': 'AU',
      'New Zealand': 'NZ',
      'Germany': 'DE',
      'France': 'FR',
      'United Kingdom': 'UK',
      'Italy': 'IT',
      'Spain': 'ES',
      'Netherlands': 'NL',
      'Belgium': 'BE',
      'Switzerland': 'CH',
      'Austria': 'AT',
      'Sweden': 'SE',
      'Norway': 'NO',
      'Finland': 'FI',
      'Denmark': 'DK',
      'Russia': 'RU',
      'Poland': 'PL',
      'Czech Republic': 'CZ',
      'Hungary': 'HU',
      'Romania': 'RO',
      'Bulgaria': 'BG',
      'Canada': 'CA',
      'Mexico': 'MX',
      'Brazil': 'BR',
      'Argentina': 'AR',
      'Chile': 'CL',
      'Peru': 'PE',
      'Colombia': 'CO',
      'Venezuela': 'VE',
    };

    return countryMap[countryName] ?? 'XX';
  }

  List<VpnServerModel> _parseServerListCsv(String csvData) {
    final List<VpnServerModel> servers = [];
    final lines = const LineSplitter().convert(csvData);

    print('🔵 VPN Gate API: Parsing ${lines.length} lines from official API');

    bool headerFound = false;
    int serversParsed = 0;
    int serversAdded = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Skip empty lines
      if (line.isEmpty) {
        continue;
      }

      // Skip comment lines
      if (line.startsWith('#')) {
        continue;
      }

      // Detect CSV header line
      if (line.startsWith('HostName,IP,Score') || line.startsWith('*vpn_servers')) {
        headerFound = true;
        print('🔵 VPN Gate API: Found CSV header at line ${i + 1}');
        continue;
      }

      // Only process data lines after header is found
      if (!headerFound) {
        continue;
      }

      try {
        final server = VpnServerModel.fromCsvLine(line);
        serversParsed++;

        // Enhanced validation: check for valid server data
        if (server.openVpnConfigData.isNotEmpty &&
            server.ip.isNotEmpty &&
            server.hostName.isNotEmpty &&
            server.countryShort.isNotEmpty) {
          servers.add(server);
          serversAdded++;
        } else {
          print('🟡 VPN Gate API: Skipping server ${server.hostName} - missing required data');
        }
      } catch (e) {
        print('🟡 VPN Gate API: Failed to parse line ${i + 1}: $e');
        continue;
      }
    }

    print('🟢 VPN Gate API: Successfully parsed $serversAdded servers out of $serversParsed total entries');

    // Sort by score (higher is better) - this gives us the best servers first
    servers.sort((a, b) => b.score.compareTo(a.score));

    return servers;
  }
}