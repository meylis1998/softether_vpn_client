import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/usecases/fetch_server_list.dart';
import '../../domain/usecases/get_cached_server_list.dart';
import 'server_list_event.dart';
import 'server_list_state.dart';

@injectable
class ServerListBloc extends Bloc<ServerListEvent, ServerListState> {
  final FetchServerList fetchServerList;
  final GetCachedServerList getCachedServerList;

  ServerListBloc({
    required this.fetchServerList,
    required this.getCachedServerList,
  }) : super(ServerListInitial()) {
    on<LoadCachedServersEvent>(_onLoadCachedServers);
    on<FetchServerListEvent>(_onFetchServerList);
    on<RefreshServerListEvent>(_onRefreshServerList);
  }

  Future<void> _onLoadCachedServers(
    LoadCachedServersEvent event,
    Emitter<ServerListState> emit,
  ) async {
    emit(ServerListLoading());

    final result = await getCachedServerList();

    result.fold(
      (failure) {
        // If no cached data, try to fetch fresh data
        add(FetchServerListEvent());
      },
      (servers) {
        if (servers.isNotEmpty) {
          emit(ServerListLoaded(
            servers: servers,
            isFromCache: true,
            lastUpdated: DateTime.now(), // You might want to store actual cache time
          ));
        } else {
          // If no cached data, try to fetch fresh data
          add(FetchServerListEvent());
        }
      },
    );
  }

  Future<void> _onFetchServerList(
    FetchServerListEvent event,
    Emitter<ServerListState> emit,
  ) async {
    if (state is! ServerListLoaded) {
      emit(ServerListLoading());
    }

    final result = await fetchServerList();

    result.fold(
      (failure) {
        emit(ServerListError(message: failure.message ?? 'Unknown error'));
      },
      (servers) {
        emit(ServerListLoaded(
          servers: servers,
          isFromCache: false,
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  Future<void> _onRefreshServerList(
    RefreshServerListEvent event,
    Emitter<ServerListState> emit,
  ) async {
    final currentState = state;

    if (currentState is ServerListLoaded) {
      emit(ServerListRefreshing(currentState.servers));
    } else {
      emit(ServerListLoading());
    }

    final result = await fetchServerList();

    result.fold(
      (failure) {
        if (currentState is ServerListLoaded) {
          emit(ServerListError(
            message: failure.message ?? 'Unknown error',
            cachedServers: currentState.servers,
          ));
        } else {
          emit(ServerListError(message: failure.message ?? 'Unknown error'));
        }
      },
      (servers) {
        emit(ServerListLoaded(
          servers: servers,
          isFromCache: false,
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }
}