import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    }) {
      return Container(
        height: isPortrait ? 150 : null,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(4, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.0,
          ),
        ),
        child: Center(
          child: month.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text(
              '$title: ошибка',
              style: const TextStyle(color: Colors.white70),
            ),
            data: (m) => year.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text(
                '$title: ошибка',
                style: const TextStyle(color: Colors.white70),
              ),
              data: (y) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$title',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isPortrait ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$m',
                    key: monthKey,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isPortrait ? 20 : 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$y',
                    key: yearKey,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isPortrait ? 16 : 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Импланты (верхняя панель)
        buildPanel(
          title: 'Импланты (зубы)',
          month: state.implantsMonthCount,
          year: state.implantsYearCount,
          monthKey: const ValueKey('implantsMonth'),
          yearKey: const ValueKey('implantsYear'),
        ),
        const SizedBox(height: 16),
        // Коронка + Абатмент (нижняя панель)
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
