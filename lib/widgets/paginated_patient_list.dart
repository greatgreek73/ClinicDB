import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/repositories/paginated_patient_repository.dart';
import '../domain/models/patient.dart';
import '../patient/details/patient_details_screen.dart';

/// A widget that displays a paginated list of patients
class PaginatedPatientList extends StatefulWidget {
  final String? filterType;
  final dynamic filterValue;
  final String? searchQuery;
  final double? minPrice;
  final double? maxPrice;

  const PaginatedPatientList({
    Key? key,
    this.filterType,
    this.filterValue,
    this.searchQuery,
    this.minPrice,
    this.maxPrice,
  }) : super(key: key);

  @override
  State<PaginatedPatientList> createState() => _PaginatedPatientListState();
}

class _PaginatedPatientListState extends State<PaginatedPatientList> {
  final _repository = PaginatedPatientRepository(FirebaseFirestore.instance);
  final _scrollController = ScrollController();
  
  List<Patient> _patients = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMorePatients();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // Load more when user scrolls to 80% of the list
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMorePatients();
    }
  }

  Future<void> _loadMorePatients() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      PaginatedResult<Patient> result;
      
      if (widget.minPrice != null && widget.maxPrice != null) {
        result = await _repository.getPaginatedPatientsWithPriceRange(
          lastDocument: _lastDocument,
          minPrice: widget.minPrice!,
          maxPrice: widget.maxPrice!,
        );
      } else {
        result = await _repository.getPaginatedPatients(
          lastDocument: _lastDocument,
          filterType: widget.filterType,
          filterValue: widget.filterValue,
          searchQuery: widget.searchQuery,
        );
      }

      if (mounted) {
        setState(() {
          _patients.addAll(result.items);
          _hasMore = result.hasMore;
          _lastDocument = result.lastDocument;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка загрузки: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _patients.clear();
      _hasMore = true;
      _lastDocument = null;
      _error = null;
    });
    await _loadMorePatients();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _refresh,
              child: Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_patients.isEmpty && _isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_patients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Пациенты не найдены',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        // Performance optimizations
        itemExtent: 80.0, // Fixed height for better performance
        cacheExtent: 500.0, // Cache content outside visible area
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _patients.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Show loading indicator at the bottom
          if (index == _patients.length) {
            return Container(
              height: 80,
              alignment: Alignment.center,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : TextButton(
                      onPressed: _loadMorePatients,
                      child: Text('Загрузить ещё'),
                    ),
            );
          }

          final patient = _patients[index];
          return _buildPatientTile(patient);
        },
      ),
    );
  }

  Widget _buildPatientTile(Patient patient) {
    // Determine avatar
    Widget avatar;
    if (patient.photoUrl != null && patient.photoUrl!.isNotEmpty) {
      avatar = CircleAvatar(
        radius: 25,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: patient.photoUrl!,
            fit: BoxFit.cover,
            width: 50,
            height: 50,
            placeholder: (context, url) => CircularProgressIndicator(strokeWidth: 2),
            errorWidget: (context, url, error) => Icon(
              patient.gender == 'Мужской' ? Icons.person : Icons.person_outline,
              color: Colors.grey.shade700,
            ),
            // Performance optimizations
            memCacheHeight: 100,
            memCacheWidth: 100,
            fadeInDuration: const Duration(milliseconds: 150),
          ),
        ),
      );
    } else {
      avatar = CircleAvatar(
        backgroundColor: Colors.grey.shade300,
        child: Icon(
          patient.gender == 'Мужской' ? Icons.person : Icons.person_outline,
          color: Colors.grey.shade700,
          size: 30,
        ),
        radius: 25,
      );
    }

    return ListTile(
      leading: avatar,
      title: Text(
        '${patient.lastName} ${patient.firstName}',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'Возраст: ${patient.age ?? "Не указан"}',
        style: TextStyle(color: Colors.grey),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientDetailsScreen(
              patientId: patient.id,
              patientData: patient.toJson(),
            ),
          ),
        );
      },
    );
  }
}