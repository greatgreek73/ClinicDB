enum TreatmentType {
  implant,
  crown,
  abutment,
  unknown;

  static TreatmentType fromString(String? value) {
    switch (value) {
      case 'Имплантация':
      case 'implant':
        return TreatmentType.implant;
      case 'Коронка':
      case 'crown':
        return TreatmentType.crown;
      case 'Абатмент':
      case 'abutment':
        return TreatmentType.abutment;
      default:
        return TreatmentType.unknown;
    }
  }

  String get asFirestoreString {
    switch (this) {
      case TreatmentType.implant:
        return 'Имплантация';
      case TreatmentType.crown:
        return 'Коронка';
      case TreatmentType.abutment:
        return 'Абатмент';
      case TreatmentType.unknown:
        return 'unknown';
    }
  }
}
