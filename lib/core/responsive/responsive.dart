import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 380;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 720;

  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 380) return 14;
    if (width >= 720) return 28;
    return 20;
  }

  static double maxContentWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 720 ? 760 : double.infinity;
}
