import 'package:equatable/equatable.dart';

abstract class ServerListEvent extends Equatable {
  const ServerListEvent();

  @override
  List<Object> get props => [];
}

class FetchServerListEvent extends ServerListEvent {}

class RefreshServerListEvent extends ServerListEvent {}

class LoadCachedServersEvent extends ServerListEvent {}