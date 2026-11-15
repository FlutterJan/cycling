import 'dart:math' as math;
import '../../core/utils/formatters.dart';
import '../../models/career/career_save.dart';
import '../../models/career/season_calendar.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/team/cycling_team.dart';
import '../generators/rider_procedural_generator.dart';
import '../generators/uci_calendar_generator.dart';
import 'scouting_and_youth_academy_service.dart';

/// Laureat nagrody indywidualnej UCI na koniec sezonu.
class UciRiderAward {
  final String riderId;
  final String riderName;
  final String teamName;
  final String nationalityIso;
  final int uciPoints;
  final String awardTitle;
  final String awardDescription;

  const UciRiderAward({
    required this.riderId,
    required this.riderName,
    required this.teamName,
    required this.nationalityIso,
    required this.uciPoints,
    required this.awardTitle,
    required this.awardDescription,
  });

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'teamName': teamName,
        'nationalityIso': nationalityIso,
        'uciPoints': uciPoints,
        'awardTitle': awardTitle,
        'awardDescription': awardDescription,
      };
}

/// Zespół nagrodzony w oficjalnej klasyfikacji UCI na koniec sezonu.
class UciTeamAward {
  final String teamId;
  final String teamName;
  final TeamDivision division;
  final int rank;
  final int uciPoints;
  final int prizeMoneyEur;

  const UciTeamAward({
    required this.teamId,
    required this.teamName,
    required this.division,
    required this.rank,
    required this.uciPoints,
    required this.prizeMoneyEur,
  });

  String get formattedPrize => Formatters.formatCurrency(prizeMoneyEur);

  Map<String, dynamic> toJson() => {
        'teamId': teamId,
        'teamName': teamName,
        'division': division.toJson(),
        'rank': rank,
        'uciPoints': uciPoints,
        'prizeMoneyEur': prizeMoneyEur,
      };
}

/// Pełne podsumowanie nagród i rankingu UCI za miniony sezon.
class UciAwardsSummary {
  final UciRiderAward? riderOfTheYear;
  final UciRiderAward? bestYoungRiderU23;
  final UciTeamAward? teamOfTheYear;
  final List<UciTeamAward> worldTourTeamRankings;
  final List<UciTeamAward> proTeamRankings;
  final int playerTeamRank;
  final int playerTeamPrizeEur;

  const UciAwardsSummary({
    this.riderOfTheYear,
    this.bestYoungRiderU23,
    this.teamOfTheYear,
    required this.worldTourTeamRankings,
    required this.proTeamRankings,
    required this.playerTeamRank,
    required this.playerTeamPrizeEur,
  });

  Map<String, dynamic> toJson() => {
        'riderOfTheYear': riderOfTheYear?.toJson(),
        'bestYoungRiderU23': bestYoungRiderU23?.toJson(),
        'teamOfTheYear': teamOfTheYear?.toJson(),
        'worldTourTeamRankings':
            worldTourTeamRankings.map((t) => t.toJson()).toList(),
        'proTeamRankings': proTeamRankings.map((t) => t.toJson()).toList(),
        'playerTeamRank': playerTeamRank,
        'playerTeamPrizeEur': playerTeamPrizeEur,
      };
}

/// Wpis drużyny awansującej do wyższej dywizji (ProTeam ➔ WorldTour).
class TeamPromotionEntry {
  final String teamId;
  final String teamName;
  final int seasonPoints;
  final String reason;

  const TeamPromotionEntry({
    required this.teamId,
    required this.teamName,
    required this.seasonPoints,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'teamId': teamId,
        'teamName': teamName,
        'seasonPoints': seasonPoints,
        'reason': reason,
      };
}

/// Wpis drużyny spadającej do niższej dywizji (WorldTour ➔ ProTeam).
class TeamRelegationEntry {
  final String teamId;
  final String teamName;
  final int seasonPoints;
  final String reason;

  const TeamRelegationEntry({
    required this.teamId,
    required this.teamName,
    required this.seasonPoints,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'teamId': teamId,
        'teamName': teamName,
        'seasonPoints': seasonPoints,
        'reason': reason,
      };
}

/// Zestawienie awansów i spadków między UCI WorldTour i ProTeam.
class PromotionRelegationSummary {
  final List<TeamPromotionEntry> promotedTeams;
  final List<TeamRelegationEntry> relegatedTeams;
  final bool didPlayerTeamPromote;
  final bool didPlayerTeamRelegate;

  const PromotionRelegationSummary({
    required this.promotedTeams,
    required this.relegatedTeams,
    required this.didPlayerTeamPromote,
    required this.didPlayerTeamRelegate,
  });

  Map<String, dynamic> toJson() => {
        'promotedTeams': promotedTeams.map((e) => e.toJson()).toList(),
        'relegatedTeams': relegatedTeams.map((e) => e.toJson()).toList(),
        'didPlayerTeamPromote': didPlayerTeamPromote,
        'didPlayerTeamRelegate': didPlayerTeamRelegate,
      };
}

/// Raport o kolarzu przechodzącym na sportową emeryturę.
class RetiredRiderReport {
  final String riderId;
  final String riderName;
  final int age;
  final String nationalityIso;
  final String formerTeamName;
  final int careerPointsUci;
  final RiderSpecialization specialization;
  final String farewellQuote;

  const RetiredRiderReport({
    required this.riderId,
    required this.riderName,
    required this.age,
    required this.nationalityIso,
    required this.formerTeamName,
    required this.careerPointsUci,
    required this.specialization,
    required this.farewellQuote,
  });

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'age': age,
        'nationalityIso': nationalityIso,
        'formerTeamName': formerTeamName,
        'careerPointsUci': careerPointsUci,
        'specialization': specialization.toJson(),
        'farewellQuote': farewellQuote,
      };
}

/// Raport o rozwoju statystyk pojedynczego kolarza (progresja / regresja).
class RiderProgressionReport {
  final String riderId;
  final String riderName;
  final int age;
  final String teamName;
  final int oldOvr;
  final int newOvr;
  final int ovrDelta;
  final int oldFtp;
  final int newFtp;
  final int ftpDelta;
  final bool isYouth;

  const RiderProgressionReport({
    required this.riderId,
    required this.riderName,
    required this.age,
    required this.teamName,
    required this.oldOvr,
    required this.newOvr,
    required this.ovrDelta,
    required this.oldFtp,
    required this.newFtp,
    required this.ftpDelta,
    required this.isYouth,
  });

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'age': age,
        'teamName': teamName,
        'oldOvr': oldOvr,
        'newOvr': newOvr,
        'ovrDelta': ovrDelta,
        'oldFtp': oldFtp,
        'newFtp': newFtp,
        'ftpDelta': ftpDelta,
        'isYouth': isYouth,
      };
}

