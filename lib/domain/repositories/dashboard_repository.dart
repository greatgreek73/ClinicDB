import '../models/patient.dart';
import '../models/treatment_counts.dart';
import '../models/treatment_type.dart';

/// Репозиторий дашборда.
/// Хранение чисел на стороне Firestore — только чтение агрегатов в приложении.
abstract class DashboardRepository {
  /// Кол-во пациентов с ровно 1 имплантом за текущий месяц.
  /// Агрегация по patientId на уровне клиента, учитывая toothNumber == 1.
  Stream<int> watchOneImplantPatientsCountForCurrentMonth();

  /// Кол-во пациентов с ровно 1 имплантом за текущий год.
  Stream<int> watchOneImplantPatientsCountForCurrentYear();

  /// Наблюдение списка пациентов.
  /// Используется для "счётчиков" в правой панели и List<Patient>.
  Stream<List<Patient>> watchPatients();

  /// Получить агрегат процедур (кол-во зубов суммарно) за произвольный период.
  /// Если [types] не задан — агрегируем по всем типам.
  Future<TreatmentCounts> getTreatmentCounts({
    required DateTime startInclusive,
    required DateTime endInclusive,
    Set<TreatmentType>? types,
  });

  /// Наблюдение агрегата процедур за текущий месяц (опционально по типам).
  Stream<TreatmentCounts> watchTreatmentCountsForCurrentMonth({
    Set<TreatmentType>? types,
  });

  /// Наблюдение агрегата процедур за текущий год (опционально по типам).
  Stream<TreatmentCounts> watchTreatmentCountsForCurrentYear({
    Set<TreatmentType>? types,
  });

  /// Наблюдение агрегата процедур за сегодня (опционально по типам).
  Stream<TreatmentCounts> watchTreatmentCountsForToday({
    Set<TreatmentType>? types,
  });

  /// Наблюдение: сумма по зубам за сегодня, сгруппировано по сырому названию типа.
  /// Ключ — точная строка из поля `treatmentType` в документе Firestore.
  Stream<Map<String, int>> watchTodayTeethCountsByRawType();

  /// Наблюдение: количество уникальных пациентов за сегодня по каждому сырому типу процедур.
  /// Считается по уникальным patientId в пределах текущего дня.
  Stream<Map<String, int>> watchTodayUniquePatientsByRawType();

  /// Наблюдение: суммы по зубам за текущую неделю, сгруппированные по сырому типу процедур.
  /// Неделя начинается с понедельника и включает текущий день.
  Stream<Map<String, int>> watchCurrentWeekTeethCountsByRawType();

  /// Наблюдение: количество уникальных пациентов за текущую неделю по каждому типу процедур.
  Stream<Map<String, int>> watchCurrentWeekUniquePatientsByRawType();

  /// Наблюдение: уникальные идентификаторы пациентов за сегодня по каждому типу процедур.
  Stream<Map<String, List<String>>> watchTodayPatientIdsByRawType();

  /// Наблюдение: уникальные идентификаторы пациентов за текущую неделю по каждому типу процедур.
  Stream<Map<String, List<String>>> watchCurrentWeekPatientIdsByRawType();
}
