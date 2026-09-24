import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/config/colors.dart' as brand show textMuted;

/// The surface and text colours that change between light and dark.
///
/// The brand colours in `colors.dart` stay the same in both modes; what flips
/// is everything drawn behind and around them. Read it with
/// `context.palette` so a widget follows the theme instead of hardcoding
/// `Colors.white`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color card;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color divider;
  final Color accentSoft;
  final Color navInactive;
  final Color shadow;

  /// Off-white page background most screens use (FBFBFC / FAF7F8 family).
  final Color scaffoldSoft;

  /// Text field and chip fill.
  final Color inputFill;

  /// Neutral hairline border around cards, fields and chips.
  final Color border;

  /// The soft pink outline around pink-accented cards.
  final Color accentBorder;

  final bool isDark;

  const AppPalette({
    required this.background,
    required this.card,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.divider,
    required this.accentSoft,
    required this.navInactive,
    required this.shadow,
    required this.scaffoldSoft,
    required this.inputFill,
    required this.border,
    required this.accentBorder,
    required this.isDark,
  });

  static const light = AppPalette(
    background: Colors.white,
    card: cardBackground,
    surface: surfaceLight,
    textPrimary: textDark,
    textSecondary: textMedium,
    textMuted: brand.textMuted,
    divider: dividerColor,
    accentSoft: accentLight,
    navInactive: Colors.grey,
    shadow: Color(0x14000000),
    scaffoldSoft: Color(0xFFFBFBFC),
    inputFill: Color(0xFFF9FAFB),
    border: Color(0xFFE5E7EB),
    accentBorder: Color(0xFFFCE4E8),
    isDark: false,
  );

  // The same greys AlloConnect's dark theme is built on (121212 / 1E1E1E), so
  // the two apps feel like one family at night.
  static const dark = AppPalette(
    background: darkBackground,
    card: darkCard,
    surface: darkSurface,
    textPrimary: Color(0xffF2F3F5),
    textSecondary: Color(0xffC4C7D0),
    textMuted: Color(0xff8E93A3),
    divider: Color(0xff2E2E33),
    accentSoft: Color(0xff3A2327),
    navInactive: Color(0xff8E93A3),
    shadow: Color(0x66000000),
    scaffoldSoft: darkBackground,
    inputFill: darkSurface,
    border: Color(0xff33333A),
    accentBorder: Color(0xff4A2A31),
    isDark: true,
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? card,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? divider,
    Color? accentSoft,
    Color? navInactive,
    Color? shadow,
    Color? scaffoldSoft,
    Color? inputFill,
    Color? border,
    Color? accentBorder,
    bool? isDark,
  }) {
    return AppPalette(
      background: background ?? this.background,
      card: card ?? this.card,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      divider: divider ?? this.divider,
      accentSoft: accentSoft ?? this.accentSoft,
      navInactive: navInactive ?? this.navInactive,
      shadow: shadow ?? this.shadow,
      scaffoldSoft: scaffoldSoft ?? this.scaffoldSoft,
      inputFill: inputFill ?? this.inputFill,
      border: border ?? this.border,
      accentBorder: accentBorder ?? this.accentBorder,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      navInactive: Color.lerp(navInactive, other.navInactive, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      scaffoldSoft: Color.lerp(scaffoldSoft, other.scaffoldSoft, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      border: Color.lerp(border, other.border, t)!,
      accentBorder: Color.lerp(accentBorder, other.accentBorder, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }

  /// A soft wash of [accent] for icon chips, badges and highlighted cards.
  ///
  /// In light mode it returns [light] when given (the pastel the design
  /// already used, e.g. `Color(0xFFFFF3E0)` behind an orange icon), otherwise
  /// a faint tint. In dark mode pastels glow, so it is always a low-alpha
  /// tint of the accent over the dark card.
  Color tint(Color accent, [Color? light]) => isDark
      ? accent.withValues(alpha: 0.18)
      : (light ?? accent.withValues(alpha: 0.10));

  /// Pick between the existing light value and a dark one.
  T pick<T>(T light, T dark) => isDark ? dark : light;

  /// The pink-to-white page wash, dimmed for dark mode.
  LinearGradient get backgroundGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff24181B), darkBackground, darkBackground],
        )
      : const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF0F1), Color(0xFFFFFAFB), Colors.white],
        );
}

extension AppThemeContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

/// Light and dark [ThemeData] for the app, both on the Allomom pink.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light, AppPalette.light);
  static ThemeData get dark => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette p) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      brightness: brightness,
    ).copyWith(
      surface: p.card,
      onSurface: p.textPrimary,
      onPrimary: Colors.white,
      outline: p.divider,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      cardColor: p.card,
      dividerColor: p.divider,
      extensions: [p],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
                .copyWith(statusBarColor: Colors.transparent)
            : SystemUiOverlayStyle.dark
                .copyWith(statusBarColor: Colors.transparent),
        iconTheme: IconThemeData(color: p.textPrimary),
        titleTextStyle: TextStyle(
          color: p.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(color: p.card, surfaceTintColor: p.card),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        modalBackgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
      ),
      bottomAppBarTheme: BottomAppBarThemeData(
        color: p.card,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(color: p.divider),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primaryColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(color: p.textMuted),
        hintStyle: TextStyle(color: p.textMuted),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primaryColor : null,
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: p.card,
        dialHandColor: primaryColor,
        entryModeIconColor: primaryColor,
      ),
    );
  }
}
