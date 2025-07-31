import 'treatment_type.dart';

class TreatmentCounts {
  final int totalTeeth;
  final Map<TreatmentType, int> byType;

  const TreatmentCounts({
    required this.totalTeeth,
    required this.byType,
  });

  factory TreatmentCounts.empty() => const TreatmentCounts(
        totalTeeth: 0,
        byType: {},
      );

  TreatmentCounts copyWith({
    int? totalTeeth,
    Map<TreatmentType, int>? byType,
  }) {
    return TreatmentCounts(
      totalTeeth: totalTeeth ?? this.totalTeeth,
      byType: byType ?? this.byType,
    );
  }

  // Удобный билдер из произвольной коллекции процедур с длиной списка зубов
  static TreatmentCounts fromIterable(Iterable<({TreatmentType type, int teethCount})> items) {
    int total = 0;
    final map = <TreatmentType, int>{};
    for (final item in items) {
      total += item.teethCount;
      map[item.type] = (map[item.type] ?? 0) + item.teethCount;
    }
    return TreatmentCounts(totalTeeth: total, byType: Map.unmodifiable(map));
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTeeth': totalTeeth,
      'byType': byType.map((k, v) => MapEntry(k.asFirestoreString, v)),
    };
  }

  factory TreatmentCounts.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const {};
    final rawByType = (map['byType'] as Map?) ?? const {};
    final parsedByType = <TreatmentType, int>{};
    rawByType.forEach((key, value) {
      final t = TreatmentType.fromString(key?.toString());
      final v = value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
      parsedByType[t] = v;
    });
    final total = map['totalTeeth'] is int
        ? map['totalTeeth'] as int
        : int.tryParse(map['totalTeeth']?.toString() ?? '') ?? 0;

    return TreatmentCounts(
      totalTeeth: total,
      byType: Map.unmodifiable(parsedByType),
    );
  }
}
