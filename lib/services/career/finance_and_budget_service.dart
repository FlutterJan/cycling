import '../../models/career/career_save.dart';
import '../../models/race/tour_race.dart';
import '../../models/rider/lactate_and_lab_profile.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';

/// Zestawienie miesięcznego przepływu gotówki (Cashflow Report)
class MonthlyCashflowReport {
  final DateTime period;
  final int sponsorPayoutEur;
  final int bikeManufacturerCashEur;
  final int prizeMoneyClubShareEur;
  final int prizeMoneyRidersShareEur;
  final int riderBuyoutIncomeEur;
  final int otherIncomeEur;
  final int totalIncomeEur;

  final int riderSalariesEur;
  final int staffSalariesEur;
  final int raceLogisticsEur;
  final int trainingCampsEur;
  final int physiologicalTestingEur;
  final int equipmentServiceAndPurchasesEur;
  final int facilitiesMaintenanceEur;
  final int totalExpensesEur;

  final int netCashflowEur;
  final int startingBalanceEur;
  final int endingBalanceEur;
  final double runwayMonths;
  final int financialHealthScore; // 1 - 100
  final List<String> recommendations;

  const MonthlyCashflowReport({
    required this.period,
    required this.sponsorPayoutEur,
    required this.bikeManufacturerCashEur,
    required this.prizeMoneyClubShareEur,
    required this.prizeMoneyRidersShareEur,
    required this.riderBuyoutIncomeEur,
    required this.otherIncomeEur,
    required this.totalIncomeEur,
    required this.riderSalariesEur,
    required this.staffSalariesEur,
    required this.raceLogisticsEur,
    required this.trainingCampsEur,
    required this.physiologicalTestingEur,
    required this.equipmentServiceAndPurchasesEur,
    required this.facilitiesMaintenanceEur,
    required this.totalExpensesEur,
    required this.netCashflowEur,
    required this.startingBalanceEur,
    required this.endingBalanceEur,
    required this.runwayMonths,
    required this.financialHealthScore,
    required this.recommendations,
  });

  bool get isProfitable => netCashflowEur >= 0;
  bool get isCritical => runwayMonths < 2.0 && netCashflowEur < 0;

  MonthlyCashflowReport copyWith({
    DateTime? period,
    int? sponsorPayoutEur,
    int? bikeManufacturerCashEur,
    int? prizeMoneyClubShareEur,
    int? prizeMoneyRidersShareEur,
    int? riderBuyoutIncomeEur,
    int? otherIncomeEur,
    int? totalIncomeEur,
    int? riderSalariesEur,
    int? staffSalariesEur,
    int? raceLogisticsEur,
    int? trainingCampsEur,
    int? physiologicalTestingEur,
    int? equipmentServiceAndPurchasesEur,
    int? facilitiesMaintenanceEur,
    int? totalExpensesEur,
    int? netCashflowEur,
    int? startingBalanceEur,
    int? endingBalanceEur,
    double? runwayMonths,
    int? financialHealthScore,
    List<String>? recommendations,
  }) {
    return MonthlyCashflowReport(
      period: period ?? this.period,
      sponsorPayoutEur: sponsorPayoutEur ?? this.sponsorPayoutEur,
      bikeManufacturerCashEur:
          bikeManufacturerCashEur ?? this.bikeManufacturerCashEur,
      prizeMoneyClubShareEur:
          prizeMoneyClubShareEur ?? this.prizeMoneyClubShareEur,
      prizeMoneyRidersShareEur:
          prizeMoneyRidersShareEur ?? this.prizeMoneyRidersShareEur,
      riderBuyoutIncomeEur: riderBuyoutIncomeEur ?? this.riderBuyoutIncomeEur,
      otherIncomeEur: otherIncomeEur ?? this.otherIncomeEur,
      totalIncomeEur: totalIncomeEur ?? this.totalIncomeEur,
      riderSalariesEur: riderSalariesEur ?? this.riderSalariesEur,
      staffSalariesEur: staffSalariesEur ?? this.staffSalariesEur,
      raceLogisticsEur: raceLogisticsEur ?? this.raceLogisticsEur,
      trainingCampsEur: trainingCampsEur ?? this.trainingCampsEur,
      physiologicalTestingEur:
          physiologicalTestingEur ?? this.physiologicalTestingEur,
      equipmentServiceAndPurchasesEur: equipmentServiceAndPurchasesEur ??
          this.equipmentServiceAndPurchasesEur,
      facilitiesMaintenanceEur:
          facilitiesMaintenanceEur ?? this.facilitiesMaintenanceEur,
      totalExpensesEur: totalExpensesEur ?? this.totalExpensesEur,
      netCashflowEur: netCashflowEur ?? this.netCashflowEur,
      startingBalanceEur: startingBalanceEur ?? this.startingBalanceEur,
      endingBalanceEur: endingBalanceEur ?? this.endingBalanceEur,
      runwayMonths: runwayMonths ?? this.runwayMonths,
      financialHealthScore: financialHealthScore ?? this.financialHealthScore,
      recommendations: recommendations != null
          ? List.unmodifiable(recommendations)
          : this.recommendations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period.toIso8601String(),
      'sponsorPayoutEur': sponsorPayoutEur,
      'bikeManufacturerCashEur': bikeManufacturerCashEur,
      'prizeMoneyClubShareEur': prizeMoneyClubShareEur,
      'prizeMoneyRidersShareEur': prizeMoneyRidersShareEur,
      'riderBuyoutIncomeEur': riderBuyoutIncomeEur,
      'otherIncomeEur': otherIncomeEur,
      'totalIncomeEur': totalIncomeEur,
      'riderSalariesEur': riderSalariesEur,
      'staffSalariesEur': staffSalariesEur,
      'raceLogisticsEur': raceLogisticsEur,
      'trainingCampsEur': trainingCampsEur,
      'physiologicalTestingEur': physiologicalTestingEur,
      'equipmentServiceAndPurchasesEur': equipmentServiceAndPurchasesEur,
      'facilitiesMaintenanceEur': facilitiesMaintenanceEur,
      'totalExpensesEur': totalExpensesEur,
      'netCashflowEur': netCashflowEur,
      'startingBalanceEur': startingBalanceEur,
      'endingBalanceEur': endingBalanceEur,
      'runwayMonths': runwayMonths,
      'financialHealthScore': financialHealthScore,
      'recommendations': recommendations,
    };
  }

