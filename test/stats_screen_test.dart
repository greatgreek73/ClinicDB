import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('Stats Screen Filter Logic Tests', () {
    test('Filter identifies patients with single implant correctly', () {
      // Test data structure
      final testTreatments = [
        // Patient 1: Has exactly 1 treatment, type is Имплантация, 1 tooth
        {
          'patientId': 'patient1',
          'treatmentType': 'Имплантация',
          'toothNumber': [15],
        },
        // Patient 2: Has exactly 1 treatment, type is Имплантация, but 2 teeth (should not count)
        {
          'patientId': 'patient2',
          'treatmentType': 'Имплантация',
          'toothNumber': [15, 16],
        },
        // Patient 3: Has exactly 1 treatment, but type is not Имплантация (should not count)
        {
          'patientId': 'patient3',
          'treatmentType': 'Лечение',
          'toothNumber': [20],
        },
        // Patient 4: Has 2 treatments (should not count)
        {
          'patientId': 'patient4',
          'treatmentType': 'Имплантация',
          'toothNumber': [25],
        },
        {
          'patientId': 'patient4',
          'treatmentType': 'Лечение',
          'toothNumber': [26],
        },
        // Patient 5: Has exactly 1 treatment, type is Имплантация, 1 tooth (should count)
        {
          'patientId': 'patient5',
          'treatmentType': 'Имплантация',
          'toothNumber': [30],
        },
      ];

      // Simulate the filtering logic
      final Map<String, List<Map<String, dynamic>>> byPatient = {};
      
      for (final treatment in testTreatments) {
        final patientId = treatment['patientId'] as String;
        (byPatient[patientId] ??= <Map<String, dynamic>>[]).add(treatment);
      }
      
      int count = 0;
      final List<String> qualifyingPatients = [];
      
      for (final entry in byPatient.entries) {
        final patientId = entry.key;
        final docs = entry.value;
        
        // Must have exactly 1 treatment document
        if (docs.length != 1) continue;
        
        final data = docs.first;
        
        // Treatment type must be "Имплантация"
        if (data['treatmentType'] != 'Имплантация') continue;
        
        // Parse toothNumber list and check it has exactly 1 element
        final toothNumbers = (data['toothNumber'] as List?)
            ?.map((x) => x is int ? x : int.tryParse(x.toString()))
            .whereType<int>()
            .toList() ?? const <int>[];
        
        if (toothNumbers.length == 1) {
          count++;
          qualifyingPatients.add(patientId);
        }
      }
      
      // Assertions
      expect(count, equals(2), reason: 'Should find exactly 2 patients with single implant');
      expect(qualifyingPatients, contains('patient1'));
      expect(qualifyingPatients, contains('patient5'));
      expect(qualifyingPatients, isNot(contains('patient2')), reason: 'Patient2 has 2 teeth');
      expect(qualifyingPatients, isNot(contains('patient3')), reason: 'Patient3 has wrong treatment type');
      expect(qualifyingPatients, isNot(contains('patient4')), reason: 'Patient4 has 2 treatments');
    });

    test('Handle edge cases correctly', () {
      // Test with various edge cases
      final edgeCases = [
        // Empty toothNumber array
        {
          'patientId': 'edge1',
          'treatmentType': 'Имплантация',
          'toothNumber': [],
        },
        // Null toothNumber
        {
          'patientId': 'edge2',
          'treatmentType': 'Имплантация',
          'toothNumber': null,
        },
        // toothNumber with string values that can be parsed
        {
          'patientId': 'edge3',
          'treatmentType': 'Имплантация',
          'toothNumber': ['15'],
        },
        // Mixed types in toothNumber
        {
          'patientId': 'edge4',
          'treatmentType': 'Имплантация',
          'toothNumber': [15, '16', null],
        },
      ];

      for (final testCase in edgeCases) {
        final toothNumbers = (testCase['toothNumber'] as List?)
            ?.map((x) => x is int ? x : int.tryParse(x.toString() ?? ''))
            .whereType<int>()
            .toList() ?? const <int>[];
        
        if (testCase['patientId'] == 'edge1') {
          expect(toothNumbers.length, equals(0), reason: 'Empty array should result in 0 teeth');
        } else if (testCase['patientId'] == 'edge2') {
          expect(toothNumbers.length, equals(0), reason: 'Null should result in 0 teeth');
        } else if (testCase['patientId'] == 'edge3') {
          expect(toothNumbers.length, equals(1), reason: 'String "15" should parse to 1 tooth');
          expect(toothNumbers.first, equals(15));
        } else if (testCase['patientId'] == 'edge4') {
          expect(toothNumbers.length, equals(2), reason: 'Should parse 2 valid integers from mixed array');
        }
      }
    });
  });
}