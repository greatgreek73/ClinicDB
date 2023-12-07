import 'package:cloud_firestore/cloud_firestore.dart';
import 'visit_model.dart';

class VisitService {
  static Future<void> addVisit(Visit visit) async {
    await FirebaseFirestore.instance.collection('visits').add(visit.toMap());
  }
}
