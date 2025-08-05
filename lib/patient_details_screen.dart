import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'edit_patient_screen.dart';
import 'add_treatment_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'payment.dart';
import 'notes_widget.dart';

// Дизайн‑система (неоморфизм)
import 'design_system/design_system_screen.dart' show NeoCard, NeoButton, DesignTokens;

final priceFormatter = NumberFormat('#,###', 'ru_RU');

class PatientDetailsScreen extends StatefulWidget {
  final String patientId;

  PatientDetailsScreen({required this.patientId});

  @override
  _PatientDetailsScreenState createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  // Контроллер для планируемого лечения
  final TextEditingController _plannedTreatmentController = TextEditingController();

  bool _waitingList = false;
  bool _secondStage = false;
  bool _hotPatient = false;

  @override
  void initState() {
    super.initState();
    _loadPlannedTreatment();
  }

  @override
  void dispose() {
    _plannedTreatmentController.dispose();
    super.dispose();
  }

  Future<void> _updatePatientField(String field, dynamic value) async {
    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .update({field: value});
    } catch (e) {
      print('Ошибка при обновлении поля $field: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('patients')
                .doc(widget.patientId)
                .snapshots(),
            builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                if (snapshot.hasData && snapshot.data?.data() != null) {
                  final patientData = snapshot.data!.data() as Map<String, dynamic>;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Основная колонка (левая)
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildPatientHeaderCard(patientData),
                              const SizedBox(height: 16),
                              _buildCompactNotesCard(),
                              const SizedBox(height: 16),
                              _buildPersonalInfoCard(patientData),
                              const SizedBox(height: 16),
                              _buildTreatmentHistoryCard(),
                              const SizedBox(height: 16),
                              _buildTreatmentDaysCard(patientData),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Боковая колонка (правая)
                      SizedBox(
                        width: 350,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildFinancialSummaryCard(patientData),
                              const SizedBox(height: 16),
                              _buildTeethSchemaCard(),
                              const SizedBox(height: 16),
                              _buildTreatmentStatsCard(),
                              const SizedBox(height: 16),
                              _buildAdditionalPhotosCard(patientData),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: NeoCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Ошибка: ${snapshot.error}'),
                      ),
                    ),
                  );
                }
              }
              return const Center(
                child: SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Карточка заголовка пациента с основной информацией
  Widget _buildPatientHeaderCard(Map<String, dynamic> patientData) {
    return NeoCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Аватар пациента (уменьшенный) - отцентрирован по вертикали
            Center(
              child: _buildPatientAvatar(patientData['photoUrl'], patientData: patientData),
            ),
            const SizedBox(width: 20),
            
            // Основная информация
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ФИО с подчеркиванием - отцентрировано по горизонтали
                  Center(
                    child: _buildUnderlinedFullName(
                      patientData['surname'] ?? '',
                      patientData['name'] ?? '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Статусные бэйджи
                  _buildStatusBadges(patientData),
                  const SizedBox(height: 16),
                  
                  // Личная информация в сетке
                  _buildPersonalInfoGrid(patientData),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Карточка финансовой сводки (компактная версия)
  Widget _buildFinancialSummaryCard(Map<String, dynamic> patientData) {
    final paymentsData = patientData['payments'] as List<dynamic>? ?? [];
    final payments = paymentsData.map((p) => Payment.fromMap(p)).toList();
    final totalPaid = payments.fold<double>(0, (sum, p) => sum + p.amount);
    final price = (patientData['price'] ?? 0) as num;
    final remain = price - totalPaid;

    return NeoCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Заголовок с подчеркиванием по центру
            Center(
              child: _buildUnderlinedTitle('Оплата', '💰'),
            ),
            const SizedBox(height: 20),
            
            // Вертикальные финансовые показатели с разделителями
            Column(
              children: [
                _buildCompactFinancialItem(
                  '${priceFormatter.format(price)} ₽',
                  Icons.account_balance_wallet_outlined,
                  DesignTokens.accentPrimary,
                ),
                _buildFinancialDivider(),
                GestureDetector(
                  onTap: () => _showPaymentHistoryDialog(context, payments),
                  child: _buildCompactFinancialItem(
                    '${priceFormatter.format(totalPaid)} ₽',
                    Icons.credit_card_outlined,
                    DesignTokens.accentSuccess,
                  ),
                ),
                _buildFinancialDivider(),
                _buildCompactFinancialItem(
                  '${priceFormatter.format(remain)} ₽',
                  Icons.schedule_outlined,
                  remain > 0 ? DesignTokens.accentWarning : DesignTokens.accentSuccess,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Карточка управления статусами (с 4 статусами)
  Widget _buildPersonalInfoCard(Map<String, dynamic> patientData) {
    return NeoCard(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('⚙️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text('Управление статусами', style: DesignTokens.h4.copyWith(fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            
            // Переключатели статусов в два ряда по 2
            Column(
              children: [
                // Первый ряд
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactStatusToggle(
                        'Список ожидания',
                        patientData['waitingList'] == true,
                        (value) {
                          if (patientData['treatmentFinished'] != true) {
                            setState(() => _waitingList = value ?? false);
                            _updatePatientField('waitingList', value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildCompactStatusToggle(
                        'Второй этап',
                        patientData['secondStage'] == true,
                        (value) {
                          if (patientData['treatmentFinished'] != true) {
                            setState(() => _secondStage = value ?? false);
                            _updatePatientField('secondStage', value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Второй ряд
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactStatusToggle(
                        'Горящий пациент',
                        patientData['hotPatient'] == true,
                        (value) {
                          if (patientData['treatmentFinished'] != true) {
                            setState(() => _hotPatient = value ?? false);
                            _updatePatientField('hotPatient', value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildCompactStatusToggle(
                        'Лечение окончено',
                        patientData['treatmentFinished'] == true,
                        (value) {
                          _handleTreatmentFinishedToggle(value ?? false);
                        },
                        isSpecial: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Карточка истории лечения
  Widget _buildTreatmentHistoryCard() {
    return NeoCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🦷', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text('История лечения', style: DesignTokens.h2),
                  ],
                ),
                // Кнопки действий с пациентом
                Row(
                  children: [
                    NeoButton(
                      label: 'Редактировать данные',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditPatientScreen(patientId: widget.patientId),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
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
                    const SizedBox(width: 8),
                    NeoButton(
                      label: 'Удалить пациента',
                      onPressed: () => _confirmDeletion(context, widget.patientId),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: _buildTreatmentsSection(widget.patientId),
            ),
          ],
        ),
      ),
    );
  }

  /// Карточка счетчика дней лечения
  Widget _buildTreatmentDaysCard(Map<String, dynamic> patientData) {
    final paymentsData = patientData['payments'] as List<dynamic>? ?? [];
    final payments = paymentsData.map((p) => Payment.fromMap(p)).toList();
    final isFinished = patientData['treatmentFinished'] == true;
    
    return NeoCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🕐', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text('Дни лечения', style: DesignTokens.h2),
              ],
            ),
            const SizedBox(height: 20),
            
            _buildTreatmentDaysContent(payments, isFinished),
          ],
        ),
      ),
    );
  }

  /// Содержимое счетчика дней
  Widget _buildTreatmentDaysContent(List<Payment> payments, bool isFinished) {
    if (payments.isEmpty) {
      return NeoCard.inset(
        child: Container(
          width: double.infinity,
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
                style: DesignTokens.h3.copyWith(
                  color: DesignTokens.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Отсчет начнется после первой оплаты',
                style: DesignTokens.body.copyWith(
                  color: DesignTokens.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final firstPaymentDate = _getFirstPaymentDate(payments);
    final daysPassed = _calculateDaysPassed(firstPaymentDate, isFinished);
    final daysColor = _getDaysColor(daysPassed);
    final statusText = isFinished ? 'окончено' : 'в лечении';
    
    return NeoCard.inset(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Основная информация
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: daysColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: daysColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isFinished ? Icons.check_circle : Icons.schedule,
                      color: daysColor,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$daysPassed дн${_getDaysEnding(daysPassed)} $statusText',
                        style: DesignTokens.h2.copyWith(
                          color: daysColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Начато: ${DateFormat('dd.MM.yyyy').format(firstPaymentDate)}',
                        style: DesignTokens.body.copyWith(
                          color: DesignTokens.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Индикатор прогресса
            _buildDaysProgressIndicator(daysPassed, daysColor),
          ],
        ),
      ),
    );
  }

  /// Индикатор прогресса по дням
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

  /// Компактная карточка заметок с кликабельным действием
  Widget _buildCompactNotesCard() {
    return FutureBuilder<String>(
      future: _getPatientNotes(),
      builder: (context, snapshot) {
        final notes = snapshot.data ?? '';
        final hasNotes = notes.trim().isNotEmpty;
        
        return NeoCard(
          child: InkWell(
            onTap: () => _showNotesDialog(context, notes),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        hasNotes ? Icons.note_alt : Icons.note_add_outlined,
                        size: 24,
                        color: hasNotes ? DesignTokens.accentPrimary : DesignTokens.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Заметки',
                        style: DesignTokens.h2.copyWith(
                          color: hasNotes ? DesignTokens.textPrimary : DesignTokens.textMuted,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.open_in_new,
                        size: 16,
                        color: DesignTokens.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: hasNotes 
                          ? DesignTokens.background.withOpacity(0.5)
                          : DesignTokens.background.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasNotes 
                            ? DesignTokens.accentPrimary.withOpacity(0.2)
                            : DesignTokens.shadowDark.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: hasNotes
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getNotesPreview(notes),
                                style: DesignTokens.body.copyWith(
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (notes.length > 100) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Нажмите для просмотра полного текста',
                                  style: DesignTokens.small.copyWith(
                                    color: DesignTokens.accentPrimary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          )
                        : Center(
                            child: Column(
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
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Нажмите для добавления',
                                  style: DesignTokens.small.copyWith(
                                    color: DesignTokens.textMuted,
                                  ),
                                ),
                              ],
                            ),
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

  /// Получить дату первой оплаты
  DateTime _getFirstPaymentDate(List<Payment> payments) {
    if (payments.isEmpty) {
      return DateTime.now();
    }
    
    // Находим самый ранний платеж
    payments.sort((a, b) => a.date.compareTo(b.date));
    return payments.first.date;
  }

  /// Подсчитать количество прошедших дней
  int _calculateDaysPassed(DateTime startDate, bool isFinished) {
    final endDate = isFinished ? startDate : DateTime.now();
    
    if (isFinished) {
      // Если лечение окончено, нужно получить дату окончания
      // Пока возвращаем текущую дату, можно будет доработать
      return DateTime.now().difference(startDate).inDays;
    }
    
    return endDate.difference(startDate).inDays;
  }

  /// Определить цвет в зависимости от количества дней
  Color _getDaysColor(int days) {
    if (days <= 30) {
      return DesignTokens.accentSuccess; // Зеленый до 30 дней
    } else if (days <= 90) {
      return DesignTokens.accentWarning; // Желтый 30-90 дней
    } else {
      return DesignTokens.accentDanger; // Красный свыше 90 дней
    }
  }

  /// Получить правильное окончание для слова "день"
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

  /// Получить краткое превью заметок
  String _getNotesPreview(String notes) {
    if (notes.length <= 100) {
      return notes;
    }
    return '${notes.substring(0, 100)}...';
  }

  /// Модальное окно с заметками
  void _showNotesDialog(BuildContext context, String initialNotes) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: NotesDialogContent(
              patientId: widget.patientId,
              initialNotes: initialNotes,
            ),
          ),
        );
      },
    );
  }

  /// Карточка статистики лечения (список)
  Widget _buildTreatmentStatsCard() {
    return NeoCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📊', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text('Статистика лечения', style: DesignTokens.h2),
              ],
            ),
            const SizedBox(height: 20),
            _buildTreatmentStatsList(),
          ],
        ),
      ),
    );
  }
  Widget _buildTeethSchemaCard() {
    return NeoCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🦷', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text('Схема зубов', style: DesignTokens.h2),
              ],
            ),
            const SizedBox(height: 20),
            _buildTreatmentSchemas(widget.patientId),
          ],
        ),
      ),
    );
  }

  /// Карточка дополнительных фото
  Widget _buildAdditionalPhotosCard(Map<String, dynamic> patientData) {
    return NeoCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('📸', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text('Дополнительные фото', style: DesignTokens.h2),
                  ],
                ),
                NeoButton(
                  label: '+ Добавить',
                  onPressed: _addAdditionalPhoto,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildPhotosGrid(patientData),
          ],
        ),
      ),
    );
  }

  /// Карточка заметок
  Widget _buildNotesCard() {
    return NeoCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📝', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text('Заметки', style: DesignTokens.h2),
              ],
            ),
            const SizedBox(height: 20),
            NotesWidget(patientId: widget.patientId),
          ],
        ),
      ),
    );
  }

  // === ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ ===

  /// Компактный финансовый элемент (только иконка и черные цифры)
  Widget _buildCompactFinancialItem(String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon, 
            size: 18, 
            color: iconColor, // Иконки остаются цветными
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: DesignTokens.body.copyWith(
                color: DesignTokens.textPrimary, // Черный цвет для сумм
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Разделитель между элементами финансовой сводки
  Widget _buildFinancialDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      height: 1,
      color: DesignTokens.shadowDark.withOpacity(0.2),
    );
  }

  /// Подчеркнутый заголовок с иконкой
  Widget _buildUnderlinedTitle(String title, String emoji) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(title, style: DesignTokens.h2),
          ],
        ),
        const SizedBox(height: 8),
        
        // Первая (длинная) линия
        Container(
          width: title.length * 12.0, // Примерная длина по длине текста
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DesignTokens.accentPrimary.withOpacity(0.8),
                DesignTokens.accentPrimary.withOpacity(0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(1),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.accentPrimary.withOpacity(0.2),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 3),
        
        // Вторая (короткая) линия
        Container(
          width: (title.length * 12.0) * 0.7, // 70% от длины первой линии
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DesignTokens.accentPrimary.withOpacity(0.6),
                DesignTokens.accentPrimary.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(0.5),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.accentPrimary.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Подчеркнутое ФИО в стиле классического двойного подчеркивания
  Widget _buildUnderlinedFullName(String surname, String name) {
    final fullName = '$surname $name'.trim();
    
    return Column(
      children: [
        Text(
          fullName,
          style: DesignTokens.h1.copyWith(fontSize: 24),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        
        // Первая (длинная) линия
        Container(
          width: fullName.length * 9.0, // Примерная длина по длине текста
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DesignTokens.accentPrimary.withOpacity(0.8),
                DesignTokens.accentPrimary.withOpacity(0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(1),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.accentPrimary.withOpacity(0.2),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 3),
        
        // Вторая (короткая) линия
        Container(
          width: (fullName.length * 9.0) * 0.7, // 70% от длины первой линии
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DesignTokens.accentPrimary.withOpacity(0.6),
                DesignTokens.accentPrimary.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(0.5),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.accentPrimary.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPatientAvatar(String? photoUrl, {Map<String, dynamic>? patientData}) {
    // Определяем цвет ободка в зависимости от статуса пациента
    Color borderColor = DesignTokens.accentPrimary;
    if (patientData != null) {
      if (patientData['hotPatient'] == true) {
        borderColor = DesignTokens.accentDanger;
      } else if (patientData['secondStage'] == true) {
        borderColor = DesignTokens.accentSuccess;
      } else if (patientData['waitingList'] == true) {
        borderColor = DesignTokens.accentWarning;
      }
    }
    
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(60),
        child: Container(
          width: 114,
          height: 114,
          color: DesignTokens.surface,
          child: photoUrl != null
              ? Image.network(
                  photoUrl, 
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text('👤', style: TextStyle(fontSize: 42)),
                    );
                  },
                )
              : const Center(
                  child: Text('👤', style: TextStyle(fontSize: 42)),
                ),
        ),
      ),
    );
  }

  /// Сетка личной информации для заголовка
  Widget _buildPersonalInfoGrid(Map<String, dynamic> patientData) {
    return FutureBuilder<String>(
      future: _getLastVisitDate(),
      builder: (context, snapshot) {
        final lastVisit = snapshot.data ?? 'Загрузка...';
        
        return Column(
          children: [
            // Первый ряд
            Row(
              children: [
                Expanded(
                  child: _buildCompactInfoItem(
                    'Возраст', 
                    '${patientData['age'] ?? 'Не указан'} лет',
                    Icons.cake_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactInfoItem(
                    'Пол', 
                    '${patientData['gender'] ?? 'Не указан'}',
                    Icons.person_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactInfoItem(
                    'Город', 
                    '${patientData['city'] ?? 'Не указан'}',
                    Icons.location_city_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Второй ряд
            Row(
              children: [
                Expanded(
                  child: _buildCompactInfoItem(
                    'Телефон', 
                    '${patientData['phone'] ?? 'Не указан'}',
                    Icons.phone_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactInfoItem(
                    'Последний визит', 
                    lastVisit,
                    Icons.schedule_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactInfoItem(
                    'Консультация', 
                    patientData['hadConsultation'] == true ? 'Была' : 'Не была',
                    Icons.chat_bubble_outline,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Компактный элемент информации с иконкой
  Widget _buildCompactInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: DesignTokens.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: DesignTokens.shadowDark.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon, 
            size: 16, 
            color: DesignTokens.textSecondary.withOpacity(0.7),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: DesignTokens.small.copyWith(
                    color: DesignTokens.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: DesignTokens.body.copyWith(
                    color: DesignTokens.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Получить дату последнего визита из истории лечения
  Future<String> _getLastVisitDate() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('treatments')
          .where('patientId', isEqualTo: widget.patientId)
          .orderBy('date', descending: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final lastTreatment = snapshot.docs.first;
        final date = (lastTreatment['date'] as Timestamp).toDate();
        
        // Проверяем, сегодня ли был визит
        final today = DateTime.now();
        final treatmentDate = DateTime(date.year, date.month, date.day);
        final todayDate = DateTime(today.year, today.month, today.day);
        
        if (treatmentDate == todayDate) {
          return 'Сегодня';
        } else {
          final difference = todayDate.difference(treatmentDate).inDays;
          if (difference == 1) {
            return 'Вчера';
          } else if (difference < 7) {
            return '$difference дн. назад';
          } else if (difference < 30) {
            final weeks = (difference / 7).floor();
            return '$weeks нед. назад';
          } else if (difference < 365) {
            // Форматируем дату красиво
            final months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 
                           'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
            if (date.year == today.year) {
              return '${date.day} ${months[date.month - 1]}';
            } else {
              return '${date.day} ${months[date.month - 1]} ${date.year}';
            }
          } else {
            return DateFormat('dd.MM.yyyy').format(date);
          }
        }
      } else {
        return 'Не был';
      }
    } catch (e) {
      print('Ошибка получения последнего визита: $e');
      return 'Ошибка';
    }
  }

  Widget _buildStatusBadges(Map<String, dynamic> patientData) {
    final badges = <Widget>[];
    
    if (patientData['waitingList'] == true) {
      badges.add(_buildStatusBadge('Список ожидания', DesignTokens.accentWarning));
    }
    
    if (patientData['secondStage'] == true) {
      badges.add(_buildStatusBadge('Второй этап', DesignTokens.accentSuccess));
    }
    
    if (patientData['hotPatient'] == true) {
      badges.add(_buildStatusBadge('Горящий пациент', DesignTokens.accentDanger));
    }
    
    if (badges.isEmpty) return const SizedBox.shrink();
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: badges,
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: DesignTokens.small.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFinancialMetric(String label, String value, Color accentColor) {
    return NeoCard.inset(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              value,
              style: DesignTokens.h2.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: DesignTokens.small.copyWith(
                color: DesignTokens.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return NeoCard.inset(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: DesignTokens.body.copyWith(
                color: DesignTokens.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                style: DesignTokens.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusToggle(String title, bool value, Function(bool?) onChanged) {
    return NeoCard.inset(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Уменьшенные отступы
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: DesignTokens.small.copyWith( // Уменьшенный шрифт
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            Transform.scale(
              scale: 0.9, // Уменьшенный checkbox
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: DesignTokens.accentPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStatusToggle(String title, bool value, Function(bool?) onChanged, {bool isSpecial = false}) {
    return NeoCard.inset(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: DesignTokens.small.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 10,
                color: isSpecial && value 
                    ? DesignTokens.accentSuccess 
                    : DesignTokens.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Transform.scale(
              scale: 0.75, // Еще меньший checkbox для 4 элементов
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: isSpecial 
                    ? DesignTokens.accentSuccess 
                    : DesignTokens.accentPrimary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Обработка переключения статуса "Лечение окончено"
  void _handleTreatmentFinishedToggle(bool value) async {
    if (value) {
      // При включении "Лечение окончено" отключаем все остальные
      setState(() {
        _waitingList = false;
        _secondStage = false;
        _hotPatient = false;
      });
      
      // Обновляем все статусы в Firebase
      await _updatePatientField('treatmentFinished', true);
      await _updatePatientField('waitingList', false);
      await _updatePatientField('secondStage', false);
      await _updatePatientField('hotPatient', false);
    } else {
      // Просто отключаем статус
      await _updatePatientField('treatmentFinished', false);
    }
  }

  /// Модальное окно с историей платежей (без размытия)
  void _showPaymentHistoryDialog(BuildContext context, List<Payment> payments) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 600,
              height: 700,
              decoration: BoxDecoration(
                color: DesignTokens.background,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: DesignTokens.shadowDark.withOpacity(0.15),
                    blurRadius: 8, // Уменьшено с 20 до 8
                    offset: const Offset(0, 4), // Уменьшено с 10 до 4
                  ),
                  BoxShadow(
                    color: DesignTokens.shadowLight,
                    blurRadius: 8, // Уменьшено с 20 до 8
                    offset: const Offset(0, -4), // Уменьшено с -10 до -4
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Заголовок
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: DesignTokens.accentSuccess.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.payment,
                            color: DesignTokens.accentSuccess,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'История платежей',
                                style: DesignTokens.h2,
                              ),
                              Text(
                                'Всего платежей: ${payments.length}',
                                style: DesignTokens.small.copyWith(
                                  color: DesignTokens.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        NeoButton(
                          label: 'Закрыть',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Список платежей
                    Expanded(
                      child: payments.isEmpty
                          ? NeoCard.inset(
                              child: Container(
                                height: double.infinity,
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.payment_outlined,
                                        size: 64,
                                        color: DesignTokens.textMuted,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Нет платежей',
                                        style: TextStyle(
                                          color: DesignTokens.textMuted,
                                          fontSize: 18,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: payments.length,
                              itemBuilder: (context, index) {
                                final payment = payments[payments.length - 1 - index]; // Обратный порядок
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: NeoCard.inset(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: DesignTokens.accentSuccess,
                                              borderRadius: BorderRadius.circular(6),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: DesignTokens.accentSuccess.withOpacity(0.3),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${priceFormatter.format(payment.amount)} ₽',
                                                  style: DesignTokens.h3.copyWith(
                                                    color: DesignTokens.accentSuccess,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Платеж №${index + 1}',
                                                  style: DesignTokens.small.copyWith(
                                                    color: DesignTokens.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                DateFormat('dd.MM.yyyy').format(payment.date),
                                                style: DesignTokens.body.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                DateFormat('HH:mm').format(payment.date),
                                                style: DesignTokens.small.copyWith(
                                                  color: DesignTokens.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    
                    // Итоговая статистика
                    if (payments.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      NeoCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      'Общая сумма',
                                      style: DesignTokens.small.copyWith(
                                        color: DesignTokens.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${priceFormatter.format(payments.fold<double>(0, (sum, p) => sum + p.amount))} ₽',
                                      style: DesignTokens.h3.copyWith(
                                        color: DesignTokens.accentSuccess,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: DesignTokens.shadowDark.withOpacity(0.2),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      'Средний платеж',
                                      style: DesignTokens.small.copyWith(
                                        color: DesignTokens.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${priceFormatter.format(payments.fold<double>(0, (sum, p) => sum + p.amount) / payments.length)} ₽',
                                      style: DesignTokens.h4.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
          return const NeoCard.inset(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(
                child: Text(
                  'Нет данных о лечении',
                  style: TextStyle(
                    color: DesignTokens.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          );
        }

        final treatments = snapshot.data!;
        final sortedTreatments = treatments.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        return Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedTreatments.length,
            itemBuilder: (context, index) {
              final treatment = sortedTreatments[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: _buildTreatmentStatListItem(treatment.key, treatment.value),
              );
            },
          ),
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

  Widget _buildPhotosGrid(Map<String, dynamic> patientData) {
    final List<dynamic> additionalPhotos = patientData['additionalPhotos'] ?? [];

    if (additionalPhotos.isEmpty) {
      return NeoCard.inset(
        child: Container(
          height: 120,
          child: const Center(
            child: Text(
              'Нет дополнительных фотографий',
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: additionalPhotos.length,
      itemBuilder: (context, index) {
        final photo = additionalPhotos[index];
        return InkWell(
          onTap: () => _showImageDialog(photo),
          child: NeoCard.inset(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                photo['url'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: DesignTokens.textMuted,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // === МЕТОДЫ ДАННЫХ ===

  String _getTreatmentIcon(String treatmentType) {
    final icons = {
      'Кариес': '🦷',
      'Имплантация': '🔩',
      'Удаление': '🗑️',
      'Сканирование': '📷',
      'Эндо': '🔬',
      'Формирователь': '⚙️',
      'PMMA': '🧪',
      'Коронка': '👑',
      'Абатмент': '🔧',
      'Сдача PMMA': '📦',
      'Сдача коронка': '👑',
      'Сдача абатмент': '🔧',
      'Удаление импланта': '❌',
    };
    return icons[treatmentType] ?? '🦷';
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

    // Возвращаем только те типы лечения, которые есть у пациента
    return Map.fromEntries(
      treatmentCounts.entries.where((entry) => entry.value > 0)
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

  Widget _buildTreatmentsSection(String patientId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('treatments')
          .where('patientId', isEqualTo: patientId)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, treatmentSnapshot) {
        if (treatmentSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (treatmentSnapshot.hasError) {
          return Text('Ошибка загрузки данных о лечении: ${treatmentSnapshot.error}');
        }

        if (!treatmentSnapshot.hasData || treatmentSnapshot.data!.docs.isEmpty) {
          return const NeoCard.inset(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(
                child: Text(
                  'Нет данных о лечении',
                  style: TextStyle(
                    color: DesignTokens.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          );
        }

        var treatments = _groupTreatmentsByDate(treatmentSnapshot.data!.docs);

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: treatments.keys.length,
          itemBuilder: (context, index) {
            DateTime date = treatments.keys.elementAt(index);
            var treatmentInfos = treatments[date]!;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: NeoCard.inset(
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: DesignTokens.accentPrimary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('dd.MM.yyyy').format(date),
                          style: DesignTokens.body.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '(${treatmentInfos.length} процедур)',
                          style: DesignTokens.small.copyWith(
                            color: DesignTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    children: treatmentInfos.map((treatmentInfo) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          children: [
                            Text(_getTreatmentIcon(treatmentInfo.treatmentType)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                treatmentInfo.treatmentType,
                                style: DesignTokens.body,
                              ),
                            ),
                            Text(
                              'Зубы: ${treatmentInfo.toothNumbers.join(", ")}',
                              style: DesignTokens.small.copyWith(
                                color: DesignTokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          },
        );
      },
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

  int _getToothNumber(int index) {
    if (index < 16) {
      // Верхний ряд: 18 17 16 15 14 13 12 11 21 22 23 24 25 26 27 28
      return index < 8 ? 18 - index : 21 + (index - 8);
    } else {
      // Нижний ряд: 48 47 46 45 44 43 42 41 31 32 33 34 35 36 37 38
      return index < 24 ? 48 - (index - 16) : 31 + (index - 24);
    }
  }

  Map<DateTime, List<TreatmentInfo>> _groupTreatmentsByDate(List<DocumentSnapshot> docs) {
    Map<DateTime, List<TreatmentInfo>> groupedTreatments = {};

    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      var timestamp = data['date'] as Timestamp;
      var dateWithoutTime = DateTime(timestamp.toDate().year, timestamp.toDate().month, timestamp.toDate().day);
      var treatmentType = data['treatmentType'];
      var toothNumbers = data['toothNumber'] != null ? List<int>.from(data['toothNumber']) : <int>[];
      var documentId = doc.id;

      if (!groupedTreatments.containsKey(dateWithoutTime)) {
        groupedTreatments[dateWithoutTime] = [];
      }

      bool found = false;
      for (var treatmentInfo in groupedTreatments[dateWithoutTime]!) {
        if (treatmentInfo.treatmentType == treatmentType) {
          found = true;
          treatmentInfo.toothNumbers.addAll(toothNumbers.where((num) => !treatmentInfo.toothNumbers.contains(num)));
          break;
        }
      }

      if (!found) {
        groupedTreatments[dateWithoutTime]!.add(TreatmentInfo(treatmentType, toothNumbers, documentId));
      }
    }

    return groupedTreatments;
  }

  void _showImageDialog(Map<String, dynamic> photo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: DesignTokens.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: Image.network(
                      photo['url'],
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (photo['description'] != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    photo['description'],
                    style: DesignTokens.body,
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  DateFormat('dd.MM.yyyy').format((photo['dateAdded'] as Timestamp).toDate()),
                  style: DesignTokens.small.copyWith(
                    color: DesignTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                NeoButton(
                  label: 'Закрыть',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addAdditionalPhoto() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      File imageFile = File(image.path);
      String fileName = 'additional_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      try {
        TaskSnapshot uploadTask = await FirebaseStorage.instance
            .ref('patients/${widget.patientId}/$fileName')
            .putFile(imageFile);
        
        String imageUrl = await uploadTask.ref.getDownloadURL();
        
        await FirebaseFirestore.instance.collection('patients').doc(widget.patientId).update({
          'additionalPhotos': FieldValue.arrayUnion([
            {
              'url': imageUrl,
              'description': 'Дополнительное фото',
              'dateAdded': Timestamp.now(),
            }
          ]),
        });
        
        setState(() {});
      } catch (e) {
        print('Error uploading additional photo: $e');
      }
    }
  }

  void _navigateAndDisplaySelection(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TreatmentSelectionScreen()),
    );

    if (result != null) {
      _plannedTreatmentController.text += (result + '\n');
      await _savePlannedTreatment(_plannedTreatmentController.text);
    }
  }

  Future<void> _savePlannedTreatment(String treatment) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('planned_treatment_${widget.patientId}', treatment);
  }

  Future<void> _loadPlannedTreatment() async {
    final prefs = await SharedPreferences.getInstance();
    String treatment = prefs.getString('planned_treatment_${widget.patientId}') ?? '';
    _plannedTreatmentController.text = treatment;
  }

  void _confirmDeletion(BuildContext context, String patientId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: DesignTokens.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Удалить пациента', style: DesignTokens.h3),
          content: Text(
            'Вы уверены, что хотите удалить этого пациента? Это действие нельзя будет отменить.',
            style: DesignTokens.body,
          ),
          actions: <Widget>[
            NeoButton(
              label: 'Отмена',
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 12),
            NeoButton(
              label: 'Удалить',
              onPressed: () {
                FirebaseFirestore.instance.collection('patients').doc(patientId).delete().then((_) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                });
              },
            ),
          ],
        );
      },
    );
  }
}

class TreatmentInfo {
  String treatmentType;
  List<int> toothNumbers;
  String? id;

  TreatmentInfo(this.treatmentType, this.toothNumbers, this.id);

  Map<String, dynamic> toMap() {
    return {
      'treatmentType': treatmentType,
      'toothNumbers': toothNumbers,
      'id': id
    };
  }
}

class TreatmentSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<String> treatments = [
      '1 сегмент', '2 сегмент', '3 сегмент', '4 сегмент',
      'Имплантация', 'Коронки', 'Лечение', 'Удаление'
    ];

    return Scaffold(
      backgroundColor: DesignTokens.background,
      appBar: AppBar(
        title: Text('Выбор лечения'),
        backgroundColor: DesignTokens.background,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: treatments.length,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: NeoCard(
                child: ListTile(
                  title: Text(
                    treatments[index],
                    style: DesignTokens.body,
                  ),
                  onTap: () {
                    Navigator.pop(context, treatments[index]);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Содержимое модального окна заметок с режимами просмотра и редактирования
class NotesDialogContent extends StatefulWidget {
  final String patientId;
  final String initialNotes;

  const NotesDialogContent({
    super.key,
    required this.patientId,
    required this.initialNotes,
  });

  @override
  _NotesDialogContentState createState() => _NotesDialogContentState();
}

class _NotesDialogContentState extends State<NotesDialogContent> {
  late TextEditingController _notesController;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.initialNotes);
    _notesController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _notesController.removeListener(_onTextChanged);
    _notesController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_hasChanges && _notesController.text != widget.initialNotes) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveNotes() async {
    if (!_hasChanges) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .update({'notes': _notesController.text});
      
      setState(() {
        _isEditing = false;
        _isLoading = false;
        _hasChanges = false;
      });
      
      _showSuccessSnackBar('Заметки сохранены');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Ошибка при сохранении: $e');
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _hasChanges = false;
      _notesController.text = widget.initialNotes;
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: DesignTokens.accentSuccess,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: DesignTokens.accentDanger,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasNotes = widget.initialNotes.trim().isNotEmpty;
    
    return Container(
      width: 600,
      height: 700,
      decoration: BoxDecoration(
        color: DesignTokens.background,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.shadowDark.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: DesignTokens.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Заголовок
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: hasNotes 
                        ? DesignTokens.accentPrimary.withOpacity(0.2)
                        : DesignTokens.textMuted.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    hasNotes ? Icons.note_alt : Icons.note_add_outlined,
                    color: hasNotes ? DesignTokens.accentPrimary : DesignTokens.textMuted,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Заметки о пациенте',
                        style: DesignTokens.h2,
                      ),
                      Text(
                        _isEditing ? 'Режим редактирования' : 'Режим просмотра',
                        style: DesignTokens.small.copyWith(
                          color: _isEditing ? DesignTokens.accentPrimary : DesignTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                NeoButton(
                  label: 'Закрыть',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Область заметок
            Expanded(
              child: NeoCard.inset(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _isEditing ? _buildEditingView() : _buildReadonlyView(),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Кнопки управления
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildReadonlyView() {
    final notesText = _notesController.text.trim();
    
    if (notesText.isEmpty) {
      return Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_add_outlined,
              size: 64,
              color: DesignTokens.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет заметок о пациенте',
              style: DesignTokens.h3.copyWith(
                color: DesignTokens.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Нажмите "Редактировать" чтобы добавить заметки',
              style: DesignTokens.body.copyWith(
                color: DesignTokens.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notesText,
              style: DesignTokens.body.copyWith(
                height: 1.6,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditingView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasChanges)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: DesignTokens.accentWarning.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit,
                  size: 16,
                  color: DesignTokens.accentWarning,
                ),
                const SizedBox(width: 8),
                Text(
                  'Есть несохраненные изменения',
                  style: DesignTokens.small.copyWith(
                    color: DesignTokens.accentWarning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        if (_hasChanges) const SizedBox(height: 12),
        
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _hasChanges 
                    ? DesignTokens.accentPrimary.withOpacity(0.3)
                    : DesignTokens.shadowDark.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _notesController,
              maxLines: null,
              expands: true,
              style: DesignTokens.body.copyWith(fontSize: 16),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                hintText: 'Введите заметки о пациенте...\n\nМожете указать:\n• Особенности лечения\n• Предпочтения пациента\n• Аллергии или противопоказания\n• Важные замечания',
                hintStyle: DesignTokens.body.copyWith(
                  color: DesignTokens.textMuted,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    if (_isEditing) {
      return Row(
        children: [
          Expanded(
            child: NeoButton(
              label: 'Отмена',
              onPressed: _isLoading ? null : _cancelEditing,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: NeoButton(
              label: _isLoading ? 'Сохранение...' : 'Сохранить',
              primary: true,
              onPressed: (_isLoading || !_hasChanges) ? null : _saveNotes,
            ),
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: NeoButton(
          label: 'Редактировать заметки',
          primary: true,
          onPressed: _isLoading ? null : () {
            setState(() {
              _isEditing = true;
            });
          },
        ),
      );
    }
  }
}
