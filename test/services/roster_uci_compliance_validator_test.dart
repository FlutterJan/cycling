import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/equipment/complete_bike.dart';
import 'package:pro_peloton_manager/models/equipment/equipment_wear_and_maintenance.dart';
import 'package:pro_peloton_manager/models/equipment/frame_model.dart';
import 'package:pro_peloton_manager/models/equipment/groupset_model.dart';
import 'package:pro_peloton_manager/models/equipment/tire_model.dart';
import 'package:pro_peloton_manager/models/equipment/wheelset_model.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/tour_race.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/services/career/anti_doping_and_whereabouts_service.dart';
import 'package:pro_peloton_manager/services/career/roster_uci_compliance_validator.dart';
import 'package:pro_peloton_manager/services/generators/rider_procedural_generator.dart';

void main() {
  const validator = RosterUciComplianceValidator();

  Rider buildRider(
    String id, {
    int ovr = 78,
    RiderHealth? health,
  }) {
    final generated = RiderProceduralGenerator.generateRider(
      id: id,
      targetOverallRating: ovr,
      random: math.Random(id.hashCode),
    );
    return generated.copyWith(
      health: health ??
          const RiderHealth(
            acuteTrainingLoad: 45.0,
            chronicTrainingLoad: 55.0,
          ),
    );
  }

  CompleteBike buildBike(
    String id, {
    int frameWeightGrams = 950,
    int wheelsetWeightGrams = 1400,
    int groupsetWeightGrams = 2300,
    int tireWeightGrams = 275,
    EquipmentWearAndMaintenance? wear,
  }) {
    // Suma: peripheral (1250g) + frame + wheelset + groupset + 2*tire
    // Domyślnie: 1250 + 950 + 1400 + 2300 + 550 = 6450g? Uwaga: 1250+950+1400+2300+550 = 6450g (<6.80)!
    // Dla 7.00 kg: frame 1150g + wheelset 1500g + groupset 2500g + 2*300g = 7000g (7.00 kg)
    return CompleteBike(
      id: id,
      name: 'Team Bike $id',
      frame: FrameModel(
        id: 'frame_$id',
        brandId: 'brand_1',
        name: 'Carbon SL',
        category: FrameCategory.allRounder,
        weightGrams: frameWeightGrams,
        aeroCdaModifier: -0.010,
        stiffnessToWeightIndex: 1.8,
        comfortCompliance: 0.7,
        priceEur: 5500,
        mesh3dAssetPath: 'assets/3d/bike.glb',
        primaryColorHex: '#8E4A49',
      ),
      wheelset: WheelsetModel(
        id: 'wheel_$id',
        brandId: 'brand_1',
        name: 'Aero 45',
        rimDepthMm: 45,
        weightGrams: wheelsetWeightGrams,
        aeroCdaModifier: -0.008,
        crosswindStabilityPenalty: 0.2,
        momentOfInertia: 0.08,
        hubEngagementDragWatts: 0.4,
        priceEur: 2200,
      ),
      groupset: GroupsetModel(
        id: 'group_$id',
        brandId: 'brand_1',
        name: 'Pro Di2 12s',
        weightGrams: groupsetWeightGrams,
        isElectronic: true,
        speedCount: 12,
        mechanicalEfficiency: 0.984,
        priceEur: 3200,
      ),
      tire: TireModel(
        id: 'tire_$id',
        brandId: 'brand_1',
        name: 'Corsa Pro 28',
        widthMm: 28,
        weightGrams: tireWeightGrams,
        rollingResistanceCrr: 0.0034,
        punctureResistanceIndex: 3.5,
        wetGripIndex: 4.2,
        isTubeless: true,
        priceEur: 90,
      ),
      cockpitWidthMm: 400,
      hoodInwardTiltDegrees: 6.0,
      slammedStem: true,
      wearAndMaintenance: wear ?? EquipmentWearAndMaintenance.brandNew(),
    );
  }

  CompleteBike buildCompliantBike(String id) => buildBike(
        id,
        frameWeightGrams: 1150,
        wheelsetWeightGrams: 1500,
        groupsetWeightGrams: 2500,
        tireWeightGrams: 300,
      ); // 1.25 + 1.15 + 1.50 + 2.50 + 0.60 = 7.00 kg

  CompleteBike buildUnderweightBike(String id) => buildBike(
        id,
        frameWeightGrams: 750,
        wheelsetWeightGrams: 1250,
        groupsetWeightGrams: 2150,
        tireWeightGrams: 250,
      ); // 1.25 + 0.75 + 1.25 + 2.15 + 0.50 = 5.90 kg (< 6.80 kg)

  TourRace buildRace({
    required RaceCategory category,
    required int stageCount,
    int ridersPerTeam = 7,
  }) {
    final stages = List<RaceStage>.generate(
      stageCount,
      (i) => RaceStage(
        id: 'stage_${i + 1}',
        stageNumber: i + 1,
        name: 'Etap ${i + 1}',
        stageType: StageType.flat,
        segments: const [],
        baseTemperatureCelsius: 20.0,
        weatherCondition: WeatherCondition.sunny,
        windSpeedKmh: 10.0,
      ),
    );
    return TourRace(
      id: 'race_${category.name}',
      name: category == RaceCategory.grandTour
          ? 'Tour de France'
          : 'Paris-Roubaix',
      countryIso: 'FRA',
      uciCategory: category,
      startMonth: 7,
      startDay: 5,
      stages: stages,
      prizePoolEur: 500000,
      participatingTeamIds: const ['team_1'],
      ridersPerTeam: ridersPerTeam,
      classifications: const RaceClassifications(
        generalClassification: [],
        pointsClassification: [],
        mountainsClassification: [],
        youthClassification: [],
        teamClassification: [],
      ),
    );
  }

  group('RosterUciComplianceValidator', () {
    test('wymaga 8 kolarzy na Grand Tour oraz 7 na wyścig jednodniowy', () {
      final grandTour = buildRace(
        category: RaceCategory.grandTour,
        stageCount: 21,
        ridersPerTeam: 8,
      );
      final oneDay = buildRace(
        category: RaceCategory.monument,
        stageCount: 1,
        ridersPerTeam: 7,
      );

      expect(validator.requiredRosterSizeForRace(grandTour), 8);
      expect(validator.requiredRosterSizeForRace(oneDay), 7);

      final nineRiders = List.generate(9, (i) => buildRider('r_$i'));
      final gtOverReport = validator.validateAndAutoFill(
        race: grandTour,
        selectedRoster: nineRiders,
      );
      expect(gtOverReport.isInitiallyCompliant, isFalse);
      expect(
        gtOverReport.initialViolations.any(
          (v) => v.type == RosterComplianceViolationType.rosterSizeExceeded,
        ),
        isTrue,
      );
      expect(gtOverReport.resolvedRoster.length, 8);
      expect(gtOverReport.isResolvedCompliant, isTrue);

      final sevenRiders = nineRiders.take(7).toList();
      final oneDayValidReport = validator.validateAndAutoFill(
        race: oneDay,
        selectedRoster: sevenRiders,
      );
      expect(oneDayValidReport.isInitiallyCompliant, isTrue);
      expect(oneDayValidReport.isResolvedCompliant, isTrue);
    });

    test('wykrywa zawieszenia medyczne i dopingowe oraz uzupełnia luki najlepszymi rezerwami', () {
      final oneDay = buildRace(
        category: RaceCategory.monument,
        stageCount: 1,
      );

      final injuredRider = buildRider(
        'r_injured',
        ovr: 85,
        health: const RiderHealth(
          acuteTrainingLoad: 30,
          chronicTrainingLoad: 50,
          currentInjury: Injury(
            name: 'Złamanie obojczyka',
            type: InjuryType.clavicleFracture,
            daysRemaining: 14,
            trainingAllowed: false,
          ),
        ),
      );

      final dopedRider = buildRider('r_doped', ovr: 86);
      final sanction = AntiDopingSanction(
        id: 'sanc_1',
        riderId: dopedRider.id,
        riderName: dopedRider.fullName,
        reason: 'Pozytywny wynik testu EPO',
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2027, 5, 1),
        suspensionMonths: 12,
        uciPointsStripped: 400,
      );

      final healthyStarters = List.generate(5, (i) => buildRider('starter_$i', ovr: 80));
      final selected = [...healthyStarters, injuredRider, dopedRider];

      final sickReserve = buildRider(
        'res_sick',
        ovr: 90,
        health: const RiderHealth(
          acuteTrainingLoad: 20,
          chronicTrainingLoad: 50,
          currentIllness: 'Grypa',
        ),
      );
      final abpSuspendedReserve = buildRider('res_abp', ovr: 89);
      final healthyReserveTop = buildRider('res_top', ovr: 84);
      final healthyReserveMid = buildRider('res_mid', ovr: 79);

      final report = validator.validateAndAutoFill(
        race: oneDay,
        selectedRoster: selected,
        reservePool: [
          sickReserve,
          abpSuspendedReserve,
          healthyReserveMid,
          healthyReserveTop,
        ],
        raceDate: DateTime(2026, 7, 5),
        activeSanctions: [sanction],
        biologicalPassportStatuses: {
          abpSuspendedReserve.id: BiologicalPassportStatus.suspended,
        },
      );

      expect(report.isInitiallyCompliant, isFalse);
      expect(
        report.initialViolations.map((v) => v.type),
        containsAll([
          RosterComplianceViolationType.medicalSuspension,
          RosterComplianceViolationType.dopingSuspension,
        ]),
      );
      expect(report.isResolvedCompliant, isTrue);
      expect(report.resolvedRoster.length, 7);
      expect(report.resolvedRoster.map((r) => r.id), containsAll(['res_top', 'res_mid']));
      expect(report.resolvedRoster.map((r) => r.id), isNot(contains('r_injured')));
      expect(report.resolvedRoster.map((r) => r.id), isNot(contains('r_doped')));
      expect(report.resolvedRoster.map((r) => r.id), isNot(contains('res_sick')));
      expect(report.resolvedRoster.map((r) => r.id), isNot(contains('res_abp')));
      expect(report.autoFillActions.length, 2);
      expect(report.autoFillActions.first.addedReserve.id, 'res_top');
    });

    test('weryfikuje limit masy roweru >= 6.80 kg oraz sprawność techniczną z zamianą na rower zapasowy', () {
      final oneDay = buildRace(
        category: RaceCategory.worldTourOneDay,
        stageCount: 1,
      );
      final riders = List.generate(7, (i) => buildRider('r_$i', ovr: 80));

      final underweightBike = buildUnderweightBike('bike_light');
      final wornBike = CompleteBike(
        id: 'bike_worn',
        name: buildCompliantBike('bike_worn').name,
        frame: buildCompliantBike('bike_worn').frame,
        wheelset: buildCompliantBike('bike_worn').wheelset,
        groupset: buildCompliantBike('bike_worn').groupset,
        tire: buildCompliantBike('bike_worn').tire,
        cockpitWidthMm: 400,
        hoodInwardTiltDegrees: 6.0,
        slammedStem: true,
        wearAndMaintenance: EquipmentWearAndMaintenance.brandNew().copyWith(
          electronicBatteryPercent: 5.0,
        ),
      );

      final bikesByRider = <String, CompleteBike>{
        riders[0].id: underweightBike,
        riders[1].id: wornBike,
        for (int i = 2; i < 7; i++) riders[i].id: buildCompliantBike('bike_$i'),
      };

      final spareCompliant1 = buildCompliantBike('spare_1');
      final spareCompliant2 = buildCompliantBike('spare_2');

      final report = validator.validateAndAutoFill(
        race: oneDay,
        selectedRoster: riders,
        assignedBikesByRiderId: bikesByRider,
        spareBikes: [spareCompliant1, spareCompliant2],
      );

      expect(report.isInitiallyCompliant, isFalse);
      expect(
        report.initialViolations.map((v) => v.type),
        containsAll([
          RosterComplianceViolationType.bikeUnderweight,
          RosterComplianceViolationType.bikeUnroadworthy,
        ]),
      );
      // Po przydzieleniu 2 sprawnych rowerów zapasowych wszyscy 7 kolarze są dopuszczeni
      expect(report.isResolvedCompliant, isTrue);
      expect(report.resolvedBikesByRiderId[riders[0].id]?.id, 'spare_1');
      expect(report.resolvedBikesByRiderId[riders[1].id]?.id, 'spare_2');

      // Sprawdź także tryb allowUciBallast: true dla lekkiego roweru
      final ballastCheck = validator.checkBikeCompliance(
        underweightBike,
        allowUciBallast: true,
      );
      expect(ballastCheck.requiresBallast, isTrue);
      expect(ballastCheck.ballastGramsNeeded, greaterThan(0));
      expect(ballastCheck.isCompliant, isTrue);
    });

    test('raportuje brak możliwości pełnego uzupełnienia przy zbyt małej liczbie zdrowych rezerw', () {
      final grandTour = buildRace(
        category: RaceCategory.grandTour,
        stageCount: 21,
      );
      final riders = List.generate(6, (i) => buildRider('r_$i'));
      final oneReserve = [buildRider('res_1')];

      final report = validator.validateAndAutoFill(
        race: grandTour,
        selectedRoster: riders,
        reservePool: oneReserve,
      );

      expect(report.isInitiallyCompliant, isFalse);
      expect(report.isResolvedCompliant, isFalse);
      expect(report.resolvedRoster.length, 7);
      expect(
        report.remainingViolations.single.type,
        RosterComplianceViolationType.rosterSizeInsufficient,
      );
    });
  });
}
