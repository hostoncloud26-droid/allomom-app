import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/repositories/user_session_manager.dart';
import 'package:allomom/services/api/vitals_api.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

class HealthVitalsController extends ChangeNotifier {
  static final HealthVitalsController instance = HealthVitalsController._internal();
  HealthVitalsController._internal();

  bool _isLoading = false;
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

  // Formatted / Derived scalar values for quick rendering
  String _heartRate = '78';
  int _steps = 4280;
  String _hrv = '52';
  String _bloodOxygen = '98';
  String _stress = 'Low';

  double _sleepHours = 8.0;
  String _sleepDate = 'Today';

  String _bloodPressure = '118/76';
  String _bloodPressureDate = 'Today';

  double _hemoglobin = 10.8;
  String _hemoglobinDate = 'Today';

  double _bloodGlucose = 92.0;
  String _bloodGlucoseDate = 'Today';

  double _weight = 62.5;
  String _weightDate = 'Today';

  double _height = 162.0;
  double _bmi = 24.1;

  // Getters
  bool get isLoading => _isLoading;
  String get error => _error;
  String get userId => _userId.isNotEmpty ? _userId : UserSessionManager.instance.userId;
  List<VitalsStreamResponse> get vitals => List.unmodifiable(_vitals);

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

  // Scalar backward-compatible getters
  String get heartRateValue => _heartRate;
  int get stepsValue => _steps;
  String get hrvValue => _hrv;
  String get bloodOxygenValue => _bloodOxygen;
  String get stressLevel => _stress;

  double get sleepHoursValue => _sleepHours;
  String get sleepDate => _sleepDate;

  String get bloodPressureValue => _bloodPressure;
  String get bloodPressureDate => _bloodPressureDate;

  double get hemoglobinValue => _hemoglobin;
  String get hemoglobinDate => _hemoglobinDate;

  double get bloodGlucoseValue => _bloodGlucose;
  String get bloodGlucoseDate => _bloodGlucoseDate;

  double get weightValue => _weight;
  String get weightDate => _weightDate;

  double get heightValue => _height;
  double get bmiValue => _bmi;

