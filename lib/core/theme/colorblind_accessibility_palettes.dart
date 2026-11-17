import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_colors.dart';
import 'app_theme.dart';

/// Supported visual accessibility modes for color vision deficiency (CVD).
///
/// Includes [standard] (trichromatic baseline) and 4 dedicated colorblind
/// accessibility palettes ([protanopia], [deuteranopia], [tritanopia],
/// [achromatopsia]) paired with geometric shape and pattern dual-coding.
enum ColorblindPaletteMode {
  standard(
    id: 'standard',
    labelPl: 'Standardowa (Trichromacja)',
    labelEn: 'Standard (Trichromacy)',
    descriptionPl:
        'Domyślna paleta Pro Peloton Manager z opcjonalnym kodowaniem kształtami.',
    descriptionEn:
        'Default Pro Peloton Manager palette with optional shape dual-coding.',
  ),
  protanopia(
    id: 'protanopia',
    labelPl: 'Protanopia (Brak czerwieni)',
    labelEn: 'Protanopia (Red-Blind)',
    descriptionPl:
        'Paleta błękitno-bursztynowo-fioletowa eliminująca mylenie czerwieni z zielenią.',
    descriptionEn:
        'Blue-amber-violet palette eliminating red-green confusion.',
  ),
  deuteranopia(
    id: 'deuteranopia',
    labelPl: 'Deuteranopia (Brak zieleni)',
    labelEn: 'Deuteranopia (Green-Blind)',
    descriptionPl:
        'Wysokokontrastowa paleta Okabe-Ito z wyraźnym rozróżnieniem odcieni błękitu i pomarańczu.',
    descriptionEn:
        'High-contrast Okabe-Ito palette with clear blue and orange separation.',
  ),
  tritanopia(
    id: 'tritanopia',
    labelPl: 'Tritanopia (Brak niebieskiego)',
    labelEn: 'Tritanopia (Blue-Yellow-Blind)',
    descriptionPl:
        'Paleta karmazynowo-turkusowo-limonkowa eliminująca mylenie niebieskiego z żółtym.',
    descriptionEn:
        'Crimson-turquoise-lime palette eliminating blue-yellow confusion.',
  ),
  achromatopsia(
    id: 'achromatopsia',
    labelPl: 'Achromatopsja (Monochromatyzm)',
    labelEn: 'Achromatopsia (Monochromacy)',
    descriptionPl:
        'Stopniowana skala luminancji o wysokim kontraście z pełnym kodowaniem kształtami i wzorami.',
    descriptionEn:
        'High-contrast stepped luminance scale with full shape and pattern encoding.',
  );

  const ColorblindPaletteMode({
    required this.id,
    required this.labelPl,
    required this.labelEn,
    required this.descriptionPl,
    required this.descriptionEn,
  });

  final String id;
  final String labelPl;
  final String labelEn;
  final String descriptionPl;
  final String descriptionEn;

  bool get isColorblindMode => this != ColorblindPaletteMode.standard;

  static ColorblindPaletteMode fromId(String? id) {
    for (final mode in ColorblindPaletteMode.values) {
      if (mode.id == id) return mode;
    }
    return ColorblindPaletteMode.standard;
  }
}

/// Geometric shapes used for dual-coding semantic states, power zones, and
/// peloton groups alongside color.
enum AccessibilityShapeType {
  circle(labelPl: 'Koło', labelEn: 'Circle'),
  triangleUp(labelPl: 'Trójkąt', labelEn: 'Triangle'),
  square(labelPl: 'Kwadrat', labelEn: 'Square'),
  diamond(labelPl: 'Romb', labelEn: 'Diamond'),
  pentagon(labelPl: 'Pięciokąt', labelEn: 'Pentagon'),
  hexagon(labelPl: 'Sześciokąt', labelEn: 'Hexagon'),
  star(labelPl: 'Gwiazda', labelEn: 'Star'),
  cross(labelPl: 'Krzyżyk', labelEn: 'Cross'),
  chevronUp(labelPl: 'Szewron w górę', labelEn: 'Chevron Up'),
  chevronDown(labelPl: 'Szewron w dół', labelEn: 'Chevron Down');

  const AccessibilityShapeType({
    required this.labelPl,
    required this.labelEn,
  });

  final String labelPl;
  final String labelEn;
}

/// Secondary fill/stroke patterns for bars, charts, and zone indicators.
enum AccessibilityPatternType {
  solid(labelPl: 'Jednolity', labelEn: 'Solid'),
  diagonalStripes(labelPl: 'Pasy ukośne', labelEn: 'Diagonal Stripes'),
  horizontalStripes(labelPl: 'Pasy poziome', labelEn: 'Horizontal Stripes'),
  dots(labelPl: 'Kropki', labelEn: 'Dots'),
  crosshatch(labelPl: 'Kratka', labelEn: 'Crosshatch'),
  dashedBorder(labelPl: 'Przerywana ramka', labelEn: 'Dashed Border'),
  ringed(labelPl: 'Pierścień', labelEn: 'Ringed');

  const AccessibilityPatternType({
    required this.labelPl,
    required this.labelEn,
  });

  final String labelPl;
  final String labelEn;
}

/// Semantic status categories used across telemetry, race HUD, and manager UI.
enum AccessibilitySemanticRole {
  success,
  warning,
  alert,
  info,
  accent,
  gold,
  neutral,
}

/// Race & peloton group markers used on minimaps, 3D overlays, and broadcast UI.
enum PelotonVisualGroupRole {
  gcLeader,
  pointsLeader,
  komLeader,
  youthLeader,
  playerTeam,
  breakaway,
  peloton,
  grupetto,
}

/// A single dual-encoded visual token pairing a [color] with a [shape],
/// optional [pattern], [icon], and localized labels.
@immutable
class DualEncodedVisualToken {
  const DualEncodedVisualToken({
    required this.color,
    required this.shape,
    required this.pattern,
    required this.icon,
    required this.labelPl,
    required this.labelEn,
    this.shortCode = '',
  });

