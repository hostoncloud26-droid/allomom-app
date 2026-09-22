/// The facts about the mother that every template resolves against.
///
/// One shape, shared by the three places that read it: the flow builder's
/// variable palette, the test chat on the web client, and this app. A flow
/// authored against `{profile.pregnancy.current_week}` or `{profile.vitals.hr}`
/// therefore resolves the same here as it previewed there — which is the whole
/// point of keeping the keys identical rather than each side naming its own.
///
/// The bot never writes here. This reads what the app already knows from
/// [MainController], [PregnancyController], [BabyController] and the vitals
/// stream, and stamps the current date and time.
///
/// Unresolved placeholders are left on screen as written rather than blanked,
/// so a key a flow asks for but this does not provide is visible while
/// authoring.
library;

import 'package:get/get.dart';
import 'package:allomom/controllers/baby_controller.dart';
import 'package:allomom/controllers/family_controller.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/controllers/vitals_controller.dart';

/// Shown in place of a reading that has never been taken, so a template that
/// asks for it renders a sentence rather than a blank.
///
/// The server drops these before they reach a model: telling it a heart rate is
/// "Not recorded yet" is worse than not mentioning the heart rate at all.
const String _missing = 'Not recorded yet';

/// Days from LMP to the expected delivery date — the standard 40 weeks.
const int _gestationDays = 280;

String _pad(int value) => value.toString().padLeft(2, '0');

/// Whether this user is the mother, her partner, or someone else.
///
/// Read off gender, since that is the only signal an account carries. A family
/// member viewing her data is still the account they signed in as.
String _type(MainController main) {
  final gender = main.gender.trim().toLowerCase();
  if (gender.startsWith('f')) return 'mom';
  if (gender.startsWith('m')) return 'dad';
  return 'others';
}

/// Who is asking: the three facts an answer can be shaped around.
///
/// Contact details are deliberately absent — a phone number or an id cannot
/// make an answer more personal, and this map is handed to a model.
Map<String, dynamic> _person(MainController main) {
  final dob = main.dob;
  return <String, dynamic>{
    'name': main.userName,
    'age': dob == null ? _missing : (_yearsSince(dob) ?? _missing),
    'gender': main.gender.trim().toLowerCase(),
  };
}

/// Where this pregnancy stands, in the units a flow asks for.
///
/// Every key is always present, even when there is no active pregnancy: a
/// template that names one should render a value rather than leaving a raw
/// `{profile.pregnancy.current_week}` on screen. `status` is what says whether
/// these numbers mean anything, and the server only narrates them when it
/// reads `pregnant`.
Map<String, dynamic> _pregnancy(MainController main) {
  final lmp = main.lmpDate;
  final daysSince = main.isPregnant
      ? main.currentPregnancyDay
      : (lmp == null ? 0 : _daysBetween(lmp, DateTime.now()));

  // The EDD the pregnancy was given, or the 40 weeks from LMP it implies.
  final edd =
      main.eddDate ?? lmp?.add(const Duration(days: _gestationDays));

  return <String, dynamic>{
    'days_since': daysSince,
    'current_week': main.isPregnant
        ? main.currentGestationalWeek
        : (daysSince / 7).floor(),
    'current_day': daysSince % 7,
    'trimester': main.isPregnant ? main.currentTrimesterNumber : 0,
    'lmp_date': lmp?.day ?? 0,
    'lmp_month': lmp?.month ?? 0,
    'lmp_year': lmp?.year ?? 0,
    // The same date as one string. The three numbers above resolve a template
    // but never reached the model — nothing on the server read them — so an
    // answer about "her last period" had the date in the payload and still
    // said it did not have it.
    'lmp_formatted':
        lmp == null ? '' : '${_pad(lmp.day)}/${_pad(lmp.month)}/${lmp.year}',
    'days_since_lmp': lmp == null ? 0 : _daysBetween(lmp, DateTime.now()),
    'ed_date': edd?.day ?? 0,
    'ed_month': edd?.month ?? 0,
    'ed_year': edd?.year ?? 0,
    'ed_formatted':
        edd == null ? '' : '${_pad(edd.day)}/${_pad(edd.month)}/${edd.year}',
    'days_for_ed': edd == null ? 0 : _daysBetween(DateTime.now(), edd),
  };
}

