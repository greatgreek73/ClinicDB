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
  String? selectedTreatment;
  List<int> selectedTeeth = []; // Изменим на список для множественного выбора

  final List<String> treatments = ['Кариес', 'Имплантация', 'Удаление'];
  final int teethCount = 32; // Предположим, у нас 32 зуба

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
              Wrap(
                spacing: 8.0,
                children: treatments.map((treatment) {
                  return ChoiceChip(
                    label: Text(treatment),
                    selected: selectedTreatment == treatment,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          selectedTreatment = treatment;
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  itemCount: teethCount,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8, // Увеличиваем количество столбцов
                    childAspectRatio: 1.0, // Соотношение сторон для каждого элемента
                  ),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (selectedTeeth.contains(index + 1)) {
                          selectedTeeth.remove(index + 1);
                        } else {
                          selectedTeeth.add(index + 1);
                        }
                      }),
                      child: Container(
                        margin: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue),
                          color: selectedTeeth.contains(index + 1) ? Colors.blue[300] : Colors.white,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() && selectedTreatment != null && selectedTeeth.isNotEmpty) {
                    for (var tooth in selectedTeeth) {
                      FirebaseFirestore.instance.collection('treatments').add({
                        'patientId': widget.patientId,
                        'treatmentType': selectedTreatment,
                        'toothNumber': tooth,
                      });
                    }
                    print("Treatments Added");
                    Navigator.of(context).pop();
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
