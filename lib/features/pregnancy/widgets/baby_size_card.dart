import 'package:flutter/material.dart';
import 'package:allomom/config/app_theme.dart';

/// How big the baby is this week: what it is the size of, a line in the
/// baby's own voice, then the typical weight and length.
class BabySizeCard extends StatelessWidget {
  const BabySizeCard({super.key, required this.gestationalWeek});

  /// Completed weeks, as `MainController.currentGestationalWeek` counts them.
  final int gestationalWeek;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ink = p.pick(const Color(0xFF1E2024), p.textPrimary);
    final inkSoft = p.pick(const Color(0xFF6B707B), p.textSecondary);
    final hair = p.pick(const Color(0xFFEDE8E1), p.border);
    final size = BabySize.forWeek(gestationalWeek);
    final week = gestationalWeek.clamp(1, 40);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: p.pick(const Color(0xFFFBF8F4), p.card),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hair, width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.pick(Colors.white, p.surface),
                  shape: BoxShape.circle,
                ),
                child: Text(size.emoji, style: const TextStyle(fontSize: 38)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WEEK $week',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: const Color(0xFFFF3B5C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${size.name} Sized Baby',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      size.line,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, thickness: 1, color: hair),
          const SizedBox(height: 10),
          _measure(
            icon: Icons.monitor_weight_outlined,
            label: 'Ideal Weight',
            value: size.weight,
            ink: ink,
            inkSoft: inkSoft,
          ),
          const SizedBox(height: 8),
          _measure(
            icon: Icons.straighten_rounded,
            label: 'Ideal Height',
            value: size.length,
            ink: ink,
            inkSoft: inkSoft,
          ),
        ],
      ),
    );
  }

  Widget _measure({
    required IconData icon,
    required String label,
    required String value,
    required Color ink,
    required Color inkSoft,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: inkSoft),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 14, color: inkSoft)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
      ],
    );
  }
}

/// The baby's size for one week of pregnancy.
class BabySize {
  const BabySize(this.name, this.emoji, this.weight, this.length, this.line);

  final String name;
  final String emoji;
  final String weight;
  final String length;
  final String line;

  /// The size at [week]; weeks before 4 show the poppy seed, weeks past 40
  /// stay at 40.
  static BabySize forWeek(int week) => _weeks[week.clamp(4, 40) - 4];

