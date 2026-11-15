import 'dart:math' as math;
import '../../models/career/career_save.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/team/cycling_team.dart';

/// Wynik oceny oferty kontraktowej przez agenta kolarza.
class AgentNegotiationResult {
  /// Decyzja agenta: zaakceptowana, kontroferta lub odrzucona
  final ContractOfferStatus status;

  /// Ogólna ocena oferty w skali 0.0 - 100.0 punktów
  final double overallScore;

  /// Realistyczna wypowiedź agenta podsumowująca stanowisko kolarza
  final String agentQuote;

  /// Szczegółowe uzasadnienie odrzucenia (jeśli status == rejected)
  final String? rejectionReason;

  /// Proponowana przez agenta pensja w kontrofercie [EUR/rok]
  final int? counterOfferAnnualSalaryEur;

  /// Proponowana przez agenta rola w zespole w kontrofercie
  final RiderRole? counterOfferRole;

  /// Proponowana przez agenta długość kontraktu w latach
  final int? counterOfferDurationYears;

  // Cząstkowe składowe oceny oferty (do wglądu w UI negocjacji)
  final double salaryScore; // Waga 35%
  final double roleScore; // Waga 25%
  final double prestigeScore; // Waga 20%
  final double equipmentScore; // Waga 10%
  final double leaderConflictScore; // Waga 10%

  /// Czy wykryto blokadę pozycji lidera przez innego kolarza w zespole
  final bool hasLeaderConflict;

  /// Nazwisko kolarza blokującego status lidera (jeśli istnieje)
  final String? conflictingLeaderName;

  const AgentNegotiationResult({
    required this.status,
    required this.overallScore,
    required this.agentQuote,
    this.rejectionReason,
    this.counterOfferAnnualSalaryEur,
    this.counterOfferRole,
    this.counterOfferDurationYears,
    required this.salaryScore,
    required this.roleScore,
    required this.prestigeScore,
    required this.equipmentScore,
    required this.leaderConflictScore,
    this.hasLeaderConflict = false,
    this.conflictingLeaderName,
  });

  bool get isAccepted => status == ContractOfferStatus.accepted;
  bool get isCounterOffer => status == ContractOfferStatus.counterOffer;
  bool get isRejected => status == ContractOfferStatus.rejected;

  Map<String, dynamic> toJson() {
    return {
      'status': status.toJson(),
      'overallScore': overallScore,
      'agentQuote': agentQuote,
      'rejectionReason': rejectionReason,
      'counterOfferAnnualSalaryEur': counterOfferAnnualSalaryEur,
      'counterOfferRole': counterOfferRole?.toJson(),
      'counterOfferDurationYears': counterOfferDurationYears,
      'salaryScore': salaryScore,
      'roleScore': roleScore,
      'prestigeScore': prestigeScore,
      'equipmentScore': equipmentScore,
      'leaderConflictScore': leaderConflictScore,
      'hasLeaderConflict': hasLeaderConflict,
      'conflictingLeaderName': conflictingLeaderName,
    };
  }

  factory AgentNegotiationResult.fromJson(Map<String, dynamic> json) {
    return AgentNegotiationResult(
      status: ContractOfferStatus.fromJson(json['status'] as String),
      overallScore: (json['overallScore'] as num).toDouble(),
      agentQuote: json['agentQuote'] as String,
      rejectionReason: json['rejectionReason'] as String?,
      counterOfferAnnualSalaryEur:
          (json['counterOfferAnnualSalaryEur'] as num?)?.toInt(),
      counterOfferRole: json['counterOfferRole'] != null
          ? RiderRole.fromJson(json['counterOfferRole'] as String)
          : null,
      counterOfferDurationYears:
          (json['counterOfferDurationYears'] as num?)?.toInt(),
      salaryScore: (json['salaryScore'] as num).toDouble(),
      roleScore: (json['roleScore'] as num).toDouble(),
      prestigeScore: (json['prestigeScore'] as num).toDouble(),
      equipmentScore: (json['equipmentScore'] as num).toDouble(),
      leaderConflictScore: (json['leaderConflictScore'] as num).toDouble(),
      hasLeaderConflict: json['hasLeaderConflict'] as bool? ?? false,
      conflictingLeaderName: json['conflictingLeaderName'] as String?,
    );
  }

