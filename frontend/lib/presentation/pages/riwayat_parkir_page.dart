import 'package:flutter/material.dart';
import '../../data/models/parking_history.dart';
import '../widgets/history_card.dart';

class RiwayatParkirPage extends StatelessWidget {
  const RiwayatParkirPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: dummyHistoryData.length,
      itemBuilder: (context, index) {
        return HistoryCard(history: dummyHistoryData[index]);
      },
    );
  }
}
