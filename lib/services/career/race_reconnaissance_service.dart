// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import '../../models/career/staff_member.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../models/race/tour_race.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_skills.dart';

/// Typ i charakterystyka terenu misji rekonesansowej (Race Reconnaissance Type).
enum ReconnaissanceType {
  /// Sektory brukowane (Paryż-Roubaix, Ronde van Vlaanderen)
  cobbledSectors,

  /// Wysokogórskie przełęcze i finały na szczytach HC (Alpy, Pireneje, Dolomity)
  alpineMountainPasses,

  /// Skrajnie techniczne i niebezpieczne zjazdy (agrafki, zła nawierzchnia)
  technicalDescent,

  /// Trasa jazdy indywidualnej na czas (ITT - techniczne zakręty i pacing)
  timeTrialCourse,

  /// Białe drogi szutrowe (Strade Bianche, gravelowe etapy Tourów)
  gravelWhiteRoads;

  String get displayName {
    switch (this) {
      case ReconnaissanceType.cobbledSectors:
        return 'Sektory Brukowe (Pavé & Bruki Flandrii)';
      case ReconnaissanceType.alpineMountainPasses:
        return 'Wysokogórskie Przełęcze & Meta na Szczycie (HC)';
      case ReconnaissanceType.technicalDescent:
        return 'Techniczne Zjazdy & Agrafki';
      case ReconnaissanceType.timeTrialCourse:
        return 'Trasa Jazdy na Czas (ITT)';
      case ReconnaissanceType.gravelWhiteRoads:
        return 'Białe Drogi Szutrowe (Strade Bianche)';
    }
  }

  String get description {
    switch (this) {
      case ReconnaissanceType.cobbledSectors:
        return 'Precyzyjny objazd sektorów bruku: nauka jazdy koroną drogi, weryfikacja ubytków w kostce oraz dobór optymalnego ciśnienia opon.';
      case ReconnaissanceType.alpineMountainPasses:
        return 'Poznanie kluczowych stromizn podjazdów HC, punktów zmiany rytmu oraz ocena wiatru na odsłoniętych przełęczach powyżej 2000m n.p.m.';
      case ReconnaissanceType.technicalDescent:
        return 'Szczegółowa mapa zakrętów, wyznaczenie idealnej linii zjazdu, punktów dohamowania i identyfikacja zanieczyszczeń nawierzchni.';
      case ReconnaissanceType.timeTrialCourse:
        return 'Testowanie przełożeń (np. blat 56T/58T), ocena nawrotów pod kątem pozycji aero i optymalizacja pacingu mocy.';
      case ReconnaissanceType.gravelWhiteRoads:
        return 'Inspekcja twardości szutru, przyczepności w wirażach oraz analiza ryzyka poślizgu na zjazdach ze żwirem.';
    }
  }

  String toJson() => name;

  static ReconnaissanceType fromJson(String value) {
    return ReconnaissanceType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ReconnaissanceType.alpineMountainPasses,
    );
  }
}

/// Zestaw bonusów wyścigowych przyznawanych kolarzowi na etapie objętym rekonesansem.
class ReconnaissanceStageBonus {
  /// Bonus do prowadzenia roweru w peletonie i na trudnych nawierzchniach (+10)
  final int bikeHandlingBonus;

  /// Bonus do techniki i znajomości zakrętów na zjazdach (+10)
  final int descendingBonus;

  /// Przewaga punktowa w walce o pozycję przed wjazdem na kluczowy podjazd lub sektor bruku (+15)
  final int positioningAdvantageScore;

  /// Mnożnik ryzyka upadku na zjeździe i bruku (np. 0.55 = -45% ryzyka kraksy)
  final double crashRiskMultiplier;

  /// Mnożnik ryzyka przebicia opony na brukach dzięki znajomości równej korony drogi (np. 0.70 = -30%)
  final double punctureRiskMultiplier;

  /// Szansa na zyskanie przewagi czasowej na zjeździe (atak zjazdowy a'la Mohorič/Pidcock)
  final double descentAttackSuccessBonus;

  const ReconnaissanceStageBonus({
    this.bikeHandlingBonus = 10,
    this.descendingBonus = 10,
    this.positioningAdvantageScore = 15,
    this.crashRiskMultiplier = 0.55,
    this.punctureRiskMultiplier = 0.70,
    this.descentAttackSuccessBonus = 0.20,
  });

