import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../add_patient_screen.dart';
import '../search_screen.dart';
import '../theme/app_theme.dart';
import 'package:go_router/go_router.dart';
// Riverpod-представление (данные приходят из контроллера)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/dashboard/widgets/patient_counts_widget.dart';
import '../../../presentation/dashboard/widgets/treatment_stats_widget.dart';
// Неоморфные компоненты дизайн‑системы
import '../design_system/design_system_screen.dart' show NeoCard, NeoButton, NeoTabBar, DesignTokens;

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
    // Новый фон под неоморфизм
    return Scaffold(
      backgroundColor: DesignTokens.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: _buildNeoLayout(context),
        ),
      ),
    );
  }

  // Новый неоморфный макет дашборда
  Widget _buildNeoLayout(BuildContext context) {
    return Row(
      children: [
        // Левая колонка: метрики, быстрые действия
        Expanded(
          flex: 1,
          child: Column(
            children: [
              // Приветствие/шапка
              AnimatedBuilder(
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
                child: NeoCard(
                  child: Row(
                    children: [
                      // Аватар
                      const Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white,
                          child: Text('👨‍⚕️', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Добрый день, доктор!', style: DesignTokens.h3),
                            SizedBox(height: 4),
                            Text('Ваше рабочее пространство', style: DesignTokens.small),
                          ],
                        ),
                      ),
                      NeoButton(
                        label: 'Добавить',
                        onPressed: () => context.push('/add'),
                        primary: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Статистика процедур (верхняя основная панель)
              Expanded(
                flex: 2,
                child: AnimatedBuilder(
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
                  child: NeoCard(
                    child: _buildMainTopPanel(context),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Быстрые действия 2x2
              AnimatedBuilder(
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
                child: NeoCard(
                  child: GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 3.2,
                    ),
                    children: [
                      NeoButton(label: 'Запись', onPressed: () {}),
                      NeoButton(label: 'Поиск', onPressed: () => context.push('/search')),
                      NeoButton(label: 'Пациенты', onPressed: () => context.push('/search')),
                      NeoButton(label: 'Отчёты', onPressed: () => context.push('/reports')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Правая колонка: мини‑панели и счётчики
        SizedBox(
          width: 320,
          child: Column(
            children: [
              // Верхняя правая панель (заглушка в неоморфном контейнере)
              Expanded(
                flex: 1,
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(20 * (1 - _fadeAnimation.value), 0),
                        child: child,
                      ),
                    );
                  },
                  child: NeoCard(
                    child: _buildRightTopPanel(context),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Нижняя правая панель: счётчики пациентов (на Riverpod)
              Expanded(
                flex: 2,
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
                  child: const NeoCard(
                    child: PatientCountsWidget(),
                  ),
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

  // Верхняя панель (неоморфная пустая полоса под будущий поиск/фильтры)
  Widget _buildHeaderPanel(BuildContext context) {
    return const NeoCard(
      child: SizedBox(height: 60),
    );
  }

  // Верхняя основная панель (теперь отображает статистику по процедурам)
  Widget _buildMainTopPanel(BuildContext context, {bool isPortrait = false}) {
    return TreatmentStatsWidget(isPortrait: isPortrait);
  }

  // Нижняя основная панель (пока как заглушка, но в неоморфном контейнере)
  Widget _buildMainBottomPanel(BuildContext context, {bool isPortrait = false}) {
    return const NeoCard(
      child: SizedBox(
        height: 150,
        child: Center(
          child: Text('Main Panel (Bottom)', style: DesignTokens.h4),
        ),
      ),
    );
  }

  // Верхняя правая панель (заглушка)
  Widget _buildRightTopPanel(BuildContext context, {bool isPortrait = false}) {
    return const SizedBox(
      height: 150,
      child: Center(
        child: Text('Right Panel (Top)', style: DesignTokens.h4),
      ),
    );
  }

  // Нижняя правая панель — теперь на Riverpod-данных (обернётся NeoCard выше)
  Widget _buildRightBottomPanel(BuildContext context, {bool isPortrait = false}) {
    return const PatientCountsWidget();
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
