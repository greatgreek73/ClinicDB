import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dashboard/dashboard_controller.dart';
import '../../../screens/filtered_patients_screen.dart';
import '../../../design_system/design_system_screen.dart' show NeoCard, NeoButton, DesignTokens;

/// Визуализация счётчиков пациентов в неоморфном стиле.
/// Каждая карточка — вдавленная NeoCard (inset), цвета — из DesignTokens.
class PatientCountsWidget extends ConsumerWidget {
  final bool isPortrait;
  const PatientCountsWidget({super.key, this.isPortrait = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);

    Widget counterCard({
      required String title,
      required AsyncValue<int> count,
      required IconData icon,
      required Color accent,
      VoidCallback? onTap,
    }) {
      return NeoCard.inset(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: accent, size: 28),
                const SizedBox(height: 12),
                count.when(
                  loading: () => const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (e, _) => Text(
                    '—',
                    style: DesignTokens.h3.copyWith(color: DesignTokens.textSecondary),
                  ),
                  data: (v) => Text(
                    v.toString(),
                    style: DesignTokens.h2.copyWith(color: DesignTokens.textPrimary),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: DesignTokens.small.copyWith(color: DesignTokens.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Разметка: верхний ряд из двух карточек и нижняя широкая карточка по центру
    final topRow = Row(
      children: [
        Expanded(
          child: counterCard(
            title: 'Список ожидания',
            count: state.waitingListCount,
            icon: Icons.hourglass_full,
            accent: DesignTokens.accentWarning,
            onTap: () {
              context.push(
                '/patients/filtered',
                extra: const FilteredPatientsScreen(
                  filterType: 'waitingList',
                  filterName: 'Список ожидания',
                  filterIcon: Icons.hourglass_full,
                  filterColor: Colors.orange,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: counterCard(
            title: 'Второй этап',
            count: state.secondStageCount,
            icon: Icons.check_circle,
            accent: DesignTokens.accentSuccess,
            onTap: () {
              context.push(
                '/patients/filtered',
                extra: const FilteredPatientsScreen(
                  filterType: 'secondStage',
                  filterName: 'Второй этап',
                  filterIcon: Icons.check_circle,
                  filterColor: Colors.green,
                ),
              );
            },
          ),
        ),
      ],
    );

    final bottomRow = Row(
      children: [
        const Expanded(flex: 1, child: SizedBox()),
        Expanded(
          flex: 2,
          child: counterCard(
            title: 'Горящие пациенты',
            count: state.hotPatientCount,
            icon: Icons.local_fire_department,
            accent: DesignTokens.accentDanger,
            onTap: () {
              context.push(
                '/patients/filtered',
                extra: const FilteredPatientsScreen(
                  filterType: 'hotPatient',
                  filterName: 'Горящие пациенты',
                  filterIcon: Icons.local_fire_department,
                  filterColor: Colors.red,
                ),
              );
            },
          ),
        ),
        const Expanded(flex: 1, child: SizedBox()),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Статистика пациентов', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            topRow,
            const SizedBox(height: 12),
            bottomRow,
          ],
        );

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: content,
          ),
        );
      },
    );
  }
}
