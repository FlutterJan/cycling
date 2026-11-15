import 'dart:math' as math;
import '../../models/rider/rider.dart';
import '../../models/rider/rider_health.dart';
import '../../models/team/cycling_team.dart';
import '../events/race_incident_engine.dart';
import '../peloton/rider_race_state.dart';
import 'stage_results_calculator.dart';
import 'stage_simulation_loop.dart';

/// Protokoły żywieniowe regeneracji potreningowej stosowane w zespole kolarskim.
enum RecoveryNutritionProtocol {
  /// Podstawowy: standardowy bufet hotelowy, ogólne uzupełnienie węglowodanów
  basic,

  /// Zaawansowany: wyliczone proporcje 1.2g/kg węglowodanów w oknie 30 min, odżywki białkowe, elektrolity
  advanced,

  /// WorldTour Elite: spersonalizowana gramatura makroskładników, sok z cierpkiej wiśni (redukcja zapaleń),
  /// estry ketonowe, kwasy Omega-3 oraz monitoring nawodnienia i glikemii
  worldTourElite;

  String toJson() => name;

  static RecoveryNutritionProtocol fromJson(String value) {
    return RecoveryNutritionProtocol.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RecoveryNutritionProtocol.basic,
    );
  }

  /// Procentowy bonus regeneracji nocnej zapewniany przez protokół żywieniowy
  double get recoveryBonusRatio {
    switch (this) {
      case RecoveryNutritionProtocol.basic:
        return 0.0;
      case RecoveryNutritionProtocol.advanced:
        return 0.05;
      case RecoveryNutritionProtocol.worldTourElite:
        return 0.10;
    }
  }

  String get label {
    switch (this) {
      case RecoveryNutritionProtocol.basic:
        return 'Standardowy bufet hotelowy';
      case RecoveryNutritionProtocol.advanced:
        return 'Zaawansowany protokół białkowo-węglowodanowy';
      case RecoveryNutritionProtocol.worldTourElite:
        return 'WorldTour Elite (spersonalizowane makro, wiśnia, ketony)';
    }
  }
}

/// Zaplecze i sprzęt regeneracyjny drużyny w trakcie wieloetapowego wyścigu.
class TeamRecoveryFacilities {
  /// Pneumatyczne nogawki kompresyjne (NormaTec / Compex) przyspieszające drenaż limfatyczny nóg
  final bool hasCompressionBoots;

  /// Krioterapia / mobilne wanny z lodem redukujące mikrourazy mięśniowe i obrzęki
  final bool hasCryoCabin;

  /// Poziom wdrożonego protokołu żywieniowego
  final RecoveryNutritionProtocol nutritionProtocol;

  /// Mobilny zestaw optymalizacji snu (własne materace ortopedyczne i klimatyzatory hotelowe)
  final bool hasSleepOptimizationKit;

  /// Dedykowana jakość masażu fizjoterapeutycznego (1-100)
  final int massageQualityLevel;

  const TeamRecoveryFacilities({
    required this.hasCompressionBoots,
    required this.hasCryoCabin,
    required this.nutritionProtocol,
    required this.hasSleepOptimizationKit,
    required this.massageQualityLevel,
  });

  /// Domyślne zaplecze generowane automatycznie z dywizji i personelu zespołu
  factory TeamRecoveryFacilities.fromTeam(CyclingTeam team) {
    final int docLvl = team.staff.doctorsLevel;
    final int trainLvl = team.staff.trainersLevel;
    final int massageQuality = ((docLvl * 0.6) + (trainLvl * 0.4)).round().clamp(1, 100);

    switch (team.division) {
      case TeamDivision.worldTour:
        return TeamRecoveryFacilities(
          hasCompressionBoots: true,
          hasCryoCabin: true,
          nutritionProtocol: RecoveryNutritionProtocol.worldTourElite,
          hasSleepOptimizationKit: true,
          massageQualityLevel: massageQuality,
        );
      case TeamDivision.proTeam:
        return TeamRecoveryFacilities(
          hasCompressionBoots: true,
          hasCryoCabin: docLvl >= 75,
          nutritionProtocol: docLvl >= 70
              ? RecoveryNutritionProtocol.advanced
              : RecoveryNutritionProtocol.basic,
          hasSleepOptimizationKit: false,
          massageQualityLevel: (massageQuality * 0.88).round().clamp(1, 100),
        );
      case TeamDivision.continental:
        return TeamRecoveryFacilities(
          hasCompressionBoots: false,
          hasCryoCabin: false,
          nutritionProtocol: RecoveryNutritionProtocol.basic,
          hasSleepOptimizationKit: false,
          massageQualityLevel: (massageQuality * 0.72).round().clamp(1, 100),
        );
    }
  }

  /// Łączny bonus sprzętowo-protokołowy do nocnej regeneracji (0.05 do 0.28)
  double get totalFacilitiesRecoveryBonus {
    double bonus = 0.0;
    if (hasCompressionBoots) bonus += 0.06;
    if (hasCryoCabin) bonus += 0.05;
    bonus += nutritionProtocol.recoveryBonusRatio;
    if (hasSleepOptimizationKit) bonus += 0.05;
    bonus += (massageQualityLevel / 100.0) * 0.08;
    return bonus;
  }

  TeamRecoveryFacilities copyWith({
    bool? hasCompressionBoots,
    bool? hasCryoCabin,
    RecoveryNutritionProtocol? nutritionProtocol,
    bool? hasSleepOptimizationKit,
    int? massageQualityLevel,
  }) {
    return TeamRecoveryFacilities(
      hasCompressionBoots: hasCompressionBoots ?? this.hasCompressionBoots,
      hasCryoCabin: hasCryoCabin ?? this.hasCryoCabin,
      nutritionProtocol: nutritionProtocol ?? this.nutritionProtocol,
      hasSleepOptimizationKit: hasSleepOptimizationKit ?? this.hasSleepOptimizationKit,
      massageQualityLevel: massageQualityLevel ?? this.massageQualityLevel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasCompressionBoots': hasCompressionBoots,
      'hasCryoCabin': hasCryoCabin,
      'nutritionProtocol': nutritionProtocol.toJson(),
      'hasSleepOptimizationKit': hasSleepOptimizationKit,
      'massageQualityLevel': massageQualityLevel,
    };
  }

