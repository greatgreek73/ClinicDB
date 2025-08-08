import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import '../../../design_system/design_system_screen.dart' show DesignTokens;
import 'widgets/patient_header.dart';
import 'widgets/navigation_rail.dart';
import 'sections/overview_section.dart';
import 'sections/treatments_section.dart';
import 'sections/finance_section.dart';
import 'sections/statistics_section.dart';
import 'sections/documents_section.dart';
import 'sections/notes_section.dart';
import 'sections/patients_stats_section.dart';

class PatientDetailsScreen extends StatefulWidget {
  final String patientId;

  PatientDetailsScreen({required this.patientId});

  @override
  _PatientDetailsScreenState createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> with SingleTickerProviderStateMixin {
  // Текущий выбранный раздел
  int _selectedIndex = 0;
  
  // Контроллер анимации для плавных переходов
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Контроллер для планируемого лечения
  final TextEditingController _plannedTreatmentController = TextEditingController();

  // Статусы пациента
  bool _waitingList = false;
  bool _secondStage = false;
  bool _hotPatient = false;


  // Разделы навигации
  final List<NavigationSection> _sections = [
    NavigationSection(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Обзор', emoji: '📋'),
    NavigationSection(icon: Icons.medical_services_outlined, activeIcon: Icons.medical_services, label: 'Лечение', emoji: '🦷'),
    NavigationSection(icon: Icons.payments_outlined, activeIcon: Icons.payments, label: 'Финансы', emoji: '💰'),
    NavigationSection(icon: Icons.analytics_outlined, activeIcon: Icons.analytics, label: 'Статистика', emoji: '📊'),
    NavigationSection(icon: Icons.photo_library_outlined, activeIcon: Icons.photo_library, label: 'Документы', emoji: '📸'),
    NavigationSection(icon: Icons.note_alt_outlined, activeIcon: Icons.note_alt, label: 'Заметки', emoji: '📝'),
    NavigationSection(icon: Icons.groups_outlined, activeIcon: Icons.groups, label: 'Пациенты', emoji: '👥'),
  ];

  @override
  void initState() {
    super.initState();
    _loadPlannedTreatment();
    
    // Инициализация анимации
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _animationController.forward();
  }


  @override
  void dispose() {
    _plannedTreatmentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _updatePatientField(String field, dynamic value) async {
    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .update({field: value});
    } catch (e) {
      print('Ошибка при обновлении поля $field: $e');
    }
  }

  void _changeSection(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('patients')
              .doc(widget.patientId)
              .snapshots(),
          builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.active) {
              if (snapshot.hasData && snapshot.data?.data() != null) {
                final patientData = snapshot.data!.data() as Map<String, dynamic>;

                return Row(
                  children: [
                    // Боковая навигационная панель
                    PatientNavigationRail(
                      patientData: patientData,
                      selectedIndex: _selectedIndex,
                      sections: _sections,
                      onSectionChanged: _changeSection,
                    ),
                    
                    // Вертикальный разделитель
                    Container(
                      width: 1,
                      color: DesignTokens.shadowDark.withOpacity(0.1),
                    ),

                    // Основное содержимое
                    Expanded(
                      child: Column(
                        children: [
                          // Заголовок пациента
                          PatientHeader(
                            patientData: patientData,
                            patientId: widget.patientId,
                            selectedIndex: _selectedIndex,
                            onAddPayment: () => _showAddPaymentDialog(context, patientData),
                            onAddPhoto: _addAdditionalPhoto,
                          ),
                          
                          // Содержимое текущего раздела с IndexedStack для сохранения состояния
                          Expanded(
                            child: IndexedStack(
                              index: _selectedIndex,
                              children: [
                                // 0: Обзор - with current selectedIndex
                                OverviewSection(
                                  key: const ValueKey('overview'),
                                  patientData: patientData,
                                  patientId: widget.patientId,
                                  onUpdatePatientField: _updatePatientField,
                                  onChangeSection: _changeSection,
                                ),
                                // 1: Лечение - with current selectedIndex
                                TreatmentsSection(
                                  key: const ValueKey('treatments'),
                                  patientData: patientData,
                                  patientId: widget.patientId,
                                  selectedIndex: _selectedIndex,
                                ),
                                // 2: Финансы - with current selectedIndex
                                FinanceSection(
                                  key: const ValueKey('finance'),
                                  patientData: patientData,
                                  patientId: widget.patientId,
                                  selectedIndex: _selectedIndex,
                                ),
                                // 3: Статистика - with current selectedIndex
                                StatisticsSection(
                                  key: const ValueKey('statistics'),
                                  patientData: patientData,
                                  patientId: widget.patientId,
                                  selectedIndex: _selectedIndex,
                                ),
                                // 4: Документы - with current selectedIndex
                                DocumentsSection(
                                  key: const ValueKey('documents'),
                                  patientData: patientData,
                                  patientId: widget.patientId,
                                  selectedIndex: _selectedIndex,
                                ),
                                // 5: Заметки - with current selectedIndex
                                NotesSection(
                                  key: const ValueKey('notes'),
                                  patientData: patientData,
                                  patientId: widget.patientId,
                                  selectedIndex: _selectedIndex,
                                ),
                                // 6: Пациенты - with current selectedIndex
                                PatientsStatsSection(
                                  key: const ValueKey('patients_stats'),
                                  patientData: patientData,
                                  patientId: widget.patientId,
                                  selectedIndex: _selectedIndex,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return const Center(
                  child: Text('Пациент не найден'),
                );
              }
            }

            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }

  Future<void> _addAdditionalPhoto() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      File imageFile = File(image.path);
      String fileName = 'additional_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      try {
        TaskSnapshot uploadTask = await FirebaseStorage.instance
            .ref('patients/${widget.patientId}/$fileName')
            .putFile(imageFile);
        
        String downloadUrl = await uploadTask.ref.getDownloadURL();
        
        Map<String, dynamic> photoData = {
          'url': downloadUrl,
          'dateAdded': Timestamp.now(),
          'description': '', // Можно добавить диалог для описания
        };
        
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(widget.patientId)
            .update({
          'additionalPhotos': FieldValue.arrayUnion([photoData])
        });
      } catch (e) {
        print('Ошибка при загрузке фото: $e');
      }
    }
  }

  void _showAddPaymentDialog(BuildContext context, Map<String, dynamic> patientData) {
    // Здесь можно добавить диалог для добавления платежа
    // TODO: Реализовать диалог добавления платежа
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Функция добавления платежа будет добавлена')),
    );
  }

  Future<void> _savePlannedTreatment(String treatment) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('planned_treatment_${widget.patientId}', treatment);
  }

  Future<void> _loadPlannedTreatment() async {
    final prefs = await SharedPreferences.getInstance();
    String treatment = prefs.getString('planned_treatment_${widget.patientId}') ?? '';
    _plannedTreatmentController.text = treatment;
  }
}