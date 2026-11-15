import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const Color borderColor = Color(0xFF2A2F3D);

  static const TextStyle _baseTextStyle = TextStyle(
    fontFamily: 'Inter',
    letterSpacing: -0.2,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      primaryColor: AppColors.primaryAccent,
      
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryAccent,
        onPrimary: Colors.white,
        secondary: AppColors.goldAccent,
        onSecondary: Colors.black,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        outline: borderColor,
        outlineVariant: AppColors.surfaceLight,
        error: AppColors.powerZone6,
        onError: Colors.white,
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: borderColor,
            width: 1.0,
          ),
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actionsIconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: _baseTextStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),

      // Navigation for Mobile (Bottom Bar)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        height: 68,
        indicatorColor: AppColors.primaryAccent.withValues(alpha: 0.25),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.goldAccent);
          }
          return const IconThemeData(color: AppColors.textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _baseTextStyle.copyWith(
              color: AppColors.goldAccent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return _baseTextStyle.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
      ),

      // Navigation for Tablet and Desktop (Rail)
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        groupAlignment: -0.9,
        indicatorColor: AppColors.primaryAccent.withValues(alpha: 0.25),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        selectedIconTheme: const IconThemeData(color: AppColors.goldAccent),
        unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary),
        selectedLabelTextStyle: _baseTextStyle.copyWith(
          color: AppColors.goldAccent,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: _baseTextStyle.copyWith(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Cycling Performance Data Table Theme
      dataTableTheme: DataTableThemeData(
        dataRowMinHeight: 48,
        dataRowMaxHeight: 52,
        headingRowHeight: 42,
        horizontalMargin: 16,
        columnSpacing: 24,
        dividerThickness: 1,
        headingRowColor: WidgetStateProperty.all(AppColors.surfaceLight),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return AppColors.surfaceLight.withValues(alpha: 0.5);
          }
          return AppColors.surface;
        }),
        headingTextStyle: _baseTextStyle.copyWith(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
        dataTextStyle: _baseTextStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primaryAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size(44, 46),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: _baseTextStyle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(44, 46),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: const BorderSide(color: borderColor, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: _baseTextStyle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.goldAccent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: _baseTextStyle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Divider & Input Decoration
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: _baseTextStyle.copyWith(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.goldAccent, width: 1.5),
        ),
      ),

      // Typography
      textTheme: TextTheme(
        displayLarge: _baseTextStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
        ),
        displayMedium: _baseTextStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
        titleLarge: _baseTextStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleMedium: _baseTextStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        titleSmall: _baseTextStyle.copyWith(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: _baseTextStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: _baseTextStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: _baseTextStyle.copyWith(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: _baseTextStyle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        labelSmall: _baseTextStyle.copyWith(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ), dialogTheme: const DialogThemeData(backgroundColor: AppColors.surface),
    );
  }

  // Stat styling helper with monospaced tabular figures
  static TextStyle statNumberStyle({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.textPrimary,
  }) {
    return _baseTextStyle.copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
