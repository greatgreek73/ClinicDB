import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/patient.dart';
import '../../domain/models/treatment_counts.dart';
import '../../domain/models/treatment_type.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../cache/memory_cache.dart';
import 'firebase_dashboard_repository.dart';

/// Cached implementation of DashboardRepository
/// Wraps FirebaseDashboardRepository with in-memory caching for better performance
class CachedDashboardRepository implements DashboardRepository {
  final FirebaseDashboardRepository _firebaseRepository;
  
  // Separate caches for different data types
  final _treatmentCountsCache = MemoryCache<String, TreatmentCounts>(
    defaultTTL: const Duration(minutes: 5),
    maxSize: 50,
  );
  
  final _patientCountCache = MemoryCache<String, int>(
    defaultTTL: const Duration(minutes: 5),
    maxSize: 20,
  );

  // Stream controllers for cached streams
  final Map<String, Stream<TreatmentCounts>> _treatmentCountStreams = {};
  final Map<String, Stream<int>> _patientCountStreams = {};
  Stream<List<Patient>>? _patientsStream;

  CachedDashboardRepository(FirebaseFirestore db) 
      : _firebaseRepository = FirebaseDashboardRepository(db);

  @override
  Stream<List<Patient>> watchPatients() {
    // Return cached stream if available
    _patientsStream ??= _firebaseRepository.watchPatients()
        .asBroadcastStream(); // Make it a broadcast stream for multiple listeners
    return _patientsStream!;
  }

  @override
  Future<TreatmentCounts> getTreatmentCounts({
    required DateTime startInclusive,
    required DateTime endInclusive,
    Set<TreatmentType>? types,
  }) {
    // Create cache key based on parameters
    final cacheKey = _buildTreatmentCountsCacheKey(
      startInclusive,
      endInclusive,
      types,
    );

    // Use cache's getOrCompute method
    return _treatmentCountsCache.getOrCompute(
      cacheKey,
      () => _firebaseRepository.getTreatmentCounts(
        startInclusive: startInclusive,
        endInclusive: endInclusive,
        types: types,
      ),
    );
  }

  @override
  Stream<int> watchOneImplantPatientsCountForCurrentMonth() {
    const cacheKey = 'one_implant_month';
    
    // Return cached stream if available
    if (!_patientCountStreams.containsKey(cacheKey)) {
      _patientCountStreams[cacheKey] = _firebaseRepository
          .watchOneImplantPatientsCountForCurrentMonth()
          .map((count) {
            // Cache the latest value
            _patientCountCache.set(cacheKey, count);
            return count;
          })
          .asBroadcastStream();
    }
    
    return _patientCountStreams[cacheKey]!;
  }

  @override
  Stream<int> watchOneImplantPatientsCountForCurrentYear() {
    const cacheKey = 'one_implant_year';
    
    // Return cached stream if available
    if (!_patientCountStreams.containsKey(cacheKey)) {
      _patientCountStreams[cacheKey] = _firebaseRepository
          .watchOneImplantPatientsCountForCurrentYear()
          .map((count) {
            // Cache the latest value
            _patientCountCache.set(cacheKey, count);
            return count;
          })
          .asBroadcastStream();
    }
    
    return _patientCountStreams[cacheKey]!;
  }

  @override
  Stream<TreatmentCounts> watchTreatmentCountsForCurrentMonth({
    Set<TreatmentType>? types,
  }) {
    final cacheKey = 'treatment_counts_month_${types?.join('_') ?? 'all'}';
    
    // Return cached stream if available
    if (!_treatmentCountStreams.containsKey(cacheKey)) {
      _treatmentCountStreams[cacheKey] = _firebaseRepository
          .watchTreatmentCountsForCurrentMonth(types: types)
          .map((counts) {
            // Cache the latest value
            _treatmentCountsCache.set(cacheKey, counts);
            return counts;
          })
          .asBroadcastStream();
    }
    
    return _treatmentCountStreams[cacheKey]!;
  }

  @override
  Stream<TreatmentCounts> watchTreatmentCountsForCurrentYear({
    Set<TreatmentType>? types,
  }) {
    final cacheKey = 'treatment_counts_year_${types?.join('_') ?? 'all'}';
    
    // Return cached stream if available
    if (!_treatmentCountStreams.containsKey(cacheKey)) {
      _treatmentCountStreams[cacheKey] = _firebaseRepository
          .watchTreatmentCountsForCurrentYear(types: types)
          .map((counts) {
            // Cache the latest value
            _treatmentCountsCache.set(cacheKey, counts);
            return counts;
          })
          .asBroadcastStream();
    }
    
    return _treatmentCountStreams[cacheKey]!;
  }

  /// Clear all caches - useful when data is updated
  void clearCache() {
    _treatmentCountsCache.clear();
    _patientCountCache.clear();
    _treatmentCountStreams.clear();
    _patientCountStreams.clear();
    _patientsStream = null;
  }

  /// Clear caches for a specific date range
  void clearCacheForDateRange(DateTime start, DateTime end) {
    // Clear treatment counts cache for entries that might overlap with the date range
    _treatmentCountsCache.clearWhere((key) => 
      key.contains(start.toIso8601String()) || 
      key.contains(end.toIso8601String())
    );
  }

  /// Dispose of resources
  void dispose() {
    _treatmentCountsCache.dispose();
    _patientCountCache.dispose();
  }

  String _buildTreatmentCountsCacheKey(
    DateTime start,
    DateTime end,
    Set<TreatmentType>? types,
  ) {
    final typesKey = types?.map((t) => t.name).join('_') ?? 'all';
    return 'counts_${start.toIso8601String()}_${end.toIso8601String()}_$typesKey';
  }
}