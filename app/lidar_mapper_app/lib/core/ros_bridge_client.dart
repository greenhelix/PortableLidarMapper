// rosbridge(WebSocket) 통신 창구 — 앱 전체에서 ROS2와 대화하는 유일한 지점.
// Service 계층: 이 클래스 위(ViewModel/Repository)는 여기 구현을 몰라도 됨.

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class RosBridgeClient {
  WebSocketChannel? _channel;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  /// 외부에서 구독할 수 있는 수신 메시지 스트림 (rosbridge가 보내는 모든 JSON)
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  bool get isConnected => _channel != null;

  /// rosbridge 서버에 연결한다.
  ///
  /// [url] 예시: "ws://lidarmapper.local:9090" 또는 "ws://192.168.0.42:9090"
  ///    - 콜백에서 받은 raw 데이터(String)를 jsonDecode()로 Map으로 변환
  ///    - 변환한 Map을 _messageController.add(...)로 흘려보내기
  Future<void> connect(String url) async {
    _channel = WebSocketChannel.connect(Uri.parse(url));
    await _channel!.ready; // 연결이 실제로 열릴 때까지 대기 (실패 시 예외 발생)

    _channel!.stream.listen(
      (raw) {
        final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
        _messageController.add(decoded);
      },
      onError: (error) {
        _messageController.addError(error);
      },
      onDone: () {
        _channel = null;
      },
    );
  }

  /// JSON 메시지를 rosbridge로 전송한다 (토픽 publish, 서비스 호출 등에 재사용).
  void send(Map<String, dynamic> message) {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode(message));
  }

  /// 연결을 종료하고 자원을 정리한다.
  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
  }
}
