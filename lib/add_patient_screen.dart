import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'patient_details_screen.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class AddPatientScreen extends StatefulWidget {
  @override
  _AddPatientScreenState createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final MoneyMaskedTextController _priceController = MoneyMaskedTextController(decimalSeparator: '', thousandSeparator: '.', precision: 0, leftSymbol: '');
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final MaskedTextController _phoneController = MaskedTextController(mask: '(000) 000-0000');
  bool _isMale = true;
  File? _image;

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
    double fieldWidth = MediaQuery.of(context).size.width * 0.8;
    Color labelColor = Color(0xFFFFC947);

    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить Пациента', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              _buildFieldWithPadding(_buildTextFormField(_surnameController, 'Фамилия', labelColor), fieldWidth),
              _buildFieldWithPadding(_buildTextFormField(_ageController, 'Возраст', labelColor, isNumber: true), fieldWidth),
              _buildFieldWithPadding(_buildPriceFormField(_priceController, 'Цена', labelColor), fieldWidth),
              _buildFieldWithPadding(_buildTextFormField(_nameController, 'Имя', labelColor), fieldWidth),
              _buildFieldWithPadding(_buildTextFormField(_cityController, 'Город', labelColor), fieldWidth),
              _buildFieldWithPadding(_buildPhoneFormField(labelColor), fieldWidth),
              SizedBox(height: 40),
              _buildGenderRow(Color(0xFF0F5BF1)),
              SizedBox(height: 40),
              _buildImageSection(),
              SizedBox(height: 40),
              _buildSaveButton(Color(0xFF0F5BF1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldWithPadding(Widget field, double width) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: SizedBox(width: width, child: field),
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String label, Color labelColor, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: labelColor),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Пожалуйста, введите $label';
        }
        return null;
      },
    );
  }

  Widget _buildPriceFormField(MoneyMaskedTextController controller, String label, Color labelColor) {
    return _buildTextFormField(controller, label, labelColor, isNumber: true);
  }

  Widget _buildPhoneFormField(Color labelColor) {
    return _buildTextFormField(_phoneController, 'Телефон', labelColor);
  }

  Widget _buildGenderRow(Color customColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        GestureDetector(
          onTap: () => setState(() => _isMale = true),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
            decoration: BoxDecoration(
              color: _isMale ? customColor : Colors.grey,
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
              color: !_isMale ? customColor : Colors.grey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('Женский', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        if (_image != null)
          SizedBox(
            width: 40,  // Ограничение размера изображения
            height: 40, // Ограничение размера изображения
            child: Image.file(_image!, fit: BoxFit.cover),
          ),
        ElevatedButton(
          onPressed: _pickImage,
          child: Text('Выбрать фотографию', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(primary: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildSaveButton(Color customColor) {
    return ElevatedButton(
      onPressed: _addPatientToFirestore,
      child: Text('Сохранить', style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        primary: customColor,
      ),
    );
  }
}
