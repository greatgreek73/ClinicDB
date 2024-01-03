// Продолжайте использовать этот класс, если он используется в вашем приложении.
class Tooth {
  int number;
  bool treated;

  Tooth({
    required this.number,
    this.treated = false,
  });

  factory Tooth.fromFirestore(Map<String, dynamic> firestore) {
    return Tooth(
      number: firestore['number'] as int,
      treated: firestore['treated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'treated': treated,
    };
  }
}
