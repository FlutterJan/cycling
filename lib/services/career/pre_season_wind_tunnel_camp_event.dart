// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/rider/rider.dart';

/// Dostępne obiekty tuneli aerodynamicznych i torów testowych na grudniowy obóz.
enum WindTunnelFacility {
  silverstoneSportsHub,
  a2WindTunnel,
  flandersAeroVelodrome,
  morganHillWinTunnel;

  String toJson() => name;

  static WindTunnelFacility fromJson(String value) {
    return WindTunnelFacility.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WindTunnelFacility.silverstoneSportsHub,
    );
  }

  String get label {
    switch (this) {
      case WindTunnelFacility.silverstoneSportsHub:
        return 'Silverstone Sports Engineering Hub';
      case WindTunnelFacility.a2WindTunnel:
        return 'A2 Wind Tunnel (Mooresville)';
      case WindTunnelFacility.flandersAeroVelodrome:
        return 'Flanders Aero Tunnel & Velodrome';
      case WindTunnelFacility.morganHillWinTunnel:
        return 'Morgan Hill Win Tunnel';
    }
  }

  String get location {
    switch (this) {
      case WindTunnelFacility.silverstoneSportsHub:
        return 'Silverstone, Wielka Brytania';
      case WindTunnelFacility.a2WindTunnel:
        return 'Karolina Północna, USA';
      case WindTunnelFacility.flandersAeroVelodrome:
        return 'Gandawa, Belgia';
      case WindTunnelFacility.morganHillWinTunnel:
        return 'Kalifornia, USA';
    }
  }

  String get specialtyDescription {
    switch (this) {
      case WindTunnelFacility.silverstoneSportsHub:
        return 'Precyzyjna waga aerodynamiczna 6-osiowa, korelacja z torem i analiza kątów odchylenia ±15°.';
      case WindTunnelFacility.a2WindTunnel:
        return 'Tunel dużych prędkości z wizualizacją dymną PIV oraz testami wiatru bocznego ±12°.';
      case WindTunnelFacility.flandersAeroVelodrome:
        return 'Bezpośrednie połączenie tunelu niskich prędkości z krytym welodromem 250 m.';
      case WindTunnelFacility.morganHillWinTunnel:
        return 'Elitarne laboratorium CFD z indywidualnym krojeniem kombinezonów i kasków 3D.';
    }
  }

  int get baseRentalCostEur {
    switch (this) {
      case WindTunnelFacility.silverstoneSportsHub:
        return 38000;
      case WindTunnelFacility.a2WindTunnel:
        return 34000;
      case WindTunnelFacility.flandersAeroVelodrome:
        return 30000;
      case WindTunnelFacility.morganHillWinTunnel:
        return 45000;
    }
  }

  /// Mnożnik precyzji pomiarowej tunelu wpływający na maksymalną redukcję CdA.
  double get precisionMultiplier {
    switch (this) {
      case WindTunnelFacility.silverstoneSportsHub:
        return 1.06;
      case WindTunnelFacility.a2WindTunnel:
        return 1.03;
      case WindTunnelFacility.flandersAeroVelodrome:
        return 1.00;
      case WindTunnelFacility.morganHillWinTunnel:
        return 1.10;
    }
  }

  int get maxYawAngleDeg {
    switch (this) {
      case WindTunnelFacility.silverstoneSportsHub:
        return 15;
      case WindTunnelFacility.a2WindTunnel:
        return 12;
      case WindTunnelFacility.flandersAeroVelodrome:
        return 10;
      case WindTunnelFacility.morganHillWinTunnel:
        return 15;
    }
  }
}

/// 3 testowane warianty pozycji czasowej (TT) podczas grudniowego obozu.
enum TimeTrialPostureOption {
  uciBalancedEndurance,
  highHandsPrayingMantis,
  lowAggressiveSuperman;

  String toJson() => name;

  static TimeTrialPostureOption fromJson(String value) {
    return TimeTrialPostureOption.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TimeTrialPostureOption.uciBalancedEndurance,
    );
  }

  String get label {
    switch (this) {
      case TimeTrialPostureOption.uciBalancedEndurance:
        return 'Pozycja Zrównoważona (UCI Endurance)';
      case TimeTrialPostureOption.highHandsPrayingMantis:
        return 'Pozycja High-Hands ("Praying Mantis")';
      case TimeTrialPostureOption.lowAggressiveSuperman:
        return 'Pozycja Ekstremalnie Niska ("Low-Stack")';
    }
  }

  String get shortTag {
    switch (this) {
      case TimeTrialPostureOption.uciBalancedEndurance:
        return 'Zrównoważona';
      case TimeTrialPostureOption.highHandsPrayingMantis:
        return 'High-Hands';
      case TimeTrialPostureOption.lowAggressiveSuperman:
        return 'Low-Stack';
    }
  }

  String get biomechanicsNote {
    switch (this) {
      case TimeTrialPostureOption.uciBalancedEndurance:
        return 'Otwarty kąt biodrowy, 100% stabilności generowanej mocy FTP i pełna zgodność z normą UCI.';
      case TimeTrialPostureOption.highHandsPrayingMantis:
        return 'Uniesione przedramiona (16°) zamykają lukę między kaskiem a klatką piersiową, redukując opór czołowy.';
      case TimeTrialPostureOption.lowAggressiveSuperman:
        return 'Maksymalnie obniżony kokpit i schowana głowa. Najniższe CdA, ale wymaga wysokiego TT Positioning (≥68).';
    }
  }

  /// Bazowa redukcja CdA wynikająca z samej zmiany pozycji [m^2].
  double get baseCdaReductionM2 {
    switch (this) {
      case TimeTrialPostureOption.uciBalancedEndurance:
        return 0.0055;
      case TimeTrialPostureOption.highHandsPrayingMantis:
        return 0.0092;
      case TimeTrialPostureOption.lowAggressiveSuperman:
        return 0.0118;
    }
  }

  /// Minimalny poziom `timeTrialPositioning` do utrzymania 100% mocy bez dyskomfortu.
  int get recommendedTtSkill {
    switch (this) {
      case TimeTrialPostureOption.uciBalancedEndurance:
        return 45;
      case TimeTrialPostureOption.highHandsPrayingMantis:
        return 60;
      case TimeTrialPostureOption.lowAggressiveSuperman:
        return 72;
    }
  }
}

/// Warianty kasków czasowych testowane w tunelu i na welodromie.
enum AeroHelmetOption {
  standardRoadAero,
  teardropTailLong,
  wideVisorStubby,
  custom3dPrintedVisor;

  String toJson() => name;

  static AeroHelmetOption fromJson(String value) {
    return AeroHelmetOption.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AeroHelmetOption.teardropTailLong,
    );
  }

  String get label {
    switch (this) {
      case AeroHelmetOption.standardRoadAero:
        return 'Kask Szosowy Aero (Baza)';
      case AeroHelmetOption.teardropTailLong:
        return 'Kask TT Długi Ogon "Teardrop"';
      case AeroHelmetOption.wideVisorStubby:
        return 'Kask TT Szeroki Wizjer "Wide-Front"';
      case AeroHelmetOption.custom3dPrintedVisor:
        return 'Kask Custom 3D-Printed Carbon';
    }
  }

  String get aeroProfileNote {
    switch (this) {
      case AeroHelmetOption.standardRoadAero:
        return 'Punkt odniesienia (baseline) bez zysku czasowego.';
      case AeroHelmetOption.teardropTailLong:
        return 'Najwyższa efektywność przy idealnym wietrze czołowym (kąt odchylenia 0–5°).';
      case AeroHelmetOption.wideVisorStubby:
        return 'Zoptymalizowany pod wiatr boczny (yaw ±10°) i płynne przejście strugi na barki.';
      case AeroHelmetOption.custom3dPrintedVisor:
        return 'Indywidualny skan czaszki 3D + zintegrowany wizjer bezszwowy.';
    }
  }

  double get cdaReductionM2 {
    switch (this) {
      case AeroHelmetOption.standardRoadAero:
        return 0.0;
      case AeroHelmetOption.teardropTailLong:
        return 0.0042;
      case AeroHelmetOption.wideVisorStubby:
        return 0.0056;
      case AeroHelmetOption.custom3dPrintedVisor:
        return 0.0074;
    }
  }

  int get costPerRiderEur {
    switch (this) {
      case AeroHelmetOption.standardRoadAero:
        return 0;
      case AeroHelmetOption.teardropTailLong:
        return 2600;
      case AeroHelmetOption.wideVisorStubby:
        return 4200;
      case AeroHelmetOption.custom3dPrintedVisor:
        return 6800;
    }
  }
}