  factory MonthlyCashflowReport.fromJson(Map<String, dynamic> json) {
    return MonthlyCashflowReport(
      period: DateTime.parse(json['period'] as String),
      sponsorPayoutEur: (json['sponsorPayoutEur'] as num).toInt(),
      bikeManufacturerCashEur: (json['bikeManufacturerCashEur'] as num).toInt(),
      prizeMoneyClubShareEur: (json['prizeMoneyClubShareEur'] as num).toInt(),
      prizeMoneyRidersShareEur:
          (json['prizeMoneyRidersShareEur'] as num).toInt(),
      riderBuyoutIncomeEur: (json['riderBuyoutIncomeEur'] as num).toInt(),
      otherIncomeEur: (json['otherIncomeEur'] as num).toInt(),
      totalIncomeEur: (json['totalIncomeEur'] as num).toInt(),
      riderSalariesEur: (json['riderSalariesEur'] as num).toInt(),
      staffSalariesEur: (json['staffSalariesEur'] as num).toInt(),
      raceLogisticsEur: (json['raceLogisticsEur'] as num).toInt(),
      trainingCampsEur: (json['trainingCampsEur'] as num).toInt(),
      physiologicalTestingEur:
          (json['physiologicalTestingEur'] as num).toInt(),
      equipmentServiceAndPurchasesEur:
          (json['equipmentServiceAndPurchasesEur'] as num).toInt(),
      facilitiesMaintenanceEur:
          (json['facilitiesMaintenanceEur'] as num).toInt(),
      totalExpensesEur: (json['totalExpensesEur'] as num).toInt(),
      netCashflowEur: (json['netCashflowEur'] as num).toInt(),
      startingBalanceEur: (json['startingBalanceEur'] as num).toInt(),
      endingBalanceEur: (json['endingBalanceEur'] as num).toInt(),
      runwayMonths: (json['runwayMonths'] as num).toDouble(),
      financialHealthScore: (json['financialHealthScore'] as num).toInt(),
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MonthlyCashflowReport &&
        other.period == period &&
        other.netCashflowEur == netCashflowEur;
  }

  @override
  int get hashCode => Object.hash(period, netCashflowEur);
}

/// Polityka podziału nagród z wyścigów (Prize Money Split Policy)
class PrizeMoneySplitPolicy {
  final int riderSharePercent; // np. 70% dla kolarzy
  final int clubSharePercent; // np. 30% dla klubu

  const PrizeMoneySplitPolicy({
    this.riderSharePercent = 70,
    this.clubSharePercent = 30,
  });

  /// Wpływ wybranej polityki na morale kolarzy (-0.08 do +0.08)
  double get moraleModifier {
    if (riderSharePercent >= 80) return 0.06;
    if (riderSharePercent >= 70) return 0.02;
    if (riderSharePercent >= 60) return -0.02;
    return -0.06; // <60% wywołuje frustrację w peletonie
  }

  String get label => '$riderSharePercent% Kolarze / $clubSharePercent% Klub';

  PrizeMoneySplitPolicy copyWith({
    int? riderSharePercent,
    int? clubSharePercent,
  }) {
    return PrizeMoneySplitPolicy(
      riderSharePercent: riderSharePercent ?? this.riderSharePercent,
      clubSharePercent: clubSharePercent ?? this.clubSharePercent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderSharePercent': riderSharePercent,
      'clubSharePercent': clubSharePercent,
    };
  }

  factory PrizeMoneySplitPolicy.fromJson(Map<String, dynamic> json) {
    return PrizeMoneySplitPolicy(
      riderSharePercent: (json['riderSharePercent'] as num?)?.toInt() ?? 70,
      clubSharePercent: (json['clubSharePercent'] as num?)?.toInt() ?? 30,
    );
  }
}

/// Rodzaje profesjonalnych badań laboratoryjnych dla kolarzy
enum PhysiologicalTestType {
  /// Test ergospirometryczny (VO2max, progi wentylacyjne VT1/VT2, moc PPO)
  ergospirometryVO2Max,

  /// Próba stopniowana ze stężeniem kwasu mlekowego we krwi (krzywa mleczanowa, wyznaczenie LT1 i LT2/OBLA)
  lactateThresholdCurve,

  /// Kompleksowy audyt laboratoryjny: ergospirometria + mleczan + skan DXA składu ciała + morfologia krwi
  fullPhysiologicalAudit,

  /// Kompleksowy przegląd całej kadry (screening przedsezonowy / przed Grand Tourem)
  teamFleetScreening;

  String toJson() => name;

  static PhysiologicalTestType fromJson(String value) {
    return PhysiologicalTestType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PhysiologicalTestType.ergospirometryVO2Max,
    );
  }

