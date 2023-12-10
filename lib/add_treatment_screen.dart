import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Для форматирования выбранной даты

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
  DateTime selectedDate = DateTime.now(); // Инициализируем с текущей датой

  final List<String> treatments = ['Кариес', 'Имплантация', 'Удаление'];
  final int teethCount = 32; // Предположим, у нас 32 зуба

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

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
          child: SingleChildScrollView(
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
                          } else {
                            selectedTreatment = null;
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: teethCount,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    childAspectRatio: 1.0,
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
                ListTile(
                  title: Text('Выбранная дата: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() && selectedTreatment != null && selectedTeeth.isNotEmpty) {
                      // Добавление информации о лечении в Firestore
                      for (var tooth in selectedTeeth) {
                        FirebaseFirestore.instance.collection('treatments').add({
                          'patientId': widget.patientId,
                          'treatmentType': selectedTreatment,
                          'toothNumber': tooth,
                          'date': Timestamp.fromDate(selectedDate), // Добавляем выбранную дату
                        });
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Лечение добавлено'),
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text('Добавить лечение'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
