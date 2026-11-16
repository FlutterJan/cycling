import 'dart:math' as math;

import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';

/// Kategoryzacja profilu etapu dla równowagi ucieczka vs. peleton.
enum EquilibriumTerrainProfile {
  /// Etap płaski kontrolowany przez drużyny sprinterskie (szansa ucieczki ~8-12%)
  flatSprinterControlled,

  /// Etap pagórkowaty sprzyjający ucieczkom / Breakaway-Friendly (szansa ~45-55%)
  hillyBreakawayFriendly,

  /// Klasyk brukowany (selektywny teren, szansa pośrednia)
  cobbleClassic,

  /// Etap wysokogórski / finisz na podjeździe (decyduje bufor >= 1 min / 3 km u podnóża)
  highMountain,

  /// Jazda indywidualna lub drużynowa na czas (brak ucieczki)
  timeTrial;

  String toJson() => name;

  static EquilibriumTerrainProfile fromJson(String value) {
    return EquilibriumTerrainProfile.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => EquilibriumTerrainProfile.flatSprinterControlled,
    );
  }

  /// Mapuje [StageType] na profil równowagi taktycznej.
  static EquilibriumTerrainProfile fromStageType(StageType stageType) {
    switch (stageType) {
      case StageType.flat:
        return EquilibriumTerrainProfile.flatSprinterControlled;
      case StageType.hilly:
        return EquilibriumTerrainProfile.hillyBreakawayFriendly;
      case StageType.cobbleClassic:
        return EquilibriumTerrainProfile.cobbleClassic;
      case StageType.highMountain:
      case StageType.summitFinish:
        return EquilibriumTerrainProfile.highMountain;
      case StageType.individualTimeTrial:
      case StageType.teamTimeTrial:
        return EquilibriumTerrainProfile.timeTrial;
    }
  }
}

/// Parametry finałowego podjazdu decydującego o przetrwaniu ucieczki w wysokich górach.
class FinalClimbProfile {
  /// Długość finałowego podjazdu w kilometrach [km].
  final double lengthKm;

  /// Średnie nachylenie podjazdu [%].
  final double averageGradientPercent;

  /// Łączne przewyższenie na finałowym podjeździe [m].
  final double elevationGainM;

  /// Kilometraż początku podjazdu (podnóże) [km].
  final double footKm;

  /// Kilometraż szczytu podjazdu / mety [km].
  final double summitKm;

  const FinalClimbProfile({
    required this.lengthKm,
    required this.averageGradientPercent,
    required this.elevationGainM,
    required this.footKm,
    required this.summitKm,
  });

  /// Wymagany zapas czasu u podnóża finałowego podjazdu:
  /// minimum 1 minuta (60 s) na każde 3 km wspinaczki (= 20 s/km).
  double get requiredFootGapSeconds =>
      BreakawayVsPelotonEquilibriumSolver.requiredMountainFootGapSeconds(
        lengthKm,
      );

  /// Wymagany zapas czasu u podnóża w minutach.
  double get requiredFootGapMinutes => requiredFootGapSeconds / 60.0;

  FinalClimbProfile copyWith({
    double? lengthKm,
    double? averageGradientPercent,
    double? elevationGainM,
    double? footKm,
    double? summitKm,
  }) {
    return FinalClimbProfile(
      lengthKm: lengthKm ?? this.lengthKm,
      averageGradientPercent:
          averageGradientPercent ?? this.averageGradientPercent,
      elevationGainM: elevationGainM ?? this.elevationGainM,
      footKm: footKm ?? this.footKm,
      summitKm: summitKm ?? this.summitKm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lengthKm': lengthKm,
      'averageGradientPercent': averageGradientPercent,
      'elevationGainM': elevationGainM,
      'footKm': footKm,
      'summitKm': summitKm,
    };
  }

  factory FinalClimbProfile.fromJson(Map<String, dynamic> json) {
    return FinalClimbProfile(
      lengthKm: (json['lengthKm'] as num).toDouble(),
      averageGradientPercent:
          (json['averageGradientPercent'] as num).toDouble(),
      elevationGainM: (json['elevationGainM'] as num).toDouble(),
      footKm: (json['footKm'] as num).toDouble(),
      summitKm: (json['summitKm'] as num).toDouble(),
    );
  }

  /// Automatycznie wykrywa finałowy podjazd na podstawie segmentów etapu [RaceStage].
  ///
  /// Skanuje segmenty od końca etapu, łącząc ciągły blok wspinaczkowy (lub
  /// ostatni znaczący podjazd kończący się tuż przed metą). Zwraca `null`,
  /// jeśli etap nie posiada finałowej wspinaczki o długości >= 1.5 km.
  static FinalClimbProfile? detectFromStage(RaceStage stage) {
    final segments = stage.segments;
    if (segments.isEmpty) return null;

    // Szukamy od końca ostatniego segmentu o nachyleniu wspinaczkowym (> 2.5%)
    int climbEndIndex = -1;
    for (int i = segments.length - 1; i >= 0; i--) {
      final StageSegment seg = segments[i];
      if (seg.gradientPercent >= 2.5 || seg.isKom) {
        climbEndIndex = i;
        break;
      }
      // Jeśli przed metą jest krótki płaski zjazd/finisz (< 15 km od końca), szukaj dalej
      if (stage.totalDistanceKm - seg.startKm > 18.0) {
        break;
      }
    }

    if (climbEndIndex < 0) return null;

    int climbStartIndex = climbEndIndex;
    for (int i = climbEndIndex - 1; i >= 0; i--) {
      final StageSegment seg = segments[i];
      if (seg.gradientPercent >= 2.0 || seg.isKom) {
        climbStartIndex = i;
      } else {
        break;
      }
    }

    double lengthKm = 0.0;
    double gainM = 0.0;
    for (int i = climbStartIndex; i <= climbEndIndex; i++) {
      lengthKm += segments[i].lengthKm;
      gainM += segments[i].elevationGainM;
    }

    if (lengthKm < 1.5) return null;

    final double avgGrad =
        lengthKm > 0.0 ? (gainM / (lengthKm * 1000.0)) * 100.0 : 0.0;

    return FinalClimbProfile(
      lengthKm: lengthKm,
      averageGradientPercent: avgGrad,
      elevationGainM: gainM,
      footKm: segments[climbStartIndex].startKm,
      summitKm: segments[climbEndIndex].endKm,
    );
  }
}

