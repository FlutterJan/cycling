// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/team/cycling_team.dart';
import '../../models/team/sponsor_contract.dart';

/// Główne kategorie celów na nadchodzący sezon ogłaszane podczas styczniowej gali.
enum SeasonMainObjectiveCategory {
  grandTourGcPodium,
  grandTourStageHunts,
  springMonumentsVictory,
  uciWorldTourPointsSurvival,
  breakawayAndJerseyShowcase,
  youthDevelopmentAndProSeries;

  String toJson() => name;

  static SeasonMainObjectiveCategory fromJson(String value) {
    return SeasonMainObjectiveCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SeasonMainObjectiveCategory.grandTourStageHunts,
    );
  }

  String get label {
    switch (this) {
      case SeasonMainObjectiveCategory.grandTourGcPodium:
        return 'Podium Klasyfikacji Generalnej Grand Touru';
      case SeasonMainObjectiveCategory.grandTourStageHunts:
        return 'Polowanie na Etapy Wielkich Tourów';
      case SeasonMainObjectiveCategory.springMonumentsVictory:
        return 'Zwycięstwo w Wiosennym Monumencie';
      case SeasonMainObjectiveCategory.uciWorldTourPointsSurvival:
        return 'Walka o Punkty UCI i Licencję WorldTour';
      case SeasonMainObjectiveCategory.breakawayAndJerseyShowcase:
        return 'Ucieczki, Koszulka Górska i Ekspozycja TV';
      case SeasonMainObjectiveCategory.youthDevelopmentAndProSeries:
        return 'Rozwój Talentów U23 i Wyścigi ProSeries';
    }
  }

  String get subtitle {
    switch (this) {
      case SeasonMainObjectiveCategory.grandTourGcPodium:
        return 'Najwyższy prestiż sportowy, presja liderów GC i rekordowe zainteresowanie prasy.';
      case SeasonMainObjectiveCategory.grandTourStageHunts:
        return 'Ofensywna jazda na wybranych etapach górskich i sprinterskich.';
      case SeasonMainObjectiveCategory.springMonumentsVictory:
        return 'Pełna koncentracja na brukach Flandrii, Roubaix oraz ardeńskich klasykach.';
      case SeasonMainObjectiveCategory.uciWorldTourPointsSurvival:
        return 'Bezpieczna strategia punktowania w wyścigach 1.WT i 2.Pro przez cały rok.';
      case SeasonMainObjectiveCategory.breakawayAndJerseyShowcase:
        return 'Maksymalizacja czasu antenowego sponsora w ucieczkach dnia i walce o grochy.';
      case SeasonMainObjectiveCategory.youthDevelopmentAndProSeries:
        return 'Budowanie przyszłości drużyny wokół neoprofesjonalistów i wyścigów etapowych.';
    }
  }

  double get baseSponsorAppeal {
    switch (this) {
      case SeasonMainObjectiveCategory.grandTourGcPodium:
        return 14.0;
      case SeasonMainObjectiveCategory.grandTourStageHunts:
        return 10.5;
      case SeasonMainObjectiveCategory.springMonumentsVictory:
        return 12.0;
      case SeasonMainObjectiveCategory.uciWorldTourPointsSurvival:
        return 8.5;
      case SeasonMainObjectiveCategory.breakawayAndJerseyShowcase:
        return 11.5;
      case SeasonMainObjectiveCategory.youthDevelopmentAndProSeries:
        return 6.5;
    }
  }

  double get baseMediaAppeal {
    switch (this) {
      case SeasonMainObjectiveCategory.grandTourGcPodium:
        return 16.5;
      case SeasonMainObjectiveCategory.grandTourStageHunts:
        return 11.5;
      case SeasonMainObjectiveCategory.springMonumentsVictory:
        return 14.0;
      case SeasonMainObjectiveCategory.uciWorldTourPointsSurvival:
        return 6.0;
      case SeasonMainObjectiveCategory.breakawayAndJerseyShowcase:
        return 9.5;
      case SeasonMainObjectiveCategory.youthDevelopmentAndProSeries:
        return 7.5;
    }
  }

  int get pressureLevel {
    switch (this) {
      case SeasonMainObjectiveCategory.grandTourGcPodium:
        return 5;
      case SeasonMainObjectiveCategory.springMonumentsVictory:
        return 4;
      case SeasonMainObjectiveCategory.grandTourStageHunts:
        return 3;
      case SeasonMainObjectiveCategory.uciWorldTourPointsSurvival:
        return 3;
      case SeasonMainObjectiveCategory.breakawayAndJerseyShowcase:
        return 2;
      case SeasonMainObjectiveCategory.youthDevelopmentAndProSeries:
        return 1;
    }
  }
}

/// Poziom ambicji deklaracji celów podczas konferencji prasowej.
enum SeasonObjectiveAmbitionLevel {
  conservative,
  ambitious,
  allInGlory;

  String toJson() => name;

  static SeasonObjectiveAmbitionLevel fromJson(String value) {
    return SeasonObjectiveAmbitionLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SeasonObjectiveAmbitionLevel.ambitious,
    );
  }

  String get label {
    switch (this) {
      case SeasonObjectiveAmbitionLevel.conservative:
        return 'Realistyczny Plan';
      case SeasonObjectiveAmbitionLevel.ambitious:
        return 'Ambitna Ofensywa';
      case SeasonObjectiveAmbitionLevel.allInGlory:
        return 'Pełna Stawka / Historyczny Cel';
    }
  }

  double get sponsorMultiplier {
    switch (this) {
      case SeasonObjectiveAmbitionLevel.conservative:
        return 0.85;
      case SeasonObjectiveAmbitionLevel.ambitious:
        return 1.15;
      case SeasonObjectiveAmbitionLevel.allInGlory:
        return 1.35;
    }
  }

  double get mediaMultiplier {
    switch (this) {
      case SeasonObjectiveAmbitionLevel.conservative:
        return 0.78;
      case SeasonObjectiveAmbitionLevel.ambitious:
        return 1.18;
      case SeasonObjectiveAmbitionLevel.allInGlory:
        return 1.45;
    }
  }

  int get moraleDelta {
    switch (this) {
      case SeasonObjectiveAmbitionLevel.conservative:
        return 2;
      case SeasonObjectiveAmbitionLevel.ambitious:
        return 4;
      case SeasonObjectiveAmbitionLevel.allInGlory:
        return 6;
    }
  }
}

/// Rodzaj prezentowanego transferu w trakcie styczniowej gali.
enum SigningSpotlightType {
  marqueeSigning,
  tacticalDomestique,
  u23Promotion;

  String toJson() => name;

  static SigningSpotlightType fromJson(String value) {
    return SigningSpotlightType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SigningSpotlightType.tacticalDomestique,
    );
  }

  String get label {
    switch (this) {
      case SigningSpotlightType.marqueeSigning:
        return 'Gwiazda Transferowa';
      case SigningSpotlightType.tacticalDomestique:
        return 'Wzmocnienie Taktyczne';
      case SigningSpotlightType.u23Promotion:
        return 'Awans z Akademii U23';
    }
  }
}

/// Styl graficzny nowej koszulki drużynowej na sezon.
enum JerseyPatternStyle {
  classicBanded,
  modernAeroFade,
  championshipGoldTrim,
  stealthCarbon;

  String toJson() => name;

  static JerseyPatternStyle fromJson(String value) {
    return JerseyPatternStyle.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => JerseyPatternStyle.classicBanded,
    );
  }

  String get label {
    switch (this) {
      case JerseyPatternStyle.classicBanded:
        return 'Klasyczne Pasy WorldTour';
      case JerseyPatternStyle.modernAeroFade:
        return 'Gradient Aero Pro';
      case JerseyPatternStyle.championshipGoldTrim:
        return 'Złote Wykończenie Prestige';
      case JerseyPatternStyle.stealthCarbon:
        return 'Karbonowy Minimalizm';
    }
  }
}

/// Ton wypowiedzi menedżera w sesji pytań i odpowiedzi (Q&A) z dziennikarzami.
enum PressQaTone {
  humbleAndFocused,
  boldPromise,
  sponsorCentric;

  String toJson() => name;

  static PressQaTone fromJson(String value) {
    return PressQaTone.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PressQaTone.humbleAndFocused,
    );
  }

  String get label {
    switch (this) {
      case PressQaTone.humbleAndFocused:
        return 'Skromność i Ciężka Praca';
      case PressQaTone.boldPromise:
        return 'Odważna Deklaracja Zwycięstw';
      case PressQaTone.sponsorCentric:
        return 'Podkreślenie Wizji Sponsora';
    }
  }

  double get sponsorBonus {
    switch (this) {
      case PressQaTone.humbleAndFocused:
        return 3.0;
      case PressQaTone.boldPromise:
        return 1.5;
      case PressQaTone.sponsorCentric:
        return 7.5;
    }
  }

  double get mediaBonus {
    switch (this) {
      case PressQaTone.humbleAndFocused:
        return 2.5;
      case PressQaTone.boldPromise:
        return 8.5;
      case PressQaTone.sponsorCentric:
        return 2.0;
    }
  }
}

