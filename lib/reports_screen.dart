import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime selectedDate = DateTime.now(); // Текущая выбранная дата
  List<String> treatmentTypes = []; // Список для хранения видов лечения

  @override
  void initState() {
    super.initState();
    _loadTreatmentTypes(); // Загрузка видов лечения
  }

  Future<void> _loadTreatmentTypes() async {
    FirebaseFirestore.instance
      .collection('treatments')
      .get()
      .then((querySnapshot) {
        var types = querySnapshot.docs.map((doc) => doc['treatmentType'].toString()).toSet().toList();
        setState(() {
          treatmentTypes = types;
        });
      });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate, 
      firstDate: DateTime(2000), 
      lastDate: DateTime(2025),
      // Отображение только месяца и года
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
      });
  }

  DateTime get firstDate => DateTime(selectedDate.year, selectedDate.month, 1);
  DateTime get lastDate => DateTime(selectedDate.year, selectedDate.month + 1, 0, 23, 59, 59);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Отчеты об имплантациях'),
      ),
      body: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _selectDate(context),
                child: Text("${DateFormat.yMMMM().format(selectedDate)}"),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: treatmentTypes.length,
              itemBuilder: (context, index) {
                return _buildStatisticsWidget(treatmentTypes[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsWidget(String treatmentType) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('treatments')
        .where('treatmentType', isEqualTo: treatmentType)
        .where('date', isGreaterThanOrEqualTo: firstDate)
        .where('date', isLessThanOrEqualTo: lastDate);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          String errorMessage = 'Ошибка: ${snapshot.error.toString()}';
          return ListTile(
            title: Text(treatmentType),
            subtitle: Text(errorMessage),
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: errorMessage));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Сообщение об ошибке скопировано в буфер обмена'),
                ),
              );
            },
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return ListTile(
            title: Text(treatmentType),
            subtitle: Text('Нет данных за выбранный период.'),
          );
        }

        int totalTeethCount = snapshot.data!.docs.fold(0, (sum, doc) {
          var toothNumbers = List.from(doc['toothNumber'] ?? []);
          return sum + toothNumbers.length;
        });

        return ListTile(
          title: Text(treatmentType),
          subtitle: Text('Количество зубов за ${DateFormat.yMMMM().format(selectedDate)}: $totalTeethCount'),
        );
      },
    );
  }
}
