class Visit {
  final String id;
  final DateTime date;
  final String description;
  final String patientId;

  Visit({this.id, required this.date, required this.description, required this.patientId});

  // Конвертация объекта Visit в Map для Firestore
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'description': description,
      'patientId': patientId,
    };
  }

  // Конвертация данных из Firestore в объект Visit
  static Visit fromJson(Map<String, dynamic> json, String id) {
    return Visit(
      id: id,
      date: (json['date'] as Timestamp).toDate(),
      description: json['description'],
      patientId: json['patientId'],
    );
  }
}
