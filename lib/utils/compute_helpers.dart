import 'package:flutter/foundation.dart';
import '../domain/models/patient.dart';
import '../domain/models/treatment.dart';
import '../domain/models/treatment_counts.dart';
import '../domain/models/treatment_type.dart';

/// Helper functions for compute operations
/// These functions must be top-level or static to work with compute()

/// Filter patients based on criteria in a background isolate
Future<List<Patient>> filterPatientsCompute(FilterPatientsParams params) {
  return compute(_filterPatientsIsolate, params);
}

/// Count treatments by type in a background isolate
Future<TreatmentCounts> countTreatmentsCompute(CountTreatmentsParams params) {
  return compute(_countTreatmentsIsolate, params);
}

/// Count patients with exactly one implant in a background isolate
Future<int> countOneImplantPatientsCompute(List<Treatment> treatments) {
  return compute(_countOneImplantPatientsIsolate, treatments);
}

/// Parameters for filtering patients
class FilterPatientsParams {
  final List<Patient> patients;
  final String? searchQuery;
  final double? minPrice;
  final double? maxPrice;
  final bool? hasImplant;
  final String? gender;

  FilterPatientsParams({
    required this.patients,
    this.searchQuery,
    this.minPrice,
    this.maxPrice,
    this.hasImplant,
    this.gender,
  });

  FilterPatientsParams copyWith({
    List<Patient>? patients,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    bool? hasImplant,
    String? gender,
  }) {
    return FilterPatientsParams(
      patients: patients ?? this.patients,
      searchQuery: searchQuery ?? this.searchQuery,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      hasImplant: hasImplant ?? this.hasImplant,
      gender: gender ?? this.gender,
    );
  }
}

/// Parameters for counting treatments
class CountTreatmentsParams {
  final List<Treatment> treatments;
  final Set<TreatmentType>? types;
  final DateTime? startDate;
  final DateTime? endDate;

  CountTreatmentsParams({
    required this.treatments,
    this.types,
    this.startDate,
    this.endDate,
  });
}

/// Isolate function for filtering patients
List<Patient> _filterPatientsIsolate(FilterPatientsParams params) {
  var filtered = params.patients;

  // Apply search query
  if (params.searchQuery != null && params.searchQuery!.isNotEmpty) {
    final query = params.searchQuery!.toLowerCase();
    filtered = filtered.where((patient) {
      final name = patient.name?.toLowerCase() ?? '';
      return name.contains(query);
    }).toList();
  }

  // Note: The current Patient model doesn't have price, gender, or hasImplant fields
  // These filters are commented out until the model is updated
  
  // Apply price filter
  // if (params.minPrice != null) {
  //   filtered = filtered.where((p) => p.price >= params.minPrice!).toList();
  // }
  // if (params.maxPrice != null) {
  //   filtered = filtered.where((p) => p.price <= params.maxPrice!).toList();
  // }

  // Apply gender filter
  // if (params.gender != null) {
  //   filtered = filtered.where((p) => p.gender == params.gender).toList();
  // }

  // Apply implant filter
  // if (params.hasImplant != null) {
  //   filtered = filtered.where((p) => p.hasImplant == params.hasImplant).toList();
  // }

  return filtered;
}

/// Isolate function for counting treatments
TreatmentCounts _countTreatmentsIsolate(CountTreatmentsParams params) {
  var treatments = params.treatments;

  // Apply date filter
  if (params.startDate != null) {
    treatments = treatments.where((t) => t.date != null && t.date!.isAfter(params.startDate!)).toList();
  }
  if (params.endDate != null) {
    treatments = treatments.where((t) => t.date != null && t.date!.isBefore(params.endDate!)).toList();
  }

  // Apply type filter
  if (params.types != null && params.types!.isNotEmpty) {
    treatments = treatments.where((t) => params.types!.contains(t.treatmentType)).toList();
  }

  // Count teeth by treatment type
  final items = treatments.map((t) => (
    type: t.treatmentType,
    teethCount: t.toothNumbers.length,
  ));

  return TreatmentCounts.fromIterable(items);
}

/// Isolate function for counting patients with exactly one implant
int _countOneImplantPatientsIsolate(List<Treatment> treatments) {
  final Map<String, int> perPatient = {};
  
  for (final treatment in treatments) {
    if (treatment.treatmentType == TreatmentType.implant) {
      final patientId = treatment.patientId;
      if (patientId != null && patientId.isNotEmpty) {
        final implantsCount = treatment.toothNumbers.length;
        perPatient.update(
          patientId,
          (v) => v + implantsCount,
          ifAbsent: () => implantsCount,
        );
      }
    }
  }
  
  return perPatient.values.where((v) => v == 1).length;
}

/// Helper to batch process large lists in chunks
Future<List<R>> batchProcess<T, R>({
  required List<T> items,
  required Future<R> Function(T item) processor,
  int batchSize = 10,
}) async {
  final results = <R>[];
  
  for (int i = 0; i < items.length; i += batchSize) {
    final end = (i + batchSize < items.length) ? i + batchSize : items.length;
    final batch = items.sublist(i, end);
    
    final futures = batch.map((item) => processor(item)).toList();
    final batchResults = await Future.wait(futures);
    results.addAll(batchResults);
  }
  
  return results;
}