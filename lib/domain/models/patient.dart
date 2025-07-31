class Patient {
  final String id;
  final String? name;
  final bool waitingList;
  final bool secondStage;
  final bool hotPatient;

  const Patient({
    required this.id,
    this.name,
    required this.waitingList,
    required this.secondStage,
    required this.hotPatient,
  });

  factory Patient.fromJson(String id, Map<String, dynamic>? json) {
    final map = json ?? const {};
    return Patient(
      id: id,
      name: map['name'] as String?,
      waitingList: (map['waitingList'] as bool?) ?? false,
      secondStage: (map['secondStage'] as bool?) ?? false,
      hotPatient: (map['hotPatient'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'waitingList': waitingList,
      'secondStage': secondStage,
      'hotPatient': hotPatient,
    };
  }

  Patient copyWith({
    String? id,
    String? name,
    bool? waitingList,
    bool? secondStage,
    bool? hotPatient,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      waitingList: waitingList ?? this.waitingList,
      secondStage: secondStage ?? this.secondStage,
      hotPatient: hotPatient ?? this.hotPatient,
    );
  }
}
