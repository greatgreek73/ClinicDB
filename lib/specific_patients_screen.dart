import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'patient_details_screen.dart';
import 'package:intl/intl.dart';

class SpecificPatientsScreen extends StatelessWidget {
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Специфические пациенты'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('patients')
            .where('price', isGreaterThanOrEqualTo: 300000)
            .where('price', isLessThanOrEqualTo: 400000)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Произошла ошибка: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Нет пациентов, соответствующих критериям цены'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var patientData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              var patientId = snapshot.data!.docs[index].id;

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('treatments')
                    .where('patientId', isEqualTo: patientId)
                    .where('date', isGreaterThanOrEqualTo: DateTime(2024, 7, 1))
                    .where('date', isLessThan: DateTime(2024, 8, 1))
                    .get(),
                builder: (context, treatmentSnapshot) {
                  if (treatmentSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(title: Text('Загрузка данных о лечении...'));
                  }

                  if (treatmentSnapshot.hasError) {
                    return ListTile(title: Text('Ошибка загрузки данных о лечении: ${treatmentSnapshot.error}'));
                  }

                  if (treatmentSnapshot.hasData && treatmentSnapshot.data!.docs.isNotEmpty) {
                    var treatment = treatmentSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text('${patientData['surname']} ${patientData['name']}'),
                      subtitle: Text('Цена: ${patientData['price']}, Дата лечения: ${dateFormat.format((treatment['date'] as Timestamp).toDate())}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PatientDetailsScreen(patientId: patientId),
                          ),
                        );
                      },
                    );
                  }

                  return Container(); // Если нет манипуляций в июле 2024, не показываем пациента
                },
              );
            },
          );
        },
      ),
    );
  }
}