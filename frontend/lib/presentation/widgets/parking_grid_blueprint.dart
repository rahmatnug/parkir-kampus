import 'package:flutter/material.dart';

/// Reusable parking grid blueprint showing MOBIL (left) and MOTOR (right) corridors.
/// Used by both ParkingAssignedPage and ExitParkingPage.
class ParkingGridBlueprint extends StatefulWidget {
  final String zoneName;
  final String? highlightSlot;
  final bool showSlotAsEmpty;

  const ParkingGridBlueprint({
    super.key,
    required this.zoneName,
    this.highlightSlot,
    this.showSlotAsEmpty = false,
  });

  @override
  State<ParkingGridBlueprint> createState() => _ParkingGridBlueprintState();
}

class _ParkingGridBlueprintState extends State<ParkingGridBlueprint>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkCtrl;
  late Animation<double> _blinkAnim;

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _blinkAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4B5563), width: 1),
      ),
      child: Column(
        children: [
          // Gate header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1F2937),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDashedLine(),
                const SizedBox(width: 8),
                Text(
                  'Keluar Masuk ${widget.zoneName}',
                  style: const TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                _buildDashedLine(),
              ],
            ),
          ),
          // Parking grid body
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // MOBIL section (left)
                Expanded(
                  flex: 2,
                  child: _buildSection('MOBIL', Icons.directions_car_rounded, 3, 2, true),
                ),
                // Divider road
                Container(width: 2, height: 200, color: const Color(0xFF6B7280)),
                // MOTOR sections (right)
                Expanded(
                  flex: 3,
                  child: Row(
                    children: List.generate(4, (col) {
                      return Expanded(
                        child: _buildSection('MOTOR', Icons.two_wheeler_rounded, 4, 1, false, col),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedLine() {
    return Row(
      children: List.generate(6, (_) {
        return Container(
          width: 8, height: 2,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          color: const Color(0xFFFBBF24),
        );
      }),
    );
  }

  Widget _buildSection(String label, IconData icon, int rows, int cols, bool isLarge, [int? colIndex]) {
    return Column(
      children: [
        // Section label
        RotatedBox(
          quarterTurns: isLarge ? 0 : 1,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: isLarge ? 2 : 0),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 7,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        // Slots grid
        ...List.generate(rows, (row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(cols, (col) {
              final slotNum = isLarge
                  ? '${row * cols + col + 1}'
                  : '${(colIndex ?? 0) * rows + row + 1}';
              final isHighlighted = widget.highlightSlot != null &&
                  slotNum == widget.highlightSlot;
              return _buildSlotCell(icon, isLarge, isHighlighted);
            }),
          );
        }),
      ],
    );
  }

  Widget _buildSlotCell(IconData icon, bool isLarge, bool isHighlighted) {
    final size = isLarge ? 32.0 : 22.0;
    final iconSize = isLarge ? 16.0 : 10.0;

    Widget cell = Container(
      width: size, height: size,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isHighlighted
            ? (widget.showSlotAsEmpty ? const Color(0xFF22C55E) : const Color(0xFFDC2626))
            : const Color(0xFF4B5563),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isHighlighted ? Colors.white : const Color(0xFF6B7280),
          width: isHighlighted ? 1.5 : 0.5,
        ),
      ),
      child: Icon(icon, size: iconSize,
        color: isHighlighted ? Colors.white : Colors.white.withOpacity(0.5)),
    );

    if (isHighlighted && !widget.showSlotAsEmpty) {
      return AnimatedBuilder(
        animation: _blinkAnim,
        builder: (_, __) => Opacity(opacity: _blinkAnim.value, child: cell),
      );
    }
    return cell;
  }
}
