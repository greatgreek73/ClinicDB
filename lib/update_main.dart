import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final patientsCollection = FirebaseFirestore.instance.collection('patients');
  final snapshot = await patientsCollection.get();

  print('🔍 Найдено пациентов: ${snapshot.docs.length}');
  int updated = 0;

  for (var doc in snapshot.docs) {
    final data = doc.data();

    bool hasHot = data.containsKey('hotPatient');

    if (!hasHot) {
      await patientsCollection.doc(doc.id).update({
        'hotPatient': false,
      });
      updated++;
    }
  }

  print('✅ Обновлено пациентов: $updated');

  runApp(MaterialApp(
    home: Scaffold(
      body: Center(child: Text('Обновлено пациентов: $updated')),
    ),
  ));
}