/// Dane wejściowe dla solvera równowagi ucieczki i peletonu.
class BreakawayEquilibriumInput {
  final StageType stageType;
  final double stageDistanceKm;
  final double currentKm;

  /// Aktualna przewaga czasowa ucieczki nad peletonem [s].
  final double currentGapSeconds;

  /// Liczba kolarzy w ucieczce.
  final int breakawayRiderCount;

  /// Jakość współpracy w ucieczce [0.0 - 1.0].
  final double breakawayCooperationScore;

  /// Średnia ocena siły/silnika kolarzy w ucieczce [0.0 - 100.0].
  final double breakawayAverageEngineRating;

  /// Liczba drużyn sprinterskich zainteresowanych finiszem z peletonu.
  final int sprintTeamsInterestedCount;

  /// Liczba pomocników pracujących aktualnie w pociągu pościgowym.
  final int committedChaseDomestiques;

  /// Czy w ucieczce znajduje się kolarz zagrażający liderowi GC.
  final bool isBreakawayDangerousInGc;

  /// Prędkość wiatru na etapie [km/h].
  final double windSpeedKmh;

  /// Kąt natarcia wiatru względem kierunku jazdy [0° = czołowy, 180° = w plecy].
  final double relativeWindAngleDegrees;

  /// Profil finałowego podjazdu (istotny dla etapów górskich).
  final FinalClimbProfile? finalClimb;

  /// Rzeczywisty zapas czasu u podnóża finałowego podjazdu [s] (opcjonalnie).
  final double? gapAtClimbFootSeconds;

  /// Intensywność walki faworytów GC na finałowym podjeździe [0.0 - 1.0].
  final double gcBattleIntensity;

  const BreakawayEquilibriumInput({
    required this.stageType,
    required this.stageDistanceKm,
    required this.currentKm,
    required this.currentGapSeconds,
    required this.breakawayRiderCount,
    this.breakawayCooperationScore = 0.85,
    this.breakawayAverageEngineRating = 75.0,
    this.sprintTeamsInterestedCount = 3,
    this.committedChaseDomestiques = 4,
    this.isBreakawayDangerousInGc = false,
    this.windSpeedKmh = 10.0,
    this.relativeWindAngleDegrees = 90.0,
    this.finalClimb,
    this.gapAtClimbFootSeconds,
    this.gcBattleIntensity = 0.75,
  });

  BreakawayEquilibriumInput copyWith({
    StageType? stageType,
    double? stageDistanceKm,
    double? currentKm,
    double? currentGapSeconds,
    int? breakawayRiderCount,
    double? breakawayCooperationScore,
    double? breakawayAverageEngineRating,
    int? sprintTeamsInterestedCount,
    int? committedChaseDomestiques,
    bool? isBreakawayDangerousInGc,
    double? windSpeedKmh,
    double? relativeWindAngleDegrees,
    FinalClimbProfile? finalClimb,
    double? gapAtClimbFootSeconds,
    double? gcBattleIntensity,
  }) {
    return BreakawayEquilibriumInput(
      stageType: stageType ?? this.stageType,
      stageDistanceKm: stageDistanceKm ?? this.stageDistanceKm,
      currentKm: currentKm ?? this.currentKm,
      currentGapSeconds: currentGapSeconds ?? this.currentGapSeconds,
      breakawayRiderCount: breakawayRiderCount ?? this.breakawayRiderCount,
      breakawayCooperationScore:
          breakawayCooperationScore ?? this.breakawayCooperationScore,
      breakawayAverageEngineRating:
          breakawayAverageEngineRating ?? this.breakawayAverageEngineRating,
      sprintTeamsInterestedCount:
          sprintTeamsInterestedCount ?? this.sprintTeamsInterestedCount,
      committedChaseDomestiques:
          committedChaseDomestiques ?? this.committedChaseDomestiques,
      isBreakawayDangerousInGc:
          isBreakawayDangerousInGc ?? this.isBreakawayDangerousInGc,
      windSpeedKmh: windSpeedKmh ?? this.windSpeedKmh,
      relativeWindAngleDegrees:
          relativeWindAngleDegrees ?? this.relativeWindAngleDegrees,
      finalClimb: finalClimb ?? this.finalClimb,
      gapAtClimbFootSeconds:
          gapAtClimbFootSeconds ?? this.gapAtClimbFootSeconds,
      gcBattleIntensity: gcBattleIntensity ?? this.gcBattleIntensity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stageType': stageType.toJson(),
      'stageDistanceKm': stageDistanceKm,
      'currentKm': currentKm,
      'currentGapSeconds': currentGapSeconds,
      'breakawayRiderCount': breakawayRiderCount,
      'breakawayCooperationScore': breakawayCooperationScore,
      'breakawayAverageEngineRating': breakawayAverageEngineRating,
      'sprintTeamsInterestedCount': sprintTeamsInterestedCount,
      'committedChaseDomestiques': committedChaseDomestiques,
      'isBreakawayDangerousInGc': isBreakawayDangerousInGc,
      'windSpeedKmh': windSpeedKmh,
      'relativeWindAngleDegrees': relativeWindAngleDegrees,
      'finalClimb': finalClimb?.toJson(),
      'gapAtClimbFootSeconds': gapAtClimbFootSeconds,
      'gcBattleIntensity': gcBattleIntensity,
    };
  }