/// Status wydarzenia Styczniowej Prezentacji Drużyny.
enum PreSeasonPresentationStatus {
  pending,
  inProgress,
  completed;

  String toJson() => name;

  static PreSeasonPresentationStatus fromJson(String value) {
    return PreSeasonPresentationStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PreSeasonPresentationStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case PreSeasonPresentationStatus.pending:
        return 'Zaplanowana — Styczeń';
      case PreSeasonPresentationStatus.inProgress:
        return 'Trwa Konferencja';
      case PreSeasonPresentationStatus.completed:
        return 'Zakończona';
    }
  }
}

/// Sylwetka nowego nabytku prezentowanego na scenie przed mediami i sponsorami.
class NewSigningSpotlight {
  final String riderId;
  final String fullName;
  final String nationalityIso;
  final String previousTeamName;
  final RiderSpecialization specialization;
  final int overallRating;
  final int contractYears;
  final SigningSpotlightType signingType;
  final String pressQuote;
  final double mediaInterestGain;
  final double sponsorPrestigeGain;

  const NewSigningSpotlight({
    required this.riderId,
    required this.fullName,
    required this.nationalityIso,
    required this.previousTeamName,
    required this.specialization,
    required this.overallRating,
    required this.contractYears,
    required this.signingType,
    required this.pressQuote,
    required this.mediaInterestGain,
    required this.sponsorPrestigeGain,
  });

  NewSigningSpotlight copyWith({
    String? riderId,
    String? fullName,
    String? nationalityIso,
    String? previousTeamName,
    RiderSpecialization? specialization,
    int? overallRating,
    int? contractYears,
    SigningSpotlightType? signingType,
    String? pressQuote,
    double? mediaInterestGain,
    double? sponsorPrestigeGain,
  }) {
    return NewSigningSpotlight(
      riderId: riderId ?? this.riderId,
      fullName: fullName ?? this.fullName,
      nationalityIso: nationalityIso ?? this.nationalityIso,
      previousTeamName: previousTeamName ?? this.previousTeamName,
      specialization: specialization ?? this.specialization,
      overallRating: overallRating ?? this.overallRating,
      contractYears: contractYears ?? this.contractYears,
      signingType: signingType ?? this.signingType,
      pressQuote: pressQuote ?? this.pressQuote,
      mediaInterestGain: mediaInterestGain ?? this.mediaInterestGain,
      sponsorPrestigeGain: sponsorPrestigeGain ?? this.sponsorPrestigeGain,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'fullName': fullName,
      'nationalityIso': nationalityIso,
      'previousTeamName': previousTeamName,
      'specialization': specialization.toJson(),
      'overallRating': overallRating,
      'contractYears': contractYears,
      'signingType': signingType.toJson(),
      'pressQuote': pressQuote,
      'mediaInterestGain': mediaInterestGain,
      'sponsorPrestigeGain': sponsorPrestigeGain,
    };
  }