  final Color color;
  final AccessibilityShapeType shape;
  final AccessibilityPatternType pattern;
  final IconData icon;
  final String labelPl;
  final String labelEn;
  final String shortCode;

  /// Computes WCAG 2.1 relative contrast ratio against [againstColor].
  double contrastRatioAgainst(Color againstColor) {
    final l1 = color.computeLuminance();
    final l2 = againstColor.computeLuminance();
    final lighter = math.max(l1, l2);
    final darker = math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  DualEncodedVisualToken copyWith({
    Color? color,
    AccessibilityShapeType? shape,
    AccessibilityPatternType? pattern,
    IconData? icon,
    String? labelPl,
    String? labelEn,
    String? shortCode,
  }) {
    return DualEncodedVisualToken(
      color: color ?? this.color,
      shape: shape ?? this.shape,
      pattern: pattern ?? this.pattern,
      icon: icon ?? this.icon,
      labelPl: labelPl ?? this.labelPl,
      labelEn: labelEn ?? this.labelEn,
      shortCode: shortCode ?? this.shortCode,
    );
  }
}

/// Complete accessibility palette for a specific [ColorblindPaletteMode].
@immutable
class ColorblindAccessibilityPalette {
  const ColorblindAccessibilityPalette({
    required this.mode,
    required this.powerZones,
    required this.semanticRoles,
    required this.pelotonGroups,
  });

  final ColorblindPaletteMode mode;
  final Map<int, DualEncodedVisualToken> powerZones;
  final Map<AccessibilitySemanticRole, DualEncodedVisualToken> semanticRoles;
  final Map<PelotonVisualGroupRole, DualEncodedVisualToken> pelotonGroups;

  DualEncodedVisualToken powerZone(int zone) {
    return powerZones[zone.clamp(1, 7)] ?? powerZones[1]!;
  }

  DualEncodedVisualToken semantic(AccessibilitySemanticRole role) {
    return semanticRoles[role] ?? semanticRoles[AccessibilitySemanticRole.neutral]!;
  }

  DualEncodedVisualToken pelotonGroup(PelotonVisualGroupRole role) {
    return pelotonGroups[role] ?? pelotonGroups[PelotonVisualGroupRole.peloton]!;
  }
}

/// Registry of all 5 palettes (Standard + 4 Colorblind Accessibility Palettes)
/// and color vision deficiency simulation helpers.
class ColorblindAccessibilityPalettes {
  ColorblindAccessibilityPalettes._();

  static const List<ColorblindPaletteMode> colorblindModes = [
    ColorblindPaletteMode.protanopia,
    ColorblindPaletteMode.deuteranopia,
    ColorblindPaletteMode.tritanopia,
    ColorblindPaletteMode.achromatopsia,
  ];

  static ColorblindAccessibilityPalette forMode(ColorblindPaletteMode mode) {
    switch (mode) {
      case ColorblindPaletteMode.standard:
        return standardPalette;
      case ColorblindPaletteMode.protanopia:
        return protanopiaPalette;
      case ColorblindPaletteMode.deuteranopia:
        return deuteranopiaPalette;
      case ColorblindPaletteMode.tritanopia:
        return tritanopiaPalette;
      case ColorblindPaletteMode.achromatopsia:
        return achromatopsiaPalette;
    }
  }

  // ---------------------------------------------------------------------------
  // 0. Standard (Trichromacy baseline using AppColors)
  // ---------------------------------------------------------------------------
  static final ColorblindAccessibilityPalette standardPalette =
      ColorblindAccessibilityPalette(
    mode: ColorblindPaletteMode.standard,
    powerZones: _buildPowerZones(const [
      AppColors.powerZone1,
      AppColors.powerZone2,
      AppColors.powerZone3,
      AppColors.powerZone4,
      AppColors.powerZone5,
      AppColors.powerZone6,
      AppColors.powerZone7,
    ]),
    semanticRoles: _buildSemanticRoles(
      success: AppColors.statusSuccess,
      warning: AppColors.amberWarning,
      alert: AppColors.crimsonAlert,
      info: AppColors.accentBlue,
      accent: AppColors.primaryAccent,
      gold: AppColors.goldAccent,
      neutral: AppColors.textSecondary,
    ),
    pelotonGroups: _buildPelotonGroups(
      gcLeader: AppColors.goldAccent,
      pointsLeader: AppColors.statusSuccess,
      komLeader: AppColors.crimsonAlert,
      youthLeader: AppColors.textPrimary,
      playerTeam: AppColors.cyanAccent,
      breakaway: AppColors.amberWarning,
      peloton: AppColors.accentBlue,
      grupetto: AppColors.textSecondary,
    ),
  );

  // ---------------------------------------------------------------------------
  // 1. Protanopia (Red-blind) — Blue / Cyan / Amber / Gold / Violet separation
  // ---------------------------------------------------------------------------
  static final ColorblindAccessibilityPalette protanopiaPalette =
      ColorblindAccessibilityPalette(
    mode: ColorblindPaletteMode.protanopia,
    powerZones: _buildPowerZones(const [
      Color(0xFF94A3B8), // Z1: Cool Slate (distinct luminance)
      Color(0xFF38BDF8), // Z2: Sky Blue
      Color(0xFF2DD4BF), // Z3: Bright Teal
      Color(0xFFFACC15), // Z4: Vivid Yellow
      Color(0xFFF59E0B), // Z5: Deep Amber
      Color(0xFFC084FC), // Z6: Soft Violet
      Color(0xFFFFFFFF), // Z7: Pure White Peak
    ]),
    semanticRoles: _buildSemanticRoles(
      success: const Color(0xFF2DD4BF), // Teal
      warning: const Color(0xFFFACC15), // Yellow
      alert: const Color(0xFFFB923C), // High-luminance Amber-Orange
      info: const Color(0xFF38BDF8), // Sky Blue
      accent: const Color(0xFF818CF8), // Indigo-Periwinkle
      gold: const Color(0xFFFDE047), // Bright Gold
      neutral: const Color(0xFF9CA3AF),
    ),
    pelotonGroups: _buildPelotonGroups(
      gcLeader: const Color(0xFFFDE047),
      pointsLeader: const Color(0xFF2DD4BF),
      komLeader: const Color(0xFFC084FC),
      youthLeader: const Color(0xFFF8FAFC),
      playerTeam: const Color(0xFF38BDF8),
      breakaway: const Color(0xFFF59E0B),
      peloton: const Color(0xFF60A5FA),
      grupetto: const Color(0xFF94A3B8),
    ),
  );

