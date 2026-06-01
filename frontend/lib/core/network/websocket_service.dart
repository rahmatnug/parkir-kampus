import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  final String _baseUrl = 'ws://localhost:8080/api/parking/ws'; // API URL
  
  String? _token;
  int _reconnectDelay = 2;
  Timer? _reconnectTimer;
  StreamSubscription? _channelSubscription;

  // StreamController to broadcast messages to listeners (e.g., ParkingProvider)
  final StreamController<dynamic> _streamController = StreamController<dynamic>.broadcast();

  bool get isConnected => _isConnected;
  Stream<dynamic> get stream => _streamController.stream;

  void connect(String token) {
    if (_isConnected) return;
    _token = token;
    _establishConnection();
  }

  void _establishConnection() {
    if (_token == null) return;

    try {
      final wsUrl = Uri.parse('$_baseUrl?token=$_token');
      _channel = WebSocketChannel.connect(wsUrl);
      
      _channelSubscription = _channel?.stream.listen(
        (message) {
          _isConnected = true;
          _reconnectDelay = 2; // Reset on successful message
          _streamController.add(message);
        },
        onDone: () {
          _handleDisconnect();
        },
        onError: (error) {
          debugPrint("WebSocket Error: $error");
          _handleDisconnect();
        },
      );
    } catch (e) {
      debugPrint("WebSocket connect error: $e");
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _channelSubscription?.cancel();
    _channel?.sink.close();
    
    // Exponential backoff reconnect
    debugPrint("WebSocket disconnected. Attempting to reconnect in $_reconnectDelay seconds...");
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: _reconnectDelay), () {
      _establishConnection();
    });
    
    _reconnectDelay = (_reconnectDelay * 2).clamp(2, 60);
  }

  void disconnect() {
    _isConnected = false;
    _token = null;
    _reconnectTimer?.cancel();
    _channelSubscription?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _streamController.close();
  }
}