  @override
  String toString() =>
      'AgentNegotiationResult(${status.name}, score: ${overallScore.toStringAsFixed(1)}/100, "$agentQuote")';
}

/// Serwis zarządzający logiką rynku transferowego i negocjacjami kontraktowymi w trybie kariery.
///
/// Zgodnie z oficjalnymi regulacjami UCI, okno transferowe na kolejny sezon otwiera się 1 sierpnia.
/// Kolarz wraz ze swoim agentem ocenia każdą ofertę w oparciu o 5 kluczowych filarów:
/// 1. Pensja roczna i bonusy w odniesieniu do wartości rynkowej (35%).
/// 2. Proponowana rola w zespole (`TeamLeader` vs `Domestique`) względem ambicji kolarza (25%).
/// 3. Prestiż drużyny i dywizja UCI (WorldTour vs ProTeam vs Continental) (20%).
/// 4. Jakość rowerów i osprzętu w bazie sprzętowej zespołu (10%).
/// 5. Konflikt liderów – czy w drużynie jest już gwiazda blokująca start w wymarzonym Grand Tourze (10%).
class TransferMarketService {
  TransferMarketService._();

  /// Miesiąc otwarcia oficjalnego okna transferowego UCI (1 sierpnia)
  static const int transferWindowOpenMonth = 8;
  static const int transferWindowOpenDay = 1;

  /// Miesiąc zamknięcia rejestracji kontraktów na nowy sezon (31 grudnia)
  static const int transferWindowCloseMonth = 12;
  static const int transferWindowCloseDay = 31;

  /// Sprawdza, czy w danej dacie kalendarzowej okno transferowe jest oficjalnie otwarte
  static bool isTransferWindowOpen(DateTime currentDate) {
    if (currentDate.month < transferWindowOpenMonth) return false;
    if (currentDate.month == transferWindowOpenMonth &&
        currentDate.day < transferWindowOpenDay) {
      return false;
    }
    return true;
  }

  /// Zwraca liczbę dni pozostałych do otwarcia okna transferowego (1 sierpnia)
  static int daysUntilTransferWindowOpens(DateTime currentDate) {
    if (isTransferWindowOpen(currentDate)) return 0;
    final openDate = DateTime(currentDate.year, transferWindowOpenMonth, transferWindowOpenDay);
    return openDate.difference(currentDate).inDays;
  }

  /// Filtruje listę kolarzy, których kontrakty wygasają z końcem bieżącego sezonu (Free Agents)
  static List<Rider> getExpiringContractRiders({
    required List<Rider> allRiders,
    required int currentSeasonYear,
  }) {
    return allRiders.where((rider) {
      return rider.contract.isExpiring(currentSeasonYear);
    }).toList();
  }

