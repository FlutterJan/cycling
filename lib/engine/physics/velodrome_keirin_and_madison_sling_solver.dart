// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../../core/constants/physics_constants.dart';
import '../../models/race/velodrome_track_and_hour_record_model.dart';
import 'velodrome_banking_and_centripetal_solver.dart';

/// Faza wyścigu torowego Keirin (1500 m / 6 okrążeń na welodromie 250 m).
enum KeirinRacePhase {
  /// Rozpędzanie stawki za motocyklem Derny (od ~30 km/h do 50 km/h).
  dernyRampUp('Jazda za Derny', 'Derny Pacing'),

  /// Zjazd motocykla Derny z toru na 3 okrążenia (750 m) przed metą.
  dernyPullOff('Zjazd motocykla Derny', 'Derny Pull-Off'),

  /// Gra taktyczna i zajmowanie pozycji po zjeździe Derny (750 m -> 400 m).
  tacticalPositioning('Gra taktyczna', 'Tactical Positioning'),

  /// Finałowy sprint beztlenowy na ostatnich 400 m.
  finalSprint('Finałowy sprint', 'Final Sprint');

  final String labelPl;
  final String labelEn;

  const KeirinRacePhase(this.labelPl, this.labelEn);
}

/// Parametry motocykla prowadzącego Derny w wyścigu Keirin.
class KeirinDernySpec {
  /// Prędkość początkowa Derny po starcie lotnym [km/h].
  final double startSpeedKmh;

  /// Docelowa prędkość maksymalna Derny w momencie zjazdu z toru [km/h] (UCI: 50.0 km/h).
  final double targetPullOffSpeedKmh;

  /// Liczba okrążeń prowadzonych przez motocykl Derny (standard UCI: 3 z 6 okrążeń = 750 m).
  final int pacedLaps;

  /// Współczynnik redukcji CdA bezpośrednio na kole Derny (np. 0.42 = 58% mniej oporu).
  final double directSlipstreamCdaFactor;

  const KeirinDernySpec({
    this.startSpeedKmh = 30.0,
    this.targetPullOffSpeedKmh = 50.0,
    this.pacedLaps = 3,
    this.directSlipstreamCdaFactor = 0.42,
  });

  /// Prędkość docelowa Derny przy zjeździe w m/s.
  double get targetPullOffSpeedMs => targetPullOffSpeedKmh / 3.6;
}

/// Profil kolarza torowego w symulacji Keirin.
class KeirinRiderProfile {
  final String riderId;
  final String name;

  /// Masa ciała kolarza [kg].
  final double riderMassKg;

  /// Rower torowy ostrokołowy.
  final FixedGearTrackBike bike;

  /// Szczytowa moc sprinterska 5s–15s [W].
  final double peakSprintPowerWatts;

  /// Próg wydolności tlenowej FTP / CP [W].
  final double criticalPowerWatts;

  /// Pojemność beztlenowa W' [J].
  final double wPrimeJoules;

  /// Umiejętność taktyki torowej i wyczucia momentu ataku (0–100).
  final double trackTacticsSkill;

  /// Wylosowana lub przypisana pozycja startowa za Derny (1 = tuż za motocyklem).
  final int startingSlot;

  const KeirinRiderProfile({
    required this.riderId,
    required this.name,
    required this.riderMassKg,
    required this.bike,
    required this.peakSprintPowerWatts,
    required this.criticalPowerWatts,
    required this.wPrimeJoules,
    this.trackTacticsSkill = 75.0,
    this.startingSlot = 1,
  });
}

/// Konfiguracja wyścigu Keirin na welodromie.
class KeirinRaceConfig {
  final VelodromeFacilitySpec facility;
  final KeirinDernySpec derny;

  /// Całkowita liczba okrążeń wyścigu (UCI: 6 okrążeń = 1500 m na torze 250 m).
  final int totalLaps;

  /// Krok czasowy symulacji [s].
  final double dtSeconds;

  const KeirinRaceConfig({
    required this.facility,
    this.derny = const KeirinDernySpec(),
    this.totalLaps = 6,
    this.dtSeconds = 0.5,
  });

  /// Całkowity dystans wyścigu [m].
  double get totalDistanceMeters => totalLaps * facility.trackLengthMeters;

  /// Dystans prowadzony przez Derny [m].
  double get dernyPullOffDistanceMeters =>
      derny.pacedLaps * facility.trackLengthMeters;
}

/// Dane wejściowe pojedynczego kroku fizyki Keirin.
class KeirinStepInput {
  final VelodromeFacilitySpec facility;
  final KeirinDernySpec derny;
  final KeirinRiderProfile rider;
  final double elapsedDistanceMeters;
  final double totalRaceDistanceMeters;
  final double currentSpeedMs;
  final double riderPowerWatts;
  final int pacelineSlot;
  final double gapToDernyMeters;
  final double lateralOffsetMeters;
  final double metersAboveBlackLine;
  final double previousMetersAboveBlackLine;
  final VelodromeTrackSection section;
  final double dtSeconds;

  const KeirinStepInput({
    required this.facility,
    required this.derny,
    required this.rider,
    required this.elapsedDistanceMeters,
    required this.totalRaceDistanceMeters,
    required this.currentSpeedMs,
    required this.riderPowerWatts,
    required this.pacelineSlot,
    required this.gapToDernyMeters,
    this.lateralOffsetMeters = 0.0,
    this.metersAboveBlackLine = 0.0,
    this.previousMetersAboveBlackLine = 0.0,
    this.section = VelodromeTrackSection.turnApex,
    this.dtSeconds = 0.5,
  });
}

/// Wynik pojedynczego kroku fizyki Keirin.
class KeirinStepResult {
  final KeirinRacePhase phase;
  final double dernyTargetSpeedMs;
  final double dernyTargetSpeedKmh;
  final double effectiveCdaFactor;
  final double effectiveCdaM2;
  final double netPropulsivePowerWatts;
  final double totalResistancePowerWatts;
  final double bankingDiveSpeedGainMs;
  final double nextSpeedMs;
  final double nextSpeedKmh;
  final double cadenceRpm;
  final double gForceLoadFactor;
  final double wPrimeDeltaJoules;
  final bool hasPassedDernyIllegally;

  const KeirinStepResult({
    required this.phase,
    required this.dernyTargetSpeedMs,
    required this.dernyTargetSpeedKmh,
    required this.effectiveCdaFactor,
    required this.effectiveCdaM2,
    required this.netPropulsivePowerWatts,
    required this.totalResistancePowerWatts,
    required this.bankingDiveSpeedGainMs,
    required this.nextSpeedMs,
    required this.nextSpeedKmh,
    required this.cadenceRpm,
    required this.gForceLoadFactor,
    required this.wPrimeDeltaJoules,
    required this.hasPassedDernyIllegally,
  });
}

/// Końcowy rezultat pojedynczego kolarza w symulacji wyścigu Keirin.
class KeirinRiderRaceOutcome {
  final String riderId;
  final String name;
  final int finishingPosition;
  final double finishTimeSeconds;
  final double peakSpeedKmh;
  final double speedAtDernyPullOffKmh;
  final double remainingWPrimeJoules;
  final bool disqualifiedForPassingDerny;

