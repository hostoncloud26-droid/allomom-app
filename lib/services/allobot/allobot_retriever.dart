/// Retrieval over the seed corpus: the "R" in AlloBot's RAG loop.
///
/// Pure BM25 over the inverted index in [AlloBotKnowledgeBase], plus a few
/// domain boosts and — the part that matters most for a maternal-health bot —
/// a *confidence* score. A generic search engine always returns its best row;
/// AlloBot must be able to tell that it has no good row and say so instead of
/// confidently answering a question the sheets never covered.
library;

import 'dart:math' as math;

import 'package:allomom/services/allobot/allobot_knowledge_base.dart';

/// BM25 term-frequency saturation. 1.4 is slightly above the usual 1.2 because
/// seed questions are short, so a repeated term really is a strong signal.
const double _k1 = 1.4;

/// BM25 length normalisation.
const double _b = 0.72;

/// How close a candidate's score must be to the best score to count as tied
/// and be reranked by confidence. 0.97 = within 3%.
const double _tieWindow = 0.97;

/// Words that mean the mother is reporting something alarming, not asking a
/// neutral question. They bias retrieval towards the warning-signs and
/// special-cases sheets.
///
/// Deliberately narrow. Broad symptom words do more harm than good here:
/// "blood" appears in "blood group" and "blood test", and mild swelling,
/// cramping and discharge are all ordinary parts of pregnancy — biasing those
/// towards the danger-signs sheet buries the reassuring answer that actually
/// fits. Genuinely urgent presentations are caught by [detectRedFlag] in
/// `allobot_intents.dart`, which matches whole phrases and escalates outright,
/// so this list only has to nudge ranking.
const Set<String> worryWords = {
  'bleeding', 'severe', 'unbearable', 'emergency', 'urgent', 'danger',
  'dangerous', 'worried', 'worry', 'scared', 'afraid', 'faint', 'fainting',
  'fits', 'seizure', 'breathless', 'leaking', 'miscarriage', 'miscarry',
};

/// One scored candidate.
class RetrievedEntry {
  const RetrievedEntry({
    required this.entry,
    required this.score,
    required this.coverage,
    required this.confidence,
    required this.matchedTerms,
  });

  final KnowledgeEntry entry;

  /// Raw BM25 score after boosts. Only meaningful relative to other candidates
  /// for the same query.
  final double score;

  /// Fraction of the query's content words this entry matched at all. The main
  /// guard against a single shared word ("baby") carrying a wrong answer.
  final double coverage;

  /// 0–1 estimate of whether this really answers the question.
  final double confidence;

  final List<String> matchedTerms;
}

/// The result of one retrieval pass.
class RetrievalResult {
  const RetrievalResult({
    required this.candidates,
    required this.queryTerms,
    required this.vocabularyOverlap,
  });

  final List<RetrievedEntry> candidates;
  final List<String> queryTerms;

  /// Fraction of the query's *informative* words that exist anywhere in the
  /// corpus.
  ///
  /// The signal that separates an off-domain question from a verbose in-domain
  /// one. "How do I fix my car engine" and "is mild swelling in feet normal in
  /// week 24" both match only a third of their words to the best row, so
  /// per-entry coverage cannot tell them apart. But the maternal corpus has
  /// never seen "fix" or "engine", while it knows "mild", "swelling" and
  /// "normal".
  ///
  /// Corpus-common words are excluded from both sides of the fraction. Counting
  /// them lets a question the sheets do not cover pass on boilerplate alone:
  /// "is jackfruit safe during pregnancy" has two of three words in the corpus,
  /// but the two are "safe" and "pregnancy" — true of nearly every row — and
  /// the only word that identifies the question is the one word missing. Judged
  /// on informative terms it scores 0 and is correctly refused.
  ///
  /// When a query is *entirely* boilerplate there is nothing informative to
  /// judge, so this falls back to counting every term.
  final double vocabularyOverlap;

  RetrievedEntry? get best => candidates.isEmpty ? null : candidates.first;
  bool get isEmpty => candidates.isEmpty;

  /// Confidence of the best candidate, or 0 when nothing matched.
  double get topConfidence => best?.confidence ?? 0;