  String get label {
    switch (this) {
      case PhysiologicalTestType.ergospirometryVO2Max:
        return 'Ergospirometria (VO2max & VT1/VT2)';
      case PhysiologicalTestType.lactateThresholdCurve:
        return 'Krzywa mleczanowa (Kwas mlekowy & Kalibracja FTP)';
      case PhysiologicalTestType.fullPhysiologicalAudit:
        return 'Kompleksowy Audyt Wydolnościowy (VO2max + Mleczan + DXA)';
      case PhysiologicalTestType.teamFleetScreening:
        return 'Przegląd Laboratoryjny Całego Zespołu (Fleet Screening)';
    }
  }

  int get costPerRiderEur {
    switch (this) {
      case PhysiologicalTestType.ergospirometryVO2Max:
        return 450;
      case PhysiologicalTestType.lactateThresholdCurve:
        return 350;
      case PhysiologicalTestType.fullPhysiologicalAudit:
        return 950;
      case PhysiologicalTestType.teamFleetScreening:
        return 14000; // Koszt pakietowy dla całej drużyny
    }
  }

  String get description {
    switch (this) {
      case PhysiologicalTestType.ergospirometryVO2Max:
        return 'Pomiar wymiany gazowej w masce. Wyznacza bezbłędny pułap tlenowy VO2max i progi wentylacyjne do stref tlenowych.';
      case PhysiologicalTestType.lactateThresholdCurve:
        return 'Pobór mikrogli z opuszka palca/ucha co stopień obciążenia. Wyznacza próg mleczanowy (4.0 mmol) i precyzyjne FTP do 1 Wata.';
      case PhysiologicalTestType.fullPhysiologicalAudit:
        return 'Złoty standard diagnostyki ProTour: ergospirometria, kinetyka mleczanu, gęstość kości i masa mięśniowa DXA oraz panel krwi.';
      case PhysiologicalTestType.teamFleetScreening:
        return 'Dedykowana sesja w uniwersyteckiej klinice medycyny sportowej dla wszystkich kolarzy kadry. Wykrywa ukryte przetrenowanie.';
    }
  }
}

/// Wynik badania wydolnościowego kolarza
class PhysiologicalTestResult {
  final String riderId;
  final String riderName;
  final PhysiologicalTestType testType;
  final DateTime testDate;
  final double measuredFtpWatts;
  final double measuredVo2Max;
  final int measuredMaxHeartRate;
  final double lactateThresholdWatts;
  final double fatigueIndexPercent; // 0 - 100%
  final bool isOvertrained;
  final String summary;
  final String recommendation;
  final LactateAndLabProfile? labProfile;

