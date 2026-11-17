// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/team/cycling_team.dart';

/// Wielki Tour, na który przygotowywana jest limitowana edycja malowania
/// koszulek oraz ram rowerowych (`Special Edition Livery`).
enum GrandTourLiveryEvent {
  giroDItalia,
  tourDeFrance,
  vueltaAEspana;

  String toJson() => name;

  static GrandTourLiveryEvent fromJson(String value) {
    return GrandTourLiveryEvent.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GrandTourLiveryEvent.tourDeFrance,
    );
  }

  String get displayName {
    switch (this) {
      case GrandTourLiveryEvent.giroDItalia:
        return "Giro d'Italia";
      case GrandTourLiveryEvent.tourDeFrance:
        return 'Tour de France';
      case GrandTourLiveryEvent.vueltaAEspana:
        return 'Vuelta a España';
    }
  }

  String get leaderJerseyName {
    switch (this) {
      case GrandTourLiveryEvent.giroDItalia:
        return 'Maglia Rosa';
      case GrandTourLiveryEvent.tourDeFrance:
        return 'Maillot Jaune';
      case GrandTourLiveryEvent.vueltaAEspana:
        return 'La Roja';
    }
  }

  /// Kolor koszulki lidera klasyfikacji generalnej chroniony regulaminem UCI.
  String get uciProtectedJerseyHex {
    switch (this) {
      case GrandTourLiveryEvent.giroDItalia:
        return '#EC4899';
      case GrandTourLiveryEvent.tourDeFrance:
        return '#FACC15';
      case GrandTourLiveryEvent.vueltaAEspana:
        return '#EF4444';
    }
  }

  Color get uciProtectedColor => LiveryColorUtils.parseHex(uciProtectedJerseyHex);

  String get monthLabel {
    switch (this) {
      case GrandTourLiveryEvent.giroDItalia:
        return 'Maj';
      case GrandTourLiveryEvent.tourDeFrance:
        return 'Lipiec';
      case GrandTourLiveryEvent.vueltaAEspana:
        return 'Sierpień / Wrzesień';
    }
  }

  double get commercialScaleMultiplier {
    switch (this) {
      case GrandTourLiveryEvent.giroDItalia:
        return 1.15;
      case GrandTourLiveryEvent.tourDeFrance:
        return 1.45;
      case GrandTourLiveryEvent.vueltaAEspana:
        return 1.10;
    }
  }
}

/// Motyw przewodni limitowanej edycji malowania sponsora i producenta roweru.
enum SpecialLiveryThemeType {
  uciClashRebrand,
  alpineSummitEdition,
  heritageRetro,
  sponsorAnniversary,
  ecoCarbonStealth,
  goldenTribute;

  String toJson() => name;

  static SpecialLiveryThemeType fromJson(String value) {
    return SpecialLiveryThemeType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SpecialLiveryThemeType.sponsorAnniversary,
    );
  }

  String get label {
    switch (this) {
      case SpecialLiveryThemeType.uciClashRebrand:
        return 'Korekta Koloru UCI';
      case SpecialLiveryThemeType.alpineSummitEdition:
        return 'Alpejski Szczyt';
      case SpecialLiveryThemeType.heritageRetro:
        return 'Klasyk Retro';
      case SpecialLiveryThemeType.sponsorAnniversary:
        return 'Jubileusz Sponsora';
      case SpecialLiveryThemeType.ecoCarbonStealth:
        return 'Stealth Carbon';
      case SpecialLiveryThemeType.goldenTribute:
        return 'Złoty Hołd';
    }
  }

  IconData get icon {
    switch (this) {
      case SpecialLiveryThemeType.uciClashRebrand:
        return Icons.gavel_rounded;
      case SpecialLiveryThemeType.alpineSummitEdition:
        return Icons.terrain_rounded;
      case SpecialLiveryThemeType.heritageRetro:
        return Icons.history_edu_rounded;
      case SpecialLiveryThemeType.sponsorAnniversary:
        return Icons.celebration_rounded;
      case SpecialLiveryThemeType.ecoCarbonStealth:
        return Icons.bolt_rounded;
      case SpecialLiveryThemeType.goldenTribute:
        return Icons.emoji_events_rounded;
    }
  }
}

/// Wykończenie lakieru limitowanej ramy rowerowej.
enum BikePaintFinish {
  matteCarbon,
  metallicFlake,
  iridescentChameleon,
  satinRaw,
  chromeMirror;

  String toJson() => name;

  static BikePaintFinish fromJson(String value) {
    return BikePaintFinish.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BikePaintFinish.metallicFlake,
    );
  }

  String get label {
    switch (this) {
      case BikePaintFinish.matteCarbon:
        return 'Matowy Karbon UD';
      case BikePaintFinish.metallicFlake:
        return 'Lakier Metaliczny';
      case BikePaintFinish.iridescentChameleon:
        return 'Kameleon Opalizujący';
      case BikePaintFinish.satinRaw:
        return 'Satyna Raw Carbon (-35g)';
      case BikePaintFinish.chromeMirror:
        return 'Chromowana Edycja';
    }
  }

  /// Oszczędność masy lakieru w gramach (np. Satin Raw Carbon eliminuje gruby podkład).
  int get weightDeltaGrams {
    switch (this) {
      case BikePaintFinish.matteCarbon:
        return -10;
      case BikePaintFinish.metallicFlake:
        return 15;
      case BikePaintFinish.iridescentChameleon:
        return 25;
      case BikePaintFinish.satinRaw:
        return -35;
      case BikePaintFinish.chromeMirror:
        return 20;
    }
  }
}

/// Status propozycji limitowanej edycji malowania.
enum SpecialLiveryStatus {
  pendingReview,
  approvedActive,
  customized,
  declined,
  completed;

  String toJson() => name;

  static SpecialLiveryStatus fromJson(String value) {
    return SpecialLiveryStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SpecialLiveryStatus.pendingReview,
    );
  }

  String get label {
    switch (this) {
      case SpecialLiveryStatus.pendingReview:
        return 'Oczekuje na decyzję';
      case SpecialLiveryStatus.approvedActive:
        return 'Zatwierdzona na wyścig';
      case SpecialLiveryStatus.customized:
        return 'Spersonalizowana';
      case SpecialLiveryStatus.declined:
        return 'Odrzucona';
      case SpecialLiveryStatus.completed:
        return 'Zakończona';
    }
  }
}

/// Narzędzia konwersji i obliczania odległości barw RGB dla przepisów UCI.
class LiveryColorUtils {
  LiveryColorUtils._();

  static final RegExp _hexPattern = RegExp(r'^#?[0-9A-Fa-f]{6}$');

  static bool isValidHex(String hex) => _hexPattern.hasMatch(hex.trim());

  static String normalizeHex(String hex, {String fallback = '#38BDF8'}) {
    final trimmed = hex.trim().toUpperCase();
    if (!isValidHex(trimmed)) {
      return fallback;
    }
    return trimmed.startsWith('#') ? trimmed : '#$trimmed';
  }

  static Color parseHex(String hex, {Color fallback = AppColors.accentBlue}) {
    final normalized = normalizeHex(hex, fallback: '');
    if (normalized.isEmpty) return fallback;
    final value = int.tryParse(normalized.substring(1), radix: 16);
    if (value == null) return fallback;
    return Color(0xFF000000 | value);
  }

  /// Odległość euklidesowa w przestrzeni RGB znormalizowana do [0.0, 1.0],
  /// gdzie 1.0 oznacza identyczne kolory, a 0.0 maksymalny kontrast.
  static double colorSimilarity(String hexA, String hexB) {
    final a = parseHex(hexA);
    final b = parseHex(hexB);
    final dr = ((a.r - b.r) * 255.0);
    final dg = ((a.g - b.g) * 255.0);
    final db = ((a.b - b.b) * 255.0);
    final maxDist = math.sqrt(255.0 * 255.0 * 3.0);
    final dist = math.sqrt(dr * dr + dg * dg + db * db);
    return (1.0 - (dist / maxDist)).clamp(0.0, 1.0);
  }
}

/// Wynik weryfikacji konfliktu koloru koszulki drużyny z koszulką lidera Wielkiego Touru.
class UciJerseyClashResult {
  final GrandTourLiveryEvent grandTour;
  final String teamPrimaryHex;
  final String leaderJerseyHex;
  final double similarityScore;
  final bool hasClash;
  final String reason;

  const UciJerseyClashResult({
    required this.grandTour,
    required this.teamPrimaryHex,
    required this.leaderJerseyHex,
    required this.similarityScore,
    required this.hasClash,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'grandTour': grandTour.toJson(),
      'teamPrimaryHex': teamPrimaryHex,
      'leaderJerseyHex': leaderJerseyHex,
      'similarityScore': similarityScore,
      'hasClash': hasClash,
      'reason': reason,
    };
  }

