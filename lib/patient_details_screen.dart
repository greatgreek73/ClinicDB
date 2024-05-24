import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_patient_screen.dart';
import 'add_treatment_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
                  Card(
                    margin: EdgeInsets.all(8),
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Фамилия: ${patientData['surname'] ?? 'Нет данных'}', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Имя: ${patientData['name'] ?? 'Нет данных'}'),
                          Text('Возраст: ${patientData['age']}'),
                          Text('Город: ${patientData['city'] ?? 'Нет данных'}'),
                          Text('Телефон: ${patientData['phone'] ?? 'Нет данных'}'),
                          Text('Цена: ${patientData['price'] ?? 'Нет данных'}', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  ListTile(
                    title: Text('Фото'),
                    subtitle: patientData['photoUrl'] != null
                      ? Image.network(
                          patientData['photoUrl'],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      : SizedBox(
                          height: 100,
                          child: Center(child: Text('Нет фото')),
                        ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Выравнивание по центру
                    crossAxisAlignment: CrossAxisAlignment.start, // Выравнивание по верхнему краю
                    children: [
                      Flexible(
                        flex: 1,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.2667, // Ширина 26.67% от экрана
                          child: _buildTreatmentsSection(patientId), // Сортировка по датам
                        ),
                      ),
                      SizedBox(width: 16), // Добавление отступа между колонками
                      Flexible(
                        flex: 1,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.2667, // Ширина 26.67% от экрана
                          child: _buildTreatmentsByTypeSection(patientId), // Сортировка по видам лечения
                        ),
                      ),
                    ],
                  ),
                  _buildPlannedTreatmentSection(context),
                ],
              );
            } else if (snapshot.hasError) {
              return Text('Ошибка: ${snapshot.error}');
            } else {
              return Text('Нет данных');
            }
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildTreatmentsSection(String patientId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('treatments').where('patientId', isEqualTo: patientId).orderBy('date', descending: true).snapshots(),
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
            return Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.5, // Ширина 50% от экрана
                child: Card(
                  margin: EdgeInsets.all(8),
                  child: ExpansionTile(
                    title: Text(
                      DateFormat('yyyy-MM-dd').format(date),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    initiallyExpanded: true, // Сразу развернутый вид
                    children: treatmentInfos.map((treatmentInfo) {
                      return ListTile(
                        leading: Icon(Icons.healing), // Иконка, отражающая тип лечения
                        title: Text(
                          treatmentInfo.treatmentType,
                          style: TextStyle(fontSize: 16, color: Colors.blue),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Зубы: ${treatmentInfo.toothNumbers.join(", ")}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red, // Изменение цвета
                                fontWeight: FontWeight.bold, // Жирный шрифт
                              ),
                            ),
                            Text('Статус: ${treatmentInfo.status}'),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_forward),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AddTreatmentScreen(patientId: patientId, treatmentData: treatmentInfo.toMap()),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTreatmentsByTypeSection(String patientId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('treatments').where('patientId', isEqualTo: patientId).snapshots(),
      builder: (context, treatmentSnapshot) {
        if (treatmentSnapshot.hasError) {
          return Text('Ошибка загрузки данных о лечении: ${treatmentSnapshot.error}');
        }
        if (treatmentSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        var treatments = _groupTreatmentsByType(treatmentSnapshot.data!.docs);

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: treatments.keys.length,
          itemBuilder: (context, index) {
            String treatmentType = treatments.keys.elementAt(index);
            var treatmentInfos = treatments[treatmentType]!;
            return ExpansionTile(
              title: Text(
                treatmentType,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              initiallyExpanded: true,
              children: treatmentInfos.map((treatmentInfo) {
                return ListTile(
                  title: Text(
                    treatmentInfo.treatmentType,
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (treatmentInfo.toothNumbers != null && treatmentInfo.toothNumbers.isNotEmpty)
                        Text(
                          'Зубы: ${treatmentInfo.toothNumbers.join(", ")}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      Text(
                        'Дата: ${DateFormat('yyyy-MM-dd').format(treatmentInfo.date)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      Text('Статус: ${treatmentInfo.status}'),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward),
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
      var status = data['status'] ?? 'Неизвестно';

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
        groupedTreatments[dateWithoutTime]!.add(TreatmentInfo(treatmentType, toothNumbers, documentId, status, timestamp.toDate()));
      }
    }

    return groupedTreatments;
  }

  Map<String, List<TreatmentInfo>> _groupTreatmentsByType(List<DocumentSnapshot> docs) {
    Map<String, List<TreatmentInfo>> groupedTreatments = {};
    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      var treatmentType = data['treatmentType'] ?? 'Неизвестно';
      var toothNumbers = data['toothNumber'] != null ? List<int>.from(data['toothNumber']) : <int>[];
      var documentId = doc.id;
      var status = data['status'] ?? 'Неизвестно';
      var timestamp = data['date'] as Timestamp;
      var date = timestamp.toDate();

      if (!groupedTreatments.containsKey(treatmentType)) {
        groupedTreatments[treatmentType] = [];
      }

      groupedTreatments[treatmentType]!.add(TreatmentInfo(treatmentType, toothNumbers, documentId, status, date));
    }

    return groupedTreatments;
  }
}

class TreatmentInfo {
  String treatmentType;
  List<int> toothNumbers;
  String? id;
  String status;
  DateTime date;

  TreatmentInfo(this.treatmentType, this.toothNumbers, this.id, this.status, this.date);

  Map<String, dynamic> toMap() {
    return {
      'treatmentType': treatmentType,
      'toothNumbers': toothNumbers,
      'id': id,
      'status': status,
      'date': date,
    };
  }
}

class TreatmentSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<String> treatments = [
      '1 сегмент', '2 сегмент', '3 сегмент', '4 сегмент',
      'Имплантация', 'Обточка', 'Лечение', 'Сдача'
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
