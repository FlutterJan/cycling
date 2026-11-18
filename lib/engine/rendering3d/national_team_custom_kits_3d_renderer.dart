// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

// =============================================================================
// 1. ENUMY KONFIGURACJI STROJU NARODOWEGO I TRYBU MISTRZOWSKIEGO
// =============================================================================

/// Wariant imprezy mistrzowskiej determinujący krój stroju i konfigurację roweru 3D.
enum NationalTeamKitEventVariant {
  worldChampionshipsRoad(
    labelPl: 'MŚ UCI — Szosa',
    shortTag: 'MŚ SZOSA',
    isTimeTrial: false,
    isOlympic: false,
    longSleeves: false,
  ),
  worldChampionshipsItt(
    labelPl: 'MŚ UCI — Czasówka',
    shortTag: 'MŚ ITT',
    isTimeTrial: true,
    isOlympic: false,
    longSleeves: true,
  ),
  olympicGamesRoad(
    labelPl: 'Igrzyska — Szosa',
    shortTag: 'IO SZOSA',
    isTimeTrial: false,
    isOlympic: true,
    longSleeves: false,
  ),
  olympicGamesItt(
    labelPl: 'Igrzyska — Czasówka',
    shortTag: 'IO ITT',
    isTimeTrial: true,
    isOlympic: true,
    longSleeves: true,
  );

  final String labelPl;
  final String shortTag;
  final bool isTimeTrial;
  final bool isOlympic;
  final bool longSleeves;

  const NationalTeamKitEventVariant({
    required this.labelPl,
    required this.shortTag,
    required this.isTimeTrial,
    required this.isOlympic,
    required this.longSleeves,
  });

  String toJson() => name;

  static NationalTeamKitEventVariant fromJson(String? value) {
    if (value == null) return NationalTeamKitEventVariant.worldChampionshipsRoad;
    return NationalTeamKitEventVariant.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => NationalTeamKitEventVariant.worldChampionshipsRoad,
    );
  }
}

/// Geometryczny wzór graficzny oficjalnej koszulki reprezentacji narodowej.
enum NationalKitPatternStyle {
  chestBand('Pas na piersi'),
  tricolorChevron('Szewron V'),
  verticalPinstripe('Pas pionowy'),
  diagonalSash('Ukośna szarfa'),
  alpineCross('Krzyż narodowy'),
  gradientWave('Fala gradientowa');

  final String labelPl;

  const NationalKitPatternStyle(this.labelPl);

  String toJson() => name;

  static NationalKitPatternStyle fromJson(String? value) {
    if (value == null) return NationalKitPatternStyle.chestBand;
    return NationalKitPatternStyle.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => NationalKitPatternStyle.chestBand,
    );
  }
}

/// Specjalne oznaczenia kasku, mankietów i osprzętu dla mistrzów olimpijskich i świata.
enum NationalKitHelmetAndBibMode {
  standardNational(
    labelPl: 'Standard Kadry',
    shortTag: 'KADRA',
  ),
  olympicChampionGold(
    labelPl: 'Mistrz Olimpijski',
    shortTag: 'ZŁOTO IO',
  ),
  reigningWorldChampion(
    labelPl: 'Mistrz Świata UCI',
    shortTag: 'TĘCZA UCI',
  );

  final String labelPl;
  final String shortTag;

  const NationalKitHelmetAndBibMode({
    required this.labelPl,
    required this.shortTag,
  });

  String toJson() => name;

  static NationalKitHelmetAndBibMode fromJson(String? value) {
    if (value == null) return NationalKitHelmetAndBibMode.standardNational;
    return NationalKitHelmetAndBibMode.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => NationalKitHelmetAndBibMode.standardNational,
    );
  }
}

/// Predefiniowane ujęcia kamery 3D w podglądzie koszulek reprezentacji.
enum NationalKitCameraPreset {
  frontThreeQuarter(
    labelPl: 'Przód 3/4',
    yawRadians: -0.58,
    pitchRadians: 0.24,
    distanceMeters: 3.15,
  ),
  sideProfile(
    labelPl: 'Profil',
    yawRadians: -1.57,
    pitchRadians: 0.14,
    distanceMeters: 3.25,
  ),
  rearBibView(
    labelPl: 'Tył / Numer',
    yawRadians: 2.68,
    pitchRadians: 0.24,
    distanceMeters: 3.15,
  ),
  aeroTopView(
    labelPl: 'Aero Góra',
    yawRadians: -0.45,
    pitchRadians: 0.62,
    distanceMeters: 3.45,
  );

  final String labelPl;
  final double yawRadians;
  final double pitchRadians;
  final double distanceMeters;

  const NationalKitCameraPreset({
    required this.labelPl,
    required this.yawRadians,
    required this.pitchRadians,
    required this.distanceMeters,
  });
}

// =============================================================================
// 2. SPECYFIKACJA KOSZULKI NARODOWEJ ORAZ KATALOG REPREZENTACJI
// =============================================================================

/// Pełna specyfikacja wizualna oficjalnego stroju reprezentacji narodowej dla silnika 3D.
@immutable
class NationalTeamKitSpec {
  final String countryCode;
  final String countryNamePl;
  final String federationTitle;
  final String chestEmblemCode;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color shortsColor;
  final Color collarColor;
  final Color sockColor;
  final List<Color> flagColors;
  final NationalKitPatternStyle patternStyle;
  final String bibNumberSample;
  final int uciNationRank;

  const NationalTeamKitSpec({
    required this.countryCode,
    required this.countryNamePl,
    required this.federationTitle,
    required this.chestEmblemCode,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.shortsColor,
    required this.collarColor,
    required this.sockColor,
    required this.flagColors,
    required this.patternStyle,
    this.bibNumberSample = '01',
    this.uciNationRank = 1,
  });

  Map<String, dynamic> toJson() => {
        'countryCode': countryCode,
        'countryNamePl': countryNamePl,
        'federationTitle': federationTitle,
        'chestEmblemCode': chestEmblemCode,
        'primaryColor': primaryColor.toARGB32(),
        'secondaryColor': secondaryColor.toARGB32(),
        'accentColor': accentColor.toARGB32(),
        'shortsColor': shortsColor.toARGB32(),
        'collarColor': collarColor.toARGB32(),
        'sockColor': sockColor.toARGB32(),
        'flagColors': flagColors.map((c) => c.toARGB32()).toList(),
        'patternStyle': patternStyle.toJson(),
        'bibNumberSample': bibNumberSample,
        'uciNationRank': uciNationRank,
      };

  factory NationalTeamKitSpec.fromJson(Map<String, dynamic> json) {
    final rawFlags = (json['flagColors'] as List<dynamic>?) ?? const [];
    return NationalTeamKitSpec(
      countryCode: (json['countryCode'] as String?) ?? 'POL',
      countryNamePl: (json['countryNamePl'] as String?) ?? 'Polska',
      federationTitle: (json['federationTitle'] as String?) ?? 'PZKol Polska',
      chestEmblemCode: (json['chestEmblemCode'] as String?) ?? 'POL',
      primaryColor: Color((json['primaryColor'] as int?) ?? 0xFFF3F4F6),
      secondaryColor: Color((json['secondaryColor'] as int?) ?? 0xFFDC143C),
      accentColor: Color((json['accentColor'] as int?) ?? 0xFFD4AF37),
      shortsColor: Color((json['shortsColor'] as int?) ?? 0xFF161920),
      collarColor: Color((json['collarColor'] as int?) ?? 0xFFDC143C),
      sockColor: Color((json['sockColor'] as int?) ?? 0xFFF3F4F6),
      flagColors: rawFlags.isEmpty
          ? const [Color(0xFFF3F4F6), Color(0xFFDC143C)]
          : rawFlags.map((v) => Color(v as int)).toList(),
      patternStyle: NationalKitPatternStyle.fromJson(
        json['patternStyle'] as String?,
      ),
      bibNumberSample: (json['bibNumberSample'] as String?) ?? '01',
      uciNationRank: (json['uciNationRank'] as int?) ?? 1,
    );
  }
}

/// Katalog 16 oficjalnych koszulek czołowych reprezentacji kolarskich świata.
class NationalTeamKitsCatalog {
  NationalTeamKitsCatalog._();

