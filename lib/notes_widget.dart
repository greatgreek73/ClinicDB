import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotesWidget extends StatefulWidget {
  final String patientId;

  NotesWidget({required this.patientId});

  @override
  _NotesWidgetState createState() => _NotesWidgetState();
}

class _NotesWidgetState extends State<NotesWidget> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _loadNotes() {
    FirebaseFirestore.instance
        .collection('patients')
        .doc(widget.patientId)
        .get()
        .then((doc) {
      if (doc.exists) {
        setState(() {
          _notesController.text = doc.data()?['notes'] ?? '';
        });
      }
    });
  }

  void _saveNotes() {
    FirebaseFirestore.instance
        .collection('patients')
        .doc(widget.patientId)
        .update({'notes': _notesController.text}).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Примечания сохранены')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Примечания', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Введите примечания здесь...',
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _saveNotes,
              child: Text('Сохранить примечания'),
            ),
          ],
        ),
      ),
    );
  }
}