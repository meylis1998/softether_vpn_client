import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../vpn_config/presentation/bloc/vpn_config_bloc.dart';

class ConfigsList extends StatelessWidget {
  const ConfigsList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VpnConfigBloc, VpnConfigState>(
      builder: (context, state) {
        if (state is VpnConfigLoaded && state.configs.isNotEmpty) {
          return Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Saved Configurations:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.configs.length,
                    itemBuilder: (context, index) {
                      final config = state.configs[index];
                      final isSelected = state.selectedConfig?.id == config.id;

                      return ListTile(
                        title: Text(config.name),
                        subtitle: Text(
                          '${config.serverAddress}:${config.serverPort} (${config.protocol.name})',
                        ),
                        leading: Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? Theme.of(context).primaryColor : null,
                        ),
                        trailing: state.isDeleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete'),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _showDeleteDialog(context, config);
                                  }
                                },
                              ),
                        onTap: () {
                          context
                              .read<VpnConfigBloc>()
                              .add(SelectConfig(config));
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, config) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Configuration'),
        content: Text('Delete "${config.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<VpnConfigBloc>().add(DeleteConfigEvent(config.id));
    }
  }
}