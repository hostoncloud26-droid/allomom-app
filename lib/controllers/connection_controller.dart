import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:allomom/controllers/health_vital_controller.dart';

class ConnectionController extends GetxController {
  static ConnectionController get instance =>
      Get.isRegistered<ConnectionController>()
          ? Get.find<ConnectionController>()
          : Get.put(ConnectionController._internal(), permanent: true);

  factory ConnectionController() => instance;
  ConnectionController._internal();

  final RxList<ConnectivityResult> _connectivityResults =
      <ConnectivityResult>[].obs;
  final RxBool _isInternetAvailable = false.obs;
  final RxBool _isChecking = false.obs;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _timer;
  bool _isInitialized = false;

  List<ConnectivityResult> get connectivityResults => _connectivityResults;
  RxList<ConnectivityResult> get connectivityResultsRx => _connectivityResults;

  bool get isInternetAvailable => _isInternetAvailable.value;
  RxBool get isInternetAvailableRx => _isInternetAvailable;

  bool get isChecking => _isChecking.value;
  RxBool get isCheckingRx => _isChecking;

  /// Helper to check if any network interface is active
  bool get isConnected =>
      _connectivityResults.any((r) => r != ConnectivityResult.none);

  @override
  void onInit() {
    super.onInit();
    if (!_isInitialized) {
      init();
    }
  }

  /// Compatibility alias for any Flutter Listeners
  void notifyListeners() => update();

  /// Initialize connection listeners and periodic verification
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _checkInitialConnection();

    // Listen for network interface changes
    _subscription?.cancel();
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      _connectivityResults.assignAll(results);
      _checkInternetPresence();
    });

    // Periodic check every 30 seconds
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkInternetPresence();
    });
  }

  /// Initial connection check on startup
  Future<void> _checkInitialConnection() async {
    try {
      final List<ConnectivityResult> results =
          await Connectivity().checkConnectivity();
      _connectivityResults.assignAll(results);
      await _checkInternetPresence();
    } catch (e) {
      debugPrint("Error checking initial connectivity: $e");
      // Still attempt ping directly
      await _checkInternetPresence();
    }
  }

  /// Pings reliable Google endpoints or uses DNS lookup to confirm actual internet access
  Future<bool> _pingGoogle() async {
    // 1. Primary ping to Google
    try {
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode >= 200 && response.statusCode < 400) {
        return true;
      }
      debugPrint(
        "Ping https://www.google.com returned status: ${response.statusCode}",
      );
    } catch (e) {
      debugPrint("Ping https://www.google.com failed: $e");
    }

    // 2. Android OS connectivity probe endpoint
    try {
      final response = await http
          .get(Uri.parse('https://connectivitycheck.gstatic.com/generate_204'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 204 ||
          (response.statusCode >= 200 && response.statusCode < 400)) {
        return true;
      }
      debugPrint("Ping generate_204 returned status: ${response.statusCode}");
    } catch (e) {
      debugPrint("Ping generate_204 failed: $e");
    }

    // 3. DNS socket lookup fallback
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
      debugPrint("DNS lookup for google.com returned empty");
    } catch (e) {
      debugPrint("DNS lookup for google.com failed: $e");
    }

    return false;
  }

  /// Verifies actual internet access by pinging Google (matching alloconnect)
  Future<void> _checkInternetPresence() async {
    if (_isChecking.value) return;
    _isChecking.value = true;

    try {
      // If network results are explicitly non-empty and strictly contains only none, device is offline
      if (_connectivityResults.isNotEmpty &&
          _connectivityResults.every((r) => r == ConnectivityResult.none)) {
        debugPrint("Internet is not available");
        _isInternetAvailable.value = false;
        update();
        return;
      }

      final hasInternet = await _pingGoogle();
      if (hasInternet) {
        debugPrint("Internet is available");
        _isInternetAvailable.value = true;
        update();
        await HealthVitalsController.instance.syncUnsyncedVitals();
      } else {
        debugPrint("Internet is not available");
        _isInternetAvailable.value = false;
        update();
      }
    } catch (_) {
      debugPrint("Internet is not available");
      _isInternetAvailable.value = false;
      update();
    } finally {
      _isChecking.value = false;
    }
  }

  /// Manually checks and returns true if internet is actively reachable
  Future<bool> checkInternet() async {
    try {
      final List<ConnectivityResult> results =
          await Connectivity().checkConnectivity();
      _connectivityResults.assignAll(results);
    } catch (e) {
      debugPrint("Error checking connectivity: $e");
    }

    if (_connectivityResults.isNotEmpty &&
        _connectivityResults.every((r) => r == ConnectivityResult.none)) {
      debugPrint("Internet is not available");
      _isInternetAvailable.value = false;
      update();
      return false;
    }

    final hasInternet = await _pingGoogle();
    if (hasInternet) {
      debugPrint("Internet is available");
      _isInternetAvailable.value = true;
      update();
      return true;
    } else {
      debugPrint("Internet is not available");
      _isInternetAvailable.value = false;
      update();
      return false;
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _timer?.cancel();
    super.onClose();
  }
}