  /// Wylicza realistyczną roczną wartość rynkową kolarza w Euro [EUR/rok]
  /// na podstawie profilu mocy, wieku, potencjału, specjalizacji i punktów UCI.
  static int calculateMarketValue(Rider rider) {
    final double weightKg = rider.physiology.weightKg > 0 ? rider.physiology.weightKg : 70.0;
    final double cp = rider.physiology.criticalPowerWatts.toDouble();
    final double wKg = cp / weightKg;
    final int uciPoints = rider.careerPointsUci;
    final int potential = rider.potential;

    // 1. Bazowa płaca minimalna WorldTour (regulamin UCI: ~45 000 EUR/rok)
    double baseSalary = 48000.0;

    // 2. Mnożnik za bezwzględną klasę sportową (W/kg oraz moc progowa CP)
    if (rider.specialization == RiderSpecialization.gcClimber ||
        rider.specialization == RiderSpecialization.pureClimber) {
      if (wKg >= 6.2) {
        baseSalary += 2500000.0; // Klasa Vingegaard / Pogačar
      } else if (wKg >= 5.8) {
        baseSalary += 1200000.0; // Top 10 Grand Tourów
      } else if (wKg >= 5.4) {
        baseSalary += 500000.0; // Solidny góral / etapowiec
      } else if (wKg >= 5.0) {
        baseSalary += 180000.0;
      }
    } else if (rider.specialization == RiderSpecialization.pureSprinter ||
        rider.specialization == RiderSpecialization.versatileSprinter) {
      final sprintWatts = rider.powerProfile.p5sWatts;
      if (sprintWatts >= 1650) {
        baseSalary += 1800000.0; // Światowy top sprinter
      } else if (sprintWatts >= 1500) {
        baseSalary += 850000.0;
      } else if (sprintWatts >= 1350) {
        baseSalary += 320000.0;
      }
    } else {
      // Klasykowcy, czasowcy, uciekinierzy
      if (cp >= 430 || wKg >= 5.6) {
        baseSalary += 1100000.0;
      } else if (cp >= 390 || wKg >= 5.2) {
        baseSalary += 420000.0;
      } else {
        baseSalary += 120000.0;
      }
    }

    // 3. Dodatek za zdobyte punkty UCI w sezonie (sukcesy w kalendarzu)
    baseSalary += (uciPoints * 250.0);

    // 4. Modyfikator wieku kolarza
    final int age = rider.age;
    if (age <= 22) {
      // Młody talent – premia za wysoki potencjał
      final potentialBonus = (potential - 60).clamp(0, 40) * 15000.0;
      baseSalary += potentialBonus;
    } else if (age >= 25 && age <= 31) {
      // Złoty wiek kolarza (szczyt fizjologiczny)
      baseSalary *= 1.15;
    } else if (age >= 34) {
      // Weteran – stopniowy spadek wymagań płacowych
      baseSalary *= math.max(0.45, 1.0 - (age - 33) * 0.12);
    }

    // Płaca nie może być niższa od obecnego kontraktu o więcej niż 30%, chyba że kolarz ma >35 lat
    final int currentSalary = rider.contract.annualSalaryEur;
    if (currentSalary > 0 && age < 35) {
      baseSalary = math.max(baseSalary, currentSalary * 0.85);
    }

    // Zaokrąglenie do pełnych tysięcy Euro
    return (baseSalary / 1000.0).round() * 1000;
  }

  /// Ocenia jakość parku maszynowego drużyny (0.0 - 100.0 punktów).
  ///
  /// Analizuje masę roweru, współczynnik aerodynamiczny CdA, osprzęt elektroniczny i opory toczenia opon.
  static double evaluateTeamBikeQuality(CyclingTeam team) {
    if (team.teamBikes.isEmpty) {
      // Domyślna ocena zależna od dywizji, jeśli brak konkretnego roweru w liście
      switch (team.division) {
        case TeamDivision.worldTour:
          return 85.0;
        case TeamDivision.proTeam:
          return 70.0;
        case TeamDivision.continental:
          return 50.0;
      }
    }

    // Bierzemy flagowy rower szosowy drużyny
    final bike = team.teamBikes.first;
    double score = 50.0;

    // 1. Masa roweru (zbliżenie do limitu UCI 6.80 kg)
    final double weightKg = bike.totalWeightKg;
    if (weightKg <= 6.85) {
      score += 20.0; // Perfekcyjna waga UCI
    } else if (weightKg <= 7.10) {
      score += 15.0;
    } else if (weightKg <= 7.50) {
      score += 8.0;
    } else {
      score -= 5.0; // Za ciężki rower
    }

    // 2. Aerodynamika (modyfikator CdA)
    final double cdaMod = bike.totalCdaModifier;
    if (cdaMod <= -0.012) {
      score += 15.0; // Wybitna aerodynamika ramy i kół
    } else if (cdaMod <= -0.006) {
      score += 10.0;
    } else if (cdaMod <= 0.0) {
      score += 5.0;
    }

    // 3. Grupa osprzętu
    if (bike.groupset.isElectronic) {
      score += 10.0;
      if (bike.groupset.speedCount >= 12) score += 5.0;
    }

    return score.clamp(10.0, 100.0);
  }

