import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import 'package:allomom/repositories/pregnancy_state.dart';
import 'package:allomom/services/cycle_predictor.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/user_db_service.dart';
import 'package:allomom/services/sq_lite/services/health_db_service.dart';
import 'package:allomom/services/sq_lite/services/baby_db_service.dart';
import 'package:allomom/api/api_base.dart';
import 'package:allomom/api/auth_api.dart';

class UserSessionManager extends GetxController {
  static UserSessionManager get instance =>
      Get.isRegistered<UserSessionManager>()
      ? Get.find<UserSessionManager>()
      : Get.put(UserSessionManager._internal(), permanent: true);

  factory UserSessionManager() => instance;
  UserSessionManager._internal();

  /// Compatibility alias for any Flutter Listeners
  void notifyListeners() => update();

  User? _currentUser;
  HealthDataTableData? _currentHealthData;
  Pregnancy? _currentPregnancy;
  int _completedPregnancyCount = 0;
  int? _averageCycleLength;
  DateTime? _lastDeliveryDate;
  bool _isLoading = true;

  // Local storage cached properties
  String? _userName;
  String? _userPhone;
  String? _userEmail;
  String? _countryCode;
  String? _pregnancyStatus;
  DateTime? _lmpDate;
  DateTime? _eddDate;
  String? _partnerName;
  String? _partnerPhone;
  bool _hasKids = false;
  int _kidsCount = 0;
  String? _gender;
  DateTime? _dob;
  String? _bio;
  String? _city;
  String? _pincode;
  String? _adline1;
  String? _adline2;
  String? _bloodGroup;
  String? _image;
  String? _coverPic;
  String? _allowearMacAddress;
  String? _riskStatus;
  bool _isLoggedIn = false;

  User? get currentUser => _currentUser;
  HealthDataTableData? get currentHealthData => _currentHealthData;
  Pregnancy? get currentPregnancy => _currentPregnancy;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isLoggedIn;

  String get userId => _currentUser?.id ?? '';
  String get userName => _userName ?? _currentUser?.name ?? 'Ananya';
  String get userPhone => _userPhone ?? _currentUser?.phone ?? '';
  String get userEmail => _userEmail ?? _currentUser?.email ?? '';
  String get countryCode => _countryCode ?? _currentUser?.countryCode ?? '+91';
  String get pregnancyStatus =>
      _pregnancyStatus ?? _currentHealthData?.pregnancyStatus ?? 'pregnant';

  /// Whether the mother is currently pregnant.
  ///
  /// Delegates to [resolveIsPregnant] so the precedence rules stay testable:
  /// an explicit status wins, and the stored LMP / EDD are only a fallback.
  bool get isPregnant => resolveIsPregnant(
    status: pregnancyStatus,
    hasPregnancyDates:
        _lmpDate != null || _eddDate != null || _currentPregnancy != null,
  );

  /// Delivered recently — postpartum rather than simply not pregnant.
  bool get isNewMom => resolveIsNewMom(pregnancyStatus);

  /// Her average cycle length, used to predict periods when not pregnant.
  int get averageCycleLength =>
      _averageCycleLength ??
      _currentHealthData?.averageCycle?.round() ??
      defaultCycleLength;

  /// Next expected period, or null while pregnant / with no LMP on record.
  CyclePrediction? get cyclePrediction {
    if (isPregnant) return null;
    final lmp = lmpDate;
    if (lmp == null) return null;
    return predictCycle(lastPeriodStart: lmp, cycleLength: averageCycleLength);
  }

  /// Completed pregnancies on record. Lets the UI tell "never registered"
  /// apart from "this journey is finished".
  int get completedPregnancyCount => _completedPregnancyCount;

  bool get hasPregnancyHistory => _completedPregnancyCount > 0 || isNewMom;

  /// The most recent delivery date, when one is on record.
  DateTime? get lastDeliveryDate =>
      _lastDeliveryDate ?? _currentHealthData?.lastDeliveryDate;

  /// Days since the last delivery, or null when there is none.
  int? get daysSinceDelivery {
    final delivered = lastDeliveryDate;
    if (delivered == null) return null;
    final days = DateTime.now().difference(delivered).inDays;
    return days < 0 ? 0 : days;
  }