  factory BreakawayEquilibriumInput.fromJson(Map<String, dynamic> json) {
    return BreakawayEquilibriumInput(
      stageType: StageType.fromJson(json['stageType'] as String),
      stageDistanceKm: (json['stageDistanceKm'] as num).toDouble(),
      currentKm: (json['currentKm'] as num).toDouble(),
      currentGapSeconds: (json['currentGapSeconds'] as num).toDouble(),
      breakawayRiderCount: (json['breakawayRiderCount'] as num).toInt(),
      breakawayCooperationScore:
          (json['breakawayCooperationScore'] as num?)?.toDouble() ?? 0.85,
      breakawayAverageEngineRating:
          (json['breakawayAverageEngineRating'] as num?)?.toDouble() ?? 75.0,
      sprintTeamsInterestedCount:
          (json['sprintTeamsInterestedCount'] as num?)?.toInt() ?? 3,
      committedChaseDomestiques:
          (json['committedChaseDomestiques'] as num?)?.toInt() ?? 4,
      isBreakawayDangerousInGc:
          json['isBreakawayDangerousInGc'] as bool? ?? false,
      windSpeedKmh: (json['windSpeedKmh'] as num?)?.toDouble() ?? 10.0,
      relativeWindAngleDegrees:
          (json['relativeWindAngleDegrees'] as num?)?.toDouble() ?? 90.0,
      finalClimb: json['finalClimb'] != null
          ? FinalClimbProfile.fromJson(
              json['finalClimb'] as Map<String, dynamic>,
            )
          : null,
      gapAtClimbFootSeconds:
          (json['gapAtClimbFootSeconds'] as num?)?.toDouble(),
      gcBattleIntensity:
          (json['gcBattleIntensity'] as num?)?.toDouble() ?? 0.75,
    );
  }
}

/// Wynik analizy równowagi ucieczki względem peletonu.
class BreakawayEquilibriumResult {
  final EquilibriumTerrainProfile terrainProfile;

  /// Prawdopodobieństwo dojechania ucieczki przed peletonem [0.0 - 1.0].
  final double survivalProbability;

  /// Bazowe prawdopodobieństwo wynikające z równowagi danego profilu etapu [0.0 - 1.0].
  final double baselineProbability;

  /// Równowagowa prędkość pościgu peletonu [km/h].
  final double equilibriumChaseSpeedKmh;

  /// Równowagowa prędkość ucieczki [km/h].
  final double equilibriumBreakawaySpeedKmh;

  /// Bilans odrabiania strat przez peleton [s / 10 km] (wartość < 0 oznacza ucieczkę powiększającą przewagę).
  final double netClawbackSecondsPer10Km;

  /// Prognozowana przewaga na linii mety [s] (< 0 oznacza skasowanie przed metą).
  final double projectedGapAtFinishSeconds;

  /// Prognozowany kilometr skasowania ucieczki [km] (lub dystans etapu jeśli ucieczka dojedzie).
  final double projectedCatchKm;

  /// Wymagany zapas czasu u podnóża finałowego podjazdu [s] (>= 1 min / 3 km).
  final double? requiredClimbFootGapSeconds;

  /// Rzeczywisty lub estymowany zapas czasu u podnóża finałowego podjazdu [s].
  final double? actualOrEstimatedClimbFootGapSeconds;

  /// Nadwyżka lub deficyt zapasu u podnóża względem progu 1 min / 3 km [s].
  final double? climbFootGapMarginSeconds;

  /// Czy ucieczka spełnia warunek przetrwania na finałowym podjeździe (>= 1 min / 3 km).
  final bool meetsMountainFootRule;

  /// Zwięzłe podsumowanie taktyczne.
  final String tacticalSummary;

  const BreakawayEquilibriumResult({
    required this.terrainProfile,
    required this.survivalProbability,
    required this.baselineProbability,
    required this.equilibriumChaseSpeedKmh,
    required this.equilibriumBreakawaySpeedKmh,
    required this.netClawbackSecondsPer10Km,
    required this.projectedGapAtFinishSeconds,
    required this.projectedCatchKm,
    this.requiredClimbFootGapSeconds,
    this.actualOrEstimatedClimbFootGapSeconds,
    this.climbFootGapMarginSeconds,
    required this.meetsMountainFootRule,
    required this.tacticalSummary,
  });

  BreakawayEquilibriumResult copyWith({
    EquilibriumTerrainProfile? terrainProfile,
    double? survivalProbability,
    double? baselineProbability,
    double? equilibriumChaseSpeedKmh,
    double? equilibriumBreakawaySpeedKmh,
    double? netClawbackSecondsPer10Km,
    double? projectedGapAtFinishSeconds,
    double? projectedCatchKm,
    double? requiredClimbFootGapSeconds,
    double? actualOrEstimatedClimbFootGapSeconds,
    double? climbFootGapMarginSeconds,
    bool? meetsMountainFootRule,
    String? tacticalSummary,
  }) {
    return BreakawayEquilibriumResult(
      terrainProfile: terrainProfile ?? this.terrainProfile,
      survivalProbability: survivalProbability ?? this.survivalProbability,
      baselineProbability: baselineProbability ?? this.baselineProbability,
      equilibriumChaseSpeedKmh:
          equilibriumChaseSpeedKmh ?? this.equilibriumChaseSpeedKmh,
      equilibriumBreakawaySpeedKmh:
          equilibriumBreakawaySpeedKmh ?? this.equilibriumBreakawaySpeedKmh,
      netClawbackSecondsPer10Km:
          netClawbackSecondsPer10Km ?? this.netClawbackSecondsPer10Km,
      projectedGapAtFinishSeconds:
          projectedGapAtFinishSeconds ?? this.projectedGapAtFinishSeconds,
      projectedCatchKm: projectedCatchKm ?? this.projectedCatchKm,
      requiredClimbFootGapSeconds:
          requiredClimbFootGapSeconds ?? this.requiredClimbFootGapSeconds,
      actualOrEstimatedClimbFootGapSeconds:
          actualOrEstimatedClimbFootGapSeconds ??
              this.actualOrEstimatedClimbFootGapSeconds,
      climbFootGapMarginSeconds:
          climbFootGapMarginSeconds ?? this.climbFootGapMarginSeconds,
      meetsMountainFootRule:
          meetsMountainFootRule ?? this.meetsMountainFootRule,
      tacticalSummary: tacticalSummary ?? this.tacticalSummary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'terrainProfile': terrainProfile.toJson(),
      'survivalProbability': survivalProbability,
      'baselineProbability': baselineProbability,
      'equilibriumChaseSpeedKmh': equilibriumChaseSpeedKmh,
      'equilibriumBreakawaySpeedKmh': equilibriumBreakawaySpeedKmh,
      'netClawbackSecondsPer10Km': netClawbackSecondsPer10Km,
      'projectedGapAtFinishSeconds': projectedGapAtFinishSeconds,
      'projectedCatchKm': projectedCatchKm,
      'requiredClimbFootGapSeconds': requiredClimbFootGapSeconds,
      'actualOrEstimatedClimbFootGapSeconds':
          actualOrEstimatedClimbFootGapSeconds,
      'climbFootGapMarginSeconds': climbFootGapMarginSeconds,
      'meetsMountainFootRule': meetsMountainFootRule,
      'tacticalSummary': tacticalSummary,
    };
  }

