import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Для форматирования выбранной даты

class AddTreatmentScreen extends StatefulWidget {
  final String patientId;
  final Map<String, dynamic>? treatmentData;

  AddTreatmentScreen({required this.patientId, this.treatmentData});

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

  @override
  void initState() {
    super.initState();
    // Если переданы данные для редактирования, инициализируем поля этими данными
    if (widget.treatmentData != null) {
      selectedTreatment = widget.treatmentData!['treatmentType'];
      
      // Убедитесь, что selectedTeeth является списком
      if (widget.treatmentData!['toothNumber'] is List) {
        selectedTeeth = List<int>.from(widget.treatmentData!['toothNumber']);
      } else {
        // Если это одно число, создайте список с одним элементом
        selectedTeeth = [widget.treatmentData!['toothNumber']];
      }

      selectedDate = (widget.treatmentData!['date'] as Timestamp).toDate();
    }
  }

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
        title: Text(widget.treatmentData == null ? 'Добавить Лечение' : 'Редактировать Лечение'),
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
                          selectedTreatment = selected ? treatment : null;
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
                      final collection = FirebaseFirestore.instance.collection('treatments');
                      if (widget.treatmentData != null) {
                        // Обновляем существующую запись лечения
                        final docId = widget.treatmentData!['id']; // Идентификатор документа для обновления
                        collection.doc(docId).update({
                          'treatmentType': selectedTreatment,
                          'toothNumber': selectedTeeth,
                          'date': Timestamp.fromDate(selectedDate),
                        });
                      } else {
                        // Добавление новой записи лечения в Firestore
                        collection.add({
                          'patientId': widget.patientId,
                          'treatmentType': selectedTreatment,
                          'toothNumber': selectedTeeth,
                          'date': Timestamp.fromDate(selectedDate),
                        });
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(widget.treatmentData == null ? 'Лечение добавлено' : 'Лечение обновлено'),
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(widget.treatmentData == null ? 'Добавить лечение' : 'Обновить лечение'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
