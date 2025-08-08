import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../design_system/design_system_screen.dart' show NeoButton, DesignTokens;
import '../../../edit_patient_screen.dart';
import '../../../add_treatment_screen.dart';
import '../../../payment.dart';

final priceFormatter = NumberFormat('#,###', 'ru_RU');

class PatientHeader extends StatelessWidget {
  final Map<String, dynamic> patientData;
  final String patientId;
  final int selectedIndex;
  final VoidCallback onAddPayment;
  final VoidCallback onAddPhoto;

  const PatientHeader({
    Key? key,
    required this.patientData,
    required this.patientId,
    required this.selectedIndex,
    required this.onAddPayment,
    required this.onAddPhoto,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160, // Увеличенная высота для размещения всей информации
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.background,
            DesignTokens.surface.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.shadowDark.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: DesignTokens.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Верхняя часть с ФИО, личной информацией и статусами
          Container(
            padding: const EdgeInsets.only(top: 20, left: 30, right: 30, bottom: 10),
            child: Column(
              children: [
                // ФИО с подчеркиванием по центру
                _buildCenteredPatientName(),
                const SizedBox(height: 16),
                // Личная информация в простом формате
                _buildSimplePersonalInfo(),
                const SizedBox(height: 12),
                // Статусные бэйджи по центру
                _buildCenteredStatusBadges(),
              ],
            ),
          ),
          
          // Разделитель
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  DesignTokens.shadowDark.withOpacity(0.1),
                  DesignTokens.shadowDark.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          
          // Нижняя часть с информацией и действиями
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              child: Row(
                children: [
                  // Личная информация
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHeaderInfoCard(
                          Icons.cake_outlined, 
                          'Возраст', 
                          '${patientData['age'] ?? '—'} лет',
                          color: DesignTokens.accentPrimary,
                        ),
                        const SizedBox(width: 16),
                        _buildHeaderInfoCard(
                          patientData['gender'] == 'Мужчина' 
                              ? Icons.male_outlined 
                              : patientData['gender'] == 'Женщина' 
                                  ? Icons.female_outlined 
                                  : Icons.person_outline,
                          'Пол', 
                          patientData['gender'] ?? 'Не указан',
                          color: DesignTokens.accentSecondary,
                        ),
                        const SizedBox(width: 16),
                        _buildHeaderInfoCard(
                          Icons.phone_outlined, 
                          'Телефон', 
                          _formatPhone(patientData['phone'] ?? 'Не указан'),
                          color: DesignTokens.accentSuccess,
                        ),
                        const SizedBox(width: 16),
                        _buildHeaderInfoCard(
                          Icons.location_city_outlined, 
                          'Город', 
                          patientData['city'] ?? 'Не указан',
                          color: DesignTokens.accentWarning,
                        ),
                        const SizedBox(width: 16),
                        FutureBuilder<String>(
                          future: _getLastVisitDate(),
                          builder: (context, snapshot) {
                            return _buildHeaderInfoCard(
                              Icons.schedule_outlined,
                              'Последний визит',
                              snapshot.data ?? 'Загрузка...',
                              color: DesignTokens.accentPrimary,
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        _buildHeaderFinanceCard(),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 30),
                  
                  // Контекстные действия
                  _buildContextActions(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ФИО по центру с двойным подчеркиванием
  Widget _buildCenteredPatientName() {
    final surname = patientData['surname'] ?? '';
    final name = patientData['name'] ?? '';
    final fullName = '$surname $name'.trim();
    
    return Column(
      children: [
        Text(
          fullName.isEmpty ? 'Пациент' : fullName,
          style: DesignTokens.h1.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        
        // Двойное подчеркивание
        Stack(
          alignment: Alignment.center,
          children: [
            // Первая (длинная) линия
            Container(
              width: fullName.length * 14.0,
              constraints: const BoxConstraints(maxWidth: 400),
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    DesignTokens.accentPrimary.withOpacity(0.8),
                    DesignTokens.accentPrimary.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(1.5),
                boxShadow: [
                  BoxShadow(
                    color: DesignTokens.accentPrimary.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            
            // Вторая (короткая) линия
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: fullName.length * 10.0,
                constraints: const BoxConstraints(maxWidth: 280),
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      DesignTokens.accentPrimary.withOpacity(0.5),
                      DesignTokens.accentPrimary.withOpacity(0.5),
                      Colors.transparent,
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
            ),
          ],
        ),
      ],
    );
  }

  /// Статусные бэйджи по центру
  Widget _buildCenteredStatusBadges() {
    final badges = <Widget>[];
    
    if (patientData['hotPatient'] == true) {
      badges.add(_buildStatusBadge('🔥 Горящий пациент', DesignTokens.accentDanger));
    }
    if (patientData['secondStage'] == true) {
      badges.add(_buildStatusBadge('2️⃣ Второй этап', DesignTokens.accentSuccess));
    }
    if (patientData['waitingList'] == true) {
      badges.add(_buildStatusBadge('⏳ Список ожидания', DesignTokens.accentWarning));
    }
    if (patientData['treatmentFinished'] == true) {
      badges.add(_buildStatusBadge('✅ Лечение окончено', DesignTokens.accentSuccess));
    }
    
    if (badges.isEmpty) {
      return const SizedBox(height: 20); // Пустое место, если нет статусов
    }
    
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: badges,
    );
  }
  
  /// Бэйдж статуса
  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
  
  /// Простая личная информация для верхней части заголовка
  Widget _buildSimplePersonalInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Возраст
        Row(
          children: [
            Icon(
              Icons.cake_outlined,
              size: 16,
              color: DesignTokens.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              '${patientData['age'] ?? '—'} лет',
              style: DesignTokens.body.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        
        // Пол
        Row(
          children: [
            Icon(
              patientData['gender'] == 'Мужчина' 
                  ? Icons.male_outlined 
                  : patientData['gender'] == 'Женщина' 
                      ? Icons.female_outlined 
                      : Icons.person_outline,
              size: 16,
              color: DesignTokens.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              patientData['gender'] ?? 'Не указан',
              style: DesignTokens.body.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        
        // Город
        Row(
          children: [
            Icon(
              Icons.location_city_outlined,
              size: 16,
              color: DesignTokens.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              patientData['city'] ?? 'Не указан',
              style: DesignTokens.body.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        
        // Телефон
        Row(
          children: [
            Icon(
              Icons.phone_outlined,
              size: 16,
              color: DesignTokens.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              _formatPhone(patientData['phone'] ?? 'Не указан'),
              style: DesignTokens.body.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Карточка информации в заголовке
  Widget _buildHeaderInfoCard(IconData icon, String label, String value, {Color? color}) {
    final cardColor = color ?? DesignTokens.accentPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: const BoxConstraints(minWidth: 100),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.surface,
            DesignTokens.surface.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: DesignTokens.shadowLight,
            blurRadius: 6,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: cardColor.withOpacity(0.8),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: DesignTokens.textSecondary,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: DesignTokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// Карточка финансовой информации в заголовке
  Widget _buildHeaderFinanceCard() {
    final paymentsData = patientData['payments'] as List<dynamic>? ?? [];
    final payments = paymentsData.map((p) => Payment.fromMap(p)).toList();
    final totalPaid = payments.fold<double>(0, (sum, p) => sum + p.amount);
    final price = (patientData['price'] ?? 0) as num;
    final remain = price - totalPaid;
    
    // Определяем цвет в зависимости от остатка
    Color financeColor;
    IconData financeIcon;
    String financeLabel;
    String financeValue;
    
    if (remain > 0) {
      financeColor = DesignTokens.accentDanger;
      financeIcon = Icons.payment_outlined;
      financeLabel = 'Остаток';
      financeValue = '${priceFormatter.format(remain)} ₽';
    } else {
      financeColor = DesignTokens.accentSuccess;
      financeIcon = Icons.check_circle_outline;
      financeLabel = 'Оплачено';
      financeValue = 'Полностью';
    }
    
    return _buildHeaderInfoCard(
      financeIcon,
      financeLabel,
      financeValue,
      color: financeColor,
    );
  }
  
  /// Форматирование телефона
  String _formatPhone(String phone) {
    if (phone == 'Не указан' || phone.isEmpty) {
      return 'Не указан';
    }
    
    // Удаляем все не-цифры
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    
    // Если это российский номер
    if (digits.length == 11 && (digits.startsWith('7') || digits.startsWith('8'))) {
      return '+7 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7, 9)}-${digits.substring(9)}';
    }
    
    // Если это 10-значный номер без кода страны
    if (digits.length == 10) {
      return '+7 (${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, 8)}-${digits.substring(8)}';
    }
    
    // Возвращаем как есть
    return phone;
  }

  /// Получение даты последнего визита
  Future<String> _getLastVisitDate() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('treatments')
          .where('patientId', isEqualTo: patientId)
          .orderBy('date', descending: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final lastTreatment = snapshot.docs.first;
        final date = (lastTreatment['date'] as Timestamp).toDate();
        
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

  /// Контекстные действия в заголовке
  Widget _buildContextActions(BuildContext context) {
    // Действия меняются в зависимости от текущего раздела
    switch (selectedIndex) {
      case 0: // Обзор
        return Row(
          children: [
            NeoButton(
              label: 'Редактировать',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditPatientScreen(patientId: patientId),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            NeoButton(
              label: 'Удалить',
              onPressed: () => _confirmDeletion(context),
            ),
          ],
        );
      
      case 1: // Лечение
        return NeoButton(
          label: '+ Добавить лечение',
          primary: true,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddTreatmentScreen(patientId: patientId),
              ),
            );
          },
        );
      
      case 2: // Финансы
        return NeoButton(
          label: '+ Добавить платеж',
          primary: true,
          onPressed: onAddPayment,
        );
      
      case 4: // Документы
        return NeoButton(
          label: '+ Добавить фото',
          onPressed: onAddPhoto,
        );
      
      default:
        return const SizedBox.shrink();
    }
  }

  /// Подтверждение удаления пациента
  void _confirmDeletion(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Удалить пациента'),
          content: Text('Вы уверены, что хотите удалить этого пациента? Это действие нельзя отменить.'),
          actions: <Widget>[
            TextButton(
              child: Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Удалить'),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await FirebaseFirestore.instance
                      .collection('patients')
                      .doc(patientId)
                      .delete();
                  Navigator.of(context).pop(); // Возвращаемся назад
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка при удалении: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}