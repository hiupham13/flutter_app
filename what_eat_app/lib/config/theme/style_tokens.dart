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
}

class AppGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.primaryLight],
  );

  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.secondary, AppColors.secondaryLight],
  );
}

class AppBreakpoints {
  static const double compact = 360;
  static const double tablet = 600;
}