  static const List<NationalTeamKitSpec> officialKits = [
    NationalTeamKitSpec(
      countryCode: 'POL',
      countryNamePl: 'Polska',
      federationTitle: 'PZKol — Reprezentacja Polski',
      chestEmblemCode: 'POL',
      primaryColor: Color(0xFFF3F4F6),
      secondaryColor: Color(0xFFD91E36),
      accentColor: Color(0xFFD4AF37),
      shortsColor: Color(0xFF151821),
      collarColor: Color(0xFFD91E36),
      sockColor: Color(0xFFF3F4F6),
      flagColors: [Color(0xFFF3F4F6), Color(0xFFD91E36)],
      patternStyle: NationalKitPatternStyle.chestBand,
      bibNumberSample: '41',
      uciNationRank: 11,
    ),
    NationalTeamKitSpec(
      countryCode: 'BEL',
      countryNamePl: 'Belgia',
      federationTitle: 'Belgian Cycling',
      chestEmblemCode: 'BEL',
      primaryColor: Color(0xFF5BA4CF),
      secondaryColor: Color(0xFF111318),
      accentColor: Color(0xFFFACC15),
      shortsColor: Color(0xFF111318),
      collarColor: Color(0xFFEF4444),
      sockColor: Color(0xFF5BA4CF),
      flagColors: [Color(0xFF111318), Color(0xFFFACC15), Color(0xFFEF4444)],
      patternStyle: NationalKitPatternStyle.tricolorChevron,
      bibNumberSample: '01',
      uciNationRank: 1,
    ),
    NationalTeamKitSpec(
      countryCode: 'SLO',
      countryNamePl: 'Słowenia',
      federationTitle: 'KZS — Kolesarska Zveza Slovenije',
      chestEmblemCode: 'SLO',
      primaryColor: Color(0xFF0EA5E9),
      secondaryColor: Color(0xFF10B981),
      accentColor: Color(0xFFF3F4F6),
      shortsColor: Color(0xFF0F172A),
      collarColor: Color(0xFF10B981),
      sockColor: Color(0xFF0EA5E9),
      flagColors: [Color(0xFFF3F4F6), Color(0xFF2563EB), Color(0xFFDC2626)],
      patternStyle: NationalKitPatternStyle.tricolorChevron,
      bibNumberSample: '11',
      uciNationRank: 2,
    ),
    NationalTeamKitSpec(
      countryCode: 'FRA',
      countryNamePl: 'Francja',
      federationTitle: 'FFC — Équipe de France',
      chestEmblemCode: 'FRA',
      primaryColor: Color(0xFF1D4ED8),
      secondaryColor: Color(0xFFF3F4F6),
      accentColor: Color(0xFFEF4444),
      shortsColor: Color(0xFF111827),
      collarColor: Color(0xFFEF4444),
      sockColor: Color(0xFF1D4ED8),
      flagColors: [Color(0xFF1D4ED8), Color(0xFFF3F4F6), Color(0xFFEF4444)],
      patternStyle: NationalKitPatternStyle.chestBand,
      bibNumberSample: '21',
      uciNationRank: 3,
    ),
    NationalTeamKitSpec(
      countryCode: 'ITA',
      countryNamePl: 'Włochy',
      federationTitle: 'FCI — Squadra Azzurra',
      chestEmblemCode: 'ITA',
      primaryColor: Color(0xFF0284C7),
      secondaryColor: Color(0xFFF3F4F6),
      accentColor: Color(0xFF16A34A),
      shortsColor: Color(0xFF0F172A),
      collarColor: Color(0xFFD4AF37),
      sockColor: Color(0xFF0284C7),
      flagColors: [Color(0xFF16A34A), Color(0xFFF3F4F6), Color(0xFFDC2626)],
      patternStyle: NationalKitPatternStyle.chestBand,
      bibNumberSample: '31',
      uciNationRank: 4,
    ),
    NationalTeamKitSpec(
      countryCode: 'NED',
      countryNamePl: 'Holandia',
      federationTitle: 'KNWU — Oranje',
      chestEmblemCode: 'NED',
      primaryColor: Color(0xFFF97316),
      secondaryColor: Color(0xFF1E3A8A),
      accentColor: Color(0xFFF3F4F6),
      shortsColor: Color(0xFF111827),
      collarColor: Color(0xFF1E3A8A),
      sockColor: Color(0xFFF97316),
      flagColors: [Color(0xFFDC2626), Color(0xFFF3F4F6), Color(0xFF1D4ED8)],
      patternStyle: NationalKitPatternStyle.verticalPinstripe,
      bibNumberSample: '05',
      uciNationRank: 5,
    ),
    NationalTeamKitSpec(
      countryCode: 'ESP',
      countryNamePl: 'Hiszpania',
      federationTitle: 'RFEC — Selección Española',
      chestEmblemCode: 'ESP',
      primaryColor: Color(0xFFDC2626),
      secondaryColor: Color(0xFFFACC15),
      accentColor: Color(0xFF991B1B),
      shortsColor: Color(0xFF171717),
      collarColor: Color(0xFFFACC15),
      sockColor: Color(0xFFDC2626),
      flagColors: [Color(0xFFDC2626), Color(0xFFFACC15), Color(0xFFDC2626)],
      patternStyle: NationalKitPatternStyle.chestBand,
      bibNumberSample: '51',
      uciNationRank: 6,
    ),
    NationalTeamKitSpec(
      countryCode: 'DEN',
      countryNamePl: 'Dania',
      federationTitle: 'DCU — Danmarks Cykle Union',
      chestEmblemCode: 'DEN',
      primaryColor: Color(0xFFC8102E),
      secondaryColor: Color(0xFFF3F4F6),
      accentColor: Color(0xFF881337),
      shortsColor: Color(0xFF14161D),
      collarColor: Color(0xFFF3F4F6),
      sockColor: Color(0xFFC8102E),
      flagColors: [Color(0xFFC8102E), Color(0xFFF3F4F6)],
      patternStyle: NationalKitPatternStyle.diagonalSash,
      bibNumberSample: '61',
      uciNationRank: 7,
    ),
    NationalTeamKitSpec(
      countryCode: 'GBR',
      countryNamePl: 'Wielka Brytania',
      federationTitle: 'British Cycling',
      chestEmblemCode: 'GBR',
      primaryColor: Color(0xFF1E293B),
      secondaryColor: Color(0xFFEF4444),
      accentColor: Color(0xFF38BDF8),
      shortsColor: Color(0xFF0F172A),
      collarColor: Color(0xFFEF4444),
      sockColor: Color(0xFFF3F4F6),
      flagColors: [Color(0xFF1D4ED8), Color(0xFFF3F4F6), Color(0xFFEF4444)],
      patternStyle: NationalKitPatternStyle.verticalPinstripe,
      bibNumberSample: '71',
      uciNationRank: 8,
    ),
    NationalTeamKitSpec(
      countryCode: 'COL',
      countryNamePl: 'Kolumbia',
      federationTitle: 'FCC — Selección Colombia',
      chestEmblemCode: 'COL',
      primaryColor: Color(0xFFFACC15),
      secondaryColor: Color(0xFF1D4ED8),
      accentColor: Color(0xFFDC2626),
      shortsColor: Color(0xFF111827),
      collarColor: Color(0xFF1D4ED8),
      sockColor: Color(0xFFFACC15),
      flagColors: [Color(0xFFFACC15), Color(0xFF1D4ED8), Color(0xFFDC2626)],
      patternStyle: NationalKitPatternStyle.diagonalSash,
      bibNumberSample: '81',
      uciNationRank: 9,
    ),
    NationalTeamKitSpec(
      countryCode: 'AUS',
      countryNamePl: 'Australia',
      federationTitle: 'AusCycling — Green & Gold',
      chestEmblemCode: 'AUS',
      primaryColor: Color(0xFF15803D),
      secondaryColor: Color(0xFFFACC15),
      accentColor: Color(0xFFF3F4F6),
      shortsColor: Color(0xFF064E3B),
      collarColor: Color(0xFFFACC15),
      sockColor: Color(0xFFFACC15),
      flagColors: [Color(0xFF1E3A8A), Color(0xFFF3F4F6), Color(0xFFDC2626)],
      patternStyle: NationalKitPatternStyle.gradientWave,
      bibNumberSample: '91',
      uciNationRank: 10,
    ),
    NationalTeamKitSpec(
      countryCode: 'USA',
      countryNamePl: 'USA',
      federationTitle: 'USA Cycling',
      chestEmblemCode: 'USA',
      primaryColor: Color(0xFF1E3A8A),
      secondaryColor: Color(0xFFDC2626),
      accentColor: Color(0xFFF3F4F6),
      shortsColor: Color(0xFF0F172A),
      collarColor: Color(0xFFDC2626),
      sockColor: Color(0xFFF3F4F6),
      flagColors: [Color(0xFF1E3A8A), Color(0xFFF3F4F6), Color(0xFFDC2626)],
      patternStyle: NationalKitPatternStyle.verticalPinstripe,
      bibNumberSample: '101',
      uciNationRank: 12,
    ),
    NationalTeamKitSpec(
      countryCode: 'SUI',
      countryNamePl: 'Szwajcaria',
      federationTitle: 'Swiss Cycling',
      chestEmblemCode: 'SUI',
      primaryColor: Color(0xFFD52B1E),
      secondaryColor: Color(0xFFF3F4F6),
      accentColor: Color(0xFF7F1D1D),
      shortsColor: Color(0xFF161920),
      collarColor: Color(0xFFF3F4F6),
      sockColor: Color(0xFFD52B1E),
      flagColors: [Color(0xFFD52B1E), Color(0xFFF3F4F6)],
      patternStyle: NationalKitPatternStyle.alpineCross,
      bibNumberSample: '111',
      uciNationRank: 13,
    ),
    NationalTeamKitSpec(
      countryCode: 'NOR',
      countryNamePl: 'Norwegia',
      federationTitle: 'NCF — Norges Cykleforbund',
      chestEmblemCode: 'NOR',
      primaryColor: Color(0xFFBA0C2F),
      secondaryColor: Color(0xFF00205B),
      accentColor: Color(0xFFF3F4F6),
      shortsColor: Color(0xFF0F172A),
      collarColor: Color(0xFF00205B),
      sockColor: Color(0xFFF3F4F6),
      flagColors: [Color(0xFFBA0C2F), Color(0xFFF3F4F6), Color(0xFF00205B)],
      patternStyle: NationalKitPatternStyle.alpineCross,
      bibNumberSample: '121',
      uciNationRank: 14,
    ),
    NationalTeamKitSpec(
      countryCode: 'GER',
      countryNamePl: 'Niemcy',
      federationTitle: 'BDR — Bund Deutscher Radfahrer',
      chestEmblemCode: 'GER',
      primaryColor: Color(0xFFF3F4F6),
      secondaryColor: Color(0xFF18181B),
      accentColor: Color(0xFFEAB308),
      shortsColor: Color(0xFF111318),
      collarColor: Color(0xFFDC2626),
      sockColor: Color(0xFFF3F4F6),
      flagColors: [Color(0xFF18181B), Color(0xFFDC2626), Color(0xFFEAB308)],
      patternStyle: NationalKitPatternStyle.gradientWave,
      bibNumberSample: '131',
      uciNationRank: 15,
    ),
    NationalTeamKitSpec(
      countryCode: 'POR',
      countryNamePl: 'Portugalia',
      federationTitle: 'FPC — Seleção Portuguesa',
      chestEmblemCode: 'POR',
      primaryColor: Color(0xFF991B1B),
      secondaryColor: Color(0xFF15803D),
      accentColor: Color(0xFFD4AF37),
      shortsColor: Color(0xFF14181F),
      collarColor: Color(0xFF15803D),
      sockColor: Color(0xFF991B1B),
      flagColors: [Color(0xFF15803D), Color(0xFFDC2626)],
      patternStyle: NationalKitPatternStyle.gradientWave,
      bibNumberSample: '141',
      uciNationRank: 16,
    ),
  ];

