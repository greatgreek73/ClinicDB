import 'package:cloud_firestore/cloud_firestore.dart';
import 'visit_model.dart';

class VisitService {
  final CollectionReference _visitsCollection = FirebaseFirestore.instance.collection('visits');

  // Добавление нового визита
  Future<void> addVisit(Visit visit) async {
    await _visitsCollection.add(visit.toJson());
  }

  // Получение визитов по ID пациента
  Stream<List<Visit>> getVisitsByPatientId(String patientId) {
    return _visitsCollection
        .where('patientId', isEqualTo: patientId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Visit.fromJson(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Обновление информации о визите
  Future<void> updateVisit(String visitId, Visit updatedVisit) async {
    await _visitsCollection.doc(visitId).update(updatedVisit.toJson());
  }

  // Удаление визита
  Future<void> deleteVisit(String visitId) async {
    await _visitsCollection.doc(visitId).delete();
  }
}