/// Raport o zrealizowanym transferze na nowy sezon.
class ExecutedTransferReport {
  final String riderId;
  final String riderName;
  final String fromTeamId;
  final String fromTeamName;
  final String toTeamId;
  final String toTeamName;
  final int annualSalaryEur;
  final RiderRole role;
  final bool isPlayerTeamInvolved;

  const ExecutedTransferReport({
    required this.riderId,
    required this.riderName,
    required this.fromTeamId,
    required this.fromTeamName,
    required this.toTeamId,
    required this.toTeamName,
    required this.annualSalaryEur,
    required this.role,
    required this.isPlayerTeamInvolved,
  });

  String get formattedSalary => Formatters.formatCurrency(annualSalaryEur);

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'fromTeamId': fromTeamId,
        'fromTeamName': fromTeamName,
        'toTeamId': toTeamId,
        'toTeamName': toTeamName,
        'annualSalaryEur': annualSalaryEur,
        'role': role.toJson(),
        'isPlayerTeamInvolved': isPlayerTeamInvolved,
      };
}

/// Raport o sytuacji drużyny gracza po zakończeniu sezonu.
class PlayerTeamSeasonReport {
  final String teamName;
  final TeamDivision oldDivision;
  final TeamDivision newDivision;
  final bool wasPromoted;
  final bool wasRelegated;
  final int seasonUciPoints;
  final int seasonRank;
  final int uciPrizeMoneyEur;
  final int incomingTransfersCount;
  final int outgoingTransfersCount;
  final int retiringRidersCount;
  final int progressingYouthCount;

  const PlayerTeamSeasonReport({
    required this.teamName,
    required this.oldDivision,
    required this.newDivision,
    required this.wasPromoted,
    required this.wasRelegated,
    required this.seasonUciPoints,
    required this.seasonRank,
    required this.uciPrizeMoneyEur,
    required this.incomingTransfersCount,
    required this.outgoingTransfersCount,
    required this.retiringRidersCount,
    required this.progressingYouthCount,
  });

  Map<String, dynamic> toJson() => {
        'teamName': teamName,
        'oldDivision': oldDivision.toJson(),
        'newDivision': newDivision.toJson(),
        'wasPromoted': wasPromoted,
        'wasRelegated': wasRelegated,
        'seasonUciPoints': seasonUciPoints,
        'seasonRank': seasonRank,
        'uciPrizeMoneyEur': uciPrizeMoneyEur,
        'incomingTransfersCount': incomingTransfersCount,
        'outgoingTransfersCount': outgoingTransfersCount,
        'retiringRidersCount': retiringRidersCount,
        'progressingYouthCount': progressingYouthCount,
      };
}

/// Całościowy raport końcoworoczny z przejścia sezonu.
class SeasonTransitionReport {
  final int oldSeasonYear;
  final int newSeasonYear;
  final UciAwardsSummary awards;
  final PromotionRelegationSummary promotionRelegation;
  final List<RetiredRiderReport> retiredRiders;
  final List<RiderProgressionReport> topProgressions;
  final List<ExecutedTransferReport> executedTransfers;
  final int newTalentsGeneratedCount;
  final PlayerTeamSeasonReport playerTeamReport;
  final List<String> newsHeadlines;

  const SeasonTransitionReport({
    required this.oldSeasonYear,
    required this.newSeasonYear,
    required this.awards,
    required this.promotionRelegation,
    required this.retiredRiders,
    required this.topProgressions,
    required this.executedTransfers,
    required this.newTalentsGeneratedCount,
    required this.playerTeamReport,
    required this.newsHeadlines,
  });

  Map<String, dynamic> toJson() => {
        'oldSeasonYear': oldSeasonYear,
        'newSeasonYear': newSeasonYear,
        'awards': awards.toJson(),
        'promotionRelegation': promotionRelegation.toJson(),
        'retiredRiders': retiredRiders.map((r) => r.toJson()).toList(),
        'topProgressions': topProgressions.map((p) => p.toJson()).toList(),
        'executedTransfers': executedTransfers.map((t) => t.toJson()).toList(),
        'newTalentsGeneratedCount': newTalentsGeneratedCount,
        'playerTeamReport': playerTeamReport.toJson(),
        'newsHeadlines': newsHeadlines,
      };
}

/// Rezultat wykonania operacji przejścia sezonu.
class SeasonTransitionResult {
  final CareerSave updatedSave;
  final SeasonTransitionReport report;

  const SeasonTransitionResult({
    required this.updatedSave,
    required this.report,
  });
}

/// Serwis obsługujący koniec sezonu (listopad/grudzień) i przejście do nowego roku.
///
/// Zakres obowiązków:
/// 1. Podsumowanie nagród i rankingu UCI (Kolarz Roku, Najlepszy Młodzieżowiec, Puchar Drużynowy, pule nagród).
/// 2. Awanse i spadki drużyn między dywizjami WorldTour i ProTeam na podstawie punktów sezonowych UCI.
/// 3. Emerytury kolarzy w wieku powyżej 35–38 lat z uwzględnieniem spadku formy i wygasających umów.
/// 4. Generowanie nowej fali 80 młodych talentów U19/U23 do puli skautingu i wolnych agentów.
/// 5. Rozwój statystyk młodych kolarzy (progresja FTP/VO2max) oraz naturalna regresja weteranów (33+).
/// 6. Realizacja podpisanych wcześniej transferów kontraktowych z dniem 1 stycznia nowego roku.
/// 7. Reset punktów UCI, regeneracja posezonowa kolarzy i wygenerowanie kalendarza wyścigów na nowy sezon.
class SeasonTransitionService {
  SeasonTransitionService._();

  /// Standardowa liczba nowo generowanych adeptów U19/U23 przy każdym przejściu sezonu
  static const int defaultNewTalentsWaveCount = 80;

  /// Sprawdza, czy gra kwalifikuje się do przejścia sezonu (listopad/grudzień lub ukończony kalendarz).
  static bool canPerformSeasonTransition(CareerSave save) {
    // Sezon kolarski kończy się po Il Lombardia i Tour of Guangxi (koniec października / listopad)
    final bool isLateSeasonMonth = save.currentDate.month >= 11 ||
        (save.currentDate.month == 10 && save.currentDate.day >= 25);
    final bool allRacesFinished = save.calendar.races.isNotEmpty &&
        save.calendar.completedRaceIds.length >= save.calendar.races.length;
    return isLateSeasonMonth || allRacesFinished;
  }

