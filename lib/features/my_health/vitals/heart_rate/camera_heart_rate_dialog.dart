import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:scppg/scppg.dart';

class CameraHeartRateDialog extends StatefulWidget {
  const CameraHeartRateDialog({Key? key}) : super(key: key);

  @override
  _CameraHeartRateDialogState createState() => _CameraHeartRateDialogState();
}

class _CameraHeartRateDialogState extends State<CameraHeartRateDialog> {
  late ScppgController _scppgController;
  bool _isInit = false;
  bool _isMeasuring = false;

  // Measurement State
  final List<double> _ppgValues = [];
  final List<DateTime> _timestamps = [];
  int _averageBpm = 0;
  final List<int> _bpmHistory = [];

  // Timer State
  int _secondsRemaining = 15; // Recommended duration for stable reading
  Timer? _countdownTimer;

  // Config
  static const int _windowSize = 100; // Keep last 100 samples

  late VoidCallback _listener;
  Timer? _analysisTimer;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    _scppgController = ScppgController(fps: 30);
    await _scppgController.init();

    _listener = () {
      if (!mounted || !_isMeasuring) return;

      final data = _scppgController.ppgData;
      if (data != null && data.y != null) {
        _ppgValues.add(data.y!);
        _timestamps.add(data.timestamp ?? DateTime.now());

        if (_ppgValues.length > _windowSize * 2) {
          _ppgValues.removeAt(0);
          _timestamps.removeAt(0);
        }
      }
    };

    _scppgController.addListener(_listener);

    setState(() {
      _isInit = true;
    });
  }

  Future<void> _startMeasurement() async {
    setState(() {
      _isMeasuring = true;
      _ppgValues.clear();
      _timestamps.clear();
      _bpmHistory.clear();
      _averageBpm = 0;
      _secondsRemaining = 15;
    });

    await _scppgController.startSensing();

    // Ensure the camera is fully ready before turning on flash/locking exposure.
    // Sometimes starting the stream takes a few frames.
    await Future.delayed(const Duration(milliseconds: 500));
    _scppgController.isFlashOn = true;
    _scppgController.isFocusAndExposureLocked = true;

    // Start a periodic analysis timer
    _analysisTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _analyzeData();
    });

    // Start a countdown timer to stop measurement automatically
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _stopMeasurement();
      }
    });
  }

  Future<void> _stopMeasurement() async {
    _analysisTimer?.cancel();
    _countdownTimer?.cancel();
    _scppgController.stopSensing();
    _scppgController.isFlashOn = false;
    _scppgController.isFocusAndExposureLocked = false;

    if (mounted) {
      setState(() {
        _isMeasuring = false;
      });
    }
  }

  void _analyzeData() {
    if (_ppgValues.length < 30) return; // Need enough data

    // Simple Peak Detection
    // Apply a simple moving average to smooth the signal
    final smoothed = _applyMovingAverage(_ppgValues, 5);

    List<int> peakIndices = [];

    // Find peaks
    for (int i = 1; i < smoothed.length - 1; i++) {
      if (smoothed[i] > smoothed[i - 1] && smoothed[i] > smoothed[i + 1]) {
        // It's a local maximum
        // Simple thresholding relative to the recent window max
        final windowMax = smoothed
            .sublist(max(0, i - 15), min(smoothed.length, i + 15))
            .reduce(max);

        if (smoothed[i] >= windowMax * 0.95) {
          // Needs to be prominent enough
          peakIndices.add(i);
        }
      }
    }

    if (peakIndices.length >= 2) {
      // Filter out peaks that are too close (e.g. less than 300ms apart - corresponding to 200 BPM max)
      List<int> validPeaks = [peakIndices[0]];
      for (int i = 1; i < peakIndices.length; i++) {
        final timeDiffMs = _timestamps[peakIndices[i]]
            .difference(_timestamps[validPeaks.last])
            .inMilliseconds;
        if (timeDiffMs > 300) {
          validPeaks.add(peakIndices[i]);
        }
      }

      if (validPeaks.length >= 2) {
        // Calculate average time between valid peaks
        double totalDurationMs = 0;
        for (int i = 1; i < validPeaks.length; i++) {
          totalDurationMs += _timestamps[validPeaks[i]]
              .difference(_timestamps[validPeaks[i - 1]])
              .inMilliseconds;
        }

        double avgPeakIntervalMs = totalDurationMs / (validPeaks.length - 1);
        if (avgPeakIntervalMs > 0) {
          int bpm = (60000 / avgPeakIntervalMs).round();

          // Sanity check BPM limits (usually 40 - 200)
          if (bpm >= 40 && bpm <= 200) {
            setState(() {
              _bpmHistory.add(bpm);
              if (_bpmHistory.length > 10) _bpmHistory.removeAt(0);

              // Calculate rolling average
              _averageBpm =
                  (_bpmHistory.reduce((a, b) => a + b) / _bpmHistory.length)
                      .round();
            });
          }
        }
      }
    }
  }

  List<double> _applyMovingAverage(List<double> data, int window) {
    List<double> result = [];
    for (int i = 0; i < data.length; i++) {
      int start = max(0, i - window ~/ 2);
      int end = min(data.length - 1, i + window ~/ 2);
      double sum = 0;
      for (int j = start; j <= end; j++) {
        sum += data[j];
      }
      result.add(sum / (end - start + 1));
    }
    return result;
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _countdownTimer?.cancel();
    _scppgController.removeListener(_listener);
    _scppgController.stopSensing();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Camera Heart Rate',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (!_isInit)
              const CircularProgressIndicator()
            else ...[
              const Text(
                'Place your fingertip completely covering both the camera lens and flash on the back of your phone.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // BPM Display
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                child: Column(children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    _averageBpm > 0 ? '$_averageBpm' : '--',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const Text('BPM'),
                ]),
              ),

              const SizedBox(height: 24),

              if (_isMeasuring) ...[
                LinearProgressIndicator(value: (15 - _secondsRemaining) / 15),
                const SizedBox(height: 8),
                Text('Measuring... $_secondsRemaining seconds remaining',
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    _stopMeasurement();
                    setState(() {
                      _averageBpm = 0;
                    });
                  },
                  child: const Text('Cancel Measurement'),
                )
              ] else if (_averageBpm > 0) ...[
                const Text('Measurement Complete!',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(_averageBpm);
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Reading'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _startMeasurement,
                  child: const Text('Retake Measurement'),
                )
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _startMeasurement,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Measurement'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                )
              ]
            ]
          ],
        ),
      ),
    );
  }
}
