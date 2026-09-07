/// Loads the `lib/seeds/` Q&A sheets off the asset bundle and caches the built
/// corpus for the process lifetime.
///
/// Discovery goes through [AssetManifest], so adding a sheet to `lib/seeds/` is
/// enough to put it in AlloBot's corpus with no code change. The filenames
/// carry spaces, ampersands and an en dash, which a hardcoded list gets wrong
/// sooner or later.
///
/// A hardcoded fallback and a timeout sit behind it purely as belt and braces:
/// the manifest is read behind the chat's loading spinner, so if that read ever
/// failed or stalled the mother would watch the spinner forever. Falling back
/// to the sheets known at build time degrades instead.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:allomom/services/allobot/allobot_knowledge_base.dart';

class AlloBotSeedLoader {
  AlloBotSeedLoader._();

  /// Directory the sheets live in, as registered in `pubspec.yaml`.
  static const String seedDirectory = 'lib/seeds/';

  /// The sheet that lists topic keys rather than Q&A rows.
  static const String topicsFileFragment = 'Topics';

  static AlloBotKnowledgeBase? _cached;
  static Future<AlloBotKnowledgeBase>? _inFlight;

  /// The corpus, built once and reused.
  ///
  /// Concurrent callers share one load — the chat tab and the voice modal both
  /// ask for it on open, and parsing fourteen sheets twice is wasted work.
  static Future<AlloBotKnowledgeBase> load({AssetBundle? bundle}) {
    final cached = _cached;
    if (cached != null) return Future.value(cached);
    return _inFlight ??= _load(bundle ?? rootBundle).then((knowledgeBase) {
      _cached = knowledgeBase;
      _inFlight = null;
      return knowledgeBase;
    }).catchError((Object error, StackTrace stack) {
      _inFlight = null;
      debugPrint('AlloBotSeedLoader: seed load failed: $error');
      // An empty corpus is a working bot that admits it knows nothing, which
      // beats a chat screen that fails to open.
      return AlloBotKnowledgeBase.empty();
    });
  }

  /// Drops the cache. Only useful in tests.
  @visibleForTesting
  static void resetCache() {
    _cached = null;
    _inFlight = null;
  }

  /// How long to wait for the asset manifest before falling back.
  ///
  /// Two seconds is far more than a local bundle read needs; this only exists
  /// so a stalled read cannot strand the chat's loading state.
  static const Duration manifestTimeout = Duration(seconds: 2);

  /// The sheets as they exist today, used when the manifest cannot be read.
  ///
  /// Kept in sync by [load] logging a warning when the manifest lists a sheet
  /// this misses.
  static const List<String> fallbackSeedAssets = [
    'lib/seeds/Allobaby - Q and A - App & Technology Usage.csv',
    'lib/seeds/Allobaby - Q and A - Baby Growth & Development.csv',
    'lib/seeds/Allobaby - Q and A - Delivery Preparation.csv',
    'lib/seeds/Allobaby - Q and A - Emotional and Mental health.csv',
    'lib/seeds/Allobaby - Q and A - Lifestyle & Daily Activities.csv',
    'lib/seeds/Allobaby - Q and A - Nutrition & Diet.csv',
    'lib/seeds/Allobaby - Q and A - Physical Changes & Symptoms.csv',
    'lib/seeds/Allobaby - Q and A - Pregnancy Basics.csv',
    'lib/seeds/Allobaby - Q and A - Risk & Warning Signs.csv',
    'lib/seeds/Allobaby - Q and A - Sleep & Rest Questions.csv',
    'lib/seeds/Allobaby - Q and A - Special Cases - Miscarriage .csv',
    'lib/seeds/Allobaby - Q and A - Topics.csv',
    'lib/seeds/Allobaby - Q and A - fruit_questions.csv',
    'lib/seeds/Allobaby - Q and A - vegetable_questions.csv',
  ];

  /// Seed asset paths, from the manifest where possible.
  static Future<List<String>> _seedPaths(AssetBundle bundle) async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(bundle)
          .timeout(manifestTimeout);
      final paths = manifest
          .listAssets()
          .where(
            (path) => path.startsWith(seedDirectory) && path.endsWith('.csv'),
          )
          .toList()
        ..sort();

      if (paths.isNotEmpty) {
        final missing = paths
            .where((path) => !fallbackSeedAssets.contains(path))
            .toList();
        if (missing.isNotEmpty) {
          debugPrint(
            'AlloBotSeedLoader: $missing is bundled but absent from '
            'fallbackSeedAssets — add it so the corpus loads in tests too.',
          );
        }
        return paths;
      }

      debugPrint(
        'AlloBotSeedLoader: manifest lists no CSVs under $seedDirectory — is '
        'it under flutter/assets in pubspec.yaml? Using the known filenames.',
      );
    } on TimeoutException {
      debugPrint('AlloBotSeedLoader: asset manifest timed out, using the '
          'known filenames');
    } catch (e) {
      debugPrint('AlloBotSeedLoader: asset manifest unavailable ($e), using '
          'the known filenames');
    }
    return fallbackSeedAssets;
  }

  static Future<AlloBotKnowledgeBase> _load(AssetBundle bundle) async {
    final paths = await _seedPaths(bundle);
    final sheets = <String, String>{};
    String? topicsCsv;

    for (final path in paths) {
      final String contents;
      try {
        contents = await bundle.loadString(path);
      } catch (e) {
        debugPrint('AlloBotSeedLoader: could not read $path: $e');
        continue;
      }

      final label = topicLabelFromPath(path);
      if (label.toLowerCase() == topicsFileFragment.toLowerCase()) {
        topicsCsv = contents;
        continue;
      }
      sheets[label] = contents;
    }

    if (sheets.isEmpty) {
      debugPrint('AlloBotSeedLoader: no seed sheets could be read');
      return AlloBotKnowledgeBase.empty();
    }

    final knowledgeBase =
        AlloBotKnowledgeBase.build(sheets: sheets, topicsCsv: topicsCsv);
    debugPrint(
      'AlloBotSeedLoader: indexed ${knowledgeBase.size} Q&A rows from '
      '${sheets.length} sheets',
    );
    return knowledgeBase;
  }

  /// Turns a seed asset path into the topic label.
  ///
  /// `lib/seeds/Allobaby - Q and A - Nutrition & Diet.csv` becomes
  /// `Nutrition & Diet`, which is exactly how `Topics.csv` spells its
  /// categories, so the two line up and the sheet inherits its canonical key.
  /// The two snake_case sheets (`fruit_questions`, `vegetable_questions`) have
  /// no `Topics.csv` row, so they are title-cased into `Fruit Questions` and
  /// `Vegetable Questions`.
  static String topicLabelFromPath(String path) {
    var name = path.split('/').last;
    if (name.toLowerCase().endsWith('.csv')) {
      name = name.substring(0, name.length - 4);
    }

    // Everything up to and including the last " - " is the sheet-name prefix
    // ("Allobaby - Q and A - ").
    final separator = name.lastIndexOf(' - ');
    if (separator != -1) name = name.substring(separator + 3);
    name = name.trim();

    if (!name.contains('_')) return name;
    return name
        .split('_')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
