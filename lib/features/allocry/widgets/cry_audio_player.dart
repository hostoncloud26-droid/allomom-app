import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:allomom/features/allocry/service/cry_audio_store.dart';

/// Plays back a kept cry recording.
///
/// Takes the stored *file name* rather than a path and resolves it through
/// [CryAudioStore], because the absolute path recorded on the day is not valid
/// after an iOS app update. When the clip is missing — cleared storage, a
/// record saved when the copy failed — the bar says so instead of failing on a
/// tap.
class CryAudioPlayer extends StatefulWidget {
  /// The stored file name from the cry record.
  final String? audioFile;

  final Color color;

  /// Compact leaves out the scrubber, for tight rows in history.
  final bool compact;

  const CryAudioPlayer({
    super.key,
    this.audioFile,
    this.color = const Color(0xFFFF4E6A),
    this.compact = false,
  });

  @override
  State<CryAudioPlayer> createState() => _CryAudioPlayerState();
}

class _CryAudioPlayerState extends State<CryAudioPlayer> {
  final AudioPlayer _player = AudioPlayer();

  String? _resolvedPath;
  bool _loading = true;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(CryAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioFile != widget.audioFile) _prepare();
  }

  Future<void> _prepare() async {
    setState(() => _loading = true);

    final path = await CryAudioStore.resolve(widget.audioFile);
    if (!mounted) return;

    if (path == null) {
      setState(() {
        _resolvedPath = null;
        _loading = false;
      });
      return;
    }

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playing = state == PlayerState.playing);
    });
    _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _position = Duration.zero);
    });

    try {
      await _player.setSourceDeviceFile(path);
      if (!mounted) return;
      setState(() {
        _resolvedPath = path;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _resolvedPath = null;
        _loading = false;
      });
    }
  }

  Future<void> _togglePlay() async {
    if (_resolvedPath == null) return;
    if (_playing) {
      await _player.pause();
    } else {
      await _player.resume();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_resolvedPath == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mic_off_rounded, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 6),
          Text(
            'Recording unavailable',
            style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade500),
          ),
        ],
      );
    }

    final button = GestureDetector(
      onTap: _togglePlay,
      child: Container(
        width: widget.compact ? 36 : 46,
        height: widget.compact ? 36 : 46,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: widget.compact ? 20 : 26,
        ),
      ),
    );

    if (widget.compact) return button;

    final maxMs = _duration.inMilliseconds.toDouble();
    final valueMs = _position.inMilliseconds.toDouble().clamp(0.0, maxMs);

    return Row(
      children: [
        button,
        const SizedBox(width: 12),
        Text(
          _format(_position),
          style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbColor: widget.color,
              activeTrackColor: widget.color,
              inactiveTrackColor: widget.color.withValues(alpha: 0.18),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              min: 0,
              max: maxMs > 0 ? maxMs : 1,
              value: maxMs > 0 ? valueMs : 0,
              onChanged: maxMs > 0
                  ? (v) => _player.seek(Duration(milliseconds: v.toInt()))
                  : null,
            ),
          ),
        ),
        Text(
          _format(_duration),
          style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280)),
        ),
      ],
    );
  }
}
