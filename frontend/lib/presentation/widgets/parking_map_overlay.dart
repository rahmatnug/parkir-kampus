import 'package:flutter/material.dart';

/// Widget overlay peta parkir yang menampilkan pin dinamis berdasarkan
/// koordinat (x_coord, y_coord) dari database backend.
///
/// Koordinat dinormalisasi agar pin selalu proporsional di dalam
/// container peta, terlepas dari ukuran layar.
class ParkingMapOverlay extends StatelessWidget {
  final String zone;
  final String slotNumber;
  final double xCoord;
  final double yCoord;

  // Maksimum range koordinat dari database seeder
  // Sesuaikan jika seeder berubah
  static const double _maxX = 400.0;
  static const double _maxY = 500.0;

  const ParkingMapOverlay({
    Key? key,
    required this.zone,
    required this.slotNumber,
    required this.xCoord,
    required this.yCoord,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;
        const containerHeight = 260.0;

        // Normalisasi koordinat agar pin selalu di dalam container
        // dengan padding 8% agar pin tidak terpotong di tepi
        final padX = containerWidth * 0.08;
        final padY = containerHeight * 0.08;
        final usableW = containerWidth - (padX * 2);
        final usableH = containerHeight - (padY * 2);

        final pinLeft = padX + (xCoord / _maxX).clamp(0.0, 1.0) * usableW;
        final pinTop = padY + (yCoord / _maxY).clamp(0.0, 1.0) * usableH;

        return Container(
          width: double.infinity,
          height: containerHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            image: const DecorationImage(
              image: AssetImage('assets/images/parking_map.png'),
              fit: BoxFit.cover,
              opacity: 0.15,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Grid lines untuk efek peta
              CustomPaint(
                size: Size(containerWidth, containerHeight),
                painter: _GridPainter(),
              ),

              // Zone labels
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E70EB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: const Color(0xFF1E70EB).withOpacity(0.3)),
                  ),
                  child: Text(
                    'Zone $zone',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E70EB),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // Animated Pin
              Positioned(
                left: pinLeft - 20,
                top: pinTop - 44,
                child: _AnimatedPin(slotNumber: slotNumber),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedPin extends StatefulWidget {
  final String slotNumber;
  const _AnimatedPin({required this.slotNumber});

  @override
  State<_AnimatedPin> createState() => _AnimatedPinState();
}

class _AnimatedPinState extends State<_AnimatedPin>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _bounce = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounce.value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E70EB),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E70EB).withOpacity(0.35),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  '#${widget.slotNumber}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Arrow triangle
              CustomPaint(
                size: const Size(12, 6),
                painter: _TrianglePainter(),
              ),
              // Pin dot
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E70EB),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E70EB).withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1E70EB);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0).withOpacity(0.5)
      ..strokeWidth = 0.5;

    // Vertical lines
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Horizontal lines
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
