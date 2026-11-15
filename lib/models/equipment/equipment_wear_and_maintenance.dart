// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

/// Rodzaje formulacji smarów do napędu łańcuchowego
enum DrivetrainLubricantType {
  /// Wosk na gorąco - standardowa parafina z dodatkiem dwusiarczku wolframu (WS2) / grafenu.
  /// Najniższe tarcie na sucho (3.5 W), ale na deszczowym etapie powyżej 120-150 km
  /// ulega wypłukaniu, jeśli mechanicy nie zastosują mieszanki hydrofobowej.
  hotMeltWaxStandard,

  /// Wosk na gorąco - formuła All-Weather / Wet Race z dodatkiem wosku tungowego
  /// i polimerów hydrofobowych. Niezwykle odporna na ulewny deszcz (do 260 km).
  hotMeltWaxAllWeather,

  /// Wosk w płynie (Drip Wax / emulsja ceramiczno-woskowa).
  /// Łatwa aplikacja bez ściągania łańcucha, średnia odporność na deszcz (~90 km).
  dripWaxEmulsion,

  /// Syntetyczny olej gęsty na mokre warunki (Wet Lube).
  /// Nie wypłukuje się w deszczu, ale generuje wyższe straty tarcia (~7.2 W)
  /// i na suchych etapach zbiera brud i piasek.
  syntheticWetLube,

  /// Syntetyczny olej lekki na suche warunki (Dry Lube PTFE).
  /// Błyskawicznie zmywany przy pierwszym deszczu i kałużach (<40 km).
  syntheticDryLube,

  /// Całkowity brak smaru - łańcuch odtłuszczony / wypłukany przez deszcz.
  /// Skrajne tarcie (11-14 W), pisk, ryzyko zerwania pod obciążeniem.
  strippedNoLube;

  String get displayName {
    switch (this) {
      case DrivetrainLubricantType.hotMeltWaxStandard:
        return 'Wosk na Gorąco (Standard WS2 / Grafen)';
      case DrivetrainLubricantType.hotMeltWaxAllWeather:
        return 'Wosk na Gorąco (All-Weather Hydrofobowy)';
      case DrivetrainLubricantType.dripWaxEmulsion:
        return 'Wosk w Płynie (Emulsja Ceramiczna)';
      case DrivetrainLubricantType.syntheticWetLube:
        return 'Olej Syntetyczny na Deszcz (Wet Lube)';
      case DrivetrainLubricantType.syntheticDryLube:
        return 'Olej Lekki na Sucho (Dry PTFE)';
      case DrivetrainLubricantType.strippedNoLube:
        return 'Łańcuch Suchy / Wypłukany (Brak Smaru)';
    }
  }

  /// Bazowe straty tarcia nowego, nasmarowanego łańcucha [Waty] przy 250W mocy kolarza
  double get baselineFrictionLossWatts {
    switch (this) {
      case DrivetrainLubricantType.hotMeltWaxStandard:
        return 3.5;
      case DrivetrainLubricantType.hotMeltWaxAllWeather:
        return 3.9;
      case DrivetrainLubricantType.dripWaxEmulsion:
        return 4.8;
      case DrivetrainLubricantType.syntheticWetLube:
        return 7.2;
      case DrivetrainLubricantType.syntheticDryLube:
        return 5.8;
      case DrivetrainLubricantType.strippedNoLube:
        return 12.5;
    }
  }

  /// Odporność filmu smarnego na ulewny deszcz [km]
  double get wetWashoutThresholdKm {
    switch (this) {
      case DrivetrainLubricantType.hotMeltWaxStandard:
        return 140.0; // Wypłukuje się powyżej 140-150 km w deszczu
      case DrivetrainLubricantType.hotMeltWaxAllWeather:
        return 270.0; // Wytrzymuje nawet najdłuższy deszczowy etap Grand Touru
      case DrivetrainLubricantType.dripWaxEmulsion:
        return 95.0;
      case DrivetrainLubricantType.syntheticWetLube:
        return 320.0; // Bardzo lepki, nie wypłukuje się
      case DrivetrainLubricantType.syntheticDryLube:
        return 35.0;
      case DrivetrainLubricantType.strippedNoLube:
        return 0.0;
    }
  }
}

/// Mieszanka okładzin klocków hamulcowych
enum BrakePadCompound {
  /// Żywiczne / Organiczne (Resin).
  /// Ciche, doskonała modulacja na sucho. W deszczu i błocie na alpejskich zjazdach
  /// ścierają się błyskawicznie (nawet 40-60% na jednym etapie).
  organicResin,

  /// Metaliczne / Spiekane (Sintered / Metallic).
  /// Wyjątkowo odporne na przegrzanie i wodę. Idealne na deszczowe etapy alpejskie,
  /// lecz głośniejsze na sucho i mocniej obciążające tarczę.
  metallicSintered,

  /// Półmetaliczne / Kompozytowe (Semi-Metallic Race).
  /// Zbalansowany kompromis WorldTour na zmienne warunki.
  semiMetallicRace;

  String get displayName {
    switch (this) {
      case BrakePadCompound.organicResin:
        return 'Żywiczne (Organiczne Resin)';
      case BrakePadCompound.metallicSintered:
        return 'Spiekane (Metaliczne Sintered)';
      case BrakePadCompound.semiMetallicRace:
        return 'Półmetaliczne (Semi-Metallic Race)';
    }
  }
}

/// Szczegółowy stan łańcucha wyścigowego i warstwy wosku / smaru
class ChainAndWaxCondition {
  /// Rodzaj zastosowanego smaru / formuły wosku
  final DrivetrainLubricantType lubricantType;

