import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // PantryPalooza palette mapped to Flutter ColorScheme tokens
  static const _slateBlue = Color(0xFF3D5F8F);   // accent-1
  static const _terracotta = Color(0xFFA3412F);   // accent-2
  static const _mossGreen = Color(0xFF556347);    // accent-3
  static const _nearBlack = Color(0xFF151514);    // bg-dark
  static const _warmOffWhite = Color(0xFFF2F0E8); // gray-light

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _slateBlue,
      primary: _slateBlue,
      secondary: _terracotta,
      tertiary: _mossGreen,
      surface: _warmOffWhite,
      onSurface: _nearBlack,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        titleTextStyle: _textTheme.titleLarge?.copyWith(
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }

  // Merriweather for heading/display slots, system font (Roboto on Android)
  // for body and label slots.
  static const TextTheme _textTheme = TextTheme(
    // Hero / splash
    displayLarge: TextStyle(
      fontFamily: 'Merriweather',
      fontWeight: FontWeight.w700,
      fontSize: 57,
      height: 1.12,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Merriweather',
      fontWeight: FontWeight.w700,
      fontSize: 45,
      height: 1.16,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Merriweather',
      fontWeight: FontWeight.w400,
      fontSize: 36,
      height: 1.22,
    ),

    // Section headings
    headlineLarge: TextStyle(
      fontFamily: 'Merriweather',
      fontWeight: FontWeight.w700,
      fontSize: 32,
      height: 1.25,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Merriweather',
      fontWeight: FontWeight.w700,
      fontSize: 28,
      height: 1.29,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Merriweather',
      fontWeight: FontWeight.w400,
      fontSize: 24,
      height: 1.33,
    ),

    // Card / panel titles
    titleLarge: TextStyle(
      fontFamily: 'Merriweather',
      fontWeight: FontWeight.w700,
      fontSize: 22,
      height: 1.27,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Merriweather',
      fontWeight: FontWeight.w400,
      fontSize: 16,
      height: 1.50,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Merriweather',
      fontWeight: FontWeight.w400,
      fontSize: 14,
      height: 1.43,
    ),

    // Body text — system font (Roboto on Android), no fontFamily override
    bodyLarge: TextStyle(fontSize: 16, height: 1.50),
    bodyMedium: TextStyle(fontSize: 14, height: 1.43),
    bodySmall: TextStyle(fontSize: 12, height: 1.33),

    // Labels / buttons / captions — system font
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.43,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.33,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.45,
    ),
  );
}
