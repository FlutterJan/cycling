import 'dart:convert';

import '../services/career/race_calendar_selection_service.dart';
import '../services/career/scouting_and_youth_academy_service.dart';
import '../services/generators/initial_game_seeder.dart';
import 'career/career_save.dart';
import 'career/season_calendar.dart';
import 'career/staff_member.dart';
import 'equipment/bike_fit_configuration.dart';
import 'equipment/complete_bike.dart';
import 'equipment/equipment_wear_and_maintenance.dart';
import 'equipment/frame_model.dart';
import 'equipment/groupset_model.dart';
import 'equipment/tire_model.dart';
import 'equipment/wheelset_model.dart';
import 'race/race_stage.dart';
import 'race/stage_segment.dart';
import 'race/tour_race.dart';
import 'rider/lactate_and_lab_profile.dart';
import 'rider/rider.dart';
import 'rider/rider_appearance.dart';
import 'rider/rider_contract.dart';
import 'rider/rider_health.dart';
import 'rider/rider_physiology.dart';
import 'rider/rider_power_profile.dart';
import 'rider/rider_skills.dart';
import 'team/bike_manufacturer_deal.dart';
import 'team/cycling_team.dart';
import 'team/sponsor_contract.dart';

/// Pojedynczy wykryty problem podczas audytu serializacji/deserializacji modelu.
class ModelAuditIssue {
  final String modelType;
  final String entityId;
  final String stage;
  final String message;

  const ModelAuditIssue({
    required this.modelType,
    required this.entityId,
    required this.stage,
    required this.message,
  });

  @override
  String toString() => '[$modelType][$entityId] ($stage): $message';
}

/// Zbiorczy raport z kompleksowego audytu serializacji wszystkich modeli danych.
class ModelAuditReport {
  final int totalModelsChecked;
  final int ridersChecked;
  final int teamsChecked;
  final int bikesChecked;
  final int racesChecked;
  final int stagesChecked;
  final int segmentsChecked;
  final int sponsorsChecked;
  final int staffChecked;
  final int otherModelsChecked;
  final int durationMs;
  final List<ModelAuditIssue> issues;

  const ModelAuditReport({
    required this.totalModelsChecked,
    required this.ridersChecked,
    required this.teamsChecked,
    required this.bikesChecked,
    required this.racesChecked,
    required this.stagesChecked,
    required this.segmentsChecked,
    required this.sponsorsChecked,
    required this.staffChecked,
    required this.otherModelsChecked,
    required this.durationMs,
    required this.issues,
  });

  bool get isSuccess => issues.isEmpty;

  String get summaryReport {
    final status = isSuccess ? 'PASS (0 błędów)' : 'FAIL (${issues.length} błędów)';
    final buffer = StringBuffer()
      ..writeln('=== MODEL SERIALIZATION AUDIT [$status] (${durationMs}ms) ===')
      ..writeln('Łącznie zweryfikowanych obiektów: $totalModelsChecked')
      ..writeln('• Kolarze (Rider + 6 sub-modeli): $ridersChecked')
      ..writeln('• Drużyny (CyclingTeam + Staff + BikeDeal): $teamsChecked')
      ..writeln('• Rowery (CompleteBike + Frame/Wheel/Groupset/Tire): $bikesChecked')
      ..writeln('• Wyścigi (TourRace + RaceClassifications): $racesChecked')
      ..writeln('• Etapy (RaceStage): $stagesChecked')
      ..writeln('• Segmenty (StageSegment): $segmentsChecked')
      ..writeln('• Sponsorzy (SponsorContract + SponsorObjective): $sponsorsChecked')
      ..writeln('• Personel (StaffMember, Roster, Grupy, Przypisania): $staffChecked')
      ..writeln('• Pozostałe modele (CareerSave, Calendar, Wear, Fit, Scouting): $otherModelsChecked');

    if (issues.isNotEmpty) {
      buffer.writeln('\nWykryte błędy:');
      for (final issue in issues.take(25)) {
        buffer.writeln('  - $issue');
      }
      if (issues.length > 25) {
        buffer.writeln('  ... oraz ${issues.length - 25} kolejnych błędów.');
      }
    }
    return buffer.toString();
  }

