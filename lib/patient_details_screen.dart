import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_patient_screen.dart';
import 'add_treatment_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'payment.dart';

final priceFormatter = NumberFormat('#,###', 'ru_RU');

class PatientDetailsScreen extends StatelessWidget {
  final String patientId;
  final TextEditingController _plannedTreatmentController = TextEditingController();

  PatientDetailsScreen({required this.patientId});

  @override
  Widget build(BuildContext context) {
    _loadPlannedTreatment();

    return Scaffold(
      appBar: AppBar(
        title: Text('Детали Пациента'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditPatientScreen(patientId: patientId),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddTreatmentScreen(patientId: patientId),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _confirmDeletion(context, patientId),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('patients').doc(patientId).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              var patientData = snapshot.data!.data() as Map<String, dynamic>;
              return ListView(
                children: <Widget>[
                  _buildPatientInfoCard(context, patientData),
                  _buildImplantSchema(patientId),
                  _buildTreatmentsSection(patientId),
                  _buildPlannedTreatmentSection(context),
                ],
              );
            } else if (snapshot.hasError) {
              return Text('Ошибка: ${snapshot.error}');
            }
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
  Widget _buildPatientInfoCard(BuildContext context, Map<String, dynamic> patientData) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5,
        margin: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildPatientPhoto(patientData['photoUrl']),
              SizedBox(height: 16),
              _buildPatientDetails(patientData),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientPhoto(String? photoUrl) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: photoUrl != null
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
              )
            : Container(
                color: Colors.grey[300],
                child: Icon(Icons.person, size: 80, color: Colors.grey[600]),
              ),
      ),
    );
  }

  Widget _buildPatientDetails(Map<String, dynamic> patientData) {
    TextStyle titleStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.blue[800],
    );
    TextStyle subtitleStyle = TextStyle(
      fontSize: 14,
      color: Colors.black87,
    );

    bool hadConsultation = patientData['hadConsultation'] == true;

    var paymentsData = patientData['payments'] as List<dynamic>? ?? [];
    List<Payment> payments = paymentsData.map((p) => Payment.fromMap(p)).toList();
    double totalPaid = payments.fold(0, (sum, payment) => sum + payment.amount);

    return Column(
      children: [
        _buildDetailRow('ФИО', '${patientData['surname']} ${patientData['name']}', titleStyle, subtitleStyle),
        _buildDetailRow('Возраст', '${patientData['age']}', titleStyle, subtitleStyle),
        _buildDetailRow('Город', patientData['city'] ?? 'Нет данных', titleStyle, subtitleStyle),
        _buildDetailRow('Телефон', patientData['phone'] ?? 'Нет данных', titleStyle, subtitleStyle),
        _buildDetailRow('Цена', '${priceFormatter.format(patientData['price'])} ₽', titleStyle, subtitleStyle),
        _buildDetailRow('Оплачено', '${priceFormatter.format(totalPaid)} ₽', titleStyle, subtitleStyle),
        _buildDetailRow('Осталось', '${priceFormatter.format((patientData['price'] ?? 0) - totalPaid)} ₽', titleStyle, subtitleStyle),
        _buildDetailRow('Консультация', hadConsultation ? 'Да' : 'Нет', titleStyle, subtitleStyle),
        SizedBox(height: 16),
        _buildPaymentsHistory(payments),
      ],
    );
  }

  Widget _buildDetailRow(String title, String value, TextStyle titleStyle, TextStyle subtitleStyle) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: titleStyle),
          Text(value, style: subtitleStyle),
        ],
      ),
    );
  }

  Widget _buildPaymentsHistory(List<Payment> payments) {
    return ExpansionTile(
      title: Text('История платежей', style: TextStyle(fontWeight: FontWeight.bold)),
      children: payments.map((payment) => ListTile(
        title: Text('${priceFormatter.format(payment.amount)} ₽'),
        subtitle: Text(DateFormat('yyyy-MM-dd').format(payment.date)),
        trailing: Icon(Icons.payment, color: Colors.green),
      )).toList(),
    );
  }
  Widget _buildImplantSchema(String patientId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('treatments')
          .where('patientId', isEqualTo: patientId)
          .where('treatmentType', isEqualTo: 'Имплантация')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Ошибка загрузки данных о лечении: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        List<int> implantTeeth = [];
        snapshot.data!.docs.forEach((doc) {
          var data = doc.data() as Map<String, dynamic>;
          implantTeeth.addAll(List<int>.from(data['toothNumber']));
        });

        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Имплантация', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 16,
                      childAspectRatio: 1,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: 32,
                    itemBuilder: (context, index) {
                      int toothNumber = _getToothNumber(index);
                      bool isTreated = implantTeeth.contains(toothNumber);
                      return Container(
                        decoration: BoxDecoration(
                          color: isTreated ? Colors.blue : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            toothNumber.toString(),
                            style: TextStyle(
                              color: isTreated ? Colors.white : Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _getToothNumber(int index) {
    if (index < 8) return index + 11;
    if (index < 16) return index + 13;
    if (index < 24) return index + 15;
    return index + 17;
  }

  Widget _buildTreatmentsSection(String patientId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('treatments')
          .where('patientId', isEqualTo: patientId)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, treatmentSnapshot) {
        if (treatmentSnapshot.hasError) {
          return Text('Ошибка загрузки данных о лечении: ${treatmentSnapshot.error}');
        }
        if (treatmentSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        var treatments = _groupTreatmentsByDate(treatmentSnapshot.data!.docs);

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: treatments.keys.length,
          itemBuilder: (context, index) {
            DateTime date = treatments.keys.elementAt(index);
            var treatmentInfos = treatments[date]!;
            return ExpansionTile(
              title: Text(DateFormat('yyyy-MM-dd').format(date)),
              children: treatmentInfos.map((treatmentInfo) {
                return ListTile(
                  title: Text(treatmentInfo.treatmentType),
                  subtitle: Text('Зубы: ${treatmentInfo.toothNumbers.join(", ")}'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AddTreatmentScreen(patientId: patientId, treatmentData: treatmentInfo.toMap()),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
  Widget _buildPlannedTreatmentSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text('Планируемое лечение:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          TextField(
            controller: _plannedTreatmentController,
            decoration: InputDecoration(border: OutlineInputBorder()),
            readOnly: true,
            maxLines: null,
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _navigateAndDisplaySelection(context),
                child: Text('Добавить'),
              ),
              ElevatedButton(
                onPressed: () {
                  _plannedTreatmentController.clear();
                  _savePlannedTreatment('');
                },
                child: Text('Очистить'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateAndDisplaySelection(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TreatmentSelectionScreen()),
    );

    if (result != null) {
      _plannedTreatmentController.text += (result + '\n');
      await _savePlannedTreatment(_plannedTreatmentController.text);
    }
  }

  Future<void> _savePlannedTreatment(String treatment) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('planned_treatment_$patientId', treatment);
  }

  Future<void> _loadPlannedTreatment() async {
    final prefs = await SharedPreferences.getInstance();
    String treatment = prefs.getString('planned_treatment_$patientId') ?? '';
    _plannedTreatmentController.text = treatment;
  }

  void _confirmDeletion(BuildContext context, String patientId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Удалить пациента'),
          content: Text('Вы уверены, что хотите удалить этого пациента?'),
          actions: <Widget>[
            TextButton(
              child: Text('Отмена'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Удалить'),
              onPressed: () {
                FirebaseFirestore.instance.collection('patients').doc(patientId).delete().then((_) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                });
              },
            ),
          ],
        );
      },
    );
  }

  Map<DateTime, List<TreatmentInfo>> _groupTreatmentsByDate(List<DocumentSnapshot> docs) {
    Map<DateTime, List<TreatmentInfo>> groupedTreatments = {};

    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      var timestamp = data['date'] as Timestamp;
      var dateWithoutTime = DateTime(timestamp.toDate().year, timestamp.toDate().month, timestamp.toDate().day);
      var treatmentType = data['treatmentType'];
      var toothNumbers = data['toothNumber'] != null ? List<int>.from(data['toothNumber']) : <int>[];
      var documentId = doc.id;

      if (!groupedTreatments.containsKey(dateWithoutTime)) {
        groupedTreatments[dateWithoutTime] = [];
      }

      bool found = false;
      for (var treatmentInfo in groupedTreatments[dateWithoutTime]!) {
        if (treatmentInfo.treatmentType == treatmentType) {
          found = true;
          treatmentInfo.toothNumbers.addAll(toothNumbers.where((num) => !treatmentInfo.toothNumbers.contains(num)));
          break;
        }
      }

      if (!found) {
        groupedTreatments[dateWithoutTime]!.add(TreatmentInfo(treatmentType, toothNumbers, documentId));
      }
    }

    return groupedTreatments;
  }
}

class TreatmentInfo {
  String treatmentType;
  List<int> toothNumbers;
  String? id;

  TreatmentInfo(this.treatmentType, this.toothNumbers, this.id);

  Map<String, dynamic> toMap() {
    return {
      'treatmentType': treatmentType,
      'toothNumbers': toothNumbers,
      'id': id
    };
  }
}

class TreatmentSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<String> treatments = [
      '1 сегмент', '2 сегмент', '3 сегмент', '4 сегмент',
      'Имплантация', 'Коронка', 'Лечение', 'Сдача'
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Выбор лечения')),
      body: ListView.builder(
        itemCount: treatments.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(treatments[index]),
            onTap: () {
              Navigator.pop(context, treatments[index]);
            },
          );
        },
      ),
    );
  }
}