  DateTime? get lmpDate =>
      _lmpDate ?? _currentHealthData?.lmpDate ?? _currentPregnancy?.lmpDate;
  DateTime? get eddDate =>
      _eddDate ?? _currentHealthData?.edDate ?? _currentPregnancy?.edDate;
  String? get partnerName => _partnerName;
  String? get partnerPhone => _partnerPhone;
  bool get hasKids => _hasKids;
  int get kidsCount => _kidsCount;
  String get gender => _gender ?? _currentUser?.gender ?? 'Female';
  DateTime? get dob => _dob ?? _currentUser?.dob;
  String get bio => _bio ?? _currentUser?.bio ?? '';
  String get city => _city ?? _currentUser?.city ?? '';
  String get pincode => _pincode ?? _currentUser?.pincode ?? '';
  String get adline1 => _adline1 ?? _currentUser?.adline1 ?? '';
  String get adline2 => _adline2 ?? _currentUser?.adline2 ?? '';
  String? get bloodGroup => _bloodGroup ?? _currentHealthData?.bloodGroup;
  String? get image => _image ?? _currentUser?.image;
  String? get coverPic => _coverPic ?? _currentUser?.coverPic;
  String? get allowearMacAddress =>
      _allowearMacAddress ?? _currentUser?.allowearMacAddress;
  String get riskStatus =>
      _riskStatus ?? _currentPregnancy?.riskStatus ?? 'Low';

  /// Health-data UUID for the active user. Every local record that hangs off
  /// the mother's health profile (pregnancies, prescriptions, reports) is keyed
  /// by this, so fall back to a deterministic id rather than an empty string.
  String get healthDataId {
    final hid = _currentUser?.healthDataID;
    if (hid != null && hid.isNotEmpty) return hid;
    final uid = userId;
    return uid.isEmpty ? '' : 'hd_$uid';
  }

  /// Days elapsed since LMP, i.e. the current day of the pregnancy.
  int get currentPregnancyDay {
    final lmp = lmpDate;
    final now = DateTime.now();
    if (lmp != null) {
      final days = now.difference(lmp).inDays;
      if (days >= 0) return days;
    }
    final edd = eddDate;
    if (edd != null) {
      final daysPassed = 280 - edd.difference(now).inDays;
      if (daysPassed > 0) return daysPassed;
    }
    return 0;
  }

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

  int get daysLeftUntilEdd {
    final edd = eddDate;
    if (edd == null) return 119;
    final now = DateTime.now();
    return edd.difference(now).inDays.clamp(0, 280);
  }

  double get pregnancyProgressFraction {
    final week = currentGestationalWeek;
    return (week / 40.0).clamp(0.0, 1.0);
  }

