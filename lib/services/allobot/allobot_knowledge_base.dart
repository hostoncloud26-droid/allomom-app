/// The retrievable half of AlloBot's RAG loop: the curated maternal Q&A in
/// `lib/seeds/` turned into a searchable, multilingual corpus.
///
/// Everything here is pure — it takes CSV text in and gives an index out — so
/// the header handling and the retrieval maths can be unit tested without an
/// asset bundle or a database. `AlloBotSeedLoader` does the asset I/O.
///
/// **Why the header handling is defensive.** The fourteen seed sheets were
/// authored by hand at different times and none of them agree on column names.
/// The same field is variously `Key`, `Keyword` or `Keywords`; the English
/// question is `Mother’s Question (English)`, `Mother's question (English)` or
/// just `Question (English) ` with a trailing space; the English answer is
/// `Allobaby Response (English)` in some sheets and `Allobaby - English` in
/// others. Matching literal strings would silently drop whole topics, so
/// columns are classified by the words they contain and by what the cells
/// actually hold.
library;

import 'package:allomom/services/allobot/allobot_csv.dart';

/// Languages the seed sheets carry answers in.
///
/// English is the retrieval language and the fallback. Kannada and Telugu are
/// offered on the app's language picker but have no columns in the sheets yet,
/// so they resolve to English via [KnowledgeEntry.localeFor].
const List<String> seedLanguages = ['en', 'ta', 'hi', 'mr', 'gu'];

/// The language rows are retrieved and fallen back to.
const String primarySeedLanguage = 'en';

/// Language tokens that can appear in a seed column header, mapped to the code
/// the app stores. Spellings are as authored, misspellings included.
const Map<String, String> _languageAliases = {
  'english': 'en',
  'eng': 'en',
  'tamil': 'ta',
  'tam': 'ta',
  'hindi': 'hi',
  'marathi': 'mr',
  'gujarathi': 'gu',
  'gujarati': 'gu',
  'gujrathi': 'gu',
  'kannada': 'kn',
  'telugu': 'te',
};

/// What a seed column holds.
enum SeedRole {
  /// The stable slug for the row, e.g. `mango_eating`.
  key,

  /// The mother's question, as she would phrase it.
  question,

  /// AlloBot's answer.
  answer,

  /// The question AlloBot asks back to keep the conversation going.
  followUp,

  /// An mp3 filename for the pre-recorded voiceover — never shown as text.
  voice,

  /// Anything unrecognised (romanised transliterations, empty spacer columns).
  ignored,
}

/// One classified seed column.
class SeedColumn {
  const SeedColumn({
    required this.index,
    required this.role,
    required this.language,
    required this.header,
  });

  final int index;
  final SeedRole role;
  final String language;
  final String header;

  @override
  String toString() => 'SeedColumn($index, $role, $language)';
}

/// Collapses a header into space-separated lowercase words.
///
/// Curly apostrophes, underscores, dashes and brackets all become spaces, and
/// `voice over` is joined into `voiceover` so the two spellings of the mp3
/// columns classify the same way.
String normalizeSeedHeader(String header) {
  final lowered = header.toLowerCase().replaceAll('’', "'").replaceAll('`', "'");
  final words = lowered
      .replaceAll(RegExp(r"[^a-z0-9']+"), ' ')
      .replaceAll("'", '')
      .trim();
  return words.replaceAll(RegExp(r'\s+'), ' ').replaceAll('voice over', 'voiceover');
}

/// Whether [value] is an audio filename rather than something to say.
///
/// The last-resort guard against headers that name neither `voiceover` nor
/// `voice over` — `Allobababy_response- Voice(HINDI)` reads as an answer column
/// but every cell in it is `1.mp3`.
bool looksLikeAudioAsset(String value) {
  final trimmed = value.trim().toLowerCase();
  if (trimmed.isEmpty || trimmed.contains(' ') && trimmed.length > 40) return false;
  return trimmed.endsWith('.mp3') ||
      trimmed.endsWith('.wav') ||
      trimmed.endsWith('.m4a') ||
      trimmed.endsWith('.ogg');
}

