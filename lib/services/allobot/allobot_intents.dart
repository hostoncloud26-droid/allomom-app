/// Query classification for AlloBot.
///
/// Retrieval alone cannot answer "when is my next check-up" or "how much water
/// have I had" — those need the mother's own data, not the seed sheets. This
/// module decides, from the wording alone, whether a question should be
/// answered from her context, escalated as a red flag, or handed to retrieval.
///
/// Pure and keyword-driven on purpose: it runs on every keystroke-free send,
/// offline, with no model call, and its decisions have to be auditable — a
/// clinician can read the red-flag list and check it.
library;

/// What the mother is asking for.
enum AlloBotIntent {
  /// A symptom needing urgent care. Always wins over everything else.
  emergency,

  /// Next / last antenatal visit.
  ancSchedule,

  /// Due date and how long is left.
  dueDate,

  /// "How many weeks am I", "how is my baby doing".
  gestationalStatus,

  /// Water intake logged today.
  waterIntake,

  /// Fetal movement counting.
  kickCount,

  /// Weight, and weight gain.
  weight,

  /// Blood pressure readings.
  bloodPressure,

  /// Vaccines due.
  vaccination,

  /// Lab tests, scans and reports on her checklist.
  labReport,

  /// What is left on Today's Care.
  todayCare,

  /// Medicines and prescriptions.
  medication,

  /// Hello / how are you.
  greeting,

  /// Thanks.
  gratitude,

  /// "Yes", "tell me more" — accepts the follow-up AlloBot just offered.
  affirmation,

  /// "No", "not now" — declines it.
  negation,

  /// Anything else: goes to retrieval over the seeds.
  knowledge,
}

/// A classified query.
class IntentMatch {
  const IntentMatch({
    required this.intent,
    required this.matchedPhrase,
    this.redFlag,
  });

  final AlloBotIntent intent;

  /// The phrase that triggered the classification, for debugging and for the
  /// "I heard you say…" line on escalations.
  final String matchedPhrase;

  /// The specific danger sign found, when [intent] is
  /// [AlloBotIntent.emergency].
  final RedFlag? redFlag;

  bool get isEmergency => intent == AlloBotIntent.emergency;

  /// Whether answering this needs the mother's own data rather than the seeds.
  bool get needsContext => const {
        AlloBotIntent.ancSchedule,
        AlloBotIntent.dueDate,
        AlloBotIntent.gestationalStatus,
        AlloBotIntent.waterIntake,
        AlloBotIntent.kickCount,
        AlloBotIntent.weight,
        AlloBotIntent.bloodPressure,
        AlloBotIntent.vaccination,
        AlloBotIntent.labReport,
        AlloBotIntent.todayCare,
        AlloBotIntent.medication,
      }.contains(intent);
}

/// An obstetric danger sign, with the advice that goes with it.
class RedFlag {
  const RedFlag({
    required this.id,
    required this.label,
    required this.phrases,
    required this.advice,
  });

  final String id;

  /// How AlloBot names the symptom back to the mother.
  final String label;

  final List<String> phrases;

  /// What she should do, in one sentence.
  final String advice;
}

/// The danger signs AlloBot escalates on.
///
/// Sourced from the `Risk & Warning Signs` seed sheet's `emergency_symptoms`
/// row — heavy bleeding, severe pain, high fever, breathing difficulty and
/// reduced fetal movement — plus the standard pre-eclampsia and labour signs.
/// Kept deliberately broad: a false escalation costs a mother one unnecessary
/// phone call, a missed one costs far more.
const List<RedFlag> redFlags = [
  RedFlag(
    id: 'bleeding',
    label: 'bleeding',
    phrases: [
      'bleeding', 'blood coming', 'heavy bleeding', 'spotting heavily',
      'passing clots', 'bleeding a lot', 'rakht', 'blood loss',
    ],
    advice:
        'Any bleeding in pregnancy needs to be checked the same day — please call your doctor or go to the nearest facility now.',
  ),
  RedFlag(
    id: 'reduced_movement',
    label: 'reduced baby movement',
    phrases: [
      'baby not moving', 'not moving', 'no movement', 'reduced movement',
      'less movement', 'movements have reduced', 'baby stopped moving',
      'no kicks', 'not kicking', 'fewer kicks', 'baby is quiet',
    ],
    advice:
        'Lie on your left side and count movements for two hours. If you feel fewer than 10, go in to be checked straight away — do not wait for morning.',
  ),
  RedFlag(
    id: 'severe_pain',
    label: 'severe pain',
    phrases: [
      'severe pain', 'unbearable pain', 'terrible pain', 'sharp pain',
      'constant pain', 'severe abdominal pain', 'stomach pain severe',
      'very bad pain', 'pain is unbearable',
    ],
    advice:
        'Severe or constant abdominal pain needs urgent review — please get to your doctor or hospital now.',
  ),
  RedFlag(
    id: 'preeclampsia',
    label: 'signs of high blood pressure',
    phrases: [
      'blurred vision', 'blurry vision', 'seeing spots', 'severe headache',
      'bad headache that wont go', 'swelling in face', 'face swollen',
      'sudden swelling', 'fits', 'seizure', 'convulsion',
    ],
    advice:
        'A severe headache, blurred vision or sudden swelling can point to high blood pressure in pregnancy. This needs checking today — please go in.',
  ),
  RedFlag(
    id: 'fluid_leak',
    label: 'leaking fluid',
    phrases: [
      'water broke', 'water break', 'waters broke', 'leaking fluid',
      'fluid leaking', 'watery discharge lot', 'gush of fluid',
    ],
    advice:
        'If your waters have broken, go to your delivery facility now, even without contractions.',
  ),
  RedFlag(
    id: 'fever',
    label: 'high fever',
    phrases: [
      'high fever', 'very high temperature', 'fever with chills',
      'fever 102', 'fever 103', 'burning fever',
    ],
    advice:
        'A high fever in pregnancy should be seen today. Please avoid self-medicating and call your doctor.',
  ),
  RedFlag(
    id: 'breathing',
    label: 'difficulty breathing',
    phrases: [
      'cannot breathe', 'cant breathe', 'difficulty breathing',
      'breathless', 'chest pain', 'shortness of breath severe',
    ],
    advice:
        'Breathing difficulty or chest pain is an emergency — please get to a hospital immediately.',
  ),
];

