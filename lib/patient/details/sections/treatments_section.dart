import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../design_system/design_system_screen.dart' show NeoCard, NeoButton, DesignTokens;
import '../../../add_treatment_screen.dart';

class TreatmentInfo {
  final String treatmentType;
  final List<int> toothNumbers;
  final DateTime date;
  final String notes;
  final String id;

  TreatmentInfo({
    required this.treatmentType,
    required this.toothNumbers,
    required this.date,
    required this.notes,
    required this.id,
  });

  factory TreatmentInfo.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TreatmentInfo(
      treatmentType: data['treatmentType'] ?? '',
      toothNumbers: List<int>.from(data['toothNumber'] ?? []),
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'] ?? '',
      id: doc.id,
    );
  }
}

class TreatmentsSection extends StatefulWidget {
  final Map<String, dynamic> patientData;
  final String patientId;
  final int selectedIndex;

  const TreatmentsSection({
    Key? key,
    required this.patientData,
    required this.patientId,
    required this.selectedIndex,
  }) : super(key: key);

  @override
  _TreatmentsSectionState createState() => _TreatmentsSectionState();
}

class _TreatmentsSectionState extends State<TreatmentsSection> with AutomaticKeepAliveClientMixin<TreatmentsSection> {
  Set<String> _activeTreatmentFilters = {};

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Container(
      key: ValueKey<int>(1),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Фильтры для истории лечения
          _buildTreatmentFilters(),
          const SizedBox(height: 16),
          // История лечения на всю ширину
          Expanded(
            child: NeoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Timeline слева с индикацией фильтров
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: DesignTokens.accentPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: DesignTokens.accentPrimary.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Timeline',
                                style: DesignTokens.small.copyWith(
                                  color: DesignTokens.accentPrimary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (_activeTreatmentFilters.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: DesignTokens.accentWarning.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: DesignTokens.accentWarning.withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.filter_alt,
                                      size: 14,
                                      color: DesignTokens.accentWarning,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Фильтры: ${_activeTreatmentFilters.length}',
                                      style: DesignTokens.small.copyWith(
                                        color: DesignTokens.accentWarning,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        
                        // История лечения по центру (отцентрована)
                        Expanded(
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('📋', style: TextStyle(fontSize: 24)),
                                const SizedBox(width: 8),
                                Text('История лечения', style: DesignTokens.h3),
                              ],
                            ),
                          ),
                        ),
                        
                        // Только кнопка добавить лечение справа (без редактирования)
                        NeoButton(
                          label: '+ Добавить лечение',
                          primary: true,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => AddTreatmentScreen(patientId: widget.patientId),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _buildTimelineTreatments(widget.patientId),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentFilters() {
    final treatmentTypes = [
      'Кариес', 'Имплантация', 'Удаление', 'Сканирование', 
      'Эндо', 'Формирователь', 'PMMA', 'Коронка', 'Абатмент'
    ];

    return NeoCard.inset(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_list,
                  size: 20,
                  color: DesignTokens.accentPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Фильтры лечения',
                  style: DesignTokens.h4.copyWith(
                    color: DesignTokens.accentPrimary,
                  ),
                ),
                const Spacer(),
                if (_activeTreatmentFilters.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _activeTreatmentFilters.clear();
                      });
                    },
                    child: Text(
                      'Сбросить',
                      style: DesignTokens.small.copyWith(
                        color: DesignTokens.accentDanger,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: treatmentTypes.map((type) {
                final isSelected = _activeTreatmentFilters.contains(type);
                return _buildFilterChip(type, isSelected, () {
                  setState(() {
                    if (isSelected) {
                      _activeTreatmentFilters.remove(type);
                    } else {
                      _activeTreatmentFilters.add(type);
                    }
                  });
                });
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? DesignTokens.accentPrimary.withOpacity(0.15)
                : DesignTokens.background.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                  ? DesignTokens.accentPrimary.withOpacity(0.5)
                  : DesignTokens.shadowDark.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: DesignTokens.accentPrimary.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected 
                  ? DesignTokens.accentPrimary 
                  : DesignTokens.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineTreatments(String patientId) {
    // Only subscribe to the stream when this section is visible (selectedIndex == 1)
    final isVisible = widget.selectedIndex == 1;
    
    if (!isVisible) {
      // Return a placeholder when not visible to avoid unnecessary stream subscriptions
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('treatments')
          .where('patientId', isEqualTo: patientId)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Ошибка загрузки лечения: ${snapshot.error}'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final treatments = snapshot.data!.docs
            .map((doc) => TreatmentInfo.fromDocument(doc))
            .where((treatment) =>
                _activeTreatmentFilters.isEmpty ||
                _activeTreatmentFilters.contains(treatment.treatmentType))
            .toList();

        if (treatments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  size: 64,
                  color: DesignTokens.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  _activeTreatmentFilters.isNotEmpty
                      ? 'Нет лечения с выбранными фильтрами'
                      : 'Пока нет записей о лечении',
                  style: DesignTokens.h4.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Добавьте первую запись, нажав кнопку выше',
                  style: DesignTokens.body.copyWith(
                    color: DesignTokens.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: treatments.length,
          itemBuilder: (context, index) {
            final treatment = treatments[index];
            final isLast = index == treatments.length - 1;
            
            return _buildTimelineItem(
              treatment: treatment,
              isLast: isLast,
            );
          },
        );
      },
    );
  }

  Widget _buildTimelineItem({
    required TreatmentInfo treatment,
    required bool isLast,
  }) {
    final color = _getColor(treatment.treatmentType);
    final isFiltered = _activeTreatmentFilters.contains(treatment.treatmentType);
    final isHighlighted = _activeTreatmentFilters.isEmpty || isFiltered;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline визуальная линия
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isHighlighted ? color : DesignTokens.shadowDark.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: isHighlighted ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: isHighlighted 
                    ? DesignTokens.shadowDark.withOpacity(0.2)
                    : DesignTokens.shadowDark.withOpacity(0.1),
              ),
          ],
        ),
        
        const SizedBox(width: 16),
        
        // Контент
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isHighlighted 
                    ? DesignTokens.surface
                    : DesignTokens.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isHighlighted && isFiltered
                      ? color.withOpacity(0.3)
                      : DesignTokens.shadowDark.withOpacity(0.1),
                  width: isHighlighted ? 1.5 : 1,
                ),
                boxShadow: isHighlighted && isFiltered
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isHighlighted && isFiltered
                              ? color.withOpacity(0.15)
                              : DesignTokens.shadowDark.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: isHighlighted && isFiltered
                              ? Border.all(
                                  color: color.withOpacity(0.3),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            _getTreatmentIcon(treatment.treatmentType),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              treatment.treatmentType,
                              style: DesignTokens.h4.copyWith(
                                color: isHighlighted ? DesignTokens.textPrimary : DesignTokens.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              DateFormat('dd.MM.yyyy • HH:mm').format(treatment.date),
                              style: DesignTokens.small.copyWith(
                                color: DesignTokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (treatment.toothNumbers.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Зубы: ${treatment.toothNumbers.join(", ")}',
                            style: DesignTokens.small.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (treatment.notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      treatment.notes,
                      style: DesignTokens.body.copyWith(
                        color: isHighlighted ? DesignTokens.textSecondary : DesignTokens.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
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