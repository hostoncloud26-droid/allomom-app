import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:allomom/api/health_api.dart';
import 'package:allomom/api/profile_api.dart';
import 'package:allomom/controllers/baby_controller.dart';
import 'package:allomom/controllers/family_controller.dart';
import 'package:allomom/controllers/pregnancy_controller.dart';
import 'package:allomom/controllers/vitals_controller.dart';
import 'package:allomom/repositories/pregnancy_state.dart';
import 'package:allomom/services/cycle_predictor.dart';
import 'package:allomom/services/auth/secure_token_store.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';
import 'package:allomom/services/sync/sync_codec.dart';
import 'package:allomom/services/sync/sync_mappers.dart';
import 'package:allomom/services/sync/sync_service.dart';

/// Owns the signed-in user and the health record, and is the entry point the
/// rest of the app reads identity from.
///
/// Everything it exposes is read out of the local database, never off the
/// network: the app is fully usable offline and [SyncService] reconciles in the
/// background. A write goes to sqlite first with `synced = 0`, then to the
/// server — so an edit made on a plane survives, and is pushed on reconnect.
class MainController extends GetxController {
  static MainController get instance => Get.isRegistered<MainController>()
      ? Get.find<MainController>()
      : Get.put(MainController._(), permanent: true);

  MainController._();

  static const _uuid = Uuid();

  User? _user;
  HealthDataTableData? _health;
  bool _isLoading = true;
  bool _bootstrapped = false;

  User? get currentUser => _user;
  HealthDataTableData? get currentHealthData => _health;
  bool get isLoading => _isLoading;

  /// Whether a session exists at all. Says nothing about registration.
  bool get isAuthenticated => SecureTokenStore.instance.hasSession;

  /// False until the registration flow completes. The app routes on this:
  /// an authenticated but unregistered user belongs in the registration flow,
  /// not the main screen.
  bool get isRegistered => _user?.isRegistered ?? false;

  /// True only when the user can be taken straight to the main screen.
  bool get isReady => isAuthenticated && isRegistered;

  String get userId => _user?.id ?? SecureTokenStore.instance.userId ?? '';
  String get healthDataId => _health?.id ?? '';
  String get userName => _user?.name ?? '';
  String get userPhone => _user?.phone ?? '';
  String get userEmail => _user?.email ?? '';
  String get countryCode => _user?.countryCode ?? '+91';
  String get gender => _user?.gender ?? 'Female';
  DateTime? get dob => _user?.dob;
  String get bio => _user?.bio ?? '';
  String get city => _user?.city ?? '';
  String get pincode => _user?.pincode ?? '';
  String get addressLine1 => _user?.addressLine1 ?? '';
  String get addressLine2 => _user?.addressLine2 ?? '';
  String? get profilePicture => _user?.profilePicture;
  String? get coverPic => _user?.coverPic;
  String get rchId => _health?.rchId ?? '';
  String get allergies => _health?.allergies ?? '';
  String get medicalCondition => _health?.medicalCondition ?? '';

  /// The last menstrual period, from the health record or the live pregnancy.
  DateTime? get lmpDate =>
      _health?.lmpDate ?? PregnancyController.instance.activePregnancy?.lmpDate;

  DateTime? get eddDate => PregnancyController.instance.activePregnancy?.eddDate;

  // ── Derived state ──────────────────────────────────────────────────────────
  //
  // Screens ask one object what the account looks like rather than assembling
  // it from four controllers. Each getter is a one-line delegation to whichever
  // controller actually owns the data, so there is still exactly one source of
  // truth per fact — this is the reading surface, not a second copy.

  PregnancyController get _pregnancy => PregnancyController.instance;
  BabyController get _baby => BabyController.instance;
  VitalsController get _vitals => VitalsController.instance;

