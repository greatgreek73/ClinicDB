import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeline_tile/timeline_tile.dart';

import 'edit_patient_screen.dart';
import 'add_treatment_screen.dart';

class PatientDetailsScreen extends StatelessWidget {
  final String patientId;
  final TextEditingController _plannedTreatmentController = TextEditingController();

  PatientDetailsScreen({required this.patientId});

  @override
  Widget build(BuildContext context) {
    _loadPlannedTreatment();
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
              );
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
              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(width: 1),
                      color: Colors.white,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Фамилия: ${patientData['surname'] ?? 'Нет данных'}', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Имя: ${patientData['name'] ?? 'Нет данных'}'),
                          Text('Возраст: ${patientData['age']}'),
                          Text('Город: ${patientData['city'] ?? 'Нет данных'}'),
                          Text('Телефон: ${patientData['phone'] ?? 'Нет данных'}'),
                          Text('Цена: ${patientData['price'] ?? 'Нет данных'}', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildTreatmentTimeline(context, patientId),
                  ),
                ],
              );
            } else if (snapshot.hasError) {
              return Text('Ошибка: ${snapshot.error}');
            }
            return Text('Нет данных');
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Future<void> _loadPlannedTreatment() async {
    final prefs = await SharedPreferences.getInstance();
    String treatment = prefs.getString('planned_treatment_$patientId') ?? '';
    _plannedTreatmentController.text = treatment;
  }

  Widget _buildTreatmentTimeline(BuildContext context, String patientId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('treatments').where('patientId', isEqualTo: patientId).orderBy('date', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Ошибка загрузки данных о лечении: ${snapshot.error}');
        } else if (snapshot.hasData) {
          List<TreatmentInfo> treatments = snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            DateTime date = (data['date'] as Timestamp).toDate();
            return TreatmentInfo(
              treatmentType: data['treatmentType'],
              toothNumbers: List<int>.from(data['toothNumber'] ?? []),
              status: data['status'] ?? 'Неизвестно',
              date: date,
            );
          }).toList();
          return ListView.builder(
            itemCount: treatments.length,
            itemBuilder: (context, index) {
              final treatment = treatments[index];
              bool isLast = index == treatments.length - 1;
              return TimelineTile(
                alignment: TimelineAlign.manual,
                lineXY: 0.2,
                isFirst: index == 0,
                isLast: isLast,
                indicatorStyle: IndicatorStyle(
                  width: 20,
                  color: Colors.purple,
                  padding: EdgeInsets.all(6),
                ),
                beforeLineStyle: LineStyle(
                  color: Colors.purple,
                  thickness: 5,
                ),
                endChild: Card(
                  margin: EdgeInsets.symmetric(vertical: 20),
                  child: ListTile(
                    title: Text(DateFormat('yyyy-MM-dd').format(treatment.date)),
                    subtitle: Text('${treatment.treatmentType} - ${treatment.status}' + 
                    (treatment.toothNumbers.isNotEmpty ? ', Зубы: ${treatment.toothNumbers.join(", ")}' : '')),
                    trailing: Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AddTreatmentScreen(patientId: patientId),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        }
        return Text('Нет данных о лечении');
      },
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
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Удалить'),
              onPressed: () {
                FirebaseFirestore.instance.collection('patients').doc(patientId).delete().then((_) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                });
              },
            ),
          ],
        );
      },
    );
  }
}

class TreatmentInfo {
  String treatmentType;
  List<int> toothNumbers;
  String status;
  DateTime date;

  TreatmentInfo({
    required this.treatmentType,
    required this.toothNumbers,
    required this.status,
    required this.date,
  });
}
