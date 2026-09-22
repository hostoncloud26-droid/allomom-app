/// Trigger matching with {variable} placeholder support, and option matching.
///
/// A faithful port of the server's matcher, so an offline turn picks the same
/// intent the API would have. A trigger example may contain placeholders
/// written as `{name}` (or `{{ name }}`), e.g. `"can i eat {food}"`. Such an
/// example matches "can i eat mango" and captures `{"food": "mango"}`; the
/// captures are seeded into the session so later steps can interpolate them.
library;

import 'dart:math' as math;

import 'package:allomom/features/offline_chatbot/model/offline_chatbot_models.dart';

/// `{food}` or `{{ food }}` — identifier-like names only, so JSON braces are
/// left untouched.
final RegExp varToken = RegExp(r'\{\{?\s*([A-Za-z_][A-Za-z0-9_]*)\s*\}?\}');

/// Match quality tiers — lower is a better match.
const int tierExactLiteral = 0;
const int tierTemplateFull = 1;
const int tierLiteralSubstring = 2;
const int tierTemplateLoose = 3;

/// The user said only *part* of a trigger phrase: "good" against the trigger
/// "Which fruits are good to eat during pregnancy?". The loosest tier there is,
/// and the one a flow waiting on a free-text answer refuses — see [maxTier].
const int tierLiteralFragment = 4;

/// Punctuation trimmed from both the incoming message and captured values.
const String _trailingPunct = ' \t\n\r.,!?;:"\'“”‘’।';

/// Unicode-aware, so non-Latin scripts split into words too.
final RegExp _wordSplit = RegExp(r'[^\p{L}\p{N}_]+', unicode: true);

String _stripEdges(String text) {
  var start = 0;
  var end = text.length;
  while (start < end && _trailingPunct.contains(text[start])) {
    start++;
  }
  while (end > start && _trailingPunct.contains(text[end - 1])) {
    end--;
  }
  return text.substring(start, end);
}

/// Lowercased word tokens.
List<String> wordTokens(String text) {
  final cleaned =
      _stripEdges(text.trim().replaceAll(RegExp(r'\s+'), ' ')).toLowerCase();
  return cleaned.split(_wordSplit).where((t) => t.isNotEmpty).toList();
}

/// True when [needle] appears as a consecutive run inside [haystack].
bool _containsTokenRun(List<String> haystack, List<String> needle) {
  final size = needle.length;
  if (size == 0 || size > haystack.length) return false;
  for (var i = 0; i <= haystack.length - size; i++) {
    var ok = true;
    for (var j = 0; j < size; j++) {
      if (haystack[i + j] != needle[j]) {
        ok = false;
        break;
      }
    }
    if (ok) return true;
  }
  return false;
}

bool hasVariables(String example) =>
    example.isNotEmpty && varToken.hasMatch(example);

/// Placeholder names used by a trigger phrase, in order, deduplicated.
List<String> triggerVariables(String example) {
  final names = <String>[];
  for (final match in varToken.allMatches(example)) {
    final name = match.group(1)!;
    if (!names.contains(name)) names.add(name);
  }
  return names;
}

String _escape(String literal) {
  final parts = literal
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .map(RegExp.escape);
  return parts.join(r'\s+');
}

class _CompiledExample {
  final List<String> names;
  final int literalLength;
  final RegExp anchored;
  final RegExp loose;

  const _CompiledExample(
      this.names, this.literalLength, this.anchored, this.loose);
}

/// Compiles a templated example into anchored + loose regexes.
///
/// Returns null when the example has no placeholders (plain-text matching is
/// used for those) or when it is made entirely of placeholders with no literal
/// text to anchor on — too greedy to be a useful trigger.
_CompiledExample? _compileExample(String example) {
  if (!hasVariables(example)) return null;

  final names = <String>[];
  var body = '';
  var literalLength = 0;
  var cursor = 0;

  for (final match in varToken.allMatches(example)) {
    final literal = example.substring(cursor, match.start);
    final stripped = literal.trim();
    if (stripped.isNotEmpty) {
      literalLength += stripped.length;
      body += '${body.isEmpty ? '' : r'\s*'}${_escape(literal)}';
    }
    names.add(match.group(1)!);
    // Distinct group names even when a placeholder repeats.
    body += '${body.isEmpty ? '' : r'\s*'}(?<g${names.length - 1}>.+?)';
    cursor = match.end;
  }

  final tail = example.substring(cursor);
  if (tail.trim().isNotEmpty) {
    literalLength += tail.trim().length;
    body += '${r'\s*'}${_escape(tail)}';
  }

  if (literalLength == 0) return null;

  const end = r'\s*[.!?।]*\s*$';
  return _CompiledExample(
    names,
    literalLength,
    RegExp('^\\s*$body$end', caseSensitive: false, unicode: true),
    // Loose: allows leading filler ("hey, can i eat mango") but keeps the end
    // anchored so a trailing placeholder captures the whole remainder.
    RegExp('$body$end', caseSensitive: false, unicode: true),
  );
}