  const KeirinRiderRaceOutcome({
    required this.riderId,
    required this.name,
    required this.finishingPosition,
    required this.finishTimeSeconds,
    required this.peakSpeedKmh,
    required this.speedAtDernyPullOffKmh,
    required this.remainingWPrimeJoules,
    required this.disqualifiedForPassingDerny,
  });
}

/// Wynik pełnej symulacji wyścigu Keirin.
class KeirinRaceSimulationResult {
  final KeirinRaceConfig config;
  final double dernyPullOffSpeedKmh;
  final List<KeirinRiderRaceOutcome> standings;

  const KeirinRaceSimulationResult({
    required this.config,
    required this.dernyPullOffSpeedKmh,
    required this.standings,
  });
}

/// Jakość wykonania rzutu za rękę (`Hand Sling`) w wyścigu Madison.
enum MadisonSlingQuality {
  /// Perfekcyjny wyrzut z pełnym transferem pędu i minimalną stratą energii.
  textbookSlingshot('Wzorcowy rzut', 'Textbook Slingshot'),

  /// Czysta, poprawna zmiana pary w biegu.
  cleanExchange('Czysta zmiana', 'Clean Exchange'),

  /// Niedokładne złapanie dłoni, wytracenie części pędu.
  awkwardFumble('Nieczysta zmiana', 'Awkward Fumble'),

  /// Rozminięcie rąk — brak przekazania pędu.
  missedHandTouch('Chybiony chwyt', 'Missed Hand Touch'),

  /// Zbyt duża różnica prędkości / błąd techniczny — ryzyko kraksy lub kary.
  illegalPushOrCrash('Kraksa / Faul przy zmianie', 'Crash / Illegal Push');

  final String labelPl;
  final String labelEn;

  const MadisonSlingQuality(this.labelPl, this.labelEn);
}

/// Rola kolarza w parze Madison.
enum MadisonRiderRole {
  /// Kolarz aktywny w stawce (utrzymuje tempo wyścigowe i walczy na sprintach).
  activeRacing('Aktywny w wyścigu', 'Active Racing'),

  /// Kolarz odpoczywający na górze wiraża przed zmianą.
  reliefCircling('Odpoczynek na górze toru', 'Relief Circling');

  final String labelPl;
  final String labelEn;

  const MadisonRiderRole(this.labelPl, this.labelEn);
}

/// Dane wejściowe do fizyki rzutu za rękę (`Hand Sling`) w wyścigu Madison.
class MadisonHandSlingInput {
  final VelodromeFacilitySpec facility;

  /// Masa kolarza nadjeżdżającego (przekazującego pęd) [kg].
  final double incomingRiderMassKg;

  /// Rower kolarza nadjeżdżającego.
  final FixedGearTrackBike incomingBike;

  /// Prędkość kolarza nadjeżdżającego przed chwytem [m/s] (np. 15.5 m/s = 55.8 km/h).
  final double incomingSpeedMs;

  /// Masa kolarza wchodzącego do gry (odbierającego rzut) [kg].
  final double outgoingRiderMassKg;

  /// Rower kolarza wchodzącego do gry.
  final FixedGearTrackBike outgoingBike;

  /// Prędkość kolarza odbierającego przed chwytem [m/s] (np. 9.5 m/s = 34.2 km/h).
  final double outgoingSpeedMs;

  /// Umiejętność rzutu Madison kolarza nadjeżdżającego (0–100).
  final double incomingSlingSkill;

  /// Umiejętność odbioru rzutu Madison kolarza wchodzącego (0–100).
  final double outgoingSlingSkill;

  /// Zgranie pary drużynowej (0–100).
  final double teamChemistry;

  /// Dystans wzdłużny między osiami kolarzy w momencie chwytu [m] (optymalnie 0.0–0.6 m).
  final double longitudinalGapMeters;

  /// Odstęp poprzeczny między kolarzami [m] (optymalnie 0.45–0.95 m).
  final double lateralGapMeters;

  /// Czas trwania fazy ciągnięcia za rękę [s] (typowo 0.45–0.70 s).
  final double gripDurationSeconds;

  /// Sekcja toru, na której wykonywana jest zmiana.
  final VelodromeTrackSection section;

  /// Wysokość nad czarną linią dla kolarza odbierającego [m].
  final double outgoingMetersAboveBlackLine;

  const MadisonHandSlingInput({
    required this.facility,
    required this.incomingRiderMassKg,
    required this.incomingBike,
    required this.incomingSpeedMs,
    required this.outgoingRiderMassKg,
    required this.outgoingBike,
    required this.outgoingSpeedMs,
    this.incomingSlingSkill = 80.0,
    this.outgoingSlingSkill = 80.0,
    this.teamChemistry = 80.0,
    this.longitudinalGapMeters = 0.25,
    this.lateralGapMeters = 0.70,
    this.gripDurationSeconds = 0.55,
    this.section = VelodromeTrackSection.transitionExit,
    this.outgoingMetersAboveBlackLine = 1.40,
  });
}

/// Wynik fizyczny pojedynczego rzutu za rękę (`Hand Sling`) w Madisonie.
class MadisonHandSlingResult {
  final MadisonSlingQuality quality;

  /// Całkowita masa układu (obaj kolarze + rowery) [kg].
  final double totalSystemMassKg;

  /// Masa zredukowana pary $\mu_{eff} = \frac{m_1 m_2}{m_1 + m_2}$ [kg].
  final double reducedMassKg;

  /// Efektywność przekazania pędu $\eta_{sling} \in [0, 0.96]$.
  final double transferEfficiency;

  /// Pęd przed zmianą [kg*m/s].
  final double totalMomentumBeforeKgMs;

  /// Pęd po zmianie [kg*m/s] (uwzględnia impuls mięśniowy ramion).
  final double totalMomentumAfterKgMs;

  /// Przekazany impuls pędu [N*s].
  final double transferredImpulseNs;

  /// Dodatkowy impuls mięśniowy z pracy ramion [N*s].
  final double muscularArmImpulseNs;

  /// Prędkość kolarza wchodzącego po wyrzucie [m/s].
  final double outgoingPostSlingSpeedMs;

  /// Prędkość kolarza wchodzącego po wyrzucie [km/h].
  final double outgoingPostSlingSpeedKmh;

  /// Zysk prędkości kolarza wchodzącego [km/h].
  final double outgoingSpeedGainKmh;

  /// Prędkość kolarza schodzącego po oddaniu pędu [m/s].
  final double incomingPostSlingSpeedMs;

  /// Prędkość kolarza schodzącego po oddaniu pędu [km/h].
  final double incomingPostSlingSpeedKmh;

  /// Koszt beztlenowy W' pracy ramion i stabilizacji podczas rzutu [J].
  final double armWorkWPrimeCostJoules;

  /// Czas stracony przy chybionym chwycie lub kraksie [s] (`0.0` dla udanej zmiany).
  final double penaltyTimeLostSeconds;

