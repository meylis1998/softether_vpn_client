import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../vpn_config/presentation/bloc/vpn_config_bloc.dart';
import '../../domain/entities/vpn_connection_status.dart';
import '../bloc/vpn_connection_bloc.dart';

class ConnectionCard extends StatelessWidget {
  const ConnectionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VpnConnectionBloc, VpnConnectionState>(
      builder: (context, connectionState) {
        return BlocBuilder<VpnConfigBloc, VpnConfigState>(
          builder: (context, configState) {
            final status = connectionState.status.status;
            final isConnected = status.isConnected;
            final isLoading = connectionState.isLoading || status.isTransitioning;
            final selectedConfig = configState is VpnConfigLoaded
                ? configState.selectedConfig
                : null;

            return Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          isConnected ? Icons.vpn_lock : Icons.vpn_lock_outlined,
                          color: isConnected ? Colors.green : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                status.displayName,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              if (connectionState.status.configName != null)
                                Text(
                                  connectionState.status.configName!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              if (connectionState.status.ipAddress != null)
                                Text(
                                  'IP: ${connectionState.status.ipAddress}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                        if (isLoading)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (connectionState.errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          connectionState.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () => _toggleConnection(
                          context,
                          isConnected,
                          selectedConfig,
                        ),
                        child: Text(
                          isConnected ? 'Disconnect' : 'Connect',
                        ),
                      ),
                    ),
                    if (isConnected && connectionState.status.duration != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Connected for ${_formatDuration(connectionState.status.duration!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _toggleConnection(
    BuildContext context,
    bool isConnected,
    selectedConfig,
  ) {
    if (isConnected) {
      context.read<VpnConnectionBloc>().add(const DisconnectFromVpn());
    } else {
      if (selectedConfig == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a configuration first'),
          ),
        );
        return;
      }

      context.read<VpnConnectionBloc>().add(ConnectToVpn(selectedConfig));
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}