  factory BreakawayEquilibriumResult.fromJson(Map<String, dynamic> json) {
    return BreakawayEquilibriumResult(
      terrainProfile:
          EquilibriumTerrainProfile.fromJson(json['terrainProfile'] as String),
      survivalProbability: (json['survivalProbability'] as num).toDouble(),
      baselineProbability: (json['baselineProbability'] as num).toDouble(),
      equilibriumChaseSpeedKmh:
          (json['equilibriumChaseSpeedKmh'] as num).toDouble(),
      equilibriumBreakawaySpeedKmh:
          (json['equilibriumBreakawaySpeedKmh'] as num).toDouble(),
      netClawbackSecondsPer10Km:
          (json['netClawbackSecondsPer10Km'] as num).toDouble(),
      projectedGapAtFinishSeconds:
          (json['projectedGapAtFinishSeconds'] as num).toDouble(),
      projectedCatchKm: (json['projectedCatchKm'] as num).toDouble(),
      requiredClimbFootGapSeconds:
          (json['requiredClimbFootGapSeconds'] as num?)?.toDouble(),
      actualOrEstimatedClimbFootGapSeconds:
          (json['actualOrEstimatedClimbFootGapSeconds'] as num?)?.toDouble(),
      climbFootGapMarginSeconds:
          (json['climbFootGapMarginSeconds'] as num?)?.toDouble(),
      meetsMountainFootRule: json['meetsMountainFootRule'] as bool? ?? false,
      tacticalSummary: json['tacticalSummary'] as String,
    );
  }

  @override
  String toString() {
    return 'BreakawayEquilibriumResult(${terrainProfile.name}, '
        'prob: ${(survivalProbability * 100).toStringAsFixed(1)}%, '
        'clawback: ${netClawbackSecondsPer10Km.toStringAsFixed(1)}s/10km, '
        'projectedCatch: ${projectedCatchKm.toStringAsFixed(1)}km)';
  }
}

/// Zbalansowany solver matematyki ucieczek względem peletonu.
///
/// Modeluje realistyczne progi równowagi znane z wyścigów WorldTour:
/// - Etapy płaskie z drużynami sprinterskimi: 8–12% szans na dojechanie ucieczki.
/// - Etapy pagórkowate (Breakaway-Friendly): 45–55% szans na dojechanie ucieczki.
/// - Wysokie góry: o przetrwaniu decyduje zapas czasu u podnóża finałowego podjazdu
///   (minimum 1 minuta na każde 3 km wspinaczki, czyli >= 20 s/km).
class BreakawayVsPelotonEquilibriumSolver {
  BreakawayVsPelotonEquilibriumSolver._();

  /// Bazowa szansa przetrwania ucieczki na etapie płaskim kontrolowanym przez sprinterów (10%).
  static const double flatSprinterBaselineProbability = 0.10;

  /// Dolna i górna granica nominalnego pasma na płaskim etapie ze sprinterami (8–12%).
  static const double flatSprinterBandMin = 0.08;
  static const double flatSprinterBandMax = 0.12;

  /// Bazowa szansa przetrwania ucieczki na etapie pagórkowatym Breakaway-Friendly (50%).
  static const double hillyBreakawayFriendlyBaselineProbability = 0.50;

  /// Dolna i górna granica nominalnego pasma na etapie pagórkowatym (45–55%).
  static const double hillyBreakawayFriendlyBandMin = 0.45;
  static const double hillyBreakawayFriendlyBandMax = 0.55;

  /// Wymagany zapas w sekundach na każdy kilometr finałowego podjazdu (1 min / 3 km = 20 s/km).
  static const double requiredSecondsPerClimbKm = 20.0;

  /// Domyślna długość finałowego podjazdu w wysokich górach, jeśli nie podano profilu [km].
  static const double defaultHighMountainClimbLengthKm = 12.0;

  /// Oblicza wymagany zapas czasu u podnóża finałowego podjazdu [s]:
  /// minimum 1 min (60 s) na każde 3 km wspinaczki.
  static double requiredMountainFootGapSeconds(double climbLengthKm) {
    if (climbLengthKm <= 0.0) return 0.0;
    return (climbLengthKm / 3.0) * 60.0;
  }

  /// Wyznacza prawdopodobieństwo przetrwania w wysokich górach wyłącznie na podstawie
  /// zapasu czasu u podnóża finałowego podjazdu względem reguły 1 min / 3 km.
  static double evaluateMountainFootSurvival({
    required double gapAtFootSeconds,
    required double climbLengthKm,
    double gcBattleIntensity = 0.75,
    bool isBreakawayDangerousInGc = false,
  }) {
    final double requiredGap = requiredMountainFootGapSeconds(climbLengthKm);
    if (requiredGap <= 0.0) {
      return gapAtFootSeconds > 15.0 ? 0.65 : 0.10;
    }

    final double safeIntensity = gcBattleIntensity.clamp(0.0, 1.0);
    // Intensywna walka faworytów GC podnosi nieco efektywny próg potrzebnego zapasu
    final double effectiveRequiredGap = requiredGap *
        (0.95 + safeIntensity * 0.10) *
        (isBreakawayDangerousInGc ? 1.18 : 1.0);

    final double ratio = gapAtFootSeconds / effectiveRequiredGap;

    if (ratio >= 1.0) {
      // Spełniony próg >= 1 min / 3 km: powyżej 55% do ~94% wraz ze wzrostem bufora
      final double surplusRatio = ratio - 1.0;
      final double bonus = 0.39 * (1.0 - math.exp(-2.2 * surplusRatio));
      return (0.55 + bonus).clamp(0.55, 0.94);
    }

    // Poniżej progu 1 min / 3 km: gwałtowny spadek szans na przetrwanie przed atakami GC
    final double deficitCurve = math.pow(ratio.clamp(0.0, 1.0), 2.1).toDouble();
    return (0.04 + 0.44 * deficitCurve).clamp(0.04, 0.48);
  }