Map<String, String>? _captures(_CompiledExample compiled, RegExpMatch match) {
  final values = <String, String>{};
  for (var i = 0; i < compiled.names.length; i++) {
    final raw = match.namedGroup('g$i') ?? '';
    final value = _stripEdges(raw.trim()).trim();
    if (value.isEmpty) return null;
    values[compiled.names[i]] = value;
  }
  return values;
}

class ExampleMatch {
  final int tier;
  final Map<String, String> variables;

  const ExampleMatch(this.tier, this.variables);
}

/// Matches one trigger example against a user message.
///
/// Returns the tier (lower is better) and the captured variables, or null when
/// the example does not match at all.
ExampleMatch? matchExample(String example, String message) {
  if (example.isEmpty || message.isEmpty) return null;

  final msg = message.trim();
  final msgClean = _stripEdges(msg).trim().toLowerCase();
  final exClean = example.trim().toLowerCase();

  final compiled = _compileExample(example);
  if (compiled == null) {
    if (exClean.isEmpty) return null;
    if (exClean == msgClean) return const ExampleMatch(tierExactLiteral, {});

    // Containment is measured in whole words, not characters: the trigger "hi"
    // belongs to "hi there" but not to the "hi" buried in "thing".
    final msgWords = wordTokens(msgClean);
    final exWords = wordTokens(exClean);
    // The user said the trigger and more besides ("hi there" for "hi").
    if (_containsTokenRun(msgWords, exWords)) {
      return const ExampleMatch(tierLiteralSubstring, {});
    }
    // The other way round: what the user said is buried inside a longer
    // trigger. A real hit when she types "foods to avoid", and a false one for
    // every one-word answer a flow ever asks for, so it is tiered apart from
    // the above rather than sharing its confidence.
    if (_containsTokenRun(exWords, msgWords)) {
      return const ExampleMatch(tierLiteralFragment, {});
    }
    return null;
  }

  final anchored = compiled.anchored.firstMatch(msg);
  if (anchored != null) {
    final values = _captures(compiled, anchored);
    if (values != null) return ExampleMatch(tierTemplateFull, values);
  }

  final loose = compiled.loose.firstMatch(msg);
  if (loose != null) {
    final values = _captures(compiled, loose);
    if (values != null) return ExampleMatch(tierTemplateLoose, values);
  }

  return null;
}

class IntentMatch {
  final BotIntent intent;
  final Map<String, String> variables;
  final String? example;

  const IntentMatch(this.intent, this.variables, this.example);
}

class _Candidate {
  final int tier;
  final int negSpecificity;
  final String example;
  final Map<String, String> variables;

  const _Candidate(
      this.tier, this.negSpecificity, this.example, this.variables);

  /// Sortable, lowest wins: quality first, then how much literal text the
  /// trigger pins down.
  bool isBetterThan(_Candidate? other) {
    if (other == null) return true;
    if (tier != other.tier) return tier < other.tier;
    return negSpecificity < other.negSpecificity;
  }
}

