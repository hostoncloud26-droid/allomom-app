import 'package:allomom/features/allocry/data/cry_data.dart';
import 'package:allomom/models/vitals_stream_model.dart';

/// One AlloCry reading, read back out of the vitals stream.
///
/// AlloCry does not own a table. Every reading is a row in the same `cry`
/// vitals stream the rest of AlloMom's health data lives in — `key` is
/// `cry`, `value` is the cry type as a code, and `data` carries the type's
/// name, the confidence, and the file name of the recording it was heard in.
/// This class is the reading side of that contract, so the UI never has to
/// know how the map is shaped.
class CryRecord {
  /// The vitals stream key every AlloCry reading is written under.
  static const String vitalKey = 'cry';

  /// The unit written alongside it, so a `cry` row is self-describing in the
  /// stream next to `kg` weights and `bpm` heart rates.
  static const String vitalUnit = 'cry';

  /// Numeric code per cry type, the `value` of the vital. These match the
  /// on-device classifier's own class numbering for the five it predicts;
  /// Attention Cry is 6 because only the app can record one.
  static const Map<String, int> typeCodes = {
    'Pain Cry': 1,
    'Burping Cry': 2,
    'Discomfort Cry': 3,
    'Hunger Cry': 4,
    'Sleepy Cry': 5,
    'Attention Cry': 6,
  };

  static int codeFor(String? cryType) => typeCodes[cryType] ?? 0;

  static String? typeForCode(double value) {
    final code = value.round();
    for (final entry in typeCodes.entries) {
      if (entry.value == code) return entry.key;
    }
    return null;
  }

  /// The vital row's id — what a delete targets.
  final String id;

  /// When the cry was heard.
  final DateTime recordedAt;

  /// The cry type the model named, e.g. "Hunger Cry".
  final String cryType;

  /// 0-1, how strongly the classifier preferred [cryType].
  final double confidence;

  /// Whether YAMNet actually heard a cry. False readings are kept so a mother
  /// can see that AlloCry listened and found nothing.
  final bool cryDetected;

  /// File name of the kept recording, resolved through `CryAudioStore`.
  final String? audioFile;

  /// The sound classes YAMNet heard, most frequent first.
  final List<String> soundLabels;

  /// How long she recorded for.
  final int durationSeconds;

  const CryRecord({
    required this.id,
    required this.recordedAt,
    required this.cryType,
    required this.confidence,
    required this.cryDetected,
    required this.audioFile,
    required this.soundLabels,
    required this.durationSeconds,
  });

  /// Everything AlloCry knows about this kind of cry.
  CryType get type => CryTypes.resolve(cryType);

  /// Confidence as the "92%" the result sheet shows.
  String get confidenceLabel => '${(confidence * 100).round()}%';

  /// A coarse band for the history badge.
  String get confidenceBand {
    if (confidence >= 0.75) return 'High';
    if (confidence >= 0.5) return 'Medium';
    return 'Low';
  }

  /// Builds the `data` map written into the vital.
  static Map<String, dynamic> toVitalData({
    required String cryType,
    required double confidence,
    required bool cryDetected,
    required String? audioFile,
    required List<String> soundLabels,
    required int durationSeconds,
  }) {
    return {
      'cryType': cryType,
      'heading': CryTypes.resolve(cryType).heading,
      'confidence': confidence,
      'cryDetected': cryDetected,
      if (audioFile != null) 'audioFile': audioFile,
      'soundLabels': soundLabels,
      'durationSeconds': durationSeconds,
      // Marks the reading as the on-device model's rather than a manual entry,
      // so a later server-side sync can tell them apart.
      'source': 'allocry_on_device',
    };
  }

  /// Reads a `cry` row back. Falls back to the numeric value when `data` is
  /// missing, so a row written by anything but this app still renders.
  factory CryRecord.fromVital(VitalsStreamResponse vital) {
    final data = vital.data ?? const <String, dynamic>{};

    final labels = data['soundLabels'];
    return CryRecord(
      id: vital.id,
      recordedAt: vital.createdAt,
      cryType: data['cryType']?.toString() ??
          typeForCode(vital.value) ??
          'Unknown Cry',
      confidence: (data['confidence'] is num)
          ? (data['confidence'] as num).toDouble()
          : 0.0,
      cryDetected: data['cryDetected'] == true || data['cryDetected'] == null,
      audioFile: data['audioFile']?.toString(),
      soundLabels: labels is List
          ? labels.map((e) => e.toString()).toList()
          : const <String>[],
      durationSeconds: (data['durationSeconds'] is num)
          ? (data['durationSeconds'] as num).toInt()
          : 0,
    );
  }
}
