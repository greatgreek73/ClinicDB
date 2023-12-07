import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditPatientScreen extends StatefulWidget {
  final String patientId;

  EditPatientScreen({required this.patientId});

  @override
  _EditPatientScreenState createState() => _EditPatientScreenState();
}

class _EditPatientScreenState extends State<EditPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Контроллеры для текстовых полей
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _ageController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _priceController = TextEditingController(); // Контроллер для цены

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _priceController.dispose(); // Не забывайте освобождать контроллер
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DocumentSnapshot patientSnapshot = await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .get();

      Map<String, dynamic> patientData = patientSnapshot.data() as Map<String, dynamic>;

      _nameController.text = patientData['name'];
      _surnameController.text = patientData['surname'];
      _ageController.text = patientData['age'].toString();
      _cityController.text = patientData['city'];
      _phoneController.text = patientData['phone'];
      _priceController.text = patientData['price'].toString(); // Загрузка цены

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String updatedSearchKey = _surnameController.text.toLowerCase();

      await FirebaseFirestore.instance.collection('patients').doc(widget.patientId).update({
        'name': _nameController.text,
        'surname': _surnameController.text,
        'age': int.parse(_ageController.text),
        'city': _cityController.text,
        'phone': _phoneController.text,
        'price': double.parse(_priceController.text), // Обновление цены
        'searchKey': updatedSearchKey,
      });

      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Редактировать Пациента'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Имя'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Пожалуйста, введите имя';
                        }
                        return null;
                      },
                    ),
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
                      controller: _cityController,
                      decoration: InputDecoration(labelText: 'Город'),
                    ),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(labelText: 'Телефон'),
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
                      onPressed: _savePatient,
                      child: Text('Сохранить изменения'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