  factory TeamRecoveryFacilities.fromJson(Map<String, dynamic> json) {
    return TeamRecoveryFacilities(
      hasCompressionBoots: json['hasCompressionBoots'] as bool? ?? false,
      hasCryoCabin: json['hasCryoCabin'] as bool? ?? false,
      nutritionProtocol: RecoveryNutritionProtocol.fromJson(
        json['nutritionProtocol'] as String? ?? 'basic',
      ),
      hasSleepOptimizationKit: json['hasSleepOptimizationKit'] as bool? ?? false,
      massageQualityLevel: (json['massageQualityLevel'] as num?)?.toInt() ?? 50,
    );
  }
}

/// Obciążenie fizyczne kolarza zarejestrowane podczas ukończonego etapu.
class RiderStageWorkload {
  final String riderId;
  final String riderName;
  final double ridingTimeSeconds;
  final double averageWatts;
  final double normalizedPowerWatts;
  final int ftpWatts;
  final double totalWorkKj;
  final double intensityFactor;

  /// Wynikowy wskaźnik stresu treningowego (Training Stress Score)
  final double tss;

  /// Liczba zaliczonych "odcięć beztlenowych" (wyzerowanie W' do zera)
  final int anaerobicExhaustionCount;

  /// Czy kolarz zaliczył hipoglikemię ("odcięcie prądu" / bonking)
  final bool isBonked;

  /// Czy kolarz uczestniczył w kraksie podczas tego etapu
  final bool hadCrash;

  /// Odniesiona kontuzja w wyniku kraksy (jeśli dotyczy)
  final Injury? crashInjury;

  /// Oficjalna lokata na mecie etapu
  final int finishRank;

  /// Czy kolarz wycofał się z wyścigu (Did Not Finish)
  final bool isDnf;

  /// Czy kolarz przekroczył limit czasu (Out of Time Limit / Hors Délais)
  final bool isTimeCutOtl;

  /// Zadanie taktyczne pełnione na etapie
  final TacticalOrder? tacticalOrder;

  const RiderStageWorkload({
    required this.riderId,
    required this.riderName,
    required this.ridingTimeSeconds,
    required this.averageWatts,
    required this.normalizedPowerWatts,
    required this.ftpWatts,
    required this.totalWorkKj,
    required this.intensityFactor,
    required this.tss,
    required this.anaerobicExhaustionCount,
    required this.isBonked,
    required this.hadCrash,
    this.crashInjury,
    required this.finishRank,
    required this.isDnf,
    required this.isTimeCutOtl,
    this.tacticalOrder,
  });

  /// Wyciąga dane obciążenia kolarza bezpośrednio z obiektów symulacji etapu
  factory RiderStageWorkload.fromSimulation({
    required Rider rider,
    required OfficialRiderStageResult officialResult,
    StageSimulationState? simulationState,
  }) {
    final double ridingTime = officialResult.rawFinishTimeSeconds > 0.0
        ? officialResult.rawFinishTimeSeconds
        : 14400.0; // Domyślnie 4 godziny jeśli brak danych

    final int ftp = rider.physiology.ftpWatts > 0 ? rider.physiology.ftpWatts : 380;

    double avgPower = 0.0;
    int exhaustions = 0;
    bool bonked = false;
    TacticalOrder? activeOrder;

    if (simulationState != null) {
      final raceState = simulationState.riderStates[rider.id];
      if (raceState != null) {
        avgPower = raceState.currentWatts.toDouble();
        activeOrder = raceState.activeTacticalOrder;
      }
      final wState = simulationState.wPrimeStates[rider.id];
      if (wState != null) {
        exhaustions = wState.exhaustionCount;
      }
      final nutState = simulationState.nutritionStates[rider.id];
      if (nutState != null) {
        bonked = nutState.isBonked;
      }
    }

    // Jeśli brak chwilowej mocy w stanie, oszacuj moc na podstawie dystansu i profilu
    if (avgPower <= 50.0) {
      final double weightKg = rider.physiology.weightKg > 0 ? rider.physiology.weightKg : 70.0;
      // Szacunek typowej mocy peletonu zawodowego: 3.2 - 3.8 W/kg dla kolarzy w peletonie
      avgPower = (weightKg * 3.4).clamp(180.0, 360.0);
      if (officialResult.rank <= 10) {
        avgPower += 35.0; // Kolarze z czuba generują większą moc na finiszach
      }
    }

    // Normalised Power (NP) uwzględnia zmienność wysiłku (Variability Index ~ 1.08 - 1.14)
    final double variabilityIndex = exhaustions > 0 ? 1.13 : 1.08;
    final double normPower = avgPower * variabilityIndex;
    final double ifFactor = normPower / ftp;

    // Standardowy wzór Coggana na TSS: (t * NP * IF) / (FTP * 3600) * 100
    double rawTss = ((ridingTime * normPower * ifFactor) / (ftp * 3600.0)) * 100.0;

    // Dodatkowy stres fizjologiczny za bonking i odcięcia beztlenowe
    if (bonked) rawTss *= 1.25;
    if (exhaustions > 0) rawTss += (exhaustions * 8.0);

    final double totalKj = (avgPower * ridingTime) / 1000.0;

    // Sprawdzenie historii incydentów
    bool crashed = false;
    Injury? sustainedInjury;
    if (simulationState != null) {
      for (final inc in simulationState.incidentHistory) {
        for (final victim in inc.primaryVictims) {
          if (victim.riderId == rider.id) {
            crashed = true;
            sustainedInjury = victim.injury;
            break;
          }
        }
      }
    }

    return RiderStageWorkload(
      riderId: rider.id,
      riderName: rider.fullName,
      ridingTimeSeconds: ridingTime,
      averageWatts: avgPower,
      normalizedPowerWatts: normPower,
      ftpWatts: ftp,
      totalWorkKj: totalKj,
      intensityFactor: ifFactor,
      tss: rawTss.clamp(20.0, 480.0),
      anaerobicExhaustionCount: exhaustions,
      isBonked: bonked,
      hadCrash: crashed,
      crashInjury: sustainedInjury,
      finishRank: officialResult.rank,
      isDnf: officialResult.isDnf,
      isTimeCutOtl: officialResult.isEliminatedOtl,
      tacticalOrder: activeOrder,
    );
  }