/// The short names the four headline readings have always had, kept so a flow
/// authored against `{profile.vitals.hr}` still resolves.
const Map<String, String> _headlineVitals = {
  'hr': VitalKeys.heartRate,
  'hrv': VitalKeys.hrv,
  'spo2': VitalKeys.bloodOxygen,
  'steps': VitalKeys.steps,
};

/// Everything else the vitals stream holds, under its own storage key.
const List<String> _otherVitals = [
  VitalKeys.weight,
  VitalKeys.height,
  VitalKeys.bmi,
  VitalKeys.bloodPressureSystolic,
  VitalKeys.bloodPressureDiastolic,
  VitalKeys.bloodGlucose,
  VitalKeys.haemoglobin,
  VitalKeys.temperature,
  VitalKeys.sleep,
  VitalKeys.stress,
  VitalKeys.calories,
  VitalKeys.water,
];

/// Every reading the phone has, newest value per key.
///
/// It used to be four. A mother asking about her weight, her sugar or her
/// haemoglobin was answered by a model that had never been told them, and a
/// step could only get at them by naming each one in its own prompt. A reading
/// that was never taken is still left out rather than sent as "not recorded" —
/// a model told a number is unavailable tends to say so, which answers nothing.
Map<String, dynamic> _vitals() {
  final vitals = <String, dynamic>{};

  try {
    final controller = VitalsController.instance;

    void put(String key, String vitalKey) {
      final value = controller.latestValue(vitalKey);
      if (value == null) return;
      // Whole numbers for counts, one decimal for the readings that have one:
      // "weight 62.4" is a fact, "weight 62.400000000000006" is noise.
      vitals[key] = value == value.roundToDouble()
          ? value.round()
          : double.parse(value.toStringAsFixed(1));
    }

    _headlineVitals.forEach(put);
    for (final key in _otherVitals) {
      put(key, key);
    }

    final group = controller.bloodGroup;
    if (group != null && group.trim().isNotEmpty) {
      vitals['blood_group'] = group.trim();
    }
  } catch (_) {
    // No vitals loaded — the placeholders below still make every key
    // answerable, which is what a template needs.
  }

  // Only the four a flow may already name are placeheld: a template that says
  // `{profile.vitals.hr}` has to render something.
  for (final key in _headlineVitals.keys) {
    vitals.putIfAbsent(key, () => _missing);
  }

  return vitals;
}

/// Where her cycle stands, for the months there is no pregnancy to talk about.
///
/// The pregnancy block's LMP comes off the health record; this one is the date
/// the cycle tracker itself works from — the latest logged period start — which
/// is what a mother means when she asks when her last period was.
Map<String, dynamic> _cycle(MainController main) {
  final anchor = main.cycleAnchorDate;
  if (anchor == null) return const <String, dynamic>{};

  final cycle = <String, dynamic>{
    'last_period_formatted':
        '${_pad(anchor.day)}/${_pad(anchor.month)}/${anchor.year}',
    'days_since_last_period': _daysBetween(anchor, DateTime.now()),
    'average_cycle_length': main.averageCycleLength,
    'average_period_duration': main.averagePeriodDuration,
  };

  // Null throughout a pregnancy, which is the honest reading: there is no
  // next period to predict.
  final prediction = main.cyclePrediction;
  if (prediction != null) {
    final next = prediction.nextPeriodStart;
    cycle['next_period_formatted'] =
        '${_pad(next.day)}/${_pad(next.month)}/${next.year}';
    cycle['days_until_next_period'] = prediction.daysUntilNextPeriod;
    cycle['cycle_day'] = prediction.cycleDay;
  }

  return cycle;
}

/// What the app knows about the mother's health beyond a reading.
///
/// Allergies and a medical condition change what an answer may safely suggest,
/// so they travel with every turn rather than waiting to be asked for.
Map<String, dynamic> _health(MainController main) {
  final health = <String, dynamic>{};

  void put(String key, String? value) {
    final clean = value?.trim() ?? '';
    if (clean.isNotEmpty) health[key] = clean;
  }

  put('allergies', main.allergies);
  put('medical_condition', main.medicalCondition);
  put('blood_group', main.bloodGroup);
  put('rch_id', main.rchId);
  return health;
}

