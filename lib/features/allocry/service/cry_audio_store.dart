import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Where AlloCry keeps the recordings it has written into the vitals stream.
///
/// A reading is only as good as the clip behind it — the mother should be able
/// to play back what the model heard weeks later — so the WAV is moved out of
/// the recorder's scratch file into a folder of its own and kept.
///
/// Only the *file name* is written into the vital. iOS rewrites the app
/// container path on every update, so an absolute path recorded today is dead
/// by the next release; [resolve] rebuilds it against wherever the documents
/// directory lives now.
class CryAudioStore {
  const CryAudioStore._();

  static const String _folder = 'allocry';

  static Future<Directory> _directory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _folder));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Moves the recording at [sourcePath] into permanent storage under an
  /// [id]-derived name and returns that name, or null when the clip could not
  /// be kept. A failure here must not lose the reading, so callers store the
  /// cry with no audio rather than aborting.
  static Future<String?> persist(String sourcePath, String id) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) return null;

      final dir = await _directory();
      final fileName = 'cry_$id${p.extension(sourcePath).isEmpty ? '.wav' : p.extension(sourcePath)}';
      final target = File(p.join(dir.path, fileName));

      await source.copy(target.path);
      return fileName;
    } catch (e) {
      debugPrint('⚠️ [CryAudioStore] could not keep $sourcePath: $e');
      return null;
    }
  }

  /// Absolute path for a stored [fileName], or null when the clip is gone.
  static Future<String?> resolve(String? fileName) async {
    if (fileName == null || fileName.trim().isEmpty) return null;
    try {
      final dir = await _directory();
      final file = File(p.join(dir.path, p.basename(fileName)));
      return await file.exists() ? file.path : null;
    } catch (e) {
      debugPrint('⚠️ [CryAudioStore] could not resolve $fileName: $e');
      return null;
    }
  }

  /// Deletes one stored clip — used when its cry record is deleted.
  static Future<void> delete(String? fileName) async {
    if (fileName == null || fileName.trim().isEmpty) return;
    try {
      final dir = await _directory();
      final file = File(p.join(dir.path, p.basename(fileName)));
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('⚠️ [CryAudioStore] could not delete $fileName: $e');
    }
  }
}