  @override
  String toString() => summaryReport;
}

/// Pomocnicza klasa walidująca serializację i deserializację (`fromJson(jsonDecode(jsonEncode(toJson())))`)
/// wszystkich modeli danych z katalogów `rider/`, `equipment/`, `team/`, `race/` i `career/`.
class ModelSerializationAudit {
  ModelSerializationAudit._();

  /// Generuje pełny świat gry przez [InitialGameSeeder] i uruchamia audyt wszystkich modeli.
  static Future<ModelAuditReport> auditGeneratedWorld({
    InitialGameSeedConfig? config,
  }) async {
    final effectiveConfig = config ??
        const InitialGameSeedConfig(
          playerTeamId: 'wt_poland_project',
          seed: 20260205,
          saveToDisk: false,
        );
    final seedResult = await InitialGameSeeder.seedNewGame(effectiveConfig);
    return auditCareerSave(seedResult.save);
  }

  /// Testuje w pętli serializację i deserializację wszystkich modeli zawartych w [save]
  /// oraz uzupełniających modeli domenowych (sprzęt, personel, kontuzje, klasyfikacje).
  static ModelAuditReport auditCareerSave(CareerSave save) {
    final stopwatch = Stopwatch()..start();
    final issues = <ModelAuditIssue>[];

    int totalChecked = 0;
    int ridersChecked = 0;
    int teamsChecked = 0;
    int bikesChecked = 0;
    int racesChecked = 0;
    int stagesChecked = 0;
    int segmentsChecked = 0;
    int sponsorsChecked = 0;
    int staffChecked = 0;
    int otherChecked = 0;

    void check<T>(
      String modelType,
      String entityId,
      T original,
      Map<String, dynamic> Function(T) toJson,
      T Function(Map<String, dynamic>) fromJson, {
      bool Function(T a, T b)? equals,
      void Function()? onPass,
    }) {
      totalChecked++;
      try {
        final rawMap = toJson(original);
        final encoded = jsonEncode(rawMap);
        final decoded = jsonDecode(encoded) as Map<String, dynamic>;
        final restored = fromJson(decoded);
        final isEqual = equals != null ? equals(original, restored) : (original == restored);
        if (!isEqual) {
          issues.add(
            ModelAuditIssue(
              modelType: modelType,
              entityId: entityId,
              stage: 'equality',
              message: 'Obiekt po deserializacji różni się od oryginału.',
            ),
          );
          return;
        }
        onPass?.call();
      } catch (e) {
        issues.add(
          ModelAuditIssue(
            modelType: modelType,
            entityId: entityId,
            stage: 'roundTrip',
            message: e.toString(),
          ),
        );
      }
    }

    // 1. Główny obiekt CareerSave oraz SeasonCalendar
    check<CareerSave>(
      'CareerSave',
      save.id,
      save,
      (m) => m.toJson(),
      CareerSave.fromJson,
      equals: (a, b) =>
          a.id == b.id &&
          a.teams.length == b.teams.length &&
          a.riders.length == b.riders.length &&
          a.calendar.races.length == b.calendar.races.length,
      onPass: () => otherChecked++,
    );

    check<SeasonCalendar>(
      'SeasonCalendar',
      'season_${save.calendar.seasonYear}',
      save.calendar,
      (m) => m.toJson(),
      SeasonCalendar.fromJson,
      equals: (a, b) => a == b && a.races.length == b.races.length,
      onPass: () => otherChecked++,
    );

    // 2. Wszystkie modele kolarzy i ich podmodele
    for (final rider in save.riders) {
      check<Rider>(
        'Rider',
        rider.id,
        rider,
        (m) => m.toJson(),
        Rider.fromJson,
        onPass: () => ridersChecked++,
      );
      check<RiderPhysiology>(
        'RiderPhysiology',
        rider.id,
        rider.physiology,
        (m) => m.toJson(),
        RiderPhysiology.fromJson,
        onPass: () => otherChecked++,
      );
      if (rider.physiology.labProfile != null) {
        check<LactateAndLabProfile>(
          'LactateAndLabProfile',
          rider.id,
          rider.physiology.labProfile!,
          (m) => m.toJson(),
          LactateAndLabProfile.fromJson,
          onPass: () => otherChecked++,
        );
      }
      check<RiderPowerProfile>(
        'RiderPowerProfile',
        rider.id,
        rider.powerProfile,
        (m) => m.toJson(),
        RiderPowerProfile.fromJson,
        onPass: () => otherChecked++,
      );
      check<RiderSkills>(
        'RiderSkills',
        rider.id,
        rider.skills,
        (m) => m.toJson(),
        RiderSkills.fromJson,
        onPass: () => otherChecked++,
      );
      check<RiderAppearance>(
        'RiderAppearance',
        rider.id,
        rider.appearance,
        (m) => m.toJson(),
        RiderAppearance.fromJson,
        onPass: () => otherChecked++,
      );
      check<RiderContract>(
        'RiderContract',
        rider.id,
        rider.contract,
        (m) => m.toJson(),
        RiderContract.fromJson,
        onPass: () => otherChecked++,
      );
      check<RiderHealth>(
        'RiderHealth',
        rider.id,
        rider.health,
        (m) => m.toJson(),
        RiderHealth.fromJson,
        onPass: () => otherChecked++,
      );
    }

    // 3. Wszystkie drużyny, kontrakty sponsorskie i flota sprzętu
    for (final team in save.teams) {
      check<CyclingTeam>(
        'CyclingTeam',
        team.id,
        team,
        (m) => m.toJson(),
        CyclingTeam.fromJson,
        equals: (a, b) =>
            a == b &&
            a.rosterRiderIds.length == b.rosterRiderIds.length &&
            a.sponsors.length == b.sponsors.length &&
            a.inventoryBikes.length == b.inventoryBikes.length,
        onPass: () => teamsChecked++,
      );
      check<TeamStaff>(
        'TeamStaff',
        team.id,
        team.staff,
        (m) => m.toJson(),
        TeamStaff.fromJson,
        onPass: () => otherChecked++,
      );
      check<BikeManufacturerDeal>(
        'BikeManufacturerDeal',
        '${team.id}_${team.bikeDeal.manufacturerId}',
        team.bikeDeal,
        (m) => m.toJson(),
        BikeManufacturerDeal.fromJson,
        onPass: () => otherChecked++,
      );

      for (final sponsor in team.sponsors) {
        check<SponsorContract>(
          'SponsorContract',
          sponsor.id,
          sponsor,
          (m) => m.toJson(),
          SponsorContract.fromJson,
          equals: (a, b) => a == b && a.objectives.length == b.objectives.length,
          onPass: () => sponsorsChecked++,
        );
        for (final obj in sponsor.objectives) {
          check<SponsorObjective>(
            'SponsorObjective',
            obj.id,
            obj,
            (m) => m.toJson(),
            SponsorObjective.fromJson,
            onPass: () => sponsorsChecked++,
          );
        }
      }

      for (final bike in team.inventoryBikes) {
        check<CompleteBike>(
          'CompleteBike',
          bike.id,
          bike,
          (m) => m.toJson(),
          CompleteBike.fromJson,
          onPass: () => bikesChecked++,
        );
        check<FrameModel>(
          'FrameModel',
          bike.frame.id,
          bike.frame,
          (m) => m.toJson(),
          FrameModel.fromJson,
          onPass: () => otherChecked++,
        );
        check<WheelsetModel>(
          'WheelsetModel',
          bike.wheelset.id,
          bike.wheelset,
          (m) => m.toJson(),
          WheelsetModel.fromJson,
          onPass: () => otherChecked++,
        );
        check<GroupsetModel>(
          'GroupsetModel',
          bike.groupset.id,
          bike.groupset,
          (m) => m.toJson(),
          GroupsetModel.fromJson,
          onPass: () => otherChecked++,
        );
        check<TireModel>(
          'TireModel',
          bike.tire.id,
          bike.tire,
          (m) => m.toJson(),
          TireModel.fromJson,
          onPass: () => otherChecked++,
        );
      }
    }

    // 4. Wszystkie wyścigi, etapy i segmenty
    for (final race in save.calendar.races) {
      check<TourRace>(
        'TourRace',
        race.id,
        race,
        (m) => m.toJson(),
        TourRace.fromJson,
        equals: (a, b) =>
            a == b &&
            a.stages.length == b.stages.length &&
            a.participatingTeamIds.length == b.participatingTeamIds.length,
        onPass: () => racesChecked++,
      );
      check<RaceClassifications>(
        'RaceClassifications',
        race.id,
        race.classifications,
        (m) => m.toJson(),
        RaceClassifications.fromJson,
        equals: (a, b) =>
            a.generalClassification.length == b.generalClassification.length &&
            a.teamClassification.length == b.teamClassification.length,
        onPass: () => otherChecked++,
      );

      for (final stage in race.stages) {
        check<RaceStage>(
          'RaceStage',
          stage.id,
          stage,
          (m) => m.toJson(),
          RaceStage.fromJson,
          equals: (a, b) => a == b && a.segments.length == b.segments.length,
          onPass: () => stagesChecked++,
        );
        for (final segment in stage.segments) {
          check<StageSegment>(
            'StageSegment',
            '${stage.id}_seg_${segment.index}',
            segment,
            (m) => m.toJson(),
            StageSegment.fromJson,
            onPass: () => segmentsChecked++,
          );
        }
      }
    }

    // 5. Kolekcje kariery (finanse, oferty, skauting, dzikie karty, akademia)
    for (final entry in save.financeLedger) {
      check<CareerFinanceLedgerEntry>(
        'CareerFinanceLedgerEntry',
        entry.id,
        entry,
        (m) => m.toJson(),
        CareerFinanceLedgerEntry.fromJson,
        onPass: () => otherChecked++,
      );
    }
    for (final offer in save.contractOffers) {
      check<CareerContractOffer>(
        'CareerContractOffer',
        offer.offerId,
        offer,
        (m) => m.toJson(),
        CareerContractOffer.fromJson,
        onPass: () => otherChecked++,
      );
    }
    for (final prospect in save.scoutingProspects) {
      check<ScoutedProspect>(
        'ScoutedProspect',
        prospect.id,
        prospect,
        (m) => m.toJson(),
        ScoutedProspect.fromJson,
        onPass: () => otherChecked++,
      );
    }
    for (final wc in save.wildcardApplications) {
      check<WildcardApplication>(
        'WildcardApplication',
        wc.id,
        wc,
        (m) => m.toJson(),
        WildcardApplication.fromJson,
        onPass: () => otherChecked++,
      );
    }
    check<YouthAcademy>(
      'YouthAcademy',
      'academy_${save.id}',
      save.youthAcademy,
      (m) => m.toJson(),
      YouthAcademy.fromJson,
      equals: (a, b) =>
          a.level == b.level &&
          a.enrolledProspectIds.length == b.enrolledProspectIds.length,
      onPass: () => otherChecked++,
    );

    // 6. Modele uzupełniające, które nie zawsze są aktywne w świeżym zapisie
    _auditSupplementaryModels(
      check: check,
      onStaffPass: () => staffChecked++,
      onOtherPass: () => otherChecked++,
    );

    stopwatch.stop();
    return ModelAuditReport(
      totalModelsChecked: totalChecked,
      ridersChecked: ridersChecked,
      teamsChecked: teamsChecked,
      bikesChecked: bikesChecked,
      racesChecked: racesChecked,
      stagesChecked: stagesChecked,
      segmentsChecked: segmentsChecked,
      sponsorsChecked: sponsorsChecked,
      staffChecked: staffChecked,
      otherModelsChecked: otherChecked,
      durationMs: stopwatch.elapsedMilliseconds,
      issues: List<ModelAuditIssue>.unmodifiable(issues),
    );
  }