  /// Whether AlloBot should answer from this result rather than admit it does
  /// not know. Both gates have to pass: the corpus must recognise the question,
  /// and the best row must actually fit it.
  bool get isAnswerable =>
      vocabularyOverlap >= minVocabularyOverlap &&
      topConfidence >= answerConfidenceThreshold;
}

/// The confidence AlloBot needs before it will answer from the seeds.
///
/// Below this the engine says it is thinking and hands the mother to a human
/// instead of guessing — the safe failure mode in this domain.
///
/// Calibrated against the real corpus over 24 in-domain and 14 off-domain
/// questions. The in-domain questions that fall below it are ones where
/// retrieval returns a genuinely wrong row anyway ("do I need to take iron
/// tablets" matches a row about taking baths), so gating them is the right
/// outcome, not a loss.
const double answerConfidenceThreshold = 0.34;

/// The share of a question's content words that must appear somewhere in the
/// corpus before AlloBot will answer it at all.
///
/// This, not confidence, is what separates an off-domain question from a
/// clumsily-worded in-domain one. Over the same calibration set the two
/// classes do not overlap on it — every in-domain question scored 0.67 or
/// above, every off-domain one 0.50 or below — while their confidences
/// interleave (a correct answer about swollen legs scores 0.32, below a
/// nonsense match on "what is my bank balance" at 0.32).
///
/// It also fails in the right direction for a real question the sheets simply
/// do not cover: "is jackfruit safe" leaves "jackfruit" unmatched, drops below
/// the floor, and gets an honest "I don't know" instead of the nearest fruit.
const double minVocabularyOverlap = 0.6;

/// Confidence above which the seed answer is treated as a direct hit and used
/// verbatim rather than hedged.
const double strongConfidenceThreshold = 0.62;

class AlloBotRetriever {
  AlloBotRetriever(this.knowledgeBase);

  final AlloBotKnowledgeBase knowledgeBase;

  /// Ranks seed entries against [query].
  RetrievalResult search(String query, {int limit = 5}) {
    final terms = tokenizeForSearch(query);
    if (terms.isEmpty || knowledgeBase.isEmpty) {
      return RetrievalResult(
        candidates: const [],
        queryTerms: terms,
        vocabularyOverlap: 0,
      );
    }

    final uniqueTerms = terms.toSet().toList();
    final total = knowledgeBase.size;
    final scores = <int, double>{};
    final matched = <int, Set<String>>{};

    for (final term in uniqueTerms) {
      final postings = knowledgeBase.postingsFor(term);
      if (postings.isEmpty) continue;

      // Standard BM25 IDF, floored so a term present in most rows still counts
      // for a little rather than going negative.
      final documentFrequency = postings.length;
      final idf = _idf(total, documentFrequency);

      for (final index in postings) {
        final frequency = knowledgeBase.termFrequency(index, term);
        if (frequency == 0) continue;
        final length = knowledgeBase.lengthOf(index);
        final normalization =
            _k1 * (1 - _b + _b * (length / knowledgeBase.averageLength));
        final contribution = idf * (frequency * (_k1 + 1)) / (frequency + normalization);

        scores[index] = (scores[index] ?? 0) + contribution;
        matched.putIfAbsent(index, () => <String>{}).add(term);
      }
    }

    final vocabularyOverlap = _vocabularyOverlap(uniqueTerms);

    if (scores.isEmpty) {
      return RetrievalResult(
        candidates: const [],
        queryTerms: terms,
        vocabularyOverlap: vocabularyOverlap,
      );
    }

    final isWorried = uniqueTerms.any(worryWords.contains);
    final querySet = uniqueTerms.toSet();

    final candidates = <RetrievedEntry>[];
    scores.forEach((index, rawScore) {
      final entry = knowledgeBase.entries[index];
      final matchedTerms = matched[index] ?? const <String>{};
      final coverage = matchedTerms.length / querySet.length;

      var score = rawScore;

      // Near-duplicate phrasing of a seed question is the strongest signal
      // available, so reward set overlap with the question itself.
      final similarity = _questionSimilarity(querySet, entry);
      score *= 1 + similarity;

      // The slug is a hand-written topic label; matching it is deliberate.
      final slugTerms = tokenizeForSearch(entry.slug.replaceAll('_', ' ')).toSet();
      if (slugTerms.isNotEmpty && slugTerms.every(querySet.contains)) score *= 1.35;

      // A worried question belongs in the warning-signs sheet; a calm one does
      // not want a page about danger signs.
      if (isWorried) {
        score *= entry.isSafetyTopic ? 1.3 : 0.92;
      }

      final lexical = score / (score + 8.0);

      // How well this row fits the question. Whether the *corpus* covers the
      // question at all is a separate judgement, made once per query by
      // [RetrievalResult.vocabularyOverlap] rather than folded in here, so
      // this number stays readable as "how good is this match".
      final confidence =
          (0.55 * coverage + 0.30 * lexical + 0.15 * similarity).clamp(0.0, 1.0);

      candidates.add(
        RetrievedEntry(
          entry: entry,
          score: score,
          coverage: coverage,
          confidence: confidence,
          matchedTerms: matchedTerms.toList(),
        ),
      );
    });

    candidates.sort((a, b) => b.score.compareTo(a.score));
    _promoteBestOfNearTies(candidates);

    return RetrievalResult(
      candidates: candidates.take(limit).toList(),
      queryTerms: terms,
      vocabularyOverlap: vocabularyOverlap,
    );
  }

