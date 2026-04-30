import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF0F3C66); // Deep blue
  static const Color secondary = Color(0xFF1A5C92); // Lighter blue
  static const Color background = Color(0xFFF4F6F9); // Light gray/blue tint
  static const Color white = Colors.white;
  static const Color text = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF6B7280);
  static const Color inputBorder = Color(0xFFD1D5DB);

  // Card Colors
  static const Color cardGreenBg = Color(0xFFE6F4EA);
  static const Color cardGreenIcon = Color(0xFF1E8E3E);

  static const Color cardBlueBg = Color(0xFFE8F0FE);
  static const Color cardBlueIcon = Color(0xFF1967D2);

  static const Color cardOrangeBg = Color(0xFFFEF7E0);
  static const Color cardOrangeIcon = Color(0xFFFBC02D);

  static const Color cardTealBg = Color(0xFFE0F2F1);
  static const Color cardTealIcon = Color(0xFF00695C);

  static const Color cardRedBg = Color(0xFFFCE8E6);
  static const Color cardRedIcon = Color(0xFFC5221F);

  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color purpleIcon = Color(0xFF9C27B0);
  static const Color purpleBg = Color(0xFFF3E5F5);
}

extension AppThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get appBackground => Theme.of(this).scaffoldBackgroundColor;

  Color get appSurface => Theme.of(this).colorScheme.surface;

  Color get appSurfaceVariant =>
      Theme.of(this).colorScheme.surfaceContainerHighest;

  Color get appText => Theme.of(this).colorScheme.onSurface;

  Color get appTextLight => Theme.of(this).colorScheme.onSurfaceVariant;

  Color get appBorder => Theme.of(this).dividerColor;
}
