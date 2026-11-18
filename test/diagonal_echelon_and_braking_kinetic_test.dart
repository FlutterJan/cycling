import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/peloton/team_sprint_train_echelon_diagonal_formation.dart';
import 'package:pro_peloton_manager/engine/physics/braking_zone_kinetic_energy_loss_solver.dart';
import 'package:pro_peloton_manager/models/equipment/wheelset_model.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';

List<EchelonTrainRiderInput> _buildTeamTrain() {
  return const [
    EchelonTrainRiderInput(
      riderId: 'team_1',
      name: 'Jan Kowalski',
      teamId: 'player_team',
      isPlayerTeam: true,
      isSprinter: false,
      roleOrder: 1,
      flatSkill: 84,
      sprintSkill: 70,
      bikeHandling: 82,
      raceIq: 80,
      draftingEfficiency: 82,
      ftpWatts: 430,
      wPrimeRemainingJoules: 21000,
      wPrimeMaxJoules: 22000,
    ),
    EchelonTrainRiderInput(
      riderId: 'team_2',
      name: 'Marek Nowak',
      teamId: 'player_team',
      isPlayerTeam: true,
      isSprinter: false,
      roleOrder: 2,
      flatSkill: 83,
      sprintSkill: 74,
      bikeHandling: 84,
      raceIq: 82,
      draftingEfficiency: 85,
      ftpWatts: 420,
      wPrimeRemainingJoules: 20500,
      wPrimeMaxJoules: 21500,
    ),
    EchelonTrainRiderInput(
      riderId: 'team_3',
      name: 'Piotr Zielinski',
      teamId: 'player_team',
      isPlayerTeam: true,
      isSprinter: false,
      roleOrder: 3,
      flatSkill: 82,
      sprintSkill: 78,
      bikeHandling: 85,
      raceIq: 84,
      draftingEfficiency: 86,
      ftpWatts: 415,
      wPrimeRemainingJoules: 20000,
      wPrimeMaxJoules: 21000,
    ),
    EchelonTrainRiderInput(
      riderId: 'team_4',
      name: 'Tomasz Wisniewski',
      teamId: 'player_team',
      isPlayerTeam: true,
      isSprinter: false,
      roleOrder: 4,
      flatSkill: 81,
      sprintSkill: 82,
      bikeHandling: 86,
      raceIq: 85,
      draftingEfficiency: 88,
      ftpWatts: 410,
      wPrimeRemainingJoules: 21500,
      wPrimeMaxJoules: 22000,
    ),
    EchelonTrainRiderInput(
      riderId: 'team_5',
      name: 'Adam Sprinter',
      teamId: 'player_team',
      isPlayerTeam: true,
      isSprinter: true,
      roleOrder: 5,
      flatSkill: 78,
      sprintSkill: 94,
      bikeHandling: 88,
      raceIq: 86,
      draftingEfficiency: 90,
      ftpWatts: 395,
      wPrimeRemainingJoules: 25000,
      wPrimeMaxJoules: 26000,
    ),
  ];
}

List<EchelonTrainRiderInput> _buildRivals() {
  return const [
    EchelonTrainRiderInput(
      riderId: 'rival_1',
      name: 'Lucas Van Dijk',
      teamId: 'rival_a',
      isPlayerTeam: false,
      isSprinter: true,
      roleOrder: 1,
      flatSkill: 82,
      sprintSkill: 90,
      bikeHandling: 80,
      raceIq: 78,
      draftingEfficiency: 80,
      ftpWatts: 405,
      wPrimeRemainingJoules: 16000,
      wPrimeMaxJoules: 22000,
    ),
    EchelonTrainRiderInput(
      riderId: 'rival_2',
      name: 'Marco Rossi',
      teamId: 'rival_b',
      isPlayerTeam: false,
      isSprinter: true,
      roleOrder: 2,
      flatSkill: 79,
      sprintSkill: 88,
      bikeHandling: 74,
      raceIq: 72,
      draftingEfficiency: 75,
      ftpWatts: 395,
      wPrimeRemainingJoules: 11000,
      wPrimeMaxJoules: 21000,
    ),
    EchelonTrainRiderInput(
      riderId: 'rival_3',
      name: 'Pierre Dubois',
      teamId: 'rival_c',
      isPlayerTeam: false,
      isSprinter: false,
      roleOrder: 3,
      flatSkill: 77,
      sprintSkill: 76,
      bikeHandling: 70,
      raceIq: 68,
      draftingEfficiency: 70,
      ftpWatts: 390,
      wPrimeRemainingJoules: 3500,
      wPrimeMaxJoules: 20000,
    ),
  ];
}

