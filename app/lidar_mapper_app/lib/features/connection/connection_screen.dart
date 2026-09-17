// 연결 설정 화면 (Tier1-2) — rosbridge 주소를 입력하고 연결 상태를 확인하는 첫 화면.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connection_viewmodel.dart';

class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({super.key});

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  final _urlController = TextEditingController(text: 'ws://lidarmapper.local:9090');

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(connectionViewModelProvider);
    final viewModel = ref.read(connectionViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('연결 설정')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Orange Pi rosbridge 주소', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              enabled: connectionState.status != ConnectionStatus.connecting,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'ws://lidarmapper.local:9090',
              ),
            ),
            const SizedBox(height: 24),
            _StatusIndicator(status: connectionState.status),
            if (connectionState.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                connectionState.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: connectionState.status == ConnectionStatus.connecting
                  ? null
                  : () {
                      if (connectionState.status == ConnectionStatus.connected) {
                        viewModel.disconnect();
                      } else {
                        viewModel.connect(_urlController.text.trim());
                      }
                    },
              child: Text(
                connectionState.status == ConnectionStatus.connected ? '연결 해제' : '연결하기',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.status});

  final ConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      ConnectionStatus.disconnected => (Colors.grey, '연결 안 됨'),
      ConnectionStatus.connecting => (Colors.orange, '연결 중...'),
      ConnectionStatus.connected => (Colors.green, '연결됨'),
      ConnectionStatus.error => (Colors.red, '연결 실패'),
    };
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
