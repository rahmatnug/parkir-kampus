import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  final String _baseUrl = 'ws://localhost:8080/api/v1/ws/connect';

  bool get isConnected => _isConnected;
  Stream<dynamic>? get stream => _channel?.stream;

  void connect(String token) {
    if (_isConnected) return;

    try {
      final wsUrl = Uri.parse('$_baseUrl?token=$token');
      _channel = WebSocketChannel.connect(wsUrl);
      _isConnected = true;
    } catch (e) {
      debugPrint("WebSocket connect error: $e");
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
    _channel = null;
  }
}