/// Phrase lists per context intent, longest-phrase-first within each list so
/// "kick count" beats a bare "count".
const Map<AlloBotIntent, List<String>> _intentPhrases = {
  AlloBotIntent.ancSchedule: [
    'next anc', 'anc visit', 'anc date', 'anc appointment', 'anc check',
    'antenatal', 'next check up', 'next checkup', 'next check-up',
    'next visit', 'next appointment', 'doctor visit', 'doctor appointment',
    'when is my scan', 'next scan', 'clinic visit', 'hospital visit',
    'anc', 'checkup', 'check-up',
  ],
  AlloBotIntent.dueDate: [
    'due date', 'edd', 'when is my delivery', 'when will i deliver',
    'when is baby coming', 'when is the baby due', 'how long left',
    'how many days left', 'days to go', 'delivery date',
  ],
  AlloBotIntent.gestationalStatus: [
    'how many weeks', 'which week', 'what week', 'how far along',
    'how many months pregnant', 'which month', 'my pregnancy week',
    'how is my baby', 'how is baby doing', 'baby size', 'baby growth now',
    'which trimester', 'my trimester', 'how many days pregnant',
  ],
  AlloBotIntent.waterIntake: [
    'how much water', 'water intake', 'drank water', 'drink water',
    'water today', 'glasses of water', 'hydration', 'hydrated',
  ],
  AlloBotIntent.kickCount: [
    'kick count', 'count kicks', 'kick counter', 'counting kicks',
    'baby kicking', 'baby kicks', 'fetal movement', 'baby movement',
    'kicks today', 'is kicking',
  ],
  AlloBotIntent.weight: [
    'my weight', 'weight gain', 'how much weight', 'gained weight',
    'weight today', 'am i gaining', 'weigh',
  ],
  AlloBotIntent.bloodPressure: [
    'blood pressure', 'my bp', 'bp reading', 'bp today', 'is my bp',
  ],
  AlloBotIntent.vaccination: [
    'vaccine', 'vaccination', 'tt injection', 'tetanus', 'tdap',
    'flu shot', 'immunisation', 'immunization', 'injection due',
  ],
  AlloBotIntent.labReport: [
    'lab test', 'lab tests', 'blood test', 'blood tests', 'urine test',
    'my tests', 'which tests', 'what tests', 'test due', 'tests due',
    'my scan', 'scan due', 'ultrasound', 'usg', 'my reports',
    'report pending', 'reports pending', 'cbc', 'hemoglobin test',
    'sugar test', 'test results', 'my results', 'anomaly scan',
  ],
  AlloBotIntent.todayCare: [
    'today care', "today's care", 'my care today', 'what should i do today',
    'what is left today', 'my tasks', 'my routine', 'care plan today',
    'anything pending', 'what is pending', 'my checklist',
  ],
  AlloBotIntent.medication: [
    'my medicine', 'my medicines', 'my tablets', 'prescription',
    'iron tablet', 'calcium tablet', 'folic acid tablet', 'my dose',
    'when to take medicine', 'medicine reminder',
  ],
};

const List<String> _greetings = [
  'hello', 'hi', 'hey', 'good morning', 'good afternoon', 'good evening',
  'vanakkam', 'namaste', 'namaskar', 'how are you', 'are you there',
];

const List<String> _gratitudes = [
  'thank you', 'thanks', 'thank u', 'nandri', 'dhanyavad', 'shukriya',
  'thank you so much', 'grateful',
];

