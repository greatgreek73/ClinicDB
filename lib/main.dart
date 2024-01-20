import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'add_patient_screen.dart';
import 'search_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'reports_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ClinicDBApp());
}

class ClinicDBApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'clinicdb',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(color: Colors.white),
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AddPatientScreen()));
                    }, buttonWidth, buttonHeight, buttonFontSize),
                    _buildButton(context, 'Поиск', () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen()));
                    }, buttonWidth, buttonHeight, buttonFontSize),
                    _buildButton(context, 'Отчеты', () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ReportsScreen()));
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
        primary: Color(0xFF0F5BF1),
        onPrimary: Colors.white,
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
