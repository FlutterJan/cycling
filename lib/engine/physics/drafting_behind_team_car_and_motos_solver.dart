import 'dart:math' as math;

import '../../core/constants/physics_constants.dart';

/// Typ pojazdu w kolumnie wyścigowej (karawanie) lub eskorcie medialnej/sędziowskiej.
enum CaravanVehicleType {
  /// Motocykl transmisji telewizyjnej (wąski ślad aero, wysoka ekspozycja na kamery).
  tvBroadcastMoto(
    labelEn: 'TV Broadcast Moto',
    labelPl: 'Motocykl TV',
    frontalAreaM2: 0.85,
    dragCoefficient: 0.78,
    effectiveWidthMeters: 0.90,
    coreWakeLengthMeters: 1.4,
    wakeDecayLengthMeters: 4.2,
    maxDraftReduction: 0.36,
    turbulenceIntensity: 0.14,
    scrutinyMultiplier: 1.35,
  ),

  /// Motocykl komisarza UCI lub regulatora ruchu wyścigowego.
  commissaireMoto(
    labelEn: 'Commissaire Moto',
    labelPl: 'Motocykl Komisarza UCI',
    frontalAreaM2: 0.82,
    dragCoefficient: 0.76,
    effectiveWidthMeters: 0.85,
    coreWakeLengthMeters: 1.3,
    wakeDecayLengthMeters: 4.0,
    maxDraftReduction: 0.33,
    turbulenceIntensity: 0.12,
    scrutinyMultiplier: 2.20,
  ),

  /// Wóz techniczny dyrektora sportowego z bagażnikiem rowerowym na dachu.
  teamSupportCar(
    labelEn: 'Team DS Car',
    labelPl: 'Wóz Techniczny DS',
    frontalAreaM2: 2.68,
    dragCoefficient: 0.44,
    effectiveWidthMeters: 1.92,
    coreWakeLengthMeters: 3.6,
    wakeDecayLengthMeters: 10.5,
    maxDraftReduction: 0.70,
    turbulenceIntensity: 0.24,
    scrutinyMultiplier: 1.00,
  ),

  /// Wóz neutralnej pomocy technicznej (Shimano/Mavic) z rowerami na dachu.
  neutralServiceCar(
    labelEn: 'Neutral Service Car',
    labelPl: 'Wóz Neutralny',
    frontalAreaM2: 2.58,
    dragCoefficient: 0.43,
    effectiveWidthMeters: 1.88,
    coreWakeLengthMeters: 3.4,
    wakeDecayLengthMeters: 9.8,
    maxDraftReduction: 0.67,
    turbulenceIntensity: 0.22,
    scrutinyMultiplier: 1.15,
  ),

  /// Samochód lekarza wyścigowego (brak bagażnika dachowego — gładszy ślad).
  raceDoctorCar(
    labelEn: 'Race Doctor Car',
    labelPl: 'Wóz Lekarski',
    frontalAreaM2: 2.42,
    dragCoefficient: 0.36,
    effectiveWidthMeters: 1.84,
    coreWakeLengthMeters: 3.1,
    wakeDecayLengthMeters: 8.8,
    maxDraftReduction: 0.61,
    turbulenceIntensity: 0.15,
    scrutinyMultiplier: 1.55,
  );

  final String labelEn;
  final String labelPl;
  final double frontalAreaM2;
  final double dragCoefficient;
  final double effectiveWidthMeters;
  final double coreWakeLengthMeters;
  final double wakeDecayLengthMeters;
  final double maxDraftReduction;
  final double turbulenceIntensity;
  final double scrutinyMultiplier;

  const CaravanVehicleType({
    required this.labelEn,
    required this.labelPl,
    required this.frontalAreaM2,
    required this.dragCoefficient,
    required this.effectiveWidthMeters,
    required this.coreWakeLengthMeters,
    required this.wakeDecayLengthMeters,
    required this.maxDraftReduction,
    required this.turbulenceIntensity,
    required this.scrutinyMultiplier,
  });

  /// Czy pojazd należy do klasy motocykli (mniejszy cień, trudniejszy do utrzymania w bocznym wietrze).
  bool get isMotorbike =>
      this == CaravanVehicleType.tvBroadcastMoto ||
      this == CaravanVehicleType.commissaireMoto;
}

/// Kontekst taktyczno-regulaminowy jazdy w cieniu pojazdu karawany.
enum CaravanDraftingContext {
  /// Powrót do peletonu po defekcie technicznym lub kraksie (wysoka tolerancja sędziów).
  mechanicalOrCrashReturn(
    labelEn: 'Mechanical / Crash Return',
    labelPl: 'Powrót po defekcie / kraksie',
    toleranceFactor: 0.42,
  ),

  /// Pogoń odpadniętego kolarza przez kolumnę wozów (umiarkowana tolerancja).
  droppedRiderConvoyHop(
    labelEn: 'Dropped Rider Convoy Hop',
    labelPl: 'Skok przez kolumnę wozów',
    toleranceFactor: 0.95,
  ),

