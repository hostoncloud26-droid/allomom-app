import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'package:allomom/features/allocry/service/yamnet_labels.dart';

/// What one pass of the on-device models made of a recording.
class CryAnalysis {
  /// The sound classes YAMNet heard, most frequent first.
  final List<String> soundLabels;

  /// True when one of the labels is a cry class — the gate that decides
  /// whether the second model's answer is worth showing at all.
  final bool cryDetected;

  /// One of the six [CryTypes] keys, e.g. "Hunger Cry". Always produced (the
  /// classifier has no "none" class), so only trust it when [cryDetected].
  final String? cryType;

  /// How strongly the classifier preferred [cryType] over the other four, as
  /// 0-1. Derived from the same scores the choice was made on, so it never
  /// disagrees with it — it only says how close the runner-up was.
  final double confidence;

  /// The recording this came from.
  final String audioPath;

  const CryAnalysis({
    required this.soundLabels,
    required this.cryDetected,
    required this.cryType,
    required this.confidence,
    required this.audioPath,
  });
}

/// The cry classifier's answer: which type, and how sure.
class _CryVerdict {
  final String? cryType;
  final double confidence;

  const _CryVerdict(this.cryType, this.confidence);
}

/// AlloCry's offline ear.
///
/// Two TFLite graphs run back to back, entirely on the phone — nothing about
/// the audio leaves the device:
///
///  1. `yamnet93600.tflite` turns 93,600 samples (~5.85s at 16kHz) into 12
///     frames. Output 0 is a [12, 521] score matrix over the AudioSet classes,
///     which tells us *whether* a baby is crying; output 1 is [12, 1024]
///     embeddings, a compact description of how the sound behaves.
///  2. `ml1.tflite` takes the mean of those 12 embeddings and scores it over
///     the five cry types AlloCry knows.
///
/// This is the same pipeline AlloBaby ships, kept numerically identical so a
/// clip predicted "Hunger Cry" there is predicted "Hunger Cry" here.
class CryAudioClassifier {
  /// Samples YAMNet's input tensor expects: ~5.85 seconds at 16kHz mono.
  static const int _waveformLength = 93600;

  /// YAMNet scores the clip in this many frames.
  static const int _frames = 12;

  /// AudioSet classes per frame.
  static const int _scoreClasses = 521;

  /// Width of a YAMNet embedding.
  static const int _embeddingSize = 1024;

  /// The cry classifier's output classes, in tensor order.
  static const List<String> _categories = ['1', '2', '3', '4', '5'];

  /// Maps a classifier class onto the cry type AlloCry writes down.
  static const Map<String, String> _categoryToCryType = {
    '1': 'Pain Cry',
    '2': 'Burping Cry',
    '3': 'Discomfort Cry',
    '4': 'Hunger Cry',
    '5': 'Sleepy Cry',
  };

  /// YAMNet labels that mean a baby is actually crying. Anything else — speech,
  /// silence, a television — leaves [CryAnalysis.cryDetected] false.
  static const List<String> cryLabels = [
    'Crying, sobbing',
    'Baby cry, infant cry',
    'Crying',
    'sobbing',
  ];

  Interpreter? _yamnet;
  Interpreter? _cryClassifier;

  bool get isReady => _yamnet != null && _cryClassifier != null;

  /// Loads both graphs from the bundled assets. Call once before [analyze].
  Future<void> initialize() async {
    if (isReady) return;
    _yamnet = await Interpreter.fromAsset('assets/ml/yamnet93600.tflite');
    _cryClassifier = await Interpreter.fromAsset('assets/ml/ml1.tflite');
  }

