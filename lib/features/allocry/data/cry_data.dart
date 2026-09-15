import 'package:flutter/material.dart';

/// What AlloCry can tell a mother about each kind of cry.
///
/// The classifier names one of these six; everything shown after a reading —
/// the illustration, the explanation, the things to try — comes from here.
class CryType {
  /// The key the classifier and the `cry` vital both use, e.g. "Hunger Cry".
  final String id;

  /// Title shown to the mother, e.g. "Hunger Crying".
  final String heading;

  /// One-line summary for cards and history rows.
  final String shortDescription;

  /// Illustration for this cry.
  final String image;

  /// A sample recording of this cry, so she can compare with her own baby.
  final String? sampleAudio;

  /// Emoji used where an illustration would be too heavy.
  final String emoji;

  /// What this cry sounds like and what else the baby tends to do, as
  /// (emphasised, text) pairs.
  final List<CryDescriptionLine> description;

  /// What to do about it.
  final List<String> recommendations;

  /// Accent for this cry throughout the feature.
  final Color color;

  /// Icon used in history rows and result sheets.
  final IconData icon;

  const CryType({
    required this.id,
    required this.heading,
    required this.shortDescription,
    required this.image,
    required this.sampleAudio,
    required this.emoji,
    required this.description,
    required this.recommendations,
    required this.color,
    required this.icon,
  });
}

class CryDescriptionLine {
  final bool bold;
  final String text;

  const CryDescriptionLine(this.bold, this.text);
}

/// The six cries AlloCry knows, keyed by the id the model produces.
///
/// Only five are ever predicted — the classifier has no "Attention Cry" class —
/// but the sixth is kept so the mother can read about it from the home grid,
/// exactly as AlloBaby presents it.
class CryTypes {
  const CryTypes._();

  static const Color _pink = Color(0xFFFF4E6A);

