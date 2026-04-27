import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/models/parking_zone.dart';
import '../../data/services/parking_repository.dart';
import '../../data/services/websocket_service.dart';
import '../../core/network/api_client.dart';

class ParkingProvider extends ChangeNotifier {
  final ParkingRepository _repository = ParkingRepository();
  final WebSocketService _wsService = WebSocketService();

  List<ParkingZone> _zones = [];
  bool _isLoading = false;
  String? _error;

  List<ParkingZone> get zones => _zones;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StreamSubscription? _wsSubscription;
  String? _currentToken;

  Future<void> fetchParkingStatus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _zones = await _repository.getParkingStatus();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void initializeWebSocket(String token) {
    _currentToken = token;
    _connectWs();
  }

  void _connectWs() {
    if (_currentToken == null) return;

    _wsService.connect(_currentToken!);

    _wsSubscription = _wsService.stream?.listen(
      (message) {
        try {
          final data = jsonDecode(message);
          if (data['event'] == 'SLOT_UPDATE') {
            // Update the UI capacity
            // Assuming data['data'] contains updated zone info or we can simply refetch
            // For now, we will just call fetchParkingStatus() for simplicity when SLOT_UPDATE is received
            // Or if data contains the specific capacity, we update it in memory.
            fetchParkingStatus();
          } else if (data['event'] == 'QUEUE_POP') {
            final context = navigatorKey.currentContext;
            if (context != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Notifikasi: Anda telah mendapatkan slot parkir!",
                  ),
                ),
              );
            }
          } else if (data['event'] == 'SYSTEM_ALERT') {
            final context = navigatorKey.currentContext;
            if (context != null) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text("Peringatan Sistem", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  content: Text(data['data']?['message'] ?? 'Perhatian sistem', style: const TextStyle(color: Colors.black87)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            }
          }
        } catch (e) {
          debugPrint("Error parsing websocket message: $e");
        }
      },
      onDone: () {
        debugPrint(
          "WebSocket disconnected. Attempting to reconnect in 5 seconds...",
        );
        _wsService.disconnect();
        // Handle Phantom Queue: sinkronisasi state kembali.
        Future.delayed(const Duration(seconds: 5), () {
          _connectWs();
          fetchParkingStatus();
        });
      },
      onError: (error) {
        debugPrint("WebSocket Error: $error");
      },
    );
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _wsService.disconnect();
    super.dispose();
  }
}