  /// Główny solver równowagi ucieczka vs. peleton dla pełnych danych wejściowych.
  static BreakawayEquilibriumResult solve(BreakawayEquilibriumInput input) {
    final EquilibriumTerrainProfile profile =
        EquilibriumTerrainProfile.fromStageType(input.stageType);
    final double stageLength = math.max(1.0, input.stageDistanceKm);
    final double clampedKm = input.currentKm.clamp(0.0, stageLength);
    final double remainingKm = math.max(0.0, stageLength - clampedKm);

    if (profile == EquilibriumTerrainProfile.timeTrial) {
      return BreakawayEquilibriumResult(
        terrainProfile: profile,
        survivalProbability: 0.0,
        baselineProbability: 0.0,
        equilibriumChaseSpeedKmh: 50.0,
        equilibriumBreakawaySpeedKmh: 50.0,
        netClawbackSecondsPer10Km: 0.0,
        projectedGapAtFinishSeconds: 0.0,
        projectedCatchKm: stageLength,
        meetsMountainFootRule: false,
        tacticalSummary: 'Jazda na czas — brak ucieczek i pościgu peletonu.',
      );
    }

    if (input.breakawayRiderCount <= 0 || input.currentGapSeconds <= 5.0) {
      return BreakawayEquilibriumResult(
        terrainProfile: profile,
        survivalProbability: 0.0,
        baselineProbability: _baselineForProfile(profile),
        equilibriumChaseSpeedKmh: _basePelotonSpeedKmh(profile),
        equilibriumBreakawaySpeedKmh: _basePelotonSpeedKmh(profile),
        netClawbackSecondsPer10Km: 0.0,
        projectedGapAtFinishSeconds: 0.0,
        projectedCatchKm: clampedKm,
        meetsMountainFootRule: false,
        tacticalSummary: 'Brak aktywnej ucieczki — peleton jedzie razem.',
      );
    }

    // 1. Prędkości równowagowe ucieczki i pociągu pościgowego
    final double breakawaySpeed = _computeBreakawaySpeedKmh(input, profile);
    final double chaseSpeed = _computePelotonChaseSpeedKmh(input, profile);

    // Przeliczenie różnicy prędkości na bilans czasu [s / 10 km]
    final double breakawaySecPer10Km = (10.0 / breakawaySpeed) * 3600.0;
    final double chaseSecPer10Km = (10.0 / chaseSpeed) * 3600.0;
    final double netClawbackPer10Km = breakawaySecPer10Km - chaseSecPer10Km;

    // 2. Projekcja miejsca skasowania i przewagi na mecie
    final double projectedGapChangeOverRemaining =
        (remainingKm / 10.0) * netClawbackPer10Km;
    final double projectedGapAtFinish =
        input.currentGapSeconds - projectedGapChangeOverRemaining;

    final double projectedCatchKm;
    if (netClawbackPer10Km > 0.5) {
      final double kmToCatch =
          input.currentGapSeconds / (netClawbackPer10Km / 10.0);
      projectedCatchKm = math.min(stageLength, clampedKm + kmToCatch);
    } else {
      projectedCatchKm = stageLength;
    }

    // 3. Wyznaczenie prawdopodobieństwa przetrwania wg profilu etapu
    switch (profile) {
      case EquilibriumTerrainProfile.flatSprinterControlled:
        return _solveFlatSprinterStage(
          input: input,
          profile: profile,
          remainingKm: remainingKm,
          breakawaySpeed: breakawaySpeed,
          chaseSpeed: chaseSpeed,
          netClawbackPer10Km: netClawbackPer10Km,
          projectedGapAtFinish: projectedGapAtFinish,
          projectedCatchKm: projectedCatchKm,
        );

      case EquilibriumTerrainProfile.hillyBreakawayFriendly:
        return _solveHillyBreakawayFriendlyStage(
          input: input,
          profile: profile,
          remainingKm: remainingKm,
          breakawaySpeed: breakawaySpeed,
          chaseSpeed: chaseSpeed,
          netClawbackPer10Km: netClawbackPer10Km,
          projectedGapAtFinish: projectedGapAtFinish,
          projectedCatchKm: projectedCatchKm,
        );

      case EquilibriumTerrainProfile.cobbleClassic:
        return _solveCobbleClassicStage(
          input: input,
          profile: profile,
          remainingKm: remainingKm,
          breakawaySpeed: breakawaySpeed,
          chaseSpeed: chaseSpeed,
          netClawbackPer10Km: netClawbackPer10Km,
          projectedGapAtFinish: projectedGapAtFinish,
          projectedCatchKm: projectedCatchKm,
        );

      case EquilibriumTerrainProfile.highMountain:
        return _solveHighMountainStage(
          input: input,
          profile: profile,
          stageLength: stageLength,
          clampedKm: clampedKm,
          breakawaySpeed: breakawaySpeed,
          chaseSpeed: chaseSpeed,
          netClawbackPer10Km: netClawbackPer10Km,
          projectedGapAtFinish: projectedGapAtFinish,
          projectedCatchKm: projectedCatchKm,
        );

      case EquilibriumTerrainProfile.timeTrial:
        // Obsłużone powyżej
        throw StateError('TimeTrial should have returned early.');
    }
  }