  RiderStageWorkload copyWith({
    String? riderId,
    String? riderName,
    double? ridingTimeSeconds,
    double? averageWatts,
    double? normalizedPowerWatts,
    int? ftpWatts,
    double? totalWorkKj,
    double? intensityFactor,
    double? tss,
    int? anaerobicExhaustionCount,
    bool? isBonked,
    bool? hadCrash,
    Injury? crashInjury,
    int? finishRank,
    bool? isDnf,
    bool? isTimeCutOtl,
    TacticalOrder? tacticalOrder,
  }) {
    return RiderStageWorkload(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      ridingTimeSeconds: ridingTimeSeconds ?? this.ridingTimeSeconds,
      averageWatts: averageWatts ?? this.averageWatts,
      normalizedPowerWatts: normalizedPowerWatts ?? this.normalizedPowerWatts,
      ftpWatts: ftpWatts ?? this.ftpWatts,
      totalWorkKj: totalWorkKj ?? this.totalWorkKj,
      intensityFactor: intensityFactor ?? this.intensityFactor,
      tss: tss ?? this.tss,
      anaerobicExhaustionCount: anaerobicExhaustionCount ?? this.anaerobicExhaustionCount,
      isBonked: isBonked ?? this.isBonked,
      hadCrash: hadCrash ?? this.hadCrash,
      crashInjury: crashInjury ?? this.crashInjury,
      finishRank: finishRank ?? this.finishRank,
      isDnf: isDnf ?? this.isDnf,
      isTimeCutOtl: isTimeCutOtl ?? this.isTimeCutOtl,
      tacticalOrder: tacticalOrder ?? this.tacticalOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'ridingTimeSeconds': ridingTimeSeconds,
      'averageWatts': averageWatts,
      'normalizedPowerWatts': normalizedPowerWatts,
      'ftpWatts': ftpWatts,
      'totalWorkKj': totalWorkKj,
      'intensityFactor': intensityFactor,
      'tss': tss,
      'anaerobicExhaustionCount': anaerobicExhaustionCount,
      'isBonked': isBonked,
      'hadCrash': hadCrash,
      'crashInjury': crashInjury?.toJson(),
      'finishRank': finishRank,
      'isDnf': isDnf,
      'isTimeCutOtl': isTimeCutOtl,
      'tacticalOrder': tacticalOrder?.toJson(),
    };
  }

  factory RiderStageWorkload.fromJson(Map<String, dynamic> json) {
    return RiderStageWorkload(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      ridingTimeSeconds: (json['ridingTimeSeconds'] as num).toDouble(),
      averageWatts: (json['averageWatts'] as num).toDouble(),
      normalizedPowerWatts: (json['normalizedPowerWatts'] as num).toDouble(),
      ftpWatts: (json['ftpWatts'] as num).toInt(),
      totalWorkKj: (json['totalWorkKj'] as num).toDouble(),
      intensityFactor: (json['intensityFactor'] as num).toDouble(),
      tss: (json['tss'] as num).toDouble(),
      anaerobicExhaustionCount: (json['anaerobicExhaustionCount'] as num).toInt(),
      isBonked: json['isBonked'] as bool,
      hadCrash: json['hadCrash'] as bool,
      crashInjury: json['crashInjury'] != null
          ? Injury.fromJson(json['crashInjury'] as Map<String, dynamic>)
          : null,
      finishRank: (json['finishRank'] as num).toInt(),
      isDnf: json['isDnf'] as bool,
      isTimeCutOtl: json['isTimeCutOtl'] as bool,
      tacticalOrder: json['tacticalOrder'] != null
          ? TacticalOrder.fromJson(json['tacticalOrder'] as String)
          : null,
    );
  }
}

/// Szczegółowy raport potreningowy i bilans regeneracji nocnej dla pojedynczego kolarza.
class RiderOvernightRecoveryReport {
  final String riderId;
  final String riderName;

  /// Stres treningowy etapu (TSS)
  final double stageTss;

  /// Stan zmęczenia ATL przed etapem
  final double previousAtl;

  /// Zmęczenie ATL bezpośrednio po etapie (brutto przed snem)
  final double grossAtl;

  /// Zmęczenie ATL o poranku po nocy i regeneracji (netto)
  final double netAtl;

  /// Baza sprawności CTL przed etapem
  final double previousCtl;

  /// Baza sprawności CTL po etapie
  final double newCtl;

  /// Wskaźnik świeżości i dyspozycji startowej na kolejny poranek (TSB = CTL - net ATL)
  final double newTsb;

  /// Indeks regeneracji nocnej (0.0 do 1.0, np. 0.88 = 88% regeneracji)
  final double overnightRecoveryScore;

  /// Wkład wskaźnika fizjologii kolarza (recoveryRate i VO2max)
  final double recoveryRateFactor;

  /// Wkład opieki lekarsko-fizjoterapeutycznej
  final double staffDoctorBonus;

  /// Wkład sprzętu i protokołów (nogawki kompresyjne, krio, dieta, materace)
  final double facilitiesBonus;

  /// Kara regeneracyjna za otarcia asfaltowe (Road Rash)
  final double roadRashPenalty;

  /// Kara regeneracyjna za hipoglikemię (Bonk)
  final double bonkPenalty;

  /// Morale kolarza przed etapem (0 - 100)
  final double previousMorale;

  /// Morale kolarza po etapie (0 - 100)
  final double newMorale;

  /// Zmiana morale (+/-)
  final double moraleDelta;

  /// Efektywna moc progowa FTP na kolejny etap z uwzględnieniem szlifów i zmęczenia [W]
  final int effectiveFtpNextStage;

  /// Aktualna kontuzja (jeśli występuje)
  final Injury? activeInjury;

  /// Liczba dni do całkowitego wyleczenia urazu
  final int injuryDaysRemaining;

  /// Podsumowanie słowne stanu zawodnika dla dyrektora sportowego
  final String statusDescription;

  const RiderOvernightRecoveryReport({
    required this.riderId,
    required this.riderName,
    required this.stageTss,
    required this.previousAtl,
    required this.grossAtl,
    required this.netAtl,
    required this.previousCtl,
    required this.newCtl,
    required this.newTsb,
    required this.overnightRecoveryScore,
    required this.recoveryRateFactor,
    required this.staffDoctorBonus,
    required this.facilitiesBonus,
    required this.roadRashPenalty,
    required this.bonkPenalty,
    required this.previousMorale,
    required this.newMorale,
    required this.moraleDelta,
    required this.effectiveFtpNextStage,
    this.activeInjury,
    required this.injuryDaysRemaining,
    required this.statusDescription,
  });

