import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Импорты тестируемого кода
import 'package:clinicdb/presentation/dashboard/dashboard_controller.dart';
import 'package:clinicdb/di/dashboard_providers.dart';
import 'package:clinicdb/domain/models/patient.dart';
import 'package:clinicdb/domain/models/treatment_counts.dart';
import 'package:clinicdb/domain/models/treatment_type.dart';
import 'package:clinicdb/domain/repositories/dashboard_repository.dart';

class _MockDashboardRepository implements DashboardRepository {
  final StreamController<List<Patient>> _patientsCtr =
      StreamController<List<Patient>>.broadcast();
  final StreamController<TreatmentCounts> _monthCtr =
      StreamController<TreatmentCounts>.broadcast();
  final StreamController<TreatmentCounts> _yearCtr =
      StreamController<TreatmentCounts>.broadcast();

  // Конфигурируемые значения для getTreatmentCounts (если понадобится)
  TreatmentCounts countsResponse = TreatmentCounts.empty();

  // Helpers для тестов
  void addPatients(List<Patient> patients) => _patientsCtr.add(patients);
  void addMonthCounts(TreatmentCounts counts) => _monthCtr.add(counts);
  void addYearCounts(TreatmentCounts counts) => _yearCtr.add(counts);

  // Возможность эмитить ошибку
  void addPatientsError(Object error) => _patientsCtr.addError(error);
  void addMonthError(Object error) => _monthCtr.addError(error);
  void addYearError(Object error) => _yearCtr.addError(error);

  @override
  Future<TreatmentCounts> getTreatmentCounts({
    required DateTime startInclusive,
    required DateTime endInclusive,
    Set<TreatmentType>? types,
  }) async {
    return countsResponse;
  }

  @override
  Stream<List<Patient>> watchPatients() => _patientsCtr.stream;

  @override
  Stream<TreatmentCounts> watchTreatmentCountsForCurrentMonth({Set<TreatmentType>? types}) =>
      _monthCtr.stream;

  @override
  Stream<TreatmentCounts> watchTreatmentCountsForCurrentYear({Set<TreatmentType>? types}) =>
      _yearCtr.stream;

  void dispose() {
    _patientsCtr.close();
    _monthCtr.close();
    _yearCtr.close();
  }
}

void main() {
  group('DashboardController', () {
    late _MockDashboardRepository repo;
    late ProviderContainer container;

    setUp(() {
      repo = _MockDashboardRepository();
      container = ProviderContainer(overrides: [
        // Переопределяем провайдеры: напрямую создаём контроллер с мок‑репо.
        dashboardControllerProvider.overrideWith((ref) {
          final controller = DashboardController(repo);
          controller.init();
          return controller;
        }),
      ]);
    });

    tearDown(() {
      container.dispose();
      repo.dispose();
    });

    test('initial state is loading for all fields', () {
      final state = container.read(dashboardControllerProvider);
      expect(state.patients.isLoading, true);
      expect(state.waitingListCount.isLoading, true);
      expect(state.secondStageCount.isLoading, true);
      expect(state.hotPatientCount.isLoading, true);
      expect(state.implantsMonthCount.isLoading, true);
      expect(state.implantsYearCount.isLoading, true);
      expect(state.crownAbutmentMonthCount.isLoading, true);
      expect(state.crownAbutmentYearCount.isLoading, true);
    });

    test('successful data flow updates counters correctly', () async {
      // Подготовим пациентов: 2 в ожидании, 1 во втором этапе, 1 "горящий"
      final patients = [
        Patient(id: 'p1', name: 'A', waitingList: true, secondStage: false, hotPatient: false),
        Patient(id: 'p2', name: 'B', waitingList: true, secondStage: true, hotPatient: false),
        Patient(id: 'p3', name: 'C', waitingList: false, secondStage: false, hotPatient: true),
      ];

      // Эмитим пациентов
      repo.addPatients(patients);
      // ждём пока пациенты попадут в стейт
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Проверяем список пациентов
      var state = container.read(dashboardControllerProvider);
      expect(state.patients.hasValue, true);
      expect(state.patients.value!.length, 3);

      // Ждём обновления производных счётчиков
      await Future<void>.delayed(const Duration(milliseconds: 30));
      state = container.read(dashboardControllerProvider);
      expect(state.waitingListCount.value, 2);
      expect(state.secondStageCount.value, 1);
      expect(state.hotPatientCount.value, 1);

      // Эмитим агрегаты имплантов (месяц/год)
      final implantsMonth = TreatmentCounts(totalTeeth: 5, byType: {TreatmentType.implant: 5});
      final implantsYear = TreatmentCounts(totalTeeth: 15, byType: {TreatmentType.implant: 15});
      repo.addMonthCounts(implantsMonth);
      repo.addYearCounts(implantsYear);

      await Future<void>.delayed(const Duration(milliseconds: 30));
      state = container.read(dashboardControllerProvider);
      expect(state.implantsMonthCount.value, 5);
      expect(state.implantsYearCount.value, 15);

      // Эмитим агрегаты коронок+абатментов (месяц/год)
      final crownAbMonth = TreatmentCounts(
        totalTeeth: 7,
        byType: {TreatmentType.crown: 5, TreatmentType.abutment: 2},
      );
      final crownAbYear = TreatmentCounts(
        totalTeeth: 20,
        byType: {TreatmentType.crown: 10, TreatmentType.abutment: 10},
      );
      repo.addMonthCounts(crownAbMonth);
      repo.addYearCounts(crownAbYear);

      await Future<void>.delayed(const Duration(milliseconds: 30));
      state = container.read(dashboardControllerProvider);
      expect(state.crownAbutmentMonthCount.value, 7);
      expect(state.crownAbutmentYearCount.value, 20);
    });

    test('patients stream error propagates to AsyncValue.error', () async {
      repo.addPatientsError(Exception('patients error'));

      // ждём пока сост-я перейдут в ошибку
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final errState = container.read(dashboardControllerProvider);
      expect(errState.patients.hasError, true);
      expect(errState.waitingListCount.hasError, true);
      expect(errState.secondStageCount.hasError, true);
      expect(errState.hotPatientCount.hasError, true);
    });

    test('empty patients produces zero counters', () async {
      repo.addPatients(const []);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      final s = container.read(dashboardControllerProvider);
      expect(s.waitingListCount.value, 0);
      expect(s.secondStageCount.value, 0);
      expect(s.hotPatientCount.value, 0);
    });
  });
}
