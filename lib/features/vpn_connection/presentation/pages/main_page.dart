import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../vpn_config/presentation/bloc/vpn_config_bloc.dart';
import '../../../vpn_config/presentation/pages/add_config_page.dart';
import '../../../server_list/presentation/pages/server_list_page.dart';
import '../widgets/connection_card.dart';
import '../widgets/config_selector.dart';
import '../widgets/configs_list.dart';
import '../widgets/debug_panel.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainPageView();
  }
}

class MainPageView extends StatelessWidget {
  const MainPageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SoftEther VPN'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download),
            tooltip: 'VPN Gate Servers',
            onPressed: () => _navigateToServerList(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Manual Config',
            onPressed: () => _navigateToAddConfig(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            ConnectionCard(),
            SizedBox(height: 20),
            ConfigSelector(),
            SizedBox(height: 20),
            DebugPanel(),
            SizedBox(height: 16),
            SizedBox(
              height: 300, // Fixed height for configs list
              child: ConfigsList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToAddConfig(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddConfigPage()),
    );

    if (result != null && context.mounted) {
      context.read<VpnConfigBloc>().add(const LoadConfigs());
    }
  }

  Future<void> _navigateToServerList(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServerListPage(
          onServerAdded: (config) {
            context.read<VpnConfigBloc>().add(SaveConfigEvent(config));
          },
        ),
      ),
    );

    if (context.mounted) {
      context.read<VpnConfigBloc>().add(const LoadConfigs());
    }
  }
}