/// Classifies every column of a seed sheet's header row.
///
/// The sheets are laid out as one block of columns per language, so a column
/// whose header names no language inherits the language of the block it sits
/// in (`Next Question`, sitting among the English columns, is English). A
/// header naming a non-English language always wins over `english` in the same
/// header, which is what makes the romanised `Gujarathi-English` column resolve
/// to Gujarati instead of hijacking the English answer.
List<SeedColumn> classifySeedHeader(List<String> header) {
  final columns = <SeedColumn>[];
  var currentLanguage = 'en';

  for (var i = 0; i < header.length; i++) {
    final normalized = normalizeSeedHeader(header[i]);
    final words = normalized.split(' ').where((w) => w.isNotEmpty).toSet();

    String? explicit;
    for (final word in words) {
      final code = _languageAliases[word];
      if (code == null) continue;
      // A non-English tag beats an English one in the same header.
      if (explicit == null || (explicit == 'en' && code != 'en')) explicit = code;
    }
    if (explicit != null) currentLanguage = explicit;

    final role = _roleFor(words, normalized);
    columns.add(
      SeedColumn(
        index: i,
        role: role,
        // The key column is shared by every language.
        language: role == SeedRole.key ? '*' : currentLanguage,
        header: header[i],
      ),
    );
  }

  return columns;
}

SeedRole _roleFor(Set<String> words, String normalized) {
  final isQuestion = words.contains('question') || words.contains('questions');
  final isNext = words.contains('next') || words.contains('trigger');
  final isResponse = words.contains('response') ||
      words.contains('responses') ||
      words.contains('allobaby') ||
      words.contains('allobababy') ||
      words.contains('allobaby_respone');

  // `voiceover` is only ever an mp3 column. `(Baby Voice)` on its own is a
  // tone-of-voice note on real follow-up text, so plain `voice` is not enough.
  if (words.contains('voiceover')) return SeedRole.voice;

  if (isNext && (isQuestion || isResponse || words.contains('trigger'))) {
    return SeedRole.followUp;
  }
  if (isResponse) return SeedRole.answer;
  if (isQuestion) return SeedRole.question;
  if (normalized == 'key' || normalized == 'keyword' || normalized == 'keywords') {
    return SeedRole.key;
  }
  return SeedRole.ignored;
}

/// AlloBot's question, answer and follow-up in one language.
class EntryLocale {
  const EntryLocale({
    required this.question,
    required this.answer,
    required this.followUp,
    required this.voiceAsset,
  });

  /// The mother's question, as she would phrase it.
  final String question;

  /// AlloBot's answer.
  final String answer;

  /// The question AlloBot asks back, from the sheet's "Next Trigger Question"
  /// column.
  final String followUp;

  /// Pre-recorded voiceover filename, where the sheet names one. Not played
  /// yet — the chat uses device TTS — but kept so it can be.
  final String voiceAsset;

  bool get isUsable => answer.isNotEmpty;
}

/// One retrievable Q&A row, in every language the sheet has it.
class KnowledgeEntry {
  KnowledgeEntry({
    required this.id,
    required this.topicKey,
    required this.topicLabel,
    required this.slug,
    required this.locales,
  });

  final String id;
  final String topicKey;
  final String topicLabel;

  /// The row's own slug, e.g. `emergency_symptoms`. Doubles as a keyword
  /// source: `mango_eating` contributes "mango" and "eating" to the index.
  final String slug;

  final Map<String, EntryLocale> locales;

  /// The English row: the retrieval target, and the fallback for a language the
  /// sheets have not been translated into.
  EntryLocale get english =>
      locales[primarySeedLanguage] ?? locales.values.first;

  /// The row in [language], falling back to English when that language is
  /// missing or has a blank answer.
  ///
  /// The sheets are translated unevenly — Gujarati in particular has rows where
  /// the answer column is empty — so this is a real fallback, not a formality.
  EntryLocale localeFor(String language) {
    final wanted = locales[language];
    if (wanted != null && wanted.isUsable) return wanted;
    return english;
  }