  /// Jazda w śladzie motocykla TV w ucieczce lub pogoni (duża uwaga sędziów).
  breakawayMotoPacing(
    labelEn: 'Breakaway Moto Pacing',
    labelPl: 'Jazda za motocyklem w ucieczce',
    toleranceFactor: 1.45,
  ),

  /// Pogoń grupy pościgowej za motocyklem transmisji.
  pelotonChaseMotoPacing(
    labelEn: 'Chase Group Moto Pacing',
    labelPl: 'Pogoń za motocyklem TV',
    toleranceFactor: 1.20,
  ),

  /// Strefa finałowa (<20 km do mety) — ścisły zakaz korzystania z osłony wozów.
  finalKilometersNoShelter(
    labelEn: 'Final <20 km Strict Ban',
    labelPl: 'Strefa finałowa (<20 km) — zakaz',
    toleranceFactor: 2.15,
  );

  final String labelEn;
  final String labelPl;
  final double toleranceFactor;

  const CaravanDraftingContext({
    required this.labelEn,
    required this.labelPl,
    required this.toleranceFactor,
  });
}

/// Poziom ryzyka interwencji komisarza UCI dla aktualnego manewru.
enum CaravanPenaltyRiskLevel {
  /// Jazda dozwolona lub poniżej progu wykrywalności.
  clean('Clean', 'Czysta jazda'),

  /// Ostrzeżenie klaksonem z samochodu sędziowskiego.
  warning('Commissaire Warning', 'Ostrzeżenie komisarza'),

  /// Ryzyko grzywny 200 CHF i odjęcia punktów UCI.
  fineAndPoints('200 CHF Fine Risk', 'Ryzyko grzywny 200 CHF'),

  /// Wysokie ryzyko kary czasowej (+20 s do +1:00) lub relegacji.
  timePenaltyRisk('Time Penalty Risk (+20s+)', 'Ryzyko kary czasowej (+20s+)');

  final String labelEn;
  final String labelPl;

  const CaravanPenaltyRiskLevel(this.labelEn, this.labelPl);
}

/// Dane wejściowe do obliczenia chwilowego cienia aerodynamicznego za pojazdem.
class CaravanDraftingInput {
  /// Typ pojazdu przed kolarzem.
  final CaravanVehicleType vehicleType;

  /// Odległość podłużna od tylnego zderzaka/koła pojazdu do przedniego koła kolarza [m].
  final double longitudinalDistanceMeters;

  /// Przesunięcie poprzeczne kolarza względem osi pojazdu [m] (+ prawo, - lewo).
  final double lateralOffsetMeters;

  /// Prędkość kolarza i pojazdu poruszających się w kolumnie [m/s].
  final double riderSpeedMs;

  /// Prędkość pojazdu względem drogi [m/s] (domyślnie równa prędkości kolarza).
  final double? vehicleSpeedMs;

  /// Składowa wiatru czołowego wzdłuż osi drogi [m/s] (>0 w twarz, <0 w plecy).
  final double headwindMs;

  /// Składowa wiatru bocznego [m/s] (+ z lewej na prawo, - z prawej na lewo).
  final double crosswindMs;

  /// Bazowy współczynnik CdA kolarza bez draftingu [m^2].
  final double riderBaseCdA;

  /// Całkowita masa zestawu (kolarz + rower + bidony) [kg].
  final double totalMassKg;

  /// Nachylenie drogi (ułamek, np. 0.04 = +4%).
  final double roadGradient;

  /// Współczynnik oporu toczenia opon Crr.
  final double crr;

  /// Wysokość n.p.m. [m].
  final double altitudeMeters;

  /// Temperatura powietrza [°C].
  final double temperatureCelsius;

  /// Sprawność mechaniczna napędu (0.94 - 0.985).
  final double drivetrainEfficiency;

  /// Kontekst regulaminowy manewru.
  final CaravanDraftingContext context;

  /// Czy pojazd ma zamontowane rowery/bagażnik na dachu (poszerza ślad wozów).
  final bool hasRoofBikeRack;

  /// Czy w pobliżu (<60 m) znajduje się motocykl/auto komisarza UCI.
  final bool commissaireInSight;

  /// Czy kamera transmisji TV aktualnie filmuje kolarza.
  final bool isTvCameraFocused;

  /// Czas dotychczasowego przebywania w cieniu pojazdu w obecnym manewrze [s].
  final double exposureDurationSeconds;

  /// Dotychczas skumulowana ekspozycja na karę UCI (0..100).
  final double currentPenaltyExposure;

  const CaravanDraftingInput({
    required this.vehicleType,
    required this.longitudinalDistanceMeters,
    this.lateralOffsetMeters = 0.0,
    required this.riderSpeedMs,
    this.vehicleSpeedMs,
    this.headwindMs = 0.0,
    this.crosswindMs = 0.0,
    this.riderBaseCdA = PhysicsConstants.cdaDrops,
    this.totalMassKg = 76.0,
    this.roadGradient = 0.0,
    this.crr = PhysicsConstants.crrStandardAsphalt,
    this.altitudeMeters = 200.0,
    this.temperatureCelsius = 20.0,
    this.drivetrainEfficiency = 0.975,
    this.context = CaravanDraftingContext.mechanicalOrCrashReturn,
    this.hasRoofBikeRack = true,
    this.commissaireInSight = false,
    this.isTvCameraFocused = false,
    this.exposureDurationSeconds = 0.0,
    this.currentPenaltyExposure = 0.0,
  });
}

