import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/action_button.dart';
import '../add_patient_screen.dart';
import '../search_screen.dart';

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
          child: Row(
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
                          
                          // Правая колонка (теперь с фиксированной шириной как у левой)
                          Container(
                            width: 300, // Такая же ширина, как у левой панели, увеличенная на 50%
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
          ),
        ),
      ),
    );
  }

  // Узкая левая панель меню
  Widget _buildSidebarPanel(BuildContext context) {
    return Container(
      width: 300, // Узкая панель для меню, увеличенная на 50%
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
  Widget _buildMainTopPanel(BuildContext context) {
    return Container(
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
  
  // Нижняя основная панель
  Widget _buildMainBottomPanel(BuildContext context) {
    return Container(
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
  
  // Верхняя правая панель
  Widget _buildRightTopPanel(BuildContext context) {
    return Container(
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
  
  // Нижняя правая панель
  Widget _buildRightBottomPanel(BuildContext context) {
    return Container(
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