/// Warianty kombinezonów czasowych (skinsuits) testowane w tunelu.
enum SkinsuitOption {
  teamStandardSuit,
  ribbedSleeveAero,
  customTailoredWindTunnelSuit;

  String toJson() => name;

  static SkinsuitOption fromJson(String value) {
    return SkinsuitOption.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SkinsuitOption.ribbedSleeveAero,
    );
  }

  String get label {
    switch (this) {
      case SkinsuitOption.teamStandardSuit:
        return 'Kombinezon Zespołowy Standard';
      case SkinsuitOption.ribbedSleeveAero:
        return 'Kombinezon Trip-Strip (Rękawy Aero)';
      case SkinsuitOption.customTailoredWindTunnelSuit:
        return 'Kombinezon Szyty na Miarę 3D';
    }
  }

  String get fabricNote {
    switch (this) {
      case SkinsuitOption.teamStandardSuit:
        return 'Seryjny krój zespołowy bez stref turbulencji warstwy przyściennej.';
      case SkinsuitOption.ribbedSleeveAero:
        return 'Prążkowane rękawy wymuszają kontrolowaną separację strugi przy 45–55 km/h.';
      case SkinsuitOption.customTailoredWindTunnelSuit:
        return 'Zero fałd materiału w pozycji TT, indywidualne dopasowanie laserowe.';
    }
  }

  double get cdaReductionM2 {
    switch (this) {
      case SkinsuitOption.teamStandardSuit:
        return 0.0;
      case SkinsuitOption.ribbedSleeveAero:
        return 0.0036;
      case SkinsuitOption.customTailoredWindTunnelSuit:
        return 0.0062;
    }
  }

  int get costPerRiderEur {
    switch (this) {
      case SkinsuitOption.teamStandardSuit:
        return 0;
      case SkinsuitOption.ribbedSleeveAero:
        return 1900;
      case SkinsuitOption.customTailoredWindTunnelSuit:
        return 4800;
    }
  }
}

/// Fazy przebiegu grudniowego obozu aerodynamicznego.
enum WindTunnelCampPhase {
  facilityAndSquadSelection,
  tunnelAndTrackTesting,
  completed;

  String toJson() => name;

  static WindTunnelCampPhase fromJson(String value) {
    return WindTunnelCampPhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WindTunnelCampPhase.facilityAndSquadSelection,
    );
  }
}

/// Bazowy profil aerodynamiczny kolarza wyliczony z fizjologii i umiejętności.
class RiderWindTunnelBaseline {
  final String riderId;
  final String riderName;
  final RiderSpecialization specialization;
  final double baseCdaM2;
  final int ftpWatts;
  final int aeroPositioning;
  final int timeTrialPositioning;
  final int overallRating;

  const RiderWindTunnelBaseline({
    required this.riderId,
    required this.riderName,
    required this.specialization,
    required this.baseCdaM2,
    required this.ftpWatts,
    required this.aeroPositioning,
    required this.timeTrialPositioning,
    required this.overallRating,
  });

  factory RiderWindTunnelBaseline.fromRider(Rider rider) {
    final baseCda = PreSeasonWindTunnelCampEvent.computeBaselineCdaM2(rider);
    return RiderWindTunnelBaseline(
      riderId: rider.id,
      riderName: rider.fullName,
      specialization: rider.specialization,
      baseCdaM2: baseCda,
      ftpWatts: rider.physiology.ftpWatts,
      aeroPositioning: rider.skills.aeroPositioning,
      timeTrialPositioning: rider.skills.timeTrialPositioning,
      overallRating: rider.overallRating,
    );
  }

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'specialization': specialization.toJson(),
        'baseCdaM2': baseCdaM2,
        'ftpWatts': ftpWatts,
        'aeroPositioning': aeroPositioning,
        'timeTrialPositioning': timeTrialPositioning,
        'overallRating': overallRating,
      };

  factory RiderWindTunnelBaseline.fromJson(Map<String, dynamic> json) {
    return RiderWindTunnelBaseline(
      riderId: json['riderId'] as String? ?? '',
      riderName: json['riderName'] as String? ?? '',
      specialization: RiderSpecialization.fromJson(
        json['specialization'] as String? ?? 'domestiqueEngine',
      ),
      baseCdaM2: (json['baseCdaM2'] as num?)?.toDouble() ?? 0.245,
      ftpWatts: (json['ftpWatts'] as num?)?.toInt() ?? 380,
      aeroPositioning: (json['aeroPositioning'] as num?)?.toInt() ?? 60,
      timeTrialPositioning: (json['timeTrialPositioning'] as num?)?.toInt() ?? 60,
      overallRating: (json['overallRating'] as num?)?.toInt() ?? 75,
    );
  }
}

/// Konfiguracja testowanego zestawu aero dla pojedynczego kolarza.
class WindTunnelRiderTestConfig {
  final String riderId;
  final TimeTrialPostureOption testedPosture;
  final AeroHelmetOption testedHelmet;
  final SkinsuitOption testedSkinsuit;
  final bool trackValidationCompleted;
  final List<int> yawAnglesTestedDeg;

  const WindTunnelRiderTestConfig({
    required this.riderId,
    this.testedPosture = TimeTrialPostureOption.highHandsPrayingMantis,
    this.testedHelmet = AeroHelmetOption.wideVisorStubby,
    this.testedSkinsuit = SkinsuitOption.ribbedSleeveAero,
    this.trackValidationCompleted = false,
    this.yawAnglesTestedDeg = const [-10, -5, 0, 5, 10],
  });