  const MadisonHandSlingResult({
    required this.quality,
    required this.totalSystemMassKg,
    required this.reducedMassKg,
    required this.transferEfficiency,
    required this.totalMomentumBeforeKgMs,
    required this.totalMomentumAfterKgMs,
    required this.transferredImpulseNs,
    required this.muscularArmImpulseNs,
    required this.outgoingPostSlingSpeedMs,
    required this.outgoingPostSlingSpeedKmh,
    required this.outgoingSpeedGainKmh,
    required this.incomingPostSlingSpeedMs,
    required this.incomingPostSlingSpeedKmh,
    required this.armWorkWPrimeCostJoules,
    required this.penaltyTimeLostSeconds,
  });

  /// Czy przekazanie pędu zakończyło się sukcesem.
  bool get isSuccessfulExchange =>
      quality != MadisonSlingQuality.missedHandTouch &&
      quality != MadisonSlingQuality.illegalPushOrCrash;
}

/// Profil pary kolarzy w wyścigu Madison.
class MadisonTeamRiderPair {
  final String teamId;
  final String teamName;
  final KeirinRiderProfile riderA;
  final KeirinRiderProfile riderB;

  /// Umiejętność rzutu za rękę kolarza A (0–100).
  final double riderASlingSkill;

  /// Umiejętność rzutu za rękę kolarza B (0–100).
  final double riderBSlingSkill;

  /// Zgranie pary (0–100).
  final double teamChemistry;

  /// Co ile okrążeń para wykonuje zmianę `Hand Sling` (typowo 2–4 okrążenia).
  final int exchangeIntervalLaps;

  const MadisonTeamRiderPair({
    required this.teamId,
    required this.teamName,
    required this.riderA,
    required this.riderB,
    this.riderASlingSkill = 82.0,
    this.riderBSlingSkill = 82.0,
    this.teamChemistry = 80.0,
    this.exchangeIntervalLaps = 3,
  });
}

/// Konfiguracja wyścigu Madison (Wyścig Amerykański).
class MadisonRaceConfig {
  final VelodromeFacilitySpec facility;

  /// Liczba okrążeń wyścigu (np. 120 okrążeń = 30 km, 200 okrążeń = 50 km).
  final int totalLaps;

  /// Co ile okrążeń rozgrywany jest punktowany sprint (UCI: co 10 okrążeń).
  final int sprintIntervalLaps;

  /// Punkty za pośredni sprint (domyślnie UCI: 5, 3, 2, 1).
  final List<int> intermediateSprintPoints;

  /// Punkty za nadrobienie / stratę okrążenia (UCI: ±20 pkt).
  final int lapGainPoints;

  const MadisonRaceConfig({
    required this.facility,
    this.totalLaps = 100,
    this.sprintIntervalLaps = 10,
    this.intermediateSprintPoints = const [5, 3, 2, 1],
    this.lapGainPoints = 20,
  });
}

/// Wynik pojedynczego sprintu punktowego w wyścigu Madison.
class MadisonSprintResult {
  final int lapNumber;
  final bool isFinalDoublePoints;
  final Map<String, int> pointsAwardedByTeamId;

  const MadisonSprintResult({
    required this.lapNumber,
    required this.isFinalDoublePoints,
    required this.pointsAwardedByTeamId,
  });
}

/// Końcowa klasyfikacja pary w wyścigu Madison.
class MadisonTeamStanding {
  final String teamId;
  final String teamName;
  final int rank;
  final int totalPoints;
  final int sprintPoints;
  final int lapBalance;
  final int totalHandSlings;
  final int successfulHandSlings;
  final double averageSlingBoostKmh;
  final double averageSpeedKmh;

  const MadisonTeamStanding({
    required this.teamId,
    required this.teamName,
    required this.rank,
    required this.totalPoints,
    required this.sprintPoints,
    required this.lapBalance,
    required this.totalHandSlings,
    required this.successfulHandSlings,
    required this.averageSlingBoostKmh,
    required this.averageSpeedKmh,
  });
}

/// Wynik pełnej symulacji wyścigu Madison.
class MadisonRaceSimulationResult {
  final MadisonRaceConfig config;
  final List<MadisonSprintResult> sprintResults;
  final List<MadisonTeamStanding> standings;

  const MadisonRaceSimulationResult({
    required this.config,
    required this.sprintResults,
    required this.standings,
  });
}

/// Solver fizyki wyścigów torowych **Keirin** (jazda za motocyklem Derny do 50 km/h)
/// oraz **Madison (Wyścig Amerykański)** z fizyką **rzutu za rękę (`Hand Sling`)**.
class VelodromeKeirinAndMadisonSlingSolver {
  VelodromeKeirinAndMadisonSlingSolver._();

  /// Minimalna fizycznie stabilna prędkość kolarza na drewnianym torze [m/s].
  static const double minTrackRidingSpeedMs = 6.5;

  /// Maksymalna bezpieczna prędkość na wirażu welodromu [m/s] (~82 km/h).
  static const double maxTrackSpeedMs = 22.8;

  /// Sprawność konwersji energii potencjalnej zjazdu z górnej linii wiraża na kinetyczną.
  static const double bankingDiveEfficiency = 0.90;

  /// Określa fazę wyścigu Keirin na podstawie przebytego dystansu.
  static KeirinRacePhase resolveKeirinPhase({
    required double elapsedDistanceMeters,
    required double dernyPullOffDistanceMeters,
    required double totalRaceDistanceMeters,
  }) {
    final double pullOffWindowStart =
        math.max(0.0, dernyPullOffDistanceMeters - 25.0);
    final double pullOffWindowEnd = dernyPullOffDistanceMeters + 25.0;
    final double finalSprintStart =
        math.max(pullOffWindowEnd, totalRaceDistanceMeters - 400.0);

    if (elapsedDistanceMeters < pullOffWindowStart) {
      return KeirinRacePhase.dernyRampUp;
    }
    if (elapsedDistanceMeters <= pullOffWindowEnd) {
      return KeirinRacePhase.dernyPullOff;
    }
    if (elapsedDistanceMeters < finalSprintStart) {
      return KeirinRacePhase.tacticalPositioning;
    }
    return KeirinRacePhase.finalSprint;
  }

  /// Wylicza docelową prędkość motocykla Derny [m/s] w funkcji przebytego dystansu.
  ///
  /// Derny rozpędza stawkę płynnie (krzywa S-curve / kosinusoidalna) od `startSpeedKmh`
  /// (domyślnie 30 km/h) do `targetPullOffSpeedKmh` (50 km/h = 13.889 m/s) na zjeździe.
  static double computeDernyTargetSpeedMs({
    required KeirinDernySpec derny,
    required double elapsedDistanceMeters,
    required double dernyPullOffDistanceMeters,
  }) {
    final double vStart = math.max(5.0, derny.startSpeedKmh / 3.6);
    final double vEnd = math.max(vStart, derny.targetPullOffSpeedKmh / 3.6);
    if (dernyPullOffDistanceMeters <= 0.0) {
      return vEnd;
    }
    final double progress =
        (elapsedDistanceMeters / dernyPullOffDistanceMeters).clamp(0.0, 1.0);
    // Płynna krzywa rozpędzania z łagodnym wejściem i precyzyjnym osiągnięciem 50 km/h.
    final double eased = 0.5 - 0.5 * math.cos(math.pi * progress);
    return vStart + (vEnd - vStart) * eased;
  }