  /// Wygodny wrapper dla obiektu [RaceStage], automatycznie wykrywający finałowy podjazd.
  static BreakawayEquilibriumResult solveForStage({
    required RaceStage stage,
    required double currentKm,
    required double currentGapSeconds,
    required int breakawayRiderCount,
    double breakawayCooperationScore = 0.85,
    double breakawayAverageEngineRating = 75.0,
    int sprintTeamsInterestedCount = 3,
    int committedChaseDomestiques = 4,
    bool isBreakawayDangerousInGc = false,
    double? gapAtClimbFootSeconds,
    double gcBattleIntensity = 0.75,
  }) {
    final FinalClimbProfile? detectedClimb =
        FinalClimbProfile.detectFromStage(stage);

    double windAngle = 90.0;
    if (stage.segments.isNotEmpty) {
      final seg = stage.segments.firstWhere(
        (s) => currentKm >= s.startKm && currentKm <= s.endKm,
        orElse: () => stage.segments.last,
      );
      windAngle = seg.relativeWindAngleDegrees;
    }

    return solve(
      BreakawayEquilibriumInput(
        stageType: stage.stageType,
        stageDistanceKm: stage.totalDistanceKm,
        currentKm: currentKm,
        currentGapSeconds: currentGapSeconds,
        breakawayRiderCount: breakawayRiderCount,
        breakawayCooperationScore: breakawayCooperationScore,
        breakawayAverageEngineRating: breakawayAverageEngineRating,
        sprintTeamsInterestedCount: sprintTeamsInterestedCount,
        committedChaseDomestiques: committedChaseDomestiques,
        isBreakawayDangerousInGc: isBreakawayDangerousInGc,
        windSpeedKmh: stage.windSpeedKmh,
        relativeWindAngleDegrees: windAngle,
        finalClimb: detectedClimb,
        gapAtClimbFootSeconds: gapAtClimbFootSeconds,
        gcBattleIntensity: gcBattleIntensity,
      ),
    );
  }

  static BreakawayEquilibriumResult _solveFlatSprinterStage({
    required BreakawayEquilibriumInput input,
    required EquilibriumTerrainProfile profile,
    required double remainingKm,
    required double breakawaySpeed,
    required double chaseSpeed,
    required double netClawbackPer10Km,
    required double projectedGapAtFinish,
    required double projectedCatchKm,
  }) {
    final bool hasSprintTeams = input.sprintTeamsInterestedCount >= 1;
    final double coop = input.breakawayCooperationScore.clamp(0.0, 1.0);

    double probability;
    if (!hasSprintTeams) {
      // Brak zainteresowanych drużyn sprinterskich zwiększa szansę ucieczki
      probability = 0.24 + (coop - 0.80) * 0.15;
    } else if (remainingKm <= 12.0 && input.currentGapSeconds >= 90.0) {
      // Późna faza wyścigu, gdy peleton ewidentnie spóźnił pościg
      probability = (0.55 + (input.currentGapSeconds - 90.0) / 180.0 * 0.30)
          .clamp(0.55, 0.88);
    } else {
      // Równowaga nominalna na płaskim etapie ze sprinterskimi drużynami: 8% - 12%
      // Modyfikatory są zbalansowane wokół 10%, by oddać realną dominację pociągów sprinterskich.
      double prob = flatSprinterBaselineProbability;

      // Współpraca i liczebność ucieczki (+/- 1.2%)
      prob += (coop - 0.80) * 0.04;
      if (input.breakawayRiderCount >= 4 && input.breakawayRiderCount <= 7) {
        prob += 0.008;
      } else if (input.breakawayRiderCount <= 2) {
        prob -= 0.012;
      }

      // Poker taktyczny przy wielu drużynach sprinterskich (+0.8%) vs 1-2 zdeterminowane (-0.6%)
      if (input.sprintTeamsInterestedCount >= 3) {
        prob += 0.008;
      } else if (input.sprintTeamsInterestedCount == 1) {
        prob -= 0.006;
      }

      // Wiatr w plecy / boczny lekko sprzyja zgranej ucieczce (+0.6%)
      if (input.windSpeedKmh >= 20.0 && input.relativeWindAngleDegrees >= 110.0) {
        prob += 0.006;
      }

      // Wpływ bieżącego bufora czasowego w ramach pasma 8-12%
      if (projectedGapAtFinish > 0.0) {
        prob += 0.012;
      } else if (remainingKm < 25.0 && input.currentGapSeconds < 45.0) {
        prob -= 0.015;
      }

      if (input.isBreakawayDangerousInGc) {
        // Zagrożenie GC powoduje pełną mobilizację — szansa spada poniżej 8%
        prob = math.min(prob, 0.055);
        probability = prob.clamp(0.02, 0.06);
      } else {
        probability = prob.clamp(flatSprinterBandMin, flatSprinterBandMax);
      }
    }

    final String summary = hasSprintTeams
        ? 'Płaski etap kontrolowany przez ${input.sprintTeamsInterestedCount} '
            'drużyny sprinterskie — szansa ucieczki '
            '${(probability * 100).toStringAsFixed(1)}%.'
        : 'Płaski etap bez pełnej mobilizacji sprinterów — szansa ucieczki '
            '${(probability * 100).toStringAsFixed(1)}%.';

    return BreakawayEquilibriumResult(
      terrainProfile: profile,
      survivalProbability: probability,
      baselineProbability: flatSprinterBaselineProbability,
      equilibriumChaseSpeedKmh: chaseSpeed,
      equilibriumBreakawaySpeedKmh: breakawaySpeed,
      netClawbackSecondsPer10Km: netClawbackPer10Km,
      projectedGapAtFinishSeconds: projectedGapAtFinish,
      projectedCatchKm: projectedCatchKm,
      meetsMountainFootRule: false,
      tacticalSummary: summary,
    );
  }

