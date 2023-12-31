import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'add_patient_screen.dart';
import 'search_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'reports_screen.dart';

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
    // Задаем фиксированные размеры для кнопок
    double buttonWidth = 350;
    double buttonHeight = 60;
    double buttonFontSize = 18;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20),
        color: Colors.white,
        child: Center(
          child: Container(
            width: 870,
            height: 300,
            decoration: ShapeDecoration(
              color: Color(0xFFF1F1F1),
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 1, color: Color(0xFF514646)),
                borderRadius: BorderRadius.circular(20),
              
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _buildButton(context, 'Добавить Пациента', () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AddPatientScreen()));
                    }, buttonWidth, buttonHeight, buttonFontSize),
                    SizedBox(width: 40), // Отступ между кнопками
                    _buildButton(context, 'Поиск', () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen()));
                    }, buttonWidth, buttonHeight, buttonFontSize),
                  ],
                ),
                SizedBox(height: 20), // Отступ между рядами
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _buildButton(context, 'Отчеты', () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ReportsScreen()));
                    }, buttonWidth, buttonHeight, buttonFontSize),
                    SizedBox(width: 40), // Отступ между кнопками
                    _buildButton(context, 'Расписание', () {}, buttonWidth, buttonHeight, buttonFontSize),
                  ],
                ),
              ],
            ),
          ),
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
