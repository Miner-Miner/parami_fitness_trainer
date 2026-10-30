import 'package:flutter/material.dart';

enum TrainerTheme {
  monochrome('Theme 1', 'Black & white', Color(0xFF333333), Color(0xFFF3F3F3)),
  gold('Theme 2', 'Black, gold & white', Color(0xFF80601F), Color(0xFFF8F5ED)),
  roseGold(
    'Theme 3',
    'Black, rose gold & white',
    Color(0xFF965A4D),
    Color(0xFFFAF2EF),
  );

  const TrainerTheme(
    this.label,
    this.description,
    this.accent,
    this.background,
  );
  final String label;
  final String description;
  final Color accent;
  final Color background;
}

class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.navyBright,
    required this.mist,
    this.variant = TrainerTheme.monochrome,
    this.dark = false,
  });
  factory AppPalette.forTheme(TrainerTheme theme, {bool dark = false}) =>
      AppPalette(
        dark: dark,
        navyBright: theme.accent,
        mist: dark ? const Color(0xFF101010) : theme.background,
        variant: theme,
      );
  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ??
      AppPalette.forTheme(TrainerTheme.monochrome);
  final bool dark;
  final TrainerTheme variant;
  double get radius => switch (variant) {
    TrainerTheme.monochrome => 4,
    TrainerTheme.gold => 12,
    TrainerTheme.roseGold => 28,
  };
  bool get editorial => variant == TrainerTheme.gold;
  bool get rounded => variant == TrainerTheme.roseGold;
  final Color navyBright;
  final Color mist;
  Color get ink => const Color(0xFF0C0C0C);
  Color get navy => const Color(0xFF191919);
  Color get steel => const Color(0xFF888888);
  Color get line => Color.lerp(mist, navyBright, 0.2)!;
  Color get muted => dark ? const Color(0xFFBBBBBB) : const Color(0xFF646464);
  Color get text => dark ? const Color(0xFFF5F5F5) : ink;
  Color get foregroundAccent =>
      dark ? Color.lerp(navyBright, Colors.white, 0.60)! : navyBright;
  Color get success => navyBright;
  Color get card => Color.lerp(
    dark ? const Color(0xFF242424) : Colors.white,
    navyBright,
    0.045,
  )!;
  Color get accentSoft => Color.lerp(card, navyBright, 0.15)!;
  @override
  AppPalette copyWith({Color? navyBright, Color? mist}) => AppPalette(
    dark: dark,
    variant: variant,
    navyBright: navyBright ?? this.navyBright,
    mist: mist ?? this.mist,
  );
  @override
  AppPalette lerp(covariant AppPalette? other, double t) => other == null
      ? this
      : AppPalette(
          dark: t < 0.5 ? dark : other.dark,
          variant: t < 0.5 ? variant : other.variant,
          navyBright: Color.lerp(navyBright, other.navyBright, t)!,
          mist: Color.lerp(mist, other.mist, t)!,
        );
}

ThemeData buildAppTheme(TrainerTheme theme, {bool dark = false}) {
  final palette = AppPalette.forTheme(theme, dark: dark);
  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    extensions: [palette],
    appBarTheme: AppBarTheme(
      centerTitle: palette.rounded,
      backgroundColor: palette.navyBright,
      foregroundColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.ink,
      indicatorColor: palette.navyBright,
      iconTheme: WidgetStateProperty.all(
        const IconThemeData(color: Colors.white),
      ),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(color: Colors.white, fontSize: 12),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: palette.ink,
      indicatorColor: palette.navyBright,
      selectedIconTheme: const IconThemeData(color: Colors.white),
      unselectedIconTheme: const IconThemeData(color: Colors.white70),
      selectedLabelTextStyle: const TextStyle(color: Colors.white),
      unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
    ),
    drawerTheme: DrawerThemeData(backgroundColor: palette.card),
    listTileTheme: ListTileThemeData(
      selectedColor: palette.foregroundAccent,
      selectedTileColor: palette.accentSoft,
    ),
    scaffoldBackgroundColor: palette.mist,
    colorScheme: ColorScheme.fromSeed(
      seedColor: palette.navyBright,
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: palette.foregroundAccent,
      onPrimary: dark ? Colors.black : Colors.white,
      secondary: palette.navyBright,
      onSecondary: Colors.white,
      surface: palette.card,
      onSurface: palette.text,
      outline: palette.line,
    ),
    textTheme: TextTheme(
      displaySmall: TextStyle(
        color: palette.foregroundAccent,
        fontFamily: palette.editorial ? 'serif' : null,
        fontSize: palette.editorial ? 32 : 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
      ),
      headlineSmall: TextStyle(
        color: palette.foregroundAccent,
        fontFamily: palette.editorial ? 'serif' : null,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
      ),
      titleLarge: TextStyle(
        color: palette.foregroundAccent,
        fontSize: 19,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: TextStyle(
        color: palette.foregroundAccent,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: TextStyle(color: palette.muted, fontSize: 14, height: 1.45),
      labelLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.3),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.card,
      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(palette.radius),
        borderSide: BorderSide(color: palette.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(palette.radius),
        borderSide: BorderSide(color: palette.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(palette.radius),
        borderSide: BorderSide(color: palette.foregroundAccent, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.navyBright,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(palette.radius),
        ),
        textStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: palette.navyBright,
      contentTextStyle: TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
