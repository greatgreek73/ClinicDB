import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'patient_details_screen.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:intl/intl.dart';
import 'payment.dart';
import 'design_system/design_system_screen.dart' show NeoCard, NeoButton, NeoTextField, DesignTokens;

class AddPatientScreen extends StatefulWidget {
  @override
  _AddPatientScreenState createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final MoneyMaskedTextController _priceController = MoneyMaskedTextController(decimalSeparator: '', thousandSeparator: '.', precision: 0, leftSymbol: '');
  final MoneyMaskedTextController _paidController = MoneyMaskedTextController(decimalSeparator: '', thousandSeparator: '.', precision: 0, leftSymbol: '');
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final MaskedTextController _phoneController = MaskedTextController(mask: '(000) 000-00-00');
  bool _isMale = true;
  File? _image;
  bool _hadConsultation = false;
  DateTime _paymentDate = DateTime.now();

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

  Future<void> _addPatientToFirestore() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String surname = _surnameController.text.trim();
    surname = surname[0].toUpperCase() + surname.substring(1);
    String name = _nameController.text.trim();
    name = name[0].toUpperCase() + name.substring(1);

    final int age = int.parse(_ageController.text);
    final double price = _priceController.numberValue;
    final double paid = _paidController.numberValue;
    final String city = _cityController.text;
    final String phone = _phoneController.text;
    final String gender = _isMale ? 'Мужской' : 'Женский';

    final querySnapshot = await FirebaseFirestore.instance
      .collection('patients')
      .where('surname', isEqualTo: surname)
      .where('name', isEqualTo: name)
      .get();

    if (querySnapshot.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Пациент с такой фамилией и именем уже существует.'),
        ),
      );
      return;
    }

    String? imageUrl;
    if (_image != null) {
      imageUrl = await _uploadImageToStorage(_image!);
    }

    FirebaseFirestore.instance.collection('patients').add({
      'surname': surname,
      'age': age,
      'price': price,
      'name': name,
      'city': city,
      'phone': phone,
      'gender': gender,
      'searchKey': surname.toLowerCase(),
      'photoUrl': imageUrl,
      'hadConsultation': _hadConsultation,
      'payments': [
        Payment(amount: paid, date: _paymentDate).toMap()
      ],
    }).then((result) {
      print('Пациент добавлен');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PatientDetailsScreen(patientId: result.id),
        ),
      );
    }).catchError((error) {
      print('Ошибка добавления пациента: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    const double formWidth = 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить пациента'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: formWidth),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.s20),
            child: NeoCard(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Заголовок формы
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Карточка пациента',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.s20),

                      // ФИО/Возраст/Город/Телефон
                      _section(
                        context,
                        title: 'Основная информация',
                        child: Column(
                          children: [
                            NeoTextField(
                              label: 'Фамилия',
                              controller: _surnameController,
                              hintText: 'Введите фамилию',
                            ),
                            const SizedBox(height: DesignTokens.s10),
                            NeoTextField(
                              label: 'Имя',
                              controller: _nameController,
                              hintText: 'Введите имя',
                            ),
                            const SizedBox(height: DesignTokens.s10),
                            NeoTextField(
                              label: 'Возраст',
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              hintText: 'Например: 34',
                            ),
                            const SizedBox(height: DesignTokens.s10),
                            NeoTextField(
                              label: 'Город',
                              controller: _cityController,
                              hintText: 'Введите город',
                            ),
                            const SizedBox(height: DesignTokens.s10),
                            NeoTextField(
                              label: 'Телефон',
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              hintText: '(000) 000-00-00',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: DesignTokens.s20),

                      // Пол и Фото
                      _section(
                        context,
                        title: 'Дополнительно',
                        child: Column(
                          children: [
                            _genderSelector(context),
                            const SizedBox(height: DesignTokens.s15),
                            _imageSection(context),
                          ],
                        ),
                      ),

                      const SizedBox(height: DesignTokens.s20),

                      // Стоимость и платеж
                      _section(
                        context,
                        title: 'Финансы',
                        child: Column(
                          children: [
                            NeoTextField(
                              label: 'Цена',
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              hintText: 'Сумма лечения',
                            ),
                            const SizedBox(height: DesignTokens.s10),
                            NeoTextField(
                              label: 'Первый платеж',
                              controller: _paidController,
                              keyboardType: TextInputType.number,
                              hintText: 'Внесённая сумма',
                            ),
                            const SizedBox(height: DesignTokens.s10),
                            _datePicker(context),
                          ],
                        ),
                      ),

                      const SizedBox(height: DesignTokens.s20),

                      // Флаг консультации
                      _section(
                        context,
                        title: 'Статус',
                        child: _consultationCheckbox(context),
                      ),

                      const SizedBox(height: DesignTokens.s20),

                      // Кнопка сохранения
                      Row(
                        children: [
                          Expanded(
                            child: NeoButton(
                              label: 'Сохранить',
                              primary: true,
                              onPressed: _addPatientToFirestore,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Раздел формы с заголовком внутри NeoCard
  Widget _section(BuildContext context, {required String title, required Widget child}) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: DesignTokens.s10),
        NeoCard.inset(child: Padding(padding: const EdgeInsets.all(12), child: child)),
      ],
    );
  }

  Widget _genderSelector(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: NeoCard.inset(
            child: InkWell(
              onTap: () => setState(() => _isMale = true),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'Мужской',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: _isMale ? DesignTokens.accentPrimary : DesignTokens.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.s10),
        Expanded(
          child: NeoCard.inset(
            child: InkWell(
              onTap: () => setState(() => _isMale = false),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'Женский',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: !_isMale ? DesignTokens.accentPrimary : DesignTokens.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _imageSection(BuildContext context) {
    return Column(
      children: [
        if (_image != null)
          NeoCard.inset(
            child: SizedBox(
              width: 100,
              height: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, fit: BoxFit.cover),
              ),
            ),
          ),
        const SizedBox(height: DesignTokens.s10),
        Row(
          children: [
            Expanded(
              child: NeoButton(
                label: 'Выбрать фотографию',
                onPressed: _pickImage,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _consultationCheckbox(BuildContext context) {
    return Row(
      children: [
        NeoCard.inset(
          child: Checkbox(
            value: _hadConsultation,
            onChanged: (bool? value) {
              setState(() {
                _hadConsultation = value ?? false;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Text('Был на консультации', style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }

  Widget _datePicker(BuildContext context) {
    return NeoCard.inset(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: const Text("Дата платежа"),
        subtitle: Text(DateFormat('yyyy-MM-dd').format(_paymentDate)),
        trailing: const Icon(Icons.calendar_today),
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: _paymentDate,
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            setState(() {
              _paymentDate = picked;
            });
          }
        },
      ),
    );
  }
}