  /// Runs both models over the WAV at [audioPath].
  Future<CryAnalysis> analyze(String audioPath) async {
    final yamnet = _yamnet;
    final classifier = _cryClassifier;
    if (yamnet == null || classifier == null) {
      throw StateError('CryAudioClassifier.initialize() was not awaited');
    }

    final waveform = await _readWaveform(audioPath);

    final scores = Float32List(_frames * _scoreClasses)
        .reshape([_frames, _scoreClasses]);
    yamnet.runInference([waveform.toList()]);
    yamnet.getOutputTensor(0).copyTo(scores);

    final labels = <String>[];
    for (final frame in scores) {
      labels.add(kYamnetLabels[_argMax(frame)]);
    }
    final rankedLabels = _sortByFrequency(labels);
    final verdict = _classifyCryType(yamnet, classifier);

    return CryAnalysis(
      soundLabels: rankedLabels,
      cryDetected: rankedLabels.any(cryLabels.contains),
      cryType: verdict.cryType,
      confidence: verdict.confidence,
      audioPath: audioPath,
    );
  }

  /// Reads the recording as the 16-bit little-endian samples YAMNet wants,
  /// zero-padded when the clip is shorter than the input tensor.
  ///
  /// The 44-byte WAV header is read as samples rather than skipped. That is
  /// AlloBaby's behaviour: ~22 samples of noise at the head of a 93,600-sample
  /// window, which the model is already tuned around. Skipping it here would
  /// shift every frame and change predictions, so it stays.
  Future<Float32List> _readWaveform(String audioPath) async {
    final bytes = await File(audioPath).readAsBytes();
    final byteData = ByteData.view(bytes.buffer);
    final available = byteData.lengthInBytes ~/ 2;

    final waveform = Float32List(_waveformLength);
    for (int i = 0; i < _waveformLength && i < available; i++) {
      waveform[i] = byteData.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return waveform;
  }

  /// Reads YAMNet's embeddings from the pass [analyze] just ran and asks the
  /// cry classifier which of the five types they look like.
  _CryVerdict _classifyCryType(Interpreter yamnet, Interpreter classifier) {
    final embeddings = Float32List(_frames * _embeddingSize)
        .reshape([_frames, _embeddingSize]);
    yamnet.getOutputTensor(1).copyTo(embeddings);

    final pooled = _meanOverFrames(
      List<List<double>>.generate(
        _frames,
        (i) => List<double>.from(embeddings[i] as List),
      ),
    );

    final output = Float32List(_categories.length)
        .reshape([1, _categories.length]);
    classifier.run(pooled, output);

    final scores = List<dynamic>.from(output.first as List);
    final winner = _argMax(scores);
    final category = _categories[winner];

    return _CryVerdict(
      _categoryToCryType[category],
      _softmaxAt(scores, winner),
    );
  }

  /// Collapses the 12 frame embeddings into the single 1024-wide vector the
  /// cry classifier was trained on.
  List<double> _meanOverFrames(List<List<double>> frames) {
    final columns = frames.first.length;
    final mean = List<double>.filled(columns, 0.0);
    for (int col = 0; col < columns; col++) {
      double sum = 0.0;
      for (final frame in frames) {
        sum += frame[col];
      }
      mean[col] = sum / frames.length;
    }
    return mean;
  }

  /// Softmax probability of class [index], computed max-shifted so a large
  /// score cannot overflow the exponential.
  double _softmaxAt(List<dynamic> scores, int index) {
    final values = scores.map((e) => (e as num).toDouble()).toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    double sum = 0.0;
    for (final v in values) {
      sum += math.exp(v - max);
    }
    if (sum <= 0) return 0.0;
    return math.exp(values[index] - max) / sum;
  }

  int _argMax(List<dynamic> logits) {
    int best = 0;
    double max = double.negativeInfinity;
    for (int i = 0; i < logits.length; i++) {
      final value = (logits[i] as num).toDouble();
      if (value > max) {
        max = value;
        best = i;
      }
    }
    return best;
  }

  /// Distinct labels ordered by how many of the 12 frames voted for each, so
  /// the sound the clip is mostly made of comes first.
  List<String> _sortByFrequency(List<String> labels) {
    final counts = <String, int>{};
    for (final label in labels) {
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return labels.toSet().toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  }

  void dispose() {
    try {
      _yamnet?.close();
      _cryClassifier?.close();
    } catch (e) {
      debugPrint('⚠️ [CryAudioClassifier] close failed: $e');
    }
    _yamnet = null;
    _cryClassifier = null;
  }
}