  Map<String, dynamic> toJson() => {
        'bikeHandlingBonus': bikeHandlingBonus,
        'descendingBonus': descendingBonus,
        'positioningAdvantageScore': positioningAdvantageScore,
        'crashRiskMultiplier': crashRiskMultiplier,
        'punctureRiskMultiplier': punctureRiskMultiplier,
        'descentAttackSuccessBonus': descentAttackSuccessBonus,
      };

  factory ReconnaissanceStageBonus.fromJson(Map<String, dynamic> json) {
    return ReconnaissanceStageBonus(
      bikeHandlingBonus: (json['bikeHandlingBonus'] as num?)?.toInt() ?? 10,
      descendingBonus: (json['descendingBonus'] as num?)?.toInt() ?? 10,
      positioningAdvantageScore:
          (json['positioningAdvantageScore'] as num?)?.toInt() ?? 15,
      crashRiskMultiplier:
          (json['crashRiskMultiplier'] as num?)?.toDouble() ?? 0.55,
      punctureRiskMultiplier:
          (json['punctureRiskMultiplier'] as num?)?.toDouble() ?? 0.70,
      descentAttackSuccessBonus:
          (json['descentAttackSuccessBonus'] as num?)?.toDouble() ?? 0.20,
    );
  }
}

/// Misja rekonesansowa zrealizowana przez drużynę na konkretnym etapie.
class ReconnaissanceMission {
  final String id;
  final String raceId;
  final String raceName;
  final int stageNumber;
  final String stageName;
  final ReconnaissanceType reconType;
  final List<String> participantRiderIds;
  final String? directorId;
  final String? mechanicId;
  final DateTime dateConducted;
  final int costEur;
  final double fatigueAtlAdded;
  final double moraleBoost;
  final String targetSectorOrClimbName;
  final List<String> keyTacticalFindings;
  final double? recommendedTirePressureBar;
  final ReconnaissanceStageBonus bonus;