  String get question => english.question;
  String get answer => english.answer;
  String get followUp => english.followUp;

  /// Languages this row actually has a usable answer in.
  Iterable<String> get availableLanguages =>
      locales.entries.where((e) => e.value.isUsable).map((e) => e.key);

  /// Whether this row can carry a safety warning. Used to bias retrieval on
  /// worrying phrasing towards the warning-signs sheet rather than a cheerful
  /// nutrition row that happens to share a word.
  bool get isSafetyTopic =>
      topicKey.contains('risk') ||
      topicKey.contains('warning') ||
      topicKey.contains('special') ||
      topicKey.contains('miscarriage');
}

/// A topic listed in `Allobaby - Q and A - Topics.csv`.
class SeedTopic {
  const SeedTopic({
    required this.key,
    required this.label,
    required this.focusArea,
    required this.sampleQuestions,
  });

  final String key;
  final String label;
  final String focusArea;
  final List<String> sampleQuestions;
}

/// English words carrying no retrieval signal.
const Set<String> _stopWords = {
  'a', 'am', 'an', 'and', 'any', 'are', 'as', 'at', 'be', 'been', 'but', 'by',
  'can', 'could', 'did', 'do', 'does', 'doing', 'during', 'for', 'from', 'get',
  'go', 'had', 'has', 'have', 'having', 'he', 'her', 'him', 'his', 'how', 'i',
  'if', 'in', 'into', 'is', 'it', 'its', 'just', 'me', 'my', 'need', 'no',
  'not', 'of', 'okay', 'on', 'or', 'our', 'out', 'please', 'she', 'should',
  'so', 'some', 'such', 'tell', 'than', 'that', 'the', 'their', 'them', 'then',
  'there', 'these', 'they', 'this', 'to', 'too', 'us', 'very', 'was', 'we',
  'were', 'what', 'when', 'where', 'which', 'who', 'why', 'will', 'with',
  'would', 'you', 'your', 'yours',
};

/// Splits on anything that is not a letter, digit or combining mark.
///
/// `\p{M}` is the part that is easy to miss and essential here: the vowel signs
/// and virama of every Indic script are combining marks, not letters, so a
/// class of only `\p{L}\p{N}` treats them as separators and shatters a Tamil
/// word into fragments — `மாம்பழம்` becomes `ம`, `ம`, `பழம`. That still
/// "works" in the sense that the index and the query shatter identically, but
/// the fragments are so common across rows that precision collapses.
final RegExp _tokenSplitter = RegExp(r'[^\p{L}\p{N}\p{M}]+', unicode: true);

/// Splits [text] into indexable terms.
///
/// Unicode-aware so Tamil, Hindi, Marathi and Gujarati questions tokenise as
/// well as English ones. English plurals and `-ing` / `-ed` forms are folded so
/// "kicking", "kicks" and "kick" all match each other.
List<String> tokenizeForSearch(String text) {
  final raw = text.toLowerCase().split(_tokenSplitter);
  final tokens = <String>[];
  for (final piece in raw) {
    if (piece.isEmpty) continue;
    if (_stopWords.contains(piece)) continue;
    if (piece.length == 1 && RegExp(r'[a-z0-9]').hasMatch(piece)) continue;
    tokens.add(_fold(piece));
  }
  return tokens;
}

