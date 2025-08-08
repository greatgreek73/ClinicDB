import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../design_system/design_system_screen.dart' show NeoCard, NeoButton, DesignTokens;
import '../patient_details_screen.dart';

class PatientsStatsSection extends StatefulWidget {
  final Map<String, dynamic> patientData;
  final String patientId;
  final int selectedIndex;

  const PatientsStatsSection({
    Key? key,
    required this.patientData,
    required this.patientId,
    required this.selectedIndex,
  }) : super(key: key);

  @override
  _PatientsStatsSectionState createState() => _PatientsStatsSectionState();
}

class _PatientsStatsSectionState extends State<PatientsStatsSection> {
  bool _isExpanded = false;
  List<Map<String, dynamic>> _singleImplantPatients = [];
  bool _isLoading = false;

  Future<void> _loadSingleImplantPatientsWithTimeout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadSingleImplantPatients().timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Превышено время ожидания (12 сек). Попробуйте снова.'),
                action: SnackBarAction(
                  label: 'Повторить',
                  onPressed: () => _loadSingleImplantPatientsWithTimeout(),
                ),
              ),
            );
          }
          throw Exception('Timeout');
        },
      );
    } catch (e) {
      print('Ошибка при загрузке пациентов с одним имплантом: $e');
      if (mounted && e.toString() != 'Exception: Timeout') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Повторить',
              onPressed: () => _loadSingleImplantPatientsWithTimeout(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSingleImplantPatients() async {
    // Получаем все лечения с типом "Имплантация"
    final treatmentsSnapshot = await FirebaseFirestore.instance
        .collection('treatments')
        .where('treatmentType', isEqualTo: 'Имплантация')
        .get();

    // Группируем по patientId и собираем уникальные зубы
    Map<String, Set<int>> patientImplants = {};
    
    for (var doc in treatmentsSnapshot.docs) {
      final data = doc.data();
      final patientId = data['patientId'] as String?;
      final toothNumber = data['toothNumber'];
      
      if (patientId != null && toothNumber != null) {
        if (patientImplants[patientId] == null) {
          patientImplants[patientId] = <int>{};
        }
        
        if (toothNumber is int) {
          patientImplants[patientId]!.add(toothNumber);
        } else if (toothNumber is List) {
          for (var tooth in toothNumber) {
            if (tooth is int) {
              patientImplants[patientId]!.add(tooth);
            }
          }
        }
      }
    }

    // Фильтруем пациентов с ровно одним уникальным зубом
    List<String> singleImplantPatientIds = [];
    for (var entry in patientImplants.entries) {
      if (entry.value.length == 1) {
        singleImplantPatientIds.add(entry.key);
      }
    }

    // Получаем данные пациентов батчами по 10
    List<Map<String, dynamic>> patientsData = [];
    
    for (int i = 0; i < singleImplantPatientIds.length; i += 10) {
      final batch = singleImplantPatientIds.skip(i).take(10).toList();
      
      if (batch.isNotEmpty) {
        final patientsSnapshot = await FirebaseFirestore.instance
            .collection('patients')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var doc in patientsSnapshot.docs) {
          final data = doc.data();
          patientsData.add({
            'id': doc.id,
            'name': data['name'] ?? '',
            'surname': data['surname'] ?? '',
            'fullName': '${data['surname'] ?? ''} ${data['name'] ?? ''}'.trim(),
          });
        }
      }
    }

    // Сортируем по фамилии
    patientsData.sort((a, b) => a['fullName'].compareTo(b['fullName']));

    if (mounted) {
      setState(() {
        _singleImplantPatients = patientsData;
        _isExpanded = true;
      });
    }
  }

  void _navigateToPatient(String patientId) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PatientDetailsScreen(patientId: patientId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<int>(6),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Верхняя карточка с кнопкой
          NeoCard(
            child: Column(
              children: [
                Text(
                  'Статистика пациентов',
                  style: DesignTokens.h3,
                ),
                const SizedBox(height: 20),
                NeoButton(
                  label: 'Один имплант',
                  onPressed: _isLoading ? null : () {
                    if (!_isExpanded) {
                      _loadSingleImplantPatientsWithTimeout();
                    } else {
                      setState(() {
                        _isExpanded = false;
                        _singleImplantPatients.clear();
                      });
                    }
                  },
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          
          // Список пациентов
          if (_isExpanded && _singleImplantPatients.isNotEmpty) ...[
            const SizedBox(height: 20),
            Expanded(
              child: NeoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Пациенты с одним имплантом (${_singleImplantPatients.length})',
                      style: DesignTokens.h4,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _singleImplantPatients.length,
                        itemBuilder: (context, index) {
                          final patient = _singleImplantPatients[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => _navigateToPatient(patient['id']),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: DesignTokens.background.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: DesignTokens.accentPrimary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Center(
                                          child: Text(
                                            patient['fullName'].isNotEmpty 
                                                ? patient['fullName'][0].toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: DesignTokens.accentPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          patient['fullName'],
                                          style: DesignTokens.body.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: DesignTokens.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (_isExpanded && _singleImplantPatients.isEmpty && !_isLoading) ...[
            const SizedBox(height: 20),
            NeoCard(
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 48,
                    color: DesignTokens.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Пациенты с одним имплантом не найдены',
                    style: DesignTokens.h4.copyWith(
                      color: DesignTokens.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}