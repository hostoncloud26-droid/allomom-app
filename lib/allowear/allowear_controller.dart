import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:allowear_sdk/allowear_sdk.dart';
import 'package:allowear_sdk/allowear_v1.dart' as v1;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import 'package:gal/gal.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:localstorage/localstorage.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:allomom/allowear/core/models/ble_device.dart';
import 'package:allomom/allowear/core/models/permission_issue.dart';
import 'package:allomom/allowear/features/device/views/device_capability_page.dart';
import 'package:allomom/allowear/sync_functions.dart';
import 'package:allomom/allowear/widgets/device_type_sheet.dart';
import 'package:allomom/allowear/compat/user_api.dart';
import 'package:allomom/allowear/entry/location_disabled_sheet.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/allowear/entry/allowear_reminder_scheduler.dart';
import 'package:allomom/models/vital_sync_item.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

/// The app-wide Allowear controller, created on first use.
///
/// Everything Allowear lives on this one controller, so call sites just reach
/// for `allowear` rather than registering a controller per feature.
AllowearController get allowear => Get.isRegistered<AllowearController>()
    ? Get.find<AllowearController>()
    : Get.put(AllowearController(), permanent: true);

/// Display name for a device model, used until the device reports its own.
extension AllowearDeviceTypeName on AllowearDeviceType {
  String get displayName => switch (this) {
        AllowearDeviceType.v1 => 'Allowear Bracelet',
        AllowearDeviceType.v8 => 'Allowear Fit',
        AllowearDeviceType.nx => 'Allowear NX',
      };
}

/// Live state for one on-demand vital measurement (heart rate, SpO2, HRV,
/// temperature).
///
/// The measurements differ only in how long they run and which SDK calls
/// drive them, so they share this one holder rather than a controller each.
class AllowearMeasurement {
  AllowearMeasurement({
    required this.name,
    required this.durationSeconds,
    required Future<void> Function() onStart,
    required Future<void> Function() onStop,
    bool Function()? stopsOnFirstReading,
    void Function(double value, DateTime at)? onResult,
  })  : _onStart = onStart,
        _onStop = onStop,
        _stopsOnFirstReading = stopsOnFirstReading,
        _onResult = onResult;

  final String name;
  final int durationSeconds;
  final Future<void> Function() _onStart;
  final Future<void> Function() _onStop;

  /// Whether the first valid reading ends the measurement. Devices that stream
  /// continuously and never mark a reading final (the ring, the watch) would
  /// otherwise keep measuring until the timer runs out.
  final bool Function()? _stopsOnFirstReading;

  /// Called once with the last valid reading when a measurement finishes.
  final void Function(double value, DateTime at)? _onResult;

  /// The latest reading, rounded, for the whole-number vitals.
  final Rxn<int> reading = Rxn<int>();

  /// The latest reading unrounded, for vitals shown with decimals.
  final Rxn<double> preciseReading = Rxn<double>();
  final Rxn<DateTime> lastUpdated = Rxn<DateTime>();
  final RxBool isMonitoring = false.obs;

  /// Last 30 readings, for the live graph.
  final RxList<int> history = <int>[].obs;

  final RxDouble progress = 0.0.obs;
  final RxString status = 'Measuring...'.obs;

  Timer? _timer;
  bool _completed = false;

  /// Feeds a reading in from the device stream.
  void accept(
      {required num value, required DateTime at, required bool isComplete}) {
    // Readings that trail in after the measurement ended belong to no one.
    if (_completed || !isMonitoring.value) return;

    reading.value = value.round();
    preciseReading.value = value.toDouble();
    lastUpdated.value = at;

    if (value > 0) {
      history.add(value.round());
      if (history.length > 30) history.removeAt(0);
    }

    if (isComplete || (value > 0 && (_stopsOnFirstReading?.call() ?? false))) {
      complete();
    }
  }