/// Wynik obliczeń fizyki cienia aerodynamicznego za pojazdem oraz oceny ryzyka UCI.
class CaravanDraftingResult {
  /// Rzeczywista redukcja oporu aerodynamicznego [0.0 .. 0.72].
  final double dragReductionFraction;

  /// Efektywny współczynnik CdA kolarza w cieniu pojazdu [m^2].
  final double effectiveCdA;

  /// Gęstość powietrza w aktualnych warunkach wysokości/temperatury [kg/m^3].
  final double airDensityKgM3;

  /// Moc aerodynamiczna bez pojazdu przed kolarzem [W].
  final double soloAeroPowerWatts;

  /// Moc aerodynamiczna w cieniu pojazdu [W].
  final double draftedAeroPowerWatts;

  /// Oszczędność mocy dzięki cieniowi aerodynamicznemu [W].
  final double aeroPowerSavedWatts;

  /// Całkowita moc na pedałach wymagana do utrzymania zadanej prędkości bez osłony [W].
  final double soloTotalPowerWatts;

  /// Całkowita moc na pedałach wymagana w cieniu pojazdu [W].
  final double draftedTotalPowerWatts;

  /// Prędkość wejściowa kolarza [m/s].
  final double riderSpeedMs;

  /// Oszacowana prędkość przy utrzymaniu tej samej całkowitej mocy co w jeździe solo [m/s].
  final double equivalentIsoPowerSpeedMs;

  /// Przesunięcie środka tunelu aerodynamicznego wywołane wiatrem bocznym [m].
  final double wakeLateralShiftMeters;

  /// Efektywna odległość boczna kolarza od osi odkształconego tunelu [m].
  final double effectiveLateralMissMeters;

  /// Współczynnik tłumienia podłużnego (0..1).
  final double longitudinalWakeFactor;

  /// Współczynnik tłumienia poprzecznego (0..1).
  final double lateralWakeFactor;

  /// Wskaźnik niestabilności/turbulencji strugi za pojazdem (0..1).
  final double wakeTurbulenceIndex;

  /// Chwilowe tempo narastania podejrzeń komisarza UCI [punkty/s].
  final double penaltyExposureRatePerSec;

  /// Zaktualizowana skumulowana ekspozycja na karę UCI (0..100).
  final double updatedPenaltyExposure;

  /// Prawdopodobieństwo nałożenia kary czasowej przy obecnym manewrze (0..1).
  final double timePenaltyProbability;

  /// Sugerowana kara czasowa [s] (0, 20, 40, 60) jeśli próg zostanie przekroczony.
  final int projectedTimePenaltySeconds;

  /// Sugerowana grzywna [CHF] (0 lub 200).
  final int projectedFineChf;

  /// Klasyfikacja poziomu ryzyka sędziowskiego.
  final CaravanPenaltyRiskLevel riskLevel;

  /// Czy odległość jest niebezpiecznie mała (<0.9 m od zderzaka — ryzyko kolizji / Sticky Bottle).
  final bool isDangerouslyCloseToBumper;

  const CaravanDraftingResult({
    required this.dragReductionFraction,
    required this.effectiveCdA,
    required this.airDensityKgM3,
    required this.soloAeroPowerWatts,
    required this.draftedAeroPowerWatts,
    required this.aeroPowerSavedWatts,
    required this.soloTotalPowerWatts,
    required this.draftedTotalPowerWatts,
    required this.riderSpeedMs,
    required this.equivalentIsoPowerSpeedMs,
    required this.wakeLateralShiftMeters,
    required this.effectiveLateralMissMeters,
    required this.longitudinalWakeFactor,
    required this.lateralWakeFactor,
    required this.wakeTurbulenceIndex,
    required this.penaltyExposureRatePerSec,
    required this.updatedPenaltyExposure,
    required this.timePenaltyProbability,
    required this.projectedTimePenaltySeconds,
    required this.projectedFineChf,
    required this.riskLevel,
    required this.isDangerouslyCloseToBumper,
  });

  /// Oszczędność mocy wyrażona w procentach oporu aero (0..100%).
  double get dragReductionPercent => dragReductionFraction * 100.0;

  /// Zysk prędkości przy tej samej mocy [km/h].
  double get isoPowerSpeedGainKmh =>
      (equivalentIsoPowerSpeedMs - riderSpeedMs) * 3.6;
}

/// Pojedyncza próbka czasowa z symulacji powrotu w kolumnie wozów technicznych.
class CaravanConvoyStepSample {
  final double elapsedSeconds;
  final double remainingGapMeters;
  final double riderSpeedMs;
  final int activeCarIndex;
  final double powerSavedWatts;
  final double dragReductionFraction;
  final double cumulativePenaltyExposure;
  final CaravanPenaltyRiskLevel riskLevel;

