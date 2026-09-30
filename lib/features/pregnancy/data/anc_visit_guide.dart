/// What an ANC check-up in each month of pregnancy looks at — the baby's
/// growth and health first, then hers — for the check-up's detail sheet.
abstract final class AncVisitGuide {
  /// The guide for pregnancy [month] (1–9); months past 9 stay at 9.
  static String forMonth(int month) => _months[month.clamp(1, 9) - 1];

  static const _months = <String>[
    // Month 1
    'Confirms your pregnancy and checks that it is growing in the womb. '
        'Your blood pressure, weight and haemoglobin are recorded as a '
        'starting point, and folic acid is started for your baby\'s brain and '
        'spine.',
    // Month 2
    'The dating scan shows your baby\'s first heartbeat, confirms your due '
        'date and whether there is more than one baby. Blood and urine tests '
        'check your blood group, sugar, thyroid and infections.',
    // Month 3
    'The NT scan and double-marker test screen your baby for chromosome '
        'conditions such as Down syndrome, and check that the early organs and '
        'heartbeat are developing well.',
    // Month 4
    'Your baby\'s heartbeat is heard on the Doppler and your womb is measured '
        'to see that your baby is growing. You get your Td vaccine and start '
        'iron and calcium.',
    // Month 5
    'The anomaly scan checks your baby\'s brain, heart, spine, kidneys and '
        'limbs, along with the placenta and the fluid around your baby. It is '
        'the most detailed look at how your baby is forming.',
    // Month 6
    'A glucose test checks for pregnancy diabetes, which can make your baby '
        'grow too big. Your belly is measured to track your baby\'s growth, '
        'and your haemoglobin is checked again.',
    // Month 7
    'Your baby\'s growth and heartbeat are checked, and you learn to count '
        'your baby\'s kicks. Your blood pressure, swelling and urine are '
        'watched closely for signs of pre-eclampsia.',
    // Month 8
    'A growth scan estimates your baby\'s weight and checks their position, '
        'the placenta and the fluid around them. Your blood pressure and '
        'haemoglobin are checked, and you start planning the birth.',
    // Month 9
    'Checks that your baby is head-down and their heartbeat is strong, often '
        'with a heart-rate trace. Your doctor confirms your baby is ready for '
        'birth and goes over the signs of labour with you.',
  ];
}