  static BreakawayEquilibriumResult _solveHillyBreakawayFriendlyStage({
    required BreakawayEquilibriumInput input,
    required EquilibriumTerrainProfile profile,
    required double remainingKm,
    required double breakawaySpeed,
    required double chaseSpeed,
    required double netClawbackPer10Km,
    required double projectedGapAtFinish,
    required double projectedCatchKm,
  }) {
    final double coop = input.breakawayCooperationScore.clamp(0.0, 1.0);
    double prob = hillyBreakawayFriendlyBaselineProbability;

    // Jakość współpracy i siła uciekinierów
    prob += (coop - 0.80) * 0.14;
    prob += ((input.breakawayAverageEngineRating - 75.0) / 25.0) * 0.04;

    // Optymalna grupa na pagórkach (5-12 kolarzy)
    if (input.breakawayRiderCount >= 5 && input.breakawayRiderCount <= 12) {
      prob += 0.025;
    } else if (input.breakawayRiderCount <= 2) {
      prob -= 0.04;
    }

    // Zainteresowanie sprinterów potrafiących przetrwać pagórki lekko zbija szansę
    if (input.sprintTeamsInterestedCount >= 3) {
      prob -= 0.03;
    } else if (input.sprintTeamsInterestedCount == 0) {
      prob += 0.035;
    }

    // Projekcja czasowa na mecie
    if (projectedGapAtFinish >= 45.0) {
      prob += 0.03;
    } else if (projectedGapAtFinish < -120.0 && remainingKm < 35.0) {
      prob -= 0.04;
    }

    double probability;
    if (input.isBreakawayDangerousInGc) {
      // Jeśli ucieczka zagraża GC, peleton jedzie pełnym pościgiem i zbija szansę
      probability = (prob - 0.24).clamp(0.12, 0.35);
    } else if (remainingKm <= 10.0 && input.currentGapSeconds >= 90.0) {
      probability = (prob + 0.25).clamp(0.60, 0.90);
    } else {
      // Nominalne pasmo Breakaway-Friendly: 45% - 55%
      probability = prob.clamp(
        hillyBreakawayFriendlyBandMin,
        hillyBreakawayFriendlyBandMax,
      );
    }

    return BreakawayEquilibriumResult(
      terrainProfile: profile,
      survivalProbability: probability,
      baselineProbability: hillyBreakawayFriendlyBaselineProbability,
      equilibriumChaseSpeedKmh: chaseSpeed,
      equilibriumBreakawaySpeedKmh: breakawaySpeed,
      netClawbackSecondsPer10Km: netClawbackPer10Km,
      projectedGapAtFinishSeconds: projectedGapAtFinish,
      projectedCatchKm: projectedCatchKm,
      meetsMountainFootRule: false,
      tacticalSummary:
          'Etap pagórkowaty (Breakaway-Friendly) — równowaga ucieczki '
          'wynosi ${(probability * 100).toStringAsFixed(1)}%.',
    );
  }

  static BreakawayEquilibriumResult _solveCobbleClassicStage({
    required BreakawayEquilibriumInput input,
    required EquilibriumTerrainProfile profile,
    required double remainingKm,
    required double breakawaySpeed,
    required double chaseSpeed,
    required double netClawbackPer10Km,
    required double projectedGapAtFinish,
    required double projectedCatchKm,
  }) {
    final double coop = input.breakawayCooperationScore.clamp(0.0, 1.0);
    double prob = 0.32 + (coop - 0.80) * 0.18;

    if (input.windSpeedKmh > 25.0) {
      prob += 0.06;
    }
    if (projectedGapAtFinish > 30.0) {
      prob += 0.08;
    } else if (projectedGapAtFinish < -180.0 && remainingKm < 40.0) {
      prob -= 0.12;
    }
    if (input.isBreakawayDangerousInGc) {
      prob -= 0.10;
    }

    final double probability = prob.clamp(0.08, 0.72);

    return BreakawayEquilibriumResult(
      terrainProfile: profile,
      survivalProbability: probability,
      baselineProbability: 0.32,
      equilibriumChaseSpeedKmh: chaseSpeed,
      equilibriumBreakawaySpeedKmh: breakawaySpeed,
      netClawbackSecondsPer10Km: netClawbackPer10Km,
      projectedGapAtFinishSeconds: projectedGapAtFinish,
      projectedCatchKm: projectedCatchKm,
      meetsMountainFootRule: false,
      tacticalSummary:
          'Klasyk brukowany — szansa przetrwania odjazdu wynosi '
          '${(probability * 100).toStringAsFixed(1)}%.',
    );
  }