  /// Sprawdza, czy w drużynie jest już inny lider blokujący nowemu kolarzowi
  /// start w wymarzonym Grand Tourze jako niekwestionowany kapitan.
  static ({bool hasConflict, String? conflictingLeaderName, double penalty}) checkGrandTourLeaderConflict({
    required Rider candidateRider,
    required CyclingTeam offeringTeam,
    required List<Rider> teamRoster,
    required RiderRole proposedRole,
  }) {
    // Konflikt dotyczy tylko kolarzy o wysokich ambicjach (GC lub czołowi sprinterzy)
    final bool isGcContender = candidateRider.specialization == RiderSpecialization.gcClimber ||
        candidateRider.specialization == RiderSpecialization.pureClimber;
    final bool isTopSprinter = candidateRider.specialization == RiderSpecialization.pureSprinter;

    if (!isGcContender && !isTopSprinter) {
      return (hasConflict: false, conflictingLeaderName: null, penalty: 0.0);
    }

    // Jeśli kolarzowi proponuje się rolę pomocnika, konflikt nie dotyczy pierwszeństwa w GC,
    // ale ambicjonalnego odrzucenia roli (obsługiwane w filarze 2).
    if (proposedRole == RiderRole.domestique || proposedRole == RiderRole.superDomestique) {
      return (hasConflict: false, conflictingLeaderName: null, penalty: 0.0);
    }

    // Szukamy w kadrze istniejących liderów o tej samej specjalizacji
    for (final teammate in teamRoster) {
      if (teammate.id == candidateRider.id) continue;

      final bool teammateIsLeader = teammate.contract.role == RiderRole.teamLeader;
      final bool teammateSameSpec = (isGcContender &&
              (teammate.specialization == RiderSpecialization.gcClimber ||
                  teammate.specialization == RiderSpecialization.pureClimber)) ||
          (isTopSprinter && teammate.specialization == RiderSpecialization.pureSprinter);

      if (teammateIsLeader && teammateSameSpec) {
        // Porównujemy klasę sportową: jeśli istniejący lider ma porównywalny lub wyższy poziom
        final double teammateCp = teammate.physiology.criticalPowerWatts.toDouble();
        final double candidateCp = candidateRider.physiology.criticalPowerWatts.toDouble();

        if (teammateCp >= candidateCp * 0.95 || teammate.careerPointsUci >= candidateRider.careerPointsUci) {
          return (
            hasConflict: true,
            conflictingLeaderName: '${teammate.firstName} ${teammate.lastName}',
            penalty: 25.0, // Ciężka kara punktowa w negocjacjach
          );
        }
      }
    }

    return (hasConflict: false, conflictingLeaderName: null, penalty: 0.0);
  }

