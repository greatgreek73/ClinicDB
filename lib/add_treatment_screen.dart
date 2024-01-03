import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
  List<int> selectedTeeth = [];
  DateTime selectedDate = DateTime.now();

  final List<String> treatments = ['Кариес', 'Имплантация', 'Удаление', 'Сканирование', 'Эндо'];
  final List<String> teethNumbers = [
    '11', '12', '13', '14', '15', '16', '17', '18',
    '21', '22', '23', '24', '25', '26', '27', '28',
    '31', '32', '33', '34', '35', '36', '37', '38',
    '41', '42', '43', '44', '45', '46', '47', '48'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.treatmentData != null) {
      selectedTreatment = widget.treatmentData!['treatmentType'];
      selectedTeeth = List<int>.from(widget.treatmentData!['toothNumber'] ?? []);

      if (widget.treatmentData!['date'] != null) {
        selectedDate = (widget.treatmentData!['date'] as Timestamp).toDate();
      }
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
        title: Text(widget.treatmentData == null ? 'Добавить лечение' : 'Редактировать лечение'),
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
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: teethNumbers.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, index) {
                    String toothNumber = teethNumbers[index];
                    return GestureDetector(
                      onTap: () => setState(() {
                        int toothIndex = int.parse(toothNumber);
                        if (selectedTeeth.contains(toothIndex)) {
                          selectedTeeth.remove(toothIndex);
                        } else {
                          selectedTeeth.add(toothIndex);
                        }
                      }),
                      child: Container(
                        margin: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          border: Border.all(color: selectedTeeth.contains(int.parse(toothNumber)) ? Colors.blue : Colors.grey),
                          color: selectedTeeth.contains(int.parse(toothNumber)) ? Colors.blue[200] : Colors.white,
                        ),
                        child: Center(
                          child: Text(
                            toothNumber,
                            style: TextStyle(
                              fontSize: 12,
                              color: selectedTeeth.contains(int.parse(toothNumber)) ? Colors.white : Colors.black,
                            ),
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
                  onPressed: () async {
                    if (_formKey.currentState!.validate() && selectedTreatment != null && selectedTeeth.isNotEmpty) {
                      final collection = FirebaseFirestore.instance.collection('treatments');
                      Map<String, dynamic> data = {
                        'patientId': widget.patientId,
                        'treatmentType': selectedTreatment,
                        'toothNumber': selectedTeeth,
                        'date': Timestamp.fromDate(selectedDate),
                      };

                      if (widget.treatmentData != null && widget.treatmentData!.containsKey('id')) {
                        await collection.doc(widget.treatmentData!['id']).update(data);
                      } else {
                        await collection.add(data);
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(widget.treatmentData == null ? 'Данные о лечении добавлены' : 'Данные о лечении обновлены'),
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