  /// Główna metoda przeprowadzająca pełne przejście sezonu i witająca nowy rok w świecie gry.
  static SeasonTransitionResult executeSeasonTransition(
    CareerSave save, {
    int newTalentsCount = defaultNewTalentsWaveCount,
    math.Random? random,
  }) {
    final rng = random ?? math.Random();
    final int oldSeasonYear = save.currentSeasonYear;
    final int newSeasonYear = oldSeasonYear + 1;

    final playerTeamBefore = save.playerTeam;
    final TeamDivision playerOldDivision = playerTeamBefore.division;

    // =========================================================================
    // KROK 1: PODSUMOWANIE NAGRÓD UCI I FINANSÓW
    // =========================================================================
    final uciAwards = _computeUciAwards(save);

    // =========================================================================
    // KROK 2: AWANSE I SPADKI DRUŻYN (WORLDTOUR <-> PROTEAM)
    // =========================================================================
    final promRelegResult = _computePromotionAndRelegation(
      teams: save.teams,
      playerTeamId: save.playerTeamId,
    );

    // =========================================================================
    // KROK 3: EMERYTURY KOLARZY (36-38+ LAT)
    // =========================================================================
    final retirementResult = _processRiderRetirements(
      riders: save.riders,
      currentYear: oldSeasonYear,
      random: rng,
    );

    // =========================================================================
    // KROK 4: ROZWÓJ STATYSTYK KOLARZY (PROGRESJA MŁODYCH / REGRESJA WETERANÓW)
    // =========================================================================
    final progressionResult = _processRiderProgressionAndRegression(
      riders: retirementResult.activeRiders,
      newSeasonYear: newSeasonYear,
      random: rng,
    );

    // =========================================================================
    // KROK 5: REALIZACJA PODPISANYCH WCZEŚNIEJ TRANSFERÓW
    // =========================================================================
    final transferResult = _executeSignedTransfers(
      currentRiders: progressionResult.updatedRiders,
      currentTeams: promRelegResult.updatedTeams,
      contractOffers: save.contractOffers,
      newSeasonYear: newSeasonYear,
      playerTeamId: save.playerTeamId,
    );

    // =========================================================================
    // KROK 6: GENEROWANIE NOWEJ FALI 80 MŁODYCH TALENTÓW U19/U23
    // =========================================================================
    final youthTalentsResult = _generateYouthTalentsWave(
      newSeasonYear: newSeasonYear,
      count: newTalentsCount,
      random: rng,
    );

    // =========================================================================
    // KROK 7: RESET POSEZONOWY KOLARZY (REGENERACJA, ZRESETOWANIE ZMĘCZENIA ATL)
    // =========================================================================
    final combinedRiders = [
      ...transferResult.updatedRiders,
      ...youthTalentsResult.newTalentRiders,
    ];

    final refreshedRiders = combinedRiders.map((rider) {
      final refreshedHealth = rider.health.copyWith(
        acuteTrainingLoad: 0.0, // Zmęczenie ostre zeruje się po przerwie zimowej
        chronicTrainingLoad: 42.0, // Baza treningowa tlenowa
        clearInjury: true, // Regeneracja drobnych urazów
        clearIllness: true,
      );

      final refreshedPhysiology = rider.physiology.copyWith(
        fatigue: 5.0,
        form: 65.0,
      );

      return rider.copyWith(
        health: refreshedHealth,
        physiology: refreshedPhysiology,
      );
    }).toList();

    // Reset punktów sezonowych UCI dla wszystkich drużyn na 0
    final resetTeamsForNewYear = transferResult.updatedTeams.map((team) {
      return team.copyWith(
        uciPointsSeason: 0,
      );
    }).toList();

    // =========================================================================
    // KROK 8: WYGENEROWANIE NOWEGO KALENDARZA NA KOLEJNY ROK
    // =========================================================================
    final newSeasonRaces = UciCalendarGenerator.generateFullSeasonCalendar(
      seasonYear: newSeasonYear,
    );

    final newSeasonCalendar = SeasonCalendar(
      seasonYear: newSeasonYear,
      races: newSeasonRaces,
      currentRaceIndex: 0,
      activeRaceId: null,
      activeStageIndex: 0,
      completedRaceIds: const [],
      raceHistory: save.calendar.raceHistory, // Zachowujemy kompletną historię wyścigów!
    );

    // Zaktualizuj pulę skautingu gracza o nowo wygenerowanych adeptów
    final updatedScoutingProspects = [
      ...youthTalentsResult.newScoutedProspects,
      ...save.scoutingProspects.where((p) => !p.isPromotedToProTeam),
    ];

    // Utwórz nowy stan zapisu gry z datą 1 stycznia nowego roku
    final newDate = DateTime(newSeasonYear, 1, 1);

    CareerSave updatedSave = save.copyWith(
      currentDate: newDate,
      currentSeasonYear: newSeasonYear,
      calendar: newSeasonCalendar,
      teams: resetTeamsForNewYear,
      riders: refreshedRiders,
      scoutingProspects: updatedScoutingProspects,
      contractOffers: const [], // Wyczyść zrealizowane oferty na nowy rok
      lastSavedAt: DateTime.now(),
    );

    // Wypłata nagrody finansowej UCI dla drużyny gracza (jeśli zdobyła premię)
    if (uciAwards.playerTeamPrizeEur > 0) {
      updatedSave = updatedSave.addFinanceTransaction(
        category: FinanceCategory.prizeMoney,
        amountEur: uciAwards.playerTeamPrizeEur,
        description:
            'Nagroda finansowa UCI za ${uciAwards.playerTeamRank}. miejsce w rankingu WorldTour ($oldSeasonYear)',
      );
    }

    // Aktualizacja reputacji menedżera za awans / spadek
    int managerRep = save.managerReputation;
    if (promRelegResult.summary.didPlayerTeamPromote) {
      managerRep = math.min(100, managerRep + 12);
    } else if (promRelegResult.summary.didPlayerTeamRelegate) {
      managerRep = math.max(1, managerRep - 10);
    }
    updatedSave = updatedSave.copyWith(managerReputation: managerRep);

    // =========================================================================
    // KROK 9: PRZYGOTOWANIE RAPORTU DLA GRACZA
    // =========================================================================
    final playerTeamAfter = updatedSave.playerTeam;

    final playerTeamReport = PlayerTeamSeasonReport(
      teamName: playerTeamAfter.name,
      oldDivision: playerOldDivision,
      newDivision: playerTeamAfter.division,
      wasPromoted: promRelegResult.summary.didPlayerTeamPromote,
      wasRelegated: promRelegResult.summary.didPlayerTeamRelegate,
      seasonUciPoints: playerTeamBefore.uciPointsSeason,
      seasonRank: uciAwards.playerTeamRank,
      uciPrizeMoneyEur: uciAwards.playerTeamPrizeEur,
      incomingTransfersCount: transferResult.incomingCountForPlayer,
      outgoingTransfersCount: transferResult.outgoingCountForPlayer,
      retiringRidersCount: retirementResult.playerRetirementsCount,
      progressingYouthCount: progressionResult.playerYouthProgressionsCount,
    );

    final headlines = _generateOffSeasonHeadlines(
      oldYear: oldSeasonYear,
      newYear: newSeasonYear,
      awards: uciAwards,
      promReleg: promRelegResult.summary,
      retirements: retirementResult.retiredReports,
      transfers: transferResult.executedReports,
      playerReport: playerTeamReport,
    );

    final finalReport = SeasonTransitionReport(
      oldSeasonYear: oldSeasonYear,
      newSeasonYear: newSeasonYear,
      awards: uciAwards,
      promotionRelegation: promRelegResult.summary,
      retiredRiders: retirementResult.retiredReports,
      topProgressions: progressionResult.topProgressionReports,
      executedTransfers: transferResult.executedReports,
      newTalentsGeneratedCount: youthTalentsResult.newTalentRiders.length,
      playerTeamReport: playerTeamReport,
      newsHeadlines: headlines,
    );

    return SeasonTransitionResult(
      updatedSave: updatedSave,
      report: finalReport,
    );
  }