  static void _auditSupplementaryModels({
    required void Function<T>(
      String modelType,
      String entityId,
      T original,
      Map<String, dynamic> Function(T) toJson,
      T Function(Map<String, dynamic>) fromJson, {
      bool Function(T a, T b)? equals,
      void Function()? onPass,
    }) check,
    required void Function() onStaffPass,
    required void Function() onOtherPass,
  }) {
    // BikeFitConfiguration
    const bikeFit = BikeFitConfiguration(
      saddleHeightMm: 745.0,
      saddleSetbackMm: 62.5,
      saddleTiltDegrees: -1.5,
      cockpitWidthMm: 380,
      stemLengthMm: 120,
      spacersStackMm: 10,
      hoodInwardTiltDegrees: 11.0,
      crankArmLengthMm: 170.0,
      cleatOffsetMm: -4.0,
    );
    check<BikeFitConfiguration>(
      'BikeFitConfiguration',
      'default_fit',
      bikeFit,
      (m) => m.toJson(),
      BikeFitConfiguration.fromJson,
      onPass: onOtherPass,
    );

    // EquipmentWearAndMaintenance + podmodele
    final wear = EquipmentWearAndMaintenance.brandNew();
    check<EquipmentWearAndMaintenance>(
      'EquipmentWearAndMaintenance',
      'brand_new_wear',
      wear,
      (m) => m.toJson(),
      EquipmentWearAndMaintenance.fromJson,
      equals: (a, b) =>
          a.electronicBatteryPercent == b.electronicBatteryPercent &&
          a.chain.waxFilmRemainingPercent == b.chain.waxFilmRemainingPercent &&
          a.frontTire.treadWearPercent == b.frontTire.treadWearPercent,
      onPass: onOtherPass,
    );

    // Injury
    const injury = Injury(
      name: 'Złamanie obojczyka',
      type: InjuryType.clavicleFracture,
      daysRemaining: 28,
      trainingAllowed: false,
    );
    check<Injury>(
      'Injury',
      'sample_injury',
      injury,
      (m) => m.toJson(),
      Injury.fromJson,
      onPass: onOtherPass,
    );

    // RaceHistoryEntry + klasyfikacje
    final historyEntry = RaceHistoryEntry(
      raceId: 'tour_de_pologne',
      raceName: 'Tour de Pologne',
      seasonYear: 2026,
      winnerRiderId: 'r_1',
      winnerRiderName: 'Jan Kowalski',
      winnerTeamId: 't_1',
      winnerTeamName: 'Polska Projekt WT',
      winnerTotalTimeSeconds: 95432,
      completedDate: DateTime(2026, 8, 10),
    );
    check<RaceHistoryEntry>(
      'RaceHistoryEntry',
      historyEntry.raceId,
      historyEntry,
      (m) => m.toJson(),
      RaceHistoryEntry.fromJson,
      onPass: onOtherPass,
    );

    const riderClassEntry = RiderClassificationEntry(
      riderId: 'r_1',
      riderName: 'Jan Kowalski',
      teamId: 't_1',
      totalTimeSeconds: 95432,
      points: 120,
      rank: 1,
      timeBehindLeaderSeconds: 0,
    );
    check<RiderClassificationEntry>(
      'RiderClassificationEntry',
      riderClassEntry.riderId,
      riderClassEntry,
      (m) => m.toJson(),
      RiderClassificationEntry.fromJson,
      onPass: onOtherPass,
    );

    const teamClassEntry = TeamClassificationEntry(
      teamId: 't_1',
      teamName: 'Polska Projekt WT',
      totalTimeSeconds: 286296,
      rank: 1,
      timeBehindLeaderSeconds: 0,
    );
    check<TeamClassificationEntry>(
      'TeamClassificationEntry',
      teamClassEntry.teamId,
      teamClassEntry,
      (m) => m.toJson(),
      TeamClassificationEntry.fromJson,
      onPass: onOtherPass,
    );

    // FullTeamStaffRoster + wszystkie 5 klas StaffMember + TrainingGroup + RaceDirectorAssignment
    final roster = StaffProceduralGenerator.generateDefaultTeamStaffRoster(
      division: TeamDivision.worldTour,
      teamCountryIso: 'PL',
      seed: 42,
    );
    check<FullTeamStaffRoster>(
      'FullTeamStaffRoster',
      'wt_roster',
      roster,
      (m) => m.toJson(),
      FullTeamStaffRoster.fromJson,
      equals: (a, b) =>
          a.sportsDirectors.length == b.sportsDirectors.length &&
          a.coaches.length == b.coaches.length &&
          a.doctors.length == b.doctors.length &&
          a.mechanics.length == b.mechanics.length &&
          a.scouts.length == b.scouts.length,
      onPass: onStaffPass,
    );

    for (final director in roster.sportsDirectors) {
      check<StaffMember>(
        'SportsDirector',
        director.id,
        director,
        (m) => m.toJson(),
        StaffMember.fromJson,
        equals: (a, b) => a.id == b.id && a.role == b.role && a.morale == b.morale,
        onPass: onStaffPass,
      );
    }
    for (final coach in roster.coaches) {
      check<StaffMember>(
        'PerformanceCoach',
        coach.id,
        coach,
        (m) => m.toJson(),
        StaffMember.fromJson,
        equals: (a, b) => a.id == b.id && a.role == b.role && a.morale == b.morale,
        onPass: onStaffPass,
      );
    }
    for (final doctor in roster.doctors) {
      check<StaffMember>(
        'TeamDoctor',
        doctor.id,
        doctor,
        (m) => m.toJson(),
        StaffMember.fromJson,
        equals: (a, b) => a.id == b.id && a.role == b.role && a.morale == b.morale,
        onPass: onStaffPass,
      );
    }
    for (final mechanic in roster.mechanics) {
      check<StaffMember>(
        'HeadMechanic',
        mechanic.id,
        mechanic,
        (m) => m.toJson(),
        StaffMember.fromJson,
        equals: (a, b) => a.id == b.id && a.role == b.role && a.morale == b.morale,
        onPass: onStaffPass,
      );
    }
    for (final scout in roster.scouts) {
      check<StaffMember>(
        'Scout',
        scout.id,
        scout,
        (m) => m.toJson(),
        StaffMember.fromJson,
        equals: (a, b) => a.id == b.id && a.role == b.role && a.morale == b.morale,
        onPass: onStaffPass,
      );
    }

    const trainingGroup = TrainingGroup(
      id: 'grp_gc',
      name: 'Grupa Górska',
      description: 'Trening pod Grand Tour',
      focusSpecialization: CoachSpecialization.enduranceAndClimbing,
      assignedCoachId: 'coach_1',
      assignedRiderIds: ['r_1', 'r_2'],
    );
    check<TrainingGroup>(
      'TrainingGroup',
      trainingGroup.id,
      trainingGroup,
      (m) => m.toJson(),
      TrainingGroup.fromJson,
      equals: (a, b) =>
          a.id == b.id &&
          a.focusSpecialization == b.focusSpecialization &&
          a.assignedRiderIds.length == b.assignedRiderIds.length,
      onPass: onStaffPass,
    );

    final assignment = RaceDirectorAssignment(
      raceId: 'tour_de_france',
      raceName: 'Tour de France',
      leadDirectorId: 'ds_1',
      supportDirectorId: 'ds_2',
      assignedAt: DateTime(2026, 7, 1),
    );
    check<RaceDirectorAssignment>(
      'RaceDirectorAssignment',
      assignment.raceId,
      assignment,
      (m) => m.toJson(),
      RaceDirectorAssignment.fromJson,
      equals: (a, b) =>
          a.raceId == b.raceId &&
          a.leadDirectorId == b.leadDirectorId &&
          a.supportDirectorId == b.supportDirectorId,
      onPass: onStaffPass,
    );
  }
}