  // ---------------------------------------------------------------------------
  // 2. Deuteranopia (Green-blind) — Okabe-Ito inspired Blue / Orange / Magenta
  // ---------------------------------------------------------------------------
  static final ColorblindAccessibilityPalette deuteranopiaPalette =
      ColorblindAccessibilityPalette(
    mode: ColorblindPaletteMode.deuteranopia,
    powerZones: _buildPowerZones(const [
      Color(0xFF9CA3AF), // Z1: Neutral Gray
      Color(0xFF56B4E9), // Z2: Okabe-Ito Sky Blue
      Color(0xFF0072B2), // Z3: Okabe-Ito Deep Blue
      Color(0xFFF0E442), // Z4: Okabe-Ito Yellow
      Color(0xFFE69F00), // Z5: Okabe-Ito Orange
      Color(0xFFD55E00), // Z6: Okabe-Ito Vermilion
      Color(0xFFCC79A7), // Z7: Okabe-Ito Reddish Purple
    ]),
    semanticRoles: _buildSemanticRoles(
      success: const Color(0xFF56B4E9), // Sky Blue
      warning: const Color(0xFFF0E442), // Yellow
      alert: const Color(0xFFD55E00), // Vermilion
      info: const Color(0xFF0072B2), // Deep Blue
      accent: const Color(0xFFCC79A7), // Reddish Purple
      gold: const Color(0xFFE69F00), // Orange-Gold
      neutral: const Color(0xFF9CA3AF),
    ),
    pelotonGroups: _buildPelotonGroups(
      gcLeader: const Color(0xFFF0E442),
      pointsLeader: const Color(0xFF56B4E9),
      komLeader: const Color(0xFFCC79A7),
      youthLeader: const Color(0xFFF3F4F6),
      playerTeam: const Color(0xFFE69F00),
      breakaway: const Color(0xFFD55E00),
      peloton: const Color(0xFF0072B2),
      grupetto: const Color(0xFF9CA3AF),
    ),
  );

  // ---------------------------------------------------------------------------
  // 3. Tritanopia (Blue-yellow-blind) — Crimson / Turquoise / Rose / Cyan
  // ---------------------------------------------------------------------------
  static final ColorblindAccessibilityPalette tritanopiaPalette =
      ColorblindAccessibilityPalette(
    mode: ColorblindPaletteMode.tritanopia,
    powerZones: _buildPowerZones(const [
      Color(0xFF9CA3AF), // Z1: Neutral Gray
      Color(0xFF22D3EE), // Z2: Bright Cyan
      Color(0xFF0D9488), // Z3: Deep Turquoise
      Color(0xFFFDA4AF), // Z4: Soft Rose
      Color(0xFFFB7185), // Z5: Coral Pink
      Color(0xFFEF4444), // Z6: Strong Crimson
      Color(0xFFF9FAFB), // Z7: High-Luminance White
    ]),
    semanticRoles: _buildSemanticRoles(
      success: const Color(0xFF2DD4BF), // Turquoise
      warning: const Color(0xFFFDA4AF), // Rose-Peach
      alert: const Color(0xFFEF4444), // Crimson
      info: const Color(0xFF22D3EE), // Cyan
      accent: const Color(0xFFFB7185), // Coral
      gold: const Color(0xFFFECDD3), // Champagne Rose
      neutral: const Color(0xFF9CA3AF),
    ),
    pelotonGroups: _buildPelotonGroups(
      gcLeader: const Color(0xFFFECDD3),
      pointsLeader: const Color(0xFF2DD4BF),
      komLeader: const Color(0xFFEF4444),
      youthLeader: const Color(0xFFF9FAFB),
      playerTeam: const Color(0xFF22D3EE),
      breakaway: const Color(0xFFFB7185),
      peloton: const Color(0xFF0D9488),
      grupetto: const Color(0xFF9CA3AF),
    ),
  );

  // ---------------------------------------------------------------------------
  // 4. Achromatopsia (Monochromacy) — Stepped luminance + full shape/pattern
  // ---------------------------------------------------------------------------
  static final ColorblindAccessibilityPalette achromatopsiaPalette =
      ColorblindAccessibilityPalette(
    mode: ColorblindPaletteMode.achromatopsia,
    powerZones: _buildPowerZones(const [
      Color(0xFF6B7280), // Z1: 42% Luminance Gray
      Color(0xFF8B949E), // Z2: 56% Luminance Gray
      Color(0xFFA3AAB4), // Z3: 66% Luminance Gray
      Color(0xFFBDC3CC), // Z4: 77% Luminance Gray
      Color(0xFFD5DAE0), // Z5: 86% Luminance Gray
      Color(0xFFEBEEF2), // Z6: 93% Luminance Gray
      Color(0xFFFFFFFF), // Z7: 100% Pure White
    ]),
    semanticRoles: _buildSemanticRoles(
      success: const Color(0xFFE5E7EB),
      warning: const Color(0xFFD1D5DB),
      alert: const Color(0xFFFFFFFF),
      info: const Color(0xFF9CA3AF),
      accent: const Color(0xFFF3F4F6),
      gold: const Color(0xFFFFFFFF),
      neutral: const Color(0xFF9CA3AF),
    ),
    pelotonGroups: _buildPelotonGroups(
      gcLeader: const Color(0xFFFFFFFF),
      pointsLeader: const Color(0xFFE5E7EB),
      komLeader: const Color(0xFFD1D5DB),
      youthLeader: const Color(0xFFF9FAFB),
      playerTeam: const Color(0xFFF3F4F6),
      breakaway: const Color(0xFFBDBDBD),
      peloton: const Color(0xFF9CA3AF),
      grupetto: const Color(0xFF6B7280),
    ),
  );

