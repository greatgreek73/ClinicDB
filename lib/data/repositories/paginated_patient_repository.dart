import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/patient.dart';

/// Repository for paginated patient queries
class PaginatedPatientRepository {
  final FirebaseFirestore _db;
  static const int _pageSize = 20; // Number of items per page

  PaginatedPatientRepository(this._db);

  /// Get paginated patients
  /// [lastDocument] - The last document from the previous page for pagination
  /// [filterType] - Optional filter field name
  /// [filterValue] - Optional filter value
  /// [searchQuery] - Optional search query for patient names
  Future<PaginatedResult<Patient>> getPaginatedPatients({
    DocumentSnapshot? lastDocument,
    String? filterType,
    dynamic filterValue,
    String? searchQuery,
  }) async {
    Query query = _db.collection('patients');

    // Apply filters
    if (filterType != null && filterValue != null) {
      query = query.where(filterType, isEqualTo: filterValue);
    }

    // Apply search query if provided
    if (searchQuery != null && searchQuery.isNotEmpty) {
      // Firestore doesn't support full-text search, so we use a workaround
      // Search by name prefix (case-insensitive would require additional setup)
      query = query
          .where('lastName', isGreaterThanOrEqualTo: searchQuery)
          .where('lastName', isLessThan: searchQuery + '\uf8ff');
    }

    // Order by creation date or ID for consistent pagination
    query = query.orderBy('lastName').orderBy('firstName');

    // Apply pagination
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(_pageSize);

    final snapshot = await query.get();
    
    final patients = snapshot.docs
        .map((doc) => Patient.fromJson(doc.id, doc.data() as Map<String, dynamic>))
        .toList();

    return PaginatedResult(
      items: patients,
      hasMore: snapshot.docs.length == _pageSize,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  /// Get paginated patients with price range filter
  Future<PaginatedResult<Patient>> getPaginatedPatientsWithPriceRange({
    DocumentSnapshot? lastDocument,
    double minPrice,
    double maxPrice,
  }) async {
    Query query = _db.collection('patients')
        .where('price', isGreaterThanOrEqualTo: minPrice)
        .where('price', isLessThanOrEqualTo: maxPrice)
        .orderBy('price')
        .orderBy('lastName');

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(_pageSize);

    final snapshot = await query.get();
    
    final patients = snapshot.docs
        .map((doc) => Patient.fromJson(doc.id, doc.data() as Map<String, dynamic>))
        .toList();

    return PaginatedResult(
      items: patients,
      hasMore: snapshot.docs.length == _pageSize,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }
}

/// Result class for paginated queries
class PaginatedResult<T> {
  final List<T> items;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;

  PaginatedResult({
    required this.items,
    required this.hasMore,
    this.lastDocument,
  });
}