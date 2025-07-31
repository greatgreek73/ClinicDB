import 'treatment_type.dart';

class Treatment {
  final String id;
  final DateTime? date;
  final TreatmentType treatmentType;
  final List<int> toothNumbers; // допущение: храним как список номеров зубов
  final String? patientId;

  const Treatment({
    required this.id,
    required this.treatmentType,
    required this.toothNumbers,
    this.date,
    this.patientId,
  });

  factory Treatment.fromJson(String id, Map<String, dynamic>? json) {
    final map = json ?? const {};
    final typeRaw = map['treatmentType'];
    final dateRaw = map['date'];
    final toothRaw = map['toothNumber'] ?? map['toothNumbers'];

    // Разбор даты: Firestore Timestamp/ISO8601/epoch
    DateTime? parsedDate;
    if (dateRaw is DateTime) {
      parsedDate = dateRaw;
    } else if (dateRaw is String) {
      parsedDate = DateTime.tryParse(dateRaw);
    } else if (dateRaw is int) {
      // epoch millis
      parsedDate = DateTime.fromMillisecondsSinceEpoch(dateRaw, isUtc: false);
    } else if (dateRaw != null && dateRaw.toString().isNotEmpty) {
      // На случай, если придёт другой тип с toString
      parsedDate = DateTime.tryParse(dateRaw.toString());
    }

    // Разбор списка зубов: допускаем List<int> / List<num> / List<String>
    final List<int> teeth = [];
    if (toothRaw is List) {
      for (final v in toothRaw) {
        if (v is int) {
          teeth.add(v);
        } else if (v is num) {
          teeth.add(v.toInt());
        } else if (v is String) {
          final parsed = int.tryParse(v);
          if (parsed != null) teeth.add(parsed);
        }
      }
    }

    return Treatment(
      id: id,
      date: parsedDate,
      treatmentType: TreatmentType.fromString(typeRaw?.toString()),
      toothNumbers: teeth,
      patientId: map['patientId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date?.toIso8601String(),
      'treatmentType': treatmentType.asFirestoreString,
      'toothNumber': toothNumbers,
      'patientId': patientId,
    };
  }

  Treatment copyWith({
    String? id,
    DateTime? date,
    TreatmentType? treatmentType,
    List<int>? toothNumbers,
    String? patientId,
  }) {
    return Treatment(
      id: id ?? this.id,
      date: date ?? this.date,
      treatmentType: treatmentType ?? this.treatmentType,
      toothNumbers: toothNumbers ?? this.toothNumbers,
      patientId: patientId ?? this.patientId,
    );
  }
}
