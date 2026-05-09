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

class _QRScanPageState extends State<QRScanPage> with SingleTickerProviderStateMixin {
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
      duration: const Duration(seconds: 2),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Format QR tidak dikenali!'),
              backgroundColor: Colors.red,
            ),
          );

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => isScanning = true);
          });
        }
        break;
      }
    }
  }

  Future<void> _processScan(String qrCode) async {
    final provider = context.read<ParkingProvider>();

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Memproses QR Code...'),
          ],
        ),
        backgroundColor: Color(0xFF1E70EB),
        duration: Duration(seconds: 10),
      ),
    );

    await provider.scanQR(qrCode);

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final status = provider.scanStatus;

    if (status == ScanStatus.success) {
      // Navigate to Parking Assigned page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ParkingAssignedPage(
            slotNumber: provider.assignedSlot ?? '-',
            zone: provider.assignedZone ?? '-',
          ),
        ),
      );
    } else if (status == ScanStatus.zoneFull) {
      // Navigate to Parking Full page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ParkingFullPage(
            availableZones: ['B', 'C'],
            vehicleType: 'Motor',
          ),
        ),
      );
    } else {
      // Show error and allow re-scan
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.scanErrorMessage ?? 'Terjadi kesalahan'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            isScanning = true;
            _isProcessing = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark mode base
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
            fontFamily: 'Montserrat',
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

          // Scanner Overlay
          CustomPaint(
            size: Size.infinite,
            painter: ScannerOverlayPainter(
              animationValue: _animationController,
            ),
          ),

          // Loading overlay when processing
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF1E70EB),
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Memproses...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                    child: IconButton(
                      icon: ValueListenableBuilder<MobileScannerState>(
                        valueListenable: cameraController,
                        builder: (context, state, child) {
                          final torchState = state.torchState;
                          return Icon(
                            torchState == TorchState.on ? Icons.flashlight_on : Icons.flashlight_off,
                            color: torchState == TorchState.on ? Colors.yellow : Colors.white,
                          );
                        },
                      ),
                      onPressed: () => cameraController.toggleTorch(),
                    ),
                ),

                const SizedBox(width: 32),

                // Camera Switch / Capture
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E70EB),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E70EB).withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.cameraswitch,
                      color: Colors.black,
                      size: 32,
                    ),
                    onPressed: () => cameraController.switchCamera(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Animation<double> animationValue;

  ScannerOverlayPainter({required this.animationValue}) : super(repaint: animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Size and position of the scanning window
    final scanRectSize = width * 0.7;
    final scanRectLeft = (width - scanRectSize) / 2;
    final scanRectTop = (height - scanRectSize) / 2 - 50; 
    final scanRect = Rect.fromLTWH(scanRectLeft, scanRectTop, scanRectSize, scanRectSize);

    // 1. Draw the semi-transparent mask
    final maskPaint = Paint()..color = const Color(0xFF0F172A).withOpacity(0.8);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, width, height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(24)))
      ..fillType = PathFillType.evenOdd;
    
    canvas.drawPath(path, maskPaint);

    // 2. Draw the L-shape corners
    final cornerPaint = Paint()
      ..color = const Color(0xFF1E70EB)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 40.0;

    // Top-Left
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.top + cornerLength)
        ..quadraticBezierTo(scanRect.left, scanRect.top, scanRect.left, scanRect.top)
        ..lineTo(scanRect.left + cornerLength, scanRect.top),
      cornerPaint,
    );

    // Top-Right
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - cornerLength, scanRect.top)
        ..quadraticBezierTo(scanRect.right, scanRect.top, scanRect.right, scanRect.top)
        ..lineTo(scanRect.right, scanRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-Left
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.bottom - cornerLength)
        ..quadraticBezierTo(scanRect.left, scanRect.bottom, scanRect.left, scanRect.bottom)
        ..lineTo(scanRect.left + cornerLength, scanRect.bottom),
      cornerPaint,
    );

    // Bottom-Right
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - cornerLength, scanRect.bottom)
        ..quadraticBezierTo(scanRect.right, scanRect.bottom, scanRect.right, scanRect.bottom)
        ..lineTo(scanRect.right, scanRect.bottom - cornerLength),
      cornerPaint,
    );

    // 3. Draw Laser Beam
    final laserY = scanRect.top + (scanRect.height * animationValue.value);
    
    final glowPaint = Paint()
      ..color = const Color(0xFF1E70EB).withOpacity(0.5)
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
    final laserPaint = Paint()
      ..color = const Color(0xFF1E70EB)
      ..strokeWidth = 2;

    if (laserY >= scanRect.top && laserY <= scanRect.bottom) {
      canvas.drawLine(
        Offset(scanRect.left + 8, laserY),
        Offset(scanRect.right - 8, laserY),
        glowPaint,
      );
      canvas.drawLine(
        Offset(scanRect.left + 8, laserY),
        Offset(scanRect.right - 8, laserY),
        laserPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ScannerOverlayPainter oldDelegate) {
    return true;
  }
}
