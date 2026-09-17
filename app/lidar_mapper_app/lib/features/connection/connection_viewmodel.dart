// 연결 화면의 상태/로직을 담당하는 ViewModel.
// View(connection_screen.dart)는 이 provider만 보고, RosBridgeClient 구현은 모른다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ros_bridge_client.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class ConnectionState {
  final ConnectionStatus status;
  final String? errorMessage;

  const ConnectionState({required this.status, this.errorMessage});

  const ConnectionState.initial() : this(status: ConnectionStatus.disconnected);

  ConnectionState copyWith({ConnectionStatus? status, String? errorMessage}) {
    return ConnectionState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

final rosBridgeClientProvider = Provider<RosBridgeClient>((ref) {
  final client = RosBridgeClient();
  ref.onDispose(client.disconnect);
  return client;
});

class ConnectionViewModel extends StateNotifier<ConnectionState> {
  ConnectionViewModel(this._client) : super(const ConnectionState.initial());

  final RosBridgeClient _client;

  Future<void> connect(String url) async {
    state = state.copyWith(status: ConnectionStatus.connecting);
    try {
      await _client.connect(url);
      state = state.copyWith(status: ConnectionStatus.connected);
    } catch (e) {
      state = state.copyWith(status: ConnectionStatus.error, errorMessage: '$e');
    }
  }

  Future<void> disconnect() async {
    await _client.disconnect();
    state = const ConnectionState.initial();
  }
}

final connectionViewModelProvider =
    StateNotifierProvider<ConnectionViewModel, ConnectionState>((ref) {
  return ConnectionViewModel(ref.watch(rosBridgeClientProvider));
});
