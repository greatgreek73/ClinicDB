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
                              _buildFinancialSummaryCard(patientData),
                              const SizedBox(height: 16),
                              _buildPersonalInfoCard(patientData),
                              const SizedBox(height: 16),
                              _buildTreatmentHistoryCard(),
                              const SizedBox(height: 16),
                              _buildPlannedTreatmentCard(),
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
                              _buildTreatmentStatsCard(),
                              const SizedBox(height: 16),
                              _buildTeethSchemaCard(),
                              const SizedBox(height: 16),
                              _buildAdditionalPhotosCard(patientData),
                              const SizedBox(height: 16),
                              _buildNotesCard(),
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
                  // ФИО - отцентрировано по горизонтали
                  Center(
                    child: Text(
                      '${patientData['surname'] ?? ''} ${patientData['name'] ?? ''}'.trim(),
                      style: DesignTokens.h1.copyWith(fontSize: 24),
                      textAlign: TextAlign.center,
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

  /// Карточка финансовой сводки
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('💰', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text('Финансовая сводка', style: DesignTokens.h2),
              ],
            ),
            const SizedBox(height: 20),
            
            // Основные финансовые показатели
            Row(
              children: [
                Expanded(
                  child: _buildFinancialMetric(
                    'Общая стоимость',
                    '${priceFormatter.format(price)} ₽',
                    DesignTokens.accentPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFinancialMetric(
                    'Оплачено',
                    '${priceFormatter.format(totalPaid)} ₽',
                    DesignTokens.accentSuccess,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFinancialMetric(
                    'К доплате',
                    '${priceFormatter.format(remain)} ₽',
                    remain > 0 ? DesignTokens.accentWarning : DesignTokens.accentSuccess,
                  ),
                ),
              ],
            ),
            
            if (payments.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text('💳', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text('История платежей', style: DesignTokens.h4),
                ],
              ),
              const SizedBox(height: 12),
              _buildPaymentsHistory(payments),
            ],
          ],
        ),
      ),
    );
  }

  /// Карточка управления статусами (уменьшенная версия)
  Widget _buildPersonalInfoCard(Map<String, dynamic> patientData) {
    return NeoCard(
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Еще более уменьшенные отступы
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('⚙️', style: TextStyle(fontSize: 18)), // Уменьшенная иконка
                const SizedBox(width: 6),
                Text('Управление статусами', style: DesignTokens.h4.copyWith(fontSize: 15)), // Еще меньший заголовок
              ],
            ),
            const SizedBox(height: 12),
            
            // Переключатели статусов в компактном виде
            Row(
              children: [
                Expanded(
                  child: _buildCompactStatusToggle(
                    'Список ожидания',
                    patientData['waitingList'] == true,
                    (value) {
                      setState(() => _waitingList = value ?? false);
                      _updatePatientField('waitingList', value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCompactStatusToggle(
                    'Второй этап',
                    patientData['secondStage'] == true,
                    (value) {
                      setState(() => _secondStage = value ?? false);
                      _updatePatientField('secondStage', value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCompactStatusToggle(
                    'Горящий пациент',
                    patientData['hotPatient'] == true,
                    (value) {
                      setState(() => _hotPatient = value ?? false);
                      _updatePatientField('hotPatient', value);
                    },
                  ),
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

  /// Карточка планируемого лечения с действиями
  Widget _buildPlannedTreatmentCard() {
    return NeoCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📋', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text('Планируемое лечение', style: DesignTokens.h2),
              ],
            ),
            const SizedBox(height: 20),
            
            NeoCard.inset(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _plannedTreatmentController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Введите план лечения...',
                    hintStyle: TextStyle(color: DesignTokens.textMuted),
                  ),
                  readOnly: true,
                  maxLines: null,
                  minLines: 3,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Кнопки действий для планов
            Row(
              children: [
                NeoButton(
                  label: 'Добавить план',
                  primary: true,
                  onPressed: () => _navigateAndDisplaySelection(context),
                ),
                const SizedBox(width: 12),
                NeoButton(
                  label: 'Очистить',
                  onPressed: () {
                    _plannedTreatmentController.clear();
                    _savePlannedTreatment('');
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
          ],
        ),
      ),
    );
  }

  /// Карточка статистики лечения
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
            _buildTreatmentStatsGrid(),
          ],
        ),
      ),
    );
  }

  /// Карточка схемы зубов
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
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 76,
          height: 76,
          color: DesignTokens.surface,
          child: photoUrl != null
              ? Image.network(
                  photoUrl, 
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text('👤', style: TextStyle(fontSize: 28)),
                    );
                  },
                )
              : const Center(
                  child: Text('👤', style: TextStyle(fontSize: 28)),
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

  Widget _buildCompactStatusToggle(String title, bool value, Function(bool?) onChanged) {
    return NeoCard.inset(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Очень компактные отступы
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: DesignTokens.small.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Transform.scale(
              scale: 0.8, // Еще меньший checkbox
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: DesignTokens.accentPrimary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsHistory(List<Payment> payments) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        child: Column(
          children: payments.map((payment) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: NeoCard.inset(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: DesignTokens.accentSuccess,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${priceFormatter.format(payment.amount)} ₽',
                          style: DesignTokens.body.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        DateFormat('dd.MM.yyyy').format(payment.date),
                        style: DesignTokens.small.copyWith(
                          color: DesignTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTreatmentStatsGrid() {
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
          return const Text('Нет данных о лечении');
        }

        final treatments = snapshot.data!;
        final sortedTreatments = treatments.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: sortedTreatments.length.clamp(0, 6), // Показываем максимум 6
          itemBuilder: (context, index) {
            final treatment = sortedTreatments[index];
            return _buildTreatmentStatCard(treatment.key, treatment.value);
          },
        );
      },
    );
  }

  Widget _buildTreatmentStatCard(String treatmentType, int count) {
    final icon = _getTreatmentIcon(treatmentType);
    final color = _getColor(treatmentType);
    
    return NeoCard.inset(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: DesignTokens.h2.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              treatmentType,
              style: DesignTokens.small.copyWith(
                color: DesignTokens.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
