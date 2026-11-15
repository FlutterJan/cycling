import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/career_save.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/career/race_calendar_selection_service.dart';
import 'package:pro_peloton_manager/services/database/demo_save_preset_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });
  });

  group('DemoSavePresetBuilder Tests', () {
    test('presets metadata zawiera dokładnie 4 bogate scenariusze', () {
      expect(DemoSavePresetBuilder.presets.length, 4);
      for (final type in DemoSavePresetType.values) {
        final info = DemoSavePresetBuilder.getInfo(type);
        expect(info.title, isNotEmpty);
        expect(info.description, isNotEmpty);
        expect(info.keyHighlights.length, greaterThanOrEqualTo(3));
        expect(info.budgetEur, greaterThan(0));
      }
    });

    test('Scenariusz 1: Polski Projekt WorldTour', () async {
      final save = await DemoSavePresetBuilder.buildPreset(
        DemoSavePresetType.polishWorldTourProject,
        seasonYear: 2026,
      );

      expect(save.playerTeam.division, TeamDivision.proTeam);
      expect(save.playerTeam.countryIso, 'POL');
      expect(save.playerCashBalanceEur, 8000000);
      expect(save.currentDate.month, 3);

      // Młody talent górski z Tatr
      final tatraStar = save.playerRoster.firstWhere(
        (r) => r.id == 'rider_pl_tatra_diamond',
      );
      expect(tatraStar.nationalityIso, 'POL');
      expect(tatraStar.specialization, RiderSpecialization.pureClimber);
      expect(tatraStar.potential, greaterThanOrEqualTo(95));

      // Oczekujący wniosek o Dziką Kartę na Tour de France
      final tdfWc = save.wildcardApplications.firstWhere(
        (w) => w.raceId == 'race_tour_de_france_2026',
      );
      expect(tdfWc.status, WildcardStatus.pending);
    });

    test('Scenariusz 2: Pojedynek Tytanów w Alpach (18. etap, -14s)', () async {
      final save = await DemoSavePresetBuilder.buildPreset(
        DemoSavePresetType.alpineTitansDuel,
        seasonYear: 2026,
      );

      expect(save.isRaceDay, isTrue);
      expect(save.calendar.activeRaceId, 'race_tour_de_france_2026');
      expect(save.calendar.activeStageIndex, 17); // 18. etap (0-based 17)

      final stage18 = save.activeStage!;
      expect(stage18.stageNumber, 18);
      final highPasses = stage18.segments
          .where((seg) => seg.endElevationM > 2000.0)
          .toList();
      expect(highPasses.length, greaterThanOrEqualTo(3));

      final gc = save.activeRace!.classifications.generalClassification;
      expect(gc.length, greaterThanOrEqualTo(2));
      expect(gc[0].timeBehindLeaderSeconds, 0);
      expect(gc[1].teamId, save.playerTeamId);
      expect(gc[1].timeBehindLeaderSeconds, 14);
    });

    test('Scenariusz 3: Kampania Brukowana (kwiecień, deszcz, 2 Monumenty)', () async {
      final save = await DemoSavePresetBuilder.buildPreset(
        DemoSavePresetType.cobbledCampaign,
        seasonYear: 2026,
      );

      expect(save.currentDate.month, 4);
      expect(save.playerTeam.countryIso, 'BEL');

      final flanders = save.calendar.getRaceById('race_flanders_monument_2026')!;
      final roubaix = save.calendar.getRaceById('race_roubaix_monument_2026')!;

      expect(
        flanders.stages.first.weatherCondition == WeatherCondition.lightRain ||
            flanders.stages.first.weatherCondition == WeatherCondition.heavyStorm,
        isTrue,
      );
      expect(
        roubaix.stages.first.weatherCondition == WeatherCondition.lightRain ||
            roubaix.stages.first.weatherCondition == WeatherCondition.heavyStorm,
        isTrue,
      );

      final leader = save.playerRoster.firstWhere(
        (r) => r.id == 'rider_bel_cobble_king',
      );
      expect(leader.skills.cobbles, greaterThanOrEqualTo(95));
    });

    test('Scenariusz 4: Imperium Galaktyczne (45 mln EUR, 3 gwiazdy, 3 GT)', () async {
      final save = await DemoSavePresetBuilder.buildPreset(
        DemoSavePresetType.galacticEmpire,
        seasonYear: 2026,
      );

      expect(save.playerCashBalanceEur, 45000000);
      expect(save.franchiseLeaders.length, 3);
      expect(save.dedicatedSquads.length, 3);

      final stars = save.playerRoster.where(
        (r) => r.id.startsWith('rider_gal_star_'),
      ).toList();
      expect(stars.length, 3);
      for (final star in stars) {
        expect(star.overallRating, greaterThanOrEqualTo(88));
        expect(star.contract.leaderLoyalty, lessThan(50.0));
      }

      final primarySponsor = save.playerTeam.sponsors.first;
      expect(primarySponsor.objectives.length, 3);

      // Weryfikacja serializacji JSON round-trip
      final roundTrip = CareerSave.fromJson(save.toJson());
      expect(roundTrip.playerCashBalanceEur, 45000000);
      expect(roundTrip.franchiseLeaders.length, 3);
    });
  });
}
