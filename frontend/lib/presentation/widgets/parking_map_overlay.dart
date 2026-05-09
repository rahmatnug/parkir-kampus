import 'package:flutter/material.dart';

class ParkingMapOverlay extends StatelessWidget {
  final String zone;
  final String slotNumber;

  const ParkingMapOverlay({
    Key? key,
    required this.zone,
    required this.slotNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        image: const DecorationImage(
          image: AssetImage('assets/images/parking_map.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Dynamic indicator overlay based on zone/slot
          // Note: In a real app, calculate top/left relative to map coordinates.
          Positioned(
            top: 120, 
            left: MediaQuery.of(context).size.width / 2 - 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.9),
                border: Border.all(color: Colors.orange, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Slot #$slotNumber',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
