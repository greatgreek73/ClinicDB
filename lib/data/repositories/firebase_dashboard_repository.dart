import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/patient.dart';
import '../../domain/models/treatment.dart';
import '../../domain/models/treatment_counts.dart';
import '../../domain/models/treatment_type.dart';
import '../../domain/repositories/dashboard_repository.dart';

class FirebaseDashboardRepository implements DashboardRepository {
  final FirebaseFirestore _db;

  FirebaseDashboardRepository(FirebaseFirestore db) : _db = db;

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
}
