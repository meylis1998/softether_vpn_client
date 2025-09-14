import 'package:equatable/equatable.dart';

class VpnServer extends Equatable {
  final String hostName;
  final String ip;
  final int score;
  final int ping;
  final int speed;
  final String countryLong;
  final String countryShort;
  final int numVpnSessions;
  final int uptime;
  final int totalUsers;
  final int totalTraffic;
  final String logType;
  final String operator;
  final String message;
  final String openVpnConfigData;

  const VpnServer({
    required this.hostName,
    required this.ip,
    required this.score,
    required this.ping,
    required this.speed,
    required this.countryLong,
    required this.countryShort,
    required this.numVpnSessions,
    required this.uptime,
    required this.totalUsers,
    required this.totalTraffic,
    required this.logType,
    required this.operator,
    required this.message,
    required this.openVpnConfigData,
  });

  @override
  List<Object?> get props => [
        hostName,
        ip,
        score,
        ping,
        speed,
        countryLong,
        countryShort,
        numVpnSessions,
        uptime,
        totalUsers,
        totalTraffic,
        logType,
        operator,
        message,
        openVpnConfigData,
      ];
}