_Candidate? _matchIntent(BotIntent intent, String message, {int? maxTier}) {
  _Candidate? best;
  for (final example in intent.examples) {
    final result = matchExample(example, message);
    if (result == null) continue;
    if (maxTier != null && result.tier > maxTier) continue;

    final specificity = example
        .replaceAll(varToken, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .length;
    final candidate =
        _Candidate(result.tier, -specificity, example, result.variables);
    if (candidate.isBetterThan(best)) best = candidate;
  }
  return best;
}

/// Picks the best matching intent for a message.
///
/// Exact literal matches beat templated matches, which beat loose/substring
/// matches; ties are broken by how much literal text the trigger pins down.
/// [maxTier] caps how loose a match may be — pass [tierTemplateFull] when a
/// stray match would be costly, e.g. while a step is waiting on one of its
/// options, where the substring tier would let "hi" fire on the word "thing".
/// [tierTemplateLoose] is the cap for a step waiting on a free-text answer:
/// enough for a real question to interrupt the flow, not so much that
/// answering "good" counts as asking about fruit.
IntentMatch? findBestIntent(List<BotIntent> intents, String message,
    {int? maxTier}) {
  _Candidate? bestCandidate;
  BotIntent? bestIntent;

  for (final intent in intents) {
    final candidate = _matchIntent(intent, message, maxTier: maxTier);
    if (candidate == null) continue;
    if (candidate.isBetterThan(bestCandidate)) {
      bestCandidate = candidate;
      bestIntent = intent;
    }
  }

  if (bestIntent == null || bestCandidate == null) return null;
  return IntentMatch(bestIntent, bestCandidate.variables, bestCandidate.example);
}

// ---------------------------------------------------------------------------
// Option matching
//
// When a flow step offers selectable options the user may tap a button (an
// exact match) or *speak* a free-form answer ("i am good", "nat good", "the
// second one"). These map such an utterance back onto one of the offered
// options so the flow can continue, and report a miss so the caller can ask
// the user to repeat instead of storing the raw utterance as the answer.
// ---------------------------------------------------------------------------

/// Similarity above which two normalised strings count as the same option.
/// Tuned to absorb speech-to-text slips ("nat good") without collapsing options
/// that are genuinely different.
const double optionFuzzyThreshold = 0.82;

/// A contained option explaining less of the utterance than this is outranked
/// by a fuzzy match on the whole utterance.
const double optionMinCoverage = 0.6;

/// Words too generic to select an option on their own.
const Set<String> _optionFillers = {
  'i', 'a', 'an', 'the', 'am', 'is', 'are', 'it', 'its', 'to', 'of', 'my',
  'me', 'we', 'you', 'so', 'please', 'well',
};

/// "2", "option 2", "#2", "2." — an explicit positional pick.
final RegExp _ordinalPick =
    RegExp(r'^(?:option|choice|number|no|#)?\s*[#.)]?\s*(\d{1,2})\s*[.):]?$');

const Map<String, int> _ordinalWords = {
  'first': 1, 'second': 2, 'third': 3, 'fourth': 4, 'fifth': 5,
  'two': 2, 'three': 3, 'four': 4, 'five': 5,
};

const Set<String> _pickContext = {
  'option', 'choice', 'number', 'the', 'one', 'select', 'choose',
};

/// Lowercases, collapses whitespace and trims punctuation for comparison.
String normalizeOptionText(String text) =>
    _stripEdges(text.trim().replaceAll(RegExp(r'\s+'), ' ')).trim().toLowerCase();

/// Guards the loose tiers — a lone filler word must not select an option.
bool _isSelective(List<String> tokens) {
  final meaningful = tokens.where((t) => !_optionFillers.contains(t)).toList();
  if (meaningful.isEmpty) return false;
  return meaningful.length > 1 || meaningful.first.length >= 2;
}

/// True for a short word and its spoken variant ("ok"/"okay", "no"/"nope").
bool _isInflection(String a, String b) {
  final short = a.length <= b.length ? a : b;
  final long = a.length <= b.length ? b : a;
  return short.length >= 2 &&
      long.startsWith(short) &&
      long.length - short.length <= 2;
}

/// Resolves "2" / "option 2" / "the second one" to a 0-based option index.
int? _ordinalIndex(String message, int optionCount) {
  final norm = normalizeOptionText(message);
  if (norm.isEmpty) return null;

  final digits = _ordinalPick.firstMatch(norm);
  if (digits != null) {
    final idx = int.parse(digits.group(1)!) - 1;
    return (idx >= 0 && idx < optionCount) ? idx : null;
  }

  final tokens = wordTokens(norm);
  // Only read a spelled-out ordinal when the rest of the utterance is pick
  // scaffolding, so an option literally named "two" is still matched by text.
  final onlyScaffolding = tokens.every(
      (t) => _pickContext.contains(t) || _ordinalWords.containsKey(t));
  if (!onlyScaffolding) return null;

  for (final token in tokens) {
    final value = _ordinalWords[token];
    if (value != null) {
      final idx = value - 1;
      return (idx >= 0 && idx < optionCount) ? idx : null;
    }
  }
  return null;
}

class _Block {
  final int a;
  final int b;
  final int size;

  const _Block(this.a, this.b, this.size);
}

_Block _longestMatch(String a, String b, int alo, int ahi, int blo, int bhi) {
  var bestA = alo, bestB = blo, bestSize = 0;
  // Longest common substring over the given windows, the same block difflib
  // builds its ratio from.
  var previous = List<int>.filled(bhi - blo + 1, 0);
  for (var i = alo; i < ahi; i++) {
    final current = List<int>.filled(bhi - blo + 1, 0);
    for (var j = blo; j < bhi; j++) {
      if (a[i] == b[j]) {
        final size = previous[j - blo] + 1;
        current[j - blo + 1] = size;
        if (size > bestSize) {
          bestSize = size;
          bestA = i - size + 1;
          bestB = j - size + 1;
        }
      }
    }
    previous = current;
  }
  return _Block(bestA, bestB, bestSize);
}

int _matchingCharacters(String a, String b, int alo, int ahi, int blo, int bhi) {
  if (alo >= ahi || blo >= bhi) return 0;
  final block = _longestMatch(a, b, alo, ahi, blo, bhi);
  if (block.size == 0) return 0;
  return block.size +
      _matchingCharacters(a, b, alo, block.a, blo, block.b) +
      _matchingCharacters(a, b, block.a + block.size, ahi,
          block.b + block.size, bhi);
}

/// How alike two strings are, 0..1 — the same 2*M/T measure the server's
/// difflib ratio uses, so a fuzzy option match lands the same way offline.
double similarityRatio(String a, String b) {
  final total = a.length + b.length;
  if (total == 0) return 1.0;
  final matched = _matchingCharacters(a, b, 0, a.length, 0, b.length);
  return 2.0 * matched / total;
}

class _OptionCandidate {
  final int tier;
  final int negTokens;
  final double negCoverage;

  const _OptionCandidate(this.tier, this.negTokens, this.negCoverage);

  bool isBetterThan(_OptionCandidate? other) {
    if (other == null) return true;
    if (tier != other.tier) return tier < other.tier;
    if (negTokens != other.negTokens) return negTokens < other.negTokens;
    return negCoverage < other.negCoverage;
  }
}

/// Maps a user utterance onto one of a step's options.
///
/// Returns the canonical option string (exactly as configured on the step), or
/// null when nothing matches confidently. Match quality, best first:
///
/// 1. the normalised texts are identical ("Not Good" == "not good.")
/// 2. a positional pick ("2", "option 2", "the second one")
/// 3. the utterance *contains* the option ("i am not good" -> "Not Good"); the
///    option pinning down the most words wins, so "Good" never steals "Not Good"
/// 4. the option contains the utterance ("not" -> "Not Good")
/// 5. a fuzzy near-match, to absorb transcription slips ("nat good")
String? matchOption(List<String> options, String message) {
  final opts = options.where((o) => o.trim().isNotEmpty).toList();
  if (opts.isEmpty || message.trim().isEmpty) return null;

  final msgNorm = normalizeOptionText(message);
  if (msgNorm.isEmpty) return null;
  final msgTokens = wordTokens(msgNorm);

  for (final opt in opts) {
    if (normalizeOptionText(opt) == msgNorm) return opt;
  }

  final idx = _ordinalIndex(msgNorm, opts.length);
  if (idx != null) return opts[idx];

  final selective = _isSelective(msgTokens);
  _OptionCandidate? best;
  String? bestOption;

  for (final opt in opts) {
    final optNorm = normalizeOptionText(opt);
    final optTokens = wordTokens(optNorm);
    if (optTokens.isEmpty) continue;

    _OptionCandidate? candidate;

    if (_containsTokenRun(msgTokens, optTokens) && _isSelective(optTokens)) {
      // How much of what the user said this option accounts for. A sliver of
      // the utterance ("good" out of "nat good") is demoted below a
      // whole-utterance fuzzy match, which is likely the real intent.
      final coverage = optNorm.length / msgNorm.length;
      final tier = coverage >= optionMinCoverage ? 3 : 6;
      candidate = _OptionCandidate(tier, -optTokens.length, -coverage);
    } else if (selective && _containsTokenRun(optTokens, msgTokens)) {
      candidate = _OptionCandidate(4, -msgTokens.length, 0.0);
    } else {
      var ratio = similarityRatio(msgNorm, optNorm);
      if (_isInflection(msgNorm, optNorm)) {
        // "okay" / "ok", "nope" / "no" — too short to score generously, but
        // unmistakably the same answer.
        ratio = math.max(ratio, optionFuzzyThreshold);
      }
      if (ratio >= optionFuzzyThreshold) {
        candidate = _OptionCandidate(5, 0, -ratio);
      }
    }

    if (candidate != null && candidate.isBetterThan(best)) {
      best = candidate;
      bestOption = opt;
    }
  }

  return bestOption;
}
