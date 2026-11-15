// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../../models/equipment/complete_bike.dart';
import '../../models/equipment/equipment_wear_and_maintenance.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../models/team/bike_manufacturer_deal.dart';
import '../../models/team/cycling_team.dart';

/// Kategoria części zamiennej lub usługi serwisowej w raporcie budżetowym.
enum SparePartCategory {
  chain,
  cassette,
  frontTire,
  rearTire,
  bearings,
  brakePads,
  waxAndSealant;

  String get displayName {
    switch (this) {
      case SparePartCategory.chain:
        return 'Łańcuch 12s';
      case SparePartCategory.cassette:
        return 'Kaseta wyścigowa';
      case SparePartCategory.frontTire:
        return 'Opona przednia';
      case SparePartCategory.rearTire:
        return 'Opona tylna';
      case SparePartCategory.bearings:
        return 'Zestaw łożysk (suport, piasty, stery)';
      case SparePartCategory.brakePads:
        return 'Klocki hamulcowe';
      case SparePartCategory.waxAndSealant:
        return 'Wosk / mleczko tubeless';
    }
  }
}

/// Stan zużycia podzespołów nieobjętych bezpośrednio przez [EquipmentWearAndMaintenance]:
/// kasety napędowej oraz łożysk (suport, piasty kół, stery).
class CassetteAndBearingWear {
  /// Zużycie kasety napędowej [%] (0.0 = nowa, 100.0 = zużyta).
  final double cassetteWearPercent;

  /// Zużycie zestawu łożysk (suport, piasty, stery) [%] (0.0 = nowe, 100.0 = zatarte).
  final double bearingsWearPercent;

  /// Łączny przebieg kasety od ostatniej wymiany [km].
  final double cassetteMileageKm;

  /// Łączny przebieg łożysk od ostatniej wymiany [km].
  final double bearingsMileageKm;

  const CassetteAndBearingWear({
    required this.cassetteWearPercent,
    required this.bearingsWearPercent,
    required this.cassetteMileageKm,
    required this.bearingsMileageKm,
  });

  factory CassetteAndBearingWear.brandNew() {
    return const CassetteAndBearingWear(
      cassetteWearPercent: 0.0,
      bearingsWearPercent: 0.0,
      cassetteMileageKm: 0.0,
      bearingsMileageKm: 0.0,
    );
  }

  bool get needsCassetteReplacement => cassetteWearPercent >= 80.0;
  bool get needsBearingsReplacement => bearingsWearPercent >= 80.0;

  CassetteAndBearingWear copyWith({
    double? cassetteWearPercent,
    double? bearingsWearPercent,
    double? cassetteMileageKm,
    double? bearingsMileageKm,
  }) {
    return CassetteAndBearingWear(
      cassetteWearPercent: cassetteWearPercent ?? this.cassetteWearPercent,
      bearingsWearPercent: bearingsWearPercent ?? this.bearingsWearPercent,
      cassetteMileageKm: cassetteMileageKm ?? this.cassetteMileageKm,
      bearingsMileageKm: bearingsMileageKm ?? this.bearingsMileageKm,
    );
  }

  Map<String, dynamic> toJson() => {
        'cassetteWearPercent': cassetteWearPercent,
        'bearingsWearPercent': bearingsWearPercent,
        'cassetteMileageKm': cassetteMileageKm,
        'bearingsMileageKm': bearingsMileageKm,
      };

