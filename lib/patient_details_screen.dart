import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_patient_screen.dart'; // Экран редактирования пациента
import 'add_treatment_screen.dart'; // Экран добавления лечения
import 'package:intl/intl.dart'; // Для форматирования дат

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
                        .orderBy('date', descending: true)
                        .snapshots(),
                    builder: (context, treatmentSnapshot) {
                      if (treatmentSnapshot.hasError) {
                        // Логирование ошибки
                        print("Ошибка загрузки данных о лечении: ${treatmentSnapshot.error}");
                        return Text('Ошибка загрузки данных о лечении');
                      }
                      if (treatmentSnapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }
                      var treatments = _groupTreatmentsByDate(treatmentSnapshot.data!.docs);

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: treatments.keys.length,
                        itemBuilder: (context, index) {
                          DateTime date = treatments.keys.elementAt(index);
                          List<Map<String, dynamic>> treatmentsForDate = treatments[date]!;
                          return ExpansionTile(
                            title: Text(DateFormat('yyyy-MM-dd').format(date)),
                            children: treatmentsForDate.map((treatmentData) {
                              return ListTile(
                                title: Text(treatmentData['treatmentType']),
                                subtitle: Text('Зуб: ${treatmentData['toothNumber']}'),
                              );
                            }).toList(),
                          );
                        },
                      );
                    },
                  ),
                ],
              );
            } else if (snapshot.hasError) {
              // Логирование ошибки
              print("Ошибка получения данных пациента: ${snapshot.error}");
              return Text('Ошибка: ${snapshot.error}');
            }
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Map<DateTime, List<Map<String, dynamic>>> _groupTreatmentsByDate(List<DocumentSnapshot> docs) {
    Map<DateTime, List<Map<String, dynamic>>> groupedTreatments = {};
    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null && data['date'] is Timestamp) {
        var date = (data['date'] as Timestamp).toDate();
        if (!groupedTreatments.containsKey(date)) {
          groupedTreatments[date] = [];
        }
        groupedTreatments[date]!.add(data);
      } else {
        print("Документ не содержит даты или дата не является Timestamp: $data");
      }
    }
    return groupedTreatments;
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