  const CaravanConvoyStepSample({
    required this.elapsedSeconds,
    required this.remainingGapMeters,
    required this.riderSpeedMs,
    required this.activeCarIndex,
    required this.powerSavedWatts,
    required this.dragReductionFraction,
    required this.cumulativePenaltyExposure,
    required this.riskLevel,
  });
}

/// Wynik wielokrokowej symulacji skoku kolarza przez kolumnę wozów technicznych (Car-Hopping).
class CaravanConvoyBridgeResult {
  /// Czy kolarzowi udało się dogonić peleton w założonym limicie czasu.
  final bool didCatchPeloton;

  /// Całkowity czas pościgu [s].
  final double totalTimeSeconds;

  /// Czas potrzebny na dogonienie w jeździe solo (bez wozów) przy tej samej mocy [s].
  final double estimatedSoloChaseTimeSeconds;

  /// Zysk czasowy względem jazdy solo [s].
  final double timeSavedVsSoloSeconds;

  /// Średnia redukcja oporu aero podczas pościgu [0..1].
  final double averageDragReductionFraction;

  /// Średnia oszczędność mocy [W].
  final double averageWattsSaved;

  /// Oszczędzona energia pracy mechanicznej [kJ].
  final double energySavedKilojoules;

  /// Końcowy poziom ekspozycji na karę UCI (0..100).
  final double finalPenaltyExposure;

  /// Końcowa ocena ryzyka kary sędziowskiej.
  final CaravanPenaltyRiskLevel finalRiskLevel;

  /// Przewidywana kara czasowa na mecie [s].
  final int projectedTimePenaltySeconds;

  /// Przewidywana grzywna [CHF].
  final int projectedFineChf;

  /// Próbki telemetrii z przebiegu pościgu.
  final List<CaravanConvoyStepSample> timeline;

  const CaravanConvoyBridgeResult({
    required this.didCatchPeloton,
    required this.totalTimeSeconds,
    required this.estimatedSoloChaseTimeSeconds,
    required this.timeSavedVsSoloSeconds,
    required this.averageDragReductionFraction,
    required this.averageWattsSaved,
    required this.energySavedKilojoules,
    required this.finalPenaltyExposure,
    required this.finalRiskLevel,
    required this.projectedTimePenaltySeconds,
    required this.projectedFineChf,
    required this.timeline,
  });
}

/// Solver fizyki cienia aerodynamicznego za motocyklami TV oraz kolumną wozów technicznych.
///
/// Modeluje:
/// - strukturę śladu aerodynamicznego (longitudinal core + rational wake decay),
/// - odchylenie strugi cienia pod wpływem wiatru bocznego (crosswind wake deflection),
/// - efekt bagażnika dachowego z rowerami w wozach DS i neutralnych,
/// - oszczędność watów i zysk prędkości przy stałej mocy (Newton-Raphson solver),
/// - akumulację ryzyka kary komisarza UCI w zależności od kontekstu i widoczności.
class DraftingBehindTeamCarAndMotosSolver {
  DraftingBehindTeamCarAndMotosSolver._();

  static const double _maxAllowedDraftReduction = 0.72;
  static const double _minAllowedCdA = 0.115;

  /// Oblicza gęstość powietrza na podstawie modelu atmosfery wzorcowej ISA.
  static double computeAirDensity({
    required double altitudeMeters,
    required double temperatureCelsius,
  }) {
    final double h = math.max(0.0, altitudeMeters);
    final double tempKelvin = temperatureCelsius + 273.15;
    if (tempKelvin <= 50.0) {
      return PhysicsConstants.seaLevelAirDensity;
    }
    const double p0 = 101325.0;
    const double t0 = 288.15;
    const double exponent = 5.25588;
    final double pressureFactor = math.pow(
      math.max(0.05, 1.0 - (PhysicsConstants.temperatureLapseRate * h) / t0),
      exponent,
    ).toDouble();
    final double pressurePa = p0 * pressureFactor;
    const double specificGasConstantAir = 287.058;
    return pressurePa / (specificGasConstantAir * tempKelvin);
  }

