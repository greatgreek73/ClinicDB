import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'edit_patient_screen.dart';
import 'add_treatment_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'payment.dart';
import 'notes_widget.dart';

final priceFormatter = NumberFormat('#,###', 'ru_RU');

class PatientDetailsScreen extends StatefulWidget {
  final String patientId;

  PatientDetailsScreen({required this.patientId});

  @override
  _PatientDetailsScreenState createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  final TextEditingController _plannedTreatmentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPlannedTreatment();
  }

  @override
  void dispose() {
    _plannedTreatmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Детали Пациента'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditPatientScreen(patientId: widget.patientId),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddTreatmentScreen(patientId: widget.patientId),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _confirmDeletion(context, widget.patientId),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('patients').doc(widget.patientId).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              var patientData = snapshot.data!.data() as Map<String, dynamic>;
              return ListView(
                children: <Widget>[
                  _buildPatientInfoCard(context, patientData),
                  _buildTreatmentSchemas(widget.patientId),
                  _buildTreatmentsSection(widget.patientId),
                  _buildAdditionalPhotosSection(patientData),
                  _buildPlannedTreatmentSection(context),
                  NotesWidget(patientId: widget.patientId),
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
    TextStyle nameStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.blue[800],
    );
    TextStyle ageStyle = TextStyle(
      fontSize: 20,
      color: Colors.black87,
    );
    TextStyle contactStyle = TextStyle(
      fontSize: 22,
      color: Colors.black87,
    );
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
        Text('${patientData['surname']} ${patientData['name']}', style: nameStyle, textAlign: TextAlign.center),
        Text('${patientData['age']} лет', style: ageStyle, textAlign: TextAlign.center),
        Text('${patientData['city'] ?? 'Нет данных'} | ${patientData['phone'] ?? 'Нет данных'}', style: contactStyle, textAlign: TextAlign.center),
        SizedBox(height: 16),
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
  Widget _buildTreatmentSchemas(String patientId) {
    return FutureBuilder<Map<String, int>>(
      future: _getTreatmentCounts(patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Ошибка: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text('Нет данных о лечении');
        }

        var sortedTreatments = snapshot.data!.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        var topFourTreatments = sortedTreatments.take(4).toList();

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildTreatmentSchema(patientId, topFourTreatments[0].key, _getColor(topFourTreatments[0].key))),
                Expanded(child: _buildTreatmentSchema(patientId, topFourTreatments[1].key, _getColor(topFourTreatments[1].key))),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildTreatmentSchema(patientId, topFourTreatments[2].key, _getColor(topFourTreatments[2].key))),
                Expanded(child: _buildTreatmentSchema(patientId, topFourTreatments[3].key, _getColor(topFourTreatments[3].key))),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTreatmentSchema(String patientId, String treatmentType, Color color) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('treatments')
          .where('patientId', isEqualTo: patientId)
          .where('treatmentType', isEqualTo: treatmentType)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Ошибка загрузки данных о лечении: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        List<int> treatedTeeth = [];
        snapshot.data!.docs.forEach((doc) {
          var data = doc.data() as Map<String, dynamic>;
          treatedTeeth.addAll(List<int>.from(data['toothNumber']));
        });

        return Card(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    treatmentType,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 16,
                      childAspectRatio: 1,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemCount: 32,
                    itemBuilder: (context, index) {
                      int toothNumber = _getToothNumber(index);
                      bool isTreated = treatedTeeth.contains(toothNumber);
                      return Container(
                        decoration: BoxDecoration(
                          color: isTreated ? color : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            toothNumber.toString(),
                            style: TextStyle(
                              color: isTreated ? Colors.white : Colors.black,
                              fontSize: 8,
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

  Future<Map<String, int>> _getTreatmentCounts(String patientId) async {
    var treatmentCounts = <String, int>{
      'Кариес': 0,
      'Имплантация': 0,
      'Удаление': 0,
      'Сканирование': 0,
      'Эндо': 0,
      'Формирователь': 0,
      'PMMA': 0,
      'Коронка': 0,
      'Абатмент': 0,
      'Сдача PMMA': 0,
      'Сдача коронка': 0,
      'Сдача абатмент': 0,
      'Удаление импланта': 0
    };

    var snapshot = await FirebaseFirestore.instance
        .collection('treatments')
        .where('patientId', isEqualTo: patientId)
        .get();

    for (var doc in snapshot.docs) {
      var data = doc.data();
      var treatmentType = data['treatmentType'] as String;
      var toothNumbers = (data['toothNumber'] as List?)?.length ?? 0;
      
      if (treatmentCounts.containsKey(treatmentType)) {
        treatmentCounts[treatmentType] = treatmentCounts[treatmentType]! + toothNumbers;
      } else {
        print('Неизвестный тип лечения: $treatmentType');
      }
    }

    return treatmentCounts;
  }

  Color _getColor(String treatmentType) {
    final colors = {
      'Кариес': Colors.red,
      'Имплантация': Colors.blue,
      'Удаление': Colors.orange,
      'Сканирование': Colors.purple,
      'Эндо': Colors.green,
      'Формирователь': Colors.teal,
      'PMMA': Colors.amber,
      'Коронка': Colors.indigo,
      'Абатмент': Colors.pink,
      'Сдача PMMA': Colors.cyan,
      'Сдача коронка': Colors.deepPurple,
      'Сдача абатмент': Colors.lightGreen,
      'Удаление импланта': Colors.deepOrange,
    };

    return colors[treatmentType] ?? Colors.grey;
  }

  int _getToothNumber(int index) {
  if (index < 16) {
    // Верхний ряд: 18 17 16 15 14 13 12 11 21 22 23 24 25 26 27 28
    return index < 8 ? 18 - index : 21 + (index - 8);
  } else {
    // Нижний ряд: 48 47 46 45 44 43 42 41 31 32 33 34 35 36 37 38
    return index < 24 ? 48 - (index - 16) : 31 + (index - 24);
  }
}
  Widget _buildTreatmentsSection(String patientId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('treatments')
          .where('patientId', isEqualTo: patientId)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, treatmentSnapshot) {
        if (treatmentSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (treatmentSnapshot.hasError) {
          print('Error in _buildTreatmentsSection: ${treatmentSnapshot.error}');
          print('Error stack trace: ${treatmentSnapshot.stackTrace}');
          return Text('Ошибка загрузки данных о лечении: ${treatmentSnapshot.error}');
        }

        if (!treatmentSnapshot.hasData || treatmentSnapshot.data!.docs.isEmpty) {
          return Text('Нет данных о лечении');
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

  Widget _buildAdditionalPhotosSection(Map<String, dynamic> patientData) {
    List<dynamic> additionalPhotos = patientData['additionalPhotos'] ?? [];
    
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Дополнительные фото', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton(
                  onPressed: _addAdditionalPhoto,
                  child: Text('Добавить'),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (additionalPhotos.isEmpty)
              Text('Нет дополнительных фотографий')
            else
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: additionalPhotos.length,
                itemBuilder: (context, index) {
                  var photo = additionalPhotos[index];
                  return GestureDetector(
                    onTap: () => _showImageDialog(photo),
                    child: Image.network(
                      photo['url'],
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(Map<String, dynamic> photo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(photo['url']),
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(photo['description']),
              ),
              Text(DateFormat('yyyy-MM-dd').format((photo['dateAdded'] as Timestamp).toDate())),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addAdditionalPhoto() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      File imageFile = File(image.path);
      String fileName = 'additional_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      try {
        TaskSnapshot uploadTask = await FirebaseStorage.instance
            .ref('patients/${widget.patientId}/$fileName')
            .putFile(imageFile);
        
        String imageUrl = await uploadTask.ref.getDownloadURL();
        
        await FirebaseFirestore.instance.collection('patients').doc(widget.patientId).update({
          'additionalPhotos': FieldValue.arrayUnion([
            {
              'url': imageUrl,
              'description': 'Дополнительное фото',
              'dateAdded': Timestamp.now(),
            }
          ]),
        });
        
        setState(() {});
      } catch (e) {
        print('Error uploading additional photo: $e');
      }
    }
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
    await prefs.setString('planned_treatment_${widget.patientId}', treatment);
  }

  Future<void> _loadPlannedTreatment() async {
    final prefs = await SharedPreferences.getInstance();
    String treatment = prefs.getString('planned_treatment_${widget.patientId}') ?? '';
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
      'Имплантация', 'Коронки', 'Лечение', 'Удаление'
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
