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

class _PatientDetailsScreenState extends State<PatientDetailsScreen> with SingleTickerProviderStateMixin {
  // Текущий выбранный раздел
  int _selectedIndex = 0;
  
  // Контроллер анимации для плавных переходов
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Контроллер для планируемого лечения
  final TextEditingController _plannedTreatmentController = TextEditingController();

  // Статусы пациента
  bool _waitingList = false;
  bool _secondStage = false;
  bool _hotPatient = false;

  // Разделы навигации
  final List<NavigationSection> _sections = [
    NavigationSection(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Обзор', emoji: '📋'),
    NavigationSection(icon: Icons.medical_services_outlined, activeIcon: Icons.medical_services, label: 'Лечение', emoji: '🦷'),
    NavigationSection(icon: Icons.payments_outlined, activeIcon: Icons.payments, label: 'Финансы', emoji: '💰'),
    NavigationSection(icon: Icons.analytics_outlined, activeIcon: Icons.analytics, label: 'Статистика', emoji: '📊'),
    NavigationSection(icon: Icons.photo_library_outlined, activeIcon: Icons.photo_library, label: 'Документы', emoji: '📸'),
    NavigationSection(icon: Icons.note_alt_outlined, activeIcon: Icons.note_alt, label: 'Заметки', emoji: '📝'),
  ];

  @override
  void initState() {
    super.initState();
    _loadPlannedTreatment();
    
    // Инициализация анимации
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _plannedTreatmentController.dispose();
    _animationController.dispose();
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

  void _changeSection(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      body: SafeArea(
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
                  children: [
                    // Боковая навигационная панель
                    _buildNavigationRail(patientData),
                    
                    // Вертикальный разделитель
                    Container(
                      width: 1,
                      color: DesignTokens.shadowDark.withOpacity(0.1),
                    ),
                    
                    // Основная область контента
                    Expanded(
                      child: Column(
                        children: [
                          // Постоянный заголовок с информацией о пациенте
                          _buildPatientHeader(patientData),
                          
                          // Разделитель
                          Container(
                            height: 1,
                            color: DesignTokens.shadowDark.withOpacity(0.1),
                          ),
                          
                          // Анимированный контент выбранного раздела
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              switchInCurve: Curves.easeInOut,
                              switchOutCurve: Curves.easeInOut,
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.05, 0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildCurrentSection(patientData),
                            ),
                          ),
                        ],
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
    );
  }

  /// Боковая навигационная панель
  Widget _buildNavigationRail(Map<String, dynamic> patientData) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: DesignTokens.surface,
        boxShadow: [
          BoxShadow(
            color: DesignTokens.shadowDark.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Аватар пациента вверху (вернули на место)
          Container(
            padding: const EdgeInsets.all(12),
            child: _buildCompactAvatar(patientData['photoUrl'], patientData: patientData),
          ),
          
          const Divider(height: 1),
          
          // Навигационные элементы
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _sections.length,
              itemBuilder: (context, index) {
                final section = _sections[index];
                final isSelected = _selectedIndex == index;
                
                return _buildNavItem(
                  icon: isSelected ? section.activeIcon : section.icon,
                  label: section.label,
                  emoji: section.emoji,
                  isSelected: isSelected,
                  onTap: () => _changeSection(index),
                );
              },
            ),
          ),
          
          // Кнопка выхода/назад внизу
          Container(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: DesignTokens.background.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                iconSize: 20,
                color: DesignTokens.textSecondary,
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Назад',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Элемент навигации
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required String emoji,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? DesignTokens.background : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? DesignTokens.innerShadows(blur: 8, offset: 4)
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Эмодзи или иконка
                Text(
                  emoji,
                  style: TextStyle(
                    fontSize: isSelected ? 24 : 20,
                  ),
                ),
                const SizedBox(height: 4),
                // Подпись
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? DesignTokens.accentPrimary : DesignTokens.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Компактный аватар для боковой панели
  Widget _buildCompactAvatar(String? photoUrl, {Map<String, dynamic>? patientData}) {
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
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          color: DesignTokens.surface,
          child: photoUrl != null
              ? Image.network(
                  photoUrl, 
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text('👤', style: TextStyle(fontSize: 24)),
                    );
                  },
                )
              : const Center(
                  child: Text('👤', style: TextStyle(fontSize: 24)),
                ),
        ),
      ),
    );
  }

  /// Постоянный заголовок пациента
  Widget _buildPatientHeader(Map<String, dynamic> patientData) {
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
                _buildCenteredPatientName(patientData),
                const SizedBox(height: 16),
                // Личная информация в простом формате
                _buildSimplePersonalInfo(patientData),
                const SizedBox(height: 12),
                // Статусные бэйджи по центру
                _buildCenteredStatusBadges(patientData),
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
                        _buildHeaderFinanceCard(patientData),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 30),
                  
                  // Контекстные действия
                  _buildContextActions(patientData),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ФИО по центру с двойным подчеркиванием
  Widget _buildCenteredPatientName(Map<String, dynamic> patientData) {
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
  Widget _buildCenteredStatusBadges(Map<String, dynamic> patientData) {
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
  
  /// Мини-бэйдж статуса в заголовке (оставляем для совместимости)
  Widget _buildMiniStatusBadge(String text, Color color) {
    return _buildStatusBadge(text, color);
  }
  
  /// Простая личная информация для верхней части заголовка
  Widget _buildSimplePersonalInfo(Map<String, dynamic> patientData) {
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
  Widget _buildHeaderFinanceCard(Map<String, dynamic> patientData) {
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
  
  /// Элемент информации в заголовке (старый метод для совместимости)
  Widget _buildHeaderInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: DesignTokens.textSecondary),
        const SizedBox(width: 6),
        Text(
          text,
          style: DesignTokens.small.copyWith(
            color: DesignTokens.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Контекстные действия в заголовке
  Widget _buildContextActions(Map<String, dynamic> patientData) {
    // Действия меняются в зависимости от текущего раздела
    switch (_selectedIndex) {
      case 0: // Обзор
        return Row(
          children: [
            NeoButton(
              label: 'Редактировать',
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
              label: 'Удалить',
              onPressed: () => _confirmDeletion(context, widget.patientId),
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
                builder: (context) => AddTreatmentScreen(patientId: widget.patientId),
              ),
            );
          },
        );
      
      case 2: // Финансы
        return NeoButton(
          label: '+ Добавить платеж',
          primary: true,
          onPressed: () => _showAddPaymentDialog(context, patientData),
        );
      
      case 4: // Документы
        return NeoButton(
          label: '+ Добавить фото',
          onPressed: _addAdditionalPhoto,
        );
      
      default:
        return const SizedBox.shrink();
    }
  }

  /// Построение контента текущего раздела
  Widget _buildCurrentSection(Map<String, dynamic> patientData) {
    // Ключ для AnimatedSwitcher
    final key = ValueKey<int>(_selectedIndex);
    
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewSection(key, patientData);
      case 1:
        return _buildTreatmentSection(key, patientData);
      case 2:
        return _buildFinanceSection(key, patientData);
      case 3:
        return _buildStatisticsSection(key, patientData);
      case 4:
        return _buildDocumentsSection(key, patientData);
      case 5:
        return _buildNotesSection(key, patientData);
      default:
        return const SizedBox.shrink();
    }
  }

  /// РАЗДЕЛ: Обзор
  Widget _buildOverviewSection(Key key, Map<String, dynamic> patientData) {
    return Container(
      key: key,
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
                        _buildPersonalInfoContent(patientData),
                      ),
                      const SizedBox(height: 16),
                      _buildOverviewCard(
                        '⚙️ Управление статусами',
                        _buildStatusManagementContent(patientData),
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
                        _buildFinancialSummaryContent(patientData),
                      ),
                      const SizedBox(height: 16),
                      _buildOverviewCard(
                        '🕐 Дни лечения',
                        _buildTreatmentDaysContent(patientData),
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
              _buildQuickNotesContent(patientData),
            ),
          ],
        ),
      ),
    );
  }

  /// РАЗДЕЛ: Лечение
  Widget _buildTreatmentSection(Key key, Map<String, dynamic> patientData) {
    return Container(
      key: key,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('📋', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Text('История лечения', style: DesignTokens.h3),
                          ],
                        ),
                        Text(
                          'Timeline',
                          style: DesignTokens.small.copyWith(
                            color: DesignTokens.textSecondary,
                          ),
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

  /// РАЗДЕЛ: Финансы
  Widget _buildFinanceSection(Key key, Map<String, dynamic> patientData) {
    final paymentsData = patientData['payments'] as List<dynamic>? ?? [];
    final payments = paymentsData.map((p) => Payment.fromMap(p)).toList();
    final totalPaid = payments.fold<double>(0, (sum, p) => sum + p.amount);
    final price = (patientData['price'] ?? 0) as num;
    final remain = price - totalPaid;
    
    return Container(
      key: key,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Финансовые показатели
          Row(
            children: [
              _buildFinanceMetricCard(
                '💵 Стоимость лечения',
                '${priceFormatter.format(price)} ₽',
                DesignTokens.accentPrimary,
                'Общая стоимость',
              ),
              const SizedBox(width: 16),
              _buildFinanceMetricCard(
                '✅ Оплачено',
                '${priceFormatter.format(totalPaid)} ₽',
                DesignTokens.accentSuccess,
                '${payments.length} платежей',
              ),
              const SizedBox(width: 16),
              _buildFinanceMetricCard(
                '⏳ Остаток',
                '${priceFormatter.format(remain)} ₽',
                remain > 0 ? DesignTokens.accentWarning : DesignTokens.accentSuccess,
                remain > 0 ? 'К оплате' : 'Оплачено полностью',
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // История платежей
          Expanded(
            child: NeoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('📜', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Text('История платежей', style: DesignTokens.h3),
                        ],
                      ),
                      Text(
                        'Всего: ${payments.length}',
                        style: DesignTokens.body.copyWith(
                          color: DesignTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _buildPaymentsList(payments),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// РАЗДЕЛ: Статистика
  Widget _buildStatisticsSection(Key key, Map<String, dynamic> patientData) {
    return Container(
      key: key,
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
                      _buildTreatmentProgress(patientData),
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

  /// РАЗДЕЛ: Документы
  Widget _buildDocumentsSection(Key key, Map<String, dynamic> patientData) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Основное фото
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Главное фото пациента
              NeoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('👤', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Text('Фото пациента', style: DesignTokens.h3),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildMainPhoto(patientData['photoUrl']),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Дополнительные фото
              Expanded(
                child: NeoCard(
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
                              Text('Дополнительные фото', style: DesignTokens.h3),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: _buildPhotosGrid(patientData),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// РАЗДЕЛ: Заметки
  Widget _buildNotesSection(Key key, Map<String, dynamic> patientData) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(20),
      child: NeoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📝', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text('Заметки о пациенте', style: DesignTokens.h3),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: NotesWidget(patientId: widget.patientId),
            ),
          ],
        ),
      ),
    );
  }

  // === ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ ДЛЯ РАЗДЕЛОВ ===

  /// Карточка для раздела Обзор
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
              _updatePatientField('waitingList', value);
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
              _updatePatientField('secondStage', value);
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
              _updatePatientField('hotPatient', value);
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
              color: DesignTokens.textSecondary,
            ),
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

  /// Контент быстрых заметок
  Widget _buildQuickNotesContent(Map<String, dynamic> patientData) {
    return FutureBuilder<String>(
      future: _getPatientNotes(),
      builder: (context, snapshot) {
        final notes = snapshot.data ?? '';
        final hasNotes = notes.trim().isNotEmpty;
        
        return InkWell(
          onTap: () => _changeSection(5), // Переход к разделу заметок
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
        );
      },
    );
  }

  /// Карточка финансовой метрики
  Widget _buildFinanceMetricCard(String title, String value, Color color, String subtitle) {
    final parts = title.split(' ');
    final emoji = parts[0];
    final text = parts.sublist(1).join(' ');
    
    return Expanded(
      child: NeoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(text, style: DesignTokens.h4),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: DesignTokens.h2.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: DesignTokens.small.copyWith(
                color: DesignTokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Список платежей
  Widget _buildPaymentsList(List<Payment> payments) {
    if (payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.payment_outlined,
              size: 64,
              color: DesignTokens.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет платежей',
              style: DesignTokens.body.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[payments.length - 1 - index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: NeoCard.inset(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: DesignTokens.accentSuccess.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: DesignTokens.body.copyWith(
                          color: DesignTokens.accentSuccess,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${priceFormatter.format(payment.amount)} ₽',
                          style: DesignTokens.h4.copyWith(
                            color: DesignTokens.accentSuccess,
                          ),
                        ),
                        Text(
                          DateFormat('dd.MM.yyyy в HH:mm').format(payment.date),
                          style: DesignTokens.small.copyWith(
                            color: DesignTokens.textSecondary,
                          ),
                        ),
                      ],
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

  /// График прогресса лечения
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

  /// Главное фото пациента
  Widget _buildMainPhoto(String? photoUrl) {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignTokens.shadowDark.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: photoUrl != null
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: DesignTokens.background,
                    child: const Center(
                      child: Text('👤', style: TextStyle(fontSize: 64)),
                    ),
                  );
                },
              )
            : Container(
                color: DesignTokens.background,
                child: const Center(
                  child: Text('👤', style: TextStyle(fontSize: 64)),
                ),
              ),
      ),
    );
  }

  // === Остальные методы остаются без изменений ===
  
  Widget _buildPhotosGrid(Map<String, dynamic> patientData) {
    final List<dynamic> additionalPhotos = patientData['additionalPhotos'] ?? [];

    if (additionalPhotos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: DesignTokens.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет дополнительных фотографий',
              style: DesignTokens.body.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
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

  /// Фильтры для истории лечения
  Widget _buildTreatmentFilters() {
    return Container(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('Все', true),
          const SizedBox(width: 8),
          _buildFilterChip('🦷 Кариес', false),
          const SizedBox(width: 8),
          _buildFilterChip('🔩 Имплантация', false),
          const SizedBox(width: 8),
          _buildFilterChip('🗑️ Удаление', false),
          const SizedBox(width: 8),
          _buildFilterChip('📷 Сканирование', false),
          const SizedBox(width: 8),
          _buildFilterChip('🔬 Эндо', false),
          const SizedBox(width: 8),
          _buildFilterChip('👑 Коронка', false),
        ],
      ),
    );
  }
  
  /// Один фильтр
  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? DesignTokens.accentPrimary : DesignTokens.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isSelected 
            ? [
                BoxShadow(
                  color: DesignTokens.accentPrimary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : DesignTokens.outerShadows(blur: 6, offset: 3),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : DesignTokens.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
  
  /// ВАРИАНТ 1: Timeline с вертикальной линией (как на скриншоте)
  Widget _buildTimelineTreatments(String patientId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('treatments')
          .where('patientId', isEqualTo: patientId)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Ошибка загрузки: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  size: 64,
                  color: DesignTokens.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  'Нет данных о лечении',
                  style: DesignTokens.body.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          );
        }

        var treatments = _groupTreatmentsByDate(snapshot.data!.docs);
        
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: treatments.keys.length,
          itemBuilder: (context, index) {
            DateTime date = treatments.keys.elementAt(index);
            var treatmentInfos = treatments[date]!;
            final isExpanded = index == 0; // Первый элемент раскрыт
            
            return _buildTimelineItem(
              date: date,
              treatments: treatmentInfos,
              isFirst: index == 0,
              isLast: index == treatments.keys.length - 1,
              isExpanded: isExpanded,
            );
          },
        );
      },
    );
  }
  
  /// Элемент timeline
  Widget _buildTimelineItem({
    required DateTime date,
    required List<TreatmentInfo> treatments,
    required bool isFirst,
    required bool isLast,
    required bool isExpanded,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Левая часть с линией и точкой
          Container(
            width: 60,
            child: Column(
              children: [
                // Линия сверху
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 20,
                    color: DesignTokens.accentPrimary.withOpacity(0.3),
                  ),
                
                // Точка
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isFirst ? DesignTokens.accentPrimary : DesignTokens.surface,
                    border: Border.all(
                      color: DesignTokens.accentPrimary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [
                      BoxShadow(
                        color: DesignTokens.accentPrimary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                
                // Линия снизу
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: DesignTokens.accentPrimary.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          ),
          
          // Контент
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 20),
              child: _buildTimelineCard(
                date: date,
                treatments: treatments,
                isExpanded: isExpanded,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Карточка в timeline
  Widget _buildTimelineCard({
    required DateTime date,
    required List<TreatmentInfo> treatments,
    required bool isExpanded,
  }) {
    return NeoCard(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignTokens.accentPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.calendar_today,
              size: 20,
              color: DesignTokens.accentPrimary,
            ),
          ),
          title: Text(
            DateFormat('dd MMMM yyyy', 'ru').format(date),
            style: DesignTokens.h4,
          ),
          subtitle: Text(
            '${treatments.length} процедур',
            style: DesignTokens.small.copyWith(
              color: DesignTokens.textSecondary,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Кнопка редактирования
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: DesignTokens.textSecondary,
                ),
                onPressed: () {
                  // TODO: Редактирование лечения
                },
              ),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: DesignTokens.textSecondary,
              ),
            ],
          ),
          children: treatments.map((treatment) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DesignTokens.background.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getColor(treatment.treatmentType).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getColor(treatment.treatmentType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
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
                          style: DesignTokens.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Зубы: ${treatment.toothNumbers.join(", ")}',
                          style: DesignTokens.small.copyWith(
                            color: DesignTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /* ВАРИАНТ 2: Карточки с цветовыми акцентами
  Widget _buildCardTreatments(String patientId) {
    // Каждая процедура - отдельная карточка с цветовым акцентом
    // С мини-схемой зубов справа
    // Можно быстро редактировать/удалять
  }
  
  ВАРИАНТ 3: Табличный вид с сортировкой
  Widget _buildTableTreatments(String patientId) {
    // Таблица с колонками: Дата | Процедура | Зубы | Стоимость | Действия
    // Можно сортировать по любой колонке
    // Компактный вид для большого объема данных
  } */
  
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
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  size: 64,
                  color: DesignTokens.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  'Нет данных о лечении',
                  style: DesignTokens.body.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          );
        }

        var treatments = _groupTreatmentsByDate(treatmentSnapshot.data!.docs);

        return ListView.builder(
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

  // === ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ===

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

  void _handleTreatmentFinishedToggle(bool value) async {
    if (value) {
      setState(() {
        _waitingList = false;
        _secondStage = false;
        _hotPatient = false;
      });
      
      await _updatePatientField('treatmentFinished', true);
      await _updatePatientField('waitingList', false);
      await _updatePatientField('secondStage', false);
      await _updatePatientField('hotPatient', false);
    } else {
      await _updatePatientField('treatmentFinished', false);
    }
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

  void _showAddPaymentDialog(BuildContext context, Map<String, dynamic> patientData) {
    // Здесь можно добавить диалог для добавления платежа
    // TODO: Реализовать диалог добавления платежа
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

// Вспомогательные классы

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

class NavigationSection {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String emoji;

  NavigationSection({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.emoji,
  });
}