  factory UciJerseyClashResult.fromJson(Map<String, dynamic> json) {
    return UciJerseyClashResult(
      grandTour: GrandTourLiveryEvent.fromJson(json['grandTour'] as String? ?? 'tourDeFrance'),
      teamPrimaryHex: json['teamPrimaryHex'] as String? ?? '#1E3A8A',
      leaderJerseyHex: json['leaderJerseyHex'] as String? ?? '#FACC15',
      similarityScore: (json['similarityScore'] as num?)?.toDouble() ?? 0.0,
      hasClash: json['hasClash'] as bool? ?? false,
      reason: json['reason'] as String? ?? '',
    );
  }
}

/// Pełna paleta barw limitowanego zestawu: koszulka, rower, koła oraz kask.
class LiveryColorPalette {
  final String primaryJerseyHex;
  final String secondaryJerseyHex;
  final String accentJerseyHex;
  final String bikeFrameHex;
  final String wheelDecalHex;
  final String helmetHex;

  const LiveryColorPalette({
    required this.primaryJerseyHex,
    required this.secondaryJerseyHex,
    required this.accentJerseyHex,
    required this.bikeFrameHex,
    required this.wheelDecalHex,
    required this.helmetHex,
  });

  Color get primaryJerseyColor => LiveryColorUtils.parseHex(primaryJerseyHex);
  Color get secondaryJerseyColor => LiveryColorUtils.parseHex(secondaryJerseyHex);
  Color get accentJerseyColor => LiveryColorUtils.parseHex(accentJerseyHex);
  Color get bikeFrameColor => LiveryColorUtils.parseHex(bikeFrameHex);
  Color get wheelDecalColor => LiveryColorUtils.parseHex(wheelDecalHex);
  Color get helmetColor => LiveryColorUtils.parseHex(helmetHex);

  LiveryColorPalette copyWith({
    String? primaryJerseyHex,
    String? secondaryJerseyHex,
    String? accentJerseyHex,
    String? bikeFrameHex,
    String? wheelDecalHex,
    String? helmetHex,
  }) {
    return LiveryColorPalette(
      primaryJerseyHex: primaryJerseyHex ?? this.primaryJerseyHex,
      secondaryJerseyHex: secondaryJerseyHex ?? this.secondaryJerseyHex,
      accentJerseyHex: accentJerseyHex ?? this.accentJerseyHex,
      bikeFrameHex: bikeFrameHex ?? this.bikeFrameHex,
      wheelDecalHex: wheelDecalHex ?? this.wheelDecalHex,
      helmetHex: helmetHex ?? this.helmetHex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primaryJerseyHex': primaryJerseyHex,
      'secondaryJerseyHex': secondaryJerseyHex,
      'accentJerseyHex': accentJerseyHex,
      'bikeFrameHex': bikeFrameHex,
      'wheelDecalHex': wheelDecalHex,
      'helmetHex': helmetHex,
    };
  }

  factory LiveryColorPalette.fromJson(Map<String, dynamic> json) {
    return LiveryColorPalette(
      primaryJerseyHex: json['primaryJerseyHex'] as String? ?? '#1E293B',
      secondaryJerseyHex: json['secondaryJerseyHex'] as String? ?? '#0F172A',
      accentJerseyHex: json['accentJerseyHex'] as String? ?? '#D4AF37',
      bikeFrameHex: json['bikeFrameHex'] as String? ?? '#1E293B',
      wheelDecalHex: json['wheelDecalHex'] as String? ?? '#D4AF37',
      helmetHex: json['helmetHex'] as String? ?? '#F3F4F6',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiveryColorPalette &&
        other.primaryJerseyHex == primaryJerseyHex &&
        other.secondaryJerseyHex == secondaryJerseyHex &&
        other.accentJerseyHex == accentJerseyHex &&
        other.bikeFrameHex == bikeFrameHex &&
        other.wheelDecalHex == wheelDecalHex &&
        other.helmetHex == helmetHex;
  }

  @override
  int get hashCode => Object.hash(
        primaryJerseyHex,
        secondaryJerseyHex,
        accentJerseyHex,
        bikeFrameHex,
        wheelDecalHex,
        helmetHex,
      );
}

/// Propozycja limitowanej edycji koszulki i roweru na Wielki Tour.
class SpecialEditionLiveryProposal {
  final String id;
  final GrandTourLiveryEvent grandTour;
  final SpecialLiveryThemeType theme;
  final BikePaintFinish bikeFinish;
  final LiveryColorPalette palette;
  final String editionTitle;
  final String sponsorName;
  final String bikeManufacturerName;
  final String bikeModelName;
  final String sponsorPitch;
  final int merchandiseRevenueBonusEur;
  final int productionCostEur;
  final double mediaExposureMultiplier;
  final int sponsorSatisfactionDelta;
  final int teamMoraleBonus;
  final bool uciClashResolved;
  final SpecialLiveryStatus status;

  const SpecialEditionLiveryProposal({
    required this.id,
    required this.grandTour,
    required this.theme,
    required this.bikeFinish,
    required this.palette,
    required this.editionTitle,
    required this.sponsorName,
    required this.bikeManufacturerName,
    required this.bikeModelName,
    required this.sponsorPitch,
    required this.merchandiseRevenueBonusEur,
    required this.productionCostEur,
    required this.mediaExposureMultiplier,
    required this.sponsorSatisfactionDelta,
    required this.teamMoraleBonus,
    required this.uciClashResolved,
    this.status = SpecialLiveryStatus.pendingReview,
  });

  int get netCommercialProfitEur => merchandiseRevenueBonusEur - productionCostEur;

  SpecialEditionLiveryProposal copyWith({
    String? id,
    GrandTourLiveryEvent? grandTour,
    SpecialLiveryThemeType? theme,
    BikePaintFinish? bikeFinish,
    LiveryColorPalette? palette,
    String? editionTitle,
    String? sponsorName,
    String? bikeManufacturerName,
    String? bikeModelName,
    String? sponsorPitch,
    int? merchandiseRevenueBonusEur,
    int? productionCostEur,
    double? mediaExposureMultiplier,
    int? sponsorSatisfactionDelta,
    int? teamMoraleBonus,
    bool? uciClashResolved,
    SpecialLiveryStatus? status,
  }) {
    return SpecialEditionLiveryProposal(
      id: id ?? this.id,
      grandTour: grandTour ?? this.grandTour,
      theme: theme ?? this.theme,
      bikeFinish: bikeFinish ?? this.bikeFinish,
      palette: palette ?? this.palette,
      editionTitle: editionTitle ?? this.editionTitle,
      sponsorName: sponsorName ?? this.sponsorName,
      bikeManufacturerName: bikeManufacturerName ?? this.bikeManufacturerName,
      bikeModelName: bikeModelName ?? this.bikeModelName,
      sponsorPitch: sponsorPitch ?? this.sponsorPitch,
      merchandiseRevenueBonusEur: merchandiseRevenueBonusEur ?? this.merchandiseRevenueBonusEur,
      productionCostEur: productionCostEur ?? this.productionCostEur,
      mediaExposureMultiplier: mediaExposureMultiplier ?? this.mediaExposureMultiplier,
      sponsorSatisfactionDelta: sponsorSatisfactionDelta ?? this.sponsorSatisfactionDelta,
      teamMoraleBonus: teamMoraleBonus ?? this.teamMoraleBonus,
      uciClashResolved: uciClashResolved ?? this.uciClashResolved,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grandTour': grandTour.toJson(),
      'theme': theme.toJson(),
      'bikeFinish': bikeFinish.toJson(),
      'palette': palette.toJson(),
      'editionTitle': editionTitle,
      'sponsorName': sponsorName,
      'bikeManufacturerName': bikeManufacturerName,
      'bikeModelName': bikeModelName,
      'sponsorPitch': sponsorPitch,
      'merchandiseRevenueBonusEur': merchandiseRevenueBonusEur,
      'productionCostEur': productionCostEur,
      'mediaExposureMultiplier': mediaExposureMultiplier,
      'sponsorSatisfactionDelta': sponsorSatisfactionDelta,
      'teamMoraleBonus': teamMoraleBonus,
      'uciClashResolved': uciClashResolved,
      'status': status.toJson(),
    };
  }