/// Irregular forms and spelling variants the suffix stemmer cannot reach.
///
/// Applied to the corpus and the query alike, so both sides land on the same
/// term. "Swollen" is the one that matters most in practice — mothers write
/// "my feet are swollen" while the sheets say "why are my legs swelling", and
/// no amount of suffix stripping connects the two. The British/American pairs
/// are here because the sheets mix both spellings between themselves.
const Map<String, String> _termVariants = {
  'swollen': 'swell',
  'swelling': 'swell',
  'feet': 'foot',
  'teeth': 'tooth',
  'labour': 'labor',
  'oedema': 'edema',
  'haemoglobin': 'hemoglobin',
  'anaemia': 'anemia',
  'anaemic': 'anemia',
  'anemic': 'anemia',
  'vomitting': 'vomit',
  'vomiting': 'vomit',
  // The sheets never use the word "nausea" — they say "vomiting" throughout.
  // Left unmapped, "why do I have nausea" matched the one place the word
  // happens to appear, inside a banana answer ("helps with energy, nausea and
  // constipation"), and answered a nausea question with a fruit.
  'nausea': 'vomit',
  'nauseous': 'vomit',
  'sickness': 'vomit',
  'tummy': 'stomach',
  'belly': 'stomach',
  'gynaecologist': 'doctor',
  'gynecologist': 'doctor',
  'foetus': 'fetus',
  'foetal': 'fetal',
  'paediatrician': 'doctor',
};

/// Crude English suffix folding. Deliberately conservative: over-stemming
/// merges unrelated maternal terms ("delivery" / "deliver" is fine, but
/// stripping more would collide "pressure" with "press").
String _fold(String token) {
  final variant = _termVariants[token];
  if (variant != null) return variant;
  if (!RegExp(r'^[a-z]+$').hasMatch(token) || token.length <= 4) return token;
  for (final suffix in const ['ing', 'ies', 'ed', 'es', 's']) {
    if (!token.endsWith(suffix)) continue;
    var stem = token.substring(0, token.length - suffix.length);
    if (stem.length < 3) continue;
    if (suffix == 'ies') return '${stem}y';
    // English turns a trailing y into i before -ed/-es, so stripping the
    // suffix leaves "worri" from "worried" and "carri" from "carried" — which
    // then fail to match "worry" and "carrying". Putting the y back joins them.
    if (stem.endsWith('i')) stem = '${stem.substring(0, stem.length - 1)}y';
    return stem;
  }
  return token;
}

/// The searchable corpus: every seed row, plus the inverted index and document
/// statistics BM25 needs.
class AlloBotKnowledgeBase {
  AlloBotKnowledgeBase._({
    required this.entries,
    required this.topics,
    required Map<String, List<int>> postings,
    required Map<int, Map<String, int>> termFrequencies,
    required Map<int, int> lengths,
    required this.averageLength,
  })  : _postings = postings,
        _termFrequencies = termFrequencies,
        _lengths = lengths;

  final List<KnowledgeEntry> entries;
  final List<SeedTopic> topics;

  final Map<String, List<int>> _postings;
  final Map<int, Map<String, int>> _termFrequencies;
  final Map<int, int> _lengths;
  final double averageLength;

  bool get isEmpty => entries.isEmpty;
  int get size => entries.length;

  /// Share of the corpus a term may appear in before it stops counting as
  /// informative.
  static const double commonTermShare = 0.25;

  /// An empty corpus, used before the seeds finish loading and if they fail to.
  static AlloBotKnowledgeBase empty() => AlloBotKnowledgeBase._(
        entries: const [],
        topics: const [],
        postings: const {},
        termFrequencies: const {},
        lengths: const {},
        averageLength: 1,
      );

  /// Builds a corpus from raw sheet text.
  ///
  /// [sheets] maps a topic label (normally derived from the filename) to that
  /// sheet's CSV contents. [topicsCsv] is the optional `Topics.csv`, which
  /// supplies canonical topic keys and the sample questions used for chat
  /// suggestions. Rows without a usable English answer are skipped — a few
  /// sheets carry blank spacer rows.
  static AlloBotKnowledgeBase build({
    required Map<String, String> sheets,
    String? topicsCsv,
  }) {
    final topics = topicsCsv == null ? <SeedTopic>[] : _parseTopics(topicsCsv);
    final topicKeyByLabel = {
      for (final topic in topics) topic.label.toLowerCase(): topic.key,
    };

    final entries = <KnowledgeEntry>[];
    final seenIds = <String>{};

    for (final sheet in sheets.entries) {
      final label = sheet.key;
      final topicKey = topicKeyByLabel[label.toLowerCase()] ?? _slugify(label);
      final rows = parseCsv(sheet.value);
      if (rows.length < 2) continue;

      final columns = classifySeedHeader(rows.first);

      for (var r = 1; r < rows.length; r++) {
        final entry = _entryFromRow(
          row: rows[r],
          columns: columns,
          topicKey: topicKey,
          topicLabel: label,
          rowNumber: r,
          seenIds: seenIds,
        );
        if (entry != null) entries.add(entry);
      }
    }

    return _index(entries, topics);
  }