/// The two parents, by name, so an answer knows whose data it is reading.
///
/// A father asking "when was her last period?" was being answered about
/// himself, because the only person in the profile was whoever had signed in.
/// Both parents are named here, each marked with whether they are the one
/// asking — the health facts in this profile are always the mother's.
Map<String, Map<String, dynamic>> _parents(MainController main) {
  final isMother = _type(main) == 'mom';

  Map<String, dynamic> me() => <String, dynamic>{
    'name': main.userName,
    'is_you': true,
  };

  final mother = <String, dynamic>{};
  final father = <String, dynamic>{};
  if (isMother) {
    mother.addAll(me());
  } else if (_type(main) == 'dad') {
    father.addAll(me());
  }

  try {
    final family = FamilyController.instance.family;
    for (final member in family?.members ?? const []) {
      final relation = (member.relation ?? '').trim().toLowerCase();
      final target = relation == 'mother'
          ? mother
          : (relation == 'father' ? father : null);
      if (target == null || member.name.trim().isEmpty) continue;
      target['name'] = member.name.trim();
      target['is_you'] = member.isMe;
      target['registered'] = member.isRegistered;
    }

    // A partner who was added but never joined a family group is still the
    // other parent, and still has a name worth knowing.
    final partner = FamilyController.instance.partner;
    final partnerRelation =
        (partner?.familyRelation ?? '').trim().toLowerCase();
    final target = partnerRelation == 'mother'
        ? mother
        : (partnerRelation == 'father' ? father : (isMother ? father : mother));
    if (partner != null &&
        partner.displayName.trim().isNotEmpty &&
        target['name'] == null) {
      target['name'] = partner.displayName.trim();
      target['is_you'] = false;
      target['registered'] = partner.isRegistered;
    }
  } catch (_) {
    // No family loaded yet — whoever signed in is still named above.
  }

  return {'mother': mother, 'father': father};
}

/// The babies already born, as the facts an answer about one would need.
List<Map<String, dynamic>> _babies() {
  try {
    return BabyController.instance.babies.map((baby) {
      final entry = <String, dynamic>{
        'name': baby.name,
        'date_of_birth': '${_pad(baby.deliveryDate.day)}/'
            '${_pad(baby.deliveryDate.month)}/${baby.deliveryDate.year}',
        'age_days': _daysBetween(baby.deliveryDate, DateTime.now()),
        'delivery': baby.typeOfDelivery,
      };
      if ((baby.gender ?? '').trim().isNotEmpty) {
        entry['gender'] = baby.gender!.trim();
      }
      if (baby.weight != null) entry['birth_weight_kg'] = baby.weight;
      if ((baby.bloodGroup ?? '').trim().isNotEmpty) {
        entry['blood_group'] = baby.bloodGroup!.trim();
      }
      return entry;
    }).toList();
  } catch (_) {
    return const [];
  }
}

/// Whether anything was recorded today.
///
/// What it answers is "is this a live reading or last week's?", so a reply can
/// say so instead of quoting a stale number as if it were current.
bool _activeToday() {
  try {
    final controller = VitalsController.instance;
    final now = DateTime.now();
    for (final key in const [
      VitalKeys.heartRate,
      VitalKeys.hrv,
      VitalKeys.bloodOxygen,
      VitalKeys.steps,
    ]) {
      final at = controller.latest(key)?.createdAt;
      if (at != null &&
          at.year == now.year &&
          at.month == now.month &&
          at.day == now.day) {
        return true;
      }
    }
  } catch (_) {
    // Treated as no activity, which is the honest reading of "we don't know".
  }
  return false;
}

