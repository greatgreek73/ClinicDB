import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../design_system/design_system_screen.dart' show NeoCard, DesignTokens;

class StatisticsSection extends StatefulWidget {
  final Map<String, dynamic> patientData;
  final String patientId;
  final int selectedIndex;

  const StatisticsSection({
    Key? key,
    required this.patientData,
    required this.patientId,
    required this.selectedIndex,
  }) : super(key: key);

  @override
  _StatisticsSectionState createState() => _StatisticsSectionState();
}

class _StatisticsSectionState extends State<StatisticsSection> with AutomaticKeepAliveClientMixin<StatisticsSection> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    // Only perform heavy calculations when this section is visible (selectedIndex == 3)
    final isVisible = widget.selectedIndex == 3;
    if (!isVisible) {
      return Container(
        key: ValueKey<int>(3),
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Container(
      key: ValueKey<int>(3),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Статистика по процедурам
          Expanded(
            child: NeoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('📊', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text('Статистика процедур', style: DesignTokens.h3),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _buildTreatmentStatsList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Дополнительная статистика
          SizedBox(
            width: 400,
            child: Column(
              children: [
                // График посещений
                NeoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('📈', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Text('Динамика лечения', style: DesignTokens.h3),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildTreatmentProgress(widget.patientData),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentProgress(Map<String, dynamic> patientData) {
    // Здесь можно добавить график или диаграмму
    return Container(
      height: 200,
      child: Center(
        child: Text(
          'График в разработке',
          style: DesignTokens.body.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildTreatmentStatsList() {
    return FutureBuilder<Map<String, int>>(
      future: _getTreatmentCounts(widget.patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Ошибка: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 64,
                  color: DesignTokens.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  'Нет данных о процедурах',
                  style: DesignTokens.body.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          );
        }

        final treatments = snapshot.data!;
        final sortedTreatments = treatments.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        return ListView.builder(
          itemCount: sortedTreatments.length,
          itemBuilder: (context, index) {
            final treatment = sortedTreatments[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: _buildTreatmentStatListItem(treatment.key, treatment.value),
            );
          },
        );
      },
    );
  }

  Widget _buildTreatmentStatListItem(String treatmentType, int count) {
    final icon = _getTreatmentIcon(treatmentType);
    final color = _getColor(treatmentType);
    
    return NeoCard.inset(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    treatmentType,
                    style: DesignTokens.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Количество процедур',
                    style: DesignTokens.small.copyWith(
                      color: DesignTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                count.toString(),
                style: DesignTokens.h4.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, int>> _getTreatmentCounts(String patientId) async {
    var treatmentCounts = <String, int>{
      'Кариес': 0,
      'Имплантация': 0,
      'Удаление': 0,
      'Сканирование': 0,
      'Эндо': 0,
      'Формирователь': 0,
      'PMMA': 0,
      'Коронка': 0,
      'Абатмент': 0,
      'Сдача PMMA': 0,
      'Сдача коронка': 0,
      'Сдача абатмент': 0,
      'Удаление импланта': 0
    };

    var snapshot = await FirebaseFirestore.instance
        .collection('treatments')
        .where('patientId', isEqualTo: patientId)
        .get();

    for (var doc in snapshot.docs) {
      var data = doc.data();
      var treatmentType = data['treatmentType'] as String;
      var toothNumbers = (data['toothNumber'] as List?)?.length ?? 0;
      
      if (treatmentCounts.containsKey(treatmentType)) {
        treatmentCounts[treatmentType] = treatmentCounts[treatmentType]! + toothNumbers;
      }
    }

    return Map.fromEntries(
      treatmentCounts.entries.where((entry) => entry.value > 0)
    );
  }

  Color _getColor(String treatmentType) {
    final colors = {
      'Кариес': Colors.red,
      'Имплантация': Colors.blue,
      'Удаление': Colors.orange,
      'Сканирование': Colors.purple,
      'Эндо': Colors.green,
      'Формирователь': Colors.teal,
      'PMMA': Colors.amber,
      'Коронка': Colors.indigo,
      'Абатмент': Colors.pink,
      'Сдача PMMA': Colors.cyan,
      'Сдача коронка': Colors.deepPurple,
      'Сдача абатмент': Colors.lightGreen,
      'Удаление импланта': Colors.deepOrange,
    };

    return colors[treatmentType] ?? Colors.grey;
  }

  String _getTreatmentIcon(String treatmentType) {
    final icons = {
      'Кариес': '🦷',
      'Имплантация': '🔩',
      'Удаление': '🗑️',
      'Сканирование': '📷',
      'Эндо': '🔬',
      'Формирователь': '⚙️',
      'PMMA': '🔧',
      'Коронка': '👑',
      'Абатмент': '🔗',
      'Сдача PMMA': '✅',
      'Сдача коронка': '✅',
      'Сдача абатмент': '✅',
      'Удаление импланта': '❌',
    };
    return icons[treatmentType] ?? '🏥';
  }
}