  factory CassetteAndBearingWear.fromJson(Map<String, dynamic> json) {
    return CassetteAndBearingWear(
      cassetteWearPercent:
          (json['cassetteWearPercent'] as num?)?.toDouble() ?? 0.0,
      bearingsWearPercent:
          (json['bearingsWearPercent'] as num?)?.toDouble() ?? 0.0,
      cassetteMileageKm:
          (json['cassetteMileageKm'] as num?)?.toDouble() ?? 0.0,
      bearingsMileageKm:
          (json['bearingsMileageKm'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Kontekst użycia pojedynczego roweru drużynowego na ukończonym etapie.
class RiderBikeStageUsage {
  final String riderId;
  final String riderName;
  final CompleteBike bike;
  final CassetteAndBearingWear cassetteAndBearingWear;
  final double averagePowerWatts;
  final double riderWeightKg;
  final bool didCrash;

  const RiderBikeStageUsage({
    required this.riderId,
    required this.riderName,
    required this.bike,
    CassetteAndBearingWear? cassetteAndBearingWear,
    this.averagePowerWatts = 265.0,
    this.riderWeightKg = 70.0,
    this.didCrash = false,
  }) : cassetteAndBearingWear =
            cassetteAndBearingWear ?? const CassetteAndBearingWear(
              cassetteWearPercent: 0.0,
              bearingsWearPercent: 0.0,
              cassetteMileageKm: 0.0,
              bearingsMileageKm: 0.0,
            );
}

/// Pojedyncza pozycja kosztowa wymienionej części zamiennej lub serwisu.
class ReplacedSparePartItem {
  final SparePartCategory category;
  final String reason;
  final int unitCostEur;

  const ReplacedSparePartItem({
    required this.category,
    required this.reason,
    required this.unitCostEur,
  });

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'reason': reason,
        'unitCostEur': unitCostEur,
      };

  factory ReplacedSparePartItem.fromJson(Map<String, dynamic> json) {
    return ReplacedSparePartItem(
      category: SparePartCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => SparePartCategory.chain,
      ),
      reason: json['reason'] as String? ?? '',
      unitCostEur: (json['unitCostEur'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Raport degradacji oraz kosztów części zamiennych dla jednego roweru po etapie.
class BikePostRaceDegradationReport {
  final String bikeId;
  final String bikeName;
  final String riderId;
  final String riderName;

  /// Przyrosty zużycia naliczone na tym etapie.
  final double chainElongationDeltaPercent;
  final double cassetteWearDeltaPercent;
  final double frontTireWearDeltaPercent;
  final double rearTireWearDeltaPercent;
  final double bearingsWearDeltaPercent;

  /// Stan końcowy po etapie i ewentualnej wymianie zużytych podzespołów.
  final CompleteBike updatedBike;
  final CassetteAndBearingWear updatedCassetteAndBearingWear;

  /// Lista części wymienionych / zużytych przez mechaników po etapie.
  final List<ReplacedSparePartItem> replacedParts;

  /// Uwagi techniczne mechaników.
  final List<String> mechanicNotes;

  /// Łączny koszt części zamiennych dla tego roweru [EUR].
  final int totalCostEur;

  const BikePostRaceDegradationReport({
    required this.bikeId,
    required this.bikeName,
    required this.riderId,
    required this.riderName,
    required this.chainElongationDeltaPercent,
    required this.cassetteWearDeltaPercent,
    required this.frontTireWearDeltaPercent,
    required this.rearTireWearDeltaPercent,
    required this.bearingsWearDeltaPercent,
    required this.updatedBike,
    required this.updatedCassetteAndBearingWear,
    required this.replacedParts,
    required this.mechanicNotes,
    required this.totalCostEur,
  });
}

/// Zbiorczy raport po etapie dla budżetu drużyny kolarskiej.
class PostRaceSparePartsBudgetReport {
  final String stageId;
  final int stageNumber;
  final String stageName;
  final double stageDistanceKm;
  final double cobblestoneDistanceKm;
  final bool isRaining;

  /// Mnożnik zużycia wynikający z opadów (3.0 w deszczu, 1.0 na sucho).
  final double rainWearMultiplier;

  /// Mnożnik zużycia wynikający z nawierzchni brukowej (do 3.0 przy 100% bruku).
  final double cobblestoneWearMultiplier;

  /// Łączny mnożnik zużycia dla etapu.
  final double combinedWearMultiplier;

  final List<BikePostRaceDegradationReport> bikeReports;

  final int chainsReplacedCount;
  final int cassettesReplacedCount;
  final int tiresReplacedCount;
  final int bearingsReplacedCount;
  final int brakePadsReplacedCount;

  final int chainsCostEur;
  final int cassettesCostEur;
  final int tiresCostEur;
  final int bearingsCostEur;
  final int consumablesAndBrakesCostEur;

  final int grossPartsCostEur;
  final int manufacturerDiscountEur;
  final int netTeamBudgetCostEur;

  final List<String> summaryLines;

  const PostRaceSparePartsBudgetReport({
    required this.stageId,
    required this.stageNumber,
    required this.stageName,
    required this.stageDistanceKm,
    required this.cobblestoneDistanceKm,
    required this.isRaining,
    required this.rainWearMultiplier,
    required this.cobblestoneWearMultiplier,
    required this.combinedWearMultiplier,
    required this.bikeReports,
    required this.chainsReplacedCount,
    required this.cassettesReplacedCount,
    required this.tiresReplacedCount,
    required this.bearingsReplacedCount,
    required this.brakePadsReplacedCount,
    required this.chainsCostEur,
    required this.cassettesCostEur,
    required this.tiresCostEur,
    required this.bearingsCostEur,
    required this.consumablesAndBrakesCostEur,
    required this.grossPartsCostEur,
    required this.manufacturerDiscountEur,
    required this.netTeamBudgetCostEur,
    required this.summaryLines,
  });

  /// Aktualizuje stan finansowy oraz flotę rowerową drużyny o koszty z raportu.
  CyclingTeam applyToTeam(CyclingTeam team) {
    final Map<String, CompleteBike> updatedById = {
      for (final report in bikeReports) report.bikeId: report.updatedBike,
    };
    final List<CompleteBike> updatedInventory = team.inventoryBikes
        .map((bike) => updatedById[bike.id] ?? bike)
        .toList(growable: false);

    return team.copyWith(
      cashBalanceEur: team.cashBalanceEur - netTeamBudgetCostEur,
      inventoryBikes: updatedInventory,
    );
  }
}

/// Serwis naliczający po każdym etapie realne zużycie łańcucha, kaset, opon
/// oraz łożysk (zwiększone 3-krotnie w deszczu i na bruku) i generujący raport
/// kosztów części zamiennych dla budżetu drużyny.
class PostRaceEquipmentDegradationService {
  const PostRaceEquipmentDegradationService();

  /// Mnożnik zużycia w warunkach deszczowych (3x).
  static const double rainMultiplierValue = 3.0;

  /// Mnożnik zużycia na nawierzchni brukowej (3x).
  static const double cobblestoneMultiplierValue = 3.0;

  /// Bazowy koszt wymiany zestawu łożysk (suport, piasty, stery) [EUR].
  static const int defaultBearingKitCostEur = 190;

  /// Bazowy koszt wymiany kompletu klocków hamulcowych na jeden zacisk [EUR].
  static const int defaultBrakePadCostEur = 32;

  /// Koszt serwisu woskowania łańcucha lub uzupełnienia mleczka tubeless [EUR].
  static const int waxServiceCostEur = 12;
  static const int sealantTopUpCostEur = 8;

  /// Ocenia degradację sprzętu wszystkich kolarzy po zakończonym etapie
  /// i generuje kompletny raport kosztów części zamiennych dla budżetu drużyny.
  PostRaceSparePartsBudgetReport processPostStageDegradation({
    required RaceStage stage,
    required List<RiderBikeStageUsage> usages,
    BikeManufacturerDeal? bikeDeal,
    int mechanicsLevel = 70,
    bool autoReplaceWornParts = true,
  }) {
    final double stageDistanceKm = math.max(0.0, stage.totalDistanceKm);
    final double cobbleDistanceKm = _calculateCobblestoneDistanceKm(stage);
    final double gravelDistanceKm = _calculateGravelDistanceKm(stage);
    final double descentElevationM = _calculateDescentElevationM(stage);
    final bool isRaining = _isStageRaining(stage);

    final double rainMultiplier = isRaining ? rainMultiplierValue : 1.0;
    final double cobbleMultiplier = _calculateSurfaceWearMultiplier(
      stageDistanceKm: stageDistanceKm,
      cobbleDistanceKm: cobbleDistanceKm,
      stageType: stage.stageType,
    );
    final double combinedMultiplier = rainMultiplier * cobbleMultiplier;

    // Wyższy poziom mechaników (1-100) pozwala minimalnie ograniczyć
    // marnotrawstwo przy montażu (maks. 8% oszczędności na zużyciu łożysk/kasety).
    final double mechanicCareFactor =
        1.0 - ((mechanicsLevel.clamp(1, 100) - 50) / 50.0) * 0.06;

    final List<BikePostRaceDegradationReport> bikeReports = [];

    int chainsReplaced = 0;
    int cassettesReplaced = 0;
    int tiresReplaced = 0;
    int bearingsReplaced = 0;
    int brakePadsReplaced = 0;

    int chainsCostEur = 0;
    int cassettesCostEur = 0;
    int tiresCostEur = 0;
    int bearingsCostEur = 0;
    int consumablesAndBrakesCostEur = 0;

    for (final usage in usages) {
      final report = _evaluateSingleBike(
        usage: usage,
        stageDistanceKm: stageDistanceKm,
        elevationGainM: stage.totalElevationGainM,
        descentElevationM: descentElevationM,
        cobbleDistanceKm: cobbleDistanceKm,
        gravelDistanceKm: gravelDistanceKm,
        isRaining: isRaining,
        rainMultiplier: rainMultiplier,
        cobbleMultiplier: cobbleMultiplier,
        combinedMultiplier: combinedMultiplier,
        mechanicCareFactor: mechanicCareFactor,
        autoReplaceWornParts: autoReplaceWornParts,
      );
      bikeReports.add(report);

      for (final part in report.replacedParts) {
        switch (part.category) {
          case SparePartCategory.chain:
            chainsReplaced++;
            chainsCostEur += part.unitCostEur;
          case SparePartCategory.cassette:
            cassettesReplaced++;
            cassettesCostEur += part.unitCostEur;
          case SparePartCategory.frontTire:
          case SparePartCategory.rearTire:
            tiresReplaced++;
            tiresCostEur += part.unitCostEur;
          case SparePartCategory.bearings:
            bearingsReplaced++;
            bearingsCostEur += part.unitCostEur;
          case SparePartCategory.brakePads:
            brakePadsReplaced++;
            consumablesAndBrakesCostEur += part.unitCostEur;
          case SparePartCategory.waxAndSealant:
            consumablesAndBrakesCostEur += part.unitCostEur;
        }
      }
    }

    final int grossCostEur = chainsCostEur +
        cassettesCostEur +
        tiresCostEur +
        bearingsCostEur +
        consumablesAndBrakesCostEur;

    final int discountEur = _calculateManufacturerDiscountEur(
      grossCostEur: grossCostEur,
      bikeDeal: bikeDeal,
    );
    final int netCostEur = math.max(0, grossCostEur - discountEur);

    final List<String> summaryLines = _buildSummaryLines(
      stage: stage,
      isRaining: isRaining,
      cobbleDistanceKm: cobbleDistanceKm,
      combinedMultiplier: combinedMultiplier,
      chainsReplaced: chainsReplaced,
      cassettesReplaced: cassettesReplaced,
      tiresReplaced: tiresReplaced,
      bearingsReplaced: bearingsReplaced,
      brakePadsReplaced: brakePadsReplaced,
      grossCostEur: grossCostEur,
      discountEur: discountEur,
      netCostEur: netCostEur,
    );

    return PostRaceSparePartsBudgetReport(
      stageId: stage.id,
      stageNumber: stage.stageNumber,
      stageName: stage.name,
      stageDistanceKm: stageDistanceKm,
      cobblestoneDistanceKm: cobbleDistanceKm,
      isRaining: isRaining,
      rainWearMultiplier: rainMultiplier,
      cobblestoneWearMultiplier: cobbleMultiplier,
      combinedWearMultiplier: combinedMultiplier,
      bikeReports: List<BikePostRaceDegradationReport>.unmodifiable(bikeReports),
      chainsReplacedCount: chainsReplaced,
      cassettesReplacedCount: cassettesReplaced,
      tiresReplacedCount: tiresReplaced,
      bearingsReplacedCount: bearingsReplaced,
      brakePadsReplacedCount: brakePadsReplaced,
      chainsCostEur: chainsCostEur,
      cassettesCostEur: cassettesCostEur,
      tiresCostEur: tiresCostEur,
      bearingsCostEur: bearingsCostEur,
      consumablesAndBrakesCostEur: consumablesAndBrakesCostEur,
      grossPartsCostEur: grossCostEur,
      manufacturerDiscountEur: discountEur,
      netTeamBudgetCostEur: netCostEur,
      summaryLines: List<String>.unmodifiable(summaryLines),
    );
  }

  BikePostRaceDegradationReport _evaluateSingleBike({
    required RiderBikeStageUsage usage,
    required double stageDistanceKm,
    required double elevationGainM,
    required double descentElevationM,
    required double cobbleDistanceKm,
    required double gravelDistanceKm,
    required bool isRaining,
    required double rainMultiplier,
    required double cobbleMultiplier,
    required double combinedMultiplier,
    required double mechanicCareFactor,
    required bool autoReplaceWornParts,
  }) {
    final EquipmentWearAndMaintenance initialWear = usage.bike.wear;
    final CassetteAndBearingWear initialAuxWear = usage.cassetteAndBearingWear;

    // 1. Bazowa symulacja zużycia z modelu EquipmentWearAndMaintenance
    final StageEquipmentWearResult baseResult = initialWear.simulateStageWear(
      stageDistanceKm: stageDistanceKm,
      elevationGainMeters: elevationGainM,
      descentElevationMeters: descentElevationM,
      isRaining: isRaining,
      roadWetness: isRaining ? 0.85 : 0.0,
      cobblestoneDistanceKm: cobbleDistanceKm,
      gravelDistanceKm: gravelDistanceKm,
      averageRiderPowerWatts: usage.averagePowerWatts,
      riderWeightKg: usage.riderWeightKg,
    );

    // 2. Zastosowanie 3-krotnego zużycia w deszczu i na bruku dla łańcucha i opon
    final double baseElongationDelta = math.max(
      0.0,
      baseResult.updatedChain.chainElongationPercent -
          initialWear.chain.chainElongationPercent,
    );
    final double crashFactor = usage.didCrash ? 1.5 : 1.0;

    // Jeśli baseResult nie skalował jeszcze pełnego 3x dla deszczu/bruku na
    // wyciągnięciu łańcucha i bieżniku opon, dokładamy precyzyjny mnożnik etapu.
    final double adjustedElongationDelta =
        baseElongationDelta * combinedMultiplier * crashFactor;
    final double finalElongation = (initialWear.chain.chainElongationPercent +
            adjustedElongationDelta)
        .clamp(0.0, 1.20);

    final ChainAndWaxCondition degradedChain = baseResult.updatedChain.copyWith(
      chainElongationPercent: finalElongation,
    );

    final double baseFrontTreadDelta = math.max(
      0.0,
      baseResult.updatedFrontTire.treadWearPercent -
          initialWear.frontTire.treadWearPercent,
    );
    final double baseRearTreadDelta = math.max(
      0.0,
      baseResult.updatedRearTire.treadWearPercent -
          initialWear.rearTire.treadWearPercent,
    );

    final double adjustedFrontTreadDelta =
        baseFrontTreadDelta * combinedMultiplier * crashFactor;
    final double adjustedRearTreadDelta =
        baseRearTreadDelta * combinedMultiplier * crashFactor;

    final TireWearCondition degradedFrontTire =
        baseResult.updatedFrontTire.copyWith(
      treadWearPercent: (initialWear.frontTire.treadWearPercent +
              adjustedFrontTreadDelta)
          .clamp(0.0, 100.0),
    );
    final TireWearCondition degradedRearTire =
        baseResult.updatedRearTire.copyWith(
      treadWearPercent:
          (initialWear.rearTire.treadWearPercent + adjustedRearTreadDelta)
              .clamp(0.0, 100.0),
    );

    // 3. Realne zużycie kasety (zależne od dystansu, mocy, stanu łańcucha, deszczu i bruku)
    final double powerFactor = (usage.averagePowerWatts / 260.0).clamp(0.75, 1.6);
    final double stretchedChainPenalty =
        degradedChain.chainElongationPercent >= 0.40 ? 1.65 : 1.0;
    final double cassetteWearDelta = ((stageDistanceKm / 100.0) *
            3.2 *
            powerFactor *
            stretchedChainPenalty *
            combinedMultiplier *
            mechanicCareFactor)
        .clamp(0.0, 100.0);

    // 4. Realne zużycie łożysk (suport, piasty, stery — wrażliwe na wodę i wstrząsy bruku)
    final double bearingsWearDelta = ((stageDistanceKm / 100.0) *
            2.6 *
            combinedMultiplier *
            crashFactor *
            mechanicCareFactor)
        .clamp(0.0, 100.0);

    EquipmentWearAndMaintenance workingWear = EquipmentWearAndMaintenance(
      chain: degradedChain,
      frontTire: degradedFrontTire,
      rearTire: degradedRearTire,
      frontBrake: baseResult.updatedFrontBrake,
      rearBrake: baseResult.updatedRearBrake,
      electronicBatteryPercent: math.max(
        10.0,
        initialWear.electronicBatteryPercent - (stageDistanceKm / 100.0) * 6.0,
      ),
    );

    CassetteAndBearingWear workingAuxWear = initialAuxWear.copyWith(
      cassetteWearPercent:
          (initialAuxWear.cassetteWearPercent + cassetteWearDelta)
              .clamp(0.0, 100.0),
      bearingsWearPercent:
          (initialAuxWear.bearingsWearPercent + bearingsWearDelta)
              .clamp(0.0, 100.0),
      cassetteMileageKm: initialAuxWear.cassetteMileageKm + stageDistanceKm,
      bearingsMileageKm: initialAuxWear.bearingsMileageKm + stageDistanceKm,
    );

    // 5. Wymiana zużytych części i wycena dla budżetu drużyny
    final List<ReplacedSparePartItem> replacedParts = [];
    final List<String> notes = List<String>.from(baseResult.mechanicNotes);

    final int chainPriceEur = _estimateChainPriceEur(usage.bike);
    final int cassettePriceEur = _estimateCassettePriceEur(usage.bike);
    final int tirePriceEur = _estimateTirePriceEur(usage.bike);

    if (autoReplaceWornParts) {
      if (workingWear.chain.needsReplacement) {
        replacedParts.add(
          ReplacedSparePartItem(
            category: SparePartCategory.chain,
            reason:
                'Wyciągnięcie łańcucha ${workingWear.chain.chainElongationPercent.toStringAsFixed(2)}% >= 0.50%',
            unitCostEur: chainPriceEur,
          ),
        );
        workingWear = workingWear.replaceChain(
          lubricant: isRaining
              ? DrivetrainLubricantType.hotMeltWaxAllWeather
              : DrivetrainLubricantType.hotMeltWaxStandard,
        );
      } else if (workingWear.chain.needsWaxing) {
        replacedParts.add(
          const ReplacedSparePartItem(
            category: SparePartCategory.waxAndSealant,
            reason: 'Ponowne woskowanie łańcucha na gorąco',
            unitCostEur: waxServiceCostEur,
          ),
        );
        workingWear = workingWear.performHotMeltWaxing(
          allWeatherFormula: isRaining,
        );
      }

      if (workingAuxWear.needsCassetteReplacement) {
        replacedParts.add(
          ReplacedSparePartItem(
            category: SparePartCategory.cassette,
            reason:
                'Zużycie zębatek kasety ${workingAuxWear.cassetteWearPercent.toStringAsFixed(1)}% >= 80%',
            unitCostEur: cassettePriceEur,
          ),
        );
        workingAuxWear = workingAuxWear.copyWith(
          cassetteWearPercent: 0.0,
          cassetteMileageKm: 0.0,
        );
      }

      if (workingWear.frontTire.needsReplacement || usage.didCrash) {
        replacedParts.add(
          ReplacedSparePartItem(
            category: SparePartCategory.frontTire,
            reason: usage.didCrash
                ? 'Wymiana prewencyjna po kraksie'
                : 'Zużycie przedniej opony (${workingWear.frontTire.treadWearPercent.toStringAsFixed(1)}% / ${workingWear.frontTire.microCutsCount} nacięć)',
            unitCostEur: tirePriceEur,
          ),
        );
        workingWear = workingWear.replaceTires(front: true, rear: false);
      }

      if (workingWear.rearTire.needsReplacement || usage.didCrash) {
        replacedParts.add(
          ReplacedSparePartItem(
            category: SparePartCategory.rearTire,
            reason: usage.didCrash
                ? 'Wymiana prewencyjna po kraksie'
                : 'Zużycie tylnej opony (${workingWear.rearTire.treadWearPercent.toStringAsFixed(1)}% / ${workingWear.rearTire.microCutsCount} nacięć)',
            unitCostEur: tirePriceEur,
          ),
        );
        workingWear = workingWear.replaceTires(front: false, rear: true);
      } else if (workingWear.frontTire.needsSealantTopUp ||
          workingWear.rearTire.needsSealantTopUp) {
        replacedParts.add(
          const ReplacedSparePartItem(
            category: SparePartCategory.waxAndSealant,
            reason: 'Uzupełnienie płynu uszczelniającego Tubeless',
            unitCostEur: sealantTopUpCostEur,
          ),
        );
        workingWear = workingWear.topUpTubelessSealant();
      }

      if (workingAuxWear.needsBearingsReplacement) {
        replacedParts.add(
          ReplacedSparePartItem(
            category: SparePartCategory.bearings,
            reason:
                'Zużycie łożysk ${workingAuxWear.bearingsWearPercent.toStringAsFixed(1)}% >= 80%',
            unitCostEur: defaultBearingKitCostEur,
          ),
        );
        workingAuxWear = workingAuxWear.copyWith(
          bearingsWearPercent: 0.0,
          bearingsMileageKm: 0.0,
        );
      }

      if (workingWear.frontBrake.needsPadReplacement) {
        replacedParts.add(
          const ReplacedSparePartItem(
            category: SparePartCategory.brakePads,
            reason: 'Zużycie przednich klocków hamulcowych',
            unitCostEur: defaultBrakePadCostEur,
          ),
        );
        workingWear = workingWear.replaceBrakePads(
          compound: isRaining
              ? BrakePadCompound.metallicSintered
              : workingWear.frontBrake.padCompound,
          front: true,
          rear: false,
        );
      }
      if (workingWear.rearBrake.needsPadReplacement) {
        replacedParts.add(
          const ReplacedSparePartItem(
            category: SparePartCategory.brakePads,
            reason: 'Zużycie tylnych klocków hamulcowych',
            unitCostEur: defaultBrakePadCostEur,
          ),
        );
        workingWear = workingWear.replaceBrakePads(
          compound: isRaining
              ? BrakePadCompound.metallicSintered
              : workingWear.rearBrake.padCompound,
          front: false,
          rear: true,
        );
      }
    }

    final int bikeTotalCost = replacedParts.fold<int>(
      0,
      (sum, item) => sum + item.unitCostEur,
    );

    final CompleteBike updatedBike = usage.bike.applyWear(workingWear);

    return BikePostRaceDegradationReport(
      bikeId: usage.bike.id,
      bikeName: usage.bike.name,
      riderId: usage.riderId,
      riderName: usage.riderName,
      chainElongationDeltaPercent: adjustedElongationDelta,
      cassetteWearDeltaPercent: cassetteWearDelta,
      frontTireWearDeltaPercent: adjustedFrontTreadDelta,
      rearTireWearDeltaPercent: adjustedRearTreadDelta,
      bearingsWearDeltaPercent: bearingsWearDelta,
      updatedBike: updatedBike,
      updatedCassetteAndBearingWear: workingAuxWear,
      replacedParts: List<ReplacedSparePartItem>.unmodifiable(replacedParts),
      mechanicNotes: List<String>.unmodifiable(notes),
      totalCostEur: bikeTotalCost,
    );
  }

  double _calculateCobblestoneDistanceKm(RaceStage stage) {
    double sum = 0.0;
    for (final segment in stage.segments) {
      if (segment.isCobblestone) {
        sum += math.max(0.0, segment.lengthKm);
      }
    }
    return sum;
  }

  double _calculateGravelDistanceKm(RaceStage stage) {
    double sum = 0.0;
    for (final segment in stage.segments) {
      if (segment.surfaceType == SegmentSurfaceType.gravelStrade) {
        sum += math.max(0.0, segment.lengthKm);
      }
    }
    return sum;
  }

  double _calculateDescentElevationM(RaceStage stage) {
    double descent = 0.0;
    for (final segment in stage.segments) {
      if (segment.endElevationM < segment.startElevationM) {
        descent += segment.startElevationM - segment.endElevationM;
      }
    }
    return descent;
  }

  bool _isStageRaining(RaceStage stage) {
    return stage.weatherCondition == WeatherCondition.lightRain ||
        stage.weatherCondition == WeatherCondition.heavyStorm;
  }

  double _calculateSurfaceWearMultiplier({
    required double stageDistanceKm,
    required double cobbleDistanceKm,
    required StageType stageType,
  }) {
    if (stageDistanceKm <= 0.0) {
      return stageType == StageType.cobbleClassic
          ? cobblestoneMultiplierValue
          : 1.0;
    }
    if (cobbleDistanceKm <= 0.0) {
      // Jeśli etap ma typ cobbleClassic bez oznaczonych segmentów brukowych,
      // przyjmujemy pełny mnożnik brukowy.
      return stageType == StageType.cobbleClassic
          ? cobblestoneMultiplierValue
          : 1.0;
    }
    final double cobbleFraction =
        (cobbleDistanceKm / stageDistanceKm).clamp(0.0, 1.0);
    return 1.0 + (cobblestoneMultiplierValue - 1.0) * cobbleFraction;
  }

  int _estimateChainPriceEur(CompleteBike bike) {
    final int derived = (bike.groupset.priceEur * 0.02).round();
    return derived.clamp(45, 95);
  }

  int _estimateCassettePriceEur(CompleteBike bike) {
    final int derived = (bike.groupset.priceEur * 0.08).round();
    return derived.clamp(160, 420);
  }

  int _estimateTirePriceEur(CompleteBike bike) {
    if (bike.tire.priceEur > 0) {
      return bike.tire.priceEur.clamp(45, 160);
    }
    return 85;
  }

  int _calculateManufacturerDiscountEur({
    required int grossCostEur,
    required BikeManufacturerDeal? bikeDeal,
  }) {
    if (bikeDeal == null || grossCostEur <= 0) {
      return 0;
    }
    // Prestiż sponsora technicznego (1-5) obniża koszty części zamiennych (5%-25%)
    final double discountRate =
        (bikeDeal.prestigeLevel.clamp(1, 5) * 0.05).clamp(0.0, 0.25);
    return (grossCostEur * discountRate).round();
  }

  List<String> _buildSummaryLines({
    required RaceStage stage,
    required bool isRaining,
    required double cobbleDistanceKm,
    required double combinedMultiplier,
    required int chainsReplaced,
    required int cassettesReplaced,
    required int tiresReplaced,
    required int bearingsReplaced,
    required int brakePadsReplaced,
    required int grossCostEur,
    required int discountEur,
    required int netCostEur,
  }) {
    final lines = <String>[
      'Etap #${stage.stageNumber} (${stage.name}): dystans ${stage.totalDistanceKm.toStringAsFixed(1)} km, '
          'warunki: ${isRaining ? 'deszcz (3x zużycie)' : 'sucho'}, '
          'bruk: ${cobbleDistanceKm.toStringAsFixed(1)} km (mnożnik łączny ${combinedMultiplier.toStringAsFixed(2)}x).',
      'Wymienione podzespoły: łańcuchy: $chainsReplaced, kasety: $cassettesReplaced, '
          'opony: $tiresReplaced, łożyska: $bearingsReplaced, klocki hamulcowe: $brakePadsReplaced.',
      'Koszt brutto części: $grossCostEur EUR | Rabat sponsora technicznego: -$discountEur EUR | '
          'Obciążenie budżetu drużyny: $netCostEur EUR.',
    ];
    return lines;
  }
}
