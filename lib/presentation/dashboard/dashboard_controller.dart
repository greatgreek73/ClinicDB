import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/dashboard_providers.dart';
import '../../domain/models/patient.dart';
import '../../domain/models/treatment_counts.dart';
import '../../domain/models/treatment_type.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardState {
  final AsyncValue<List<Patient>> patients;
  final AsyncValue<int> waitingListCount;
  final AsyncValue<int> secondStageCount;
  final AsyncValue<int> hotPatientCount;

  final AsyncValue<int> implantsMonthCount;
  final AsyncValue<int> implantsYearCount;

  // Новые показатели: пациенты с ровно одним имплантом
  final AsyncValue<int> oneImplantPatientsMonthCount;
  final AsyncValue<int> oneImplantPatientsYearCount;

  final AsyncValue<int> crownAbutmentMonthCount;
  final AsyncValue<int> crownAbutmentYearCount;

  const DashboardState({
    required this.patients,
    required this.waitingListCount,
    required this.secondStageCount,
    required this.hotPatientCount,
    required this.implantsMonthCount,
    required this.implantsYearCount,
    required this.crownAbutmentMonthCount,
    required this.crownAbutmentYearCount,
    required this.oneImplantPatientsMonthCount,
    required this.oneImplantPatientsYearCount,
  });

  factory DashboardState.initial() => const DashboardState(
        patients: AsyncValue.loading(),
        waitingListCount: AsyncValue.loading(),
        secondStageCount: AsyncValue.loading(),
        hotPatientCount: AsyncValue.loading(),
        implantsMonthCount: AsyncValue.loading(),
        implantsYearCount: AsyncValue.loading(),
        crownAbutmentMonthCount: AsyncValue.loading(),
        crownAbutmentYearCount: AsyncValue.loading(),
        oneImplantPatientsMonthCount: AsyncValue.loading(),
        oneImplantPatientsYearCount: AsyncValue.loading(),
      );

  DashboardState copyWith({
    AsyncValue<List<Patient>>? patients,
    AsyncValue<int>? waitingListCount,
    AsyncValue<int>? secondStageCount,
    AsyncValue<int>? hotPatientCount,
    AsyncValue<int>? implantsMonthCount,
    AsyncValue<int>? implantsYearCount,
    AsyncValue<int>? crownAbutmentMonthCount,
    AsyncValue<int>? crownAbutmentYearCount,
    AsyncValue<int>? oneImplantPatientsMonthCount,
    AsyncValue<int>? oneImplantPatientsYearCount,
  }) {
    return DashboardState(
      patients: patients ?? this.patients,
      waitingListCount: waitingListCount ?? this.waitingListCount,
      secondStageCount: secondStageCount ?? this.secondStageCount,
      hotPatientCount: hotPatientCount ?? this.hotPatientCount,
      implantsMonthCount: implantsMonthCount ?? this.implantsMonthCount,
      implantsYearCount: implantsYearCount ?? this.implantsYearCount,
      crownAbutmentMonthCount:
          crownAbutmentMonthCount ?? this.crownAbutmentMonthCount,
      crownAbutmentYearCount:
          crownAbutmentYearCount ?? this.crownAbutmentYearCount,
      oneImplantPatientsMonthCount:
          oneImplantPatientsMonthCount ?? this.oneImplantPatientsMonthCount,
      oneImplantPatientsYearCount:
          oneImplantPatientsYearCount ?? this.oneImplantPatientsYearCount,
    );
  }
}

class DashboardController extends StateNotifier<DashboardState> {
  final DashboardRepository _repo;
  StreamSubscription? _patientsSub;
  StreamSubscription? _implantsMonthSub;
  StreamSubscription? _implantsYearSub;
  StreamSubscription? _crownAbMonthSub;
  StreamSubscription? _crownAbYearSub;
  StreamSubscription? _oneImplantMonthSub;
  StreamSubscription? _oneImplantYearSub;

  DashboardController(this._repo) : super(DashboardState.initial());