  /// Główna metoda oceny oferty kontraktowej przez agenta kolarza.
  ///
  /// Zwraca szczegółowy wynik negocjacji ([AgentNegotiationResult]) wraz z punktacją cząstkową.
  static AgentNegotiationResult evaluateOffer({
    required Rider candidateRider,
    required CyclingTeam offeringTeam,
    required List<Rider> teamRoster,
    required int annualSalaryEur,
    required RiderRole proposedRole,
    required int contractDurationYears,
    required int winBonusEur,
    DateTime? currentDate,
  }) {
    // 0. Sprawdzenie okna transferowego (jeśli podano datę)
    if (currentDate != null && !isTransferWindowOpen(currentDate)) {
      return const AgentNegotiationResult(
        status: ContractOfferStatus.rejected,
        overallScore: 0.0,
        agentQuote: 'Oficjalne okno transferowe UCI otwiera się dopiero 1 sierpnia. Nie możemy teraz złożyć podpisu pod umową na kolejny sezon.',
        rejectionReason: 'Okno transferowe jest zamknięte (otwarcie 1 sierpnia).',
        salaryScore: 0.0,
        roleScore: 0.0,
        prestigeScore: 0.0,
        equipmentScore: 0.0,
        leaderConflictScore: 0.0,
      );
    }

    final int expectedMarketSalary = calculateMarketValue(candidateRider);

    // =========================================================================
    // FILAR 1: WYNAGRODZENIE I BONUSY (Waga 35%)
    // =========================================================================
    double salaryScore;
    final double salaryRatio = annualSalaryEur / expectedMarketSalary.toDouble();

    if (salaryRatio >= 1.30) {
      salaryScore = 35.0; // Wybitna oferta ponad rynek
    } else if (salaryRatio >= 1.05) {
      salaryScore = 28.0 + (salaryRatio - 1.05) * 28.0;
    } else if (salaryRatio >= 0.85) {
      salaryScore = 18.0 + (salaryRatio - 0.85) * 50.0;
    } else if (salaryRatio >= 0.65) {
      salaryScore = 6.0 + (salaryRatio - 0.65) * 60.0;
    } else {
      salaryScore = math.max(0.0, salaryRatio * 8.0); // Zdecydowanie poniżej oczekiwań
    }

    // =========================================================================
    // FILAR 2: PROPONOWANA ROLA W ZESPOLE (Waga 25%)
    // =========================================================================
    double roleScore = 15.0;
    final bool isStarRider = candidateRider.potential >= 78 ||
        candidateRider.careerPointsUci >= 800 ||
        (candidateRider.physiology.criticalPowerWatts / candidateRider.physiology.weightKg) >= 5.7;

    switch (proposedRole) {
      case RiderRole.teamLeader:
        roleScore = 25.0; // Maksymalna satysfakcja z pozycji lidera
        break;
      case RiderRole.coLeader:
        roleScore = isStarRider ? 18.0 : 23.0;
        break;
      case RiderRole.superDomestique:
        roleScore = isStarRider ? 6.0 : 20.0;
        break;
      case RiderRole.sprinter:
        roleScore = (candidateRider.specialization == RiderSpecialization.pureSprinter ||
                candidateRider.specialization == RiderSpecialization.versatileSprinter)
            ? 25.0
            : 10.0;
        break;
      case RiderRole.breakawaySpecialist:
        roleScore = 16.0;
        break;
      case RiderRole.domestique:
      case RiderRole.neoPro:
        roleScore = isStarRider ? 0.0 : 18.0; // Gwiazda nigdy nie zaakceptuje roli zwykłego pomocnika!
        break;
    }

    // =========================================================================
    // FILAR 3: PRESTIŻ DRUŻYNY I DYWIZJA UCI (Waga 20%)
    // =========================================================================
    double prestigeScore;
    switch (offeringTeam.division) {
      case TeamDivision.worldTour:
        prestigeScore = 20.0; // Gwarantowany start w Grand Tourach i Monumentach
        break;
      case TeamDivision.proTeam:
        prestigeScore = isStarRider ? 8.0 : 16.0; // Gwiazdy wolą WorldTour
        break;
      case TeamDivision.continental:
        prestigeScore = candidateRider.age <= 21 ? 14.0 : 3.0; // Dobre tylko dla juniorów
        break;
    }

    // =========================================================================
    // FILAR 4: JAKOŚĆ ROWERÓW I OSPRZĘTU (Waga 10%)
    // =========================================================================
    final double bikeQuality0to100 = evaluateTeamBikeQuality(offeringTeam);
    final double equipmentScore = (bikeQuality0to100 / 100.0) * 10.0;

    // =========================================================================
    // FILAR 5: KONFLIKT LIDERÓW W GRAND TOURACH (Waga 10%)
    // =========================================================================
    final conflictCheck = checkGrandTourLeaderConflict(
      candidateRider: candidateRider,
      offeringTeam: offeringTeam,
      teamRoster: teamRoster,
      proposedRole: proposedRole,
    );

    double leaderConflictScore = 10.0;
    if (conflictCheck.hasConflict) {
      leaderConflictScore = math.max(0.0, 10.0 - conflictCheck.penalty);
    } else {
      // Bonus za 'czystą kartę' (brak konkurenta na Grand Toury)
      leaderConflictScore = 10.0;
    }

    // =========================================================================
    // ŁĄCZNY WYNIK PUNKTOWY I DECYZJA AGENTA
    // =========================================================================
    final double totalScore = (salaryScore +
            roleScore +
            prestigeScore +
            equipmentScore +
            leaderConflictScore)
        .clamp(0.0, 100.0);

    // Kolarz gwiazda zaoferowany jako pomocnik natychmiast odrzuca ofertę
    if (isStarRider && (proposedRole == RiderRole.domestique || proposedRole == RiderRole.neoPro)) {
      return AgentNegotiationResult(
        status: ContractOfferStatus.rejected,
        overallScore: totalScore,
        agentQuote: 'Mój klient jest kolarzem formatu mistrzowskiego. Oferowanie mu roli zwykłego pomocnika odbieramy jako brak szacunku dla jego dotychczasowej kariery.',
        rejectionReason: 'Zaoferowano rolę pomocnika kolarzowi o statusie lidera.',
        salaryScore: salaryScore,
        roleScore: roleScore,
        prestigeScore: prestigeScore,
        equipmentScore: equipmentScore,
        leaderConflictScore: leaderConflictScore,
        hasLeaderConflict: conflictCheck.hasConflict,
        conflictingLeaderName: conflictCheck.conflictingLeaderName,
      );
    }

    // Jeśli występuje poważny konflikt liderów, a kolarz ma wysokie ambicje
    if (conflictCheck.hasConflict && isStarRider && proposedRole == RiderRole.teamLeader) {
      final leaderName = conflictCheck.conflictingLeaderName ?? 'inny lider';
      if (totalScore < 70.0) {
        return AgentNegotiationResult(
          status: ContractOfferStatus.rejected,
          overallScore: totalScore,
          agentQuote: 'W waszej ekipie niekwestionowanym numerem 1 na Tour de France jest już $leaderName. Mój klient nie zamierza toczyć bratobójczej wojny o pozycję kapitana.',
          rejectionReason: 'Blokada pozycji lidera na Grand Toury przez $leaderName.',
          salaryScore: salaryScore,
          roleScore: roleScore,
          prestigeScore: prestigeScore,
          equipmentScore: equipmentScore,
          leaderConflictScore: leaderConflictScore,
          hasLeaderConflict: true,
          conflictingLeaderName: conflictCheck.conflictingLeaderName,
        );
      }
    }

    // Decyzja na podstawie sumarycznego wyniku punktowego
    if (totalScore >= 72.0) {
      // 1. ZAAKCEPTOWANA
      return AgentNegotiationResult(
        status: ContractOfferStatus.accepted,
        overallScore: totalScore,
        agentQuote: 'Warunki kontraktu są bardzo satysfakcjonujące. Mój klient z dumą założy barwy ${offeringTeam.name} w nowym sezonie!',
        salaryScore: salaryScore,
        roleScore: roleScore,
        prestigeScore: prestigeScore,
        equipmentScore: equipmentScore,
        leaderConflictScore: leaderConflictScore,
        hasLeaderConflict: conflictCheck.hasConflict,
        conflictingLeaderName: conflictCheck.conflictingLeaderName,
      );
    } else if (totalScore >= 48.0) {
      // 2. KONTROFERTA AGENTA
      final int counterSalary = (expectedMarketSalary * 1.10 / 1000.0).round() * 1000;
      final RiderRole counterRole = (isStarRider && proposedRole != RiderRole.teamLeader)
          ? RiderRole.teamLeader
          : proposedRole;

      String quote = 'Jesteśmy otwarci na przejście do waszego zespołu, jednak obecna oferta wymaga korekty.';
      if (salaryRatio < 0.95) {
        quote += ' Oczekujemy rocznej pensji na poziomie €${(counterSalary / 1000).round()}k.';
      }
      if (isStarRider && proposedRole != RiderRole.teamLeader) {
        quote += ' Klient domaga się gwarancji statusu Lidera Zespołu.';
      }

      return AgentNegotiationResult(
        status: ContractOfferStatus.counterOffer,
        overallScore: totalScore,
        agentQuote: quote,
        counterOfferAnnualSalaryEur: counterSalary,
        counterOfferRole: counterRole,
        counterOfferDurationYears: math.max(2, contractDurationYears),
        salaryScore: salaryScore,
        roleScore: roleScore,
        prestigeScore: prestigeScore,
        equipmentScore: equipmentScore,
        leaderConflictScore: leaderConflictScore,
        hasLeaderConflict: conflictCheck.hasConflict,
        conflictingLeaderName: conflictCheck.conflictingLeaderName,
      );
    } else {
      // 3. ODRZUCONA
      String reason = 'Niewystarczające warunki finansowe lub sportowe.';
      String quote = 'Niestety, musimy odrzucić waszą propozycję.';

      if (salaryRatio < 0.75) {
        reason = 'Pensja drastycznie poniżej wartości rynkowej kolarza.';
        quote = 'Proponowane zarobki znacznie odbiegają od aktualnej pozycji rynkowej mojego klienta.';
      } else if (offeringTeam.division == TeamDivision.continental && isStarRider) {
        reason = 'Zbyt niska dywizja zespołu (brak startów w WorldTour).';
        quote = 'Mój klient nie zamierza schodzić na poziom Continental na tym etapie kariery.';
      } else if (bikeQuality0to100 < 50.0) {
        reason = 'Niezadowalający poziom sprzętu rowerowego zespołu.';
        quote = 'Mój zawodnik potrzebuje bezkompromisowego sprzętu aero i wagi na limicie UCI, aby wygrywać wyścigi.';
      }

      return AgentNegotiationResult(
        status: ContractOfferStatus.rejected,
        overallScore: totalScore,
        agentQuote: quote,
        rejectionReason: reason,
        salaryScore: salaryScore,
        roleScore: roleScore,
        prestigeScore: prestigeScore,
        equipmentScore: equipmentScore,
        leaderConflictScore: leaderConflictScore,
        hasLeaderConflict: conflictCheck.hasConflict,
        conflictingLeaderName: conflictCheck.conflictingLeaderName,
      );
    }
  }

