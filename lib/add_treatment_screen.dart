import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTreatmentScreen extends StatefulWidget {
  final String patientId;

  AddTreatmentScreen({required this.patientId});

  @override
  _AddTreatmentScreenState createState() => _AddTreatmentScreenState();
}

class _AddTreatmentScreenState extends State<AddTreatmentScreen> {
  final _formKey = GlobalKey<FormState>();
  String treatmentDescription = '';
  double treatmentCost = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить Лечение'),
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Описание лечения',
                ),
                onChanged: (value) {
                  treatmentDescription = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите описание лечения';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Стоимость лечения',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  treatmentCost = double.tryParse(value) ?? 0.0;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите стоимость лечения';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    FirebaseFirestore.instance.collection('treatments').add({
                      'patientId': widget.patientId,
                      'description': treatmentDescription,
                      'cost': treatmentCost,
                    }).then((value) {
                      print("Treatment Added");
                      Navigator.of(context).pop(); // Возвращаемся назад после добавления
                    }).catchError((error) {
                      print("Failed to add treatment: $error");
                    });
                  }
                },
                child: Text('Добавить лечение'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
