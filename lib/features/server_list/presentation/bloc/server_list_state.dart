import 'package:equatable/equatable.dart';
import '../../domain/entities/vpn_server.dart';

abstract class ServerListState extends Equatable {
  const ServerListState();

  @override
  List<Object?> get props => [];
}

class ServerListInitial extends ServerListState {}

class ServerListLoading extends ServerListState {}

class ServerListLoaded extends ServerListState {
  final List<VpnServer> servers;
  final bool isFromCache;
  final DateTime? lastUpdated;

  const ServerListLoaded({
    required this.servers,
    this.isFromCache = false,
    this.lastUpdated,
  });

  @override
  List<Object?> get props => [servers, isFromCache, lastUpdated];
}

class ServerListError extends ServerListState {
  final String message;
  final List<VpnServer>? cachedServers;

  const ServerListError({
    required this.message,
    this.cachedServers,
  });

  @override
  List<Object?> get props => [message, cachedServers];
}

class ServerListRefreshing extends ServerListState {
  final List<VpnServer> currentServers;

  const ServerListRefreshing(this.currentServers);

  @override
  List<Object> get props => [currentServers];
}