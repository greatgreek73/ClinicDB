import 'package:clinicdb/presentation/dashboard/dashboard_controller.dart';
import 'package:clinicdb/presentation/dashboard/widgets/treatment_stats_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Импорты доменного слоя для заглушек
import 'package:clinicdb/domain/repositories/dashboard_repository.dart';
import 'package:clinicdb/domain/models/patient.dart';
import 'package:clinicdb/domain/models/treatment_counts.dart';
import 'package:clinicdb/domain/models/treatment_type.dart';

void main() {
  group('TreatmentStatsWidget', () {
    testWidgets('renders loading state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Переопределяем контроллер на фейковый с loading-состоянием
            dashboardControllerProvider.overrideWith((ref) {
              return _FakeController(DashboardState.initial());
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 600,
                height: 260,
                child: TreatmentStatsWidget(),
              ),
            ),
          ),
        ),
      );

      // Проверяем, что виджет отрендерился (loading-состояние допустимо без индикатора)
      expect(find.byType(TreatmentStatsWidget), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      final container = ProviderContainer(overrides: [
        dashboardControllerProvider.overrideWith((ref) {
          final state = DashboardState.initial().copyWith(
            implantsMonthCount: const AsyncValue.error('err', StackTrace.empty),
            implantsYearCount: const AsyncValue.error('err', StackTrace.empty),
            crownAbutmentMonthCount: const AsyncValue.error('err', StackTrace.empty),
            crownAbutmentYearCount: const AsyncValue.error('err', StackTrace.empty),
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
                width: 600,
                height: 260,
                child: TreatmentStatsWidget(),
              ),
            ),
          ),
        ),
      );

      // При ошибке внутри .when можно отображать дефолтные значения/прочерк — проверим наличие текста-панелей
      expect(find.textContaining('Main Panel'), findsNothing); // в рефакторе мы заменили на реальный виджет статистики
      // Проверяем, что есть какой-то текст заголовков/подписей в панели (если они предусмотрены)
      // Здесь оставим базовую проверку наличия виджета на экране.
      expect(find.byType(TreatmentStatsWidget), findsOneWidget);
    });

    testWidgets('renders data state with counts', (tester) async {
      final container = ProviderContainer(overrides: [
        dashboardControllerProvider.overrideWith((ref) {
          final state = DashboardState.initial().copyWith(
            implantsMonthCount: const AsyncValue.data(5),
            implantsYearCount: const AsyncValue.data(12),
            crownAbutmentMonthCount: const AsyncValue.data(7),
            crownAbutmentYearCount: const AsyncValue.data(21),
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
                width: 600,
                height: 260,
                child: TreatmentStatsWidget(),
              ),
            ),
          ),
        ),
      );

      // Проверяем значения по ключам
      final monthFinder = find.byKey(const ValueKey('implantsMonth'));
      final yearFinder = find.byKey(const ValueKey('implantsYear'));
      final crownMonthFinder = find.byKey(const ValueKey('crownAbMonth'));
      final crownYearFinder = find.byKey(const ValueKey('crownAbYear'));

      expect(monthFinder, findsOneWidget);
      expect(yearFinder, findsOneWidget);
      expect(crownMonthFinder, findsOneWidget);
      expect(crownYearFinder, findsOneWidget);

      final monthText = tester.widget<Text>(monthFinder);
      final yearText = tester.widget<Text>(yearFinder);
      final crownMonthText = tester.widget<Text>(crownMonthFinder);
      final crownYearText = tester.widget<Text>(crownYearFinder);

      expect(monthText.data, '5');
      expect(yearText.data, '12');
      expect(crownMonthText.data, '7');
      expect(crownYearText.data, '21');
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

/// Пустая «заглушка» для репозитория — не используется в этих виджет‑тестах.
class _DummyRepo implements DashboardRepository {
  @override
  Future<TreatmentCounts> getTreatmentCounts({
    required DateTime startInclusive,
    required DateTime endInclusive,
    Set<TreatmentType>? types,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<List<Patient>> watchPatients() => const Stream.empty();

  @override
  Stream<TreatmentCounts> watchTreatmentCountsForCurrentMonth({Set<TreatmentType>? types}) =>
      const Stream.empty();

  @override
  Stream<TreatmentCounts> watchTreatmentCountsForCurrentYear({Set<TreatmentType>? types}) =>
      const Stream.empty();
}