  // ===========================================================================
  // MODUŁ 1: ROZLICZENIE NAGRÓD I RANKINGÓW UCI
  // ===========================================================================

  static UciAwardsSummary _computeUciAwards(CareerSave save) {
    // 1. Zwycięzca indywidualnego rankingu UCI (Rider of the Year)
    final sortedRiders = List<Rider>.from(save.riders)
      ..sort((a, b) => b.careerPointsUci.compareTo(a.careerPointsUci));

    UciRiderAward? riderOfTheYear;
    if (sortedRiders.isNotEmpty) {
      final best = sortedRiders.first;
      final bestTeam = save.getTeamById(best.contract.teamId);
      riderOfTheYear = UciRiderAward(
        riderId: best.id,
        riderName: best.fullName,
        teamName: bestTeam?.name ?? 'Klub Zawodowy',
        nationalityIso: best.nationalityIso,
        uciPoints: best.careerPointsUci,
        awardTitle: 'Złoty Rower UCI / Kolarz Roku',
        awardDescription:
            'Najbardziej wartościowy kolarz sezonu ${save.currentSeasonYear} wg rankingu światowego UCI.',
      );
    }

    // 2. Najlepszy młodzieżowiec U23 (Best Young Rider)
    UciRiderAward? bestYoungRider;
    final youngRiders = sortedRiders.where((r) => r.age <= 23).toList();
    if (youngRiders.isNotEmpty) {
      final bestY = youngRiders.first;
      final bestYTeam = save.getTeamById(bestY.contract.teamId);
      bestYoungRider = UciRiderAward(
        riderId: bestY.id,
        riderName: bestY.fullName,
        teamName: bestYTeam?.name ?? 'Klub Zawodowy',
        nationalityIso: bestY.nationalityIso,
        uciPoints: bestY.careerPointsUci,
        awardTitle: 'Biała Koszulka UCI / Najlepszy Młodzieżowiec U23',
        awardDescription:
            'Zwycięzca światowego rankingu młodzieżowego U23 w sezonie ${save.currentSeasonYear}.',
      );
    }

    // 3. Ranking drużyn WorldTour i ProTeam wg punktów zdobytych w sezonie
    final wtTeams = save.teams
        .where((t) => t.division == TeamDivision.worldTour)
        .toList()
      ..sort((a, b) => b.uciPointsSeason.compareTo(a.uciPointsSeason));

    final proTeams = save.teams
        .where((t) => t.division == TeamDivision.proTeam)
        .toList()
      ..sort((a, b) => b.uciPointsSeason.compareTo(a.uciPointsSeason));

    // Nagrody finansowe za miejsca w WorldTour
    final List<int> prizeScale = [
      3000000, // 1. miejsce: 3.0M EUR
      2000000, // 2. miejsce: 2.0M EUR
      1400000, // 3. miejsce: 1.4M EUR
      1000000, // 4. miejsce: 1.0M EUR
      800000,  // 5. miejsce: 800k EUR
      650000,  // 6. miejsce
      550000,  // 7. miejsce
      450000,  // 8. miejsce
      400000,  // 9. miejsce
      350000,  // 10. miejsce
      300000,  // 11. miejsce
      250000,  // 12. miejsce
      220000,  // 13. miejsce
      200000,  // 14. miejsce
      180000,  // 15. miejsce
      150000,  // 16. miejsce
      120000,  // 17. miejsce
      100000,  // 18. miejsce
    ];

    final List<UciTeamAward> wtRankings = [];
    int playerRank = 0;
    int playerPrize = 0;

    for (int i = 0; i < wtTeams.length; i++) {
      final team = wtTeams[i];
      final rank = i + 1;
      final prize = i < prizeScale.length ? prizeScale[i] : 50000;

      wtRankings.add(
        UciTeamAward(
          teamId: team.id,
          teamName: team.name,
          division: TeamDivision.worldTour,
          rank: rank,
          uciPoints: team.uciPointsSeason,
          prizeMoneyEur: prize,
        ),
      );

      if (team.id == save.playerTeamId) {
        playerRank = rank;
        playerPrize = prize;
      }
    }

    final List<UciTeamAward> proRankings = [];
    for (int i = 0; i < proTeams.length; i++) {
      final team = proTeams[i];
      final rank = i + 1;
      final prize = i == 0 ? 300000 : (i == 1 ? 200000 : 100000);

      proRankings.add(
        UciTeamAward(
          teamId: team.id,
          teamName: team.name,
          division: TeamDivision.proTeam,
          rank: rank,
          uciPoints: team.uciPointsSeason,
          prizeMoneyEur: prize,
        ),
      );

      if (team.id == save.playerTeamId) {
        playerRank = rank;
        playerPrize = prize;
      }
    }

    UciTeamAward? teamOfTheYear = wtRankings.isNotEmpty ? wtRankings.first : null;

    return UciAwardsSummary(
      riderOfTheYear: riderOfTheYear,
      bestYoungRiderU23: bestYoungRider,
      teamOfTheYear: teamOfTheYear,
      worldTourTeamRankings: wtRankings,
      proTeamRankings: proRankings,
      playerTeamRank: playerRank,
      playerTeamPrizeEur: playerPrize,
    );
  }

