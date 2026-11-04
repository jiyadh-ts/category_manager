import 'package:flutter/material.dart';

/// Design tokens extracted directly from Stitch project 17593075487443235860
/// (Enterprise Hierarchy Category Manager - Simple Screens)
class AppColors {
  const AppColors._();

  // Primary & Containers
  static const Color primary = Color(0xFF000617);
  static const Color primaryContainer = Color(0xFF0B1F3C);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF7687AA);

  // Secondary & Accents
  static const Color secondary = Color(0xFF0051D5);
  static const Color secondaryContainer = Color(0xFF316BF3);
  static const Color secondaryFixed = Color(0xFFDBE1FF);
  static const Color onSecondaryFixed = Color(0xFF00174B);
  static const Color secondaryFixedDim = Color(0xFFB4C5FF);
  static const Color onSecondaryContainer = Color(0xFFFEFCFF);

  // Tertiary
  static const Color tertiary = Color(0xFF0B0024);
  static const Color tertiaryFixed = Color(0xFFEADDFF);
  static const Color onTertiaryFixed = Color(0xFF25005A);
  static const Color tertiaryFixedDim = Color(0xFFD2BBFF);
  static const Color onTertiaryFixedVariant = Color(0xFF543098);

  // Surfaces & Backgrounds
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceCanvas = Color(0xFFF8F9FA);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE5EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color surfaceContainerHighest = Color(0xFFD3E4FE);

  // Texts & Outlines
  static const Color onSurface = Color(0xFF0B1C30);
  static const Color onSurfaceVariant = Color(0xFF44474D);
  static const Color outline = Color(0xFF75777E);
  static const Color outlineVariant = Color(0xFFC5C6CE);
  static const Color borderSubtle = Color(0xFFE2E8F0);

  // Status & Semantic Colors
  static const Color statusSuccess = Color(0xFF059669);
  static const Color statusWarning = Color(0xFFD97706);
  static const Color statusError = Color(0xFFDC2626);
  static const Color statusInfo = Color(0xFF2563EB);

  // Error States
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
}