  static const _weeks = <BabySize>[
    BabySize('Poppy Seed', '🌱', '<1 g', '1 - 2 mm',
        'I have become a zygote — a fertilized egg made up of 32 cells, about the size of a poppy seed.'),
    BabySize('Sesame Seed', '🌱', '<1 g', '2 - 3 mm',
        'My tiny heart has started to form, and soon it will begin to beat.'),
    BabySize('Lentil', '🫘', '<1 g', '4 - 6 mm',
        'My heart is beating now, and buds for my arms and legs are appearing.'),
    BabySize('Blueberry', '🫐', '<1 g', '1 cm',
        'My brain is growing fast, and my little face is starting to take shape.'),
    BabySize('Kidney Bean', '🫘', '1 g', '1.6 cm',
        'My fingers and toes are forming, and I am starting to move around.'),
    BabySize('Grape', '🍇', '2 g', '2.3 cm',
        'All my major organs have begun to form, and my tail is almost gone.'),
    BabySize('Strawberry', '🍓', '4 g', '3.1 cm',
        'I am officially a fetus now! My tiny nails and teeth buds are forming.'),
    BabySize('Lime', '🍋', '7 g', '4.1 cm',
        'I can open and close my fists, and my bones are starting to harden.'),
    BabySize('Plum', '🍑', '14 g', '5.4 cm',
        'My reflexes are developing — I can curl my toes and even suck my thumb.'),
    BabySize('Peach', '🍑', '23 g', '7.4 cm',
        'My fingerprints are forming, and my vocal cords are developing.'),
    BabySize('Lemon', '🍋', '43 g', '8.7 cm',
        'I can make faces now — squinting, frowning and maybe even smiling.'),
    BabySize('Apple', '🍎', '70 g', '10.1 cm',
        'I can sense light through my eyelids, and my legs are getting longer.'),
    BabySize('Avocado', '🥑', '100 g', '11.6 cm',
        'My heart pumps about 25 litres of blood a day, and I can hear you.'),
    BabySize('Pear', '🍐', '140 g', '13 cm',
        'I am storing fat to keep warm, and my skeleton is turning to bone.'),
    BabySize('Bell Pepper', '🫑', '190 g', '14.2 cm',
        'You may start feeling my flutters soon — that is me stretching!'),
    BabySize('Mango', '🥭', '240 g', '15.3 cm',
        'A protective coating called vernix is covering my delicate skin.'),
    BabySize('Banana', '🍌', '300 g', '25.6 cm',
        'Halfway there! I can swallow now and I am practising my kicks.'),
    BabySize('Carrot', '🥕', '360 g', '26.7 cm',
        'My eyebrows and eyelids are in place, and I taste what you eat.'),
    BabySize('Coconut', '🥥', '430 g', '27.8 cm',
        'My sense of touch is developing, and I love grasping my cord.'),
    BabySize('Grapefruit', '🍊', '500 g', '28.9 cm',
        'I can hear your heartbeat and your voice clearly now.'),
    BabySize('Corn', '🌽', '600 g', '30 cm',
        'My lungs are developing the branches they will need to breathe.'),
    BabySize('Cauliflower', '🥦', '660 g', '34.6 cm',
        'My nostrils are opening, and I am putting on more baby fat.'),
    BabySize('Lettuce', '🥬', '760 g', '35.6 cm',
        'My eyes are about to open, and I respond to sounds around you.'),
    BabySize('Broccoli', '🥦', '875 g', '36.6 cm',
        'I sleep and wake on a schedule now, and I may even have hiccups.'),
    BabySize('Eggplant', '🍆', '1 kg', '37.6 cm',
        'I can blink, and I might be dreaming during my sleep.'),
    BabySize('Butternut Squash', '🎃', '1.2 kg', '38.6 cm',
        'My muscles and lungs keep maturing, and my head is growing to fit my brain.'),
    BabySize('Cabbage', '🥬', '1.3 kg', '39.9 cm',
        'My brain is getting wrinkly, and my bone marrow makes red blood cells.'),
    BabySize('Pineapple', '🍍', '1.5 kg', '41.1 cm',
        'I can turn my head from side to side and follow light.'),
    BabySize('Sweet Potato', '🍠', '1.7 kg', '42.4 cm',
        'My toenails have grown in, and I am practising breathing.'),
    BabySize('Durian', '🍈', '1.9 kg', '43.7 cm',
        'My bones are hardening, but my skull stays soft for birth.'),
    BabySize('Cantaloupe', '🍈', '2.1 kg', '45 cm',
        'My central nervous system is maturing, and my lungs are nearly ready.'),
    BabySize('Honeydew', '🍈', '2.4 kg', '46.2 cm',
        'There is less room to move now, so my kicks may feel like rolls.'),
    BabySize('Papaya', '🥭', '2.6 kg', '47.4 cm',
        'I am shedding my soft body hair, and I may drop lower soon.'),
    BabySize('Winter Melon', '🍉', '2.9 kg', '48.6 cm',
        'I am considered early term now — practising sucking and gripping.'),
    BabySize('Pumpkin', '🎃', '3.1 kg', '49.8 cm',
        'My organs are ready for life outside, and I am just gaining weight.'),
    BabySize('Watermelon', '🍉', '3.3 kg', '50.7 cm',
        'I am full term! My brain and lungs are still fine-tuning.'),
    BabySize('Jackfruit', '🍉', '3.5 kg', '51.2 cm',
        'I am ready to meet you any day now — see you very soon!'),
  ];
}
