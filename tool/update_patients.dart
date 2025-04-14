import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../lib/firebase_options.dart';

Future<void> main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final patientsCollection = FirebaseFirestore.instance.collection('patients');
  final snapshot = await patientsCollection.get();

  print('🔍 Найдено пациентов: ${snapshot.docs.length}');
  int updated = 0;

  for (var doc in snapshot.docs) {
    final data = doc.data();

    bool hasWaitingList = data.containsKey('waitingList');
    bool hasSecondStage = data.containsKey('secondStage');
    bool hasHotPatient = data.containsKey('hotPatient');

    if (!hasWaitingList || !hasSecondStage || !hasHotPatient) {
      await patientsCollection.doc(doc.id).update({
        if (!hasWaitingList) 'waitingList': false,
        if (!hasSecondStage) 'secondStage': false,
        if (!hasHotPatient) 'hotPatient': false,
      });
      updated++;
    }
  }

  print('✅ Обновлено пациентов: $updated');
}