  String get formattedEddDate {
    final edd = eddDate;
    if (edd == null) return '28 Feb';
    const months = [
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
    return '${edd.day} ${months[edd.month - 1]}';
  }

  String get formattedEddDateFull {
    final edd = eddDate;
    if (edd == null) return '28 Feb 2026';
    const months = [
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
    return '${edd.day} ${months[edd.month - 1]} ${edd.year}';
  }

  String get currentTrimester {
    final week = currentGestationalWeek;
    if (week <= 12) return '1st Trimester';
    if (week <= 26) return '2nd Trimester';
    return '3rd Trimester';
  }

  Future<void> init() async {
    _isLoading = true;
    update();
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwt = await ApiBase.getJwt();
      final active = await UserDbService.instance.getActiveUser();

      final hasStoredLogin = prefs.getBool('is_logged_in') == true;
      final hasJwt = jwt != null && jwt.isNotEmpty;

      // A stored profile row is NOT a session — logging out leaves it behind
      // on purpose. Only the explicit login flag or a token counts, otherwise
      // the previous user is signed back in on the next launch.
      _isLoggedIn = hasStoredLogin || hasJwt;

      if (_isLoggedIn) {
        _userName = prefs.getString('user_name');
        _userPhone = prefs.getString('user_phone');
        _userEmail = prefs.getString('user_email');
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
        _gender = prefs.getString('user_gender');
        final dobStr = prefs.getString('user_dob');
        if (dobStr != null && dobStr.isNotEmpty) {
          _dob = DateTime.tryParse(dobStr);
        }
        _bio = prefs.getString('user_bio');
        _city = prefs.getString('user_city');
        _pincode = prefs.getString('user_pincode');
        _adline1 = prefs.getString('user_adline1');
        _adline2 = prefs.getString('user_adline2');
        _bloodGroup = prefs.getString('user_blood_group');
        _image = prefs.getString('user_image');
        _coverPic = prefs.getString('user_cover_pic');
        _allowearMacAddress = prefs.getString('allowear_mac_address');

        if (active != null) {
          _currentUser = active;
          _userName ??= active.name;
          _userPhone ??= active.phone;
          _userEmail ??= active.email;
          await _loadHealthAndPregnancy(_currentUser!);
        }

        // Ensure is_logged_in flag is stored in SharedPreferences
        await prefs.setBool('is_logged_in', true);

        // Local-only hydration: the SQLite row is the source of truth outside
        // of login/signup, so fill in anything SharedPreferences was missing.
        _hydrateFromLocalRecords();
      }
    } catch (e) {
      debugPrint('Error initializing UserSessionManager: $e');
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<void> _loadHealthAndPregnancy(User user) async {
    if (user.healthDataID != null && user.healthDataID!.isNotEmpty) {
      _currentHealthData = await HealthDbService.instance.getHealthDataById(
        user.healthDataID!,
      );
      if (_currentHealthData != null) {
        _currentPregnancy = await HealthDbService.instance.getActivePregnancy(
          _currentHealthData!.id,
        );

        final completed = await HealthDbService.instance
            .getCompletedPregnancies(_currentHealthData!.id);
        _completedPregnancyCount = completed.length;
        _lastDeliveryDate = completed
            .map((p) => p.deliveryDate ?? p.completedAt)
            .whereType<DateTime>()
            .fold<DateTime?>(
              null,
              (latest, date) =>
                  latest == null || date.isAfter(latest) ? date : latest,
            );
      }
    }
  }

  /// Fills the cached session fields from the local SQLite rows. Used on init
  /// so a fresh install / cleared SharedPreferences still shows the stored
  /// profile without needing the network.
  void _hydrateFromLocalRecords() {
    final user = _currentUser;
    final health = _currentHealthData;
    final preg = _currentPregnancy;

    if (user != null) {
      _userName ??= user.name;
      _userPhone ??= user.phone;
      _userEmail ??= user.email;
      _countryCode ??= user.countryCode;
      _gender ??= user.gender;
      _dob ??= user.dob;
      _bio ??= user.bio;
      _city ??= user.city;
      _pincode ??= user.pincode;
      _adline1 ??= user.adline1;
      _adline2 ??= user.adline2;
      _image ??= user.image;
      _coverPic ??= user.coverPic;
      _allowearMacAddress ??= user.allowearMacAddress;
    }

    if (health != null) {
      _averageCycleLength ??= health.averageCycle?.round();
      _bloodGroup ??= health.bloodGroup;
      _pregnancyStatus ??= health.pregnancyStatus;
      _lmpDate ??= health.lmpDate;
      _eddDate ??= health.edDate;
    }

    if (preg != null) {
      _lmpDate ??= preg.lmpDate;
      _eddDate ??= preg.edDate;
      _riskStatus ??= preg.riskStatus;
      if (preg.status == 'active') _pregnancyStatus = 'pregnant';
    }

    update();
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
    int? averageCycleLength,
    String? userId,
    String? jwt,
    String? refresh,
    String? healthDataId,
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

    final resolvedUserId =
        userId ?? "usr_${DateTime.now().millisecondsSinceEpoch}";
    final resolvedHealthId =
        healthDataId ?? "hd_${DateTime.now().millisecondsSinceEpoch}";

    if (averageCycleLength != null) {
      await prefs.setInt('average_cycle_length', averageCycleLength);
      _averageCycleLength = averageCycleLength;
    }

    await setAuthenticatedSession(
      userId: resolvedUserId,
      averageCycleLength: averageCycleLength,
      jwt: jwt ?? "local_jwt_token",
      refresh: refresh ?? "local_refresh_token",
      name: name,
      phone: phone,
      healthDataId: resolvedHealthId,
      pregnancyStatus: pregnancyStatus,
      eddDate: eddDate,
      lmpDate: lmpDate,
    );

    update();
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
    int? averageCycleLength,
  }) async {
    await ApiBase.setJwt(jwt);
    if (refresh != null) {
      await ApiBase.setRefreshToken(refresh);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_id', userId);
    if (name != null && name.isNotEmpty) {
      await prefs.setString('user_name', name);
    }
    if (phone != null && phone.isNotEmpty) {
      await prefs.setString('user_phone', phone);
    }
    if (email != null && email.isNotEmpty) {
      await prefs.setString('user_email', email);
    }
    if (pregnancyStatus != null && pregnancyStatus.isNotEmpty) {
      await prefs.setString('pregnancy_status', pregnancyStatus);
    }
    if (eddDate != null) {
      await prefs.setString('edd_date', eddDate.toIso8601String());
    }
    if (lmpDate != null) {
      await prefs.setString('lmp_date', lmpDate.toIso8601String());
    }

    final savedUser = await UserDbService.instance.saveUser(
      UsersCompanion(
        id: drift.Value(userId),
        name: drift.Value(name ?? _userName ?? "Mommy"),
        phone: drift.Value(phone ?? _userPhone ?? ""),
        email: drift.Value(email ?? ""),
        healthDataID: drift.Value(healthDataId),
        isDeleted: const drift.Value(false),
        synced: const drift.Value(0),
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
          averageCycle: drift.Value(averageCycleLength?.toDouble()),
          synced: const drift.Value(0),
        ),
      );

      if (pregnancyStatus == "pregnant" || eddDate != null) {
        // Reuse the existing active pregnancy on re-login so a second row is
        // not created for the same journey.
        final existing = await HealthDbService.instance.getActivePregnancy(
          healthDataId,
        );
        await HealthDbService.instance.savePregnancy(
          PregnanciesCompanion(
            id: drift.Value(existing?.id ?? const Uuid().v4()),
            healthId: drift.Value(healthDataId),
            status: const drift.Value("active"),
            edDate: drift.Value(eddDate),
            lmpDate: drift.Value(lmpDate),
            createdAt: drift.Value(existing?.createdAt ?? DateTime.now()),
            synced: const drift.Value(0),
          ),
        );
      }
    }

    await UserDbService.instance.setActiveUser(userId);
    _currentUser = savedUser;
    if (name != null) _userName = name;
    if (phone != null) _userPhone = phone;
    if (email != null) _userEmail = email;
    if (pregnancyStatus != null) _pregnancyStatus = pregnancyStatus;
    if (eddDate != null) _eddDate = eddDate;
    if (lmpDate != null) _lmpDate = lmpDate;

    await _loadHealthAndPregnancy(_currentUser!);
    _isLoggedIn = true;
    update();
  }

  Future<void> switchUser(String userId) async {
    await UserDbService.instance.setActiveUser(userId);
    _currentUser = await UserDbService.instance.getUserById(userId);
    if (_currentUser != null) {
      await _loadHealthAndPregnancy(_currentUser!);
    }
    update();
  }

  /// Guards [refresh] against re-entering itself.
  ///
  /// GetX's `update()` calls `refresh()`, and this override ends by calling
  /// `update()` — so without the guard a single `update()` starts an
  /// unbounded async loop that re-reads the user, health data and pregnancy
  /// from SQLite on every cycle.
  bool _isRefreshing = false;

  @override
  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      if (_currentUser != null) {
        _currentUser = await UserDbService.instance.getUserById(
          _currentUser!.id,
        );
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
      update();
    } finally {
      _isRefreshing = false;
    }
  }

  /// Update profile details in memory, SharedPreferences, SQLite, and remotely via API
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? gender,
    DateTime? dob,
    String? bio,
    String? city,
    String? pincode,
    String? adline1,
    String? adline2,
    String? bloodGroup,
    String? pregnancyStatus,
    DateTime? lmpDate,
    DateTime? eddDate,
    String? image,
    String? coverPic,
    String? allowearMacAddress,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (name != null) {
      _userName = name;
      await prefs.setString('user_name', name);
    }
    if (email != null) {
      _userEmail = email;
      await prefs.setString('user_email', email);
    }
    if (phone != null) {
      _userPhone = phone;
      await prefs.setString('user_phone', phone);
    }
    if (gender != null) {
      _gender = gender;
      await prefs.setString('user_gender', gender);
    }
    if (dob != null) {
      _dob = dob;
      await prefs.setString('user_dob', dob.toIso8601String());
    }
    if (bio != null) {
      _bio = bio;
      await prefs.setString('user_bio', bio);
    }
    if (city != null) {
      _city = city;
      await prefs.setString('user_city', city);
    }
    if (pincode != null) {
      _pincode = pincode;
      await prefs.setString('user_pincode', pincode);
    }
    if (adline1 != null) {
      _adline1 = adline1;
      await prefs.setString('user_adline1', adline1);
    }
    if (adline2 != null) {
      _adline2 = adline2;
      await prefs.setString('user_adline2', adline2);
    }
    if (bloodGroup != null) {
      _bloodGroup = bloodGroup;
      await prefs.setString('user_blood_group', bloodGroup);
    }
    if (pregnancyStatus != null) {
      _pregnancyStatus = pregnancyStatus;
      await prefs.setString('pregnancy_status', pregnancyStatus);
    }
    if (lmpDate != null) {
      _lmpDate = lmpDate;
      await prefs.setString('lmp_date', lmpDate.toIso8601String());
    }
    if (eddDate != null) {
      _eddDate = eddDate;
      await prefs.setString('edd_date', eddDate.toIso8601String());
    }
    if (image != null) {
      _image = image;
      await prefs.setString('user_image', image);
    }
    if (coverPic != null) {
      _coverPic = coverPic;
      await prefs.setString('user_cover_pic', coverPic);
    }
    if (allowearMacAddress != null) {
      _allowearMacAddress = allowearMacAddress;
      await prefs.setString('allowear_mac_address', allowearMacAddress);
    }

    // Update SQLite local tables
    if (_currentUser != null) {
      await UserDbService.instance.saveUser(
        UsersCompanion(
          id: drift.Value(_currentUser!.id),
          name: drift.Value(_userName ?? _currentUser!.name),
          phone: drift.Value(_userPhone ?? _currentUser!.phone),
          email: drift.Value(_userEmail ?? _currentUser!.email),
          gender: drift.Value(_gender ?? _currentUser!.gender),
          dob: drift.Value(_dob ?? _currentUser!.dob),
          bio: drift.Value(_bio ?? _currentUser!.bio),
          city: drift.Value(_city ?? _currentUser!.city),
          pincode: drift.Value(_pincode ?? _currentUser!.pincode),
          adline1: drift.Value(_adline1 ?? _currentUser!.adline1),
          adline2: drift.Value(_adline2 ?? _currentUser!.adline2),
          image: drift.Value(_image ?? _currentUser!.image),
          coverPic: drift.Value(_coverPic ?? _currentUser!.coverPic),
          allowearMacAddress: drift.Value(
            _allowearMacAddress ?? _currentUser!.allowearMacAddress,
          ),
          healthDataID: drift.Value(_currentUser!.healthDataID),
          isDeleted: const drift.Value(false),
          synced: const drift.Value(0),
        ),
      );

      final hid = _currentUser!.healthDataID;
      if (hid != null && hid.isNotEmpty) {
        await HealthDbService.instance.saveHealthData(
          HealthDataTableCompanion(
            id: drift.Value(hid),
            userId: drift.Value(_currentUser!.id),
            bloodGroup: drift.Value(_bloodGroup),
            pregnancyStatus: drift.Value(_pregnancyStatus ?? "pregnant"),
            edDate: drift.Value(_eddDate),
            lmpDate: drift.Value(_lmpDate),
            synced: const drift.Value(0),
          ),
        );
      }
    }

    update();

    // Local-only: the row is written with synced = 0 so a future sync worker
    // can push it. No network call is made here.
    return true;
  }