  RiderOvernightRecoveryReport copyWith({
    String? riderId,
    String? riderName,
    double? stageTss,
    double? previousAtl,
    double? grossAtl,
    double? netAtl,
    double? previousCtl,
    double? newCtl,
    double? newTsb,
    double? overnightRecoveryScore,
    double? recoveryRateFactor,
    double? staffDoctorBonus,
    double? facilitiesBonus,
    double? roadRashPenalty,
    double? bonkPenalty,
    double? previousMorale,
    double? newMorale,
    double? moraleDelta,
    int? effectiveFtpNextStage,
    Injury? activeInjury,
    int? injuryDaysRemaining,
    String? statusDescription,
  }) {
    return RiderOvernightRecoveryReport(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      stageTss: stageTss ?? this.stageTss,
      previousAtl: previousAtl ?? this.previousAtl,
      grossAtl: grossAtl ?? this.grossAtl,
      netAtl: netAtl ?? this.netAtl,
      previousCtl: previousCtl ?? this.previousCtl,
      newCtl: newCtl ?? this.newCtl,
      newTsb: newTsb ?? this.newTsb,
      overnightRecoveryScore: overnightRecoveryScore ?? this.overnightRecoveryScore,
      recoveryRateFactor: recoveryRateFactor ?? this.recoveryRateFactor,
      staffDoctorBonus: staffDoctorBonus ?? this.staffDoctorBonus,
      facilitiesBonus: facilitiesBonus ?? this.facilitiesBonus,
      roadRashPenalty: roadRashPenalty ?? this.roadRashPenalty,
      bonkPenalty: bonkPenalty ?? this.bonkPenalty,
      previousMorale: previousMorale ?? this.previousMorale,
      newMorale: newMorale ?? this.newMorale,
      moraleDelta: moraleDelta ?? this.moraleDelta,
      effectiveFtpNextStage: effectiveFtpNextStage ?? this.effectiveFtpNextStage,
      activeInjury: activeInjury ?? this.activeInjury,
      injuryDaysRemaining: injuryDaysRemaining ?? this.injuryDaysRemaining,
      statusDescription: statusDescription ?? this.statusDescription,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'stageTss': stageTss,
      'previousAtl': previousAtl,
      'grossAtl': grossAtl,
      'netAtl': netAtl,
      'previousCtl': previousCtl,
      'newCtl': newCtl,
      'newTsb': newTsb,
      'overnightRecoveryScore': overnightRecoveryScore,
      'recoveryRateFactor': recoveryRateFactor,
      'staffDoctorBonus': staffDoctorBonus,
      'facilitiesBonus': facilitiesBonus,
      'roadRashPenalty': roadRashPenalty,
      'bonkPenalty': bonkPenalty,
      'previousMorale': previousMorale,
      'newMorale': newMorale,
      'moraleDelta': moraleDelta,
      'effectiveFtpNextStage': effectiveFtpNextStage,
      'activeInjury': activeInjury?.toJson(),
      'injuryDaysRemaining': injuryDaysRemaining,
      'statusDescription': statusDescription,
    };
  }

  factory RiderOvernightRecoveryReport.fromJson(Map<String, dynamic> json) {
    return RiderOvernightRecoveryReport(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      stageTss: (json['stageTss'] as num).toDouble(),
      previousAtl: (json['previousAtl'] as num).toDouble(),
      grossAtl: (json['grossAtl'] as num).toDouble(),
      netAtl: (json['netAtl'] as num).toDouble(),
      previousCtl: (json['previousCtl'] as num).toDouble(),
      newCtl: (json['newCtl'] as num).toDouble(),
      newTsb: (json['newTsb'] as num).toDouble(),
      overnightRecoveryScore: (json['overnightRecoveryScore'] as num).toDouble(),
      recoveryRateFactor: (json['recoveryRateFactor'] as num).toDouble(),
      staffDoctorBonus: (json['staffDoctorBonus'] as num).toDouble(),
      facilitiesBonus: (json['facilitiesBonus'] as num).toDouble(),
      roadRashPenalty: (json['roadRashPenalty'] as num).toDouble(),
      bonkPenalty: (json['bonkPenalty'] as num).toDouble(),
      previousMorale: (json['previousMorale'] as num).toDouble(),
      newMorale: (json['newMorale'] as num).toDouble(),
      moraleDelta: (json['moraleDelta'] as num).toDouble(),
      effectiveFtpNextStage: (json['effectiveFtpNextStage'] as num).toInt(),
      activeInjury: json['activeInjury'] != null
          ? Injury.fromJson(json['activeInjury'] as Map<String, dynamic>)
          : null,
      injuryDaysRemaining: (json['injuryDaysRemaining'] as num).toInt(),
      statusDescription: json['statusDescription'] as String,
    );
  }

  @override
  String toString() {
    return '$riderName: TSS ${stageTss.toStringAsFixed(0)}, Net ATL ${netAtl.toStringAsFixed(1)}, '
        'TSB ${newTsb.toStringAsFixed(1)}, Morale: ${newMorale.toStringAsFixed(1)} '
        '(${moraleDelta >= 0 ? '+' : ''}${moraleDelta.toStringAsFixed(1)}), '
        'FTP: ${effectiveFtpNextStage}W';
  }
}

/// Zbiorczy raport po etapie dla całej drużyny kolarskiej.
class TeamPostStageReport {
  final String teamId;
  final String teamName;
  final int stageNumber;
  final double averageTeamMorale;
  final double averageMoraleDelta;
  final double averageTeamTsb;
  final String? stageWinnerRiderName;
  final List<String> stagePodiumRiderNames;
  final List<String> crashedRiderNames;
  final List<String> dnfRiderNames;
  final List<RiderOvernightRecoveryReport> riderReports;
  final List<String> teamHighlights;

  const TeamPostStageReport({
    required this.teamId,
    required this.teamName,
    required this.stageNumber,
    required this.averageTeamMorale,
    required this.averageMoraleDelta,
    required this.averageTeamTsb,
    this.stageWinnerRiderName,
    required this.stagePodiumRiderNames,
    required this.crashedRiderNames,
    required this.dnfRiderNames,
    required this.riderReports,
    required this.teamHighlights,
  });