  // ===========================================================================
  // MODUŁ 2: AWANSE I SPADKI DRUŻYN (UCI PROMOTION & RELEGATION)
  // ===========================================================================

  static ({List<CyclingTeam> updatedTeams, PromotionRelegationSummary summary})
      _computePromotionAndRelegation({
    required List<CyclingTeam> teams,
    required String playerTeamId,
  }) {
    // Oddzielenie i posortowanie WorldTour oraz ProTeam według punktów sezonowych
    final wtTeams = teams
        .where((t) => t.division == TeamDivision.worldTour)
        .toList()
      ..sort((a, b) => b.uciPointsSeason.compareTo(a.uciPointsSeason));

    final proTeams = teams
        .where((t) => t.division == TeamDivision.proTeam)
        .toList()
      ..sort((a, b) => b.uciPointsSeason.compareTo(a.uciPointsSeason));

    final otherTeams = teams
        .where((t) =>
            t.division != TeamDivision.worldTour &&
            t.division != TeamDivision.proTeam)
        .toList();

    // Standard UCI: 2 najgorsze zespoły WorldTour spadają, 2 najlepsze ProTeams awansują
    final List<TeamRelegationEntry> relegatedEntries = [];
    final List<TeamPromotionEntry> promotedEntries = [];

    final Set<String> relegatedIds = {};
    final Set<String> promotedIds = {};

    // Spadki z WorldTour (2 ostatnie zespoły)
    if (wtTeams.length >= 2) {
      final team1 = wtTeams[wtTeams.length - 2];
      final team2 = wtTeams[wtTeams.length - 1];

      relegatedIds.add(team1.id);
      relegatedIds.add(team2.id);

      relegatedEntries.add(
        TeamRelegationEntry(
          teamId: team1.id,
          teamName: team1.name,
          seasonPoints: team1.uciPointsSeason,
          reason: 'Zajęcie ${wtTeams.length - 1}. miejsca w rankingu WorldTour',
        ),
      );
      relegatedEntries.add(
        TeamRelegationEntry(
          teamId: team2.id,
          teamName: team2.name,
          seasonPoints: team2.uciPointsSeason,
          reason: 'Ostatnie (${wtTeams.length}.) miejsce w rankingu WorldTour',
        ),
      );
    }

    // Awanse z ProTeam (2 czołowe zespoły)
    if (proTeams.length >= 2) {
      final pTeam1 = proTeams[0];
      final pTeam2 = proTeams[1];

      promotedIds.add(pTeam1.id);
      promotedIds.add(pTeam2.id);

      promotedEntries.add(
        TeamPromotionEntry(
          teamId: pTeam1.id,
          teamName: pTeam1.name,
          seasonPoints: pTeam1.uciPointsSeason,
          reason: '1. miejsce w klasyfikacji ProTeams i triumf w UCI Europe Tour',
        ),
      );
      promotedEntries.add(
        TeamPromotionEntry(
          teamId: pTeam2.id,
          teamName: pTeam2.name,
          seasonPoints: pTeam2.uciPointsSeason,
          reason: '2. miejsce w klasyfikacji ProTeams i wypełnienie wymogów licencyjnych UCI',
        ),
      );
    }

    // Zastosowanie zmian dywizji w modelach zespołów
    final List<CyclingTeam> updatedAllTeams = [];

    for (final t in wtTeams) {
      if (relegatedIds.contains(t.id)) {
        updatedAllTeams.add(t.copyWith(division: TeamDivision.proTeam));
      } else {
        updatedAllTeams.add(t);
      }
    }

    for (final t in proTeams) {
      if (promotedIds.contains(t.id)) {
        updatedAllTeams.add(t.copyWith(division: TeamDivision.worldTour));
      } else {
        updatedAllTeams.add(t);
      }
    }

    updatedAllTeams.addAll(otherTeams);

    final bool didPlayerPromote = promotedIds.contains(playerTeamId);
    final bool didPlayerRelegate = relegatedIds.contains(playerTeamId);

    final summary = PromotionRelegationSummary(
      promotedTeams: promotedEntries,
      relegatedTeams: relegatedEntries,
      didPlayerTeamPromote: didPlayerPromote,
      didPlayerTeamRelegate: didPlayerRelegate,
    );

    return (updatedTeams: updatedAllTeams, summary: summary);
  }

  // ===========================================================================
  // MODUŁ 3: EMERYTURY KOLARZY (RETIREMENTS)
  // ===========================================================================

  static ({
    List<Rider> activeRiders,
    List<RetiredRiderReport> retiredReports,
    int playerRetirementsCount,
  }) _processRiderRetirements({
    required List<Rider> riders,
    required int currentYear,
    required math.Random random,
  }) {
    final List<Rider> stillActiveRiders = [];
    final List<RetiredRiderReport> retiredList = [];
    int playerRetirements = 0;

    for (final rider in riders) {
      final int age = rider.age;

      if (age < 35) {
        // Młodsi kolarze nie przechodzą na rutynową emeryturę wiekową
        stillActiveRiders.add(rider);
        continue;
      }

      // Obliczenie prawdopodobieństwa emerytury w zależności od wieku (35–39+)
      double retirementChance;
      switch (age) {
        case 35:
          retirementChance = 0.15;
          break;
        case 36:
          retirementChance = 0.35;
          break;
        case 37:
          retirementChance = 0.60;
          break;
        case 38:
          retirementChance = 0.82;
          break;
        default:
          retirementChance = 0.98; // 39 lat i więcej – prawie pewny koniec kariery
      }

      // Modyfikatory: wygasający kontrakt i niska forma zwiększają chęć odwieszenia roweru
      if (rider.contract.isExpiring(currentYear)) {
        retirementChance += 0.20;
      }
      if (rider.overallRating < 72) {
        retirementChance += 0.15;
      }

      final roll = random.nextDouble();
      if (roll < retirementChance) {
        // Kolarz przechodzi na emeryturę!
        if (rider.contract.teamId.isNotEmpty) {
          playerRetirements++;
        }

        final quote = _generateFarewellQuote(rider, random);
        retiredList.add(
          RetiredRiderReport(
            riderId: rider.id,
            riderName: rider.fullName,
            age: age,
            nationalityIso: rider.nationalityIso,
            formerTeamName: rider.contract.teamId,
            careerPointsUci: rider.careerPointsUci,
            specialization: rider.specialization,
            farewellQuote: quote,
          ),
        );
      } else {
        // Kolarz postanawia powalczyć jeszcze przez kolejny sezon!
        stillActiveRiders.add(rider);
      }
    }

    // Sortuj emerytów według punktów kariery (największe legendy na czele)
    retiredList.sort((a, b) => b.careerPointsUci.compareTo(a.careerPointsUci));

    return (
      activeRiders: stillActiveRiders,
      retiredReports: retiredList,
      playerRetirementsCount: playerRetirements,
    );
  }

