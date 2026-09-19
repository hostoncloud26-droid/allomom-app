/// The facts about the mother that every template resolves against.
///
/// Exposed to the engine under the reserved `profile` namespace, so a reply or
/// a step can say `{profile.pregnancy.week}` or `{profile.vitals.bp}` and get a
/// real value. The bot never writes here — this reads what the app already
/// knows from [MainController], [PregnancyController], [BabyController] and the
/// vitals stream.
///
/// Unresolved placeholders are left on screen as written rather than blanked,
/// so a key a flow asks for but this does not provide is visible while
/// authoring.
library;

import 'package:allomom/controllers/baby_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/controllers/pregnancy_controller.dart';
import 'package:allomom/controllers/vitals_controller.dart';
import 'package:allomom/services/app_language.dart';

const List<String> _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const List<String> _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday',
  'Friday', 'Saturday', 'Sunday',
];

/// Shown in place of a reading that has never been taken, so a template that
/// asks for it renders a sentence rather than a blank.
const String _missing = 'Not recorded yet';

/// Who is asking.
Map<String, dynamic> _user(MainController main) {
  final user = <String, dynamic>{
    'id': main.userId,
    'name': main.userName,
    'gender': main.gender,
    'phone': main.userPhone,
    'email': main.userEmail,
    'city': main.city,
    'bio': main.bio,
    'language': AppLanguage.cachedOrFallback,
  };

  final dob = main.dob;
  if (dob != null) {
    user['dob'] = _isoDate(dob);
    final age = _yearsSince(dob);
    if (age != null) user['age'] = age;
  }

  user.removeWhere((_, value) => value == null || value.toString().isEmpty);
  return user;
}

/// Where this pregnancy stands, or what came after it.
Map<String, dynamic> _pregnancy(MainController main) {
  final pregnancy = <String, dynamic>{
    'is_pregnant': main.isPregnant,
    'status': main.pregnancyStatus,
    'is_new_mom': main.isNewMom,
  };

  if (main.isPregnant) {
    pregnancy.addAll({
      'week': main.currentGestationalWeek,
      'day': main.currentPregnancyDay,
      'trimester': main.currentTrimester,
      'trimester_number': main.currentTrimesterNumber,
      'days_left': main.daysLeftUntilEdd,
      'risk_status': main.riskStatus,
      'edd': main.formattedEddDateFull,
    });
    final edd = main.eddDate;
    if (edd != null) pregnancy['edd_iso'] = _isoDate(edd);
  }

  final lmp = main.lmpDate;
  if (lmp != null) pregnancy['lmp'] = _isoDate(lmp);

  final lastBirth = main.lastBirthDate;
  if (lastBirth != null) pregnancy['last_birth'] = _isoDate(lastBirth);

  return pregnancy;
}

/// The babies already here.
Map<String, dynamic> _baby(MainController main) {
  final baby = <String, dynamic>{
    'has_kids': main.hasKids,
    'count': main.kidsCount,
  };

  final dob = main.youngestBabyDob;
  if (dob != null) {
    baby['youngest_dob'] = _isoDate(dob);
    final days = DateTime.now().difference(dob).inDays;
    baby['youngest_age_days'] = days;
    baby['youngest_age_months'] = (days / 30.44).floor();
  }

  final sinceDelivery = main.daysSinceDelivery;
  if (sinceDelivery != null) baby['days_since_delivery'] = sinceDelivery;

  try {
    final names = BabyController.instance.babies
        .map((b) => b.name)
        .where((name) => name.trim().isNotEmpty)
        .toList();
    if (names.isNotEmpty) {
      baby['names'] = names;
      baby['name'] = names.first;
    }
  } catch (_) {
    // The baby list not being loaded is not worth failing a turn over.
  }

  return baby;
}

/// The latest reading of each vital, with a stated absence where there is none.
///
/// Every key is present either way: a flow that says "your BP is
/// {profile.vitals.bp}" should read as a sentence before the first reading is
/// ever taken, not as a hole.
Map<String, dynamic> _vitals() {
  final vitals = <String, dynamic>{};

  try {
    final controller = VitalsController.instance;

    void put(String key, String vitalKey, {String? unit, int? decimals}) {
      final reading = controller.latest(vitalKey);
      final value = reading?.value;
      if (value == null) return;
      vitals[key] = decimals == 0 ? value.round() : _round(value, decimals ?? 1);
      final resolvedUnit = reading?.unit;
      if (resolvedUnit != null && resolvedUnit.isNotEmpty) {
        vitals['${key}_unit'] = resolvedUnit;
      } else if (unit != null) {
        vitals['${key}_unit'] = unit;
      }
    }

    put('weight', VitalKeys.weight, unit: 'kg');
    put('height', VitalKeys.height, unit: 'cm');
    put('bmi', VitalKeys.bmi);
    put('heart_rate', VitalKeys.heartRate, unit: 'bpm', decimals: 0);
    put('hrv', VitalKeys.hrv, unit: 'ms', decimals: 0);
    put('blood_oxygen', VitalKeys.bloodOxygen, unit: '%', decimals: 0);
    put('blood_glucose', VitalKeys.bloodGlucose, unit: 'mg/dL');
    put('hemoglobin', VitalKeys.haemoglobin, unit: 'g/dL');
    put('temperature', VitalKeys.temperature, unit: '°F');
    put('steps', VitalKeys.steps, decimals: 0);
    put('sleep', VitalKeys.sleep, unit: 'hours');
    put('stress', VitalKeys.stress, decimals: 0);
    put('calories', VitalKeys.calories, unit: 'kcal', decimals: 0);
    put('water', VitalKeys.water, unit: 'ml', decimals: 0);

    if (vitals['heart_rate'] != null) vitals['hr'] = vitals['heart_rate'];
    if (vitals['blood_oxygen'] != null) vitals['spo2'] = vitals['blood_oxygen'];
    if (vitals['sleep'] != null) vitals['sleep_hours'] = vitals['sleep'];

    final systolic = controller.latestValue(VitalKeys.bloodPressureSystolic);
    final diastolic = controller.latestValue(VitalKeys.bloodPressureDiastolic);
    if (systolic != null && diastolic != null) {
      vitals['systolic'] = systolic.round();
      vitals['diastolic'] = diastolic.round();
      vitals['blood_pressure'] = '${systolic.round()}/${diastolic.round()}';
      vitals['bp'] = vitals['blood_pressure'];
    }

    final bloodGroup = MainController.instance.bloodGroup;
    if (bloodGroup != null && bloodGroup.isNotEmpty) {
      vitals['blood_group'] = bloodGroup;
    }
  } catch (_) {
    // No vitals loaded — the defaults below still make every key answerable.
  }

  for (final key in const [
    'weight', 'height', 'bmi', 'heart_rate', 'hr', 'hrv', 'blood_oxygen',
    'spo2', 'blood_pressure', 'bp', 'systolic', 'diastolic', 'blood_glucose',
    'hemoglobin', 'temperature', 'steps', 'sleep', 'sleep_hours', 'stress',
    'calories', 'water', 'blood_group',
  ]) {
    vitals.putIfAbsent(key, () => _missing);
  }

  vitals.putIfAbsent('weight_unit', () => 'kg');
  vitals.putIfAbsent('height_unit', () => 'cm');
  vitals.putIfAbsent('heart_rate_unit', () => 'bpm');
  vitals.putIfAbsent('blood_oxygen_unit', () => '%');

  return vitals;
}

