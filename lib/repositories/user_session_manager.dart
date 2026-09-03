import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' as drift;
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/user_db_service.dart';
import 'package:allomom/services/sq_lite/services/health_db_service.dart';
import 'package:allomom/services/api/api_base.dart';
import 'package:allomom/services/api/auth_api.dart';
import 'package:allomom/services/api/pregnancy_api.dart';

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
  String get pregnancyStatus => _pregnancyStatus ?? _currentHealthData?.pregnancyStatus ?? 'pregnant';
  bool get isPregnant {
    if (_lmpDate != null || _eddDate != null || _currentPregnancy != null) return true;
    final s = pregnancyStatus.toLowerCase().trim();
    if (s == 'notpregnant' || s == 'not_pregnant' || s == 'not pregnant') return false;
    return true;
  }
  DateTime? get lmpDate => _lmpDate ?? _currentHealthData?.lmpDate ?? _currentPregnancy?.lmpDate;
  DateTime? get eddDate => _eddDate ?? _currentHealthData?.edDate ?? _currentPregnancy?.edDate;
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
  String? get allowearMacAddress => _allowearMacAddress ?? _currentUser?.allowearMacAddress;
  String get riskStatus => _riskStatus ?? _currentPregnancy?.riskStatus ?? 'Low';

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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${edd.day} ${months[edd.month - 1]}';
  }

  String get formattedEddDateFull {
    final edd = eddDate;
    if (edd == null) return '28 Feb 2026';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwt = await ApiBase.getJwt();
      final active = await UserDbService.instance.getActiveUser();

      final hasStoredLogin = prefs.getBool('is_logged_in') == true;
      final hasJwt = jwt != null && jwt.isNotEmpty;
      final hasActiveUser = active != null;

      _isLoggedIn = hasStoredLogin || hasJwt || hasActiveUser;

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

        // Ensure is_logged_in flag is synced in SharedPreferences
        await prefs.setBool('is_logged_in', true);

        // Background sync with API
        fetchAndSyncProfileFromApi();
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

    final resolvedUserId = userId ?? "usr_${DateTime.now().millisecondsSinceEpoch}";
    final resolvedHealthId = healthDataId ?? "hd_${DateTime.now().millisecondsSinceEpoch}";

    await setAuthenticatedSession(
      userId: resolvedUserId,
      jwt: jwt ?? "local_jwt_token",
      refresh: refresh ?? "local_refresh_token",
      name: name,
      phone: phone,
      healthDataId: resolvedHealthId,
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_id', userId);
    if (name != null && name.isNotEmpty) await prefs.setString('user_name', name);
    if (phone != null && phone.isNotEmpty) await prefs.setString('user_phone', phone);
    if (email != null && email.isNotEmpty) await prefs.setString('user_email', email);
    if (pregnancyStatus != null && pregnancyStatus.isNotEmpty) await prefs.setString('pregnancy_status', pregnancyStatus);
    if (eddDate != null) await prefs.setString('edd_date', eddDate.toIso8601String());
    if (lmpDate != null) await prefs.setString('lmp_date', lmpDate.toIso8601String());

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
    if (name != null) _userName = name;
    if (phone != null) _userPhone = phone;
    if (email != null) _userEmail = email;
    if (pregnancyStatus != null) _pregnancyStatus = pregnancyStatus;
    if (eddDate != null) _eddDate = eddDate;
    if (lmpDate != null) _lmpDate = lmpDate;

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

    if (name != null) { _userName = name; await prefs.setString('user_name', name); }
    if (email != null) { _userEmail = email; await prefs.setString('user_email', email); }
    if (phone != null) { _userPhone = phone; await prefs.setString('user_phone', phone); }
    if (gender != null) { _gender = gender; await prefs.setString('user_gender', gender); }
    if (dob != null) { _dob = dob; await prefs.setString('user_dob', dob.toIso8601String()); }
    if (bio != null) { _bio = bio; await prefs.setString('user_bio', bio); }
    if (city != null) { _city = city; await prefs.setString('user_city', city); }
    if (pincode != null) { _pincode = pincode; await prefs.setString('user_pincode', pincode); }
    if (adline1 != null) { _adline1 = adline1; await prefs.setString('user_adline1', adline1); }
    if (adline2 != null) { _adline2 = adline2; await prefs.setString('user_adline2', adline2); }
    if (bloodGroup != null) { _bloodGroup = bloodGroup; await prefs.setString('user_blood_group', bloodGroup); }
    if (pregnancyStatus != null) { _pregnancyStatus = pregnancyStatus; await prefs.setString('pregnancy_status', pregnancyStatus); }
    if (lmpDate != null) { _lmpDate = lmpDate; await prefs.setString('lmp_date', lmpDate.toIso8601String()); }
    if (eddDate != null) { _eddDate = eddDate; await prefs.setString('edd_date', eddDate.toIso8601String()); }
    if (image != null) { _image = image; await prefs.setString('user_image', image); }
    if (coverPic != null) { _coverPic = coverPic; await prefs.setString('user_cover_pic', coverPic); }
    if (allowearMacAddress != null) { _allowearMacAddress = allowearMacAddress; await prefs.setString('allowear_mac_address', allowearMacAddress); }

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
          allowearMacAddress: drift.Value(_allowearMacAddress ?? _currentUser!.allowearMacAddress),
          healthDataID: drift.Value(_currentUser!.healthDataID),
          isDeleted: const drift.Value(false),
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
          ),
        );
      }
    }

    notifyListeners();

    // Sync with backend API
    try {
      final payload = <String, dynamic>{};
      if (name != null) payload['name'] = name;
      if (email != null) payload['email'] = email;
      if (phone != null) payload['phone'] = phone;
      if (gender != null) payload['gender'] = gender.toLowerCase();
      if (dob != null) payload['dob'] = dob.toIso8601String();
      if (bio != null) payload['bio'] = bio;
      if (city != null) payload['city'] = city;
      if (pincode != null) payload['pincode'] = pincode;
      if (adline1 != null) payload['adline1'] = adline1;
      if (adline2 != null) payload['adline2'] = adline2;
      if (image != null) payload['image'] = image;
      if (coverPic != null) payload['cover_pic'] = coverPic;
      if (allowearMacAddress != null) payload['allowear_mac_address'] = allowearMacAddress;
      if (bloodGroup != null) payload['bloodGroup'] = bloodGroup;
      if (pregnancyStatus != null) payload['pregnancyStatus'] = pregnancyStatus;
      if (lmpDate != null) payload['lmpDate'] = lmpDate.toIso8601String();
      if (eddDate != null) payload['edDate'] = eddDate.toIso8601String();

      final res = await AuthApi.updateProfile(payload);
      return res.success;
    } catch (e) {
      debugPrint('Error updating profile with API: $e');
      return true;
    }
  }

  Future<bool> updateBloodGroup(String bg) => updateProfile(bloodGroup: bg);
  Future<bool> updateLmpDate(DateTime lmp) => updateProfile(lmpDate: lmp);
  Future<bool> updateEddDate(DateTime edd) => updateProfile(eddDate: edd);

  /// Syncs latest profile information from GET /me
  Future<void> fetchAndSyncProfileFromApi() async {
    try {
      final res = await AuthApi.getMe();
      if (res.success && res.item is Map) {
        final data = res.item as Map;
        final prefs = await SharedPreferences.getInstance();

        if (data['name'] != null) {
          _userName = data['name'].toString();
          await prefs.setString('user_name', _userName!);
        }
        if (data['email'] != null) {
          _userEmail = data['email'].toString();
          await prefs.setString('user_email', _userEmail!);
        }
        if (data['phone'] != null) {
          _userPhone = data['phone'].toString();
          await prefs.setString('user_phone', _userPhone!);
        }
        if (data['gender'] != null) {
          _gender = data['gender'].toString();
          await prefs.setString('user_gender', _gender!);
        }
        if (data['dob'] != null) {
          _dob = DateTime.tryParse(data['dob'].toString());
          if (_dob != null) await prefs.setString('user_dob', _dob!.toIso8601String());
        }
        if (data['bio'] != null) {
          _bio = data['bio'].toString();
          await prefs.setString('user_bio', _bio!);
        }
        if (data['city'] != null) {
          _city = data['city'].toString();
          await prefs.setString('user_city', _city!);
        }
        if (data['pincode'] != null) {
          _pincode = data['pincode'].toString();
          await prefs.setString('user_pincode', _pincode!);
        }
        if (data['adline1'] != null) {
          _adline1 = data['adline1'].toString();
          await prefs.setString('user_adline1', _adline1!);
        }
        if (data['adline2'] != null) {
          _adline2 = data['adline2'].toString();
          await prefs.setString('user_adline2', _adline2!);
        }
        if (data['bloodGroup'] != null) {
          _bloodGroup = data['bloodGroup'].toString();
          await prefs.setString('user_blood_group', _bloodGroup!);
        }
        if (data['pregnancyStatus'] != null) {
          _pregnancyStatus = data['pregnancyStatus'].toString();
          await prefs.setString('pregnancy_status', _pregnancyStatus!);
        }
        if (data['lmpDate'] != null) {
          _lmpDate = DateTime.tryParse(data['lmpDate'].toString());
          if (_lmpDate != null) await prefs.setString('lmp_date', _lmpDate!.toIso8601String());
        }
        if (data['edDate'] != null) {
          _eddDate = DateTime.tryParse(data['edDate'].toString());
          if (_eddDate != null) await prefs.setString('edd_date', _eddDate!.toIso8601String());
        }
        if (data['image'] != null) {
          _image = data['image'].toString();
          await prefs.setString('user_image', _image!);
        }
        if (data['cover_pic'] != null) {
          _coverPic = data['cover_pic'].toString();
          await prefs.setString('user_cover_pic', _coverPic!);
        }
        if (data['allowear_mac_address'] != null) {
          _allowearMacAddress = data['allowear_mac_address'].toString();
          await prefs.setString('allowear_mac_address', _allowearMacAddress!);
        }

        if (data['pregnancy'] is Map) {
          final preg = data['pregnancy'] as Map;
          if (preg['lmpDate'] != null) {
            _lmpDate = DateTime.tryParse(preg['lmpDate'].toString());
            if (_lmpDate != null) await prefs.setString('lmp_date', _lmpDate!.toIso8601String());
          }
          if (preg['edDate'] != null) {
            _eddDate = DateTime.tryParse(preg['edDate'].toString());
            if (_eddDate != null) await prefs.setString('edd_date', _eddDate!.toIso8601String());
          }
          if (preg['riskStatus'] != null) {
            _riskStatus = preg['riskStatus'].toString();
          }
          if (preg['status'] != null && preg['status'].toString().toLowerCase() != 'notpregnant') {
            _pregnancyStatus = 'pregnant';
            await prefs.setString('pregnancy_status', 'pregnant');
          }
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Background profile sync notice: $e');
    }

    // Sync active pregnancy info from PregnancyApi
    try {
      final pregInfoRes = await PregnancyApi.getPregnancyInfo();
      if (pregInfoRes.success && pregInfoRes.item is Map) {
        final pregItem = pregInfoRes.item as Map;
        final prefs = await SharedPreferences.getInstance();

        if (pregItem['lmp_date'] != null) {
          _lmpDate = DateTime.tryParse(pregItem['lmp_date'].toString());
          if (_lmpDate != null) await prefs.setString('lmp_date', _lmpDate!.toIso8601String());
        }
        if (pregItem['estimatedDueDate'] != null) {
          _eddDate = DateTime.tryParse(pregItem['estimatedDueDate'].toString());
          if (_eddDate != null) await prefs.setString('edd_date', _eddDate!.toIso8601String());
        }
        if (pregItem['riskStatus'] != null) {
          _riskStatus = pregItem['riskStatus'].toString();
        }
        if (pregItem['status'] != null && pregItem['status'] == 'active') {
          _pregnancyStatus = 'pregnant';
          await prefs.setString('pregnancy_status', 'pregnant');
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Background pregnancy sync notice: $e');
    }
  }

  /// Create or update pregnancy record both locally and remotely via allomom-api
  Future<bool> saveOrUpdatePregnancy({
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

    // Update SQLite
    final hid = _currentUser?.healthDataID ?? 'hd_${DateTime.now().millisecondsSinceEpoch}';
    if (_currentUser != null) {
      await HealthDbService.instance.saveHealthData(
        HealthDataTableCompanion(
          id: drift.Value(hid),
          userId: drift.Value(_currentUser!.id),
          pregnancyStatus: const drift.Value('pregnant'),
          edDate: drift.Value(resolvedEdd),
          lmpDate: drift.Value(lmpDate),
        ),
      );

      await HealthDbService.instance.savePregnancy(
        PregnanciesCompanion(
          id: drift.Value(hid),
          healthId: drift.Value(hid),
          status: const drift.Value('active'),
          edDate: drift.Value(resolvedEdd),
          lmpDate: drift.Value(lmpDate),
          gravidity: drift.Value(gravidity ?? 0),
          parity: drift.Value(parity ?? 0),
          livingChildren: drift.Value(livingChildren ?? 0),
          abortions: drift.Value(abortions ?? 0),
          stillBirths: drift.Value(stillBirths ?? 0),
          miscarriages: drift.Value(miscarriages ?? 0),
          csectionDeliveries: drift.Value(csectionDeliveries ?? 0),
          methodOfConception: drift.Value(methodOfConception),
        ),
      );
    }

    notifyListeners();

    // Call PregnancyApi.createPregnancy
    try {
      final payload = {
        'lmpDate': lmpDate.toIso8601String(),
        'edDate': resolvedEdd.toIso8601String(),
        'methodOfConception': methodOfConception,
        'gravidity': gravidity ?? 0,
        'parity': parity ?? 0,
        'livingChildren': livingChildren ?? 0,
        'abortions': abortions ?? 0,
        'stillBirths': stillBirths ?? 0,
        'miscarriages': miscarriages ?? 0,
        'csectionDeliveries': csectionDeliveries ?? 0,
      };
      final res = await PregnancyApi.createPregnancy(payload);
      return res.success;
    } catch (e) {
      debugPrint('Error creating pregnancy record in API: $e');
      return true;
    }
  }

  /// Sets pregnancy status (e.g. 'pregnant', 'notpregnant', 'new_mom')
  Future<bool> setPregnancyStatus(String status) async {
    _pregnancyStatus = status;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pregnancy_status', status);

    if (_currentUser != null && _currentUser!.healthDataID != null) {
      await HealthDbService.instance.saveHealthData(
        HealthDataTableCompanion(
          id: drift.Value(_currentUser!.healthDataID!),
          userId: drift.Value(_currentUser!.id),
          pregnancyStatus: drift.Value(status),
        ),
      );
    }

    notifyListeners();

    try {
      final res = await AuthApi.updateProfile({'pregnancyStatus': status});
      return res.success;
    } catch (e) {
      debugPrint('Error updating pregnancy status in API: $e');
      return true;
    }
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
        ),
      );
    }

    notifyListeners();

    if (activePregId != null) {
      try {
        final res = await PregnancyApi.deletePregnancy(activePregId);
        return res.success;
      } catch (e) {
        debugPrint('Error deleting pregnancy in API: $e');
      }
    }
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