  WindTunnelRiderTestConfig copyWith({
    TimeTrialPostureOption? testedPosture,
    AeroHelmetOption? testedHelmet,
    SkinsuitOption? testedSkinsuit,
    bool? trackValidationCompleted,
    List<int>? yawAnglesTestedDeg,
  }) {
    return WindTunnelRiderTestConfig(
      riderId: riderId,
      testedPosture: testedPosture ?? this.testedPosture,
      testedHelmet: testedHelmet ?? this.testedHelmet,
      testedSkinsuit: testedSkinsuit ?? this.testedSkinsuit,
      trackValidationCompleted:
          trackValidationCompleted ?? this.trackValidationCompleted,
      yawAnglesTestedDeg: yawAnglesTestedDeg ?? this.yawAnglesTestedDeg,
    );
  }

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'testedPosture': testedPosture.toJson(),
        'testedHelmet': testedHelmet.toJson(),
        'testedSkinsuit': testedSkinsuit.toJson(),
        'trackValidationCompleted': trackValidationCompleted,
        'yawAnglesTestedDeg': yawAnglesTestedDeg,
      };

  factory WindTunnelRiderTestConfig.fromJson(Map<String, dynamic> json) {
    return WindTunnelRiderTestConfig(
      riderId: json['riderId'] as String? ?? '',
      testedPosture: TimeTrialPostureOption.fromJson(
        json['testedPosture'] as String? ?? 'highHandsPrayingMantis',
      ),
      testedHelmet: AeroHelmetOption.fromJson(
        json['testedHelmet'] as String? ?? 'wideVisorStubby',
      ),
      testedSkinsuit: SkinsuitOption.fromJson(
        json['testedSkinsuit'] as String? ?? 'ribbedSleeveAero',
      ),
      trackValidationCompleted:
          json['trackValidationCompleted'] as bool? ?? false,
      yawAnglesTestedDeg: (json['yawAnglesTestedDeg'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [-10, -5, 0, 5, 10],
    );
  }
}

/// Wynik pomiarów tunelowych i torowych dla pojedynczego zawodnika.
class RiderAeroTestResult {
  final String riderId;
  final String riderName;
  final double initialBaseCdaM2;
  final double optimizedBaseCdaM2;
  final double cdaReductionM2;
  final double cdaReductionPercent;
  final double wattsSavedAt45Kmh;
  final double wattsSavedAt50Kmh;
  final double estimated40KmTtGainSeconds;
  final int aeroSkillGain;
  final int ttSkillGain;
  final TimeTrialPostureOption chosenPosture;
  final AeroHelmetOption chosenHelmet;
  final SkinsuitOption chosenSkinsuit;
  final bool trackValidated;
  final String? sustainabilityWarning;

  const RiderAeroTestResult({
    required this.riderId,
    required this.riderName,
    required this.initialBaseCdaM2,
    required this.optimizedBaseCdaM2,
    required this.cdaReductionM2,
    required this.cdaReductionPercent,
    required this.wattsSavedAt45Kmh,
    required this.wattsSavedAt50Kmh,
    required this.estimated40KmTtGainSeconds,
    required this.aeroSkillGain,
    required this.ttSkillGain,
    required this.chosenPosture,
    required this.chosenHelmet,
    required this.chosenSkinsuit,
    required this.trackValidated,
    this.sustainabilityWarning,
  });

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'initialBaseCdaM2': initialBaseCdaM2,
        'optimizedBaseCdaM2': optimizedBaseCdaM2,
        'cdaReductionM2': cdaReductionM2,
        'cdaReductionPercent': cdaReductionPercent,
        'wattsSavedAt45Kmh': wattsSavedAt45Kmh,
        'wattsSavedAt50Kmh': wattsSavedAt50Kmh,
        'estimated40KmTtGainSeconds': estimated40KmTtGainSeconds,
        'aeroSkillGain': aeroSkillGain,
        'ttSkillGain': ttSkillGain,
        'chosenPosture': chosenPosture.toJson(),
        'chosenHelmet': chosenHelmet.toJson(),
        'chosenSkinsuit': chosenSkinsuit.toJson(),
        'trackValidated': trackValidated,
        'sustainabilityWarning': sustainabilityWarning,
      };
}

/// Trwały certyfikat obniżenia bazowego CdA na cały sezon dla zawodnika.
class SeasonAeroCdaGrant {
  final String riderId;
  final int seasonYear;
  final double permanentCdaDeltaM2;
  final double newBaseCdaM2;
  final TimeTrialPostureOption lockedPosture;
  final AeroHelmetOption lockedHelmet;
  final SkinsuitOption lockedSkinsuit;

  const SeasonAeroCdaGrant({
    required this.riderId,
    required this.seasonYear,
    required this.permanentCdaDeltaM2,
    required this.newBaseCdaM2,
    required this.lockedPosture,
    required this.lockedHelmet,
    required this.lockedSkinsuit,
  });

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'seasonYear': seasonYear,
        'permanentCdaDeltaM2': permanentCdaDeltaM2,
        'newBaseCdaM2': newBaseCdaM2,
        'lockedPosture': lockedPosture.toJson(),
        'lockedHelmet': lockedHelmet.toJson(),
        'lockedSkinsuit': lockedSkinsuit.toJson(),
      };
}

/// Kompletny raport końcowy grudniowego obozu aerodynamicznego.
class PreSeasonWindTunnelCampOutcome {
  final int seasonYear;
  final WindTunnelFacility facility;
  final int totalCostEur;
  final List<RiderAeroTestResult> riderResults;
  final List<Rider> updatedRoster;
  final List<SeasonAeroCdaGrant> seasonCdaGrants;
  final double averageCdaReductionM2;
  final double totalWattsSavedAt50Kmh;
  final String summaryHeadline;

  const PreSeasonWindTunnelCampOutcome({
    required this.seasonYear,
    required this.facility,
    required this.totalCostEur,
    required this.riderResults,
    required this.updatedRoster,
    required this.seasonCdaGrants,
    required this.averageCdaReductionM2,
    required this.totalWattsSavedAt50Kmh,
    required this.summaryHeadline,
  });
}

/// Serwis domenowy corocznego grudniowego obozu aerodynamicznego w tunelu i na torze.
///
/// Umożliwia przetestowanie 3 pozycji czasowych (TT), nowych kasków i kombinezonów
/// dla maksymalnie 6 kluczowych zawodników przed rozpoczęciem sezonu, trwale obniżając
/// ich bazowe $CdA$ na cały nadchodzący rok poprzez aktualizację `aeroPositioning`
/// oraz `timeTrialPositioning` w `RiderSkills`.
class PreSeasonWindTunnelCampEvent {
  static const int maxKeyRiders = 6;
  static const double airDensitySeaLevelKgM3 = 1.225;
  static const double minRealisticCdaM2 = 0.175;
  static const double maxRealisticCdaM2 = 0.340;

  const PreSeasonWindTunnelCampEvent();

  /// Sprawdza, czy bieżąca data znajduje się w grudniowym oknie obozu przedsezonowego.
  static bool isDecemberCampWindow(DateTime date) => date.month == 12;

  /// Wylicza bazowe $CdA$ [m^2] kolarza na podstawie powierzchni czołowej i umiejętności aero.
  static double computeBaselineCdaM2(Rider rider) {
    final frontalArea = rider.physiology.frontalAreaM2 > 0.0
        ? rider.physiology.frontalAreaM2
        : 0.48;
    // Współczynnik oporu pozycji czasowej skorygowany o `aeroPositioning` kolarza
    final rawCda = frontalArea * 0.56 * rider.skills.cdaModifier;
    return rawCda.clamp(minRealisticCdaM2, maxRealisticCdaM2);
  }

  /// Automatycznie wybiera 6 kluczowych zawodników drużyny do testów w tunelu.
  List<Rider> selectKeySixRiders(List<Rider> roster) {
    if (roster.isEmpty) return const [];
    final scored = List<Rider>.from(roster);
    scored.sort((a, b) {
      final scoreA = _riderCampPriorityScore(a);
      final scoreB = _riderCampPriorityScore(b);
      return scoreB.compareTo(scoreA);
    });
    return scored.take(maxKeyRiders).toList(growable: false);
  }

  double _riderCampPriorityScore(Rider rider) {
    double specWeight = 0.0;
    switch (rider.specialization) {
      case RiderSpecialization.timeTrialist:
        specWeight = 26.0;
        break;
      case RiderSpecialization.gcClimber:
        specWeight = 22.0;
        break;
      case RiderSpecialization.classicCobbles:
        specWeight = 16.0;
        break;
      case RiderSpecialization.pureSprinter:
      case RiderSpecialization.versatileSprinter:
        specWeight = 14.0;
        break;
      case RiderSpecialization.puncher:
        specWeight = 12.0;
        break;
      case RiderSpecialization.pureClimber:
      case RiderSpecialization.breakawaySpecialist:
        specWeight = 10.0;
        break;
      case RiderSpecialization.domestiqueEngine:
        specWeight = 6.0;
        break;
    }
    return rider.overallRating +
        specWeight +
        (rider.skills.timeTrialPositioning * 0.25);
  }

