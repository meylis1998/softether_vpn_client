import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';
import 'package:http/http.dart' as http;
import '../../../../core/errors/exceptions.dart';
import '../models/softether_pack.dart';
import '../models/softether_server_model.dart';

abstract class SoftEtherDdnsDataSource {
  Future<List<SoftEtherServerModel>> fetchSoftEtherServers();
}

@LazySingleton(as: SoftEtherDdnsDataSource)
class SoftEtherDdnsDataSourceImpl implements SoftEtherDdnsDataSource {
  final http.Client client;

  // SoftEther DDNS URLs from the source code
  static const List<String> _ddnsUrlsV4 = [
    'https://x%c.x%c.servers.ddns.softether-network.net/ddns/ddns.aspx',
    'https://x%c.x%c.servers.ddns.uxcom.jp/ddns/ddns.aspx', // Alternative for China
  ];

  static const List<String> _ddnsUrlsV6 = [
    'https://x%c.x%c.servers-v6.ddns.softether-network.net/ddns/ddns.aspx',
    'https://x%c.x%c.servers-v6.ddns.uxcom.jp/ddns/ddns.aspx', // Alternative for China
  ];

  // Certificate hashes from SoftEther source (DDNS.h)
  static const String _ddnsCertHash =
    '78BF0499A99396907C9F49DD13571C81FE26E6F5'
    '439BAFA75A6EE5671FC9F9A02D34FF29881761A0'
    'EFAC5FA0CDD14E0F864EED58A73C35D7E33B62F3'
    '74DF99D4B1B5F0488A388B50D347D26013DC67A5'
    '6EBB39AFCA8C900635CFC11218CF293A612457E4'
    '05A9386C5E2B233F7BAB2479620EAAA2793709ED'
    'A811C64BB715351E36B6C1E022648D8BE0ACD128'
    'BD264DB3B0B1B3ABA0AF3074AA574ED1EF3B42D7'
    '9AB61D691536645DD55A8730FC6D2CDF33C8C73F';

  SoftEtherDdnsDataSourceImpl(this.client);

  @override
  Future<List<SoftEtherServerModel>> fetchSoftEtherServers() async {
    print('🔵 SoftEther DDNS: Starting server discovery process');

    final List<SoftEtherServerModel> servers = [];

    try {
      // Try IPv4 servers first
      final ipv4Servers = await _fetchServersForProtocol(false);
      servers.addAll(ipv4Servers);
      print('🔵 SoftEther DDNS: Found ${ipv4Servers.length} IPv4 servers');

      // Try IPv6 servers
      try {
        final ipv6Servers = await _fetchServersForProtocol(true);
        servers.addAll(ipv6Servers);
        print('🔵 SoftEther DDNS: Found ${ipv6Servers.length} IPv6 servers');
      } catch (e) {
        print('🟡 SoftEther DDNS: IPv6 discovery failed: $e');
      }

      if (servers.isEmpty) {
        throw ServerException('No SoftEther servers found through DDNS discovery');
      }

      print('🟢 SoftEther DDNS: Successfully discovered ${servers.length} total servers');
      return servers;

    } catch (e) {
      print('🔴 SoftEther DDNS: Discovery failed: $e');
      if (e is ServerException) rethrow;
      throw ServerException('SoftEther DDNS discovery error: $e');
    }
  }

  Future<List<SoftEtherServerModel>> _fetchServersForProtocol(bool ipv6) async {
    final urls = ipv6 ? _ddnsUrlsV6 : _ddnsUrlsV4;
    final protocol = ipv6 ? 'IPv6' : 'IPv4';

    for (final urlTemplate in urls) {
      try {
        print('🔵 SoftEther DDNS: Trying $protocol discovery with $urlTemplate');
        final servers = await _performDdnsRequest(urlTemplate, ipv6);
        if (servers.isNotEmpty) {
          return servers;
        }
      } catch (e) {
        print('🟡 SoftEther DDNS: $protocol request failed for $urlTemplate: $e');
        continue;
      }
    }

    return [];
  }

