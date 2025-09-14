import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../bloc/vpn_config_bloc.dart';
import '../widgets/config_form.dart';

class AddConfigPage extends StatelessWidget {
  const AddConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<VpnConfigBloc>(),
      child: const AddConfigPageView(),
    );
  }
}

class AddConfigPageView extends StatelessWidget {
  const AddConfigPageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add VPN Configuration'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BlocListener<VpnConfigBloc, VpnConfigState>(
        listener: (context, state) {
          if (state is VpnConfigLoaded && !state.isSaving && state.errorMessage == null) {
            // Configuration saved successfully
            Navigator.pop(context, true);
          } else if (state is VpnConfigLoaded && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: ConfigForm(
          onSave: (config) {
            context.read<VpnConfigBloc>().add(SaveConfigEvent(config));
          },
        ),
      ),
    );
  }
}