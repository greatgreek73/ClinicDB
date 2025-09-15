import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/dashboard_controller.dart';
import '../../../design_system/design_system_screen.dart' show NeoCard, DesignTokens;

class TodayStatsWidget extends ConsumerWidget {
  final bool isPortrait;
  const TodayStatsWidget({super.key, this.isPortrait = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Все процедуры за сегодня по типам',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        state.proceduresTodayByType.when(
          loading: () => const Center(
            child: SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (e, _) => Text(
            'Ошибка загрузки',
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(color: DesignTokens.textSecondary),
          ),
          data: (map) {
            if (map.isEmpty) {
              return Text(
                'Нет данных за сегодня',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: DesignTokens.textSecondary),
              );
            }

            final entries = map.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key))
              ..sort((a, b) => b.value.compareTo(a.value));

            return NeoCard.inset(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.key,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              '${e.value}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: DesignTokens.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

