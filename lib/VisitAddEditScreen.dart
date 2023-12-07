import 'package:flutter/material.dart';
import 'package:clinicdb/visit_model.dart';
import 'package:clinicdb/visit_service.dart';
import 'package:intl/intl.dart';

class VisitAddEditScreen extends StatefulWidget {
  final Visit? visit;
  final String patientId;

  VisitAddEditScreen({this.visit, required this.patientId});

  @override
  _VisitAddEditScreenState createState() => _VisitAddEditScreenState();
}

class _VisitAddEditScreenState extends State<VisitAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  final VisitService _visitService = VisitService();

  @override
  void initState() {
    super.initState();
    if (widget.visit != null) {
      _descriptionController.text = widget.visit!.description;
      _selectedDate = widget.visit!.date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.visit == null ? 'Добавить Визит' : 'Редактировать Визит'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Описание'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите описание';
                  }
                  return null;
                },
              ),
              ListTile(
                title: Text(_selectedDate == null ? 'Выберите дату' : 'Дата: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _saveVisit();
                  }
                },
                child: Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveVisit() async {
    if (_selectedDate == null) {
      // Показать ошибку, если дата не выбрана
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Пожалуйста, выберите дату')));
      return;
    }
    Visit visit = Visit(
      id: widget.visit?.id,
      date: _selectedDate!,
      description: _descriptionController.text,
      patientId: widget.patientId,
    );
    if (widget.visit == null) {
      await _visitService.addVisit(visit);
    } else {
      await _visitService.updateVisit(widget.visit!.id, visit);
    }
    Navigator.of(context).pop();
  }
}