  TeamPostStageReport copyWith({
    String? teamId,
    String? teamName,
    int? stageNumber,
    double? averageTeamMorale,
    double? averageMoraleDelta,
    double? averageTeamTsb,
    String? stageWinnerRiderName,
    List<String>? stagePodiumRiderNames,
    List<String>? crashedRiderNames,
    List<String>? dnfRiderNames,
    List<RiderOvernightRecoveryReport>? riderReports,
    List<String>? teamHighlights,
  }) {
    return TeamPostStageReport(
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      stageNumber: stageNumber ?? this.stageNumber,
      averageTeamMorale: averageTeamMorale ?? this.averageTeamMorale,
      averageMoraleDelta: averageMoraleDelta ?? this.averageMoraleDelta,
      averageTeamTsb: averageTeamTsb ?? this.averageTeamTsb,
      stageWinnerRiderName: stageWinnerRiderName ?? this.stageWinnerRiderName,
      stagePodiumRiderNames: stagePodiumRiderNames ?? this.stagePodiumRiderNames,
      crashedRiderNames: crashedRiderNames ?? this.crashedRiderNames,
      dnfRiderNames: dnfRiderNames ?? this.dnfRiderNames,
      riderReports: riderReports ?? this.riderReports,
      teamHighlights: teamHighlights ?? this.teamHighlights,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'stageNumber': stageNumber,
      'averageTeamMorale': averageTeamMorale,
      'averageMoraleDelta': averageMoraleDelta,
      'averageTeamTsb': averageTeamTsb,
      'stageWinnerRiderName': stageWinnerRiderName,
      'stagePodiumRiderNames': stagePodiumRiderNames,
      'crashedRiderNames': crashedRiderNames,
      'dnfRiderNames': dnfRiderNames,
      'riderReports': riderReports.map((r) => r.toJson()).toList(),
      'teamHighlights': teamHighlights,
    };
  }