  static String _generateFarewellQuote(Rider rider, math.Random rng) {
    final quotes = [
      'To był niesamowity rozdział mojego życia. Czas oddać szosę młodszym i spędzić więcej czasu z rodziną.',
      'Po tylu kilometrach w peletonie i setkach etapów Grand Tourów, moje ciało zasłużyło na zasłużony odpoczynek.',
      'Dziękuję kibicom i drużynie za każdy ucieczkowy kilometr. Kolarstwo na zawsze pozostanie w moim sercu.',
      'Zawieszam rower na kołku z podniesioną głową. Osiągnąłem więcej, niż kiedykolwiek marzyłem.',
    ];
    return quotes[rng.nextInt(quotes.length)];
  }

  // ===========================================================================
  // MODUŁ 4: ROZWÓJ I REGRESJA STATYSTYK (PROGRESSION & REGRESSION)
  // ===========================================================================

  static ({
    List<Rider> updatedRiders,
    List<RiderProgressionReport> topProgressionReports,
    int playerYouthProgressionsCount,
  }) _processRiderProgressionAndRegression({
    required List<Rider> riders,
    required int newSeasonYear,
    required math.Random random,
  }) {
    final List<Rider> updatedList = [];
    final List<RiderProgressionReport> reports = [];
    int playerYouthCount = 0;

    for (final rider in riders) {
      final int age = newSeasonYear - rider.birthDate.year;
      final int oldOvr = rider.overallRating;
      final int oldFtp = rider.physiology.ftpWatts;

      Rider upgradedRider;

      if (age <= 24) {
        // --- 1. MŁODY TALENT (U19 - U24): SILNY ROZWÓJ PROGRESYWNY ---
        final int potentialGap = math.max(0, rider.potential - oldOvr);
        final double growthFactor = (potentialGap / 25.0).clamp(0.25, 1.4);

        // Przyrost mocy progowej FTP (+6W do +18W)
        final int ftpBoost = (5 + (growthFactor * 9) + random.nextInt(4)).round();
        final int newFtp = oldFtp + ftpBoost;

        // Skalowanie profilu mocy (watts20m, watts5m, watts1m) proporcjonalnie do FTP
        final double ftpRatio = newFtp / oldFtp;
        final newPowerProfile = rider.powerProfile.copyWith(
          watts60m: newFtp,
          watts20m: (rider.powerProfile.watts20m * ftpRatio).round(),
          watts5m: (rider.powerProfile.watts5m * ftpRatio).round(),
          watts1m: (rider.powerProfile.watts1m * (1.0 + (ftpRatio - 1.0) * 0.7)).round(),
        );

        // Poprawa VO2max i W'
        final double vo2Boost = (0.4 + (growthFactor * 0.9)).clamp(0.1, 2.5);
        final double newVo2 = math.min(88.0, rider.physiology.vo2Max + vo2Boost);
        final int wBoost = (250 + (growthFactor * 600)).round();

        final newPhysiology = rider.physiology.copyWith(
          ftpWatts: newFtp,
          vo2Max: newVo2,
          wPrimeJoules: rider.physiology.wPrimeJoules + wBoost,
        );

        // Rozwój umiejętności wyścigowych z wiekiem (Race IQ, Aero, Drafting)
        final newSkills = rider.skills.copyWith(
          timeTrialPositioning: math.min(99, rider.skills.timeTrialPositioning + 2),
          aeroPositioning: math.min(99, rider.skills.aeroPositioning + 2),
          draftingEfficiency: math.min(99, rider.skills.draftingEfficiency + 3),
          raceIq: math.min(99, rider.skills.raceIq + 3),
          bikeHandling: math.min(99, rider.skills.bikeHandling + 1),
        );

        upgradedRider = rider.copyWith(
          physiology: newPhysiology,
          powerProfile: newPowerProfile,
          skills: newSkills,
        );

        if (rider.contract.teamId.isNotEmpty) {
          playerYouthCount++;
        }
      } else if (age >= 25 && age <= 31) {
        // --- 2. PEŁNIA FORMY / PRIME (25 - 31 LAT): STABILIZACJA I DOŚWIADCZENIE ---
        // Doświadczenie taktyczne rośnie, drobne fluktuacje mocy
        final int ftpFluc = random.nextInt(5) - 2; // -2W do +2W
        final newFtp = math.max(250, oldFtp + ftpFluc);

        final newSkills = rider.skills.copyWith(
          raceIq: math.min(99, rider.skills.raceIq + 1),
          bikeHandling: math.min(99, rider.skills.bikeHandling + 1),
        );

        upgradedRider = rider.copyWith(
          physiology: rider.physiology.copyWith(ftpWatts: newFtp),
          powerProfile: rider.powerProfile.copyWith(watts60m: newFtp),
          skills: newSkills,
        );
      } else if (age >= 32 && age <= 34) {
        // --- 3. POCZĄTEK REGRESJI FIZJOLOGICZNEJ (32 - 34 LATA) ---
        // Delikatny spadek mocy zrywu sprinterskiego (watts5s), utrzymanie bazy tlenowej
        final new5s = (rider.powerProfile.watts5s * 0.98).round();
        final int ftpDrop = random.nextInt(4); // 0W do -3W
        final newFtp = oldFtp - ftpDrop;

        upgradedRider = rider.copyWith(
          physiology: rider.physiology.copyWith(ftpWatts: newFtp),
          powerProfile: rider.powerProfile.copyWith(
            watts5s: new5s,
            watts60m: newFtp,
          ),
          skills: rider.skills.copyWith(
            raceIq: math.min(99, rider.skills.raceIq + 1),
          ),
        );
      } else {
        // --- 4. WETERAN (35+ LAT): WYRAŹNY SPADEK WYDOLNOŚCI TLENOWEJ ---
        final int ftpDrop = (6 + random.nextInt(8)).round(); // -6W do -13W
        final newFtp = math.max(220, oldFtp - ftpDrop);

        final double vo2Drop = 0.8 + (random.nextDouble() * 1.0);
        final double newVo2 = math.max(50.0, rider.physiology.vo2Max - vo2Drop);

        final new5s = (rider.powerProfile.watts5s * 0.95).round();

        upgradedRider = rider.copyWith(
          physiology: rider.physiology.copyWith(
            ftpWatts: newFtp,
            vo2Max: newVo2,
            wPrimeJoules: math.max(10000, rider.physiology.wPrimeJoules - 800),
          ),
          powerProfile: rider.powerProfile.copyWith(
            watts5s: new5s,
            watts60m: newFtp,
          ),
        );
      }

      updatedList.add(upgradedRider);

      final int newOvr = upgradedRider.overallRating;
      final int ovrDelta = newOvr - oldOvr;
      final int ftpDelta = upgradedRider.physiology.ftpWatts - oldFtp;

      if (ovrDelta.abs() >= 1 || ftpDelta.abs() >= 5) {
        reports.add(
          RiderProgressionReport(
            riderId: upgradedRider.id,
            riderName: upgradedRider.fullName,
            age: age,
            teamName: upgradedRider.contract.teamId,
            oldOvr: oldOvr,
            newOvr: newOvr,
            ovrDelta: ovrDelta,
            oldFtp: oldFtp,
            newFtp: upgradedRider.physiology.ftpWatts,
            ftpDelta: ftpDelta,
            isYouth: age <= 24,
          ),
        );
      }
    }

    // Sortuj największe talenty (największy przyrost ratingu na czele)
    reports.sort((a, b) => b.ovrDelta.compareTo(a.ovrDelta));

    return (
      updatedRiders: updatedList,
      topProgressionReports: reports,
      playerYouthProgressionsCount: playerYouthCount,
    );
  }

