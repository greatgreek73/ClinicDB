import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'design_system/design_system_screen.dart' show NeoCard, NeoButton, DesignTokens;
import 'patient_details_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // Stream for counting patients with single implant
  Stream<int> _singleImplantOnlyCountStream() {
    return FirebaseFirestore.instance
        .collection('treatments')
        .snapshots()
        .map((snap) {
      final Map<String, List<QueryDocumentSnapshot>> byPatient = {};
      
      // Group treatments by patientId
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final patientId = data['patientId'] as String?;
        if (patientId == null) continue;
        
        (byPatient[patientId] ??= <QueryDocumentSnapshot>[]).add(doc);
      }
      
      int count = 0;
      
      // Check each patient's treatments
      for (final entry in byPatient.entries) {
        final docs = entry.value;
        
        // Must have exactly 1 treatment document
        if (docs.length != 1) continue;
        
        final data = docs.first.data() as Map<String, dynamic>;
        
        // Treatment type must be "Имплантация"
        if (data['treatmentType'] != 'Имплантация') continue;
        
        // Parse toothNumber list and check it has exactly 1 element
        final toothNumberRaw = data['toothNumber'];
        final toothNumbers = (toothNumberRaw as List?)
            ?.map((x) => x is int ? x : int.tryParse(x.toString()))
            .whereType<int>()
            .toList() ?? const <int>[];
        
        if (toothNumbers.length == 1) {
          count++;
        }
      }
      
      return count;
    });
  }

  // Load list of patients with single implant
  Future<List<Map<String, String>>> _loadSingleImplantOnlyPatients() async {
    try {
      // Get all treatments
      final treatmentsSnapshot = await FirebaseFirestore.instance
          .collection('treatments')
          .get();
      
      final Map<String, List<QueryDocumentSnapshot>> byPatient = {};
      
      // Group treatments by patientId
      for (final doc in treatmentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final patientId = data['patientId'] as String?;
        if (patientId == null) continue;
        
        (byPatient[patientId] ??= <QueryDocumentSnapshot>[]).add(doc);
      }
      
      final List<String> qualifyingPatientIds = [];
      
      // Find qualifying patients
      for (final entry in byPatient.entries) {
        final patientId = entry.key;
        final docs = entry.value;
        
        // Must have exactly 1 treatment document
        if (docs.length != 1) continue;
        
        final data = docs.first.data() as Map<String, dynamic>;
        
        // Treatment type must be "Имплантация"
        if (data['treatmentType'] != 'Имплантация') continue;
        
        // Parse toothNumber list and check it has exactly 1 element
        final toothNumberRaw = data['toothNumber'];
        final toothNumbers = (toothNumberRaw as List?)
            ?.map((x) => x is int ? x : int.tryParse(x.toString()))
            .whereType<int>()
            .toList() ?? const <int>[];
        
        if (toothNumbers.length == 1) {
          qualifyingPatientIds.add(patientId);
        }
      }
      
      // Load patient names for qualifying patients
      final List<Map<String, String>> patients = [];
      
      for (final patientId in qualifyingPatientIds) {
        final patientDoc = await FirebaseFirestore.instance
            .collection('patients')
            .doc(patientId)
            .get();
        
        if (patientDoc.exists) {
          final data = patientDoc.data() as Map<String, dynamic>;
          patients.add({
            'id': patientId,
            'surname': data['surname'] ?? '',
            'name': data['name'] ?? '',
          });
        }
      }
      
      // Sort by surname alphabetically
      patients.sort((a, b) => (a['surname'] ?? '').compareTo(b['surname'] ?? ''));
      
      return patients;
    } catch (e) {
      print('Error loading single implant patients: $e');
      return [];
    }
  }

  // Show patients list in bottom sheet
  void _showPatientsBottomSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FutureBuilder<List<Map<String, String>>>(
          future: _loadSingleImplantOnlyPatients(),
          builder: (context, snapshot) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Title
                  const Text(
                    'Пациенты с одной имплантацией',
                    style: DesignTokens.h3,
                  ),
                  const SizedBox(height: 16),
                  
                  // Content
                  Expanded(
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? const Center(child: CircularProgressIndicator())
                        : snapshot.hasError
                            ? Center(
                                child: Text(
                                  'Ошибка загрузки: ${snapshot.error}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              )
                            : snapshot.data?.isEmpty ?? true
                                ? const Center(
                                    child: Text(
                                      'Нет пациентов с одной имплантацией',
                                      style: DesignTokens.body,
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: snapshot.data!.length,
                                    itemBuilder: (context, index) {
                                      final patient = snapshot.data![index];
                                      return Card(
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                        elevation: 2,
                                        color: DesignTokens.surface,
                                        child: ListTile(
                                          title: Text(
                                            '${patient['surname']} ${patient['name']}',
                                            style: DesignTokens.body.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          trailing: const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          onTap: () {
                                            Navigator.pop(context); // Close bottom sheet
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => PatientDetailsScreen(
                                                  patientId: patient['id']!,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      appBar: AppBar(
        title: const Text('Статистика'),
        backgroundColor: DesignTokens.surface,
        elevation: 0,
        foregroundColor: DesignTokens.textPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Single Implantation Card
              NeoCard(
                child: StreamBuilder<int>(
                  stream: _singleImplantOnlyCountStream(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    final isLoading = snapshot.connectionState == ConnectionState.waiting;
                    
                    return InkWell(
                      onTap: isLoading ? null : () => _showPatientsBottomSheet(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: DesignTokens.accentPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: Icon(
                                Icons.medical_services_outlined,
                                size: 40,
                                color: DesignTokens.accentPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Title with count
                            isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(
                                    'Одна имплантация ($count)',
                                    style: DesignTokens.h3.copyWith(
                                      color: DesignTokens.textPrimary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                            
                            const SizedBox(height: 8),
                            
                            // Description
                            Text(
                              'Пациенты с единственной имплантацией на один зуб',
                              style: DesignTokens.small.copyWith(
                                color: DesignTokens.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Tap hint
                            if (!isLoading)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.touch_app,
                                    size: 16,
                                    color: DesignTokens.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Нажмите для просмотра списка',
                                    style: DesignTokens.small.copyWith(
                                      color: DesignTokens.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Placeholder for future statistics
              NeoCard(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.bar_chart,
                        size: 48,
                        color: DesignTokens.textSecondary.withOpacity(0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Дополнительная статистика',
                        style: DesignTokens.body.copyWith(
                          color: DesignTokens.textSecondary.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Будет добавлена в будущих обновлениях',
                        style: DesignTokens.small.copyWith(
                          color: DesignTokens.textSecondary.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}