void main() {
  group('TeamSprintTrainEchelonDiagonalFormation', () {
    test('calculates crosswind component, diagonal angle and sheltered capacity', () {
      expect(
        TeamSprintTrainEchelonDiagonalFormation.calculateCrosswindComponentKmh(
          windSpeedKmh: 36.0,
          windAngleDegrees: 0.0,
        ),
        closeTo(0.0, 1e-6),
      );
      expect(
        TeamSprintTrainEchelonDiagonalFormation.calculateCrosswindComponentKmh(
          windSpeedKmh: 36.0,
          windAngleDegrees: 90.0,
        ),
        closeTo(36.0, 1e-6),
      );
      expect(
        TeamSprintTrainEchelonDiagonalFormation.calculateCrosswindComponentKmh(
          windSpeedKmh: -10.0,
          windAngleDegrees: 90.0,
        ),
        0.0,
      );

      final inlineAngle =
          TeamSprintTrainEchelonDiagonalFormation.calculateDiagonalAngleDegrees(
        crosswindKmh: 28.0,
        trainSpeedKmh: 58.0,
        mode: DiagonalTrainFormationMode.standardInline,
      );
      final pressAngle =
          TeamSprintTrainEchelonDiagonalFormation.calculateDiagonalAngleDegrees(
        crosswindKmh: 28.0,
        trainSpeedKmh: 58.0,
        mode: DiagonalTrainFormationMode.aggressiveGutterPress,
      );

      expect(inlineAngle, inInclusiveRange(4.0, 44.0));
      expect(pressAngle, greaterThan(inlineAngle));

      final capacityNarrow =
          TeamSprintTrainEchelonDiagonalFormation.calculateMaxShelteredRiders(
        roadWidthMeters: 4.5,
        lateralStepMeters: 0.9,
      );
      final capacityWide =
          TeamSprintTrainEchelonDiagonalFormation.calculateMaxShelteredRiders(
        roadWidthMeters: 9.0,
        lateralStepMeters: 0.9,
      );
      expect(capacityNarrow, inInclusiveRange(2, 14));
      expect(capacityWide, greaterThan(capacityNarrow));
    });

    test('aggressiveGutterPress closes gutter and traps/drops rivals on crosswind', () {
      const context = DiagonalTrainWindContext(
        windSpeedKmh: 34.0,
        windAngleDegrees: 80.0,
        crosswindSide: CrosswindSide.leftToRight,
        roadWidthMeters: 5.5,
        distanceToFinishMeters: 1600.0,
        targetTrainSpeedKmh: 58.0,
      );

      final team = _buildTeamTrain();
      final rivals = _buildRivals();

      final eval =
          TeamSprintTrainEchelonDiagonalFormation.evaluateDiagonalFormation(
        context: context,
        mode: DiagonalTrainFormationMode.aggressiveGutterPress,
        teamTrain: team,
        rivalContenders: rivals,
      );

      expect(eval.isCrosswindActive, isTrue);
      expect(eval.phase, DiagonalTrainPhase.diagonalLock);
      expect(eval.teamSlots, hasLength(team.length));
      expect(eval.rivalSlots, hasLength(rivals.length));
      expect(eval.gutterReport.isGutterClosed, isTrue);
      expect(
        eval.gutterReport.gutterGapMeters,
        lessThanOrEqualTo(
          TeamSprintTrainEchelonDiagonalFormation.gutterCloseThresholdMeters,
        ),
      );

      // Left-to-right crosswind: team fans out toward increasing lateralPositionMeters.
      for (var i = 1; i < eval.teamSlots.length; i++) {
        expect(
          eval.teamSlots[i].lateralPositionMeters,
          greaterThanOrEqualTo(eval.teamSlots[i - 1].lateralPositionMeters),
        );
      }

      // Leadout riders in front of the tail are in the sheltered pocket, and the sprinter gets strong draft savings.
      expect(
        eval.teamSlots[1].gutterStatus,
        GutterPressureStatus.shelteredPocket,
      );
      final sprinterSlot = eval.teamSlots.firstWhere((s) => s.isSprinter);
      expect(sprinterSlot.draftingSavingsPercent, greaterThan(20.0));
      expect(
        sprinterSlot.gutterStatus,
        anyOf(
          GutterPressureStatus.shelteredPocket,
          GutterPressureStatus.fightingForWheel,
        ),
      );

      // Trapped/dropped rivals suffer high exposure and time loss.
      expect(
        eval.gutterReport.trappedRivalIds.length +
            eval.gutterReport.droppedRivalIds.length,
        rivals.length,
      );
      expect(
        eval.gutterReport.averageTeamDraftSavingsPercent,
        greaterThan(15.0),
      );
      expect(eval.gutterReport.averageRivalExposurePercent, greaterThan(80.0));
      for (final rivalSlot in eval.rivalSlots) {
        expect(rivalSlot.estimatedTimeLossPerKmSeconds, greaterThan(0.0));
      }
    });

    test('rightToLeft crosswind mirrors lateral positions and calm wind deactivates echelon', () {
      const rightToLeftContext = DiagonalTrainWindContext(
        windSpeedKmh: 30.0,
        windAngleDegrees: 85.0,
        crosswindSide: CrosswindSide.rightToLeft,
        roadWidthMeters: 6.0,
        distanceToFinishMeters: 250.0,
        targetTrainSpeedKmh: 62.0,
      );

      final evalRtl =
          TeamSprintTrainEchelonDiagonalFormation.evaluateDiagonalFormation(
        context: rightToLeftContext,
        mode: DiagonalTrainFormationMode.diagonalShield,
        teamTrain: _buildTeamTrain(),
        rivalContenders: _buildRivals(),
      );

      expect(evalRtl.isCrosswindActive, isTrue);
      expect(evalRtl.phase, DiagonalTrainPhase.sprintLaunch);
      for (var i = 1; i < evalRtl.teamSlots.length; i++) {
        expect(
          evalRtl.teamSlots[i].lateralPositionMeters,
          lessThanOrEqualTo(evalRtl.teamSlots[i - 1].lateralPositionMeters),
        );
      }

      final calmContext = rightToLeftContext.copyWith(
        windSpeedKmh: 10.0,
        distanceToFinishMeters: 4200.0,
      );
      final evalCalm =
          TeamSprintTrainEchelonDiagonalFormation.evaluateDiagonalFormation(
        context: calmContext,
        mode: DiagonalTrainFormationMode.standardInline,
        teamTrain: const [],
        rivalContenders: const [],
      );
      expect(evalCalm.isCrosswindActive, isFalse);
      expect(evalCalm.phase, DiagonalTrainPhase.positioning);
      expect(evalCalm.teamSlots, isEmpty);
      expect(evalCalm.rivalSlots, isEmpty);
    });

    test('JSON round-trip preserves DiagonalTrainWindContext, RiderInput, Slot and GutterTrapReport', () {
      const ctx = DiagonalTrainWindContext(
        windSpeedKmh: 27.5,
        windAngleDegrees: 72.0,
        crosswindSide: CrosswindSide.rightToLeft,
        roadWidthMeters: 6.2,
        distanceToFinishMeters: 1400.0,
        targetTrainSpeedKmh: 59.0,
      );
      final ctxCopy = DiagonalTrainWindContext.fromJson(ctx.toJson());
      expect(ctxCopy.windSpeedKmh, ctx.windSpeedKmh);
      expect(ctxCopy.crosswindSide, ctx.crosswindSide);
      expect(ctxCopy.roadWidthMeters, ctx.roadWidthMeters);

      final rider = _buildTeamTrain().first;
      final riderCopy = EchelonTrainRiderInput.fromJson(rider.toJson());
      expect(riderCopy.riderId, rider.riderId);
      expect(riderCopy.ftpWatts, rider.ftpWatts);
      expect(riderCopy.wPrimeRatio, closeTo(rider.wPrimeRatio, 1e-6));

      final eval =
          TeamSprintTrainEchelonDiagonalFormation.evaluateDiagonalFormation(
        context: ctx,
        mode: DiagonalTrainFormationMode.splitAndSnap,
        teamTrain: _buildTeamTrain(),
        rivalContenders: _buildRivals(),
      );
      final slotCopy = DiagonalRiderSlot.fromJson(eval.teamSlots.first.toJson());
      expect(slotCopy.riderId, eval.teamSlots.first.riderId);
      expect(slotCopy.gutterStatus, eval.teamSlots.first.gutterStatus);

      final reportCopy = GutterTrapReport.fromJson(eval.gutterReport.toJson());
      expect(reportCopy.isGutterClosed, eval.gutterReport.isGutterClosed);
      expect(
        reportCopy.droppedRivalIds,
        equals(eval.gutterReport.droppedRivalIds),
      );
    });
  });

  group('BrakingZoneKineticEnergyLossSolver', () {
    const lightLowProfileWheels = WheelsetModel(
      id: 'w_light',
      brandId: 'b1',
      name: 'Feather Climber 28',
      rimDepthMm: 28,
      weightGrams: 1180,
      aeroCdaModifier: -0.002,
      crosswindStabilityPenalty: 0.05,
      momentOfInertia: 0.082,
      hubEngagementDragWatts: 1.8,
      priceEur: 2400,
    );

    const heavyAeroWheels = WheelsetModel(
      id: 'w_aero',
      brandId: 'b2',
      name: 'Deep Aero 65',
      rimDepthMm: 65,
      weightGrams: 1620,
      aeroCdaModifier: -0.011,
      crosswindStabilityPenalty: 0.45,
      momentOfInertia: 0.165,
      hubEngagementDragWatts: 2.1,
      priceEur: 2200,
    );

    test('computes translational, rotational and inertial mass accurately', () {
      const config = BrakingZoneRiderConfig(
        riderMassKg: 68.0,
        bikeMassKg: 7.0,
        wheelset: heavyAeroWheels,
        wheelRadiusMeters: 0.34,
      );

      expect(config.effectiveRotationalInertiaKgM2, closeTo(0.165, 1e-6));
      expect(
        config.effectiveRotationalMassKg,
        closeTo(0.165 / (0.34 * 0.34), 1e-6),
      );
      expect(
        config.totalEffectiveInertialMassKg,
        closeTo(config.totalSystemMassKg + config.effectiveRotationalMassKg, 1e-6),
      );
    });

    test('fast sweeper requires no braking while hairpin causes major energy and time loss', () {
      const config = BrakingZoneRiderConfig(
        wheelset: lightLowProfileWheels,
        pelotonPositionFactor: 0.0,
      );

      const fastSweeper = BrakingCornerSpec(
        id: 'sweep',
        name: 'Fast Sweeper',
        geometryType: CornerGeometryType.sweeper,
        radiusMeters: 45.0,
        arcAngleDegrees: 40.0,
        entrySpeedMs: 12.0,
      );
      final sweeperRes =
          BrakingZoneKineticEnergyLossSolver.evaluateCornerBrakingZone(
        corner: fastSweeper,
        config: config,
      );
      expect(sweeperRes.severity, BrakingZoneSeverity.noBrakingNeeded);
      expect(sweeperRes.totalKineticEnergyLossJoules, 0.0);
      expect(sweeperRes.timeLostSeconds, 0.0);

      const hairpin = BrakingCornerSpec(
        id: 'hairpin',
        name: 'Station Hairpin',
        geometryType: CornerGeometryType.hairpin180,
        radiusMeters: 6.5,
        arcAngleDegrees: 180.0,
        entrySpeedMs: 14.5,
      );
      final hairpinRes =
          BrakingZoneKineticEnergyLossSolver.evaluateCornerBrakingZone(
        corner: hairpin,
        config: config,
      );

      expect(hairpinRes.severity, isNot(BrakingZoneSeverity.noBrakingNeeded));
      expect(hairpinRes.apexSpeedMs, lessThan(hairpin.entrySpeedMs));
      expect(hairpinRes.translationalEnergyLossJoules, greaterThan(0.0));
      expect(hairpinRes.rotationalEnergyLossJoules, greaterThan(0.0));
      expect(
        hairpinRes.totalKineticEnergyLossJoules,
        closeTo(
          hairpinRes.translationalEnergyLossJoules +
              hairpinRes.rotationalEnergyLossJoules +
              hairpinRes.accordionExtraLossJoules,
          1e-6,
        ),
      );
      expect(hairpinRes.brakeDissipatedEnergyJoules, greaterThan(0.0));
      expect(hairpinRes.reaccelerationWorkJoules, greaterThan(0.0));
      expect(hairpinRes.wPrimeDepletedJoules, greaterThan(0.0));
      expect(hairpinRes.timeLostSeconds, greaterThan(0.0));
      expect(hairpinRes.rotationalShareFraction, inInclusiveRange(0.005, 0.15));
    });

    test('wet surface, peloton accordion effect and downhill grade increase braking losses', () {
      const corner = BrakingCornerSpec(
        id: 't90',
        name: 'City 90°',
        geometryType: CornerGeometryType.ninetyDegreeTurn,
        radiusMeters: 11.0,
        arcAngleDegrees: 90.0,
        entrySpeedMs: 14.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
      );

      const drySolo = BrakingZoneRiderConfig(
        surfaceWetness: 0.0,
        pelotonPositionFactor: 0.0,
      );
      const wetPack = BrakingZoneRiderConfig(
        surfaceWetness: 1.0,
        pelotonPositionFactor: 0.9,
      );

      final dryRes =
          BrakingZoneKineticEnergyLossSolver.evaluateCornerBrakingZone(
        corner: corner,
        config: drySolo,
      );
      final wetPackRes =
          BrakingZoneKineticEnergyLossSolver.evaluateCornerBrakingZone(
        corner: corner,
        config: wetPack,
      );

      expect(wetPackRes.apexSpeedMs, lessThan(dryRes.apexSpeedMs));
      expect(
        wetPackRes.totalKineticEnergyLossJoules,
        greaterThan(dryRes.totalKineticEnergyLossJoules),
      );
      expect(wetPackRes.accordionExtraLossJoules, greaterThan(0.0));
      expect(
        wetPackRes.brakingDistanceMeters,
        greaterThan(dryRes.brakingDistanceMeters),
      );

      const downhillCorner = BrakingCornerSpec(
        id: 't90_dh',
        name: 'Downhill 90°',
        geometryType: CornerGeometryType.ninetyDegreeTurn,
        radiusMeters: 11.0,
        arcAngleDegrees: 90.0,
        entrySpeedMs: 14.0,
        roadGradientPercent: -8.0,
      );
      final dhRes =
          BrakingZoneKineticEnergyLossSolver.evaluateCornerBrakingZone(
        corner: downhillCorner,
        config: wetPack,
      );
      expect(
        dhRes.brakingDecelerationMs2,
        lessThan(wetPackRes.brakingDecelerationMs2),
      );
      expect(
        dhRes.brakingDistanceMeters,
        greaterThan(wetPackRes.brakingDistanceMeters),
      );
    });

    test('evaluates full criterium profile and compares light vs deep aero wheelsets', () {
      final critCorners =
          BrakingZoneKineticEnergyLossSolver.urbanFourCornerCriterium();
      final techCorners =
          BrakingZoneKineticEnergyLossSolver.technicalEightCornerCriterium();

      const baseConfig = BrakingZoneRiderConfig(
        riderMassKg: 70.0,
        bikeMassKg: 7.2,
        riderFtpWatts: 390.0,
        pelotonPositionFactor: 0.55,
      );

      final emptyProfile =
          BrakingZoneKineticEnergyLossSolver.evaluateCourseBrakingProfile(
        discipline: BrakingCourseDiscipline.urbanCriterium,
        lapCorners: const [],
        config: baseConfig,
      );
      expect(emptyProfile.totalBrakingEvents, 0);
      expect(emptyProfile.totalKineticEnergyLossKj, 0.0);

      final critProfile =
          BrakingZoneKineticEnergyLossSolver.evaluateCourseBrakingProfile(
        discipline: BrakingCourseDiscipline.urbanCriterium,
        lapCorners: critCorners,
        config: baseConfig.copyWith(wheelset: lightLowProfileWheels),
        laps: 25,
      );
      expect(critProfile.laps, 25);
      expect(critProfile.cornerCountPerLap, 4);
      expect(critProfile.totalBrakingEvents, greaterThan(50));
      expect(critProfile.totalKineticEnergyLossKj, greaterThan(100.0));
      expect(critProfile.totalRotationalLossKj, greaterThan(0.0));
      expect(critProfile.variabilityIndex, greaterThanOrEqualTo(1.0));
      expect(critProfile.peakBrakeTempCelsius, greaterThan(22.0));

      final comparison =
          BrakingZoneKineticEnergyLossSolver.compareWheelsetsOnCourse(
        discipline: BrakingCourseDiscipline.technicalCircuit,
        lapCorners: techCorners,
        baseConfig: baseConfig,
        wheelsetA: heavyAeroWheels,
        wheelsetB: lightLowProfileWheels,
        laps: 12,
      );

      expect(comparison.rotationalEnergySavedKj, greaterThan(0.0));
      expect(comparison.kineticEnergySavedKj, greaterThan(0.0));
      expect(comparison.summaryReasonPl, isNotEmpty);
      expect(comparison.summaryReasonEn, isNotEmpty);
    });
  });

  group('TeamSprintTrainEchelonDiagonalPanel responsiveness', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders cleanly without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.darkTheme,
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: TeamSprintTrainEchelonDiagonalPanel(),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(
            find.byType(TeamSprintTrainEchelonDiagonalPanel),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