  bool get isPregnant => _pregnancy.isPregnant;
  int get currentPregnancyDay => _pregnancy.currentPregnancyDay;
  int get currentGestationalWeek => _pregnancy.currentGestationalWeek;
  String get currentTrimester => _pregnancy.currentTrimester;
  int get currentTrimesterNumber => _pregnancy.currentTrimesterNumber;
  int get daysLeftUntilEdd => _pregnancy.daysLeftUntilEdd;
  String? get activePregnancyId => _pregnancy.activePregnancyId;
  Pregnancy? get currentPregnancy => _pregnancy.activePregnancy;
  int get completedPregnancyCount => _pregnancy.completedPregnancyCount;
  String get riskStatus => _pregnancy.activePregnancy?.riskStatus ?? 'normal';

  bool get hasKids => _baby.hasKids;
  int get kidsCount => _baby.kidsCount;
  DateTime? get youngestBabyDob => _baby.youngestBabyDob;
  int? get daysSinceDelivery => _baby.daysSinceDelivery;

  /// The status the pregnancy-state helpers expect, derived rather than stored.
  ///
  /// The server has no `pregnancy_status` column: whether a pregnancy is in
  /// progress is a fact about the pregnancy rows, so storing a second copy of
  /// it could only ever go stale.
  String get pregnancyStatus =>
      isPregnant ? pregnantStatus : notPregnantStatus;

  /// The most recent delivery, from a pregnancy's delivery date or a baby's
  /// birth date, whichever is later.
  DateTime? get lastBirthDate {
    final delivered = _pregnancy.pregnancies
        .map((p) => p.deliveryDateTime)
        .whereType<DateTime>()
        .fold<DateTime?>(
          null,
          (latest, d) => latest == null || d.isAfter(latest) ? d : latest,
        );
    final dob = youngestBabyDob;
    if (delivered == null) return dob;
    if (dob == null) return delivered;
    return dob.isAfter(delivered) ? dob : delivered;
  }

  DateTime? get lastDeliveryDate => lastBirthDate;

  /// Postpartum: not pregnant, with a birth inside the new-mom window.
  bool get isNewMom =>
      resolveIsNewMom(isPregnant: isPregnant, lastBirthDate: lastBirthDate);

  bool get hasPregnancyHistory => completedPregnancyCount > 0 || isNewMom;

  /// Blood group, now a dated reading in the vitals stream rather than a field
  /// on the health profile.
  String? get bloodGroup => _vitals.bloodGroup;

  int get averageCycleLength =>
      _vitals.averageCycleLength?.round() ?? defaultCycleLength;

  int get averagePeriodDuration =>
      _vitals.averagePeriodDuration?.round() ?? defaultPeriodDuration;

  /// The LMP the cycle tracker predicts from: the latest logged period start,
  /// falling back to the health record's LMP before any period is logged.
  DateTime? get cycleAnchorDate => _vitals.lastPeriodStart ?? _health?.lmpDate;

  bool get hasCycleTracking => cycleAnchorDate != null;

  /// Null during a pregnancy — there is no cycle to predict.
  CyclePrediction? get cyclePrediction {
    if (isPregnant) return null;
    final anchor = cycleAnchorDate;
    if (anchor == null) return null;
    return predictCycle(
      lastPeriodStart: anchor,
      cycleLength: averageCycleLength,
      periodDuration: averagePeriodDuration,
    );
  }

  String get formattedEddDate {
    final edd = eddDate;
    if (edd == null) return '--';
    return '${edd.day} ${_monthsShort[edd.month - 1]}';
  }

  String get formattedEddDateFull {
    final edd = eddDate;
    if (edd == null) return 'Not set';
    return '${edd.day} ${_monthsShort[edd.month - 1]} ${edd.year}';
  }