  void init() {
    // Пациенты + производные счётчики
    _patientsSub = _repo.watchPatients().listen((list) {
      state = state.copyWith(patients: AsyncValue.data(list));
      final waiting = list.where((p) => p.waitingList).length;
      final second = list.where((p) => p.secondStage).length;
      final hot = list.where((p) => p.hotPatient).length;
      state = state.copyWith(
        waitingListCount: AsyncValue.data(waiting),
        secondStageCount: AsyncValue.data(second),
        hotPatientCount: AsyncValue.data(hot),
      );
    }, onError: (e, st) {
      state = state.copyWith(
        patients: AsyncValue.error(e, st),
        waitingListCount: AsyncValue.error(e, st),
        secondStageCount: AsyncValue.error(e, st),
        hotPatientCount: AsyncValue.error(e, st),
      );
    });

    // Импланты за месяц/год
    final implantTypes = {TreatmentType.implant};
    _implantsMonthSub = _repo
        .watchTreatmentCountsForCurrentMonth(types: implantTypes)
        .listen((counts) {
      state = state.copyWith(
        implantsMonthCount: AsyncValue.data(counts.totalTeeth),
      );
    }, onError: (e, st) {
      state = state.copyWith(implantsMonthCount: AsyncValue.error(e, st));
    });

    _implantsYearSub = _repo
        .watchTreatmentCountsForCurrentYear(types: implantTypes)
        .listen((counts) {
      state = state.copyWith(
        implantsYearCount: AsyncValue.data(counts.totalTeeth),
      );
    }, onError: (e, st) {
      state = state.copyWith(implantsYearCount: AsyncValue.error(e, st));
    });

    // Пациенты с ровно 1 имплантом: за месяц/год
    _oneImplantMonthSub = _repo
        .watchOneImplantPatientsCountForCurrentMonth()
        .listen((count) {
      state = state.copyWith(
        oneImplantPatientsMonthCount: AsyncValue.data(count),
      );
    }, onError: (e, st) {
      state = state.copyWith(
          oneImplantPatientsMonthCount: AsyncValue.error(e, st));
    });

    _oneImplantYearSub = _repo
        .watchOneImplantPatientsCountForCurrentYear()
        .listen((count) {
      state = state.copyWith(
        oneImplantPatientsYearCount: AsyncValue.data(count),
      );
    }, onError: (e, st) {
      state = state.copyWith(
          oneImplantPatientsYearCount: AsyncValue.error(e, st));
    });

    // Коронки + Абатменты за месяц/год
    final crownAbTypes = {TreatmentType.crown, TreatmentType.abutment};
    _crownAbMonthSub = _repo
        .watchTreatmentCountsForCurrentMonth(types: crownAbTypes)
        .listen((counts) {
      state = state.copyWith(
        crownAbutmentMonthCount: AsyncValue.data(counts.totalTeeth),
      );
    }, onError: (e, st) {
      state =
          state.copyWith(crownAbutmentMonthCount: AsyncValue.error(e, st));
    });

    _crownAbYearSub = _repo
        .watchTreatmentCountsForCurrentYear(types: crownAbTypes)
        .listen((counts) {
      state = state.copyWith(
        crownAbutmentYearCount: AsyncValue.data(counts.totalTeeth),
      );
    }, onError: (e, st) {
      state = state.copyWith(crownAbutmentYearCount: AsyncValue.error(e, st));
    });
  }

  @override
  void dispose() {
    _patientsSub?.cancel();
    _implantsMonthSub?.cancel();
    _implantsYearSub?.cancel();
    _crownAbMonthSub?.cancel();
    _crownAbYearSub?.cancel();
    _oneImplantMonthSub?.cancel();
    _oneImplantYearSub?.cancel();
    super.dispose();
  }
}

/// Провайдер контроллера + состояния
final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>((ref) {
  final repo = ref.watch(dashboardRepositoryProvider);
  final controller = DashboardController(repo);
  // Ленивый запуск: инициируем подписки при первом чтении
  controller.init();
  return controller;
});