  static Map<int, DualEncodedVisualToken> _buildPowerZones(
    List<Color> colors,
  ) {
    assert(colors.length == 7);
    const shapes = [
      AccessibilityShapeType.circle,
      AccessibilityShapeType.triangleUp,
      AccessibilityShapeType.square,
      AccessibilityShapeType.diamond,
      AccessibilityShapeType.pentagon,
      AccessibilityShapeType.hexagon,
      AccessibilityShapeType.star,
    ];
    const patterns = [
      AccessibilityPatternType.solid,
      AccessibilityPatternType.dots,
      AccessibilityPatternType.horizontalStripes,
      AccessibilityPatternType.diagonalStripes,
      AccessibilityPatternType.ringed,
      AccessibilityPatternType.crosshatch,
      AccessibilityPatternType.dashedBorder,
    ];
    const icons = [
      Icons.spa_outlined,
      Icons.directions_bike,
      Icons.speed,
      Icons.trending_up,
      Icons.local_fire_department,
      Icons.bolt,
      Icons.flash_on,
    ];
    const labelsPl = [
      'Z1 Regeneracja',
      'Z2 Wytrzymałość',
      'Z3 Tempo',
      'Z4 Próg FTP',
      'Z5 VO2 Max',
      'Z6 Beztlenowa',
      'Z7 Neuromięśniowa',
    ];
    const labelsEn = [
      'Z1 Active Recovery',
      'Z2 Endurance',
      'Z3 Tempo',
      'Z4 Threshold',
      'Z5 VO2 Max',
      'Z6 Anaerobic',
      'Z7 Neuromuscular',
    ];

    return {
      for (int i = 0; i < 7; i++)
        i + 1: DualEncodedVisualToken(
          color: colors[i],
          shape: shapes[i],
          pattern: patterns[i],
          icon: icons[i],
          labelPl: labelsPl[i],
          labelEn: labelsEn[i],
          shortCode: 'Z${i + 1}',
        ),
    };
  }

  static Map<AccessibilitySemanticRole, DualEncodedVisualToken>
      _buildSemanticRoles({
    required Color success,
    required Color warning,
    required Color alert,
    required Color info,
    required Color accent,
    required Color gold,
    required Color neutral,
  }) {
    return {
      AccessibilitySemanticRole.success: DualEncodedVisualToken(
        color: success,
        shape: AccessibilityShapeType.chevronUp,
        pattern: AccessibilityPatternType.solid,
        icon: Icons.check_circle_outline,
        labelPl: 'Optymalny / Sukces',
        labelEn: 'Optimal / Success',
        shortCode: 'OK',
      ),
      AccessibilitySemanticRole.warning: DualEncodedVisualToken(
        color: warning,
        shape: AccessibilityShapeType.triangleUp,
        pattern: AccessibilityPatternType.diagonalStripes,
        icon: Icons.warning_amber_rounded,
        labelPl: 'Ostrzeżenie',
        labelEn: 'Warning',
        shortCode: 'WARN',
      ),
      AccessibilitySemanticRole.alert: DualEncodedVisualToken(
        color: alert,
        shape: AccessibilityShapeType.cross,
        pattern: AccessibilityPatternType.crosshatch,
        icon: Icons.error_outline,
        labelPl: 'Krytyczny / Alert',
        labelEn: 'Critical / Alert',
        shortCode: 'ALRT',
      ),
      AccessibilitySemanticRole.info: DualEncodedVisualToken(
        color: info,
        shape: AccessibilityShapeType.circle,
        pattern: AccessibilityPatternType.dots,
        icon: Icons.info_outline,
        labelPl: 'Telemetria',
        labelEn: 'Telemetry',
        shortCode: 'INFO',
      ),
      AccessibilitySemanticRole.accent: DualEncodedVisualToken(
        color: accent,
        shape: AccessibilityShapeType.diamond,
        pattern: AccessibilityPatternType.ringed,
        icon: Icons.flag_outlined,
        labelPl: 'Akcent Taktyczny',
        labelEn: 'Tactical Accent',
        shortCode: 'TAC',
      ),
      AccessibilitySemanticRole.gold: DualEncodedVisualToken(
        color: gold,
        shape: AccessibilityShapeType.star,
        pattern: AccessibilityPatternType.solid,
        icon: Icons.emoji_events_outlined,
        labelPl: 'Lider / Złoto',
        labelEn: 'Leader / Gold',
        shortCode: 'GC',
      ),
      AccessibilitySemanticRole.neutral: DualEncodedVisualToken(
        color: neutral,
        shape: AccessibilityShapeType.square,
        pattern: AccessibilityPatternType.dashedBorder,
        icon: Icons.remove_circle_outline,
        labelPl: 'Neutralny',
        labelEn: 'Neutral',
        shortCode: 'NEUT',
      ),
    };
  }

