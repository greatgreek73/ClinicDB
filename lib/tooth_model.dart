class Tooth {
  int number;
  bool treated;

  Tooth({
    required this.number,
    this.treated = false,
  });

  // Метод для создания объекта Tooth из данных Firestore
  factory Tooth.fromFirestore(Map<String, dynamic> firestore) {
    return Tooth(
      number: firestore['number'],
      treated: firestore['treated'] ?? false,
    );
  }

  // Метод для преобразования объекта Tooth в Map
  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'treated': treated,
    };
  }
}