  /// Rozwiązuje chwilowy cień aerodynamiczny za pojedynczym pojazdem kolumny lub motocyklem.
  static CaravanDraftingResult solveInstantDrafting(
    CaravanDraftingInput input, {
    double dtSeconds = 1.0,
  }) {
    final double dt = math.max(0.0, dtSeconds);
    final double vRider = math.max(0.0, input.riderSpeedMs);
    final double vVehicle = math.max(0.0, input.vehicleSpeedMs ?? vRider);
    final double dLong = input.longitudinalDistanceMeters;
    final double rho = computeAirDensity(
      altitudeMeters: input.altitudeMeters,
      temperatureCelsius: input.temperatureCelsius,
    );

    final double baseCdA = math.max(_minAllowedCdA, input.riderBaseCdA);
    final double vAppLong = vRider + input.headwindMs;
    final double vAppSq = vAppLong * vAppLong.abs();

    // Siła i moc aero bez osłony pojazdu
    final double soloAeroForce = 0.5 * rho * baseCdA * vAppSq;
    final double soloAeroPower = soloAeroForce * vRider;

    // Składowe grawitacji i oporu toczenia
    final double mass = math.max(40.0, input.totalMassKg);
    final double slopeAngle = math.atan(input.roadGradient);
    final double fGravity = mass * PhysicsConstants.gravity * math.sin(slopeAngle);
    final double fRolling =
        mass * PhysicsConstants.gravity * math.cos(slopeAngle) * input.crr;
    final double efficiency = input.drivetrainEfficiency.clamp(0.85, 0.995);

    final double soloWheelPower = soloAeroPower + (fGravity + fRolling) * vRider;
    final double soloTotalPower = soloWheelPower / efficiency;

    // Jeśli kolarz jest przed pojazdem lub zbyt daleko (>45 m) albo stoi w miejscu, brak draftu
    if (dLong < -0.2 || dLong > 45.0 || vRider < 2.0) {
      return CaravanDraftingResult(
        dragReductionFraction: 0.0,
        effectiveCdA: baseCdA,
        airDensityKgM3: rho,
        soloAeroPowerWatts: soloAeroPower,
        draftedAeroPowerWatts: soloAeroPower,
        aeroPowerSavedWatts: 0.0,
        soloTotalPowerWatts: soloTotalPower,
        draftedTotalPowerWatts: soloTotalPower,
        riderSpeedMs: vRider,
        equivalentIsoPowerSpeedMs: vRider,
        wakeLateralShiftMeters: 0.0,
        effectiveLateralMissMeters: input.lateralOffsetMeters.abs(),
        longitudinalWakeFactor: 0.0,
        lateralWakeFactor: 0.0,
        wakeTurbulenceIndex: 0.0,
        penaltyExposureRatePerSec: 0.0,
        updatedPenaltyExposure: _decayPenaltyExposure(
          input.currentPenaltyExposure,
          dt,
        ),
        timePenaltyProbability:
            _exposureToProbability(input.currentPenaltyExposure),
        projectedTimePenaltySeconds:
            _exposureToTimePenalty(input.currentPenaltyExposure),
        projectedFineChf: input.currentPenaltyExposure >= 55.0 ? 200 : 0,
        riskLevel: _classifyRisk(input.currentPenaltyExposure),
        isDangerouslyCloseToBumper: false,
      );
    }

    final CaravanVehicleType vehicle = input.vehicleType;
    final double clampedDLong = math.max(0.0, dLong);

    // 1. Podłużny profil zanikania śladu (core plateau + rational decay)
    final double roofRackBoost =
        (!vehicle.isMotorbike && input.hasRoofBikeRack) ? 1.12 : 1.0;
    final double effectiveCoreLength =
        vehicle.coreWakeLengthMeters * roofRackBoost;
    final double effectiveDecayLength =
        vehicle.wakeDecayLengthMeters *
        roofRackBoost *
        (0.85 + 0.15 * (vVehicle / 12.0).clamp(0.5, 1.5));

    final double longitudinalFactor;
    if (clampedDLong <= effectiveCoreLength) {
      longitudinalFactor = 1.0;
    } else {
      final double excess = clampedDLong - effectiveCoreLength;
      longitudinalFactor =
          1.0 / (1.0 + math.pow(excess / effectiveDecayLength, 1.65));
    }

    // 2. Odchylenie strugi cienia pod wpływem wiatru bocznego
    final double effectiveAirspeed = math.max(4.0, vAppLong.abs());
    final double crosswindRatio =
        (input.crosswindMs / effectiveAirspeed).clamp(-0.65, 0.65);
    final double wakeLateralShift = clampedDLong * crosswindRatio;
    final double lateralMiss =
        (input.lateralOffsetMeters - wakeLateralShift).abs();

    // Szerokość połówkowa śladu rozszerza się z dystansem, lecz motocykl ma węższy stożek
    final double halfWidth = (vehicle.effectiveWidthMeters * 0.5) +
        (0.042 * clampedDLong) +
        ((!vehicle.isMotorbike && input.hasRoofBikeRack) ? 0.12 : 0.0);
    final double lateralFactor =
        math.exp(-math.pow(lateralMiss / math.max(0.25, halfWidth), 2.0));

    // 3. Wpływ względnej prędkości pojazd-kolarz (zysk przy podciąganiu spada przy dużej różnicy prędkości)
    final double speedMismatchPenalty =
        math.exp(-0.08 * (vRider - vVehicle).abs());

    // 4. Sumaryczna redukcja oporu aero
    double peakReduction = vehicle.maxDraftReduction;
    if (!vehicle.isMotorbike && input.hasRoofBikeRack) {
      peakReduction = math.min(_maxAllowedDraftReduction, peakReduction + 0.03);
    }
    // Wiatr czołowy lekko wzmacnia opłacalność tunelu, bardzo silny boczny rozmywa strugę
    final double crosswindDispersion =
        1.0 - (0.18 * (input.crosswindMs.abs() / 12.0).clamp(0.0, 1.0));

    final double rawReduction = peakReduction *
        longitudinalFactor *
        lateralFactor *
        speedMismatchPenalty *
        crosswindDispersion;
    final double dragReduction =
        rawReduction.clamp(0.0, _maxAllowedDraftReduction);

    final double effectiveCdA =
        math.max(_minAllowedCdA, baseCdA * (1.0 - dragReduction));
    final double draftedAeroPower = 0.5 * rho * effectiveCdA * vAppSq * vRider;
    final double aeroPowerSaved = math.max(0.0, soloAeroPower - draftedAeroPower);
    final double draftedWheelPower =
        draftedAeroPower + (fGravity + fRolling) * vRider;
    final double draftedTotalPower = draftedWheelPower / efficiency;

    // 5. Równoważna prędkość przy zachowaniu mocy solo (Newton-Raphson)
    final double isoPowerSpeed = _solveSpeedForTotalPower(
      targetTotalPowerWatts: soloTotalPower,
      rho: rho,
      effectiveCdA: effectiveCdA,
      headwindMs: input.headwindMs,
      fGravityPlusRolling: fGravity + fRolling,
      efficiency: efficiency,
      initialGuessMs: vRider,
    );

    // 6. Turbulencje w śladzie za bagażnikiem dachowym lub motocyklem przy dużej prędkości
    final double speedNorm = (vRider / 15.0).clamp(0.2, 1.6);
    final double turbulence = (vehicle.turbulenceIntensity *
            longitudinalFactor *
            lateralFactor *
            speedNorm *
            (input.hasRoofBikeRack && !vehicle.isMotorbike ? 1.15 : 1.0))
        .clamp(0.0, 1.0);

    final bool dangerouslyClose = clampedDLong < 0.90 && lateralFactor > 0.45;

    // 7. Ocena ryzyka kary komisarza UCI
    final double exposureRate = _computePenaltyExposureRate(
      vehicle: vehicle,
      context: input.context,
      longitudinalDistanceMeters: clampedDLong,
      dragReduction: dragReduction,
      commissaireInSight: input.commissaireInSight,
      isTvCameraFocused: input.isTvCameraFocused,
      exposureDurationSeconds: input.exposureDurationSeconds,
      dangerouslyClose: dangerouslyClose,
    );

    final double updatedExposure;
    if (exposureRate > 0.0) {
      updatedExposure =
          (input.currentPenaltyExposure + exposureRate * dt).clamp(0.0, 100.0);
    } else {
      updatedExposure = _decayPenaltyExposure(input.currentPenaltyExposure, dt);
    }

    return CaravanDraftingResult(
      dragReductionFraction: dragReduction,
      effectiveCdA: effectiveCdA,
      airDensityKgM3: rho,
      soloAeroPowerWatts: soloAeroPower,
      draftedAeroPowerWatts: draftedAeroPower,
      aeroPowerSavedWatts: aeroPowerSaved,
      soloTotalPowerWatts: soloTotalPower,
      draftedTotalPowerWatts: draftedTotalPower,
      riderSpeedMs: vRider,
      equivalentIsoPowerSpeedMs: isoPowerSpeed,
      wakeLateralShiftMeters: wakeLateralShift,
      effectiveLateralMissMeters: lateralMiss,
      longitudinalWakeFactor: longitudinalFactor,
      lateralWakeFactor: lateralFactor,
      wakeTurbulenceIndex: turbulence,
      penaltyExposureRatePerSec: exposureRate,
      updatedPenaltyExposure: updatedExposure,
      timePenaltyProbability: _exposureToProbability(updatedExposure),
      projectedTimePenaltySeconds: _exposureToTimePenalty(updatedExposure),
      projectedFineChf: updatedExposure >= 55.0 ? 200 : 0,
      riskLevel: _classifyRisk(updatedExposure),
      isDangerouslyCloseToBumper: dangerouslyClose,
    );
  }