  factory SpecialEditionLiveryProposal.fromJson(Map<String, dynamic> json) {
    return SpecialEditionLiveryProposal(
      id: json['id'] as String? ?? '',
      grandTour: GrandTourLiveryEvent.fromJson(json['grandTour'] as String? ?? 'tourDeFrance'),
      theme: SpecialLiveryThemeType.fromJson(json['theme'] as String? ?? 'sponsorAnniversary'),
      bikeFinish: BikePaintFinish.fromJson(json['bikeFinish'] as String? ?? 'metallicFlake'),
      palette: LiveryColorPalette.fromJson(
        Map<String, dynamic>.from(json['palette'] as Map? ?? const {}),
      ),
      editionTitle: json['editionTitle'] as String? ?? 'Special Edition',
      sponsorName: json['sponsorName'] as String? ?? 'Title Sponsor',
      bikeManufacturerName: json['bikeManufacturerName'] as String? ?? 'ProBike',
      bikeModelName: json['bikeModelName'] as String? ?? 'Aero SL8',
      sponsorPitch: json['sponsorPitch'] as String? ?? '',
      merchandiseRevenueBonusEur: (json['merchandiseRevenueBonusEur'] as num?)?.toInt() ?? 0,
      productionCostEur: (json['productionCostEur'] as num?)?.toInt() ?? 0,
      mediaExposureMultiplier: (json['mediaExposureMultiplier'] as num?)?.toDouble() ?? 1.0,
      sponsorSatisfactionDelta: (json['sponsorSatisfactionDelta'] as num?)?.toInt() ?? 0,
      teamMoraleBonus: (json['teamMoraleBonus'] as num?)?.toInt() ?? 0,
      uciClashResolved: json['uciClashResolved'] as bool? ?? false,
      status: SpecialLiveryStatus.fromJson(json['status'] as String? ?? 'pendingReview'),
    );
  }
}

/// Aktywne wdrożenie limitowanego malowania na czas trwania Wielkiego Touru.
class ActiveSpecialLiveryDeployment {
  final String proposalId;
  final GrandTourLiveryEvent grandTour;
  final int seasonYear;
  final String editionTitle;
  final LiveryColorPalette activePalette;
  final BikePaintFinish bikeFinish;
  final String originalPrimaryHex;
  final String originalSecondaryHex;
  final String originalAccentHex;
  final double mediaExposureMultiplier;
  final int estimatedMerchRevenueEur;
  final int productionCostEur;
  final bool isActive;

  const ActiveSpecialLiveryDeployment({
    required this.proposalId,
    required this.grandTour,
    required this.seasonYear,
    required this.editionTitle,
    required this.activePalette,
    required this.bikeFinish,
    required this.originalPrimaryHex,
    required this.originalSecondaryHex,
    required this.originalAccentHex,
    required this.mediaExposureMultiplier,
    required this.estimatedMerchRevenueEur,
    required this.productionCostEur,
    this.isActive = true,
  });

  /// Nakłada tymczasowe kolory limitowanej edycji na model drużyny.
  CyclingTeam applyToTeam(CyclingTeam team) {
    return team.copyWith(
      primaryJerseyColorHex: activePalette.primaryJerseyHex,
      secondaryJerseyColorHex: activePalette.secondaryJerseyHex,
      accentJerseyColorHex: activePalette.accentJerseyHex,
    );
  }

  /// Przywraca bazowe barwy drużyny po zakończeniu Wielkiego Touru.
  CyclingTeam revertTeamColors(CyclingTeam team) {
    return team.copyWith(
      primaryJerseyColorHex: originalPrimaryHex,
      secondaryJerseyColorHex: originalSecondaryHex,
      accentJerseyColorHex: originalAccentHex,
    );
  }

  ActiveSpecialLiveryDeployment copyWith({
    String? proposalId,
    GrandTourLiveryEvent? grandTour,
    int? seasonYear,
    String? editionTitle,
    LiveryColorPalette? activePalette,
    BikePaintFinish? bikeFinish,
    String? originalPrimaryHex,
    String? originalSecondaryHex,
    String? originalAccentHex,
    double? mediaExposureMultiplier,
    int? estimatedMerchRevenueEur,
    int? productionCostEur,
    bool? isActive,
  }) {
    return ActiveSpecialLiveryDeployment(
      proposalId: proposalId ?? this.proposalId,
      grandTour: grandTour ?? this.grandTour,
      seasonYear: seasonYear ?? this.seasonYear,
      editionTitle: editionTitle ?? this.editionTitle,
      activePalette: activePalette ?? this.activePalette,
      bikeFinish: bikeFinish ?? this.bikeFinish,
      originalPrimaryHex: originalPrimaryHex ?? this.originalPrimaryHex,
      originalSecondaryHex: originalSecondaryHex ?? this.originalSecondaryHex,
      originalAccentHex: originalAccentHex ?? this.originalAccentHex,
      mediaExposureMultiplier: mediaExposureMultiplier ?? this.mediaExposureMultiplier,
      estimatedMerchRevenueEur: estimatedMerchRevenueEur ?? this.estimatedMerchRevenueEur,
      productionCostEur: productionCostEur ?? this.productionCostEur,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'proposalId': proposalId,
      'grandTour': grandTour.toJson(),
      'seasonYear': seasonYear,
      'editionTitle': editionTitle,
      'activePalette': activePalette.toJson(),
      'bikeFinish': bikeFinish.toJson(),
      'originalPrimaryHex': originalPrimaryHex,
      'originalSecondaryHex': originalSecondaryHex,
      'originalAccentHex': originalAccentHex,
      'mediaExposureMultiplier': mediaExposureMultiplier,
      'estimatedMerchRevenueEur': estimatedMerchRevenueEur,
      'productionCostEur': productionCostEur,
      'isActive': isActive,
    };
  }