  static const Map<String, CryType> all = {
    'Hunger Cry': CryType(
      id: 'Hunger Cry',
      heading: 'Hunger Crying',
      shortDescription:
          "Rhythmic, repetitive cries that grow louder if the baby isn't fed. "
          'Often accompanied by hand-sucking and rooting behavior.',
      image: 'assets/babyicons/hc.webp',
      sampleAudio: 'cry_samples/hungry.wav',
      emoji: '🍼',
      color: _pink,
      icon: Icons.restaurant_rounded,
      description: [
        CryDescriptionLine(true,
            "Hunger cries are rhythmic, repetitive, and grow louder if the baby isn't fed."),
        CryDescriptionLine(true, 'Babies may also:'),
        CryDescriptionLine(false, 'Suck on hands or fingers'),
        CryDescriptionLine(
            false, 'Smack lips, root (turn head searching for a nipple)'),
        CryDescriptionLine(false, 'Get fussy even after being comforted'),
      ],
      recommendations: [
        'Feed promptly — responding early prevents excessive crying and makes feeding easier.',
        'Watch for hunger cues — crying is a late sign; look for lip-smacking, rooting, sticking out the tongue, or sucking on hands.',
        'Ensure a proper latch — if breastfeeding, a deep latch avoids discomfort.',
        'Check the feeding schedule — newborns need feeding every 2-3 hours.',
        'Burp baby after feeding — helps prevent gas and fussiness.',
      ],
    ),
    'Sleepy Cry': CryType(
      id: 'Sleepy Cry',
      heading: 'Sleepy Crying',
      shortDescription:
          'A whiny, nasal cry that sounds weaker than a hunger cry, often '
          'accompanied by yawning and eye-rubbing.',
      image: 'assets/babyicons/sc.webp',
      sampleAudio: 'cry_samples/sleepy.wav',
      emoji: '😴',
      color: Color(0xFF7E57C2),
      icon: Icons.nightlight_round,
      description: [
        CryDescriptionLine(
            true, 'A whiny, nasal cry that may sound weaker than a hunger cry.'),
        CryDescriptionLine(true, 'Babies may also:'),
        CryDescriptionLine(false, 'Yawn frequently'),
        CryDescriptionLine(false, 'Rub their eyes or pull their ears'),
        CryDescriptionLine(false, 'Become fussy and harder to soothe'),
      ],
      recommendations: [
        'Look for sleep cues early — yawning, zoning out, or rubbing eyes signal it is time to sleep.',
        'Create a calm sleep environment — dim lights, reduce noise, and use white noise if needed.',
        'Use gentle rocking — motion, swaddling, or a pacifier can help.',
        'Follow a sleep routine — a consistent bedtime routine helps babies recognise sleep time.',
        'Avoid overstimulation — too much activity before bed makes sleep harder.',
      ],
    ),
    'Pain Cry': CryType(
      id: 'Pain Cry',
      heading: 'Pain Crying',
      shortDescription:
          'A sudden, high-pitched, intense cry that comes in bursts with '
          'breathing pauses. Often accompanied by physical tension.',
      image: 'assets/babyicons/pc.webp',
      sampleAudio: 'cry_samples/pain.wav',
      emoji: '😢',
      color: Color(0xFFE53935),
      icon: Icons.healing_rounded,
      description: [
        CryDescriptionLine(true,
            'A sudden, high-pitched, intense cry that may come in bursts with pauses for breath.'),
        CryDescriptionLine(true, 'Babies may also:'),
        CryDescriptionLine(false, 'Clench fists or arch their back'),
        CryDescriptionLine(false, 'Become stiff or tense'),
        CryDescriptionLine(false,
            'Show signs of discomfort (scrunched face, difficulty calming down)'),
      ],
      recommendations: [
        'Check for obvious issues — diaper rash, teething pain, or tight clothing.',
        'Soothe with gentle touch — skin-to-skin contact or holding them close can help.',
        'Try pain relief techniques — a chilled teether for teething, a tummy massage for gas.',
        'Monitor for fever or illness — if crying persists with fever, vomiting, or lethargy, consult a doctor.',
        'Trust your instincts — if the baby seems in severe pain, seek medical advice immediately.',
      ],
    ),
    'Discomfort Cry': CryType(
      id: 'Discomfort Cry',
      heading: 'Discomfort Crying',
      shortDescription:
          'A fussy, irritated cry that typically stops when the source of '
          'discomfort is addressed.',
      image: 'assets/babyicons/dc.webp',
      sampleAudio: 'cry_samples/discomfort.wav',
      emoji: '😣',
      color: Color(0xFFFF9800),
      icon: Icons.sentiment_dissatisfied_rounded,
      description: [
        CryDescriptionLine(
            true, 'A fussy, irritated cry that may stop when the issue is resolved.'),
        CryDescriptionLine(true, 'Babies may also:'),
        CryDescriptionLine(false, 'Wiggle or squirm a lot'),
        CryDescriptionLine(false, 'Tug at their clothing or ears'),
        CryDescriptionLine(false, 'Appear restless or uneasy'),
      ],
      recommendations: [
        'Check the diaper — a wet or soiled diaper is a common cause of discomfort.',
        'Ensure comfortable clothing — soft, breathable fabrics, nothing too tight.',
        "Adjust temperature — feel baby's neck or back to see if they are too hot or cold.",
        'Check for external irritants — tags, rough fabric, or hair wrapped around fingers and toes.',
        'Reposition baby — changing positions or holding them differently can help.',
      ],
    ),
    'Burping Cry': CryType(
      id: 'Burping Cry',
      heading: 'Burping Crying',
      shortDescription:
          'Prolonged, intense crying episodes, typically in the evening, with '
          'physical signs of distress.',
      image: 'assets/babyicons/cc.webp',
      sampleAudio: 'cry_samples/discomfort.wav',
      emoji: '🤕',
      color: Color(0xFF26A69A),
      icon: Icons.child_care_rounded,
      description: [
        CryDescriptionLine(true,
            'A prolonged, intense, high-pitched cry that often occurs in the evening.'),
        CryDescriptionLine(true, 'Babies may also:'),
        CryDescriptionLine(false, 'Clench fists, arch their back, or pull up legs'),
        CryDescriptionLine(false, 'Have a tense, bloated belly'),
        CryDescriptionLine(false, 'Be difficult to soothe, even after feeding'),
      ],
      recommendations: [
        "Use gentle motions — rocking, swaying, or a 'colic carry' (on their tummy along your forearm).",
        'Try white noise — rhythmic sounds, like a fan or a heartbeat, can be soothing.',
        'Burp baby well — gas buildup makes it worse. Burp frequently during feeds.',
        'Massage the tummy — a gentle circular tummy massage relieves gas.',
        'Consult a paediatrician — if it persists, ask about probiotic drops or diet changes.',
      ],
    ),
    'Attention Cry': CryType(
      id: 'Attention Cry',
      heading: 'Attention Crying',
      shortDescription:
          'A mild cry that starts softly and increases if ignored, often '
          'accompanied by eye contact and reaching out.',
      image: 'assets/babyicons/ac.webp',
      sampleAudio: null,
      emoji: '🤗',
      color: Color(0xFF3898EC),
      icon: Icons.favorite_rounded,
      description: [
        CryDescriptionLine(
            true, 'A mild, whimpering cry that starts softly and gets louder if ignored.'),
        CryDescriptionLine(true, 'Babies may also:'),
        CryDescriptionLine(false, 'Make eye contact while crying'),
        CryDescriptionLine(false, 'Reach out for comfort'),
        CryDescriptionLine(false, 'Stop crying quickly when picked up'),
      ],
      recommendations: [
        'Respond with reassurance — holding, talking, or making eye contact helps babies feel secure.',
        'Try gentle touch — a cuddle or a soft pat on the back can be calming.',
        'Engage with soothing sounds — humming or talking in a calm voice reassures the baby.',
        'Encourage independent comforting — allow baby to self-soothe briefly before responding.',
        'Maintain a balance — meeting attention needs matters, and consistency helps babies learn security.',
      ],
    ),
  };

  /// The order the home grid lists them in.
  static const List<String> gridOrder = [
    'Hunger Cry',
    'Sleepy Cry',
    'Burping Cry',
    'Discomfort Cry',
    'Pain Cry',
    'Attention Cry',
  ];

  static CryType? byId(String? id) => id == null ? null : all[id];

  /// Falls back to a neutral entry so an unrecognised id — an old record, a
  /// future model class — still renders a readable row instead of throwing.
  static CryType resolve(String? id) => all[id] ?? _unknown;

  static const CryType _unknown = CryType(
    id: 'Unknown Cry',
    heading: 'Crying',
    shortDescription: 'A cry AlloCry could not place into one of its types.',
    image: 'assets/babyicons/ac.webp',
    sampleAudio: null,
    emoji: '👶',
    color: _pink,
    icon: Icons.graphic_eq_rounded,
    description: [
      CryDescriptionLine(true, 'AlloCry could not match this cry to a type.'),
      CryDescriptionLine(false, 'Try recording again, closer to the baby.'),
    ],
    recommendations: [
      'Record again in a quieter place, holding the phone closer to the baby.',
      'Check the usual causes first: hunger, a wet diaper, tiredness, or gas.',
    ],
  );
}
