import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/patient.dart';
import '../../domain/models/treatment.dart';
import '../../domain/models/treatment_counts.dart';
import '../../domain/models/treatment_type.dart';
import '../../domain/repositories/dashboard_repository.dart';

class FirebaseDashboardRepository implements DashboardRepository {
  final FirebaseFirestore _db;

  FirebaseDashboardRepository(FirebaseFirestore db) : _db = db;

  DateTime _truncateToDate(DateTime date) => DateTime(date.year, date.month, date.day);

  ({DateTime start, DateTime end}) _currentWeekRange() {
    final today = _truncateToDate(DateTime.now());
    final start = today.subtract(Duration(days: today.weekday - DateTime.monday));
    final end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return (start: start, end: end);
  }

  // Вспомогательная функция: считает пациентов с суммарно ровно 1 имплантом в снапшоте
  int _countOneImplantPatientsFromSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    final Map<String, int> perPatient = {};
    for (final doc in snap.docs) {
      final data = doc.data();
      final String patientId = (data['patientId'] as String?) ?? '';
      if (patientId.isEmpty) continue;
      final List<dynamic> toothNumbersDyn = List.from(data['toothNumber'] ?? []);
      final int implantsInThisTreatment = toothNumbersDyn.length;
      perPatient.update(patientId, (v) => v + implantsInThisTreatment, ifAbsent: () => implantsInThisTreatment);
    }
    return perPatient.values.where((v) => v == 1).length;
  }

  @override
  Stream<List<Patient>> watchPatients() {
    return _db.collection('patients').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Patient.fromJson(doc.id, (doc.data() as Map<String, dynamic>?)))
          .toList(growable: false);
    });
  }

  @override
  Future<TreatmentCounts> getTreatmentCounts({
    required DateTime startInclusive,
    required DateTime endInclusive,
    Set<TreatmentType>? types,
  }) async {
    final col = _db.collection('treatments');
    Query query = col
        .where('date', isGreaterThanOrEqualTo: startInclusive)
        .where('date', isLessThanOrEqualTo: endInclusive);

    if (types != null && types.isNotEmpty) {
      final typeStrings = types.map((e) => e.asFirestoreString).toList();
      query = query.where('treatmentType', whereIn: typeStrings);
    }

    final snap = await query.get();
    final items = snap.docs.map((doc) {
      final t = Treatment.fromJson(doc.id, (doc.data() as Map<String, dynamic>?));
      final count = t.toothNumbers.length;
      return (type: t.treatmentType, teethCount: count);
    });

    return TreatmentCounts.fromIterable(items);
  }

  @override
  Stream<int> watchOneImplantPatientsCountForCurrentMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final query = _db
        .collection('treatments')
        .where('treatmentType', isEqualTo: TreatmentType.implant.asFirestoreString)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end);

    return query.snapshots().map(_countOneImplantPatientsFromSnapshot);
  }

  @override
  Stream<int> watchOneImplantPatientsCountForCurrentYear() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final end = DateTime(now.year, 12, 31, 23, 59, 59);

    final query = _db
        .collection('treatments')
        .where('treatmentType', isEqualTo: TreatmentType.implant.asFirestoreString)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end);

    return query.snapshots().map(_countOneImplantPatientsFromSnapshot);
  }

  @override
  Stream<TreatmentCounts> watchTreatmentCountsForCurrentMonth({
    Set<TreatmentType>? types,
  }) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    Query query = _db
        .collection('treatments')
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end);

    if (types != null && types.isNotEmpty) {
      final typeStrings = types.map((e) => e.asFirestoreString).toList();
      query = query.where('treatmentType', whereIn: typeStrings);
    }

    return query.snapshots().map((snap) {
      final items = snap.docs.map((doc) {
        final t = Treatment.fromJson(doc.id, (doc.data() as Map<String, dynamic>?));
        return (type: t.treatmentType, teethCount: t.toothNumbers.length);
      });
      return TreatmentCounts.fromIterable(items);
    });
  }

  @override
  Stream<TreatmentCounts> watchTreatmentCountsForCurrentYear({
    Set<TreatmentType>? types,
  }) {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final end = DateTime(now.year, 12, 31, 23, 59, 59);

    Query query = _db
        .collection('treatments')
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end);

    if (types != null && types.isNotEmpty) {
      final typeStrings = types.map((e) => e.asFirestoreString).toList();
      query = query.where('treatmentType', whereIn: typeStrings);
    }

    return query.snapshots().map((snap) {
      final items = snap.docs.map((doc) {
        final t = Treatment.fromJson(doc.id, (doc.data() as Map<String, dynamic>?));
        return (type: t.treatmentType, teethCount: t.toothNumbers.length);
      });
      return TreatmentCounts.fromIterable(items);
    });
  }

  @override
  Stream<TreatmentCounts> watchTreatmentCountsForToday({
    Set<TreatmentType>? types,
  }) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    Query query = _db
        .collection('treatments')
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end);

    if (types != null && types.isNotEmpty) {
      final typeStrings = types.map((e) => e.asFirestoreString).toList();
      query = query.where('treatmentType', whereIn: typeStrings);
    }

    return query.snapshots().map((snap) {
      final items = snap.docs.map((doc) {
        final t = Treatment.fromJson(doc.id, (doc.data() as Map<String, dynamic>?));
        return (type: t.treatmentType, teethCount: t.toothNumbers.length);
      });
      return TreatmentCounts.fromIterable(items);
    });
  }

  @override
  Stream<Map<String, int>> watchTodayTeethCountsByRawType() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final query = _db
        .collection('treatments')
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end);

    return query.snapshots().map((snap) {
      final map = <String, int>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final rawType = data['treatmentType'];
        final String type = rawType is String ? rawType : rawType?.toString() ?? 'unknown';
        final t = Treatment.fromJson(doc.id, (doc.data() as Map<String, dynamic>?));
        final count = t.toothNumbers.length;
        map[type] = (map[type] ?? 0) + count;
      }
      return Map.unmodifiable(map);
    });
  }

  @override
  Stream<Map<String, int>> watchTodayUniquePatientsByRawType() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final query = _db
        .collection('treatments')
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end);

    return query.snapshots().map((snap) {
      final map = <String, Set<String>>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final rawType = data['treatmentType'];
        final String type = rawType is String ? rawType : rawType?.toString() ?? 'unknown';
        final String patientId = (data['patientId'] as String?) ?? '';
        if (patientId.isEmpty) continue;
        map.putIfAbsent(type, () => <String>{}).add(patientId);
      }
      final counts = <String, int>{};
      map.forEach((k, v) => counts[k] = v.length);
      return Map.unmodifiable(counts);
    });
  }

  @override
  Stream<Map<String, int>> watchCurrentWeekTeethCountsByRawType() {
    final range = _currentWeekRange();
    final query = _db
        .collection('treatments')
        .where('date', isGreaterThanOrEqualTo: range.start)
        .where('date', isLessThanOrEqualTo: range.end);

    return query.snapshots().map((snap) {
      final map = <String, int>{};
      for (final doc in snap.docs) {
        final rawData = doc.data();
        final rawType = rawData['treatmentType'];
        final String type =
            rawType is String ? rawType : rawType?.toString() ?? 'unknown';
        final treatment =
            Treatment.fromJson(doc.id, (rawData as Map<String, dynamic>?));
        final count = treatment.toothNumbers.length;
        map[type] = (map[type] ?? 0) + count;
      }
      return Map.unmodifiable(map);
    });
  }

  @override
  Stream<Map<String, int>> watchCurrentWeekUniquePatientsByRawType() {
    final range = _currentWeekRange();
    final query = _db
        .collection('treatments')
        .where('date', isGreaterThanOrEqualTo: range.start)
        .where('date', isLessThanOrEqualTo: range.end);

    return query.snapshots().map((snap) {
      final map = <String, Set<String>>{};
      for (final doc in snap.docs) {
        final rawData = doc.data();
        final rawType = rawData['treatmentType'];
        final String type =
            rawType is String ? rawType : rawType?.toString() ?? 'unknown';
        final String patientId = (rawData['patientId'] as String?) ?? '';
        if (patientId.isEmpty) continue;
        map.putIfAbsent(type, () => <String>{}).add(patientId);
      }
      final counts = <String, int>{};
      map.forEach((k, v) => counts[k] = v.length);
      return Map.unmodifiable(counts);
    });
  }
}
