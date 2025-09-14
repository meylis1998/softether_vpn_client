import 'package:flutter/material.dart';
import '../../domain/entities/vpn_server.dart';

class ServerListItem extends StatelessWidget {
  final VpnServer server;
  final VoidCallback? onTap;

  const ServerListItem({
    super.key,
    required this.server,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getScoreColor(server.score),
          child: Text(
            server.countryShort,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          server.hostName,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${server.countryLong} - ${server.ip}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.speed, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatSpeed(server.speed),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.signal_cellular_alt, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${server.ping}ms',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${server.numVpnSessions}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getScoreColor(server.score),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatScore(server.score),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatUptime(server.uptime),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: onTap,
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score > 1000000) return Colors.green;
    if (score > 500000) return Colors.orange;
    return Colors.red;
  }

  String _formatScore(int score) {
    if (score > 1000000) {
      return '${(score / 1000000).toStringAsFixed(1)}M';
    }
    if (score > 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K';
    }
    return score.toString();
  }

  String _formatSpeed(int speed) {
    if (speed > 1000000000) {
      return '${(speed / 1000000000).toStringAsFixed(1)} Gbps';
    }
    if (speed > 1000000) {
      return '${(speed / 1000000).toStringAsFixed(1)} Mbps';
    }
    if (speed > 1000) {
      return '${(speed / 1000).toStringAsFixed(1)} Kbps';
    }
    return '$speed bps';
  }

  String _formatUptime(int uptimeSeconds) {
    if (uptimeSeconds == 0) return 'Unknown';

    final days = uptimeSeconds ~/ (24 * 3600);
    final hours = (uptimeSeconds % (24 * 3600)) ~/ 3600;

    if (days > 0) {
      return '${days}d ${hours}h';
    }
    if (hours > 0) {
      return '${hours}h';
    }
    final minutes = (uptimeSeconds % 3600) ~/ 60;
    return '${minutes}m';
  }
}