  /// Oblicza współczynnik redukcji CdA za motocyklem Derny lub w szyku Keirin.
  ///
  /// - `pacelineSlot == 1`: bezpośrednio na kole Derny (do ~58% redukcji CdA).
  /// - `pacelineSlot > 1`: kolejne miejsca w pociągu za Derny.
  /// - Po zjeździe Derny (`isDernyActive == false`): klasyczny draft torowy między kolarzami.
  static double computeKeirinDraftCdaFactor({
    required KeirinDernySpec derny,
    required int pacelineSlot,
    required double gapToLeadMeters,
    required double lateralOffsetMeters,
    required bool isDernyActive,
  }) {
    final int safeSlot = math.max(1, pacelineSlot);
    final double safeGap = math.max(0.2, gapToLeadMeters);
    final double safeLateral = lateralOffsetMeters.abs();

    // Utrata tunelu aerodynamicznego przy wyjściu na bok (atak lub górna linia wiraża).
    final double lateralDecay = math.exp(-1.45 * safeLateral * safeLateral);

    if (isDernyActive) {
      // Motocykl Derny daje szerszy i głębszy cień aerodynamiczny niż rower.
      final double baseSlotFactor = safeSlot == 1
          ? derny.directSlipstreamCdaFactor
          : (derny.directSlipstreamCdaFactor + 0.055 * (safeSlot - 1))
              .clamp(derny.directSlipstreamCdaFactor, 0.78);
      final double distancePenalty =
          (1.0 - math.exp(-0.22 * math.max(0.0, safeGap - 0.8))) * 0.25;
      final double rawSavings = (1.0 - baseSlotFactor) * lateralDecay;
      return (1.0 - rawSavings + distancePenalty).clamp(0.38, 1.0);
    }

    // Po zjeździe Derny: slot 1 jedzie na czele (brak draftu = 1.0), kolejni korzystają z koła.
    if (safeSlot == 1) {
      return 1.0;
    }
    final double riderDraftBase =
        (0.60 + 0.05 * math.min(safeSlot - 2, 4)).clamp(0.60, 0.82);
    final double gapDecay = math.exp(-0.35 * math.max(0.0, safeGap - 0.6));
    final double savings = (1.0 - riderDraftBase) * lateralDecay * gapDecay;
    return (1.0 - savings).clamp(0.58, 1.0);
  }

  /// Oblicza przyrost prędkości [m/s] wynikający ze zjazdu z górnej części wiraża
  /// (konwersja energii potencjalnej na kinetyczną: $\Delta E_p = m g \Delta y \sin(\theta)$).
  static double computeBankingDiveSpeedGainMs({
    required VelodromeFacilitySpec facility,
    required VelodromeTrackSection section,
    required double previousMetersAboveBlackLine,
    required double currentMetersAboveBlackLine,
    required double currentSpeedMs,
  }) {
    final double deltaHeightTrack =
        previousMetersAboveBlackLine - currentMetersAboveBlackLine;
    if (deltaHeightTrack <= 0.0 || currentSpeedMs <= 1.0) {
      return 0.0;
    }
    final double bankDeg =
        VelodromeBankingAndCentripetalSolver.localBankingAngleDegrees(
      facility: facility,
      section: section,
    );
    final double bankRad = bankDeg.clamp(5.0, 50.0) * (math.pi / 180.0);
    final double verticalDropMeters = deltaHeightTrack * math.sin(bankRad);
    final double specificKineticEnergy =
        0.5 * currentSpeedMs * currentSpeedMs +
            bankingDiveEfficiency * PhysicsConstants.gravity * verticalDropMeters;
    final double newSpeedMs = math.sqrt(math.max(0.0, 2.0 * specificKineticEnergy));
    return math.max(0.0, newSpeedMs - currentSpeedMs);
  }

  /// Rozwiązuje pojedynczy krok fizyczny wyścigu Keirin.
  static KeirinStepResult solveKeirinStep(KeirinStepInput input) {
    final double safeDt = input.dtSeconds.clamp(0.05, 2.0);
    final double safeCurrentSpeedMs = math.max(1.0, input.currentSpeedMs);
    final double dernyPullOffDist =
        input.derny.pacedLaps * input.facility.trackLengthMeters;

    final KeirinRacePhase phase = resolveKeirinPhase(
      elapsedDistanceMeters: input.elapsedDistanceMeters,
      dernyPullOffDistanceMeters: dernyPullOffDist,
      totalRaceDistanceMeters: input.totalRaceDistanceMeters,
    );

    final bool isDernyActive = phase == KeirinRacePhase.dernyRampUp;
    final double dernyTargetSpeedMs = computeDernyTargetSpeedMs(
      derny: input.derny,
      elapsedDistanceMeters: input.elapsedDistanceMeters,
      dernyPullOffDistanceMeters: dernyPullOffDist,
    );

    final double cdaFactor = computeKeirinDraftCdaFactor(
      derny: input.derny,
      pacelineSlot: input.pacelineSlot,
      gapToLeadMeters: input.gapToDernyMeters,
      lateralOffsetMeters: input.lateralOffsetMeters,
      isDernyActive: isDernyActive,
    );

    final double effectiveCdaM2 = input.rider.bike.cdaMetersSquared * cdaFactor;

    final VelodromeBankingPhysicsResult bankingPhysics =
        VelodromeBankingAndCentripetalSolver.solveInstantaneousPhysics(
      VelodromePhysicsInput(
        facility: input.facility,
        bike: input.rider.bike,
        riderMassKg: input.rider.riderMassKg,
        speedMs: safeCurrentSpeedMs,
        section: input.section,
        metersAboveBlackLine: input.metersAboveBlackLine,
        customCda: effectiveCdaM2,
      ),
    );

    final double mechEfficiency = input.rider.bike.drivetrainEfficiency;
    final double netPropulsivePowerW =
        math.max(0.0, input.riderPowerWatts) * mechEfficiency;
    final double resistancePowerW = bankingPhysics.wheelPowerWatts;
    final double totalMassKg = bankingPhysics.totalMassKg;

    // Równanie bilansu mocy: dE_k / dt = P_prop - P_res => dv / dt = (P_prop - P_res) / (m * v).
    final double netPowerW = netPropulsivePowerW - resistancePowerW;
    final double accelerationMs2 =
        netPowerW / (totalMassKg * math.max(4.0, safeCurrentSpeedMs));

    final double diveGainMs = computeBankingDiveSpeedGainMs(
      facility: input.facility,
      section: input.section,
      previousMetersAboveBlackLine: input.previousMetersAboveBlackLine,
      currentMetersAboveBlackLine: input.metersAboveBlackLine,
      currentSpeedMs: safeCurrentSpeedMs,
    );

    double nextSpeedMs =
        (safeCurrentSpeedMs + accelerationMs2 * safeDt + diveGainMs)
            .clamp(minTrackRidingSpeedMs, maxTrackSpeedMs);

    // Podczas jazdy za Derny lider nie może wyprzedzić motocykla (chyba że popełni faul).
    final bool illegalDernyPass = isDernyActive &&
        input.pacelineSlot == 1 &&
        input.gapToDernyMeters < -0.15;

    final double nextCadenceRpm =
        input.rider.bike.cadenceRpmFromSpeedKmh(nextSpeedMs * 3.6);
    final double wPrimeDelta =
        (input.rider.criticalPowerWatts - input.riderPowerWatts) * safeDt;

    return KeirinStepResult(
      phase: phase,
      dernyTargetSpeedMs: dernyTargetSpeedMs,
      dernyTargetSpeedKmh: dernyTargetSpeedMs * 3.6,
      effectiveCdaFactor: cdaFactor,
      effectiveCdaM2: effectiveCdaM2,
      netPropulsivePowerWatts: netPropulsivePowerW,
      totalResistancePowerWatts: resistancePowerW,
      bankingDiveSpeedGainMs: diveGainMs,
      nextSpeedMs: nextSpeedMs,
      nextSpeedKmh: nextSpeedMs * 3.6,
      cadenceRpm: nextCadenceRpm,
      gForceLoadFactor: bankingPhysics.gForceLoadFactor,
      wPrimeDeltaJoules: wPrimeDelta,
      hasPassedDernyIllegally: illegalDernyPass,
    );
  }

