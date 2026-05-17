import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../data/models/parking_zone.dart';
import '../../data/services/parking_repository.dart';
import '../../data/services/websocket_service.dart';
import '../../core/network/api_client.dart';
import '../../data/services/auth_service.dart';

enum ScanStatus { idle, loading, success, zoneFull, error }

class ParkingProvider extends ChangeNotifier {
  final ParkingRepository _repository = ParkingRepository();
  final WebSocketService _wsService = WebSocketService();
  final ApiClient _apiClient = ApiClient();

  List<ParkingZone> _zones = [];
  bool _isLoading = false;
  String? _error;

  // Scan state
  ScanStatus _scanStatus = ScanStatus.idle;
  String? _scanErrorMessage;
  String? _scanErrorCode = null;
  String? _assignedSlot = null;
  String? _assignedZone = null;
  int? _assignedTransaksiID = null;
  double? _assignedX = null;
  double? _assignedY = null;

  String? _platNomor;
  String? _jenisKendaraan;

  List<ParkingZone> get zones => _zones;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ScanStatus get scanStatus => _scanStatus;
  String? get scanErrorMessage => _scanErrorMessage;
  String? get scanErrorCode => _scanErrorCode;
  String? get assignedSlot => _assignedSlot;
  String? get assignedZone => _assignedZone;
  int? get assignedTransaksiID => _assignedTransaksiID;
  double? get assignedX => _assignedX;
  double? get assignedY => _assignedY;
  String? get platNomor => _platNomor;
  String? get jenisKendaraan => _jenisKendaraan;

  /// True only when a scan has been confirmed AND slot data is populated
  bool get hasActiveSession =>
      _scanStatus == ScanStatus.success &&
      _assignedSlot != null &&
      _assignedZone != null;

  StreamSubscription? _wsSubscription;
  String? _currentToken;
  int _wsReconnectDelay = 2;

  Future<void> checkVehicleData() async {
    final authService = AuthService();
    final data = await authService.getUserData();
    _platNomor = data['plat_nomor'];
    _jenisKendaraan = data['jenis_kendaraan'];
    notifyListeners();
  }

