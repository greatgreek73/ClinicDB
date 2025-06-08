import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme/app_theme.dart';

class NotesWidget extends StatefulWidget {
  final String patientId;
  final Color backgroundColor;
  final Color textColor;
  final Color buttonColor;
  final Color borderColor;
  final Color boxShadowColor;

  NotesWidget({
    Key? key,
    required this.patientId,
    this.backgroundColor = AppTheme.darkCardColor,
    this.textColor = AppTheme.darkPrimaryTextColor,
    this.buttonColor = AppTheme.primaryColor,
    this.borderColor = AppTheme.darkBorderColor,
    this.boxShadowColor = const Color(0x80000000),
  }) : super(key: key);

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
    return Container(
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: widget.borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: widget.boxShadowColor,
            blurRadius: 10,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Примечания',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.textColor,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 5,
              style: TextStyle(color: widget.textColor),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: widget.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: widget.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: widget.buttonColor),
                ),
                hintText: 'Введите примечания здесь...',
                hintStyle: TextStyle(color: widget.textColor.withOpacity(0.6)),
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.buttonColor,
                foregroundColor: widget.textColor,
              ),
              onPressed: _saveNotes,
              child: Text('Сохранить примечания'),
            ),
          ],
        ),
      ),
    );
  }
}