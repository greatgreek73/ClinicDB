import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InfoPanel extends StatefulWidget {
  const InfoPanel({Key? key}) : super(key: key);

  @override
  _InfoPanelState createState() => _InfoPanelState();
}

class _InfoPanelState extends State<InfoPanel> {
  int totalTeethCountMonth = 0;
  int totalTeethCountYear = 0;
  int totalPatients = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  void _loadStatistics() {
    // Загрузка статистики имплантаций
    FirebaseFirestore.instance
        .collection('treatments')
        .where('treatmentType', isEqualTo: 'Имплантация')
        .where('date', isGreaterThanOrEqualTo: firstDateOfMonth)
        .where('date', isLessThanOrEqualTo: lastDateOfMonth)
        .get()
        .then((snapshot) {
      if (mounted) {
        setState(() {
          totalTeethCountMonth = snapshot.docs.fold<int>(0, (int sum, doc) {
            var toothNumbers = List.from(doc['toothNumber'] ?? []);
            return sum + toothNumbers.length;
          });
        });
      }
    });

    FirebaseFirestore.instance
        .collection('treatments')
        .where('treatmentType', isEqualTo: 'Имплантация')
        .where('date', isGreaterThanOrEqualTo: firstDateOfYear)
        .where('date', isLessThanOrEqualTo: lastDateOfYear)
        .get()
        .then((snapshot) {
      if (mounted) {
        setState(() {
          totalTeethCountYear = snapshot.docs.fold<int>(0, (int sum, doc) {
            var toothNumbers = List.from(doc['toothNumber'] ?? []);
            return sum + toothNumbers.length;
          });
        });
      }
    });

    // Загрузка общего количества пациентов
    FirebaseFirestore.instance
        .collection('patients')
        .get()
        .then((snapshot) {
      if (mounted) {
        setState(() {
          totalPatients = snapshot.docs.length;
        });
      }
    });
  }

  DateTime get firstDateOfMonth => DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime get lastDateOfMonth => DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);
  DateTime get firstDateOfYear => DateTime(DateTime.now().year, 1, 1);
  DateTime get lastDateOfYear => DateTime(DateTime.now().year, 12, 31, 23, 59, 59);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.navPanelDecoration,
      padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatisticValue(totalTeethCountMonth.toString(), 'импл.', 'За месяц'),
          SizedBox(height: 40),
          _buildStatisticValue(totalTeethCountYear.toString(), 'импл.', 'За год'),
          SizedBox(height: 40),
          _buildStatisticValue(totalPatients.toString(), 'пациентов', 'Всего'),
          Spacer(),
          _buildDateInfo(),
        ],
      ),
    );
  }

  Widget _buildStatisticValue(String value, String unit, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppTheme.lightTextColor,
              ),
            ),
            SizedBox(width: 5),
            Text(
              unit,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.lightTextColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.lightTextColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildDateInfo() {
    String formattedDate = DateFormat('dd MMMM yyyy').format(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formattedDate,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.lightTextColor,
          ),
        ),
        SizedBox(height: 4),
        Text(
          DateFormat('EEEE').format(DateTime.now()),
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.lightTextColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
