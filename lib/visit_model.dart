class Visit {
  String patientId;
  String treatmentDetails;
  DateTime date;

  Visit({required this.patientId, required this.treatmentDetails, required this.date});

  // Метод для преобразования в Map, если требуется для работы с Firestore
  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'treatmentDetails': treatmentDetails,
      'date': date,
    };
  }
}