  /// Przetwarza złożenie oficjalnej oferty przez gracza lub zespół,
  /// ocenia ją przez agenta i zwraca zaktualizowany stan zapisu kariery ([CareerSave]).
  static ({CareerSave updatedSave, AgentNegotiationResult negotiationResult}) submitContractOffer({
    required CareerSave currentSave,
    required String riderId,
    required String offeringTeamId,
    required int annualSalaryEur,
    required int contractDurationYears,
    required RiderRole proposedRole,
    int winBonusEur = 15000,
  }) {
    final rider = currentSave.getRiderById(riderId);
    final offeringTeam = currentSave.getTeamById(offeringTeamId);

    if (rider == null || offeringTeam == null) {
      throw ArgumentError('Nie znaleziono kolarza lub drużyny w bazie zapisu.');
    }

    final teamRoster = currentSave.riders.where((r) => r.contract.teamId == offeringTeamId).toList();

    // Ocena oferty przez agenta
    final negotiation = evaluateOffer(
      candidateRider: rider,
      offeringTeam: offeringTeam,
      teamRoster: teamRoster,
      annualSalaryEur: annualSalaryEur,
      proposedRole: proposedRole,
      contractDurationYears: contractDurationYears,
      winBonusEur: winBonusEur,
      currentDate: currentSave.currentDate,
    );

    final offerId = 'off_${DateTime.now().millisecondsSinceEpoch}_${rider.id}';
    final newOffer = CareerContractOffer(
      offerId: offerId,
      riderId: rider.id,
      riderName: rider.fullName,
      offeringTeamId: offeringTeam.id,
      offeringTeamName: offeringTeam.name,
      annualSalaryEur: annualSalaryEur,
      contractDurationYears: contractDurationYears,
      winBonusEur: winBonusEur,
      proposedRole: proposedRole,
      status: negotiation.status,
      offeredDate: currentSave.currentDate,
      rejectionReason: negotiation.rejectionReason,
    );

    CareerSave updatedSave = currentSave.copyWith(
      contractOffers: [newOffer, ...currentSave.contractOffers],
    );

    // Jeśli oferta została natychmiast zaakceptowana, finalizujemy transfer na kolejny sezon!
    if (negotiation.isAccepted) {
      updatedSave = executeAcceptedTransfer(
        currentSave: updatedSave,
        offer: newOffer,
      );
    }

    return (updatedSave: updatedSave, negotiationResult: negotiation);
  }

