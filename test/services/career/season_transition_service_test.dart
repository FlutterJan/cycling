import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/career_save.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/career/season_transition_service.dart';
import 'package:pro_peloton_manager/services/database/save_service.dart';
import 'package:pro_peloton_manager/services/generators/world_teams_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });
  });

  group('SeasonTransitionService Tests', () {
    late CareerSave baseSave;

    setUp(() async {
      final world = WorldTeamsGenerator.generateWorldTourSystem(seed: 42);
      final firstTeamId = world.teams.first.id;

      baseSave = await SaveService.createNewCareer(
        saveName: 'Test Transition Career',
        playerManagerName: 'Dyrektor Sportowy',
        playerTeamId: firstTeamId,
        difficulty: CareerDifficulty.normal,
        seasonYear: 2026,
      );
    });

    test('1. canPerformSeasonTransition rozpoznaje zakończenie sezonu w listopadzie/grudniu', () {
      // W trakcie sezonu (np. lipiec podczas Tour de France) przejście jest zablokowane
      final midSeasonSave = baseSave.copyWith(
        currentDate: DateTime(2026, 7, 15),
      );
      expect(SeasonTransitionService.canPerformSeasonTransition(midSeasonSave), isFalse);

      // Pod koniec sezonu (np. 15 listopada) przejście jest dozwolone
      final endSeasonSave = baseSave.copyWith(
        currentDate: DateTime(2026, 11, 15),
      );
      expect(SeasonTransitionService.canPerformSeasonTransition(endSeasonSave), isTrue);

      // W grudniu przejście jest również dozwolone
      final decemberSave = baseSave.copyWith(
        currentDate: DateTime(2026, 12, 10),
      );
      expect(SeasonTransitionService.canPerformSeasonTransition(decemberSave), isTrue);
    });

    test('2. Podsumowanie nagród UCI i przyznanie nagród finansowych dla zespołu gracza', () {
      // Ustawiamy drużynie gracza wysokie punkty UCI (np. 2. miejsce w WorldTour)
      final playerTeamId = baseSave.playerTeamId;
      final updatedTeams = baseSave.teams.map((t) {
        if (t.id == playerTeamId) {
          return t.copyWith(uciPointsSeason: 4800);
        } else {
          return t.copyWith(uciPointsSeason: 2100);
        }
      }).toList();

      final initialCash = baseSave.playerCashBalanceEur;

      final saveWithPoints = baseSave.copyWith(
        teams: updatedTeams,
        currentDate: DateTime(2026, 11, 15),
      );

      final result = SeasonTransitionService.executeSeasonTransition(
        saveWithPoints,
        newTalentsCount: 80,
        random: math.Random(12345),
      );

      final awards = result.report.awards;
      expect(awards.riderOfTheYear, isNotNull);
      expect(awards.worldTourTeamRankings.isNotEmpty, isTrue);

      // Drużyna gracza z 4800 pkt powinna zająć 1. miejsce i otrzymać nagrodę finansową
      expect(awards.playerTeamRank, equals(1));
      expect(awards.playerTeamPrizeEur, equals(3000000)); // 3.0M EUR za 1. miejsce

      // Sprawdź czy nagroda trafiła do księgi finansowej i powiększyła stan konta
      expect(result.updatedSave.playerCashBalanceEur, greaterThan(initialCash));
      expect(
        result.updatedSave.financeLedger.any((f) => f.category == FinanceCategory.prizeMoney),
        isTrue,
      );
    });

    test('3. Awanse i spadki drużyn między WorldTour i ProTeam na podstawie punktów', () {
      // Dajemy dwóm najgorszym zespołom WorldTour znikomą liczbę punktów
      final wtTeams = baseSave.teams.where((t) => t.division == TeamDivision.worldTour).toList();
      final proTeams = baseSave.teams.where((t) => t.division == TeamDivision.proTeam).toList();

      expect(wtTeams.length, greaterThanOrEqualTo(2));
      expect(proTeams.length, greaterThanOrEqualTo(2));

      final worstWt1 = wtTeams[wtTeams.length - 2];
      final worstWt2 = wtTeams[wtTeams.length - 1];

      final bestPro1 = proTeams[0];
      final bestPro2 = proTeams[1];

      final modifiedTeams = baseSave.teams.map((t) {
        if (t.id == worstWt1.id) {
          return t.copyWith(uciPointsSeason: 50); // Najgorszy WorldTour
        } else if (t.id == worstWt2.id) {
          return t.copyWith(uciPointsSeason: 20); // Ostatni WorldTour
        } else if (t.id == bestPro1.id) {
          return t.copyWith(uciPointsSeason: 3500); // 1. ProTeam (awans)
        } else if (t.id == bestPro2.id) {
          return t.copyWith(uciPointsSeason: 3200); // 2. ProTeam (awans)
        } else {
          return t.copyWith(uciPointsSeason: 1500);
        }
      }).toList();

      final saveForRelegation = baseSave.copyWith(
        teams: modifiedTeams,
        currentDate: DateTime(2026, 11, 20),
      );

      final result = SeasonTransitionService.executeSeasonTransition(
        saveForRelegation,
        newTalentsCount: 80,
        random: math.Random(42),
      );

      final promReleg = result.report.promotionRelegation;

      // Weryfikacja spadków
      expect(promReleg.relegatedTeams.length, equals(2));
      final relegatedIds = promReleg.relegatedTeams.map((e) => e.teamId).toSet();
      expect(relegatedIds.contains(worstWt1.id), isTrue);
      expect(relegatedIds.contains(worstWt2.id), isTrue);

      // Weryfikacja awansów
      expect(promReleg.promotedTeams.length, equals(2));
      final promotedIds = promReleg.promotedTeams.map((e) => e.teamId).toSet();
      expect(promotedIds.contains(bestPro1.id), isTrue);
      expect(promotedIds.contains(bestPro2.id), isTrue);

      // Weryfikacja zaktualizowanych obiektów CyclingTeam w nowym sezonie
      final updatedWorstWt1 = result.updatedSave.getTeamById(worstWt1.id);
      final updatedBestPro1 = result.updatedSave.getTeamById(bestPro1.id);

      expect(updatedWorstWt1?.division, equals(TeamDivision.proTeam));
      expect(updatedBestPro1?.division, equals(TeamDivision.worldTour));
    });

    test('4. Emerytury kolarzy w wieku powyżej 36-38 lat z wygasającymi umowami', () {
      // Wstrzykujemy weterana w wieku 39 lat z wygasającym kontraktem
      final veteranRider = baseSave.riders.first.copyWith(
        id: 'veteran_legend_39',
        firstName: 'Alejandro',
        lastName: 'Veterano',
        birthDate: DateTime(1987, 4, 25), // 39 lat w 2026
        careerPointsUci: 4500,
        contract: baseSave.riders.first.contract.copyWith(
          contractEndYear: 2026, // Wygasa w tym roku!
        ),
      );

      // Dodajemy młodego kolarza w wieku 21 lat
      final youngRider = baseSave.riders.first.copyWith(
        id: 'young_talent_21',
        firstName: 'Jan',
        lastName: 'Mlody',
        birthDate: DateTime(2005, 5, 10), // 21 lat w 2026
        contract: baseSave.riders.first.contract.copyWith(
          contractEndYear: 2028,
        ),
      );

      final saveWithVeterans = baseSave.copyWith(
        riders: [veteranRider, youngRider, ...baseSave.riders],
        currentDate: DateTime(2026, 11, 25),
      );

      final result = SeasonTransitionService.executeSeasonTransition(
        saveWithVeterans,
        newTalentsCount: 80,
        random: math.Random(123),
      );

      // Sprawdź czy raport emerytur zawiera weterana
      final retirements = result.report.retiredRiders;
      expect(retirements.isNotEmpty, isTrue);

      final isVeteranRetired = retirements.any((r) => r.riderId == veteranRider.id);
      expect(isVeteranRetired, isTrue);

      // Młody kolarz absolutnie nie powinien przejść na emeryturę
      final isYoungRetired = retirements.any((r) => r.riderId == youngRider.id);
      expect(isYoungRetired, isFalse);

      // Emerytowany kolarz nie powinien znajdować się w aktywnej puli zawodników na nowy rok
      final activeIds = result.updatedSave.riders.map((r) => r.id).toSet();
      expect(activeIds.contains(veteranRider.id), isFalse);
      expect(activeIds.contains(youngRider.id), isTrue);
    });

    test('5. Generowanie nowej fali dokładnie 80 młodych talentów U19/U23', () {
      final saveBefore = baseSave.copyWith(
        currentDate: DateTime(2026, 12, 1),
      );

      final result = SeasonTransitionService.executeSeasonTransition(
        saveBefore,
        newTalentsCount: 80,
        random: math.Random(999),
      );

      // Sprawdź liczbę wygenerowanych talentów
      expect(result.report.newTalentsGeneratedCount, equals(80));

      // Sprawdź czy nowi adepci mają prawidłowy wiek U19/U23 (17-21 lat)
      final newProspects = result.updatedSave.scoutingProspects
          .where((p) => p.id.startsWith('prospect_2027_'))
          .toList();

      expect(newProspects.length, equals(80));
      for (final p in newProspects) {
        expect(p.age, inInclusiveRange(17, 21));
        expect(p.fullName.isNotEmpty, isTrue);
        expect(p.nationalityIso.isNotEmpty, isTrue);
        expect(p.estimatedMinFtpWatts, lessThan(p.estimatedMaxFtpWatts));
      }
    });

    test('6. Rozwój statystyk młodych kolarzy (progresja) oraz naturalna regresja weteranów', () {
      // Młody kolarz (wiek 19 lat, OVR 68, potencjał 92)
      final neoProRider = baseSave.riders.first.copyWith(
        id: 'neo_pro_growing',
        birthDate: DateTime(2007, 3, 1), // 19 lat
        potential: 94,
        physiology: baseSave.riders.first.physiology.copyWith(ftpWatts: 340),
        powerProfile: baseSave.riders.first.powerProfile.copyWith(watts60m: 340),
      );

      // Starszy kolarz (wiek 36 lat)
      final olderRider = baseSave.riders.first.copyWith(
        id: 'older_rider_declining',
        birthDate: DateTime(1990, 2, 1), // 36 lat
        physiology: baseSave.riders.first.physiology.copyWith(ftpWatts: 420),
        powerProfile: baseSave.riders.first.powerProfile.copyWith(watts60m: 420),
        contract: baseSave.riders.first.contract.copyWith(contractEndYear: 2029), // Nie emerytuje
      );

      final saveWithProgression = baseSave.copyWith(
        riders: [neoProRider, olderRider, ...baseSave.riders],
        currentDate: DateTime(2026, 12, 1),
      );

      final result = SeasonTransitionService.executeSeasonTransition(
        saveWithProgression,
        newTalentsCount: 80,
        random: math.Random(777),
      );

      final updatedNeoPro = result.updatedSave.getRiderById(neoProRider.id);
      expect(updatedNeoPro, isNotNull);

      // Młody kolarz powinien zyskać na FTP (progresja)
      expect(updatedNeoPro!.physiology.ftpWatts, greaterThan(340));
      expect(result.report.topProgressions.any((p) => p.riderId == neoProRider.id), isTrue);

      final progressionEntry = result.report.topProgressions.firstWhere((p) => p.riderId == neoProRider.id);
      expect(progressionEntry.ftpDelta, greaterThan(0));
      expect(progressionEntry.isYouth, isTrue);
    });

    test('7. Realizacja podpisanych wcześniej transferów kontraktowych z dniem 1 stycznia', () {
      // Wybieramy kolarza z innej drużyny i podpisujemy z nim kontrakt do drużyny gracza
      final otherTeam = baseSave.teams.firstWhere((t) => t.id != baseSave.playerTeamId);
      final candidateRiderId = otherTeam.rosterRiderIds.first;
      final candidateRider = baseSave.getRiderById(candidateRiderId)!;

      final acceptedOffer = CareerContractOffer(
        offerId: 'offer_accepted_tdf_star',
        riderId: candidateRider.id,
        riderName: candidateRider.fullName,
        offeringTeamId: baseSave.playerTeamId,
        offeringTeamName: baseSave.playerTeam.name,
        annualSalaryEur: 1800000,
        contractDurationYears: 3,
        winBonusEur: 50000,
        proposedRole: RiderRole.teamLeader,
        status: ContractOfferStatus.accepted,
        offeredDate: DateTime(2026, 8, 15),
      );

      final saveWithTransfer = baseSave.copyWith(
        contractOffers: [acceptedOffer],
        currentDate: DateTime(2026, 11, 28),
      );

      final result = SeasonTransitionService.executeSeasonTransition(
        saveWithTransfer,
        newTalentsCount: 80,
        random: math.Random(111),
      );

      // Sprawdź raport zrealizowanych transferów
      final transfers = result.report.executedTransfers;
      expect(transfers.isNotEmpty, isTrue);

      final ourTransfer = transfers.firstWhere((t) => t.riderId == candidateRider.id);
      expect(ourTransfer.toTeamId, equals(baseSave.playerTeamId));
      expect(ourTransfer.isPlayerTeamInvolved, isTrue);

      // Sprawdź skład nowej drużyny (drużyna gracza ma teraz nowego kolarza!)
      final updatedPlayerTeam = result.updatedSave.playerTeam;
      expect(updatedPlayerTeam.rosterRiderIds.contains(candidateRider.id), isTrue);

      // Sprawdź skład starej drużyny (kolarz został usunięty)
      final updatedOldTeam = result.updatedSave.getTeamById(otherTeam.id)!;
      expect(updatedOldTeam.rosterRiderIds.contains(candidateRider.id), isFalse);

      // Sprawdź kontrakt kolarza
      final transferredRider = result.updatedSave.getRiderById(candidateRider.id)!;
      expect(transferredRider.contract.teamId, equals(baseSave.playerTeamId));
      expect(transferredRider.contract.role, equals(RiderRole.teamLeader));
      expect(transferredRider.contract.contractEndYear, equals(2027 + 3));
    });

    test('8. Reset na nowy rok: data 1 stycznia 2027, nowy kalendarz wyścigów i zerowanie punktów sezonu', () {
      final saveBefore = baseSave.copyWith(
        currentDate: DateTime(2026, 12, 15),
        currentSeasonYear: 2026,
      );

      final result = SeasonTransitionService.executeSeasonTransition(
        saveBefore,
        newTalentsCount: 80,
        random: math.Random(333),
      );

      final newSave = result.updatedSave;

      // 1. Zmiana roku i daty
      expect(newSave.currentSeasonYear, equals(2027));
      expect(newSave.currentDate, equals(DateTime(2027, 1, 1)));

      // 2. Nowy kalendarz wyścigów
      expect(newSave.calendar.seasonYear, equals(2027));
      expect(newSave.calendar.races.isNotEmpty, isTrue);
      expect(newSave.calendar.completedRaceIds.isEmpty, isTrue);

      // 3. Zerowanie punktów UCI w nowym sezonie
      for (final team in newSave.teams) {
        expect(team.uciPointsSeason, equals(0));
      }

      // 4. Regeneracja posezonowa kolarzy (ATL zresetowane do 0)
      for (final rider in newSave.riders) {
        expect(rider.health.acuteTrainingLoad, equals(0.0));
      }

      // 5. Generowanie nagłówków prasowych w raporcie
      expect(result.report.newsHeadlines.isNotEmpty, isTrue);
    });
  });
}

