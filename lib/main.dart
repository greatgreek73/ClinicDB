import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Убедитесь, что файл сгенерирован FlutterFire CLI
import 'add_patient_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Обязательно для инициализации Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Использует настройки из файла firebase_options.dart
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
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('clinicdb - Вход'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddPatientScreen()),
            );
          },
          child: Text('Добавить Пациента'),
        ),
      ),
    );
  }
}