const List<String> _affirmations = [
  'yes', 'yes please', 'yeah', 'yep', 'ok', 'okay', 'sure', 'tell me',
  'tell me more', 'go on', 'please tell', 'i want to know', 'yes tell me',
  'aama', 'haan', 'ho', 'ha',
];

const List<String> _negations = [
  'no', 'no thanks', 'not now', 'later', 'nope', 'no need', 'illa', 'nahi',
];

/// Lowercases and strips punctuation so phrase matching is stable.
String normalizeQuery(String query) => query
    .toLowerCase()
    .replaceAll('’', "'")
    .replaceAll(RegExp(r"[^a-z0-9'\s\p{L}]", unicode: true), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Whether [normalized] contains [phrase] as whole words.
///
/// Substring matching would fire "bp" inside "abpm" and "no" inside "nose",
/// which for the red-flag list would be actively harmful.
bool containsPhrase(String normalized, String phrase) {
  if (phrase.isEmpty) return false;
  final pattern = RegExp(
    r'(?<![\p{L}\p{N}])' + RegExp.escape(phrase) + r'(?![\p{L}\p{N}])',
    unicode: true,
  );
  return pattern.hasMatch(normalized);
}

/// The first danger sign [query] mentions, or null.
RedFlag? detectRedFlag(String query) {
  final normalized = normalizeQuery(query);
  if (normalized.isEmpty) return null;

  // "Is spotting normal?" and "will bleeding happen later" are questions about
  // a symptom, not reports of one. Escalating those would train mothers to
  // ignore the escalation, so hypothetical framings are excluded.
  if (_isHypothetical(normalized)) return null;

  for (final flag in redFlags) {
    for (final phrase in flag.phrases) {
      if (containsPhrase(normalized, phrase)) return flag;
    }
  }
  return null;
}

/// Framings that discuss a symptom rather than report it.
bool _isHypothetical(String normalized) {
  const hypotheticals = [
    'is it normal', 'is that normal', 'is this normal', 'what causes',
    'what if', 'can i get', 'why does', 'why do', 'what are the signs',
    'what are signs', 'list of', 'tell me about', 'what should i know about',
    'is it common', 'does everyone',
  ];
  // A hypothetical framing only overrides when she is not also saying it is
  // happening now.
  const happeningNow = [
    'i have', 'i am having', 'i m having', 'im having', 'i feel', 'i am feeling',
    'right now', 'since morning', 'my baby', 'help me', 'started',
  ];
  if (happeningNow.any((phrase) => containsPhrase(normalized, phrase))) {
    return false;
  }
  return hypotheticals.any((phrase) => containsPhrase(normalized, phrase));
}

/// Classifies [query].
///
/// Red flags are checked first and unconditionally. Context intents are then
/// matched by longest phrase, so a query mentioning two topics resolves to the
/// more specific one. Everything unmatched becomes
/// [AlloBotIntent.knowledge] and goes to retrieval.
IntentMatch classifyIntent(String query) {
  final normalized = normalizeQuery(query);
  if (normalized.isEmpty) {
    return const IntentMatch(intent: AlloBotIntent.knowledge, matchedPhrase: '');
  }

  final flag = detectRedFlag(query);
  if (flag != null) {
    return IntentMatch(
      intent: AlloBotIntent.emergency,
      matchedPhrase: flag.label,
      redFlag: flag,
    );
  }

  AlloBotIntent? bestIntent;
  var bestPhrase = '';
  _intentPhrases.forEach((intent, phrases) {
    for (final phrase in phrases) {
      if (!containsPhrase(normalized, phrase)) continue;
      if (phrase.length > bestPhrase.length) {
        bestPhrase = phrase;
        bestIntent = intent;
      }
    }
  });
  if (bestIntent != null) {
    return IntentMatch(intent: bestIntent!, matchedPhrase: bestPhrase);
  }

  // Short conversational turns only. "yes" alone accepts a follow-up; "yes I
  // have swelling in week 24" is a real question and must reach retrieval.
  final wordCount = normalized.split(' ').length;
  if (wordCount <= 4) {
    for (final phrase in _affirmations) {
      if (containsPhrase(normalized, phrase)) {
        return IntentMatch(
          intent: AlloBotIntent.affirmation,
          matchedPhrase: phrase,
        );
      }
    }
    for (final phrase in _negations) {
      if (containsPhrase(normalized, phrase)) {
        return IntentMatch(intent: AlloBotIntent.negation, matchedPhrase: phrase);
      }
    }
  }

  for (final phrase in _gratitudes) {
    if (containsPhrase(normalized, phrase)) {
      return IntentMatch(intent: AlloBotIntent.gratitude, matchedPhrase: phrase);
    }
  }
  if (wordCount <= 5) {
    for (final phrase in _greetings) {
      if (containsPhrase(normalized, phrase)) {
        return IntentMatch(intent: AlloBotIntent.greeting, matchedPhrase: phrase);
      }
    }
  }

  return IntentMatch(intent: AlloBotIntent.knowledge, matchedPhrase: normalized);
}
