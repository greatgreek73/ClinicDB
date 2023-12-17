import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'patient_details_screen.dart';

class AddPatientScreen extends StatefulWidget {
  @override
  _AddPatientScreenState createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isMale = true; // Добавлена переменная для отслеживания выбора пола

  void _addPatientToFirestore() {
    final String surname = _surnameController.text;
    final int age = int.parse(_ageController.text);
    final double price = double.parse(_priceController.text);
    final String name = _nameController.text;
    final String city = _cityController.text;
    final String phone = _phoneController.text;
    final String gender = _isMale ? 'Мужской' : 'Женский'; // Добавлен параметр пола

    FirebaseFirestore.instance.collection('patients').add({
      'surname': surname,
      'age': age,
      'price': price,
      'name': name,
      'city': city,
      'phone': phone,
      'gender': gender, // Сохраняем пол в Firestore
      'searchKey': surname.toLowerCase(),
    }).then((result) {
      print('Пациент добавлен');
      String newPatientId = result.id;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PatientDetailsScreen(patientId: newPatientId),
        ),
      );
    }).catchError((error) {
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
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Имя'),
              ),
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(labelText: 'Город'),
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Телефон'),
                keyboardType: TextInputType.number,
              ),

              // Виджеты для выбора пола
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  GestureDetector(
                    onTap: () => setState(() => _isMale = true),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                      decoration: BoxDecoration(
                        color: _isMale ? Colors.blue : Colors.grey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Мужской', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  SizedBox(width: 20),
                  GestureDetector(
                    onTap: () => setState(() => _isMale = false),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                      decoration: BoxDecoration(
                        color: !_isMale ? Colors.pink : Colors.grey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Женский', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _addPatientToFirestore();
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
