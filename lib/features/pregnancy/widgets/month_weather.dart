import 'package:flutter/material.dart';
import 'package:allomom/config/app_theme.dart';

/// The weather a calendar month brings in India, by the Met Department's
/// four seasons: winter (Dec–Feb), summer (Mar–May), the southwest monsoon
/// (Jun–Sep) and the post-monsoon (Oct–Nov) — for dressing a card set in
/// that month. Tamil Nadu and Puducherry get their northeast-monsoon rains in
/// Oct–Dec instead.
class MonthWeather {
  const MonthWeather(this.emoji, this.from, this.to, this.accent);

  final String emoji;

  /// The light-mode wash, from the top-right corner to the bottom-left.
  final Color from;
  final Color to;

  /// Tints the wash in dark mode.
  final Color accent;

  /// The weather for [month] (1–12) where [pincode] is; all-India when the
  /// pincode is empty or elsewhere.
  static MonthWeather of(int month, {String pincode = ''}) {
    final m = (month - 1) % 12 + 1;
    if (_northeastMonsoon(pincode)) {
      final rains = _northeastRains[m];
      if (rains != null) return rains;
    }
    return _months[m - 1];
  }

  /// Tamil Nadu and Puducherry: pincodes 60xxxx–64xxxx.
  static bool _northeastMonsoon(String pincode) {
    final code = pincode.trim();
    if (code.length != 6) return false;
    final zone = int.tryParse(code.substring(0, 2));
    return zone != null && zone >= 60 && zone <= 64;
  }

  /// A soft wash with the month's emoji tucked large and faint into the
  /// right edge, painted behind a card's content.
  Widget backdrop(BuildContext context) {
    final p = context.palette;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: p.isDark
                    ? [accent.withValues(alpha: 0.22), p.card]
                    : [from, to],
              ),
            ),
          ),
        ),
        Positioned(
          right: -14,
          top: 34,
          child: Opacity(
            opacity: p.isDark ? 0.22 : 0.30,
            child: Text(emoji, style: const TextStyle(fontSize: 76)),
          ),
        ),
      ],
    );
  }

  static const _months = <MonthWeather>[
    // Jan — winter: cold, foggy mornings in the north.
    MonthWeather(
      '🌫️',
      Color(0xFFE6ECF3),
      Color(0xFFFFFFFF),
      Color(0xFF94A3B8),
    ),
    // Feb — winter easing into Vasant, mild and bright.
    MonthWeather('🌼', Color(0xFFFFF3D1), Color(0xFFFFFFFF), Color(0xFFEAB308)),
    // Mar — summer begins, days warming up.
    MonthWeather(
      '🌤️',
      Color(0xFFFFF1DA),
      Color(0xFFFFFFFF),
      Color(0xFFFBBF24),
    ),
    // Apr — hot, dry summer.
    MonthWeather('☀️', Color(0xFFFFE6C2), Color(0xFFFFFFFF), Color(0xFFF59E0B)),
    // May — peak heat and loo winds.
    MonthWeather('🥵', Color(0xFFFFDCC8), Color(0xFFFFFFFF), Color(0xFFF97316)),
    // Jun — the southwest monsoon sets in over Kerala and moves north.
    MonthWeather(
      '🌦️',
      Color(0xFFDDF4F1),
      Color(0xFFFFFFFF),
      Color(0xFF14B8A6),
    ),
    // Jul — the monsoon at its peak across the country.
    MonthWeather(
      '🌧️',
      Color(0xFFDCEBFA),
      Color(0xFFFFFFFF),
      Color(0xFF3B82F6),
    ),
    // Aug — heavy rain and thunderstorms.
    MonthWeather('⛈️', Color(0xFFE2E4FA), Color(0xFFFFFFFF), Color(0xFF6366F1)),
    // Sep — the monsoon withdraws; green and fresh.
    MonthWeather('🌈', Color(0xFFE3F6E3), Color(0xFFFFFFFF), Color(0xFF22C55E)),
    // Oct — post-monsoon: clear skies, festive season.
    MonthWeather('⛅', Color(0xFFFFEFD9), Color(0xFFFFFFFF), Color(0xFFF59E0B)),
    // Nov — cooling, with haze settling in.
    MonthWeather(
      '🌫️',
      Color(0xFFEDE9F6),
      Color(0xFFFFFFFF),
      Color(0xFFA78BFA),
    ),
    // Dec — winter: cold waves in the north.
    MonthWeather('❄️', Color(0xFFE3F0FF), Color(0xFFFFFFFF), Color(0xFF60A5FA)),
  ];

  /// Tamil Nadu and Puducherry's rainy season, from the northeast monsoon.
  static const _northeastRains = <int, MonthWeather>{
    // Oct — the northeast monsoon sets in.
    10: MonthWeather(
      '🌦️',
      Color(0xFFDDF4F1),
      Color(0xFFFFFFFF),
      Color(0xFF14B8A6),
    ),
    // Nov — its heaviest rain.
    11: MonthWeather(
      '🌧️',
      Color(0xFFDCEBFA),
      Color(0xFFFFFFFF),
      Color(0xFF3B82F6),
    ),
    // Dec — rain and cyclones from the Bay of Bengal.
    12: MonthWeather(
      '⛈️',
      Color(0xFFE2E4FA),
      Color(0xFFFFFFFF),
      Color(0xFF6366F1),
    ),
  };
}