  /// Finalizuje transfer po zaakceptowaniu oferty kontraktowej (podpisanie umowy na nowy sezon).
  static CareerSave executeAcceptedTransfer({
    required CareerSave currentSave,
    required CareerContractOffer offer,
  }) {
    final rider = currentSave.getRiderById(offer.riderId);
    final newTeam = currentSave.getTeamById(offer.offeringTeamId);

    if (rider == null || newTeam == null) return currentSave;

    final int newEndYear = currentSave.currentSeasonYear + offer.contractDurationYears;
    final int monthlySalary = (offer.annualSalaryEur / 12.0).round();

    // Nowy kontrakt kolarza
    final updatedContract = rider.contract.copyWith(
      teamId: newTeam.id,
      role: offer.proposedRole,
      monthlySalaryEur: monthlySalary,
      contractEndYear: newEndYear,
      winBonusEur: offer.winBonusEur,
      morale: 0.95, // Wysokie morale po podpisaniu dobrego kontraktu
    );

    final updatedRider = rider.copyWith(contract: updatedContract);

    // Aktualizacja składów obu drużyn (starej i nowej)
    final updatedTeams = currentSave.teams.map((t) {
      if (t.id == rider.contract.teamId && t.id != newTeam.id) {
        // Usuwamy ze starej drużyny
        final updatedRoster = t.rosterRiderIds.where((id) => id != rider.id).toList();
        return t.copyWith(rosterRiderIds: updatedRoster);
      } else if (t.id == newTeam.id) {
        // Dodajemy do nowej drużyny
        if (!t.rosterRiderIds.contains(rider.id)) {
          final updatedRoster = [...t.rosterRiderIds, rider.id];
          return t.copyWith(rosterRiderIds: updatedRoster);
        }
      }
      return t;
    }).toList();

    // Aktualizacja kolarza w bazie
    final updatedRiders = currentSave.riders.map((r) {
      return r.id == rider.id ? updatedRider : r;
    }).toList();

    return currentSave.copyWith(
      riders: updatedRiders,
      teams: updatedTeams,
      lastSavedAt: DateTime.now(),
    );
  }

