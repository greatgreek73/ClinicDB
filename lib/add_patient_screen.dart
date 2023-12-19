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
  final TextEditingController _priceController = TextEditingController();
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

    final String surname = _surnameController.text;
    final int age = int.parse(_ageController.text);
    final double price = double.parse(_priceController.text);
    final String name = _nameController.text;
    final String city = _cityController.text;
    final String phone = _phoneController.text;
    final String gender = _isMale ? 'Мужской' : 'Женский';

    // Проверка на существование пациента с такой же фамилией и именем
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
              _buildTextFormField(_surnameController, 'Фамилия'),
              _buildTextFormField(_ageController, 'Возраст', isNumber: true),
              _buildTextFormField(_priceController, 'Цена', isNumber: true),
              _buildTextFormField(_nameController, 'Имя'),
              _buildTextFormField(_cityController, 'Город'),
              _buildPhoneFormField(),
              _buildGenderRow(),
              _buildImageSection(),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String label, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
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

  Widget _buildPhoneFormField() {
    return TextFormField(
      controller: _phoneController,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Телефон',
        labelStyle: TextStyle(color: Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
      keyboardType: TextInputType.phone,
      validator: (value) {
        if (value == null || value.isEmpty || !RegExp(r'\(\d{3}\) \d{3}-\d{4}').hasMatch(value)) {
          return 'Введите корректный номер телефона';
        }
        return null;
      },
    );
  }

  Widget _buildGenderRow() {
    return Row(
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
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        if (_image != null)
          SizedBox(
            width: 200,
            height: 200,
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

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _addPatientToFirestore,
      child: Text('Сохранить', style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(primary: Colors.grey),
    );
  }
}