  /// Wylicza oszczędność mocy aerodynamicznej [W] przy zadanej prędkości [km/h].
  ///
  /// Wzór: $\Delta P = \frac{1}{2} \cdot \rho \cdot \Delta CdA \cdot v^3$
  static double computeAerodynamicWattsSaved({
    required double cdaReductionM2,
    required double speedKmh,
  }) {
    if (cdaReductionM2 <= 0.0 || speedKmh <= 0.0) return 0.0;
    final speedMs = speedKmh / 3.6;
    return 0.5 *
        airDensitySeaLevelKgM3 *
        cdaReductionM2 *
        math.pow(speedMs, 3);
  }

  /// Wylicza pełny wynik testu w tunelu i na torze dla pojedynczego zawodnika.
  RiderAeroTestResult evaluateRiderSetup({
    required RiderWindTunnelBaseline baseline,
    required WindTunnelFacility facility,
    required WindTunnelRiderTestConfig config,
  }) {
    final postureGain = config.testedPosture.baseCdaReductionM2;
    final helmetGain = config.testedHelmet.cdaReductionM2;
    final suitGain = config.testedSkinsuit.cdaReductionM2;

    // Synergia z umiejętnością utrzymania pozycji TT oraz walidacją na welodromie
    final ttSkillFactor =
        0.92 + ((baseline.timeTrialPositioning.clamp(40, 99) - 40) / 59.0) * 0.16;
    final trackBonusMultiplier = config.trackValidationCompleted ? 1.08 : 1.0;

    final rawReduction = (postureGain + helmetGain + suitGain) *
        facility.precisionMultiplier *
        ttSkillFactor *
        trackBonusMultiplier;

    final clampedOptimizedCda =
        (baseline.baseCdaM2 - rawReduction).clamp(minRealisticCdaM2, baseline.baseCdaM2);
    final actualReduction = math.max(0.0, baseline.baseCdaM2 - clampedOptimizedCda);
    final reductionPercent = baseline.baseCdaM2 > 0.0
        ? (actualReduction / baseline.baseCdaM2) * 100.0
        : 0.0;

    final watts45 = computeAerodynamicWattsSaved(
      cdaReductionM2: actualReduction,
      speedKmh: 45.0,
    );
    final watts50 = computeAerodynamicWattsSaved(
      cdaReductionM2: actualReduction,
      speedKmh: 50.0,
    );

    // Przybliżony zysk na 40 km ITT (~50 km/h): ok. 1.0 s na każde ~0.9 W oszczędności na dystansie 40 km
    final tt40KmGainSec = watts50 * 1.18;

    // Trwały wzrost `aeroPositioning` i `timeTrialPositioning` w RiderSkills
    // Każde 0.0015 m^2 redukcji CdA przekłada się na +1 pkt aeroPositioning (max +10).
    final aeroSkillGain = (actualReduction / 0.0022).round().clamp(1, 10);
    final ttSkillGain = config.trackValidationCompleted
        ? math.max(1, (aeroSkillGain * 0.7).round())
        : math.max(1, (aeroSkillGain * 0.45).round());

    String? warning;
    if (baseline.timeTrialPositioning < config.testedPosture.recommendedTtSkill) {
      warning =
          'Wymagana adaptacja mięśniowa: ${config.testedPosture.shortTag} zalecana od TT ≥ ${config.testedPosture.recommendedTtSkill} (aktualnie ${baseline.timeTrialPositioning}).';
    }

    return RiderAeroTestResult(
      riderId: baseline.riderId,
      riderName: baseline.riderName,
      initialBaseCdaM2: baseline.baseCdaM2,
      optimizedBaseCdaM2: clampedOptimizedCda,
      cdaReductionM2: actualReduction,
      cdaReductionPercent: reductionPercent,
      wattsSavedAt45Kmh: watts45,
      wattsSavedAt50Kmh: watts50,
      estimated40KmTtGainSeconds: tt40KmGainSec,
      aeroSkillGain: aeroSkillGain,
      ttSkillGain: ttSkillGain,
      chosenPosture: config.testedPosture,
      chosenHelmet: config.testedHelmet,
      chosenSkinsuit: config.testedSkinsuit,
      trackValidated: config.trackValidationCompleted,
      sustainabilityWarning: warning,
    );
  }

  /// Wylicza całkowity koszt obozu (wynajem tunelu + kaski + kombinezony dla wybranych kolarzy).
  int calculateTotalCampCostEur({
    required WindTunnelFacility facility,
    required Iterable<WindTunnelRiderTestConfig> configs,
  }) {
    int equipmentCost = 0;
    for (final cfg in configs) {
      equipmentCost += cfg.testedHelmet.costPerRiderEur;
      equipmentCost += cfg.testedSkinsuit.costPerRiderEur;
    }
    return facility.baseRentalCostEur + equipmentCost;
  }

  /// Finalizuje obóz grudniowy i trwale obniża bazowe $CdA$ wybranych zawodników na cały sezon.
  PreSeasonWindTunnelCampOutcome finalizeCamp({
    required int seasonYear,
    required WindTunnelFacility facility,
    required List<Rider> fullRoster,
    required List<String> selectedRiderIds,
    required Map<String, WindTunnelRiderTestConfig> configsByRiderId,
  }) {
    final limitedIds = selectedRiderIds.take(maxKeyRiders).toSet();
    final results = <RiderAeroTestResult>[];
    final grants = <SeasonAeroCdaGrant>[];
    final updatedRoster = <Rider>[];
    final activeConfigs = <WindTunnelRiderTestConfig>[];

    for (final rider in fullRoster) {
      if (!limitedIds.contains(rider.id)) {
        updatedRoster.add(rider);
        continue;
      }

      final baseline = RiderWindTunnelBaseline.fromRider(rider);
      final config = configsByRiderId[rider.id] ??
          WindTunnelRiderTestConfig(riderId: rider.id);
      activeConfigs.add(config);

      final result = evaluateRiderSetup(
        baseline: baseline,
        facility: facility,
        config: config,
      );
      results.add(result);

      final nextAero =
          (rider.skills.aeroPositioning + result.aeroSkillGain).clamp(1, 99);
      final nextTt =
          (rider.skills.timeTrialPositioning + result.ttSkillGain).clamp(1, 99);

      final updatedRider = rider.copyWith(
        skills: rider.skills.copyWith(
          aeroPositioning: nextAero,
          timeTrialPositioning: nextTt,
        ),
      );
      updatedRoster.add(updatedRider);

      grants.add(
        SeasonAeroCdaGrant(
          riderId: rider.id,
          seasonYear: seasonYear,
          permanentCdaDeltaM2: -result.cdaReductionM2,
          newBaseCdaM2: result.optimizedBaseCdaM2,
          lockedPosture: config.testedPosture,
          lockedHelmet: config.testedHelmet,
          lockedSkinsuit: config.testedSkinsuit,
        ),
      );
    }

    final totalCost = calculateTotalCampCostEur(
      facility: facility,
      configs: activeConfigs,
    );

    final avgCdaDrop = results.isEmpty
        ? 0.0
        : results.fold<double>(0.0, (sum, r) => sum + r.cdaReductionM2) /
            results.length;
    final totalWatts50 =
        results.fold<double>(0.0, (sum, r) => sum + r.wattsSavedAt50Kmh);

    final headline = results.isEmpty
        ? 'Obóz aerodynamiczny zakończony bez wybranych zawodników.'
        : '${facility.label}: ${results.length} kluczowych kolarzy obniżyło średnie CdA o ${(avgCdaDrop * 1000).toStringAsFixed(1)}×10⁻³ m² (łącznie ${totalWatts50.toStringAsFixed(1)} W oszczędności przy 50 km/h).';

    return PreSeasonWindTunnelCampOutcome(
      seasonYear: seasonYear,
      facility: facility,
      totalCostEur: totalCost,
      riderResults: results,
      updatedRoster: updatedRoster,
      seasonCdaGrants: grants,
      averageCdaReductionM2: avgCdaDrop,
      totalWattsSavedAt50Kmh: totalWatts50,
      summaryHeadline: headline,
    );
  }
}