  /// Symuluje pełny wyścig torowy Keirin (np. 6 okrążeń = 1500 m) dla listy kolarzy.
  static KeirinRaceSimulationResult simulateKeirinRace({
    required KeirinRaceConfig config,
    required List<KeirinRiderProfile> riders,
  }) {
    if (riders.isEmpty) {
      return KeirinRaceSimulationResult(
        config: config,
        dernyPullOffSpeedKmh: config.derny.targetPullOffSpeedKmh,
        standings: const [],
      );
    }

    final double totalDist = config.totalDistanceMeters;
    final double pullOffDist = config.dernyPullOffDistanceMeters;
    final double dt = config.dtSeconds.clamp(0.1, 1.0);
    final double lapLength = config.facility.trackLengthMeters;

    final List<KeirinRiderProfile> sortedBySlot = List.of(riders)
      ..sort((a, b) => a.startingSlot.compareTo(b.startingSlot));

    final int count = sortedBySlot.length;
    final List<double> distances = List<double>.filled(count, 0.0);
    final List<double> speeds = List<double>.filled(
      count,
      config.derny.startSpeedKmh / 3.6,
    );
    final List<double> wPrimes =
        sortedBySlot.map((r) => r.wPrimeJoules).toList();
    final List<double> peakSpeedsKmh =
        List<double>.filled(count, config.derny.startSpeedKmh);
    final List<double> speedAtPullOffKmh =
        List<double>.filled(count, config.derny.targetPullOffSpeedKmh);
    final List<bool> capturedPullOff = List<bool>.filled(count, false);
    final List<double?> finishTimes = List<double?>.filled(count, null);
    final List<double> laneHeights = List<double>.filled(count, 0.25);

    double elapsedTime = 0.0;
    double dernyPullOffRecordedSpeedKmh = config.derny.targetPullOffSpeedKmh;

    // Maksymalnie 300 s bezpieczeństwa przed nieskończoną pętlą.
    while (elapsedTime < 300.0 && finishTimes.any((t) => t == null)) {
      elapsedTime += dt;

      // Wyznacz aktualne miejsca w szyku (slot 1 = najbardziej wysunięty kolarz).
      final List<int> order = List<int>.generate(count, (i) => i)
        ..sort((a, b) => distances[b].compareTo(distances[a]));
      final List<int> slots = List<int>.filled(count, 1);
      for (int rank = 0; rank < count; rank++) {
        slots[order[rank]] = rank + 1;
      }

      for (int i = 0; i < count; i++) {
        if (finishTimes[i] != null) continue;

        final KeirinRiderProfile rider = sortedBySlot[i];
        final double dist = distances[i];
        final double speed = speeds[i];
        final double remaining = math.max(0.0, totalDist - dist);

        final double lapFraction = (dist % lapLength) / lapLength;
        final VelodromeTrackSection section = (lapFraction < 0.22 ||
                (lapFraction >= 0.50 && lapFraction < 0.72))
            ? VelodromeTrackSection.straight
            : VelodromeTrackSection.turnApex;

        final double dernySpeedMs = computeDernyTargetSpeedMs(
          derny: config.derny,
          elapsedDistanceMeters: dist,
          dernyPullOffDistanceMeters: pullOffDist,
        );

        final bool behindDerny = dist < pullOffDist;
        final double prevHeight = laneHeights[i];
        double targetHeight = prevHeight;
        double targetPowerW;

        if (behindDerny) {
          // Za Derny kolarze jadą równo w szyku, utrzymując prędkość motocykla.
          targetHeight = 0.15 + (slots[i] - 1) * 0.12;
          final double speedErrorMs = dernySpeedMs - speed;
          // Uproszczony regulator tempa trzymający koło Derny.
          final double steadyEstimate =
              VelodromeBankingAndCentripetalSolver.solveInstantaneousPhysics(
            VelodromePhysicsInput(
              facility: config.facility,
              bike: rider.bike,
              riderMassKg: rider.riderMassKg,
              speedMs: dernySpeedMs,
              section: section,
              metersAboveBlackLine: targetHeight,
              customCda: rider.bike.cdaMetersSquared *
                  computeKeirinDraftCdaFactor(
                    derny: config.derny,
                    pacelineSlot: slots[i],
                    gapToLeadMeters: 1.0,
                    lateralOffsetMeters: 0.0,
                    isDernyActive: true,
                  ),
            ),
          ).requiredRiderPowerWatts;
          targetPowerW =
              (steadyEstimate + speedErrorMs * 260.0).clamp(150.0, 950.0);
        } else {
          if (!capturedPullOff[i]) {
            capturedPullOff[i] = true;
            speedAtPullOffKmh[i] = speed * 3.6;
            if (slots[i] == 1) {
              dernyPullOffRecordedSpeedKmh = dernySpeedMs * 3.6;
            }
          }

          if (remaining > 400.0) {
            // Faza taktyczna: podjazd wyżej na wiraż dla uzyskania energii potencjalnej.
            final double skillFactor =
                (rider.trackTacticsSkill / 100.0).clamp(0.4, 1.0);
            targetHeight = slots[i] == 1 ? 0.25 : (1.1 + 1.1 * skillFactor);
            targetPowerW = rider.criticalPowerWatts * (1.25 + 0.35 * skillFactor);
          } else {
            // Ostatnie 400 m: zjazd po wirażu na czarną linię i maksymalny sprint.
            targetHeight = 0.05;
            final double wPrimeRatio =
                (wPrimes[i] / math.max(1.0, rider.wPrimeJoules))
                    .clamp(0.0, 1.0);
            final double sprintFactor = 0.45 + 0.55 * wPrimeRatio;
            targetPowerW = rider.criticalPowerWatts +
                (rider.peakSprintPowerWatts - rider.criticalPowerWatts) *
                    sprintFactor;
          }
        }

        laneHeights[i] = targetHeight;

        final KeirinStepResult step = solveKeirinStep(
          KeirinStepInput(
            facility: config.facility,
            derny: config.derny,
            rider: rider,
            elapsedDistanceMeters: dist,
            totalRaceDistanceMeters: totalDist,
            currentSpeedMs: speed,
            riderPowerWatts: targetPowerW,
            pacelineSlot: slots[i],
            gapToDernyMeters: 1.0 + (slots[i] - 1) * 1.6,
            lateralOffsetMeters:
                behindDerny ? 0.0 : (targetHeight - prevHeight).abs() * 0.35,
            metersAboveBlackLine: targetHeight,
            previousMetersAboveBlackLine: prevHeight,
            section: section,
            dtSeconds: dt,
          ),
        );

        speeds[i] = step.nextSpeedMs;
        wPrimes[i] = math.max(0.0, wPrimes[i] + step.wPrimeDeltaJoules);
        if (step.nextSpeedKmh > peakSpeedsKmh[i]) {
          peakSpeedsKmh[i] = step.nextSpeedKmh;
        }

        final double prevDist = distances[i];
        final double nextDist = prevDist + step.nextSpeedMs * dt;
        distances[i] = nextDist;

        if (nextDist >= totalDist) {
          final double fraction =
              (totalDist - prevDist) / math.max(0.001, nextDist - prevDist);
          finishTimes[i] = elapsedTime - dt + dt * fraction;
        }
      }
    }

    final List<int> finalOrder = List<int>.generate(count, (i) => i)
      ..sort((a, b) {
        final double ta = finishTimes[a] ?? 9999.0;
        final double tb = finishTimes[b] ?? 9999.0;
        return ta.compareTo(tb);
      });

    final List<KeirinRiderRaceOutcome> standings = [];
    for (int pos = 0; pos < finalOrder.length; pos++) {
      final int idx = finalOrder[pos];
      final KeirinRiderProfile rider = sortedBySlot[idx];
      standings.add(
        KeirinRiderRaceOutcome(
          riderId: rider.riderId,
          name: rider.name,
          finishingPosition: pos + 1,
          finishTimeSeconds: finishTimes[idx] ?? elapsedTime,
          peakSpeedKmh: peakSpeedsKmh[idx],
          speedAtDernyPullOffKmh: speedAtPullOffKmh[idx],
          remainingWPrimeJoules: wPrimes[idx],
          disqualifiedForPassingDerny: false,
        ),
      );
    }

    return KeirinRaceSimulationResult(
      config: config,
      dernyPullOffSpeedKmh: dernyPullOffRecordedSpeedKmh,
      standings: standings,
    );
  }

