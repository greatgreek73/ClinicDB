import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'add_patient_screen.dart';
import 'search_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'reports_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'specific_patients_screen.dart';
import 'theme/app_theme.dart';
import 'screens/new_dashboard_screen.dart';
import 'package:go_router/go_router.dart';
import 'routing/app_router.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.i('WidgetsFlutterBinding initialized');

  if (!kIsWeb) {
    // Включаем полноэкранный режим (скрываем строку состояния и навигационную панель)
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,  // Полностью иммерсивный режим
    );
    
    // Устанавливаем цвет и прозрачность навигационной панели на случай, если она появится по свайпу
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ));
  }
  Logger.i('SystemChrome set');

  try {
    // Проверяем платформу перед инициализацией Firebase
    if (kIsWeb || (defaultTargetPlatform == TargetPlatform.android)) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      Logger.i('Firebase initialized');
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      Logger.w('Firebase not configured for Windows. Running without Firebase.');
      // Для Windows пока пропускаем инициализацию Firebase
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      Logger.i('Firebase initialized');
    }
  } catch (e, st) {
    Logger.e('Error initializing Firebase', e, st);
    Logger.w('Continuing without Firebase...');
  }

  runApp(const ProviderScope(child: ClinicDBApp()));
  Logger.i('ClinicDBApp started');
}

class ClinicDBApp extends StatelessWidget {
  const ClinicDBApp({super.key});

  @override
  Widget build(BuildContext context) {
    Logger.d('Building ClinicDBApp');
    return MaterialApp.router(
      title: 'clinicdb',
      theme: AppTheme.themeData,
      debugShowCheckedModeBanner: false, // Скрыть баннер debug режима
      routerConfig: appRouter,
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  int specificPatientsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSpecificPatientsCount();
  }

  Future<void> _loadSpecificPatientsCount() async {
    int count = await countSpecificPatients();
    setState(() {
      specificPatientsCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    Logger.d('Building LoginPage');
    double buttonWidth = 350;
    double buttonHeight = 60;
    double buttonFontSize = 18;

    return Scaffold(
      appBar: AppBar(title: Text('Клиника - Панель управления')),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20),
        color: Colors.white,
        child: Column(
          children: [
            ImplantationSummaryWidget(),
            CrownAndAbutmentSummaryWidget(),
            Expanded(
              child: Center(
                child: Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    _buildButton(context, 'Добавить Пациента', () {
                      context.push('/add');
                    }, buttonWidth, buttonHeight, buttonFontSize),
                    _buildButton(context, 'Поиск', () {
                      context.push('/search');
                    }, buttonWidth, buttonHeight, buttonFontSize),
                    _buildButton(context, 'Отчеты', () {
                      context.push('/reports');
                    }, buttonWidth, buttonHeight, buttonFontSize),
                    _buildButton(context, 'Специфические пациенты ($specificPatientsCount)', () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SpecificPatientsScreen()));
                    }, buttonWidth, buttonHeight, buttonFontSize),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String title, VoidCallback onPressed, double width, double height, double fontSize) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF0F5BF1),
        foregroundColor: Colors.white,
        shadowColor: Color(0x40000000),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fixedSize: Size(width, height),
      ),
      onPressed: onPressed,
      child: Text(title, style: TextStyle(fontSize: fontSize)),
    );
  }
}

Future<int> countSpecificPatients() async {
  QuerySnapshot patientsSnapshot = await FirebaseFirestore.instance
      .collection('patients')
      .where('price', isGreaterThanOrEqualTo: 300000)
      .where('price', isLessThanOrEqualTo: 400000)
      .get();

  int count = 0;
  for (var patientDoc in patientsSnapshot.docs) {
    QuerySnapshot treatmentsSnapshot = await FirebaseFirestore.instance
        .collection('treatments')
        .where('patientId', isEqualTo: patientDoc.id)
        .where('date', isGreaterThanOrEqualTo: DateTime(2024, 7, 1))
        .where('date', isLessThan: DateTime(2024, 8, 1))
        .get();

    if (treatmentsSnapshot.docs.isNotEmpty) {
      count++;
    }
  }

  return count;
}

