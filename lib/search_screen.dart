import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'patient_details_screen.dart'; // Убедитесь, что этот импорт присутствует

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Поиск Пациентов'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Поиск...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      searchQuery = '';
                    });
                  },
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: (searchQuery == "")
                  ? FirebaseFirestore.instance
                      .collection('patients')
                      .orderBy('searchKey') // Сортировка по фамилии
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('patients')
                      .orderBy('searchKey')
                      .where('searchKey', isGreaterThanOrEqualTo: searchQuery)
                      .where('searchKey', isLessThan: searchQuery + '\uF8FF')
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var documents = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      var patient = documents[index].data() as Map<String, dynamic>;
                      var patientId = documents[index].id; // Получение ID пациента

                      // Определяем стиль и оформление по статусу
                      bool scheduled = patient['scheduledByAssistant'] == true;
                      bool ambiguous = patient['ambiguousSchedule'] == true;

                      Color cardColor = scheduled
                          ? Color(0xFFB9F6CA)
                          : ambiguous
                              ? Color(0xFFFFF3E0)
                              : Colors.white;
                      Color borderColor = scheduled
                          ? Colors.green.shade700
                          : ambiguous
                              ? Colors.orange.shade700
                              : Colors.grey.shade300;
                      double borderWidth = scheduled || ambiguous ? 3.0 : 1.0;

                      Widget? statusLabel = scheduled
                          ? Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade700,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.event_available, color: Colors.white, size: 18),
                                  SizedBox(width: 4),
                                  Text(
                                    'В расписании',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ambiguous
                              ? Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade700,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.warning, color: Colors.white, size: 18),
                                      SizedBox(width: 4),
                                      Text(
                                        'Требует проверки',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : null;

                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: scheduled ? 6 : ambiguous ? 4 : 2,
                        color: cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: borderColor,
                            width: borderWidth,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PatientDetailsScreen(patientId: patientId),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  scheduled
                                      ? Icons.event_available
                                      : ambiguous
                                          ? Icons.warning
                                          : Icons.person,
                                  color: scheduled
                                      ? Colors.green.shade700
                                      : ambiguous
                                          ? Colors.orange.shade700
                                          : Colors.grey.shade700,
                                  size: 32,
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${patient['surname'] ?? 'Нет фамилии'} ${patient['name'] ?? 'Нет имени'}',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: scheduled
                                                    ? Colors.green.shade900
                                                    : ambiguous
                                                        ? Colors.orange.shade900
                                                        : Colors.black,
                                              ),
                                            ),
                                          ),
                                          if (statusLabel != null) ...[
                                            SizedBox(width: 8),
                                            statusLabel,
                                          ],
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      if (patient['phone'] != null)
                                        Text(
                                          '${patient['phone']}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: scheduled
                                                ? Colors.green.shade900
                                                : ambiguous
                                                    ? Colors.orange.shade900
                                                    : Colors.grey.shade600,
                                            fontWeight: scheduled || ambiguous ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                      if (patient['city'] != null)
                                        Text(
                                          patient['city'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: scheduled
                                                ? Colors.green.shade900
                                                : ambiguous
                                                    ? Colors.orange.shade900
                                                    : Colors.grey.shade600,
                                            fontWeight: scheduled || ambiguous ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text('Ошибка: ${snapshot.error}');
                }
                return Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }
}