  factory TeamPostStageReport.fromJson(Map<String, dynamic> json) {
    return TeamPostStageReport(
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      stageNumber: (json['stageNumber'] as num).toInt(),
      averageTeamMorale: (json['averageTeamMorale'] as num).toDouble(),
      averageMoraleDelta: (json['averageMoraleDelta'] as num).toDouble(),
      averageTeamTsb: (json['averageTeamTsb'] as num).toDouble(),
      stageWinnerRiderName: json['stageWinnerRiderName'] as String?,
      stagePodiumRiderNames: (json['stagePodiumRiderNames'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      crashedRiderNames: (json['crashedRiderNames'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      dnfRiderNames: (json['dnfRiderNames'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      riderReports: (json['riderReports'] as List<dynamic>)
          .map((e) => RiderOvernightRecoveryReport.fromJson(e as Map<String, dynamic>))
          .toList(),
      teamHighlights: (json['teamHighlights'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }
}

/// Rezultat wykonania procedury potreningowej i nocnej regeneracji.
class PostStageRecoveryResult {
  /// Lista kolarzy zespołu ze zaktualizowanym zdrowiem (ATL/CTL, Road Rash) i morale
  final List<Rider> updatedRiders;

  /// Zaktualizowany stan drużyny
  final CyclingTeam updatedTeam;

  /// Kompletny raport potreningowy dla sztabu i gracza
  final TeamPostStageReport report;

  /// Łączna wygrana kwota nagród finansowych wywalczonych przez drużynę na tym etapie [EUR]
  final int teamTotalPrizeMoneyEur;

  const PostStageRecoveryResult({
    required this.updatedRiders,
    required this.updatedTeam,
    required this.report,
    this.teamTotalPrizeMoneyEur = 0,
  });

  PostStageRecoveryResult copyWith({
    List<Rider>? updatedRiders,
    CyclingTeam? updatedTeam,
    TeamPostStageReport? report,
    int? teamTotalPrizeMoneyEur,
  }) {
    return PostStageRecoveryResult(
      updatedRiders: updatedRiders ?? this.updatedRiders,
      updatedTeam: updatedTeam ?? this.updatedTeam,
      report: report ?? this.report,
      teamTotalPrizeMoneyEur: teamTotalPrizeMoneyEur ?? this.teamTotalPrizeMoneyEur,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'updatedRiders': updatedRiders.map((r) => r.toJson()).toList(),
      'updatedTeam': updatedTeam.toJson(),
      'report': report.toJson(),
    };
  }

  factory PostStageRecoveryResult.fromJson(Map<String, dynamic> json) {
    return PostStageRecoveryResult(
      updatedRiders: (json['updatedRiders'] as List<dynamic>)
          .map((r) => Rider.fromJson(r as Map<String, dynamic>))
          .toList(),
      updatedTeam: CyclingTeam.fromJson(json['updatedTeam'] as Map<String, dynamic>),
      report: TeamPostStageReport.fromJson(json['report'] as Map<String, dynamic>),
    );
  }
}

/// Zaawansowany procesor regeneracji potreningowej i nocnej po etapie Touru.
///
/// Oblicza:
/// 1. Aktualizację zmęczenia krótkoterminowego (ATL - Acute Training Load) i bazy (CTL)
///    na podstawie wysiłku TSS (Training Stress Score).
/// 2. Nocną regenerację w hotelu opartą na genetyce kolarza (`recoveryRate`), poziomie lekarzy
///    i fizjoterapeutów (`doctorsLevel`) oraz wyposażeniu (nogawki kompresyjne, masaże, dieta, kriokomory).
/// 3. Obniżenie osiągów kolarzy jadących z otarciami po kraksach (Road Rash) oraz postęp gojenia ran.
/// 4. Zmianę morale kolarzy i całej drużyny w oparciu o sukcesy etapowe, straty czasowe, kontuzje i atmosferę.
class PostStageRecoveryProcessor {
  PostStageRecoveryProcessor._();

  /// Stała czasowa zmęczenia krótkoterminowego ATL: 7 dni
  static const double tauAtlDays = 7.0;

  /// Stała czasowa bazy treningowej CTL: 42 dni
  static const double tauCtlDays = 42.0;

  /// Główna metoda przetwarzająca regenerację nocną zespołu po zakończonym etapie.
  static PostStageRecoveryResult processStageRecovery({
    required List<Rider> teamRiders,
    required CyclingTeam team,
    required int stageNumber,
    required List<OfficialRiderStageResult> officialResults,
    StageSimulationState? simulationState,
    TeamRecoveryFacilities? customFacilities,
    TeamRecoveryFacilities? teamFacilities,
    List<dynamic>? incidents,
    bool teamHoldsLeaderJersey = false,
  }) {
    final facilities = teamFacilities ?? customFacilities ?? TeamRecoveryFacilities.fromTeam(team);

    // Krok 1: Identyfikacja sukcesów i incydentów zespołowych na tym etapie
    final resultsMap = <String, OfficialRiderStageResult>{};
    for (final res in officialResults) {
      resultsMap[res.riderId] = res;
    }

    String? stageWinnerName;
    final List<String> podiumNames = [];
    final List<String> crashedNames = [];
    final List<String> dnfNames = [];
    final List<String> highlights = [];

    bool teamWonStage = false;
    bool teamHadPodium = false;
    bool teamHadCrash = false;
    bool teamHadDnf = false;

    for (final rider in teamRiders) {
      final res = resultsMap[rider.id];
      if (res != null) {
        if (res.rank == 1 && !res.isDnf) {
          teamWonStage = true;
          stageWinnerName = rider.fullName;
          podiumNames.add(rider.fullName);
        } else if (res.rank <= 3 && !res.isDnf) {
          teamHadPodium = true;
          podiumNames.add(rider.fullName);
        }

        if (res.isDnf) {
          teamHadDnf = true;
          dnfNames.add(rider.fullName);
        }
      }

      // Sprawdź czy kolarz brał udział w kraksie
      if (simulationState != null) {
        for (final inc in simulationState.incidentHistory) {
          for (final victim in inc.primaryVictims) {
            if (victim.riderId == rider.id &&
                (victim.incidentType == IncidentType.soloCrash ||
                    victim.incidentType == IncidentType.pelotonPileup)) {
              teamHadCrash = true;
              if (!crashedNames.contains(rider.fullName)) {
                crashedNames.add(rider.fullName);
              }
            }
          }
        }
      }
    }

    if (teamWonStage) {
      highlights.add('🏆 Zwycięstwo etapowe dla $stageWinnerName! Euforia w autobusie drużyny.');
    } else if (teamHadPodium) {
      highlights.add('🥈 Podium na etapie! Znakomity występ umacnia wiarę zespołu w sukces.');
    }

    if (teamHoldsLeaderJersey) {
      highlights.add('🟡 Drużyna utrzymała koszulkę lidera wyścigu! Wysoka determinacja.');
    }

    if (teamHadCrash) {
      highlights.add('⚠️ Zawodnicy zespołu uczestniczyli w kraksie. Sztab medyczny pracuje nad szlifami.');
    }

    if (teamHadDnf) {
      highlights.add('❌ Bolesne wycofanie kolarza z wyścigu osłabia skład na kolejne etapy.');
    }

    // Krok 2: Przetwarzanie każdego kolarza z osobna
    final updatedRiders = <Rider>[];
    final reports = <RiderOvernightRecoveryReport>[];
    double totalTeamMorale = 0.0;
    double totalMoraleDelta = 0.0;
    double totalTeamTsb = 0.0;

    for (final rider in teamRiders) {
      final officialRes = resultsMap[rider.id] ??
          OfficialRiderStageResult(
            riderId: rider.id,
            riderName: rider.fullName,
            teamId: team.id,
            rank: 99,
            rawFinishTimeSeconds: 14400.0,
            officialFinishTimeSeconds: 14400.0,
            gapToWinnerSeconds: 600.0,
          );

      final workload = RiderStageWorkload.fromSimulation(
        rider: rider,
        officialResult: officialRes,
        simulationState: simulationState,
      );

      final report = _processSingleRiderRecovery(
        rider: rider,
        workload: workload,
        team: team,
        facilities: facilities,
        teamWonStage: teamWonStage,
        teamHadPodium: teamHadPodium,
        teamHadCrash: teamHadCrash,
        teamHadDnf: teamHadDnf,
        teamHoldsLeaderJersey: teamHoldsLeaderJersey,
      );

      reports.add(report);
      totalTeamMorale += report.newMorale;
      totalMoraleDelta += report.moraleDelta;
      totalTeamTsb += report.newTsb;

      // Zaktualizuj stan zdrowia i kontrakt kolarza
      final updatedHealth = rider.health.copyWith(
        acuteTrainingLoad: report.netAtl,
        chronicTrainingLoad: report.newCtl,
        currentInjury: report.activeInjury,
        clearInjury: report.activeInjury == null,
      );

      final updatedContract = rider.contract.copyWith(
        morale: report.newMorale,
      );

      updatedRiders.add(
        rider.copyWith(
          health: updatedHealth,
          contract: updatedContract,
        ),
      );
    }

    final double avgTeamMorale =
        updatedRiders.isNotEmpty ? totalTeamMorale / updatedRiders.length : 70.0;
    final double avgMoraleDelta =
        updatedRiders.isNotEmpty ? totalMoraleDelta / updatedRiders.length : 0.0;
    final double avgTeamTsb =
        updatedRiders.isNotEmpty ? totalTeamTsb / updatedRiders.length : 0.0;

    final teamReport = TeamPostStageReport(
      teamId: team.id,
      teamName: team.name,
      stageNumber: stageNumber,
      averageTeamMorale: avgTeamMorale,
      averageMoraleDelta: avgMoraleDelta,
      averageTeamTsb: avgTeamTsb,
      stageWinnerRiderName: stageWinnerName,
      stagePodiumRiderNames: podiumNames,
      crashedRiderNames: crashedNames,
      dnfRiderNames: dnfNames,
      riderReports: reports,
      teamHighlights: highlights,
    );

    int totalPrizeMoney = 0;
    for (final res in officialResults) {
      if (res.teamId == team.id) {
        totalPrizeMoney += res.prizeMoneyEur;
      }
    }

    return PostStageRecoveryResult(
      updatedRiders: List<Rider>.unmodifiable(updatedRiders),
      updatedTeam: team,
      report: teamReport,
      teamTotalPrizeMoneyEur: totalPrizeMoney,
    );
  }

  /// Wylicza wskaźnik stresu treningowego (TSS) na podstawie czasu i mocy.
  static double calculateStageTss({
    required double ridingTimeSeconds,
    required double normalizedPowerWatts,
    required int ftpWatts,
    int exhaustionCount = 0,
    bool isBonked = false,
  }) {
    if (ftpWatts <= 0 || ridingTimeSeconds <= 0.0) return 0.0;
    final double ifFactor = normalizedPowerWatts / ftpWatts;
    double rawTss = ((ridingTimeSeconds * normalizedPowerWatts * ifFactor) /
            (ftpWatts * 3600.0)) *
        100.0;

    if (isBonked) rawTss *= 1.25;
    if (exhaustionCount > 0) rawTss += (exhaustionCount * 8.0);
    return rawTss.clamp(10.0, 500.0);
  }

  /// Wylicza indeks regeneracji nocnej (0.0 do 1.0) dla zadanych parametrów.
  static double calculateOvernightRecoveryScore({
    required double recoveryRate,
    required double vo2Max,
    required int age,
    required int doctorsLevel,
    required int trainersLevel,
    required TeamRecoveryFacilities facilities,
    bool hasRoadRash = false,
    bool isBonked = false,
  }) {
    final double safeRecRate = math.max(0.60, recoveryRate);
    final double safeVo2 = math.max(50.0, vo2Max);
    final double agePenalty = math.max(0, age - 29) * 0.015;

    final double physBase =
        ((safeRecRate * 0.55) + ((safeVo2 / 72.0) * 0.35) - agePenalty).clamp(0.40, 1.15);

    final double docBonus = (doctorsLevel / 100.0) * 0.08;
    final double trainerBonus = (trainersLevel / 100.0) * 0.04;
    final double staffBonus = docBonus + trainerBonus;

    final double facBonus = facilities.totalFacilitiesRecoveryBonus;

    double roadRashPenalty = 0.0;
    if (hasRoadRash) {
      roadRashPenalty = 0.22;
      final double docMitigation = (doctorsLevel / 100.0) * 0.08;
      roadRashPenalty = math.max(0.08, roadRashPenalty - docMitigation);
    }

    final double bonkPenalty = isBonked ? 0.12 : 0.0;

    return (physBase + staffBonus + facBonus - roadRashPenalty - bonkPenalty).clamp(0.35, 0.98);
  }

  /// Oblicza efektywną moc progową FTP kolarza na kolejny etap.
  static int calculateEffectiveFtp({
    required int baseFtpWatts,
    required Injury? injury,
    required double tsb,
    int doctorsLevel = 50,
  }) {
    if (baseFtpWatts <= 0) return 0;
    double ftpPenaltyRatio = 0.0;

    if (injury != null && injury.type == InjuryType.roadRash) {
      switch (injury.daysRemaining) {
        case 3:
        case 4:
          ftpPenaltyRatio = 0.07;
          break;
        case 2:
          ftpPenaltyRatio = 0.05;
          break;
        case 1:
          ftpPenaltyRatio = 0.03;
          break;
        default:
          ftpPenaltyRatio = 0.02;
          break;
      }
      final double docPainRelief = (doctorsLevel / 100.0) * 0.025;
      ftpPenaltyRatio = math.max(0.015, ftpPenaltyRatio - docPainRelief);
    }

    if (tsb < -25.0) {
      final double deepFatiguePenalty = ((-25.0 - tsb) / 50.0) * 0.05;
      ftpPenaltyRatio += deepFatiguePenalty.clamp(0.0, 0.06);
    }

    return (baseFtpWatts * (1.0 - ftpPenaltyRatio)).round();
  }

  /// Przelicza regenerację nocną i wpływ szlifów asfaltowych na pojedynczego zawodnika.
  static RiderOvernightRecoveryReport _processSingleRiderRecovery({
    required Rider rider,
    required RiderStageWorkload workload,
    required CyclingTeam team,
    required TeamRecoveryFacilities facilities,
    required bool teamWonStage,
    required bool teamHadPodium,
    required bool teamHadCrash,
    required bool teamHadDnf,
    required bool teamHoldsLeaderJersey,
  }) {
    final double prevAtl = rider.health.acuteTrainingLoad;
    final double prevCtl = rider.health.chronicTrainingLoad;

    // 1. Aktualizacja zmęczenia fizycznego (Bannister Impulse Response Model)
    // Współczynniki wygasania z jedno-dniowym krokiem dyskretnym
    final double kAtl = 1.0 - math.exp(-1.0 / tauAtlDays);
    final double kCtl = 1.0 - math.exp(-1.0 / tauCtlDays);

    // Zmęczenie bezpośrednio po przekroczeniu linii mety (gross ATL)
    final double grossAtl = (prevAtl * (1.0 - kAtl)) + (workload.tss * kAtl);
    final double newCtl = (prevCtl * (1.0 - kCtl)) + (workload.tss * kCtl);

    // 2. Składniki regeneracji nocnej (Overnight Recovery Score)
    // (a) Fizjologia zawodnika: recoveryRate i VO2max
    final double safeRecRate = math.max(0.60, rider.physiology.recoveryRate);
    final double safeVo2 = math.max(50.0, rider.physiology.vo2Max);

    // Wpływ wieku: kolarze po 30. roku życia regenerują się wolniej
    final double agePenalty = math.max(0, rider.age - 29) * 0.015;
    final double physBase =
        ((safeRecRate * 0.55) + ((safeVo2 / 72.0) * 0.35) - agePenalty).clamp(0.40, 1.15);

    // (b) Jakość sztabu medycznego i fizjoterapeutów
    final double docBonus = (team.staff.doctorsLevel / 100.0) * 0.08;
    final double trainerBonus = (team.staff.trainersLevel / 100.0) * 0.04;
    final double staffBonus = docBonus + trainerBonus;

    // (c) Sprzęt regeneracyjny (nogawki kompresyjne, krio, dieta, materace)
    final double facBonus = facilities.totalFacilitiesRecoveryBonus;

    // (d) Kary za otarcia, kraksy i hipoglikemię
    double roadRashPenalty = 0.0;
    Injury? activeInjury = rider.health.currentInjury;

    // Jeśli kolarz uczestniczył w kraksie na tym etapie i nie miał urazu, doznał Road Rash
    if (workload.hadCrash) {
      if (workload.crashInjury != null) {
        activeInjury = workload.crashInjury;
      } else {
        activeInjury ??= const Injury(
          name: 'Otarcia asfaltowe (Road Rash)',
          type: InjuryType.roadRash,
          daysRemaining: 4,
          trainingAllowed: true,
        );
      }
    }

    if (activeInjury != null && activeInjury.type == InjuryType.roadRash) {
      // Szlify asfaltowe powodują ból nocny, stan zapalny i zaburzenia fazy snu głębokiego NREM
      roadRashPenalty = 0.22;
      // Doświadczony lekarz drużyny łagodzi ból specjalistycznymi opatrunkami hydrokoloidowymi
      final double docMitigation = (team.staff.doctorsLevel / 100.0) * 0.08;
      roadRashPenalty = math.max(0.08, roadRashPenalty - docMitigation);
    }

    double bonkPenalty = 0.0;
    if (workload.isBonked) {
      bonkPenalty = 0.12; // Skrajne wyczerpanie glikogenu spowalnia nocną syntezę białek
    }

    // Łączny wskaźnik regeneracji nocnej (0.35 do 0.98)
    final double overnightRecoveryScore =
        (physBase + staffBonus + facBonus - roadRashPenalty - bonkPenalty).clamp(0.35, 0.98);

    // 3. Wyliczenie porannego zmęczenia (net ATL)
    // Im wyższy overnightRecoveryScore, tym więcej świeżego stresu zostaje zmetabolizowane nocą
    final double atlSpike = math.max(0.0, grossAtl - prevAtl);
    final double clearedSpikeRatio = (overnightRecoveryScore - 0.35) / (0.98 - 0.35); // 0.0 do 1.0
    // Kolarz w idealnych warunkach neutralizuje nawet do 75% świeżego skoku zmęczenia
    final double netAtl = grossAtl - (atlSpike * clearedSpikeRatio * 0.72);
    final double newTsb = newCtl - netAtl;

    // 4. Postęp gojenia ran i kalkulacja osiągów kolarza z Road Rash
    int daysRemaining = 0;
    if (activeInjury != null) {
      daysRemaining = activeInjury.daysRemaining;
      // Nocny postęp leczenia
      daysRemaining--;
      // Wybitny sztab lekarski (poziom >= 85) przyspiesza regenerację tkanek
      if (team.staff.doctorsLevel >= 85 && daysRemaining > 1 && rider.physiology.recoveryRate > 1.05) {
        daysRemaining--;
      }

      if (daysRemaining <= 0) {
        activeInjury = null; // Całkowite wyleczenie szlifów
      } else {
        activeInjury = activeInjury.copyWith(daysRemaining: daysRemaining);
      }
    }

    // Obniżenie efektywnego FTP na kolejny etap z powodu szlifów i bólu
    final int baseFtp = rider.physiology.ftpWatts > 0 ? rider.physiology.ftpWatts : 380;
    final int effectiveFtp = calculateEffectiveFtp(
      baseFtpWatts: baseFtp,
      injury: activeInjury,
      tsb: newTsb,
      doctorsLevel: team.staff.doctorsLevel,
    );
    final double ftpPenaltyRatio = baseFtp > 0 ? (baseFtp - effectiveFtp) / baseFtp : 0.0;

    // 5. Aktualizacja morale kolarza
    final double prevMorale = rider.contract.morale;
    double moraleChange = 0.0;

    // Wpływ indywidualnego wyniku
    if (workload.isDnf) {
      moraleChange -= 12.0;
    } else if (workload.finishRank == 1) {
      moraleChange += 16.0;
    } else if (workload.finishRank <= 3) {
      moraleChange += 9.0;
    } else if (workload.finishRank <= 10) {
      moraleChange += 4.5;
    } else if (workload.finishRank <= 25) {
      moraleChange += 1.5;
    }

    // Wpływ sukcesu zespołowego
    if (teamWonStage && workload.finishRank != 1) {
      moraleChange += 8.5; // Zwycięstwo kolegi podnosi na duchu
      if (workload.tacticalOrder == TacticalOrder.pullGroup ||
          workload.tacticalOrder == TacticalOrder.protectLeader) {
        moraleChange += 3.5; // Dumny ze skutecznej pomocy
      }
    } else if (teamHadPodium && workload.finishRank > 3) {
      moraleChange += 4.0;
    }

    if (teamHoldsLeaderJersey) {
      moraleChange += 2.5;
    }

    // Wpływ negatywnych zdarzeń zespołowych
    if (teamHadDnf && !workload.isDnf) {
      moraleChange -= 2.0;
    }

    // Wpływ odniesionych ran
    if (activeInjury != null) {
      moraleChange -= 4.0;
    }

    // Wpływ komfortu sprzętowego
    if (facilities.hasSleepOptimizationKit && facilities.hasCompressionBoots) {
      moraleChange += 1.0;
    }

    final double newMorale = (prevMorale + moraleChange).clamp(1.0, 100.0);

    // 6. Opis słowny stanu kolarza
    final StringBuffer statusDesc = StringBuffer();
    if (activeInjury != null) {
      statusDesc.write(
          'Szlify asfaltowe (pozostało ${daysRemaining}d, moc -${(ftpPenaltyRatio * 100).toStringAsFixed(1)}%). ');
    }
    if (newTsb > 10.0) {
      statusDesc.write('Wysoka świeżość, pełna dyspozycja fizyczna.');
    } else if (newTsb >= -15.0) {
      statusDesc.write('Dobra regeneracja, gotowy do realizacji taktyki.');
    } else if (newTsb >= -30.0) {
      statusDesc.write('Wyraźne zmęczenie mięśniowe, wskazana jazda oszczędna.');
    } else {
      statusDesc.write('Głębokie wyczerpanie (TSB ${newTsb.toStringAsFixed(1)}), ryzyko kryzysu.');
    }

    return RiderOvernightRecoveryReport(
      riderId: rider.id,
      riderName: rider.fullName,
      stageTss: workload.tss,
      previousAtl: prevAtl,
      grossAtl: grossAtl,
      netAtl: netAtl,
      previousCtl: prevCtl,
      newCtl: newCtl,
      newTsb: newTsb,
      overnightRecoveryScore: overnightRecoveryScore,
      recoveryRateFactor: physBase,
      staffDoctorBonus: staffBonus,
      facilitiesBonus: facBonus,
      roadRashPenalty: roadRashPenalty,
      bonkPenalty: bonkPenalty,
      previousMorale: prevMorale,
      newMorale: newMorale,
      moraleDelta: moraleChange,
      effectiveFtpNextStage: effectiveFtp,
      activeInjury: activeInjury,
      injuryDaysRemaining: daysRemaining,
      statusDescription: statusDesc.toString().trim(),
    );
  }
}
