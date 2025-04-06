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
        child: Stack(
          children: [
            // Декоративный фон с градиентом
            Positioned.fill(
              child: Stack(
                children: [
                  // Основной градиент
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1A2151),  // Темно-синий
                          Color(0xFF0F5BF1),  // Основной синий
                        ],
                      ),
                    ),
                  ),
                  // Декоративные элементы
                  Positioned(
                    right: -100,
                    top: -100,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0x40FFFFFF),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: size.width * 0.5,
                    bottom: -120,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0x30FFFFFF),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Декоративные линии
                  Positioned(
                    top: size.height * 0.3,
                    right: 0,
                    child: CustomPaint(
                      size: Size(size.width * 0.6, size.height * 0.7),
                      painter: DecorativeCurvePainter(),
                    ),
                  ),
                ],
              ),
            ),
            
            // Левая информационная панель - без 3D эффектов для надежности
            Positioned(
              left: 30,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(-80 * (1 - _fadeAnimation.value), 0),
                        child: child,
                      ),
                    );
                  },
                  child: _buildLeftPanel(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel(BuildContext context) {
    return Container(
      width: 375, // Увеличиваем ширину на 50%
      height: 715, // Увеличиваем высоту на 30%
      // Внешний слой с 3D тенями для эффекта поднятия
      child: Stack(
        children: [
          // Дополнительная тень для эффекта глубины
          Container(
            margin: EdgeInsets.only(right: 12, bottom: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: -5,
                  offset: Offset(15, 15),
                ),
              ],
            ),
          ),
          
            // Упрощенная панель с более контрастными элементами
          Container(
            decoration: BoxDecoration(
              // Более простой градиент
              color: Color(0xFF2A2A2A), // Однотонный темно-серый
              borderRadius: BorderRadius.circular(30),
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
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center, // Центрирование всех элементов
                children: [
                  // Верхний разделитель (декоративная линия)
                  Container(
                    height: 1,
                    width: 60,
                    margin: EdgeInsets.only(bottom: 40),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  
                  // Статистика с ореолом
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Color(0xFFE0E0E0)],
                    ).createShader(bounds),
                    child: Text(
                      '84',
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 0.9,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 5,
                            color: Colors.black.withOpacity(0.5),
                          ),
                          Shadow(
                            offset: Offset(0, -1),
                            blurRadius: 3,
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  Text(
                    'implants',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 5),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: Text(
                      'This month',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                  
                  // Разделитель между статистикой и кнопками
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 40),
                    width: 200,
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.4),
                          Colors.white.withOpacity(0.2),
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.2, 0.5, 0.8, 1.0],
                      ),
                    ),
                  ),
                  
                  // Кнопки
                  Container(
                    width: 280,
                    child: _buildActionButton(
                      "Add Patient",
                      Icons.person_add,
                      () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AddPatientScreen()));
                      },
                    ),
                  ),
                  SizedBox(height: 18),
                  Container(
                    width: 280,
                    child: _buildActionButton(
                      "Search",
                      Icons.search,
                      () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen()));
                      },
                    ),
                  ),
                  
                  Spacer(),
                  
                  // Дата внизу панели с более стильным оформлением
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '06 April 2025',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Sunday',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.5),
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onPressed) {
    // Простая кнопка без сложных эффектов
    return Container(
      width: double.infinity,
      height: 50, // фиксированная высота для стабильности
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        // Яркий синий цвет без градиента
        color: Color(0xFF1E88E5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            spreadRadius: 0,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
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