  List<VitalsStreamResponse> getHistory(String key) =>
      List.unmodifiable(_historyByKey[key.toLowerCase()] ?? []);

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
    _error = '';
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setStepTarget(int stepTarget, {String? userId}) async {
    final existingVital = _targetVital;
    final existingData = existingVital?.data ?? <String, dynamic>{};
    final newData = Map<String, dynamic>.from(existingData)..['stepTarget'] = stepTarget;

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

  /// Fetches latest vitals from local SQLite database first, then syncs from API
  Future<void> fetchLatestVitals({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }
    _error = '';

    try {
      await _loadLatestVitalsFromLocal();
    } catch (e) {
      _error = 'Error fetching local vitals: ${e.toString()}';
      debugPrint("⚠️ [HealthVitalsController] fetchLatestVitals error: $e");
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> _loadLatestVitalsFromLocal() async {
    try {
      final currentUserId = userId;
      var localData = await VitalsSqLiteService().getLatestVitals(currentUserId);

      // If no data in local DB, attempt fetching from API
      if (localData.isEmpty) {
        await refreshAndSyncLast30Days();
        localData = await VitalsSqLiteService().getLatestVitals(currentUserId);
      }

      final latestVitals = localData.map(_vitalFromDbMap).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _vitals = latestVitals;
      _applyLatestVitalsToState(_vitals);

      // Populate history by key from local DB
      final allRows = await VitalsSqLiteService().getAllVitalsForUser(currentUserId);
      _historyByKey.clear();
      for (final r in allRows) {
        final v = _vitalFromDbMap(r);
        _historyByKey.putIfAbsent(v.key.toLowerCase(), () => []).add(v);
      }
    } catch (e) {
      debugPrint("⚠️ [HealthVitalsController] Error loading latest vitals from local: $e");
    }
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
    final startOfToday = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final sortedVitals = List<VitalsStreamResponse>.from(vitalsList)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Steps
    final stepsEntry = sortedVitals.where((v) => v.key.toLowerCase() == 'steps').firstOrNull;
    if (stepsEntry != null &&
        (stepsEntry.createdAt.isAfter(startOfToday) ||
            stepsEntry.createdAt.isAtSameMomentAs(startOfToday))) {
      _stepsVital = stepsEntry;
      _steps = stepsEntry.value.toInt();
    } else {
      _stepsVital = stepsEntry;
      if (stepsEntry != null) {
        _steps = stepsEntry.value.toInt();
      }
    }

    // Sleep
    final sleepEntry = sortedVitals.where((v) =>
        v.key.toLowerCase() == 'sleep' ||
        v.key.toLowerCase() == 'sleep_data' ||
        v.key.toLowerCase() == 'sleep_hours').firstOrNull;
    _sleepVital = sleepEntry;
    if (sleepEntry != null) {
      if (sleepEntry.unit.toLowerCase().contains('min') || sleepEntry.value > 24) {
        _sleepHours = (sleepEntry.value / 60.0);
      } else {
        _sleepHours = sleepEntry.value;
      }
      _sleepDate = _formatDate(sleepEntry.createdAt);
    }

    // Heart Rate
    final hrEntry = sortedVitals.where((v) => v.key.toLowerCase() == 'heart_rate').firstOrNull;
    _heartRateVital = hrEntry;
    if (hrEntry != null) {
      _heartRate = hrEntry.value.toInt().toString();
    }

    // Stress
    final stressEntry = sortedVitals.where((v) => v.key.toLowerCase() == 'stress').firstOrNull;
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
    }

    // HRV
    final hrvEntry = sortedVitals.where((v) => v.key.toLowerCase() == 'hrv').firstOrNull;
    _hrvVital = hrvEntry;
    if (hrvEntry != null) {
      _hrv = hrvEntry.value.toInt().toString();
    }

    // Blood Oxygen
    final spo2Entry = sortedVitals.where((v) =>
        v.key.toLowerCase() == 'blood_oxygen' || v.key.toLowerCase() == 'spo2').firstOrNull;
    _bloodOxygenVital = spo2Entry;
    if (spo2Entry != null) {
      _bloodOxygen = spo2Entry.value.toInt().toString();
    }

    // Blood Pressure
    final bpEntry = sortedVitals.where((v) => v.key.toLowerCase() == 'blood_pressure').firstOrNull;
    _bloodPressureVital = bpEntry;
    if (bpEntry != null) {
      if (bpEntry.data != null && bpEntry.data!['systolic'] != null && bpEntry.data!['diastolic'] != null) {
        _bloodPressure = "${bpEntry.data!['systolic']}/${bpEntry.data!['diastolic']}";
      } else {
        _bloodPressure = "${bpEntry.value.toInt()}/80";
      }
      _bloodPressureDate = _formatDate(bpEntry.createdAt);
    }

    // Weight & Height
    final weightEntry = sortedVitals.where((v) => v.key.toLowerCase() == 'weight').firstOrNull;
    _weightVital = weightEntry;
    if (weightEntry != null) {
      _weight = weightEntry.value;
      _weightDate = _formatDate(weightEntry.createdAt);
    }

    final heightEntry = sortedVitals.where((v) => v.key.toLowerCase() == 'height').firstOrNull;
    _heightVital = heightEntry;
    if (heightEntry != null) {
      _height = heightEntry.value;
    }

    final heightM = _height > 3 ? _height / 100.0 : _height;
    if (heightM > 0) {
      _bmi = _weight / (heightM * heightM);
    }

    // Hemoglobin
    final hgbEntry = sortedVitals.where((v) => v.key.toLowerCase() == 'hemoglobin').firstOrNull;
    _hemoglobinVital = hgbEntry;
    if (hgbEntry != null) {
      _hemoglobin = hgbEntry.value;
      _hemoglobinDate = _formatDate(hgbEntry.createdAt);
    }

    // Blood Glucose
    final glucoseEntry = sortedVitals.where((v) =>
        v.key.toLowerCase() == 'glucose' || v.key.toLowerCase() == 'blood_glucose').firstOrNull;
    if (glucoseEntry != null) {
      _bloodGlucose = glucoseEntry.value;
      _bloodGlucoseDate = _formatDate(glucoseEntry.createdAt);
    }

    // Blood Group
    final bgEntry = sortedVitals.where((v) => v.key.toLowerCase() == 'blood_group').firstOrNull;
    _bloodGroupVital = bgEntry;

    // LMP Date
    final lmpEntry = sortedVitals.where((v) =>
        v.key.toLowerCase() == 'lmp_date' && (v.data?.containsKey('lmp_date') ?? false)).firstOrNull;
    _lmpDateVital = lmpEntry;

    // Targets
    final targetEntry = sortedVitals.where((v) => v.key.toLowerCase() == 'targets').firstOrNull;
    _targetVital = targetEntry;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    }
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  /// Refreshes and syncs vitals history from the server for the last N days
  Future<void> refreshAndSyncLast30Days({int days = 30}) async {
    try {
      _isLoading = true;
      _error = '';

      final targetUserId = userId;
      if (targetUserId.isEmpty) {
        return;
      }

      final now = DateTime.now();
      final fromDate = now.subtract(Duration(days: days));
      final syncedHistory = <VitalsStreamResponse>[];

      final response = await VitalsApi.getUserVitalsHistory(
        targetUserId,
        fromDate: fromDate,
        toDate: now,
      );

      if (response.success) {
        if (response.items is List) {
          syncedHistory.addAll(VitalsStreamResponse.fromJsonArray(response.items as List<dynamic>));
        } else if (response.item is Map<String, dynamic>) {
          syncedHistory.add(VitalsStreamResponse.fromJson(response.item as Map<String, dynamic>));
        } else if (response.item is List) {
          syncedHistory.addAll(VitalsStreamResponse.fromJsonArray(response.item as List<dynamic>));
        }
      }

      if (syncedHistory.isNotEmpty) {
        await VitalsSqLiteService().saveVitalsStreamResponsesBulk(
          syncedHistory,
          synced: 1,
          userId: targetUserId,
        );
      }

      await _loadLatestVitalsFromLocal();
    } catch (e) {
      _error = 'Error syncing 30-day vitals: ${e.toString()}';
      debugPrint("⚠️ [HealthVitalsController] refreshAndSyncLast30Days error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
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

      final targetUserId = userId?.trim().isNotEmpty == true ? userId!.trim() : this.userId;
      final recordTime = createdAt ?? DateTime.now();
      final vitalId = const Uuid().v7();

      // Save to SQLite first
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
      notifyListeners();

      // Attempt background API sync
      try {
        final response = await VitalsApi.addVital(
          key,
          value,
          unit,
          recordTime,
          userId: targetUserId.isNotEmpty ? targetUserId : null,
          data: data,
          id: vitalId,
        );
        if (response.success) {
          await VitalsSqLiteService().markAsSynced(vitalId);
        }
      } catch (syncErr) {
        debugPrint("⚠️ [HealthVitalsController] API addVital sync optional warning: $syncErr");
      }

      await _loadLatestVitalsFromLocal();
      return localVital;
    } catch (e) {
      _error = 'Error adding vital: ${e.toString()}';
      debugPrint("⚠️ [HealthVitalsController] addVitalEntry error: $e");
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
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

      final targetUserId = userId?.trim().isNotEmpty == true ? userId!.trim() : this.userId;
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
      notifyListeners();

      try {
        final response = await VitalsApi.addVitalDailyData(
          key,
          value,
          unit,
          recordTime,
          data,
          targetUserId.isNotEmpty ? targetUserId : null,
        );
        if (response.success) {
          await VitalsSqLiteService().markAsSynced(vitalId);
        }
      } catch (syncErr) {
        debugPrint("⚠️ [HealthVitalsController] API addVitalDailyData sync warning: $syncErr");
      }

      await _loadLatestVitalsFromLocal();
      return localVital;
    } catch (e) {
      _error = 'Error adding daily vital: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateLocalState(String key, double value, String unit, DateTime time, Map<String, dynamic>? data) {
    switch (key.toLowerCase()) {
      case 'blood_pressure':
        if (data != null && data['systolic'] != null && data['diastolic'] != null) {
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

      final targetUserId = userId?.trim().isNotEmpty == true ? userId!.trim() : this.userId;

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

      _updateLocalState(key, value, unit, createdAt, data);

      try {
        final res = await VitalsApi.updateVital(
          vitalId,
          key,
          value,
          unit,
          createdAt,
          data: data,
        );
        if (res.success) {
          await VitalsSqLiteService().markAsSynced(vitalId);
        }
      } catch (err) {
        debugPrint("⚠️ [HealthVitalsController] API updateVital sync warning: $err");
      }

      await _loadLatestVitalsFromLocal();
      return localVital;
    } catch (e) {
      _error = 'Error updating vital: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
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
      final matches = _vitals.where((v) => v.key.toLowerCase() == key.toLowerCase()).toList();
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
            (vitalDate.isAfter(startOfToday) || vitalDate.isAtSameMomentAs(startOfToday)) &&
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
      notifyListeners();
    }
  }

  double calculateTodayTotalCalories({double? newValue, String? excludeVitalId}) {
    final startOfToday = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final endOfToday = startOfToday.add(const Duration(days: 1));

    double total = 0.0;
    for (var vital in _vitals) {
      if ((vital.createdAt.isAfter(startOfToday) || vital.createdAt.isAtSameMomentAs(startOfToday)) &&
          vital.createdAt.isBefore(endOfToday)) {
        final k = vital.key.toLowerCase();
        if (k == 'food' || k == 'break_fast' || k == 'breakfast' || k == 'lunch' || k == 'dinner' || k == 'snacks') {
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