/// Stan UI i logiki grudniowego obozu aerodynamicznego zarządzany przez Riverpod.
class PreSeasonWindTunnelCampState {
  final int seasonYear;
  final int teamBudgetEur;
  final WindTunnelCampPhase phase;
  final WindTunnelFacility selectedFacility;
  final List<Rider> roster;
  final List<String> selectedRiderIds;
  final String? activeRiderId;
  final Map<String, WindTunnelRiderTestConfig> configsByRiderId;
  final PreSeasonWindTunnelCampOutcome? outcome;
  final String? errorMessage;

  const PreSeasonWindTunnelCampState({
    required this.seasonYear,
    required this.teamBudgetEur,
    this.phase = WindTunnelCampPhase.facilityAndSquadSelection,
    this.selectedFacility = WindTunnelFacility.silverstoneSportsHub,
    this.roster = const [],
    this.selectedRiderIds = const [],
    this.activeRiderId,
    this.configsByRiderId = const {},
    this.outcome,
    this.errorMessage,
  });

  PreSeasonWindTunnelCampState copyWith({
    int? seasonYear,
    int? teamBudgetEur,
    WindTunnelCampPhase? phase,
    WindTunnelFacility? selectedFacility,
    List<Rider>? roster,
    List<String>? selectedRiderIds,
    String? activeRiderId,
    Map<String, WindTunnelRiderTestConfig>? configsByRiderId,
    PreSeasonWindTunnelCampOutcome? outcome,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PreSeasonWindTunnelCampState(
      seasonYear: seasonYear ?? this.seasonYear,
      teamBudgetEur: teamBudgetEur ?? this.teamBudgetEur,
      phase: phase ?? this.phase,
      selectedFacility: selectedFacility ?? this.selectedFacility,
      roster: roster ?? this.roster,
      selectedRiderIds: selectedRiderIds ?? this.selectedRiderIds,
      activeRiderId: activeRiderId ?? this.activeRiderId,
      configsByRiderId: configsByRiderId ?? this.configsByRiderId,
      outcome: outcome ?? this.outcome,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Notifier zarządzający grudniowym obozem aerodynamicznym w tunelu i na torze.
class PreSeasonWindTunnelCampNotifier
    extends StateNotifier<PreSeasonWindTunnelCampState> {
  final PreSeasonWindTunnelCampEvent _service;

  PreSeasonWindTunnelCampNotifier({
    PreSeasonWindTunnelCampEvent? service,
    int seasonYear = 2027,
    int teamBudgetEur = 250000,
    List<Rider> initialRoster = const [],
  })  : _service = service ?? const PreSeasonWindTunnelCampEvent(),
        super(
          PreSeasonWindTunnelCampState(
            seasonYear: seasonYear,
            teamBudgetEur: teamBudgetEur,
          ),
        ) {
    if (initialRoster.isNotEmpty) {
      initializeCamp(
        seasonYear: seasonYear,
        teamBudgetEur: teamBudgetEur,
        roster: initialRoster,
      );
    }
  }

  void initializeCamp({
    required int seasonYear,
    required int teamBudgetEur,
    required List<Rider> roster,
  }) {
    final keySix = _service.selectKeySixRiders(roster);
    final selectedIds = keySix.map((r) => r.id).toList(growable: false);
    final configs = <String, WindTunnelRiderTestConfig>{
      for (final rider in keySix)
        rider.id: WindTunnelRiderTestConfig(riderId: rider.id),
    };

    state = PreSeasonWindTunnelCampState(
      seasonYear: seasonYear,
      teamBudgetEur: teamBudgetEur,
      phase: WindTunnelCampPhase.facilityAndSquadSelection,
      selectedFacility: WindTunnelFacility.silverstoneSportsHub,
      roster: roster,
      selectedRiderIds: selectedIds,
      activeRiderId: selectedIds.isNotEmpty ? selectedIds.first : null,
      configsByRiderId: configs,
    );
  }

  void selectFacility(WindTunnelFacility facility) {
    state = state.copyWith(selectedFacility: facility, clearError: true);
  }

  void toggleKeyRider(String riderId) {
    final current = List<String>.from(state.selectedRiderIds);
    final configs =
        Map<String, WindTunnelRiderTestConfig>.from(state.configsByRiderId);

    if (current.contains(riderId)) {
      if (current.length <= 1) {
        state = state.copyWith(
          errorMessage: 'Wybierz przynajmniej 1 zawodnika na testy w tunelu.',
        );
        return;
      }
      current.remove(riderId);
    } else {
      if (current.length >= PreSeasonWindTunnelCampEvent.maxKeyRiders) {
        state = state.copyWith(
          errorMessage:
              'Limit obozu wynosi ${PreSeasonWindTunnelCampEvent.maxKeyRiders} kluczowych zawodników.',
        );
        return;
      }
      current.add(riderId);
      configs.putIfAbsent(
        riderId,
        () => WindTunnelRiderTestConfig(riderId: riderId),
      );
    }

    final nextActive = current.contains(state.activeRiderId)
        ? state.activeRiderId
        : (current.isNotEmpty ? current.first : null);

    state = state.copyWith(
      selectedRiderIds: current,
      activeRiderId: nextActive,
      configsByRiderId: configs,
      clearError: true,
    );
  }

  void setActiveRider(String riderId) {
    if (!state.selectedRiderIds.contains(riderId)) return;
    state = state.copyWith(activeRiderId: riderId, clearError: true);
  }

  void proceedToTestingPhase() {
    if (state.selectedRiderIds.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Wybierz kluczowych zawodników przed wejściem do tunelu.',
      );
      return;
    }
    state = state.copyWith(
      phase: WindTunnelCampPhase.tunnelAndTrackTesting,
      activeRiderId: state.activeRiderId ?? state.selectedRiderIds.first,
      clearError: true,
    );
  }

  void backToFacilitySelection() {
    state = state.copyWith(
      phase: WindTunnelCampPhase.facilityAndSquadSelection,
      clearError: true,
    );
  }

  void setRiderPosture(String riderId, TimeTrialPostureOption posture) {
    final configs =
        Map<String, WindTunnelRiderTestConfig>.from(state.configsByRiderId);
    final existing =
        configs[riderId] ?? WindTunnelRiderTestConfig(riderId: riderId);
    configs[riderId] = existing.copyWith(testedPosture: posture);
    state = state.copyWith(configsByRiderId: configs, clearError: true);
  }

  void setRiderHelmet(String riderId, AeroHelmetOption helmet) {
    final configs =
        Map<String, WindTunnelRiderTestConfig>.from(state.configsByRiderId);
    final existing =
        configs[riderId] ?? WindTunnelRiderTestConfig(riderId: riderId);
    configs[riderId] = existing.copyWith(testedHelmet: helmet);
    state = state.copyWith(configsByRiderId: configs, clearError: true);
  }

  void setRiderSkinsuit(String riderId, SkinsuitOption skinsuit) {
    final configs =
        Map<String, WindTunnelRiderTestConfig>.from(state.configsByRiderId);
    final existing =
        configs[riderId] ?? WindTunnelRiderTestConfig(riderId: riderId);
    configs[riderId] = existing.copyWith(testedSkinsuit: skinsuit);
    state = state.copyWith(configsByRiderId: configs, clearError: true);
  }

  void runTrackValidationForRider(String riderId) {
    final configs =
        Map<String, WindTunnelRiderTestConfig>.from(state.configsByRiderId);
    final existing =
        configs[riderId] ?? WindTunnelRiderTestConfig(riderId: riderId);
    configs[riderId] = existing.copyWith(trackValidationCompleted: true);
    state = state.copyWith(configsByRiderId: configs, clearError: true);
  }

  void runTrackValidationForAllSelected() {
    final configs =
        Map<String, WindTunnelRiderTestConfig>.from(state.configsByRiderId);
    for (final id in state.selectedRiderIds) {
      final existing = configs[id] ?? WindTunnelRiderTestConfig(riderId: id);
      configs[id] = existing.copyWith(trackValidationCompleted: true);
    }
    state = state.copyWith(configsByRiderId: configs, clearError: true);
  }

  int get currentTotalCostEur {
    final activeConfigs = state.selectedRiderIds
        .map(
          (id) =>
              state.configsByRiderId[id] ??
              WindTunnelRiderTestConfig(riderId: id),
        )
        .toList(growable: false);
    return _service.calculateTotalCampCostEur(
      facility: state.selectedFacility,
      configs: activeConfigs,
    );
  }

  List<RiderAeroTestResult> evaluateAllSelectedPreview() {
    final results = <RiderAeroTestResult>[];
    for (final id in state.selectedRiderIds) {
      final rider = state.roster.where((r) => r.id == id).firstOrNull;
      if (rider == null) continue;
      final baseline = RiderWindTunnelBaseline.fromRider(rider);
      final config =
          state.configsByRiderId[id] ?? WindTunnelRiderTestConfig(riderId: id);
      results.add(
        _service.evaluateRiderSetup(
          baseline: baseline,
          facility: state.selectedFacility,
          config: config,
        ),
      );
    }
    return results;
  }

  PreSeasonWindTunnelCampOutcome? finalizeCampAndApplyCda() {
    final cost = currentTotalCostEur;
    if (cost > state.teamBudgetEur) {
      state = state.copyWith(
        errorMessage:
            'Niewystarczający budżet drużyny (${Formatters.formatCurrency(state.teamBudgetEur)} < ${Formatters.formatCurrency(cost)}).',
      );
      return null;
    }

    final outcome = _service.finalizeCamp(
      seasonYear: state.seasonYear,
      facility: state.selectedFacility,
      fullRoster: state.roster,
      selectedRiderIds: state.selectedRiderIds,
      configsByRiderId: state.configsByRiderId,
    );

    state = state.copyWith(
      phase: WindTunnelCampPhase.completed,
      teamBudgetEur: state.teamBudgetEur - outcome.totalCostEur,
      roster: outcome.updatedRoster,
      outcome: outcome,
      clearError: true,
    );
    return outcome;
  }
}

final preSeasonWindTunnelCampProvider = StateNotifierProvider.autoDispose<
    PreSeasonWindTunnelCampNotifier, PreSeasonWindTunnelCampState>((ref) {
  return PreSeasonWindTunnelCampNotifier();
});

/// Wizualizacja strug powietrza w tunelu aerodynamicznym wokół kolarza TT.
class WindTunnelAirflowPainter extends CustomPainter {
  final TimeTrialPostureOption posture;
  final AeroHelmetOption helmet;
  final SkinsuitOption skinsuit;
  final double cdaReductionPercent;
  final bool trackValidated;

  const WindTunnelAirflowPainter({
    required this.posture,
    required this.helmet,
    required this.skinsuit,
    required this.cdaReductionPercent,
    required this.trackValidated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF0F1115),
          Color(0xFF151B24),
          Color(0xFF0F1115),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      bgPaint,
    );

    // Siatka pomiarowa tunelu
    final gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;
    for (int i = 1; i < 6; i++) {
      final y = size.height * (i / 6);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (int i = 1; i < 10; i++) {
      final x = size.width * (i / 10);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Strugi laminarne powietrza (gładkość zależna od redukcji CdA)
    final smoothness = (cdaReductionPercent / 12.0).clamp(0.1, 1.0);
    final streamColor = trackValidated
        ? AppColors.statusSuccess
        : AppColors.cyanAccent;

    for (int row = 0; row < 7; row++) {
      final baseY = size.height * (0.14 + row * 0.115);
      final path = Path()..moveTo(10, baseY);
      final wakeTurbulence = (1.0 - smoothness) * 14.0;

      final ctrl1X = size.width * 0.35;
      final ctrl2X = size.width * 0.62;
      final riderDeflect = (row >= 1 && row <= 4)
          ? (posture == TimeTrialPostureOption.lowAggressiveSuperman
              ? -12.0
              : posture == TimeTrialPostureOption.highHandsPrayingMantis
                  ? -16.0
                  : -22.0)
          : 0.0;

      path.cubicTo(
        ctrl1X,
        baseY + riderDeflect * 0.4,
        ctrl2X,
        baseY + riderDeflect,
        size.width - 12,
        baseY + (row.isEven ? wakeTurbulence : -wakeTurbulence * 0.6),
      );

      final streamPaint = Paint()
        ..color = streamColor.withValues(alpha: 0.28 + smoothness * 0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = row == 2 || row == 3 ? 2.0 : 1.3;
      canvas.drawPath(path, streamPaint);
    }

    // Uproszczona sylwetka kolarza TT i roweru
    final cx = size.width * 0.48;
    final groundY = size.height * 0.82;
    final wheelRadius = math.min(size.height * 0.17, 22.0);

    final bikePaint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    // Koła dyskowe TT
    canvas.drawCircle(Offset(cx - 46, groundY - wheelRadius), wheelRadius, bikePaint);
    canvas.drawCircle(Offset(cx + 46, groundY - wheelRadius), wheelRadius, bikePaint);

    // Rama + pozycja tułowia
    final torsoDrop = posture == TimeTrialPostureOption.lowAggressiveSuperman
        ? 6.0
        : posture == TimeTrialPostureOption.highHandsPrayingMantis
            ? 12.0
            : 18.0;
    final backY = groundY - wheelRadius * 2.1 - torsoDrop;

    final framePath = Path()
      ..moveTo(cx - 46, groundY - wheelRadius)
      ..lineTo(cx - 12, groundY - wheelRadius * 1.9)
      ..lineTo(cx + 26, groundY - wheelRadius * 1.95)
      ..lineTo(cx + 46, groundY - wheelRadius);
    canvas.drawPath(framePath, bikePaint);

    // Kolarz (kolor zależny od kombinezonu)
    final suitColor = skinsuit == SkinsuitOption.customTailoredWindTunnelSuit
        ? AppColors.goldAccent
        : skinsuit == SkinsuitOption.ribbedSleeveAero
            ? AppColors.accentBlue
            : AppColors.primaryAccent;

    final riderPaint = Paint()
      ..color = suitColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - 14, groundY - wheelRadius * 2.0),
      Offset(cx + 18, backY),
      riderPaint,
    );

    // Kask TT
    final helmetColor = helmet == AeroHelmetOption.custom3dPrintedVisor
        ? AppColors.goldAccent
        : AppColors.textPrimary;
    final helmetPaint = Paint()
      ..color = helmetColor
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + 25, backY - 4),
        width: helmet == AeroHelmetOption.teardropTailLong ? 22 : 16,
        height: 11,
      ),
      helmetPaint,
    );
  }

