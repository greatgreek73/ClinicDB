import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'payment.dart';

class EditPatientScreen extends StatefulWidget {
  final String patientId;

  EditPatientScreen({required this.patientId});

  @override
  _EditPatientScreenState createState() => _EditPatientScreenState();
}

class _EditPatientScreenState extends State<EditPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isMale = true;
  File? _image;
  bool _hadConsultation = false;
  bool _waitingList = false;
  bool _secondStage = false;
  bool _hotPatient = false;
  List<Payment> _payments = [];

  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _ageController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImageToStorage(File imageFile) async {
    try {
      String fileName = 'patients/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      UploadTask uploadTask = FirebaseStorage.instance.ref().child(fileName).putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Ошибка при загрузке изображения: $e");
      return null;
    }
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DocumentSnapshot patientSnapshot = await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .get();

      Map<String, dynamic> patientData = patientSnapshot.data() as Map<String, dynamic>;

      _nameController.text = patientData['name'];
      _surnameController.text = patientData['surname'];
      _ageController.text = patientData['age'].toString();
      _cityController.text = patientData['city'];
      _phoneController.text = patientData['phone'];
      _priceController.text = patientData['price'].toString();
      _isMale = patientData['gender'] == 'Мужской';
      _hadConsultation = patientData['hadConsultation'] ?? false;
      _waitingList = patientData['waitingList'] ?? false;
      _secondStage = patientData['secondStage'] ?? false;
      _hotPatient = patientData['hotPatient'] ?? false;

      var paymentsData = patientData['payments'] as List<dynamic>? ?? [];
      _payments = paymentsData.map((p) => Payment.fromMap(p)).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? imageUrl;
    if (_image != null) {
      imageUrl = await _uploadImageToStorage(_image!);
    }

    try {
      String updatedSearchKey = _surnameController.text.toLowerCase();
      Map<String, dynamic> updateData = {
        'name': _nameController.text,
        'surname': _surnameController.text,
        'age': int.parse(_ageController.text),
        'city': _cityController.text,
        'phone': _phoneController.text,
        'price': double.parse(_priceController.text),
        'searchKey': updatedSearchKey,
        'gender': _isMale ? 'Мужской' : 'Женский',
        'hadConsultation': _hadConsultation,
        'waitingList': _waitingList,
        'secondStage': _secondStage,
        'hotPatient': _hotPatient,
        'payments': _payments.map((p) => p.toMap()).toList(),
      };

      if (imageUrl != null) {
        updateData['photoUrl'] = imageUrl;
      }

      await FirebaseFirestore.instance.collection('patients').doc(widget.patientId).update(updateData);

      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Ошибка сохранения пациента: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Редактировать Пациента'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Имя'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Пожалуйста, введите имя';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _surnameController,
                      decoration: InputDecoration(labelText: 'Фамилия'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Пожалуйста, введите фамилию';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _ageController,
                      decoration: InputDecoration(labelText: 'Возраст'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Пожалуйста, введите возраст';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(labelText: 'Город'),
                    ),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(labelText: 'Телефон'),
                    ),
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(labelText: 'Цена'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Пожалуйста, введите цену';
                        }
                        return null;
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        GestureDetector(
                          onTap: () => setState(() => _isMale = true),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                            decoration: BoxDecoration(
                              color: _isMale ? Colors.blue : Colors.grey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('Мужской', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        SizedBox(width: 20),
                        GestureDetector(
                          onTap: () => setState(() => _isMale = false),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                            decoration: BoxDecoration(
                              color: !_isMale ? Colors.pink : Colors.grey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('Женский', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    if (_image != null)
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: Image.file(
                          _image!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: Text('Выбрать фотографию'),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Checkbox(
                          value: _hadConsultation,
                          onChanged: (bool? value) {
                            setState(() {
                              _hadConsultation = value ?? false;
                            });
                          },
                        ),
                        Text('Был на консультации'),
                      ],
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: _waitingList,
                          onChanged: (bool? value) {
                            setState(() {
                              _waitingList = value ?? false;
                            });
                          },
                        ),
                        Text('Список ожидания'),
                      ],
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: _secondStage,
                          onChanged: (bool? value) {
                            setState(() {
                              _secondStage = value ?? false;
                            });
                          },
                        ),
                        Text('Второй этап'),
                      ],
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: _hotPatient,
                          onChanged: (bool? value) {
                            setState(() {
                              _hotPatient = value ?? false;
                            });
                          },
                        ),
                        Text('Горящий пациент'),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text('Платежи', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    _buildPaymentsList(),
                    ElevatedButton(
                      onPressed: _addNewPayment,
                      child: Text('Добавить платеж'),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _savePatient,
                      child: Text('Сохранить изменения'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPaymentsList() {
    return Column(
      children: _payments.map((payment) => ListTile(
        title: Text('${NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 2).format(payment.amount)}'),
        subtitle: Text(DateFormat('yyyy-MM-dd').format(payment.date)),
        trailing: IconButton(
          icon: Icon(Icons.edit),
          onPressed: () => _editPayment(payment),
        ),
      )).toList(),
    );
  }

  void _addNewPayment() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) => PaymentDialog(),
    );

    if (result != null) {
      setState(() {
        _payments.add(Payment(amount: result['amount'], date: result['date']));
      });
    }
  }

  void _editPayment(Payment payment) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) => PaymentDialog(initialPayment: payment),
    );

    if (result != null) {
      setState(() {
        int index = _payments.indexOf(payment);
        _payments[index] = Payment(amount: result['amount'], date: result['date']);
      });
    }
  }
}

class PaymentDialog extends StatefulWidget {
  final Payment? initialPayment;

  PaymentDialog({this.initialPayment});

  @override
  _PaymentDialogState createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  late TextEditingController _amountController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.initialPayment?.amount.toString() ?? '');
    _selectedDate = widget.initialPayment?.date ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialPayment == null ? 'Добавить платеж' : 'Редактировать платеж'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amountController,
            decoration: InputDecoration(labelText: 'Сумма'),
            keyboardType: TextInputType.number,
          ),
          ListTile(
            title: Text("Дата платежа"),
            subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
            trailing: Icon(Icons.calendar_today),
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text('Отмена'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text('Сохранить'),
          onPressed: () {
            Navigator.of(context).pop({
              'amount': double.parse(_amountController.text),
              'date': _selectedDate,
            });
          },
        ),
      ],
    );
  }
}
