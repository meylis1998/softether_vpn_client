import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../vpn_config/presentation/bloc/vpn_config_bloc.dart';

class ConfigSelector extends StatelessWidget {
  const ConfigSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VpnConfigBloc, VpnConfigState>(
      builder: (context, state) {
        if (state is VpnConfigLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (state is VpnConfigError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Error loading configurations: ${state.message}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context
                        .read<VpnConfigBloc>()
                        .add(const LoadConfigs()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is VpnConfigLoaded) {
          if (state.configs.isEmpty) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'No VPN configurations found. Add one to get started.',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Configuration:'),
                  const SizedBox(height: 8),
                  DropdownButton(
                    isExpanded: true,
                    value: state.selectedConfig,
                    hint: const Text('Choose a VPN configuration'),
                    onChanged: (config) {
                      context
                          .read<VpnConfigBloc>()
                          .add(SelectConfig(config));
                    },
                    items: state.configs.map((config) {
                      return DropdownMenuItem(
                        value: config,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(config.name),
                            Text(
                              '${config.serverAddress} (${config.protocol.name})',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  if (state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Loading configurations...'),
          ),
        );
      },
    );
  }
}