import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../vpn_config/presentation/bloc/vpn_config_bloc.dart';
import '../../../vpn_config/presentation/pages/add_config_page.dart';
import '../bloc/vpn_connection_bloc.dart';
import '../widgets/connection_card.dart';
import '../widgets/config_selector.dart';
import '../widgets/configs_list.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<VpnConnectionBloc>()..add(const LoadConnectionStatus()),
        ),
        BlocProvider(
          create: (_) => sl<VpnConfigBloc>()..add(const LoadConfigs()),
        ),
      ],
      child: const MainPageView(),
    );
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
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddConfig(context),
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            ConnectionCard(),
            SizedBox(height: 20),
            ConfigSelector(),
            SizedBox(height: 20),
            Expanded(child: ConfigsList()),
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
}