  factory ActiveSpecialLiveryDeployment.fromJson(Map<String, dynamic> json) {
    return ActiveSpecialLiveryDeployment(
      proposalId: json['proposalId'] as String? ?? '',
      grandTour: GrandTourLiveryEvent.fromJson(json['grandTour'] as String? ?? 'tourDeFrance'),
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      editionTitle: json['editionTitle'] as String? ?? 'Special Edition',
      activePalette: LiveryColorPalette.fromJson(
        Map<String, dynamic>.from(json['activePalette'] as Map? ?? const {}),
      ),
      bikeFinish: BikePaintFinish.fromJson(json['bikeFinish'] as String? ?? 'metallicFlake'),
      originalPrimaryHex: json['originalPrimaryHex'] as String? ?? '#181B22',
      originalSecondaryHex: json['originalSecondaryHex'] as String? ?? '#8E4A49',
      originalAccentHex: json['originalAccentHex'] as String? ?? '#D4AF37',
      mediaExposureMultiplier: (json['mediaExposureMultiplier'] as num?)?.toDouble() ?? 1.2,
      estimatedMerchRevenueEur: (json['estimatedMerchRevenueEur'] as num?)?.toInt() ?? 0,
      productionCostEur: (json['productionCostEur'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

/// Raport komercyjny po zakończeniu Wielkiego Touru w limitowanej edycji.
class SpecialLiveryOutcomeReport {
  final GrandTourLiveryEvent grandTour;
  final int seasonYear;
  final String editionTitle;
  final int stageWinsInLivery;
  final int jerseysSoldCount;
  final int replicaFramesSoldCount;
  final int grossMerchRevenueEur;
  final int netProfitEur;
  final double realizedMediaBoostPercent;
  final String mediaHeadline;

  const SpecialLiveryOutcomeReport({
    required this.grandTour,
    required this.seasonYear,
    required this.editionTitle,
    required this.stageWinsInLivery,
    required this.jerseysSoldCount,
    required this.replicaFramesSoldCount,
    required this.grossMerchRevenueEur,
    required this.netProfitEur,
    required this.realizedMediaBoostPercent,
    required this.mediaHeadline,
  });

  Map<String, dynamic> toJson() {
    return {
      'grandTour': grandTour.toJson(),
      'seasonYear': seasonYear,
      'editionTitle': editionTitle,
      'stageWinsInLivery': stageWinsInLivery,
      'jerseysSoldCount': jerseysSoldCount,
      'replicaFramesSoldCount': replicaFramesSoldCount,
      'grossMerchRevenueEur': grossMerchRevenueEur,
      'netProfitEur': netProfitEur,
      'realizedMediaBoostPercent': realizedMediaBoostPercent,
      'mediaHeadline': mediaHeadline,
    };
  }

  factory SpecialLiveryOutcomeReport.fromJson(Map<String, dynamic> json) {
    return SpecialLiveryOutcomeReport(
      grandTour: GrandTourLiveryEvent.fromJson(json['grandTour'] as String? ?? 'tourDeFrance'),
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      editionTitle: json['editionTitle'] as String? ?? 'Special Edition',
      stageWinsInLivery: (json['stageWinsInLivery'] as num?)?.toInt() ?? 0,
      jerseysSoldCount: (json['jerseysSoldCount'] as num?)?.toInt() ?? 0,
      replicaFramesSoldCount: (json['replicaFramesSoldCount'] as num?)?.toInt() ?? 0,
      grossMerchRevenueEur: (json['grossMerchRevenueEur'] as num?)?.toInt() ?? 0,
      netProfitEur: (json['netProfitEur'] as num?)?.toInt() ?? 0,
      realizedMediaBoostPercent: (json['realizedMediaBoostPercent'] as num?)?.toDouble() ?? 0.0,
      mediaHeadline: json['mediaHeadline'] as String? ?? '',
    );
  }
}

/// Serwis zarządzający limitowanymi edycjami koszulek i rowerów na Wielkie Toury.
class SponsorCustomColorRebrandEventsService {
  const SponsorCustomColorRebrandEventsService();

  static const double _uciClashSimilarityThreshold = 0.72;

  /// Sprawdza, czy podstawowa koszulka drużyny koliduje z koszulką lidera Wielkiego Touru.
  UciJerseyClashResult detectUciJerseyClash({
    required CyclingTeam team,
    required GrandTourLiveryEvent grandTour,
  }) {
    final primaryHex = LiveryColorUtils.normalizeHex(team.primaryJerseyColorHex);
    final leaderHex = grandTour.uciProtectedJerseyHex;
    final similarity = LiveryColorUtils.colorSimilarity(primaryHex, leaderHex);
    final hasClash = similarity >= _uciClashSimilarityThreshold;

    final reason = hasClash
        ? 'Kolor bazowy ($primaryHex) jest zbyt zbliżony do ${grandTour.leaderJerseyName} '
            '($leaderHex). Regulamin UCI wymaga tymczasowego rebrandingu na czas wyścigu.'
        : 'Kolor bazowy ($primaryHex) wyraźnie odróżnia się od ${grandTour.leaderJerseyName} '
            '($leaderHex) — rebranding ma charakter czysto marketingowy.';

    return UciJerseyClashResult(
      grandTour: grandTour,
      teamPrimaryHex: primaryHex,
      leaderJerseyHex: leaderHex,
      similarityScore: similarity,
      hasClash: hasClash,
      reason: reason,
    );
  }

  /// Generuje 3 zróżnicowane propozycje limitowanego malowania na wybrany Wielki Tour.
  List<SpecialEditionLiveryProposal> generateGrandTourLiveryProposals({
    required CyclingTeam team,
    required GrandTourLiveryEvent grandTour,
    required int seasonYear,
    int seed = 0,
  }) {
    final clash = detectUciJerseyClash(team: team, grandTour: grandTour);
    final titleSponsor = team.sponsors.isNotEmpty ? team.sponsors.first.sponsorName : 'Apex Capital';
    final bikeBrand = team.bikeDeal.manufacturerName;
    final bikeModel = team.inventoryBikes.isNotEmpty
        ? team.inventoryBikes.first.frame.name
        : '$bikeBrand Aero SL';

    final divisionFactor = switch (team.division) {
      TeamDivision.worldTour => 1.35,
      TeamDivision.proTeam => 1.0,
      TeamDivision.continental => 0.65,
    };

    final tourScale = grandTour.commercialScaleMultiplier * divisionFactor;
    final rng = math.Random(seasonYear * 97 + grandTour.index * 31 + seed);

    final proposals = <SpecialEditionLiveryProposal>[];

    // 1. Propozycja pierwsza: Korekta UCI lub Alpejski Szczyt
    if (clash.hasClash) {
      final safePalette = _safePaletteForTour(grandTour);
      proposals.add(
        SpecialEditionLiveryProposal(
          id: 'livery_${grandTour.name}_${seasonYear}_uci',
          grandTour: grandTour,
          theme: SpecialLiveryThemeType.uciClashRebrand,
          bikeFinish: BikePaintFinish.iridescentChameleon,
          palette: safePalette,
          editionTitle: '${grandTour.displayName} "Switch Edition"',
          sponsorName: titleSponsor,
          bikeManufacturerName: bikeBrand,
          bikeModelName: bikeModel,
          sponsorPitch:
              'Pilny rebranding uzgodniony z $titleSponsor i $bikeBrand w celu uniknięcia '
              'kolizji z ${grandTour.leaderJerseyName}. Limitowana seria przyciąga uwagę mediów.',
          merchandiseRevenueBonusEur: ((145000 + rng.nextInt(35000)) * tourScale).round(),
          productionCostEur: (28000 * divisionFactor).round(),
          mediaExposureMultiplier: 1.32,
          sponsorSatisfactionDelta: 8,
          teamMoraleBonus: 4,
          uciClashResolved: true,
        ),
      );
    } else {
      proposals.add(
        SpecialEditionLiveryProposal(
          id: 'livery_${grandTour.name}_${seasonYear}_summit',
          grandTour: grandTour,
          theme: SpecialLiveryThemeType.alpineSummitEdition,
          bikeFinish: BikePaintFinish.metallicFlake,
          palette: _summitPaletteForTour(grandTour),
          editionTitle: '${grandTour.displayName} "High Altitude"',
          sponsorName: titleSponsor,
          bikeManufacturerName: bikeBrand,
          bikeModelName: bikeModel,
          sponsorPitch:
              '$titleSponsor proponuje lodowcowo-kobaltowe malowanie inspirowane przełęczami '
              '${grandTour.displayName} z dedykowanym lakierem metalicznym $bikeBrand.',
          merchandiseRevenueBonusEur: ((125000 + rng.nextInt(30000)) * tourScale).round(),
          productionCostEur: (26000 * divisionFactor).round(),
          mediaExposureMultiplier: 1.24,
          sponsorSatisfactionDelta: 6,
          teamMoraleBonus: 3,
          uciClashResolved: false,
        ),
      );
    }

    // 2. Propozycja druga: Stealth Carbon (oszczędność masy lakieru)
    proposals.add(
      SpecialEditionLiveryProposal(
        id: 'livery_${grandTour.name}_${seasonYear}_stealth',
        grandTour: grandTour,
        theme: SpecialLiveryThemeType.ecoCarbonStealth,
        bikeFinish: BikePaintFinish.satinRaw,
        palette: LiveryColorPalette(
          primaryJerseyHex: '#14171F',
          secondaryJerseyHex: '#222630',
          accentJerseyHex: grandTour == GrandTourLiveryEvent.giroDItalia
              ? '#38BDF8'
              : grandTour == GrandTourLiveryEvent.tourDeFrance
                  ? '#10B981'
                  : '#D4AF37',
          bikeFrameHex: '#111318',
          wheelDecalHex: '#F3F4F6',
          helmetHex: '#181B22',
        ),
        editionTitle: '$bikeBrand "Raw Carbon Zero"',
        sponsorName: titleSponsor,
        bikeManufacturerName: bikeBrand,
        bikeModelName: bikeModel,
        sponsorPitch:
            'Minimalistyczna edycja z odsłoniętym splotem karbonu UD oszczędza 35 g lakieru na ramie '
            'i promuje ekologiczny proces produkcji $bikeBrand.',
        merchandiseRevenueBonusEur: ((115000 + rng.nextInt(25000)) * tourScale).round(),
        productionCostEur: (22000 * divisionFactor).round(),
        mediaExposureMultiplier: 1.21,
        sponsorSatisfactionDelta: 5,
        teamMoraleBonus: 5,
        uciClashResolved: clash.hasClash,
      ),
    );

    // 3. Propozycja trzecia: Jubileusz Sponsora / Złoty Hołd
    proposals.add(
      SpecialEditionLiveryProposal(
        id: 'livery_${grandTour.name}_${seasonYear}_anniversary',
        grandTour: grandTour,
        theme: SpecialLiveryThemeType.sponsorAnniversary,
        bikeFinish: BikePaintFinish.chromeMirror,
        palette: const LiveryColorPalette(
          primaryJerseyHex: '#8E4A49',
          secondaryJerseyHex: '#181B22',
          accentJerseyHex: '#D4AF37',
          bikeFrameHex: '#2B1819',
          wheelDecalHex: '#D4AF37',
          helmetHex: '#D4AF37',
        ),
        editionTitle: '$titleSponsor "Heritage Gold"',
        sponsorName: titleSponsor,
        bikeManufacturerName: bikeBrand,
        bikeModelName: bikeModel,
        sponsorPitch:
            'Prestiżowe burgundowo-złote barwy z okazji jubileuszu $titleSponsor oraz '
            'kolekcjonerskie chromowane wstawki na widelcu $bikeModel.',
        merchandiseRevenueBonusEur: ((155000 + rng.nextInt(40000)) * tourScale).round(),
        productionCostEur: (34000 * divisionFactor).round(),
        mediaExposureMultiplier: 1.36,
        sponsorSatisfactionDelta: 10,
        teamMoraleBonus: 4,
        uciClashResolved: clash.hasClash,
      ),
    );

    return proposals;
  }

  /// Waliduje i aktualizuje własne kolory w propozycji, pilnując braku konfliktu UCI.
  SpecialEditionLiveryProposal customizeProposalColors({
    required SpecialEditionLiveryProposal proposal,
    String? primaryJerseyHex,
    String? secondaryJerseyHex,
    String? accentJerseyHex,
    String? bikeFrameHex,
    BikePaintFinish? bikeFinish,
  }) {
    final updatedPalette = proposal.palette.copyWith(
      primaryJerseyHex: primaryJerseyHex != null
          ? LiveryColorUtils.normalizeHex(primaryJerseyHex, fallback: proposal.palette.primaryJerseyHex)
          : null,
      secondaryJerseyHex: secondaryJerseyHex != null
          ? LiveryColorUtils.normalizeHex(secondaryJerseyHex, fallback: proposal.palette.secondaryJerseyHex)
          : null,
      accentJerseyHex: accentJerseyHex != null
          ? LiveryColorUtils.normalizeHex(accentJerseyHex, fallback: proposal.palette.accentJerseyHex)
          : null,
      bikeFrameHex: bikeFrameHex != null
          ? LiveryColorUtils.normalizeHex(bikeFrameHex, fallback: proposal.palette.bikeFrameHex)
          : null,
    );

    final similarity = LiveryColorUtils.colorSimilarity(
      updatedPalette.primaryJerseyHex,
      proposal.grandTour.uciProtectedJerseyHex,
    );
    final isSafeFromClash = similarity < _uciClashSimilarityThreshold;

    return proposal.copyWith(
      palette: updatedPalette,
      bikeFinish: bikeFinish ?? proposal.bikeFinish,
      uciClashResolved: isSafeFromClash,
      status: SpecialLiveryStatus.customized,
    );
  }

  /// Zatwierdza wybraną propozycję i tworzy aktywne wdrożenie na czas Wielkiego Touru.
  ActiveSpecialLiveryDeployment approveLiveryProposal({
    required SpecialEditionLiveryProposal proposal,
    required CyclingTeam team,
    required int seasonYear,
  }) {
    return ActiveSpecialLiveryDeployment(
      proposalId: proposal.id,
      grandTour: proposal.grandTour,
      seasonYear: seasonYear,
      editionTitle: proposal.editionTitle,
      activePalette: proposal.palette,
      bikeFinish: proposal.bikeFinish,
      originalPrimaryHex: team.primaryJerseyColorHex,
      originalSecondaryHex: team.secondaryJerseyColorHex,
      originalAccentHex: team.accentJerseyColorHex,
      mediaExposureMultiplier: proposal.mediaExposureMultiplier,
      estimatedMerchRevenueEur: proposal.merchandiseRevenueBonusEur,
      productionCostEur: proposal.productionCostEur,
      isActive: true,
    );
  }

  /// Rozlicza sprzedaż koszulek, replik rowerów i ekspozycję medialną po zakończeniu Wielkiego Touru.
  SpecialLiveryOutcomeReport simulateMerchandiseAndExposure({
    required ActiveSpecialLiveryDeployment deployment,
    required int stageWinsInLivery,
    required bool podiumGcFinish,
  }) {
    final winFactor = 1.0 + (stageWinsInLivery.clamp(0, 10) * 0.14) + (podiumGcFinish ? 0.35 : 0.0);
    final grossRevenue = (deployment.estimatedMerchRevenueEur * winFactor).round();
    final netProfit = grossRevenue - deployment.productionCostEur;
    final jerseysSold = (grossRevenue * 0.72 / 115.0).round();
    final framesSold = math.max(12, (grossRevenue * 0.28 / 4800.0).round());
    final mediaBoostPct = ((deployment.mediaExposureMultiplier - 1.0) * 100.0 * winFactor)
        .clamp(8.0, 95.0);

    final headline = stageWinsInLivery > 0
        ? 'Limitowana edycja "${deployment.editionTitle}" podbiła ${deployment.grandTour.displayName} '
            '— $stageWinsInLivery wygrane etapy wyprzedały całą partię koszulek!'
        : 'Kolekcjonerskie malowanie "${deployment.editionTitle}" zapewniło +${mediaBoostPct.toStringAsFixed(0)}% '
            'ekwiwalentu reklamowego na trasie ${deployment.grandTour.displayName}.';

    return SpecialLiveryOutcomeReport(
      grandTour: deployment.grandTour,
      seasonYear: deployment.seasonYear,
      editionTitle: deployment.editionTitle,
      stageWinsInLivery: stageWinsInLivery,
      jerseysSoldCount: jerseysSold,
      replicaFramesSoldCount: framesSold,
      grossMerchRevenueEur: grossRevenue,
      netProfitEur: netProfit,
      realizedMediaBoostPercent: mediaBoostPct,
      mediaHeadline: headline,
    );
  }

  LiveryColorPalette _safePaletteForTour(GrandTourLiveryEvent tour) {
    switch (tour) {
      case GrandTourLiveryEvent.tourDeFrance:
        return const LiveryColorPalette(
          primaryJerseyHex: '#0F4C81',
          secondaryJerseyHex: '#181B22',
          accentJerseyHex: '#38BDF8',
          bikeFrameHex: '#0F4C81',
          wheelDecalHex: '#38BDF8',
          helmetHex: '#F3F4F6',
        );
      case GrandTourLiveryEvent.giroDItalia:
        return const LiveryColorPalette(
          primaryJerseyHex: '#065F46',
          secondaryJerseyHex: '#111827',
          accentJerseyHex: '#10B981',
          bikeFrameHex: '#065F46',
          wheelDecalHex: '#D4AF37',
          helmetHex: '#181B22',
        );
      case GrandTourLiveryEvent.vueltaAEspana:
        return const LiveryColorPalette(
          primaryJerseyHex: '#1E293B',
          secondaryJerseyHex: '#0F1115',
          accentJerseyHex: '#F59E0B',
          bikeFrameHex: '#1E293B',
          wheelDecalHex: '#F59E0B',
          helmetHex: '#F3F4F6',
        );
    }
  }

  LiveryColorPalette _summitPaletteForTour(GrandTourLiveryEvent tour) {
    switch (tour) {
      case GrandTourLiveryEvent.giroDItalia:
        return const LiveryColorPalette(
          primaryJerseyHex: '#1E3A8A',
          secondaryJerseyHex: '#0F172A',
          accentJerseyHex: '#38BDF8',
          bikeFrameHex: '#1D4ED8',
          wheelDecalHex: '#F3F4F6',
          helmetHex: '#F3F4F6',
        );
      case GrandTourLiveryEvent.tourDeFrance:
        return const LiveryColorPalette(
          primaryJerseyHex: '#1E293B',
          secondaryJerseyHex: '#334155',
          accentJerseyHex: '#00E5FF',
          bikeFrameHex: '#0F172A',
          wheelDecalHex: '#00E5FF',
          helmetHex: '#E2E8F0',
        );
      case GrandTourLiveryEvent.vueltaAEspana:
        return const LiveryColorPalette(
          primaryJerseyHex: '#312E81',
          secondaryJerseyHex: '#181B22',
          accentJerseyHex: '#F59E0B',
          bikeFrameHex: '#1E1B4B',
          wheelDecalHex: '#F59E0B',
          helmetHex: '#F3F4F6',
        );
    }
  }
}

/// Stan Riverpod dla modułu limitowanych edycji koszulek i rowerów.
class SponsorCustomColorRebrandState {
  final GrandTourLiveryEvent selectedTour;
  final int seasonYear;
  final UciJerseyClashResult? clashResult;
  final List<SpecialEditionLiveryProposal> proposals;
  final String? selectedProposalId;
  final ActiveSpecialLiveryDeployment? activeDeployment;
  final List<SpecialLiveryOutcomeReport> outcomeHistory;
  final String? statusMessage;

  const SponsorCustomColorRebrandState({
    this.selectedTour = GrandTourLiveryEvent.tourDeFrance,
    this.seasonYear = 2026,
    this.clashResult,
    this.proposals = const [],
    this.selectedProposalId,
    this.activeDeployment,
    this.outcomeHistory = const [],
    this.statusMessage,
  });

  SpecialEditionLiveryProposal? get selectedProposal {
    if (proposals.isEmpty) return null;
    if (selectedProposalId == null) return proposals.first;
    for (final p in proposals) {
      if (p.id == selectedProposalId) return p;
    }
    return proposals.first;
  }

  int get totalLifetimeMerchProfitEur {
    var total = 0;
    for (final report in outcomeHistory) {
      total += report.netProfitEur;
    }
    return total;
  }

  SponsorCustomColorRebrandState copyWith({
    GrandTourLiveryEvent? selectedTour,
    int? seasonYear,
    UciJerseyClashResult? clashResult,
    List<SpecialEditionLiveryProposal>? proposals,
    String? selectedProposalId,
    ActiveSpecialLiveryDeployment? activeDeployment,
    bool clearActiveDeployment = false,
    List<SpecialLiveryOutcomeReport>? outcomeHistory,
    String? statusMessage,
    bool clearStatusMessage = false,
  }) {
    return SponsorCustomColorRebrandState(
      selectedTour: selectedTour ?? this.selectedTour,
      seasonYear: seasonYear ?? this.seasonYear,
      clashResult: clashResult ?? this.clashResult,
      proposals: proposals ?? this.proposals,
      selectedProposalId: selectedProposalId ?? this.selectedProposalId,
      activeDeployment: clearActiveDeployment ? null : (activeDeployment ?? this.activeDeployment),
      outcomeHistory: outcomeHistory ?? this.outcomeHistory,
      statusMessage: clearStatusMessage ? null : (statusMessage ?? this.statusMessage),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selectedTour': selectedTour.toJson(),
      'seasonYear': seasonYear,
      'clashResult': clashResult?.toJson(),
      'proposals': proposals.map((p) => p.toJson()).toList(),
      'selectedProposalId': selectedProposalId,
      'activeDeployment': activeDeployment?.toJson(),
      'outcomeHistory': outcomeHistory.map((r) => r.toJson()).toList(),
      'statusMessage': statusMessage,
    };
  }

  factory SponsorCustomColorRebrandState.fromJson(Map<String, dynamic> json) {
    return SponsorCustomColorRebrandState(
      selectedTour: GrandTourLiveryEvent.fromJson(json['selectedTour'] as String? ?? 'tourDeFrance'),
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      clashResult: json['clashResult'] is Map
          ? UciJerseyClashResult.fromJson(Map<String, dynamic>.from(json['clashResult'] as Map))
          : null,
      proposals: (json['proposals'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => SpecialEditionLiveryProposal.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      selectedProposalId: json['selectedProposalId'] as String?,
      activeDeployment: json['activeDeployment'] is Map
          ? ActiveSpecialLiveryDeployment.fromJson(
              Map<String, dynamic>.from(json['activeDeployment'] as Map),
            )
          : null,
      outcomeHistory: (json['outcomeHistory'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => SpecialLiveryOutcomeReport.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      statusMessage: json['statusMessage'] as String?,
    );
  }
}

/// Kontroler Riverpod zarządzający procesem wyboru i zatwierdzania limitowanych edycji.
class SponsorCustomColorRebrandNotifier extends StateNotifier<SponsorCustomColorRebrandState> {
  final SponsorCustomColorRebrandEventsService _service;

  SponsorCustomColorRebrandNotifier({
    SponsorCustomColorRebrandEventsService service = const SponsorCustomColorRebrandEventsService(),
  })  : _service = service,
        super(const SponsorCustomColorRebrandState());

  void initializeForTeam({
    required CyclingTeam team,
    required GrandTourLiveryEvent grandTour,
    required int seasonYear,
    int seed = 0,
  }) {
    final clash = _service.detectUciJerseyClash(team: team, grandTour: grandTour);
    final proposals = _service.generateGrandTourLiveryProposals(
      team: team,
      grandTour: grandTour,
      seasonYear: seasonYear,
      seed: seed,
    );
    state = state.copyWith(
      selectedTour: grandTour,
      seasonYear: seasonYear,
      clashResult: clash,
      proposals: proposals,
      selectedProposalId: proposals.isNotEmpty ? proposals.first.id : null,
      clearStatusMessage: true,
    );
  }

  void selectProposal(String proposalId) {
    if (state.proposals.any((p) => p.id == proposalId)) {
      state = state.copyWith(selectedProposalId: proposalId, clearStatusMessage: true);
    }
  }

  void customizeSelectedColors({
    String? primaryJerseyHex,
    String? secondaryJerseyHex,
    String? accentJerseyHex,
    String? bikeFrameHex,
    BikePaintFinish? bikeFinish,
  }) {
    final selected = state.selectedProposal;
    if (selected == null) return;

    final updated = _service.customizeProposalColors(
      proposal: selected,
      primaryJerseyHex: primaryJerseyHex,
      secondaryJerseyHex: secondaryJerseyHex,
      accentJerseyHex: accentJerseyHex,
      bikeFrameHex: bikeFrameHex,
      bikeFinish: bikeFinish,
    );

    final updatedList = state.proposals
        .map((p) => p.id == updated.id ? updated : p)
        .toList(growable: false);

    state = state.copyWith(
      proposals: updatedList,
      statusMessage: updated.uciClashResolved
          ? 'Zaktualizowano paletę — brak konfliktu z koszulką lidera.'
          : 'Uwaga: wybrany kolor podstawowy jest bliski koszulce lidera UCI.',
    );
  }

  ActiveSpecialLiveryDeployment? approveSelectedProposal({required CyclingTeam team}) {
    final selected = state.selectedProposal;
    if (selected == null) return null;

    final deployment = _service.approveLiveryProposal(
      proposal: selected,
      team: team,
      seasonYear: state.seasonYear,
    );

    final updatedList = state.proposals
        .map(
          (p) => p.id == selected.id
              ? p.copyWith(status: SpecialLiveryStatus.approvedActive)
              : p,
        )
        .toList(growable: false);

    state = state.copyWith(
      proposals: updatedList,
      activeDeployment: deployment,
      statusMessage: 'Zatwierdzono edycję "${selected.editionTitle}" na ${state.selectedTour.displayName}.',
    );
    return deployment;
  }

  void declineSelectedProposal() {
    final selected = state.selectedProposal;
    if (selected == null) return;

    final updatedList = state.proposals
        .map(
          (p) => p.id == selected.id
              ? p.copyWith(status: SpecialLiveryStatus.declined)
              : p,
        )
        .toList(growable: false);

    state = state.copyWith(
      proposals: updatedList,
      statusMessage: 'Odrzucono propozycję "${selected.editionTitle}".',
    );
  }

  SpecialLiveryOutcomeReport? completeActiveDeployment({
    int stageWinsInLivery = 0,
    bool podiumGcFinish = false,
  }) {
    final deployment = state.activeDeployment;
    if (deployment == null) return null;

    final report = _service.simulateMerchandiseAndExposure(
      deployment: deployment,
      stageWinsInLivery: stageWinsInLivery,
      podiumGcFinish: podiumGcFinish,
    );

    final updatedList = state.proposals
        .map(
          (p) => p.id == deployment.proposalId
              ? p.copyWith(status: SpecialLiveryStatus.completed)
              : p,
        )
        .toList(growable: false);

    state = state.copyWith(
      proposals: updatedList,
      clearActiveDeployment: true,
      outcomeHistory: [...state.outcomeHistory, report],
      statusMessage: report.mediaHeadline,
    );
    return report;
  }
}

final sponsorCustomColorRebrandProvider =
    StateNotifierProvider<SponsorCustomColorRebrandNotifier, SponsorCustomColorRebrandState>(
  (ref) => SponsorCustomColorRebrandNotifier(),
);

/// Wektorowy podgląd limitowanej koszulki kolarskiej oraz roweru szosowego.
class SpecialEditionKitAndBikePainter extends CustomPainter {
  final LiveryColorPalette palette;
  final BikePaintFinish bikeFinish;

  const SpecialEditionKitAndBikePainter({
    required this.palette,
    required this.bikeFinish,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final primary = palette.primaryJerseyColor;
    final secondary = palette.secondaryJerseyColor;
    final accent = palette.accentJerseyColor;
    final frameColor = palette.bikeFrameColor;
    final wheelDecal = palette.wheelDecalColor;

    // 1. Koszulka kolarska po lewej stronie płótna
    final jerseyCenterX = size.width * 0.25;
    final jerseyTop = size.height * 0.14;
    final jerseyW = math.min(size.width * 0.34, 130.0);
    final jerseyH = size.height * 0.72;

    final jerseyPath = Path()
      ..moveTo(jerseyCenterX - jerseyW * 0.22, jerseyTop)
      ..lineTo(jerseyCenterX + jerseyW * 0.22, jerseyTop)
      ..lineTo(jerseyCenterX + jerseyW * 0.56, jerseyTop + jerseyH * 0.20)
      ..lineTo(jerseyCenterX + jerseyW * 0.44, jerseyTop + jerseyH * 0.38)
      ..lineTo(jerseyCenterX + jerseyW * 0.33, jerseyTop + jerseyH * 0.32)
      ..lineTo(jerseyCenterX + jerseyW * 0.30, jerseyTop + jerseyH)
      ..lineTo(jerseyCenterX - jerseyW * 0.30, jerseyTop + jerseyH)
      ..lineTo(jerseyCenterX - jerseyW * 0.33, jerseyTop + jerseyH * 0.32)
      ..lineTo(jerseyCenterX - jerseyW * 0.44, jerseyTop + jerseyH * 0.38)
      ..lineTo(jerseyCenterX - jerseyW * 0.56, jerseyTop + jerseyH * 0.20)
      ..close();

    canvas.drawPath(
      jerseyPath,
      Paint()
        ..color = primary
        ..style = PaintingStyle.fill,
    );

    // Pasek akcentowy na piersi
    final chestStripe = Rect.fromLTWH(
      jerseyCenterX - jerseyW * 0.31,
      jerseyTop + jerseyH * 0.36,
      jerseyW * 0.62,
      jerseyH * 0.14,
    );
    canvas.save();
    canvas.clipPath(jerseyPath);
    canvas.drawRect(
      Rect.fromLTWH(
        jerseyCenterX - jerseyW * 0.6,
        jerseyTop + jerseyH * 0.62,
        jerseyW * 1.2,
        jerseyH * 0.4,
      ),
      Paint()..color = secondary,
    );
    canvas.drawRect(chestStripe, Paint()..color = accent);
    canvas.restore();

    // Zamek i obrys koszulki
    canvas.drawLine(
      Offset(jerseyCenterX, jerseyTop + 4),
      Offset(jerseyCenterX, jerseyTop + jerseyH * 0.65),
      Paint()
        ..color = AppColors.textPrimary.withValues(alpha: 0.45)
        ..strokeWidth = 1.4,
    );
    canvas.drawPath(
      jerseyPath,
      Paint()
        ..color = AppColors.textPrimary.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 2. Rower aero po prawej stronie płótna
    final bikeLeft = size.width * 0.48;
    final bikeWidth = size.width * 0.46;
    final wheelRadius = math.min(size.height * 0.24, bikeWidth * 0.19);
    final groundY = size.height * 0.80;
    final rearHub = Offset(bikeLeft + wheelRadius + 6, groundY - wheelRadius);
    final frontHub = Offset(bikeLeft + bikeWidth - wheelRadius - 6, groundY - wheelRadius);

    // Koła karbonowe z naklejkami w kolorze edycji
    for (final hub in [rearHub, frontHub]) {
      canvas.drawCircle(
        hub,
        wheelRadius,
        Paint()
          ..color = const Color(0xFF0B0D11)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.5,
      );
      canvas.drawArc(
        Rect.fromCircle(center: hub, radius: wheelRadius - 1.5),
        -0.4,
        1.1,
        false,
        Paint()
          ..color = wheelDecal
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6,
      );
      canvas.drawArc(
        Rect.fromCircle(center: hub, radius: wheelRadius - 1.5),
        2.7,
        1.1,
        false,
        Paint()
          ..color = wheelDecal
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6,
      );
    }

    // Geometria ramy szosowej
    final bb = Offset((rearHub.dx + frontHub.dx) * 0.47, rearHub.dy + 4);
    final seatCluster = Offset(bb.dx - wheelRadius * 0.45, bb.dy - wheelRadius * 1.15);
    final headTop = Offset(frontHub.dx - wheelRadius * 0.42, bb.dy - wheelRadius * 1.18);
    final headBottom = Offset(frontHub.dx - wheelRadius * 0.34, bb.dy - wheelRadius * 0.86);

    final framePaint = Paint()
      ..color = frameColor
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Tylny trójkąt + główny trójkąt + widelec
    canvas.drawLine(rearHub, bb, framePaint);
    canvas.drawLine(rearHub, seatCluster, framePaint);
    canvas.drawLine(bb, seatCluster, framePaint);
    canvas.drawLine(seatCluster, headTop, framePaint);
    canvas.drawLine(bb, headBottom, framePaint);
    canvas.drawLine(headTop, headBottom, framePaint);
    canvas.drawLine(headBottom, frontHub, framePaint);

    // Akcent lakieru specjalnego na rurze górnej
    canvas.drawLine(
      Offset.lerp(seatCluster, headTop, 0.18)!,
      Offset.lerp(seatCluster, headTop, 0.78)!,
      Paint()
        ..color = bikeFinish == BikePaintFinish.chromeMirror ? AppColors.textPrimary : accent
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // Sztyca i siodełko
    final saddleBase = Offset(seatCluster.dx - 5, seatCluster.dy - 14);
    canvas.drawLine(seatCluster, saddleBase, framePaint..strokeWidth = 2.5);
    canvas.drawLine(
      Offset(saddleBase.dx - 9, saddleBase.dy),
      Offset(saddleBase.dx + 8, saddleBase.dy),
      Paint()
        ..color = AppColors.textPrimary
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );

    // Kierownica szosowa (baranek)
    final stemEnd = Offset(headTop.dx + 10, headTop.dy - 10);
    canvas.drawLine(headTop, stemEnd, framePaint..strokeWidth = 2.5);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(stemEnd.dx + 4, stemEnd.dy + 7), width: 14, height: 14),
      -1.4,
      3.1,
      false,
      Paint()
        ..color = AppColors.textPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
  }

  @override
  bool shouldRepaint(covariant SpecialEditionKitAndBikePainter oldDelegate) {
    return oldDelegate.palette != palette || oldDelegate.bikeFinish != bikeFinish;
  }
}

/// Produkcyjny panel UI zarządzania limitowanymi edycjami koszulek i rowerów na Wielkie Toury.
class SponsorCustomColorRebrandPanel extends ConsumerStatefulWidget {
  final CyclingTeam team;
  final int seasonYear;
  final ValueChanged<ActiveSpecialLiveryDeployment>? onDeploymentApproved;
  final ValueChanged<SpecialLiveryOutcomeReport>? onTourCompleted;

  const SponsorCustomColorRebrandPanel({
    super.key,
    required this.team,
    this.seasonYear = 2026,
    this.onDeploymentApproved,
    this.onTourCompleted,
  });

  @override
  ConsumerState<SponsorCustomColorRebrandPanel> createState() =>
      _SponsorCustomColorRebrandPanelState();
}

class _SponsorCustomColorRebrandPanelState extends ConsumerState<SponsorCustomColorRebrandPanel> {
  static const List<String> _presetAccentSwatches = [
    '#D4AF37',
    '#38BDF8',
    '#10B981',
    '#00E5FF',
    '#F59E0B',
    '#8E4A49',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = ref.read(sponsorCustomColorRebrandProvider);
      if (current.proposals.isEmpty) {
        ref.read(sponsorCustomColorRebrandProvider.notifier).initializeForTeam(
              team: widget.team,
              grandTour: current.selectedTour,
              seasonYear: widget.seasonYear,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sponsorCustomColorRebrandProvider);
    final notifier = ref.read(sponsorCustomColorRebrandProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 960;
          final isTablet = constraints.maxWidth >= 640 && constraints.maxWidth < 960;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(state),
                const SizedBox(height: 16),
                _buildGrandTourTabs(state, notifier),
                if (state.clashResult != null) ...[
                  const SizedBox(height: 14),
                  _buildClashBanner(state.clashResult!),
                ],
                if (state.statusMessage != null) ...[
                  const SizedBox(height: 12),
                  _buildStatusToast(state.statusMessage!),
                ],
                const SizedBox(height: 18),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildProposalsColumn(state, notifier, columns: 1),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 6,
                        child: _buildDetailAndPreviewCard(state, notifier),
                      ),
                    ],
                  )
                else ...[
                  _buildDetailAndPreviewCard(state, notifier),
                  const SizedBox(height: 16),
                  _buildProposalsColumn(state, notifier, columns: isTablet ? 2 : 1),
                ],
                if (state.activeDeployment != null) ...[
                  const SizedBox(height: 18),
                  _buildActiveDeploymentBar(state.activeDeployment!, notifier),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(SponsorCustomColorRebrandState state) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SPECIAL EDITION LIVERY',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.goldAccent,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Limitowane Edycje Koszulek i Rowerów (${state.seasonYear})',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront_rounded, size: 16, color: AppColors.goldAccent),
              const SizedBox(width: 8),
              Text(
                'Zysk merch: ${Formatters.formatCurrency(state.totalLifetimeMerchProfitEur)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGrandTourTabs(
    SponsorCustomColorRebrandState state,
    SponsorCustomColorRebrandNotifier notifier,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: GrandTourLiveryEvent.values.map((tour) {
        final isSelected = state.selectedTour == tour;
        return _InteractiveLiveryChip(
          label: '${tour.displayName} (${tour.monthLabel})',
          accentColor: tour.uciProtectedColor,
          isSelected: isSelected,
          onTap: () {
            notifier.initializeForTeam(
              team: widget.team,
              grandTour: tour,
              seasonYear: widget.seasonYear,
            );
          },
        );
      }).toList(growable: false),
    );
  }

  Widget _buildClashBanner(UciJerseyClashResult clash) {
    final color = clash.hasClash ? AppColors.amberWarning : AppColors.statusSuccess;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            clash.hasClash ? Icons.warning_amber_rounded : Icons.verified_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clash.hasClash
                      ? 'Wykryto konflikt koloru z ${clash.grandTour.leaderJerseyName} (UCI)'
                      : 'Zgodność kolorystyczna UCI potwierdzona',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  clash.reason,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusToast(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.5), width: 1.0),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.accentBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProposalsColumn(
    SponsorCustomColorRebrandState state,
    SponsorCustomColorRebrandNotifier notifier, {
    required int columns,
  }) {
    if (state.proposals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 1.0),
        ),
        child: const Text(
          'Brak dostępnych propozycji malowania.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }

    if (columns == 2) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: state.proposals.map((proposal) {
          return SizedBox(
            width: 300,
            child: _ProposalCard(
              proposal: proposal,
              isSelected: state.selectedProposal?.id == proposal.id,
              onSelect: () => notifier.selectProposal(proposal.id),
            ),
          );
        }).toList(growable: false),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: state.proposals.map((proposal) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ProposalCard(
            proposal: proposal,
            isSelected: state.selectedProposal?.id == proposal.id,
            onSelect: () => notifier.selectProposal(proposal.id),
          ),
        );
      }).toList(growable: false),
    );
  }

  Widget _buildDetailAndPreviewCard(
    SponsorCustomColorRebrandState state,
    SponsorCustomColorRebrandNotifier notifier,
  ) {
    final proposal = state.selectedProposal;
    if (proposal == null) return const SizedBox.shrink();

    final isDisabled = proposal.status == SpecialLiveryStatus.declined ||
        proposal.status == SpecialLiveryStatus.completed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(proposal.theme.icon, size: 18, color: AppColors.goldAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  proposal.editionTitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _StatusBadge(status: proposal.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            proposal.sponsorPitch,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 175,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 1.0),
            ),
            child: CustomPaint(
              painter: SpecialEditionKitAndBikePainter(
                palette: proposal.palette,
                bikeFinish: proposal.bikeFinish,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _MetricTile(
                label: 'Przychód Merch',
                value: Formatters.formatCurrency(proposal.merchandiseRevenueBonusEur),
                color: AppColors.statusSuccess,
              ),
              _MetricTile(
                label: 'Koszt Produkcji',
                value: Formatters.formatCurrency(proposal.productionCostEur),
                color: AppColors.amberWarning,
              ),
              _MetricTile(
                label: 'Ekspozycja TV',
                value: '${proposal.mediaExposureMultiplier.toStringAsFixed(2)}x',
                color: AppColors.accentBlue,
              ),
              _MetricTile(
                label: 'Masa Lakieru',
                value: '${proposal.bikeFinish.weightDeltaGrams > 0 ? '+' : ''}${proposal.bikeFinish.weightDeltaGrams} g',
                color: AppColors.textPrimary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Szybka personalizacja akcentu:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetAccentSwatches.map((hex) {
              final swatchColor = LiveryColorUtils.parseHex(hex);
              final isCurrent = proposal.palette.accentJerseyHex.toUpperCase() == hex;
              return _ColorSwatchButton(
                color: swatchColor,
                isSelected: isCurrent,
                isDisabled: isDisabled,
                onTap: () => notifier.customizeSelectedColors(accentJerseyHex: hex),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _LiveryActionButton(
                label: 'Zatwierdź na ${proposal.grandTour.displayName}',
                icon: Icons.check_circle_outline_rounded,
                isPrimary: true,
                isDisabled: isDisabled || proposal.status == SpecialLiveryStatus.approvedActive,
                onPressed: () {
                  final deployment = notifier.approveSelectedProposal(team: widget.team);
                  if (deployment != null) {
                    widget.onDeploymentApproved?.call(deployment);
                  }
                },
              ),
              _LiveryActionButton(
                label: 'Odrzuć ofertę',
                icon: Icons.close_rounded,
                isPrimary: false,
                isDisabled: isDisabled,
                onPressed: notifier.declineSelectedProposal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDeploymentBar(
    ActiveSpecialLiveryDeployment deployment,
    SponsorCustomColorRebrandNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.55), width: 1.0),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AKTYWNE MALOWANIE: ${deployment.editionTitle}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldAccent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Wyścig: ${deployment.grandTour.displayName} • Lakier: ${deployment.bikeFinish.label}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          _LiveryActionButton(
            label: 'Rozlicz Tour i przywróć barwy',
            icon: Icons.flag_rounded,
            isPrimary: true,
            isDisabled: false,
            onPressed: () {
              final report = notifier.completeActiveDeployment(stageWinsInLivery: 1);
              if (report != null) {
                widget.onTourCompleted?.call(report);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _InteractiveLiveryChip extends StatefulWidget {
  final String label;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _InteractiveLiveryChip({
    required this.label,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_InteractiveLiveryChip> createState() => _InteractiveLiveryChipState();
}

class _InteractiveLiveryChipState extends State<_InteractiveLiveryChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected || _focused
        ? widget.accentColor
        : _hovered
            ? AppColors.textSecondary
            : AppColors.cardBorder;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.diagonal3Values(_pressed ? 0.98 : 1.0, _pressed ? 0.98 : 1.0, 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.accentColor.withValues(alpha: 0.16)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: widget.accentColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProposalCard extends StatefulWidget {
  final SpecialEditionLiveryProposal proposal;
  final bool isSelected;
  final VoidCallback onSelect;

  const _ProposalCard({
    required this.proposal,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  State<_ProposalCard> createState() => _ProposalCardState();
}

class _ProposalCardState extends State<_ProposalCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected
        ? AppColors.goldAccent
        : _focused
            ? AppColors.accentBlue
            : _hovered
                ? AppColors.textSecondary
                : AppColors.cardBorder;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.onSelect,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isSelected ? AppColors.surfaceLight : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: widget.proposal.palette.primaryJerseyColor,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: widget.proposal.palette.accentJerseyColor, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.proposal.editionTitle,
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
              const SizedBox(height: 6),
              Text(
                '${widget.proposal.theme.label} • ${widget.proposal.bikeFinish.label}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Text(
                    'Netto: ${Formatters.formatCurrency(widget.proposal.netCommercialProfitEur)}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.statusSuccess,
                    ),
                  ),
                  _StatusBadge(status: widget.proposal.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final SpecialLiveryStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      SpecialLiveryStatus.pendingReview => AppColors.amberWarning,
      SpecialLiveryStatus.approvedActive => AppColors.statusSuccess,
      SpecialLiveryStatus.customized => AppColors.accentBlue,
      SpecialLiveryStatus.declined => AppColors.crimsonAlert,
      SpecialLiveryStatus.completed => AppColors.goldAccent,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.0),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorSwatchButton extends StatefulWidget {
  final Color color;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _ColorSwatchButton({
    required this.color,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_ColorSwatchButton> createState() => _ColorSwatchButtonState();
}

class _ColorSwatchButtonState extends State<_ColorSwatchButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: widget.isDisabled ? widget.color.withValues(alpha: 0.35) : widget.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isSelected || _focused
                  ? AppColors.textPrimary
                  : _hovered
                      ? AppColors.goldAccent
                      : AppColors.cardBorder,
              width: widget.isSelected ? 2.5 : 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveryActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isDisabled;
  final VoidCallback onPressed;

  const _LiveryActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.isDisabled,
    required this.onPressed,
  });

  @override
  State<_LiveryActionButton> createState() => _LiveryActionButtonState();
}

class _LiveryActionButtonState extends State<_LiveryActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isPrimary ? AppColors.primaryAccent : AppColors.surfaceLight;
    final bgColor = widget.isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : _pressed
            ? baseColor.withValues(alpha: 0.8)
            : _hovered
                ? (widget.isPrimary ? AppColors.goldAccent : AppColors.surfaceLight)
                : baseColor;

    final fgColor = widget.isDisabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : (_hovered && widget.isPrimary)
            ? AppColors.background
            : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.isDisabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: widget.isDisabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _focused ? AppColors.goldAccent : AppColors.cardBorder,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: fgColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
