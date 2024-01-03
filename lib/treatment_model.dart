import 'package:cloud_firestore/cloud_firestore.dart';

class Treatment {
  String id;
  String patientId;
  String treatmentType;
  List<int> toothNumbers; // Изменено на список целых чисел
  double cost;
  DateTime date;

  Treatment({
    required this.id,
    required this.patientId,
    required this.treatmentType,
    required this.toothNumbers, // Изменено на соответствие списку
    required this.cost,
    required this.date,
  });

  factory Treatment.fromFirestore(Map<String, dynamic> firestore) {
    return Treatment(
      id: firestore['id'] as String,
      patientId: firestore['patientId'] as String,
      treatmentType: firestore['treatmentType'] as String,
      toothNumbers: List<int>.from(firestore['toothNumbers']),
      cost: (firestore['cost'] as num).toDouble(),
      date: (firestore['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'treatmentType': treatmentType,
      'toothNumbers': toothNumbers, // Сохраняем как список
      'cost': cost,
      'date': Timestamp.fromDate(date),
    };
  }
}