  Future<bool> updateBloodGroup(String bg) => updateProfile(bloodGroup: bg);
  Future<bool> updateLmpDate(DateTime lmp) => updateProfile(lmpDate: lmp);
  Future<bool> updateEddDate(DateTime edd) => updateProfile(eddDate: edd);

  /// Pulls the profile from `GET /me` and writes it into local storage.
  ///
  /// This is the ONE place outside of login/signup that touches the network,
  /// and it is only meant to be called straight after a successful
  /// authentication (e.g. Google sign-in) to seed the local database with the
  /// account that was just logged into. Everything after that reads and writes
  /// SQLite only.
  Future<void> fetchUser() async {
    Map? data;
    try {
      final res = await AuthApi.getMe();
      if (res.success && res.item is Map) {
        data = res.item as Map;
      }
    } catch (e) {
      debugPrint('fetchUser: could not load profile from API: $e');
    }
    if (data == null) return;

    final prefs = await SharedPreferences.getInstance();

    String? str(String key) => data![key]?.toString();

    DateTime? date(String key) {
      final v = data![key];
      return v == null ? null : DateTime.tryParse(v.toString());
    }

    final userId = str('id') ?? str('userId') ?? _currentUser?.id;

    _userName = str('name') ?? _userName;
    _userEmail = str('email') ?? _userEmail;
    _userPhone = str('phone') ?? _userPhone;
    _gender = str('gender') ?? _gender;
    _dob = date('dob') ?? _dob;
    _bio = str('bio') ?? _bio;
    _city = str('city') ?? _city;
    _pincode = str('pincode') ?? _pincode;
    _adline1 = str('adline1') ?? _adline1;
    _adline2 = str('adline2') ?? _adline2;
    _bloodGroup = str('bloodGroup') ?? _bloodGroup;
    _pregnancyStatus = str('pregnancyStatus') ?? _pregnancyStatus;
    _lmpDate = date('lmpDate') ?? _lmpDate;
    _eddDate = date('edDate') ?? _eddDate;
    _image = str('image') ?? _image;
    _coverPic = str('cover_pic') ?? _coverPic;
    _allowearMacAddress = str('allowear_mac_address') ?? _allowearMacAddress;

    final healthDataId =
        str('healthDataID') ??
        str('healthDataId') ??
        _currentUser?.healthDataID;

    if (data['pregnancy'] is Map) {
      final preg = data['pregnancy'] as Map;
      _lmpDate =
          DateTime.tryParse(preg['lmpDate']?.toString() ?? '') ?? _lmpDate;
      _eddDate =
          DateTime.tryParse(preg['edDate']?.toString() ?? '') ?? _eddDate;
      _riskStatus = preg['riskStatus']?.toString() ?? _riskStatus;
      final pregStatus = preg['status']?.toString().toLowerCase();
      if (pregStatus != null && pregStatus != 'notpregnant') {
        _pregnancyStatus = 'pregnant';
      }
    }

    // Mirror into SharedPreferences
    Future<void> put(String key, String? value) async {
      if (value != null && value.isNotEmpty) await prefs.setString(key, value);
    }

    await put('user_id', userId);
    await put('user_name', _userName);
    await put('user_email', _userEmail);
    await put('user_phone', _userPhone);
    await put('user_gender', _gender);
    await put('user_dob', _dob?.toIso8601String());
    await put('user_bio', _bio);
    await put('user_city', _city);
    await put('user_pincode', _pincode);
    await put('user_adline1', _adline1);
    await put('user_adline2', _adline2);
    await put('user_blood_group', _bloodGroup);
    await put('pregnancy_status', _pregnancyStatus);
    await put('lmp_date', _lmpDate?.toIso8601String());
    await put('edd_date', _eddDate?.toIso8601String());
    await put('user_image', _image);
    await put('user_cover_pic', _coverPic);
    await put('allowear_mac_address', _allowearMacAddress);

    // Persist into SQLite as the local source of truth
    if (userId != null && userId.isNotEmpty) {
      _currentUser = await UserDbService.instance.saveUser(
        UsersCompanion(
          id: drift.Value(userId),
          name: drift.Value(_userName),
          email: drift.Value(_userEmail),
          phone: drift.Value(_userPhone),
          gender: drift.Value(_gender),
          dob: drift.Value(_dob),
          bio: drift.Value(_bio),
          city: drift.Value(_city),
          pincode: drift.Value(_pincode),
          adline1: drift.Value(_adline1),
          adline2: drift.Value(_adline2),
          image: drift.Value(_image),
          coverPic: drift.Value(_coverPic),
          allowearMacAddress: drift.Value(_allowearMacAddress),
          healthDataID: drift.Value(healthDataId),
          isDeleted: const drift.Value(false),
          synced: const drift.Value(0),
        ),
      );
      await UserDbService.instance.setActiveUser(userId);

      if (healthDataId != null && healthDataId.isNotEmpty) {
        await HealthDbService.instance.saveHealthData(
          HealthDataTableCompanion(
            id: drift.Value(healthDataId),
            userId: drift.Value(userId),
            bloodGroup: drift.Value(_bloodGroup),
            pregnancyStatus: drift.Value(_pregnancyStatus ?? 'pregnant'),
            lmpDate: drift.Value(_lmpDate),
            edDate: drift.Value(_eddDate),
            synced: const drift.Value(0),
          ),
        );
      }

      await _loadHealthAndPregnancy(_currentUser!);
    }

    _isLoggedIn = true;
    await prefs.setBool('is_logged_in', true);
    update();
  }

