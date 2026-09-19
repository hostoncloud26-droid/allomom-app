/// One line the baby can say: a stable key, the clip that voices it, and the
/// text the baby head card shows while it plays.
///
/// AlloBaby fetches the equivalent list from `/audio/get_by_language/<lang>`
/// and caches it. AlloMom ships the clips in `assets/audio/<lang>/onboard/`
/// instead, so the "list" is built from the local catalogue — the shape is kept
/// the same so a backend-fed list can be dropped in later without touching the
/// controller or the call sites.
class NarrationAudio {
  /// The keyword call sites ask for, e.g. `onb_lang`.
  final String key;

  /// Full asset path, e.g. `assets/audio/en/onboard/onb_lang.mp3`.
  ///
  /// Null when no clip is bundled for this key — the card still shows [text],
  /// it just stays silent.
  final String? asset;

  /// What the baby head card shows while this plays.
  final String text;

  const NarrationAudio({required this.key, required this.asset, required this.text});

  /// `audioplayers` resolves [AssetSource] against its own `assets/` prefix, so
  /// it wants the path with that prefix already stripped.
  String? get playerPath {
    final path = asset;
    if (path == null) return null;
    return path.startsWith('assets/') ? path.substring('assets/'.length) : path;
  }

  bool get hasAudio => asset != null;

  @override
  String toString() => 'NarrationAudio($key -> $asset)';
}