class ImplantationSummaryWidget extends StatefulWidget {
  @override
  _ImplantationSummaryWidgetState createState() => _ImplantationSummaryWidgetState();
}

class _ImplantationSummaryWidgetState extends State<ImplantationSummaryWidget> {
  DateTime get firstDateOfMonth => DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime get lastDateOfMonth => DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);
  DateTime get firstDateOfYear => DateTime(DateTime.now().year, 1, 1);
  DateTime get lastDateOfYear => DateTime(DateTime.now().year, 12, 31, 23, 59, 59);

  int totalTeethCountMonth = 0;
  int totalTeethCountYear = 0;

  @override
  void initState() {
    super.initState();
    calculateStatistics();
  }

  void calculateStatistics() {
    FirebaseFirestore.instance
        .collection('treatments')
        .where('treatmentType', isEqualTo: 'Имплантация')
        .where('date', isGreaterThanOrEqualTo: firstDateOfMonth)
        .where('date', isLessThanOrEqualTo: lastDateOfMonth)
        .get()
        .then((snapshot) {
          setState(() {
            totalTeethCountMonth = snapshot.docs.fold<int>(0, (int sum, doc) {
              var toothNumbers = List.from(doc['toothNumber'] ?? []);
              return sum + toothNumbers.length;
            });
          });
        });

    FirebaseFirestore.instance
        .collection('treatments')
        .where('treatmentType', isEqualTo: 'Имплантация')
        .where('date', isGreaterThanOrEqualTo: firstDateOfYear)
        .where('date', isLessThanOrEqualTo: lastDateOfYear)
        .get()
        .then((snapshot) {
          setState(() {
            totalTeethCountYear = snapshot.docs.fold<int>(0, (int sum, doc) {
              var toothNumbers = List.from(doc['toothNumber'] ?? []);
              return sum + toothNumbers.length;
            });
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Количество зубов за текущий месяц: $totalTeethCountMonth',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 10),
          Text(
            'Количество зубов за текущий год: $totalTeethCountYear',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class CrownAndAbutmentSummaryWidget extends StatefulWidget {
  @override
  _CrownAndAbutmentSummaryWidgetState createState() => _CrownAndAbutmentSummaryWidgetState();
}

class _CrownAndAbutmentSummaryWidgetState extends State<CrownAndAbutmentSummaryWidget> {
  DateTime get firstDateOfMonth => DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime get lastDateOfMonth => DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);
  DateTime get firstDateOfYear => DateTime(DateTime.now().year, 1, 1);
  DateTime get lastDateOfYear => DateTime(DateTime.now().year, 12, 31, 23, 59, 59);

  int totalTeethCountMonth = 0;
  int totalTeethCountYear = 0;

  @override
  void initState() {
    super.initState();
    calculateStatistics();
  }

  void calculateStatistics() {
    FirebaseFirestore.instance
        .collection('treatments')
        .where('treatmentType', whereIn: ['Коронка', 'Абатмент'])
        .where('date', isGreaterThanOrEqualTo: firstDateOfMonth)
        .where('date', isLessThanOrEqualTo: lastDateOfMonth)
        .get()
        .then((snapshot) {
          setState(() {
            totalTeethCountMonth = snapshot.docs.fold<int>(0, (int sum, doc) {
              var toothNumbers = List.from(doc['toothNumber'] ?? []);
              return sum + toothNumbers.length;
            });
          });
        });

    FirebaseFirestore.instance
        .collection('treatments')
        .where('treatmentType', whereIn: ['Коронка', 'Абатмент'])
        .where('date', isGreaterThanOrEqualTo: firstDateOfYear)
        .where('date', isLessThanOrEqualTo: lastDateOfYear)
        .get()
        .then((snapshot) {
          setState(() {
            totalTeethCountYear = snapshot.docs.fold<int>(0, (int sum, doc) {
              var toothNumbers = List.from(doc['toothNumber'] ?? []);
              return sum + toothNumbers.length;
            });
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Количество зубов (Коронка и Абатмент) за текущий месяц: $totalTeethCountMonth',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 10),
          Text(
            'Количество зубов (Коронка и Абатмент) за текущий год: $totalTeethCountYear',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