  // ===========================================================================
  // MODUŁ 5: REALIZACJA PODPISANYCH TRANSFERÓW (TRANSFERS EXECUTION)
  // ===========================================================================

  static ({
    List<Rider> updatedRiders,
    List<CyclingTeam> updatedTeams,
    List<ExecutedTransferReport> executedReports,
    int incomingCountForPlayer,
    int outgoingCountForPlayer,
  }) _executeSignedTransfers({
    required List<Rider> currentRiders,
    required List<CyclingTeam> currentTeams,
    required List<CareerContractOffer> contractOffers,
    required int newSeasonYear,
    required String playerTeamId,
  }) {
    // 1. Zbieramy wszystkie oferty o statusie 'accepted'
    final acceptedOffers = contractOffers
        .where((o) => o.status == ContractOfferStatus.accepted)
        .toList();

    final Map<String, CareerContractOffer> riderToOfferMap = {};
    for (final offer in acceptedOffers) {
      riderToOfferMap[offer.riderId] = offer;
    }

    final List<ExecutedTransferReport> reports = [];
    int incomingPlayer = 0;
    int outgoingPlayer = 0;

    final Map<String, List<String>> teamRostersMap = {};
    for (final t in currentTeams) {
      teamRostersMap[t.id] = List<String>.from(t.rosterRiderIds);
    }

    final List<Rider> updatedRiders = [];

    for (final rider in currentRiders) {
      final offer = riderToOfferMap[rider.id];

      if (offer != null) {
        // --- REALIZACJA FORMALNEGO TRANSFERU ---
        final String oldTeamId = rider.contract.teamId;
        final String newTeamId = offer.offeringTeamId;

        // Usuń ze starego zespołu
        if (oldTeamId.isNotEmpty && teamRostersMap.containsKey(oldTeamId)) {
          teamRostersMap[oldTeamId]!.remove(rider.id);
        }

        // Dodaj do nowego zespołu
        if (teamRostersMap.containsKey(newTeamId)) {
          if (!teamRostersMap[newTeamId]!.contains(rider.id)) {
            teamRostersMap[newTeamId]!.add(rider.id);
          }
        }

        // Nowy kontrakt kolarza od 1 stycznia
        final int monthlySalary = (offer.annualSalaryEur / 12.0).round();
        final int endYear = newSeasonYear + offer.contractDurationYears;

        final updatedContract = rider.contract.copyWith(
          teamId: newTeamId,
          role: offer.proposedRole,
          monthlySalaryEur: monthlySalary,
          contractEndYear: endYear,
          winBonusEur: offer.winBonusEur,
          morale: 0.98,
        );

        final transferredRider = rider.copyWith(contract: updatedContract);
        updatedRiders.add(transferredRider);

        final bool isPlayerInvolved =
            oldTeamId == playerTeamId || newTeamId == playerTeamId;
        if (newTeamId == playerTeamId) incomingPlayer++;
        if (oldTeamId == playerTeamId) outgoingPlayer++;

        reports.add(
          ExecutedTransferReport(
            riderId: rider.id,
            riderName: rider.fullName,
            fromTeamId: oldTeamId,
            fromTeamName: offer.offeringTeamId == oldTeamId ? 'Dotychczasowy klub' : oldTeamId,
            toTeamId: newTeamId,
            toTeamName: offer.offeringTeamName,
            annualSalaryEur: offer.annualSalaryEur,
            role: offer.proposedRole,
            isPlayerTeamInvolved: isPlayerInvolved,
          ),
        );
      } else {
        // Brak formalnego transferu – sprawdź czy wygasł kontrakt
        if (rider.contract.isExpiring(newSeasonYear - 1)) {
          // Jeśli kolarz nie podpisał nowej umowy, zostaje wolnym agentem lub przedłuża o rok w AI
          final String teamId = rider.contract.teamId;
          if (teamId == playerTeamId) {
            // Wygasły kontrakt w drużynie gracza bez przedłużenia -> Wolny Agent
            if (teamRostersMap.containsKey(playerTeamId)) {
              teamRostersMap[playerTeamId]!.remove(rider.id);
            }
            outgoingPlayer++;
            updatedRiders.add(
              rider.copyWith(
                contract: rider.contract.copyWith(teamId: ''),
              ),
            );
          } else {
            // W zespołach AI – automatyczne przedłużenie o 1 rok dla wartościowych kolarzy
            if (rider.overallRating >= 72) {
              updatedRiders.add(
                rider.copyWith(
                  contract: rider.contract.copyWith(
                    contractEndYear: newSeasonYear + 1,
                  ),
                ),
              );
            } else {
              // Słaby kolarz staje się wolnym agentem
              if (teamRostersMap.containsKey(teamId)) {
                teamRostersMap[teamId]!.remove(rider.id);
              }
              updatedRiders.add(
                rider.copyWith(
                  contract: rider.contract.copyWith(teamId: ''),
                ),
              );
            }
          }
        } else {
          // Kontrakt wciąż obowiązuje
          updatedRiders.add(rider);
        }
      }
    }

    // Aktualizacja składów w obiektach CyclingTeam
    final List<CyclingTeam> updatedTeams = currentTeams.map((team) {
      final roster = teamRostersMap[team.id] ?? team.rosterRiderIds;
      return team.copyWith(
        rosterRiderIds: List<String>.unmodifiable(roster),
      );
    }).toList();

    return (
      updatedRiders: updatedRiders,
      updatedTeams: updatedTeams,
      executedReports: reports,
      incomingCountForPlayer: incomingPlayer,
      outgoingCountForPlayer: outgoingPlayer,
    );
  }

