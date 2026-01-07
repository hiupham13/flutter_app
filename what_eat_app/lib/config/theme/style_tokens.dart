import 'package:flutter/material.dart';
import 'package:what_eat_app/core/constants/app_colors.dart';

class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;
}

class AppDurations {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration medium = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);
}

class AppShadows {
  static const BoxShadow card = BoxShadow(
    color: Color.fromRGBO(15, 23, 42, 0.06),
    blurRadius: 12,
    offset: Offset(0, 8),
  );

  static const BoxShadow elevated = BoxShadow(
    color: Color.fromRGBO(15, 23, 42, 0.12),
    blurRadius: 16,
    offset: Offset(0, 10),
  );

  static const BoxShadow soft = BoxShadow(
    color: Color.fromRGBO(15, 23, 42, 0.04),
    blurRadius: 10,
    offset: Offset(0, 4),
  );

  // Shadow lists for multiple shadows
  static const List<BoxShadow> small = [soft];
  static const List<BoxShadow> medium = [card];
  static const List<BoxShadow> large = [elevated];
}

class AppGradients {
  // Primary gradient - matches icon (Orange → Yellow → Lime Green)
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primary,    // Orange
      AppColors.accent,     // Yellow
      AppColors.secondary,  // Lime Green
    ],
  );

  // Accent gradient - Lime Green to Yellow
  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.secondary,  // Lime Green
      AppColors.accent,     // Yellow
    ],
  );

  // Warm gradient - Orange tones
  static const LinearGradient warm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primary,
      AppColors.primaryLight,
    ],
  );
}

class AppBreakpoints {
  static const double compact = 360;
  static const double tablet = 600;
}

/// Typography system - Material Design 3 inspired
class AppFonts {
  // Headline styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: 0,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: 0,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: 0,
  );
  
  // Title styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.15,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.1,
  );
  
  // Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
    letterSpacing: 0.15,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
    letterSpacing: 0.25,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.5,
    letterSpacing: 0.4,
  );
  
  // Label styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.1,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.5,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.5,
  );
}

