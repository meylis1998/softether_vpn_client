import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../vpn_config/domain/entities/vpn_config.dart';
import '../../../vpn_config/presentation/bloc/vpn_config_bloc.dart';
import '../bloc/vpn_connection_bloc.dart';

class DebugPanel extends StatelessWidget {
  const DebugPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🐛 Debug Panel',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quick test configurations:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _addTestL2TPConfig(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Test L2TP'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade100,
                    foregroundColor: Colors.orange.shade800,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _addTestOpenVPNConfig(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Test OpenVPN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade100,
                    foregroundColor: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '💡 Check console output for detailed connection logs',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            BlocBuilder<VpnConnectionBloc, VpnConnectionState>(
              builder: (context, state) {
                return ExpansionTile(
                  title: const Text(
                    'Debug Info',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  initiallyExpanded: false,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: ${state.status.status}'),
                          if (state.status.configName != null)
                            Text('Config: ${state.status.configName}'),
                          if (state.status.ipAddress != null)
                            Text('IP: ${state.status.ipAddress}'),
                          if (state.errorMessage != null)
                            Text(
                              'Error: ${state.errorMessage}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          Text('Loading: ${state.isLoading}'),
                          if (state.status.connectedAt != null)
                            Text('Connected: ${state.status.connectedAt}'),
                          if (state.status.duration != null)
                            Text('Duration: ${state.status.duration}'),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addTestL2TPConfig(BuildContext context) {
    final testConfig = VpnConfig(
      id: 'test_l2tp_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Test L2TP Server',
      serverAddress: 'vpn.example.com',
      serverPort: 1701,
      protocol: VpnProtocol.l2tpIpsec,
      username: 'testuser',
      password: 'testpass',
      presharedKey: 'testpsk',
      createdAt: DateTime.now(),
    );

    context.read<VpnConfigBloc>().add(SaveConfigEvent(testConfig));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added test L2TP configuration: ${testConfig.name}'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _addTestOpenVPNConfig(BuildContext context) {
    const testOpenVPNConfig = '''
client
dev tun
proto udp
remote vpn.example.com 1194
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
cert client.crt
key client.key
remote-cert-tls server
cipher AES-256-CBC
verb 3
''';

    final testConfig = VpnConfig(
      id: 'test_ovpn_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Test OpenVPN Server',
      serverAddress: 'vpn.example.com',
      serverPort: 1194,
      protocol: VpnProtocol.openVpn,
      username: 'testuser',
      password: 'testpass',
      ovpnConfig: testOpenVPNConfig,
      createdAt: DateTime.now(),
    );

    context.read<VpnConfigBloc>().add(SaveConfigEvent(testConfig));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added test OpenVPN configuration: ${testConfig.name}'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}