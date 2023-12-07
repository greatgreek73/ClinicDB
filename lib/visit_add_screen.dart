import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'visit_model.dart'; // Импорт модели визита (предполагается, что она уже создана)
import 'visit_service.dart'; // Импорт сервиса для работы с визитами

class VisitAddScreen extends StatefulWidget {
  final String patientId;

  VisitAddScreen({required this.patientId});

  @override
  _VisitAddScreenState createState() => _VisitAddScreenState();
}

class _VisitAddScreenState extends State<VisitAddScreen> {
  final _formKey = GlobalKey<FormState>();
  String treatmentDetails = '';

  void _saveVisit() async {
    if (_formKey.currentState!.validate()) {
      // Создание объекта визита
      Visit visit = Visit(
        patientId: widget.patientId,
        treatmentDetails: treatmentDetails,
        date: DateTime.now(), // Пример использования текущей даты
      );

      // Сохранение информации о визите в Firestore через сервис
      await VisitService.addVisit(visit);
      Navigator.of(context).pop(); // Возвращение на предыдущий экран после сохранения
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить Визит'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Детали Лечения'),
                onChanged: (value) => treatmentDetails = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите детали лечения';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveVisit,
                child: Text('Сохранить Визит'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
