import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/drafting_grid_system.dart';
import 'package:pro_peloton_manager/engine/peloton/echelon_crosswind_engine.dart';
import 'package:pro_peloton_manager/engine/physics/aero_calculator.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';

StageSegment _createFlatSegment({
  double windDirectionDegrees = 90.0,
  double roadBearingDegrees = 0.0,
  SegmentSurfaceType surfaceType = SegmentSurfaceType.smoothAsphalt,
  double technicalDifficulty = 20.0,
}) {
  return StageSegment(
    index: 0,
    startKm: 0.0,
    lengthKm: 10.0,
    startElevationM: 50.0,
    endElevationM: 50.0,
    surfaceType: surfaceType,
    technicalDifficulty: technicalDifficulty,
    windDirectionDegrees: windDirectionDegrees,
    roadBearingDegrees: roadBearingDegrees,
    sprintOrKomClassification: SegmentClassification.none,
  );
}

RiderSkills _createSkills({
  int raceIq = 75,
  int bikeHandling = 75,
  int draftingEfficiency = 75,
  int aeroPositioning = 75,
}) {
  return RiderSkills(
    cobbles: 60,
    descending: 65,
    bikeHandling: bikeHandling,
    aeroPositioning: aeroPositioning,
    draftingEfficiency: draftingEfficiency,
    raceIq: raceIq,
    rainResistance: 70,
    heatTolerance: 70,
    timeTrialPositioning: 65,
  );
}

