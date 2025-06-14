import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import '../theme/app_theme.dart';
import '../widgets/action_button.dart';
import '../add_patient_screen.dart';
import '../search_screen.dart';
import 'filtered_patients_screen.dart';
import '../widgets/creature_widget.dart';

class NewDashboardScreen extends StatefulWidget {
  const NewDashboardScreen({Key? key}) : super(key: key);

  @override
  _NewDashboardScreenState createState() => _NewDashboardScreenState();
}

class _NewDashboardScreenState extends State<NewDashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Инициализируем анимации
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    // Запускаем анимацию
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Color(0xFF202020), // Темно-серый фон
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          // Всегда используем только ландшафтный макет
          child: _buildLandscapeLayout(context),
        ),
      ),
    );
  }

  // Ландшафтный макет (похож на текущий)
  Widget _buildLandscapeLayout(BuildContext context) {
    return Row(
      children: [
        // Левая узкая панель меню
        AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.translate(
                offset: Offset(-30 * (1 - _fadeAnimation.value), 0),
                child: child,
              ),
            );
          },
          child: _buildSidebarPanel(context),
        ),

        SizedBox(width: 16),

        // Центральная и правая части
        Expanded(
          child: Column(
            children: [
              // Верхняя панель с поиском
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, -30 * (1 - _fadeAnimation.value)),
                      child: child,
                    ),
                  );
                },
                child: _buildHeaderPanel(context),
              ),

              SizedBox(height: 16),

              // Основная часть (центр + правая колонка)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Центральная колонка (теперь занимает всё доступное пространство)
                    Expanded(
                      child: Column(
                        children: [
                          // Верхняя основная панель
                          Expanded(
                            flex: 2,
                            child: AnimatedBuilder(
                              animation: _fadeAnimation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _fadeAnimation.value,
                                  child: Transform.translate(
                                    offset: Offset(0, 30 * (1 - _fadeAnimation.value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildMainTopPanel(context),
                            ),
                          ),

                          SizedBox(height: 16),

                          // Нижняя основная панель
                          Expanded(
                            flex: 1,
                            child: AnimatedBuilder(
                              animation: _fadeAnimation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _fadeAnimation.value,
                                  child: Transform.translate(
                                    offset: Offset(0, 40 * (1 - _fadeAnimation.value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildMainBottomPanel(context),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 16),

                    // Правая колонка
                    Container(
                      width: 300,
                      child: Column(
                        children: [
                          // Верхняя правая панель
                          Expanded(
                            flex: 1,
                            child: AnimatedBuilder(
                              animation: _fadeAnimation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _fadeAnimation.value,
                                  child: Transform.translate(
                                    offset: Offset(30 * (1 - _fadeAnimation.value), 0),
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildRightTopPanel(context),
                            ),
                          ),

                          SizedBox(height: 16),

                          // Нижняя правая панель
                          Expanded(
                            flex: 2,
                            child: AnimatedBuilder(
                              animation: _fadeAnimation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _fadeAnimation.value,
                                  child: Transform.translate(
                                    offset: Offset(40 * (1 - _fadeAnimation.value), 0),
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildRightBottomPanel(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Портретный макет с использованием табов для лучшей организации
  Widget _buildPortraitLayout(BuildContext context) {
    return Column(
      children: [
        // Верхняя навигационная панель
        _buildPortraitHeader(context),
        
        SizedBox(height: 16),
        
        // Компактные метрики
        _buildPortraitMetrics(context),
        
        SizedBox(height: 16),
        
        // Основная часть через табы
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                // Панель табов
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    indicatorColor: Color(0xFF3949AB),
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    tabs: [
                      Tab(text: 'Main', icon: Icon(Icons.dashboard)),
                      Tab(text: 'Reports', icon: Icon(Icons.bar_chart)),
                    ],
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Содержимое табов
                Expanded(
                  child: TabBarView(
                    children: [
                      // Первый таб - основные панели
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildMainTopPanel(context, isPortrait: true),
                            SizedBox(height: 16),
                            _buildMainBottomPanel(context, isPortrait: true),
                          ],
                        ),
                      ),
                      
                      // Второй таб - отчеты (правые панели)
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildRightTopPanel(context, isPortrait: true),
                            SizedBox(height: 16),
                            _buildRightBottomPanel(context, isPortrait: true),
                          ],
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
    );
  }

  // Специальная верхняя панель для портретного режима
  Widget _buildPortraitHeader(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, -20 * (1 - _fadeAnimation.value)),
            child: child,
          ),
        );
      },
      child: Container(
        height: 70,
        padding: EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(4, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Clinic Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                _buildPortraitActionButton('Add', Icons.person_add_alt, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AddPatientScreen()));
                }),
                SizedBox(width: 8),
                _buildPortraitActionButton('Search', Icons.search, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SearchScreen()));
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Компактные метрики для портретного режима
  Widget _buildPortraitMetrics(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(4, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.0,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '84',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'implants',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'This month',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Datetime
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('dd MMMM yyyy').format(DateTime.now()),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 10),
                Text(
                  DateFormat('EEEE').format(DateTime.now()),
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Компактные кнопки действий для портретного режима
  Widget _buildPortraitActionButton(String title, IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Color(0xFF3949AB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text(title, style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  // Узкая левая панель меню - ВЕРСИЯ С ПОЛНОЙ ВЫСОТОЙ И КОМПАКТНЫМ КОНТЕНТОМ
  Widget _buildSidebarPanel(BuildContext context) {
    final now = DateTime.now();
    final dateFormatter = DateFormat('dd MMMM yyyy'); // Format for date
    final dayFormatter = DateFormat('EEEE'); // Format for day name

    return Container(
      width: 300,
      padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(4, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Верхняя часть (метрика и кнопки) - будет центрирована
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min, // Сжимает колонку по контенту
                children: [
                  // Metric Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '84',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'implants',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'This month',
                          style: TextStyle(color: Colors.white60),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 32),

                  // Divider and Buttons Section
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Divider(color: Colors.white12, height: 1, thickness: 0.5),
                      ),
                      _buildActionButton('Add Patient', Icons.person_add_alt, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AddPatientScreen()));
                      }),
                      SizedBox(height: 16),
                      _buildActionButton('Search', Icons.search, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => SearchScreen()));
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Date Section - останется внизу
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                dateFormatter.format(now), // Use formatted date
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                dayFormatter.format(now), // Use formatted day name
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Верхняя панель с поиском
  Widget _buildHeaderPanel(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A), // Однотонный темно-серый
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(4, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.0,
        ),
      ),
      // Пустая панель без содержимого
      child: Container(),
    );
  }

  // Верхняя основная панель
  Widget _buildMainTopPanel(BuildContext context, {bool isPortrait = false}) {
    return Container(
      height: isPortrait ? 200 : null, // Фиксированная высота в портретном режиме
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A), // Однотонный темно-серый
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(4, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.0,
        ),
      ),
      // Отображаем динамическое "существо"
      child: const Center(
        child: CreatureWidget(),
      ),
    );
  }

  // Нижняя основная панель
  Widget _buildMainBottomPanel(BuildContext context, {bool isPortrait = false}) {
    return Container(
      height: isPortrait ? 150 : null, // Фиксированная высота в портретном режиме
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A), // Однотонный темно-серый
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(4, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.0,
        ),
      ),
      // Добавим текст, чтобы панель была не пустой
      child: Center(
        child: Text(
          'Main Panel (Bottom)',
          style: TextStyle(
            color: Colors.white70,
            fontSize: isPortrait ? 16 : 18,
          ),
        ),
      ),
    );
  }

  // Верхняя правая панель
Widget _buildRightTopPanel(BuildContext context, {bool isPortrait = false}) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('patients').snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return Container(
          height: isPortrait ? 150 : null,
          decoration: BoxDecoration(
            color: Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 0,
                offset: Offset(4, 4),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.0,
            ),
          ),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      int todayCount = 0;
      DateTime now = DateTime.now();
      List<Map<String, dynamic>> todayPayments = [];
      for (var doc in snapshot.data!.docs) {
        var data = doc.data() as Map<String, dynamic>;
        var payments = data['payments'] as List<dynamic>? ?? [];
        for (var payment in payments) {
          DateTime paymentDate;
          if (payment['date'] is Timestamp) {
            paymentDate = (payment['date'] as Timestamp).toDate();
          } else if (payment['date'] is DateTime) {
            paymentDate = payment['date'];
          } else {
            continue;
          }
          if (paymentDate.year == now.year &&
              paymentDate.month == now.month &&
              paymentDate.day == now.day) {
            todayCount++;
            todayPayments.add({
              'surname': data['surname'] ?? '',
              'name': data['name'] ?? '',
              'amount': payment['amount'] ?? payment['paid'] ?? 0,
              'time': paymentDate,
              'patientId': doc.id,
            });
            break; // Считаем пациента только один раз
          }
        }
      }
      return Container(
        height: isPortrait ? 150 : null,
        decoration: BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(4, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payments, color: Colors.green, size: 40),
            SizedBox(height: 12),
            Text(
              'Платежей сегодня:',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) {
                    return AlertDialog(
                      backgroundColor: Color(0xFF232323),
                      title: Text(
                        'Платежи за сегодня',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: Container(
                        width: 300,
                        height: 300,
                        child: todayPayments.isNotEmpty
                            ? ListView.builder(
                                itemCount: todayPayments.length,
                                itemBuilder: (context, idx) {
                                  final p = todayPayments[idx];
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      '${p['surname']} ${p['name']}',
                                      style: TextStyle(color: Colors.white, fontSize: 15),
                                    ),
                                    subtitle: Text(
                                      'Сумма: ${p['amount']} ₽, Время: ${DateFormat('HH:mm').format(p['time'])}',
                                      style: TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                    onTap: () {
                                      // Здесь можно реализовать переход к деталям пациента, если нужно
                                    },
                                  );
                                },
                              )
                            : Text(
                                'Нет платежей за сегодня',
                                style: TextStyle(color: Colors.white54),
                              ),
                      ),
                      actions: [
                        TextButton(
                          child: Text('Закрыть', style: TextStyle(color: Colors.white)),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text(
                '$todayCount',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

  // Нижняя правая панель - Счетчики пациентов в списке ожидания и на втором этапе
  Widget _buildRightBottomPanel(BuildContext context, {bool isPortrait = false}) {
    return Container(
      height: isPortrait ? 180 : null, // Фиксированная высота в портретном режиме
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A), // Однотонный темно-серый
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(4, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.0,
        ),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('patients').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка при загрузке данных', style: TextStyle(color: Colors.white)));
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Нет данных', style: TextStyle(color: Colors.white)));
          }
          
          // Подсчет пациентов по категориям
          int waitingListCount = 0;
          int secondStageCount = 0;
          int hotPatientCount = 0;
          
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            if (data['waitingList'] == true) {
              waitingListCount++;
            }
            if (data['secondStage'] == true) {
              secondStageCount++;
            }
            if (data['hotPatient'] == true) {
              hotPatientCount++;
            }
          }
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Статистика пациентов',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: Column(
                  children: [
                    // Верхний ряд с двумя карточками
                    Expanded(
                      child: Row(
                        children: [
                          // Блок "Список ожидания"
                          Expanded(
                            child: _buildPatientCategoryCard(
                              title: 'Список ожидания',
                              count: waitingListCount,
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
                          SizedBox(width: 16),
                          // Блок "Второй этап"
                          Expanded(
                            child: _buildPatientCategoryCard(
                              title: 'Второй этап',
                              count: secondStageCount,
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
                    ),
                    SizedBox(height: 16),
                    // Нижний ряд с карточкой "Горящие пациенты"
                    Expanded(
                      child: Row(
                        children: [
                          // Пустое пространство слева для центрирования
                          Expanded(flex: 1, child: SizedBox()),
                          // Блок "Горящие пациенты"
                          Expanded(
                            flex: 2,
                            child: _buildPatientCategoryCard(
                              title: 'Горящие пациенты',
                              count: hotPatientCount,
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
                          // Пустое пространство справа для центрирования
                          Expanded(flex: 1, child: SizedBox()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // Виджет карточки для отображения категории пациентов с количеством
  Widget _buildPatientCategoryCard({
    required String title,
    required int count,
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
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFF202020),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 36,
              ),
              SizedBox(height: 16),
              Text(
                count.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              if (onTap != null) ...[
                SizedBox(height: 12),
                Icon(
                  Icons.arrow_forward,
                  color: color.withOpacity(0.7),
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData? icon, String title, {bool active = false, bool highlight = false}) {
    final color = highlight
        ? Color(0xFFE0A939)
        : active
            ? Colors.white
            : Colors.white70;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 20),
            SizedBox(width: 12),
          ],
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onPressed) {
    // Кнопка с глубоким индиго градиентом и белым текстом
    return Container(
      width: double.infinity,
      height: 50, // фиксированная высота для стабильности
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12), // уменьшенный радиус для соответствия панелям
        // Глубокий индиго градиент
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5C6BC0), // Светлый индиго
            Color(0xFF3949AB), // Глубокий индиго (основной цвет)
            Color(0xFF303F9F), // Темный индиго
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          // Основная тень с индиго оттенком
          BoxShadow(
            color: Color(0xFF303F9F).withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 0,
            offset: Offset(2, 2),
          ),
          // Светлая тень сверху для объема
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: -1,
            offset: Offset(0, -1),
          ),
        ],
        // Единая тонкая граница для совместимости с borderRadius
        border: Border.all(
          color: Color(0xFF7986CB).withOpacity(0.7),
          width: 1,
        ),
      ),
      // Деликатный эффект блика сверху
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [
            Colors.white.withOpacity(0.4),
            Colors.white.withOpacity(0.2),
            Colors.transparent,
          ],
          stops: [0.0, 0.3, 0.6],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12), // Значение соответствует контейнеру
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white, // Белый цвет для иконки
                  size: 20,
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white, // Белый цвет для текста
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Класс для рисования декоративных кривых линий
class DecorativeCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.2);
    path1.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.1,
      size.width,
      size.height * 0.3
    );

    final path2 = Path();
    path2.moveTo(0, size.height * 0.5);
    path2.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.3,
      size.width,
      size.height * 0.6
    );

    final path3 = Path();
    path3.moveTo(0, size.height * 0.8);
    path3.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.9,
      size.width,
      size.height * 0.7
    );

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