  /// Pozostały film smarujący (100.0% = świeży, 0.0% = całkowicie suchy / wypłukany)
  final double waxFilmRemainingPercent;

  /// Wyciągnięcie łańcucha w procentach (np. 0.0% nowy, 0.5% limit wymiany 12s, 0.75%+ zużyty)
  final double chainElongationPercent;

  /// Całkowity przebieg łańcucha od nowości [km]
  final double totalChainMileageKm;

  /// Przebieg od ostatniego wygotowania w wosku lub aplikacji smaru [km]
  final double mileageSinceLastWaxKm;

  /// Czy film smarny uległ wypłukaniu przez wodę
  final bool isWashedOut;

  const ChainAndWaxCondition({
    required this.lubricantType,
    required this.waxFilmRemainingPercent,
    required this.chainElongationPercent,
    required this.totalChainMileageKm,
    required this.mileageSinceLastWaxKm,
    required this.isWashedOut,
  });

  /// Fabrycznie nowy, świeżo wygotowany w wosku na gorąco łańcuch
  factory ChainAndWaxCondition.brandNewHotMeltWax({
    bool allWeatherFormula = false,
  }) {
    return ChainAndWaxCondition(
      lubricantType: allWeatherFormula
          ? DrivetrainLubricantType.hotMeltWaxAllWeather
          : DrivetrainLubricantType.hotMeltWaxStandard,
      waxFilmRemainingPercent: 100.0,
      chainElongationPercent: 0.05,
      totalChainMileageKm: 0.0,
      mileageSinceLastWaxKm: 0.0,
      isWashedOut: false,
    );
  }

  /// Czy łańcuch kwalifikuje się do natychmiastowej wymiany (wyciągnięcie >= 0.50%)
  bool get needsReplacement => chainElongationPercent >= 0.50;

  /// Czy łańcuch kwalifikuje się do ponownego wygotowania w wosku (film < 25% lub wypłukany)
  bool get needsWaxing => waxFilmRemainingPercent < 25.0 || isWashedOut;

  /// Rzeczywiste straty tarcia napędu w Watach przy obciążeniu 250W
  double get effectiveFrictionLossWatts {
    if (isWashedOut || waxFilmRemainingPercent <= 0.0) {
      return DrivetrainLubricantType.strippedNoLube.baselineFrictionLossWatts +
          (chainElongationPercent * 4.0);
    }

    final double baseLoss = lubricantType.baselineFrictionLossWatts;
    // W miarę zużywania filmu wosku tarcie rośnie o 1.5 - 3.5 W
    final double filmDegradationPenalty =
        (1.0 - (waxFilmRemainingPercent / 100.0)) * 2.8;
    // Wyciągnięty łańcuch dokłada dodatkowe straty tarcia
    final double wearPenalty = (chainElongationPercent / 0.50) * 1.6;

    return (baseLoss + filmDegradationPenalty + wearPenalty).clamp(3.2, 14.5);
  }

  /// Ryzyko zerwania lub spadnięcia łańcucha pod obciążeniem (0.0 - 1.0)
  double get chainSnapRiskFactor {
    double risk = 0.01;
    if (chainElongationPercent >= 0.50) {
      risk += (chainElongationPercent - 0.50) * 0.4;
    }
    if (isWashedOut) {
      risk += 0.05;
    }
    return risk.clamp(0.005, 0.45);
  }

  ChainAndWaxCondition copyWith({
    DrivetrainLubricantType? lubricantType,
    double? waxFilmRemainingPercent,
    double? chainElongationPercent,
    double? totalChainMileageKm,
    double? mileageSinceLastWaxKm,
    bool? isWashedOut,
  }) {
    return ChainAndWaxCondition(
      lubricantType: lubricantType ?? this.lubricantType,
      waxFilmRemainingPercent:
          waxFilmRemainingPercent ?? this.waxFilmRemainingPercent,
      chainElongationPercent:
          chainElongationPercent ?? this.chainElongationPercent,
      totalChainMileageKm: totalChainMileageKm ?? this.totalChainMileageKm,
      mileageSinceLastWaxKm:
          mileageSinceLastWaxKm ?? this.mileageSinceLastWaxKm,
      isWashedOut: isWashedOut ?? this.isWashedOut,
    );
  }

  Map<String, dynamic> toJson() => {
        'lubricantType': lubricantType.name,
        'waxFilmRemainingPercent': waxFilmRemainingPercent,
        'chainElongationPercent': chainElongationPercent,
        'totalChainMileageKm': totalChainMileageKm,
        'mileageSinceLastWaxKm': mileageSinceLastWaxKm,
        'isWashedOut': isWashedOut,
      };

  factory ChainAndWaxCondition.fromJson(Map<String, dynamic> json) {
    return ChainAndWaxCondition(
      lubricantType: DrivetrainLubricantType.values.firstWhere(
        (e) => e.name == json['lubricantType'],
        orElse: () => DrivetrainLubricantType.hotMeltWaxStandard,
      ),
      waxFilmRemainingPercent:
          (json['waxFilmRemainingPercent'] as num?)?.toDouble() ?? 100.0,
      chainElongationPercent:
          (json['chainElongationPercent'] as num?)?.toDouble() ?? 0.05,
      totalChainMileageKm:
          (json['totalChainMileageKm'] as num?)?.toDouble() ?? 0.0,
      mileageSinceLastWaxKm:
          (json['mileageSinceLastWaxKm'] as num?)?.toDouble() ?? 0.0,
      isWashedOut: json['isWashedOut'] as bool? ?? false,
    );
  }
}

/// Szczegółowy stan pojedynczej opony wyścigowej (bieżnik, nacięcia, mleczko tubeless)
class TireWearCondition {
  /// Stopień zużycia bieżnika (0.0% = nowa, 100.0% = całkowicie starta)
  final double treadWearPercent;

