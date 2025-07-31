import 'package:clinicdb/presentation/dashboard/dashboard_controller.dart';
import 'package:clinicdb/presentation/dashboard/widgets/patient_counts_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Импорты доменного слоя, которые используются в фейковом репозитории
import 'package:clinicdb/domain/repositories/dashboard_repository.dart';
import 'package:clinicdb/domain/models/patient.dart';
import 'package:clinicdb/domain/models/treatment_counts.dart';
import 'package:clinicdb/domain/models/treatment_type.dart';

void main() {
  group('PatientCountsWidget', () {
    testWidgets('renders loading state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Переопределяем контроллер на фейковый с loading-состоянием без инициализации Firebase
            dashboardControllerProvider.overrideWith((ref) {
              return _FakeController(DashboardState.initial());
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 300,
                child: PatientCountsWidget(),
              ),
            ),
          ),
        ),
      );

      // Ожидаем индикаторы загрузки (минимум один прогресс)
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.text('Статистика пациентов'), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      final container = ProviderContainer(overrides: [
        dashboardControllerProvider.overrideWith((ref) {
          // Создаём фейковое состояние с ошибками
          final state = DashboardState.initial().copyWith(
            waitingListCount: const AsyncValue.error('err', StackTrace.empty),
            secondStageCount: const AsyncValue.error('err', StackTrace.empty),
            hotPatientCount: const AsyncValue.error('err', StackTrace.empty),
          );
          return _FakeController(state);
        }),
      ]);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 300,
                child: PatientCountsWidget(),
              ),
            ),
          ),
        ),
      );

      // В ошибке мы показываем '—'
      expect(find.text('—'), findsWidgets);
      expect(find.text('Статистика пациентов'), findsOneWidget);
    });

    testWidgets('renders data state with counts', (tester) async {
      final container = ProviderContainer(overrides: [
        dashboardControllerProvider.overrideWith((ref) {
          final state = DashboardState.initial().copyWith(
            waitingListCount: const AsyncValue.data(2),
            secondStageCount: const AsyncValue.data(1),
            hotPatientCount: const AsyncValue.data(3),
          );
          return _FakeController(state);
        }),
      ]);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 320,
                child: PatientCountsWidget(),
              ),
            ),
          ),
        ),
      );

      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Список ожидания'), findsOneWidget);
      expect(find.text('Второй этап'), findsOneWidget);
      expect(find.text('Горящие пациенты'), findsOneWidget);
    });
  });
}

/// Простой фейковый контроллер, возвращает готовый стейт и не подписывается ни на что.
class _FakeController extends DashboardController {
  final DashboardState _state;
  _FakeController(this._state) : super(_DummyRepo());

  @override
  DashboardState get state => _state;

  @override
  void init() {}
}

/// Пустая реализация репозитория — не используется в этих виджет-тестах.
class _DummyRepo implements DashboardRepository {
  @override
  Future<TreatmentCounts> getTreatmentCounts({required DateTime startInclusive, required DateTime endInclusive, Set<TreatmentType>? types}) {
    throw UnimplementedError();
  }

  @override
  Stream<List<Patient>> watchPatients() => const Stream.empty();

  @override
  Stream<TreatmentCounts> watchTreatmentCountsForCurrentMonth({Set<TreatmentType>? types}) => const Stream.empty();

  @override
  Stream<TreatmentCounts> watchTreatmentCountsForCurrentYear({Set<TreatmentType>? types}) => const Stream.empty();
}
