// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../events/race_incident_engine.dart';

/// Typ etapu decydujący o aktywacji strefy ochronnej UCI (Art. 2.6.027).
enum NeutralZoneStageType {
  /// Płaski etap sprinterski — strefa 3 km lub rozszerzona 5 km aktywna.
  flatSprint(
    label: 'Etap sprinterski (płaski)',
    shortLabel: 'Sprinterski',
    isEligible: true,
    supportsFiveKmExtension: true,
  ),

  /// Etap pagórkowaty z płaskim finiszem — strefa ochronna aktywna.
  rollingSprint(
    label: 'Pagórkowaty (płaski finisz)',
    shortLabel: 'Pagórkowaty',
    isEligible: true,
    supportsFiveKmExtension: true,
  ),

  /// Finisz na podjeździe / szczycie — brak strefy ochronnej wg przepisów UCI.
  summitFinish(
    label: 'Finisz górski (szczyt)',
    shortLabel: 'Szczytowy',
    isEligible: false,
    supportsFiveKmExtension: false,
  ),

  /// Jazda indywidualna na czas (ITT) — brak strefy ochronnej.
  individualTimeTrial(
    label: 'Jazda indywidualna na czas',
    shortLabel: 'ITT',
    isEligible: false,
    supportsFiveKmExtension: false,
  ),

  /// Jazda drużynowa na czas (TTT) — brak strefy ochronnej.
  teamTimeTrial(
    label: 'Jazda drużynowa na czas',
    shortLabel: 'TTT',
    isEligible: false,
    supportsFiveKmExtension: false,
  ),

  /// Wyścig jednodniowy / Monument — reguła 3 km dotyczy tylko wyścigów etapowych.
  oneDayClassic(
    label: 'Klasyk jednodniowy',
    shortLabel: 'Klasyk',
    isEligible: false,
    supportsFiveKmExtension: false,
  );

  final String label;
  final String shortLabel;
  final bool isEligible;
  final bool supportsFiveKmExtension;

  const NeutralZoneStageType({
    required this.label,
    required this.shortLabel,
    required this.isEligible,
    required this.supportsFiveKmExtension,
  });

  String toJson() => name;

  static NeutralZoneStageType fromJson(String value) {
    return NeutralZoneStageType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => NeutralZoneStageType.flatSprint,
    );
  }
}

/// Długość strefy ochronnej przed metą wyznaczona przez kolegium sędziów UCI.
enum NeutralZoneDistancePreset {
  /// Standardowa strefa 3 km (3000 m).
  standard3Km(
    meters: 3000.0,
    label: '3 km (Standard UCI)',
    badgeText: '3 KM ZONE',
  ),

  /// Rozszerzona strefa 5 km (5000 m) dla technicznych lub mokrych finiszów sprinterskich.
  extended5Km(
    meters: 5000.0,
    label: '5 km (Rozszerzona Sprint)',
    badgeText: '5 KM ZONE',
  );

  final double meters;
  final String label;
  final String badgeText;

  const NeutralZoneDistancePreset({
    required this.meters,
    required this.label,
    required this.badgeText,
  });

  String toJson() => name;

  static NeutralZoneDistancePreset fromJson(String value) {
    return NeutralZoneDistancePreset.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => NeutralZoneDistancePreset.standard3Km,
    );
  }
}

/// Przyczyna opóźnienia kolarza w końcówce etapu.
enum NeutralZoneIncidentType {
  /// Kraksa indywidualna lub zbiorowa w peletonie.
  crash(
    label: 'Kraksa',
    isMechanicalOrCrash: true,
  ),

  /// Przebicie opony (defekt ogumienia).
  puncture(
    label: 'Przebicie opony',
    isMechanicalOrCrash: true,
  ),

  /// Awaria mechaniczna (łańcuch, przerzutka, szprycha, hamulec).
  mechanicalFailure(
    label: 'Awaria mechaniczna',
    isMechanicalOrCrash: true,
  ),

  /// Zablokowanie drogi przez kraksę innych kolarzy.
  blockedByCrash(
    label: 'Zablokowanie przez kraksę',
    isMechanicalOrCrash: true,
  ),

  /// Odpadnięcie z powodu braku sił / tempa (brak ochrony).
  droppedOnPace(
    label: 'Odpadnięcie z tempa',
    isMechanicalOrCrash: false,
  ),

  /// Podejrzenie symulowanego defektu odrzucone przez VAR sędziowski.
  unverifiedStoppage(
    label: 'Niezweryfikowany postój',
    isMechanicalOrCrash: false,
  );

  final String label;
  final bool isMechanicalOrCrash;

  const NeutralZoneIncidentType({
    required this.label,
    required this.isMechanicalOrCrash,
  });

  /// Mapuje ogólny typ incydentu z silnika zdarzeń na typ strefy ochronnej.
  static NeutralZoneIncidentType fromEngineIncident(IncidentType type) {
    switch (type) {
      case IncidentType.punctureFlatTire:
        return NeutralZoneIncidentType.puncture;
      case IncidentType.mechanicalFailure:
        return NeutralZoneIncidentType.mechanicalFailure;
      case IncidentType.soloCrash:
      case IncidentType.pelotonPileup:
        return NeutralZoneIncidentType.crash;
      case IncidentType.roadBlockage:
        return NeutralZoneIncidentType.blockedByCrash;
    }
  }

  String toJson() => name;

  static NeutralZoneIncidentType fromJson(String value) {
    return NeutralZoneIncidentType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => NeutralZoneIncidentType.mechanicalFailure,
    );
  }
}

/// Werdykt kolegium sędziów UCI w sprawie neutralizacji czasu GC.
enum NeutralZoneVerdictStatus {
  /// Czas GC zneutralizowany — kolarz otrzymuje czas grupy z momentu incydentu.
  neutralized(
    label: 'GC ZNEUTRALIZOWANE',
    color: AppColors.statusSuccess,
  ),

  /// Oczekuje na weryfikację wideo VAR przez sędziów UCI.
  pendingReview(
    label: 'WERYFIKACJA UCI',
    color: AppColors.amberWarning,
  ),

  /// Odrzucone — incydent przed strefą, odpadnięcie z tempa lub brak ochrony na etapie.
  rejected(
    label: 'BEZ OCHRONY',
    color: AppColors.crimsonAlert,
  ),

  /// Kolarz nie ukończył etapu (DNF) — brak klasyfikacji czasowej.
  dnfNoTime(
    label: 'DNF — BRAK CZASU',
    color: AppColors.textSecondary,
  );

  final String label;
  final Color color;

  const NeutralZoneVerdictStatus({
    required this.label,
    required this.color,
  });