/// Whether meals or hydration have been recorded today.
Map<String, dynamic> _todayNutrition() {
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final endOfToday = startOfToday.add(const Duration(days: 1));
  final twoHoursAgo = now.subtract(const Duration(hours: 2));

  bool hadBreakfast = false;
  bool hadLunch = false;
  bool hadDinner = false;
  bool hadWaterWithin2Hrs = false;

  try {
    if (Get.isRegistered<HealthVitalsController>()) {
      for (final v in HealthVitalsController.instance.vitals) {
        final k = v.key.toLowerCase().trim();
        final at = v.createdAt;
        final isToday =
            (at.isAfter(startOfToday) || at.isAtSameMomentAs(startOfToday)) &&
                at.isBefore(endOfToday);
        if (isToday) {
          if (k == 'breakfast' || k == 'break_fast') hadBreakfast = true;
          if (k == 'lunch') hadLunch = true;
          if (k == 'dinner') hadDinner = true;
        }
        if (k == 'water') {
          if (at.isAfter(twoHoursAgo) &&
              at.isBefore(now.add(const Duration(minutes: 1)))) {
            hadWaterWithin2Hrs = true;
          }
        }
      }
    }
  } catch (_) {}

  try {
    if (Get.isRegistered<VitalsController>()) {
      final vc = VitalsController.instance;
      for (final row in [
        ...vc.readings('breakfast'),
        ...vc.readings('break_fast')
      ]) {
        final at = row.createdAt;
        if ((at.isAfter(startOfToday) || at.isAtSameMomentAs(startOfToday)) &&
            at.isBefore(endOfToday)) {
          hadBreakfast = true;
        }
      }
      for (final row in vc.readings('lunch')) {
        final at = row.createdAt;
        if ((at.isAfter(startOfToday) || at.isAtSameMomentAs(startOfToday)) &&
            at.isBefore(endOfToday)) {
          hadLunch = true;
        }
      }
      for (final row in vc.readings('dinner')) {
        final at = row.createdAt;
        if ((at.isAfter(startOfToday) || at.isAtSameMomentAs(startOfToday)) &&
            at.isBefore(endOfToday)) {
          hadDinner = true;
        }
      }
      for (final row in vc.readings('water')) {
        final at = row.createdAt;
        if (at.isAfter(twoHoursAgo) &&
            at.isBefore(now.add(const Duration(minutes: 1)))) {
          hadWaterWithin2Hrs = true;
        }
      }
    }
  } catch (_) {}

  return <String, dynamic>{
    'had_breakfast': hadBreakfast,
    'had_lunch': hadLunch,
    'had_dinner': hadDinner,
    'had_water_within_2_hrs': hadWaterWithin2Hrs,
  };
}

/// How many babies are already here.
int _babyCount(MainController main) {
  try {
    final listed = BabyController.instance.babies.length;
    if (listed > 0) return listed;
  } catch (_) {
    // The baby list not being loaded is not worth failing a turn over.
  }
  return main.kidsCount;
}

/// The facts handed to the engine on every turn.
///
/// The engine both nests this under `profile` and spreads it at the top level,
/// so a flow can write `{profile.vitals.hr}` — the form the builder's palette
/// offers — or the bare `{vitals.hr}`, and get the same value.
Map<String, dynamic> offlineChatbotProfile() {
  final now = DateTime.now();
  final main = MainController.instance;

  final hour24 = now.hour;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final amPm = hour24 >= 12 ? 'PM' : 'AM';

  final time24 = '${_pad(hour24)}:${_pad(now.minute)}';
  final time12 = '${_pad(hour12)}:${_pad(now.minute)} $amPm';
  final timeFormatted24 = '$time24:${_pad(now.second)}';
  final timeFormatted12 =
      '${_pad(hour12)}:${_pad(now.minute)}:${_pad(now.second)} $amPm';

  final parents = _parents(main);

  return <String, dynamic>{
    'type': _type(main),
    'status': main.pregnancyStatus,
    'profile': _person(main),
    'mother': parents['mother']!,
    'father': parents['father']!,
    'pregnancy': _pregnancy(main),
    'vitals': _vitals(),
    'cycle': _cycle(main),
    'health': _health(main),
    'babies': _babies(),
    'baby_count': _babyCount(main),
    'active_today': _activeToday(),
    'today_nutrition': _todayNutrition(),

    'current_date': now.day,
    'current_month': now.month,
    'current_year': now.year,
    'current_date_formatted':
        '${_pad(now.day)}/${_pad(now.month)}/${now.year}',

    'current_hour_24': hour24,
    'current_hour_12': hour12,
    'current_minute': now.minute,
    'current_second': now.second,
    'current_am_pm': amPm,
    'current_time_24': time24,
    'current_time_12': time12,
    'current_time_formatted': time12,
    'current_time_formatted_24': timeFormatted24,
    'current_time_formatted_12': timeFormatted12,
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

/// Whole days between two instants, never negative — a mistyped date cannot
/// render a negative gestation or a delivery that already happened.
int _daysBetween(DateTime from, DateTime to) {
  final days = to.difference(from).inDays;
  return days < 0 ? 0 : days;
}

int? _yearsSince(DateTime date) {
  final now = DateTime.now();
  var years = now.year - date.year;
  if (now.month < date.month ||
      (now.month == date.month && now.day < date.day)) {
    years--;
  }
  return years >= 0 && years < 130 ? years : null;
}
