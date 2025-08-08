import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../design_system/design_system_screen.dart' show NeoCard, DesignTokens;
import '../../../payment.dart';

final priceFormatter = NumberFormat('#,###', 'ru_RU');

class OverviewSection extends StatefulWidget {
  final Map<String, dynamic> patientData;
  final String patientId;
  final Function(String, dynamic) onUpdatePatientField;
  final Function(int) onChangeSection;

  const OverviewSection({
    Key? key,
    required this.patientData,
    required this.patientId,
    required this.onUpdatePatientField,
    required this.onChangeSection,
  }) : super(key: key);

  @override
  _OverviewSectionState createState() => _OverviewSectionState();
}

class _OverviewSectionState extends State<OverviewSection> {
  bool _waitingList = false;
  bool _secondStage = false;
  bool _hotPatient = false;

  @override
  void initState() {
    super.initState();
    _waitingList = widget.patientData['waitingList'] == true;
    _secondStage = widget.patientData['secondStage'] == true;
    _hotPatient = widget.patientData['hotPatient'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<int>(0),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Схема зубов в самом верху
            NeoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🦷', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text('Схема зубов', style: DesignTokens.h3),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildTreatmentSchemas(widget.patientId),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Основная информация в сетке
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Левая колонка
                Expanded(
                  child: Column(
                    children: [
                      _buildOverviewCard(
                        '👤 Личная информация',
                        _buildPersonalInfoContent(widget.patientData),
                      ),
                      const SizedBox(height: 16),
                      _buildOverviewCard(
                        '⚙️ Управление статусами',
                        _buildStatusManagementContent(widget.patientData),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Правая колонка
                Expanded(
                  child: Column(
                    children: [
                      _buildOverviewCard(
                        '💰 Финансовая сводка',
                        _buildFinancialSummaryContent(widget.patientData),
                      ),
                      const SizedBox(height: 16),
                      _buildOverviewCard(
                        '🕐 Дни лечения',
                        _buildTreatmentDaysContent(widget.patientData),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Краткие заметки
            _buildOverviewCard(
              '📝 Заметки',
              _buildQuickNotesContent(widget.patientData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(String title, Widget content) {
    final parts = title.split(' ');
    final emoji = parts[0];
    final text = parts.sublist(1).join(' ');
    
    return NeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(text, style: DesignTokens.h4),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  /// Контент личной информации
  Widget _buildPersonalInfoContent(Map<String, dynamic> patientData) {
    return Column(
      children: [
        _buildInfoRow('Возраст', '${patientData['age'] ?? 'Не указан'} лет'),
        const SizedBox(height: 12),
        _buildInfoRow('Пол', patientData['gender'] ?? 'Не указан'),
        const SizedBox(height: 12),
        _buildInfoRow('Город', patientData['city'] ?? 'Не указан'),
        const SizedBox(height: 12),
        _buildInfoRow('Телефон', patientData['phone'] ?? 'Не указан'),
        const SizedBox(height: 12),
        _buildInfoRow('Консультация', 
          patientData['hadConsultation'] == true ? 'Была' : 'Не была'),
      ],
    );
  }

  /// Строка информации
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: DesignTokens.body.copyWith(
            color: DesignTokens.textSecondary,
          ),
        ),
        Text(
          value,
          style: DesignTokens.body.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Контент управления статусами
  Widget _buildStatusManagementContent(Map<String, dynamic> patientData) {
    return Column(
      children: [
        _buildCompactStatusToggle(
          'Список ожидания',
          patientData['waitingList'] == true,
          (value) {
            if (patientData['treatmentFinished'] != true) {
              setState(() => _waitingList = value ?? false);
              widget.onUpdatePatientField('waitingList', value);
            }
          },
        ),
        const SizedBox(height: 8),
        _buildCompactStatusToggle(
          'Второй этап',
          patientData['secondStage'] == true,
          (value) {
            if (patientData['treatmentFinished'] != true) {
              setState(() => _secondStage = value ?? false);
              widget.onUpdatePatientField('secondStage', value);
            }
          },
        ),
        const SizedBox(height: 8),
        _buildCompactStatusToggle(
          'Горящий пациент',
          patientData['hotPatient'] == true,
          (value) {
            if (patientData['treatmentFinished'] != true) {
              setState(() => _hotPatient = value ?? false);
              widget.onUpdatePatientField('hotPatient', value);
            }
          },
        ),
        const SizedBox(height: 8),
        _buildCompactStatusToggle(
          'Лечение окончено',
          patientData['treatmentFinished'] == true,
          (value) {
            _handleTreatmentFinishedToggle(value ?? false);
          },
          isSpecial: true,
        ),
      ],
    );
  }

  /// Переключатель статуса
  Widget _buildCompactStatusToggle(String title, bool value, Function(bool?) onChanged, {bool isSpecial = false}) {
    return NeoCard.inset(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: DesignTokens.body.copyWith(
                fontWeight: FontWeight.w500,
                color: isSpecial && value 
                    ? DesignTokens.accentSuccess 
                    : DesignTokens.textPrimary,
              ),
            ),
            Transform.scale(
              scale: 0.9,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: isSpecial 
                    ? DesignTokens.accentSuccess 
                    : DesignTokens.accentPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Контент финансовой сводки
  Widget _buildFinancialSummaryContent(Map<String, dynamic> patientData) {
    final paymentsData = patientData['payments'] as List<dynamic>? ?? [];
    final payments = paymentsData.map((p) => Payment.fromMap(p)).toList();
    final totalPaid = payments.fold<double>(0, (sum, p) => sum + p.amount);
    final price = (patientData['price'] ?? 0) as num;
    final remain = price - totalPaid;
    
    return Column(
      children: [
        _buildFinanceRow(
          Icons.account_balance_wallet,
          'Стоимость',
          '${priceFormatter.format(price)} ₽',
          DesignTokens.accentPrimary,
        ),
        const SizedBox(height: 12),
        _buildFinanceRow(
          Icons.credit_card,
          'Оплачено',
          '${priceFormatter.format(totalPaid)} ₽',
          DesignTokens.accentSuccess,
        ),
        const SizedBox(height: 12),
        _buildFinanceRow(
          Icons.schedule,
          'Остаток',
          '${priceFormatter.format(remain)} ₽',
          remain > 0 ? DesignTokens.accentWarning : DesignTokens.accentSuccess,
        ),
      ],
    );
  }

  /// Строка финансовой информации
  Widget _buildFinanceRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: DesignTokens.body.copyWith(
              fontWeight: FontWeight.w600,
              color: DesignTokens.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        Text(
          value,
          style: DesignTokens.body.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Контент дней лечения
  Widget _buildTreatmentDaysContent(Map<String, dynamic> patientData) {
    final paymentsData = patientData['payments'] as List<dynamic>? ?? [];
    final payments = paymentsData.map((p) => Payment.fromMap(p)).toList();
    final isFinished = patientData['treatmentFinished'] == true;
    
    if (payments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 48,
              color: DesignTokens.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'Лечение не начато',
              style: DesignTokens.body.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          ],
        ),
      );
    }
    
    final firstPaymentDate = _getFirstPaymentDate(payments);
    final daysPassed = _calculateDaysPassed(firstPaymentDate, isFinished);
    final daysColor = _getDaysColor(daysPassed);
    
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: daysColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Icon(
                  isFinished ? Icons.check_circle : Icons.schedule,
                  color: daysColor,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$daysPassed дн${_getDaysEnding(daysPassed)}',
                    style: DesignTokens.h3.copyWith(
                      color: daysColor,
                    ),
                  ),
                  Text(
                    'Начато: ${DateFormat('dd.MM.yyyy').format(firstPaymentDate)}',
                    style: DesignTokens.small.copyWith(
                      color: DesignTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDaysProgressIndicator(daysPassed, daysColor),
      ],
    );
  }

  Widget _buildDaysProgressIndicator(int days, Color color) {
    String phaseText;
    double progress;
    
    if (days <= 30) {
      phaseText = 'Начальная фаза';
      progress = days / 30;
    } else if (days <= 90) {
      phaseText = 'Основная фаза';
      progress = (days - 30) / 60;
    } else {
      phaseText = 'Продленная фаза';
      progress = 1.0;
    }
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              phaseText,
              style: DesignTokens.small.copyWith(
                color: DesignTokens.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$days дн${_getDaysEnding(days)}',
              style: DesignTokens.small.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: DesignTokens.background,
            borderRadius: BorderRadius.circular(3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }

  /// Контент быстрых заметок
  Widget _buildQuickNotesContent(Map<String, dynamic> patientData) {
    return FutureBuilder<String>(
      future: _getPatientNotes(),
      builder: (context, snapshot) {
        final notes = snapshot.data ?? '';
        final hasNotes = notes.trim().isNotEmpty;
        
        return InkWell(
          onTap: () => widget.onChangeSection(5), // Переход к разделу заметок
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DesignTokens.background.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasNotes 
                    ? DesignTokens.accentPrimary.withOpacity(0.2)
                    : DesignTokens.shadowDark.withOpacity(0.1),
              ),
            ),
            child: hasNotes
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getNotesPreview(notes),
                        style: DesignTokens.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Нажмите для перехода к заметкам',
                        style: DesignTokens.small.copyWith(
                          color: DesignTokens.accentPrimary,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.note_add_outlined,
                          size: 32,
                          color: DesignTokens.textMuted,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Нет заметок',
                          style: DesignTokens.body.copyWith(
                            color: DesignTokens.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Нажмите, чтобы добавить',
                          style: DesignTokens.small.copyWith(
                            color: DesignTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildTreatmentSchemas(String patientId) {
    return FutureBuilder<Map<String, int>>(
      future: _getTreatmentCounts(patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Ошибка: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('Нет данных о лечении');
        }

        var sortedTreatments = snapshot.data!.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        var topFourTreatments = sortedTreatments.take(4).toList();

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildTreatmentSchema(patientId, topFourTreatments[0].key, _getColor(topFourTreatments[0].key))),
                const SizedBox(width: 12),
                Expanded(child: _buildTreatmentSchema(patientId, topFourTreatments.length > 1 ? topFourTreatments[1].key : '', _getColor(topFourTreatments.length > 1 ? topFourTreatments[1].key : ''))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTreatmentSchema(patientId, topFourTreatments.length > 2 ? topFourTreatments[2].key : '', _getColor(topFourTreatments.length > 2 ? topFourTreatments[2].key : ''))),
                const SizedBox(width: 12),
                Expanded(child: _buildTreatmentSchema(patientId, topFourTreatments.length > 3 ? topFourTreatments[3].key : '', _getColor(topFourTreatments.length > 3 ? topFourTreatments[3].key : ''))),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTreatmentSchema(String patientId, String treatmentType, Color color) {
    if (treatmentType.isEmpty) {
      return NeoCard.inset(
        child: Container(
          height: 120,
          child: const Center(
            child: Text(
              '—',
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: 24,
              ),
            ),
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('treatments')
          .where('patientId', isEqualTo: patientId)
          .where('treatmentType', isEqualTo: treatmentType)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Ошибка загрузки данных о лечении: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        List<int> treatedTeeth = [];
        for (final doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          treatedTeeth.addAll(List<int>.from(data['toothNumber'] ?? const []));
        }

        return NeoCard.inset(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  treatmentType,
                  style: DesignTokens.small.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 16,
                      childAspectRatio: 1,
                      crossAxisSpacing: 1,
                      mainAxisSpacing: 1,
                    ),
                    itemCount: 32,
                    itemBuilder: (context, index) {
                      final toothNumber = _getToothNumber(index);
                      final isTreated = treatedTeeth.contains(toothNumber);
                      return Container(
                        decoration: BoxDecoration(
                          color: isTreated ? color : DesignTokens.background,
                          border: Border.all(
                            color: DesignTokens.shadowDark.withOpacity(0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            toothNumber.toString(),
                            style: TextStyle(
                              color: isTreated ? Colors.white : DesignTokens.textSecondary,
                              fontSize: 6,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper methods
  DateTime _getFirstPaymentDate(List<Payment> payments) {
    if (payments.isEmpty) {
      return DateTime.now();
    }
    
    payments.sort((a, b) => a.date.compareTo(b.date));
    return payments.first.date;
  }

  int _calculateDaysPassed(DateTime startDate, bool isFinished) {
    final endDate = isFinished ? startDate : DateTime.now();
    
    if (isFinished) {
      return DateTime.now().difference(startDate).inDays;
    }
    
    return endDate.difference(startDate).inDays;
  }

  Color _getDaysColor(int days) {
    if (days <= 30) {
      return DesignTokens.accentSuccess;
    } else if (days <= 90) {
      return DesignTokens.accentWarning;
    } else {
      return DesignTokens.accentDanger;
    }
  }

  String _getDaysEnding(int days) {
    final lastDigit = days % 10;
    final lastTwoDigits = days % 100;
    
    if (lastTwoDigits >= 11 && lastTwoDigits <= 14) {
      return 'ей';
    }
    
    switch (lastDigit) {
      case 1:
        return 'ь';
      case 2:
      case 3:
      case 4:
        return 'я';
      default:
        return 'ей';
    }
  }

  Future<String> _getPatientNotes() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return doc.data()!['notes'] ?? '';
      }
      return '';
    } catch (e) {
      print('Ошибка получения заметок: $e');
      return '';
    }
  }

  String _getNotesPreview(String notes) {
    if (notes.length <= 150) {
      return notes;
    }
    return '${notes.substring(0, 150)}...';
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

  int _getToothNumber(int index) {
    if (index < 16) {
      return index < 8 ? 18 - index : 21 + (index - 8);
    } else {
      return index < 24 ? 48 - (index - 16) : 31 + (index - 24);
    }
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

  void _handleTreatmentFinishedToggle(bool value) async {
    if (value) {
      setState(() {
        _waitingList = false;
        _secondStage = false;
        _hotPatient = false;
      });
      
      await widget.onUpdatePatientField('treatmentFinished', true);
      await widget.onUpdatePatientField('waitingList', false);
      await widget.onUpdatePatientField('secondStage', false);
      await widget.onUpdatePatientField('hotPatient', false);
    } else {
      await widget.onUpdatePatientField('treatmentFinished', false);
    }
  }
}