  /// Rozwiązuje fizykę **rzutu za rękę (`Hand Sling`)** w wyścigu Madison (Wyścig Amerykański).
  ///
  /// Modeluje:
  /// 1. Zasadę zachowania pędu układu 2 kolarzy: $p = m_{in} v_{in} + m_{out} v_{out}$.
  /// 2. Przekazanie impulsu z użyciem masy zredukowanej $\mu_{eff} = \frac{m_{in} m_{out}}{m_{in} + m_{out}}$
  ///    oraz sprawności technicznej $\eta_{sling}$ zależnej od umiejętności, zgrania i geometrii chwytu.
  /// 3. Dodatkowy impuls mięśniowy z pracy ramion podczas obrotu i wypchnięcia partnera.
  static MadisonHandSlingResult solveMadisonHandSling(
    MadisonHandSlingInput input,
  ) {
    final double mIn =
        math.max(40.0, input.incomingRiderMassKg + input.incomingBike.bikeWeightKg);
    final double mOut =
        math.max(40.0, input.outgoingRiderMassKg + input.outgoingBike.bikeWeightKg);
    final double totalMass = mIn + mOut;
    final double reducedMass = (mIn * mOut) / totalMass;

    final double vIn = math.max(1.0, input.incomingSpeedMs);
    final double vOut = math.max(1.0, input.outgoingSpeedMs);
    final double momentumBefore = mIn * vIn + mOut * vOut;
    final double speedDelta = vIn - vOut;

    final double avgSkill =
        ((input.incomingSlingSkill + input.outgoingSlingSkill) * 0.5)
            .clamp(0.0, 100.0);
    final double chemistry = input.teamChemistry.clamp(0.0, 100.0);

    // Sprawdzenie błędu pozycjonowania lub nadmiernej różnicy prędkości.
    final bool outOfReach = input.longitudinalGapMeters.abs() > 1.35 ||
        input.lateralGapMeters.abs() > 1.50 ||
        speedDelta <= 0.4;

    if (outOfReach) {
      return MadisonHandSlingResult(
        quality: MadisonSlingQuality.missedHandTouch,
        totalSystemMassKg: totalMass,
        reducedMassKg: reducedMass,
        transferEfficiency: 0.0,
        totalMomentumBeforeKgMs: momentumBefore,
        totalMomentumAfterKgMs: momentumBefore,
        transferredImpulseNs: 0.0,
        muscularArmImpulseNs: 0.0,
        outgoingPostSlingSpeedMs: vOut,
        outgoingPostSlingSpeedKmh: vOut * 3.6,
        outgoingSpeedGainKmh: 0.0,
        incomingPostSlingSpeedMs: vIn,
        incomingPostSlingSpeedKmh: vIn * 3.6,
        armWorkWPrimeCostJoules: 45.0,
        penaltyTimeLostSeconds: 1.85,
      );
    }

    // Zbyt duża różnica prędkości (> 11.5 m/s = > 41 km/h różnicy) przy słabej technice grozi kraksą.
    final double crashThresholdDelta = 9.5 + (avgSkill / 100.0) * 3.0;
    if (speedDelta > crashThresholdDelta) {
      final double slowedIn = math.max(minTrackRidingSpeedMs, vIn * 0.62);
      final double slowedOut = math.max(minTrackRidingSpeedMs, vOut * 0.88);
      return MadisonHandSlingResult(
        quality: MadisonSlingQuality.illegalPushOrCrash,
        totalSystemMassKg: totalMass,
        reducedMassKg: reducedMass,
        transferEfficiency: 0.15,
        totalMomentumBeforeKgMs: momentumBefore,
        totalMomentumAfterKgMs: mIn * slowedIn + mOut * slowedOut,
        transferredImpulseNs: 0.0,
        muscularArmImpulseNs: 0.0,
        outgoingPostSlingSpeedMs: slowedOut,
        outgoingPostSlingSpeedKmh: slowedOut * 3.6,
        outgoingSpeedGainKmh: (slowedOut - vOut) * 3.6,
        incomingPostSlingSpeedMs: slowedIn,
        incomingPostSlingSpeedKmh: slowedIn * 3.6,
        armWorkWPrimeCostJoules: 320.0,
        penaltyTimeLostSeconds: 6.50,
      );
    }

    // Sprawność transferu pędu (0.58 - 0.96): najwyższa na wyjściu z wiraża i przy małym odstępie.
    final double skillNorm = avgSkill / 100.0;
    final double chemNorm = chemistry / 100.0;
    final double alignmentPenalty =
        (input.longitudinalGapMeters.abs() * 0.12 +
                (input.lateralGapMeters.abs() - 0.65).abs() * 0.10)
            .clamp(0.0, 0.25);
    final double sectionBonus =
        input.section == VelodromeTrackSection.transitionExit ? 0.03 : 0.0;

    final double transferEfficiency = (0.62 +
            0.22 * skillNorm +
            0.10 * chemNorm +
            sectionBonus -
            alignmentPenalty)
        .clamp(0.55, 0.96);

    // Impuls wymiany pędu bazujący na zderzeniu częściowo sprężystym z podciągnięciem:
    // J_inertia = (1 + e_sling) * mu * delta_v, gdzie e_sling rośnie ze sprawnością.
    final double restitutionAnalog = 0.25 + 0.55 * transferEfficiency;
    final double inertiaImpulseNs =
        (1.0 + restitutionAnalog) * reducedMass * speedDelta * transferEfficiency;

    // Praca mięśniowa ramion (ciągnięcie w przód przy wypchnięciu partnera): 100-220 N przez ~0.55 s.
    final double safeDuration = input.gripDurationSeconds.clamp(0.30, 0.90);
    final double armForceNewtons = 95.0 + 115.0 * skillNorm * transferEfficiency;
    final double muscularArmImpulseNs = armForceNewtons * safeDuration;

    final double totalOutgoingImpulseNs =
        inertiaImpulseNs + muscularArmImpulseNs;

    // Zjazd kolarza wchodzącego z wyższej linii wiraża daje mały bonus energii potencjalnej.
    final double diveBonusMs = computeBankingDiveSpeedGainMs(
      facility: input.facility,
      section: input.section,
      previousMetersAboveBlackLine: input.outgoingMetersAboveBlackLine,
      currentMetersAboveBlackLine: 0.20,
      currentSpeedMs: vOut,
    );

    final double postOutSpeedMs = (vOut +
            totalOutgoingImpulseNs / mOut +
            diveBonusMs)
        .clamp(minTrackRidingSpeedMs, maxTrackSpeedMs);

    // Kolarz schodzący oddaje impuls bezwładnościowy oraz część reakcji ramienia.
    final double incomingRecoilImpulseNs =
        inertiaImpulseNs + muscularArmImpulseNs * 0.55;
    final double postInSpeedMs = math.max(
      minTrackRidingSpeedMs,
      vIn - incomingRecoilImpulseNs / mIn,
    );

    final double momentumAfter = mIn * postInSpeedMs + mOut * postOutSpeedMs;
    final double speedGainKmh = (postOutSpeedMs - vOut) * 3.6;

    final MadisonSlingQuality quality;
    if (transferEfficiency >= 0.87 && speedGainKmh >= 12.0) {
      quality = MadisonSlingQuality.textbookSlingshot;
    } else if (transferEfficiency >= 0.72) {
      quality = MadisonSlingQuality.cleanExchange;
    } else {
      quality = MadisonSlingQuality.awkwardFumble;
    }

    final double armWorkCostJoules =
        (armForceNewtons * 0.85 * safeDuration * 2.2) +
            (quality == MadisonSlingQuality.awkwardFumble ? 85.0 : 0.0);

    return MadisonHandSlingResult(
      quality: quality,
      totalSystemMassKg: totalMass,
      reducedMassKg: reducedMass,
      transferEfficiency: transferEfficiency,
      totalMomentumBeforeKgMs: momentumBefore,
      totalMomentumAfterKgMs: momentumAfter,
      transferredImpulseNs: totalOutgoingImpulseNs,
      muscularArmImpulseNs: muscularArmImpulseNs,
      outgoingPostSlingSpeedMs: postOutSpeedMs,
      outgoingPostSlingSpeedKmh: postOutSpeedMs * 3.6,
      outgoingSpeedGainKmh: speedGainKmh,
      incomingPostSlingSpeedMs: postInSpeedMs,
      incomingPostSlingSpeedKmh: postInSpeedMs * 3.6,
      armWorkWPrimeCostJoules: armWorkCostJoules,
      penaltyTimeLostSeconds:
          quality == MadisonSlingQuality.awkwardFumble ? 0.35 : 0.0,
    );
  }