  /// Zwraca oficjalną specyfikację koszulki dla podanego kodu kraju lub generuje deterministyczny zestaw fallback.
  static NationalTeamKitSpec byCountryCode(String countryCode) {
    final normalized = countryCode.trim().toUpperCase();
    for (final spec in officialKits) {
      if (spec.countryCode == normalized) {
        return spec;
      }
    }
    final hash = normalized.codeUnits.fold<int>(17, (acc, c) => acc * 31 + c);
    final hue = (hash % 360).toDouble();
    final primary = HSLColor.fromAHSL(1.0, hue, 0.72, 0.48).toColor();
    final secondary =
        HSLColor.fromAHSL(1.0, (hue + 150) % 360, 0.76, 0.56).toColor();
    return NationalTeamKitSpec(
      countryCode: normalized.isEmpty ? 'UCI' : normalized,
      countryNamePl: normalized.isEmpty ? 'Reprezentacja' : normalized,
      federationTitle: 'Federacja $normalized',
      chestEmblemCode: normalized.isEmpty ? 'UCI' : normalized,
      primaryColor: primary,
      secondaryColor: secondary,
      accentColor: AppColors.goldAccent,
      shortsColor: const Color(0xFF141821),
      collarColor: secondary,
      sockColor: primary,
      flagColors: [primary, secondary, AppColors.textPrimary],
      patternStyle: NationalKitPatternStyle
          .values[hash.abs() % NationalKitPatternStyle.values.length],
      bibNumberSample: '${(hash.abs() % 89) + 10}',
      uciNationRank: 25,
    );
  }
}

// =============================================================================
// 3. KONFIGURACJA RENDERERA 3D I TELEMETRIA KLATKI
// =============================================================================

/// Stan konfiguracji renderera 3D oficjalnych koszulek reprezentacji narodowych.
@immutable
class NationalKit3dRenderConfig {
  final String selectedCountryCode;
  final NationalTeamKitEventVariant eventVariant;
  final NationalKitHelmetAndBibMode helmetAndBibMode;
  final double riderYawRadians;
  final double riderPitchRadians;
  final double cameraDistanceMeters;
  final double cadenceRpm;
  final double windSpeedMs;
  final bool showPelotonComparison;
  final bool showSponsorAndFederationPatches;
  final bool showLightingAndSpecular;

  const NationalKit3dRenderConfig({
    this.selectedCountryCode = 'POL',
    this.eventVariant = NationalTeamKitEventVariant.worldChampionshipsRoad,
    this.helmetAndBibMode = NationalKitHelmetAndBibMode.standardNational,
    this.riderYawRadians = -0.58,
    this.riderPitchRadians = 0.24,
    this.cameraDistanceMeters = 3.15,
    this.cadenceRpm = 92.0,
    this.windSpeedMs = 12.5,
    this.showPelotonComparison = false,
    this.showSponsorAndFederationPatches = true,
    this.showLightingAndSpecular = true,
  });

  NationalKit3dRenderConfig copyWith({
    String? selectedCountryCode,
    NationalTeamKitEventVariant? eventVariant,
    NationalKitHelmetAndBibMode? helmetAndBibMode,
    double? riderYawRadians,
    double? riderPitchRadians,
    double? cameraDistanceMeters,
    double? cadenceRpm,
    double? windSpeedMs,
    bool? showPelotonComparison,
    bool? showSponsorAndFederationPatches,
    bool? showLightingAndSpecular,
  }) {
    return NationalKit3dRenderConfig(
      selectedCountryCode: selectedCountryCode ?? this.selectedCountryCode,
      eventVariant: eventVariant ?? this.eventVariant,
      helmetAndBibMode: helmetAndBibMode ?? this.helmetAndBibMode,
      riderYawRadians: riderYawRadians ?? this.riderYawRadians,
      riderPitchRadians: (pitchClamp(riderPitchRadians ?? this.riderPitchRadians)),
      cameraDistanceMeters:
          (cameraDistanceMeters ?? this.cameraDistanceMeters).clamp(2.1, 5.2),
      cadenceRpm: (cadenceRpm ?? this.cadenceRpm).clamp(0.0, 130.0),
      windSpeedMs: (windSpeedMs ?? this.windSpeedMs).clamp(0.0, 25.0),
      showPelotonComparison:
          showPelotonComparison ?? this.showPelotonComparison,
      showSponsorAndFederationPatches: showSponsorAndFederationPatches ??
          this.showSponsorAndFederationPatches,
      showLightingAndSpecular:
          showLightingAndSpecular ?? this.showLightingAndSpecular,
    );
  }

  static double pitchClamp(double value) => value.clamp(0.04, 0.92);

  Map<String, dynamic> toJson() => {
        'selectedCountryCode': selectedCountryCode,
        'eventVariant': eventVariant.toJson(),
        'helmetAndBibMode': helmetAndBibMode.toJson(),
        'riderYawRadians': riderYawRadians,
        'riderPitchRadians': riderPitchRadians,
        'cameraDistanceMeters': cameraDistanceMeters,
        'cadenceRpm': cadenceRpm,
        'windSpeedMs': windSpeedMs,
        'showPelotonComparison': showPelotonComparison,
        'showSponsorAndFederationPatches': showSponsorAndFederationPatches,
        'showLightingAndSpecular': showLightingAndSpecular,
      };

  factory NationalKit3dRenderConfig.fromJson(Map<String, dynamic> json) {
    return NationalKit3dRenderConfig(
      selectedCountryCode: (json['selectedCountryCode'] as String?) ?? 'POL',
      eventVariant: NationalTeamKitEventVariant.fromJson(
        json['eventVariant'] as String?,
      ),
      helmetAndBibMode: NationalKitHelmetAndBibMode.fromJson(
        json['helmetAndBibMode'] as String?,
      ),
      riderYawRadians: (json['riderYawRadians'] as num?)?.toDouble() ?? -0.58,
      riderPitchRadians: (json['riderPitchRadians'] as num?)?.toDouble() ?? 0.24,
      cameraDistanceMeters:
          (json['cameraDistanceMeters'] as num?)?.toDouble() ?? 3.15,
      cadenceRpm: (json['cadenceRpm'] as num?)?.toDouble() ?? 92.0,
      windSpeedMs: (json['windSpeedMs'] as num?)?.toDouble() ?? 12.5,
      showPelotonComparison: (json['showPelotonComparison'] as bool?) ?? false,
      showSponsorAndFederationPatches:
          (json['showSponsorAndFederationPatches'] as bool?) ?? true,
      showLightingAndSpecular:
          (json['showLightingAndSpecular'] as bool?) ?? true,
    );
  }
}

/// Rzutowany punkt 3D na ekranie 2D wraz z głębią Z dla sortowania malarskiego.
@immutable
class ProjectedKitPoint3D {
  final Offset offset;
  final double depth;
  final double scale;
  final bool visible;

  const ProjectedKitPoint3D({
    required this.offset,
    required this.depth,
    required this.scale,
    required this.visible,
  });
}

/// Telemetria klatki wyrenderowanej przez [NationalTeamCustomKits3dRenderer].
@immutable
class NationalKit3dProjectedMeshStats {
  final int riderCount;
  final int projectedVerticesCount;
  final int renderedPrimitivesCount;
  final double cameraOrbitDeg;
  final String activeCountryCode;
  final String eventVariantTag;

  const NationalKit3dProjectedMeshStats({
    required this.riderCount,
    required this.projectedVerticesCount,
    required this.renderedPrimitivesCount,
    required this.cameraOrbitDeg,
    required this.activeCountryCode,
    required this.eventVariantTag,
  });
}

// =============================================================================
// 4. SILNIK MATEMATYCZNY I GEOMETRYCZNY 3D (CZYSTY DART + VECTOR_MATH_64)
// =============================================================================

/// Silnik obliczeniowy 3D do rzutowania i cieniowania oficjalnych koszulek reprezentacji.
class NationalTeamCustomKits3dRenderer {
  const NationalTeamCustomKits3dRenderer();