  static KnowledgeEntry? _entryFromRow({
    required List<String> row,
    required List<SeedColumn> columns,
    required String topicKey,
    required String topicLabel,
    required int rowNumber,
    required Set<String> seenIds,
  }) {
    String cell(int index) => index < row.length ? row[index].trim() : '';

    /// First non-empty cell for [role] in [language] that is not an mp3 name.
    /// "First wins" is what keeps duplicate and romanised columns from
    /// overwriting the authored text.
    String pick(SeedRole role, String language) {
      for (final column in columns) {
        if (column.role != role || column.language != language) continue;
        final value = cell(column.index);
        if (value.isEmpty || looksLikeAudioAsset(value)) continue;
        return _cleanText(value);
      }
      return '';
    }

    String pickVoice(String language) {
      for (final column in columns) {
        if (column.language != language) continue;
        final value = cell(column.index);
        if (value.isEmpty) continue;
        if (column.role == SeedRole.voice && !value.contains(' ')) return value;
        if (looksLikeAudioAsset(value)) return value;
      }
      return '';
    }

    var slug = '';
    for (final column in columns) {
      if (column.role != SeedRole.key) continue;
      slug = cell(column.index);
      if (slug.isNotEmpty) break;
    }
    // A couple of sheets leave the key column blank on continuation rows.
    if (slug.isEmpty) slug = _slugify(pick(SeedRole.question, primarySeedLanguage));

    final locales = <String, EntryLocale>{};
    for (final language in seedLanguages) {
      final answer = pick(SeedRole.answer, language);
      final question = pick(SeedRole.question, language);
      if (answer.isEmpty && question.isEmpty) continue;
      locales[language] = EntryLocale(
        question: question,
        answer: answer,
        followUp: pick(SeedRole.followUp, language),
        voiceAsset: pickVoice(language),
      );
    }

    // A row with no English answer is nothing to retrieve against — a few
    // sheets carry blank spacer rows.
    final english = locales[primarySeedLanguage];
    if (english == null || !english.isUsable) return null;

    var id = '$topicKey#${slug.isEmpty ? 'row$rowNumber' : slug}';
    if (!seenIds.add(id)) {
      id = '$id@$rowNumber';
      seenIds.add(id);
    }

    return KnowledgeEntry(
      id: id,
      topicKey: topicKey,
      topicLabel: topicLabel,
      slug: slug,
      locales: locales,
    );
  }

  static AlloBotKnowledgeBase _index(
    List<KnowledgeEntry> entries,
    List<SeedTopic> topics,
  ) {
    final postings = <String, List<int>>{};
    final termFrequencies = <int, Map<String, int>>{};
    final lengths = <int, int>{};
    var totalLength = 0;

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];

      // The question and the slug describe what the row is *about*, so they are
      // weighted above the answer prose, which is long and full of shared
      // boilerplate ("mommy", "doctor", "safe").
      final tokens = <String>[
        ...tokenizeForSearch(entry.question) * 3,
        ...tokenizeForSearch(entry.slug.replaceAll('_', ' ')) * 3,
        ...tokenizeForSearch(entry.topicLabel),
        ...tokenizeForSearch(entry.answer),
        ...tokenizeForSearch(entry.followUp),
        // Translated questions are indexed against the same row, so a mother
        // typing in Tamil reaches the answer English retrieval would find.
        for (final locale in entry.locales.entries)
          if (locale.key != primarySeedLanguage)
            ...tokenizeForSearch(locale.value.question),
      ];