  const PhysiologicalTestResult({
    required this.riderId,
    required this.riderName,
    required this.testType,
    required this.testDate,
    required this.measuredFtpWatts,
    required this.measuredVo2Max,
    required this.measuredMaxHeartRate,
    required this.lactateThresholdWatts,
    required this.fatigueIndexPercent,
    required this.isOvertrained,
    required this.summary,
    required this.recommendation,
    this.labProfile,
  });

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'testType': testType.toJson(),
      'testDate': testDate.toIso8601String(),
      'measuredFtpWatts': measuredFtpWatts,
      'measuredVo2Max': measuredVo2Max,
      'measuredMaxHeartRate': measuredMaxHeartRate,
      'lactateThresholdWatts': lactateThresholdWatts,
      'fatigueIndexPercent': fatigueIndexPercent,
      'isOvertrained': isOvertrained,
      'summary': summary,
      'recommendation': recommendation,
      'labProfile': labProfile?.toJson(),
    };
  }

  factory PhysiologicalTestResult.fromJson(Map<String, dynamic> json) {
    return PhysiologicalTestResult(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      testType: PhysiologicalTestType.fromJson(json['testType'] as String),
      testDate: DateTime.parse(json['testDate'] as String),
      measuredFtpWatts: (json['measuredFtpWatts'] as num).toDouble(),
      measuredVo2Max: (json['measuredVo2Max'] as num).toDouble(),
      measuredMaxHeartRate: (json['measuredMaxHeartRate'] as num).toInt(),
      lactateThresholdWatts: (json['lactateThresholdWatts'] as num).toDouble(),
      fatigueIndexPercent: (json['fatigueIndexPercent'] as num).toDouble(),
      isOvertrained: json['isOvertrained'] as bool,
      summary: json['summary'] as String,
      recommendation: json['recommendation'] as String,
      labProfile: json['labProfile'] != null
          ? LactateAndLabProfile.fromJson(json['labProfile'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Pakiet materiałów eksploatacyjnych i serwisu sprzętu
class EquipmentConsumablePackage {
  final String id;
  final String name;
  final int costEur;
  final String description;
  final String benefitDescription;

  const EquipmentConsumablePackage({
    required this.id,
    required this.name,
    required this.costEur,
    required this.description,
    required this.benefitDescription,
  });
}

/// Serwis zarządzania finansami, budżetem i przepływem gotówki drużyny kolarskiej.
///
/// Odpowiada za:
/// 1. Śledzenie miesięcznego Cashflow (przychody sponsorskie, producenci, pensje, logistyka).
/// 2. Obsługę nagród z wyścigów (Prize Money) z podziałem procentowym dla kolarzy i klubu.
/// 3. Sprzedaż zawodników poprzez wykup klauzul kontraktowych (Release Clause).
/// 4. Zlecanie profesjonalnych badań laboratoryjnych (ergospirometria, mleczan, VO2max).
/// 5. Bieżące zakupy eksploatacyjne floty rowerowej oraz obsługę logistyczną.
class FinanceAndBudgetService {
  FinanceAndBudgetService._();

  // ===========================================================================
  // KALKULATORY PENSJI I PRZYCHODÓW
  // ===========================================================================

  /// Oblicza łączną miesięczną sumę pensji kolarzy w kadrze
  static int calculateRiderMonthlySalaries(List<Rider> roster) {
    int sum = 0;
    for (final rider in roster) {
      sum += rider.contract.monthlySalaryEur;
    }
    return sum;
  }

  /// Oblicza łączną miesięczną sumę wynagrodzeń sztabu szkoleniowego i medycznego
  static int calculateStaffMonthlySalaries(TeamStaff staff) {
    final trainersSalary = (staff.trainersLevel / 100.0 * 9000 + 3000).round();
    final dsSalary = (staff.sportsDirectorsLevel / 100.0 * 12000 + 4000).round();
    final docsSalary = (staff.doctorsLevel / 100.0 * 14000 + 5000).round();
    final mechSalary = (staff.mechanicsLevel / 100.0 * 6000 + 2500).round();
    final scoutsSalary = (staff.scoutsLevel / 100.0 * 5000 + 2000).round();

    return trainersSalary + dsSalary + docsSalary + mechSalary + scoutsSalary;
  }

  /// Oblicza miesięczny przychód sponsorski drużyny (sponsorzy + producent rowerów)
  static int calculateMonthlySponsorIncome(CyclingTeam team) {
    int annualTotal = team.bikeDeal.annualCashContributionEur;
    for (final sponsor in team.sponsors) {
      annualTotal += sponsor.annualBudgetEur;
    }
    return (annualTotal / 12.0).round();
  }

  /// Oblicza stałe miesięczne koszty utrzymania floty logistycznej (autokar klubowy, wozy techniczne, serwis łączności)
  static int calculateMonthlyFleetMaintenance(CyclingTeam team) {
    switch (team.division) {
      case TeamDivision.worldTour:
        return 14500; // Autokar luksusowy + 4 wozy serwisowe + mobilna kuchnia
      case TeamDivision.proTeam:
        return 8200; // Autokar standard + 2 wozy techniczne
      case TeamDivision.continental:
        return 3400; // Bus klubowy + 1 wóz serwisowy
    }
  }

  /// Oblicza szacowane koszty podróży, hoteli i logistyki wyścigowej dla wyścigów w danym miesiącu
  static int calculateRaceTravelLogistics(CareerSave save, int month) {
    final monthRaces = save.calendar.races.where((r) {
      return r.startMonth == month &&
          r.participatingTeamIds.contains(save.playerTeamId);
    }).toList();

    int totalTravel = 0;
    for (final race in monthRaces) {
      if (race.isGrandTour) {
        totalTravel += 42000; // 3 tygodnie, przeloty, hotele, catering
      } else if (race.uciCategory == RaceCategory.monument) {
        totalTravel += 8500;
      } else if (race.uciCategory == RaceCategory.worldTourStageRace) {
        totalTravel += 18000;
      } else {
        totalTravel += 4500;
      }
    }
    return totalTravel;
  }

  // ===========================================================================
  // GENEROWANIE RAPORTU CASHFLOW
  // ===========================================================================

  /// Tworzy całościowy, szczegółowy raport przepływu gotówki za dany miesiąc
  static MonthlyCashflowReport generateMonthlyCashflowReport({
    required CareerSave save,
    int? targetYear,
    int? targetMonth,
  }) {
    final team = save.playerTeam;
    final roster = save.playerRoster;
    final date = save.currentDate;
    final year = targetYear ?? date.year;
    final month = targetMonth ?? date.month;
    final period = DateTime(year, month, 1);

    // 1. Przychody
    int monthlySponsor = 0;
    for (final s in team.sponsors) {
      monthlySponsor += (s.annualBudgetEur / 12.0).round();
    }
    final int bikeDealCash = (team.bikeDeal.annualCashContributionEur / 12.0).round();

    // Filtrujemy transakcje z księgi finansowej dla danego miesiąca
    final ledgerEntriesThisMonth = save.financeLedger.where((e) {
      return e.date.year == year && e.date.month == month;
    }).toList();

    int prizeMoneyClub = 0;
    int prizeMoneyRiders = 0;
    int buyoutIncome = 0;
    int otherIncome = 0;

    int campsExpenses = 0;
    int testingExpenses = 0;
    int equipmentExpenses = 0;
    int facilityExpenses = 0;

    for (final entry in ledgerEntriesThisMonth) {
      if (entry.category == FinanceCategory.racePrizeMoney ||
          entry.category == FinanceCategory.prizeMoney) {
        if (entry.amountEur > 0) prizeMoneyClub += entry.amountEur;
      } else if (entry.category == FinanceCategory.riderBuyoutIncome) {
        buyoutIncome += entry.amountEur;
      } else if (entry.category == FinanceCategory.trainingCamps) {
        campsExpenses += entry.amountEur.abs();
      } else if (entry.category == FinanceCategory.physiologicalTesting) {
        testingExpenses += entry.amountEur.abs();
      } else if (entry.category == FinanceCategory.equipmentUpgrade) {
        equipmentExpenses += entry.amountEur.abs();
      } else if (entry.category == FinanceCategory.facilityUpgrade) {
        facilityExpenses += entry.amountEur.abs();
      } else if (entry.amountEur > 0 &&
          entry.category != FinanceCategory.sponsorPayout &&
          entry.category != FinanceCategory.bikeManufacturerCash) {
        otherIncome += entry.amountEur;
      }
    }

    // Szacowane nagrody dla kolarzy na podstawie nagród klubu (domyślny split 70/30)
    if (prizeMoneyClub > 0) {
      prizeMoneyRiders = ((prizeMoneyClub / 30.0) * 70.0).round();
    }

    final totalIncome =
        monthlySponsor + bikeDealCash + prizeMoneyClub + buyoutIncome + otherIncome;

    // 2. Koszty operacyjne
    final riderSalaries = calculateRiderMonthlySalaries(roster);
    final staffSalaries = calculateStaffMonthlySalaries(team.staff);
    final fleetLogistics = calculateMonthlyFleetMaintenance(team);
    final raceTravel = calculateRaceTravelLogistics(save, month);
    final raceLogistics = fleetLogistics + raceTravel;

    // Domyślny koszt utrzymania infrastruktury i bazy jeśli nie było inwestycji
    if (facilityExpenses == 0) {
      facilityExpenses = (save.serviceCourseLevel * 1200) +
          (save.windTunnelLevel * 1800) +
          (save.medicalCenterLevel * 1400);
    }

    // Domyślny koszt serwisu sprzętu (opony, łańcuchy, klocki hamulcowe)
    if (equipmentExpenses == 0) {
      equipmentExpenses = roster.length * 280;
    }

    final totalExpenses = riderSalaries +
        staffSalaries +
        raceLogistics +
        campsExpenses +
        testingExpenses +
        equipmentExpenses +
        facilityExpenses;

    final netCashflow = totalIncome - totalExpenses;
    final currentCash = team.cashBalanceEur;
    final startingBalance = currentCash - netCashflow;
    final endingBalance = currentCash;

    double runway = 99.0;
    if (totalExpenses > totalIncome) {
      final monthlyDeficit = totalExpenses - totalIncome;
      runway = currentCash > 0 ? (currentCash / monthlyDeficit) : 0.0;
    }

    // Obliczenie wskaźnika kondycji finansowej (1-100)
    int healthScore = 75;
    if (netCashflow > 0) healthScore += 15;
    if (runway > 12) healthScore += 10;
    if (runway < 3) healthScore -= 30;
    if (currentCash < 100000) healthScore -= 25;
    if (riderSalaries > totalIncome * 0.7) healthScore -= 15;
    healthScore = healthScore.clamp(10, 100);

    // Rekomendacje zarządcze
    final List<String> recommendations = [];
    if (riderSalaries > totalIncome * 0.65) {
      recommendations.add(
        'Pensje zawodników pochłaniają ponad 65% przychodów. Rozważ sprzedaż rezerwowych lub renegocjację wygasających umów.',
      );
    }
    if (runway < 4.0 && netCashflow < 0) {
      recommendations.add(
        'UWAGA: Płynność finansowa wynosi poniżej 4 miesięcy! Pilnie pozyskaj sponsora dodatkowego lub sprzedaj zawodnika z wysoką klauzulą.',
      );
    }
    if (team.bikeDeal.annualCashContributionEur <= 0 &&
        team.division != TeamDivision.continental) {
      recommendations.add(
        'Brak gotówkowego wsparcia od producenta ram. Podejmij negocjacje z marką z segmentu Premium Tier.',
      );
    }
    if (netCashflow > 50000) {
      recommendations.add(
        'Dodatni bilans operacyjny. Bezpieczny moment na inwestycję w tunel aero lub badania wydolnościowe kadry.',
      );
    }

    return MonthlyCashflowReport(
      period: period,
      sponsorPayoutEur: monthlySponsor,
      bikeManufacturerCashEur: bikeDealCash,
      prizeMoneyClubShareEur: prizeMoneyClub,
      prizeMoneyRidersShareEur: prizeMoneyRiders,
      riderBuyoutIncomeEur: buyoutIncome,
      otherIncomeEur: otherIncome,
      totalIncomeEur: totalIncome,
      riderSalariesEur: riderSalaries,
      staffSalariesEur: staffSalaries,
      raceLogisticsEur: raceLogistics,
      trainingCampsEur: campsExpenses,
      physiologicalTestingEur: testingExpenses,
      equipmentServiceAndPurchasesEur: equipmentExpenses,
      facilitiesMaintenanceEur: facilityExpenses,
      totalExpensesEur: totalExpenses,
      netCashflowEur: netCashflow,
      startingBalanceEur: startingBalance,
      endingBalanceEur: endingBalance,
      runwayMonths: runway,
      financialHealthScore: healthScore,
      recommendations: recommendations,
    );
  }

  // ===========================================================================
  // MIESIĘCZNE ROZLICZENIE FINANSOWE (1. DZIEŃ MIESIĄCA)
  // ===========================================================================

  /// Przeprowadza oficjalne, comiesięczne rozliczenie finansowe klubu
  static CareerSave processMonthlySettlement({required CareerSave save}) {
    final team = save.playerTeam;
    final roster = save.playerRoster;
    final date = save.currentDate;

    int updatedBalance = team.cashBalanceEur;
    final List<CareerFinanceLedgerEntry> newEntries = [];

    // 1. Wpływ transzy sponsorskiej
    int sponsorMonthly = 0;
    for (final s in team.sponsors) {
      sponsorMonthly += (s.annualBudgetEur / 12.0).round();
    }
    if (sponsorMonthly > 0) {
      updatedBalance += sponsorMonthly;
      newEntries.add(CareerFinanceLedgerEntry(
        id: 'fin_spons_${date.year}_${date.month}',
        date: date,
        category: FinanceCategory.sponsorPayout,
        amountEur: sponsorMonthly,
        description: 'Miesięczna transza sponsorska (${team.sponsors.length} sponsorów)',
      ));
    }

    // 2. Wpływ od producenta rowerów
    final bikeCashMonthly = (team.bikeDeal.annualCashContributionEur / 12.0).round();
    if (bikeCashMonthly > 0) {
      updatedBalance += bikeCashMonthly;
      newEntries.add(CareerFinanceLedgerEntry(
        id: 'fin_bike_${date.year}_${date.month}',
        date: date,
        category: FinanceCategory.bikeManufacturerCash,
        amountEur: bikeCashMonthly,
        description: 'Miesięczna dotacja od sponsora technicznego: ${team.bikeDeal.manufacturerName}',
      ));
    }

    // 3. Wypłata pensji kolarzy
    final riderPayroll = calculateRiderMonthlySalaries(roster);
    if (riderPayroll > 0) {
      updatedBalance -= riderPayroll;
      newEntries.add(CareerFinanceLedgerEntry(
        id: 'fin_riders_${date.year}_${date.month}',
        date: date,
        category: FinanceCategory.riderSalaries,
        amountEur: -riderPayroll,
        description: 'Wypłata wynagrodzeń kolarzy (${roster.length} zawodników w kadrze)',
      ));
    }

    // 4. Wypłata pensji sztabu
    final staffPayroll = calculateStaffMonthlySalaries(team.staff);
    if (staffPayroll > 0) {
      updatedBalance -= staffPayroll;
      newEntries.add(CareerFinanceLedgerEntry(
        id: 'fin_staff_${date.year}_${date.month}',
        date: date,
        category: FinanceCategory.staffSalaries,
        amountEur: -staffPayroll,
        description: 'Wynagrodzenia sztabu szkoleniowo-medycznego (DS, lekarze, mechanicy, trenerzy)',
      ));
    }

    // 5. Koszty stałe floty logistycznej
    final fleetCost = calculateMonthlyFleetMaintenance(team);
    if (fleetCost > 0) {
      updatedBalance -= fleetCost;
      newEntries.add(CareerFinanceLedgerEntry(
        id: 'fin_fleet_${date.year}_${date.month}',
        date: date,
        category: FinanceCategory.raceLogistics,
        amountEur: -fleetCost,
        description: 'Koszty stałe floty: serwis autokaru klubowego, wozów serwisowych i łączności',
      ));
    }

    // 6. Utrzymanie infrastruktury
    final facilityCost = (save.serviceCourseLevel * 1200) +
        (save.windTunnelLevel * 1800) +
        (save.medicalCenterLevel * 1400);
    if (facilityCost > 0) {
      updatedBalance -= facilityCost;
      newEntries.add(CareerFinanceLedgerEntry(
        id: 'fin_facil_${date.year}_${date.month}',
        date: date,
        category: FinanceCategory.facilityUpgrade,
        amountEur: -facilityCost,
        description: 'Koszty operacyjne Service Course, tunelu aerodynamicznego i kliniki regeneracji',
      ));
    }

    // Aktualizacja salda drużyny gracza
    final updatedTeams = save.teams.map((t) {
      if (t.id == team.id) {
        return t.copyWith(cashBalanceEur: updatedBalance);
      }
      return t;
    }).toList();

    return save.copyWith(
      teams: updatedTeams,
      financeLedger: [...newEntries, ...save.financeLedger],
      lastSavedAt: DateTime.now(),
    );
  }

  // ===========================================================================
  // ROZDZIAŁ NAGRÓD FINANSOWYCH (PRIZE MONEY SPLIT)
  // ===========================================================================

  /// Dzieli wygrane nagrody finansowe pomiędzy kolarzy i klub zgodnie z polityką zespołu
  static CareerSave processRacePrizeMoney({
    required CareerSave save,
    required String raceName,
    required int totalPrizeWonEur,
    PrizeMoneySplitPolicy policy = const PrizeMoneySplitPolicy(),
  }) {
    if (totalPrizeWonEur <= 0) return save;

    final clubShareEur = (totalPrizeWonEur * (policy.clubSharePercent / 100.0)).round();
    final ridersShareEur = totalPrizeWonEur - clubShareEur;

    // Aktualizujemy konto klubu o część klubową
    final updatedTeams = save.teams.map((t) {
      if (t.id == save.playerTeamId) {
        return t.copyWith(cashBalanceEur: t.cashBalanceEur + clubShareEur);
      }
      return t;
    }).toList();

    // Wpis do księgi finansowej
    final ledgerEntry = CareerFinanceLedgerEntry(
      id: 'prize_${DateTime.now().millisecondsSinceEpoch}',
      date: save.currentDate,
      category: FinanceCategory.racePrizeMoney,
      amountEur: clubShareEur,
      description:
          'Premie z $raceName (Pula: €$totalPrizeWonEur | Klub $clubShareEur € | Kolarze $ridersShareEur €)',
    );

    // Kolarze otrzymują nagrodę do podziału, co podnosi ich morale i lojalność
    final moraleBoost = policy.moraleModifier;
    final updatedRiders = save.riders.map((r) {
      if (save.playerTeam.rosterRiderIds.contains(r.id)) {
        final currentMorale = r.contract.morale;
        final newMorale = (currentMorale + moraleBoost).clamp(0.1, 1.0);
        return r.copyWith(
          contract: r.contract.copyWith(morale: newMorale),
        );
      }
      return r;
    }).toList();

    return save.copyWith(
      teams: updatedTeams,
      riders: updatedRiders,
      financeLedger: [ledgerEntry, ...save.financeLedger],
      lastSavedAt: DateTime.now(),
    );
  }

  // ===========================================================================
  // BADANIA WYDOLNOŚCIOWE (ERGOSPIROMETRIA, MLECZAN)
  // ===========================================================================

  /// Przeprowadza specjalistyczne badania laboratoryjne dla wybranej grupy kolarzy
  static PhysiologicalTestingOutcome conductPhysiologicalTesting({
    required CareerSave save,
    required List<String> riderIds,
    required PhysiologicalTestType testType,
  }) {
    final team = save.playerTeam;
    final testCost = testType == PhysiologicalTestType.teamFleetScreening
        ? testType.costPerRiderEur
        : testType.costPerRiderEur * riderIds.length;

    if (team.cashBalanceEur < testCost) {
      throw StateError(
        'Niewystarczające środki na koncie drużyny! Koszt badań: €$testCost, dostępne: €${team.cashBalanceEur}.',
      );
    }

    final targetRiders = save.riders.where((r) => riderIds.contains(r.id)).toList();
    final List<PhysiologicalTestResult> results = [];
    final List<Rider> updatedRiders = List.from(save.riders);

    for (final rider in targetRiders) {
      final phys = rider.physiology;
      final power = rider.powerProfile;
      final weight = phys.weightKg > 0 ? phys.weightKg : 70.0;

      // Obliczamy rzeczywistą wydolność na podstawie profilu mocy
      final realFtp = power.watts20m * 0.95;
      final realVo2 = (power.watts5m / weight) * 11.2;
      final maxHr = 220 - rider.age;

      // Wyznaczenie progu mleczanowego (LT2 / OBLA 4.0 mmol/L)
      final lactateWatts = realFtp * 0.98;

      // Badanie wykrywa poziom zmęczenia i przetrenowanie (ATL / stan zdrowia)
      final fatigueIndex = ((phys.acuteFatigueAtl / 120.0) * 100.0).clamp(10.0, 99.0);
      final isOvertrained = phys.acuteFatigueAtl > 105.0 || phys.trainingStressBalanceTsb < -35.0;

      String summary;
      String recommendation;

      if (isOvertrained) {
        summary =
            'Wykryto syndrom ostrego przetrenowania! Podwyższony spoczynkowy kwas mlekowy i spadek tętna maksymalnego.';
        recommendation =
            'Zalecany natychmiastowy 5-dniowy odpoczynek aktywny w strefie Z1 oraz sesje w kriokomorze.';
      } else if (fatigueIndex < 40.0) {
        summary =
            'Kolarz w znakomitej dyspozycji tlenowej. Niski poziom zakwaszenia mięśniowego przy obciążeniach podprogowych.';
        recommendation =
            'Optymalna adaptacja. Gotowy do startu w docelowym Grand Tourze na 100% możliwości.';
      } else {
        summary =
            'Stabilna wydolność w fazie obciążenia. Prawidłowa kinetyka mleczanu w strefie Sweet Spot.';
        recommendation =
            'Kontynuować plan treningowy z zachowaniem zaplanowanych dni regeneracyjnych.';
      }

      final testResult = PhysiologicalTestResult(
        riderId: rider.id,
        riderName: rider.fullName,
        testType: testType,
        testDate: save.currentDate,
        measuredFtpWatts: realFtp,
        measuredVo2Max: realVo2,
        measuredMaxHeartRate: maxHr,
        lactateThresholdWatts: lactateWatts,
        fatigueIndexPercent: fatigueIndex,
        isOvertrained: isOvertrained,
        summary: summary,
        recommendation: recommendation,
        labProfile: rider.labProfile,
      );
      results.add(testResult);

      // Dzięki badaniom sztab trenerski może precyzyjniej dobrać obciążenia (+1 do race IQ lub optymalizacja FTP)
      final idx = updatedRiders.indexWhere((r) => r.id == rider.id);
      if (idx >= 0) {
        updatedRiders[idx] = rider.copyWith(
          skills: rider.skills.copyWith(
            raceIq: (rider.skills.raceIq + 1).clamp(1, 99),
          ),
        );
      }
    }

    // Aktualizacja salda finansowego
    final updatedTeams = save.teams.map((t) {
      if (t.id == team.id) {
        return t.copyWith(cashBalanceEur: t.cashBalanceEur - testCost);
      }
      return t;
    }).toList();

    final ledgerEntry = CareerFinanceLedgerEntry(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      date: save.currentDate,
      category: FinanceCategory.physiologicalTesting,
      amountEur: -testCost,
      description:
          'Badania wydolnościowe (${testType.label}) dla ${riderIds.length} kolarzy',
    );

    final updatedSave = save.copyWith(
      teams: updatedTeams,
      riders: updatedRiders,
      financeLedger: [ledgerEntry, ...save.financeLedger],
      lastSavedAt: DateTime.now(),
    );

    return PhysiologicalTestingOutcome(
      updatedSave: updatedSave,
      totalCostEur: testCost,
      results: results,
    );
  }

  // ===========================================================================
  // SPRZEDAŻ ZAWODNIKA (WYKUP KLAUZULI / BUYOUT)
  // ===========================================================================

  /// Przeprowadza transfer wychodzący kolarza z tytułu wpłaty klauzuli wykupu (Release Clause)
  static RiderBuyoutTransferResult processRiderBuyoutSale({
    required CareerSave save,
    required String riderId,
    required String buyingTeamId,
    int? customBuyoutFeeEur,
  }) {
    final rider = save.getRiderById(riderId);
    if (rider == null) {
      throw ArgumentError('Nie znaleziono kolarza o ID: $riderId');
    }

    final buyingTeam = save.getTeamById(buyingTeamId);
    if (buyingTeam == null) {
      throw ArgumentError('Nie znaleziono drużyny kupującej o ID: $buyingTeamId');
    }

    final buyoutFee = customBuyoutFeeEur ?? rider.contract.releaseClauseEur;

    // Zwiększamy budżet drużyny gracza o kwotę odstępnego
    final updatedTeams = save.teams.map((t) {
      if (t.id == save.playerTeamId) {
        final currentRoster = List<String>.from(t.rosterRiderIds)..remove(riderId);
        return t.copyWith(
          cashBalanceEur: t.cashBalanceEur + buyoutFee,
          rosterRiderIds: currentRoster,
        );
      } else if (t.id == buyingTeamId) {
        final currentRoster = List<String>.from(t.rosterRiderIds)..add(riderId);
        return t.copyWith(
          cashBalanceEur: t.cashBalanceEur - buyoutFee,
          rosterRiderIds: currentRoster,
        );
      }
      return t;
    }).toList();

    // Aktualizujemy kontrakt zawodnika
    final updatedRiders = save.riders.map((r) {
      if (r.id == riderId) {
        return r.copyWith(
          contract: r.contract.copyWith(
            teamId: buyingTeamId,
            morale: 0.95, // Nowy klub daje zastrzyk motywacji
          ),
        );
      }
      return r;
    }).toList();

    final ledgerEntry = CareerFinanceLedgerEntry(
      id: 'buyout_${DateTime.now().millisecondsSinceEpoch}',
      date: save.currentDate,
      category: FinanceCategory.riderBuyoutIncome,
      amountEur: buyoutFee,
      description:
          'Wykup klauzuli odstępnego: ${rider.fullName} przechodzi do ${buyingTeam.name}',
    );

    final updatedSave = save.copyWith(
      teams: updatedTeams,
      riders: updatedRiders,
      financeLedger: [ledgerEntry, ...save.financeLedger],
      lastSavedAt: DateTime.now(),
    );

    return RiderBuyoutTransferResult(
      updatedSave: updatedSave,
      riderId: riderId,
      riderName: rider.fullName,
      buyingTeamId: buyingTeamId,
      buyingTeamName: buyingTeam.name,
      buyoutFeeEur: buyoutFee,
      summary:
          'Klub ${buyingTeam.name} aktywował klauzulę wykupu w wysokości €${(buyoutFee / 1000).toStringAsFixed(0)}k za ${rider.fullName}. Gotówka wpłynęła na konto klubu.',
    );
  }

  // ===========================================================================
  // PAKIETY SERWISOWE I MATERIAŁY EKSPLOATACYJNE
  // ===========================================================================

  static const List<EquipmentConsumablePackage> availableEquipmentPackages = [
    EquipmentConsumablePackage(
      id: 'eq_pack_tires',
      name: 'Zapas szytek i opon bezdętkowych WorldTour',
      costEur: 6800,
      description: 'Zestaw 60 szytek bawełnianych 28mm z mleczkiem uszczelniającym na cały miesiąc wyścigów.',
      benefitDescription: 'Zmniejsza ryzyko przebicia opony (kapcia) o 35% na etapach z gorszą nawierzchnią.',
    ),
    EquipmentConsumablePackage(
      id: 'eq_pack_chains',
      name: 'Łańcuchy woskowane i łożyska ceramiczne',
      costEur: 9400,
      description: 'Zestaw napędowy zoptymalizowany pod kątem minimalizacji strat tarcia watów (Save 4-6W).',
      benefitDescription: 'Poprawia efektywność przeniesienia napędu i odporność na zrywanie łańcucha na finiszach.',
    ),
    EquipmentConsumablePackage(
      id: 'eq_pack_tt_disc',
      name: 'Koła pełne (Disc Wheels) i kierownice czasowe 3D',
      costEur: 18500,
      description: 'Nowoczesne koła dyskowe carbon monocoque z dedykowanymi kokpitami drukowanymi z tytanu.',
      benefitDescription: 'Obniża CdA o 0.008 m² na wszystkich etapach jazdy indywidualnej na czas (ITT).',
    ),
  ];

  /// Dokonuje zakupu pakietu serwisowo-sprzętowego
  static CareerSave purchaseEquipmentPackage({
    required CareerSave save,
    required EquipmentConsumablePackage package,
  }) {
    final team = save.playerTeam;
    if (team.cashBalanceEur < package.costEur) {
      throw StateError(
        'Brak wystarczających środków na zakup pakietu: ${package.name}. Wymagane: €${package.costEur}.',
      );
    }

    final updatedTeams = save.teams.map((t) {
      if (t.id == team.id) {
        return t.copyWith(cashBalanceEur: t.cashBalanceEur - package.costEur);
      }
      return t;
    }).toList();

    final ledgerEntry = CareerFinanceLedgerEntry(
      id: 'eq_${DateTime.now().millisecondsSinceEpoch}',
      date: save.currentDate,
      category: FinanceCategory.equipmentUpgrade,
      amountEur: -package.costEur,
      description: 'Zakup pakietu sprzętowego: ${package.name}',
    );

    return save.copyWith(
      teams: updatedTeams,
      financeLedger: [ledgerEntry, ...save.financeLedger],
      lastSavedAt: DateTime.now(),
    );
  }
}

class PhysiologicalTestingOutcome {
  final CareerSave updatedSave;
  final int totalCostEur;
  final List<PhysiologicalTestResult> results;

  const PhysiologicalTestingOutcome({
    required this.updatedSave,
    required this.totalCostEur,
    required this.results,
  });
}

class RiderBuyoutTransferResult {
  final CareerSave updatedSave;
  final String riderId;
  final String riderName;
  final String buyingTeamId;
  final String buyingTeamName;
  final int buyoutFeeEur;
  final String summary;

  const RiderBuyoutTransferResult({
    required this.updatedSave,
    required this.riderId,
    required this.riderName,
    required this.buyingTeamId,
    required this.buyingTeamName,
    required this.buyoutFeeEur,
    required this.summary,
  });
}

