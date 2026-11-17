import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/cobble_tire_pressure_real_time_deflection.dart';
import 'package:pro_peloton_manager/engine/physics/real_time_cfd_vortex_and_drag_solver.dart';
import 'package:pro_peloton_manager/engine/physics/tire_pressure_calculator.dart';

void main() {
  group('RealTimeCfdVortexAndDragSolver — aerodynamika strefowa CFD', () {
    test('rozwiązuje wszystkie 6 stref i zachowuje sumę udziałów oporu = 1.0', () {
      const input = CfdSolverInput(
        groundSpeedKmh: 48.0,
        headwindKmh: 4.0,
        crosswindKmh: 6.0,
      );

      final result = RealTimeCfdVortexAndDragSolver.solveFrame(input);

      expect(result.zones.length, CfdAeroZone.values.length);
      for (final zone in CfdAeroZone.values) {
        final breakdown = result.zoneOf(zone);
        expect(breakdown.frontalAreaM2, greaterThan(0.0));
        expect(breakdown.effectiveCdA, greaterThan(0.0));
        expect(breakdown.reynoldsNumber, greaterThan(1e4));
        expect(breakdown.karmanFrequencyHz, greaterThan(0.0));
      }

      final shareSum = result.zones.fold<double>(
        0.0,
        (sum, z) => sum + z.shareOfTotalDrag,
      );
      expect(shareSum, closeTo(1.0, 1e-6));

      final sumCdA = result.zones.fold<double>(
        0.0,
        (sum, z) => sum + z.effectiveCdA,
      );
      final sumPower = result.zones.fold<double>(
        0.0,
        (sum, z) => sum + z.aeroPowerWatts,
      );
      expect(result.totalCdA, closeTo(sumCdA, 1e-6));
      expect(result.totalAeroPowerWatts, closeTo(sumPower, 1e-6));
      expect(result.apparentWindSpeedKmh, greaterThan(48.0));
      expect(result.yawAngleDegrees, greaterThan(0.0));
    });

    test('kask, pozycja przedramion, tekstylia i rozpięty zamek zmieniają opór strefowy', () {
      const roadBaseline = CfdSolverInput(
        groundSpeedKmh: 55.0,
        headwindKmh: 10.0,
        helmetType: CfdHelmetType.roadVented,
        headTuckFactor: 0.1,
        forearmPosture: CfdForearmPosture.hoodsWide,
        textileSpec: CfdTextileSpec.looseClubJersey,
        zipperOpenFraction: 1.0,
      );
      const aeroOptimized = CfdSolverInput(
        groundSpeedKmh: 55.0,
        headwindKmh: 10.0,
        helmetType: CfdHelmetType.ttLongTeardrop,
        headTuckFactor: 1.0,
        forearmPosture: CfdForearmPosture.highHandsMantis,
        textileSpec: CfdTextileSpec.aeroSkinsuitRibbed,
        zipperOpenFraction: 0.0,
      );

      final resRoad = RealTimeCfdVortexAndDragSolver.solveFrame(roadBaseline);
      final resAero = RealTimeCfdVortexAndDragSolver.solveFrame(aeroOptimized);

      expect(
        resAero.zoneOf(CfdAeroZone.helmet).effectiveCdA,
        lessThan(resRoad.zoneOf(CfdAeroZone.helmet).effectiveCdA),
      );
      expect(
        resAero.zoneOf(CfdAeroZone.forearms).effectiveCdA,
        lessThan(resRoad.zoneOf(CfdAeroZone.forearms).effectiveCdA),
      );
      expect(
        resAero.zoneOf(CfdAeroZone.textiles).effectiveCdA,
        lessThan(resRoad.zoneOf(CfdAeroZone.textiles).effectiveCdA),
      );
      expect(resAero.totalCdA, lessThan(resRoad.totalCdA));
      expect(
        resAero.karmanWakeTurbulenceIntensity,
        lessThan(resRoad.karmanWakeTurbulenceIntensity),
      );
      expect(
        resRoad.zoneOf(CfdAeroZone.textiles).flowRegime,
        CfdFlowRegime.karmanVortexShedding,
      );
    });

    test('reguła 105% obręczy i efekt żagla przy wietrze skośnym', () {
      const compliantDeepWheel = CfdSolverInput(
        groundSpeedKmh: 46.0,
        crosswindKmh: 8.5, // ~10.5 deg yaw
        wheelSpec: CfdWheelProfileSpec.deepCarbon65, // 28mm ext
        tireWidthMm: 26.0, // 26 * 1.05 = 27.3 <= 28
      );
      const violatedShallowWheel = CfdSolverInput(
        groundSpeedKmh: 46.0,
        crosswindKmh: 8.5,
        wheelSpec: CfdWheelProfileSpec.shallowAlloy24, // 25mm ext
        tireWidthMm: 30.0, // 30 * 1.05 = 31.5 > 25
      );

      final resCompliant = RealTimeCfdVortexAndDragSolver.solveFrame(compliantDeepWheel);
      final resViolated = RealTimeCfdVortexAndDragSolver.solveFrame(violatedShallowWheel);

      expect(resCompliant.satisfiesRuleOf105, isTrue);
      expect(resViolated.satisfiesRuleOf105, isFalse);
      expect(
        resViolated.zoneOf(CfdAeroZone.wheels).flowRegime,
        CfdFlowRegime.separatedWake,
      );
      expect(
        resCompliant.sailingEffectWattsGain,
        greaterThan(resViolated.sailingEffectWattsGain),
      );
    });

    test('drafting, wysokość n.p.m. oraz przypadek brzegowy 0 km/h', () {
      const soloSeaLevel = CfdSolverInput(
        groundSpeedKmh: 50.0,
        altitudeMeters: 0.0,
        draftingReduction: 0.0,
      );
      const pelotonDraft = CfdSolverInput(
        groundSpeedKmh: 50.0,
        altitudeMeters: 0.0,
        draftingReduction: 0.45,
        gapToRiderAheadMeters: 0.6,
      );
      const highAltitude = CfdSolverInput(
        groundSpeedKmh: 50.0,
        altitudeMeters: 2200.0,
        draftingReduction: 0.0,
      );
      const stationary = CfdSolverInput(groundSpeedKmh: 0.0);

      final resSolo = RealTimeCfdVortexAndDragSolver.solveFrame(soloSeaLevel);
      final resDraft = RealTimeCfdVortexAndDragSolver.solveFrame(pelotonDraft);
      final resAlt = RealTimeCfdVortexAndDragSolver.solveFrame(highAltitude);
      final resZero = RealTimeCfdVortexAndDragSolver.solveFrame(stationary);

      expect(resDraft.dynamicPressurePa, lessThan(resSolo.dynamicPressurePa));
      expect(resDraft.totalAeroPowerWatts, lessThan(resSolo.totalAeroPowerWatts));
      expect(resAlt.airDensityKgM3, lessThan(resSolo.airDensityKgM3));
      expect(resAlt.totalAeroPowerWatts, lessThan(resSolo.totalAeroPowerWatts));

      expect(resZero.totalAeroPowerWatts, 0.0);
      expect(resZero.karmanDominantFrequencyHz, 0.0);
      expect(resZero.totalCdA.isFinite, isTrue);
    });

    test('ścieżka wirów Kármána, przemiatanie yaw i porównanie konfiguracji', () {
      const base = CfdSolverInput(
        groundSpeedKmh: 48.0,
        crosswindKmh: 6.0,
        helmetType: CfdHelmetType.roadVented,
        forearmPosture: CfdForearmPosture.dropsCompact,
      );
      final upgraded = base.copyWith(
        helmetType: CfdHelmetType.ttShortTail,
        forearmPosture: CfdForearmPosture.ttAeroBars,
        textileSpec: CfdTextileSpec.aeroSkinsuitRibbed,
        wheelSpec: CfdWheelProfileSpec.ttDiscRear80Front,
        tireWidthMm: 24.0,
      );

      final solvedBase = RealTimeCfdVortexAndDragSolver.solveFrame(base);
      final vortices = RealTimeCfdVortexAndDragSolver.sampleWakeVortexField(
        solverResult: solvedBase,
        timeSeconds: 0.35,
        vortexPairCount: 10,
      );

      expect(vortices, isNotEmpty);
      if (vortices.length >= 2) {
        expect(vortices[0].circulationStrength.sign, -vortices[1].circulationStrength.sign);
      }
      for (final node in vortices) {
        expect(node.downstreamMeters, lessThanOrEqualTo(solvedBase.wakeLengthMeters));
        expect(node.energyRetention, inInclusiveRange(0.08, 1.0));
      }

      final sweep = RealTimeCfdVortexAndDragSolver.sweepYawAngles(
        base,
        minYawDegrees: -15.0,
        maxYawDegrees: 15.0,
        stepDegrees: 5.0,
      );
      expect(sweep.length, 7);
      expect(sweep.first.yawDegrees, -15.0);
      expect(sweep.last.yawDegrees, 15.0);

      final cmp = RealTimeCfdVortexAndDragSolver.compareConfigurations(
        baselineInput: base,
        upgradedInput: upgraded,
        distanceKm: 40.0,
        riderPowerWatts: 400.0,
      );
      expect(cmp.deltaCdA, lessThan(0.0));
      expect(cmp.wattsSaved, greaterThan(0.0));
      expect(cmp.timeSavedSeconds, greaterThan(0.0));
    });
  });

  group('CobbleTirePressureRealTimeDeflection — wibracje i ugięcie na bruku', () {
    test('optymalne ciśnienie spada wraz z szerokością opony, wilgocią i trudnością bruku', () {
      const dry5Star32mm = CobbleTireDeflectionInput(
        nominalTireWidthMm: 32,
        sectorRating: CobbleSectorRating.fiveStar,
        moisture: CobbleSurfaceMoisture.dry,
        tireSystem: TireSystemType.tubeless,
        rimType: RimType.hookless,
      );
      final wet5Star32mm = dry5Star32mm.copyWith(
        moisture: CobbleSurfaceMoisture.wetMuddy,
      );
      final dry1Star25mm = dry5Star32mm.copyWith(
        nominalTireWidthMm: 25,
        sectorRating: CobbleSectorRating.oneStar,
        tireSystem: TireSystemType.butylTube,
        rimType: RimType.hooked,
      );

      final optDry32 = CobbleTirePressureRealTimeDeflection.computeOptimalCobblePressures(dry5Star32mm);
      final optWet32 = CobbleTirePressureRealTimeDeflection.computeOptimalCobblePressures(wet5Star32mm);
      final optDry25 = CobbleTirePressureRealTimeDeflection.computeOptimalCobblePressures(dry1Star25mm);

      expect(optWet32.frontBar, lessThanOrEqualTo(optDry32.frontBar));
      expect(optWet32.rearBar, lessThanOrEqualTo(optDry32.rearBar));
      expect(optDry32.frontBar, lessThan(optDry25.frontBar));
      expect(optDry32.rearBar, lessThan(optDry25.rearBar));
      expect(optDry32.frontBar, lessThanOrEqualTo(RimType.hookless.maxSafePressureBar));
      expect(optDry32.rearBar, lessThanOrEqualTo(RimType.hookless.maxSafePressureBar));
    });

    test('kompromis histereza vs impedancja i werdykty ciśnienia', () {
      const base = CobbleTireDeflectionInput(
        totalMassKg: 82.0,
        nominalTireWidthMm: 30,
        internalRimWidthMm: 23.0,
        tireSystem: TireSystemType.tubeless,
        rimType: RimType.hooked,
        sectorRating: CobbleSectorRating.fiveStar,
        speedKmh: 38.0,
      );
      final opt = CobbleTirePressureRealTimeDeflection.computeOptimalCobblePressures(base);

      final optimalSnap = CobbleTirePressureRealTimeDeflection.evaluateStep(
        base.copyWith(frontPressureBar: opt.frontBar, rearPressureBar: opt.rearBar),
      );
      final tooLowSnap = CobbleTirePressureRealTimeDeflection.evaluateStep(
        base.copyWith(frontPressureBar: 1.85, rearPressureBar: 2.00),
      );
      final tooHighSnap = CobbleTirePressureRealTimeDeflection.evaluateStep(
        base.copyWith(frontPressureBar: 6.50, rearPressureBar: 6.75),
      );
      final hooklessOverSnap = CobbleTirePressureRealTimeDeflection.evaluateStep(
        base.copyWith(
          rimType: RimType.hookless,
          frontPressureBar: 5.40,
          rearPressureBar: 5.60,
        ),
      );

      expect(optimalSnap.verdict, CobbleDeflectionVerdict.optimalCompliance);
      expect(tooLowSnap.hysteresisLossWatts, greaterThan(optimalSnap.hysteresisLossWatts));
      expect(tooLowSnap.rimStrikeProbabilityPercent, greaterThan(optimalSnap.rimStrikeProbabilityPercent));
      expect(tooHighSnap.impedanceLossWatts, greaterThan(optimalSnap.impedanceLossWatts));
      expect(tooHighSnap.rmsVerticalAccelerationG, greaterThan(optimalSnap.rmsVerticalAccelerationG));
      expect(tooHighSnap.fatigueMultiplier, greaterThan(optimalSnap.fatigueMultiplier));
      expect(tooHighSnap.overallTractionPercent, lessThan(optimalSnap.overallTractionPercent));
      expect(tooHighSnap.verdict, CobbleDeflectionVerdict.tooStiffHighImpedance);
      expect(hooklessOverSnap.verdict, CobbleDeflectionVerdict.hooklessOverpressure);
      expect(
        tooLowSnap.verdict == CobbleDeflectionVerdict.imminentRimStrike ||
            tooLowSnap.verdict == CobbleDeflectionVerdict.excessiveSquirm,
        isTrue,
      );
    });

    test('wkładka antyprzebiciowa Tire Insert redukuje ryzyko dobicia i pinch flat', () {
      const lowPressureNoInsert = CobbleTireDeflectionInput(
        nominalTireWidthMm: 28,
        frontPressureBar: 2.30,
        rearPressureBar: 2.45,
        sectorRating: CobbleSectorRating.fiveStar,
        hasTireInsert: false,
      );
      final withInsert = lowPressureNoInsert.copyWith(hasTireInsert: true);

      final snapNoInsert = CobbleTirePressureRealTimeDeflection.evaluateStep(lowPressureNoInsert);
      final snapInsert = CobbleTirePressureRealTimeDeflection.evaluateStep(withInsert);

      expect(
        snapInsert.rimStrikeProbabilityPercent,
        lessThan(snapNoInsert.rimStrikeProbabilityPercent),
      );
      expect(
        snapInsert.punctureRiskPerSectorPercent,
        lessThan(snapNoInsert.punctureRiskPerSectorPercent),
      );
    });

    test('krzywa przemiatania ciśnienia i symulacja sektora 2.4 km Trouée d\'Arenberg', () {
      const input = CobbleTireDeflectionInput(
        nominalTireWidthMm: 32,
        frontPressureBar: 3.10,
        rearPressureBar: 3.30,
        sectorRating: CobbleSectorRating.fiveStar,
        speedKmh: 38.0,
      );

      final sweep = CobbleTirePressureRealTimeDeflection.sweepPressureCurve(
        input,
        minBar: 2.0,
        maxBar: 6.0,
        stepBar: 0.5,
      );
      expect(sweep.length, 9);
      expect(sweep.first.hysteresisWatts, greaterThan(sweep.last.hysteresisWatts));
      expect(sweep.last.impedanceWatts, greaterThan(sweep.first.impedanceWatts));

      final summary = CobbleTirePressureRealTimeDeflection.simulateSectorTraversal(
        input,
        sectorLengthKm: 2.4,
        dtSec: 2.0,
      );
      expect(summary.samples, isNotEmpty);
      expect(summary.sectorLengthKm, 2.4);
      expect(summary.elapsedTimeSec, greaterThan(200.0));
      expect(summary.totalEnergyLostKj, greaterThan(0.0));
      expect(summary.peakRmsAccelerationG, greaterThan(0.5));
      expect(
        summary.cumulativePunctureProbabilityPercent,
        inInclusiveRange(0.0, 99.5),
      );
    });
  });

  group('Responsywność paneli CFD i Cobble Deflection (390x844 / 1024x768 / 1600x900)', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'RealTimeCfdVortexAndDragPanel renderuje się bez przepełnień w ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          CfdSolverResult? lastSolved;
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: RealTimeCfdVortexAndDragPanel(
                  onSolved: (res) => lastSolved = res,
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('REAL-TIME CFD VORTEX & ZONAL DRAG'), findsOneWidget);
          expect(tester.takeException(), isNull);
          expect(lastSolved, isNull);
        },
      );

      testWidgets(
        'CobbleTirePressureDeflectionPanel renderuje się bez przepełnień w ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: CobbleTirePressureDeflectionPanel(),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.byType(CobbleTirePressureDeflectionPanel), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