  static Map<PelotonVisualGroupRole, DualEncodedVisualToken>
      _buildPelotonGroups({
    required Color gcLeader,
    required Color pointsLeader,
    required Color komLeader,
    required Color youthLeader,
    required Color playerTeam,
    required Color breakaway,
    required Color peloton,
    required Color grupetto,
  }) {
    return {
      PelotonVisualGroupRole.gcLeader: DualEncodedVisualToken(
        color: gcLeader,
        shape: AccessibilityShapeType.star,
        pattern: AccessibilityPatternType.solid,
        icon: Icons.emoji_events,
        labelPl: 'Lider GC',
        labelEn: 'GC Leader',
        shortCode: 'GC',
      ),
      PelotonVisualGroupRole.pointsLeader: DualEncodedVisualToken(
        color: pointsLeader,
        shape: AccessibilityShapeType.triangleUp,
        pattern: AccessibilityPatternType.diagonalStripes,
        icon: Icons.flash_on,
        labelPl: 'Lider Punktowy',
        labelEn: 'Points Leader',
        shortCode: 'PTS',
      ),
      PelotonVisualGroupRole.komLeader: DualEncodedVisualToken(
        color: komLeader,
        shape: AccessibilityShapeType.hexagon,
        pattern: AccessibilityPatternType.dots,
        icon: Icons.terrain,
        labelPl: 'Król Gór KOM',
        labelEn: 'KOM Leader',
        shortCode: 'KOM',
      ),
      PelotonVisualGroupRole.youthLeader: DualEncodedVisualToken(
        color: youthLeader,
        shape: AccessibilityShapeType.diamond,
        pattern: AccessibilityPatternType.ringed,
        icon: Icons.workspace_premium,
        labelPl: 'Młodzieżowiec',
        labelEn: 'Youth Leader',
        shortCode: 'YTH',
      ),
      PelotonVisualGroupRole.playerTeam: DualEncodedVisualToken(
        color: playerTeam,
        shape: AccessibilityShapeType.pentagon,
        pattern: AccessibilityPatternType.solid,
        icon: Icons.shield,
        labelPl: 'Twoja Drużyna',
        labelEn: 'Your Team',
        shortCode: 'TEAM',
      ),
      PelotonVisualGroupRole.breakaway: DualEncodedVisualToken(
        color: breakaway,
        shape: AccessibilityShapeType.chevronUp,
        pattern: AccessibilityPatternType.horizontalStripes,
        icon: Icons.double_arrow,
        labelPl: 'Ucieczka',
        labelEn: 'Breakaway',
        shortCode: 'BRK',
      ),
      PelotonVisualGroupRole.peloton: DualEncodedVisualToken(
        color: peloton,
        shape: AccessibilityShapeType.circle,
        pattern: AccessibilityPatternType.solid,
        icon: Icons.groups,
        labelPl: 'Peleton',
        labelEn: 'Peloton',
        shortCode: 'PEL',
      ),
      PelotonVisualGroupRole.grupetto: DualEncodedVisualToken(
        color: grupetto,
        shape: AccessibilityShapeType.chevronDown,
        pattern: AccessibilityPatternType.dashedBorder,
        icon: Icons.directions_bus,
        labelPl: 'Grupetto',
        labelEn: 'Grupetto',
        shortCode: 'GRP',
      ),
    };
  }

  /// Simulates how a [Color] appears under a given [ColorblindPaletteMode]
  /// using standard sRGB transformation matrices.
  static Color simulateColor(Color input, ColorblindPaletteMode mode) {
    if (mode == ColorblindPaletteMode.standard) return input;

    final r = input.r;
    final g = input.g;
    final b = input.b;
    final a = input.a;

    double sr;
    double sg;
    double sb;

    switch (mode) {
      case ColorblindPaletteMode.standard:
        return input;
      case ColorblindPaletteMode.protanopia:
        sr = 0.567 * r + 0.433 * g;
        sg = 0.558 * r + 0.442 * g;
        sb = 0.242 * g + 0.758 * b;
      case ColorblindPaletteMode.deuteranopia:
        sr = 0.625 * r + 0.375 * g;
        sg = 0.700 * r + 0.300 * g;
        sb = 0.300 * g + 0.700 * b;
      case ColorblindPaletteMode.tritanopia:
        sr = 0.950 * r + 0.050 * g;
        sg = 0.433 * g + 0.567 * b;
        sb = 0.475 * g + 0.525 * b;
      case ColorblindPaletteMode.achromatopsia:
        final luma = 0.2126 * r + 0.7152 * g + 0.0722 * b;
        sr = luma;
        sg = luma;
        sb = luma;
    }

    return Color.from(
      alpha: a,
      red: sr.clamp(0.0, 1.0),
      green: sg.clamp(0.0, 1.0),
      blue: sb.clamp(0.0, 1.0),
    );
  }
}

/// Riverpod state for colorblind accessibility configuration.
@immutable
class ColorblindAccessibilityState {
  const ColorblindAccessibilityState({
    this.mode = ColorblindPaletteMode.standard,
    this.enableShapeDualCoding = true,
    this.enablePatternOverlay = true,
    this.highContrastBorders = false,
    this.simulateInPreview = false,
  });

  final ColorblindPaletteMode mode;
  final bool enableShapeDualCoding;
  final bool enablePatternOverlay;
  final bool highContrastBorders;
  final bool simulateInPreview;

  ColorblindAccessibilityPalette get activePalette =>
      ColorblindAccessibilityPalettes.forMode(mode);

  ColorblindAccessibilityState copyWith({
    ColorblindPaletteMode? mode,
    bool? enableShapeDualCoding,
    bool? enablePatternOverlay,
    bool? highContrastBorders,
    bool? simulateInPreview,
  }) {
    return ColorblindAccessibilityState(
      mode: mode ?? this.mode,
      enableShapeDualCoding:
          enableShapeDualCoding ?? this.enableShapeDualCoding,
      enablePatternOverlay: enablePatternOverlay ?? this.enablePatternOverlay,
      highContrastBorders: highContrastBorders ?? this.highContrastBorders,
      simulateInPreview: simulateInPreview ?? this.simulateInPreview,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ColorblindAccessibilityState &&
        other.mode == mode &&
        other.enableShapeDualCoding == enableShapeDualCoding &&
        other.enablePatternOverlay == enablePatternOverlay &&
        other.highContrastBorders == highContrastBorders &&
        other.simulateInPreview == simulateInPreview;
  }

  @override
  int get hashCode => Object.hash(
        mode,
        enableShapeDualCoding,
        enablePatternOverlay,
        highContrastBorders,
        simulateInPreview,
      );
}

/// StateNotifier managing active colorblind accessibility settings.
class ColorblindAccessibilityNotifier
    extends StateNotifier<ColorblindAccessibilityState> {
  ColorblindAccessibilityNotifier([ColorblindAccessibilityState? initialState])
      : super(initialState ?? const ColorblindAccessibilityState());

  void setMode(ColorblindPaletteMode mode) {
    state = state.copyWith(
      mode: mode,
      enableShapeDualCoding:
          mode.isColorblindMode ? true : state.enableShapeDualCoding,
    );
  }

  void setShapeDualCoding(bool enabled) {
    state = state.copyWith(enableShapeDualCoding: enabled);
  }

  void setPatternOverlay(bool enabled) {
    state = state.copyWith(enablePatternOverlay: enabled);
  }

  void setHighContrastBorders(bool enabled) {
    state = state.copyWith(highContrastBorders: enabled);
  }

  void setSimulateInPreview(bool enabled) {
    state = state.copyWith(simulateInPreview: enabled);
  }

  void resetToDefault() {
    state = const ColorblindAccessibilityState();
  }
}

final colorblindAccessibilityProvider = StateNotifierProvider<
    ColorblindAccessibilityNotifier, ColorblindAccessibilityState>(
  (ref) => ColorblindAccessibilityNotifier(),
);

final activeColorblindPaletteProvider =
    Provider<ColorblindAccessibilityPalette>(
  (ref) => ref.watch(colorblindAccessibilityProvider).activePalette,
);

/// Renders geometric dual-coding shapes with crisp borders and optional
/// secondary pattern overlays.
class AccessibilityShapePainter extends CustomPainter {
  const AccessibilityShapePainter({
    required this.shape,
    required this.color,
    this.pattern = AccessibilityPatternType.solid,
    this.enablePattern = false,
    this.borderColor = AppColors.background,
    this.strokeWidth = 1.4,
  });