  /// Liczba mikronacięć kordu i bieżnika po bruku i szutrach
  final int microCutsCount;

  /// Objętość płynu uszczelniającego Tubeless [ml] (0 do 45 ml)
  final double tubelessSealantVolumeMl;

  /// Świeżość mleczka tubeless (100.0% = świeże płynne, 0.0% = zaschnięte/lateksowy kożuch)
  final double tubelessSealantFreshnessPercent;

  /// Całkowity przebieg opony [km]
  final double totalMileageKm;

  const TireWearCondition({
    required this.treadWearPercent,
    required this.microCutsCount,
    required this.tubelessSealantVolumeMl,
    required this.tubelessSealantFreshnessPercent,
    required this.totalMileageKm,
  });

  /// Nowa opona z pełnym bieżnikiem i świeżym mleczkiem
  factory TireWearCondition.brandNew({bool isTubeless = true}) {
    return TireWearCondition(
      treadWearPercent: 0.0,
      microCutsCount: 0,
      tubelessSealantVolumeMl: isTubeless ? 38.0 : 0.0,
      tubelessSealantFreshnessPercent: 100.0,
      totalMileageKm: 0.0,
    );
  }

  /// Mnożnik podatności na przebicie opony (1.0 = baza nowej opony, wyżej = większe ryzyko)
  double get punctureRiskMultiplier {
    // 1. Wpływ zużycia bieżnika (starta guma ułatwia wbicie szkła/drutu)
    final double treadFactor = 1.0 + (treadWearPercent / 100.0) * 1.5;

    // 2. Mikronacięcia kordu (każde nacięcie po bruku osłabia szkielet opony)
    final double microCutsFactor = 1.0 + (microCutsCount * 0.12);

    // 3. Ochrona mleczka Tubeless
    double sealantProtection = 1.0;
    if (tubelessSealantVolumeMl > 15.0 && tubelessSealantFreshnessPercent > 40.0) {
      sealantProtection = 0.42; // Świeże mleczko natychmiast uszczelnia 90% nacięć
    } else if (tubelessSealantVolumeMl <= 5.0 || tubelessSealantFreshnessPercent < 20.0) {
      sealantProtection = 1.25; // Zaschnięty lateks nie działa, a dodaje oporu
    }

    return (treadFactor * microCutsFactor * sealantProtection).clamp(0.35, 4.5);
  }

  /// Czy opona wymaga wymiany przed kolejnym etapem
  bool get needsReplacement =>
      treadWearPercent >= 80.0 || microCutsCount >= 6;

  /// Czy mleczko uszczelniające wymaga dolania
  bool get needsSealantTopUp =>
      tubelessSealantVolumeMl < 18.0 || tubelessSealantFreshnessPercent < 35.0;

  TireWearCondition copyWith({
    double? treadWearPercent,
    int? microCutsCount,
    double? tubelessSealantVolumeMl,
    double? tubelessSealantFreshnessPercent,
    double? totalMileageKm,
  }) {
    return TireWearCondition(
      treadWearPercent: treadWearPercent ?? this.treadWearPercent,
      microCutsCount: microCutsCount ?? this.microCutsCount,
      tubelessSealantVolumeMl:
          tubelessSealantVolumeMl ?? this.tubelessSealantVolumeMl,
      tubelessSealantFreshnessPercent:
          tubelessSealantFreshnessPercent ?? this.tubelessSealantFreshnessPercent,
      totalMileageKm: totalMileageKm ?? this.totalMileageKm,
    );
  }

  Map<String, dynamic> toJson() => {
        'treadWearPercent': treadWearPercent,
        'microCutsCount': microCutsCount,
        'tubelessSealantVolumeMl': tubelessSealantVolumeMl,
        'tubelessSealantFreshnessPercent': tubelessSealantFreshnessPercent,
        'totalMileageKm': totalMileageKm,
      };

