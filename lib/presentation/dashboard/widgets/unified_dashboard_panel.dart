import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dashboard/dashboard_controller.dart';

class UnifiedDashboardPanel extends ConsumerWidget {
  const UnifiedDashboardPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);

    Widget todayByTypes() {
      return state.proceduresTodayByType.when(
        loading: () => const Center(
          child: SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (e, _) => const Text('Ошибка загрузки'),
        data: (map) {
          if (map.isEmpty) return const Text('Нет данных за сегодня');
          final entries = map.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key))
            ..sort((a, b) => b.value.compareTo(a.value));
          return Column(
            children: entries
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(e.key, overflow: TextOverflow.ellipsis)),
                        Text('${e.value}', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                )
                .toList(),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          height: constraints.maxHeight,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top buttons: Add + Search
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.push('/add'),
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/search'),
                    icon: const Icon(Icons.search),
                    label: const Text('Поиск'),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Text('Все процедуры за сегодня по типам',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(child: todayByTypes()),
              ),
            ],
          ),
        );
      },
    );
  }
}
