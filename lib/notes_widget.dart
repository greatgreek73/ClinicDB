import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'design_system/design_system_screen.dart' show NeoCard, NeoButton, DesignTokens;

class NotesWidget extends StatefulWidget {
  final String patientId;

  const NotesWidget({super.key, required this.patientId});

  @override
  _NotesWidgetState createState() => _NotesWidgetState();
}

class _NotesWidgetState extends State<NotesWidget> {
  final TextEditingController _notesController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _notesController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _notesController.removeListener(_onTextChanged);
    _notesController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _loadNotes() {
    setState(() {
      _isLoading = true;
    });

    FirebaseFirestore.instance
        .collection('patients')
        .doc(widget.patientId)
        .get()
        .then((doc) {
      if (doc.exists && mounted) {
        setState(() {
          _notesController.text = doc.data()?['notes'] ?? '';
          _isLoading = false;
          _hasChanges = false;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Ошибка при загрузке заметок: $error');
      }
    });
  }

  void _saveNotes() {
    if (!_hasChanges) return;

    setState(() {
      _isLoading = true;
    });

    FirebaseFirestore.instance
        .collection('patients')
        .doc(widget.patientId)
        .update({'notes': _notesController.text}).then((_) {
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
          _hasChanges = false;
        });
        _showSuccessSnackBar('Заметки сохранены');
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Ошибка при сохранении: $error');
      }
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _hasChanges = false;
    });
    _loadNotes(); // Перезагружаем исходный текст
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: DesignTokens.accentSuccess,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: DesignTokens.accentDanger,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _notesController.text.isEmpty) {
      return const Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Column(
      children: [
        // Область для заметок
        NeoCard.inset(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isEditing ? _buildEditingView() : _buildReadonlyView(),
          ),
        ),

        const SizedBox(height: 16),

        // Кнопки управления
        _buildControlButtons(),
      ],
    );
  }

  Widget _buildReadonlyView() {
    final notesText = _notesController.text.trim();
    
    if (notesText.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.note_add_outlined,
              size: 48,
              color: DesignTokens.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'Нет заметок о пациенте',
              style: DesignTokens.body.copyWith(
                color: DesignTokens.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Нажмите "Добавить заметку" чтобы начать',
              style: DesignTokens.small.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Иконка и индикатор
          Row(
            children: [
              Icon(
                Icons.sticky_note_2,
                size: 20,
                color: DesignTokens.accentPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Заметки о пациенте',
                style: DesignTokens.small.copyWith(
                  color: DesignTokens.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Текст заметок
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignTokens.background.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: DesignTokens.shadowDark.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Text(
              notesText,
              style: DesignTokens.body.copyWith(
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditingView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок редактирования
        Row(
          children: [
            Icon(
              Icons.edit,
              size: 20,
              color: DesignTokens.accentPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              'Редактирование заметок',
              style: DesignTokens.small.copyWith(
                color: DesignTokens.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (_hasChanges)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DesignTokens.accentWarning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Не сохранено',
                  style: DesignTokens.small.copyWith(
                    color: DesignTokens.accentWarning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Поле ввода
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hasChanges 
                  ? DesignTokens.accentPrimary.withOpacity(0.3)
                  : DesignTokens.shadowDark.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 8,
            minLines: 4,
            style: DesignTokens.body,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              hintText: 'Введите заметки о пациенте...\n\nМожете указать:\n• Особенности лечения\n• Предпочтения пациента\n• Аллергии или противопоказания\n• Важные замечания',
              hintStyle: DesignTokens.body.copyWith(
                color: DesignTokens.textMuted,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    if (_isEditing) {
      return Row(
        children: [
          Expanded(
            child: NeoButton(
              label: 'Отмена',
              onPressed: _isLoading ? null : _cancelEditing,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: NeoButton(
              label: _isLoading ? 'Сохранение...' : 'Сохранить',
              primary: true,
              onPressed: (_isLoading || !_hasChanges) ? null : _saveNotes,
            ),
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: NeoButton(
          label: _notesController.text.trim().isEmpty 
              ? 'Добавить заметку' 
              : 'Редактировать заметки',
          primary: true,
          onPressed: _isLoading ? null : () {
            setState(() {
              _isEditing = true;
            });
          },
        ),
      );
    }
  }
}
