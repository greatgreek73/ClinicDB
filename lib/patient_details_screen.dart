import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'edit_patient_screen.dart';
import 'add_treatment_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'payment.dart';
import 'dart:io';


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
  Widget _buildTreatmentSchemas(String patientId) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildTreatmentSchema(patientId, 'Имплантация', Colors.blue)),
            Expanded(child: _buildTreatmentSchema(patientId, 'Коронки', Colors.green)),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildTreatmentSchema(patientId, 'Лечение', Colors.orange)),
            Expanded(child: _buildTreatmentSchema(patientId, 'Удаление', Colors.red)),
          ],
        ),
      ],
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(treatmentType, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
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
      if (treatmentSnapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      if (treatmentSnapshot.hasError) {
        print('Error in _buildTreatmentsSection: ${treatmentSnapshot.error}');
        print('Error stack trace: ${treatmentSnapshot.stackTrace}');

        if (treatmentSnapshot.error.toString().contains('The query requires an index')) {
          final urlMatch = RegExp(r'https://console\.firebase\.google\.com[^\s]+').firstMatch(treatmentSnapshot.error.toString());
          final indexUrl = urlMatch?.group(0);
          if (indexUrl != null) {
            return Column(
              children: [
                Text('Требуется создание индекса. Нажмите на ссылку ниже для создания:'),
                InkWell(
                  child: Text(indexUrl, style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: indexUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ссылка скопирована в буфер обмена')),
                    );
                  },
                ),
              ],
            );
          }
        }
        return Text('Ошибка загрузки данных о лечении: ${treatmentSnapshot.error}');
      }

      if (!treatmentSnapshot.hasData || treatmentSnapshot.data!.docs.isEmpty) {
        print('No treatment data found for patient: $patientId');
        return Text('Нет данных о лечении');
      }

      print('Treatment data loaded successfully. Document count: ${treatmentSnapshot.data!.docs.length}');
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
        // Загрузка изображения в Firebase Storage
        TaskSnapshot uploadTask = await FirebaseStorage.instance
            .ref('patients/${widget.patientId}/$fileName')
            .putFile(imageFile);
        
        String imageUrl = await uploadTask.ref.getDownloadURL();
        
        // Обновление документа пациента в Firestore
        await FirebaseFirestore.instance.collection('patients').doc(widget.patientId).update({
          'additionalPhotos': FieldValue.arrayUnion([
            {
              'url': imageUrl,
              'description': 'Дополнительное фото', // Можно добавить диалог для ввода описания
              'dateAdded': Timestamp.now(),
            }
          ]),
        });
        
        // Обновление UI
        setState(() {});
      } catch (e) {
        print('Error uploading additional photo: $e');
        // Добавьте обработку ошибок, например, показ SnackBar
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