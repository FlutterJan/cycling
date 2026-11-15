import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core Theme Palette
  static const Color background = Color(0xFF0F1115);
  static const Color backgroundDark = Color(0xFF0F1115);
  static const Color surface = Color(0xFF181B22);
  static const Color surfaceLight = Color(0xFF222630);
  static const Color cardDark = Color(0xFF181B22);
  static const Color cardSurface = Color(0xFF222630);
  static const Color cardBorder = Color(0xFF2E3440);
  static const Color primaryAccent = Color(0xFF8E4A49);
  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color accentBlue = Color(0xFF38BDF8);
  static const Color cyanAccent = Color(0xFF00E5FF);
  static const Color statusSuccess = Color(0xFF10B981);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color amberWarning = Color(0xFFF59E0B);
  static const Color crimsonAlert = Color(0xFFEF4444);

  // Typography Colors
  static const Color textPrimary = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Cycling Power Zones (Coggan Power Zones 1-7)
  static const Color powerZone1 = Color(0xFF6B7280); // Active Recovery (Szary)
  static const Color powerZone2 = Color(0xFF3B82F6); // Endurance (Niebieski)
  static const Color powerZone3 = Color(0xFF10B981); // Tempo (Zielony)
  static const Color powerZone4 = Color(0xFFEAB308); // Lactate Threshold (Żółty)
  static const Color powerZone5 = Color(0xFFF97316); // VO2 Max (Pomarańczowy)
  static const Color powerZone6 = Color(0xFFEF4444); // Anaerobic Capacity (Czerwony)
  static const Color powerZone7 = Color(0xFF8B5CF6); // Neuromuscular Power (Fioletowy)

  static Color getPowerZoneColor(int zone) {
    switch (zone) {
      case 1:
        return powerZone1;
      case 2:
        return powerZone2;
      case 3:
        return powerZone3;
      case 4:
        return powerZone4;
      case 5:
        return powerZone5;
      case 6:
        return powerZone6;
      case 7:
        return powerZone7;
      default:
        return powerZone1;
    }
  }
}