  /// Share of [uniqueTerms] the corpus recognises, counting only informative
  /// terms and falling back to all of them when none are informative.
  double _vocabularyOverlap(List<String> uniqueTerms) {
    if (uniqueTerms.isEmpty) return 0;

    var informative = 0;
    var informativeKnown = 0;
    var known = 0;

    for (final term in uniqueTerms) {
      final isKnown = knowledgeBase.documentFrequency(term) > 0;
      if (isKnown) known++;
      if (!knowledgeBase.isInformativeTerm(term)) continue;
      informative++;
      if (isKnown) informativeKnown++;
    }

    if (informative == 0) return known / uniqueTerms.length;
    return informativeKnown / informative;
  }

  /// Among candidates whose BM25 scores are effectively tied, moves the one
  /// with the highest confidence to the front.
  ///
  /// BM25 alone cannot separate rows that differ by one content word — a Tamil
  /// query for mango scores within half a percent of the pineapple row, since
  /// the two questions are otherwise word-for-word identical. Confidence,
  /// which weighs how much of the *question* was matched, does separate them.
  ///
  /// The window is deliberately tight. Widening it would let confidence
  /// override real score gaps, which is worse: for "is mild swelling in feet
  /// normal in week 24" the correct row about swollen legs scores 10% above a
  /// row about mild bleeding that happens to share the phrase "is this normal
  /// in pregnancy" — and has marginally higher confidence.
  static void _promoteBestOfNearTies(List<RetrievedEntry> candidates) {
    if (candidates.length < 2) return;
    final best = candidates.first;
    if (best.score <= 0) return;

    var winner = 0;
    for (var i = 1; i < candidates.length; i++) {
      if (candidates[i].score < best.score * _tieWindow) break;
      if (candidates[i].confidence > candidates[winner].confidence) winner = i;
    }
    if (winner == 0) return;

    final promoted = candidates.removeAt(winner);
    candidates.insert(0, promoted);
  }

  /// Standard BM25 IDF with the +1 shift that keeps it non-negative for terms
  /// appearing in more than half the corpus.
  static double _idf(int total, int documentFrequency) => math.log(
        (total - documentFrequency + 0.5) / (documentFrequency + 0.5) + 1,
      );

  /// Jaccard overlap between the query terms and the entry's question, taking
  /// the best-scoring language.
  ///
  /// Scored per language rather than against English only, so a question typed
  /// in Tamil is compared with the Tamil phrasing of the row — which is what
  /// separates the mango row from the otherwise word-identical pineapple row.
  static double _questionSimilarity(Set<String> querySet, KnowledgeEntry entry) {
    var best = 0.0;
    for (final locale in entry.locales.values) {
      if (locale.question.isEmpty) continue;
      final questionSet = tokenizeForSearch(locale.question).toSet();
      if (questionSet.isEmpty) continue;
      final intersection = questionSet.intersection(querySet).length;
      if (intersection == 0) continue;
      final score = intersection / questionSet.union(querySet).length;
      if (score > best) best = score;
    }
    return best;
  }
}
