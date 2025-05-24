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

// Define consistent card styling elements
final BoxDecoration kDarkCardDecoration = BoxDecoration(
  color: Color(0xFF2A2A2A),
  borderRadius: BorderRadius.circular(12.0), 
  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.0),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.5),
      blurRadius: 10,
      spreadRadius: 0,
      offset: Offset(4, 4),
    )
  ],
);

final EdgeInsets kCardPadding = EdgeInsets.all(16.0);
final EdgeInsets kCardMargin = EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0);


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

  Future<void> _updatePatientField(String field, dynamic value) async {
    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .update({field: value});
    } catch (e) {
      print('Ошибка при обновлении поля $field: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления: $e'), backgroundColor: Colors.redAccent)
        );
      }
    }
  }

  Widget _buildToggleRow(String title, bool currentValue, Function(bool?) onChanged, TextStyle titleStyle) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.0), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: titleStyle),
          Switch( 
            value: currentValue,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveThumbColor: Colors.grey[700],
            inactiveTrackColor: Colors.grey[800]?.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _plannedTreatmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF202020), 
      appBar: AppBar(
        title: Text('Детали Пациента', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF2A2A2A), 
        iconTheme: IconThemeData(color: Colors.white), 
        elevation: 0, 
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.edit_outlined), // Updated Icon
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditPatientScreen(patientId: widget.patientId),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.post_add_outlined), // Updated Icon
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddTreatmentScreen(patientId: widget.patientId),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline), // Updated Icon
            onPressed: () => _confirmDeletion(context, widget.patientId),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('patients').doc(widget.patientId).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: Theme(data: ThemeData.dark(), child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}', style: TextStyle(color: Colors.redAccent)));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Пациент не найден.', style: TextStyle(color: Colors.white70)));
          }
          
          var patientData = snapshot.data!.data() as Map<String, dynamic>;
          return ListView(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            children: <Widget>[
              _buildPatientInfoCard(context, patientData),
              _buildSectionWrapper(child: _buildPaymentsHistory(context, patientData), title: 'История платежей'),
              _buildTreatmentSchemas(widget.patientId), 
              _buildSectionWrapper(child: _buildTreatmentsSection(widget.patientId), title: 'Проведенное лечение'),
              _buildAdditionalPhotosSection(context, patientData),
              _buildPlannedTreatmentSection(context), 
              Padding(
                padding: kCardMargin, 
                child: NotesWidget(
                  patientId: widget.patientId,
                  backgroundColor: Color(0xFF2A2A2A), 
                  textColor: Colors.white,
                  buttonColor: Theme.of(context).colorScheme.primary,
                  borderColor: Colors.white.withOpacity(0.2), 
                  boxShadowColor: Colors.black.withOpacity(0.5), 
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper to wrap sections in styled cards
  Widget _buildSectionWrapper({required Widget child, String? title}) {
    return Container(
      margin: kCardMargin,
      decoration: kDarkCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) 
            Padding(
              padding: EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 8.0),
              child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          child,
        ],
      )
    );
  }


  Widget _buildPatientInfoCard(BuildContext context, Map<String, dynamic> patientData) {
    return Container(
      key: Key('patientInfoCard'), // Added Key for testing
      margin: kCardMargin,
      decoration: kDarkCardDecoration,
      child: Padding(
        padding: kCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildPatientPhoto(context, patientData['photoUrl']),
            SizedBox(height: 16),
            _buildPatientDetails(context, patientData),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientPhoto(BuildContext context, String? photoUrl) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.8), width: 3), 
        image: photoUrl != null ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) : null,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3), 
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: photoUrl == null 
          ? Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[800], 
              ),
              child: Icon(Icons.person, size: 80, color: Colors.white70),
            )
          : null, 
    );
  }

  Widget _buildPatientDetails(BuildContext context, Map<String, dynamic> patientData) {
    TextStyle nameStyle = TextStyle(
      fontSize: 26, 
      fontWeight: FontWeight.bold,
      color: Colors.white, 
    );
    TextStyle ageStyle = TextStyle(
      fontSize: 20,
      color: Colors.white.withOpacity(0.85), 
    );
    TextStyle contactStyle = TextStyle(
      fontSize: 18, 
      color: Colors.white.withOpacity(0.85),
    );
    TextStyle titleStyle = TextStyle( 
      fontSize: 16,
      fontWeight: FontWeight.w600, 
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.9), 
    );
    TextStyle subtitleStyle = TextStyle( 
      fontSize: 16, 
      color: Colors.white,
    );

    bool hadConsultation = patientData['hadConsultation'] == true;
    var paymentsData = patientData['payments'] as List<dynamic>? ?? [];
    List<Payment> payments = paymentsData.map((p) => Payment.fromMap(p)).toList();
    double totalPaid = payments.fold(0, (sum, payment) => sum + payment.amount);

    bool waitingList = patientData['waitingList'] == true;
    bool secondStage = patientData['secondStage'] == true;
    bool hotPatient = patientData['hotPatient'] == true;

    return Column(
      children: [
        Text('${patientData['surname']} ${patientData['name']}', style: nameStyle, textAlign: TextAlign.center),
        SizedBox(height: 4),
        Text('${patientData['age']} лет', style: ageStyle, textAlign: TextAlign.center),
        SizedBox(height: 8),
        Text('${patientData['city'] ?? 'Город не указан'} | ${patientData['phone'] ?? 'Телефон не указан'}', style: contactStyle, textAlign: TextAlign.center),
        Divider(color: Colors.white.withOpacity(0.2), height: 32),
        _buildDetailRow('Цена:', '${priceFormatter.format(patientData['price'] ?? 0)} ₽', titleStyle, subtitleStyle),
        _buildDetailRow('Оплачено:', '${priceFormatter.format(totalPaid)} ₽', titleStyle, subtitleStyle),
        _buildDetailRow('Осталось:', '${priceFormatter.format((patientData['price'] ?? 0) - totalPaid)} ₽', titleStyle, subtitleStyle),
        _buildDetailRow('Консультация:', hadConsultation ? 'Да' : 'Нет', titleStyle, subtitleStyle),
        Divider(color: Colors.white.withOpacity(0.2), height: 32),
        _buildToggleRow('Список ожидания', waitingList, (value) { _updatePatientField('waitingList', value); }, titleStyle),
        _buildToggleRow('Второй этап', secondStage, (value) { _updatePatientField('secondStage', value); }, titleStyle),
        _buildToggleRow('Горящий пациент', hotPatient, (value) { _updatePatientField('hotPatient', value); }, titleStyle),
      ],
    );
  }

  Widget _buildDetailRow(String title, String value, TextStyle titleStyle, TextStyle subtitleStyle) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.0), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: titleStyle),
          Text(value, style: subtitleStyle),
        ],
      ),
    );
  }

  Widget _buildPaymentsHistory(BuildContext context, Map<String, dynamic> patientData) {
    var paymentsData = patientData['payments'] as List<dynamic>? ?? [];
    List<Payment> payments = paymentsData.map((p) => Payment.fromMap(p)).toList();

    return ExpansionTile(
      iconColor: Colors.white70,
      collapsedIconColor: Colors.white54,
      textColor: Colors.white,
      collapsedTextColor: Colors.white70,
      childrenPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      // Title is now part of _buildSectionWrapper, so we adjust the content here
      // We can use a dummy title or just the trailing IconButton for actions
      title: Row(
        mainAxisAlignment: MainAxisAlignment.end, // Align action button to the right
        children: [
          IconButton(
            icon: Icon(Icons.add_card_outlined, color: Theme.of(context).colorScheme.primary), // Changed icon
            tooltip: 'Добавить платёж',
            onPressed: () => _showAddPaymentDialog(context),
          ),
        ],
      ),
      subtitle: payments.isEmpty ? null : Text("Всего платежей: ${payments.length}", style: TextStyle(color: Colors.white70, fontSize: 12)),
      initiallyExpanded: false,
      children: payments.isEmpty 
      ? [Padding(padding: EdgeInsets.all(16.0), child: Center(child:Text("Платежей не найдено", style: TextStyle(color: Colors.white70))))]
      : payments.map((payment) => ListTile(
        title: Text('${priceFormatter.format(payment.amount)} ₽', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        subtitle: Text(DateFormat('dd MMMM yyyy, HH:mm', 'ru_RU').format(payment.date), style: TextStyle(color: Colors.white70)),
        leading: Icon(Icons.receipt_long_outlined, color: Colors.greenAccent.withOpacity(0.8)), // Changed icon
        dense: true,
      )).toList(),
    );
  }

  void _showAddPaymentDialog(BuildContext context) {
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) { 
        return StatefulBuilder(
          builder: (stfContext, setStateDialog) { 
            return AlertDialog(
              backgroundColor: Color(0xFF303030), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0), side: BorderSide(color: Colors.white.withOpacity(0.2))),
              title: Text('Добавить платёж', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              contentTextStyle: TextStyle(color: Colors.white70),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    style: TextStyle(color: Colors.white),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Сумма', 
                      labelStyle: TextStyle(color: Colors.white70),
                      prefixText: "₽ ",
                      prefixStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white38), borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary), borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Дата: ${DateFormat('dd.MM.yyyy HH:mm').format(selectedDate)}', style: TextStyle(color: Colors.white)),
                    trailing: Icon(Icons.calendar_today_outlined, color: Colors.white70),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: dialogContext, 
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(Duration(days: 365)), 
                        builder: (pickerContext, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: Theme.of(context).colorScheme.primary,
                                onPrimary: Colors.white,
                                surface: Color(0xFF303030),
                                onSurface: Colors.white,
                              ),
                              dialogBackgroundColor: Color(0xFF303030),
                              textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary))
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedDate != null) {
                         TimeOfDay? pickedTime = await showTimePicker(
                            context: dialogContext,
                            initialTime: TimeOfDay.fromDateTime(selectedDate),
                             builder: (pickerContext, child) {
                              return Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: ColorScheme.dark(
                                    primary: Theme.of(context).colorScheme.primary,
                                    onPrimary: Colors.white,
                                    surface: Color(0xFF303030),
                                    onSurface: Colors.white,
                                  ),
                                  dialogBackgroundColor: Color(0xFF303030),
                                ), child: child!);
                             });
                        if (pickedTime != null) {
                           setStateDialog(() { 
                            selectedDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Отмена', style: TextStyle(color: Colors.white70)),
                  onPressed: () => Navigator.of(dialogContext).pop(), 
                ),
                ElevatedButton(
                  child: Text('Сохранить'),
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () async {
                    double amount = double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0;
                    if (amount > 0) {
                      await FirebaseFirestore.instance
                        .collection('patients')
                        .doc(widget.patientId)
                        .update({
                          'payments': FieldValue.arrayUnion([
                            Payment(amount: amount, date: selectedDate).toMap()
                          ])
                        });
                      Navigator.of(dialogContext).pop(); 
                    } else {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text("Сумма должна быть больше нуля."), backgroundColor: Colors.orangeAccent));
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildTreatmentSchemas(String patientId) {
    return FutureBuilder<Map<String, int>>(
      future: _getTreatmentCounts(patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Theme(data: ThemeData.dark(), child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)));
        }
        if (snapshot.hasError) {
          return Padding(padding: kCardPadding, child: Text('Ошибка загрузки схем: ${snapshot.error}', style: TextStyle(color: Colors.redAccent)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildSectionWrapper(
            title: "Схемы лечения",
            child: Padding(padding: kCardPadding, child: Center(child:Text('Нет данных о схемах лечения', style: TextStyle(color: Colors.white70)))),
          );
        }

        var sortedTreatments = snapshot.data!.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        List<Widget> schemaRows = [];
        for (int i = 0; i < sortedTreatments.length; i += 2) {
          Widget rowChild1 = Expanded(child: _buildTreatmentSchema(patientId, sortedTreatments[i].key, _getColor(sortedTreatments[i].key)));
          Widget rowChild2 = (i + 1 < sortedTreatments.length) 
                            ? Expanded(child: _buildTreatmentSchema(patientId, sortedTreatments[i+1].key, _getColor(sortedTreatments[i+1].key)))
                            : Expanded(child: SizedBox.shrink()); 
          schemaRows.add(Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0), 
            child: Row(children: [rowChild1, SizedBox(width: 8), rowChild2]),
          ));
          if (i + 2 < sortedTreatments.length) { 
             schemaRows.add(SizedBox(height: 8));
          }
        }
        
        return _buildSectionWrapper(
          title: "Схемы лечения",
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0, top: 8.0), 
            child: Column(children: schemaRows),
          )
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
          return Padding(padding:kCardPadding, child: Text('Ошибка: ${snapshot.error}', style: TextStyle(color: Colors.redAccent)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(height: 150, child: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary.withOpacity(0.5))));
        }

        List<int> treatedTeeth = [];
        snapshot.data!.docs.forEach((doc) {
          var data = doc.data() as Map<String, dynamic>;
          if (data['toothNumber'] is List) { 
            treatedTeeth.addAll(List<int>.from(data['toothNumber']));
          }
        });

        Color textColorOnTreatment = color.computeLuminance() > 0.4 ? Colors.black87 : Colors.white;

        return Card(
          color: Color(0xFF333333), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0), side: BorderSide(color: Colors.white.withOpacity(0.15))),
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 6.0),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.25), 
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    treatmentType,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color, 
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 12),
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
                    physics: NeverScrollableScrollPhysics(), 
                    itemBuilder: (context, index) {
                      int toothNumber = _getToothNumber(index);
                      bool isTreated = treatedTeeth.contains(toothNumber);
                      return Container(
                        decoration: BoxDecoration(
                          color: isTreated ? color : Colors.white.withOpacity(0.1), 
                          shape: BoxShape.circle,
                           border: isTreated ? null : Border.all(color: Colors.white.withOpacity(0.2), width: 0.5)
                        ),
                        child: Center(
                          child: Text(
                            toothNumber.toString(),
                            style: TextStyle(
                              color: isTreated ? textColorOnTreatment : Colors.white70, 
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
      'Кариес': 0, 'Имплантация': 0, 'Удаление': 0, 'Сканирование': 0,
      'Эндо': 0, 'Формирователь': 0, 'PMMA': 0, 'Коронка': 0, 'Абатмент': 0,
      'Сдача PMMA': 0, 'Сдача коронка': 0, 'Сдача абатмент': 0, 'Удаление импланта': 0
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
    treatmentCounts.removeWhere((key, value) => value == 0);
    return treatmentCounts;
  }

  Color _getColor(String treatmentType) { 
    final colors = {
      'Кариес': Colors.red.shade400, 'Имплантация': Colors.blue.shade400,
      'Удаление': Colors.orange.shade400, 'Сканирование': Colors.purple.shade400,
      'Эндо': Colors.green.shade400,'Формирователь': Colors.teal.shade400,
      'PMMA': Colors.amber.shade600, 'Коронка': Colors.indigo.shade400,
      'Абатмент': Colors.pink.shade300, 'Сдача PMMA': Colors.cyan.shade400,
      'Сдача коронка': Colors.deepPurple.shade400, 'Сдача абатмент': Colors.lightGreen.shade500,
      'Удаление импланта': Colors.deepOrange.shade400,
    };
    return colors[treatmentType] ?? Colors.grey.shade500; 
  }

  int _getToothNumber(int index) {
    if (index < 16) {
      return index < 8 ? 18 - index : 21 + (index - 8);
    } else {
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
          return Center(child: Theme(data: ThemeData.dark(), child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)));
        }
        if (treatmentSnapshot.hasError) {
          return Padding(padding: kCardPadding, child: Text('Ошибка: ${treatmentSnapshot.error}', style: TextStyle(color: Colors.redAccent)));
        }
        if (!treatmentSnapshot.hasData || treatmentSnapshot.data!.docs.isEmpty) {
          return Padding(
            padding: kCardPadding,
            child: Center(child:Text('Нет данных о лечении', style: TextStyle(color: Colors.white70))),
          );
        }

        var treatments = _groupTreatmentsByDate(treatmentSnapshot.data!.docs);

        return ExpansionTileTheme( 
          data: ExpansionTileThemeData(
            iconColor: Colors.white70,
            collapsedIconColor: Colors.white54,
            textColor: Colors.white,
            collapsedTextColor: Colors.white70,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: treatments.keys.length,
            itemBuilder: (context, index) {
              DateTime date = treatments.keys.elementAt(index);
              var treatmentInfos = treatments[date]!;
              return ExpansionTile(
                 title: Text(
                    DateFormat('dd MMMM yyyy', 'ru_RU').format(date) + 
                    " (${treatmentInfos.length} ${treatmentInfos.length == 1 ? 'запись' : (treatmentInfos.length < 5 ? 'записи' : 'записей')})",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)
                ),
                childrenPadding: EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
                children: treatmentInfos.map((treatmentInfo) {
                  return Card( // Wrap ListTile in a Card for better separation
                    color: Colors.white.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    margin: EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      title: Text(treatmentInfo.treatmentType, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      subtitle: Text('Зубы: ${treatmentInfo.toothNumbers.join(", ")}', style: TextStyle(color: Colors.white70)),
                      leading: Icon(_getIconForTreatment(treatmentInfo.treatmentType), color: _getColor(treatmentInfo.treatmentType).withOpacity(0.8), size: 28),
                      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AddTreatmentScreen(patientId: patientId, treatmentData: treatmentInfo.toMap()),
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Adjusted padding
                      dense: true,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        );
      },
    );
  }

  IconData _getIconForTreatment(String treatmentType) {
    switch (treatmentType) {
      case 'Кариес': return Icons.coronavirus_outlined; 
      case 'Имплантация': return Icons.settings_system_daydream_outlined; 
      case 'Удаление': return Icons.delete_sweep_outlined; 
      case 'Сканирование': return Icons.qr_code_scanner_outlined;
      case 'Эндо': return Icons.healing_outlined; 
      case 'Формирователь': return Icons.trip_origin_outlined; 
      case 'PMMA': return Icons.layers_outlined; 
      case 'Коронка': return Icons.star_outline; 
      case 'Абатмент': return Icons.widgets_outlined;
      case 'Сдача PMMA': return Icons.check_circle_outline;
      case 'Сдача коронка': return Icons.verified_outlined;
      case 'Сдача абатмент': return Icons.done_all_outlined;
      case 'Удаление импланта': return Icons.remove_circle_outline;
      default: return Icons.medical_services_outlined;
    }
  }


  Widget _buildAdditionalPhotosSection(BuildContext context, Map<String, dynamic> patientData) {
    List<dynamic> additionalPhotos = patientData['additionalPhotos'] ?? [];
    
    return Container(
      margin: kCardMargin,
      padding: kCardPadding,
      decoration: kDarkCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Дополнительные фото', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ElevatedButton.icon(
                icon: Icon(Icons.add_a_photo_outlined, size: 18),
                label: Text('Добавить'),
                onPressed: () => _addAdditionalPhoto(context), 
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.8), 
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (additionalPhotos.isEmpty)
            Center(child: Text('Нет дополнительных фотографий', style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)))
          else
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 3, 
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: additionalPhotos.length,
              itemBuilder: (context, index) {
                var photo = additionalPhotos[index];
                return GestureDetector(
                  onTap: () => _showImageDialog(context, photo as Map<String,dynamic>), 
                  child: ClipRRect( 
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.white.withOpacity(0.1), width: 1)),
                      child: Image.network(
                        photo['url'],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)));
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[850], child: Icon(Icons.broken_image_outlined, color: Colors.white38, size: 40)
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, Map<String, dynamic> photo) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Color(0xFF303030).withOpacity(0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0), side: BorderSide(color: Colors.white.withOpacity(0.2))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(12.0), topRight: Radius.circular(12.0)),
                child: Image.network(
                  photo['url'], 
                  fit: BoxFit.contain, 
                  errorBuilder: (context, error, stackTrace) => Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Icon(Icons.broken_image_outlined, size: 100, color: Colors.white70),
                  )
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(photo['description'] ?? 'Нет описания', style: TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0, right: 12.0),
                child: Text(
                  photo['dateAdded'] != null ? DateFormat('dd.MM.yyyy HH:mm', 'ru_RU').format((photo['dateAdded'] as Timestamp).toDate()) : 'Нет даты', 
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addAdditionalPhoto(BuildContext context) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80); 
    
    if (image != null) {
      File imageFile = File(image.path);
      String fileName = 'additional_${DateTime.now().millisecondsSinceEpoch}.${image.name.split('.').last}'; 
      
      try {
        TaskSnapshot uploadTask = await FirebaseStorage.instance
            .ref('patients/${widget.patientId}/$fileName')
            .putFile(imageFile);
        
        String imageUrl = await uploadTask.ref.getDownloadURL();
        
        String? description = await _showDescriptionDialog(context);

        await FirebaseFirestore.instance.collection('patients').doc(widget.patientId).update({
          'additionalPhotos': FieldValue.arrayUnion([
            {
              'url': imageUrl,
              'description': description ?? 'Дополнительное фото', 
              'dateAdded': Timestamp.now(),
            }
          ]),
        });
      } catch (e) {
        print('Error uploading additional photo: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка загрузки фото: $e'), backgroundColor: Colors.redAccent)
          );
        }
      }
    }
  }

  Future<String?> _showDescriptionDialog(BuildContext context) async {
    TextEditingController descriptionController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Color(0xFF303030),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0), side: BorderSide(color: Colors.white.withOpacity(0.2))),
          title: Text('Описание фото', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: descriptionController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Введите описание...',
              hintStyle: TextStyle(color: Colors.white70),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white38), borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary), borderRadius: BorderRadius.circular(8)),
            ),
            maxLines: 3,
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Отмена', style: TextStyle(color: Colors.white70)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: Text('Сохранить'),
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () {
                Navigator.of(dialogContext).pop(descriptionController.text.trim());
              },
            ),
          ],
        );
      },
    );
  }


  Widget _buildPlannedTreatmentSection(BuildContext context) {
    return Container(
      margin: kCardMargin,
      padding: kCardPadding,
      decoration: kDarkCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Планируемое лечение:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 12),
          TextField(
            controller: _plannedTreatmentController,
            style: TextStyle(color: Colors.white, fontSize: 15, height: 1.4), 
            decoration: InputDecoration(
              hintText: "Записи о планируемом лечении...",
              hintStyle: TextStyle(color: Colors.white54),
              fillColor: Colors.white.withOpacity(0.05),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.white38)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.white38.withOpacity(0.5))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            readOnly: true, 
            maxLines: null, 
            minLines: 3,   
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end, 
            children: [
              TextButton.icon( 
                icon: Icon(Icons.clear_all_outlined, size: 18),
                label: Text('Очистить'),
                onPressed: () {
                  _plannedTreatmentController.clear();
                  _savePlannedTreatment('');
                },
                style: TextButton.styleFrom(foregroundColor: Colors.white70, textStyle: TextStyle(fontSize: 14)),
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                icon: Icon(Icons.add_circle_outline_outlined, size: 18),
                label: Text('Добавить'),
                onPressed: () => _navigateAndDisplaySelection(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.8), 
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
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

    if (result != null && result is String && result.isNotEmpty) {
      String currentText = _plannedTreatmentController.text;
      if (currentText.isNotEmpty && !currentText.endsWith('\n')) {
        _plannedTreatmentController.text += '\n' + result;
      } else {
         _plannedTreatmentController.text += result;
      }
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
    if (mounted) { 
      _plannedTreatmentController.text = treatment;
    }
  }

  void _confirmDeletion(BuildContext context, String patientId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Color(0xFF303030),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0), side: BorderSide(color: Colors.white.withOpacity(0.2))),
          title: Text('Удалить пациента', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text('Вы уверены, что хотите удалить этого пациента? Это действие необратимо.', style: TextStyle(color: Colors.white70)),
          actions: <Widget>[
            TextButton(
              child: Text('Отмена', style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton( 
              child: Text('Удалить'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.shade200, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () {
                FirebaseFirestore.instance.collection('patients').doc(patientId).delete().then((_) {
                  Navigator.of(dialogContext).pop(); 
                  if (mounted) { 
                    Navigator.of(context).popUntil((route) => route.isFirst); 
                  }
                }).catchError((error) {
                   Navigator.of(dialogContext).pop();
                   if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Ошибка удаления: $error'), backgroundColor: Colors.redAccent)
                     );
                   }
                });
              },
            ),
          ],
        );
      },
    );
  }

  Map<DateTime, List<TreatmentInfo>> _groupTreatmentsByDate(
      List<DocumentSnapshot> docs) {
    Map<DateTime, List<TreatmentInfo>> groupedTreatments = {};

    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      var timestamp = data['date'] as Timestamp?; 
      if (timestamp == null) continue; 

      var dateWithoutTime = DateTime(timestamp.toDate().year, timestamp.toDate().month, timestamp.toDate().day);
      var treatmentType = data['treatmentType'] as String?; 
      if (treatmentType == null) continue; 

      var toothNumbers = data['toothNumber'] != null && data['toothNumber'] is List
          ? List<int>.from(data['toothNumber'])
          : <int>[];
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
        groupedTreatments[dateWithoutTime]!
            .add(TreatmentInfo(treatmentType, toothNumbers, documentId, dateWithoutTime));
      }
    }
    var sortedKeys = groupedTreatments.keys.toList()..sort((a,b) => b.compareTo(a));
    Map<DateTime, List<TreatmentInfo>> sortedGroupedTreatments = {};
    for (var key in sortedKeys) {
      sortedGroupedTreatments[key] = groupedTreatments[key]!;
    }
    return sortedGroupedTreatments;
  }
}

