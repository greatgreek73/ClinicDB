import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_patient_screen.dart'; // Экран редактирования пациента
import 'add_treatment_screen.dart'; // Экран добавления лечения

class PatientDetailsScreen extends StatelessWidget {
  final String patientId;

  PatientDetailsScreen({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Детали Пациента'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditPatientScreen(patientId: patientId),
                ),
              ).then((_) {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PatientDetailsScreen(patientId: patientId),
                  ),
                );
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddTreatmentScreen(patientId: patientId),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _confirmDeletion(context, patientId),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('patients').doc(patientId).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              var patientData = snapshot.data!.data() as Map<String, dynamic>;
              return ListView(
                children: <Widget>[
                  ListTile(
                    title: Text('Фамилия'),
                    subtitle: Text(patientData['surname'] ?? 'Нет данных'),
                  ),
                  ListTile(
                    title: Text('Имя'),
                    subtitle: Text(patientData['name'] ?? 'Нет данных'),
                  ),
                  ListTile(
                    title: Text('Возраст'),
                    subtitle: Text('${patientData['age']}'),
                  ),
                  ListTile(
                    title: Text('Город'),
                    subtitle: Text(patientData['city'] ?? 'Нет данных'),
                  ),
                  ListTile(
                    title: Text('Телефон'),
                    subtitle: Text(patientData['phone'] ?? 'Нет данных'),
                  ),
                  ListTile(
                    title: Text('Цена'),
                    subtitle: Text('${patientData['price']}'),
                  ),
                  ListTile(
                    title: Text('Фото'),
                    subtitle: patientData['photoUrl'] != null
                      ? Image.network(patientData['photoUrl'])
                      : Text('Нет фото'),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('treatments')
                        .where('patientId', isEqualTo: patientId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Ошибка загрузки данных о лечении');
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }
                      return Column(
                        children: snapshot.data!.docs.map((DocumentSnapshot document) {
                          Map<String, dynamic> treatmentData = document.data()! as Map<String, dynamic>;
                          return Card(
                            child: ListTile(
                              title: Text(treatmentData['treatmentType'] ?? 'Лечение'),
                              subtitle: Text('Зуб: ${treatmentData['toothNumber']}'),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
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

  void _confirmDeletion(BuildContext context, String patientId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Удалить пациента'),
          content: Text('Вы уверены, что хотите удалить этого пациента?'),
          actions: <Widget>[
            TextButton(
              child: Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Удалить'),
              onPressed: () {
                FirebaseFirestore.instance.collection('patients').doc(patientId).delete().then((_) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                });
              },
            ),
          ],
        );
      },
    );
  }
}
