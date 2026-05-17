import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../providers/parking_provider.dart';
import 'parking_assigned_page.dart';
import 'parking_full_page.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage>
    with SingleTickerProviderStateMixin {
  late MobileScannerController cameraController;
  late AnimationController _animationController;
  bool isScanning = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Reset scan state when entering this page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ParkingProvider>().resetScanState();
    });
  }

  @override
  void dispose() {
    cameraController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!isScanning || _isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        // Validate the format: URL, PK-prefix, ZONE-prefix, or length > 3
        if (code.startsWith('http') ||
            code.startsWith('PK-') ||
            code.toUpperCase().startsWith('ZONE') ||
            code.length > 3) {
          setState(() {
            isScanning = false;
            _isProcessing = true;
          });
          _processScan(code);
        } else {
          setState(() => isScanning = false);
          _showErrorSheet('Format QR tidak dikenali!',
              'Pastikan Anda memindai kode QR yang terdapat pada tiang zona parkir.');
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => isScanning = true);
          });
        }
        break;
      }
    }
  }

  Future<void> _processScan(String qrCode) async {
    final provider = context.read<ParkingProvider>();

    // Show processing modal bottom sheet
    _showProcessingSheet();

    await provider.scanQR(qrCode);

    if (!mounted) return;

    // Close processing sheet
    Navigator.of(context).pop();

    final status = provider.scanStatus;

    if (status == ScanStatus.success) {
      // Navigate to Parking Assigned page with real coordinates
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ParkingAssignedPage(
            slotNumber: provider.assignedSlot ?? '-',
            zone: provider.assignedZone ?? '-',
            xCoord: provider.assignedX ?? 0.0,
            yCoord: provider.assignedY ?? 0.0,
            vehicleType: provider.jenisKendaraan ?? 'Motor',
          ),
        ),
      );
    } else if (status == ScanStatus.zoneFull) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ParkingFullPage(
            availableZones: const ['B', 'C'],
            vehicleType: provider.jenisKendaraan ?? 'Motor',
          ),
        ),
      );
    } else {
      // Show error bottom sheet
      _showErrorSheet(
        provider.scanErrorCode == 'NO_VEHICLE'
            ? 'Profil Kendaraan Kosong'
            : 'Gagal Memproses QR',
        provider.scanErrorMessage ?? 'Terjadi kesalahan, silakan coba lagi.',
      );

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            isScanning = true;
            _isProcessing = false;
          });
        }
      });
    }
  }

  void _showProcessingSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.only(bottom: 32),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Spinner
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: Color(0xFF1E70EB),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Memproses Scan...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mohon tunggu sebentar,\nkami sedang memverifikasi data parkir Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Skeleton shimmer bars
            _buildShimmerBar(),
            const SizedBox(height: 12),
            _buildShimmerBar(),
            const SizedBox(height: 12),
            _buildShimmerBar(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBar() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _showErrorSheet(String title, String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFEF4444), size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    isScanning = true;
                    _isProcessing = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E70EB),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Coba Lagi',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Scan QR Parkiran',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Camera Preview
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),

          // Scanner Overlay with animated laser
          CustomPaint(
            size: Size.infinite,
            painter: _ScannerOverlayPainter(
              animationValue: _animationController,
            ),
          ),

          // Instruction text below viewfinder
          Positioned(
            bottom: 180,
            left: 0,
            right: 0,
            child: Text(
              'Scan barcode yang ada\ndi zona parkir',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Flash Toggle
                _buildControlButton(
                  size: 56,
                  child: ValueListenableBuilder<MobileScannerState>(
                    valueListenable: cameraController,
                    builder: (context, state, child) {
                      final isOn = state.torchState == TorchState.on;
                      return Icon(
                        isOn
                            ? Icons.flashlight_on_rounded
                            : Icons.flashlight_off_rounded,
                        color: isOn ? Colors.amber : Colors.white70,
                        size: 24,
                      );
                    },
                  ),
                  onTap: () => cameraController.toggleTorch(),
                  isAccent: false,
                ),

                const SizedBox(width: 24),

                // Switch Camera (primary action)
                _buildControlButton(
                  size: 72,
                  child: const Icon(
                    Icons.cameraswitch_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  onTap: () => cameraController.switchCamera(),
                  isAccent: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required double size,
    required Widget child,
    required VoidCallback onTap,
    required bool isAccent,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isAccent
              ? const Color(0xFF1E70EB)
              : Colors.white.withOpacity(0.12),
          border: Border.all(
            color: isAccent
                ? const Color(0xFF1E70EB)
                : Colors.white.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: isAccent
              ? [
                  BoxShadow(
                    color: const Color(0xFF1E70EB).withOpacity(0.45),
                    blurRadius: 24,
                    spreadRadius: 6,
                  ),
                ]
              : [],
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Custom Painter: Scanner Overlay with animated laser beam
// ──────────────────────────────────────────────────────────────
class _ScannerOverlayPainter extends CustomPainter {
  final Animation<double> animationValue;

  _ScannerOverlayPainter({required this.animationValue})
      : super(repaint: animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Size and position of the scanning window
    final scanRectSize = width * 0.68;
    final scanRectLeft = (width - scanRectSize) / 2;
    final scanRectTop = (height - scanRectSize) / 2 - 60;
    final scanRect =
        Rect.fromLTWH(scanRectLeft, scanRectTop, scanRectSize, scanRectSize);
    final cornerRadius = 20.0;

    // 1. Draw the dark overlay mask
    final maskPaint = Paint()..color = const Color(0xFF0A0F1E).withOpacity(0.82);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, width, height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, Radius.circular(cornerRadius)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, maskPaint);

    // 2. Draw rounded corner brackets (L-shaped)
    final cornerPaint = Paint()
      ..color = const Color(0xFF1E70EB)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 36.0;
    final r = cornerRadius;

    // Top-Left corner
    final tlPath = Path()
      ..moveTo(scanRect.left, scanRect.top + cornerLen)
      ..lineTo(scanRect.left, scanRect.top + r)
      ..quadraticBezierTo(
          scanRect.left, scanRect.top, scanRect.left + r, scanRect.top)
      ..lineTo(scanRect.left + cornerLen, scanRect.top);
    canvas.drawPath(tlPath, cornerPaint);

    // Top-Right corner
    final trPath = Path()
      ..moveTo(scanRect.right - cornerLen, scanRect.top)
      ..lineTo(scanRect.right - r, scanRect.top)
      ..quadraticBezierTo(
          scanRect.right, scanRect.top, scanRect.right, scanRect.top + r)
      ..lineTo(scanRect.right, scanRect.top + cornerLen);
    canvas.drawPath(trPath, cornerPaint);

    // Bottom-Left corner
    final blPath = Path()
      ..moveTo(scanRect.left, scanRect.bottom - cornerLen)
      ..lineTo(scanRect.left, scanRect.bottom - r)
      ..quadraticBezierTo(
          scanRect.left, scanRect.bottom, scanRect.left + r, scanRect.bottom)
      ..lineTo(scanRect.left + cornerLen, scanRect.bottom);
    canvas.drawPath(blPath, cornerPaint);

    // Bottom-Right corner
    final brPath = Path()
      ..moveTo(scanRect.right - cornerLen, scanRect.bottom)
      ..lineTo(scanRect.right - r, scanRect.bottom)
      ..quadraticBezierTo(
          scanRect.right, scanRect.bottom, scanRect.right, scanRect.bottom - r)
      ..lineTo(scanRect.right, scanRect.bottom - cornerLen);
    canvas.drawPath(brPath, cornerPaint);

    // 3. Draw animated laser beam
    final laserY =
        scanRect.top + 16 + ((scanRect.height - 32) * animationValue.value);

    if (laserY >= scanRect.top && laserY <= scanRect.bottom) {
      // Glow effect
      final glowPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF1E70EB).withOpacity(0.0),
            const Color(0xFF1E70EB).withOpacity(0.6),
            const Color(0xFF60A5FA).withOpacity(0.8),
            const Color(0xFF1E70EB).withOpacity(0.6),
            const Color(0xFF1E70EB).withOpacity(0.0),
          ],
        ).createShader(
            Rect.fromLTWH(scanRect.left, laserY - 16, scanRect.width, 32));

      canvas.drawRect(
        Rect.fromLTWH(
            scanRect.left + 12, laserY - 16, scanRect.width - 24, 32),
        glowPaint,
      );

      // Crisp laser line
      final laserPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF1E70EB).withOpacity(0.0),
            const Color(0xFF60A5FA),
            const Color(0xFF93C5FD),
            const Color(0xFF60A5FA),
            const Color(0xFF1E70EB).withOpacity(0.0),
          ],
        ).createShader(
            Rect.fromLTWH(scanRect.left, laserY - 1, scanRect.width, 2));

      laserPaint.strokeWidth = 2;
      canvas.drawLine(
        Offset(scanRect.left + 12, laserY),
        Offset(scanRect.right - 12, laserY),
        laserPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) => true;
}