  Future<List<SoftEtherServerModel>> _performDdnsRequest(String urlTemplate, bool ipv6) async {
    // Generate random key (like SoftEther client does)
    final key = _generateRandomKey();
    final keyStr = _bytesToHex(key).toUpperCase();

    // Create key hash for URL generation
    final keyHash = sha1.convert(utf8.encode(keyStr)).bytes;
    final keyHashStr = _bytesToHex(keyHash).toLowerCase();

    // Generate final URL with random values and key hash (fix double replacement)
    final randomValue = Random().nextInt(0xFFFFFFFF);
    final baseUrl = urlTemplate.replaceFirst('%c', keyHashStr[2]).replaceFirst('%c', keyHashStr[3]);
    final finalUrl = '$baseUrl?v=$randomValue';

    print('🔵 SoftEther DDNS: Requesting $finalUrl');

    // Create PACK request (like SoftEther client)
    final pack = SoftEtherPack();
    pack.addString('key', keyStr);
    pack.addInt('build', 5180); // SoftEther build version
    pack.addInt('osinfo', 2); // Android
    pack.addBool('is_64bit', true);
    pack.addBool('is_softether', true);
    pack.addBool('is_packetix', false);
    pack.addString('machine_key', _generateMachineKey());
    pack.addString('machine_name', 'android-client');
    pack.addInt('lasterror_ipv4', 0);
    pack.addInt('lasterror_ipv6', 0);
    pack.addBool('use_azure', false);
    pack.addString('product_str', 'SoftEther VPN Client (Flutter)');
    pack.addInt('ddns_protocol_version', 1);

    final requestBody = pack.serialize();

    try {
      final response = await client.post(
        Uri.parse(finalUrl),
        headers: {
          'Content-Type': 'application/octet-stream',
          'User-Agent': 'SoftEther VPN Client (Flutter)/1.0',
          'Content-Length': '${requestBody.length}',
        },
        body: requestBody,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ServerException('DDNS request failed: ${response.statusCode}');
      }

      print('🔵 SoftEther DDNS: Received ${response.bodyBytes.length} bytes');

      // Parse PACK response
      final responsePack = SoftEtherPack.deserialize(response.bodyBytes);

      return _parseServerResponse(responsePack);

    } catch (e) {
      print('🔴 SoftEther DDNS: Request failed: $e');
      rethrow;
    }
  }

  List<SoftEtherServerModel> _parseServerResponse(SoftEtherPack pack) {
    final List<SoftEtherServerModel> servers = [];

    try {
      // Extract basic server info from DDNS response
      final hostname = pack.getString('current_hostname') ?? '';
      final fqdn = pack.getString('current_fqdn') ?? '';
      final ipv4 = pack.getString('current_ipv4') ?? '';
      final ipv6 = pack.getString('current_ipv6') ?? '';
      final region = pack.getString('current_region') ?? 'Unknown';

      print('🔵 SoftEther DDNS: Parsing response - hostname: $hostname, fqdn: $fqdn');

      // Create server entry if we have valid data
      if (hostname.isNotEmpty && fqdn.isNotEmpty && (ipv4.isNotEmpty || ipv6.isNotEmpty)) {
        final server = SoftEtherServerModel.fromDdnsResponse(
          hostname: hostname,
          fqdn: fqdn,
          ipv4: ipv4.isNotEmpty ? ipv4 : ipv6,
          region: region,
          operator: 'SoftEther Network',
          message: 'Direct SoftEther VPN Server via DDNS',
        );

        servers.add(server);
        print('🟢 SoftEther DDNS: Created server entry: $hostname ($region)');
      }

      // Look for additional server list data in the response
      // SoftEther might return multiple servers or references to other servers
      final serverList = pack.getString('server_list');
      if (serverList != null && serverList.isNotEmpty) {
        print('🔵 SoftEther DDNS: Found additional server list data');
        // Parse additional servers if provided
        final additionalServers = _parseAdditionalServers(serverList);
        servers.addAll(additionalServers);
      }

    } catch (e) {
      print('🟡 SoftEther DDNS: Error parsing server response: $e');
    }

    return servers;
  }

  List<SoftEtherServerModel> _parseAdditionalServers(String serverListData) {
    final List<SoftEtherServerModel> servers = [];

    try {
      // Parse server list if it's in a known format (CSV, JSON, etc.)
      final lines = serverListData.split('\n');

      for (final line in lines) {
        if (line.trim().isEmpty || line.startsWith('#')) continue;

        final parts = line.split(',');
        if (parts.length >= 3) {
          final hostname = parts[0].trim();
          final ip = parts[1].trim();
          final region = parts.length > 2 ? parts[2].trim() : 'Unknown';

          if (hostname.isNotEmpty && ip.isNotEmpty) {
            final server = SoftEtherServerModel.fromDdnsResponse(
              hostname: hostname,
              fqdn: hostname.contains('.') ? hostname : '$hostname.vpn.softether.net',
              ipv4: ip,
              region: region,
            );
            servers.add(server);
          }
        }
      }
    } catch (e) {
      print('🟡 SoftEther DDNS: Error parsing additional servers: $e');
    }

    return servers;
  }

  Uint8List _generateRandomKey() {
    final random = Random.secure();
    final key = Uint8List(20); // SHA1 size
    for (int i = 0; i < key.length; i++) {
      key[i] = random.nextInt(256);
    }
    return key;
  }

  String _generateMachineKey() {
    // Generate a consistent machine key based on device info
    final deviceInfo = Platform.operatingSystem + Platform.operatingSystemVersion;
    final hash = sha1.convert(utf8.encode(deviceInfo)).bytes;
    return _bytesToHex(hash).toUpperCase();
  }

  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }
}