  String toJson() => name;

  static NeutralZoneVerdictStatus fromJson(String value) {
    return NeutralZoneVerdictStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => NeutralZoneVerdictStatus.pendingReview,
    );
  }
}

/// Konfiguracja strefy ochronnej dla konkretnego etapu wyścigu.
@immutable
class NeutralZoneConfig {
  final String stageId;
  final String stageName;
  final double stageTotalDistanceMeters;
  final NeutralZoneStageType stageType;
  final NeutralZoneDistancePreset distancePreset;

  /// Czy sędziowie wymusili rozszerzenie strefy do 5 km (np. mokry finisz / ronda).
  final bool juryExtendedTo5Km;

  /// Powód ewentualnego rozszerzenia strefy do 5 km.
  final String? extensionReason;

  /// Próg różnicy czasowej dla utrzymania wspólnego czasu grupy na finiszu sprinterskim.
  final double sprintGroupGapThresholdSeconds;

  const NeutralZoneConfig({
    required this.stageId,
    required this.stageName,
    required this.stageTotalDistanceMeters,
    required this.stageType,
    this.distancePreset = NeutralZoneDistancePreset.standard3Km,
    this.juryExtendedTo5Km = false,
    this.extensionReason,
    this.sprintGroupGapThresholdSeconds = 1.0,
  });

  /// Aktywna długość strefy ochronnej w metrach (0.0 jeśli etap wykluczony).
  double get activeZoneLengthMeters {
    if (!isProtectionActiveForStage) {
      return 0.0;
    }
    if (juryExtendedTo5Km && stageType.supportsFiveKmExtension) {
      return NeutralZoneDistancePreset.extended5Km.meters;
    }
    return distancePreset.meters;
  }

  /// Dystans od startu etapu, od którego rozpoczyna się strefa ochronna [m].
  double get zoneStartDistanceMeters {
    if (!isProtectionActiveForStage) {
      return stageTotalDistanceMeters;
    }
    return math.max(0.0, stageTotalDistanceMeters - activeZoneLengthMeters);
  }

  /// Czy przepisy UCI przewidują ochronę na tym etapie.
  bool get isProtectionActiveForStage =>
      stageType.isEligible && stageTotalDistanceMeters > 0;

  /// Etykieta aktywnej strefy np. "3 KM ZONE" lub "5 KM ZONE".
  String get activeBadgeText {
    if (!isProtectionActiveForStage) {
      return 'NO NEUTRAL ZONE';
    }
    return activeZoneLengthMeters >= 4500.0
        ? NeutralZoneDistancePreset.extended5Km.badgeText
        : NeutralZoneDistancePreset.standard3Km.badgeText;
  }

  /// Sprawdza, czy podany dystans przejechany przez kolarza znajduje się wewnątrz strefy ochronnej.
  bool isDistanceInsideZone(double distanceCoveredMeters) {
    if (!isProtectionActiveForStage) {
      return false;
    }
    final remaining = stageTotalDistanceMeters - distanceCoveredMeters;
    return remaining >= 0.0 && remaining <= activeZoneLengthMeters;
  }

  /// Oblicza dystans pozostały do mety w metrach (zabezpieczony przed ujemnymi wartościami).
  double remainingMeters(double distanceCoveredMeters) {
    return math.max(0.0, stageTotalDistanceMeters - distanceCoveredMeters);
  }

