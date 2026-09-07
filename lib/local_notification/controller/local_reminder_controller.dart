import 'package:get/get.dart';
import 'package:allomom/local_notification/models/local_reminder.dart';
import 'package:allomom/local_notification/services/local_reminder_storage.dart';
import 'package:allomom/local_notification/services/local_reminder_scheduler.dart';

class LocalReminderController extends GetxController {
  static LocalReminderController get instance =>
      Get.isRegistered<LocalReminderController>()
          ? Get.find<LocalReminderController>()
          : Get.put(LocalReminderController._internal(), permanent: true);

  factory LocalReminderController() => instance;
  LocalReminderController._internal() {
    _loadConfigs();
  }

  @override
  void onInit() {
    super.onInit();
    _loadConfigs();
  }

  final Map<LocalReminderType, LocalReminderConfig> _configs = {};
  final RxMap<LocalReminderType, LocalReminderConfig> configsRx =
      <LocalReminderType, LocalReminderConfig>{}.obs;
  final RxBool isLoadingRx = false.obs;

  bool get isLoading => isLoadingRx.value;
  List<LocalReminderConfig> get configs =>
      LocalReminderType.values.map((t) => getConfig(t)).toList();

  /// Compatibility alias for any Flutter Listeners
  void notifyListeners() => update();

  void _loadConfigs() {
    for (final type in LocalReminderType.values) {
      final config = LocalReminderStorage.load(type);
      _configs[type] = config;
      configsRx[type] = config;
    }
    update();
  }

  LocalReminderConfig getConfig(LocalReminderType type) {
    return _configs[type] ?? LocalReminderStorage.load(type);
  }

  bool isEnabled(LocalReminderType type) {
    return getConfig(type).enabled;
  }

  /// Toggle enabled state
  Future<void> toggleReminder(LocalReminderType type, bool enabled) async {
    final current = getConfig(type);
    final updated = current.copyWith(enabled: enabled);
    _configs[type] = updated;
    configsRx[type] = updated;
    update();

    await LocalReminderScheduler.scheduleReminder(updated);
  }

  /// Update interval for interval-based reminders
  Future<void> updateInterval(
    LocalReminderType type,
    int intervalMinutes,
  ) async {
    final current = getConfig(type);
    final updated = current.copyWith(intervalMinutes: intervalMinutes);
    _configs[type] = updated;
    configsRx[type] = updated;
    update();

    if (updated.enabled) {
      await LocalReminderScheduler.scheduleReminder(updated);
    } else {
      await LocalReminderStorage.save(updated);
    }
  }

  /// Update fixed time
  Future<void> updateTime(LocalReminderType type, int hour, int minute) async {
    final current = getConfig(type);
    final updated = current.copyWith(hour: hour, minute: minute);
    _configs[type] = updated;
    configsRx[type] = updated;
    update();

    if (updated.enabled) {
      await LocalReminderScheduler.scheduleReminder(updated);
    } else {
      await LocalReminderStorage.save(updated);
    }
  }

  /// Update active window hours
  Future<void> updateActiveHours(
    LocalReminderType type,
    int startHour,
    int endHour,
  ) async {
    final current = getConfig(type);
    final updated = current.copyWith(startHour: startHour, endHour: endHour);
    _configs[type] = updated;
    configsRx[type] = updated;
    update();

    if (updated.enabled) {
      await LocalReminderScheduler.scheduleReminder(updated);
    } else {
      await LocalReminderStorage.save(updated);
    }
  }

  /// Refresh and reschedule all
  Future<void> refreshAndReschedule() async {
    isLoadingRx.value = true;
    update();

    _loadConfigs();
    await LocalReminderScheduler.rescheduleAll();

    isLoadingRx.value = false;
    update();
  }
}
