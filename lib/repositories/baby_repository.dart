import 'package:flutter/foundation.dart';

import 'package:allomom/controllers/baby_controller.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/baby_db_service.dart';

/// Adding a baby, in one place.
///
/// It used to sequence four local writes — birth record, the baby's own health
/// row, the immunisation and milestone schedule, and the mother's kid count.
/// allomom-api-new does all of that in a single `POST /me/baby`, so this is now
/// a thin wrapper over [BabyController] that keeps the call sites in the
/// registration flow, the complete-pregnancy modal and the Babies screen
/// working unchanged.
class BabyRepository {
  static final BabyRepository instance = BabyRepository._internal();
  BabyRepository._internal();

  final _db = BabyDbService.instance;

  /// Creates a baby and returns its id, or null if the server could not be
  /// reached.
  ///
  /// [pregnancyId] links the baby back to the active pregnancy that produced
  /// them. It stays null for a previous child added during registration, since
  /// a birth predating the app has no pregnancy row of its own.
  Future<String?> addBaby({
    required DateTime dob,
    String? pregnancyId,
    String? babyName,
    String? gender,
    String? deliveryType,
    double? weight,
    String? bloodGroup,
    String? photo,
    String? video,
    List<String> complications = const [],
    bool seedSchedule = true,
  }) async {
    final id = await BabyController.instance.addBaby(
      name: _orEmpty(babyName),
      deliveryDate: dob,
      typeOfDelivery: _orNull(deliveryType) ?? 'normal',
      pregnancyId: pregnancyId,
      gender: _orNull(gender),
      weight: weight,
      bloodGroup: _orNull(bloodGroup),
    );

    if (id == null) {
      debugPrint('⚠️ [BabyRepository] could not add baby — server unreachable');
    }
    return id;
  }

  /// Records the births a delivery produced, and returns their ids.
  ///
  /// [babyCount] is 2 for twins and so on; each baby is created separately so
  /// the server seeds a full immunisation and milestone schedule per child.
  /// Babies that could not be created are simply absent from the result, so a
  /// partial success still records the ones that landed.
  Future<List<String>> recordBirthsForPregnancy({
    required String pregnancyId,
    required DateTime deliveryDate,
    String? gender,
    String? deliveryType,
    double? weight,
    String? photo,
    int babyCount = 1,
    String? babyName,
  }) async {
    final ids = <String>[];
    for (var i = 0; i < (babyCount < 1 ? 1 : babyCount); i++) {
      final name = babyCount > 1
          ? '${babyName ?? 'Baby'} ${i + 1}'
          : (babyName ?? 'Baby');
      final id = await addBaby(
        dob: deliveryDate,
        pregnancyId: pregnancyId,
        babyName: name,
        gender: gender,
        deliveryType: deliveryType,
        weight: weight,
        photo: photo,
      );
      if (id != null) ids.add(id);
    }
    return ids;
  }

  Future<List<Baby>> getBabies() => _db.getBabies();

  Future<Baby?> getBabyById(String id) => _db.getBabyById(id);

  Future<List<Baby>> getBabiesForPregnancy(String pregnancyId) =>
      _db.getBabiesForPregnancy(pregnancyId);

  Future<bool> updateBaby(String babyId, Map<String, dynamic> changes) =>
      BabyController.instance.updateBaby(babyId, changes);

  Future<bool> deleteBaby(String babyId) =>
      BabyController.instance.deleteBaby(babyId);

  /// A baby needs a name — the server's column is not nullable — so an empty
  /// one becomes a placeholder the parent can correct rather than a failed save.
  static String _orEmpty(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? 'Baby' : trimmed;
  }

  static String? _orNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