      final frequencies = <String, int>{};
      for (final token in tokens) {
        frequencies[token] = (frequencies[token] ?? 0) + 1;
      }
      for (final token in frequencies.keys) {
        postings.putIfAbsent(token, () => <int>[]).add(i);
      }

      termFrequencies[i] = frequencies;
      lengths[i] = tokens.length;
      totalLength += tokens.length;
    }

    return AlloBotKnowledgeBase._(
      entries: entries,
      topics: topics,
      postings: postings,
      termFrequencies: termFrequencies,
      lengths: lengths,
      averageLength: entries.isEmpty ? 1 : totalLength / entries.length,
    );
  }

  /// Entry indices containing [term].
  List<int> postingsFor(String term) => _postings[term] ?? const [];

  /// How many entries contain [term]; 0 when the corpus has never seen it.
  int documentFrequency(String term) => _postings[term]?.length ?? 0;

  /// Whether [term] is discriminating enough to say anything about coverage.
  ///
  /// "Safe", "pregnancy" and "eat" appear in a large share of rows, so their
  /// presence is not evidence the corpus knows a question — every question
  /// contains words like them. Only rarer terms carry that signal.
  bool isInformativeTerm(String term) {
    if (entries.isEmpty) return true;
    final frequency = documentFrequency(term);
    if (frequency == 0) return true; // Unknown, and maximally informative.
    return frequency <= entries.length * commonTermShare;
  }

  /// How often [term] occurs in entry [index].
  int termFrequency(int index, String term) =>
      _termFrequencies[index]?[term] ?? 0;

  /// Token count of entry [index].
  int lengthOf(int index) => _lengths[index] ?? 1;

  /// Sample questions from `Topics.csv`, for the chat's suggestion chips.
  List<String> sampleQuestions({int limit = 5}) {
    final questions = <String>[];
    for (final topic in topics) {
      if (topic.sampleQuestions.isEmpty) continue;
      questions.add(topic.sampleQuestions.first);
      if (questions.length >= limit) break;
    }
    return questions;
  }

  static List<SeedTopic> _parseTopics(String csv) {
    final rows = parseCsv(csv);
    if (rows.length < 2) return const [];

    final topics = <SeedTopic>[];
    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.length < 2) continue;
      final key = row[0].trim();
      final label = row[1].trim();
      if (key.isEmpty || label.isEmpty) continue;
      topics.add(
        SeedTopic(
          key: key,
          label: label,
          focusArea: row.length > 2 ? row[2].trim() : '',
          sampleQuestions: row.length > 3 ? _splitSampleQuestions(row[3]) : const [],
        ),
      );
    }
    return topics;
  }

  /// Sample questions are crammed into one cell with no separator beyond the
  /// question marks, e.g. "Am I really pregnant?What symptoms are normal?".
  static List<String> _splitSampleQuestions(String cell) {
    return cell
        .split(RegExp(r'(?<=\?)\s*'))
        .map((q) => q.trim())
        .where((q) => q.length > 3)
        .toList();
  }

  /// Strips the wrapping quotes the sheets sometimes leave on a cell and
  /// flattens embedded newlines so the text fits a chat bubble.
  static String _cleanText(String value) {
    var text = value.trim();
    while (text.length > 1 && text.startsWith('"') && text.endsWith('"')) {
      text = text.substring(1, text.length - 1).trim();
    }
    if (text.startsWith('"')) text = text.substring(1).trim();
    if (text.endsWith('"')) text = text.substring(0, text.length - 1).trim();
    return text.replaceAll(RegExp(r'\s*\n+\s*'), ' ').replaceAll(RegExp(r'  +'), ' ');
  }

  static String _slugify(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

extension _Repeat<T> on List<T> {
  /// `tokens * 3` — repeats the list, which is how a field is weighted up in
  /// the bag-of-words index.
  List<T> operator *(int times) {
    final out = <T>[];
    for (var i = 0; i < times; i++) {
      out.addAll(this);
    }
    return out;
  }
}
