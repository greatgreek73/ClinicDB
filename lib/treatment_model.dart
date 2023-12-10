class Treatment {
  String id;
  String patientId;
  String treatmentType;
  int toothNumber;
  double cost;

  Treatment({
    required this.id,
    required this.patientId,
    required this.treatmentType,
    required this.toothNumber,
    required this.cost,
  });

  // Метод для создания объекта Treatment из данных Firestore
  factory Treatment.fromFirestore(Map<String, dynamic> firestore) {
    return Treatment(
      id: firestore['id'],
      patientId: firestore['patientId'],
      treatmentType: firestore['treatmentType'],
      toothNumber: firestore['toothNumber'],
      cost: firestore['cost'],
    );
  }

  // Метод для преобразования объекта Treatment в Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'treatmentType': treatmentType,
      'toothNumber': toothNumber,
      'cost': cost,
    };
  }
}
