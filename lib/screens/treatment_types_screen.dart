import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TreatmentTypesScreen extends StatefulWidget {
  const TreatmentTypesScreen({super.key});

  @override
  State<TreatmentTypesScreen> createState() => _TreatmentTypesScreenState();
}

class _TreatmentTypesScreenState extends State<TreatmentTypesScreen> {
  bool _loading = false;
  String? _error;
  List<_TypeItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snap = await FirebaseFirestore.instance.collection('treatments').get();
      final counts = <String, int>{};
      for (final doc in snap.docs) {
        final data = (doc.data() as Map<String, dynamic>? ) ?? const {};
        final dynamic raw = data['treatmentType'];
        final String? type = raw is String ? raw : raw?.toString();
        if (type == null || type.trim().isEmpty) continue;
        counts[type] = (counts[type] ?? 0) + 1;
      }
      final items = counts.entries
          .map((e) => _TypeItem(name: e.key, count: e.value))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      setState(() {
        _items = items;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Типы процедур'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Ошибка: $_error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _items.isEmpty
                  ? const Center(child: Text('Нет данных'))
                  : ListView.separated(
                      itemBuilder: (_, i) {
                        final it = _items[i];
                        return ListTile(
                          leading: const Icon(Icons.local_hospital_outlined),
                          title: Text(it.name),
                          trailing: Text('${it.count}'),
                        );
                      },
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemCount: _items.length,
                    ),
    );
  }
}

class _TypeItem {
  final String name;
  final int count;
  const _TypeItem({required this.name, required this.count});
}