  /// Symuluje powrót kolarza do peletonu przez kolumnę N wozów technicznych ("Car-Hopping").
  ///
  /// Kolarz przeskakuje z cienia kolejnego wozu na następny, oszczędzając W' i czas.
  static CaravanConvoyBridgeResult simulateCaravanConvoyBridge({
    required double initialGapMeters,
    required int convoyCarCount,
    double carSpacingMeters = 15.0,
    double riderTargetPowerWatts = 385.0,
    double pelotonSpeedMs = 12.2,
    double targetFollowDistanceMeters = 2.4,
    double riderBaseCdA = PhysicsConstants.cdaDrops,
    double totalMassKg = 75.0,
    double roadGradient = 0.005,
    double headwindMs = 1.5,
    double crosswindMs = 0.0,
    double altitudeMeters = 250.0,
    double temperatureCelsius = 20.0,
    CaravanDraftingContext context =
        CaravanDraftingContext.mechanicalOrCrashReturn,
    bool commissaireInSight = false,
    double maxSimulationSeconds = 600.0,
    double timeStepSeconds = 1.0,
  }) {
    final double dt = math.max(0.25, timeStepSeconds);
    final double gapStart = math.max(0.0, initialGapMeters);
    final int carCount = math.max(1, convoyCarCount);
    final double spacing = math.max(6.0, carSpacingMeters);

    final double rho = computeAirDensity(
      altitudeMeters: altitudeMeters,
      temperatureCelsius: temperatureCelsius,
    );
    final double slopeAngle = math.atan(roadGradient);
    final double fGravityPlusRolling = totalMassKg *
        PhysicsConstants.gravity *
        (math.sin(slopeAngle) + math.cos(slopeAngle) * PhysicsConstants.crrStandardAsphalt);
    const double efficiency = 0.975;

    // Prędkość solo przy zadanej mocy
    final double soloSpeedMs = _solveSpeedForTotalPower(
      targetTotalPowerWatts: riderTargetPowerWatts,
      rho: rho,
      effectiveCdA: riderBaseCdA,
      headwindMs: headwindMs,
      fGravityPlusRolling: fGravityPlusRolling,
      efficiency: efficiency,
      initialGuessMs: pelotonSpeedMs,
    );
    final double soloClosingSpeed = soloSpeedMs - pelotonSpeedMs;
    final double estimatedSoloTime = soloClosingSpeed > 0.05
        ? gapStart / soloClosingSpeed
        : maxSimulationSeconds * 2.5;

    double remainingGap = gapStart;
    double elapsed = 0.0;
    double penaltyExposure = 0.0;
    double sumDragReduction = 0.0;
    double sumWattsSaved = 0.0;
    double totalEnergySavedJoules = 0.0;
    int stepCount = 0;

    final List<CaravanConvoyStepSample> timeline = <CaravanConvoyStepSample>[];

    while (remainingGap > 0.5 && elapsed < maxSimulationSeconds) {
      // Wyznacz indeks aktualnego wozu w kolumnie przed peletonem
      final int carIndexFromFront =
          ((remainingGap - targetFollowDistanceMeters) / spacing)
              .floor()
              .clamp(0, carCount - 1);

      // Odległość do najbliższego wozu przed kolarzem w tym segmencie kolumny
      final double carPositionGap =
          carIndexFromFront * spacing + targetFollowDistanceMeters;
      final double distToCar =
          (remainingGap - carPositionGap).abs().clamp(1.2, spacing * 0.85);

      // Przyjęta prędkość konwoju (zbliżona do peletonu, z lekkim przyspieszeniem kolarza)
      final CaravanDraftingResult stepDraft = solveInstantDrafting(
        CaravanDraftingInput(
          vehicleType: carIndexFromFront == 0
              ? CaravanVehicleType.neutralServiceCar
              : CaravanVehicleType.teamSupportCar,
          longitudinalDistanceMeters: distToCar,
          lateralOffsetMeters: 0.15,
          riderSpeedMs: pelotonSpeedMs + 1.4,
          vehicleSpeedMs: pelotonSpeedMs + 1.1,
          headwindMs: headwindMs,
          crosswindMs: crosswindMs,
          riderBaseCdA: riderBaseCdA,
          totalMassKg: totalMassKg,
          roadGradient: roadGradient,
          altitudeMeters: altitudeMeters,
          temperatureCelsius: temperatureCelsius,
          context: context,
          commissaireInSight: commissaireInSight,
          exposureDurationSeconds: elapsed,
          currentPenaltyExposure: penaltyExposure,
        ),
        dtSeconds: dt,
      );

      final double draftedRiderSpeed = _solveSpeedForTotalPower(
        targetTotalPowerWatts: riderTargetPowerWatts,
        rho: rho,
        effectiveCdA: stepDraft.effectiveCdA,
        headwindMs: headwindMs,
        fGravityPlusRolling: fGravityPlusRolling,
        efficiency: efficiency,
        initialGuessMs: pelotonSpeedMs + 1.5,
      );

      final double closingSpeed = math.max(0.25, draftedRiderSpeed - pelotonSpeedMs);
      remainingGap = math.max(0.0, remainingGap - closingSpeed * dt);
      elapsed += dt;
      penaltyExposure = stepDraft.updatedPenaltyExposure;

      sumDragReduction += stepDraft.dragReductionFraction;
      sumWattsSaved += stepDraft.aeroPowerSavedWatts;
      totalEnergySavedJoules += stepDraft.aeroPowerSavedWatts * dt;
      stepCount++;

      // Zapisz próbkę co 5s lub na finiszu pogoni
      if (stepCount == 1 ||
          (elapsed % 5.0) < dt ||
          remainingGap <= 0.5 ||
          elapsed >= maxSimulationSeconds) {
        timeline.add(
          CaravanConvoyStepSample(
            elapsedSeconds: elapsed,
            remainingGapMeters: remainingGap,
            riderSpeedMs: draftedRiderSpeed,
            activeCarIndex: carIndexFromFront + 1,
            powerSavedWatts: stepDraft.aeroPowerSavedWatts,
            dragReductionFraction: stepDraft.dragReductionFraction,
            cumulativePenaltyExposure: penaltyExposure,
            riskLevel: stepDraft.riskLevel,
          ),
        );
      }
    }

    final double avgDrag = stepCount > 0 ? sumDragReduction / stepCount : 0.0;
    final double avgWatts = stepCount > 0 ? sumWattsSaved / stepCount : 0.0;
    final bool caught = remainingGap <= 0.5;
    final double timeSaved = math.max(0.0, estimatedSoloTime - elapsed);

    return CaravanConvoyBridgeResult(
      didCatchPeloton: caught,
      totalTimeSeconds: elapsed,
      estimatedSoloChaseTimeSeconds: estimatedSoloTime,
      timeSavedVsSoloSeconds: timeSaved,
      averageDragReductionFraction: avgDrag,
      averageWattsSaved: avgWatts,
      energySavedKilojoules: totalEnergySavedJoules / 1000.0,
      finalPenaltyExposure: penaltyExposure,
      finalRiskLevel: _classifyRisk(penaltyExposure),
      projectedTimePenaltySeconds: _exposureToTimePenalty(penaltyExposure),
      projectedFineChf: penaltyExposure >= 55.0 ? 200 : 0,
      timeline: timeline,
    );
  }

