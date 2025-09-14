import 'package:equatable/equatable.dart';

class SoftEtherServerModel extends Equatable {
  final String hostname;
  final String ip;
  final String fqdn;
  final String region;
  final int score;
  final int ping;
  final String country;
  final String operator;
  final String message;
  final String openVpnConfig;
  final DateTime lastUpdated;

  const SoftEtherServerModel({
    required this.hostname,
    required this.ip,
    required this.fqdn,
    required this.region,
    required this.score,
    required this.ping,
    required this.country,
    required this.operator,
    required this.message,
    required this.openVpnConfig,
    required this.lastUpdated,
  });

  factory SoftEtherServerModel.fromDdnsResponse({
    required String hostname,
    required String fqdn,
    required String ipv4,
    required String region,
    String? operator,
    String? message,
  }) {
    return SoftEtherServerModel(
      hostname: hostname,
      ip: ipv4,
      fqdn: fqdn,
      region: region,
      score: 100, // Default score for DDNS servers
      ping: 0, // Will be measured separately
      country: _extractCountryFromRegion(region),
      operator: operator ?? 'SoftEther',
      message: message ?? 'Direct SoftEther VPN Server',
      openVpnConfig: _generateOpenVpnConfig(fqdn),
      lastUpdated: DateTime.now(),
    );
  }

  static String _extractCountryFromRegion(String region) {
    // Extract country from region string (e.g., "JP-Tokyo" -> "Japan")
    final countryMap = {
      'JP': 'Japan',
      'US': 'United States',
      'KR': 'South Korea',
      'CN': 'China',
      'TW': 'Taiwan',
      'HK': 'Hong Kong',
      'SG': 'Singapore',
      'TH': 'Thailand',
      'MY': 'Malaysia',
      'ID': 'Indonesia',
      'PH': 'Philippines',
      'VN': 'Vietnam',
      'IN': 'India',
      'AU': 'Australia',
      'NZ': 'New Zealand',
      'DE': 'Germany',
      'FR': 'France',
      'UK': 'United Kingdom',
      'IT': 'Italy',
      'ES': 'Spain',
      'NL': 'Netherlands',
      'BE': 'Belgium',
      'CH': 'Switzerland',
      'AT': 'Austria',
      'SE': 'Sweden',
      'NO': 'Norway',
      'FI': 'Finland',
      'DK': 'Denmark',
      'RU': 'Russia',
      'PL': 'Poland',
      'CZ': 'Czech Republic',
      'HU': 'Hungary',
      'RO': 'Romania',
      'BG': 'Bulgaria',
      'CA': 'Canada',
      'MX': 'Mexico',
      'BR': 'Brazil',
      'AR': 'Argentina',
      'CL': 'Chile',
      'PE': 'Peru',
      'CO': 'Colombia',
      'VE': 'Venezuela',
    };

    for (final entry in countryMap.entries) {
      if (region.startsWith(entry.key)) {
        return entry.value;
      }
    }
    return 'Unknown';
  }

  static String _generateOpenVpnConfig(String fqdn) {
    // Generate a basic OpenVPN configuration for SoftEther servers
    return '''client
dev tun
proto udp
remote $fqdn 1194
resolv-retry infinite
nobind
persist-key
persist-tun
cipher AES-256-CBC
auth SHA256
verb 3
auth-user-pass
compress lzo
<ca>
-----BEGIN CERTIFICATE-----
[Certificate will be downloaded from server]
-----END CERTIFICATE-----
</ca>''';
  }

  SoftEtherServerModel copyWith({
    String? hostname,
    String? ip,
    String? fqdn,
    String? region,
    int? score,
    int? ping,
    String? country,
    String? operator,
    String? message,
    String? openVpnConfig,
    DateTime? lastUpdated,
  }) {
    return SoftEtherServerModel(
      hostname: hostname ?? this.hostname,
      ip: ip ?? this.ip,
      fqdn: fqdn ?? this.fqdn,
      region: region ?? this.region,
      score: score ?? this.score,
      ping: ping ?? this.ping,
      country: country ?? this.country,
      operator: operator ?? this.operator,
      message: message ?? this.message,
      openVpnConfig: openVpnConfig ?? this.openVpnConfig,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hostname': hostname,
      'ip': ip,
      'fqdn': fqdn,
      'region': region,
      'score': score,
      'ping': ping,
      'country': country,
      'operator': operator,
      'message': message,
      'openVpnConfig': openVpnConfig,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory SoftEtherServerModel.fromJson(Map<String, dynamic> json) {
    return SoftEtherServerModel(
      hostname: json['hostname'] as String,
      ip: json['ip'] as String,
      fqdn: json['fqdn'] as String,
      region: json['region'] as String,
      score: json['score'] as int,
      ping: json['ping'] as int,
      country: json['country'] as String,
      operator: json['operator'] as String,
      message: json['message'] as String,
      openVpnConfig: json['openVpnConfig'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  @override
  List<Object?> get props => [
        hostname,
        ip,
        fqdn,
        region,
        score,
        ping,
        country,
        operator,
        message,
        openVpnConfig,
        lastUpdated,
      ];

  @override
  String toString() {
    return 'SoftEtherServerModel(hostname: $hostname, ip: $ip, region: $region, country: $country)';
  }
}