  Future<void> checkActiveSession() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/parking/current');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final data = response.data['data'];
        _assignedSlot = data['nomor_slot'];
        _assignedZone = data['nama_zona'];
        _assignedTransaksiID = data['id_transaksi'];
        _assignedX = (data['x_coord'] as num?)?.toDouble() ?? 0.0;
        _assignedY = (data['y_coord'] as num?)?.toDouble() ?? 0.0;
        _scanStatus = ScanStatus.success;
      } else {
        // No active session — clear any stale dummy data
        _assignedSlot = null;
        _assignedZone = null;
        _assignedTransaksiID = null;
        _assignedX = null;
        _assignedY = null;
        if (_scanStatus == ScanStatus.success) _scanStatus = ScanStatus.idle;
      }
      notifyListeners();
    } catch (e) {
      // On error (e.g. 404 no active session), clear stale state
      _assignedSlot = null;
      _assignedZone = null;
      _assignedTransaksiID = null;
      _assignedX = null;
      _assignedY = null;
      if (_scanStatus == ScanStatus.success) _scanStatus = ScanStatus.idle;
      notifyListeners();
    }
  }

  Future<void> fetchParkingStatus({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    _error = null;

    try {
      await checkVehicleData();
      await checkActiveSession();
      _zones = await _repository.getParkingStatus();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  /// Read-only check for active parking session (does not mutate state)
  Future<bool> _hasActiveSession() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/parking/current');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return true;
      }
    } catch (e) {
      // Ignore – will be caught by the server-side guard anyway
    }
    return false;
  }

  /// Process a QR code scan by calling POST /api/v1/parking/scan
  Future<void> scanQR(String qrCode) async {
    _scanStatus = ScanStatus.loading;
    _scanErrorMessage = null;
    _scanErrorCode = null;
    _assignedSlot = null;
    _assignedZone = null;
    _assignedX = null;
    _assignedY = null;
    notifyListeners();

    // Guard 1: Check vehicle data
    await checkVehicleData();
    if (_platNomor == null || _jenisKendaraan == null || _platNomor!.isEmpty || _jenisKendaraan!.isEmpty) {
      _scanStatus = ScanStatus.error;
      _scanErrorCode = 'NO_VEHICLE';
      _scanErrorMessage = "Lengkapi profil kendaraan Anda terlebih dahulu.";
      notifyListeners();
      return;
    }

    // Guard 2: Check active session
    if (await _hasActiveSession()) {
      _scanStatus = ScanStatus.error;
      _scanErrorCode = 'ALREADY_PARKED';
      _scanErrorMessage = "Anda masih memiliki sesi parkir aktif. Silakan scan QR untuk keluar terlebih dahulu.";
      notifyListeners();
      return;
    }

    try {
      final response = await _apiClient.dio.post(
        '/api/v1/parking/scan',
        data: {'qr_code': qrCode},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        _assignedSlot = data['nomor_slot'];
        _assignedZone = data['nama_zona'];
        _assignedTransaksiID = data['id_transaksi'];
        _assignedX = (data['x_coord'] as num?)?.toDouble() ?? 0.0;
        _assignedY = (data['y_coord'] as num?)?.toDouble() ?? 0.0;
        _scanStatus = ScanStatus.success;
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
        final responseData = e.response!.data;
        _scanErrorCode = responseData['error_code'] ?? 'UNKNOWN';
        _scanErrorMessage = responseData['message'] ?? 'Terjadi kesalahan';

        if (_scanErrorCode == 'ZONE_FULL') {
          _scanStatus = ScanStatus.zoneFull;
        } else {
          _scanStatus = ScanStatus.error;
        }
      } else {
        _scanErrorCode = 'NETWORK_ERROR';
        _scanErrorMessage = 'Gagal terhubung ke server';
        _scanStatus = ScanStatus.error;
      }
    }

    notifyListeners();
  }

  /// Process parking exit by calling POST /api/v1/parking/exit
  Future<Map<String, dynamic>> exitParking() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post('/api/v1/parking/exit');
      
      if (response.statusCode == 200) {
        final data = response.data['data'];
        // Clear local active transaction state so user can scan again
        resetScanState();
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Gagal memproses keluar'};
    } catch (e) {
      String errMsg = 'Terjadi kesalahan jaringan';
      if (e is DioException && e.response != null) {
        errMsg = e.response!.data['message'] ?? 'Terjadi kesalahan';
      }
      _error = errMsg;
      return {'success': false, 'message': errMsg};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset scan state (e.g., when user re-opens scanner)
  void resetScanState() {
    _scanStatus = ScanStatus.idle;
    _scanErrorMessage = null;
    _scanErrorCode = null;
    _assignedSlot = null;
    _assignedZone = null;
    _assignedTransaksiID = null;
    _assignedX = null;
    _assignedY = null;
    notifyListeners();
  }

  void initializeWebSocket(String token) {
    _currentToken = token;
    _wsReconnectDelay = 2;
    _connectWs();
  }

  void _connectWs() {
    if (_currentToken == null) return;

    _wsService.connect(_currentToken!);

    _wsSubscription = _wsService.stream?.listen(
      (message) {
        // Reset delay on successful message received (indicates connection is healthy)
        _wsReconnectDelay = 2;
        
        try {
          final data = jsonDecode(message);
          if (data['event'] == 'SLOT_UPDATE') {
            final payload = data['data'];
            if (payload != null) {
              final idZona = payload['id_zona'].toString();
              final tersedia = payload['tersedia'] as int;
              final kapasitas = payload['kapasitas'] as int;
              final terisi = kapasitas - tersedia;
              
              // Temukan zona dan update state secara lokal
              final index = _zones.indexWhere((z) => z.id == idZona);
              if (index != -1) {
                _zones[index] = _zones[index].copyWith(
                  terisiSaatIni: terisi,
                );
                notifyListeners();
              } else {
                fetchParkingStatus();
              }
            }
          } else if (data['event'] == 'LAYOUT_UPDATE') {
            fetchParkingStatus(silent: true);
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
          "WebSocket disconnected. Attempting to reconnect in $_wsReconnectDelay seconds...",
        );
        _wsService.disconnect();
        Future.delayed(Duration(seconds: _wsReconnectDelay), () {
          _connectWs();
          fetchParkingStatus();
        });
        
        // Exponential backoff logic
        _wsReconnectDelay = (_wsReconnectDelay * 2).clamp(2, 32);
      },
      onError: (error) {
        debugPrint("WebSocket Error: $error");
      },
    );
  }

  void disconnectWebSocket() {
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _wsService.disconnect();
    _currentToken = null;
  }

  @override
  void dispose() {
    disconnectWebSocket();
    super.dispose();
  }
}
