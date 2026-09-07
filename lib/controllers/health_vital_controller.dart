import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';
import 'package:allomom/controllers/connection_controller.dart';
import 'package:allomom/services/health_vital_sync_service.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class HealthVitalsController extends GetxController {
  static HealthVitalsController get instance =>
      Get.isRegistered<HealthVitalsController>()
          ? Get.find<HealthVitalsController>()
          : Get.put(HealthVitalsController._internal(), permanent: true);

  factory HealthVitalsController() => instance;
  HealthVitalsController._internal();

  @override
  void onInit() {
    super.onInit();
    final currentUserId = UserSessionManager.instance.userId;
    if (currentUserId.isNotEmpty) {
      setUserId(currentUserId);
    }
  }

  /// Compatibility alias for any Flutter Listeners
  void notifyListeners() => update();

  bool _isLoading = false;
  bool _isSyncing = false;
  String _error = '';
  String _userId = '';
  List<VitalsStreamResponse> _vitals = [];
  final Map<String, List<VitalsStreamResponse>> _historyByKey = {};

  // Typed Vitals Stream Responses
  VitalsStreamResponse? _stepsVital;
  VitalsStreamResponse? _targetVital;
  VitalsStreamResponse? _sleepVital;
  VitalsStreamResponse? _heartRateVital;
  VitalsStreamResponse? _stressVital;
  VitalsStreamResponse? _hrvVital;
  VitalsStreamResponse? _weightVital;
  VitalsStreamResponse? _heightVital;
  VitalsStreamResponse? _bloodOxygenVital;
  VitalsStreamResponse? _bloodPressureVital;
  VitalsStreamResponse? _lmpDateVital;
  VitalsStreamResponse? _hemoglobinVital;
  VitalsStreamResponse? _bloodGroupVital;
  VitalsStreamResponse? _kickCountVital;
  VitalsStreamResponse? _feedingVital;

  // Formatted / Derived scalar values for quick rendering
  String _heartRate = '--';
  int _steps = 0;
  String _hrv = '--';
  String _bloodOxygen = '--';
  String _stress = '--';

  double _sleepHours = 0.0;
  String _sleepDate = '';

  String _bloodPressure = '--/--';
  String _bloodPressureDate = '';

  double _hemoglobin = 0.0;
  String _hemoglobinDate = '';

  double _bloodGlucose = 0.0;
  String _bloodGlucoseDate = '';

  double _weight = 0.0;
  String _weightDate = '';

  double _height = 162.0;
  double _bmi = 0.0;

  int _kickCount = 0;
  String _kickCountDate = '';

  double _feedingValue = 0.0;
  String _feedingUnit = 'mins';
  String _feedingDate = '';
  String _feedingType = 'Breastfeeding';

  // Getters
  bool get isLoading => _isLoading;
  String get error => _error;
  String get userId =>
      _userId.isNotEmpty ? _userId : UserSessionManager.instance.userId;
  List<VitalsStreamResponse> get vitals => List.unmodifiable(_vitals);

  // Status checks for presence of recorded data
  bool get hasHeartRate => _heartRateVital != null;
  bool get hasSteps => _stepsVital != null && _steps > 0;
  bool get hasSleep => _sleepVital != null;
  bool get hasStress => _stressVital != null;
  bool get hasHrv => _hrvVital != null;
  bool get hasBloodOxygen => _bloodOxygenVital != null;
  bool get hasBloodPressure => _bloodPressureVital != null;
  bool get hasHemoglobin => _hemoglobinVital != null;
  bool get hasBloodGlucose => _vitals.any(
    (v) =>
        v.key.toLowerCase() == 'glucose' ||
        v.key.toLowerCase() == 'blood_glucose',
  );
  bool get hasWeight => _weightVital != null;
  bool get hasKickCount =>
      _kickCountVital != null ||
      _vitals.any(
        (v) =>
            v.key.toLowerCase() == 'kick_count' ||
            v.key.toLowerCase() == 'kicks',
      );
  bool get hasFeeding =>
      _feedingVital != null ||
      _vitals.any((v) => v.key.toLowerCase() == 'feeding');

  // Typed getters
  VitalsStreamResponse? get stepsVital => _stepsVital;
  VitalsStreamResponse? get targetVital => _targetVital;
  VitalsStreamResponse? get sleepVital => _sleepVital;
  VitalsStreamResponse? get heartRateVital => _heartRateVital;
  VitalsStreamResponse? get stressVital => _stressVital;
  VitalsStreamResponse? get hrvVital => _hrvVital;
  VitalsStreamResponse? get weightVital => _weightVital;
  VitalsStreamResponse? get heightVital => _heightVital;
  VitalsStreamResponse? get bloodOxygenVital => _bloodOxygenVital;
  VitalsStreamResponse? get bloodPressureVital => _bloodPressureVital;
  VitalsStreamResponse? get lmpDateVital => _lmpDateVital;
  VitalsStreamResponse? get hemoglobinVital => _hemoglobinVital;
  VitalsStreamResponse? get bloodGroupVital => _bloodGroupVital;
  VitalsStreamResponse? get kickCountVital => _kickCountVital;
  VitalsStreamResponse? get feedingVital => _feedingVital;

  // Safe scalar getters
  String get heartRateValue => hasHeartRate ? _heartRate : '--';
  int get stepsValue => _steps;
  String get hrvValue => hasHrv ? _hrv : '--';
  String get bloodOxygenValue => hasBloodOxygen ? _bloodOxygen : '--';
  String get stressLevel => hasStress ? _stress : '--';

  double get sleepHoursValue => hasSleep ? _sleepHours : 0.0;
  String get sleepDate => _sleepDate.isNotEmpty ? _sleepDate : 'No data';

  String get bloodPressureValue => hasBloodPressure ? _bloodPressure : '--/--';
  String get bloodPressureDate =>
      _bloodPressureDate.isNotEmpty ? _bloodPressureDate : 'No record';

  double get hemoglobinValue => hasHemoglobin ? _hemoglobin : 0.0;
  String get hemoglobinDate =>
      _hemoglobinDate.isNotEmpty ? _hemoglobinDate : 'No record';

  double get bloodGlucoseValue => hasBloodGlucose ? _bloodGlucose : 0.0;
  String get bloodGlucoseDate =>
      _bloodGlucoseDate.isNotEmpty ? _bloodGlucoseDate : 'No record';

  double get weightValue => hasWeight ? _weight : 0.0;
  String get weightDate => _weightDate.isNotEmpty ? _weightDate : 'No record';

  double get heightValue => _height;
  double get bmiValue => hasWeight ? _bmi : 0.0;

  int get kickCountValue => _kickCount;
  String get kickCountDate =>
      _kickCountDate.isNotEmpty ? _kickCountDate : 'No record';

  double get feedingValue => _feedingValue;
  String get feedingUnit => _feedingUnit;
  String get feedingDate =>
      _feedingDate.isNotEmpty ? _feedingDate : 'No record';
  String get feedingType => _feedingType;

  List<VitalsStreamResponse> getHistory(String key) =>
      List.unmodifiable(_historyByKey[key.toLowerCase()] ?? []);

  /// Returns vitals history filtered by period: 'day', 'week', or 'month'
  List<VitalsStreamResponse> getHistoryForPeriod(String key, String period) {
    final all = getHistory(key);
    if (all.isEmpty) return [];

    final now = DateTime.now();
    DateTime cutoff;
    final p = period.toLowerCase();
    if (p == 'day' || p == 'today') {
      cutoff = DateTime(now.year, now.month, now.day);
    } else if (p == 'week') {
      cutoff = now.subtract(const Duration(days: 7));
    } else {
      cutoff = now.subtract(const Duration(days: 30));
    }

    final filtered = all
        .where(
          (v) =>
              v.createdAt.isAfter(cutoff) ||
              v.createdAt.isAtSameMomentAs(cutoff),
        )
        .toList();
    filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return filtered;
  }

  double getAverageForVitalPeriod(String key, String period) {
    final list = getHistoryForPeriod(key, period);
    if (list.isEmpty) return getAverageForVital(key);
    final sum = list.map((e) => e.value).reduce((a, b) => a + b);
    return sum / list.length;
  }

  double getMinForVitalPeriod(String key, String period) {
    final list = getHistoryForPeriod(key, period);
    if (list.isEmpty) return getMinForVital(key);
    return list.map((e) => e.value).reduce((a, b) => a < b ? a : b);
  }

  double getMaxForVitalPeriod(String key, String period) {
    final list = getHistoryForPeriod(key, period);
    if (list.isEmpty) return getMaxForVital(key);
    return list.map((e) => e.value).reduce((a, b) => a > b ? a : b);
  }

  double getAverageForVital(String key) {
    final list = getHistory(key);
    if (list.isEmpty) {
      if (key == 'heart_rate' && hasHeartRate) {
        return double.tryParse(_heartRate) ?? 0.0;
      }
      if (key == 'hrv' && hasHrv) {
        return double.tryParse(_hrv) ?? 0.0;
      }
      if (key == 'blood_oxygen' && hasBloodOxygen) {
        return double.tryParse(_bloodOxygen) ?? 0.0;
      }
      return 0.0;
    }
    final sum = list.map((e) => e.value).reduce((a, b) => a + b);
    return sum / list.length;
  }

  double getMinForVital(String key) {
    final list = getHistory(key);
    if (list.isEmpty) {
      if (key == 'heart_rate' && hasHeartRate) {
        return double.tryParse(_heartRate) ?? 0.0;
      }
      if (key == 'hrv' && hasHrv) {
        return double.tryParse(_hrv) ?? 0.0;
      }
      if (key == 'blood_oxygen' && hasBloodOxygen) {
        return double.tryParse(_bloodOxygen) ?? 0.0;
      }
      return 0.0;
    }
    return list.map((e) => e.value).reduce((a, b) => a < b ? a : b);
  }

  double getMaxForVital(String key) {
    final list = getHistory(key);
    if (list.isEmpty) {
      if (key == 'heart_rate' && hasHeartRate) {
        return double.tryParse(_heartRate) ?? 0.0;
      }
      if (key == 'hrv' && hasHrv) {
        return double.tryParse(_hrv) ?? 0.0;
      }
      if (key == 'blood_oxygen' && hasBloodOxygen) {
        return double.tryParse(_bloodOxygen) ?? 0.0;
      }
      return 0.0;
    }
    return list.map((e) => e.value).reduce((a, b) => a > b ? a : b);
  }

  int get currentStepTarget {
    final vital = _targetVital;
    if (vital == null) return 6000;
    if (vital.data != null && vital.data!['stepTarget'] != null) {
      return (vital.data!['stepTarget'] as num).toInt();
    }
    return 6000;
  }

  void setUserId(String id) {
    if (_userId == id) return;
    _userId = id;
    fetchLatestVitals();
  }

  void reload() {
    final currentUserId = UserSessionManager.instance.userId;
    setUserId(currentUserId);
  }

  void reset() {
    reload();
  }

  void clearData() {
    _vitals.clear();
    _historyByKey.clear();
    _stepsVital = null;
    _targetVital = null;
    _sleepVital = null;
    _heartRateVital = null;
    _stressVital = null;
    _hrvVital = null;
    _weightVital = null;
    _heightVital = null;
    _bloodOxygenVital = null;
    _bloodPressureVital = null;
    _lmpDateVital = null;
    _hemoglobinVital = null;
    _bloodGroupVital = null;
    _kickCountVital = null;
    _feedingVital = null;
    _userId = '';
    _error = '';
    _isLoading = false;
    _applyLatestVitalsToState([]);
    update();
  }

  /// Update or replace a vital by ID in memory and local SQLite.
  void updateVitalByKey(VitalsStreamResponse newVital, {int synced = 1}) {
    final index = _vitals.indexWhere((v) => v.id == newVital.id);

    if (index != -1) {
      _vitals[index] = newVital;
    } else {
      _vitals.add(newVital);
    }

    VitalsSqLiteService().saveVitalsStreamResponse(
      newVital,
      synced: synced,
      userId: userId,
    );

    _applyLatestVitalsToState(_vitals);
    update();
  }

  Future<void> setStepTarget(int stepTarget, {String? userId}) async {
    final existingVital = _targetVital;
    final existingData = existingVital?.data ?? <String, dynamic>{};
    final newData = Map<String, dynamic>.from(existingData)
      ..['stepTarget'] = stepTarget;

    if (existingVital != null) {
      await updateVitalEntry(
        vitalId: existingVital.id,
        key: 'targets',
        value: 0.0,
        unit: '',
        createdAt: DateTime.now(),
        userId: userId,
        data: newData,
      );
    } else {
      await addVitalEntry(
        key: 'targets',
        value: 0.0,
        unit: '',
        createdAt: DateTime.now(),
        userId: userId,
        data: newData,
      );
    }
  }

  /// Fetches latest vitals from the local SQLite database.
  Future<void> fetchLatestVitals({bool showLoading = true}) async {
    try {
      if (showLoading) {
        _isLoading = true;
        update();
      }
      _error = '';

      try {
        final currentUserId = userId.trim();
        if (currentUserId.isEmpty) {
          _vitals = [];
          _applyLatestVitalsToState([]);
          return;
        }

        final localData =
            await VitalsSqLiteService().getLatestVitals(currentUserId);

        debugPrint(
          "Loaded ${localData.length} vitals from local storage for user $currentUserId",
        );

        final latestVitals = localData.map(_vitalFromDbMap).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        _vitals = latestVitals;
        _applyLatestVitalsToState(_vitals);

        // Populate history by key from local DB
        final allRows = await VitalsSqLiteService().getAllVitalsForUser(
          currentUserId,
        );
        _historyByKey.clear();
        for (final r in allRows) {
          final v = _vitalFromDbMap(r);
          _historyByKey.putIfAbsent(v.key.toLowerCase(), () => []).add(v);
        }
      } catch (e) {
        debugPrint('Error loading latest vitals from local storage: $e');
      }
    } catch (e) {
      _error = 'Error fetching local vitals: ${e.toString()}';
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      update();
    }
  }

  /// Compatibility helper for local-only reload
  Future<void> loadLatestVitalsFromLocal() =>
      fetchLatestVitals(showLoading: false);

  Future<void> syncUnsyncedVitals() async {
    // 1. Prevent concurrent syncs
    if (_isSyncing) {
      debugPrint(
        "⏳ [HealthVitalsController] Sync already in progress, skipping...",
      );
      return;
    }

    // 2. First verify internet connectivity! (Modeled after alloconnect)
    bool hasInternet = ConnectionController.instance.isInternetAvailable;
    if (!hasInternet) {
      hasInternet = await ConnectionController.instance.checkInternet();
      if (!hasInternet) {
        debugPrint(
          "📡 [HealthVitalsController] Device is offline. Postponing vitals sync until internet is restored.",
        );
        return;
      }
    }

    _isSyncing = true;
    try {
      await HealthVitalSyncService.instance.syncUnsyncedVitals();
      await fetchLatestVitals(showLoading: false);
    } catch (e) {
      debugPrint("⚠️ [HealthVitalsController] syncUnsyncedVitals warning: $e");
    } finally {
      _isSyncing = false;
      update();
    }
  }

  Future<void> syncAllVitals() async {
    await refreshAndSyncLast30Days();
  }

  VitalsStreamResponse _vitalFromDbMap(Map<String, dynamic> map) {
    final rawData = map['data'];
    final parsedData = rawData is String && rawData.isNotEmpty
        ? jsonDecode(rawData) as Map<String, dynamic>?
        : rawData as Map<String, dynamic>?;

    return VitalsStreamResponse(
      id: map['id']?.toString() ?? '',
      key: map['vital_key']?.toString() ?? '',
      value: (map['value'] is num) ? (map['value'] as num).toDouble() : 0.0,
      unit: map['unit']?.toString() ?? '',
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : (DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()),
      data: parsedData,
    );
  }

  void _applyLatestVitalsToState(List<VitalsStreamResponse> vitalsList) {
    final sortedVitals = List<VitalsStreamResponse>.from(vitalsList)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Steps
    final stepsEntry = sortedVitals
        .where((v) => v.key.toLowerCase() == 'steps')
        .firstOrNull;
    _stepsVital = stepsEntry;
    if (stepsEntry != null) {
      _steps = stepsEntry.value.toInt();
    } else {
      _steps = 0;
    }

    // Sleep
    final sleepEntry = sortedVitals
        .where(
          (v) =>
              v.key.toLowerCase() == 'sleep' ||
              v.key.toLowerCase() == 'sleep_data' ||
              v.key.toLowerCase() == 'sleep_hours',
        )
        .firstOrNull;
    _sleepVital = sleepEntry;
    if (sleepEntry != null) {
      if (sleepEntry.unit.toLowerCase().contains('min') ||
          sleepEntry.value > 24) {
        _sleepHours = (sleepEntry.value / 60.0);
      } else {
        _sleepHours = sleepEntry.value;
      }
      _sleepDate = _formatDate(sleepEntry.createdAt);
    } else {
      _sleepHours = 0.0;
      _sleepDate = '';
    }

    // Heart Rate
    final hrEntry = sortedVitals
        .where((v) => v.key.toLowerCase() == 'heart_rate')
        .firstOrNull;
    _heartRateVital = hrEntry;
    if (hrEntry != null) {
      _heartRate = hrEntry.value.toInt().toString();
    } else {
      _heartRate = '--';
    }

    // Stress
    final stressEntry = sortedVitals
        .where((v) => v.key.toLowerCase() == 'stress')
        .firstOrNull;
    _stressVital = stressEntry;
    if (stressEntry != null) {
      if (stressEntry.data != null && stressEntry.data!['level'] != null) {
        _stress = stressEntry.data!['level'].toString();
      } else if (stressEntry.value <= 30) {
        _stress = 'Low';
      } else if (stressEntry.value <= 60) {
        _stress = 'Moderate';
      } else {
        _stress = 'High';
      }
    } else {
      _stress = '--';
    }

    // HRV
    final hrvEntry = sortedVitals
        .where((v) => v.key.toLowerCase() == 'hrv')
        .firstOrNull;
    _hrvVital = hrvEntry;
    if (hrvEntry != null) {
      _hrv = hrvEntry.value.toInt().toString();
    } else {
      _hrv = '--';
    }

    // Blood Oxygen
    final spo2Entry = sortedVitals
        .where(
          (v) =>
              v.key.toLowerCase() == 'blood_oxygen' ||
              v.key.toLowerCase() == 'spo2',
        )
        .firstOrNull;
    _bloodOxygenVital = spo2Entry;
    if (spo2Entry != null) {
      _bloodOxygen = spo2Entry.value.toInt().toString();
    } else {
      _bloodOxygen = '--';
    }

    // Blood Pressure
    final bpEntry = sortedVitals
        .where((v) => v.key.toLowerCase() == 'blood_pressure')
        .firstOrNull;
    _bloodPressureVital = bpEntry;
    if (bpEntry != null) {
      if (bpEntry.data != null &&
          bpEntry.data!['systolic'] != null &&
          bpEntry.data!['diastolic'] != null) {
        _bloodPressure =
            "${bpEntry.data!['systolic']}/${bpEntry.data!['diastolic']}";
      } else {
        _bloodPressure = "${bpEntry.value.toInt()}/80";
      }
      _bloodPressureDate = _formatDate(bpEntry.createdAt);
    } else {
      _bloodPressure = '--/--';
      _bloodPressureDate = '';
    }

    // Weight & Height
    final weightEntry = sortedVitals
        .where((v) => v.key.toLowerCase() == 'weight')
        .firstOrNull;
    _weightVital = weightEntry;
    if (weightEntry != null) {
      _weight = weightEntry.value;
      _weightDate = _formatDate(weightEntry.createdAt);
    } else {
      _weight = 0.0;
      _weightDate = '';
    }

    final heightEntry = sortedVitals
        .where((v) => v.key.toLowerCase() == 'height')
        .firstOrNull;
    _heightVital = heightEntry;
    if (heightEntry != null) {
      _height = heightEntry.value;
    }

    final heightM = _height > 3 ? _height / 100.0 : _height;
    if (heightM > 0 && _weight > 0) {
      _bmi = _weight / (heightM * heightM);
    } else {
      _bmi = 0.0;
    }

    // Hemoglobin
    final hgbEntry = sortedVitals
        .where((v) => v.key.toLowerCase() == 'hemoglobin')
        .firstOrNull;
    _hemoglobinVital = hgbEntry;
    if (hgbEntry != null) {
      _hemoglobin = hgbEntry.value;
      _hemoglobinDate = _formatDate(hgbEntry.createdAt);
    } else {
      _hemoglobin = 0.0;
      _hemoglobinDate = '';
    }

    // Blood Glucose
    final glucoseEntry = sortedVitals
        .where(
          (v) =>
              v.key.toLowerCase() == 'glucose' ||
              v.key.toLowerCase() == 'blood_glucose',
        )
        .firstOrNull;
    if (glucoseEntry != null) {
      _bloodGlucose = glucoseEntry.value;
      _bloodGlucoseDate = _formatDate(glucoseEntry.createdAt);
    } else {
      _bloodGlucose = 0.0;
      _bloodGlucoseDate = '';
    }

    // Blood Group
    final bgEntry = sortedVitals
        .where((v) => v.key.toLowerCase() == 'blood_group')
        .firstOrNull;
    _bloodGroupVital = bgEntry;

    // LMP Date
    final lmpEntry = sortedVitals
        .where(
          (v) =>
              v.key.toLowerCase() == 'lmp_date' &&
              (v.data?.containsKey('lmp_date') ?? false),
        )
        .firstOrNull;
    _lmpDateVital = lmpEntry;

    // Targets
    final targetEntry = sortedVitals
        .where((v) => v.key.toLowerCase() == 'targets')
        .firstOrNull;
    _targetVital = targetEntry;

    // Kick Count (key: kick_count or kicks)
    final kickEntry = sortedVitals
        .where(
          (v) =>
              v.key.toLowerCase() == 'kick_count' ||
              v.key.toLowerCase() == 'kicks',
        )
        .firstOrNull;
    _kickCountVital = kickEntry;
    if (kickEntry != null) {
      _kickCount = kickEntry.value.toInt();
      _kickCountDate = _formatDate(kickEntry.createdAt);
    } else {
      _kickCount = 0;
      _kickCountDate = '';
    }

    // Feeding (key: feeding)
    final feedingEntry = sortedVitals
        .where((v) => v.key.toLowerCase() == 'feeding')
        .firstOrNull;
    _feedingVital = feedingEntry;
    if (feedingEntry != null) {
      _feedingValue = feedingEntry.value;
      _feedingUnit = feedingEntry.unit.isNotEmpty ? feedingEntry.unit : 'mins';
      _feedingDate = _formatDate(feedingEntry.createdAt);
      _feedingType = feedingEntry.data?['type']?.toString() ?? 'Breastfeeding';
    } else {
      _feedingValue = 0.0;
      _feedingUnit = 'mins';
      _feedingDate = '';
      _feedingType = 'Breastfeeding';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  bool _isSyncingLast30Days = false;

  /// Reloads the last [days] of vitals from local SQLite.
  ///
  /// Local-only: the previous `VitalsApi.getUserVitalsHistory` pull was
  /// removed, so history comes purely from what this device recorded.
  Future<void> refreshAndSyncLast30Days({int days = 30}) async {
    if (_isSyncingLast30Days) return;
    _isSyncingLast30Days = true;
    try {
      _isLoading = true;
      _error = '';
      await fetchLatestVitals(showLoading: false);
    } catch (e) {
      _error = 'Error loading $days-day vitals: ${e.toString()}';
      debugPrint(
        "⚠️ [HealthVitalsController] refreshAndSyncLast30Days error: $e",
      );
    } finally {
      _isSyncingLast30Days = false;
      _isLoading = false;
      update();
    }
  }

  /// Adds a new vital entry, persists locally in SQLite and attempts server sync
  Future<VitalsStreamResponse?> addVitalEntry({
    required String key,
    required double value,
    required String unit,
    DateTime? createdAt,
    String? userId,
    Map<String, dynamic>? data,
  }) async {
    try {
      _isLoading = true;
      _error = '';

      final targetUserId = userId?.trim().isNotEmpty == true
          ? userId!.trim()
          : this.userId;
      final recordTime = createdAt ?? DateTime.now();
      final vitalId = const Uuid().v7();

      // Save to SQLite first (mark as unsynced)
      await VitalsSqLiteService().saveVital(
        id: vitalId,
        key: key,
        value: value,
        unit: unit,
        createdAt: recordTime,
        userId: targetUserId,
        additionalData: data,
        synced: 0,
      );

      final localVital = VitalsStreamResponse(
        id: vitalId,
        key: key,
        value: value,
        unit: unit,
        createdAt: recordTime,
        data: data,
      );

      _updateLocalState(key, value, unit, recordTime, data);
      _historyByKey
          .putIfAbsent(key.toLowerCase(), () => [])
          .insert(0, localVital);
      update();

      // Attempt background API sync through HealthVitalSyncService if online
      if (ConnectionController.instance.isInternetAvailable) {
        HealthVitalSyncService.instance.syncUnsyncedVitals();
      }

      await fetchLatestVitals(showLoading: false);
      return localVital;
    } catch (e) {
      _error = 'Error adding vital: ${e.toString()}';
      debugPrint("⚠️ [HealthVitalsController] addVitalEntry error: $e");
      return null;
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<VitalsStreamResponse?> addBloodPressureEntry({
    required int systolic,
    required int diastolic,
    int? pulse,
    DateTime? createdAt,
    String? userId,
  }) async {
    return addVitalEntry(
      key: 'blood_pressure',
      value: systolic.toDouble(),
      unit: 'mmHg',
      createdAt: createdAt,
      userId: userId,
      data: {
        'systolic': systolic,
        'diastolic': diastolic,
        if (pulse != null) 'pulse': pulse,
      },
    );
  }

  Future<VitalsStreamResponse?> addHeartRateEntry({
    required int bpm,
    DateTime? createdAt,
    String? state,
  }) async {
    return addVitalEntry(
      key: 'heart_rate',
      value: bpm.toDouble(),
      unit: 'bpm',
      createdAt: createdAt,
      data: {'heartRate': bpm, if (state != null) 'state': state},
    );
  }

  Future<VitalsStreamResponse?> addStepsEntry({
    required int steps,
    DateTime? createdAt,
  }) async {
    final km = (steps * 0.00078).toStringAsFixed(2);
    final kcal = (steps * 0.04).toInt();
    return addVitalEntry(
      key: 'steps',
      value: steps.toDouble(),
      unit: 'steps',
      createdAt: createdAt,
      data: {'steps': steps, 'distanceKm': km, 'calories': kcal},
    );
  }

  Future<VitalsStreamResponse?> addSleepEntry({
    required double hours,
    DateTime? createdAt,
    double? deepSleepHours,
  }) async {
    final mins = (hours * 60).toInt();
    final deep = deepSleepHours ?? (hours * 0.25);
    return addVitalEntry(
      key: 'sleep',
      value: hours,
      unit: 'hours',
      createdAt: createdAt,
      data: {
        'totalMinutes': mins,
        'hours': hours,
        'deepSleep': deep,
        'lightSleep': hours - deep,
      },
    );
  }

  Future<VitalsStreamResponse?> addHrvEntry({
    required int hrvMs,
    DateTime? createdAt,
  }) async {
    return addVitalEntry(
      key: 'hrv',
      value: hrvMs.toDouble(),
      unit: 'ms',
      createdAt: createdAt,
      data: {'hrv': hrvMs},
    );
  }

  Future<VitalsStreamResponse?> addBloodOxygenEntry({
    required double spo2Percent,
    DateTime? createdAt,
  }) async {
    return addVitalEntry(
      key: 'blood_oxygen',
      value: spo2Percent,
      unit: '%',
      createdAt: createdAt,
      data: {'spo2': spo2Percent},
    );
  }

  Future<VitalsStreamResponse?> addStressEntry({
    required int stressScore,
    DateTime? createdAt,
  }) async {
    return addVitalEntry(
      key: 'stress',
      value: stressScore.toDouble(),
      unit: 'score',
      createdAt: createdAt,
      data: {'stressScore': stressScore},
    );
  }

  Future<VitalsStreamResponse?> addHemoglobinEntry({
    required double hemoglobinGdl,
    DateTime? createdAt,
  }) async {
    return addVitalEntry(
      key: 'hemoglobin',
      value: hemoglobinGdl,
      unit: 'g/dL',
      createdAt: createdAt,
      data: {'hemoglobin': hemoglobinGdl},
    );
  }

  Future<VitalsStreamResponse?> addBloodGlucoseEntry({
    required double mgDl,
    String? mealPhase,
    DateTime? createdAt,
  }) async {
    return addVitalEntry(
      key: 'glucose',
      value: mgDl,
      unit: 'mg/dL',
      createdAt: createdAt,
      data: {'glucose': mgDl, 'mealPhase': mealPhase ?? 'fasting'},
    );
  }

  Future<VitalsStreamResponse?> addWeightEntry({
    required double weightKg,
    double? heightCm,
    DateTime? createdAt,
  }) async {
    final h = (heightCm ?? _height) > 0 ? (heightCm ?? _height) : 162.0;
    final hM = h / 100.0;
    final bmi = weightKg / (hM * hM);
    return addVitalEntry(
      key: 'weight',
      value: weightKg,
      unit: 'kg',
      createdAt: createdAt,
      data: {
        'weight': weightKg,
        'height': h,
        'bmi': double.parse(bmi.toStringAsFixed(1)),
      },
    );
  }

  Future<VitalsStreamResponse?> addKickCountEntry({
    required int count,
    int? durationMinutes,
    String? timeStr,
    DateTime? createdAt,
    String? userId,
    Map<String, dynamic>? extraData,
  }) async {
    return addVitalEntry(
      key: 'kick_count',
      value: count.toDouble(),
      unit: 'kicks',
      createdAt: createdAt,
      userId: userId,
      data: {
        'count': count,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        if (timeStr != null) 'time': timeStr,
        if (extraData != null) ...extraData,
      },
    );
  }

  Future<VitalsStreamResponse?> addFeedingEntry({
    required double value,
    required String unit,
    String? feedingType,
    String? side,
    int? leftMinutes,
    int? rightMinutes,
    int? amountMl,
    DateTime? createdAt,
    String? userId,
    Map<String, dynamic>? extraData,
  }) async {
    return addVitalEntry(
      key: 'feeding',
      value: value,
      unit: unit,
      createdAt: createdAt,
      userId: userId,
      data: {
        'count': value,
        'amount': value,
        'type': feedingType ?? 'Breastfeeding',
        if (side != null) 'side': side,
        if (leftMinutes != null) 'leftMinutes': leftMinutes,
        if (rightMinutes != null) 'rightMinutes': rightMinutes,
        if (amountMl != null) 'amountMl': amountMl,
        if (extraData != null) ...extraData,
      },
    );
  }

  Future<VitalsStreamResponse?> addVitalDailyData({
    required String key,
    required double value,
    required String unit,
    DateTime? createdAt,
    String? userId,
    Map<String, dynamic>? data,
  }) async {
    try {
      _isLoading = true;
      _error = '';

      final targetUserId = userId?.trim().isNotEmpty == true
          ? userId!.trim()
          : this.userId;
      final recordTime = createdAt ?? DateTime.now();
      final vitalId = const Uuid().v7();

      await VitalsSqLiteService().saveVital(
        id: vitalId,
        key: key,
        value: value,
        unit: unit,
        createdAt: recordTime,
        userId: targetUserId,
        additionalData: data,
        synced: 0,
      );

      final localVital = VitalsStreamResponse(
        id: vitalId,
        key: key,
        value: value,
        unit: unit,
        createdAt: recordTime,
        data: data,
      );

      _updateLocalState(key, value, unit, recordTime, data);
      updateVitalByKey(localVital, synced: 0);

      // Attempt background API sync through HealthVitalSyncService if online
      if (ConnectionController.instance.isInternetAvailable) {
        HealthVitalSyncService.instance.syncUnsyncedVitals();
      }

      await fetchLatestVitals(showLoading: false);
      return localVital;
    } catch (e) {
      _error = 'Error adding daily vital: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      update();
    }
  }

  void _updateLocalState(
    String key,
    double value,
    String unit,
    DateTime time,
    Map<String, dynamic>? data,
  ) {
    switch (key.toLowerCase()) {
      case 'blood_pressure':
        if (data != null &&
            data['systolic'] != null &&
            data['diastolic'] != null) {
          _bloodPressure = "${data['systolic']}/${data['diastolic']}";
        } else {
          _bloodPressure = "${value.toInt()}/80";
        }
        _bloodPressureDate = 'Today';
        break;
      case 'hemoglobin':
        _hemoglobin = value;
        _hemoglobinDate = 'Today';
        break;
      case 'glucose':
      case 'blood_glucose':
        _bloodGlucose = value;
        _bloodGlucoseDate = 'Today';
        break;
      case 'weight':
        _weight = value;
        _weightDate = 'Today';
        final heightM = _height > 3 ? _height / 100.0 : _height;
        if (heightM > 0) _bmi = _weight / (heightM * heightM);
        break;
      case 'heart_rate':
        _heartRate = value.toInt().toString();
        break;
      case 'steps':
        _steps = value.toInt();
        break;
      case 'hrv':
        _hrv = value.toInt().toString();
        break;
      case 'blood_oxygen':
      case 'spo2':
        _bloodOxygen = value.toInt().toString();
        break;
      case 'feeding':
        _feedingValue = value;
        _feedingUnit = unit;
        _feedingDate = _formatDate(time);
        _feedingType = data?['type']?.toString() ?? 'Breastfeeding';
        break;
      case 'kick_count':
      case 'kicks':
        _kickCount = value.toInt();
        _kickCountDate = _formatDate(time);
        break;
    }
  }

  Future<VitalsStreamResponse?> updateVitalEntry({
    required String vitalId,
    required String key,
    required double value,
    required String unit,
    required DateTime createdAt,
    String? userId,
    Map<String, dynamic>? data,
  }) async {
    try {
      _isLoading = true;
      _error = '';

      final targetUserId = userId?.trim().isNotEmpty == true
          ? userId!.trim()
          : this.userId;

      await VitalsSqLiteService().saveVital(
        id: vitalId,
        key: key,
        value: value,
        unit: unit,
        createdAt: createdAt,
        userId: targetUserId,
        additionalData: data,
        synced: 0,
      );

      final localVital = VitalsStreamResponse(
        id: vitalId,
        key: key,
        value: value,
        unit: unit,
        createdAt: createdAt,
        data: data,
      );

      updateVitalByKey(localVital, synced: 0);

      // Attempt background API sync through HealthVitalSyncService if online
      if (ConnectionController.instance.isInternetAvailable) {
        HealthVitalSyncService.instance.syncUnsyncedVitals();
      }

      await fetchLatestVitals(showLoading: false);
      return localVital;
    } catch (e) {
      _error = 'Error updating vital: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<VitalsStreamResponse?> deleteVital(
    String vitalId, {
    String? userId,
    required DateTime createdAt,
  }) async {
    return updateVitalEntry(
      vitalId: vitalId,
      key: 'deleted',
      value: 0.0,
      unit: '',
      createdAt: createdAt,
      userId: userId,
      data: <String, dynamic>{},
    );
  }

  /// Get the latest value for a specific vital key
  VitalsStreamResponse? getLatestVitalByKey(String key) {
    try {
      final matches = _vitals
          .where((v) => v.key.toLowerCase() == key.toLowerCase())
          .toList();
      if (matches.isEmpty) return null;
      matches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return matches.first;
    } catch (e) {
      return null;
    }
  }

  /// Get today's vital value for a specific vital key
  VitalsStreamResponse? getTodayVitalByKey(String key) {
    try {
      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);
      final endOfToday = startOfToday.add(const Duration(days: 1));

      final matches = _vitals.where((v) {
        final vitalDate = v.createdAt;
        return v.key.toLowerCase() == key.toLowerCase() &&
            (vitalDate.isAfter(startOfToday) ||
                vitalDate.isAtSameMomentAs(startOfToday)) &&
            vitalDate.isBefore(endOfToday);
      }).toList();

      if (matches.isEmpty) return null;
      matches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return matches.first;
    } catch (e) {
      return null;
    }
  }

  /// Get all latest vitals as a map (key -> value)
  Map<String, double> getVitalsMap() {
    return {for (var vital in _vitals) vital.key: vital.value};
  }

  Future<List<VitalsStreamResponse>> getVitalsHistory(
    String userId,
    String type, {
    DateTime? fromDate,
    DateTime? toDate,
    double? valueFrom,
    double? valueTo,
  }) async {
    try {
      _isLoading = true;
      _error = '';

      final localData = await VitalsSqLiteService().getVitalsHistory(
        userId,
        type,
        fromDate: fromDate,
        toDate: toDate,
      );

      final history = localData.map(_vitalFromDbMap).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return history;
    } catch (e) {
      _error = 'Error getting local vitals history: ${e.toString()}';
      return <VitalsStreamResponse>[];
    } finally {
      _isLoading = false;
      update();
    }
  }

  double calculateTodayTotalCalories({
    double? newValue,
    String? excludeVitalId,
  }) {
    final startOfToday = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final endOfToday = startOfToday.add(const Duration(days: 1));

    double total = 0.0;
    for (var vital in _vitals) {
      if ((vital.createdAt.isAfter(startOfToday) ||
              vital.createdAt.isAtSameMomentAs(startOfToday)) &&
          vital.createdAt.isBefore(endOfToday)) {
        final k = vital.key.toLowerCase();
        if (k == 'food' ||
            k == 'break_fast' ||
            k == 'breakfast' ||
            k == 'lunch' ||
            k == 'dinner' ||
            k == 'snacks') {
          if (excludeVitalId != null && vital.id == excludeVitalId) {
            continue;
          }
          total += vital.value;
        }
      }
    }

    if (newValue != null) {
      total += newValue;
    }
    return total;
  }
}
