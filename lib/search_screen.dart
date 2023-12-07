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
                      .orderBy('surname') // Сортировка по фамилии
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('patients')
                      .where('searchKey', isGreaterThanOrEqualTo: searchQuery)
                      .where('searchKey', isLessThan: searchQuery + '\uF8FF')
                      .orderBy('surname') // Сортировка по фамилии
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var documents = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      var patient = documents[index].data() as Map<String, dynamic>;
                      var patientId = documents[index].id; // Получение ID пациента

                      return ListTile(
                        title: Text(patient['surname'] ?? 'Нет фамилии', style: TextStyle(fontSize: 18)),
                        subtitle: Text(patient['name'] ?? 'Нет имени', style: TextStyle(fontSize: 14)),
                        onTap: () {
                          // Переход на экран деталей пациента
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PatientDetailsScreen(patientId: patientId),
                            ),
                          );
                        },
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
