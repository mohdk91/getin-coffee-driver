import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static const TextStyle display = TextStyle(
    color: AppColors.greenDark,
    fontSize: 28,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    height: 1.15,
  );

  static const TextStyle title = TextStyle(
    color: AppColors.greenDark,
    fontSize: 20,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.25,
  );

  static const TextStyle section = TextStyle(
    color: AppColors.greenDark,
    fontSize: 18,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle body = TextStyle(
    color: AppColors.greenDark,
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle muted = TextStyle(
    color: AppColors.muted,
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle label = TextStyle(
    color: AppColors.greenDark,
    fontSize: 12,
    fontWeight: FontWeight.w800,
  );
}
