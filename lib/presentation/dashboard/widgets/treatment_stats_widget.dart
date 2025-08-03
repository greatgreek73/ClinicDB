import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system_screen.dart' show NeoCard, DesignTokens;
import '../../dashboard/dashboard_controller.dart';

/// Отображает агрегаты процедур:
/// - Импланты: месяц/год
/// - Коронка+Абатмент: месяц/год
class TreatmentStatsWidget extends ConsumerWidget {
  final bool isPortrait;
  const TreatmentStatsWidget({super.key, this.isPortrait = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);

    Widget buildPanel({
      required String title,
      required AsyncValue<int> month,
      required AsyncValue<int> year,
      required Key monthKey,
      required Key yearKey,
      AsyncValue<int>? oneImplantMonth,
      AsyncValue<int>? oneImplantYear,
      Key? oneImplantMonthKey,
      Key? oneImplantYearKey,
    }) {
      return NeoCard(
        child: month.when(
          loading: () => const Center(
            child: SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (e, _) => Center(
            child: Text(
              '$title: ошибка',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: DesignTokens.textSecondary,
                  ),
            ),
          ),
          data: (m) => year.when(
            loading: () => const Center(
              child: SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, _) => Center(
              child: Text(
                '$title: ошибка',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: DesignTokens.textSecondary,
                    ),
              ),
            ),
            data: (y) => SizedBox(
              height: isPortrait ? 180 : null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Верхний ряд: заголовок + подпись
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Агрегированные значения по зубам',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: DesignTokens.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Ряд 1: Месяц/Год (зубы)
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          label: 'Месяц',
                          value: m,
                          valueKey: monthKey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatBox(
                          label: 'Год',
                          value: y,
                          valueKey: yearKey,
                        ),
                      ),
                    ],
                  ),
                  // Ряд 2: Пациенты с 1 имплантом (если передано)
                  if (oneImplantMonth != null && oneImplantYear != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: oneImplantMonth.when(
                            loading: () => NeoCard.inset(
                              child: const Center(
                                child: SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                            error: (e, _) => NeoCard.inset(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  '1 импл. (месяц): —',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: DesignTokens.textSecondary,
                                      ),
                                ),
                              ),
                            ),
                            data: (v) => _StatBox(
                              label: '1 имплант (месяц)',
                              value: v,
                              valueKey: oneImplantMonthKey ?? const ValueKey('oneImplantMonth'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: oneImplantYear.when(
                            loading: () => NeoCard.inset(
                              child: const Center(
                                child: SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                            error: (e, _) => NeoCard.inset(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  '1 импл. (год): —',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: DesignTokens.textSecondary,
                                      ),
                                ),
                              ),
                            ),
                            data: (v) => _StatBox(
                              label: '1 имплант (год)',
                              value: v,
                              valueKey: oneImplantYearKey ?? const ValueKey('oneImplantYear'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        buildPanel(
          title: 'Импланты (зубы)',
          month: state.implantsMonthCount,
          year: state.implantsYearCount,
          monthKey: const ValueKey('implantsMonth'),
          yearKey: const ValueKey('implantsYear'),
          oneImplantMonth: state.oneImplantPatientsMonthCount,
          oneImplantYear: state.oneImplantPatientsYearCount,
          oneImplantMonthKey: const ValueKey('oneImplantPatientsMonth'),
          oneImplantYearKey: const ValueKey('oneImplantPatientsYear'),
        ),
        const SizedBox(height: 12),
        buildPanel(
          title: 'Коронка + Абатмент (зубы)',
          month: state.crownAbutmentMonthCount,
          year: state.crownAbutmentYearCount,
          monthKey: const ValueKey('crownAbMonth'),
          yearKey: const ValueKey('crownAbYear'),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final int value;
  final Key valueKey;

  const _StatBox({
    required this.label,
    required this.value,
    required this.valueKey,
  });

  @override
  Widget build(BuildContext context) {
    return NeoCard.inset(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DesignTokens.textSecondary,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              '$value',
              key: valueKey,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: DesignTokens.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
