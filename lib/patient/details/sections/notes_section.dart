import 'package:flutter/material.dart';
import '../../../design_system/design_system_screen.dart' show NeoCard, DesignTokens;
import '../../../notes_widget.dart';

class NotesSection extends StatefulWidget {
  final Map<String, dynamic> patientData;
  final String patientId;
  final int selectedIndex;

  const NotesSection({
    Key? key,
    required this.patientData,
    required this.patientId,
    required this.selectedIndex,
  }) : super(key: key);

  @override
  _NotesSectionState createState() => _NotesSectionState();
}

class _NotesSectionState extends State<NotesSection> with AutomaticKeepAliveClientMixin<NotesSection> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    // Only build the NotesWidget when this section is visible (selectedIndex == 5)
    final isVisible = widget.selectedIndex == 5;
    if (!isVisible) {
      return Container(
        key: ValueKey<int>(5),
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Container(
      key: ValueKey<int>(5),
      padding: const EdgeInsets.all(20),
      child: NeoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📝', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text('Заметки о пациенте', style: DesignTokens.h3),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: NotesWidget(patientId: widget.patientId),
            ),
          ],
        ),
      ),
    );
  }
}