  /// Create or update the active pregnancy record in local SQLite.
  ///
  /// Written with `synced = 0`; no API call is made. Returns the pregnancy's
  /// id so callers can hang a care schedule off it, or null if there is no
  /// signed-in user to attach it to.
  Future<String?> saveOrUpdatePregnancy({
    required DateTime lmpDate,
    DateTime? eddDate,
    String? methodOfConception,
    int? gravidity,
    int? parity,
    int? livingChildren,
    int? abortions,
    int? stillBirths,
    int? miscarriages,
    int? csectionDeliveries,
  }) async {
    final resolvedEdd = eddDate ?? lmpDate.add(const Duration(days: 280));
    final prefs = await SharedPreferences.getInstance();

    _lmpDate = lmpDate;
    _eddDate = resolvedEdd;
    _pregnancyStatus = 'pregnant';

    await prefs.setString('lmp_date', lmpDate.toIso8601String());
    await prefs.setString('edd_date', resolvedEdd.toIso8601String());
    await prefs.setString('pregnancy_status', 'pregnant');

    final user = _currentUser;
    if (user == null) {
      update();
      return null;
    }

    final hid = healthDataId;

    await HealthDbService.instance.saveHealthData(
      HealthDataTableCompanion(
        id: drift.Value(hid),
        userId: drift.Value(user.id),
        pregnancyStatus: const drift.Value('pregnant'),
        edDate: drift.Value(resolvedEdd),
        lmpDate: drift.Value(lmpDate),
        synced: const drift.Value(0),
      ),
    );

    final linkedHealthId = user.healthDataID;
    if (linkedHealthId == null || linkedHealthId.isEmpty) {
      _currentUser = await UserDbService.instance.saveUser(
        UsersCompanion(
          id: drift.Value(user.id),
          healthDataID: drift.Value(hid),
          isDeleted: const drift.Value(false),
          synced: const drift.Value(0),
        ),
      );
    }

    // Reuse the existing active pregnancy so repeated edits update one row
    // instead of piling up new ones.
    final existing = await HealthDbService.instance.getActivePregnancy(hid);
    final pregnancyId = existing?.id ?? const Uuid().v4();

    await HealthDbService.instance.savePregnancy(
      PregnanciesCompanion(
        id: drift.Value(pregnancyId),
        healthId: drift.Value(hid),
        status: const drift.Value('active'),
        edDate: drift.Value(resolvedEdd),
        lmpDate: drift.Value(lmpDate),
        gravidity: drift.Value(gravidity ?? existing?.gravidity ?? 0),
        parity: drift.Value(parity ?? existing?.parity ?? 0),
        livingChildren: drift.Value(
          livingChildren ?? existing?.livingChildren ?? 0,
        ),
        abortions: drift.Value(abortions ?? existing?.abortions ?? 0),
        stillBirths: drift.Value(stillBirths ?? existing?.stillBirths ?? 0),
        miscarriages: drift.Value(miscarriages ?? existing?.miscarriages ?? 0),
        csectionDeliveries: drift.Value(
          csectionDeliveries ?? existing?.csectionDeliveries ?? 0,
        ),
        methodOfConception: drift.Value(
          methodOfConception ?? existing?.methodOfConception,
        ),
        createdAt: drift.Value(existing?.createdAt ?? DateTime.now()),
        synced: const drift.Value(0),
      ),
    );

    await _loadHealthAndPregnancy(_currentUser ?? user);
    update();
    return pregnancyId;
  }

