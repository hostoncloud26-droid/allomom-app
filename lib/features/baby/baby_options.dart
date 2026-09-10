/// Canonical stored values for a birth record, and the labels shown for them.
///
/// A baby can be added from three places — the complete-pregnancy modal, the
/// registration flow's kids question and the Babies screen — so the mapping
/// between what the mother taps and what lands in `birth_records` lives here
/// rather than being retyped (and drifting) at each call site.
library;

/// `birth_records.gender`.
const List<({String value, String label})> babyGenderOptions = [
  (value: 'male', label: 'Boy'),
  (value: 'female', label: 'Girl'),
  (value: 'other', label: 'Other'),
];

/// `birth_records.delivery_type`.
const List<({String value, String label})> deliveryTypeOptions = [
  (value: 'normal', label: 'Normal'),
  (value: 'c-section', label: 'C-Section'),
  (value: 'assisted', label: 'Assisted'),
];

const List<String> bloodGroupOptions = [
  'A+',
  'A-',
  'B+',
  'B-',
  'AB+',
  'AB-',
  'O+',
  'O-',
];

String labelForGender(String? value) => _labelFor(babyGenderOptions, value);

String labelForDeliveryType(String? value) =>
    _labelFor(deliveryTypeOptions, value);

String _labelFor(
  List<({String value, String label})> options,
  String? value,
) {
  if (value == null || value.isEmpty) return '—';
  for (final option in options) {
    if (option.value == value) return option.label;
  }
  return value;
}

/// Formats a baby's age from their date of birth, e.g. "3 months", "2 yrs".
String babyAgeLabel(DateTime? dob, {DateTime? now}) {
  if (dob == null) return '';
  final today = now ?? DateTime.now();
  if (dob.isAfter(today)) return 'Due soon';

  var months = (today.year - dob.year) * 12 + (today.month - dob.month);
  if (today.day < dob.day) months--;

  if (months < 1) {
    final days = today.difference(dob).inDays;
    if (days < 1) return 'Newborn';
    return days == 1 ? '1 day' : '$days days';
  }
  if (months < 24) return months == 1 ? '1 month' : '$months months';

  final years = months ~/ 12;
  return years == 1 ? '1 yr' : '$years yrs';
}