  /// Wyznacza prędkość jazdy [m/s] z zadanej mocy całkowitej metodą Newtona-Raphsona.
  static double _solveSpeedForTotalPower({
    required double targetTotalPowerWatts,
    required double rho,
    required double effectiveCdA,
    required double headwindMs,
    required double fGravityPlusRolling,
    required double efficiency,
    required double initialGuessMs,
  }) {
    final double wheelPower = targetTotalPowerWatts * efficiency;
    double v = math.max(1.5, initialGuessMs);

    for (int i = 0; i < 10; i++) {
      final double vApp = v + headwindMs;
      final double fAero = 0.5 * rho * effectiveCdA * vApp * vApp.abs();
      final double pCalc = (fAero + fGravityPlusRolling) * v;
      final double diff = pCalc - wheelPower;
      if (diff.abs() < 0.05) {
        break;
      }
      final double dfAeroDv = rho * effectiveCdA * vApp.abs();
      final double dpDv = (fAero + fGravityPlusRolling) + v * dfAeroDv;
      if (dpDv.abs() < 1e-4) {
        break;
      }
      v = (v - diff / dpDv).clamp(0.5, 36.0);
    }
    return v;
  }

  static double _computePenaltyExposureRate({
    required CaravanVehicleType vehicle,
    required CaravanDraftingContext context,
    required double longitudinalDistanceMeters,
    required double dragReduction,
    required bool commissaireInSight,
    required bool isTvCameraFocused,
    required double exposureDurationSeconds,
    required bool dangerouslyClose,
  }) {
    // Brak znaczącej korzyści aero => brak podstaw do kary
    if (dragReduction < 0.10) {
      return 0.0;
    }

    // Im bliżej pojazdu (szczególnie <5 m), tym bardziej oczywisty manewr
    final double proximityFactor = longitudinalDistanceMeters < 3.0
        ? 1.85
        : longitudinalDistanceMeters < 6.0
            ? 1.25
            : longitudinalDistanceMeters < 11.0
                ? 0.65
                : 0.20;

    final double benefitFactor = (dragReduction / 0.45).clamp(0.2, 1.8);
    final double visibilityFactor = (commissaireInSight ? 1.85 : 1.0) *
        (isTvCameraFocused ? 1.30 : 1.0);
    final double durationEscalation =
        1.0 + (exposureDurationSeconds / 45.0).clamp(0.0, 1.2);
    final double bumperBonus = dangerouslyClose ? 1.45 : 1.0;

    return 0.85 *
        vehicle.scrutinyMultiplier *
        context.toleranceFactor *
        proximityFactor *
        benefitFactor *
        visibilityFactor *
        durationEscalation *
        bumperBonus;
  }

  static double _decayPenaltyExposure(double currentExposure, double dt) {
    if (currentExposure <= 0.0 || dt <= 0.0) {
      return 0.0;
    }
    // Stopniowe wygaszanie podejrzeń po wyjściu z cienia pojazdu
    return math.max(0.0, currentExposure - 1.25 * dt);
  }

  static double _exposureToProbability(double exposure) {
    if (exposure <= 20.0) {
      return 0.0;
    }
    return ((exposure - 20.0) / 80.0).clamp(0.0, 1.0);
  }

  static int _exposureToTimePenalty(double exposure) {
    if (exposure >= 92.0) {
      return 60;
    }
    if (exposure >= 80.0) {
      return 20;
    }
    return 0;
  }

  static CaravanPenaltyRiskLevel _classifyRisk(double exposure) {
    if (exposure >= 80.0) {
      return CaravanPenaltyRiskLevel.timePenaltyRisk;
    }
    if (exposure >= 55.0) {
      return CaravanPenaltyRiskLevel.fineAndPoints;
    }
    if (exposure >= 30.0) {
      return CaravanPenaltyRiskLevel.warning;
    }
    return CaravanPenaltyRiskLevel.clean;
  }
}
