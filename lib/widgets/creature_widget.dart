import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Widget that visualizes the "creature" mood depending on today's treatment count.
class CreatureWidget extends StatelessWidget {
  const CreatureWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('treatments')
          .where('date', isEqualTo: Timestamp.fromDate(today))
          .snapshots(),
      builder: (context, snapshot) {
        int count = snapshot.hasData ? snapshot.data!.docs.length : 0;

        IconData icon;
        Color color;
        String label;

        if (count <= 5) {
          icon = Icons.sentiment_satisfied_alt;
          color = Colors.green;
          label = 'Спокоен';
        } else if (count <= 10) {
          icon = Icons.sentiment_neutral;
          color = Colors.amber;
          label = 'Нервничает';
        } else if (count <= 20) {
          icon = Icons.sentiment_dissatisfied;
          color = Colors.orange;
          label = 'Раздражен';
        } else {
          icon = Icons.sentiment_very_dissatisfied;
          color = Colors.red;
          label = 'Бешенство';
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 80),
            const SizedBox(height: 8),
            Text(
              'Пациентов сегодня: $count',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        );
      },
    );
  }
}
