enum TreatmentType {
  implant,
  crown,
  abutment,
  scan,
  unknown;

  static TreatmentType fromString(String? value) {
    switch (value) {
      case '���������':
      case 'implant':
        return TreatmentType.implant;
      case '��஭��':
      case 'crown':
        return TreatmentType.crown;
      case '���⬥��':
      case 'abutment':
        return TreatmentType.abutment;
      case 'Сканирование':
      case 'scan':
        return TreatmentType.scan;
      default:
        // Fallbacks for potential lowercase inputs
        final lower = value?.toLowerCase();
        if (lower == 'сканирование') return TreatmentType.scan;
        if (lower == 'implant') return TreatmentType.implant;
        if (lower == 'crown') return TreatmentType.crown;
        if (lower == 'abutment') return TreatmentType.abutment;
        return TreatmentType.unknown;
    }
  }

  String get asFirestoreString {
    switch (this) {
      case TreatmentType.implant:
        return '���������';
      case TreatmentType.crown:
        return '��஭��';
      case TreatmentType.abutment:
        return '���⬥��';
      case TreatmentType.scan:
        return 'Сканирование';
      case TreatmentType.unknown:
        return 'unknown';
    }
  }
}