void main() {
  group('DraftingGridSystem — redukcja oporu powietrza w peletonie (35–48%)', () {
    test('Kolarz na czele ma 0% oszczędności, 2. koło 32%, 3. rząd 37.5%, środek szerokiego peletonu 45%', () {
      final riderIds = List<String>.generate(60, (i) => 'r_$i');

      final group = DraftingGridSystem.arrangeGroupPositions(
        groupId: 'peloton_main',
        groupType: GroupType.peloton,
        riderIds: riderIds,
        pacemakerRiderIds: const ['r_0'],
        roadWidthMeters: 7.5, // 7 kolumn przy 0.95m
        relativeWindAngleDegrees: 0.0, // wiatr w twarz (brak wachlarzy)
      );

      expect(group.riderCount, equals(60));
      expect(group.positions.length, equals(60));

      final lead = group.getPositionForRider('r_0')!;
      expect(lead.isPulling, isTrue);
      expect(lead.rowIndex, equals(0));
      expect(lead.draftingSavingsPercent, equals(0.0));
      expect(lead.draftingReduction, equals(0.0));
      expect(lead.draftingMultiplier, equals(1.0));

      // Drugi rząd (bezpośrednio za kołem lidera)
      final secondRow = group.positions.firstWhere((p) => p.rowIndex == 1);
      expect(secondRow.isPulling, isFalse);
      expect(secondRow.draftingSavingsPercent, equals(32.0));
      expect(secondRow.draftingReduction, closeTo(0.32, 1e-6));
      expect(secondRow.draftingMultiplier, closeTo(0.68, 1e-6));

      // Trzeci rząd mieści się w przedziale 35–48%
      final thirdRow = group.positions.firstWhere((p) => p.rowIndex == 2);
      expect(thirdRow.draftingSavingsPercent, equals(37.5));
      expect(thirdRow.draftingSavingsPercent, inInclusiveRange(35.0, 48.0));

      // Środek szerokiego peletonu (rząd >= 3, kolumna wewnętrzna, nie ogon)
      final interiorMiddle = group.positions.where(
        (p) => p.rowIndex >= 3 && p.rowIndex <= 5 && p.columnIndex > 0 && p.columnIndex < 6,
      );
      expect(interiorMiddle, isNotEmpty);
      for (final pos in interiorMiddle) {
        expect(pos.draftingSavingsPercent, equals(45.0));
        expect(pos.draftingSavingsPercent, inInclusiveRange(35.0, 48.0));
        expect(pos.draftingReduction, closeTo(0.45, 1e-6));
        expect(pos.draftingMultiplier, closeTo(0.55, 1e-6));
      }

      // Skrajne kolumny w głębi peletonu nadal w przedziale 35–48% (36%), ale mniej niż środek (45%)
      final edgeMiddle = group.positions.firstWhere(
        (p) => p.rowIndex == 4 && p.columnIndex == 0,
      );
      expect(edgeMiddle.draftingSavingsPercent, equals(36.0));
      expect(edgeMiddle.draftingSavingsPercent, inInclusiveRange(35.0, 48.0));
      expect(edgeMiddle.draftingSavingsPercent, lessThan(interiorMiddle.first.draftingSavingsPercent));
    });

    test('Zwężenie drogi (bruk 5*) zmniejsza liczbę kolumn i redukuje maksymalną ochronę środka', () {
      final narrowSegment = _createFlatSegment(
        surfaceType: SegmentSurfaceType.cobblestonesSector5,
      );
      final wideSegment = _createFlatSegment(
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 15.0,
      );

      final narrowWidth = DraftingGridSystem.estimateRoadWidthMeters(narrowSegment);
      final wideWidth = DraftingGridSystem.estimateRoadWidthMeters(wideSegment);
      expect(narrowWidth, equals(3.0));
      expect(wideWidth, equals(7.5));

      final narrowCols = DraftingGridSystem.calculateMaxColumnsForRoadWidth(narrowWidth);
      final wideCols = DraftingGridSystem.calculateMaxColumnsForRoadWidth(wideWidth);
      expect(narrowCols, lessThan(wideCols));

      final riderIds = List<String>.generate(40, (i) => 'r_$i');
      final narrowGroup = DraftingGridSystem.arrangeGroupPositions(
        groupId: 'cobble_peloton',
        groupType: GroupType.peloton,
        riderIds: riderIds,
        pacemakerRiderIds: const ['r_0'],
        roadWidthMeters: narrowWidth,
      );
      final wideGroup = DraftingGridSystem.arrangeGroupPositions(
        groupId: 'wide_peloton',
        groupType: GroupType.peloton,
        riderIds: riderIds,
        pacemakerRiderIds: const ['r_0'],
        roadWidthMeters: wideWidth,
      );

      expect(
        wideGroup.averageDraftingSavingsPercent,
        greaterThan(narrowGroup.averageDraftingSavingsPercent),
      );
    });

    test('AeroCalculator redukuje moc oporu powietrza proporcjonalnie do współczynnika draftingu (35–48%)', () {
      const double speedMs = 12.5; // 45 km/h

      final soloResult = AeroCalculator.calculateDetailed(
        altitudeMeters: 100.0,
        temperatureCelsius: 20.0,
        riderFrontalAreaM2: AeroCalculator.referenceFrontalAreaM2,
        riderPosition: RiderPosition.drops,
        riderSpeedMs: speedMs,
        windSpeedMs: 0.0,
        draftingReduction: 0.0,
      );

      final pelotonCenterResult = AeroCalculator.calculateDetailed(
        altitudeMeters: 100.0,
        temperatureCelsius: 20.0,
        riderFrontalAreaM2: AeroCalculator.referenceFrontalAreaM2,
        riderPosition: RiderPosition.drops,
        riderSpeedMs: speedMs,
        windSpeedMs: 0.0,
        draftingReduction: 0.45,
      );

      final maxDraftResult = AeroCalculator.calculateDetailed(
        altitudeMeters: 100.0,
        temperatureCelsius: 20.0,
        riderFrontalAreaM2: AeroCalculator.referenceFrontalAreaM2,
        riderPosition: RiderPosition.drops,
        riderSpeedMs: speedMs,
        windSpeedMs: 0.0,
        draftingReduction: 0.48,
      );

      final ratioCenter = pelotonCenterResult.aeroPowerWatts / soloResult.aeroPowerWatts;
      final reductionCenterPercent = (1.0 - ratioCenter) * 100.0;
      expect(reductionCenterPercent, closeTo(45.0, 0.1));
      expect(reductionCenterPercent, inInclusiveRange(35.0, 48.0));

      final ratioMax = maxDraftResult.aeroPowerWatts / soloResult.aeroPowerWatts;
      final reductionMaxPercent = (1.0 - ratioMax) * 100.0;
      expect(reductionMaxPercent, closeTo(48.0, 0.1));
      expect(reductionMaxPercent, inInclusiveRange(35.0, 48.0));

      // Wartości powyżej 0.48 są bezpiecznie przycinane do maxDraftingReduction = 0.48
      final clampedResult = AeroCalculator.calculateDetailed(
        altitudeMeters: 100.0,
        temperatureCelsius: 20.0,
        riderFrontalAreaM2: AeroCalculator.referenceFrontalAreaM2,
        riderPosition: RiderPosition.drops,
        riderSpeedMs: speedMs,
        windSpeedMs: 0.0,
        draftingReduction: 0.85,
      );
      expect(clampedResult.draftingReduction, equals(AeroCalculator.maxDraftingReduction));
      expect(clampedResult.aeroPowerWatts, closeTo(maxDraftResult.aeroPowerWatts, 1e-6));
    });

    test('Pusta lista kolarzy zwraca bezpiecznie pustą grupę bez wyjątków', () {
      final emptyGroup = DraftingGridSystem.arrangeGroupPositions(
        groupId: 'empty',
        groupType: GroupType.peloton,
        riderIds: const [],
        pacemakerRiderIds: const [],
        roadWidthMeters: 6.0,
      );

      expect(emptyGroup.riderCount, equals(0));
      expect(emptyGroup.positions, isEmpty);
      expect(emptyGroup.leadRiderId, isNull);
      expect(emptyGroup.averageDraftingSavingsPercent, equals(0.0));
    });
  });

  group('EchelonCrosswindEngine — pękanie grupy na rantach przy wietrze bocznym > 35 km/h', () {
    test('Obliczanie składowej poprzecznej wiatru (0° czołowy, 45° skośny, 90° czysty boczny)', () {
      expect(
        EchelonCrosswindEngine.calculateCrosswindSpeedKmh(
          windSpeedKmh: 45.0,
          relativeWindAngleDegrees: 0.0,
        ),
        closeTo(0.0, 1e-6),
      );
      expect(
        EchelonCrosswindEngine.calculateCrosswindSpeedKmh(
          windSpeedKmh: 45.0,
          relativeWindAngleDegrees: 180.0,
        ),
        closeTo(0.0, 1e-6),
      );
      expect(
        EchelonCrosswindEngine.calculateCrosswindSpeedKmh(
          windSpeedKmh: 45.0,
          relativeWindAngleDegrees: 90.0,
        ),
        closeTo(45.0, 1e-6),
      );
      expect(
        EchelonCrosswindEngine.calculateCrosswindSpeedKmh(
          windSpeedKmh: 50.0,
          relativeWindAngleDegrees: 45.0,
        ),
        closeTo(50.0 * math.sin(math.pi / 4.0), 1e-6),
      );
    });

    test('Brak podziału peletonu przy słabym wietrze bocznym (< 25 km/h) lub małej grupie (< 12 kolarzy)', () {
      final riderIds = List<String>.generate(30, (i) => 'r_$i');
      final skillsMap = {for (final id in riderIds) id: _createSkills()};
      final sourceGroup = PelotonGroup(
        id: 'peloton',
        type: GroupType.peloton,
        riderIds: riderIds,
        pacemakerRiderIds: const ['r_0'],
        positions: const [],
      );
      final segment = _createFlatSegment(windDirectionDegrees: 90.0, roadBearingDegrees: 0.0);

      // Słaby wiatr boczny 20 km/h
      final calmResult = EchelonCrosswindEngine.simulateCrosswindSplit(
        sourceGroup: sourceGroup,
        segment: segment,
        windSpeedKmh: 20.0,
        riderSkillsMap: skillsMap,
        roadWidthMeters: 6.0,
      );

      expect(calmResult.isEchelonActive, isFalse);
      expect(calmResult.crosswindSpeedKmh, closeTo(20.0, 1e-6));
      expect(calmResult.echelons, isEmpty);
      expect(calmResult.resultingGroups.length, equals(1));
      expect(calmResult.gutterRiderIds, isEmpty);

      // Silny wiatr 45 km/h, ale mała grupa 10 kolarzy (< 12)
      final smallGroup = PelotonGroup(
        id: 'breakaway',
        type: GroupType.breakaway,
        riderIds: riderIds.take(10).toList(),
        pacemakerRiderIds: const ['r_0'],
        positions: const [],
      );
      final smallResult = EchelonCrosswindEngine.simulateCrosswindSplit(
        sourceGroup: smallGroup,
        segment: segment,
        windSpeedKmh: 45.0,
        riderSkillsMap: skillsMap,
        roadWidthMeters: 6.0,
      );

      expect(smallResult.isEchelonActive, isFalse);
      expect(smallResult.resultingGroups.length, equals(1));
    });

    test('Peleton pęka na wiele wachlarzy (Echelon 1, 2, 3...) przy wietrze bocznym > 35 km/h', () {
      final riderIds = List<String>.generate(45, (i) => 'rider_$i');
      final skillsMap = <String, RiderSkills>{};

      for (int i = 0; i < riderIds.length; i++) {
        // Zróżnicowane umiejętności pozycjonowania od 95 do 30
        final skillBase = 95 - (i * 1.4).round();
        skillsMap[riderIds[i]] = _createSkills(
          raceIq: skillBase.clamp(25, 99),
          bikeHandling: skillBase.clamp(25, 99),
          draftingEfficiency: skillBase.clamp(25, 99),
          aeroPositioning: skillBase.clamp(25, 99),
        );
      }

      final sourceGroup = PelotonGroup(
        id: 'main_peloton',
        type: GroupType.peloton,
        riderIds: riderIds,
        pacemakerRiderIds: const ['rider_0', 'rider_1'],
        positions: const [],
        averageSpeedKmh: 46.0,
      );

      // Wiatr 42 km/h pod kątem 90° => crosswind = 42 km/h (> 35 km/h)
      final segment = _createFlatSegment(
        windDirectionDegrees: 90.0,
        roadBearingDegrees: 0.0,
        technicalDifficulty: 45.0, // szosa ~6.0m
      );

      final result = EchelonCrosswindEngine.simulateCrosswindSplit(
        sourceGroup: sourceGroup,
        segment: segment,
        windSpeedKmh: 42.0,
        riderSkillsMap: skillsMap,
      );

      expect(result.isEchelonActive, isTrue);
      expect(result.crosswindSpeedKmh, greaterThan(35.0));
      expect(result.echelons.length, greaterThanOrEqualTo(3));
      expect(result.resultingGroups.length, equals(result.echelons.length));
      expect(result.gutterRiderIds, isNotEmpty);

      // Weryfikacja zachowania całkowitej liczby kolarzy (brak zagubionych lub zduplikowanych)
      final allSplitRiders = result.resultingGroups.expand((g) => g.riderIds).toList();
      expect(allSplitRiders.length, equals(45));
      expect(allSplitRiders.toSet().length, equals(45));

      // Pierwszy wachlarz ma limit pojemności echelonCapacity, gap == 0.0 i typ peloton
      final echelon1 = result.echelons[0];
      final echelon2 = result.echelons[1];
      final echelon3 = result.echelons[2];

      expect(echelon1.echelonIndex, equals(1));
      expect(echelon1.riderCount, equals(result.echelonCapacity));
      expect(echelon1.isGutterFormed, isTrue);
      expect(echelon1.gutterRiderId, isNotNull);
      expect(echelon1.gapToLeadEchelonSeconds, equals(0.0));

      expect(echelon2.echelonIndex, equals(2));
      expect(echelon2.gapToLeadEchelonSeconds, greaterThan(0.0));
      expect(echelon3.gapToLeadEchelonSeconds, greaterThan(echelon2.gapToLeadEchelonSeconds));

      expect(result.resultingGroups[0].type, equals(GroupType.peloton));
      expect(result.resultingGroups[1].type, equals(GroupType.chaseGroup));
      expect(result.resultingGroups[2].type, equals(GroupType.grupetto));

      // Kolejne wachlarze jadą wolniej niż pierwszy rant
      expect(
        result.resultingGroups[1].averageSpeedKmh,
        lessThan(result.resultingGroups[0].averageSpeedKmh),
      );
    });

    test('Kolarze ze słabym pozycjonowaniem (raceIq/bikeHandling) odpadają do dalszych rantów / rynsztoka', () {
      final riderIds = List<String>.generate(24, (i) => 'r_$i');
      final skillsMap = <String, RiderSkills>{};

      for (int i = 0; i < 24; i++) {
        if (i < 12) {
          // Elita klasyków
          skillsMap['r_$i'] = _createSkills(
            raceIq: 90,
            bikeHandling: 90,
            draftingEfficiency: 90,
            aeroPositioning: 88,
          );
        } else {
          // Słabi na wietrze
          skillsMap['r_$i'] = _createSkills(
            raceIq: 25,
            bikeHandling: 25,
            draftingEfficiency: 25,
            aeroPositioning: 30,
          );
        }
      }

      final sourceGroup = PelotonGroup(
        id: 'peloton_test',
        type: GroupType.peloton,
        riderIds: riderIds,
        pacemakerRiderIds: const ['r_0'],
        positions: const [],
      );

      final segment = _createFlatSegment(windDirectionDegrees: 90.0, roadBearingDegrees: 0.0);

      final result = EchelonCrosswindEngine.simulateCrosswindSplit(
        sourceGroup: sourceGroup,
        segment: segment,
        windSpeedKmh: 45.0,
        riderSkillsMap: skillsMap,
        roadWidthMeters: 6.0,
      );

      expect(result.isEchelonActive, isTrue);
      final echelon1Riders = result.echelons.first.riderIds.toSet();

      // Wszyscy w 1. wachlarzu powinni pochodzić z grupy elity (r_0..r_11)
      for (final id in echelon1Riders) {
        final idx = int.parse(id.split('_').last);
        expect(idx, lessThan(12));
      }

      // Żaden ze słabszych kolarzy (r_12..r_23) nie utrzymał się w 1. wachlarzu — wszyscy spadli do dalszych rantów
      final laterEchelonsRiders = result.echelons
          .skip(1)
          .expand((e) => e.riderIds)
          .toSet();
      for (int i = 12; i < 24; i++) {
        expect(echelon1Riders.contains('r_$i'), isFalse);
        expect(laterEchelonsRiders.contains('r_$i'), isTrue);
      }
    });

    test('Wypchnięcie na pobocze (gutter) przy wietrze bocznym > 35° drastycznie obniża ochronę aero w DraftingGridSystem', () {
      final riderIds = List<String>.generate(25, (i) => 'r_$i');

      final crosswindGroup = DraftingGridSystem.arrangeGroupPositions(
        groupId: 'crosswind_group',
        groupType: GroupType.peloton,
        riderIds: riderIds,
        pacemakerRiderIds: const ['r_0'],
        roadWidthMeters: 6.0, // echelonCapacity = floor(6.0 / 1.15) = 5
        relativeWindAngleDegrees: 90.0,
      );

      final protectedRiders = crosswindGroup.positions.where((p) => !p.isInGutter && !p.isPulling).toList();
      final gutterRiders = crosswindGroup.positions.where((p) => p.isInGutter).toList();

      expect(protectedRiders, isNotEmpty);
      expect(gutterRiders, isNotEmpty);

      for (final gutterPos in gutterRiders) {
        // Po redukcji * 0.45 oszczędność spada wyraźnie poniżej progu peletonu (35%)
        expect(gutterPos.draftingSavingsPercent, lessThan(25.0));
        expect(gutterPos.draftingSavingsPercent, greaterThanOrEqualTo(12.0));
      }
    });

    test('Serializacja JSON dla GridRiderPosition, PelotonGroup i EchelonFormation zachowuje spójność danych', () {
      final group = DraftingGridSystem.arrangeGroupPositions(
        groupId: 'json_group',
        groupType: GroupType.peloton,
        riderIds: const ['r_0', 'r_1', 'r_2', 'r_3'],
        pacemakerRiderIds: const ['r_0'],
        roadWidthMeters: 6.0,
      );

      final decodedGroup = PelotonGroup.fromJson(group.toJson());
      expect(decodedGroup.id, equals(group.id));
      expect(decodedGroup.type, equals(group.type));
      expect(decodedGroup.riderIds, equals(group.riderIds));
      expect(decodedGroup.positions.length, equals(group.positions.length));
      expect(
        decodedGroup.positions[1].draftingSavingsPercent,
        equals(group.positions[1].draftingSavingsPercent),
      );

      const formation = EchelonFormation(
        echelonIndex: 1,
        riderIds: ['r_0', 'r_1'],
        capacity: 8,
        isGutterFormed: true,
        gutterRiderId: 'r_2',
        averageDraftingSavingsPercent: 16.5,
        gapToLeadEchelonSeconds: 0.0,
      );
      final decodedFormation = EchelonFormation.fromJson(formation.toJson());
      expect(decodedFormation.echelonIndex, equals(1));
      expect(decodedFormation.isGutterFormed, isTrue);
      expect(decodedFormation.gutterRiderId, equals('r_2'));
      expect(decodedFormation.averageDraftingSavingsPercent, equals(16.5));
    });
  });
}
