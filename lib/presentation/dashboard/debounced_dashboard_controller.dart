import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/dashboard_providers.dart';
import '../../domain/models/patient.dart';
import '../../domain/models/treatment_counts.dart';
import '../../domain/models/treatment_type.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../utils/compute_helpers.dart';
import 'dashboard_controller.dart';

/// Debounced version of DashboardController that batches state updates
/// to prevent excessive rebuilds and improve performance
class DebouncedDashboardController extends StateNotifier<DashboardState> {
  final DashboardRepository _repo;
  StreamSubscription? _patientsSub;
  StreamSubscription? _implantsMonthSub;
  StreamSubscription? _implantsYearSub;
  StreamSubscription? _crownAbMonthSub;
  StreamSubscription? _crownAbYearSub;
  StreamSubscription? _oneImplantMonthSub;
  StreamSubscription? _oneImplantYearSub;

  // Debouncing timers
  Timer? _stateUpdateTimer;
  DashboardState? _pendingState;
  
  // Batch update duration
  static const _batchDuration = Duration(milliseconds: 100);

  DebouncedDashboardController(this._repo) : super(DashboardState.initial());

  /// Update state with debouncing to batch multiple updates
  void _updateState(DashboardState Function(DashboardState) updater) {
    _pendingState = updater(_pendingState ?? state);
    
    // Cancel previous timer
    _stateUpdateTimer?.cancel();
    
    // Schedule new update
    _stateUpdateTimer = Timer(_batchDuration, () {
      if (_pendingState != null && mounted) {
        state = _pendingState!;
        _pendingState = null;
      }
    });
  }

  void init() {
    // Пациенты + производные счётчики
    _patientsSub = _repo.watchPatients().listen((list) async {
      _updateState((s) => s.copyWith(patients: AsyncValue.data(list)));
      
      // Use compute for counting operations when list is large
      if (list.length > 100) {
        try {
          // Count in parallel using compute
          final results = await Future.wait([
            Future.value(list.where((p) => p.waitingList).length),
            Future.value(list.where((p) => p.secondStage).length),
            Future.value(list.where((p) => p.hotPatient).length),
          ]);
          
          _updateState((s) => s.copyWith(
            waitingListCount: AsyncValue.data(results[0]),
            secondStageCount: AsyncValue.data(results[1]),
            hotPatientCount: AsyncValue.data(results[2]),
          ));
        } catch (e) {
          // Fallback to synchronous counting
          final waiting = list.where((p) => p.waitingList).length;
          final second = list.where((p) => p.secondStage).length;
          final hot = list.where((p) => p.hotPatient).length;
          
          _updateState((s) => s.copyWith(
            waitingListCount: AsyncValue.data(waiting),
            secondStageCount: AsyncValue.data(second),
            hotPatientCount: AsyncValue.data(hot),
          ));
        }
      } else {
        // For small lists, count on main thread
        final waiting = list.where((p) => p.waitingList).length;
        final second = list.where((p) => p.secondStage).length;
        final hot = list.where((p) => p.hotPatient).length;
        
        _updateState((s) => s.copyWith(
          waitingListCount: AsyncValue.data(waiting),
          secondStageCount: AsyncValue.data(second),
          hotPatientCount: AsyncValue.data(hot),
        ));
      }
    }, onError: (e, st) {
      _updateState((s) => s.copyWith(
        patients: AsyncValue.error(e, st),
        waitingListCount: AsyncValue.error(e, st),
        secondStageCount: AsyncValue.error(e, st),
        hotPatientCount: AsyncValue.error(e, st),
      ));
    });

    // Импланты за месяц/год
    final implantTypes = {TreatmentType.implant};
    _implantsMonthSub = _repo
        .watchTreatmentCountsForCurrentMonth(types: implantTypes)
        .listen((counts) {
      _updateState((s) => s.copyWith(
        implantsMonthCount: AsyncValue.data(counts.totalTeeth),
      ));
    }, onError: (e, st) {
      _updateState((s) => s.copyWith(implantsMonthCount: AsyncValue.error(e, st)));
    });

    _implantsYearSub = _repo
        .watchTreatmentCountsForCurrentYear(types: implantTypes)
        .listen((counts) {
      _updateState((s) => s.copyWith(
        implantsYearCount: AsyncValue.data(counts.totalTeeth),
      ));
    }, onError: (e, st) {
      _updateState((s) => s.copyWith(implantsYearCount: AsyncValue.error(e, st)));
    });

    // Пациенты с ровно 1 имплантом: за месяц/год
    _oneImplantMonthSub = _repo
        .watchOneImplantPatientsCountForCurrentMonth()
        .listen((count) {
      _updateState((s) => s.copyWith(
        oneImplantPatientsMonthCount: AsyncValue.data(count),
      ));
    }, onError: (e, st) {
      _updateState((s) => s.copyWith(
          oneImplantPatientsMonthCount: AsyncValue.error(e, st)));
    });

    _oneImplantYearSub = _repo
        .watchOneImplantPatientsCountForCurrentYear()
        .listen((count) {
      _updateState((s) => s.copyWith(
        oneImplantPatientsYearCount: AsyncValue.data(count),
      ));
    }, onError: (e, st) {
      _updateState((s) => s.copyWith(
          oneImplantPatientsYearCount: AsyncValue.error(e, st)));
    });

    // Коронки + Абатменты за месяц/год
    final crownAbTypes = {TreatmentType.crown, TreatmentType.abutment};
    _crownAbMonthSub = _repo
        .watchTreatmentCountsForCurrentMonth(types: crownAbTypes)
        .listen((counts) {
      _updateState((s) => s.copyWith(
        crownAbutmentMonthCount: AsyncValue.data(counts.totalTeeth),
      ));
    }, onError: (e, st) {
      _updateState((s) => s.copyWith(crownAbutmentMonthCount: AsyncValue.error(e, st)));
    });

    _crownAbYearSub = _repo
        .watchTreatmentCountsForCurrentYear(types: crownAbTypes)
        .listen((counts) {
      _updateState((s) => s.copyWith(
        crownAbutmentYearCount: AsyncValue.data(counts.totalTeeth),
      ));
    }, onError: (e, st) {
      _updateState((s) => s.copyWith(crownAbutmentYearCount: AsyncValue.error(e, st)));
    });
  }

  /// Force immediate state update (bypasses debouncing)
  void forceUpdate() {
    _stateUpdateTimer?.cancel();
    if (_pendingState != null && mounted) {
      state = _pendingState!;
      _pendingState = null;
    }
  }

  @override
  void dispose() {
    _stateUpdateTimer?.cancel();
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

/// Provider for debounced dashboard controller
final debouncedDashboardControllerProvider =
    StateNotifierProvider<DebouncedDashboardController, DashboardState>((ref) {
  final repo = ref.watch(dashboardRepositoryProvider);
  final controller = DebouncedDashboardController(repo);
  controller.init();
  return controller;
});