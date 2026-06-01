import 'package:flutter/foundation.dart';
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
    with TickerProviderStateMixin {
  late MobileScannerController cameraController;
  late AnimationController _animationController;
  late AnimationController _shimmerController;
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

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Reset scan state when entering this page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ParkingProvider>().resetScanState();
    });
  }

  @override
  void dispose() {
    cameraController.dispose();
    _animationController.dispose();
    _shimmerController.dispose();
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
      final availableZones = provider.zones
          .where((z) => z.tersedia > 0 && 
                        z.jenisKendaraan.toLowerCase() == (provider.jenisKendaraan ?? 'motor').toLowerCase())
          .map((z) => z.nama)
          .toList();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ParkingFullPage(
            availableZones: availableZones.isEmpty ? const ['Belum ada zona lain'] : availableZones,
            vehicleType: provider.jenisKendaraan ?? 'Motor',
          ),
        ),
      );
    } else {
      // Show error bottom sheet
      String title;
      IconData errorIcon;
      Color errorColor;

      switch (provider.scanErrorCode) {
        case 'NO_VEHICLE':
          title = 'Profil Kendaraan Kosong';
          errorIcon = Icons.directions_car_outlined;
          errorColor = const Color(0xFFF59E0B);
          break;
        case 'ALREADY_PARKED':
          title = 'Sesi Parkir Aktif';
          errorIcon = Icons.local_parking_rounded;
          errorColor = const Color(0xFF3B82F6);
          break;
        default:
          title = 'Gagal Memproses QR';
          errorIcon = Icons.warning_amber_rounded;
          errorColor = const Color(0xFFEF4444);
      }

      _showErrorSheet(
        title,
        provider.errorMessage ?? 'Terjadi kesalahan, silakan coba lagi.',
        icon: errorIcon,
        iconColor: errorColor,
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
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
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
            // Animated spinner with glow
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E70EB).withValues(alpha: 0.08),
              ),
              child: const Center(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: Color(0xFF1E70EB),
                  ),
                ),
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
            // Shimmer skeleton bars
            _ShimmerBar(controller: _shimmerController, width: double.infinity),
            const SizedBox(height: 12),
            _ShimmerBar(controller: _shimmerController, width: double.infinity, delay: 0.15),
            const SizedBox(height: 12),
            _ShimmerBar(controller: _shimmerController, width: double.infinity, delay: 0.3),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showErrorSheet(String title, String message, {
    IconData icon = Icons.warning_amber_rounded,
    Color iconColor = const Color(0xFFEF4444),
  }) {
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
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 36),
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
    return SafeArea(
      child: Scaffold(
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
            bottom: kIsWeb ? 230 : 180,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'Scan barcode yang ada\ndi zona parkir',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          if (kIsWeb)
            Positioned(
              bottom: 160,
              left: 40,
              right: 40,
              child: ElevatedButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () => _processScan('Zone A'),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.bug_report_rounded),
                label: Text(_isProcessing
                    ? 'Memproses...'
                    : 'Simulasi Bypass Scan (Debug)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isProcessing
                      ? const Color(0xFFD97706)
                      : const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),

          // Bottom Controls
          Positioned(
            bottom: 60,
            left: 32,
            right: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Flash Toggle
                Positioned(
                  left: 0,
                  child: _buildControlButton(
                    size: 56,
                    child: ValueListenableBuilder<MobileScannerState>(
                      valueListenable: cameraController,
                      builder: (context, state, child) {
                        final isOn = state.torchState == TorchState.on;
                        return Icon(
                          isOn
                              ? Icons.flashlight_on_rounded
                              : Icons.flashlight_off_rounded,
                          color: isOn ? Colors.amber : Colors.white,
                          size: 24,
                        );
                      },
                    ),
                    onTap: () => cameraController.toggleTorch(),
                    isAccent: false,
                  ),
                ),

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
    ),
    );
  }

  Widget _buildControlButton({
    required double size,
    required Widget child,
    required VoidCallback onTap,
    required bool isAccent,
    String? label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isAccent
                  ? const Color(0xFF3B82F6)
                  : Colors.black.withValues(alpha: 0.5),
              border: Border.all(
                color: isAccent
                    ? const Color(0xFF3B82F6)
                    : Colors.white.withValues(alpha: 0.1),
                width: 2,
              ),
              boxShadow: isAccent
                  ? [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                        blurRadius: 24,
                        spreadRadius: 6,
                      ),
                    ]
                  : [],
            ),
            child: Center(child: child),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Shimmer Bar Widget for Processing Sheet