  Future<void> start() async {
    try {
      _completed = false;
      reading.value = null;
      preciseReading.value = null;
      history.clear();
      progress.value = 0.0;
      status.value = 'Measuring...';
      isMonitoring.value = true;

      _startProgressTimer();
      await _onStart();
    } catch (e) {
      _cancelProgressTimer();
      isMonitoring.value = false;
      Get.snackbar('Error', 'Failed to start $name monitoring: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> stop() async {
    try {
      _cancelProgressTimer();
      isMonitoring.value = false;
      await _onStop();
    } catch (e) {
      Get.snackbar('Error', 'Failed to stop $name monitoring: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _startProgressTimer() {
    _timer?.cancel();
    const tickMs = 100;
    int elapsedMs = 0;
    _timer = Timer.periodic(const Duration(milliseconds: tickMs), (_) {
      elapsedMs += tickMs;
      final value = elapsedMs / (durationSeconds * 1000);
      progress.value = value.clamp(0.0, 1.0);

      if (value >= 0.85 && status.value == 'Measuring...') {
        status.value = 'Calculating...';
      }
      if (value >= 1.0) complete();
    });
  }

  void _cancelProgressTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void complete() {
    if (_completed) return;
    _completed = true;
    _cancelProgressTimer();
    progress.value = 1.0;
    status.value = 'Done';

    final value = preciseReading.value;
    if (value != null && value > 0) {
      _onResult?.call(value, lastUpdated.value ?? DateTime.now());
    }

    // Smooth transition to the summary view.
    Future.delayed(const Duration(milliseconds: 800), () {
      if (status.value == 'Done') isMonitoring.value = false;
    });

    _onStop().catchError((Object e) {
      debugPrint('[Allowear] stopping $name measurement failed: $e');
    });
  }

  void dispose() => _cancelProgressTimer();
}

/// The single controller for everything Allowear: device model selection,
/// connection and auto-reconnect, permissions, battery, on-demand vitals,
/// health-data sync, timed monitoring config, firmware, and the
/// bracelet-triggered camera.
///
/// All BLE traffic goes through `allowear_sdk`. Connect, sync, live vitals and
/// schedules use the unified API, so they work the same on the bracelet (V1),
/// Allowear Fit (V8) and NX watch. The camera, video HID mode, firmware update,
/// shutdown and factory reset only exist on the bracelet and go through
/// `allowear_v1`.
class AllowearController extends GetxController with WidgetsBindingObserver {
  static const String connectedDeviceMacKey = 'allowear_connected_device_mac';
  static const String deviceTypeKey = 'allowear_device_type';
  static const String deviceMacKey = 'allowear_device_mac';

  AllowearRepository get _sdk => AllowearSdk.instance;
  final FlutterBlueClassic _bluetooth = FlutterBlueClassic();

  // ───────────────────────────── Device / connection ─────────────────────────

  /// The device model the SDK is talking to, persisted across launches.
  final Rxn<AllowearDeviceType> deviceType = Rxn<AllowearDeviceType>();

  final RxList<BleDevice> devices = <BleDevice>[].obs;
  final Rx<BleDevice?> connectedDevice = Rx<BleDevice?>(null);
  final Rx<BleDevice?> savedDevice = Rx<BleDevice?>(null);
  final RxBool isScanning = false.obs;
  final RxBool isConnecting = false.obs;
  final RxString connectingDeviceId = ''.obs;

  /// Hardware MAC of the device, as `AA:BB:CC:DD:EE:FF`, read through
  /// [AllowearRepository.getDeviceMac]. Kept after a disconnect so the
  /// "searching" screen can still show it.
  final RxnString deviceMac = RxnString();
  final Rxn<Map<String, dynamic>> firmwareInfo = Rxn<Map<String, dynamic>>();
  final RxInt videoHidMode = 0.obs;
  final RxMap<String, bool> deviceCapabilities = <String, bool>{}.obs;
  final Rx<AllowearPermissionIssue?> permissionIssue =
      Rx<AllowearPermissionIssue?>(null);

  /// Whether the selected model is the V1 bracelet, the only one with camera,
  /// video HID, firmware update, shutdown and factory reset.
  bool get isBracelet => deviceType.value == AllowearDeviceType.v1;

  StreamSubscription<ConnectionUpdate>? _connectionSub;
  StreamSubscription<List<DiscoveredDevice>>? _scanSub;
  StreamSubscription<v1.DeviceConnectionMessage>? _braceletCapabilitySub;
  StreamSubscription<Map<String, dynamic>>? _firmwareVersionSub;
  StreamSubscription<int>? _videoControlSub;

  // ───────────────────────────────── Battery ─────────────────────────────────

  final Rxn<int> batteryLevel = Rxn<int>();
  final Rxn<DateTime> batteryLastUpdated = Rxn<DateTime>();

  StreamSubscription<v1.BatteryInfo>? _batterySub;
  DateTime? _lastSavedBatteryTime;
  int? _lastSavedBatteryLevel;

  /// Set on each connect; the first real reading after it decides the
  /// charge reminders.
  bool _chargeReminderCheckPending = false;

  // ──────────────────────────── On-demand vitals ─────────────────────────────

  late final AllowearMeasurement hr = AllowearMeasurement(
    name: 'heart rate',
    durationSeconds: 30,
    onStart: () => _sdk.startLiveMeasurement(VitalType.heartRate),
    onStop: () => _sdk.stopLiveMeasurement(VitalType.heartRate),
    stopsOnFirstReading: _streamsWithoutFinalReading,
  );

  late final AllowearMeasurement spo2 = AllowearMeasurement(
    name: 'blood oxygen',
    durationSeconds: 60,
    onStart: () => _sdk.startLiveMeasurement(VitalType.spo2),
    onStop: () => _sdk.stopLiveMeasurement(VitalType.spo2),
    stopsOnFirstReading: _streamsWithoutFinalReading,
  );

  late final AllowearMeasurement hrv = AllowearMeasurement(
    name: 'HRV',
    durationSeconds: 180,
    onStart: () => _sdk.startLiveMeasurement(VitalType.hrv),
    onStop: () => _sdk.stopLiveMeasurement(VitalType.hrv),
    stopsOnFirstReading: _streamsWithoutFinalReading,
  );

  /// Skin temperature, on the models that can measure it live. Its reading is
  /// saved straight away: nothing guarantees the device keeps a live reading
  /// in the history a sync would pull.
  late final AllowearMeasurement temperature = AllowearMeasurement(
    name: 'skin temperature',
    durationSeconds: 60,
    onStart: () => _sdk.startLiveMeasurement(VitalType.temperature),
    onStop: () => _sdk.stopLiveMeasurement(VitalType.temperature),
    stopsOnFirstReading: () => true,
    onResult: (value, at) => _saveLiveVital(
        key: 'temperature', value: value, unit: '°C', at: at),
  );

  /// The bracelet streams interim values and then marks its final one; the
  /// ring and the watch stream continuously and never do, so for them the
  /// first valid value is the result.
  bool _streamsWithoutFinalReading() => !isBracelet;

  StreamSubscription<LiveVitalReading>? _liveSub;

  // ─────────────────────────────── Health sync ───────────────────────────────

  final RxBool isSyncing = false.obs;
  final RxInt syncProgress = 0.obs;
  final RxString syncStatus = 'Ready to sync'.obs;
  final Rx<DateTime?> lastSyncTime = Rx<DateTime?>(null);

  StreamSubscription<SyncProgress>? _syncSub;

  // ─────────────────────── Timed (automatic) monitoring ──────────────────────

  /// The automatic measurement schedule of every vital the device reported.
  /// A vital missing here has not been read from the device yet.
  final RxMap<VitalType, AutoVitalConfig> autoConfigs =
      <VitalType, AutoVitalConfig>{}.obs;

  /// Vitals whose schedule is being read or written right now.
  final RxSet<VitalType> savingSchedules = <VitalType>{}.obs;
  final RxBool isLoadingSchedules = false.obs;

  // ─────────────────────────────────  Camera  ────────────────────────────────

  CameraController? cameraController;
  final RxList<CameraDescription> cameras = <CameraDescription>[].obs;
  final RxBool isCameraInitialized = false.obs;
  final RxInt currentCameraIndex = 0.obs;
  final RxList<String> capturedImages = <String>[].obs;

  StreamSubscription<int>? _cameraSub;

  // ═══════════════════════════════ Lifecycle ═════════════════════════════════

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    // The app asks for permissions itself, with its own explanation, before
    // any scan or connect. Letting the SDK prompt too would pop system dialogs
    // in the middle of a silent reconnect on app open.
    _sdk.autoRequestPermissions = false;

    _listenConnection();
    _listenScanResults();
    _listenBraceletEvents();
    _listenVitals();
    _listenSyncProgress();

    final storedSync = localStorage.getItem('allowear_synced_at')?.trim();
    if (storedSync != null && storedSync.isNotEmpty) {
      lastSyncTime.value = DateTime.tryParse(storedSync);
    }

    checkPermissions();
    _restoreDeviceType()
        .then((_) => checkConnectedDevice())
        .then((_) => startAutoReconnect());
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _reconnectTimer?.cancel();

    _connectionSub?.cancel();
    _scanSub?.cancel();
    _braceletCapabilitySub?.cancel();
    _firmwareVersionSub?.cancel();
    _videoControlSub?.cancel();
    _batterySub?.cancel();
    _liveSub?.cancel();
    _syncSub?.cancel();
    _cameraSub?.cancel();

    hr.dispose();
    spo2.dispose();
    hrv.dispose();
    temperature.dispose();
    cameraController?.dispose();

    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    checkPermissions().then((_) {
      if (permissionIssue.value == null && connectedDevice.value == null) {
        startAutoReconnect();
      }
    });
  }

  // ═══════════════════════════ Device model selection ════════════════════════

  AllowearDeviceType? _savedDeviceType() =>
      AllowearDeviceType.fromId(localStorage.getItem(deviceTypeKey)?.trim());

  /// Restores the remembered device model into the SDK.
  ///
  /// A bracelet paired on this phone before the SDK migration has a MAC saved
  /// but no model, and the bracelet was the only model then, so it is taken
  /// as V1. A MAC known only from the account profile (a fresh login) says
  /// nothing about the model, so the user picks it instead of the app
  /// guessing and failing to connect.
  Future<void> _restoreDeviceType() async {
    var type = _savedDeviceType();
    deviceMac.value = localStorage.getItem(deviceMacKey)?.trim();
    final localMac = localStorage.getItem(connectedDeviceMacKey)?.trim();
    if (type == null && localMac != null && localMac.isNotEmpty) {
      type = AllowearDeviceType.v1;
    }
    if (type != null) {
      await selectDeviceType(type);
      _restoreSavedDevice();
    }
  }

  /// Selects [type] in the SDK and remembers it for the next launch.
  Future<void> selectDeviceType(AllowearDeviceType type) async {
    localStorage.setItem(deviceTypeKey, type.id);
    deviceType.value = type;
    try {
      await _sdk.setDeviceType(type);
    } catch (e) {
      debugPrint('[Allowear] selecting ${type.id} failed: $e');
    }
  }

  /// Asks which model the user has, saves it, and starts scanning for it.
  Future<void> pickDeviceTypeAndScan() async {
    final type = await DeviceTypeSheet.show();
    if (type == null) return;
    if (isScanning.value) await stopScan();
    await selectDeviceType(type);
    await startScan();
  }

  // ═════════════════════════ Connection event handling ═══════════════════════

  /// MAC of the connect attempt in flight, for back ends whose connection
  /// events do not carry one.
  String? _pendingMac;
  String? _pendingName;

  void _listenConnection() {
    _connectionSub = _sdk.connectionStateStream.listen((event) {
      switch (event.state) {
        case AllowearConnectionState.connecting:
          isConnecting.value = true;
          connectingDeviceId.value = event.macAddress ?? _pendingMac ?? '';
          update();
          break;

        case AllowearConnectionState.connected:
          _onConnected(
            event.macAddress ?? _pendingMac ?? getSavedMac() ?? '',
            event.deviceName ?? _pendingName,
          );
          break;

        case AllowearConnectionState.disconnected:
        case AllowearConnectionState.error:
          _onLinkLost();
          break;
      }
    });
  }

  void _onLinkLost() {
    connectedDevice.value = null;
    isConnecting.value = false;
    connectingDeviceId.value = '';
    _lastUserInfoSent = null;
    // A disconnect the user asked for (or a logout) ends here: nothing to
    // show as "searching" and nothing to retry.
    if (_userDisconnected) {
      savedDevice.value = null;
      update();
      return;
    }
    // Put the remembered device back on screen so the UI shows the
    // "searching" state while we retry, rather than falling back to the
    // pick-a-device view.
    _restoreSavedDevice();
    update();
    // Only treat this as an unsolicited drop. A failure reported while an
    // attempt is in flight is that attempt's own result, and it schedules
    // its own retry — scheduling here too would double-advance the
    // backoff and could strand the chain on the in-flight guard.
    if (!_reconnectInFlight) _scheduleReconnect();
  }

  void _onConnected(String mac, String? name) {
    // Both the connection stream and the connect call itself report success;
    // only the first one does the post-connect work.
    if (mac.isEmpty || connectedDevice.value?.id == mac) return;

    final type = deviceType.value;
    connectedDevice.value = BleDevice(
      name: (name == null || name.isEmpty)
          ? (savedDevice.value?.name ?? type?.displayName ?? 'Allowear')
          : name,
      id: mac,
      deviceType: type,
    );
    savedDevice.value = null;
    isConnecting.value = false;
    connectingDeviceId.value = '';
    isScanning.value = false;
    _reconnectAttempt = 0;
    _reconnectTimer?.cancel();
    update();

    _saveConnectedDeviceMac(mac);
    _chargeReminderCheckPending = true;
    _afterConnect();
  }

  /// Reads device details, applies settings, then syncs. Run in sequence so
  /// the ring and the watch, which answer one command at a time, never see
  /// two in flight.
  Future<void> _afterConnect() async {
    _refreshCapabilityMap();

    if (isBracelet) {
      _safe(v1.DeviceService.getFirmwareVersion, 'firmware read');
      _safe(v1.DeviceService.getVideoControlMode, 'video mode read');
    } else if (_sdk.capabilities.supports(AllowearFeature.deviceTime)) {
      await _safe(() => _sdk.setDeviceTime(), 'clock sync');
    }
    await fetchDeviceMac();
    await refreshBattery();

    if (_applyDefaultSchedules) {
      _applyDefaultSchedules = false;
      try {
        final applied = await _sdk.applyDefaultAutoVitalConfig();
        debugPrint('[Allowear] default schedules applied: $applied');
      } catch (e) {
        debugPrint('[Allowear] applying default schedules failed: $e');
      }
    }

    await fetchAllConfigs();
    await syncUserInfoToDevice();
    await _triggerHealthSync();
  }

  /// Reads the connected device's MAC from the SDK and remembers it.
  ///
  /// The hardware MAC, not the connect ID (a CoreBluetooth UUID on iOS), is
  /// what the account is linked to on the server.
  Future<String?> fetchDeviceMac() async {
    String? mac;
    try {
      mac = await _sdk.getDeviceMac();
    } catch (e) {
      debugPrint('[Allowear] MAC read failed: $e');
    }
    // Android connects by MAC, so the connect ID stands in if the read failed.
    mac ??= normalizeMacAddress(connectedDevice.value?.id);
    if (mac == null || mac.isEmpty) return deviceMac.value;

    deviceMac.value = mac;
    localStorage.setItem(deviceMacKey, mac);
    if (Get.isRegistered<MainController>()) {
      // Allomom: the MAC is kept on the session with a setter.
      Get.find<MainController>().setAllowearMacAddress(mac);
    }
    Userapi.connectAllowear(mac).catchError((e) {
      debugPrint('[Allowear] server connect sync failed: $e');
      return e;
    });
    return mac;
  }

  static Future<void> _safe(Future<void> Function() action, String what) async {
    try {
      await action();
    } catch (e) {
      debugPrint('[Allowear] $what failed: $e');
    }
  }

  // ═══════════════════════════ Auto-reconnect ════════════════════════════════
  //
  // On app open (and on resume) the remembered device is connected directly by
  // MAC — no discovery scan, which Android may withhold in the background. A
  // failed attempt backs off and retries; a manual disconnect stops the loop.

  static const List<int> _backoffSeconds = [2, 4, 8, 15, 30, 60];
  static const int _maxReconnectAttempts = 8;

  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _reconnectInFlight = false;
  bool _userDisconnected = false;

  /// Reads the remembered MAC from local storage. The MAC on the user's
  /// profile is not used: only a device paired on this phone counts.
  String? getSavedMac() {
    final savedMac = localStorage.getItem(connectedDeviceMacKey)?.trim();
    return (savedMac == null || savedMac.isEmpty) ? null : savedMac;
  }

  /// Shows the remembered device as "searching" while it is reconnected.
  ///
  /// Only with a known model: without one there is nothing to reconnect with,
  /// and the screen would sit on "looking for device" forever.
  void _restoreSavedDevice() {
    final mac = getSavedMac();
    final type = deviceType.value;
    if (type != null &&
        mac != null &&
        mac.isNotEmpty &&
        connectedDevice.value == null) {
      savedDevice.value = BleDevice(
        name: type.displayName,
        id: mac,
        deviceType: type,
      );
    }
  }

  /// Starts (or restarts) the reconnect loop for the remembered device.
  /// Safe to call repeatedly — it no-ops while connected or mid-attempt.
  Future<void> startAutoReconnect() async {
    _userDisconnected = false;
    _reconnectAttempt = 0;
    _reconnectTimer?.cancel();
    await _attemptReconnect();
  }

  Future<void> _attemptReconnect() async {
    if (_reconnectInFlight || _userDisconnected) return;
    if (connectedDevice.value != null) return;

    final mac = getSavedMac();
    if (mac == null || mac.isEmpty) return;

    final type = deviceType.value;
    if (type == null) return;

    // Don't burn an attempt while Bluetooth or permissions are unusable.
    await checkPermissions();
    if (permissionIssue.value != null) {
      _scheduleReconnect();
      return;
    }

    _reconnectInFlight = true;
    isConnecting.value = true;
    connectingDeviceId.value = mac;
    update();

    bool connected = false;
    try {
      await _connect(mac, savedDevice.value?.name ?? type.displayName, type);
      connected = true;
    } catch (e) {
      debugPrint('[Allowear] reconnect attempt failed: $e');
    } finally {
      _reconnectInFlight = false;
    }

    if (connected) return;

    isConnecting.value = false;
    connectingDeviceId.value = '';
    update();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_userDisconnected) return;
    if (getSavedMac()?.isNotEmpty != true) return;

    if (_reconnectAttempt >= _maxReconnectAttempts) {
      debugPrint(
          '[Allowear] gave up reconnecting after $_reconnectAttempt attempts; '
          'will retry when the app is resumed');
      return;
    }

    final delay =
        _backoffSeconds[min(_reconnectAttempt, _backoffSeconds.length - 1)];
    _reconnectAttempt++;
    debugPrint('[Allowear] reconnect attempt $_reconnectAttempt in ${delay}s');
    _reconnectTimer = Timer(Duration(seconds: delay), _attemptReconnect);
  }

  /// Connects through the SDK with [type]'s back end. Throws on failure.
  ///
  /// On success the connection stream normally drives the state; the explicit
  /// [_onConnected] covers a back end that reports success only by returning.
  Future<void> _connect(String mac, String name, AllowearDeviceType type) async {
    _pendingMac = mac;
    _pendingName = name;
    try {
      await _sdk.connect(mac, deviceName: name, deviceType: type);
      _onConnected(mac, name);
    } finally {
      _pendingMac = null;
      _pendingName = null;
    }
  }

  // ═════════════════════════════ Permissions ═════════════════════════════════

  /// The runtime permissions the SDK needs before it will scan or connect.
  ///
  /// Deliberately excludes background location. Android ignores a request that
  /// mixes ACCESS_BACKGROUND_LOCATION with foreground location and grants
  /// neither — which surfaces as the permission dialog simply never appearing.
  /// Background location must be requested on its own, after foreground is
  /// already granted, and none of the devices need it.
  List<Permission> get _requiredPermissions => Platform.isAndroid
      ? const [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
          Permission.location,
        ]
      : const [Permission.bluetooth];

  /// Asks for the permissions we need and, on Android, brings the adapter up.
  Future<void> _ensureBluetoothReady() async {
    await _requiredPermissions.request();

    if (!Platform.isAndroid) return;
    try {
      if (!await _bluetooth.isEnabled) await _bluetooth.turnOn();
    } catch (e) {
      debugPrint('[Allowear] could not turn Bluetooth on: $e');
    }
  }

  Future<void> checkPermissions() async {
    try {
      permissionIssue.value = await _currentPermissionIssue();
    } catch (e) {
      debugPrint('[Allowear] permission check failed: $e');
    }
  }

  Future<void> resolvePermissionIssue() async {
    final issue = permissionIssue.value;
    if (issue == null) return;

    if (issue.isSettingsAction) {
      await openAppSettings();
    } else {
      switch (issue.type) {
        case AllowearPermissionIssueType.locationServiceDisabled:
          if (!await Geolocator.isLocationServiceEnabled()) {
            LocationDisabledSheet.show(
              title: 'Location Service Required'.tr,
              subtitle:
                  'Please turn on your device\'s location services (GPS) to discover nearby Allowear devices.'
                      .tr,
            );
          }
          break;
        case AllowearPermissionIssueType.bluetoothDisabled:
          if (Platform.isAndroid) {
            try {
              if (!await _bluetooth.isEnabled) await _bluetooth.turnOn();
            } catch (_) {
              await openAppSettings();
            }
          } else {
            await openAppSettings();
          }
          break;
        default:
          await _ensureBluetoothReady();
      }
    }

    await checkPermissions();

    final remaining = permissionIssue.value;
    if (remaining == null) {
      if (connectedDevice.value == null) startAutoReconnect();
      return;
    }

    // The request came back without the OS prompting — it will not ask again.
    // Hand the user off to app settings, otherwise tapping the button looks
    // like it did nothing at all.
    if (!issue.isSettingsAction &&
        remaining.type == AllowearPermissionIssueType.permanentlyDenied) {
      await openAppSettings();
    }
  }

  /// Inspects permissions, GPS and the Bluetooth adapter, and describes the
  /// first thing standing between the app and a scan.
  Future<AllowearPermissionIssue?> _currentPermissionIssue() async {
    if (Platform.isAndroid) {
      final permanentlyDenied = await Permission.location.isPermanentlyDenied ||
          await Permission.bluetoothScan.isPermanentlyDenied ||
          await Permission.bluetoothConnect.isPermanentlyDenied ||
          await Permission.bluetoothAdvertise.isPermanentlyDenied;
      if (permanentlyDenied) {
        return AllowearPermissionIssue(
          type: AllowearPermissionIssueType.permanentlyDenied,
          title: 'Permissions Required'.tr,
          description:
              'Please grant Location and Bluetooth permissions in Settings to scan devices'
                  .tr,
          actionText: 'Open Settings'.tr,
          isSettingsAction: true,
        );
      }

      final denied = await Permission.location.isDenied ||
          await Permission.bluetoothScan.isDenied ||
          await Permission.bluetoothConnect.isDenied ||
          await Permission.bluetoothAdvertise.isDenied;
      if (denied) {
        return AllowearPermissionIssue(
          type: AllowearPermissionIssueType.denied,
          title: 'Permissions Required'.tr,
          description:
              'Location and Bluetooth permissions are required to scan devices'
                  .tr,
          actionText: 'Enable'.tr,
          isSettingsAction: false,
        );
      }

      if (!await Geolocator.isLocationServiceEnabled()) {
        return AllowearPermissionIssue(
          type: AllowearPermissionIssueType.locationServiceDisabled,
          title: 'Location Service Required'.tr,
          description:
              'Please turn on your device\'s location services (GPS) to discover nearby Allowear devices.'
                  .tr,
          actionText: 'Turn On GPS'.tr,
          isSettingsAction: false,
        );
      }
    } else if (Platform.isIOS) {
      final permanentlyDenied =
          await Permission.bluetooth.isPermanentlyDenied ||
              await Permission.bluetooth.isRestricted;
      if (permanentlyDenied) {
        return AllowearPermissionIssue(
          type: AllowearPermissionIssueType.permanentlyDenied,
          title: 'Bluetooth Permission Required'.tr,
          description:
              'Please grant Bluetooth permission in Settings to scan devices'
                  .tr,
          actionText: 'Open Settings'.tr,
          isSettingsAction: true,
        );
      }

      if (await Permission.bluetooth.isDenied) {
        return AllowearPermissionIssue(
          type: AllowearPermissionIssueType.denied,
          title: 'Bluetooth Permission Required'.tr,
          description:
              'Please allow Bluetooth permission to scan for Allowear devices'
                  .tr,
          actionText: 'Enable'.tr,
          isSettingsAction: false,
        );
      }
    }

    try {
      if (!await _bluetooth.isEnabled) {
        return AllowearPermissionIssue(
          type: AllowearPermissionIssueType.bluetoothDisabled,
          title: 'Bluetooth Required'.tr,
          description:
              'Please turn on Bluetooth to scan for Allowear devices'.tr,
          actionText: 'Turn On'.tr,
          isSettingsAction: false,
        );
      }
    } catch (_) {}

    return null;
  }

  // ═══════════════════════════ Scanning & pairing ════════════════════════════

  /// The name the SDK's scanner gives a device that advertises none, on both
  /// Android and iOS. Such a device can't be an Allowear, which always
  /// advertises its own name, so it is kept out of the list.
  static const String _unnamedDevicePlaceholder = 'v8 device';

  static bool _isListable(DiscoveredDevice device) {
    final name = device.name.trim().toLowerCase();
    return name.isNotEmpty && name != _unnamedDevicePlaceholder;
  }

  void _listenScanResults() {
    _scanSub = _sdk.scanResultsStream.listen((found) {
      devices.value =
          found.where(_isListable).map(BleDevice.fromDiscovered).toList();
    });
  }

  /// Re-checks permissions and restarts discovery. Used by the "refresh" action
  /// on the disconnected view.
  Future<void> initBluetooth() async {
    await checkPermissions();
    await checkConnectedDevice();
    _restoreSavedDevice();
    if (connectedDevice.value == null) await startScan();
  }

  /// Picks up a device that is still connected from before (a hot restart, or
  /// the native side keeping the bracelet link across an engine restart).
  Future<void> checkConnectedDevice() async {
    final type = deviceType.value;
    if (type == null) return;

    try {
      String? mac;
      String? name;
      if (type == AllowearDeviceType.v1) {
        final device = await v1.DeviceService.getConnectedDevice();
        name = device['name']?.toString();
        mac = device['id']?.toString();
      } else if (_sdk.isConnected) {
        final info = await _sdk.getDeviceInfo();
        name = info.deviceName;
        mac = info.macAddress ?? getSavedMac();
      }
      if (name == null || name.isEmpty || mac == null || mac.isEmpty) return;

      _onConnected(mac, name);
    } catch (_) {
      // Nothing connected.
    }
  }

  /// Scans for the selected model. Asks which model first when none is saved.
  Future<void> startScan() async {
    if (deviceType.value == null) {
      await pickDeviceTypeAndScan();
      return;
    }

    await checkPermissions();
    if (permissionIssue.value != null) {
      isScanning.value = false;
      return;
    }

    try {
      await _ensureBluetoothReady();
    } catch (e) {
      debugPrint('[Allowear] enableBluetooth failed: $e');
      await checkPermissions();
      isScanning.value = false;
      return;
    }

    isScanning.value = true;
    devices.clear();
    try {
      await _sdk.startScan();
    } catch (e) {
      debugPrint('[Allowear] scan failed to start: $e');
      isScanning.value = false;
      await checkPermissions();
      if (permissionIssue.value == null) {
        Get.snackbar('Error', _describe(e),
            snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  Future<void> stopScan() async {
    try {
      await _sdk.stopScan();
    } catch (e) {
      debugPrint('[Allowear] stopping scan failed: $e');
    }
    isScanning.value = false;
  }

  /// Set when the user pairs a new ring or watch, so it starts recording
  /// vitals on its own. The bracelet keeps whatever schedule it already has.
  bool _applyDefaultSchedules = false;

  /// Connects to a device the user picked from the scan list.
  Future<void> connectToDevice(BleDevice device, {bool silent = false}) async {
    if (isConnecting.value) return;

    final type = device.deviceType ?? deviceType.value;
    if (type == null) return;
    if (type != deviceType.value) await selectDeviceType(type);

    _userDisconnected = false;
    isConnecting.value = true;
    connectingDeviceId.value = device.id;

    // Held for the same reason as in _attemptReconnect: a failure arriving on
    // the connection stream belongs to this attempt, not to a dropped link, so
    // the auto-reconnect loop should stay out of it.
    _reconnectTimer?.cancel();
    _reconnectInFlight = true;
    _applyDefaultSchedules = type != AllowearDeviceType.v1;

    try {
      await stopScan();
      await _connect(
        device.id,
        device.name.isNotEmpty ? device.name : type.displayName,
        type,
      );
    } catch (e) {
      _applyDefaultSchedules = false;
      isConnecting.value = false;
      connectingDeviceId.value = '';
      if (!silent) {
        Get.snackbar(
          'Error',
          e is ConnectionFailureException
              ? 'Could not connect to ${device.name}'
              : 'Failed to connect: ${_describe(e)}',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      _reconnectInFlight = false;
    }
  }

  /// User-initiated disconnect: unlinks the device from the account, drops
  /// the link and forgets everything saved about it.
  Future<void> disconnectAllowear() async {
    await _forgetDevice();
    try {
      await Userapi.disconnectAllowear();
    } catch (e) {
      debugPrint('[Allowear] server disconnect sync failed: $e');
    }
  }

  /// Logout: drops the link and clears this user's device state. The device
  /// stays linked to the account on the server, so it comes back on login.
  Future<void> resetForLogout() => _forgetDevice();

  /// Local storage keys holding the remembered device.
  static const List<String> _savedKeys = [
    connectedDeviceMacKey,
    deviceTypeKey,
    deviceMacKey,
    'allowear_synced_at',
  ];

  Future<void> _forgetDevice() async {
    // Set first: the disconnect event this triggers must neither put the
    // device back on screen nor schedule a reconnect.
    _userDisconnected = true;
    _reconnectTimer?.cancel();
    _applyDefaultSchedules = false;

    // Forget the device before dropping the link, so nothing that reacts to
    // the drop can read it back.
    for (final key in _savedKeys) {
      localStorage.removeItem(key);
    }
    if (Get.isRegistered<MainController>()) {
      // Allomom: the MAC is kept on the session with a setter.
      Get.find<MainController>().setAllowearMacAddress(null);
    }

    for (final measurement in [hr, spo2, hrv, temperature]) {
      if (measurement.isMonitoring.value) await measurement.stop();
    }
    if (isScanning.value) await stopScan();

    try {
      if (deviceType.value != null) await _sdk.disconnect();
    } catch (e) {
      debugPrint('[Allowear] disconnect failed: $e');
    }

    connectedDevice.value = null;
    savedDevice.value = null;
    deviceMac.value = null;
    deviceType.value = null;
    devices.clear();
    isConnecting.value = false;
    connectingDeviceId.value = '';
    firmwareInfo.value = null;
    videoHidMode.value = 0;
    deviceCapabilities.clear();
    batteryLevel.value = null;
    batteryLastUpdated.value = null;
    autoConfigs.clear();
    savingSchedules.clear();
    lastSyncTime.value = null;
    syncStatus.value = 'Ready to sync';
    syncProgress.value = 0;
    _lastUserInfoSent = null;
    _lastSavedBatteryLevel = null;
    _lastSavedBatteryTime = null;
    _chargeReminderCheckPending = false;
    AllowearReminderScheduler.cancelChargeReminders();
    update();
  }

  void _saveConnectedDeviceMac(String? macAddress) {
    if (macAddress == null || macAddress.isEmpty || macAddress == 'Unknown') {
      return;
    }
    // The ID to reconnect with. The server is told the hardware MAC once
    // fetchDeviceMac has read it.
    localStorage.setItem(connectedDeviceMacKey, macAddress);
  }

  static String _describe(Object e) =>
      e is AllowearException ? e.message : e.toString();

  // ═══════════════════════ Device actions & capabilities ═════════════════════

  /// Bracelet-only events: its capability menu, firmware version, video HID
  /// mode and battery pushes. The channels exist whatever model is selected,
  /// they just stay quiet unless a bracelet is connected.
  void _listenBraceletEvents() {
    _braceletCapabilitySub = v1.DeviceService.connectionStream.listen((msg) {
      if (msg.state != v1.DeviceConnectionState.capability) return;
      final caps = <String, bool>{};
      msg.rawData.forEach((key, value) {
        if (key == 'status' || key == 'deviceName' || key == 'deviceMac') {
          return;
        }
        if (value is bool) {
          caps[key] = value;
        } else if (value is int) {
          caps[key] = value == 1;
        }
      });
      deviceCapabilities.value = caps;
      update();
    });

    _firmwareVersionSub = v1.DeviceService.firmwareVersionStream
        .listen((info) => firmwareInfo.value = info);
    _videoControlSub = v1.DeviceService.videoControlStream
        .listen((mode) => videoHidMode.value = mode);
    _batterySub = v1.BatteryService.batteryStream
        .listen((info) => _onBattery(info.level, info.lastUpdated));
  }

  /// The ring and the watch report no support menu of their own, so the
  /// capability page shows what the SDK knows about the model instead.
  void _refreshCapabilityMap() {
    if (isBracelet || deviceType.value == null) return;
    final caps = _sdk.capabilities;
    deviceCapabilities.value = {
      for (final feature in AllowearFeature.values)
        feature.name: caps.supports(feature),
    };
  }

  Future<void> refreshCapabilities() async {
    try {
      if (isBracelet) {
        await v1.DeviceService.getCapabilities();
      } else {
        _refreshCapabilityMap();
      }
    } catch (e) {
      debugPrint('[Allowear] capability query failed: $e');
    }
  }

  /// Whether the selected model can schedule automatic measurement of [type].
  bool supportsAutoConfig(VitalType type) {
    if (deviceType.value == null) return false;
    return _sdk.capabilities.supportsAutoConfig(type);
  }

  /// Whether the selected model can measure [type] on demand.
  bool supportsLive(VitalType type) {
    if (deviceType.value == null) return false;
    return _sdk.capabilities.supportsLive(type);
  }

  Future<void> shutdownDevice() async {
    if (isBracelet) await v1.DeviceService.shutdownDevice();
  }

  Future<void> factoryResetDevice() async {
    if (isBracelet) await v1.DeviceService.factoryResetDevice();
  }

  Future<void> startFirmwareUpgrade(String path) async {
    if (!isBracelet) {
      throw const AllowearException(
          'Firmware update is only available on the Allowear Bracelet.');
    }
    await v1.DeviceService.startFirmwareUpgrade(path);
  }

  Future<void> setVideoControlMode(int mode) async {
    if (isBracelet) await v1.DeviceService.setVideoControlMode(mode);
  }

  Stream<Map<String, dynamic>> get firmwareUpdateProgress =>
      v1.DeviceService.firmwareUpdateProgress;

  int _deviceModelTapCount = 0;
  DateTime? _lastTapTime;

  /// Five quick taps on the device model opens the hidden capability page.
  void handleDeviceModelTap() {
    final now = DateTime.now();
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
      _deviceModelTapCount = 1;
    } else {
      _deviceModelTapCount++;
    }
    _lastTapTime = now;

    if (_deviceModelTapCount >= 5) {
      _deviceModelTapCount = 0;
      Get.to(() => const DeviceCapabilityPage());
    }
  }

  /// Last payload written to the device, so identical writes are skipped.
  /// Cleared on disconnect: a reconnected device may have been reset.
  String? _lastUserInfoSent;

  /// Pushes the user's profile (gender, height, weight, age) onto the device.
  Future<void> syncUserInfoToDevice() async {
    try {
      int? gender;
      double? height;
      double? weight;
      int? age;

      if (Get.isRegistered<MainController>()) {
        final mc = Get.find<MainController>();
        final g = mc.gender.toLowerCase();
        if (g == 'female') {
          gender = 0;
        } else if (g.isNotEmpty) {
          gender = 1;
        }
        // Allomom: height and weight live on the vitals stream (read below),
        // and dob is already a DateTime.
        {
          final dob = mc.dob;
          if (dob != null) {
            final now = DateTime.now();
            var years = now.year - dob.year;
            if (now.month < dob.month ||
                (now.month == dob.month && now.day < dob.day)) {
              years--;
            }
            if (years > 0) age = years;
          }
        }
      }

      // The vitals controller holds fresher height/weight when it is around.
      if (Get.isRegistered<HealthVitalsController>()) {
        final hvc = Get.find<HealthVitalsController>();
        // Allomom: the controller exposes the latest readings directly.
        height = hvc.heightVital?.value ?? height;
        weight = hvc.hasWeight ? hvc.weightValue : weight;
      }

      // The device keeps this until it changes, so re-sending an identical
      // payload is pure BLE traffic. Callers are legitimately spread out
      // (on connect, after a sync, on profile edits), so dedupe here rather
      // than trying to keep every caller honest.
      final payload = '${deviceType.value?.id}|$gender|$height|$weight|$age';
      if (payload == _lastUserInfoSent) return;

      if (isBracelet) {
        // The bracelet takes a partial profile and keeps the rest.
        _lastUserInfoSent = payload;
        v1.DeviceService.setUserInfo(
            gender: gender, height: height, weight: weight, age: age);
        return;
      }

      // The ring and the watch overwrite the whole profile at once, so a
      // partial one would replace real values with guesses.
      if (deviceType.value == null ||
          gender == null ||
          height == null ||
          weight == null ||
          age == null ||
          height <= 0 ||
          weight <= 0) {
        return;
      }
      _lastUserInfoSent = payload;
      await _sdk.setPersonalInfo(PersonalInfo(
        age: age,
        heightCm: height.round(),
        weightKg: weight.round(),
        gender: gender,
        strideCm: (height * 0.415).round(),
      ));
    } catch (e) {
      _lastUserInfoSent = null;
      debugPrint('[Allowear] user info sync failed: $e');
    }
  }

  // ═════════════════════════════════ Battery ═════════════════════════════════

  void _onBattery(int level, DateTime at) {
    batteryLevel.value = level;
    batteryLastUpdated.value = at;
    _saveBatteryVital(level, at);
    if (_chargeReminderCheckPending &&
        connectedDevice.value != null &&
        level > 0) {
      _chargeReminderCheckPending = false;
      AllowearReminderScheduler.onBatteryLevel(level);
    }
  }

  /// Asks the device for its charge. The bracelet answers on its battery
  /// stream; the ring and the watch answer the device-info read, which also
  /// carries the firmware version.
  Future<void> refreshBattery() async {
    try {
      if (isBracelet) {
        await v1.BatteryService.getBatteryLevel();
        return;
      }
      if (deviceType.value == null || !_sdk.isConnected) return;

      final info = await _sdk.getDeviceInfo();
      firmwareInfo.value = {
        'deviceModel': info.deviceName,
        if (info.firmwareVersion != null)
          'firmwareVersion': info.firmwareVersion,
      };
      final level = info.batteryLevel;
      if (level != null) _onBattery(level, DateTime.now());
    } catch (_) {
      // Best effort.
    }
  }

  /// Records the battery level as an unsynced vital so it reaches the server.
  Future<void> _saveBatteryVital(int level, DateTime at) async {
    try {
      if (level <= 0) return;

      // Skip redundant rows when the level hasn't moved within 2 minutes.
      if (_lastSavedBatteryLevel == level &&
          _lastSavedBatteryTime != null &&
          DateTime.now().difference(_lastSavedBatteryTime!).inMinutes < 2) {
        return;
      }
      _lastSavedBatteryLevel = level;
      _lastSavedBatteryTime = DateTime.now();

      final mac = deviceMac.value ?? getAllowearDeviceMac() ?? '';

      await VitalsSqLiteService().saveVitalSyncItem(
        VitalSyncItem(
          key: 'battery',
          value: level.toDouble(),
          unit: '%',
          createdAt: at,
          data: {
            'source': 'allowear',
            if (deviceType.value != null) 'device_type': deviceType.value!.id,
            'mac': mac,
          },
        ),
        synced: 0,
      );
    } catch (e) {
      debugPrint('[Allowear] saving battery vital failed: $e');
    }
  }

  // ═══════════════════════════ On-demand vitals ══════════════════════════════

  void _listenVitals() {
    _liveSub = _sdk.liveVitalStream.listen((reading) {
      final measurement = switch (reading.type) {
        VitalType.heartRate => hr,
        VitalType.spo2 => spo2,
        VitalType.hrv => hrv,
        VitalType.temperature => temperature,
        _ => null,
      };
      measurement?.accept(
        value: reading.value,
        at: reading.timestamp,
        isComplete: reading.isFinal,
      );
    });
  }

  /// Stores a reading taken live on the device as an unsynced vital, so it
  /// shows up right away and the background sync uploads it.
  Future<void> _saveLiveVital({
    required String key,
    required double value,
    required String unit,
    required DateTime at,
  }) async {
    try {
      await VitalsSqLiteService().saveVitalSyncItem(
        VitalSyncItem(
          key: key,
          value: double.parse(value.toStringAsFixed(1)),
          unit: unit,
          createdAt: at,
          data: {
            'source': 'allowear',
            if (deviceType.value != null) 'device_type': deviceType.value!.id,
            'measurement': 'live',
          },
        ),
        synced: 0,
      );
      if (Get.isRegistered<HealthVitalsController>()) {
        await Get.find<HealthVitalsController>().fetchLatestVitals();
      }
    } catch (e) {
      debugPrint('[Allowear] saving live $key failed: $e');
    }
  }

  // ═════════════════════════════ Health sync ═════════════════════════════════

  void _listenSyncProgress() {
    _syncSub = _sdk.syncProgressStream.listen((progress) {
      if (!isSyncing.value || progress.isTerminal) return;
      syncProgress.value = progress.percent;
      syncStatus.value = 'Syncing... ${progress.percent}%';
    });
  }

  void _finishSync() {
    // Guarded so a late second call can't repeat the post-sync work (battery
    // read, user-info write).
    if (!isSyncing.value) return;

    syncProgress.value = 100;
    syncStatus.value = 'Sync completed successfully';
    isSyncing.value = false;
    final now = DateTime.now();
    lastSyncTime.value = now;
    localStorage.setItem('allowear_synced_at', now.toIso8601String());
    // One after the other: the ring answers one command at a time.
    refreshBattery().then((_) => syncUserInfoToDevice());
  }

  Future<void> _triggerHealthSync() async {
    await Future.delayed(const Duration(seconds: 2));
    if (isSyncing.value) return;
    await startSync();
  }

  /// Pulls everything the device holds, then validates, stores and uploads it.
  Future<void> startSync() async {
    if (isSyncing.value) return;
    if (deviceType.value == null) {
      syncStatus.value = 'Select your Allowear device first';
      return;
    }

    isSyncing.value = true;
    syncProgress.value = 0;
    syncStatus.value = 'Starting sync...';

    final HealthSyncResult result;
    try {
      result = await _sdk.syncAllHealthData();
    } catch (e) {
      syncStatus.value = 'Error starting sync: ${_describe(e)}';
      isSyncing.value = false;
      return;
    }

    // A stage that failed still leaves good records from the others, and a
    // bracelet that timed out mid-dump returns what it sent before, so
    // whatever arrived is saved rather than thrown away.
    if (!result.isEmpty) {
      final mac = deviceMac.value ?? getAllowearDeviceMac() ?? '';
      try {
        await syncHealthDataToServer(mac, result);
      } catch (e) {
        debugPrint('[Allowear] saving synced data failed: $e');
      }
    }

    if (result.errors.isNotEmpty && result.isEmpty) {
      syncStatus.value = 'Sync failed: ${result.errors.first}';
      isSyncing.value = false;
      return;
    }
    if (result.errors.isNotEmpty) {
      debugPrint('[Allowear] sync finished with errors: ${result.errors}');
    }
    _finishSync();
  }

  // ═══════════════════════ Timed monitoring configuration ════════════════════

  /// What the selected model can do, or null before a model is picked.
  DeviceCapabilities? get capabilities =>
      deviceType.value == null ? null : _sdk.capabilities;

  /// Reads every automatic schedule the device has.
  Future<void> fetchAllConfigs() async {
    if (deviceType.value == null || connectedDevice.value == null) return;
    if (isLoadingSchedules.value) return;
    isLoadingSchedules.value = true;
    try {
      // The ring answers one command at a time, so a read sent mid-sync
      // times out. Let the sync finish first.
      if (isSyncing.value) {
        await isSyncing.stream
            .firstWhere((syncing) => !syncing)
            .timeout(const Duration(minutes: 2));
      }
      if (connectedDevice.value == null) return;
      // Merge rather than replace: a vital whose read timed out is missing
      // from the result and must keep the value last read, not flip to off.
      autoConfigs.addAll(await _sdk.getAllAutoVitalConfigs());
    } catch (e) {
      debugPrint('[Allowear] reading monitoring config failed: $e');
    } finally {
      isLoadingSchedules.value = false;
    }
  }

  /// Turns automatic measurement of [type] on or off, every
  /// [intervalMinutes], all day, every day. Replaces any advanced schedule.
  Future<void> setBasicSchedule(
    VitalType type, {
    required bool enabled,
    int? intervalMinutes,
  }) =>
      _writeSchedule(
        type,
        optimistic: enabled
            ? AutoVitalConfig.allDay(
                intervalMinutes: intervalMinutes ??
                    autoConfigs[type]?.intervalMinutes ??
                    60)
            : const AutoVitalConfig.off(),
        write: () => _sdk.setBasicAutoVitalConfig(
          type,
          enabled: enabled,
          intervalMinutes:
              intervalMinutes ?? autoConfigs[type]?.intervalMinutes ?? 60,
        ),
      );

  /// Writes a full schedule for [type]: mode, interval, time window, days.
  Future<void> setAdvancedSchedule(VitalType type, AutoVitalConfig config) =>
      _writeSchedule(
        type,
        optimistic: config,
        write: () => _sdk.setAdvancedAutoVitalConfig(type, config),
      );

  /// Turns on round-the-clock measurement of every schedulable vital.
  Future<void> applyScheduleToAll(int intervalMinutes) async {
    final caps = capabilities;
    if (caps == null || connectedDevice.value == null) return;
    final types = caps.configurableVitals;
    savingSchedules.addAll(types);
    try {
      final applied = await _sdk.applyDefaultAutoVitalConfig(
          intervalMinutes: intervalMinutes);
      final missed = types.difference(applied);
      if (missed.isNotEmpty) {
        Get.snackbar('Schedule',
            'Could not update ${missed.map((t) => t.label).join(', ')}',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update schedules: ${_describe(e)}',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      savingSchedules.removeAll(types);
    }
    // Read back what the device actually kept, fixed intervals included.
    await fetchAllConfigs();
  }

  /// Shows [optimistic] straight away, writes it, then keeps what the SDK says
  /// it wrote — or puts the old schedule back if the write failed.
  Future<void> _writeSchedule(
    VitalType type, {
    required AutoVitalConfig optimistic,
    required Future<AutoVitalConfig> Function() write,
  }) async {
    if (connectedDevice.value == null) {
      Get.snackbar('Allowear', 'Connect your device to change its schedule',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final previous = autoConfigs[type];
    autoConfigs[type] = optimistic;
    savingSchedules.add(type);
    try {
      autoConfigs[type] = await write();
    } catch (e) {
      if (previous == null) {
        autoConfigs.remove(type);
      } else {
        autoConfigs[type] = previous;
      }
      Get.snackbar('Error',
          'Failed to update ${type.label} schedule: ${_describe(e)}',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      savingSchedules.remove(type);
    }
  }

  // ══════════════════════════════════ Camera ═════════════════════════════════
  //
  // Driven by the bracelet's shutter button. The camera page owns the window in
  // which this is live: it calls enterCameraMode() and exitCameraMode().

  /// Opens the camera and tells the bracelet we are in camera mode.
  Future<void> enterCameraMode() async {
    if (isBracelet) {
      _cameraSub ??= v1.DeviceService.cameraControlStream.listen((data) {
        if (data == 2) takePicture(); // shutter pressed on the bracelet
      });
      await _setDeviceCameraMode(1);
    }

    try {
      cameras.value = await availableCameras();
      if (cameras.isNotEmpty) {
        await _setupCamera(cameras[currentCameraIndex.value]);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to initialize camera: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withOpacity(0.8),
          colorText: Colors.white);
    }
  }

  /// Tears the camera down and tells the bracelet we left camera mode.
  Future<void> exitCameraMode() async {
    await _cameraSub?.cancel();
    _cameraSub = null;

    await cameraController?.dispose();
    cameraController = null;
    isCameraInitialized.value = false;

    if (isBracelet) await _setDeviceCameraMode(0);
  }

  Future<void> _setupCamera(CameraDescription description) async {
    isCameraInitialized.value = false;
    cameraController = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await cameraController!.initialize();
      isCameraInitialized.value = true;
    } catch (e) {
      debugPrint('[Allowear] camera init failed: $e');
    }
  }

  Future<void> _setDeviceCameraMode(int enter) async {
    try {
      await v1.DeviceService.controlTakePhoto(enter);
    } catch (e) {
      debugPrint('[Allowear] toggling device camera mode failed: $e');
    }
  }

  Future<void> switchCamera() async {
    if (cameras.length < 2) return;
    currentCameraIndex.value = (currentCameraIndex.value + 1) % cameras.length;
    await cameraController?.dispose();
    await _setupCamera(cameras[currentCameraIndex.value]);
  }

  Future<void> takePicture() async {
    if (!isCameraInitialized.value || cameraController == null) return;
    if (cameraController!.value.isTakingPicture) return;

    try {
      final photo = await cameraController!.takePicture();
      await Gal.putImage(photo.path);
      capturedImages.insert(0, photo.path);

      Get.snackbar('Success', 'Photo saved to gallery!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 1));
    } catch (e) {
      Get.snackbar('Error', 'Failed to take photo: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withOpacity(0.8),
          colorText: Colors.white);
    }
  }
}
