import 'package:flutter/material.dart';

class AppThemePalette {
  final String name;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color text;
  final Color accent;

  const AppThemePalette({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.text,
    required this.accent,
  });
}

class AppTheme {
  static const String defaultName = 'default';
  static const String merdekaName = 'merdeka';

  static String currentName() =>
      const String.fromEnvironment('APP_THEME', defaultValue: defaultName);

  static AppThemePalette paletteFor(String name) {
    switch (name.toLowerCase()) {
      case merdekaName:
        return const AppThemePalette(
          name: merdekaName,
          primary: Color.fromARGB(185, 214, 40, 40),
          secondary: Color(0xFFF4B400),
          background: Colors.white,
          surface: Colors.white,
          text: Color(0xFF364057),
          accent: Color(0xFF1E5F74),
        );
      case defaultName:
      default:
        return const AppThemePalette(
          name: defaultName,
          primary: Color(0xFF768BBD),
          secondary: Color(0xFFB7BBC3),
          background: Colors.white,
          surface: Colors.white,
          text: Color(0xFF364057),
          accent: Color(0xFF5A6F8F),
        );
    }
  }

  static ThemeData buildTheme(String name) {
    final palette = paletteFor(name);

    return ThemeData(
      primaryColor: palette.primary,
      scaffoldBackgroundColor: palette.background,
      fontFamily: 'CircularStd',
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.primary,
        primary: palette.primary,
        secondary: palette.secondary,
        surface: palette.surface,
      ),
      useMaterial3: true,
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: palette.text,
        displayColor: palette.text,
      ),
    );
  }
}