  /// Symuluje wielookrążeniowy wyścig **Madison** ze sprintami co 10 okrążeń,
  /// punktacją ±20 pkt za nadrobione okrążenia oraz zmianami `Hand Sling`.
  static MadisonRaceSimulationResult simulateMadisonRace({
    required MadisonRaceConfig config,
    required List<MadisonTeamRiderPair> teams,
  }) {
    if (teams.isEmpty || config.totalLaps <= 0) {
      return MadisonRaceSimulationResult(
        config: config,
        sprintResults: const [],
        standings: const [],
      );
    }

    final int teamCount = teams.length;
    final double lapLen = config.facility.trackLengthMeters;

    final List<bool> isRiderAActive = List<bool>.filled(teamCount, true);
    final List<double> activeSpeedMs = List<double>.filled(teamCount, 14.5);
    final List<double> wPrimeA =
        teams.map((t) => t.riderA.wPrimeJoules).toList();
    final List<double> wPrimeB =
        teams.map((t) => t.riderB.wPrimeJoules).toList();
    final List<double> cumulativeTimeS = List<double>.filled(teamCount, 0.0);
    final List<int> sprintPoints = List<int>.filled(teamCount, 0);
    final List<int> lapBalance = List<int>.filled(teamCount, 0);
    final List<int> totalSlings = List<int>.filled(teamCount, 0);
    final List<int> successfulSlings = List<int>.filled(teamCount, 0);
    final List<double> slingBoostSumKmh = List<double>.filled(teamCount, 0.0);

    final List<MadisonSprintResult> sprintResults = [];

    for (int lap = 1; lap <= config.totalLaps; lap++) {
      final bool isSprintLap = config.sprintIntervalLaps > 0 &&
          (lap % config.sprintIntervalLaps == 0 || lap == config.totalLaps);
      final bool isFinalSprint = lap == config.totalLaps;

      for (int i = 0; i < teamCount; i++) {
        final MadisonTeamRiderPair pair = teams[i];
        final bool aActive = isRiderAActive[i];
        final KeirinRiderProfile activeRider = aActive ? pair.riderA : pair.riderB;
        final KeirinRiderProfile reliefRider = aActive ? pair.riderB : pair.riderA;

        // Zmiana Hand Sling przed sprintem lub co ustaloną liczbę okrążeń.
        final bool shouldSling = lap > 1 &&
            (lap % math.max(1, pair.exchangeIntervalLaps) == 0 || isSprintLap);

        if (shouldSling) {
          final MadisonHandSlingResult sling = solveMadisonHandSling(
            MadisonHandSlingInput(
              facility: config.facility,
              incomingRiderMassKg: activeRider.riderMassKg,
              incomingBike: activeRider.bike,
              incomingSpeedMs: activeSpeedMs[i],
              outgoingRiderMassKg: reliefRider.riderMassKg,
              outgoingBike: reliefRider.bike,
              outgoingSpeedMs: 9.6, // ~34.5 km/h odpoczynek na górze toru
              incomingSlingSkill:
                  aActive ? pair.riderASlingSkill : pair.riderBSlingSkill,
              outgoingSlingSkill:
                  aActive ? pair.riderBSlingSkill : pair.riderASlingSkill,
              teamChemistry: pair.teamChemistry,
            ),
          );

          totalSlings[i]++;
          if (sling.isSuccessfulExchange) {
            successfulSlings[i]++;
            slingBoostSumKmh[i] += sling.outgoingSpeedGainKmh;
            activeSpeedMs[i] = sling.outgoingPostSlingSpeedMs;
            isRiderAActive[i] = !aActive;
          } else {
            cumulativeTimeS[i] += sling.penaltyTimeLostSeconds;
            activeSpeedMs[i] = math.max(12.8, activeSpeedMs[i] - 1.2);
          }

          if (aActive) {
            wPrimeA[i] = math.max(0.0, wPrimeA[i] - sling.armWorkWPrimeCostJoules);
          } else {
            wPrimeB[i] = math.max(0.0, wPrimeB[i] - sling.armWorkWPrimeCostJoules);
          }
        }

        // Wylicz moc na okrążeniu (wyższa na okrążeniach sprinterskich).
        final bool newAActive = isRiderAActive[i];
        final KeirinRiderProfile currentActive =
            newAActive ? pair.riderA : pair.riderB;
        final double activeWPrime = newAActive ? wPrimeA[i] : wPrimeB[i];
        final double wPrimeRatio =
            (activeWPrime / math.max(1.0, currentActive.wPrimeJoules))
                .clamp(0.0, 1.0);

        final double targetSpeedMs = isSprintLap
            ? (16.5 + 2.2 * wPrimeRatio) // 59.4–67.3 km/h w sprincie
            : (14.4 + 0.8 * wPrimeRatio); // 51.8–54.7 km/h tempo peletonu

        // Wygładzenie prędkości okrążenia + czas okrążenia.
        final double lapSpeedMs =
            (activeSpeedMs[i] * 0.35 + targetSpeedMs * 0.65)
                .clamp(minTrackRidingSpeedMs, maxTrackSpeedMs);
        activeSpeedMs[i] = lapSpeedMs;

        final VelodromeBankingPhysicsResult physics =
            VelodromeBankingAndCentripetalSolver.solveInstantaneousPhysics(
          VelodromePhysicsInput(
            facility: config.facility,
            bike: currentActive.bike,
            riderMassKg: currentActive.riderMassKg,
            speedMs: lapSpeedMs,
            section: VelodromeTrackSection.turnApex,
            metersAboveBlackLine: 0.25,
            customCda: currentActive.bike.cdaMetersSquared * 0.72,
          ),
        );

        final double lapTimeS = lapLen / lapSpeedMs;
        cumulativeTimeS[i] += lapTimeS;

        // Zużycie W' aktywnego kolarza i regeneracja W' kolarza odpoczywającego.
        final double activeDeltaW =
            (currentActive.criticalPowerWatts - physics.requiredRiderPowerWatts) *
                lapTimeS;
        if (newAActive) {
          wPrimeA[i] = (wPrimeA[i] + activeDeltaW)
              .clamp(0.0, pair.riderA.wPrimeJoules);
          wPrimeB[i] = math.min(
            pair.riderB.wPrimeJoules,
            wPrimeB[i] + 220.0 * lapTimeS,
          );
        } else {
          wPrimeB[i] = (wPrimeB[i] + activeDeltaW)
              .clamp(0.0, pair.riderB.wPrimeJoules);
          wPrimeA[i] = math.min(
            pair.riderA.wPrimeJoules,
            wPrimeA[i] + 220.0 * lapTimeS,
          );
        }
      }

      if (isSprintLap) {
        final List<int> sprintOrder = List<int>.generate(teamCount, (i) => i)
          ..sort((a, b) => cumulativeTimeS[a].compareTo(cumulativeTimeS[b]));
        final int multiplier = isFinalSprint ? 2 : 1;
        final Map<String, int> awarded = {};
        for (int place = 0;
            place < sprintOrder.length &&
                place < config.intermediateSprintPoints.length;
            place++) {
          final int teamIdx = sprintOrder[place];
          final int pts = config.intermediateSprintPoints[place] * multiplier;
          sprintPoints[teamIdx] += pts;
          awarded[teams[teamIdx].teamId] = pts;
        }
        sprintResults.add(
          MadisonSprintResult(
            lapNumber: lap,
            isFinalDoublePoints: isFinalSprint,
            pointsAwardedByTeamId: awarded,
          ),
        );
      }
    }

    // Wykrycie nadrobionych / straconych okrążeń względem mediany czasu stawki.
    final List<double> sortedTimes = List<double>.of(cumulativeTimeS)..sort();
    final double medianTimeS = sortedTimes[sortedTimes.length ~/ 2];
    final double avgLapTimeS = medianTimeS / config.totalLaps;

    for (int i = 0; i < teamCount; i++) {
      final double deltaTimeS = medianTimeS - cumulativeTimeS[i];
      if (avgLapTimeS > 0.1) {
        final int gainedOrLostLaps = (deltaTimeS / avgLapTimeS).truncate();
        lapBalance[i] = gainedOrLostLaps;
      }
    }

    final List<int> finalOrder = List<int>.generate(teamCount, (i) => i)
      ..sort((a, b) {
        final int totalA =
            sprintPoints[a] + lapBalance[a] * config.lapGainPoints;
        final int totalB =
            sprintPoints[b] + lapBalance[b] * config.lapGainPoints;
        if (totalB != totalA) return totalB.compareTo(totalA);
        return cumulativeTimeS[a].compareTo(cumulativeTimeS[b]);
      });

    final double totalDistM = config.totalLaps * lapLen;
    final List<MadisonTeamStanding> standings = [];
    for (int rank = 0; rank < finalOrder.length; rank++) {
      final int idx = finalOrder[rank];
      final MadisonTeamRiderPair pair = teams[idx];
      final int totalPts =
          sprintPoints[idx] + lapBalance[idx] * config.lapGainPoints;
      final double avgBoost = successfulSlings[idx] > 0
          ? slingBoostSumKmh[idx] / successfulSlings[idx]
          : 0.0;
      final double avgSpeedKmh = cumulativeTimeS[idx] > 0.0
          ? (totalDistM / cumulativeTimeS[idx]) * 3.6
          : 0.0;

      standings.add(
        MadisonTeamStanding(
          teamId: pair.teamId,
          teamName: pair.teamName,
          rank: rank + 1,
          totalPoints: totalPts,
          sprintPoints: sprintPoints[idx],
          lapBalance: lapBalance[idx],
          totalHandSlings: totalSlings[idx],
          successfulHandSlings: successfulSlings[idx],
          averageSlingBoostKmh: avgBoost,
          averageSpeedKmh: avgSpeedKmh,
        ),
      );
    }

    return MadisonRaceSimulationResult(
      config: config,
      sprintResults: sprintResults,
      standings: standings,
    );
  }
}