  factory NewSigningSpotlight.fromJson(Map<String, dynamic> json) {
    return NewSigningSpotlight(
      riderId: json['riderId'] as String,
      fullName: json['fullName'] as String,
      nationalityIso: json['nationalityIso'] as String,
      previousTeamName: json['previousTeamName'] as String,
      specialization: RiderSpecialization.fromJson(
        json['specialization'] as String,
      ),
      overallRating: (json['overallRating'] as num).toInt(),
      contractYears: (json['contractYears'] as num).toInt(),
      signingType: SigningSpotlightType.fromJson(
        json['signingType'] as String,
      ),
      pressQuote: json['pressQuote'] as String,
      mediaInterestGain: (json['mediaInterestGain'] as num).toDouble(),
      sponsorPrestigeGain: (json['sponsorPrestigeGain'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NewSigningSpotlight && other.riderId == riderId;
  }

  @override
  int get hashCode => riderId.hashCode;
}

/// Wariant nowej koszulki wyścigowej na sezon prezentowany sponsorom i kibicom.
class KitPresentationVariant {
  final String id;
  final String name;
  final String tagline;
  final String primaryHex;
  final String secondaryHex;
  final String accentHex;
  final JerseyPatternStyle patternStyle;
  final double sponsorLogoProminence; // 0.50 - 1.00
  final double mediaAppealScore; // 0.0 - 15.0
  final double sponsorVisibilityScore; // 0.0 - 15.0

  const KitPresentationVariant({
    required this.id,
    required this.name,
    required this.tagline,
    required this.primaryHex,
    required this.secondaryHex,
    required this.accentHex,
    required this.patternStyle,
    required this.sponsorLogoProminence,
    required this.mediaAppealScore,
    required this.sponsorVisibilityScore,
  });

  KitPresentationVariant copyWith({
    String? id,
    String? name,
    String? tagline,
    String? primaryHex,
    String? secondaryHex,
    String? accentHex,
    JerseyPatternStyle? patternStyle,
    double? sponsorLogoProminence,
    double? mediaAppealScore,
    double? sponsorVisibilityScore,
  }) {
    return KitPresentationVariant(
      id: id ?? this.id,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      primaryHex: primaryHex ?? this.primaryHex,
      secondaryHex: secondaryHex ?? this.secondaryHex,
      accentHex: accentHex ?? this.accentHex,
      patternStyle: patternStyle ?? this.patternStyle,
      sponsorLogoProminence:
          sponsorLogoProminence ?? this.sponsorLogoProminence,
      mediaAppealScore: mediaAppealScore ?? this.mediaAppealScore,
      sponsorVisibilityScore:
          sponsorVisibilityScore ?? this.sponsorVisibilityScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tagline': tagline,
      'primaryHex': primaryHex,
      'secondaryHex': secondaryHex,
      'accentHex': accentHex,
      'patternStyle': patternStyle.toJson(),
      'sponsorLogoProminence': sponsorLogoProminence,
      'mediaAppealScore': mediaAppealScore,
      'sponsorVisibilityScore': sponsorVisibilityScore,
    };
  }

  factory KitPresentationVariant.fromJson(Map<String, dynamic> json) {
    return KitPresentationVariant(
      id: json['id'] as String,
      name: json['name'] as String,
      tagline: json['tagline'] as String,
      primaryHex: json['primaryHex'] as String,
      secondaryHex: json['secondaryHex'] as String,
      accentHex: json['accentHex'] as String,
      patternStyle: JerseyPatternStyle.fromJson(
        json['patternStyle'] as String,
      ),
      sponsorLogoProminence:
          (json['sponsorLogoProminence'] as num).toDouble(),
      mediaAppealScore: (json['mediaAppealScore'] as num).toDouble(),
      sponsorVisibilityScore:
          (json['sponsorVisibilityScore'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KitPresentationVariant && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Podgląd na żywo budowanych indeksów zadowolenia sponsora i zainteresowania mediów.
class PreSeasonPresentationPreviewMetrics {
  final double initialSponsorSatisfactionIndex;
  final double initialMediaInterestIndex;
  final double sponsorSatisfactionDelta;
  final double mediaInterestDelta;
  final int projectedMediaValueEur;
  final int teamMoraleBonus;
  final String alignmentVerdict;

  const PreSeasonPresentationPreviewMetrics({
    required this.initialSponsorSatisfactionIndex,
    required this.initialMediaInterestIndex,
    required this.sponsorSatisfactionDelta,
    required this.mediaInterestDelta,
    required this.projectedMediaValueEur,
    required this.teamMoraleBonus,
    required this.alignmentVerdict,
  });
}

/// Końcowy rezultat Styczniowej Prezentacji Drużyny dla Mediów i Sponsorów.
class PreSeasonTeamPresentationOutcome {
  final int seasonYear;
  final String teamId;
  final String teamName;
  final SeasonMainObjectiveCategory selectedMainObjective;
  final SeasonMainObjectiveCategory? secondaryObjective;
  final SeasonObjectiveAmbitionLevel ambitionLevel;
  final List<NewSigningSpotlight> presentedSignings;
  final KitPresentationVariant selectedKit;
  final PressQaTone pressTone;
  final double initialSponsorSatisfactionIndex;
  final double initialMediaInterestIndex;
  final double sponsorSatisfactionDelta;
  final double mediaInterestDelta;
  final int projectedMediaValueEur;
  final int teamMoraleBonus;
  final String headlineSummary;
  final List<String> mediaQuotes;
  final DateTime completedAt;

  const PreSeasonTeamPresentationOutcome({
    required this.seasonYear,
    required this.teamId,
    required this.teamName,
    required this.selectedMainObjective,
    required this.secondaryObjective,
    required this.ambitionLevel,
    required this.presentedSignings,
    required this.selectedKit,
    required this.pressTone,
    required this.initialSponsorSatisfactionIndex,
    required this.initialMediaInterestIndex,
    required this.sponsorSatisfactionDelta,
    required this.mediaInterestDelta,
    required this.projectedMediaValueEur,
    required this.teamMoraleBonus,
    required this.headlineSummary,
    required this.mediaQuotes,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'seasonYear': seasonYear,
      'teamId': teamId,
      'teamName': teamName,
      'selectedMainObjective': selectedMainObjective.toJson(),
      'secondaryObjective': secondaryObjective?.toJson(),
      'ambitionLevel': ambitionLevel.toJson(),
      'presentedSignings': presentedSignings.map((s) => s.toJson()).toList(),
      'selectedKit': selectedKit.toJson(),
      'pressTone': pressTone.toJson(),
      'initialSponsorSatisfactionIndex': initialSponsorSatisfactionIndex,
      'initialMediaInterestIndex': initialMediaInterestIndex,
      'sponsorSatisfactionDelta': sponsorSatisfactionDelta,
      'mediaInterestDelta': mediaInterestDelta,
      'projectedMediaValueEur': projectedMediaValueEur,
      'teamMoraleBonus': teamMoraleBonus,
      'headlineSummary': headlineSummary,
      'mediaQuotes': mediaQuotes,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory PreSeasonTeamPresentationOutcome.fromJson(Map<String, dynamic> json) {
    return PreSeasonTeamPresentationOutcome(
      seasonYear: (json['seasonYear'] as num).toInt(),
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      selectedMainObjective: SeasonMainObjectiveCategory.fromJson(
        json['selectedMainObjective'] as String,
      ),
      secondaryObjective: json['secondaryObjective'] != null
          ? SeasonMainObjectiveCategory.fromJson(
              json['secondaryObjective'] as String,
            )
          : null,
      ambitionLevel: SeasonObjectiveAmbitionLevel.fromJson(
        json['ambitionLevel'] as String,
      ),
      presentedSignings: (json['presentedSignings'] as List<dynamic>? ?? const [])
          .map((e) => NewSigningSpotlight.fromJson(e as Map<String, dynamic>))
          .toList(),
      selectedKit: KitPresentationVariant.fromJson(
        json['selectedKit'] as Map<String, dynamic>,
      ),
      pressTone: PressQaTone.fromJson(json['pressTone'] as String),
      initialSponsorSatisfactionIndex:
          (json['initialSponsorSatisfactionIndex'] as num).toDouble(),
      initialMediaInterestIndex:
          (json['initialMediaInterestIndex'] as num).toDouble(),
      sponsorSatisfactionDelta:
          (json['sponsorSatisfactionDelta'] as num).toDouble(),
      mediaInterestDelta: (json['mediaInterestDelta'] as num).toDouble(),
      projectedMediaValueEur:
          (json['projectedMediaValueEur'] as num).toInt(),
      teamMoraleBonus: (json['teamMoraleBonus'] as num).toInt(),
      headlineSummary: json['headlineSummary'] as String,
      mediaQuotes: (json['mediaQuotes'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }
}

/// Pełny stan Riverpod dla wydarzenia Styczniowej Prezentacji Drużyny.
class PreSeasonTeamPresentationState {
  final int seasonYear;
  final PreSeasonPresentationStatus status;
  final CyclingTeam? team;
  final SeasonMainObjectiveCategory selectedMainObjective;
  final SeasonMainObjectiveCategory? secondaryObjective;
  final SeasonObjectiveAmbitionLevel ambitionLevel;
  final List<NewSigningSpotlight> newSignings;
  final Set<String> featuredSigningIds;
  final List<KitPresentationVariant> kitVariants;
  final String? selectedKitId;
  final PressQaTone pressTone;
  final PreSeasonTeamPresentationOutcome? outcome;
  final String? validationError;

  const PreSeasonTeamPresentationState({
    required this.seasonYear,
    required this.status,
    required this.team,
    required this.selectedMainObjective,
    required this.secondaryObjective,
    required this.ambitionLevel,
    required this.newSignings,
    required this.featuredSigningIds,
    required this.kitVariants,
    required this.selectedKitId,
    required this.pressTone,
    required this.outcome,
    required this.validationError,
  });

  factory PreSeasonTeamPresentationState.initial({int seasonYear = 2026}) {
    return PreSeasonTeamPresentationState(
      seasonYear: seasonYear,
      status: PreSeasonPresentationStatus.pending,
      team: null,
      selectedMainObjective: SeasonMainObjectiveCategory.grandTourStageHunts,
      secondaryObjective: SeasonMainObjectiveCategory.springMonumentsVictory,
      ambitionLevel: SeasonObjectiveAmbitionLevel.ambitious,
      newSignings: const [],
      featuredSigningIds: const {},
      kitVariants: const [],
      selectedKitId: null,
      pressTone: PressQaTone.humbleAndFocused,
      outcome: null,
      validationError: null,
    );
  }

  KitPresentationVariant? get selectedKit {
    if (kitVariants.isEmpty) return null;
    if (selectedKitId == null) return kitVariants.first;
    for (final kit in kitVariants) {
      if (kit.id == selectedKitId) return kit;
    }
    return kitVariants.first;
  }

  PreSeasonPresentationPreviewMetrics get previewMetrics {
    return PreSeasonTeamPresentationEvent.evaluateLivePreview(
      team: team,
      mainObjective: selectedMainObjective,
      secondaryObjective: secondaryObjective,
      ambitionLevel: ambitionLevel,
      newSignings: newSignings,
      featuredSigningIds: featuredSigningIds,
      selectedKit: selectedKit,
      pressTone: pressTone,
    );
  }

  PreSeasonTeamPresentationState copyWith({
    int? seasonYear,
    PreSeasonPresentationStatus? status,
    CyclingTeam? team,
    bool clearTeam = false,
    SeasonMainObjectiveCategory? selectedMainObjective,
    SeasonMainObjectiveCategory? secondaryObjective,
    bool clearSecondaryObjective = false,
    SeasonObjectiveAmbitionLevel? ambitionLevel,
    List<NewSigningSpotlight>? newSignings,
    Set<String>? featuredSigningIds,
    List<KitPresentationVariant>? kitVariants,
    String? selectedKitId,
    PressQaTone? pressTone,
    PreSeasonTeamPresentationOutcome? outcome,
    bool clearOutcome = false,
    String? validationError,
    bool clearValidationError = false,
  }) {
    return PreSeasonTeamPresentationState(
      seasonYear: seasonYear ?? this.seasonYear,
      status: status ?? this.status,
      team: clearTeam ? null : (team ?? this.team),
      selectedMainObjective:
          selectedMainObjective ?? this.selectedMainObjective,
      secondaryObjective: clearSecondaryObjective
          ? null
          : (secondaryObjective ?? this.secondaryObjective),
      ambitionLevel: ambitionLevel ?? this.ambitionLevel,
      newSignings: newSignings != null
          ? List<NewSigningSpotlight>.unmodifiable(newSignings)
          : this.newSignings,
      featuredSigningIds: featuredSigningIds != null
          ? Set<String>.unmodifiable(featuredSigningIds)
          : this.featuredSigningIds,
      kitVariants: kitVariants != null
          ? List<KitPresentationVariant>.unmodifiable(kitVariants)
          : this.kitVariants,
      selectedKitId: selectedKitId ?? this.selectedKitId,
      pressTone: pressTone ?? this.pressTone,
      outcome: clearOutcome ? null : (outcome ?? this.outcome),
      validationError: clearValidationError
          ? null
          : (validationError ?? this.validationError),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seasonYear': seasonYear,
      'status': status.toJson(),
      'team': team?.toJson(),
      'selectedMainObjective': selectedMainObjective.toJson(),
      'secondaryObjective': secondaryObjective?.toJson(),
      'ambitionLevel': ambitionLevel.toJson(),
      'newSignings': newSignings.map((s) => s.toJson()).toList(),
      'featuredSigningIds': featuredSigningIds.toList(),
      'kitVariants': kitVariants.map((k) => k.toJson()).toList(),
      'selectedKitId': selectedKitId,
      'pressTone': pressTone.toJson(),
      'outcome': outcome?.toJson(),
      'validationError': validationError,
    };
  }

  factory PreSeasonTeamPresentationState.fromJson(Map<String, dynamic> json) {
    return PreSeasonTeamPresentationState(
      seasonYear: (json['seasonYear'] as num).toInt(),
      status: PreSeasonPresentationStatus.fromJson(json['status'] as String),
      team: json['team'] != null
          ? CyclingTeam.fromJson(json['team'] as Map<String, dynamic>)
          : null,
      selectedMainObjective: SeasonMainObjectiveCategory.fromJson(
        json['selectedMainObjective'] as String,
      ),
      secondaryObjective: json['secondaryObjective'] != null
          ? SeasonMainObjectiveCategory.fromJson(
              json['secondaryObjective'] as String,
            )
          : null,
      ambitionLevel: SeasonObjectiveAmbitionLevel.fromJson(
        json['ambitionLevel'] as String,
      ),
      newSignings: (json['newSignings'] as List<dynamic>? ?? const [])
          .map((e) => NewSigningSpotlight.fromJson(e as Map<String, dynamic>))
          .toList(),
      featuredSigningIds: (json['featuredSigningIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toSet(),
      kitVariants: (json['kitVariants'] as List<dynamic>? ?? const [])
          .map((e) => KitPresentationVariant.fromJson(e as Map<String, dynamic>))
          .toList(),
      selectedKitId: json['selectedKitId'] as String?,
      pressTone: PressQaTone.fromJson(json['pressTone'] as String),
      outcome: json['outcome'] != null
          ? PreSeasonTeamPresentationOutcome.fromJson(
              json['outcome'] as Map<String, dynamic>,
            )
          : null,
      validationError: json['validationError'] as String?,
    );
  }
}

/// Wydarzenie Styczniowej Prezentacji Drużyny dla Mediów i Sponsorów.
///
/// Odpowiada za przygotowanie scenariusza konferencji, prezentację nowych
/// transferów oraz nowej koszulki, a także wyliczenie początkowego indeksu
/// zadowolenia sponsora i zainteresowania mediów na start sezonu.
class PreSeasonTeamPresentationEvent {
  const PreSeasonTeamPresentationEvent._();

  /// Maksymalna liczba transferów wyróżnionych w świetle reflektorów na scenie.
  static const int maxFeaturedSignings = 3;

  /// Sprawdza, czy bieżąca data kariery przypada w oknie styczniowej prezentacji.
  static bool isJanuaryPresentationWindow(DateTime date) => date.month == 1;

  /// Generuje 4 gotowe warianty nowej koszulki drużynowej na sezon.
  static List<KitPresentationVariant> buildDefaultKitVariants(CyclingTeam team) {
    final primary = _sanitizeHex(team.primaryJerseyColorHex, '#8E4A49');
    final secondary = _sanitizeHex(team.secondaryJerseyColorHex, '#181B22');
    final accent = _sanitizeHex(team.accentJerseyColorHex, '#D4AF37');

    return [
      KitPresentationVariant(
        id: 'kit_classic_wt',
        name: '${team.name} Heritage Pro',
        tagline: 'Klasyczne pasy peletonu z wyraźnym logotypem sponsora na piersi',
        primaryHex: primary,
        secondaryHex: secondary,
        accentHex: accent,
        patternStyle: JerseyPatternStyle.classicBanded,
        sponsorLogoProminence: 0.92,
        mediaAppealScore: 9.5,
        sponsorVisibilityScore: 13.0,
      ),
      KitPresentationVariant(
        id: 'kit_aero_fade',
        name: 'Aero Velocity Gradient',
        tagline: 'Nowoczesny gradient aerodynamiczny przyciągający kamery transmisji TV',
        primaryHex: primary,
        secondaryHex: '#0F1115',
        accentHex: '#38BDF8',
        patternStyle: JerseyPatternStyle.modernAeroFade,
        sponsorLogoProminence: 0.85,
        mediaAppealScore: 13.5,
        sponsorVisibilityScore: 10.5,
      ),
      KitPresentationVariant(
        id: 'kit_gold_prestige',
        name: 'Edition Dorée Prestige',
        tagline: 'Limitowana edycja ze złotymi wstawkami pod ceremonię otwarcia sezonu',
        primaryHex: '#181B22',
        secondaryHex: primary,
        accentHex: '#D4AF37',
        patternStyle: JerseyPatternStyle.championshipGoldTrim,
        sponsorLogoProminence: 0.96,
        mediaAppealScore: 14.0,
        sponsorVisibilityScore: 14.0,
      ),
      KitPresentationVariant(
        id: 'kit_stealth_carbon',
        name: 'Stealth Carbon Lab',
        tagline: 'Ultralekka matowa czerń 3K z akcentem zespołu — wysoka estetyka, mniejszy kontrast logo',
        primaryHex: '#0F1115',
        secondaryHex: '#222630',
        accentHex: primary,
        patternStyle: JerseyPatternStyle.stealthCarbon,
        sponsorLogoProminence: 0.68,
        mediaAppealScore: 11.5,
        sponsorVisibilityScore: 7.5,
      ),
    ];
  }

  /// Buduje listę nowych transferów do prezentacji na podstawie modeli [Rider].
  static List<NewSigningSpotlight> buildSigningsFromRoster(
    List<Rider> newSignings, {
    int seasonYear = 2026,
    Map<String, String>? previousTeams,
  }) {
    if (newSignings.isEmpty) return const [];

    final sorted = List<Rider>.from(newSignings)
      ..sort((a, b) => b.overallRating.compareTo(a.overallRating));

    return sorted.map((rider) {
      final rating = rider.overallRating;
      final SigningSpotlightType type;
      if (rider.contract.role == RiderRole.neoPro || rider.age <= 22) {
        type = SigningSpotlightType.u23Promotion;
      } else if (rating >= 78 ||
          rider.contract.role == RiderRole.teamLeader ||
          rider.contract.role == RiderRole.coLeader) {
        type = SigningSpotlightType.marqueeSigning;
      } else {
        type = SigningSpotlightType.tacticalDomestique;
      }

      final years = math.max(1, rider.contract.contractEndYear - seasonYear + 1);
      final prevTeam = previousTeams?[rider.id] ?? 'Wolny Transfer';

      final double mediaGain;
      final double sponsorGain;
      switch (type) {
        case SigningSpotlightType.marqueeSigning:
          mediaGain = 6.5 + ((rating - 75).clamp(0, 20) * 0.35);
          sponsorGain = 5.0 + ((rating - 75).clamp(0, 20) * 0.25);
          break;
        case SigningSpotlightType.u23Promotion:
          mediaGain = 4.5 + (rider.potential >= 85 ? 2.5 : 0.5);
          sponsorGain = 3.5;
          break;
        case SigningSpotlightType.tacticalDomestique:
          mediaGain = 2.5 + ((rating - 70).clamp(0, 15) * 0.15);
          sponsorGain = 3.0;
          break;
      }

      return NewSigningSpotlight(
        riderId: rider.id,
        fullName: rider.fullName,
        nationalityIso: rider.nationalityIso,
        previousTeamName: prevTeam,
        specialization: rider.specialization,
        overallRating: rating,
        contractYears: years,
        signingType: type,
        pressQuote: _buildSigningQuote(rider, type),
        mediaInterestGain: double.parse(mediaGain.toStringAsFixed(1)),
        sponsorPrestigeGain: double.parse(sponsorGain.toStringAsFixed(1)),
      );
    }).toList(growable: false);
  }

  /// Wylicza podgląd na żywo indeksów zadowolenia sponsora oraz zainteresowania mediów.
  static PreSeasonPresentationPreviewMetrics evaluateLivePreview({
    required CyclingTeam? team,
    required SeasonMainObjectiveCategory mainObjective,
    required SeasonMainObjectiveCategory? secondaryObjective,
    required SeasonObjectiveAmbitionLevel ambitionLevel,
    required List<NewSigningSpotlight> newSignings,
    required Set<String> featuredSigningIds,
    required KitPresentationVariant? selectedKit,
    required PressQaTone pressTone,
  }) {
    final double baselineSponsor = _computeBaselineSponsorSatisfaction(team);
    final double baselineMedia = _computeBaselineMediaInterest(team);

    // 1. Wpływ celów sezonowych i poziomu ambicji
    final double objectiveSponsorScore =
        mainObjective.baseSponsorAppeal * ambitionLevel.sponsorMultiplier +
            (secondaryObjective != null && secondaryObjective != mainObjective
                ? secondaryObjective.baseSponsorAppeal * 0.40
                : 0.0);

    final double objectiveMediaScore =
        mainObjective.baseMediaAppeal * ambitionLevel.mediaMultiplier +
            (secondaryObjective != null && secondaryObjective != mainObjective
                ? secondaryObjective.baseMediaAppeal * 0.40
                : 0.0);

    // 2. Premia lub kara za dopasowanie celu do dywizji zespołu
    final double divisionFitBonus = _evaluateDivisionObjectiveFit(
      team?.division,
      mainObjective,
      ambitionLevel,
    );

    // 3. Wpływ wyróżnionych transferów na scenie
    final featured = newSignings
        .where((s) => featuredSigningIds.contains(s.riderId))
        .take(maxFeaturedSignings)
        .toList();

    double signingsSponsor = 0.0;
    double signingsMedia = 0.0;
    for (final signing in featured) {
      signingsSponsor += signing.sponsorPrestigeGain;
      signingsMedia += signing.mediaInterestGain;
    }
    if (featured.isEmpty && newSignings.isNotEmpty) {
      // Jeśli są transfery, ale żaden nie został wyróżniony, mały ułamek nadal działa
      signingsSponsor += 1.5;
      signingsMedia += 1.5;
    }

    // 4. Wpływ prezentacji nowej koszulki
    final double kitSponsor = selectedKit != null
        ? (selectedKit.sponsorVisibilityScore * 0.85) +
            (selectedKit.sponsorLogoProminence * 4.0)
        : 4.0;
    final double kitMedia =
        selectedKit != null ? selectedKit.mediaAppealScore * 0.85 : 4.0;

    // 5. Ton wypowiedzi na konferencji prasowej
    final double toneSponsor = pressTone.sponsorBonus;
    final double toneMedia = pressTone.mediaBonus;

    final double totalSponsorIndex = (baselineSponsor +
            objectiveSponsorScore +
            divisionFitBonus +
            signingsSponsor +
            kitSponsor +
            toneSponsor)
        .clamp(15.0, 99.0);

    final double totalMediaIndex = (baselineMedia +
            objectiveMediaScore +
            (divisionFitBonus * 0.5) +
            signingsMedia +
            kitMedia +
            toneMedia)
        .clamp(15.0, 99.0);

    final double sponsorDelta = totalSponsorIndex - baselineSponsor;
    final double mediaDelta = totalMediaIndex - baselineMedia;

    final int baseBudget = team?.annualSponsorIncomeEur ?? 4500000;
    final int projectedMediaValueEur =
        (baseBudget * (0.45 + (totalMediaIndex / 100.0) * 0.85)).round();

    final int moraleBonus = (ambitionLevel.moraleDelta +
            (featured.isNotEmpty ? 2 : 0) +
            (pressTone == PressQaTone.humbleAndFocused ? 2 : 0))
        .clamp(1, 10);

    final String verdict = _buildAlignmentVerdict(
      totalSponsorIndex: totalSponsorIndex,
      totalMediaIndex: totalMediaIndex,
      divisionFitBonus: divisionFitBonus,
    );

    return PreSeasonPresentationPreviewMetrics(
      initialSponsorSatisfactionIndex:
          double.parse(totalSponsorIndex.toStringAsFixed(1)),
      initialMediaInterestIndex:
          double.parse(totalMediaIndex.toStringAsFixed(1)),
      sponsorSatisfactionDelta: double.parse(sponsorDelta.toStringAsFixed(1)),
      mediaInterestDelta: double.parse(mediaDelta.toStringAsFixed(1)),
      projectedMediaValueEur: projectedMediaValueEur,
      teamMoraleBonus: moraleBonus,
      alignmentVerdict: verdict,
    );
  }

  /// Finalizuje wydarzenie Styczniowej Prezentacji Drużyny i zwraca wynik.
  static PreSeasonTeamPresentationOutcome completePresentation({
    required int seasonYear,
    required CyclingTeam team,
    required SeasonMainObjectiveCategory mainObjective,
    required SeasonMainObjectiveCategory? secondaryObjective,
    required SeasonObjectiveAmbitionLevel ambitionLevel,
    required List<NewSigningSpotlight> newSignings,
    required Set<String> featuredSigningIds,
    required KitPresentationVariant selectedKit,
    required PressQaTone pressTone,
    DateTime? completedAt,
  }) {
    final effectiveSecondary =
        secondaryObjective == mainObjective ? null : secondaryObjective;

    final metrics = evaluateLivePreview(
      team: team,
      mainObjective: mainObjective,
      secondaryObjective: effectiveSecondary,
      ambitionLevel: ambitionLevel,
      newSignings: newSignings,
      featuredSigningIds: featuredSigningIds,
      selectedKit: selectedKit,
      pressTone: pressTone,
    );

    final presented = newSignings
        .where((s) => featuredSigningIds.contains(s.riderId))
        .take(maxFeaturedSignings)
        .toList(growable: false);

    final sponsorName = team.sponsors.isNotEmpty
        ? team.sponsors.first.companyName
        : 'Sponsor Tytularny';

    final headline =
        '${team.name} prezentuje strój "${selectedKit.name}" i celuje w: ${mainObjective.label}';

    final quotes = <String>[
      'Dyrektor Sportowy ${team.name}: "${_buildDirectorQuote(mainObjective, ambitionLevel, pressTone, sponsorName)}"',
      if (presented.isNotEmpty)
        '${presented.first.fullName} (nowy nabytek): "${presented.first.pressQuote}"',
      'Przedstawiciel $sponsorName: "Ekspozycja naszej marki na nowej koszulce i jasna strategia na sezon $seasonYear budują pełne zaufanie zarządu."',
    ];

    return PreSeasonTeamPresentationOutcome(
      seasonYear: seasonYear,
      teamId: team.id,
      teamName: team.name,
      selectedMainObjective: mainObjective,
      secondaryObjective: effectiveSecondary,
      ambitionLevel: ambitionLevel,
      presentedSignings: presented,
      selectedKit: selectedKit,
      pressTone: pressTone,
      initialSponsorSatisfactionIndex: metrics.initialSponsorSatisfactionIndex,
      initialMediaInterestIndex: metrics.initialMediaInterestIndex,
      sponsorSatisfactionDelta: metrics.sponsorSatisfactionDelta,
      mediaInterestDelta: metrics.mediaInterestDelta,
      projectedMediaValueEur: metrics.projectedMediaValueEur,
      teamMoraleBonus: metrics.teamMoraleBonus,
      headlineSummary: headline,
      mediaQuotes: List<String>.unmodifiable(quotes),
      completedAt: completedAt ?? DateTime(seasonYear, 1, 15, 18, 0),
    );
  }

  /// Aplikuje wynik prezentacji do modelu [CyclingTeam] (barwy koszulki i satysfakcja sponsorów).
  static CyclingTeam applyOutcomeToTeam(
    CyclingTeam team,
    PreSeasonTeamPresentationOutcome outcome,
  ) {
    final updatedSponsors = team.sponsors.map((sponsor) {
      final weight = sponsor.sponsorTier == SponsorTier.titlePrimary ? 1.0 : 0.6;
      final newSatisfaction = (sponsor.sponsorSatisfaction +
              (outcome.sponsorSatisfactionDelta * weight))
          .clamp(0.0, 100.0);
      return sponsor.copyWith(
        sponsorSatisfaction: double.parse(newSatisfaction.toStringAsFixed(1)),
      );
    }).toList(growable: false);

    return team.copyWith(
      primaryJerseyColorHex: outcome.selectedKit.primaryHex,
      secondaryJerseyColorHex: outcome.selectedKit.secondaryHex,
      accentJerseyColorHex: outcome.selectedKit.accentHex,
      sponsors: updatedSponsors,
    );
  }

  static double _computeBaselineSponsorSatisfaction(CyclingTeam? team) {
    if (team == null || team.sponsors.isEmpty) return 52.0;
    final avg = team.sponsors
            .map((s) => s.sponsorSatisfaction)
            .reduce((a, b) => a + b) /
        team.sponsors.length;
    return avg.clamp(25.0, 75.0);
  }

  static double _computeBaselineMediaInterest(CyclingTeam? team) {
    if (team == null) return 38.0;
    switch (team.division) {
      case TeamDivision.worldTour:
        return 52.0;
      case TeamDivision.proTeam:
        return 40.0;
      case TeamDivision.continental:
        return 28.0;
    }
  }

  static double _evaluateDivisionObjectiveFit(
    TeamDivision? division,
    SeasonMainObjectiveCategory objective,
    SeasonObjectiveAmbitionLevel ambition,
  ) {
    if (division == null) return 0.0;
    switch (division) {
      case TeamDivision.worldTour:
        if (objective == SeasonMainObjectiveCategory.youthDevelopmentAndProSeries &&
            ambition == SeasonObjectiveAmbitionLevel.conservative) {
          return -5.0; // Zbyt pasywny cel jak na WorldTour
        }
        if (objective == SeasonMainObjectiveCategory.grandTourGcPodium ||
            objective == SeasonMainObjectiveCategory.springMonumentsVictory) {
          return 4.0;
        }
        return 2.0;
      case TeamDivision.proTeam:
        if (objective == SeasonMainObjectiveCategory.grandTourGcPodium &&
            ambition == SeasonObjectiveAmbitionLevel.allInGlory) {
          return -4.5; // Nierealistyczna deklaracja z perspektywy sponsora
        }
        if (objective == SeasonMainObjectiveCategory.breakawayAndJerseyShowcase ||
            objective == SeasonMainObjectiveCategory.grandTourStageHunts) {
          return 4.5;
        }
        return 2.0;
      case TeamDivision.continental:
        if (objective == SeasonMainObjectiveCategory.grandTourGcPodium) {
          return -7.0;
        }
        if (objective == SeasonMainObjectiveCategory.youthDevelopmentAndProSeries ||
            objective == SeasonMainObjectiveCategory.breakawayAndJerseyShowcase) {
          return 5.0;
        }
        return 1.0;
    }
  }

  static String _buildSigningQuote(Rider rider, SigningSpotlightType type) {
    switch (type) {
      case SigningSpotlightType.marqueeSigning:
        return 'Przyszedłem tu, aby walczyć o największe zwycięstwa i spłacić zaufanie sponsorów na trasie.';
      case SigningSpotlightType.u23Promotion:
        return 'Debiut w elicie to spełnienie marzeń. Dam z siebie 100% na każdym kilometrze dla liderów.';
      case SigningSpotlightType.tacticalDomestique:
        return 'Moim zadaniem jest ochrona liderów na wietrze i w górach. Mamy świetną atmosferę.';
    }
  }

  static String _buildDirectorQuote(
    SeasonMainObjectiveCategory objective,
    SeasonObjectiveAmbitionLevel ambition,
    PressQaTone tone,
    String sponsorName,
  ) {
    switch (tone) {
      case PressQaTone.boldPromise:
        return 'Nie boimy się presji (${ambition.label}). Naszym celem jest ${objective.label.toLowerCase()} i będziemy dyktować tempo w peletonie.';
      case PressQaTone.sponsorCentric:
        return 'Dzięki wsparciu $sponsorName dysponujemy sprzętem i zapleczem klasy światowej. Cel: ${objective.label}.';
      case PressQaTone.humbleAndFocused:
        return 'Krok po kroku realizujemy plan (${ambition.label}). Szanujemy rywali, ale ${objective.label.toLowerCase()} to nasz główny priorytet.';
    }
  }

  static String _buildAlignmentVerdict({
    required double totalSponsorIndex,
    required double totalMediaIndex,
    required double divisionFitBonus,
  }) {
    if (divisionFitBonus < -3.0) {
      return 'Ostrzeżenie: Cel może być zbyt ryzykowny względem dywizji zespołu';
    }
    if (totalSponsorIndex >= 82.0 && totalMediaIndex >= 82.0) {
      return 'Entuzjazm na sali: Idealna synergia Mediów i Sponsora';
    }
    if (totalSponsorIndex >= 72.0) {
      return 'Solidne otwarcie: Zarząd sponsora bardzo zadowolony';
    }
    if (totalMediaIndex >= 72.0) {
      return 'Głośna konferencja: Duży szum medialny przed sezonem';
    }
    return 'Stabilna prezentacja: Bezpieczny start relacji przedsezonowych';
  }

  static String _sanitizeHex(String raw, String fallback) {
    final cleaned = raw.trim().replaceAll('#', '');
    if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(cleaned)) {
      return '#${cleaned.toUpperCase()}';
    }
    return fallback;
  }
}

/// Kontroler Riverpod zarządzający cyklem życia Styczniowej Prezentacji Drużyny.
class PreSeasonTeamPresentationNotifier
    extends StateNotifier<PreSeasonTeamPresentationState> {
  PreSeasonTeamPresentationNotifier()
      : super(PreSeasonTeamPresentationState.initial());

  /// Inicjalizuje wydarzenie dla wybranej drużyny i listy nowych transferów.
  void initializeForTeam({
    required int seasonYear,
    required CyclingTeam team,
    List<Rider> newSignings = const [],
    Map<String, String>? previousTeams,
  }) {
    final kits = PreSeasonTeamPresentationEvent.buildDefaultKitVariants(team);
    final signings = PreSeasonTeamPresentationEvent.buildSigningsFromRoster(
      newSignings,
      seasonYear: seasonYear,
      previousTeams: previousTeams,
    );
    final autoFeatured = signings
        .take(PreSeasonTeamPresentationEvent.maxFeaturedSignings)
        .map((s) => s.riderId)
        .toSet();

    final defaultMain = team.division == TeamDivision.worldTour
        ? SeasonMainObjectiveCategory.grandTourGcPodium
        : team.division == TeamDivision.proTeam
            ? SeasonMainObjectiveCategory.grandTourStageHunts
            : SeasonMainObjectiveCategory.youthDevelopmentAndProSeries;

    state = PreSeasonTeamPresentationState(
      seasonYear: seasonYear,
      status: PreSeasonPresentationStatus.inProgress,
      team: team,
      selectedMainObjective: defaultMain,
      secondaryObjective: SeasonMainObjectiveCategory.springMonumentsVictory,
      ambitionLevel: SeasonObjectiveAmbitionLevel.ambitious,
      newSignings: signings,
      featuredSigningIds: autoFeatured,
      kitVariants: kits,
      selectedKitId: kits.isNotEmpty ? kits.first.id : null,
      pressTone: PressQaTone.humbleAndFocused,
      outcome: null,
      validationError: null,
    );
  }

  void selectMainObjective(SeasonMainObjectiveCategory objective) {
    if (state.status == PreSeasonPresentationStatus.completed) return;
    state = state.copyWith(
      selectedMainObjective: objective,
      clearSecondaryObjective: state.secondaryObjective == objective,
      clearValidationError: true,
    );
  }

  void selectSecondaryObjective(SeasonMainObjectiveCategory? objective) {
    if (state.status == PreSeasonPresentationStatus.completed) return;
    if (objective == state.selectedMainObjective) return;
    state = state.copyWith(
      secondaryObjective: objective,
      clearSecondaryObjective: objective == null,
      clearValidationError: true,
    );
  }

  void setAmbitionLevel(SeasonObjectiveAmbitionLevel ambition) {
    if (state.status == PreSeasonPresentationStatus.completed) return;
    state = state.copyWith(
      ambitionLevel: ambition,
      clearValidationError: true,
    );
  }

  void toggleFeaturedSigning(String riderId) {
    if (state.status == PreSeasonPresentationStatus.completed) return;
    final next = Set<String>.from(state.featuredSigningIds);
    if (next.contains(riderId)) {
      next.remove(riderId);
    } else {
      if (next.length >= PreSeasonTeamPresentationEvent.maxFeaturedSignings) {
        state = state.copyWith(
          validationError:
              'Na scenie możesz wyróżnić maksymalnie ${PreSeasonTeamPresentationEvent.maxFeaturedSignings} transfery.',
        );
        return;
      }
      next.add(riderId);
    }
    state = state.copyWith(
      featuredSigningIds: next,
      clearValidationError: true,
    );
  }

  void selectKitVariant(String kitId) {
    if (state.status == PreSeasonPresentationStatus.completed) return;
    final exists = state.kitVariants.any((k) => k.id == kitId);
    if (!exists) return;
    state = state.copyWith(
      selectedKitId: kitId,
      clearValidationError: true,
    );
  }

  void setPressTone(PressQaTone tone) {
    if (state.status == PreSeasonPresentationStatus.completed) return;
    state = state.copyWith(
      pressTone: tone,
      clearValidationError: true,
    );
  }

  /// Zatwierdza prezentację i generuje ostateczny raport dla mediów i sponsora.
  PreSeasonTeamPresentationOutcome? confirmPresentation({DateTime? now}) {
    if (state.status == PreSeasonPresentationStatus.completed) {
      return state.outcome;
    }
    final team = state.team;
    final kit = state.selectedKit;
    if (team == null || kit == null) {
      state = state.copyWith(
        validationError:
            'Brak danych drużyny lub wariantu koszulki do zatwierdzenia prezentacji.',
      );
      return null;
    }

    final outcome = PreSeasonTeamPresentationEvent.completePresentation(
      seasonYear: state.seasonYear,
      team: team,
      mainObjective: state.selectedMainObjective,
      secondaryObjective: state.secondaryObjective,
      ambitionLevel: state.ambitionLevel,
      newSignings: state.newSignings,
      featuredSigningIds: state.featuredSigningIds,
      selectedKit: kit,
      pressTone: state.pressTone,
      completedAt: now,
    );

    final updatedTeam =
        PreSeasonTeamPresentationEvent.applyOutcomeToTeam(team, outcome);

    state = state.copyWith(
      status: PreSeasonPresentationStatus.completed,
      team: updatedTeam,
      outcome: outcome,
      clearValidationError: true,
    );

    return outcome;
  }

  void resetForNewSeason({int? seasonYear}) {
    state = PreSeasonTeamPresentationState.initial(
      seasonYear: seasonYear ?? (state.seasonYear + 1),
    );
  }
}

final preSeasonTeamPresentationProvider = StateNotifierProvider<
    PreSeasonTeamPresentationNotifier, PreSeasonTeamPresentationState>(
  (ref) => PreSeasonTeamPresentationNotifier(),
);

/// Produkcyjny, responsywny panel UI Styczniowej Prezentacji Drużyny dla Mediów i Sponsorów.
class PreSeasonTeamPresentationPanel extends ConsumerWidget {
  final ValueChanged<PreSeasonTeamPresentationOutcome>? onCompleted;

  const PreSeasonTeamPresentationPanel({
    super.key,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(preSeasonTeamPresentationProvider);
    final notifier = ref.read(preSeasonTeamPresentationProvider.notifier);
    final preview = state.previewMetrics;
    final isCompleted = state.status == PreSeasonPresentationStatus.completed;

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1200;
          final isTablet = constraints.maxWidth >= 760 && !isDesktop;
          final horizontalPadding = isDesktop ? 28.0 : (isTablet ? 20.0 : 14.0);

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeaderBanner(
                  seasonYear: state.seasonYear,
                  teamName: state.team?.name ?? 'Zespół WorldTour',
                  status: state.status,
                  verdict: preview.alignmentVerdict,
                ),
                const SizedBox(height: 16),
                if (state.validationError != null) ...[
                  _ValidationAlertBanner(message: state.validationError!),
                  const SizedBox(height: 16),
                ],
                if (isDesktop || isTablet)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: isDesktop ? 7 : 6,
                        child: _LeftConfigurationColumn(
                          state: state,
                          isCompleted: isCompleted,
                          onSelectMain: notifier.selectMainObjective,
                          onSelectSecondary: notifier.selectSecondaryObjective,
                          onSelectAmbition: notifier.setAmbitionLevel,
                          onToggleSigning: notifier.toggleFeaturedSigning,
                          onSelectTone: notifier.setPressTone,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: isDesktop ? 5 : 5,
                        child: _RightStageAndMetricsColumn(
                          state: state,
                          preview: preview,
                          isCompleted: isCompleted,
                          onSelectKit: notifier.selectKitVariant,
                          onConfirm: () {
                            final outcome = notifier.confirmPresentation();
                            if (outcome != null) {
                              onCompleted?.call(outcome);
                            }
                          },
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _RightStageAndMetricsColumn(
                        state: state,
                        preview: preview,
                        isCompleted: isCompleted,
                        onSelectKit: notifier.selectKitVariant,
                        onConfirm: () {
                          final outcome = notifier.confirmPresentation();
                          if (outcome != null) {
                            onCompleted?.call(outcome);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _LeftConfigurationColumn(
                        state: state,
                        isCompleted: isCompleted,
                        onSelectMain: notifier.selectMainObjective,
                        onSelectSecondary: notifier.selectSecondaryObjective,
                        onSelectAmbition: notifier.setAmbitionLevel,
                        onToggleSigning: notifier.toggleFeaturedSigning,
                        onSelectTone: notifier.setPressTone,
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  final int seasonYear;
  final String teamName;
  final PreSeasonPresentationStatus status;
  final String verdict;

  const _HeaderBanner({
    required this.seasonYear,
    required this.teamName,
    required this.status,
    required this.verdict,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = status == PreSeasonPresentationStatus.completed
        ? AppColors.statusSuccess
        : AppColors.goldAccent;

    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.mic_external_on_rounded,
              color: AppColors.goldAccent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'GALA STYCZNIOWA • SEZON $seasonYear',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppColors.goldAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Prezentacja Drużyny $teamName dla Mediów i Sponsorów',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          verdict,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    final statusBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.45)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleColumn,
                const SizedBox(height: 12),
                statusBadge,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleColumn),
              const SizedBox(width: 16),
              statusBadge,
            ],
          );
        },
      ),
    );
  }
}

class _ValidationAlertBanner extends StatelessWidget {
  final String message;

  const _ValidationAlertBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.crimsonAlert.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.crimsonAlert.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.crimsonAlert,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeftConfigurationColumn extends StatelessWidget {
  final PreSeasonTeamPresentationState state;
  final bool isCompleted;
  final ValueChanged<SeasonMainObjectiveCategory> onSelectMain;
  final ValueChanged<SeasonMainObjectiveCategory?> onSelectSecondary;
  final ValueChanged<SeasonObjectiveAmbitionLevel> onSelectAmbition;
  final ValueChanged<String> onToggleSigning;
  final ValueChanged<PressQaTone> onSelectTone;

  const _LeftConfigurationColumn({
    required this.state,
    required this.isCompleted,
    required this.onSelectMain,
    required this.onSelectSecondary,
    required this.onSelectAmbition,
    required this.onToggleSigning,
    required this.onSelectTone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: '1. Główne Cele na Sezon ${state.seasonYear}',
          subtitle:
              'Wybierz priorytet zespołu oraz poziom deklarowanych ambicji przed kamerami.',
          icon: Icons.flag_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...SeasonMainObjectiveCategory.values.map((objective) {
                final isSelected = state.selectedMainObjective == objective;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _InteractiveSelectionTile(
                    title: objective.label,
                    subtitle: objective.subtitle,
                    trailingText: 'Presja ${objective.pressureLevel}/5',
                    isSelected: isSelected,
                    isDisabled: isCompleted,
                    accentColor: AppColors.goldAccent,
                    onTap: () => onSelectMain(objective),
                  ),
                );
              }),
              const SizedBox(height: 12),
              const Text(
                'Poziom Ambicji Deklaracji',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SeasonObjectiveAmbitionLevel.values.map((ambition) {
                  return _InteractiveChoiceChip(
                    label: ambition.label,
                    isSelected: state.ambitionLevel == ambition,
                    isDisabled: isCompleted,
                    onTap: () => onSelectAmbition(ambition),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              const Text(
                'Cel Dodatkowy (Opcjonalnie)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SeasonMainObjectiveCategory.values
                    .where((o) => o != state.selectedMainObjective)
                    .map((objective) {
                  final selected = state.secondaryObjective == objective;
                  return _InteractiveChoiceChip(
                    label: objective.label,
                    isSelected: selected,
                    isDisabled: isCompleted,
                    onTap: () => onSelectSecondary(selected ? null : objective),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: '2. Prezentacja Nowych Transferów',
          subtitle:
              'Wyróżnij do ${PreSeasonTeamPresentationEvent.maxFeaturedSignings} nabytków w głównym świetle reflektorów.',
          icon: Icons.person_add_alt_1_rounded,
          child: state.newSignings.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Brak nowych transferów w tym oknie — zespół stawia na stabilizację obecnego składu.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : Column(
                  children: state.newSignings.map((signing) {
                    final isFeatured =
                        state.featuredSigningIds.contains(signing.riderId);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _InteractiveSelectionTile(
                        title:
                            '${signing.fullName} (${signing.nationalityIso}) • OVR ${signing.overallRating}',
                        subtitle:
                            '${signing.signingType.label} • z ${signing.previousTeamName} • ${signing.contractYears} lat(a)',
                        trailingText:
                            '+${signing.mediaInterestGain.toStringAsFixed(1)} Media',
                        isSelected: isFeatured,
                        isDisabled: isCompleted,
                        accentColor: AppColors.accentBlue,
                        onTap: () => onToggleSigning(signing.riderId),
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: '3. Sesja Q&A z Dziennikarzami',
          subtitle:
              'Wybierz ton wypowiedzi podczas oficjalnej konferencji prasowej.',
          icon: Icons.record_voice_over_rounded,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PressQaTone.values.map((tone) {
              return _InteractiveChoiceChip(
                label: tone.label,
                isSelected: state.pressTone == tone,
                isDisabled: isCompleted,
                onTap: () => onSelectTone(tone),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _RightStageAndMetricsColumn extends StatelessWidget {
  final PreSeasonTeamPresentationState state;
  final PreSeasonPresentationPreviewMetrics preview;
  final bool isCompleted;
  final ValueChanged<String> onSelectKit;
  final VoidCallback onConfirm;

  const _RightStageAndMetricsColumn({
    required this.state,
    required this.preview,
    required this.isCompleted,
    required this.onSelectKit,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final selectedKit = state.selectedKit;
    final sponsorName = state.team?.sponsors.isNotEmpty == true
        ? state.team!.sponsors.first.companyName
        : 'PRO PELOTON';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: 'Indeksy Otwarcia Sezonu',
          subtitle:
              'Wpływ gali na początkowe zaufanie sponsora i szum medialny.',
          icon: Icons.analytics_rounded,
          child: Column(
            children: [
              _MetricProgressBar(
                label: 'Indeks Zadowolenia Sponsora',
                value: preview.initialSponsorSatisfactionIndex,
                delta: preview.sponsorSatisfactionDelta,
                color: AppColors.goldAccent,
              ),
              const SizedBox(height: 12),
              _MetricProgressBar(
                label: 'Indeks Zainteresowania Mediów',
                value: preview.initialMediaInterestIndex,
                delta: preview.mediaInterestDelta,
                color: AppColors.accentBlue,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MiniStatChip(
                      label: 'Wartość Medialna TV',
                      value: Formatters.formatCurrency(
                        preview.projectedMediaValueEur,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStatChip(
                      label: 'Morale Składu',
                      value: '+${preview.teamMoraleBonus} pkt',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: '4. Prezentacja Nowej Koszulki',
          subtitle: 'Wybierz projekt stroju wyścigowego na nowy sezon.',
          icon: Icons.checkroom_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (selectedKit != null)
                Container(
                  height: 170,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: CustomPaint(
                    painter: _PresentationJerseyPreviewPainter(
                      kit: selectedKit,
                      sponsorName: sponsorName,
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          '${selectedKit.name} • ${selectedKit.patternStyle.label}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ...state.kitVariants.map((kit) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _InteractiveSelectionTile(
                    title: kit.name,
                    subtitle: kit.tagline,
                    trailingText:
                        'Logo ${(kit.sponsorLogoProminence * 100).round()}%',
                    isSelected: selectedKit?.id == kit.id,
                    isDisabled: isCompleted,
                    accentColor: AppColors.primaryAccent,
                    onTap: () => onSelectKit(kit.id),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (isCompleted && state.outcome != null)
          _OutcomeSummaryCard(outcome: state.outcome!)
        else
          _PrimaryConfirmButton(
            label: 'ZATWIERDŹ PREZENTACJĘ SEZONU',
            enabled: state.team != null && selectedKit != null,
            onPressed: onConfirm,
          ),
      ],
    );
  }
}

class _OutcomeSummaryCard extends StatelessWidget {
  final PreSeasonTeamPresentationOutcome outcome;

  const _OutcomeSummaryCard({required this.outcome});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.statusSuccess.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.verified_rounded,
                color: AppColors.statusSuccess,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'RAPORT KOŃCOWY MEDIÓW',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.statusSuccess,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            outcome.headlineSummary,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...outcome.mediaQuotes.map(
            (q) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $q',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.goldAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InteractiveSelectionTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final String trailingText;
  final bool isSelected;
  final bool isDisabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _InteractiveSelectionTile({
    required this.title,
    required this.subtitle,
    required this.trailingText,
    required this.isSelected,
    required this.isDisabled,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_InteractiveSelectionTile> createState() =>
      _InteractiveSelectionTileState();
}

class _InteractiveSelectionTileState extends State<_InteractiveSelectionTile> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected
        ? widget.accentColor
        : (_isFocused
            ? AppColors.goldAccent
            : (_isHovered
                ? AppColors.textSecondary.withValues(alpha: 0.45)
                : AppColors.cardBorder));

    final bgColor = widget.isSelected
        ? widget.accentColor.withValues(alpha: 0.14)
        : (_isPressed
            ? AppColors.surfaceLight.withValues(alpha: 0.9)
            : (_isHovered ? AppColors.surfaceLight : AppColors.background));

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: MouseRegion(
        cursor: widget.isDisabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: widget.isDisabled
              ? null
              : (_) => setState(() => _isPressed = true),
          onTapUp: widget.isDisabled
              ? null
              : (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.isDisabled ? null : widget.onTap,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: widget.isDisabled && !widget.isSelected ? 0.55 : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: widget.isSelected || _isFocused ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: widget.isSelected
                        ? widget.accentColor
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.trailingText,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: widget.isSelected
                          ? widget.accentColor
                          : AppColors.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveChoiceChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _InteractiveChoiceChip({
    required this.label,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_InteractiveChoiceChip> createState() => _InteractiveChoiceChipState();
}

class _InteractiveChoiceChipState extends State<_InteractiveChoiceChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: MouseRegion(
        cursor: widget.isDisabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.isDisabled ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.primaryAccent.withValues(alpha: 0.25)
                  : (_hovered ? AppColors.surfaceLight : AppColors.background),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isSelected
                    ? AppColors.goldAccent
                    : (_focused ? AppColors.accentBlue : AppColors.cardBorder),
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight:
                    widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                color: widget.isDisabled && !widget.isSelected
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryConfirmButton extends StatefulWidget {
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _PrimaryConfirmButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_PrimaryConfirmButton> createState() => _PrimaryConfirmButtonState();
}

class _PrimaryConfirmButtonState extends State<_PrimaryConfirmButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bg = !widget.enabled
        ? AppColors.surfaceLight
        : (_pressed
            ? AppColors.primaryAccent.withValues(alpha: 0.85)
            : (_hovered ? AppColors.goldAccent : AppColors.primaryAccent));

    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown:
              widget.enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp:
              widget.enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : (widget.enabled
                        ? AppColors.goldAccent.withValues(alpha: 0.5)
                        : AppColors.cardBorder),
              ),
            ),
            child: Center(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: widget.enabled
                      ? (_hovered ? AppColors.background : AppColors.textPrimary)
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricProgressBar extends StatelessWidget {
  final String label;
  final double value;
  final double delta;
  final Color color;

  const _MetricProgressBar({
    required this.label,
    required this.value,
    required this.delta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final sign = delta >= 0 ? '+' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)} / 100 ($sign${delta.toStringAsFixed(1)})',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 8,
            color: AppColors.background,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (value / 100.0).clamp(0.0, 1.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniStatChip extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStatChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresentationJerseyPreviewPainter extends CustomPainter {
  final KitPresentationVariant kit;
  final String sponsorName;

  const _PresentationJerseyPreviewPainter({
    required this.kit,
    required this.sponsorName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final primary = _parseHexColor(kit.primaryHex, AppColors.primaryAccent);
    final secondary = _parseHexColor(kit.secondaryHex, AppColors.surface);
    final accent = _parseHexColor(kit.accentHex, AppColors.goldAccent);

    final cx = size.width / 2;
    const top = 16.0;
    final bodyHeight = size.height - 50.0;

    final jerseyPath = Path()
      ..moveTo(cx - 22, top)
      ..lineTo(cx - 56, top + 14)
      ..lineTo(cx - 68, top + 46)
      ..lineTo(cx - 42, top + 54)
      ..lineTo(cx - 36, top + 38)
      ..lineTo(cx - 36, top + bodyHeight)
      ..lineTo(cx + 36, top + bodyHeight)
      ..lineTo(cx + 36, top + 38)
      ..lineTo(cx + 42, top + 54)
      ..lineTo(cx + 68, top + 46)
      ..lineTo(cx + 56, top + 14)
      ..lineTo(cx + 22, top)
      ..quadraticBezierTo(cx, top + 12, cx - 22, top)
      ..close();

    final basePaint = Paint()..style = PaintingStyle.fill;
    if (kit.patternStyle == JerseyPatternStyle.modernAeroFade) {
      basePaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [primary, secondary],
      ).createShader(Rect.fromLTWH(cx - 70, top, 140, bodyHeight));
    } else {
      basePaint.color = primary;
    }
    canvas.drawPath(jerseyPath, basePaint);

    // Wzór na piersi / pasy
    canvas.save();
    canvas.clipPath(jerseyPath);

    final bandHeight = 14.0 + (kit.sponsorLogoProminence * 12.0);
    final bandPaint = Paint()..color = secondary;
    canvas.drawRect(
      Rect.fromLTWH(cx - 40, top + 32, 80, bandHeight),
      bandPaint,
    );

    final accentStripePaint = Paint()..color = accent;
    canvas.drawRect(
      Rect.fromLTWH(cx - 40, top + 32 + bandHeight, 80, 4),
      accentStripePaint,
    );

    // Mankiety rękawków
    canvas.drawRect(
      Rect.fromLTWH(cx - 72, top + 40, 34, 6),
      accentStripePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(cx + 38, top + 40, 34, 6),
      accentStripePaint,
    );

    canvas.restore();

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = accent.withValues(alpha: 0.75);
    canvas.drawPath(jerseyPath, outlinePaint);

    // Nazwa sponsora na piersi
    final textPainter = TextPainter(
      text: TextSpan(
        text: sponsorName.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9 + (kit.sponsorLogoProminence * 2),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppColors.textPrimary,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 66);

    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, top + 34 + (bandHeight - textPainter.height) / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _PresentationJerseyPreviewPainter oldDelegate) {
    return oldDelegate.kit != kit || oldDelegate.sponsorName != sponsorName;
  }

  static Color _parseHexColor(String hex, Color fallback) {
    final cleaned = hex.trim().replaceAll('#', '');
    if (cleaned.length == 6) {
      final value = int.tryParse('FF$cleaned', radix: 16);
      if (value != null) return Color(value);
    }
    return fallback;
  }
}