  /// Sets pregnancy status (e.g. 'pregnant', 'notpregnant', 'new_mom')
  Future<bool> setPregnancyStatus(String status) async {
    _pregnancyStatus = status;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pregnancy_status', status);

    final user = _currentUser;
    if (user != null && user.healthDataID != null) {
      await HealthDbService.instance.saveHealthData(
        HealthDataTableCompanion(
          id: drift.Value(user.healthDataID!),
          userId: drift.Value(user.id),
          pregnancyStatus: drift.Value(status),
          synced: const drift.Value(0),
        ),
      );

      // Reload so the active pregnancy, completed count and delivery date
      // match the new status — a journey marked complete must stop reading
      // as active straight away, not after the next app launch.
      await _loadHealthAndPregnancy(user);
    }

    update();
    return true;
  }

  /// Re-derives `hasKids` / `kidsCount` from the birth records table.
  ///
  /// Once babies are stored as birth records that table is the source of
  /// truth; the SharedPreferences pair is only a cache for the UI, and it
  /// drifts as soon as a baby is added or deleted outside registration.
  Future<void> refreshKidsFromBirthRecords() async {
    final babies = await BabyDbService.instance.getBirthRecords();
    _kidsCount = babies.length;
    _hasKids = babies.isNotEmpty;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_kids', _hasKids);
    await prefs.setInt('kids_count', _kidsCount);

    update();
  }