  @override
  bool shouldRepaint(covariant WindTunnelAirflowPainter oldDelegate) {
    return oldDelegate.posture != posture ||
        oldDelegate.helmet != helmet ||
        oldDelegate.skinsuit != skinsuit ||
        oldDelegate.cdaReductionPercent != cdaReductionPercent ||
        oldDelegate.trackValidated != trackValidated;
  }
}

/// Główny panel UI grudniowego obozu aerodynamicznego w tunelu i na torze.
class PreSeasonWindTunnelCampPanel extends ConsumerWidget {
  final ValueChanged<PreSeasonWindTunnelCampOutcome>? onCampCompleted;

  const PreSeasonWindTunnelCampPanel({
    super.key,
    this.onCampCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(preSeasonWindTunnelCampProvider);
    final notifier = ref.read(preSeasonWindTunnelCampProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 680;
        final isDesktop = constraints.maxWidth >= 1150;

        return Container(
          color: AppColors.background,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeaderBanner(
                  state: state,
                  totalCostEur: notifier.currentTotalCostEur,
                  isMobile: isMobile,
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _ErrorBanner(message: state.errorMessage!),
                ],
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  child: _buildPhaseContent(
                    context: context,
                    state: state,
                    notifier: notifier,
                    isMobile: isMobile,
                    isDesktop: isDesktop,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhaseContent({
    required BuildContext context,
    required PreSeasonWindTunnelCampState state,
    required PreSeasonWindTunnelCampNotifier notifier,
    required bool isMobile,
    required bool isDesktop,
  }) {
    switch (state.phase) {
      case WindTunnelCampPhase.facilityAndSquadSelection:
        return _FacilityAndSquadView(
          key: const ValueKey('facility_and_squad'),
          state: state,
          notifier: notifier,
          isMobile: isMobile,
          isDesktop: isDesktop,
        );
      case WindTunnelCampPhase.tunnelAndTrackTesting:
        return _TunnelTestingWorkbench(
          key: const ValueKey('tunnel_testing'),
          state: state,
          notifier: notifier,
          isMobile: isMobile,
          isDesktop: isDesktop,
          onCampCompleted: onCampCompleted,
        );
      case WindTunnelCampPhase.completed:
        return _CompletedCampSummaryView(
          key: const ValueKey('completed_summary'),
          outcome: state.outcome,
          isMobile: isMobile,
        );
    }
  }
}

class _HeaderBanner extends StatelessWidget {
  final PreSeasonWindTunnelCampState state;
  final int totalCostEur;
  final bool isMobile;

  const _HeaderBanner({
    required this.state,
    required this.totalCostEur,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryAccent),
                ),
                child: const Icon(
                  Icons.air_rounded,
                  color: AppColors.goldAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grudniowy Obóz Aerodynamiczny ${state.seasonYear}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isMobile ? 16 : 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${state.selectedFacility.label} • ${state.selectedRiderIds.length}/${PreSeasonWindTunnelCampEvent.maxKeyRiders} kluczowych zawodników',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _MetricBadge(
                label: 'Budżet',
                value: Formatters.formatCurrency(state.teamBudgetEur),
                color: AppColors.statusSuccess,
              ),
              _MetricBadge(
                label: 'Koszt Obozu',
                value: Formatters.formatCurrency(totalCostEur),
                color: totalCostEur > state.teamBudgetEur
                    ? AppColors.crimsonAlert
                    : AppColors.goldAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricBadge({
    required this.label,
    required this.value,
    required this.color,
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
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.crimsonAlert.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.crimsonAlert),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.crimsonAlert, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityAndSquadView extends StatelessWidget {
  final PreSeasonWindTunnelCampState state;
  final PreSeasonWindTunnelCampNotifier notifier;
  final bool isMobile;
  final bool isDesktop;

  const _FacilityAndSquadView({
    super.key,
    required this.state,
    required this.notifier,
    required this.isMobile,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: '1. Wybierz Tunel Aerodynamiczny i Tor Testowy',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: WindTunnelFacility.values.map((facility) {
              final selected = state.selectedFacility == facility;
              return SizedBox(
                width: isMobile ? double.infinity : (isDesktop ? 340 : 280),
                child: _InteractiveOptionCard(
                  selected: selected,
                  onTap: () => notifier.selectFacility(facility),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              facility.label,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (selected)
                            const Icon(Icons.check_circle,
                                color: AppColors.goldAccent, size: 18),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${facility.location} • ${Formatters.formatCurrency(facility.baseRentalCostEur)}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.accentBlue,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        facility.specialtyDescription,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title:
              '2. Wybierz do 6 Kluczowych Zawodników (${state.selectedRiderIds.length}/6)',
          child: state.roster.isEmpty
              ? const Text(
                  'Brak zawodników w kadrze drużyny.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                  ),
                )
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: state.roster.map((rider) {
                    final selected = state.selectedRiderIds.contains(rider.id);
                    final baseCda =
                        PreSeasonWindTunnelCampEvent.computeBaselineCdaM2(
                            rider);
                    return SizedBox(
                      width: isMobile ? double.infinity : 260,
                      child: _InteractiveOptionCard(
                        selected: selected,
                        onTap: () => notifier.toggleKeyRider(rider.id),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rider.fullName,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${rider.specialization.displayName} • CdA ${baseCda.toStringAsFixed(4)} m²',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      fontFeatures: [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              selected
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              color: selected
                                  ? AppColors.goldAccent
                                  : AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: _PrimaryActionButton(
            label: 'Rozpocznij Testy w Tunelu i na Torze',
            icon: Icons.science_rounded,
            enabled: state.selectedRiderIds.isNotEmpty,
            onPressed: notifier.proceedToTestingPhase,
          ),
        ),
      ],
    );
  }
}

class _TunnelTestingWorkbench extends StatelessWidget {
  final PreSeasonWindTunnelCampState state;
  final PreSeasonWindTunnelCampNotifier notifier;
  final bool isMobile;
  final bool isDesktop;
  final ValueChanged<PreSeasonWindTunnelCampOutcome>? onCampCompleted;

  const _TunnelTestingWorkbench({
    super.key,
    required this.state,
    required this.notifier,
    required this.isMobile,
    required this.isDesktop,
    this.onCampCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final activeId = state.activeRiderId ??
        (state.selectedRiderIds.isNotEmpty
            ? state.selectedRiderIds.first
            : null);
    final activeRider =
        state.roster.where((r) => r.id == activeId).firstOrNull;
    final previewResults = notifier.evaluateAllSelectedPreview();

    if (activeRider == null) {
      return const SizedBox.shrink();
    }

    final baseline = RiderWindTunnelBaseline.fromRider(activeRider);
    final config = state.configsByRiderId[activeRider.id] ??
        WindTunnelRiderTestConfig(riderId: activeRider.id);
    final result = const PreSeasonWindTunnelCampEvent().evaluateRiderSetup(
      baseline: baseline,
      facility: state.selectedFacility,
      config: config,
    );

    final riderTabs = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: state.selectedRiderIds.map((id) {
        final rider = state.roster.where((r) => r.id == id).firstOrNull;
        if (rider == null) return const SizedBox.shrink();
        final isActive = id == activeRider.id;
        final isValidated =
            state.configsByRiderId[id]?.trackValidationCompleted ?? false;
        return _InteractiveOptionCard(
          selected: isActive,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          onTap: () => notifier.setActiveRider(id),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                rider.lastName,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              if (isValidated) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified_rounded,
                    size: 14, color: AppColors.statusSuccess),
              ],
            ],
          ),
        );
      }).toList(),
    );

    final configPanel = _RiderAeroSetupPanel(
      rider: activeRider,
      config: config,
      result: result,
      notifier: notifier,
      isMobile: isMobile,
    );

    final telemetryPanel = _RiderTelemetryPreviewCard(
      config: config,
      result: result,
      onRunTrackTest: () =>
          notifier.runTrackValidationForRider(activeRider.id),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: 'Wybór Kolarza w Tunelu (${state.selectedRiderIds.length}/6)',
          child: riderTabs,
        ),
        const SizedBox(height: 16),
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: configPanel),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: telemetryPanel),
            ],
          )
        else ...[
          telemetryPanel,
          const SizedBox(height: 16),
          configPanel,
        ],
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Podsumowanie Pomiarów Przed Zatwierdzeniem na Sezon',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...previewResults.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            '${r.riderName} (${r.chosenPosture.shortTag})',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          flex: 2,
                          child: Text(
                            '${r.initialBaseCdaM2.toStringAsFixed(4)} → ${r.optimizedBaseCdaM2.toStringAsFixed(4)} m² (-${r.cdaReductionPercent.toStringAsFixed(1)}%)',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.statusSuccess,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  _SecondaryActionButton(
                    label: 'Wróć do Wyboru Kadry',
                    icon: Icons.arrow_back_rounded,
                    onPressed: notifier.backToFacilitySelection,
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _SecondaryActionButton(
                        label: 'Waliduj Wszystkie na Torze',
                        icon: Icons.speed_rounded,
                        onPressed: notifier.runTrackValidationForAllSelected,
                      ),
                      _PrimaryActionButton(
                        label: 'Zatwierdź Obóz i Obniż Bazowe CdA na Cały Rok',
                        icon: Icons.lock_clock_rounded,
                        enabled:
                            notifier.currentTotalCostEur <= state.teamBudgetEur,
                        onPressed: () {
                          final outcome = notifier.finalizeCampAndApplyCda();
                          if (outcome != null) {
                            onCampCompleted?.call(outcome);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RiderAeroSetupPanel extends StatelessWidget {
  final Rider rider;
  final WindTunnelRiderTestConfig config;
  final RiderAeroTestResult result;
  final PreSeasonWindTunnelCampNotifier notifier;
  final bool isMobile;

  const _RiderAeroSetupPanel({
    required this.rider,
    required this.config,
    required this.result,
    required this.notifier,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Konfiguracja Aerodynamiczna: ${rider.fullName}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '3 Pozycje Czasowe (TT)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.goldAccent,
            ),
          ),
          const SizedBox(height: 8),
          ...TimeTrialPostureOption.values.map((posture) {
            final selected = config.testedPosture == posture;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _InteractiveOptionCard(
                selected: selected,
                onTap: () => notifier.setRiderPosture(rider.id, posture),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            posture.label,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '-${(posture.baseCdaReductionM2 * 1000).toStringAsFixed(1)}×10⁻³ m²',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.cyanAccent,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      posture.biomechanicsNote,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          const Text(
            'Kask Czasowy',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.goldAccent,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AeroHelmetOption.values.map((helmet) {
              final selected = config.testedHelmet == helmet;
              return SizedBox(
                width: isMobile ? double.infinity : 250,
                child: _InteractiveOptionCard(
                  selected: selected,
                  onTap: () => notifier.setRiderHelmet(rider.id, helmet),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        helmet.label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${Formatters.formatCurrency(helmet.costPerRiderEur)} • -${(helmet.cdaReductionM2 * 1000).toStringAsFixed(1)}×10⁻³ m²',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.accentBlue,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const Text(
            'Kombinezon Aero (Skinsuit)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.goldAccent,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SkinsuitOption.values.map((suit) {
              final selected = config.testedSkinsuit == suit;
              return SizedBox(
                width: isMobile ? double.infinity : 250,
                child: _InteractiveOptionCard(
                  selected: selected,
                  onTap: () => notifier.setRiderSkinsuit(rider.id, suit),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suit.label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${Formatters.formatCurrency(suit.costPerRiderEur)} • -${(suit.cdaReductionM2 * 1000).toStringAsFixed(1)}×10⁻³ m²',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.accentBlue,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (result.sustainabilityWarning != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.amberWarning.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.amberWarning),
              ),
              child: Text(
                result.sustainabilityWarning!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RiderTelemetryPreviewCard extends StatelessWidget {
  final WindTunnelRiderTestConfig config;
  final RiderAeroTestResult result;
  final VoidCallback onRunTrackTest;

  const _RiderTelemetryPreviewCard({
    required this.config,
    required this.result,
    required this.onRunTrackTest,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Telemetria Tunelu i Welodromu',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 165,
            child: CustomPaint(
              painter: WindTunnelAirflowPainter(
                posture: config.testedPosture,
                helmet: config.testedHelmet,
                skinsuit: config.testedSkinsuit,
                cdaReductionPercent: result.cdaReductionPercent,
                trackValidated: config.trackValidationCompleted,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _TelemetryRow(
            label: 'Bazowe CdA (przed)',
            value: '${result.initialBaseCdaM2.toStringAsFixed(4)} m²',
          ),
          _TelemetryRow(
            label: 'Nowe Bazowe CdA (sezon)',
            value: '${result.optimizedBaseCdaM2.toStringAsFixed(4)} m²',
            valueColor: AppColors.statusSuccess,
          ),
          _TelemetryRow(
            label: 'Oszczędność przy 45 km/h',
            value: '${result.wattsSavedAt45Kmh.toStringAsFixed(1)} W',
            valueColor: AppColors.cyanAccent,
          ),
          _TelemetryRow(
            label: 'Oszczędność przy 50 km/h',
            value: '${result.wattsSavedAt50Kmh.toStringAsFixed(1)} W',
            valueColor: AppColors.goldAccent,
          ),
          _TelemetryRow(
            label: 'Zysk na 40 km ITT',
            value: '-${result.estimated40KmTtGainSeconds.toStringAsFixed(1)} s',
            valueColor: AppColors.statusSuccess,
          ),
          _TelemetryRow(
            label: 'Trwały bonus Aero / TT',
            value: '+${result.aeroSkillGain} / +${result.ttSkillGain} pkt',
          ),
          const SizedBox(height: 12),
          _PrimaryActionButton(
            label: config.trackValidationCompleted
                ? 'Zwalidowano na Torze (+8% Korelacji)'
                : 'Wykonaj Przejazd Walidacyjny na Torze',
            icon: config.trackValidationCompleted
                ? Icons.verified_rounded
                : Icons.track_changes_rounded,
            enabled: !config.trackValidationCompleted,
            onPressed: onRunTrackTest,
          ),
        ],
      ),
    );
  }
}

class _TelemetryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _TelemetryRow({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedCampSummaryView extends StatelessWidget {
  final PreSeasonWindTunnelCampOutcome? outcome;
  final bool isMobile;

  const _CompletedCampSummaryView({
    super.key,
    required this.outcome,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    if (outcome == null) return const SizedBox.shrink();
    final data = outcome!;
    return _SectionCard(
      title: 'Raport Końcowy Obozu Aerodynamicznego ${data.seasonYear}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.summaryHeadline,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.statusSuccess,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: data.riderResults.map((r) {
              return Container(
                width: isMobile ? double.infinity : 310,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.riderName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${r.chosenPosture.shortTag} • ${r.chosenHelmet.label}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _TelemetryRow(
                      label: 'Nowe bazowe CdA',
                      value: '${r.optimizedBaseCdaM2.toStringAsFixed(4)} m²',
                      valueColor: AppColors.statusSuccess,
                    ),
                    _TelemetryRow(
                      label: 'Zysk 50 km/h',
                      value: '${r.wattsSavedAt50Kmh.toStringAsFixed(1)} W',
                      valueColor: AppColors.goldAccent,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InteractiveOptionCard extends StatefulWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _InteractiveOptionCard({
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  State<_InteractiveOptionCard> createState() => _InteractiveOptionCardState();
}

class _InteractiveOptionCardState extends State<_InteractiveOptionCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.selected
        ? AppColors.goldAccent
        : (_focused
            ? AppColors.accentBlue
            : (_hovered ? AppColors.textSecondary : AppColors.cardBorder));

    return Focus(
      onFocusChange: (val) => setState(() => _focused = val),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: widget.padding,
              decoration: BoxDecoration(
                color: widget.selected
                    ? AppColors.primaryAccent.withValues(alpha: 0.16)
                    : (_hovered
                        ? AppColors.surfaceLight
                        : AppColors.background),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: widget.selected ? 1.5 : 1.0,
                ),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.surfaceLight;
          }
          if (states.contains(WidgetState.hovered)) {
            return const Color(0xFFA25756);
          }
          if (states.contains(WidgetState.pressed)) {
            return const Color(0xFF763C3B);
          }
          return AppColors.primaryAccent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.textSecondary;
          }
          return AppColors.textPrimary;
        }),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        elevation: WidgetStateProperty.all(0),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _SecondaryActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(AppColors.textPrimary),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return const BorderSide(color: AppColors.goldAccent);
          }
          return const BorderSide(color: AppColors.cardBorder);
        }),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
