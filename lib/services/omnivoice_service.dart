import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OmniVoiceService {
  static final OmniVoiceService instance = OmniVoiceService._internal();
  OmniVoiceService._internal();

  /// Server URLs to try (Emulator 10.0.2.2, port-forwarded 127.0.0.1, localhost)
  List<String> get candidateBaseUrls {
    if (Platform.isAndroid) {
      return const [
        'http://10.0.2.2:7860',
        'http://127.0.0.1:7860',
        'http://localhost:7860',
      ];
    }
    return const ['http://127.0.0.1:7860', 'http://localhost:7860'];
  }

  String? _workingBaseUrl;

  /// The server the settings screen points at, probed before the built-in
  /// candidates. Set to null to go back to probing only the defaults.
  String? _configuredBaseUrl;

  /// Points the service at [baseUrl]. A change drops the cached result of the
  /// last probe, so switching servers takes effect on the next clip rather
  /// than on the next launch.
  void setBaseUrl(String? baseUrl) {
    final clean = baseUrl?.trim();
    final normalised = (clean == null || clean.isEmpty)
        ? null
        : (clean.endsWith('/') ? clean.substring(0, clean.length - 1) : clean);
    if (normalised == _configuredBaseUrl) return;
    _configuredBaseUrl = normalised;
    _workingBaseUrl = null;
  }

  /// What is tried, in order: the configured server first.
  List<String> get _urlsToProbe {
    final configured = _configuredBaseUrl;
    if (configured == null) return candidateBaseUrls;
    return [configured, ...candidateBaseUrls.where((u) => u != configured)];
  }

  /// Whether the configured server answers right now.
  ///
  /// What the settings screen's test button asks: [generateBabySpeech] falls
  /// back to the phone's own voice without a word, so an unreachable server is
  /// otherwise indistinguishable from the setting not having been saved.
  Future<bool> ping({Duration timeout = const Duration(seconds: 6)}) async {
    final url = _configuredBaseUrl ?? candidateBaseUrls.first;
    try {
      final resp = await http
          .get(Uri.parse('$url/api/system-info'))
          .timeout(timeout);
      final ok = resp.statusCode == 200;
      debugPrint('OmniVoice ping $url → ${resp.statusCode}');
      if (ok) _workingBaseUrl = url;
      return ok;
    } catch (e) {
      debugPrint('OmniVoice ping $url failed: $e');
      return false;
    }
  }

  Future<String?> getWorkingBaseUrl() async {
    if (_workingBaseUrl != null) return _workingBaseUrl;

    for (final url in _urlsToProbe) {
      try {
        final uri = Uri.parse('$url/api/system-info');
        // Six seconds rather than two: a server on the same wifi as the phone,
        // rather than on the emulator's host, answers well outside two.
        final resp = await http.get(uri).timeout(const Duration(seconds: 6));
        if (resp.statusCode == 200) {
          debugPrint('OmniVoice active at: $url');
          _workingBaseUrl = url;
          return url;
        }
        debugPrint('OmniVoice $url answered ${resp.statusCode}');
      } catch (e) {
        debugPrint('OmniVoice $url unreachable: $e');
      }
    }
    return _urlsToProbe.first;
  }

  /// Sends text to OmniVoice API, parses the SSE stream for the completed output
  /// filename, and returns the network audio URL for direct streaming playback.
  Future<String?> generateBabySpeech({
    required String text,
    String langCode = 'en',
    String model = 'k2-fsa/OmniVoice',
    String refAudio = 'reference.mp3',
    String audioFormat = 'wav',
    Duration timeout = const Duration(seconds: 35),
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return null;

    try {
      final baseUrl = await getWorkingBaseUrl() ?? _urlsToProbe.first;
      final uri = Uri.parse('$baseUrl/api/generate');

      final request = http.MultipartRequest('POST', uri)
        ..fields['model'] = model
        ..fields['text'] = cleanText
        ..fields['lang_code'] = langCode
        ..fields['ref_audio'] = refAudio
        ..fields['audio_format'] = audioFormat;

      final streamedResponse = await request.send().timeout(timeout);
      if (streamedResponse.statusCode != 200) {
        debugPrint('OmniVoice HTTP ${streamedResponse.statusCode}');
        return null;
      }

      String? outputFilename;

      final lines = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lines) {
        final cleanLine = line.trim();
        if (cleanLine.startsWith('data:')) {
          final payload = cleanLine.substring(5).trim();
          try {
            final data = jsonDecode(payload);
            if (data is Map<String, dynamic>) {
              if (data['type'] == 'done' && data['filename'] != null) {
                outputFilename = data['filename'].toString();
                break;
              } else if (data['filename'] != null) {
                outputFilename = data['filename'].toString();
              }
            }
          } catch (_) {
            final match = RegExp(
              r'"filename":\s*"([^"]+)"',
            ).firstMatch(cleanLine);
            if (match != null) {
              outputFilename = match.group(1);
            }
          }
        }
      }

      if (outputFilename == null || outputFilename.isEmpty) {
        debugPrint('OmniVoice did not yield a filename');
        return null;
      }

      final networkAudioUrl = '$baseUrl/audio/outputs/$outputFilename';
      debugPrint('OmniVoice baby speech network URL ready: $networkAudioUrl');
      return networkAudioUrl;
    } catch (e) {
      debugPrint('OmniVoice generateBabySpeech error: $e');
      return null;
    }
  }
}