  static const double _focalLengthFactor = 1.48;
  static const List<Color> uciRainbowColors = [
    Color(0xFF0081C8), // Niebieski
    Color(0xFFEF3340), // Czerwony
    Color(0xFF111318), // Czarny
    Color(0xFFFAB700), // Żółty
    Color(0xFF009F3D), // Zielony
  ];

  /// Rzutuje punkt w przestrzeni świata 3D (X: prawo, Y: góra, Z: przód) na płótno 2D.
  ProjectedKitPoint3D projectWorldPoint({
    required Vector3 worldPoint,
    required NationalKit3dRenderConfig config,
    required Size viewportSize,
  }) {
    final target = Vector3(0.0, 0.88, 0.0);
    final rel = worldPoint - target;

    // Obrót kamery wokół osi Y (yaw) oraz pochylenie (pitch).
    final cosYaw = math.cos(config.riderYawRadians);
    final sinYaw = math.sin(config.riderYawRadians);
    final xYaw = rel.x * cosYaw - rel.z * sinYaw;
    final zYaw = rel.x * sinYaw + rel.z * cosYaw;

    final cosPitch = math.cos(config.riderPitchRadians);
    final sinPitch = math.sin(config.riderPitchRadians);
    final yCam = rel.y * cosPitch - zYaw * sinPitch;
    final zCam = rel.y * sinPitch + zYaw * cosPitch + config.cameraDistanceMeters;

    if (zCam <= 0.25) {
      return const ProjectedKitPoint3D(
        offset: Offset.zero,
        depth: 0.25,
        scale: 0.0,
        visible: false,
      );
    }

    final minDim = math.min(viewportSize.width, viewportSize.height);
    final focalPx = minDim * _focalLengthFactor;
    final scale = focalPx / zCam;

    final screenX = viewportSize.width * 0.5 + xYaw * scale;
    final screenY = viewportSize.height * 0.54 - yCam * scale;

    return ProjectedKitPoint3D(
      offset: Offset(screenX, screenY),
      depth: zCam,
      scale: scale,
      visible: true,
    );
  }

  /// Oblicza współczynnik oświetlenia Lamberta + światła obrysowego dla ścianki 3D koszulki.
  double evaluateFabricLuminance({
    required Vector3 surfaceNormal,
    required NationalKit3dRenderConfig config,
  }) {
    if (!config.showLightingAndSpecular) return 0.88;

    final lightDir = Vector3(0.55, 0.78, 0.62)..normalize();
    final n = surfaceNormal.normalized();
    final diffuse = math.max(0.0, n.dot(lightDir));
    final rim = math.pow(1.0 - math.max(0.0, n.z.abs()), 2.0) * 0.16;
    return (0.44 + diffuse * 0.56 + rim).clamp(0.32, 1.12);
  }

  /// Cieniuje kolor tkaniny zgodnie z obliczoną luminancją 3D.
  Color shadeFabricColor(Color base, double luminance) {
    final hsl = HSLColor.fromColor(base);
    final adjustedLightness = (hsl.lightness * luminance).clamp(0.06, 0.96);
    return hsl.withLightness(adjustedLightness).toColor();
  }

  /// Oblicza kąt fazy korby [rad] dla danej kadencji i czasu animacji.
  double computeCrankPhaseRadians({
    required double animationSeconds,
    required double cadenceRpm,
  }) {
    return animationSeconds * (cadenceRpm / 60.0) * 2.0 * math.pi;
  }

  /// Wylicza telemetrię klatki 3D na podstawie aktualnej konfiguracji.
  NationalKit3dProjectedMeshStats computeFrameStats(
    NationalKit3dRenderConfig config,
  ) {
    final riderCount = config.showPelotonComparison ? 3 : 1;
    final verticesPerRider = config.eventVariant.isTimeTrial ? 74 : 68;
    final primitivesPerRider = config.eventVariant.isTimeTrial ? 48 : 42;
    final orbitDeg =
        ((config.riderYawRadians * 180.0 / math.pi) % 360.0 + 360.0) % 360.0;

    return NationalKit3dProjectedMeshStats(
      riderCount: riderCount,
      projectedVerticesCount: riderCount * verticesPerRider,
      renderedPrimitivesCount: riderCount * primitivesPerRider + 18,
      cameraOrbitDeg: orbitDeg,
      activeCountryCode: config.selectedCountryCode,
      eventVariantTag: config.eventVariant.shortTag,
    );
  }
}

// =============================================================================
// 5. CUSTOM PAINTER 3D: SCENA PODIUM/SZOSY, ROWER, KOLARZ I KOSZULKA NARODOWA
// =============================================================================

/// Painter 3D renderujący oficjalne koszulki reprezentacji narodowych na modelu kolarza 3D.
class NationalTeamCustomKits3dPainter extends CustomPainter {
  final NationalKit3dRenderConfig config;
  final NationalTeamKitSpec kitSpec;
  final double animationSeconds;
  final NationalTeamCustomKits3dRenderer renderer;

  const NationalTeamCustomKits3dPainter({
    required this.config,
    required this.kitSpec,
    required this.animationSeconds,
    this.renderer = const NationalTeamCustomKits3dRenderer(),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    _drawStudioBackdrop(canvas, size);
    _draw3dAsphaltPlatform(canvas, size);

    // Przygotowanie kolarzy (pojedynczy lider lub 3-osobowy wachlarz reprezentacji).
    final riderOffsets = config.showPelotonComparison
        ? <Vector3>[
            Vector3(-0.72, 0.0, -0.75),
            Vector3(0.68, 0.0, -0.58),
            Vector3(0.0, 0.0, 0.12),
          ]
        : <Vector3>[Vector3.zero()];

    // Sortowanie od najdalszego kolarza do najbliższego kamerze.
    final sortedOffsets = List<Vector3>.from(riderOffsets)
      ..sort((a, b) {
        final pa = renderer.projectWorldPoint(
          worldPoint: a + Vector3(0.0, 0.9, 0.0),
          config: config,
          viewportSize: size,
        );
        final pb = renderer.projectWorldPoint(
          worldPoint: b + Vector3(0.0, 0.9, 0.0),
          config: config,
          viewportSize: size,
        );
        return pb.depth.compareTo(pa.depth);
      });

    for (var i = 0; i < sortedOffsets.length; i++) {
      final isHero =
          sortedOffsets[i].x.abs() < 0.05 && sortedOffsets[i].z.abs() < 0.2;
      _drawRiderAndBike3D(
        canvas: canvas,
        size: size,
        origin: sortedOffsets[i],
        phaseOffset: i * 1.15,
        isHeroRider: isHero,
      );
    }
  }

  void _drawStudioBackdrop(Canvas canvas, Size size) {
    final bgRect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.5, size.height * 0.42),
        math.max(size.width, size.height) * 0.72,
        [
          kitSpec.primaryColor.withValues(alpha: 0.14),
          AppColors.surface,
          AppColors.background,
        ],
        const [0.0, 0.46, 1.0],
      );
    canvas.drawRect(bgRect, bgPaint);