/// Counts a reply can quote without opening a page.
Map<String, dynamic> _stats(MainController main) {
  final stats = <String, dynamic>{
    'babies_count': main.kidsCount,
    'completed_pregnancies': main.completedPregnancyCount,
  };

  try {
    stats['pregnancies_count'] = PregnancyController.instance.pregnancies.length;
  } catch (_) {
    // Optional detail.
  }

  return stats;
}

/// The facts handed to the engine on every turn.
Map<String, dynamic> offlineChatbotProfile() {
  final now = DateTime.now();
  final main = MainController.instance;

  final monthName = _months[now.month - 1];
  final dayName = _weekdays[now.weekday - 1];
  final dateToday = '$dayName, ${now.day} $monthName ${now.year}';
  final dateFormatted = '${now.day} $monthName ${now.year}';

  final hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
  final minutePadded = now.minute.toString().padLeft(2, '0');
  final period = now.hour >= 12 ? 'PM' : 'AM';
  final timeFormatted = '$hour12:$minutePadded $period';

  final user = _user(main);
  final pregnancy = _pregnancy(main);
  final baby = _baby(main);

  return <String, dynamic>{
    'user': user,
    'pregnancy': pregnancy,
    'baby': baby,
    'vitals': _vitals(),
    'stats': _stats(main),

    // Top-level conveniences, for the placeholders an author reaches for first.
    'name': user['name'] ?? '',
    'id': user['id'] ?? '',
    'week': pregnancy['week'] ?? '',
    'trimester': pregnancy['trimester'] ?? '',
    'is_pregnant': pregnancy['is_pregnant'],
    'language': AppLanguage.cachedOrFallback,

    // Time and date, under every name a flow is likely to use.
    'time_hour': now.hour,
    'time_minute': now.minute,
    'time_minutes': now.minute,
    'hour': now.hour,
    'minute': now.minute,
    'minutes': now.minute,
    'time_formatted': timeFormatted,
    'current_time': timeFormatted,
    'time_now': timeFormatted,
    'time_period': period,
    'greeting': _greeting(now.hour),
    'date_today': dateToday,
    'date': dateFormatted,
    'today': dateToday,
    'formatted_date': dateFormatted,
    'day': dayName,
    'day_of_week': dayName,
    'date_iso': _isoDate(now),
    'month': monthName,
    'year': now.year,
    'time': {
      'hour': now.hour,
      'minute': now.minute,
      'minutes': now.minute,
      'formatted': timeFormatted,
      'period': period,
      'display': timeFormatted,
    },
  };
}

/// Every `profile.` path the current data offers, for showing an author which
/// placeholders will resolve. Walks nested maps into dotted paths.
List<String> offlineChatbotProfileKeys() {
  final paths = <String>[];

  void walk(dynamic value, String prefix) {
    if (value is Map) {
      value.forEach((key, child) {
        final path = prefix.isEmpty ? '$key' : '$prefix.$key';
        if (child is Map) {
          walk(child, path);
        } else if (!paths.contains(path)) {
          paths.add(path);
        }
      });
    } else if (prefix.isNotEmpty && !paths.contains(prefix)) {
      paths.add(prefix);
    }
  }

  walk(offlineChatbotProfile(), '');
  paths.sort();
  return paths;
}

String _greeting(int hour) {
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
}

String _isoDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

int? _yearsSince(DateTime date) {
  final now = DateTime.now();
  var years = now.year - date.year;
  if (now.month < date.month ||
      (now.month == date.month && now.day < date.day)) {
    years--;
  }
  return years >= 0 && years < 130 ? years : null;
}

num _round(double value, int decimals) {
  final rounded = double.parse(value.toStringAsFixed(decimals));
  return rounded == rounded.roundToDouble() ? rounded.round() : rounded;
}