  static const _monthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  Future<AppDriftDatabase> get _db => SqLiteService().database;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Loads the local copy and, if signed in, kicks off a background sync.
  ///
  /// The local read is awaited so the first frame has real data; the network
  /// work deliberately is not, because a slow connection must never hold up the
  /// UI of an offline-first app.
  Future<void> bootstrap() async {
    _isLoading = true;
    update();

    // Background passes bring rows no screen asked for — the schedule of a
    // pregnancy registered offline, say — so reload whenever one lands.
    // Removed first so a second bootstrap does not register it twice.
    SyncService.instance
      ..removeListener(_onSynced)
      ..addListener(_onSynced);

    await _loadDeviceSettings();
    await loadFromLocal();

    if (isAuthenticated) {
      // A device that signed in but never completed the seed — killed mid-flow,
      // or freshly migrated onto the v7 schema — has a session but no rows.
      if (_user == null) {
        await SyncService.instance.seedFromServer();
        await loadFromLocal();
      } else {
        unawaited(SyncService.instance.syncAll());
      }
      SyncService.instance.start();

      // The family tables are not part of the incremental sync engine — they
      // are reconciled from `/family/my`, which is authoritative and cheap.
      // Unawaited for the same reason as the sync pass: an offline start must
      // still reach the first frame.
      unawaited(FamilyController.instance.refreshFromServer());
    }

    _bootstrapped = true;
    _isLoading = false;
    update();
  }

  bool get isBootstrapped => _bootstrapped;

  /// Re-reads the user and health rows, then the dependent controllers.
  void _onSynced() => unawaited(loadFromLocal());

  Future<void> loadFromLocal() async {
    final db = await _db;
    final knownId = SecureTokenStore.instance.userId;

    _user = knownId != null && knownId.isNotEmpty
        ? await (db.select(db.users)..where((u) => u.id.equals(knownId)))
              .getSingleOrNull()
        : await (db.select(db.users)..limit(1)).getSingleOrNull();

    final id = _user?.id;
    _health = id == null
        ? null
        : await (db.select(db.healthDataTable)
                ..where((h) => h.userId.equals(id)))
              .getSingleOrNull();

    await PregnancyController.instance.loadFromLocal();
    await BabyController.instance.loadFromLocal();
    await VitalsController.instance.loadFromLocal();
    await FamilyController.instance.loadFromLocal();

    update();
  }

