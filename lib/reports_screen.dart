import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String selectedPeriod = 'month'; // 'month' или 'year'
  late DateTime firstDate;
  late DateTime lastDate;

  @override
  void initState() {
    super.initState();
    _setDateRange();
  }

  void _setDateRange() {
    DateTime now = DateTime.now();
    if (selectedPeriod == 'month') {
      firstDate = DateTime(now.year, now.month, 1);
      lastDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    } else {
      firstDate = DateTime(now.year, 1, 1);
      lastDate = DateTime(now.year, 12, 31, 23, 59, 59);
    }
  }

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
              _periodButton('Месяц', 'month'),
              _periodButton('Год', 'year'),
            ],
          ),
          Expanded(
            child: ListView(
              children: [
                _buildStatisticsWidget('Имплантация'),
                _buildStatisticsWidget('Удаление'),
                _buildStatisticsWidget('Кариес'),
                _buildStatisticsWidget('Сканирование'),
                _buildStatisticsWidget('Эндо'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodButton(String title, String period) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedPeriod = period;
          _setDateRange();
        });
      },
      child: Text(title),
      style: ElevatedButton.styleFrom(
        primary: selectedPeriod == period ? Colors.blue : Colors.grey,
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

        int count = snapshot.data!.docs.length;
        return ListTile(
          title: Text(treatmentType),
          subtitle: Text('Количество за $selectedPeriod: $count'),
        );
      },
    );
  }
}