  final AccessibilityShapeType shape;
  final Color color;
  final AccessibilityPatternType pattern;
  final bool enablePattern;
  final Color borderColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final side = math.min(w, h);
    final cx = w / 2;
    final cy = h / 2;
    final radius = (side / 2) - strokeWidth;
    if (radius <= 0) return;

    final path = _buildShapePath(shape, cx, cy, radius);
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(path, fillPaint);

    if (enablePattern && pattern != AccessibilityPatternType.solid) {
      canvas.save();
      canvas.clipPath(path);
      _paintPattern(canvas, size, cx, cy, radius);
      canvas.restore();
    }

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawPath(path, borderPaint);
  }

  Path _buildShapePath(
    AccessibilityShapeType type,
    double cx,
    double cy,
    double r,
  ) {
    switch (type) {
      case AccessibilityShapeType.circle:
        return Path()
          ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      case AccessibilityShapeType.triangleUp:
        return _regularPolygonPath(cx, cy, r, 3, -math.pi / 2);
      case AccessibilityShapeType.square:
        final half = r * 0.84;
        return Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(cx, cy),
                width: half * 2,
                height: half * 2,
              ),
              Radius.circular(r * 0.2),
            ),
          );
      case AccessibilityShapeType.diamond:
        return Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r, cy)
          ..lineTo(cx, cy + r)
          ..lineTo(cx - r, cy)
          ..close();
      case AccessibilityShapeType.pentagon:
        return _regularPolygonPath(cx, cy, r, 5, -math.pi / 2);
      case AccessibilityShapeType.hexagon:
        return _regularPolygonPath(cx, cy, r, 6, -math.pi / 2);
      case AccessibilityShapeType.star:
        return _starPath(cx, cy, r, r * 0.48, 5);
      case AccessibilityShapeType.cross:
        final arm = r * 0.36;
        final d = r * 0.86;
        return Path()
          ..moveTo(cx - arm, cy - d)
          ..lineTo(cx + arm, cy - d)
          ..lineTo(cx + arm, cy - arm)
          ..lineTo(cx + d, cy - arm)
          ..lineTo(cx + d, cy + arm)
          ..lineTo(cx + arm, cy + arm)
          ..lineTo(cx + arm, cy + d)
          ..lineTo(cx - arm, cy + d)
          ..lineTo(cx - arm, cy + arm)
          ..lineTo(cx - d, cy + arm)
          ..lineTo(cx - d, cy - arm)
          ..lineTo(cx - arm, cy - arm)
          ..close();
      case AccessibilityShapeType.chevronUp:
        return Path()
          ..moveTo(cx, cy - r * 0.85)
          ..lineTo(cx + r * 0.9, cy + r * 0.25)
          ..lineTo(cx + r * 0.55, cy + r * 0.75)
          ..lineTo(cx, cy + r * 0.1)
          ..lineTo(cx - r * 0.55, cy + r * 0.75)
          ..lineTo(cx - r * 0.9, cy + r * 0.25)
          ..close();
      case AccessibilityShapeType.chevronDown:
        return Path()
          ..moveTo(cx, cy + r * 0.85)
          ..lineTo(cx + r * 0.9, cy - r * 0.25)
          ..lineTo(cx + r * 0.55, cy - r * 0.75)
          ..lineTo(cx, cy - r * 0.1)
          ..lineTo(cx - r * 0.55, cy - r * 0.75)
          ..lineTo(cx - r * 0.9, cy - r * 0.25)
          ..close();
    }
  }

  Path _regularPolygonPath(
    double cx,
    double cy,
    double r,
    int sides,
    double startAngle,
  ) {
    final path = Path();
    for (int i = 0; i < sides; i++) {
      final angle = startAngle + (2 * math.pi * i / sides);
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  Path _starPath(
    double cx,
    double cy,
    double outerR,
    double innerR,
    int points,
  ) {
    final path = Path();
    final totalVertices = points * 2;
    for (int i = 0; i < totalVertices; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = -math.pi / 2 + (math.pi * i / points);
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  void _paintPattern(
    Canvas canvas,
    Size size,
    double cx,
    double cy,
    double radius,
  ) {
    final overlayColor = color.computeLuminance() > 0.5
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.45);
    final paint = Paint()
      ..color = overlayColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final step = math.max(3.5, radius * 0.42);
    switch (pattern) {
      case AccessibilityPatternType.solid:
        return;
      case AccessibilityPatternType.diagonalStripes:
        for (double x = -size.height; x < size.width + size.height; x += step) {
          canvas.drawLine(
            Offset(x, size.height),
            Offset(x + size.height, 0),
            paint,
          );
        }
      case AccessibilityPatternType.horizontalStripes:
        for (double y = step * 0.5; y < size.height; y += step) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
      case AccessibilityPatternType.crosshatch:
        for (double x = -size.height; x < size.width + size.height; x += step) {
          canvas.drawLine(
            Offset(x, size.height),
            Offset(x + size.height, 0),
            paint,
          );
          canvas.drawLine(
            Offset(x, 0),
            Offset(x + size.height, size.height),
            paint,
          );
        }
      case AccessibilityPatternType.dots:
        final dotPaint = Paint()
          ..color = overlayColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(cx, cy), math.max(1.3, radius * 0.2), dotPaint);
      case AccessibilityPatternType.ringed:
        canvas.drawCircle(Offset(cx, cy), radius * 0.46, paint);
      case AccessibilityPatternType.dashedBorder:
        canvas.drawCircle(Offset(cx, cy), radius * 0.62, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AccessibilityShapePainter oldDelegate) {
    return oldDelegate.shape != shape ||
        oldDelegate.color != color ||
        oldDelegate.pattern != pattern ||
        oldDelegate.enablePattern != enablePattern ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Reusable badge rendering a dual-encoded [DualEncodedVisualToken].
class AccessibilityShapeBadge extends StatelessWidget {
  const AccessibilityShapeBadge({
    super.key,
    required this.token,
    this.size = 18,
    this.showShape = true,
    this.showPattern = true,
    this.simulatedMode,
  });

  final DualEncodedVisualToken token;
  final double size;
  final bool showShape;
  final bool showPattern;
  final ColorblindPaletteMode? simulatedMode;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = simulatedMode == null
        ? token.color
        : ColorblindAccessibilityPalettes.simulateColor(
            token.color,
            simulatedMode!,
          );

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: AccessibilityShapePainter(
          shape: showShape ? token.shape : AccessibilityShapeType.circle,
          color: effectiveColor,
          pattern: token.pattern,
          enablePattern: showPattern,
        ),
      ),
    );
  }
}

/// Compact pill displaying a dual-encoded power zone or status token.
class DualEncodedTokenPill extends StatelessWidget {
  const DualEncodedTokenPill({
    super.key,
    required this.token,
    required this.showShape,
    required this.showPattern,
    this.highContrastBorder = false,
    this.simulatedMode,
    this.compact = false,
  });

  final DualEncodedVisualToken token;
  final bool showShape;
  final bool showPattern;
  final bool highContrastBorder;
  final ColorblindPaletteMode? simulatedMode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final displayColor = simulatedMode == null
        ? token.color
        : ColorblindAccessibilityPalettes.simulateColor(
            token.color,
            simulatedMode!,
          );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highContrastBorder
              ? displayColor.withValues(alpha: 0.85)
              : AppTheme.borderColor,
          width: highContrastBorder ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AccessibilityShapeBadge(
            token: token,
            size: compact ? 14 : 16,
            showShape: showShape,
            showPattern: showPattern,
            simulatedMode: simulatedMode,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              compact && token.shortCode.isNotEmpty
                  ? token.shortCode
                  : token.labelPl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Production-ready settings and live preview panel for Colorblind
/// Accessibility Palettes & Shape Dual-Coding.
///
/// Responsive across 390x844 (mobile), 1024x768 (tablet), and 1600x900 (desktop).
class ColorblindAccessibilitySettingsPanel extends ConsumerWidget {
  const ColorblindAccessibilitySettingsPanel({
    super.key,
    this.enabled = true,
  });

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(colorblindAccessibilityProvider);
    final notifier = ref.read(colorblindAccessibilityProvider.notifier);
    final palette = state.activePalette;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1080;
          final isTablet =
              constraints.maxWidth >= 680 && constraints.maxWidth < 1080;

          final selectorSection = _PaletteSelectorSection(
            state: state,
            notifier: notifier,
            enabled: enabled,
            isCompact: !isDesktop && !isTablet,
          );

          final previewSection = _PaletteLivePreviewSection(
            state: state,
            palette: palette,
            isCompact: !isDesktop && !isTablet,
          );

          if (isDesktop) {
            return SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: selectorSection),
                  const SizedBox(width: 20),
                  Expanded(flex: 6, child: previewSection),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                selectorSection,
                const SizedBox(height: 16),
                previewSection,
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PaletteSelectorSection extends StatelessWidget {
  const _PaletteSelectorSection({
    required this.state,
    required this.notifier,
    required this.enabled,
    required this.isCompact,
  });

  final ColorblindAccessibilityState state;
  final ColorblindAccessibilityNotifier notifier;
  final bool enabled;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryAccent.withValues(alpha: 0.5),
                ),
              ),
              child: const Icon(
                Icons.visibility_outlined,
                color: AppColors.goldAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dostępność Wizualna (Daltonizm)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '4 palety CVD + podwójne kodowanie kształtami',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            if (!isCompact)
              _ActionResetButton(
                enabled: enabled &&
                    state != const ColorblindAccessibilityState(),
                onPressed: notifier.resetToDefault,
              ),
          ],
        ),
        const SizedBox(height: 14),
        for (final mode in ColorblindPaletteMode.values) ...[
          _PaletteModeCard(
            mode: mode,
            palette: ColorblindAccessibilityPalettes.forMode(mode),
            selected: state.mode == mode,
            enabled: enabled,
            showShapes: state.enableShapeDualCoding,
            onSelect: () => notifier.setMode(mode),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 6),
        _AccessibilityToggleRow(
          title: 'Podwójne kodowanie kształtami',
          subtitle: 'Różnicuj strefy Z1–Z7 i grupy peletonu kształtami',
          value: state.enableShapeDualCoding,
          enabled: enabled,
          onChanged: notifier.setShapeDualCoding,
        ),
        const SizedBox(height: 8),
        _AccessibilityToggleRow(
          title: 'Wzory na wskaźnikach i wykresach',
          subtitle: 'Nakładaj kreskowanie, kropki i kratkę na paski stref',
          value: state.enablePatternOverlay,
          enabled: enabled,
          onChanged: notifier.setPatternOverlay,
        ),
        const SizedBox(height: 8),
        _AccessibilityToggleRow(
          title: 'Ramki wysokiego kontrastu',
          subtitle: 'Wzmacniaj obramowania kart i badge\'ów telemetrii',
          value: state.highContrastBorders,
          enabled: enabled,
          onChanged: notifier.setHighContrastBorders,
        ),
        const SizedBox(height: 8),
        _AccessibilityToggleRow(
          title: 'Symulacja widzenia CVD w podglądzie',
          subtitle: 'Podgląd jak wybrana paleta wygląda w symulacji daltonizmu',
          value: state.simulateInPreview,
          enabled: enabled && state.mode.isColorblindMode,
          onChanged: notifier.setSimulateInPreview,
        ),
        if (isCompact) ...[
          const SizedBox(height: 12),
          _ActionResetButton(
            enabled:
                enabled && state != const ColorblindAccessibilityState(),
            onPressed: notifier.resetToDefault,
          ),
        ],
      ],
    );
  }
}

