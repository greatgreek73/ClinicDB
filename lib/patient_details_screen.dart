import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientDetailsScreen extends StatelessWidget {
  final String patientId;

  PatientDetailsScreen({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Детали Пациента'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('patients').doc(patientId).get(),
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              var patientData = snapshot.data!.data() as Map<String, dynamic>;
              return ListView(
                children: <Widget>[
                  ListTile(
                    title: Text('Фамилия'),
                    subtitle: Text(patientData['surname'] ?? 'Нет данных'),
                  ),
                  ListTile(
                    title: Text('Возраст'),
                    subtitle: Text('${patientData['age']}'),
                  ),
                  ListTile(
                    title: Text('Цена'),
                    subtitle: Text('${patientData['price']}'),
                  ),
                  // Добавьте здесь другие поля, если нужно
                ],
              );
            } else if (snapshot.hasError) {
              return Text('Ошибка: ${snapshot.error}');
            }
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
