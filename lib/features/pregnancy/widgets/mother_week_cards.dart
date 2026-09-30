import 'package:flutter/material.dart';
import 'package:allomom/config/app_theme.dart';

/// This week for the mother: a line of encouragement, how she might feel
/// with a tip, and what to eat and drink — three cards stacked above the
/// train, under the baby's size.
class MotherWeekCards extends StatelessWidget {
  const MotherWeekCards({super.key, required this.gestationalWeek});

  /// Completed weeks, as `MainController.currentGestationalWeek` counts them.
  final int gestationalWeek;

  static const _rose = Color(0xFFE8606A);
  static const _leaf = Color(0xFF5DAE5A);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ink = p.pick(const Color(0xFF1E2024), p.textPrimary);
    final inkSoft = p.pick(const Color(0xFF6B707B), p.textSecondary);
    final week = MotherWeek.forWeek(gestationalWeek);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(
          context,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 20, color: _rose),
                const SizedBox(width: 8),
                const Text(
                  "MOTHER'S INSIGHT",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                    color: _rose,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              week.insight,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _card(
          context,
          children: [
            _heading(
              icon: const Icon(Icons.favorite_rounded, size: 26, color: _rose),
              title: 'How You Might Feel',
              ink: ink,
            ),
            const SizedBox(height: 10),
            for (final line in week.feelings)
              _bullet(text: Text(line), dot: _rose, inkSoft: inkSoft),
          ],
        ),
        const SizedBox(height: 14),
        _card(
          context,
          children: [
            _heading(
              icon: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: _leaf,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              title: 'Nutrition Focus',
              ink: ink,
            ),
            const SizedBox(height: 10),
            _bullet(
              text: _labelled('PROTEIN', week.protein),
              dot: _leaf,
              inkSoft: inkSoft,
            ),
            _bullet(
              text: _labelled('HYDRATION', week.hydration),
              dot: _leaf,
              inkSoft: inkSoft,
            ),
          ],
        ),
      ],
    );
  }

  /// A rounded card with a faint circle tucked into its top-right corner.
  Widget _card(BuildContext context, {required List<Widget> children}) {
    final p = context.palette;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.pick(Colors.white, p.card),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: p.pick(const Color(0xFFF0EBE6), p.border),
          width: 1.1,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -50,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.pick(
                  const Color(0xFFFBF6F4),
                  Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heading({
    required Widget icon,
    required String title,
    required Color ink,
  }) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _bullet({
    required Widget text,
    required Color dot,
    required Color inkSoft,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 7, right: 12),
            decoration: BoxDecoration(
              color: dot.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: DefaultTextStyle.merge(
              style: TextStyle(fontSize: 14, height: 1.45, color: inkSoft),
              child: text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _labelled(String label, String value) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

/// What one week of pregnancy holds for the mother.
class MotherWeek {
  const MotherWeek(this.insight, this.feelings, this.protein, this.hydration);

  final String insight;

  /// How she might feel, ending with a tip.
  final List<String> feelings;

  final String protein;
  final String hydration;

  /// The week at [week]; weeks before 4 show week 4, weeks past 40 stay at
  /// 40 — the same range as `BabySize`.
  static MotherWeek forWeek(int week) => _weeks[week.clamp(4, 40) - 4];

  static const _weeks = <MotherWeek>[
    // Week 4
    MotherWeek(
      'Your body has quietly begun its most important work. Be gentle with yourself 🌷',
      ['A missed period and mild cramps', 'Tip: Start folic acid every day 💊'],
      'Moong dal 🫘',
      'Warm water 💧',
    ),
    // Week 5
    MotherWeek(
      'A tiny heart is forming inside you. You are already a mother ❤️',
      ['Tender breasts and tiredness 😴', 'Tip: Rest whenever you can 🛏️'],
      'Boiled eggs 🥚',
      'Lemon water 🍋',
    ),
    // Week 6
    MotherWeek(
      'Feeling tired means your body is building a home. Slow down, Amma 🏡',
      ['Morning sickness may begin 🤢', 'Tip: Eat small meals often 🍽️'],
      'Curd 🥛',
      'Ginger water 🫚',
    ),
    // Week 7
    MotherWeek(
      'Every small meal you keep down is a gift to your baby 🎁',
      ['Nausea and food aversions', 'Tip: Keep plain biscuits by your bed 🍪'],
      'Paneer 🧀',
      'Buttermilk 🥛',
    ),
    // Week 8
    MotherWeek(
      'Mood swings are normal — your hormones are working hard for two 🌈',
      ['Emotional ups and downs 🎭', 'Tip: Share your feelings with family 🤗'],
      'Chana 🫘',
      'Coconut water 🥥',
    ),
    // Week 9
    MotherWeek(
      'Your baby is growing fast, and so is your strength 💪',
      ['Frequent urination 🚻', 'Tip: Do not cut down on water 💧'],
      'Rajma 🫘',
      'Warm water 💧',
    ),
    // Week 10
    MotherWeek(
      'You are doing beautifully, even on the hard days 🌸',
      ['Bloating and mild headaches', 'Tip: Take short, gentle walks 🚶‍♀️'],
      'Soya chunks 🌱',
      'Jeera water 🌿',
    ),
    // Week 11
    MotherWeek(
      'The first trimester is almost behind you. Be proud of yourself 🏅',
      ['Nausea may start easing 😌', 'Tip: Book your first-trimester scan 🩺'],
      'Toor dal 🫘',
      'Lemon water 🍋',
    ),
    // Week 12
    MotherWeek(
      'You made it through the first trimester — what a journey already! 🎉',
      ['More energy returning ⚡', 'Tip: Start iron and calcium as advised 💊'],
      'Eggs 🥚',
      'Coconut water 🥥',
    ),
    // Week 13
    MotherWeek(
      'Welcome to the second trimester — often the most comfortable one 🌼',
      ['Feeling brighter and hungrier 😋', 'Tip: Choose healthy snacks 🥜'],
      'Peanuts 🥜',
      'Buttermilk 🥛',
    ),
    // Week 14
    MotherWeek(
      'Your glow is real — your body is blooming with life ✨',
      ['A small bump may show 🤰', 'Tip: Wear loose, comfortable clothes 👗'],
      'Fish 🐟',
      'Warm water 💧',
    ),
    // Week 15
    MotherWeek(
      'Talk to your baby — they will soon hear your voice 🗣️',
      [
        'Stuffy nose or bleeding gums',
        'Tip: Brush gently with a soft brush 🪥',
      ],
      'Paneer 🧀',
      'Tender coconut water 🥥',
    ),
    // Week 16
    MotherWeek(
      'Your love is already shaping your little one 💞',
      ['Backaches may begin', 'Tip: Sleep on your side with a pillow 🛌'],
      'Sprouts 🌱',
      'Fresh fruit juice 🍊',
    ),
    // Week 17
    MotherWeek(
      'Your body is making room for two hearts 💗',
      ['Increased appetite 🍛', 'Tip: Add greens to every meal 🥬'],
      'Moong dal 🫘',
      'Buttermilk 🥛',
    ),
    // Week 18
    MotherWeek(
      'The first flutters are near — a moment you will never forget 🦋',
      [
        'Light flutters in your tummy',
        'Tip: Rest your feet up in the evening 🦶',
      ],
      'Curd 🥛',
      'Coconut water 🥥',
    ),
    // Week 19
    MotherWeek(
      'You are halfway to meeting your baby. Keep going, Amma 🌻',
      [
        'Dizziness when standing up quickly',
        'Tip: Rise slowly and stay hydrated 💧',
      ],
      'Chicken 🍗',
      'Warm water 💧',
    ),
    // Week 20
    MotherWeek(
      'Halfway there! Every kick is your baby saying hello 👋',
      ['Joy as you feel baby move 🥰', 'Tip: Keep your anomaly scan date 🩺'],
      'Rajma 🫘',
      'Lemon water 🍋',
    ),
    // Week 21
    MotherWeek(
      'Your baby tastes what you eat — make it colourful 🌈',
      ['Leg cramps at night', 'Tip: Stretch your calves before bed 🧘‍♀️'],
      'Ragi and dal 🌾',
      'Coconut water 🥥',
    ),
    // Week 22
    MotherWeek(
      'Every stretch mark is a story of love 💕',
      ['Itchy, stretching skin', 'Tip: Moisturise your belly daily 🧴'],
      'Eggs 🥚',
      'Buttermilk 🥛',
    ),
    // Week 23
    MotherWeek(
      'Your baby knows your heartbeat — it is their favourite song 🎵',
      ['Swollen feet and ankles 🦶', 'Tip: Avoid standing for too long 🪑'],
      'Paneer 🧀',
      'Warm water 💧',
    ),
    // Week 24
    MotherWeek(
      'You are stronger than you know, and your baby feels it 💪',
      [
        'Heartburn after meals 🔥',
        'Tip: Eat slowly and sit up after meals 🍽️',
      ],
      'Chana 🫘',
      'Tender coconut water 🥥',
    ),
    // Week 25
    MotherWeek(
      'Taking care of yourself is taking care of your baby 🤱',
      [
        'Trouble finding a comfy sleep position',
        'Tip: Use a pillow between your knees 🛌',
      ],
      'Fish 🐟',
      'Fresh fruit juice 🍊',
    ),
    // Week 26
    MotherWeek(
      'Your baby can hear you now — sing, read, and talk to them 📖',
      [
        'Braxton Hicks tightenings',
        'Tip: Rest and drink water when they come 💧',
      ],
      'Sprouts 🌱',
      'Coconut water 🥥',
    ),
    // Week 27
    MotherWeek(
      'The final trimester is close. You are doing wonderfully 🌟',
      [
        'Feeling heavier and slower',
        'Tip: Try prenatal yoga, if advised 🧘‍♀️',
      ],
      'Moong dal 🫘',
      'Buttermilk 🥛',
    ),
    // Week 28
    MotherWeek(
      'Welcome to the third trimester — the home stretch begins 🏁',
      ['Shortness of breath 😮‍💨', 'Tip: Start counting baby kicks daily 👣'],
      'Eggs 🥚',
      'Warm water 💧',
    ),
    // Week 29
    MotherWeek(
      'Every kick is a reminder: you are never alone 💞',
      ['Strong, frequent kicks 👣', 'Tip: Eat iron-rich foods for energy 🥬'],
      'Chicken 🍗',
      'Coconut water 🥥',
    ),
    // Week 30
    MotherWeek(
      'Your body knows exactly what to do. Trust it 🌿',
      ['Tiredness returns 😴', 'Tip: Nap in the afternoon if you can 🛏️'],
      'Rajma 🫘',
      'Lemon water 🍋',
    ),
    // Week 31
    MotherWeek(
      'Soon you will hold the little one you have carried with so much love 🤗',
      ['Back and hip aches', 'Tip: Warm compress on your lower back ♨️'],
      'Paneer 🧀',
      'Buttermilk 🥛',
    ),
    // Week 32
    MotherWeek(
      'It is okay to ask for help — you deserve care too 🙏',
      ['Needing the toilet more often 🚻', 'Tip: Pack your hospital bag 🎒'],
      'Fish 🐟',
      'Tender coconut water 🥥',
    ),
    // Week 33
    MotherWeek(
      'Your baby is getting ready, and so are you 🌸',
      [
        'Trouble sleeping at night 🌙',
        'Tip: Relax with slow, deep breaths 🌬️',
      ],
      'Ragi and dal 🌾',
      'Warm water 💧',
    ),
    // Week 34
    MotherWeek(
      'You have carried your baby so far with strength and love ❤️',
      [
        'Pelvic pressure as baby moves down',
        'Tip: Learn the signs of labour 📋',
      ],
      'Sprouts 🌱',
      'Coconut water 🥥',
    ),
    // Week 35
    MotherWeek(
      'Every day now is one day closer to meeting your baby 📅',
      [
        'Nesting urge to get things ready 🏠',
        'Tip: Do not overexert yourself 🛋️',
      ],
      'Eggs 🥚',
      'Fresh fruit juice 🍊',
    ),
    // Week 36
    MotherWeek(
      'You are nearly there. Your baby is so lucky to have you 🍀',
      [
        'Easier breathing as baby drops 😌',
        'Tip: Keep your doctor\'s number handy 📞',
      ],
      'Chana 🫘',
      'Buttermilk 🥛',
    ),
    // Week 37
    MotherWeek(
      'Full term is here — your baby could arrive any day now 👶',
      [
        'Excitement and some nerves 💓',
        'Tip: Rest well and stay close to home 🏡',
      ],
      'Moong dal 🫘',
      'Coconut water 🥥',
    ),
    // Week 38
    MotherWeek(
      'Breathe, Amma. You are ready for this beautiful moment 🌼',
      [
        'Restless and eager to meet baby',
        'Tip: Walk gently to stay active 🚶‍♀️',
      ],
      'Paneer 🧀',
      'Warm water 💧',
    ),
    // Week 39
    MotherWeek(
      'Your baby is ready to meet the one who loves them most — you 💖',
      ['Stronger tightenings 🌊', 'Tip: Time your contractions ⏱️'],
      'Curd 🥛',
      'Lemon water 🍋',
    ),
    // Week 40
    MotherWeek(
      'You have grown a whole human life. You are amazing! ❤️',
      [
        'Anticipation and excitement ⚡',
        'Tip: Trust your body and stay peaceful 🙏',
      ],
      'Dal 🫘',
      'Coconut water 🥥',
    ),
  ];
}
