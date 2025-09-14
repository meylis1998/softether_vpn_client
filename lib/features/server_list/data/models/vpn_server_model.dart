import 'dart:convert';
import '../../domain/entities/vpn_server.dart';

class VpnServerModel extends VpnServer {
  const VpnServerModel({
    required super.hostName,
    required super.ip,
    required super.score,
    required super.ping,
    required super.speed,
    required super.countryLong,
    required super.countryShort,
    required super.numVpnSessions,
    required super.uptime,
    required super.totalUsers,
    required super.totalTraffic,
    required super.logType,
    required super.operator,
    required super.message,
    required super.openVpnConfigData,
  });

  factory VpnServerModel.fromCsvLine(String csvLine) {
    final parts = _parseCsvLine(csvLine);

    if (parts.length < 15) {
      throw FormatException('Invalid CSV line format');
    }

    // Decode base64 OpenVPN config
    String decodedConfig = '';
    try {
      if (parts[14].isNotEmpty) {
        decodedConfig = utf8.decode(base64.decode(parts[14]));
      }
    } catch (e) {
      // If decode fails, use empty string
      decodedConfig = '';
    }

    return VpnServerModel(
      hostName: parts[0],
      ip: parts[1],
      score: int.tryParse(parts[2]) ?? 0,
      ping: int.tryParse(parts[3]) ?? 0,
      speed: int.tryParse(parts[4]) ?? 0,
      countryLong: parts[5],
      countryShort: parts[6],
      numVpnSessions: int.tryParse(parts[7]) ?? 0,
      uptime: int.tryParse(parts[8]) ?? 0,
      totalUsers: int.tryParse(parts[9]) ?? 0,
      totalTraffic: int.tryParse(parts[10]) ?? 0,
      logType: parts[11],
      operator: parts[12],
      message: parts[13],
      openVpnConfigData: decodedConfig,
    );
  }

  static List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    bool inQuotes = false;
    String current = '';

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.trim());
        current = '';
      } else {
        current += char;
      }
    }

    result.add(current.trim());
    return result;
  }

  Map<String, dynamic> toJson() {
    return {
      'hostName': hostName,
      'ip': ip,
      'score': score,
      'ping': ping,
      'speed': speed,
      'countryLong': countryLong,
      'countryShort': countryShort,
      'numVpnSessions': numVpnSessions,
      'uptime': uptime,
      'totalUsers': totalUsers,
      'totalTraffic': totalTraffic,
      'logType': logType,
      'operator': operator,
      'message': message,
      'openVpnConfigData': openVpnConfigData,
    };
  }

  factory VpnServerModel.fromJson(Map<String, dynamic> json) {
    return VpnServerModel(
      hostName: json['hostName'] ?? '',
      ip: json['ip'] ?? '',
      score: json['score'] ?? 0,
      ping: json['ping'] ?? 0,
      speed: json['speed'] ?? 0,
      countryLong: json['countryLong'] ?? '',
      countryShort: json['countryShort'] ?? '',
      numVpnSessions: json['numVpnSessions'] ?? 0,
      uptime: json['uptime'] ?? 0,
      totalUsers: json['totalUsers'] ?? 0,
      totalTraffic: json['totalTraffic'] ?? 0,
      logType: json['logType'] ?? '',
      operator: json['operator'] ?? '',
      message: json['message'] ?? '',
      openVpnConfigData: json['openVpnConfigData'] ?? '',
    );
  }
}