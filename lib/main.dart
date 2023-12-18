import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'add_patient_screen.dart';
import 'search_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    return ScreenUtilInit(
      designSize: Size(360, 690),
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          title: 'clinicdb',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: AppBarTheme(color: Colors.white),
          ),
          home: LoginPage(),
        );
      },
    );
  }
}

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: Size(360, 690));
    var orientation = MediaQuery.of(context).orientation;

    double buttonWidth = orientation == Orientation.portrait ? 280.w : 480.w;
    double buttonHeight = orientation == Orientation.portrait ? 52.h : 72.h;
    double buttonFontSize = orientation == Orientation.portrait ? 16.sp : 20.sp;

    return Scaffold(
      body: Container(
        color: Color(0xFF000000),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildButton(context, 'Добавить Пациента', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AddPatientScreen()));
              }, buttonWidth, buttonHeight, buttonFontSize),
              SizedBox(height: 20.h),
              _buildButton(context, 'Поиск', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen()));
              }, buttonWidth, buttonHeight, buttonFontSize),
              SizedBox(height: 20.h),
              _buildButton(context, 'Отчеты', () {}, buttonWidth, buttonHeight, buttonFontSize),
              SizedBox(height: 20.h),
              _buildButton(context, 'Статистика', () {}, buttonWidth, buttonHeight, buttonFontSize),
              SizedBox(height: 20.h),
              _buildButton(context, 'Напоминания', () {}, buttonWidth, buttonHeight, buttonFontSize),
            ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
        fixedSize: Size(width, height),
      ),
      onPressed: onPressed,
      child: Text(title, style: TextStyle(fontSize: fontSize)),
    );
  }
}
