import 'package:flutter/foundation.dart';
import '../models/patient.dart';
import '../models/treatment_counts.dart';
import '../models/treatment_type.dart';

/// Контракт репозитория дашборда.
/// Домашний слой не знает о Firestore — только о доменных моделях.
abstract class DashboardRepository {
  /// Наблюдение за списком пациентов.
  /// Репозиторий преобразует "сырые" данные источника в List<Patient>.
  Stream<List<Patient>> watchPatients();

  /// Получение агрегатов процедур (число зубов и разбиение по типам) за произвольный период.
  /// Если [types] не задан — агрегируются все доступные типы.
  Future<TreatmentCounts> getTreatmentCounts({
    required DateTime startInclusive,
    required DateTime endInclusive,
    Set<TreatmentType>? types,
  });

  /// Стрим агрегатов за текущий месяц по указанным типам (например, только импланты).
  Stream<TreatmentCounts> watchTreatmentCountsForCurrentMonth({
    Set<TreatmentType>? types,
  });

  /// Стрим агрегатов за текущий год по указанным типам.
  Stream<TreatmentCounts> watchTreatmentCountsForCurrentYear({
    Set<TreatmentType>? types,
  });
}
