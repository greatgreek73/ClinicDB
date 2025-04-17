import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../patient_details_screen.dart';

class FilteredPatientsScreen extends StatelessWidget {
  final String filterType;
  final String filterName;
  final IconData filterIcon;
  final Color filterColor;

  const FilteredPatientsScreen({
    Key? key,
    required this.filterType,
    required this.filterName,
    required this.filterIcon,
    required this.filterColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(filterIcon, color: filterColor),
            SizedBox(width: 10),
            Text(filterName),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('patients')
            .where(filterType, isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(filterIcon, size: 80, color: filterColor.withOpacity(0.5)),
                  SizedBox(height: 20),
                  Text(
                    'Нет пациентов в категории "$filterName"',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var patientData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              var patientId = snapshot.data!.docs[index].id;

              // Определяем аватар пациента
              Widget avatar;
              if (patientData['photoUrl'] != null && patientData['photoUrl'].toString().isNotEmpty) {
                avatar = CircleAvatar(
                  backgroundImage: NetworkImage(patientData['photoUrl']),
                  radius: 25,
                );
              } else {
                avatar = CircleAvatar(
                  backgroundColor: Colors.grey.shade300,
                  child: Icon(
                    patientData['gender'] == 'Мужской' ? Icons.person : Icons.person_outline,
                    color: Colors.grey.shade700,
                    size: 30,
                  ),
                  radius: 25,
                );
              }

              // Определяем стиль и оформление по статусу
              bool scheduled = patientData['scheduledByAssistant'] == true;
              bool ambiguous = patientData['ambiguousSchedule'] == true;

              Color cardColor = scheduled
                  ? Color(0xFFB9F6CA) // насыщенно-зелёный
                  : ambiguous
                      ? Color(0xFFFFF3E0) // светло-оранжевый
                      : Colors.white;
              Color borderColor = scheduled
                  ? Colors.green.shade700
                  : ambiguous
                      ? Colors.orange.shade700
                      : filterColor.withOpacity(0.3);
              double borderWidth = scheduled || ambiguous ? 3.0 : 1.0;

              Widget? statusLabel = scheduled
                  ? Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_available, color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'В расписании',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ambiguous
                      ? Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade700,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning, color: Colors.white, size: 18),
                              SizedBox(width: 4),
                              Text(
                                'Требует проверки',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : null;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: scheduled ? 6 : ambiguous ? 4 : 2,
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: borderColor,
                    width: borderWidth,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientDetailsScreen(patientId: patientId),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        avatar,
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${patientData['surname']} ${patientData['name']}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: scheduled
                                            ? Colors.green.shade900
                                            : ambiguous
                                                ? Colors.orange.shade900
                                                : Colors.black,
                                      ),
                                    ),
                                  ),
                                  if (statusLabel != null) ...[
                                    SizedBox(width: 8),
                                    statusLabel,
                                  ],
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${patientData['age']} лет | ${patientData['phone'] ?? 'Нет телефона'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: scheduled
                                      ? Colors.green.shade900
                                      : ambiguous
                                          ? Colors.orange.shade900
                                          : Colors.grey.shade600,
                                  fontWeight: scheduled || ambiguous ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                patientData['city'] ?? 'Город не указан',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: scheduled
                                      ? Colors.green.shade900
                                      : ambiguous
                                          ? Colors.orange.shade900
                                          : Colors.grey.shade600,
                                  fontWeight: scheduled || ambiguous ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.navigate_next, color: filterColor)
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
