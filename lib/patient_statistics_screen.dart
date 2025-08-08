import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'patient/details/patient_details_screen.dart';
import 'design_system/design_system_screen.dart' show NeoCard, NeoButton, DesignTokens;

class PatientStatisticsScreen extends StatefulWidget {
  const PatientStatisticsScreen({Key? key}) : super(key: key);

  @override
  _PatientStatisticsScreenState createState() => _PatientStatisticsScreenState();
}

class _PatientStatisticsScreenState extends State<PatientStatisticsScreen> {
  bool _isExpanded = false;
  List<Map<String, dynamic>> _singleImplantPatients = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Используем упрощённый метод, чтобы избежать проблем с индексами Firebase
    _loadSimplified();
  }
  
  Future<void> _loadWithTimeout() async {
    try {
      await _loadSimplified().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Таймаут загрузки данных (10 секунд)');
          if (mounted) {
            setState(() {
              _isLoading = false;
              // Можем добавить тестовые данные
              _singleImplantPatients = [];
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Превышено время ожидания загрузки'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
      );
    } catch (e) {
      print('Ошибка с таймаутом: $e');
    }
  }

  // Упрощённый метод без составных запросов
  Future<void> _loadSimplified() async {
    print('Пробуем упрощённый метод загрузки...');
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Получаем все процедуры имплантации
      final treatmentsSnapshot = await FirebaseFirestore.instance
          .collection('treatments')
          .where('treatmentType', isEqualTo: 'Имплантация')
          .get();
      
      print('Найдено записей имплантации: ${treatmentsSnapshot.docs.length}');
      
      // Группируем по пациентам
      Map<String, int> patientImplantCount = {};
      
      for (var doc in treatmentsSnapshot.docs) {
        final data = doc.data();
        final patientId = data['patientId'] as String;
        final toothNumbers = data['toothNumber'] as List<dynamic>? ?? [];
        
        if (patientImplantCount.containsKey(patientId)) {
          patientImplantCount[patientId] = patientImplantCount[patientId]! + toothNumbers.length;
        } else {
          patientImplantCount[patientId] = toothNumbers.length;
        }
      }
      
      print('Пациентов с имплантами: ${patientImplantCount.length}');
      
      // Отбираем только с одним имплантом
      List<String> singleImplantPatientIds = [];
      patientImplantCount.forEach((patientId, count) {
        if (count == 1) {
          singleImplantPatientIds.add(patientId);
        }
      });
      
      print('Пациентов с одним имплантом: ${singleImplantPatientIds.length}');
      
      // Теперь получаем данные этих пациентов
      List<Map<String, dynamic>> singleImplantPatients = [];
      
      for (String patientId in singleImplantPatientIds) {
        try {
          final patientDoc = await FirebaseFirestore.instance
              .collection('patients')
              .doc(patientId)
              .get();
          
          if (patientDoc.exists) {
            final data = patientDoc.data()!;
            singleImplantPatients.add({
              'id': patientId,
              'name': data['name'] ?? '',
              'surname': data['surname'] ?? '',
              'age': data['age'] ?? 0,
              'phone': data['phone'] ?? '',
            });
          }
        } catch (e) {
          print('Ошибка загрузки пациента $patientId: $e');
        }
      }
      
      // Сортируем
      singleImplantPatients.sort((a, b) => 
        (a['surname'] as String).compareTo(b['surname'] as String)
      );
      
      if (mounted) {
        setState(() {
          _singleImplantPatients = singleImplantPatients;
          _isLoading = false;
        });
      }
      
    } catch (e) {
      print('Ошибка в упрощённом методе: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadSingleImplantPatients() async {
    print('Начинаем загрузку пациентов с одним имплантом...');
    setState(() {
      _isLoading = true;
    });

    try {
      // Получаем всех пациентов
      print('Получаем список всех пациентов...');
      final patientsSnapshot = await FirebaseFirestore.instance
          .collection('patients')
          .get();
      
      print('Найдено пациентов: ${patientsSnapshot.docs.length}');

      List<Map<String, dynamic>> singleImplantPatients = [];

      // Для каждого пациента проверяем процедуры
      for (var patientDoc in patientsSnapshot.docs) {
        final patientData = patientDoc.data();
        final patientId = patientDoc.id;
        
        // Проверяем, что у пациента есть основные данные
        final name = patientData['name'] ?? '';
        final surname = patientData['surname'] ?? '';
        
        print('Проверяем пациента: $surname $name (ID: $patientId)');

        try {
          // Получаем все процедуры имплантации для пациента
          final treatmentsSnapshot = await FirebaseFirestore.instance
              .collection('treatments')
              .where('patientId', isEqualTo: patientId)
              .where('treatmentType', isEqualTo: 'Имплантация')
              .get();
          
          print('  Найдено записей имплантации: ${treatmentsSnapshot.docs.length}');

          // Подсчитываем общее количество зубов с имплантами
          int totalImplants = 0;
          for (var treatmentDoc in treatmentsSnapshot.docs) {
            final treatmentData = treatmentDoc.data();
            final toothNumbers = treatmentData['toothNumber'] as List<dynamic>? ?? [];
            totalImplants += toothNumbers.length;
            print('    Зубы в записи: ${toothNumbers.length}');
          }
          
          print('  Всего имплантов у пациента: $totalImplants');

          // Если ровно один имплант, добавляем в список
          if (totalImplants == 1) {
            print('  ✓ Добавляем в список (1 имплант)');
            singleImplantPatients.add({
              'id': patientId,
              'name': name,
              'surname': surname,
              'age': patientData['age'] ?? 0,
              'phone': patientData['phone'] ?? '',
            });
          }
        } catch (treatmentError) {
          print('  Ошибка при обработке процедур пациента $patientId: $treatmentError');
          // Продолжаем с следующим пациентом
        }
      }

      print('Всего найдено пациентов с одним имплантом: ${singleImplantPatients.length}');

      // Сортируем по фамилии
      singleImplantPatients.sort((a, b) => 
        (a['surname'] as String).compareTo(b['surname'] as String)
      );

      if (mounted) {
        setState(() {
          _singleImplantPatients = singleImplantPatients;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('ОШИБКА загрузки пациентов: $e');
      print('Stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Показываем ошибку пользователю
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки данных: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
    
    print('Загрузка завершена. isLoading = $_isLoading');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      body: SafeArea(
        child: Row(
          children: [
            // Боковая панель с кнопкой назад
            Container(
              width: 80,
              decoration: BoxDecoration(
                color: DesignTokens.surface,
                boxShadow: [
                  BoxShadow(
                    color: DesignTokens.shadowDark.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Иконка статистики
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: DesignTokens.background,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: DesignTokens.innerShadows(blur: 8, offset: 4),
                    ),
                    child: const Center(
                      child: Text('📊', style: TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Статистика',
                    style: DesignTokens.small.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Кнопка назад
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: DesignTokens.background.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        iconSize: 20,
                        color: DesignTokens.textSecondary,
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Назад',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Основной контент
            Expanded(
              child: Column(
                children: [
                  // Заголовок
                  Container(
                    padding: const EdgeInsets.all(30),
                    child: Row(
                      children: [
                        const Text('📊', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Статистика пациентов',
                              style: DesignTokens.h1,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Анализ данных по категориям',
                              style: DesignTokens.body.copyWith(
                                color: DesignTokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Контент
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: _isLoading
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Загрузка данных...',
                                    style: DesignTokens.body.copyWith(
                                      color: DesignTokens.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _isLoading = false;
                                          });
                                        },
                                        child: const Text('Отменить'),
                                      ),
                                      const SizedBox(width: 16),
                                      TextButton(
                                        onPressed: () {
                                          _loadSimplified();
                                        },
                                        child: const Text('Повторить'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Интерактивная карточка "1 имплант"
                                _buildImplantCard(),
                                
                                // Список пациентов (если развернуто)
                                if (_isExpanded) ...[
                                  const SizedBox(height: 20),
                                  Expanded(
                                    child: _buildPatientsList(),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImplantCard() {
    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: NeoCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              // Иконка
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: DesignTokens.accentPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: DesignTokens.accentPrimary.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Text('🦷', style: TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 20),
              
              // Текст
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1 имплант',
                      style: DesignTokens.h2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Пациенты с одним имплантом',
                      style: DesignTokens.body.copyWith(
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Количество и стрелка
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: DesignTokens.accentPrimary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: DesignTokens.accentPrimary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _singleImplantPatients.length.toString(),
                      style: DesignTokens.h3.copyWith(
                        color: DesignTokens.accentPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isExpanded ? 0.5 : 0,
                    child: Icon(
                      Icons.expand_more,
                      color: DesignTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientsList() {
    if (_singleImplantPatients.isEmpty) {
      return Center(
        child: NeoCard(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔍', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'Нет пациентов с одним имплантом',
                  style: DesignTokens.h4.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return NeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text('👥', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Text('Список пациентов', style: DesignTokens.h3),
                const Spacer(),
                Text(
                  'Всего: ${_singleImplantPatients.length}',
                  style: DesignTokens.body.copyWith(
                    color: DesignTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              // Performance optimizations
              itemExtent: 72.0, // Fixed height for each patient item
              cacheExtent: 300.0, // Cache content outside visible area
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: _singleImplantPatients.length,
              itemBuilder: (context, index) {
                final patient = _singleImplantPatients[index];
                return _buildPatientItem(patient, index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientItem(Map<String, dynamic> patient, int number) {
    final fullName = '${patient['surname']} ${patient['name']}'.trim();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          // Переход к карточке пациента
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PatientDetailsScreen(patientId: patient['id']),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: NeoCard.inset(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Номер
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: DesignTokens.accentPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      number.toString(),
                      style: DesignTokens.body.copyWith(
                        color: DesignTokens.accentPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Информация о пациенте
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName.isEmpty ? 'Пациент' : fullName,
                        style: DesignTokens.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.cake_outlined,
                            size: 14,
                            color: DesignTokens.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${patient['age']} лет',
                            style: DesignTokens.small.copyWith(
                              color: DesignTokens.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: DesignTokens.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            patient['phone'],
                            style: DesignTokens.small.copyWith(
                              color: DesignTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Стрелка
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: DesignTokens.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