class _PaletteModeCard extends StatefulWidget {
  const _PaletteModeCard({
    required this.mode,
    required this.palette,
    required this.selected,
    required this.enabled,
    required this.showShapes,
    required this.onSelect,
  });

  final ColorblindPaletteMode mode;
  final ColorblindAccessibilityPalette palette;
  final bool selected;
  final bool enabled;
  final bool showShapes;
  final VoidCallback onSelect;

  @override
  State<_PaletteModeCard> createState() => _PaletteModeCardState();
}

class _PaletteModeCardState extends State<_PaletteModeCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = !widget.enabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : widget.selected
            ? AppColors.goldAccent
            : _focused
                ? AppColors.accentBlue
                : _hovered
                    ? AppColors.primaryAccent
                    : AppTheme.borderColor;

    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : _pressed
            ? AppColors.primaryAccent.withValues(alpha: 0.22)
            : widget.selected
                ? AppColors.surfaceLight
                : _hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.75)
                    : AppColors.background;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onSelect : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: widget.selected || _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 18,
                color: !widget.enabled
                    ? AppColors.textSecondary.withValues(alpha: 0.4)
                    : widget.selected
                        ? AppColors.goldAccent
                        : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.mode.labelPl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: widget.enabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.mode.descriptionPl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary.withValues(
                          alpha: widget.enabled ? 0.9 : 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int z = 2; z <= 6; z += 2) ...[
                    AccessibilityShapeBadge(
                      token: widget.palette.powerZone(z),
                      size: 14,
                      showShape: widget.showShapes,
                      showPattern: false,
                    ),
                    if (z < 6) const SizedBox(width: 4),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessibilityToggleRow extends StatefulWidget {
  const _AccessibilityToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  State<_AccessibilityToggleRow> createState() =>
      _AccessibilityToggleRowState();
}

class _AccessibilityToggleRowState extends State<_AccessibilityToggleRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.enabled ? () => widget.onChanged(!widget.value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered && widget.enabled
                ? AppColors.surfaceLight
                : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? AppColors.accentBlue
                  : AppTheme.borderColor.withValues(
                      alpha: widget.enabled ? 1.0 : 0.45,
                    ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.enabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary.withValues(
                          alpha: widget.enabled ? 0.9 : 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: widget.value,
                activeThumbColor: AppColors.goldAccent,
                activeTrackColor: AppColors.primaryAccent,
                onChanged: widget.enabled ? widget.onChanged : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionResetButton extends StatefulWidget {
  const _ActionResetButton({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  State<_ActionResetButton> createState() => _ActionResetButtonState();
}

class _ActionResetButtonState extends State<_ActionResetButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: OutlinedButton.icon(
        onPressed: widget.enabled ? widget.onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: _hovered && widget.enabled
              ? AppColors.surfaceLight
              : Colors.transparent,
          side: BorderSide(
            color: _focused ? AppColors.accentBlue : AppTheme.borderColor,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(44, 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.restart_alt, size: 16),
        label: const Text(
          'Reset',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PaletteLivePreviewSection extends StatelessWidget {
  const _PaletteLivePreviewSection({
    required this.state,
    required this.palette,
    required this.isCompact,
  });

  final ColorblindAccessibilityState state;
  final ColorblindAccessibilityPalette palette;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final simMode =
        state.simulateInPreview && state.mode.isColorblindMode ? state.mode : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: state.highContrastBorders
              ? AppColors.goldAccent.withValues(alpha: 0.7)
              : AppTheme.borderColor,
          width: state.highContrastBorders ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.palette_outlined,
                color: AppColors.accentBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  simMode == null
                      ? 'Podgląd Stref Mocy Z1–Z7 i Grup Peletonu'
                      : 'Podgląd w Symulacji: ${simMode.labelPl}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'STREFY MOCY COGGANA (Z1–Z7)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int z = 1; z <= 7; z++)
                DualEncodedTokenPill(
                  token: palette.powerZone(z),
                  showShape: state.enableShapeDualCoding,
                  showPattern: state.enablePatternOverlay,
                  highContrastBorder: state.highContrastBorders,
                  simulatedMode: simMode,
                  compact: isCompact,
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'GRUPY PELETONU I KOSZULKI LIDERÓW',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final group in PelotonVisualGroupRole.values)
                DualEncodedTokenPill(
                  token: palette.pelotonGroup(group),
                  showShape: state.enableShapeDualCoding,
                  showPattern: state.enablePatternOverlay,
                  highContrastBorder: state.highContrastBorders,
                  simulatedMode: simMode,
                  compact: isCompact,
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'STATUSY TELEMETRII I ALERTY',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final role in AccessibilitySemanticRole.values)
                DualEncodedTokenPill(
                  token: palette.semantic(role),
                  showShape: state.enableShapeDualCoding,
                  showPattern: state.enablePatternOverlay,
                  highContrastBorder: state.highContrastBorders,
                  simulatedMode: simMode,
                  compact: isCompact,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
