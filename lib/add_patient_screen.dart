import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddPatientScreen extends StatefulWidget {
  @override
  _AddPatientScreenState createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  void _addPatientToFirestore() {
    // Считываем значения из контроллеров и конвертируем их в нужные типы данных
    final String surname = _surnameController.text;
    final int age = int.parse(_ageController.text);
    final double price = double.parse(_priceController.text);

    // Отправляем собранные данные в коллекцию 'patients' Firestore
    FirebaseFirestore.instance.collection('patients').add({
      'surname': surname,
      'age': age,
      'price': price,
    }).then((result) {
      // Выводим в консоль сообщение об успешном добавлении и закрываем экран
      print('Пациент добавлен');
      Navigator.of(context).pop();
    }).catchError((error) {
      // Выводим сообщение об ошибке, если что-то пошло не так
      print('Ошибка добавления пациента: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить Пациента'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _surnameController,
                decoration: InputDecoration(labelText: 'Фамилия'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите фамилию';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(labelText: 'Возраст'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите возраст';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Цена'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите цену';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Проверяем, валидны ли данные формы
                  if (_formKey.currentState!.validate()) {
                    _addPatientToFirestore(); // Вызываем функцию для сохранения данных
                  }
                },
                child: Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