  /// Symuluje autonomiczne ruchy transferowe AI pomiędzy drużynami WorldTour i ProTeam.
  ///
  /// Dzięki temu świat nie stoi w miejscu – inne zespoły aktywnie kontraktują kolarzy
  /// z wygasającymi umowami, budując składy na kolejny rok.
  static CareerSave simulateAiTransferMarket({
    required CareerSave currentSave,
    int maxAiTransfersPerWeek = 4,
    math.Random? random,
  }) {
    // Rynek transferowy działa tylko od 1 sierpnia
    if (!isTransferWindowOpen(currentSave.currentDate)) {
      return currentSave;
    }

    final rng = random ?? math.Random();
    final expiringRiders = getExpiringContractRiders(
      allRiders: currentSave.riders,
      currentSeasonYear: currentSave.currentSeasonYear,
    );

    if (expiringRiders.isEmpty) return currentSave;

    CareerSave state = currentSave;
    int transfersDone = 0;

    // Przetasowanie kolarzy
    final shuffledRiders = List<Rider>.from(expiringRiders)..shuffle(rng);

    for (final rider in shuffledRiders) {
      if (transfersDone >= maxAiTransfersPerWeek) break;

      // Kolarz gracza nie może być podkradziony bez formalnej oferty (chronimy drużynę gracza przed cichym transferem)
      if (rider.contract.teamId == currentSave.playerTeamId) continue;

      // Wybieramy losową drużynę AI zainteresowaną transferem
      final aiTeams = currentSave.teams
          .where((t) => t.id != currentSave.playerTeamId && t.id != rider.contract.teamId)
          .toList();

      if (aiTeams.isEmpty) continue;
      final targetTeam = aiTeams[rng.nextInt(aiTeams.length)];

      // Sprawdzamy, czy zespół AI stać na kolarza
      final marketSalary = calculateMarketValue(rider);
      if (targetTeam.cashBalanceEur < marketSalary * 1.2) continue;

      final role = (rider.potential >= 78) ? RiderRole.teamLeader : RiderRole.domestique;

      final teamRoster = state.riders.where((r) => r.contract.teamId == targetTeam.id).toList();

      final eval = evaluateOffer(
        candidateRider: rider,
        offeringTeam: targetTeam,
        teamRoster: teamRoster,
        annualSalaryEur: marketSalary,
        proposedRole: role,
        contractDurationYears: 2,
        winBonusEur: 10000,
      );

      if (eval.isAccepted) {
        final offer = CareerContractOffer(
          offerId: 'ai_tr_${DateTime.now().millisecondsSinceEpoch}_${rider.id}',
          riderId: rider.id,
          riderName: rider.fullName,
          offeringTeamId: targetTeam.id,
          offeringTeamName: targetTeam.name,
          annualSalaryEur: marketSalary,
          contractDurationYears: 2,
          winBonusEur: 10000,
          proposedRole: role,
          status: ContractOfferStatus.accepted,
          offeredDate: currentSave.currentDate,
        );

        state = executeAcceptedTransfer(currentSave: state, offer: offer);
        transfersDone++;
      }
    }

    return state;
  }
}

