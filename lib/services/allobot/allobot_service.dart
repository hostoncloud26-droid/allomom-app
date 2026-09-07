/// Entry point for the AlloBot chat: hands out an engine that already has the
/// seed corpus and the mother's live context loaded.
///
/// The corpus is process-wide and cached; the context is per-engine and
/// refreshable, because vitals and ANC rows change while a chat is open.
library;

import 'package:flutter/foundation.dart';

import 'package:allomom/services/allobot/allobot_context_loader.dart';
import 'package:allomom/services/allobot/allobot_engine.dart';
import 'package:allomom/services/allobot/allobot_seed_loader.dart';
import 'package:allomom/services/app_language.dart';

class AlloBotService {
  AlloBotService._();

  /// An engine ready to answer, with corpus and context in place.
  ///
  /// The two loads run concurrently: parsing fourteen CSVs and querying SQLite
  /// have nothing to do with each other, and the chat opens on whichever
  /// finishes last.
  static Future<AlloBotEngine> createEngine({
    String? language,
    DateTime? now,
  }) async {
    // Started together, awaited separately: `Future.wait` would collapse the
    // two result types into Object.
    final seeds = AlloBotSeedLoader.load();
    final context = AlloBotContextLoader.load(now: now);

    return AlloBotEngine(
      knowledgeBase: await seeds,
      context: await context,
      language: language ?? await AppLanguage.current(),
    );
  }

  /// Re-reads the mother's context into [engine], for after she logs a vital or
  /// completes a visit.
  static Future<void> refreshContext(
    AlloBotEngine engine, {
    DateTime? now,
  }) async {
    try {
      engine.updateContext(await AlloBotContextLoader.load(now: now));
    } catch (e) {
      debugPrint('AlloBotService: context refresh failed: $e');
    }
  }
}