  // ===========================================================================
  // MODUŁ 6: GENEROWANIE NOWEJ FALI 80 MŁODYCH TALENTÓW U19/U23
  // ===========================================================================

  static ({
    List<Rider> newTalentRiders,
    List<ScoutedProspect> newScoutedProspects,
  }) _generateYouthTalentsWave({
    required int newSeasonYear,
    required int count,
    required math.Random random,
  }) {
    final List<Rider> riders = [];
    final List<ScoutedProspect> prospects = [];

    const sources = ScoutingSource.values;

    for (int i = 0; i < count; i++) {
      // Rozkład tierów talentu (5% geniusz, 25% WorldTour, 45% Solid Pro, 25% Continental)
      ScoutingTier tier;
      final roll = random.nextDouble();
      if (roll < 0.05) {
        tier = ScoutingTier.generationalTalent;
      } else if (roll < 0.30) {
        tier = ScoutingTier.worldTourProspect;
      } else if (roll < 0.75) {
        tier = ScoutingTier.solidPro;
      } else {
        tier = ScoutingTier.continentalHopeful;
      }

      final int targetAge = 17 + random.nextInt(5);
      final talentRaw = RiderProceduralGenerator.generateNeoProTalent(
        currentSeasonYear: DateTime.now().year,
        tier: tier,
        random: random,
      );
      final talent = talentRaw.copyWith(
        birthDate: DateTime(DateTime.now().year - targetAge, 1, 15),
      );

      riders.add(talent);

      final source = sources[i % sources.length];
      final prospect = ScoutedProspect(
        id: 'prospect_${newSeasonYear}_${talent.id}',
        firstName: talent.firstName,
        lastName: talent.lastName,
        nationalityIso: talent.nationalityIso,
        age: targetAge,
        source: source,
        discoveryStage: ScoutingDiscoveryStage.rawTalent,
        estimatedMinFtpWatts: talent.physiology.ftpWatts - 30,
        estimatedMaxFtpWatts: talent.physiology.ftpWatts + 30,
        estimatedMinVo2Max: (talent.physiology.vo2Max - 5.0).clamp(45.0, 95.0),
        estimatedMaxVo2Max: (talent.physiology.vo2Max + 5.0).clamp(50.0, 99.0),
        estimatedMinPotential: math.max(50, talent.potential - 8),
        estimatedMaxPotential: math.min(100, talent.potential + 8),
        probableSpecialization: talent.specialization,
        scoutReport:
            'Obserwowany młody adept (${source.label}). Wykazuje predyspozycje do rozwoju w peletonie zawodowym.',
        trueRider: talent,
      );

      prospects.add(prospect);
    }

    return (newTalentRiders: riders, newScoutedProspects: prospects);
  }

  // ===========================================================================
  // MODUŁ 7: GENEROWANIE WIADOMOŚCI PRASOWYCH PODSUMOWUJĄCYCH ZIMĘ
  // ===========================================================================

  static List<String> _generateOffSeasonHeadlines({
    required int oldYear,
    required int newYear,
    required UciAwardsSummary awards,
    required PromotionRelegationSummary promReleg,
    required List<RetiredRiderReport> retirements,
    required List<ExecutedTransferReport> transfers,
    required PlayerTeamSeasonReport playerReport,
  }) {
    final List<String> news = [];

    // 1. Zwycięzcy UCI
    if (awards.riderOfTheYear != null) {
      news.add(
        '🏆 Złoty Rower UCI $oldYear: ${awards.riderOfTheYear!.riderName} (${awards.riderOfTheYear!.teamName}) '
        'oficjalnie uznany najlepszym kolarzem świata z dorobkiem ${awards.riderOfTheYear!.uciPoints} pkt!',
      );
    }

    if (awards.bestYoungRiderU23 != null) {
      news.add(
        '🤍 Biała Koszulka UCI U23: ${awards.bestYoungRiderU23!.riderName} (${awards.bestYoungRiderU23!.teamName}) '
        'triumfatorem klasyfikacji młodzieżowej!',
      );
    }

    // 2. Awanse i spadki
    if (promReleg.promotedTeams.isNotEmpty) {
      final names = promReleg.promotedTeams.map((t) => t.teamName).join(', ');
      news.add('🚀 Awanse do UCI WorldTour: W nowym sezonie $newYear w elicie zadebiutują: $names!');
    }

    if (promReleg.relegatedTeams.isNotEmpty) {
      final names = promReleg.relegatedTeams.map((t) => t.teamName).join(', ');
      news.add('⚠️ Spadek do UCI ProTeam: Niezwykle bolesna degradacja dla: $names.');
    }

    // 3. Pozycja drużyny gracza
    if (playerReport.wasPromoted) {
      news.add(
        '🎉 WIELKI SUKCES! Twoja drużyna ${playerReport.teamName} oficjalnie awansowała do UCI WorldTour!',
      );
    } else if (playerReport.wasRelegated) {
      news.add(
        '⚠️ GORYCZ PORAŻKI: Drużyna ${playerReport.teamName} spadła z WorldTour do dywizji ProTeam.',
      );
    }

    // 4. Emerytury
    if (retirements.isNotEmpty) {
      final legends = retirements.take(3).map((r) => '${r.riderName} (${r.age} l.)').join(', ');
      news.add('👋 Koniec pewnej epoki. Rower na kołku zawieszają m.in.: $legends.');
    }

    // 5. Młode talenty
    news.add(
      '🌟 Przyszłość kolarstwa: Do międzynarodowej bazy skautingu trafiła fala 80 utalentowanych adeptów U19/U23!',
    );

    // 6. Transfery
    if (transfers.isNotEmpty) {
      final topTransfer = transfers.first;
      news.add(
        '💼 Bomba transferowa: ${topTransfer.riderName} oficjalnie zakłada koszulkę ${topTransfer.toTeamName}!',
      );
    }

    return news;
  }
}
