import 'package:cloud_firestore/cloud_firestore.dart';

class Treatment {
  String id;
  String patientId;
  String treatmentType;
  int toothNumber;
  double cost;
  DateTime date; // Новое поле для даты лечения

  Treatment({
    required this.id,
    required this.patientId,
    required this.treatmentType,
    required this.toothNumber,
    required this.cost,
    required this.date, // Требуем дату при инициализации
  });

  // Метод для создания объекта Treatment из данных Firestore
  factory Treatment.fromFirestore(Map<String, dynamic> firestore) {
    return Treatment(
      id: firestore['id'],
      patientId: firestore['patientId'],
      treatmentType: firestore['treatmentType'],
      toothNumber: firestore['toothNumber'],
      cost: firestore['cost'],
      date: (firestore['date'] as Timestamp).toDate(), // Преобразуем Timestamp в DateTime
    );
  }

  // Метод для преобразования объекта Treatment в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'treatmentType': treatmentType,
      'toothNumber': toothNumber,
      'cost': cost,
      'date': Timestamp.fromDate(date), // Сохраняем DateTime как Timestamp
    };
  }
}