  /// Pulls the whole account down and replaces the local copy.
  /// Used right after sign-in, and by pull-to-refresh.
  Future<bool> refreshFromServer() async {
    final ok = await SyncService.instance.seedFromServer();
    await FamilyController.instance.refreshFromServer();
    await loadFromLocal();
    return ok;
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  /// Applies a profile change locally, then pushes it.
  ///
  /// The local write lands first and unconditionally, marked `synced = 0`. If
  /// the network call fails the edit is still on screen and still queued, and
  /// the next sync pass carries it up.
  Future<bool> updateProfile(Map<String, dynamic> changes) async {
    final user = _user;
    if (user == null || changes.isEmpty) return false;

    final db = await _db;
    final now = DateTime.now();

    await (db.update(db.users)..where((u) => u.id.equals(user.id))).write(
      UsersCompanion(
        name: _nullableText(changes, 'name'),
        email: _nullableText(changes, 'email'),
        countryCode: _nullableText(changes, 'country_code'),
        coverPic: _nullableText(changes, 'cover_pic'),
        bio: _nullableText(changes, 'bio'),
        gender: _nullableText(changes, 'gender'),
        dob: changes.containsKey('dob')
            ? drift.Value(SyncCodec.date(changes['dob']))
            : const drift.Value.absent(),
        profilePicture: _nullableText(changes, 'profile_picture'),
        userType: _text(changes, 'user_type', user.userType),
        addressLine1: _nullableText(changes, 'address_line_1'),
        addressLine2: _nullableText(changes, 'address_line_2'),
        city: _nullableText(changes, 'city'),
        pincode: _nullableText(changes, 'pincode'),
        userName: _nullableText(changes, 'user_name'),
        isRegistered: changes.containsKey('is_registered')
            ? drift.Value(changes['is_registered'] == true)
            : const drift.Value.absent(),
        updatedAt: drift.Value(now),
        synced: const drift.Value(0),
      ),
    );

    await loadFromLocal();

    final response = await ProfileApi.patch(changes);
    if (response.success && response.item is Map) {
      await _applyServerUser(Map<String, dynamic>.from(response.item as Map));
      await loadFromLocal();
      return true;
    }

    debugPrint(
      'ℹ️ [MainController] profile saved locally, queued for sync: '
      '${response.detail}',
    );
    return false;
  }

  /// Records the answers the registration flow collected.
  ///
  /// Partner details are accepted and deliberately not stored: allomom-api-new
  /// has no column for them, and keeping a local-only copy that never syncs
  /// would be a field the user edits on one device and never sees on another.
  Future<bool> saveRegistration({
    String? name,
    String? gender,
    DateTime? dob,
    String? city,
    String? pincode,
    String? bloodGroup,
    DateTime? lmpDate,
    String? partnerName,
    String? partnerPhone,
    bool markRegistered = true,
  }) async {
    final profile = <String, dynamic>{
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (gender != null) 'gender': gender,
      if (dob != null) 'dob': SyncCodec.isoDate(dob),
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      if (pincode != null && pincode.trim().isNotEmpty) 'pincode': pincode.trim(),
      if (markRegistered) 'is_registered': true,
    };
    if (profile.isNotEmpty) await updateProfile(profile);

    if (lmpDate != null) {
      await updateHealthData({'lmp_date': SyncCodec.isoUtc(lmpDate)});
    }
    if (bloodGroup != null && bloodGroup.trim().isNotEmpty) {
      await VitalsController.instance.setBloodGroup(bloodGroup.trim());
    }

    return true;
  }

  /// Records the blood group as a dated reading rather than a profile field.
  Future<bool> updateBloodGroup(String group) async {
    await VitalsController.instance.setBloodGroup(group);
    await loadFromLocal();
    return true;
  }

  Future<bool> updateLmpDate(DateTime lmp) =>
      updateHealthData({'lmp_date': SyncCodec.isoUtc(lmp)});

  /// The EDD lives on the pregnancy, not the health record, so this only has
  /// somewhere to go while a pregnancy is active.
  Future<bool> updateEddDate(DateTime edd) async {
    final id = activePregnancyId;
    if (id == null) return false;
    return PregnancyController.instance.updatePregnancy(id, {
      'edd_date': SyncCodec.isoDate(edd),
    });
  }

  /// Ends or resumes the active pregnancy.
  ///
  /// There is no `pregnancy_status` column to set: whether she is pregnant is
  /// the status of her pregnancy row, so "not pregnant" means closing it out.
  Future<bool> setPregnancyStatus(String status) async {
    final id = activePregnancyId;
    if (id == null) return false;
    final normalized = normalizePregnancyStatus(status);
    if (normalized == pregnantStatus) return true;
    return PregnancyController.instance.updatePregnancy(id, {
      'status': 'delivered',
    });
  }

  /// Re-reads the babies after one is added or removed.
  Future<void> refreshKidsFromBirthRecords() async {
    await BabyController.instance.loadFromLocal();
    update();
  }

  /// Re-reads everything from the local database.
  ///
  /// Deliberately *not* called `refresh`: `GetxController.update()` calls
  /// `refresh()` to notify listeners, so overriding it with a method that
  /// reloads and then calls `update()` again is an infinite loop — one that
  /// hangs on the first rebuild rather than failing visibly.
  Future<void> reload() => loadFromLocal();

  /// Pulls the user's own record from the server.
  Future<void> fetchUser() async {
    await SyncService.instance.syncModule('user');
    await loadFromLocal();
  }

  /// Marks registration complete. One-way by design — the server refuses to
  /// flip it back, and nothing in the app should either.
  Future<bool> completeRegistration() =>
      updateProfile({'is_registered': true});

  Future<bool> updateHealthData(Map<String, dynamic> changes) async {
    final health = await _ensureHealthRecord();
    if (health == null || changes.isEmpty) return false;

    final db = await _db;
    await (db.update(db.healthDataTable)
          ..where((h) => h.id.equals(health.id)))
        .write(
          HealthDataTableCompanion(
            lmpDate: changes.containsKey('lmp_date')
                ? drift.Value(SyncCodec.date(changes['lmp_date']))
                : const drift.Value.absent(),
            rchId: _nullableText(changes, 'rch_id'),
            allergies: _nullableText(changes, 'allergies'),
            medicalCondition: _nullableText(changes, 'medical_condition'),
            updatedAt: drift.Value(DateTime.now()),
            synced: const drift.Value(0),
          ),
        );

    await loadFromLocal();
    await SyncService.instance.syncModule('health');
    await loadFromLocal();
    return true;
  }

  /// Guarantees the account has a health record, keyed by the id the *server*
  /// uses, and returns it.
  ///
  /// `GET /me/healthdata` creates the row when it is missing and answers with
  /// it, so the local copy ends up under the same id the server hangs
  /// pregnancies — and therefore babies — off. Without that agreement a baby
  /// added during registration is written locally under a pregnancy this device
  /// has never heard of, and disappears the moment anything reads it back.
  ///
  /// Falls back to the local-only row when the call cannot be made, so an
  /// offline registration still has somewhere to write.
  Future<String> ensureHealthRecord() async {
    final response = await HealthApi.get();
    if (response.success && response.item is Map) {
      final row = Map<String, dynamic>.from(response.item as Map);
      final db = await _db;
      final serverId = row['id'].toString();
      final userId = _user?.id;

      // The server's `user_id` is uniquely indexed, so any *other* row for this
      // user is a stand-in this device invented before it had heard from the
      // server. Two of them would make [loadFromLocal]'s single-row read throw,
      // so the stand-in goes — but anything written into it offline is carried
      // across first, or an edit made on a plane would vanish on landing.
      final stale = userId == null
          ? null
          : await (db.select(db.healthDataTable)
                  ..where((h) => h.userId.equals(userId) & h.id.isNotValue(serverId)))
                .getSingleOrNull();

      await const HealthMapper().applyServerRow(db, row);

      if (stale != null) {
        await (db.delete(db.healthDataTable)..where((h) => h.id.equals(stale.id)))
            .go();

        final pending = stale.synced == 0;
        if (pending) {
          await (db.update(db.healthDataTable)
                ..where((h) => h.id.equals(serverId)))
              .write(
                HealthDataTableCompanion(
                  lmpDate: stale.lmpDate == null
                      ? const drift.Value.absent()
                      : drift.Value(stale.lmpDate),
                  rchId: _keep(stale.rchId),
                  allergies: _keep(stale.allergies),
                  medicalCondition: _keep(stale.medicalCondition),
                  updatedAt: drift.Value(DateTime.now()),
                  synced: const drift.Value(0),
                ),
              );
        }
      }

      await loadFromLocal();
      return healthDataId;
    }

    debugPrint(
      'ℹ️ [MainController] health record unavailable, using local row: '
      '${response.detail}',
    );
    return (await _ensureHealthRecord())?.id ?? '';
  }

  /// Keeps a value only when there is one — an empty offline field must not
  /// overwrite what the server already knows.
  static drift.Value<String?> _keep(String? value) =>
      value == null || value.isEmpty
          ? const drift.Value.absent()
          : drift.Value(value);

  /// Guarantees a health row exists locally so a screen can write to it offline.
  Future<HealthDataTableData?> _ensureHealthRecord() async {
    if (_health != null) return _health;
    final user = _user;
    if (user == null) return null;

    final db = await _db;
    final now = DateTime.now();
    await db
        .into(db.healthDataTable)
        .insertOnConflictUpdate(
          HealthDataTableCompanion.insert(
            id: _uuid.v4(),
            userId: user.id,
            createdAt: drift.Value(now),
            updatedAt: drift.Value(now),
            synced: const drift.Value(0),
          ),
        );
    await loadFromLocal();
    return _health;
  }

  Future<void> _applyServerUser(Map<String, dynamic> json) async {
    final db = await _db;
    final updatedAt = SyncCodec.date(json['updated_at']);
    await db
        .into(db.users)
        .insertOnConflictUpdate(
          UsersCompanion(
            id: drift.Value(json['id'].toString()),
            name: drift.Value(SyncCodec.text(json['name'])),
            email: drift.Value(SyncCodec.text(json['email'])),
            phone: drift.Value(SyncCodec.text(json['phone'])),
            phoneVerified: drift.Value(SyncCodec.date(json['phone_verified'])),
            countryCode: drift.Value(SyncCodec.text(json['country_code'])),
            emailVerified: drift.Value(SyncCodec.date(json['email_verified'])),
            coverPic: drift.Value(SyncCodec.text(json['cover_pic'])),
            bio: drift.Value(SyncCodec.text(json['bio'])),
            gender: drift.Value(SyncCodec.text(json['gender'])),
            dob: drift.Value(SyncCodec.date(json['dob'])),
            profilePicture: drift.Value(SyncCodec.text(json['profile_picture'])),
            userType: drift.Value(SyncCodec.text(json['user_type']) ?? 'User'),
            addressLine1: drift.Value(SyncCodec.text(json['address_line_1'])),
            addressLine2: drift.Value(SyncCodec.text(json['address_line_2'])),
            city: drift.Value(SyncCodec.text(json['city'])),
            pincode: drift.Value(SyncCodec.text(json['pincode'])),
            lat: drift.Value(SyncCodec.number(json['lat'])),
            lng: drift.Value(SyncCodec.number(json['lng'])),
            isRegistered:
                drift.Value(SyncCodec.boolean(json['is_registered']) ?? false),
            userName: drift.Value(SyncCodec.text(json['user_name'])),
            createdAt:
                drift.Value(SyncCodec.date(json['created_at']) ?? DateTime.now()),
            updatedAt: drift.Value(updatedAt ?? DateTime.now()),
            syncedAt: drift.Value(updatedAt),
            synced: const drift.Value(1),
          ),
        );
  }

  // ── Device-local settings ──────────────────────────────────────────────────

  /// The paired AlloWear's MAC address.
  ///
  /// Device-local on purpose: it identifies a band physically paired with this
  /// phone, so it has no server column and syncing it to her other devices
  /// would be meaningless.
  String? _allowearMacAddress;
  String? get allowearMacAddress => _allowearMacAddress;

  static const _allowearKey = 'allomom_allowear_mac';

  Future<void> _loadDeviceSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _allowearMacAddress = prefs.getString(_allowearKey);
    } catch (e) {
      debugPrint('⚠️ [MainController] could not read device settings: $e');
    }
  }

  Future<void> setAllowearMacAddress(String? mac) async {
    _allowearMacAddress = mac;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mac == null || mac.isEmpty) {
        await prefs.remove(_allowearKey);
      } else {
        await prefs.setString(_allowearKey, mac);
      }
    } catch (e) {
      debugPrint('⚠️ [MainController] could not save device settings: $e');
    }
    update();
  }

  /// Alias kept for the screens that read the profile picture as `image`.
  String? get image => profilePicture;

  String get adline1 => addressLine1;
  String get adline2 => addressLine2;

  /// Drops every trace of the account from the device.
  Future<void> clearSession() async {
    SyncService.instance.stop();
    final db = await _db;
    await db.clearAccountData();
    _user = null;
    _health = null;
    PregnancyController.instance.reset();
    BabyController.instance.reset();
    VitalsController.instance.reset();
    update();
  }

  /// Builds a companion field only when the caller actually sent the key.
  ///
  /// An omitted key leaves the column untouched; an explicit null clears it.
  /// That is the same `exclude_unset` contract the server's PATCH routes use,
  /// so a partial update means the same thing on both sides.
  static drift.Value<String?> _nullableText(
    Map<String, dynamic> changes,
    String key,
  ) {
    if (!changes.containsKey(key)) return const drift.Value.absent();
    final raw = changes[key];
    return drift.Value<String?>(raw?.toString());
  }

  /// As [_nullableText], but for a non-nullable column: an explicit null falls
  /// back to [fallback] rather than violating the column's constraint.
  static drift.Value<String> _text(
    Map<String, dynamic> changes,
    String key,
    String fallback,
  ) {
    if (!changes.containsKey(key)) return const drift.Value.absent();
    return drift.Value<String>(changes[key]?.toString() ?? fallback);
  }
}

/// Fires [future] without awaiting it, making the intent explicit at the call
/// site rather than leaving a bare unawaited future for a reader to wonder at.
void unawaited(Future<void> future) {
  future.catchError((Object e) {
    debugPrint('⚠️ [MainController] background task failed: $e');
  });
}
