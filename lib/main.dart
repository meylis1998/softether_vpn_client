import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection_container.dart';
import 'features/vpn_connection/presentation/pages/main_page.dart';
import 'features/vpn_config/presentation/bloc/vpn_config_bloc.dart';
import 'features/vpn_connection/presentation/bloc/vpn_connection_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await configureDependencies();

  runApp(const SoftEtherVPNApp());
}

class SoftEtherVPNApp extends StatelessWidget {
  const SoftEtherVPNApp({super.key});

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
      child: MaterialApp(
        title: 'SoftEther VPN Client',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const MainPage(),
      ),
    );
  }
}