  NeutralZoneConfig copyWith({
    String? stageId,
    String? stageName,
    double? stageTotalDistanceMeters,
    NeutralZoneStageType? stageType,
    NeutralZoneDistancePreset? distancePreset,
    bool? juryExtendedTo5Km,
    String? extensionReason,
    double? sprintGroupGapThresholdSeconds,
  }) {
    return NeutralZoneConfig(
      stageId: stageId ?? this.stageId,
      stageName: stageName ?? this.stageName,
      stageTotalDistanceMeters:
          stageTotalDistanceMeters ?? this.stageTotalDistanceMeters,
      stageType: stageType ?? this.stageType,
      distancePreset: distancePreset ?? this.distancePreset,
      juryExtendedTo5Km: juryExtendedTo5Km ?? this.juryExtendedTo5Km,
      extensionReason: extensionReason ?? this.extensionReason,
      sprintGroupGapThresholdSeconds:
          sprintGroupGapThresholdSeconds ?? this.sprintGroupGapThresholdSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'stageId': stageId,
        'stageName': stageName,
        'stageTotalDistanceMeters': stageTotalDistanceMeters,
        'stageType': stageType.toJson(),
        'distancePreset': distancePreset.toJson(),
        'juryExtendedTo5Km': juryExtendedTo5Km,
        'extensionReason': extensionReason,
        'sprintGroupGapThresholdSeconds': sprintGroupGapThresholdSeconds,
      };

  factory NeutralZoneConfig.fromJson(Map<String, dynamic> json) {
    return NeutralZoneConfig(
      stageId: json['stageId'] as String? ?? 'stage_01',
      stageName: json['stageName'] as String? ?? 'Etap sprinterski',
      stageTotalDistanceMeters:
          (json['stageTotalDistanceMeters'] as num?)?.toDouble() ?? 185000.0,
      stageType: NeutralZoneStageType.fromJson(
        json['stageType'] as String? ?? 'flatSprint',
      ),
      distancePreset: NeutralZoneDistancePreset.fromJson(
        json['distancePreset'] as String? ?? 'standard3Km',
      ),
      juryExtendedTo5Km: json['juryExtendedTo5Km'] as bool? ?? false,
      extensionReason: json['extensionReason'] as String?,
      sprintGroupGapThresholdSeconds:
          (json['sprintGroupGapThresholdSeconds'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// Migawka grupy, w której kolarz wjeżdżał do strefy ochronnej lub doznał incydentu.
@immutable
class RiderNeutralZoneEntry {
  final String riderId;
  final String riderName;
  final String teamId;
  final String teamShortCode;
  final int bibNumber;

  /// Identyfikator grupy w momencie wejścia do strefy / incydentu (np. 0 = ucieczka, 1 = peleton).
  final int groupIndexAtIncident;

  /// Nazwa grupy (np. "Peleton główny", "Ucieczka dnia", "Grupetto").
  final String groupLabel;

  /// Liczba kolarzy jadących razem w tej grupie w chwili zdarzenia.
  final int groupSizeAtIncident;

  /// Czy kolarz jest liderem klasyfikacji generalnej (GC) lub walczy o GC.
  final bool isGcContender;

  const RiderNeutralZoneEntry({
    required this.riderId,
    required this.riderName,
    required this.teamId,
    required this.teamShortCode,
    required this.bibNumber,
    required this.groupIndexAtIncident,
    required this.groupLabel,
    required this.groupSizeAtIncident,
    this.isGcContender = false,
  });

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'teamId': teamId,
        'teamShortCode': teamShortCode,
        'bibNumber': bibNumber,
        'groupIndexAtIncident': groupIndexAtIncident,
        'groupLabel': groupLabel,
        'groupSizeAtIncident': groupSizeAtIncident,
        'isGcContender': isGcContender,
      };

  factory RiderNeutralZoneEntry.fromJson(Map<String, dynamic> json) {
    return RiderNeutralZoneEntry(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      teamId: json['teamId'] as String,
      teamShortCode: json['teamShortCode'] as String? ?? 'PPM',
      bibNumber: (json['bibNumber'] as num?)?.toInt() ?? 1,
      groupIndexAtIncident:
          (json['groupIndexAtIncident'] as num?)?.toInt() ?? 1,
      groupLabel: json['groupLabel'] as String? ?? 'Peleton główny',
      groupSizeAtIncident:
          (json['groupSizeAtIncident'] as num?)?.toInt() ?? 120,
      isGcContender: json['isGcContender'] as bool? ?? false,
    );
  }
}

/// Zarejestrowany incydent w końcówce etapu z pełnymi danymi telemetrycznymi.
@immutable
class NeutralZoneIncidentRecord {
  final String incidentId;
  final RiderNeutralZoneEntry rider;
  final NeutralZoneIncidentType incidentType;

  /// Dystans do mety w chwili incydentu [m] (np. 1850.0 = 1.85 km do mety).
  final double distanceToFinishMeters;

  /// Czas wyścigu w chwili wystąpienia incydentu [s].
  final double incidentRaceTimeSeconds;

  /// Rzeczywisty czas przekroczenia linii mety przez poszkodowanego kolarza [s].
  final double actualFinishTimeSeconds;

  /// Rzeczywiste miejsce zajęte na etapie (kolarz nie zyskuje lokaty etapowej dzięki regule).
  final int actualStageRank;

  /// Czy kolarz przekroczył linię mety o własnych siłach lub na rowerze zapasowym.
  final bool crossedFinishLine;

  /// Czy incydent został zweryfikowany przez kamery i sędziów UCI.
  final bool isCommissaireVerified;

  /// Dodatkowy opis zdarzenia (np. "Przebicie tylnej opony na rondzie 1.8 km").
  final String details;

  const NeutralZoneIncidentRecord({
    required this.incidentId,
    required this.rider,
    required this.incidentType,
    required this.distanceToFinishMeters,
    required this.incidentRaceTimeSeconds,
    required this.actualFinishTimeSeconds,
    required this.actualStageRank,
    this.crossedFinishLine = true,
    this.isCommissaireVerified = true,
    required this.details,
  });

  NeutralZoneIncidentRecord copyWith({
    bool? isCommissaireVerified,
    bool? crossedFinishLine,
    double? actualFinishTimeSeconds,
    int? actualStageRank,
    String? details,
  }) {
    return NeutralZoneIncidentRecord(
      incidentId: incidentId,
      rider: rider,
      incidentType: incidentType,
      distanceToFinishMeters: distanceToFinishMeters,
      incidentRaceTimeSeconds: incidentRaceTimeSeconds,
      actualFinishTimeSeconds:
          actualFinishTimeSeconds ?? this.actualFinishTimeSeconds,
      actualStageRank: actualStageRank ?? this.actualStageRank,
      crossedFinishLine: crossedFinishLine ?? this.crossedFinishLine,
      isCommissaireVerified:
          isCommissaireVerified ?? this.isCommissaireVerified,
      details: details ?? this.details,
    );
  }

  Map<String, dynamic> toJson() => {
        'incidentId': incidentId,
        'rider': rider.toJson(),
        'incidentType': incidentType.toJson(),
        'distanceToFinishMeters': distanceToFinishMeters,
        'incidentRaceTimeSeconds': incidentRaceTimeSeconds,
        'actualFinishTimeSeconds': actualFinishTimeSeconds,
        'actualStageRank': actualStageRank,
        'crossedFinishLine': crossedFinishLine,
        'isCommissaireVerified': isCommissaireVerified,
        'details': details,
      };

  factory NeutralZoneIncidentRecord.fromJson(Map<String, dynamic> json) {
    return NeutralZoneIncidentRecord(
      incidentId: json['incidentId'] as String,
      rider: RiderNeutralZoneEntry.fromJson(
        json['rider'] as Map<String, dynamic>,
      ),
      incidentType: NeutralZoneIncidentType.fromJson(
        json['incidentType'] as String,
      ),
      distanceToFinishMeters:
          (json['distanceToFinishMeters'] as num).toDouble(),
      incidentRaceTimeSeconds:
          (json['incidentRaceTimeSeconds'] as num).toDouble(),
      actualFinishTimeSeconds:
          (json['actualFinishTimeSeconds'] as num).toDouble(),
      actualStageRank: (json['actualStageRank'] as num).toInt(),
      crossedFinishLine: json['crossedFinishLine'] as bool? ?? true,
      isCommissaireVerified: json['isCommissaireVerified'] as bool? ?? true,
      details: json['details'] as String? ?? '',
    );
  }
}

/// Wynik rozstrzygnięcia czasu GC dla pojedynczego incydentu w końcówce etapu.
@immutable
class NeutralZoneResolutionResult {
  final NeutralZoneIncidentRecord incident;
  final NeutralZoneVerdictStatus status;

  /// Czas grupy z momentu incydentu na mecie [s].
  final double groupFinishTimeSeconds;

  /// Finalnie przypisany czas w klasyfikacji generalnej (GC) [s].
  final double creditedGcTimeSeconds;

  /// Zaoszczędzone sekundy w GC dzięki regule 3 km / 5 km [s].
  final double savedGcSeconds;

  /// Rzeczywiste miejsce etapowe (zawsze zachowane wg przekroczenia kreski).
  final int stagePlacementRank;

  /// Czy kolarz zachowuje prawo do punktów sprinterskich / bonifikat (false przy stracie).
  final bool eligibleForStagePointsAndBonuses;

  /// Uzasadnienie decyzji sędziowskiej UCI.
  final String rulingExplanation;

  const NeutralZoneResolutionResult({
    required this.incident,
    required this.status,
    required this.groupFinishTimeSeconds,
    required this.creditedGcTimeSeconds,
    required this.savedGcSeconds,
    required this.stagePlacementRank,
    required this.eligibleForStagePointsAndBonuses,
    required this.rulingExplanation,
  });

  bool get isNeutralized => status == NeutralZoneVerdictStatus.neutralized;

  Map<String, dynamic> toJson() => {
        'incident': incident.toJson(),
        'status': status.toJson(),
        'groupFinishTimeSeconds': groupFinishTimeSeconds,
        'creditedGcTimeSeconds': creditedGcTimeSeconds,
        'savedGcSeconds': savedGcSeconds,
        'stagePlacementRank': stagePlacementRank,
        'eligibleForStagePointsAndBonuses': eligibleForStagePointsAndBonuses,
        'rulingExplanation': rulingExplanation,
      };

  factory NeutralZoneResolutionResult.fromJson(Map<String, dynamic> json) {
    return NeutralZoneResolutionResult(
      incident: NeutralZoneIncidentRecord.fromJson(
        json['incident'] as Map<String, dynamic>,
      ),
      status: NeutralZoneVerdictStatus.fromJson(json['status'] as String),
      groupFinishTimeSeconds:
          (json['groupFinishTimeSeconds'] as num).toDouble(),
      creditedGcTimeSeconds:
          (json['creditedGcTimeSeconds'] as num).toDouble(),
      savedGcSeconds: (json['savedGcSeconds'] as num).toDouble(),
      stagePlacementRank: (json['stagePlacementRank'] as num).toInt(),
      eligibleForStagePointsAndBonuses:
          json['eligibleForStagePointsAndBonuses'] as bool? ?? false,
      rulingExplanation: json['rulingExplanation'] as String? ?? '',
    );
  }
}

/// Zbiorczy raport sędziowski ze strefy ochronnej na etapie.
@immutable
class NeutralZoneAuditSummary {
  final int totalIncidentsReviewed;
  final int neutralizedCount;
  final int pendingCount;
  final int rejectedCount;
  final int dnfCount;
  final double totalGcSecondsSaved;
  final double maxSingleRiderSavedSeconds;

  const NeutralZoneAuditSummary({
    required this.totalIncidentsReviewed,
    required this.neutralizedCount,
    required this.pendingCount,
    required this.rejectedCount,
    required this.dnfCount,
    required this.totalGcSecondsSaved,
    required this.maxSingleRiderSavedSeconds,
  });
}

/// Precyzyjny silnik obsługujący strefę ochronną UCI 3 km / 5 km na końcówkach etapów.
///
/// Implementuje regułę UCI Art. 2.6.027:
/// - Ochrona obowiązuje wyłącznie na etapach niekwalifikowanych jako ITT/TTT, szczytowe czy klasyki.
/// - Wewnątrz strefy (3000 m lub 5000 m przed metą) kraksa, przebicie, defekt lub zablokowanie
///   zapewnia kolarzowi czas GC grupy, w której jechał w chwili zdarzenia.
/// - Odpadnięcie z tempa (brak sił) oraz incydenty poza strefą nie podlegają ochronie.
/// - Kolarz musi przekroczyć linię mety, a jego lokata etapowa pozostaje rzeczywista (brak punktów/bonifikat).
class LateRaceMechanicalNeutralZoneEngine {
  const LateRaceMechanicalNeutralZoneEngine();

  /// Rozstrzyga pojedynczy incydent w końcówce etapu względem konfiguracji i czasów grup.
  NeutralZoneResolutionResult evaluateIncident({
    required NeutralZoneConfig config,
    required NeutralZoneIncidentRecord incident,
    required Map<int, double> groupFinishTimesSeconds,
  }) {
    final groupIndex = incident.rider.groupIndexAtIncident;
    final groupFinishTime = groupFinishTimesSeconds[groupIndex] ??
        incident.actualFinishTimeSeconds;

    // 1. Brak ukończenia etapu (DNF) — brak czasu na mecie, wycofanie z wyścigu.
    if (!incident.crossedFinishLine) {
      return NeutralZoneResolutionResult(
        incident: incident,
        status: NeutralZoneVerdictStatus.dnfNoTime,
        groupFinishTimeSeconds: groupFinishTime,
        creditedGcTimeSeconds: 0.0,
        savedGcSeconds: 0.0,
        stagePlacementRank: incident.actualStageRank,
        eligibleForStagePointsAndBonuses: false,
        rulingExplanation:
            'Kolarz nie przekroczył linii mety (DNF). Reguła strefy ochronnej nie przyznaje czasu.',
      );
    }

    // 2. Sprawdzenie kwalifikowalności etapu wg przepisów UCI.
    if (!config.isProtectionActiveForStage) {
      return NeutralZoneResolutionResult(
        incident: incident,
        status: NeutralZoneVerdictStatus.rejected,
        groupFinishTimeSeconds: groupFinishTime,
        creditedGcTimeSeconds: incident.actualFinishTimeSeconds,
        savedGcSeconds: 0.0,
        stagePlacementRank: incident.actualStageRank,
        eligibleForStagePointsAndBonuses: true,
        rulingExplanation:
            'Typ etapu (${config.stageType.shortLabel}) wyłączony ze strefy ochronnej UCI.',
      );
    }

    // 3. Sprawdzenie dystansu do mety (czy incydent nastąpił wewnątrz strefy 3 km / 5 km).
    final zoneMeters = config.activeZoneLengthMeters;
    if (incident.distanceToFinishMeters < 0.0 ||
        incident.distanceToFinishMeters > zoneMeters) {
      final kmOut = (incident.distanceToFinishMeters / 1000.0).toStringAsFixed(2);
      final zoneKm = (zoneMeters / 1000.0).toStringAsFixed(0);
      return NeutralZoneResolutionResult(
        incident: incident,
        status: NeutralZoneVerdictStatus.rejected,
        groupFinishTimeSeconds: groupFinishTime,
        creditedGcTimeSeconds: incident.actualFinishTimeSeconds,
        savedGcSeconds: 0.0,
        stagePlacementRank: incident.actualStageRank,
        eligibleForStagePointsAndBonuses: true,
        rulingExplanation:
            'Incydent na $kmOut km przed metą — poza aktywną strefą $zoneKm km.',
      );
    }

    // 4. Odpadnięcie z tempa lub niezweryfikowany postój nie są chronione.
    if (!incident.incidentType.isMechanicalOrCrash) {
      return NeutralZoneResolutionResult(
        incident: incident,
        status: NeutralZoneVerdictStatus.rejected,
        groupFinishTimeSeconds: groupFinishTime,
        creditedGcTimeSeconds: incident.actualFinishTimeSeconds,
        savedGcSeconds: 0.0,
        stagePlacementRank: incident.actualStageRank,
        eligibleForStagePointsAndBonuses: true,
        rulingExplanation:
            'Przyczyna (${incident.incidentType.label}) nie podlega neutralizacji czasu GC.',
      );
    }

    // 5. Samotny kolarz w grupie 1-osobowej nie ma grupy odniesienia, której czas mógłby przejąć.
    if (incident.rider.groupSizeAtIncident <= 1) {
      return NeutralZoneResolutionResult(
        incident: incident,
        status: NeutralZoneVerdictStatus.rejected,
        groupFinishTimeSeconds: incident.actualFinishTimeSeconds,
        creditedGcTimeSeconds: incident.actualFinishTimeSeconds,
        savedGcSeconds: 0.0,
        stagePlacementRank: incident.actualStageRank,
        eligibleForStagePointsAndBonuses: true,
        rulingExplanation:
            'Jazda indywidualna bez grupy odniesienia w chwili zdarzenia — obowiązuje czas rzeczywisty.',
      );
    }

    // 6. Oczekiwanie na weryfikację wideo przez kolegium sędziów.
    if (!incident.isCommissaireVerified) {
      return NeutralZoneResolutionResult(
        incident: incident,
        status: NeutralZoneVerdictStatus.pendingReview,
        groupFinishTimeSeconds: groupFinishTime,
        creditedGcTimeSeconds: incident.actualFinishTimeSeconds,
        savedGcSeconds: 0.0,
        stagePlacementRank: incident.actualStageRank,
        eligibleForStagePointsAndBonuses: false,
        rulingExplanation:
            'Oczekiwanie na potwierdzenie incydentu przez kolegium sędziów (VAR).',
      );
    }

    // 7. Pełna neutralizacja GC — przypisanie czasu grupy (nigdy gorszego niż rzeczywisty,
    //    ale też nigdy lepszego niż czas grupy z momentu incydentu).
    final creditedTime = math.min(incident.actualFinishTimeSeconds, groupFinishTime);
    final savedSeconds =
        math.max(0.0, incident.actualFinishTimeSeconds - creditedTime);
    final kmToGo = (incident.distanceToFinishMeters / 1000.0).toStringAsFixed(2);

    return NeutralZoneResolutionResult(
      incident: incident,
      status: NeutralZoneVerdictStatus.neutralized,
      groupFinishTimeSeconds: groupFinishTime,
      creditedGcTimeSeconds: creditedTime,
      savedGcSeconds: savedSeconds,
      stagePlacementRank: incident.actualStageRank,
      eligibleForStagePointsAndBonuses: savedSeconds <= 0.0,
      rulingExplanation:
          'Zneutralizowano wg Art. 2.6.027 (${incident.incidentType.label} na $kmToGo km): '
          'przypisano czas grupy "${incident.rider.groupLabel}".',
    );
  }

  /// Rozstrzyga listę incydentów na etapie i zwraca kompletny raport wraz z podsumowaniem.
  List<NeutralZoneResolutionResult> evaluateBatch({
    required NeutralZoneConfig config,
    required List<NeutralZoneIncidentRecord> incidents,
    required Map<int, double> groupFinishTimesSeconds,
  }) {
    return incidents
        .map(
          (incident) => evaluateIncident(
            config: config,
            incident: incident,
            groupFinishTimesSeconds: groupFinishTimesSeconds,
          ),
        )
        .toList(growable: false);
  }

  /// Tworzy podsumowanie statystyczne werdyktów sędziowskich.
  NeutralZoneAuditSummary summarizeResolutions(
    List<NeutralZoneResolutionResult> results,
  ) {
    int neutralized = 0;
    int pending = 0;
    int rejected = 0;
    int dnf = 0;
    double totalSaved = 0.0;
    double maxSaved = 0.0;

    for (final result in results) {
      switch (result.status) {
        case NeutralZoneVerdictStatus.neutralized:
          neutralized++;
          totalSaved += result.savedGcSeconds;
          if (result.savedGcSeconds > maxSaved) {
            maxSaved = result.savedGcSeconds;
          }
          break;
        case NeutralZoneVerdictStatus.pendingReview:
          pending++;
          break;
        case NeutralZoneVerdictStatus.rejected:
          rejected++;
          break;
        case NeutralZoneVerdictStatus.dnfNoTime:
          dnf++;
          break;
      }
    }

    return NeutralZoneAuditSummary(
      totalIncidentsReviewed: results.length,
      neutralizedCount: neutralized,
      pendingCount: pending,
      rejectedCount: rejected,
      dnfCount: dnf,
      totalGcSecondsSaved: totalSaved,
      maxSingleRiderSavedSeconds: maxSaved,
    );
  }

  /// Oblicza znormalizowany postęp kolarza w strefie ochronnej (0.0 = wejście, 1.0 = meta).
  double calculateZoneProgress({
    required NeutralZoneConfig config,
    required double distanceCoveredMeters,
  }) {
    if (!config.isProtectionActiveForStage ||
        config.activeZoneLengthMeters <= 0.0) {
      return 0.0;
    }
    final remaining = config.remainingMeters(distanceCoveredMeters);
    if (remaining >= config.activeZoneLengthMeters) {
      return 0.0;
    }
    return ((config.activeZoneLengthMeters - remaining) /
            config.activeZoneLengthMeters)
        .clamp(0.0, 1.0);
  }
}

/// Stan Riverpod zarządzający obsługą strefy ochronnej 3 km / 5 km na żywo i w symulacji.
@immutable
class LateRaceNeutralZoneState {
  final NeutralZoneConfig config;
  final double currentLeadDistanceMeters;
  final Map<int, double> groupFinishTimesSeconds;
  final List<NeutralZoneIncidentRecord> incidents;
  final List<NeutralZoneResolutionResult> resolutions;
  final NeutralZoneAuditSummary summary;
  final NeutralZoneVerdictStatus? activeFilter;

  const LateRaceNeutralZoneState({
    required this.config,
    required this.currentLeadDistanceMeters,
    required this.groupFinishTimesSeconds,
    required this.incidents,
    required this.resolutions,
    required this.summary,
    this.activeFilter,
  });

  bool get isLeadRiderInsideZone =>
      config.isDistanceInsideZone(currentLeadDistanceMeters);

  double get remainingToFinishMeters =>
      config.remainingMeters(currentLeadDistanceMeters);

  List<NeutralZoneResolutionResult> get filteredResolutions {
    if (activeFilter == null) {
      return resolutions;
    }
    return resolutions
        .where((r) => r.status == activeFilter)
        .toList(growable: false);
  }

  LateRaceNeutralZoneState copyWith({
    NeutralZoneConfig? config,
    double? currentLeadDistanceMeters,
    Map<int, double>? groupFinishTimesSeconds,
    List<NeutralZoneIncidentRecord>? incidents,
    List<NeutralZoneResolutionResult>? resolutions,
    NeutralZoneAuditSummary? summary,
    NeutralZoneVerdictStatus? activeFilter,
    bool clearFilter = false,
  }) {
    return LateRaceNeutralZoneState(
      config: config ?? this.config,
      currentLeadDistanceMeters:
          currentLeadDistanceMeters ?? this.currentLeadDistanceMeters,
      groupFinishTimesSeconds:
          groupFinishTimesSeconds ?? this.groupFinishTimesSeconds,
      incidents: incidents ?? this.incidents,
      resolutions: resolutions ?? this.resolutions,
      summary: summary ?? this.summary,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
    );
  }
}

/// Notifier zarządzający stanem strefy ochronnej 3 km / 5 km oraz decyzjami sędziowskimi.
class LateRaceNeutralZoneNotifier
    extends StateNotifier<LateRaceNeutralZoneState> {
  final LateRaceMechanicalNeutralZoneEngine _engine;

  LateRaceNeutralZoneNotifier({
    LateRaceMechanicalNeutralZoneEngine? engine,
    NeutralZoneConfig? initialConfig,
  })  : _engine = engine ?? const LateRaceMechanicalNeutralZoneEngine(),
        super(_createInitialState(
          engine ?? const LateRaceMechanicalNeutralZoneEngine(),
          initialConfig ?? _defaultConfig,
        ));

  static const NeutralZoneConfig _defaultConfig = NeutralZoneConfig(
    stageId: 'tdf_s04_sprint',
    stageName: 'Etap 4: Orleans – Saint-Amand-Montrond',
    stageTotalDistanceMeters: 187500.0,
    stageType: NeutralZoneStageType.flatSprint,
    distancePreset: NeutralZoneDistancePreset.standard3Km,
    juryExtendedTo5Km: false,
    extensionReason: 'Techniczny finisz z dwoma rondami w mieście',
  );

  static LateRaceNeutralZoneState _createInitialState(
    LateRaceMechanicalNeutralZoneEngine engine,
    NeutralZoneConfig config,
  ) {
    final groupTimes = <int, double>{
      0: 14812.0, // Ucieczka
      1: 14820.0, // Peleton główny
      2: 15195.0, // Grupetto
    };

    final sampleIncidents = <NeutralZoneIncidentRecord>[
      const NeutralZoneIncidentRecord(
        incidentId: 'inc_01',
        rider: RiderNeutralZoneEntry(
          riderId: 'rider_gc_01',
          riderName: 'T. Pogacar',
          teamId: 'team_uae',
          teamShortCode: 'UAD',
          bibNumber: 1,
          groupIndexAtIncident: 1,
          groupLabel: 'Peleton główny',
          groupSizeAtIncident: 138,
          isGcContender: true,
        ),
        incidentType: NeutralZoneIncidentType.puncture,
        distanceToFinishMeters: 2150.0,
        incidentRaceTimeSeconds: 14685.0,
        actualFinishTimeSeconds: 14908.0,
        actualStageRank: 112,
        crossedFinishLine: true,
        isCommissaireVerified: true,
        details: 'Przebicie tylnego koła na zjeździe z ronda (2.15 km do mety).',
      ),
      const NeutralZoneIncidentRecord(
        incidentId: 'inc_02',
        rider: RiderNeutralZoneEntry(
          riderId: 'rider_gc_02',
          riderName: 'J. Vingegaard',
          teamId: 'team_tvl',
          teamShortCode: 'TVL',
          bibNumber: 11,
          groupIndexAtIncident: 1,
          groupLabel: 'Peleton główny',
          groupSizeAtIncident: 138,
          isGcContender: true,
        ),
        incidentType: NeutralZoneIncidentType.blockedByCrash,
        distanceToFinishMeters: 1420.0,
        incidentRaceTimeSeconds: 14732.0,
        actualFinishTimeSeconds: 14864.0,
        actualStageRank: 74,
        crossedFinishLine: true,
        isCommissaireVerified: false,
        details: 'Zablokowany za kraksą pociągu sprinterskiego na 1.42 km.',
      ),
      const NeutralZoneIncidentRecord(
        incidentId: 'inc_03',
        rider: RiderNeutralZoneEntry(
          riderId: 'rider_dom_08',
          riderName: 'M. Kwiatkowski',
          teamId: 'team_igd',
          teamShortCode: 'IGD',
          bibNumber: 44,
          groupIndexAtIncident: 1,
          groupLabel: 'Peleton główny',
          groupSizeAtIncident: 138,
          isGcContender: false,
        ),
        incidentType: NeutralZoneIncidentType.droppedOnPace,
        distanceToFinishMeters: 1900.0,
        incidentRaceTimeSeconds: 14705.0,
        actualFinishTimeSeconds: 14878.0,
        actualStageRank: 91,
        crossedFinishLine: true,
        isCommissaireVerified: true,
        details: 'Odpadł z peletonu po wykonaniu zmiany na rzecz sprintera.',
      ),
      const NeutralZoneIncidentRecord(
        incidentId: 'inc_04',
        rider: RiderNeutralZoneEntry(
          riderId: 'rider_gc_05',
          riderName: 'R. Evenepoel',
          teamId: 'team_soq',
          teamShortCode: 'SOQ',
          bibNumber: 21,
          groupIndexAtIncident: 1,
          groupLabel: 'Peleton główny',
          groupSizeAtIncident: 138,
          isGcContender: true,
        ),
        incidentType: NeutralZoneIncidentType.mechanicalFailure,
        distanceToFinishMeters: 3650.0,
        incidentRaceTimeSeconds: 14592.0,
        actualFinishTimeSeconds: 14895.0,
        actualStageRank: 104,
        crossedFinishLine: true,
        isCommissaireVerified: true,
        details: 'Spadnięty łańcuch na 3.65 km przed metą — kluczowa granica 3 km vs 5 km.',
      ),
    ];

    final resolutions = engine.evaluateBatch(
      config: config,
      incidents: sampleIncidents,
      groupFinishTimesSeconds: groupTimes,
    );

    return LateRaceNeutralZoneState(
      config: config,
      currentLeadDistanceMeters: 185200.0,
      groupFinishTimesSeconds: groupTimes,
      incidents: sampleIncidents,
      resolutions: resolutions,
      summary: engine.summarizeResolutions(resolutions),
    );
  }

  void _recompute({
    NeutralZoneConfig? config,
    double? currentLeadDistanceMeters,
    Map<int, double>? groupFinishTimesSeconds,
    List<NeutralZoneIncidentRecord>? incidents,
    NeutralZoneVerdictStatus? activeFilter,
    bool clearFilter = false,
  }) {
    final nextConfig = config ?? state.config;
    final nextGroupTimes =
        groupFinishTimesSeconds ?? state.groupFinishTimesSeconds;
    final nextIncidents = incidents ?? state.incidents;
    final nextResolutions = _engine.evaluateBatch(
      config: nextConfig,
      incidents: nextIncidents,
      groupFinishTimesSeconds: nextGroupTimes,
    );

    state = state.copyWith(
      config: nextConfig,
      currentLeadDistanceMeters: currentLeadDistanceMeters,
      groupFinishTimesSeconds: nextGroupTimes,
      incidents: nextIncidents,
      resolutions: nextResolutions,
      summary: _engine.summarizeResolutions(nextResolutions),
      activeFilter: activeFilter,
      clearFilter: clearFilter,
    );
  }

  /// Zmienia typ etapu (np. sprinterski vs szczytowy vs ITT).
  void setStageType(NeutralZoneStageType stageType) {
    final nextExtended =
        stageType.supportsFiveKmExtension ? state.config.juryExtendedTo5Km : false;
    _recompute(
      config: state.config.copyWith(
        stageType: stageType,
        juryExtendedTo5Km: nextExtended,
      ),
    );
  }

  /// Przełącza długość strefy między standardem 3 km a rozszerzeniem 5 km.
  void setZonePreset(NeutralZoneDistancePreset preset) {
    final is5Km = preset == NeutralZoneDistancePreset.extended5Km;
    _recompute(
      config: state.config.copyWith(
        distancePreset: preset,
        juryExtendedTo5Km:
            is5Km && state.config.stageType.supportsFiveKmExtension,
      ),
    );
  }

  /// Aktualizuje dystans lidera wyścigu od startu [m].
  void updateLeadDistance(double distanceMeters) {
    final clamped =
        distanceMeters.clamp(0.0, state.config.stageTotalDistanceMeters);
    state = state.copyWith(currentLeadDistanceMeters: clamped);
  }

  /// Zapisuje lub aktualizuje incydent z silnika wyścigu.
  void registerIncident(NeutralZoneIncidentRecord record) {
    final updated = List<NeutralZoneIncidentRecord>.from(state.incidents);
    final idx = updated.indexWhere((e) => e.incidentId == record.incidentId);
    if (idx >= 0) {
      updated[idx] = record;
    } else {
      updated.insert(0, record);
    }
    _recompute(incidents: updated);
  }

  /// Weryfikuje lub odrzuca incydent oczekujący na decyzję sędziów (VAR).
  void setCommissaireVerification(String incidentId, bool verified) {
    final updated = state.incidents.map((inc) {
      if (inc.incidentId != incidentId) {
        return inc;
      }
      if (!verified) {
        return NeutralZoneIncidentRecord(
          incidentId: inc.incidentId,
          rider: inc.rider,
          incidentType: NeutralZoneIncidentType.unverifiedStoppage,
          distanceToFinishMeters: inc.distanceToFinishMeters,
          incidentRaceTimeSeconds: inc.incidentRaceTimeSeconds,
          actualFinishTimeSeconds: inc.actualFinishTimeSeconds,
          actualStageRank: inc.actualStageRank,
          crossedFinishLine: inc.crossedFinishLine,
          isCommissaireVerified: false,
          details: '${inc.details} [Odrzucono przez VAR UCI]',
        );
      }
      return inc.copyWith(isCommissaireVerified: true);
    }).toList(growable: false);

    _recompute(incidents: updated);
  }

  /// Ustawia filtr statusów werdyktu na liście incydentów.
  void setFilter(NeutralZoneVerdictStatus? status) {
    if (status == null) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(activeFilter: status);
    }
  }
}

/// Globalny provider strefy ochronnej 3 km / 5 km.
final lateRaceNeutralZoneProvider = StateNotifierProvider<
    LateRaceNeutralZoneNotifier, LateRaceNeutralZoneState>(
  (ref) => LateRaceNeutralZoneNotifier(),
);

/// Responsywny panel diagnostyczno-taktyczny strefy ochronnej 3 km / 5 km UCI.
class LateRaceMechanicalNeutralZonePanel extends ConsumerWidget {
  const LateRaceMechanicalNeutralZonePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lateRaceNeutralZoneProvider);
    final notifier = ref.read(lateRaceNeutralZoneProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 680;
          final isDesktop = width >= 1120;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NeutralZoneHeaderCard(
                  state: state,
                  isMobile: isMobile,
                ),
                const SizedBox(height: 16),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _NeutralZoneControlsCard(
                          state: state,
                          notifier: notifier,
                          isMobile: false,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 7,
                        child: _NeutralZoneIncidentsCard(
                          state: state,
                          notifier: notifier,
                          isMobile: false,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _NeutralZoneControlsCard(
                    state: state,
                    notifier: notifier,
                    isMobile: isMobile,
                  ),
                  const SizedBox(height: 16),
                  _NeutralZoneIncidentsCard(
                    state: state,
                    notifier: notifier,
                    isMobile: isMobile,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NeutralZoneHeaderCard extends StatelessWidget {
  final LateRaceNeutralZoneState state;
  final bool isMobile;

  const _NeutralZoneHeaderCard({
    required this.state,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final config = state.config;
    final active = config.isProtectionActiveForStage;
    final inZone = state.isLeadRiderInsideZone;
    final remainingKm = (state.remainingToFinishMeters / 1000.0).toStringAsFixed(2);

    final Color badgeColor = !active
        ? AppColors.textSecondary
        : (inZone ? AppColors.statusSuccess : AppColors.accentBlue);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: inZone ? AppColors.statusSuccess : AppColors.cardBorder,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Icon(
                  active ? Icons.shield_outlined : Icons.gpp_bad_outlined,
                  color: badgeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STREFA OCHRONNA UCI (ART. 2.6.027)',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.goldAccent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      config.stageName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  config.activeBadgeText,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _MetricChip(
                label: 'Do mety',
                value: '$remainingKm km',
                accent: inZone ? AppColors.statusSuccess : AppColors.textPrimary,
              ),
              _MetricChip(
                label: 'Zneutralizowani',
                value: '${state.summary.neutralizedCount}',
                accent: AppColors.statusSuccess,
              ),
              _MetricChip(
                label: 'Weryfikacja VAR',
                value: '${state.summary.pendingCount}',
                accent: AppColors.amberWarning,
              ),
              _MetricChip(
                label: 'Uratowany czas GC',
                value:
                    '${state.summary.totalGcSecondsSaved.toStringAsFixed(0)} s',
                accent: AppColors.cyanAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _NeutralZoneControlsCard extends StatelessWidget {
  final LateRaceNeutralZoneState state;
  final LateRaceNeutralZoneNotifier notifier;
  final bool isMobile;

  const _NeutralZoneControlsCard({
    required this.state,
    required this.notifier,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final config = state.config;
    final supports5Km = config.stageType.supportsFiveKmExtension;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Konfiguracja Jury UCI',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Typ etapu',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: NeutralZoneStageType.values.map((type) {
              return _InteractiveActionChip(
                label: type.shortLabel,
                selected: config.stageType == type,
                enabled: true,
                accentColor: type.isEligible
                    ? AppColors.primaryAccent
                    : AppColors.textSecondary,
                onTap: () => notifier.setStageType(type),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 16),
          const Text(
            'Zasięg strefy ochronnej',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: NeutralZoneDistancePreset.values.map((preset) {
              final isSelected = config.isProtectionActiveForStage &&
                  ((preset == NeutralZoneDistancePreset.extended5Km &&
                          config.activeZoneLengthMeters >= 4500.0) ||
                      (preset == NeutralZoneDistancePreset.standard3Km &&
                          config.activeZoneLengthMeters > 0 &&
                          config.activeZoneLengthMeters < 4500.0));
              final enabled = config.isProtectionActiveForStage &&
                  (preset == NeutralZoneDistancePreset.standard3Km ||
                      supports5Km);

              return _InteractiveActionChip(
                label: preset.label,
                selected: isSelected,
                enabled: enabled,
                accentColor: AppColors.goldAccent,
                onTap: () => notifier.setZonePreset(preset),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Symulacja pozycji czołówki',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(state.remainingToFinishMeters / 1000.0).toStringAsFixed(2)} km do mety',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentBlue,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          Slider(
            value: state.remainingToFinishMeters.clamp(0.0, 6000.0),
            min: 0.0,
            max: 6000.0,
            divisions: 60,
            activeColor: state.isLeadRiderInsideZone
                ? AppColors.statusSuccess
                : AppColors.accentBlue,
            inactiveColor: AppColors.surfaceLight,
            onChanged: (remaining) {
              notifier.updateLeadDistance(
                config.stageTotalDistanceMeters - remaining,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NeutralZoneIncidentsCard extends StatelessWidget {
  final LateRaceNeutralZoneState state;
  final LateRaceNeutralZoneNotifier notifier;
  final bool isMobile;

  const _NeutralZoneIncidentsCard({
    required this.state,
    required this.notifier,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final items = state.filteredResolutions;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Rejestr incydentów i werdykty GC',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _InteractiveActionChip(
                    label: 'Wszystkie',
                    selected: state.activeFilter == null,
                    enabled: true,
                    accentColor: AppColors.accentBlue,
                    onTap: () => notifier.setFilter(null),
                  ),
                  _InteractiveActionChip(
                    label: 'Neutralizacja',
                    selected:
                        state.activeFilter == NeutralZoneVerdictStatus.neutralized,
                    enabled: true,
                    accentColor: AppColors.statusSuccess,
                    onTap: () =>
                        notifier.setFilter(NeutralZoneVerdictStatus.neutralized),
                  ),
                  _InteractiveActionChip(
                    label: 'VAR',
                    selected: state.activeFilter ==
                        NeutralZoneVerdictStatus.pendingReview,
                    enabled: true,
                    accentColor: AppColors.amberWarning,
                    onTap: () => notifier
                        .setFilter(NeutralZoneVerdictStatus.pendingReview),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Center(
                child: Text(
                  'Brak incydentów spełniających wybrane kryteria.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            Column(
              children: items.map((res) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ResolutionTile(
                    resolution: res,
                    onVerify: () => notifier.setCommissaireVerification(
                      res.incident.incidentId,
                      true,
                    ),
                    onReject: () => notifier.setCommissaireVerification(
                      res.incident.incidentId,
                      false,
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _ResolutionTile extends StatelessWidget {
  final NeutralZoneResolutionResult resolution;
  final VoidCallback onVerify;
  final VoidCallback onReject;

  const _ResolutionTile({
    required this.resolution,
    required this.onVerify,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final inc = resolution.incident;
    final statusColor = resolution.status.color;
    final km = (inc.distanceToFinishMeters / 1000.0).toStringAsFixed(2);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  '#${inc.rider.bibNumber} ${inc.rider.teamShortCode}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  inc.rider.riderName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.45)),
                ),
                child: Text(
                  resolution.status.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${inc.incidentType.label} • $km km do mety • Lokata: ${resolution.stagePlacementRank}.'
            '${resolution.savedGcSeconds > 0 ? ' • Ocalono: +${resolution.savedGcSeconds.toStringAsFixed(0)} s GC' : ''}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.accentBlue,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            resolution.rulingExplanation,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (resolution.status == NeutralZoneVerdictStatus.pendingReview) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InteractiveActionChip(
                  label: 'Zatwierdź VAR (Neutralizuj)',
                  selected: false,
                  enabled: true,
                  accentColor: AppColors.statusSuccess,
                  onTap: onVerify,
                ),
                _InteractiveActionChip(
                  label: 'Odrzuć',
                  selected: false,
                  enabled: true,
                  accentColor: AppColors.crimsonAlert,
                  onTap: onReject,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Przycisk/chip z pełną obsługą stanów hover / active / disabled / focus.
class _InteractiveActionChip extends StatefulWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _InteractiveActionChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_InteractiveActionChip> createState() => _InteractiveActionChipState();
}

class _InteractiveActionChipState extends State<_InteractiveActionChip> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.enabled;
    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    if (!active) {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.45);
      borderColor = AppColors.cardBorder.withValues(alpha: 0.5);
      textColor = AppColors.textSecondary.withValues(alpha: 0.45);
    } else if (widget.selected) {
      bgColor = widget.accentColor.withValues(alpha: _pressed ? 0.30 : 0.22);
      borderColor = widget.accentColor;
      textColor = AppColors.textPrimary;
    } else if (_pressed) {
      bgColor = widget.accentColor.withValues(alpha: 0.18);
      borderColor = widget.accentColor;
      textColor = AppColors.textPrimary;
    } else if (_hovered || _focused) {
      bgColor = AppColors.surfaceLight;
      borderColor = widget.accentColor.withValues(alpha: 0.8);
      textColor = AppColors.textPrimary;
    } else {
      bgColor = AppColors.surfaceLight;
      borderColor = AppColors.cardBorder;
      textColor = AppColors.textSecondary;
    }

    return FocusableActionDetector(
      enabled: active,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          active ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: active ? (_) => setState(() => _pressed = true) : null,
        onTapUp: active ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: active ? () => setState(() => _pressed = false) : null,
        onTap: active ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused && active
                  ? AppColors.goldAccent
                  : borderColor,
              width: _focused && active ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