  const ReconnaissanceMission({
    required this.id,
    required this.raceId,
    required this.raceName,
    required this.stageNumber,
    required this.stageName,
    required this.reconType,
    required this.participantRiderIds,
    this.directorId,
    this.mechanicId,
    required this.dateConducted,
    required this.costEur,
    this.fatigueAtlAdded = 14.0,
    this.moraleBoost = 6.0,
    required this.targetSectorOrClimbName,
    required this.keyTacticalFindings,
    this.recommendedTirePressureBar,
    this.bonus = const ReconnaissanceStageBonus(),
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'raceId': raceId,
        'raceName': raceName,
        'stageNumber': stageNumber,
        'stageName': stageName,
        'reconType': reconType.toJson(),
        'participantRiderIds': participantRiderIds,
        'directorId': directorId,
        'mechanicId': mechanicId,
        'dateConducted': dateConducted.toIso8601String(),
        'costEur': costEur,
        'fatigueAtlAdded': fatigueAtlAdded,
        'moraleBoost': moraleBoost,
        'targetSectorOrClimbName': targetSectorOrClimbName,
        'keyTacticalFindings': keyTacticalFindings,
        'recommendedTirePressureBar': recommendedTirePressureBar,
        'bonus': bonus.toJson(),
      };

  factory ReconnaissanceMission.fromJson(Map<String, dynamic> json) {
    return ReconnaissanceMission(
      id: json['id'] as String,
      raceId: json['raceId'] as String,
      raceName: json['raceName'] as String,
      stageNumber: (json['stageNumber'] as num).toInt(),
      stageName: json['stageName'] as String,
      reconType: ReconnaissanceType.fromJson(json['reconType'] as String),
      participantRiderIds: (json['participantRiderIds'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      directorId: json['directorId'] as String?,
      mechanicId: json['mechanicId'] as String?,
      dateConducted: DateTime.parse(json['dateConducted'] as String),
      costEur: (json['costEur'] as num).toInt(),
      fatigueAtlAdded: (json['fatigueAtlAdded'] as num?)?.toDouble() ?? 14.0,
      moraleBoost: (json['moraleBoost'] as num?)?.toDouble() ?? 6.0,
      targetSectorOrClimbName: json['targetSectorOrClimbName'] as String,
      keyTacticalFindings: (json['keyTacticalFindings'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      recommendedTirePressureBar:
          (json['recommendedTirePressureBar'] as num?)?.toDouble(),
      bonus: json['bonus'] != null
          ? ReconnaissanceStageBonus.fromJson(
              json['bonus'] as Map<String, dynamic>)
          : const ReconnaissanceStageBonus(),
    );
  }
}

/// Rekomendacja etapu wyścigu jako priorytetowego kandydata do objazdu.
class ReconCandidateStage {
  final TourRace race;
  final RaceStage stage;
  final ReconnaissanceType reconType;
  final int priorityScore; // 1 - 100
  final String rationale;
  final int estimatedCostEur;
  final List<String> targetKeySegments;

  const ReconCandidateStage({
    required this.race,
    required this.stage,
    required this.reconType,
    required this.priorityScore,
    required this.rationale,
    required this.estimatedCostEur,
    required this.targetKeySegments,
  });
}

/// Rezultat przeprowadzenia misji rekonesansowej.
class ReconnaissanceExecutionResult {
  final ReconnaissanceMission mission;
  final List<Rider> updatedParticipants;
  final int totalCostEur;
  final String directorSummaryReport;
  final String mechanicTireReport;

  const ReconnaissanceExecutionResult({
    required this.mission,
    required this.updatedParticipants,
    required this.totalCostEur,
    required this.directorSummaryReport,
    required this.mechanicTireReport,
  });
}

/// Główny serwis i mechanika rekonesansu kluczowych etapów wyścigów
/// (Race Reconnaissance Service).
class RaceReconnaissanceService {
  RaceReconnaissanceService._();

  /// Analizuje wyścig i wyłania najważniejsze etapy wymagające rekonesansu
  /// (posortowane malejąco wg wskaźnika priorytetu).
  static List<ReconCandidateStage> identifyHighPriorityStages(TourRace race) {
    final candidates = <ReconCandidateStage>[];

    for (final stage in race.stages) {
      int score = 0;
      ReconnaissanceType type = ReconnaissanceType.alpineMountainPasses;
      String rationale = '';
      final keySegments = <String>[];

      // 1. Etapy brukowane (Paris-Roubaix, etapy pavé w Grand Tourach)
      final hasCobbles = stage.stageType == StageType.cobbleClassic ||
          stage.segments.any((s) =>
              s.surfaceType == SegmentSurfaceType.cobblestonesSector3 ||
              s.surfaceType == SegmentSurfaceType.cobblestonesSector4 ||
              s.surfaceType == SegmentSurfaceType.cobblestonesSector5);

      if (hasCobbles) {
        type = ReconnaissanceType.cobbledSectors;
        score = 98;
        rationale = 'Kluczowe sektory brukowane (Trouée d\'Arenberg, Carrefour de l\'Arbre). '
            'Objazd pozwala poznać równą koronę drogi i zredukować ryzyko defektu.';
        for (final s in stage.segments) {
          if (s.surfaceType == SegmentSurfaceType.cobblestonesSector4 ||
              s.surfaceType == SegmentSurfaceType.cobblestonesSector5) {
            keySegments.add('Sektor km ${s.startKm.toStringAsFixed(1)}: ${s.surfaceType.name}');
          }
        }
        if (keySegments.isEmpty) {
          keySegments.add('Sektory 4-gwiazdkowe i 5-gwiazdkowe');
        }
      }
      // 2. Etapy wysokogórskie i mety na szczycie (HC)
      else if (stage.stageType == StageType.highMountain ||
          stage.stageType == StageType.summitFinish) {
        type = ReconnaissanceType.alpineMountainPasses;
        score = 92;
        rationale = 'Królewski etap górski. Precyzyjne rozpoznanie kątów nachylenia '
            'oraz wiatru na przełęczach powyżej 1800m n.p.m.';
        for (final s in stage.segments) {
          if (s.sprintOrKomClassification == SegmentClassification.horsCategorie ||
              s.sprintOrKomClassification == SegmentClassification.cat1) {
            keySegments.add('Podjazd HC km ${s.startKm.toStringAsFixed(1)}: ${s.lengthKm.toStringAsFixed(1)} km');
          }
        }
        if (keySegments.isEmpty) {
          keySegments.add('Finałowa wspinaczka pod metę');
        }
      }
      // 3. Jazda indywidualna na czas (ITT)
      else if (stage.stageType == StageType.individualTimeTrial) {
        type = ReconnaissanceType.timeTrialCourse;
        score = 85;
        rationale = 'Czasówka decydująca o klasyfikacji generalnej. '
            'Wyznaczenie optymalnej linii w zakrętach w pozycji aero i dobór blatów.';
        keySegments.add('Punkty nawrotu i techniczne szykany');
      }
      // 4. Szutry (Strade Bianche)
      else if (stage.segments.any((s) => s.surfaceType == SegmentSurfaceType.gravelStrade)) {
        type = ReconnaissanceType.gravelWhiteRoads;
        score = 88;
        rationale = 'Białe drogi szutrowe z luźnym żwirem. '
            'Ocena przyczepności na zjazdach i punktów zwężeń drogi.';
        keySegments.add('Sektory szutrowe z ostrymi zjazdami');
      }
      // 5. Etapy z bardzo technicznymi zjazdami
      else if (stage.segments.any((s) => s.technicalDifficulty >= 70.0)) {
        type = ReconnaissanceType.technicalDescent;
        score = 78;
        rationale = 'Niebezpieczne sekwencje agrafek na zjazdach. '
            'Znajomość punktów hamowania chroni przed upadkiem i pozwala na zysk sekund.';
        keySegments.add('Agrafki i techniczne zjazdy');
      }

      if (score >= 70) {
        final estimatedCost = _calculateEstimatedMissionCost(stage);
        candidates.add(ReconCandidateStage(
          race: race,
          stage: stage,
          reconType: type,
          priorityScore: score,
          rationale: rationale,
          estimatedCostEur: estimatedCost,
          targetKeySegments: keySegments,
        ));
      }
    }

    candidates.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    return candidates;
  }

  /// Wylicza szacunkowy koszt logistyczny wyprawy rekonesansowej
  static int _calculateEstimatedMissionCost(RaceStage stage) {
    // Koszt: transport autokarem/busem, wóz techniczny, hotele, wyżywienie, mechanicy
    int baseCost = 4500;
    if (stage.stageType == StageType.cobbleClassic) {
      baseCost += 2500; // Dodatkowe koła, opony i paliwo na brukach Północy
    } else if (stage.stageType == StageType.highMountain) {
      baseCost += 3000; // Logistyka w odległych dolinach alpejskich
    }
    return baseCost;
  }

  /// Przeprowadza misję rekonesansową dla wybranej grupy kolarzy (3-7 zawodników).
  static ReconnaissanceExecutionResult executeReconnaissance({
    required TourRace race,
    required RaceStage stage,
    required List<Rider> participantRiders,
    SportsDirector? director,
    HeadMechanic? mechanic,
    required DateTime dateConducted,
    int? customCostEur,
  }) {
    if (participantRiders.isEmpty) {
      throw ArgumentError('Misja rekonesansowa wymaga co najmniej 1 kolarza (zalecane 5 kolarzy).');
    }

    // Wyznaczenie typu rekonesansu
    final ReconnaissanceType reconType;
    if (stage.stageType == StageType.cobbleClassic ||
        stage.segments.any((s) => s.surfaceType.name.contains('cobble'))) {
      reconType = ReconnaissanceType.cobbledSectors;
    } else if (stage.stageType == StageType.highMountain ||
        stage.stageType == StageType.summitFinish) {
      reconType = ReconnaissanceType.alpineMountainPasses;
    } else if (stage.stageType == StageType.individualTimeTrial) {
      reconType = ReconnaissanceType.timeTrialCourse;
    } else if (stage.segments.any((s) => s.surfaceType == SegmentSurfaceType.gravelStrade)) {
      reconType = ReconnaissanceType.gravelWhiteRoads;
    } else {
      reconType = ReconnaissanceType.technicalDescent;
    }

    // Koszt misji
    final costEur = customCostEur ?? _calculateEstimatedMissionCost(stage);

    // Nazwy kluczowych obiektów
    final String targetName;
    final findings = <String>[];
    double? recPressure;

    switch (reconType) {
      case ReconnaissanceType.cobbledSectors:
        targetName = 'Sektory bruku (Arenberg & Carrefour de l\'Arbre)';
        recPressure = 3.8;
        findings.addAll([
          'Zidentyfikowano zdradliwe zapadnięte kostki na wjeździe w Trouée d\'Arenberg.',
          'Rekomendowana jazda grzbietem bruku (korona drogi) – redukcja wstrząsów o 35%.',
          'Zalecane ciśnienie w oponach tubeless 30mm: 3.8 bar przód / 4.0 bar tył.',
          'Zwężenie drogi 300m przed sektorem – kluczowe wprowadzenie lidera w pierwszych 10 pozycjach.',
        ]);
        break;

      case ReconnaissanceType.alpineMountainPasses:
        targetName = 'Przełęcze alpejskie & Finałowa wspinaczka HC';
        recPressure = 5.2;
        findings.addAll([
          'Rozpoznano zdradliwy odcinek 12% na 4. kilometrze finałowej góry.',
          'Silny przeciwny wiatr w odkrytej dolinie powyżej granicy lasu (1900m n.p.m.).',
          'Na zjeździe z przełęczy: 3 ślepe agrafki z wybojami na krawędzi asfaltu.',
          'Wyznaczono optymalne punkty ataku i bezpieczne strefy poboru bidonów.',
        ]);
        break;

      case ReconnaissanceType.technicalDescent:
        targetName = 'Sekwencja technicznych zjazdów i agrafek';
        recPressure = 5.0;
        findings.addAll([
          'Oznaczono niebezpieczny luźny żwir na wyjściu z 5. wirażu.',
          'Wymagana wczesna linia dohamowania na mokrych odcinkach w lesie.',
          'Możliwość zyskania 8-12 sekund przewagi poprzez agresywne ścięcie zakrętu 8.',
        ]);
        break;

      case ReconnaissanceType.timeTrialCourse:
        targetName = 'Trasa ITT z technicznymi nawrotami';
        recPressure = 5.5;
        findings.addAll([
          'Dobór przedniego blatu: 58T na zjazdy z wiatrem w plecy.',
          'Trzy ostre nawroty 90° wymagające płynnego wyjścia z pozycji aero.',
          'Oszacowano docelowy pacing mocy: 410W na płaskim, 460W na 800-metrowej hopce.',
        ]);
        break;

      case ReconnaissanceType.gravelWhiteRoads:
        targetName = 'Białe szutry Strade Bianche';
        recPressure = 4.2;
        findings.addAll([
          'Luźna warstwa kamieni na zjeździe Monte Sante Marie – ryzyko poślizgu koła.',
          'Zalecane opony z delikatnym bieżnikiem i ciśnieniem 4.2 bar.',
          'Konieczność ataku pozycji przed wjazdem w szuter z powodu tumanów kurzu.',
        ]);
        break;
    }

    // Aktualizacja kolarzy: lekki wzrost zmęczenia ATL (+12) i zastrzyk morale (+6)
    final updatedRiders = participantRiders.map((r) {
      final curHealth = r.health;
      final newAtl = (curHealth.acuteTrainingLoad + 12.0).clamp(10.0, 130.0);
      final newCtl = (curHealth.chronicTrainingLoad + 3.0).clamp(10.0, 120.0);
      return r.copyWith(
        health: curHealth.copyWith(
          acuteTrainingLoad: newAtl,
          chronicTrainingLoad: newCtl,
        ),
      );
    }).toList();

    // Raport Dyrektora Sportowego
    final dsName = director?.fullName ?? 'Sztab Sportowy';
    final dirReport = '$dsName: „Kolarze odbyli pełny objazd etapu ${stage.stageNumber} ($targetName). '
        'Cała 5-tka zna każdy zakręt, zjazd i zwężenie. Zapewni nam to decydującą przewagę taktyczną '
        'i pozycję z przodu peletonu.”';

    // Raport Mechanika
    final mechName = mechanic?.fullName ?? 'Główny Mechanik';
    final mechReport = '$mechName: „Przetestowaliśmy różne warianty ogumienia. '
        'Rekomendowane ciśnienie $recPressure bar. Ryzyko defektu mechanicznego zredukowane.”';

    final mission = ReconnaissanceMission(
      id: 'recon_${race.id}_st${stage.stageNumber}_${dateConducted.millisecondsSinceEpoch}',
      raceId: race.id,
      raceName: race.name,
      stageNumber: stage.stageNumber,
      stageName: stage.name,
      reconType: reconType,
      participantRiderIds: participantRiders.map((r) => r.id).toList(),
      directorId: director?.id,
      mechanicId: mechanic?.id,
      dateConducted: dateConducted,
      costEur: costEur,
      fatigueAtlAdded: 12.0,
      moraleBoost: 6.0,
      targetSectorOrClimbName: targetName,
      keyTacticalFindings: findings,
      recommendedTirePressureBar: recPressure,
      bonus: const ReconnaissanceStageBonus(
        bikeHandlingBonus: 10,
        descendingBonus: 10,
        positioningAdvantageScore: 15,
        crashRiskMultiplier: 0.55,
        punctureRiskMultiplier: 0.70,
        descentAttackSuccessBonus: 0.20,
      ),
    );

    return ReconnaissanceExecutionResult(
      mission: mission,
      updatedParticipants: updatedRiders,
      totalCostEur: costEur,
      directorSummaryReport: dirReport,
      mechanicTireReport: mechReport,
    );
  }

  /// Sprawdza, czy dany kolarz odbył rekonesans konkretnego etapu wyścigu.
  static bool isRiderReconCompleted({
    required List<ReconnaissanceMission> completedMissions,
    required String riderId,
    required String raceId,
    required int stageNumber,
  }) {
    for (final mission in completedMissions) {
      if (mission.raceId == raceId &&
          mission.stageNumber == stageNumber &&
          mission.participantRiderIds.contains(riderId)) {
        return true;
      }
    }
    return false;
  }

  /// Zwraca obiekt [Rider] z zaaplikowanymi bonusami rekonesansu (+10 bikeHandling, +10 descending)
  /// dla konkretnego etapu, jeśli kolarz brał udział w objeździe trasy.
  static Rider applyReconBonusToRider({
    required Rider rider,
    required List<ReconnaissanceMission> completedMissions,
    required String raceId,
    required int stageNumber,
  }) {
    final hasRecon = isRiderReconCompleted(
      completedMissions: completedMissions,
      riderId: rider.id,
      raceId: raceId,
      stageNumber: stageNumber,
    );

    if (!hasRecon) return rider;

    final curSkills = rider.skills;
    final boostedSkills = curSkills.copyWith(
      bikeHandling: math.min(99, curSkills.bikeHandling + 10),
      descending: math.min(99, curSkills.descending + 10),
    );

    return rider.copyWith(skills: boostedSkills);
  }

  /// Zwraca umiejętności kolarza [RiderSkills] z doliczonym bonusem +10 do bikeHandling i descending.
  static RiderSkills getEffectiveRiderSkills({
    required Rider rider,
    required List<ReconnaissanceMission> completedMissions,
    required String raceId,
    required int stageNumber,
  }) {
    final hasRecon = isRiderReconCompleted(
      completedMissions: completedMissions,
      riderId: rider.id,
      raceId: raceId,
      stageNumber: stageNumber,
    );

    if (!hasRecon) return rider.skills;

    return rider.skills.copyWith(
      bikeHandling: math.min(99, rider.skills.bikeHandling + 10),
      descending: math.min(99, rider.skills.descending + 10),
    );
  }

  /// Wylicza przewagę pozycjonowania przed wjazdem na kluczowy podjazd lub sektor bruku.
  /// Kolarz po rekonesansie zyskuje +15 do +25 punktów do walki na łokcie o czołowe miejsca.
  static double calculatePositioningAdvantage({
    required Rider rider,
    required List<ReconnaissanceMission> completedMissions,
    required String raceId,
    required int stageNumber,
  }) {
    final hasRecon = isRiderReconCompleted(
      completedMissions: completedMissions,
      riderId: rider.id,
      raceId: raceId,
      stageNumber: stageNumber,
    );

    if (!hasRecon) return 0.0;

    // Bazowy bonus +15 pkt, powiększony o zmysł wyścigowy kolarza (raceIq)
    return 15.0 + ((rider.skills.raceIq / 100.0) * 8.0);
  }

  /// Wylicza mnożnik ryzyka upadku (kraksy) na niebezpiecznych zjazdach i bruku.
  /// Kolarz po rekonesansie ma o ~45% niższe ryzyko upadku (mnożnik 0.55).
  static double calculateCrashRiskMultiplier({
    required String riderId,
    required List<ReconnaissanceMission> completedMissions,
    required String raceId,
    required int stageNumber,
  }) {
    final hasRecon = isRiderReconCompleted(
      completedMissions: completedMissions,
      riderId: riderId,
      raceId: raceId,
      stageNumber: stageNumber,
    );

    return hasRecon ? 0.55 : 1.0;
  }

  /// Wylicza mnożnik ryzyka przebicia dętki/opony na sektorze brukowym.
  /// Kolarz znający równą koronę drogi obniża ryzyko uszkodzenia koła o 30% (mnożnik 0.70).
  static double calculatePunctureRiskMultiplier({
    required String riderId,
    required List<ReconnaissanceMission> completedMissions,
    required String raceId,
    required int stageNumber,
  }) {
    final hasRecon = isRiderReconCompleted(
      completedMissions: completedMissions,
      riderId: riderId,
      raceId: raceId,
      stageNumber: stageNumber,
    );

    return hasRecon ? 0.70 : 1.0;
  }
}