  factory TireWearCondition.fromJson(Map<String, dynamic> json) {
    return TireWearCondition(
      treadWearPercent: (json['treadWearPercent'] as num?)?.toDouble() ?? 0.0,
      microCutsCount: (json['microCutsCount'] as num?)?.toInt() ?? 0,
      tubelessSealantVolumeMl:
          (json['tubelessSealantVolumeMl'] as num?)?.toDouble() ?? 35.0,
      tubelessSealantFreshnessPercent:
          (json['tubelessSealantFreshnessPercent'] as num?)?.toDouble() ?? 100.0,
      totalMileageKm: (json['totalMileageKm'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Szczegółowy stan hamulców tarczowych (klocki, tarcza, zeszklenie, płyn)
class BrakeWearCondition {
  /// Mieszanka klocków hamulcowych
  final BrakePadCompound padCompound;

  /// Zużycie okładzin klocków (0.0% = nowe 4mm, 100.0% = starte do blachy)
  final double padWearPercent;

  /// Zużycie tarczy hamulcowej (0.0% = nowa 1.8mm, 100.0% = poniżej limitu 1.5mm)
  final double rotorWearPercent;

  /// Zeszklenie tarczy i klocków po przegrzaniu na zjazdach alpejskich (0.0% - 100.0%)
  final double rotorGlazingPercent;

  /// Kondycja płynu hydraulicznego / odporność na zagotowanie (100% = świeży, 0% = napowietrzony)
  final double hydraulicFluidConditionPercent;

  const BrakeWearCondition({
    required this.padCompound,
    required this.padWearPercent,
    required this.rotorWearPercent,
    required this.rotorGlazingPercent,
    required this.hydraulicFluidConditionPercent,
  });

  /// Nowe hamulce z zadaną mieszanką klocków
  factory BrakeWearCondition.brandNew({
    BrakePadCompound compound = BrakePadCompound.organicResin,
  }) {
    return BrakeWearCondition(
      padCompound: compound,
      padWearPercent: 0.0,
      rotorWearPercent: 0.0,
      rotorGlazingPercent: 0.0,
      hydraulicFluidConditionPercent: 100.0,
    );
  }

  /// Efektywność hamowania (1.0 = pełna siła, <0.70 = wydłużona droga hamowania w peletonie)
  double get brakingEfficiencyIndex {
    double eff = 1.0;

    // Klocki zużyte powyżej 80%
    if (padWearPercent > 80.0) {
      eff -= ((padWearPercent - 80.0) / 20.0) * 0.40;
    }

    // Zeszklenie (Glazing) po stromych zjazdach
    eff -= (rotorGlazingPercent / 100.0) * 0.35;

    // Przegrzany płyn hydrauliczny
    if (hydraulicFluidConditionPercent < 50.0) {
      eff -= ((50.0 - hydraulicFluidConditionPercent) / 50.0) * 0.25;
    }

    return eff.clamp(0.25, 1.0);
  }

  /// Czy klocki wymagają natychmiastowej wymiany (zużycie >= 80% lub zeszklenie >= 75%)
  bool get needsPadReplacement =>
      padWearPercent >= 80.0 || rotorGlazingPercent >= 75.0;

  /// Czy tarcza wymaga wymiany (zużycie >= 85%)
  bool get needsRotorReplacement => rotorWearPercent >= 85.0;

  BrakeWearCondition copyWith({
    BrakePadCompound? padCompound,
    double? padWearPercent,
    double? rotorWearPercent,
    double? rotorGlazingPercent,
    double? hydraulicFluidConditionPercent,
  }) {
    return BrakeWearCondition(
      padCompound: padCompound ?? this.padCompound,
      padWearPercent: padWearPercent ?? this.padWearPercent,
      rotorWearPercent: rotorWearPercent ?? this.rotorWearPercent,
      rotorGlazingPercent: rotorGlazingPercent ?? this.rotorGlazingPercent,
      hydraulicFluidConditionPercent:
          hydraulicFluidConditionPercent ?? this.hydraulicFluidConditionPercent,
    );
  }

  Map<String, dynamic> toJson() => {
        'padCompound': padCompound.name,
        'padWearPercent': padWearPercent,
        'rotorWearPercent': rotorWearPercent,
        'rotorGlazingPercent': rotorGlazingPercent,
        'hydraulicFluidConditionPercent': hydraulicFluidConditionPercent,
      };

  factory BrakeWearCondition.fromJson(Map<String, dynamic> json) {
    return BrakeWearCondition(
      padCompound: BrakePadCompound.values.firstWhere(
        (e) => e.name == json['padCompound'],
        orElse: () => BrakePadCompound.organicResin,
      ),
      padWearPercent: (json['padWearPercent'] as num?)?.toDouble() ?? 0.0,
      rotorWearPercent: (json['rotorWearPercent'] as num?)?.toDouble() ?? 0.0,
      rotorGlazingPercent:
          (json['rotorGlazingPercent'] as num?)?.toDouble() ?? 0.0,
      hydraulicFluidConditionPercent:
          (json['hydraulicFluidConditionPercent'] as num?)?.toDouble() ?? 100.0,
    );
  }
}

/// Wynik symulacji zużycia sprzętu podczas etapu (Raport Serwisowy po etapie)
class StageEquipmentWearResult {
  /// Stan napędu po etapie
  final ChainAndWaxCondition updatedChain;

  /// Stan przedniej opony po etapie
  final TireWearCondition updatedFrontTire;

  /// Stan tylnej opony po etapie
  final TireWearCondition updatedRearTire;

  /// Stan przedniego hamulca po etapie
  final BrakeWearCondition updatedFrontBrake;

  /// Stan tylnego hamulca po etapie
  final BrakeWearCondition updatedRearBrake;

  /// Czy wosk łańcucha uległ wypłukaniu w trakcie etapu
  final bool didWaxWashoutOccur;

  /// Przybliżony kilometr trasy, na którym doszło do wypłukania wosku [km] (null jeśli brak)
  final double? washoutDistanceKm;

  /// Nowe mikronacięcia opon powstałe na tym etapie
  final int newFrontTireMicroCuts;
  final int newRearTireMicroCuts;

  /// Procentowe zużycie klocków hamulcowych na tym etapie [%]
  final double frontPadWearDeltaPercent;
  final double rearPadWearDeltaPercent;

  /// Średnie dodatkowe straty mocy napędu na finiszu z powodu degradacji smaru [W]
  final double drivetrainLossWattsDelta;

  /// Lista uwag i zaleceń mechaników przed kolejnym startem
  final List<String> mechanicNotes;

  const StageEquipmentWearResult({
    required this.updatedChain,
    required this.updatedFrontTire,
    required this.updatedRearTire,
    required this.updatedFrontBrake,
    required this.updatedRearBrake,
    required this.didWaxWashoutOccur,
    required this.washoutDistanceKm,
    required this.newFrontTireMicroCuts,
    required this.newRearTireMicroCuts,
    required this.frontPadWearDeltaPercent,
    required this.rearPadWearDeltaPercent,
    required this.drivetrainLossWattsDelta,
    required this.mechanicNotes,
  });
}

/// Kompletny model stanu technicznego, zużycia i serwisu roweru wyścigowego
/// w trakcie sezonu kolarskiego (Equipment Wear & Maintenance).
class EquipmentWearAndMaintenance {
  /// Stan łańcucha i woskowania
  final ChainAndWaxCondition chain;

  /// Stan przedniej opony
  final TireWearCondition frontTire;

  /// Stan tylnej opony (zużywa się szybciej z racji napędu i docisku)
  final TireWearCondition rearTire;

  /// Stan przedniego hamulca tarczowego
  final BrakeWearCondition frontBrake;

  /// Stan tylnego hamulca tarczowego
  final BrakeWearCondition rearBrake;

  /// Stan baterii i okablowania osprzętu elektronicznego Di2/AXS (0.0% - 100.0%)
  final double electronicBatteryPercent;

  const EquipmentWearAndMaintenance({
    required this.chain,
    required this.frontTire,
    required this.rearTire,
    required this.frontBrake,
    required this.rearBrake,
    required this.electronicBatteryPercent,
  });

  /// Fabrycznie nowy, świeżo przygotowany przez mechaników sprzęt
  factory EquipmentWearAndMaintenance.brandNew({
    bool allWeatherWax = false,
    BrakePadCompound padCompound = BrakePadCompound.organicResin,
  }) {
    return EquipmentWearAndMaintenance(
      chain: ChainAndWaxCondition.brandNewHotMeltWax(
          allWeatherFormula: allWeatherWax),
      frontTire: TireWearCondition.brandNew(isTubeless: true),
      rearTire: TireWearCondition.brandNew(isTubeless: true),
      frontBrake: BrakeWearCondition.brandNew(compound: padCompound),
      rearBrake: BrakeWearCondition.brandNew(compound: padCompound),
      electronicBatteryPercent: 100.0,
    );
  }

  // ===========================================================================
  // SYMULACJA ZUŻYCIA SPRZĘTU NA ETAPIE (SIMULATE STAGE WEAR)
  // ===========================================================================

  /// Symuluje zużycie podzespołów roweru w trakcie zadanego etapu wyścigowego.
  ///
  /// Uwzględnia:
  /// - Wypłukiwanie wosku na deszczowych etapach powyżej 120-150 km dla standardowej parafiny
  ///   vs ochronę formuły All-Weather,
  /// - Mikronacięcia opon na brukach (np. Roubaix) i szutrach (Strade Bianche),
  /// - Ekstremalne zużycie klocków hamulcowych i tarcz na deszczowych zjazdach alpejskich.
  StageEquipmentWearResult simulateStageWear({
    required double stageDistanceKm,
    required double elevationGainMeters,
    required double descentElevationMeters,
    required bool isRaining,
    double roadWetness = 0.0, // 0.0 (sucho) do 1.0 (ulewa i stojąca woda)
    double cobblestoneDistanceKm = 0.0,
    double gravelDistanceKm = 0.0,
    double averageRiderPowerWatts = 260.0,
    double riderWeightKg = 70.0,
  }) {
    final notes = <String>[];

    // -------------------------------------------------------------------------
    // 1. SYMULACJA ŁAŃCUCHA I WOSKU (HOT MELT WAX VS RAIN)
    // -------------------------------------------------------------------------
    double newWaxFilm = chain.waxFilmRemainingPercent;
    bool newIsWashedOut = chain.isWashedOut;
    double? washoutDist;

    // Normalne zużycie wosku na sucho: ~10% na 100 km
    final double dryWearRate = (stageDistanceKm / 100.0) * 10.0;
    newWaxFilm -= dryWearRate;

    // Mechanika deszczu: wypłukiwanie warstwy wosku
    if (isRaining || roadWetness > 0.25) {
      final double wetFactor = roadWetness > 0 ? roadWetness : 0.8;
      final double thresholdKm = chain.lubricantType.wetWashoutThresholdKm;

      // Jeśli etap jest dłuższy niż odporność smaru na deszcz
      if (stageDistanceKm >= thresholdKm) {
        newIsWashedOut = true;
        newWaxFilm = 0.0;
        washoutDist = thresholdKm;

        if (chain.lubricantType == DrivetrainLubricantType.hotMeltWaxStandard) {
          notes.add(
            'UWAGA: Standardowy wosk na gorąco (Hot Melt Wax) uległ wypłukaniu '
            'na ${thresholdKm.round()}. km etapu z powodu ulewnego deszczu! '
            'Na kolejny mokry etap zastosuj formułę All-Weather Hydrophobic.',
          );
        } else {
          notes.add(
            'Film smarny łańcucha uległ zmyciu przez deszcz na ${thresholdKm.round()}. km!',
          );
        }
      } else {
        // Stopniowe wymywanie filmu
        final double washoutPercent =
            (stageDistanceKm / thresholdKm) * 75.0 * wetFactor;
        newWaxFilm -= washoutPercent;
      }
    }

    newWaxFilm = newWaxFilm.clamp(0.0, 100.0);
    if (newWaxFilm <= 0.0) newIsWashedOut = true;

    // Wyciągnięcie łańcucha (rośnie szybciej pod dużą mocą i przy braku smaru)
    double elongationDelta = (stageDistanceKm / 1000.0) * 0.035;
    if (averageRiderPowerWatts > 320.0) elongationDelta *= 1.4;
    if (newIsWashedOut) elongationDelta *= 2.8; // Zgrzytający suchy łańcuch wyciąga się błyskawicznie!

    final double newElongation =
        (chain.chainElongationPercent + elongationDelta).clamp(0.0, 1.20);
    final double newTotalChainKm = chain.totalChainMileageKm + stageDistanceKm;
    final double newWaxDistKm = chain.mileageSinceLastWaxKm + stageDistanceKm;

    final updatedChain = chain.copyWith(
      waxFilmRemainingPercent: newWaxFilm,
      chainElongationPercent: newElongation,
      totalChainMileageKm: newTotalChainKm,
      mileageSinceLastWaxKm: newWaxDistKm,
      isWashedOut: newIsWashedOut,
    );

    final double drivetrainDeltaWatts =
        updatedChain.effectiveFrictionLossWatts - chain.effectiveFrictionLossWatts;

    // -------------------------------------------------------------------------
    // 2. SYMULACJA OPON I MIKRONACIĘĆ (BRUK, SZUTRY, BIEŻNIK)
    // -------------------------------------------------------------------------
    // Bieżnik: przednia opona zużywa się wolniej, tylna szybciej
    final double frontTreadDelta = (stageDistanceKm / 100.0) * 2.2;
    final double rearTreadDelta = (stageDistanceKm / 100.0) * 3.6; // Napęd + docisk masy

    // Mikronacięcia od bruku i szutru
    int newFrontCuts = 0;
    int newRearCuts = 0;
    if (cobblestoneDistanceKm > 0.0) {
      // Bruk generuje ostre uderzenia i nacięcia kordu
      newFrontCuts += (cobblestoneDistanceKm * 0.16).round();
      newRearCuts += (cobblestoneDistanceKm * 0.22).round();
    }
    if (gravelDistanceKm > 0.0) {
      newFrontCuts += (gravelDistanceKm * 0.08).round();
      newRearCuts += (gravelDistanceKm * 0.12).round();
    }

    // Parowanie i praca mleczka tubeless
    final double sealantLoss = (stageDistanceKm / 100.0) * 1.5;
    final double freshnessLoss = (stageDistanceKm / 100.0) * 2.0;

    final updatedFrontTire = frontTire.copyWith(
      treadWearPercent:
          (frontTire.treadWearPercent + frontTreadDelta).clamp(0.0, 100.0),
      microCutsCount: frontTire.microCutsCount + newFrontCuts,
      tubelessSealantVolumeMl:
          math.max(0.0, frontTire.tubelessSealantVolumeMl - sealantLoss),
      tubelessSealantFreshnessPercent: math.max(
          0.0, frontTire.tubelessSealantFreshnessPercent - freshnessLoss),
      totalMileageKm: frontTire.totalMileageKm + stageDistanceKm,
    );

    final updatedRearTire = rearTire.copyWith(
      treadWearPercent:
          (rearTire.treadWearPercent + rearTreadDelta).clamp(0.0, 100.0),
      microCutsCount: rearTire.microCutsCount + newRearCuts,
      tubelessSealantVolumeMl:
          math.max(0.0, rearTire.tubelessSealantVolumeMl - sealantLoss),
      tubelessSealantFreshnessPercent: math.max(
          0.0, rearTire.tubelessSealantFreshnessPercent - freshnessLoss),
      totalMileageKm: rearTire.totalMileageKm + stageDistanceKm,
    );

    if (newRearCuts > 0) {
      notes.add(
        'Sektory brukowe/szutrowe spowodowały $newRearCuts mikronacięć na tylnej oponie! '
        'Ryzyko przebicia wzrosło o ${(updatedRearTire.punctureRiskMultiplier * 10).round()}%.',
      );
    }

    // -------------------------------------------------------------------------
    // 3. SYMULACJA HAMULCÓW NA ALPEJSKICH ZJAZDACH W DESZCZU
    // -------------------------------------------------------------------------
    // Bazowe zużycie klocków: zależy od przewyższenia zjazdów [m] i masy
    final double descentFactor = (descentElevationMeters / 1000.0);
    double padWearBase = descentFactor * 2.5;

    // Deszcz i piasek w górach drastycznie przyspieszają ścieranie klocków!
    if (isRaining || roadWetness > 0.25) {
      if (frontBrake.padCompound == BrakePadCompound.organicResin) {
        // Klocki żywiczne w deszczu ścierają się dramatycznie!
        padWearBase *= 5.5;
        notes.add(
          'ALERTY SERWISOWE: Klocki żywiczne na deszczowym zjeździe alpejskim '
          'starły się gwałtownie (${(padWearBase * 1.1).toStringAsFixed(1)}% zużycia)! '
          'Zalecana natychmiastowa wymiana na klocki metaliczne (Sintered).',
        );
      } else if (frontBrake.padCompound == BrakePadCompound.metallicSintered) {
        // Klocki metaliczne są wysoce odporne na wodę
        padWearBase *= 1.4;
      } else {
        padWearBase *= 2.5;
      }
    }

    final double frontPadWear = padWearBase * 1.1; // Przedni hamulec przyjmuje 70% masy
    final double rearPadWear = padWearBase * 0.8;

    // Przegrzanie i zeszklenie tarcz (Glazing) przy stromych zjazdach
    double glazingDelta = 0.0;
    if (descentElevationMeters > 2000.0) {
      glazingDelta = (descentElevationMeters / 1000.0) * 8.0;
    }

    final double rotorWearDelta = descentFactor * 0.8;

    final updatedFrontBrake = frontBrake.copyWith(
      padWearPercent:
          (frontBrake.padWearPercent + frontPadWear).clamp(0.0, 100.0),
      rotorWearPercent:
          (frontBrake.rotorWearPercent + rotorWearDelta).clamp(0.0, 100.0),
      rotorGlazingPercent:
          (frontBrake.rotorGlazingPercent + glazingDelta).clamp(0.0, 100.0),
      hydraulicFluidConditionPercent: math.max(
          20.0, frontBrake.hydraulicFluidConditionPercent - (descentFactor * 3.0)),
    );

    final updatedRearBrake = rearBrake.copyWith(
      padWearPercent:
          (rearBrake.padWearPercent + rearPadWear).clamp(0.0, 100.0),
      rotorWearPercent:
          (rearBrake.rotorWearPercent + rotorWearDelta * 0.8).clamp(0.0, 100.0),
      rotorGlazingPercent:
          (rearBrake.rotorGlazingPercent + glazingDelta * 0.7).clamp(0.0, 100.0),
      hydraulicFluidConditionPercent: math.max(
          20.0, rearBrake.hydraulicFluidConditionPercent - (descentFactor * 2.5)),
    );

    // Ostrzeżenia o zużyciu klocków
    if (updatedFrontBrake.padWearPercent >= 80.0) {
      notes.add(
        'KRYTYCZNE ZUŻYCIE: Przednie klocki hamulcowe mają ponad 80% zużycia! Wymień przed kolejnym etapem.',
      );
    }
    if (updatedChain.needsReplacement) {
      notes.add(
        'Łańcuch osiągnął wyciągnięcie ${updatedChain.chainElongationPercent.toStringAsFixed(2)}% (limit 0.50%). Ryzyko zerwania!',
      );
    }

    return StageEquipmentWearResult(
      updatedChain: updatedChain,
      updatedFrontTire: updatedFrontTire,
      updatedRearTire: updatedRearTire,
      updatedFrontBrake: updatedFrontBrake,
      updatedRearBrake: updatedRearBrake,
      didWaxWashoutOccur: newIsWashedOut && !chain.isWashedOut,
      washoutDistanceKm: washoutDist,
      newFrontTireMicroCuts: newFrontCuts,
      newRearTireMicroCuts: newRearCuts,
      frontPadWearDeltaPercent: frontPadWear,
      rearPadWearDeltaPercent: rearPadWear,
      drivetrainLossWattsDelta: drivetrainDeltaWatts,
      mechanicNotes: notes,
    );
  }

  // ===========================================================================
  // AKCJE SERWISOWE MECHANIKÓW (MECHANIC MAINTENANCE ACTIONS)
  // ===========================================================================

  /// Wygotowanie łańcucha w wosku na gorąco (Hot Melt Waxing) w ultradźwiękach
  EquipmentWearAndMaintenance performHotMeltWaxing({
    bool allWeatherFormula = false,
  }) {
    final updatedChain = chain.copyWith(
      lubricantType: allWeatherFormula
          ? DrivetrainLubricantType.hotMeltWaxAllWeather
          : DrivetrainLubricantType.hotMeltWaxStandard,
      waxFilmRemainingPercent: 100.0,
      mileageSinceLastWaxKm: 0.0,
      isWashedOut: false,
    );
    return copyWith(chain: updatedChain);
  }

  /// Wymiana łańcucha na fabrycznie nowy egzemplarz 12-biegowy
  EquipmentWearAndMaintenance replaceChain({
    DrivetrainLubricantType lubricant = DrivetrainLubricantType.hotMeltWaxStandard,
  }) {
    return copyWith(
      chain: ChainAndWaxCondition(
        lubricantType: lubricant,
        waxFilmRemainingPercent: 100.0,
        chainElongationPercent: 0.03,
        totalChainMileageKm: 0.0,
        mileageSinceLastWaxKm: 0.0,
        isWashedOut: false,
      ),
    );
  }

  /// Szybkie dokropienie wosku w emulsji przed startem etapu (Drip Wax Top-Up)
  EquipmentWearAndMaintenance applyDripWaxTopUp() {
    final updatedChain = chain.copyWith(
      lubricantType: DrivetrainLubricantType.dripWaxEmulsion,
      waxFilmRemainingPercent: 100.0,
      mileageSinceLastWaxKm: 0.0,
      isWashedOut: false,
    );
    return copyWith(chain: updatedChain);
  }

  /// Wymiana opon na nowe wyścigowe szytki lub opony bezdętkowe
  EquipmentWearAndMaintenance replaceTires({
    bool front = true,
    bool rear = true,
  }) {
    return copyWith(
      frontTire: front ? TireWearCondition.brandNew(isTubeless: true) : frontTire,
      rearTire: rear ? TireWearCondition.brandNew(isTubeless: true) : rearTire,
    );
  }

  /// Uzupełnienie mleczka uszczelniającego Tubeless (dolanie 35ml świeżego lateksu)
  EquipmentWearAndMaintenance topUpTubelessSealant({
    double amountMl = 35.0,
  }) {
    return copyWith(
      frontTire: frontTire.copyWith(
        tubelessSealantVolumeMl: (frontTire.tubelessSealantVolumeMl + amountMl).clamp(0.0, 45.0),
        tubelessSealantFreshnessPercent: 100.0,
      ),
      rearTire: rearTire.copyWith(
        tubelessSealantVolumeMl: (rearTire.tubelessSealantVolumeMl + amountMl).clamp(0.0, 45.0),
        tubelessSealantFreshnessPercent: 100.0,
      ),
    );
  }

  /// Wymiana klocków hamulcowych z doborem mieszanki (żywiczne vs spiekane)
  EquipmentWearAndMaintenance replaceBrakePads({
    required BrakePadCompound compound,
    bool front = true,
    bool rear = true,
  }) {
    return copyWith(
      frontBrake: front
          ? frontBrake.copyWith(
              padCompound: compound,
              padWearPercent: 0.0,
              rotorGlazingPercent: 0.0,
            )
          : frontBrake,
      rearBrake: rear
          ? rearBrake.copyWith(
              padCompound: compound,
              padWearPercent: 0.0,
              rotorGlazingPercent: 0.0,
            )
          : rearBrake,
    );
  }

  /// Prostowanie tarcz i odpowietrzenie hydrauliki
  EquipmentWearAndMaintenance trueRotorsAndBleedHydraulics() {
    return copyWith(
      frontBrake: frontBrake.copyWith(
        rotorGlazingPercent: 0.0,
        hydraulicFluidConditionPercent: 100.0,
      ),
      rearBrake: rearBrake.copyWith(
        rotorGlazingPercent: 0.0,
        hydraulicFluidConditionPercent: 100.0,
      ),
    );
  }

  /// Kompleksowy generalny serwis roweru przed decydującym etapem lub dniem przerwy
  EquipmentWearAndMaintenance performCompleteGrandTourOverhaul({
    bool allWeatherWax = true,
    BrakePadCompound padCompound = BrakePadCompound.metallicSintered,
  }) {
    return EquipmentWearAndMaintenance(
      chain: ChainAndWaxCondition.brandNewHotMeltWax(
          allWeatherFormula: allWeatherWax),
      frontTire: TireWearCondition.brandNew(isTubeless: true),
      rearTire: TireWearCondition.brandNew(isTubeless: true),
      frontBrake: BrakeWearCondition.brandNew(compound: padCompound),
      rearBrake: BrakeWearCondition.brandNew(compound: padCompound),
      electronicBatteryPercent: 100.0,
    );
  }

  // ===========================================================================
  // STATUS OGÓLNY I REKOMENDACJE
  // ===========================================================================

  /// Ogólna kondycja techniczna roweru (0-100)
  int get overallHealthIndex {
    double score = 100.0;

    // Łańcuch
    score -= (chain.chainElongationPercent / 0.50) * 20.0;
    if (chain.isWashedOut) score -= 15.0;

    // Opony
    score -= (frontTire.treadWearPercent / 100.0) * 10.0;
    score -= (rearTire.treadWearPercent / 100.0) * 15.0;
    score -= (rearTire.microCutsCount * 2.5);

    // Hamulce
    score -= (frontBrake.padWearPercent / 100.0) * 15.0;
    score -= (rearBrake.padWearPercent / 100.0) * 10.0;

    return score.round().clamp(10, 100);
  }

  /// Lista pilnych akcji serwisowych wymaganych przed startem
  List<String> get urgentMaintenanceAlerts {
    final alerts = <String>[];
    if (chain.needsReplacement) {
      alerts.add('Konieczna wymiana łańcucha (wyciągnięcie ${chain.chainElongationPercent.toStringAsFixed(2)}% >= 0.50%)');
    } else if (chain.needsWaxing) {
      alerts.add('Wymagane wygotowanie w wosku na gorąco (film wosku ${chain.waxFilmRemainingPercent.round()}% lub wypłukany)');
    }

    if (rearTire.needsReplacement) {
      alerts.add('Wymiana tylnej opony: starty bieżnik (${rearTire.treadWearPercent.round()}%) lub ${rearTire.microCutsCount} mikronacięć kordu');
    }
    if (frontTire.needsReplacement) {
      alerts.add('Wymiana przedniej opony: stan krytyczny');
    }

    if (frontBrake.needsPadReplacement) {
      alerts.add('Wymiana przednich klocków hamulcowych: zużycie ${frontBrake.padWearPercent.round()}%');
    }
    if (rearBrake.needsPadReplacement) {
      alerts.add('Wymiana tylnych klocków hamulcowych: zużycie ${rearBrake.padWearPercent.round()}%');
    }

    return alerts;
  }

  EquipmentWearAndMaintenance copyWith({
    ChainAndWaxCondition? chain,
    TireWearCondition? frontTire,
    TireWearCondition? rearTire,
    BrakeWearCondition? frontBrake,
    BrakeWearCondition? rearBrake,
    double? electronicBatteryPercent,
  }) {
    return EquipmentWearAndMaintenance(
      chain: chain ?? this.chain,
      frontTire: frontTire ?? this.frontTire,
      rearTire: rearTire ?? this.rearTire,
      frontBrake: frontBrake ?? this.frontBrake,
      rearBrake: rearBrake ?? this.rearBrake,
      electronicBatteryPercent:
          electronicBatteryPercent ?? this.electronicBatteryPercent,
    );
  }

  Map<String, dynamic> toJson() => {
        'chain': chain.toJson(),
        'frontTire': frontTire.toJson(),
        'rearTire': rearTire.toJson(),
        'frontBrake': frontBrake.toJson(),
        'rearBrake': rearBrake.toJson(),
        'electronicBatteryPercent': electronicBatteryPercent,
      };

  factory EquipmentWearAndMaintenance.fromJson(Map<String, dynamic> json) {
    return EquipmentWearAndMaintenance(
      chain: json['chain'] != null
          ? ChainAndWaxCondition.fromJson(json['chain'] as Map<String, dynamic>)
          : ChainAndWaxCondition.brandNewHotMeltWax(),
      frontTire: json['frontTire'] != null
          ? TireWearCondition.fromJson(json['frontTire'] as Map<String, dynamic>)
          : TireWearCondition.brandNew(),
      rearTire: json['rearTire'] != null
          ? TireWearCondition.fromJson(json['rearTire'] as Map<String, dynamic>)
          : TireWearCondition.brandNew(),
      frontBrake: json['frontBrake'] != null
          ? BrakeWearCondition.fromJson(json['frontBrake'] as Map<String, dynamic>)
          : BrakeWearCondition.brandNew(),
      rearBrake: json['rearBrake'] != null
          ? BrakeWearCondition.fromJson(json['rearBrake'] as Map<String, dynamic>)
          : BrakeWearCondition.brandNew(),
      electronicBatteryPercent:
          (json['electronicBatteryPercent'] as num?)?.toDouble() ?? 100.0,
    );
  }
}