  /// Delete active pregnancy record
  Future<bool> deleteActivePregnancy() async {
    final activePregId = _currentPregnancy?.id ?? _currentUser?.healthDataID;
    _currentPregnancy = null;
    _pregnancyStatus = 'notpregnant';
    _lmpDate = null;
    _eddDate = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pregnancy_status', 'notpregnant');
    await prefs.remove('lmp_date');
    await prefs.remove('edd_date');

    if (_currentUser != null && _currentUser!.healthDataID != null) {
      await HealthDbService.instance.saveHealthData(
        HealthDataTableCompanion(
          id: drift.Value(_currentUser!.healthDataID!),
          userId: drift.Value(_currentUser!.id),
          pregnancyStatus: const drift.Value('notpregnant'),
          edDate: const drift.Value(null),
          lmpDate: const drift.Value(null),
          synced: const drift.Value(0),
        ),
      );
    }

    if (activePregId != null && activePregId.isNotEmpty) {
      await HealthDbService.instance.deletePregnancy(activePregId);
    }

    update();
    return true;
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
      // Clear the login flag first and on its own: if the bulk clear throws
      // part-way through, the session must still read as signed out.
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('is_logged_in');
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
    _completedPregnancyCount = 0;
    _lastDeliveryDate = null;
    _averageCycleLength = null;
    _userName = null;
    _userPhone = null;
    _userEmail = null;
    _countryCode = null;
    _pregnancyStatus = null;
    _lmpDate = null;
    _eddDate = null;
    _partnerName = null;
    _partnerPhone = null;
    _hasKids = false;
    _kidsCount = 0;
    _gender = null;
    _dob = null;
    _bio = null;
    _city = null;
    _pincode = null;
    _adline1 = null;
    _adline2 = null;
    _bloodGroup = null;
    _image = null;
    _coverPic = null;
    _allowearMacAddress = null;
    _riskStatus = null;

    update();
  }
}
