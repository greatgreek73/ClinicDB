import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> updateAllPatients() async {
  final patientsCollection = FirebaseFirestore.instance.collection('patients');
  final snapshot = await patientsCollection.get();

  int updated = 0;

  for (var doc in snapshot.docs) {
    final data = doc.data();

    bool hasWaitingList = data.containsKey('waitingList');
    bool hasSecondStage = data.containsKey('secondStage');

    if (!hasWaitingList || !hasSecondStage) {
      await patientsCollection.doc(doc.id).update({
        if (!hasWaitingList) 'waitingList': false,
        if (!hasSecondStage) 'secondStage': false,
      });
      updated++;
    }
  }

  print("✅ Обновлено пациентов: $updated");
}