// ──────────────────────────────────────────────────────────────
class _ShimmerBar extends StatelessWidget {
  final AnimationController controller;
  final double width;
  final double delay;

  const _ShimmerBar({
    required this.controller,
    required this.width,
    this.delay = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = ((controller.value + delay) % 1.0);
        return Container(
          width: width,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * value, 0),
              end: Alignment(-1.0 + 2.0 * value + 1.0, 0),
              colors: const [
                Color(0xFFF1F5F9),
                Color(0xFFE2E8F0),
                Color(0xFFF1F5F9),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
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
    final maskPaint = Paint()..color = const Color(0xFF0A0F1E).withValues(alpha: 0.82);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, width, height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, Radius.circular(cornerRadius)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, maskPaint);

    // 2. Draw rounded corner brackets (L-shaped) with glow
    final cornerPaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowCornerPaint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.4)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    const cornerLen = 36.0;
    final r = cornerRadius;

    // Helper to draw a corner with both glow and crisp line
    void drawCorner(Path cornerPath) {
      canvas.drawPath(cornerPath, glowCornerPaint);
      canvas.drawPath(cornerPath, cornerPaint);
    }

    // Top-Left corner
    final tlPath = Path()
      ..moveTo(scanRect.left, scanRect.top + cornerLen)
      ..lineTo(scanRect.left, scanRect.top + r)
      ..quadraticBezierTo(
          scanRect.left, scanRect.top, scanRect.left + r, scanRect.top)
      ..lineTo(scanRect.left + cornerLen, scanRect.top);
    drawCorner(tlPath);

    // Top-Right corner
    final trPath = Path()
      ..moveTo(scanRect.right - cornerLen, scanRect.top)
      ..lineTo(scanRect.right - r, scanRect.top)
      ..quadraticBezierTo(
          scanRect.right, scanRect.top, scanRect.right, scanRect.top + r)
      ..lineTo(scanRect.right, scanRect.top + cornerLen);
    drawCorner(trPath);

    // Bottom-Left corner
    final blPath = Path()
      ..moveTo(scanRect.left, scanRect.bottom - cornerLen)
      ..lineTo(scanRect.left, scanRect.bottom - r)
      ..quadraticBezierTo(
          scanRect.left, scanRect.bottom, scanRect.left + r, scanRect.bottom)
      ..lineTo(scanRect.left + cornerLen, scanRect.bottom);
    drawCorner(blPath);

    // Bottom-Right corner
    final brPath = Path()
      ..moveTo(scanRect.right - cornerLen, scanRect.bottom)
      ..lineTo(scanRect.right - r, scanRect.bottom)
      ..quadraticBezierTo(
          scanRect.right, scanRect.bottom, scanRect.right, scanRect.bottom - r)
      ..lineTo(scanRect.right, scanRect.bottom - cornerLen);
    drawCorner(brPath);

    // 3. Draw animated laser beam
    final laserY =
        scanRect.top + 16 + ((scanRect.height - 32) * animationValue.value);

    if (laserY >= scanRect.top && laserY <= scanRect.bottom) {
      // Glow effect
      final glowPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF1E70EB).withValues(alpha: 0.0),
            const Color(0xFF1E70EB).withValues(alpha: 0.6),
            const Color(0xFF60A5FA).withValues(alpha: 0.8),
            const Color(0xFF1E70EB).withValues(alpha: 0.6),
            const Color(0xFF1E70EB).withValues(alpha: 0.0),
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
            const Color(0xFF1E70EB).withValues(alpha: 0.0),
            const Color(0xFF60A5FA),
            const Color(0xFF93C5FD),
            const Color(0xFF60A5FA),
            const Color(0xFF1E70EB).withValues(alpha: 0.0),
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
