import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/dashboard_controller.dart';
import '../../../screens/filtered_patients_screen.dart';

class PatientCountsWidget extends ConsumerWidget {
  final bool isPortrait;
  const PatientCountsWidget({super.key, this.isPortrait = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);

    Widget buildCard({
      required String title,
      required AsyncValue<int> count,
      required Color color,
      required IconData icon,
      VoidCallback? onTap,
    }) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF202020),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 36),
                  const SizedBox(height: 16),
                  count.when(
                    loading: () => const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (e, _) => Text(
                      '—',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    data: (v) => Text(
                      v.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (onTap != null) ...[
                    const SizedBox(height: 12),
                    Icon(Icons.arrow_forward, color: color.withOpacity(0.7), size: 20),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Статистика пациентов',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Используем фиксированные карточки без Expanded, чтобы избежать переполнения по высоте
            Row(
              children: [
                Expanded(
                  child: buildCard(
                    title: 'Список ожидания',
                    count: state.waitingListCount,
                    color: Colors.orange,
                    icon: Icons.hourglass_full,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FilteredPatientsScreen(
                            filterType: 'waitingList',
                            filterName: 'Список ожидания',
                            filterIcon: Icons.hourglass_full,
                            filterColor: Colors.orange,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: buildCard(
                    title: 'Второй этап',
                    count: state.secondStageCount,
                    color: Colors.green,
                    icon: Icons.check_circle,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FilteredPatientsScreen(
                            filterType: 'secondStage',
                            filterName: 'Второй этап',
                            filterIcon: Icons.check_circle,
                            filterColor: Colors.green,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(flex: 1, child: SizedBox()),
                Expanded(
                  flex: 2,
                  child: buildCard(
                    title: 'Горящие пациенты',
                    count: state.hotPatientCount,
                    color: Colors.red,
                    icon: Icons.local_fire_department,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FilteredPatientsScreen(
                            filterType: 'hotPatient',
                            filterName: 'Горящие пациенты',
                            filterIcon: Icons.local_fire_department,
                            filterColor: Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Expanded(flex: 1, child: SizedBox()),
              ],
            ),
          ],
        );

        // Если высоты недостаточно, разрешаем прокрутку
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