class TreatmentInfo {
  String treatmentType;
  List<int> toothNumbers;
  String? id;
  DateTime date;

  TreatmentInfo(this.treatmentType, this.toothNumbers, this.id, this.date);

  Map<String, dynamic> toMap() {
    return {
      'treatmentType': treatmentType,
      'toothNumbers': toothNumbers,
      'id': id,
      'date': Timestamp.fromDate(date),
    };
  }
}

class TreatmentSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<String> treatments = [
      '1 сегмент', '2 сегмент', '3 сегмент', '4 сегмент',
      'Имплантация', 'Коронки', 'Лечение', 'Удаление',
      'Консультация', 'Осмотр', 'Снятие швов', 'Профгигиена', 'Другое' 
    ];

    return Scaffold(
      backgroundColor: Color(0xFF202020), 
      appBar: AppBar(
        title: Text('Выбор лечения', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF2A2A2A), 
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        itemCount: treatments.length,
        itemBuilder: (context, index) {
          return Card(
            color: Color(0xFF2A2A2A),
            margin: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0), side: BorderSide(color: Colors.white.withOpacity(0.15))),
            child: ListTile(
              title: Text(treatments[index], style: TextStyle(color: Colors.white)),
              trailing: Icon(Icons.add_circle_outline_outlined, color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
              onTap: () {
                Navigator.pop(context, treatments[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
