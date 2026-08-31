import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' as drift;
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/user_db_service.dart';
import 'package:allomom/services/sq_lite/services/health_db_service.dart';
import 'package:allomom/services/api/api_base.dart';
import 'package:allomom/services/api/auth_api.dart';

class UserSessionManager extends ChangeNotifier {
  static final UserSessionManager instance = UserSessionManager._internal();
  UserSessionManager._internal();

  User? _currentUser;
  HealthDataTableData? _currentHealthData;
  Pregnancy? _currentPregnancy;
  bool _isLoading = true;

  // Local storage cached properties
  String? _userName;
  String? _userPhone;
  String? _countryCode;
  String? _pregnancyStatus;
  DateTime? _lmpDate;
  DateTime? _eddDate;
  String? _partnerName;
  String? _partnerPhone;
  bool _hasKids = false;
  int _kidsCount = 0;
  bool _isLoggedIn = false;

  User? get currentUser => _currentUser;
  HealthDataTableData? get currentHealthData => _currentHealthData;
  Pregnancy? get currentPregnancy => _currentPregnancy;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isLoggedIn;

  String get userName => _userName ?? _currentUser?.name ?? 'Ananya';
  String get userPhone => _userPhone ?? _currentUser?.phone ?? '';
  String get countryCode => _countryCode ?? _currentUser?.countryCode ?? '+91';
  String get pregnancyStatus => _pregnancyStatus ?? _currentHealthData?.pregnancyStatus ?? 'pregnant';
  DateTime? get lmpDate => _lmpDate ?? _currentHealthData?.lmpDate ?? _currentPregnancy?.lmpDate;
  DateTime? get eddDate => _eddDate ?? _currentHealthData?.edDate ?? _currentPregnancy?.edDate;
  String? get partnerName => _partnerName;
  String? get partnerPhone => _partnerPhone;
  bool get hasKids => _hasKids;
  int get kidsCount => _kidsCount;

  int get currentGestationalWeek {
    final lmp = lmpDate;
    final now = DateTime.now();
    if (lmp != null) {
      final days = now.difference(lmp).inDays;
      if (days >= 0) {
        return (days ~/ 7) + 1;
      }
    }
    final edd = eddDate;
    if (edd != null) {
      final daysRemaining = edd.difference(now).inDays;
      final daysPassed = 280 - daysRemaining;
      if (daysPassed > 0) {
        return (daysPassed ~/ 7) + 1;
      }
    }
    return 24;
  }