    // Subtelny reflektor podiumowy od góry.
    if (config.showLightingAndSpecular) {
      final spotlight = Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width * 0.5, 0),
          Offset(size.width * 0.5, size.height * 0.78),
          [
            Colors.white.withValues(alpha: 0.07),
            Colors.transparent,
          ],
        );
      canvas.drawRect(bgRect, spotlight);
    }
  }

  void _draw3dAsphaltPlatform(Canvas canvas, Size size) {
    final corners = [
      Vector3(-1.85, 0.0, -1.75),
      Vector3(1.85, 0.0, -1.75),
      Vector3(1.85, 0.0, 1.75),
      Vector3(-1.85, 0.0, 1.75),
    ]
        .map(
          (p) => renderer.projectWorldPoint(
            worldPoint: p,
            config: config,
            viewportSize: size,
          ),
        )
        .toList();

    if (corners.any((c) => !c.visible)) return;

    final roadPath = Path()
      ..moveTo(corners[0].offset.dx, corners[0].offset.dy)
      ..lineTo(corners[1].offset.dx, corners[1].offset.dy)
      ..lineTo(corners[2].offset.dx, corners[2].offset.dy)
      ..lineTo(corners[3].offset.dx, corners[3].offset.dy)
      ..close();

    final roadPaint = Paint()
      ..color = const Color(0xFF141820).withValues(alpha: 0.94)
      ..style = PaintingStyle.fill;
    canvas.drawPath(roadPath, roadPaint);

    final borderPaint = Paint()
      ..color = AppTheme.borderColor.withValues(alpha: 0.75)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawPath(roadPath, borderPaint);

    // Siatka perspektywiczna nawierzchni.
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..strokeWidth = 1.0;

    for (var x = -1.5; x <= 1.51; x += 0.5) {
      final a = renderer.projectWorldPoint(
        worldPoint: Vector3(x, 0.002, -1.75),
        config: config,
        viewportSize: size,
      );
      final b = renderer.projectWorldPoint(
        worldPoint: Vector3(x, 0.002, 1.75),
        config: config,
        viewportSize: size,
      );
      if (a.visible && b.visible) {
        canvas.drawLine(a.offset, b.offset, gridPaint);
      }
    }

    // Pasy w barwach flagi narodowej na krawędziach podestu szosowego.
    final flagCount = kitSpec.flagColors.length;
    for (var i = 0; i < flagCount; i++) {
      final stripX = -1.72 + i * 0.07;
      final p1 = renderer.projectWorldPoint(
        worldPoint: Vector3(stripX, 0.005, -1.65),
        config: config,
        viewportSize: size,
      );
      final p2 = renderer.projectWorldPoint(
        worldPoint: Vector3(stripX, 0.005, 1.65),
        config: config,
        viewportSize: size,
      );
      if (p1.visible && p2.visible) {
        canvas.drawLine(
          p1.offset,
          p2.offset,
          Paint()
            ..color = kitSpec.flagColors[i].withValues(alpha: 0.85)
            ..strokeWidth = 3.0
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  void _drawRiderAndBike3D({
    required Canvas canvas,
    required Size size,
    required Vector3 origin,
    required double phaseOffset,
    required bool isHeroRider,
  }) {
    final crankPhase = renderer.computeCrankPhaseRadians(
          animationSeconds: animationSeconds,
          cadenceRpm: config.cadenceRpm,
        ) +
        phaseOffset;
    final flutterWave =
        math.sin(animationSeconds * (4.0 + config.windSpeedMs * 0.35) + phaseOffset) *
            0.014 *
            (config.windSpeedMs / 12.0).clamp(0.2, 1.8);

    ProjectedKitPoint3D p(double x, double y, double z) =>
        renderer.projectWorldPoint(
          worldPoint: Vector3(origin.x + x, origin.y + y, origin.z + z),
          config: config,
          viewportSize: size,
        );

    // 1. Miękki cień kontaktowy na asfalcie.
    final shadowFront = p(0.0, 0.006, 0.62);
    final shadowRear = p(0.0, 0.006, -0.62);
    if (shadowFront.visible && shadowRear.visible) {
      canvas.drawLine(
        shadowRear.offset,
        shadowFront.offset,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.52)
          ..strokeWidth = (0.36 * shadowFront.scale).clamp(10.0, 44.0)
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0),
      );
    }

    // 2. Koła 3D (dysk tylny w trybie ITT lub szprychy karbonowe).
    final rearHub = p(0.0, 0.34, -0.50);
    final frontHub = p(0.0, 0.34, 0.52);
    final bb = p(0.0, 0.31, -0.05);
    final seatTop = p(0.0, 0.86, -0.22);
    final headTop = p(0.0, 0.82, 0.36);

    final isGoldFrame =
        config.helmetAndBibMode == NationalKitHelmetAndBibMode.olympicChampionGold &&
            isHeroRider;
    final frameColor = isGoldFrame
        ? AppColors.goldAccent
        : kitSpec.primaryColor.computeLuminance() > 0.72
            ? const Color(0xFF1F2937)
            : kitSpec.primaryColor;

    _drawWheel3D(
      canvas: canvas,
      size: size,
      origin: origin,
      centerZ: -0.50,
      isDiscWheel: config.eventVariant.isTimeTrial,
      wheelPhase: crankPhase * 2.4,
      accentColor: isGoldFrame ? AppColors.goldAccent : kitSpec.accentColor,
    );
    _drawWheel3D(
      canvas: canvas,
      size: size,
      origin: origin,
      centerZ: 0.52,
      isDiscWheel: false,
      wheelPhase: crankPhase * 2.4,
      accentColor: isGoldFrame ? AppColors.goldAccent : kitSpec.accentColor,
    );

    // 3. Rama karbonowa roweru szosowego / TT.
    if (rearHub.visible &&
        frontHub.visible &&
        bb.visible &&
        seatTop.visible &&
        headTop.visible) {
      final tubeWidth = (0.030 * bb.scale).clamp(2.4, 7.2);
      final framePaint = Paint()
        ..color = frameColor
        ..strokeWidth = tubeWidth
        ..strokeCap = StrokeCap.round;
      final chainStayPaint = Paint()
        ..color = frameColor.withValues(alpha: 0.9)
        ..strokeWidth = tubeWidth * 0.72
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(rearHub.offset, bb.offset, chainStayPaint);
      canvas.drawLine(rearHub.offset, seatTop.offset, chainStayPaint);
      canvas.drawLine(bb.offset, seatTop.offset, framePaint);
      canvas.drawLine(bb.offset, headTop.offset, framePaint);
      canvas.drawLine(seatTop.offset, headTop.offset, framePaint);
      canvas.drawLine(headTop.offset, frontHub.offset, framePaint);

      // Kierownica (baranek szosowy lub lemondka TT).
      final barCenter = p(0.0, 0.88, 0.44);
      final barLeft = p(-0.18, config.eventVariant.isTimeTrial ? 0.90 : 0.85, 0.46);
      final barRight = p(0.18, config.eventVariant.isTimeTrial ? 0.90 : 0.85, 0.46);
      if (barCenter.visible && barLeft.visible && barRight.visible) {
        final barPaint = Paint()
          ..color = const Color(0xFF272C38)
          ..strokeWidth = tubeWidth * 0.72
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(headTop.offset, barCenter.offset, barPaint);
        canvas.drawLine(barLeft.offset, barRight.offset, barPaint);
        if (config.eventVariant.isTimeTrial) {
          final aeroTipL = p(-0.06, 0.94, 0.64);
          final aeroTipR = p(0.06, 0.94, 0.64);
          if (aeroTipL.visible && aeroTipR.visible) {
            canvas.drawLine(barCenter.offset, aeroTipL.offset, barPaint);
            canvas.drawLine(barCenter.offset, aeroTipR.offset, barPaint);
          }
        }
      }
    }

    // 4. Nogi pedałujące, spodenki kolarskie i skarpety reprezentacji.
    _drawRiderLegsAndShorts(
      canvas: canvas,
      size: size,
      origin: origin,
      crankPhase: crankPhase,
      isGoldMode: isGoldFrame,
    );

    // 5. Tułów 3D z oficjalnym wzorem koszulki reprezentacji narodowej.
    _drawNationalJerseyTorso3D(
      canvas: canvas,
      size: size,
      origin: origin,
      flutterWave: flutterWave,
      isHeroRider: isHeroRider,
    );

    // 6. Ręce, kask aero/TT i okulary wyścigowe.
    _drawArmsAndHelmet3D(
      canvas: canvas,
      size: size,
      origin: origin,
      flutterWave: flutterWave,
      isHeroRider: isHeroRider,
    );
  }

  void _drawWheel3D({
    required Canvas canvas,
    required Size size,
    required Vector3 origin,
    required double centerZ,
    required bool isDiscWheel,
    required double wheelPhase,
    required Color accentColor,
  }) {
    const segments = 22;
    const radius = 0.34;
    final pts = <Offset>[];
    for (var i = 0; i < segments; i++) {
      final a = (i / segments) * math.pi * 2.0;
      final wp = renderer.projectWorldPoint(
        worldPoint: Vector3(
          origin.x,
          origin.y + radius + math.sin(a) * radius,
          origin.z + centerZ + math.cos(a) * radius,
        ),
        config: config,
        viewportSize: size,
      );
      if (!wp.visible) return;
      pts.add(wp.offset);
    }

    final wheelPath = Path()..addPolygon(pts, true);
    final hub = renderer.projectWorldPoint(
      worldPoint: Vector3(origin.x, origin.y + radius, origin.z + centerZ),
      config: config,
      viewportSize: size,
    );
    if (!hub.visible) return;

    if (isDiscWheel) {
      canvas.drawPath(
        wheelPath,
        Paint()
          ..color = const Color(0xFF151922)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        wheelPath,
        Paint()
          ..color = accentColor.withValues(alpha: 0.72)
          ..strokeWidth = (0.018 * hub.scale).clamp(1.5, 4.0)
          ..style = PaintingStyle.stroke,
      );
    } else {
      // Obręcz karbonowa i opona.
      canvas.drawPath(
        wheelPath,
        Paint()
          ..color = const Color(0xFF1A1F29)
          ..strokeWidth = (0.026 * hub.scale).clamp(2.2, 5.8)
          ..style = PaintingStyle.stroke,
      );
      // Szprychy obracające się zgodnie z kadencją.
      final spokePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..strokeWidth = 1.0;
      for (var s = 0; s < 6; s++) {
        final sa = wheelPhase + s * (math.pi / 3.0);
        final rimPt = renderer.projectWorldPoint(
          worldPoint: Vector3(
            origin.x,
            origin.y + radius + math.sin(sa) * (radius - 0.02),
            origin.z + centerZ + math.cos(sa) * (radius - 0.02),
          ),
          config: config,
          viewportSize: size,
        );
        if (rimPt.visible) {
          canvas.drawLine(hub.offset, rimPt.offset, spokePaint);
        }
      }
    }

    canvas.drawCircle(
      hub.offset,
      (0.024 * hub.scale).clamp(2.0, 5.0),
      Paint()..color = accentColor,
    );
  }

  void _drawRiderLegsAndShorts({
    required Canvas canvas,
    required Size size,
    required Vector3 origin,
    required double crankPhase,
    required bool isGoldMode,
  }) {
    for (var side = -1; side <= 1; side += 2) {
      final phase = side == -1 ? crankPhase : crankPhase + math.pi;
      final hip = renderer.projectWorldPoint(
        worldPoint: Vector3(origin.x + side * 0.11, origin.y + 0.94, origin.z - 0.21),
        config: config,
        viewportSize: size,
      );
      final pedalZ = -0.05 + math.cos(phase) * 0.17;
      final pedalY = 0.31 + math.sin(phase) * 0.17;
      final kneeZ = (-0.21 + pedalZ) * 0.5 + 0.12;
      final kneeY = (0.94 + pedalY) * 0.5 + 0.07;

      final knee = renderer.projectWorldPoint(
        worldPoint: Vector3(origin.x + side * 0.12, origin.y + kneeY, origin.z + kneeZ),
        config: config,
        viewportSize: size,
      );
      final ankle = renderer.projectWorldPoint(
        worldPoint: Vector3(origin.x + side * 0.11, origin.y + pedalY, origin.z + pedalZ),
        config: config,
        viewportSize: size,
      );

      if (!hip.visible || !knee.visible || !ankle.visible) continue;

      final legWidth = (0.088 * hip.scale).clamp(5.0, 18.0);
      // Spodenki (górna część uda).
      final midThigh = Offset.lerp(hip.offset, knee.offset, 0.72)!;
      canvas.drawLine(
        hip.offset,
        midThigh,
        Paint()
          ..color = kitSpec.shortsColor
          ..strokeWidth = legWidth * 1.15
          ..strokeCap = StrokeCap.round,
      );
      // Skóra dolnej części uda i łydki.
      canvas.drawLine(
        midThigh,
        knee.offset,
        Paint()
          ..color = const Color(0xFFD6A888)
          ..strokeWidth = legWidth * 0.92
          ..strokeCap = StrokeCap.round,
      );
      final sockStart = Offset.lerp(knee.offset, ankle.offset, 0.54)!;
      canvas.drawLine(
        knee.offset,
        sockStart,
        Paint()
          ..color = const Color(0xFFD6A888)
          ..strokeWidth = legWidth * 0.78
          ..strokeCap = StrokeCap.round,
      );
      // Wysokie skarpety narodowe.
      canvas.drawLine(
        sockStart,
        ankle.offset,
        Paint()
          ..color = kitSpec.sockColor
          ..strokeWidth = legWidth * 0.74
          ..strokeCap = StrokeCap.round,
      );
      // But kolarski (złoty w trybie Mistrza Olimpijskiego).
      canvas.drawCircle(
        ankle.offset,
        (0.036 * ankle.scale).clamp(3.0, 7.5),
        Paint()
          ..color = isGoldMode ? AppColors.goldAccent : const Color(0xFFF3F4F6),
      );
    }
  }

  void _drawNationalJerseyTorso3D({
    required Canvas canvas,
    required Size size,
    required Vector3 origin,
    required double flutterWave,
    required bool isHeroRider,
  }) {
    final isAeroPosture = config.eventVariant.isTimeTrial;
    final shoulderY = isAeroPosture ? 1.15 : 1.24;
    final shoulderZ = isAeroPosture ? 0.16 : 0.10;

    final hipL = Vector3(origin.x - 0.14, origin.y + 0.94, origin.z - 0.22);
    final hipR = Vector3(origin.x + 0.14, origin.y + 0.94, origin.z - 0.22);
    final shL = Vector3(
      origin.x - 0.19,
      origin.y + shoulderY + flutterWave,
      origin.z + shoulderZ,
    );
    final shR = Vector3(
      origin.x + 0.19,
      origin.y + shoulderY - flutterWave,
      origin.z + shoulderZ,
    );
    final spineMid = Vector3(
      origin.x,
      origin.y + (0.94 + shoulderY) * 0.5 + 0.05,
      origin.z + (-0.22 + shoulderZ) * 0.5 - 0.04,
    );

    final pHipL = renderer.projectWorldPoint(
      worldPoint: hipL,
      config: config,
      viewportSize: size,
    );
    final pHipR = renderer.projectWorldPoint(
      worldPoint: hipR,
      config: config,
      viewportSize: size,
    );
    final pShL = renderer.projectWorldPoint(
      worldPoint: shL,
      config: config,
      viewportSize: size,
    );
    final pShR = renderer.projectWorldPoint(
      worldPoint: shR,
      config: config,
      viewportSize: size,
    );
    final pSpine = renderer.projectWorldPoint(
      worldPoint: spineMid,
      config: config,
      viewportSize: size,
    );

    if (!pHipL.visible || !pHipR.visible || !pShL.visible || !pShR.visible) {
      return;
    }

    // Dwa panele 3D (lewa i prawa połowa tułowia) dla realistycznego cieniowania.
    final lumLeft = renderer.evaluateFabricLuminance(
      surfaceNormal: Vector3(-0.45, 0.78, 0.42),
      config: config,
    );
    final lumRight = renderer.evaluateFabricLuminance(
      surfaceNormal: Vector3(0.45, 0.78, 0.42),
      config: config,
    );

    final torsoPath = Path()
      ..moveTo(pHipL.offset.dx, pHipL.offset.dy)
      ..lineTo(pShL.offset.dx, pShL.offset.dy)
      ..lineTo(pShR.offset.dx, pShR.offset.dy)
      ..lineTo(pHipR.offset.dx, pHipR.offset.dy)
      ..close();

    final leftPanel = Path()
      ..moveTo(pHipL.offset.dx, pHipL.offset.dy)
      ..lineTo(pShL.offset.dx, pShL.offset.dy)
      ..lineTo(
        (pShL.offset.dx + pShR.offset.dx) * 0.5,
        (pShL.offset.dy + pShR.offset.dy) * 0.5,
      )
      ..lineTo(pSpine.offset.dx, pSpine.offset.dy)
      ..lineTo(
        (pHipL.offset.dx + pHipR.offset.dx) * 0.5,
        (pHipL.offset.dy + pHipR.offset.dy) * 0.5,
      )
      ..close();

    final rightPanel = Path()
      ..moveTo(pHipR.offset.dx, pHipR.offset.dy)
      ..lineTo(pShR.offset.dx, pShR.offset.dy)
      ..lineTo(
        (pShL.offset.dx + pShR.offset.dx) * 0.5,
        (pShL.offset.dy + pShR.offset.dy) * 0.5,
      )
      ..lineTo(pSpine.offset.dx, pSpine.offset.dy)
      ..lineTo(
        (pHipL.offset.dx + pHipR.offset.dx) * 0.5,
        (pHipL.offset.dy + pHipR.offset.dy) * 0.5,
      )
      ..close();

    canvas.drawPath(
      leftPanel,
      Paint()..color = renderer.shadeFabricColor(kitSpec.primaryColor, lumLeft),
    );
    canvas.drawPath(
      rightPanel,
      Paint()..color = renderer.shadeFabricColor(kitSpec.primaryColor, lumRight),
    );

    // Clip na tułów i naniesienie oficjalnego wzoru reprezentacji narodowej.
    canvas.save();
    canvas.clipPath(torsoPath);
    _paintJerseyPatternOverlay(
      canvas: canvas,
      pHipL: pHipL.offset,
      pHipR: pHipR.offset,
      pShL: pShL.offset,
      pShR: pShR.offset,
    );

    // Opcjonalne paski Mistrza Świata UCI (tęcza na kołnierzu) lub Złote IO.
    if (config.helmetAndBibMode ==
            NationalKitHelmetAndBibMode.reigningWorldChampion &&
        isHeroRider) {
      final collarMid = Offset.lerp(pShL.offset, pShR.offset, 0.5)!;
      for (var i = 0; i < NationalTeamCustomKits3dRenderer.uciRainbowColors.length; i++) {
        final dy = i * 2.2;
        canvas.drawLine(
          Offset(pShL.offset.dx, collarMid.dy + dy),
          Offset(pShR.offset.dx, collarMid.dy + dy),
          Paint()
            ..color = NationalTeamCustomKits3dRenderer.uciRainbowColors[i]
            ..strokeWidth = 2.0,
        );
      }
    }

    // Naszywka federacji i numer startowy na plecach / piersi.
    if (config.showSponsorAndFederationPatches) {
      final center = Offset(
        (pHipL.offset.dx + pHipR.offset.dx + pShL.offset.dx + pShR.offset.dx) * 0.25,
        (pHipL.offset.dy + pHipR.offset.dy + pShL.offset.dy + pShR.offset.dy) * 0.25,
      );
      final fontSize = (0.068 * pSpine.scale).clamp(7.0, 15.0);
      final isRearView = math.cos(config.riderYawRadians) < -0.2;

      if (isRearView) {
        // Numer startowy na plecach.
        final bibRect = Rect.fromCenter(
          center: center + Offset(0, fontSize * 0.65),
          width: fontSize * 2.6,
          height: fontSize * 1.5,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(bibRect, const Radius.circular(3)),
          Paint()..color = const Color(0xFFF3F4F6),
        );
        _drawCenteredText(
          canvas: canvas,
          text: kitSpec.bibNumberSample,
          center: bibRect.center,
          color: const Color(0xFF111318),
          fontSize: fontSize * 0.95,
          fontWeight: FontWeight.w800,
        );
      } else {
        // Kod federacji na piersi/plecach.
        _drawCenteredText(
          canvas: canvas,
          text: kitSpec.chestEmblemCode,
          center: center,
          color: kitSpec.primaryColor.computeLuminance() > 0.55
              ? const Color(0xFF111318)
              : const Color(0xFFF3F4F6),
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
        );
      }
    }
    canvas.restore();

    // Krawędź konturowa koszulki i zamek błyskawiczny.
    canvas.drawPath(
      torsoPath,
      Paint()
        ..color = kitSpec.collarColor.withValues(alpha: 0.65)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke,
    );
  }

  void _paintJerseyPatternOverlay({
    required Canvas canvas,
    required Offset pHipL,
    required Offset pHipR,
    required Offset pShL,
    required Offset pShR,
  }) {
    final topMid = Offset.lerp(pShL, pShR, 0.5)!;
    final botMid = Offset.lerp(pHipL, pHipR, 0.5)!;

    switch (kitSpec.patternStyle) {
      case NationalKitPatternStyle.chestBand:
        final a1 = Offset.lerp(pShL, pHipL, 0.34)!;
        final a2 = Offset.lerp(pShR, pHipR, 0.34)!;
        final b2 = Offset.lerp(pShR, pHipR, 0.64)!;
        final b1 = Offset.lerp(pShL, pHipL, 0.64)!;
        final band = Path()
          ..moveTo(a1.dx, a1.dy)
          ..lineTo(a2.dx, a2.dy)
          ..lineTo(b2.dx, b2.dy)
          ..lineTo(b1.dx, b1.dy)
          ..close();
        canvas.drawPath(band, Paint()..color = kitSpec.secondaryColor);
        break;

      case NationalKitPatternStyle.tricolorChevron:
        final tip = Offset.lerp(topMid, botMid, 0.58)!;
        final l1 = Offset.lerp(pShL, pHipL, 0.25)!;
        final r1 = Offset.lerp(pShR, pHipR, 0.25)!;
        final l2 = Offset.lerp(pShL, pHipL, 0.45)!;
        final r2 = Offset.lerp(pShR, pHipR, 0.45)!;
        final chev = Path()
          ..moveTo(l1.dx, l1.dy)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(r1.dx, r1.dy)
          ..lineTo(r2.dx, r2.dy)
          ..lineTo(tip.dx, tip.dy + 12)
          ..lineTo(l2.dx, l2.dy)
          ..close();
        canvas.drawPath(chev, Paint()..color = kitSpec.secondaryColor);
        canvas.drawLine(
          l2,
          r2,
          Paint()
            ..color = kitSpec.accentColor
            ..strokeWidth = 3.0,
        );
        break;

      case NationalKitPatternStyle.verticalPinstripe:
        final leftEdge = Offset.lerp(pShL, pShR, 0.38)!;
        final rightEdge = Offset.lerp(pShL, pShR, 0.62)!;
        final botLeft = Offset.lerp(pHipL, pHipR, 0.38)!;
        final botRight = Offset.lerp(pHipL, pHipR, 0.62)!;
        final stripe = Path()
          ..moveTo(leftEdge.dx, leftEdge.dy)
          ..lineTo(rightEdge.dx, rightEdge.dy)
          ..lineTo(botRight.dx, botRight.dy)
          ..lineTo(botLeft.dx, botLeft.dy)
          ..close();
        canvas.drawPath(stripe, Paint()..color = kitSpec.secondaryColor);
        break;

      case NationalKitPatternStyle.diagonalSash:
        final sash = Path()
          ..moveTo(pShL.dx, pShL.dy)
          ..lineTo(Offset.lerp(pShL, pShR, 0.36)!.dx,
              Offset.lerp(pShL, pShR, 0.36)!.dy)
          ..lineTo(pHipR.dx, pHipR.dy)
          ..lineTo(Offset.lerp(pHipL, pHipR, 0.64)!.dx,
              Offset.lerp(pHipL, pHipR, 0.64)!.dy)
          ..close();
        canvas.drawPath(sash, Paint()..color = kitSpec.secondaryColor);
        break;

      case NationalKitPatternStyle.alpineCross:
        final center = Offset.lerp(topMid, botMid, 0.45)!;
        final crossPaint = Paint()
          ..color = kitSpec.secondaryColor
          ..strokeWidth = 7.0
          ..strokeCap = StrokeCap.square;
        canvas.drawLine(
          center + const Offset(-14, 0),
          center + const Offset(14, 0),
          crossPaint,
        );
        canvas.drawLine(
          center + const Offset(0, -14),
          center + const Offset(0, 14),
          crossPaint,
        );
        break;

      case NationalKitPatternStyle.gradientWave:
        final bounds = Rect.fromPoints(pShL, pHipR);
        canvas.drawRect(
          bounds.inflate(40),
          Paint()
            ..shader = ui.Gradient.linear(
              topMid,
              botMid,
              [
                kitSpec.primaryColor,
                kitSpec.secondaryColor,
                kitSpec.accentColor,
              ],
              const [0.0, 0.65, 1.0],
            ),
        );
        break;
    }
  }

  void _drawArmsAndHelmet3D({
    required Canvas canvas,
    required Size size,
    required Vector3 origin,
    required double flutterWave,
    required bool isHeroRider,
  }) {
    final isAero = config.eventVariant.isTimeTrial;
    final shoulderY = isAero ? 1.15 : 1.24;
    final shoulderZ = isAero ? 0.16 : 0.10;

    for (var side = -1; side <= 1; side += 2) {
      final sh = renderer.projectWorldPoint(
        worldPoint: Vector3(
          origin.x + side * 0.19,
          origin.y + shoulderY + side * flutterWave,
          origin.z + shoulderZ,
        ),
        config: config,
        viewportSize: size,
      );
      final elbow = renderer.projectWorldPoint(
        worldPoint: Vector3(
          origin.x + side * (isAero ? 0.12 : 0.21),
          origin.y + (isAero ? 0.98 : 1.06),
          origin.z + (isAero ? 0.36 : 0.30),
        ),
        config: config,
        viewportSize: size,
      );
      final hand = renderer.projectWorldPoint(
        worldPoint: Vector3(
          origin.x + side * (isAero ? 0.06 : 0.18),
          origin.y + (isAero ? 0.93 : 0.86),
          origin.z + (isAero ? 0.58 : 0.45),
        ),
        config: config,
        viewportSize: size,
      );
      if (!sh.visible || !elbow.visible || !hand.visible) continue;

      final armW = (0.068 * sh.scale).clamp(4.0, 14.0);
      // Rękaw koszulki (krótki na szosę, długi kombinezon na czasówkę).
      canvas.drawLine(
        sh.offset,
        elbow.offset,
        Paint()
          ..color = kitSpec.secondaryColor
          ..strokeWidth = armW
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        elbow.offset,
        hand.offset,
        Paint()
          ..color = config.eventVariant.longSleeves
              ? kitSpec.primaryColor
              : const Color(0xFFD6A888)
          ..strokeWidth = armW * 0.82
          ..strokeCap = StrokeCap.round,
      );
      // Rękawiczka kolarska.
      canvas.drawCircle(
        hand.offset,
        (0.032 * hand.scale).clamp(2.5, 6.5),
        Paint()..color = kitSpec.collarColor,
      );
    }

    // Głowa i kask (złoty kask Mistrza Olimpijskiego lub kask kadry narodowej).
    final headCenter = renderer.projectWorldPoint(
      worldPoint: Vector3(
        origin.x,
        origin.y + (isAero ? 1.24 : 1.38),
        origin.z + (isAero ? 0.30 : 0.22),
      ),
      config: config,
      viewportSize: size,
    );
    if (!headCenter.visible) return;

    final headR = (0.105 * headCenter.scale).clamp(7.0, 24.0);
    // Twarz / szyja.
    canvas.drawCircle(
      headCenter.offset + Offset(0, headR * 0.22),
      headR * 0.84,
      Paint()..color = const Color(0xFFD6A888),
    );

    final isOlympicGold =
        config.helmetAndBibMode == NationalKitHelmetAndBibMode.olympicChampionGold &&
            isHeroRider;
    final helmetColor =
        isOlympicGold ? AppColors.goldAccent : kitSpec.primaryColor;

    final helmetRect = Rect.fromCenter(
      center: headCenter.offset - Offset(0, headR * 0.14),
      width: isAero ? headR * 2.45 : headR * 2.05,
      height: headR * 1.45,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(helmetRect, Radius.circular(headR * 0.72)),
      Paint()..color = helmetColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(helmetRect, Radius.circular(headR * 0.72)),
      Paint()
        ..color = kitSpec.accentColor.withValues(alpha: 0.75)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke,
    );

    // Okulary przeciwsłoneczne / wizjer TT.
    final visorRect = Rect.fromCenter(
      center: headCenter.offset + Offset(0, headR * 0.14),
      width: headR * 1.42,
      height: headR * 0.44,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(visorRect, Radius.circular(headR * 0.22)),
      Paint()..color = AppColors.cyanAccent.withValues(alpha: 0.72),
    );
  }

  void _drawCenteredText({
    required Canvas canvas,
    required String text,
    required Offset center,
    required Color color,
    required double fontSize,
    required FontWeight fontWeight,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          letterSpacing: -0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width * 0.5, center.dy - painter.height * 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant NationalTeamCustomKits3dPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.kitSpec.countryCode != kitSpec.countryCode ||
        oldDelegate.animationSeconds != animationSeconds;
  }
}

// =============================================================================
// 6. PRODUKCYJNY PANEL INTERAKTYWNEGO PODGLĄDU 3D KOSZULEK REPREZENTACJI
// =============================================================================

/// Interaktywny panel 3D prezentacji oficjalnych koszulek reprezentacji narodowych.
class NationalTeamCustomKits3dPreviewPanel extends StatefulWidget {
  final NationalKit3dRenderConfig initialConfig;
  final ValueChanged<NationalKit3dRenderConfig>? onConfigChanged;
  final bool controlsEnabled;

  const NationalTeamCustomKits3dPreviewPanel({
    super.key,
    this.initialConfig = const NationalKit3dRenderConfig(),
    this.onConfigChanged,
    this.controlsEnabled = true,
  });

  @override
  State<NationalTeamCustomKits3dPreviewPanel> createState() =>
      _NationalTeamCustomKits3dPreviewPanelState();
}

class _NationalTeamCustomKits3dPreviewPanelState
    extends State<NationalTeamCustomKits3dPreviewPanel>
    with SingleTickerProviderStateMixin {
  late NationalKit3dRenderConfig _config;
  late final AnimationController _animationController;
  final NationalTeamCustomKits3dRenderer _renderer =
      const NationalTeamCustomKits3dRenderer();

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateConfig(NationalKit3dRenderConfig next) {
    if (!widget.controlsEnabled) return;
    setState(() => _config = next);
    widget.onConfigChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final kitSpec = NationalTeamKitsCatalog.byCountryCode(
      _config.selectedCountryCode,
    );
    final stats = _renderer.computeFrameStats(_config);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactMobile = constraints.maxWidth < 640;
        final isWideDesktop = constraints.maxWidth >= 1060;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1),
          ),
          padding: EdgeInsets.all(isCompactMobile ? 12 : 16),
          child: isWideDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildViewportCard(kitSpec, stats, isCompactMobile),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(
                        child: _buildControlDeck(kitSpec, isCompactMobile),
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: isCompactMobile ? 310 : 380,
                        child:
                            _buildViewportCard(kitSpec, stats, isCompactMobile),
                      ),
                      const SizedBox(height: 14),
                      _buildControlDeck(kitSpec, isCompactMobile),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildViewportCard(
    NationalTeamKitSpec kitSpec,
    NationalKit3dProjectedMeshStats stats,
    bool isCompactMobile,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onPanUpdate: widget.controlsEnabled
                  ? (details) {
                      _updateConfig(
                        _config.copyWith(
                          riderYawRadians:
                              _config.riderYawRadians + details.delta.dx * 0.012,
                          riderPitchRadians: _config.riderPitchRadians +
                              details.delta.dy * 0.008,
                        ),
                      );
                    }
                  : null,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: NationalTeamCustomKits3dPainter(
                      config: _config,
                      kitSpec: kitSpec,
                      animationSeconds: _animationController.value * 12.0,
                      renderer: _renderer,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
          ),
          // Górny pasek identyfikacji kadry i flagi.
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _FlagSwatchStrip(colors: kitSpec.flagColors),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${kitSpec.countryNamePl.toUpperCase()} (${kitSpec.countryCode})',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        kitSpec.federationTitle,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.goldAccent.withValues(alpha: 0.65),
                    ),
                  ),
                  child: Text(
                    _config.eventVariant.shortTag,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Dolny pasek telemetrii 3D i przycisków kamery.
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Text(
                    '3D • ${stats.riderCount}x • ${stats.projectedVerticesCount} vtx • ${stats.cameraOrbitDeg.toStringAsFixed(0)}°',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentBlue,
                      fontFeatures: [ui.FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                if (!isCompactMobile)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _InteractiveKitButton(
                        label: '-',
                        tooltip: 'Oddal kamerę 3D',
                        enabled: widget.controlsEnabled,
                        onPressed: () => _updateConfig(
                          _config.copyWith(
                            cameraDistanceMeters:
                                _config.cameraDistanceMeters + 0.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _InteractiveKitButton(
                        label: '+',
                        tooltip: 'Przybliż kamerę 3D',
                        enabled: widget.controlsEnabled,
                        onPressed: () => _updateConfig(
                          _config.copyWith(
                            cameraDistanceMeters:
                                _config.cameraDistanceMeters - 0.25,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlDeck(NationalTeamKitSpec kitSpec, bool isCompactMobile) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      padding: EdgeInsets.all(isCompactMobile ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'OFICJALNE KOSZULKI REPREZENTACJI 3D',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.goldAccent,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          // Wybór reprezentacji narodowej.
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: NationalTeamKitsCatalog.officialKits.map((spec) {
              final selected = spec.countryCode == _config.selectedCountryCode;
              return _InteractiveKitButton(
                label: spec.countryCode,
                selected: selected,
                enabled: widget.controlsEnabled,
                accentColor: spec.secondaryColor,
                onPressed: () => _updateConfig(
                  _config.copyWith(selectedCountryCode: spec.countryCode),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          // Wariant imprezy mistrzowskiej.
          const Text(
            'Krój i Dyscyplina',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: NationalTeamKitEventVariant.values.map((variant) {
              return _InteractiveKitButton(
                label: variant.shortTag,
                selected: _config.eventVariant == variant,
                enabled: widget.controlsEnabled,
                onPressed: () => _updateConfig(
                  _config.copyWith(eventVariant: variant),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          // Tryb kasku mistrza olimpijskiego / świata.
          const Text(
            'Oznaczenia Mistrzowskie',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: NationalKitHelmetAndBibMode.values.map((mode) {
              return _InteractiveKitButton(
                label: mode.shortTag,
                selected: _config.helmetAndBibMode == mode,
                enabled: widget.controlsEnabled,
                accentColor: AppColors.goldAccent,
                onPressed: () => _updateConfig(
                  _config.copyWith(helmetAndBibMode: mode),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          // Presety kamery 3D.
          const Text(
            'Ujęcie Kamery 3D',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: NationalKitCameraPreset.values.map((preset) {
              final isMatch =
                  (_config.riderYawRadians - preset.yawRadians).abs() < 0.08 &&
                      (_config.riderPitchRadians - preset.pitchRadians).abs() <
                          0.08;
              return _InteractiveKitButton(
                label: preset.labelPl,
                selected: isMatch,
                enabled: widget.controlsEnabled,
                onPressed: () => _updateConfig(
                  _config.copyWith(
                    riderYawRadians: preset.yawRadians,
                    riderPitchRadians: preset.pitchRadians,
                    cameraDistanceMeters: preset.distanceMeters,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          // Przełączniki detali 3D.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InteractiveKitButton(
                label: _config.showPelotonComparison
                    ? 'Wachlarz 3x: WŁ'
                    : 'Wachlarz 3x: WYŁ',
                selected: _config.showPelotonComparison,
                enabled: widget.controlsEnabled,
                onPressed: () => _updateConfig(
                  _config.copyWith(
                    showPelotonComparison: !_config.showPelotonComparison,
                  ),
                ),
              ),
              _InteractiveKitButton(
                label: _config.showSponsorAndFederationPatches
                    ? 'Naszywki & Numer: WŁ'
                    : 'Naszywki & Numer: WYŁ',
                selected: _config.showSponsorAndFederationPatches,
                enabled: widget.controlsEnabled,
                onPressed: () => _updateConfig(
                  _config.copyWith(
                    showSponsorAndFederationPatches:
                        !_config.showSponsorAndFederationPatches,
                  ),
                ),
              ),
              _InteractiveKitButton(
                label: _config.showLightingAndSpecular
                    ? 'Światło 3D: WŁ'
                    : 'Światło 3D: WYŁ',
                selected: _config.showLightingAndSpecular,
                enabled: widget.controlsEnabled,
                onPressed: () => _updateConfig(
                  _config.copyWith(
                    showLightingAndSpecular: !_config.showLightingAndSpecular,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Informacja o wzorze i rankingu UCI.
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Wzór: ${kitSpec.patternStyle.labelPl} • Numer: #${kitSpec.bibNumberSample}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      fontFeatures: [ui.FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Text(
                  'UCI #${kitSpec.uciNationRank}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                    fontFeatures: [ui.FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlagSwatchStrip extends StatelessWidget {
  final List<Color> colors;

  const _FlagSwatchStrip({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppTheme.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: colors
            .map(
              (c) => Expanded(
                child: Container(color: c),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Przycisk z pełną obsługą stanów hover / active / disabled / focus.
class _InteractiveKitButton extends StatefulWidget {
  final String label;
  final String? tooltip;
  final bool selected;
  final bool enabled;
  final Color? accentColor;
  final VoidCallback onPressed;

  const _InteractiveKitButton({
    required this.label,
    required this.onPressed,
    this.tooltip,
    this.selected = false,
    this.enabled = true,
    this.accentColor,
  });

  @override
  State<_InteractiveKitButton> createState() => _InteractiveKitButtonState();
}

class _InteractiveKitButtonState extends State<_InteractiveKitButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final activeAccent = widget.accentColor ?? AppColors.primaryAccent;
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.selected
            ? activeAccent.withValues(alpha: _pressed ? 0.40 : 0.28)
            : _pressed
                ? AppColors.surfaceLight.withValues(alpha: 0.95)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background;
    final borderColor = !widget.enabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : _focused
            ? AppColors.accentBlue
            : widget.selected
                ? activeAccent
                : _hovered
                    ? AppColors.textSecondary.withValues(alpha: 0.55)
                    : AppTheme.borderColor;
    final textColor = !widget.enabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : widget.selected
            ? AppColors.textPrimary
            : AppColors.textSecondary;

    final button = FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown:
            widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onPressed();
              }
            : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: _focused ? 1.6 : 1.0,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w600,
              color: textColor,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}
