import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/repositories/dashboard_repository.dart';
import '../domain/models/patient.dart';
import '../domain/models/treatment_counts.dart';
import '../domain/models/treatment_type.dart';
import '../data/repositories/firebase_dashboard_repository.dart';

/// Провайдер FirebaseFirestore (отдельно для тестируемости)
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Провайдер репозитория дашборда.
/// На Windows (не web) подставляет мок, чтобы приложение работало без Firebase.
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final isWindowsDesktop = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  if (isWindowsDesktop) {
    return MockDashboardRepository();
  }
  final db = ref.watch(firebaseFirestoreProvider);
  return FirebaseDashboardRepository(db);
});

/// Простая мок-реализация для среды без Firebase или для тестов.
/// Возвращает пустые/статические данные.
class MockDashboardRepository implements DashboardRepository {
  @override
  Stream<List<Patient>> watchPatients() {
    // Пустой список пациентов по умолчанию
    return Stream.value(const <Patient>[]);
  }

  @override
  Future<TreatmentCounts> getTreatmentCounts({
    required DateTime startInclusive,
    required DateTime endInclusive,
    Set<TreatmentType>? types,
  }) async {
    // Нулевые агрегаты
    return TreatmentCounts.empty();
  }

  @override
  Stream<TreatmentCounts> watchTreatmentCountsForCurrentMonth({Set<TreatmentType>? types}) {
    return Stream.value(TreatmentCounts.empty());
  }

  @override
  Stream<TreatmentCounts> watchTreatmentCountsForCurrentYear({Set<TreatmentType>? types}) {
    return Stream.value(TreatmentCounts.empty());
  }

  // Новые методы для метрики "пациенты с 1 имплантом"
  @override
  Stream<int> watchOneImplantPatientsCountForCurrentMonth() {
    return Stream.value(0);
  }

  @override
  Stream<int> watchOneImplantPatientsCountForCurrentYear() {
    return Stream.value(0);
  }

  @override
  Stream<TreatmentCounts> watchTreatmentCountsForToday({Set<TreatmentType>? types}) {
    return Stream.value(TreatmentCounts.empty());
  }

  @override
  Stream<Map<String, int>> watchTodayTeethCountsByRawType() {
    return Stream.value(const <String, int>{});
  }

  @override
  Stream<Map<String, int>> watchTodayUniquePatientsByRawType() {
    return Stream.value(const <String, int>{});
  }

  @override
  Stream<Map<String, int>> watchCurrentWeekTeethCountsByRawType() {
    return Stream.value(const <String, int>{});
  }

  @override
  Stream<Map<String, int>> watchCurrentWeekUniquePatientsByRawType() {
    return Stream.value(const <String, int>{});
  }
}