  static BreakawayEquilibriumResult _solveHighMountainStage({
    required BreakawayEquilibriumInput input,
    required EquilibriumTerrainProfile profile,
    required double stageLength,
    required double clampedKm,
    required double breakawaySpeed,
    required double chaseSpeed,
    required double netClawbackPer10Km,
    required double projectedGapAtFinish,
    required double projectedCatchKm,
  }) {
    final FinalClimbProfile climb = input.finalClimb ??
        FinalClimbProfile(
          lengthKm: defaultHighMountainClimbLengthKm,
          averageGradientPercent: 7.5,
          elevationGainM: defaultHighMountainClimbLengthKm * 75.0,
          footKm: math.max(0.0, stageLength - defaultHighMountainClimbLengthKm),
          summitKm: stageLength,
        );

    final double requiredFootGap = climb.requiredFootGapSeconds;

    // Jeśli kolarze są jeszcze przed podnóżem, prognozujemy zapas u podnóża.
    // Jeśli podano bezpośredni zapas u podnóża (gapAtClimbFootSeconds), używamy go wprost.
    final double estimatedFootGap;
    if (input.gapAtClimbFootSeconds != null) {
      estimatedFootGap = math.max(0.0, input.gapAtClimbFootSeconds!);
    } else if (clampedKm < climb.footKm) {
      final double kmToFoot = climb.footKm - clampedKm;
      final double changeToFoot = (kmToFoot / 10.0) * netClawbackPer10Km;
      estimatedFootGap = math.max(0.0, input.currentGapSeconds - changeToFoot);
    } else {
      // Kolarze już są na finałowym podjeździe — skalujemy obecny zapas proporcjonalnie do pozostałego dystansu wspinaczki
      final double climbRemainingKm = math.max(0.5, climb.summitKm - clampedKm);
      final double fractionRemaining =
          (climbRemainingKm / math.max(1.0, climb.lengthKm)).clamp(0.1, 1.0);
      estimatedFootGap = input.currentGapSeconds / fractionRemaining;
    }

    final double marginSeconds = estimatedFootGap - requiredFootGap;
    final bool meetsRule = estimatedFootGap >= requiredFootGap;

    double probability = evaluateMountainFootSurvival(
      gapAtFootSeconds: estimatedFootGap,
      climbLengthKm: climb.lengthKm,
      gcBattleIntensity: input.gcBattleIntensity,
      isBreakawayDangerousInGc: input.isBreakawayDangerousInGc,
    );

    // Drobna korekta za jakość współpracy i siłę górali w ucieczce
    final double engineMod =
        ((input.breakawayAverageEngineRating - 75.0) / 25.0) * 0.04;
    final double coopMod =
        (input.breakawayCooperationScore.clamp(0.0, 1.0) - 0.80) * 0.06;
    probability = (probability + engineMod + coopMod).clamp(0.03, 0.96);

    final double reqMin = requiredFootGap / 60.0;
    final double actMin = estimatedFootGap / 60.0;
    final String summary = meetsRule
        ? 'Wysokie góry (podjazd ${climb.lengthKm.toStringAsFixed(1)} km): '
            'zapas u podnóża ${actMin.toStringAsFixed(1)} min spełnia próg '
            '${reqMin.toStringAsFixed(1)} min (>= 1 min / 3 km) — szansa '
            '${(probability * 100).toStringAsFixed(1)}%.'
        : 'Wysokie góry (podjazd ${climb.lengthKm.toStringAsFixed(1)} km): '
            'zapas u podnóża ${actMin.toStringAsFixed(1)} min jest poniżej '
            'progu ${reqMin.toStringAsFixed(1)} min (1 min / 3 km) — faworyci GC '
            'skasują ucieczkę (${(probability * 100).toStringAsFixed(1)}%).';

    return BreakawayEquilibriumResult(
      terrainProfile: profile,
      survivalProbability: probability,
      baselineProbability: 0.50,
      equilibriumChaseSpeedKmh: chaseSpeed,
      equilibriumBreakawaySpeedKmh: breakawaySpeed,
      netClawbackSecondsPer10Km: netClawbackPer10Km,
      projectedGapAtFinishSeconds: projectedGapAtFinish,
      projectedCatchKm: projectedCatchKm,
      requiredClimbFootGapSeconds: requiredFootGap,
      actualOrEstimatedClimbFootGapSeconds: estimatedFootGap,
      climbFootGapMarginSeconds: marginSeconds,
      meetsMountainFootRule: meetsRule,
      tacticalSummary: summary,
    );
  }

  static double _baselineForProfile(EquilibriumTerrainProfile profile) {
    switch (profile) {
      case EquilibriumTerrainProfile.flatSprinterControlled:
        return flatSprinterBaselineProbability;
      case EquilibriumTerrainProfile.hillyBreakawayFriendly:
        return hillyBreakawayFriendlyBaselineProbability;
      case EquilibriumTerrainProfile.cobbleClassic:
        return 0.32;
      case EquilibriumTerrainProfile.highMountain:
        return 0.50;
      case EquilibriumTerrainProfile.timeTrial:
        return 0.0;
    }
  }

  static double _basePelotonSpeedKmh(EquilibriumTerrainProfile profile) {
    switch (profile) {
      case EquilibriumTerrainProfile.flatSprinterControlled:
        return 45.5;
      case EquilibriumTerrainProfile.hillyBreakawayFriendly:
        return 41.0;
      case EquilibriumTerrainProfile.cobbleClassic:
        return 42.5;
      case EquilibriumTerrainProfile.highMountain:
        return 35.5;
      case EquilibriumTerrainProfile.timeTrial:
        return 50.0;
    }
  }

  static double _computeBreakawaySpeedKmh(
    BreakawayEquilibriumInput input,
    EquilibriumTerrainProfile profile,
  ) {
    final double base = _basePelotonSpeedKmh(profile);
    final double coop = input.breakawayCooperationScore.clamp(0.0, 1.0);
    final double coopBonus = coop >= 0.70
        ? (coop - 0.70) * 5.0
        : -(0.70 - coop) * 8.0;
    final double sizeBonus = input.breakawayRiderCount >= 4 &&
            input.breakawayRiderCount <= 8
        ? 0.9
        : (input.breakawayRiderCount <= 2 ? -1.1 : 0.3);
    final double engineBonus =
        ((input.breakawayAverageEngineRating - 75.0) / 25.0) * 1.2;

    return math.max(20.0, base + coopBonus + sizeBonus + engineBonus);
  }

  static double _computePelotonChaseSpeedKmh(
    BreakawayEquilibriumInput input,
    EquilibriumTerrainProfile profile,
  ) {
    final double base = _basePelotonSpeedKmh(profile);
    final int domestiques = math.max(0, input.committedChaseDomestiques);

    double chaseBonus;
    switch (profile) {
      case EquilibriumTerrainProfile.flatSprinterControlled:
        // Peleton korzysta z dużego draftu i pociągów sprinterskich
        chaseBonus = 1.1 + math.min(8, domestiques) * 0.45;
        if (input.sprintTeamsInterestedCount >= 3 &&
            !input.isBreakawayDangerousInGc) {
          chaseBonus -= 0.45; // Poker taktyczny między drużynami sprinterskimi
        }
        break;
      case EquilibriumTerrainProfile.hillyBreakawayFriendly:
        chaseBonus = 0.2 + math.min(6, domestiques) * 0.28;
        break;
      case EquilibriumTerrainProfile.cobbleClassic:
        chaseBonus = 0.5 + math.min(6, domestiques) * 0.32;
        break;
      case EquilibriumTerrainProfile.highMountain:
        chaseBonus = 0.4 +
            math.min(6, domestiques) * 0.35 +
            input.gcBattleIntensity.clamp(0.0, 1.0) * 0.8;
        break;
      case EquilibriumTerrainProfile.timeTrial:
        chaseBonus = 0.0;
        break;
    }

    if (input.isBreakawayDangerousInGc) {
      chaseBonus += 1.2;
    }

    return math.max(20.0, base + chaseBonus);
  }
}
