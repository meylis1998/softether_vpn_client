import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../vpn_config/domain/entities/vpn_config.dart';
import '../../../vpn_config/presentation/bloc/vpn_config_bloc.dart';
import '../../domain/entities/vpn_server.dart';
import '../bloc/server_list_bloc.dart';
import '../bloc/server_list_event.dart';
import '../bloc/server_list_state.dart';
import '../widgets/server_list_item.dart';

enum SortCriteria {
  score,
  ping,
  speed,
  uptime,
  sessions,
  country,
}

class ServerListPage extends StatefulWidget {
  final void Function(VpnConfig config)? onServerAdded;

  const ServerListPage({super.key, this.onServerAdded});

  @override
  State<ServerListPage> createState() => _ServerListPageState();
}

class _ServerListPageState extends State<ServerListPage> {
  SortCriteria _currentSort = SortCriteria.score;
  bool _ascending = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ServerListBloc>()..add(LoadCachedServersEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('VPN Gate Servers'),
          actions: [
            PopupMenuButton<SortCriteria>(
              icon: const Icon(Icons.sort),
              onSelected: (SortCriteria criteria) {
                setState(() {
                  if (_currentSort == criteria) {
                    _ascending = !_ascending;
                  } else {
                    _currentSort = criteria;
                    _ascending = false;
                  }
                });
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: SortCriteria.score,
                  child: Row(
                    children: [
                      Icon(Icons.star, size: 16),
                      SizedBox(width: 8),
                      Text('Score'),
                      if (_currentSort == SortCriteria.score)
                        Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: SortCriteria.uptime,
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 16),
                      SizedBox(width: 8),
                      Text('Uptime (Latest)'),
                      if (_currentSort == SortCriteria.uptime)
                        Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: SortCriteria.ping,
                  child: Row(
                    children: [
                      Icon(Icons.signal_cellular_alt, size: 16),
                      SizedBox(width: 8),
                      Text('Ping'),
                      if (_currentSort == SortCriteria.ping)
                        Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: SortCriteria.speed,
                  child: Row(
                    children: [
                      Icon(Icons.speed, size: 16),
                      SizedBox(width: 8),
                      Text('Speed'),
                      if (_currentSort == SortCriteria.speed)
                        Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: SortCriteria.sessions,
                  child: Row(
                    children: [
                      Icon(Icons.people, size: 16),
                      SizedBox(width: 8),
                      Text('Sessions'),
                      if (_currentSort == SortCriteria.sessions)
                        Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: SortCriteria.country,
                  child: Row(
                    children: [
                      Icon(Icons.flag, size: 16),
                      SizedBox(width: 8),
                      Text('Country'),
                      if (_currentSort == SortCriteria.country)
                        Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
                    ],
                  ),
                ),
              ],
            ),
            BlocBuilder<ServerListBloc, ServerListState>(
              builder: (context, state) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: state is ServerListLoading || state is ServerListRefreshing
                      ? null
                      : () {
                          context.read<ServerListBloc>().add(RefreshServerListEvent());
                        },
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<ServerListBloc, ServerListState>(
          builder: (context, state) {
            if (state is ServerListInitial || state is ServerListLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading VPN servers...'),
                  ],
                ),
              );
            }

            if (state is ServerListRefreshing) {
              final sortedServers = _sortServers(state.currentServers);
              return Stack(
                children: [
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.sort, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              'Sorted by ${_getSortDisplayName(_currentSort)} ${_ascending ? '↑' : '↓'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${sortedServers.length} servers',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _buildServerList(context, sortedServers, isFromCache: false),
                      ),
                    ],
                  ),
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(),
                  ),
                ],
              );
            }

            if (state is ServerListLoaded) {
              final sortedServers = _sortServers(state.servers);
              return Column(
                children: [
                  if (state.isFromCache)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      color: Colors.orange.shade100,
                      child: Row(
                        children: [
                          Icon(Icons.cached, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Showing cached servers. Pull to refresh for latest data.',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.sort, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Sorted by ${_getSortDisplayName(_currentSort)} ${_ascending ? '↑' : '↓'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${sortedServers.length} servers',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _buildServerList(context, sortedServers, isFromCache: state.isFromCache),
                  ),
                ],
              );
            }

            if (state is ServerListError) {
              if (state.cachedServers != null && state.cachedServers!.isNotEmpty) {
                final sortedServers = _sortServers(state.cachedServers!);
                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      color: Colors.red.shade100,
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Failed to refresh: ${state.message}',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.sort, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Sorted by ${_getSortDisplayName(_currentSort)} ${_ascending ? '↑' : '↓'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${sortedServers.length} servers',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildServerList(context, sortedServers, isFromCache: true),
                    ),
                  ],
                );
              }

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load servers',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.red.shade600,
                          ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ServerListBloc>().add(FetchServerListEvent());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildServerList(BuildContext context, List<VpnServer> servers, {required bool isFromCache}) {
    if (servers.isEmpty) {
      return const Center(
        child: Text('No VPN servers available'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ServerListBloc>().add(RefreshServerListEvent());

        // Wait for refresh to complete
        await context.read<ServerListBloc>().stream.firstWhere(
          (state) => state is! ServerListRefreshing,
        );
      },
      child: ListView.builder(
        itemCount: servers.length,
        itemBuilder: (context, index) {
          final server = servers[index];
          return ServerListItem(
            server: server,
            onTap: () => _onServerSelected(context, server),
          );
        },
      ),
    );
  }

  void _onServerSelected(BuildContext context, VpnServer server) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${server.hostName}'),
        content: Text('Add this server to your VPN configurations?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final config = VpnConfig(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: '${server.hostName} (${server.countryShort})',
                serverAddress: server.ip,
                serverPort: 443, // Default OpenVPN port
                protocol: VpnProtocol.openVpn,
                username: 'vpn',
                password: 'vpn',
                ovpnConfig: server.openVpnConfigData,
                createdAt: DateTime.now(),
              );

              // Use callback if provided, otherwise try to access bloc
              if (widget.onServerAdded != null) {
                widget.onServerAdded!(config);
              } else {
                try {
                  context.read<VpnConfigBloc>().add(SaveConfigEvent(config));
                } catch (e) {
                  // Fallback: show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error adding server. Please try again from the main screen.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  return;
                }
              }

              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to main screen

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added ${server.hostName} to configurations'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  List<VpnServer> _sortServers(List<VpnServer> servers) {
    final sortedServers = List<VpnServer>.from(servers);

    switch (_currentSort) {
      case SortCriteria.score:
        sortedServers.sort((a, b) => _ascending
            ? a.score.compareTo(b.score)
            : b.score.compareTo(a.score));
        break;
      case SortCriteria.ping:
        sortedServers.sort((a, b) => _ascending
            ? a.ping.compareTo(b.ping)
            : b.ping.compareTo(a.ping));
        break;
      case SortCriteria.speed:
        sortedServers.sort((a, b) => _ascending
            ? a.speed.compareTo(b.speed)
            : b.speed.compareTo(a.speed));
        break;
      case SortCriteria.uptime:
        // For uptime, lower value means more recent/better
        sortedServers.sort((a, b) => _ascending
            ? a.uptime.compareTo(b.uptime)
            : b.uptime.compareTo(a.uptime));
        break;
      case SortCriteria.sessions:
        sortedServers.sort((a, b) => _ascending
            ? a.numVpnSessions.compareTo(b.numVpnSessions)
            : b.numVpnSessions.compareTo(a.numVpnSessions));
        break;
      case SortCriteria.country:
        sortedServers.sort((a, b) => _ascending
            ? a.countryLong.compareTo(b.countryLong)
            : b.countryLong.compareTo(a.countryLong));
        break;
    }

    return sortedServers;
  }

  String _getSortDisplayName(SortCriteria criteria) {
    switch (criteria) {
      case SortCriteria.score:
        return 'Score';
      case SortCriteria.ping:
        return 'Ping';
      case SortCriteria.speed:
        return 'Speed';
      case SortCriteria.uptime:
        return 'Uptime';
      case SortCriteria.sessions:
        return 'Sessions';
      case SortCriteria.country:
        return 'Country';
    }
  }
}