  String get currentTrimester {
    final week = currentGestationalWeek;
    if (week <= 12) return 'First trimester';
    if (week <= 26) return 'Second trimester';
    return 'Third trimester';
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      if (_isLoggedIn) {
        _userName = prefs.getString('user_name');
        _userPhone = prefs.getString('user_phone');
        _countryCode = prefs.getString('country_code');
        _pregnancyStatus = prefs.getString('pregnancy_status') ?? 'pregnant';
        final lmpStr = prefs.getString('lmp_date');
        final eddStr = prefs.getString('edd_date');
        if (lmpStr != null && lmpStr.isNotEmpty) {
          _lmpDate = DateTime.tryParse(lmpStr);
        }
        if (eddStr != null && eddStr.isNotEmpty) {
          _eddDate = DateTime.tryParse(eddStr);
        }
        _partnerName = prefs.getString('partner_name');
        _partnerPhone = prefs.getString('partner_phone');
        _hasKids = prefs.getBool('has_kids') ?? false;
        _kidsCount = prefs.getInt('kids_count') ?? 0;

        final active = await UserDbService.instance.getActiveUser();
        if (active != null) {
          _currentUser = active;
          await _loadHealthAndPregnancy(_currentUser!);
        }
      }
    } catch (e) {
      debugPrint('Error initializing UserSessionManager: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadHealthAndPregnancy(User user) async {
    if (user.healthDataID != null && user.healthDataID!.isNotEmpty) {
      _currentHealthData =
          await HealthDbService.instance.getHealthDataById(user.healthDataID!);
      if (_currentHealthData != null) {
        _currentPregnancy = await HealthDbService.instance
            .getActivePregnancy(_currentHealthData!.id);
      }
    }
  }

  /// Save full user registration details to local storage and SQLite
  Future<void> saveRegistration({
    required String name,
    required String phone,
    String countryCode = '+91',
    String pregnancyStatus = 'pregnant',
    DateTime? lmpDate,
    DateTime? eddDate,
    String? partnerName,
    String? partnerPhone,
    bool hasKids = false,
    int kidsCount = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_name', name);
    await prefs.setString('user_phone', phone);
    await prefs.setString('country_code', countryCode);
    await prefs.setString('pregnancy_status', pregnancyStatus);
    if (lmpDate != null) {
      await prefs.setString('lmp_date', lmpDate.toIso8601String());
    }
    if (eddDate != null) {
      await prefs.setString('edd_date', eddDate.toIso8601String());
    }
    if (partnerName != null) {
      await prefs.setString('partner_name', partnerName);
    }
    if (partnerPhone != null) {
      await prefs.setString('partner_phone', partnerPhone);
    }
    await prefs.setBool('has_kids', hasKids);
    await prefs.setInt('kids_count', kidsCount);

    _isLoggedIn = true;
    _userName = name;
    _userPhone = phone;
    _countryCode = countryCode;
    _pregnancyStatus = pregnancyStatus;
    _lmpDate = lmpDate;
    _eddDate = eddDate;
    _partnerName = partnerName;
    _partnerPhone = partnerPhone;
    _hasKids = hasKids;
    _kidsCount = kidsCount;

    final userId = "usr_${DateTime.now().millisecondsSinceEpoch}";
    final healthId = "hd_${DateTime.now().millisecondsSinceEpoch}";

    await setAuthenticatedSession(
      userId: userId,
      jwt: "local_jwt_token",
      refresh: "local_refresh_token",
      name: name,
      phone: phone,
      healthDataId: healthId,
      pregnancyStatus: pregnancyStatus,
      eddDate: eddDate,
      lmpDate: lmpDate,
    );

    notifyListeners();
  }

  /// Sets authenticated session in SQLite database
  Future<void> setAuthenticatedSession({
    required String userId,
    required String jwt,
    String? refresh,
    String? name,
    String? phone,
    String? email,
    String? healthDataId,
    String? pregnancyStatus,
    DateTime? eddDate,
    DateTime? lmpDate,
  }) async {
    await ApiBase.setJwt(jwt);
    if (refresh != null) {
      await ApiBase.setRefreshToken(refresh);
    }

    final savedUser = await UserDbService.instance.saveUser(
      UsersCompanion(
        id: drift.Value(userId),
        name: drift.Value(name ?? _userName ?? "Mommy"),
        phone: drift.Value(phone ?? _userPhone ?? ""),
        email: drift.Value(email ?? ""),
        healthDataID: drift.Value(healthDataId),
        isDeleted: const drift.Value(false),
      ),
    );

    if (healthDataId != null && healthDataId.isNotEmpty) {
      await HealthDbService.instance.saveHealthData(
        HealthDataTableCompanion(
          id: drift.Value(healthDataId),
          userId: drift.Value(userId),
          pregnancyStatus: drift.Value(pregnancyStatus ?? "pregnant"),
          edDate: drift.Value(eddDate),
          lmpDate: drift.Value(lmpDate),
        ),
      );

      if (pregnancyStatus == "pregnant" || eddDate != null) {
        await HealthDbService.instance.savePregnancy(
          PregnanciesCompanion(
            id: drift.Value(healthDataId),
            healthId: drift.Value(healthDataId),
            status: const drift.Value("active"),
            edDate: drift.Value(eddDate),
            lmpDate: drift.Value(lmpDate),
          ),
        );
      }
    }

    await UserDbService.instance.setActiveUser(userId);
    _currentUser = savedUser;
    await _loadHealthAndPregnancy(_currentUser!);
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> switchUser(String userId) async {
    await UserDbService.instance.setActiveUser(userId);
    _currentUser = await UserDbService.instance.getUserById(userId);
    if (_currentUser != null) {
      await _loadHealthAndPregnancy(_currentUser!);
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_currentUser != null) {
      _currentUser = await UserDbService.instance.getUserById(_currentUser!.id);
      if (_currentUser != null) {
        await _loadHealthAndPregnancy(_currentUser!);
      }
    } else {
      final active = await UserDbService.instance.getActiveUser();
      if (active != null) {
        _currentUser = active;
        await _loadHealthAndPregnancy(_currentUser!);
      }
    }
    notifyListeners();
  }

  /// Logout clears all SharedPreferences, API tokens, and SQLite session
  Future<void> logout() async {
    try {
      await AuthApi.logout();
    } catch (e) {
      debugPrint('Logout API warning: $e');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint('Error clearing SharedPreferences on logout: $e');
    }
    await ApiBase.clearTokens();
    await UserDbService.instance.logout();

    _isLoggedIn = false;
    _currentUser = null;
    _currentHealthData = null;
    _currentPregnancy = null;
    _userName = null;
    _userPhone = null;
    _countryCode = null;
    _pregnancyStatus = null;
    _lmpDate = null;
    _eddDate = null;
    _partnerName = null;
    _partnerPhone = null;
    _hasKids = false;
    _kidsCount = 0;

    notifyListeners();
  }
}
