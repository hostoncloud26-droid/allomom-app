import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:allomom/features/allocry/data/cry_data.dart';
import 'package:allomom/features/allocry/service/cry_audio_classifier.dart';

/// Proves AlloCry's two TFLite graphs actually load and run on a real device,
/// with no network available to fall back on.
///
/// Runs as an integration test rather than a unit test because the interpreter
/// is native code: `flutter test` on the host has no TensorFlow Lite library to
/// bind to, so this is the only place the offline claim can be checked.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late CryAudioClassifier classifier;

  setUpAll(() async {
    classifier = CryAudioClassifier();
    await classifier.initialize();
  });

  tearDownAll(() => classifier.dispose());

  /// Rebuilds a bundled cry sample at the 16kHz the models expect.
  ///
  /// AlloBaby's clips are 8kHz, while AlloCry records at 16kHz — feeding the
  /// raw asset in would halve the pitch and leave 40% of YAMNet's window
  /// empty, which it hears as silence. Doubling each sample restores the
  /// original pitch and duration at the recorder's rate, so this exercises
  /// the pipeline with the kind of audio it actually receives.
  Future<String> cryClipAt16k(String asset, String name) async {
    final raw = (await rootBundle.load(asset)).buffer.asUint8List();

    // Skip the 44-byte canonical WAV header and read the PCM behind it.
    final pcm = ByteData.view(raw.buffer, 44);
    final sampleCount = pcm.lengthInBytes ~/ 2;

    final upsampled = ByteData(sampleCount * 2 * 2);
    for (int i = 0; i < sampleCount; i++) {
      final sample = pcm.getInt16(i * 2, Endian.little);
      upsampled.setInt16(i * 4, sample, Endian.little);
      upsampled.setInt16(i * 4 + 2, sample, Endian.little);
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(
      _wav(upsampled.buffer.asUint8List(), sampleRate: 16000),
    );
    return file.path;
  }

  testWidgets('both models load from the bundled assets', (_) async {
    expect(classifier.isReady, isTrue);
  });

  testWidgets('a real baby cry is detected and given a type', (_) async {
    final path = await cryClipAt16k(
      'assets/cry_samples/hungry.wav',
      'it_cry.wav',
    );

    final analysis = await classifier.analyze(path);

    expect(analysis.soundLabels, isNotEmpty,
        reason: 'YAMNet scored the clip');
    expect(analysis.cryDetected, isTrue,
        reason: 'labels were ${analysis.soundLabels}');
    expect(analysis.cryType, isNotNull);
    expect(CryTypes.all.containsKey(analysis.cryType), isTrue,
        reason: '${analysis.cryType} must be a type AlloCry can explain');
    expect(analysis.confidence, inInclusiveRange(0.0, 1.0));
  });

  testWidgets('silence is not reported as a cry', (_) async {
    // Pure silence at the recorder's own rate: the gate must reject it, or
    // every quiet room would be logged as a cry.
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/it_silence.wav');
    await file.writeAsBytes(
      _wav(Uint8List(16000 * 6 * 2), sampleRate: 16000),
    );

    final analysis = await classifier.analyze(file.path);

    expect(analysis.cryDetected, isFalse,
        reason: 'labels were ${analysis.soundLabels}');
  });
}

/// A canonical 16-bit mono WAV around [pcm].
Uint8List _wav(Uint8List pcm, {required int sampleRate}) {
  final header = ByteData(44);
  void ascii(int offset, String tag) {
    for (int i = 0; i < tag.length; i++) {
      header.setUint8(offset + i, tag.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  header.setInt32(4, 36 + pcm.length, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  header.setInt32(16, 16, Endian.little);
  header.setInt16(20, 1, Endian.little); // PCM
  header.setInt16(22, 1, Endian.little); // mono
  header.setInt32(24, sampleRate, Endian.little);
  header.setInt32(28, sampleRate * 2, Endian.little); // byte rate
  header.setInt16(32, 2, Endian.little); // block align
  header.setInt16(34, 16, Endian.little); // bits per sample
  ascii(36, 'data');
  header.setInt32(40, pcm.length, Endian.little);

  return Uint8List.fromList([...header.buffer.asUint8List(), ...pcm]);
}
