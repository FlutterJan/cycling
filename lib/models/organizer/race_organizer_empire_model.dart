import 'dart:math' as math;

/// Archetyp syndykatu promotorskiego i organizatora wyścigów kolarskich.
enum OrganizerSyndicateArchetype {
  /// Gigant Wielkich Tourów i Monumentów (model ASO).
  asoGrandTourGiant,

  /// Historyczny promotor włoskich klasyków i Giro (model RCS Sport).
  rcsHeritagePromoter,

  /// Kolektyw klasyków brukowanych i północnych (model Flanders Classics).
  flandersClassicsCollective,

  /// Niezależny promotor rozwijający wyścigi UCI ProSeries do WorldTour.
  independentProSeries;

  String toJson() => name;

  static OrganizerSyndicateArchetype fromJson(String value) {
    return OrganizerSyndicateArchetype.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => OrganizerSyndicateArchetype.independentProSeries,
    );
  }

  String get displayNamePl {
    switch (this) {
      case OrganizerSyndicateArchetype.asoGrandTourGiant:
        return 'Gigant Wielkich Tourów (ASO)';
      case OrganizerSyndicateArchetype.rcsHeritagePromoter:
        return 'Promotor Dziedzictwa (RCS Sport)';
      case OrganizerSyndicateArchetype.flandersClassicsCollective:
        return 'Kolektyw Klasyków Północy';
      case OrganizerSyndicateArchetype.independentProSeries:
        return 'Niezależny Promotor ProSeries';
    }
  }

  String get displayNameEn {
    switch (this) {
      case OrganizerSyndicateArchetype.asoGrandTourGiant:
        return 'Grand Tour Giant (ASO)';
      case OrganizerSyndicateArchetype.rcsHeritagePromoter:
        return 'Heritage Promoter (RCS Sport)';
      case OrganizerSyndicateArchetype.flandersClassicsCollective:
        return 'Northern Classics Collective';
      case OrganizerSyndicateArchetype.independentProSeries:
        return 'Independent ProSeries Promoter';
    }
  }
}

/// Klasyfikacja wyścigu w kalendarzu UCI determinująca prestiż, budżet i wymogi TV.
enum UciRaceClassificationTier {
  uci1_1,
  uci2_1,
  uci1Pro,
  uci2Pro,
  uci1Uwt,
  uci2Uwt,
  monument,
  grandTour;

  String toJson() => name;

  static UciRaceClassificationTier fromJson(String value) {
    return UciRaceClassificationTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UciRaceClassificationTier.uci2Pro,
    );
  }

  String get uciCode {
    switch (this) {
      case UciRaceClassificationTier.uci1_1:
        return '1.1';
      case UciRaceClassificationTier.uci2_1:
        return '2.1';
      case UciRaceClassificationTier.uci1Pro:
        return '1.Pro';
      case UciRaceClassificationTier.uci2Pro:
        return '2.Pro';
      case UciRaceClassificationTier.uci1Uwt:
        return '1.UWT';
      case UciRaceClassificationTier.uci2Uwt:
        return '2.UWT';
      case UciRaceClassificationTier.monument:
        return '1.UWT Monument';
      case UciRaceClassificationTier.grandTour:
        return '2.UWT Grand Tour';
    }
  }

  String get displayNamePl {
    switch (this) {
      case UciRaceClassificationTier.uci1_1:
        return 'Klasyk UCI 1.1';
      case UciRaceClassificationTier.uci2_1:
        return 'Wyścig Etapowy UCI 2.1';
      case UciRaceClassificationTier.uci1Pro:
        return 'Klasyk UCI 1.Pro';
      case UciRaceClassificationTier.uci2Pro:
        return 'Wyścig Etapowy UCI 2.Pro';
      case UciRaceClassificationTier.uci1Uwt:
        return 'Klasyk WorldTour 1.UWT';
      case UciRaceClassificationTier.uci2Uwt:
        return 'Wyścig Etapowy WorldTour 2.UWT';
      case UciRaceClassificationTier.monument:
        return 'Monument Kolarski (1.UWT)';
      case UciRaceClassificationTier.grandTour:
        return 'Wielki Tour (2.UWT GT)';
    }
  }

  String get displayNameEn {
    switch (this) {
      case UciRaceClassificationTier.uci1_1:
        return 'UCI 1.1 One-Day';
      case UciRaceClassificationTier.uci2_1:
        return 'UCI 2.1 Stage Race';
      case UciRaceClassificationTier.uci1Pro:
        return 'UCI 1.Pro Classic';
      case UciRaceClassificationTier.uci2Pro:
        return 'UCI 2.Pro Stage Race';
      case UciRaceClassificationTier.uci1Uwt:
        return 'WorldTour 1.UWT Classic';
      case UciRaceClassificationTier.uci2Uwt:
        return 'WorldTour 2.UWT Stage Race';
      case UciRaceClassificationTier.monument:
        return 'Cycling Monument (1.UWT)';
      case UciRaceClassificationTier.grandTour:
        return 'Grand Tour (2.UWT GT)';
    }
  }

  bool get isStageRace {
    switch (this) {
      case UciRaceClassificationTier.uci2_1:
      case UciRaceClassificationTier.uci2Pro:
      case UciRaceClassificationTier.uci2Uwt:
      case UciRaceClassificationTier.grandTour:
        return true;
      case UciRaceClassificationTier.uci1_1:
      case UciRaceClassificationTier.uci1Pro:
      case UciRaceClassificationTier.uci1Uwt:
      case UciRaceClassificationTier.monument:
        return false;
    }
  }

  bool get isWorldTour {
    switch (this) {
      case UciRaceClassificationTier.uci1Uwt:
      case UciRaceClassificationTier.uci2Uwt:
      case UciRaceClassificationTier.monument:
      case UciRaceClassificationTier.grandTour:
        return true;
      case UciRaceClassificationTier.uci1_1:
      case UciRaceClassificationTier.uci2_1:
      case UciRaceClassificationTier.uci1Pro:
      case UciRaceClassificationTier.uci2Pro:
        return false;
    }
  }

  /// Minimalna pula nagród wymagana przez regulamin UCI w EUR.
  int get minPrizePoolEur {
    switch (this) {
      case UciRaceClassificationTier.uci1_1:
        return 18000;
      case UciRaceClassificationTier.uci2_1:
        return 45000;
      case UciRaceClassificationTier.uci1Pro:
        return 42000;
      case UciRaceClassificationTier.uci2Pro:
        return 135000;
      case UciRaceClassificationTier.uci1Uwt:
        return 110000;
      case UciRaceClassificationTier.uci2Uwt:
        return 280000;
      case UciRaceClassificationTier.monument:
        return 250000;
      case UciRaceClassificationTier.grandTour:
        return 2200000;
    }
  }

  /// Roczna opłata licencyjna UCI za sankcjonowanie wyścigu w EUR.
  int get uciSanctionFeeEur {
    switch (this) {
      case UciRaceClassificationTier.uci1_1:
        return 9500;
      case UciRaceClassificationTier.uci2_1:
        return 22000;
      case UciRaceClassificationTier.uci1Pro:
        return 28000;
      case UciRaceClassificationTier.uci2Pro:
        return 68000;
      case UciRaceClassificationTier.uci1Uwt:
        return 95000;
      case UciRaceClassificationTier.uci2Uwt:
        return 185000;
      case UciRaceClassificationTier.monument:
        return 210000;
      case UciRaceClassificationTier.grandTour:
        return 650000;
    }
  }

  /// Minimalna liczba godzin transmisji na żywo wymagana dla danej kategorii.
  double get minLiveTvHoursPerStage {
    switch (this) {
      case UciRaceClassificationTier.uci1_1:
        return 1.5;
      case UciRaceClassificationTier.uci2_1:
        return 1.5;
      case UciRaceClassificationTier.uci1Pro:
        return 2.5;
      case UciRaceClassificationTier.uci2Pro:
        return 2.5;
      case UciRaceClassificationTier.uci1Uwt:
        return 4.0;
      case UciRaceClassificationTier.uci2Uwt:
        return 3.5;
      case UciRaceClassificationTier.monument:
        return 6.0;
      case UciRaceClassificationTier.grandTour:
        return 5.0;
    }
  }

  /// Próg prestiżu (0–100) wymagany do awansu do wyższej kategorii.
  double get prestigePromotionThreshold {
    switch (this) {
      case UciRaceClassificationTier.uci1_1:
        return 58.0;
      case UciRaceClassificationTier.uci2_1:
        return 62.0;
      case UciRaceClassificationTier.uci1Pro:
        return 76.0;
      case UciRaceClassificationTier.uci2Pro:
        return 78.0;
      case UciRaceClassificationTier.uci1Uwt:
        return 92.0;
      case UciRaceClassificationTier.uci2Uwt:
        return 94.0;
      case UciRaceClassificationTier.monument:
      case UciRaceClassificationTier.grandTour:
        return 100.0;
    }
  }

  /// Dolna granica prestiżu (0–100), poniżej której grozi degradacja licencji UCI.
  double get prestigeRelegationFloor {
    switch (this) {
      case UciRaceClassificationTier.uci1_1:
      case UciRaceClassificationTier.uci2_1:
        return 0.0;
      case UciRaceClassificationTier.uci1Pro:
        return 42.0;
      case UciRaceClassificationTier.uci2Pro:
        return 45.0;
      case UciRaceClassificationTier.uci1Uwt:
        return 64.0;
      case UciRaceClassificationTier.uci2Uwt:
        return 66.0;
      case UciRaceClassificationTier.monument:
        return 78.0;
      case UciRaceClassificationTier.grandTour:
        return 82.0;
    }
  }

  UciRaceClassificationTier? get nextHigherTier {
    switch (this) {
      case UciRaceClassificationTier.uci1_1:
        return UciRaceClassificationTier.uci1Pro;
      case UciRaceClassificationTier.uci2_1:
        return UciRaceClassificationTier.uci2Pro;
      case UciRaceClassificationTier.uci1Pro:
        return UciRaceClassificationTier.uci1Uwt;
      case UciRaceClassificationTier.uci2Pro:
        return UciRaceClassificationTier.uci2Uwt;
      case UciRaceClassificationTier.uci1Uwt:
        return UciRaceClassificationTier.monument;
      case UciRaceClassificationTier.uci2Uwt:
        return UciRaceClassificationTier.grandTour;
      case UciRaceClassificationTier.monument:
      case UciRaceClassificationTier.grandTour:
        return null;
    }
  }

  UciRaceClassificationTier? get nextLowerTier {
    switch (this) {
      case UciRaceClassificationTier.uci1_1:
      case UciRaceClassificationTier.uci2_1:
        return null;
      case UciRaceClassificationTier.uci1Pro:
        return UciRaceClassificationTier.uci1_1;
      case UciRaceClassificationTier.uci2Pro:
        return UciRaceClassificationTier.uci2_1;
      case UciRaceClassificationTier.uci1Uwt:
        return UciRaceClassificationTier.uci1Pro;
      case UciRaceClassificationTier.uci2Uwt:
        return UciRaceClassificationTier.uci2Pro;
      case UciRaceClassificationTier.monument:
        return UciRaceClassificationTier.uci1Uwt;
      case UciRaceClassificationTier.grandTour:
        return UciRaceClassificationTier.uci2Uwt;
    }
  }
}

/// Rola miasta gospodarza w strukturze wyścigu (przetargi Host City Bids).
enum HostBidRole {
  grandDepart,
  stageStart,
  stageFinish,
  mountainSummitFinish,
  individualTimeTrialHost,
  finalChampsElyseesFinish;

  String toJson() => name;

  static HostBidRole fromJson(String value) {
    return HostBidRole.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => HostBidRole.stageFinish,
    );
  }

  String get displayNamePl {
    switch (this) {
      case HostBidRole.grandDepart:
        return 'Grand Départ (Start Wielkiego Touru)';
      case HostBidRole.stageStart:
        return 'Miasto Startowe Etapu';
      case HostBidRole.stageFinish:
        return 'Miasto Metowe Etapu';
      case HostBidRole.mountainSummitFinish:
        return 'Meta Górska (Szczyt HC / Cat 1)';
      case HostBidRole.individualTimeTrialHost:
        return 'Gospodarz Czasówki (ITT)';
      case HostBidRole.finalChampsElyseesFinish:
        return 'Prestiżowa Meta Finałowa';
    }
  }

  String get displayNameEn {
    switch (this) {
      case HostBidRole.grandDepart:
        return 'Grand Départ';
      case HostBidRole.stageStart:
        return 'Stage Start City';
      case HostBidRole.stageFinish:
        return 'Stage Finish City';
      case HostBidRole.mountainSummitFinish:
        return 'Mountain Summit Finish';
      case HostBidRole.individualTimeTrialHost:
        return 'Individual Time Trial Host';
      case HostBidRole.finalChampsElyseesFinish:
        return 'Prestigious Final Finish';
    }
  }

  /// Mnożnik prestiżu i atrakcyjności medialnej roli miasta.
  double get prestigeWeight {
    switch (this) {
      case HostBidRole.grandDepart:
        return 1.35;
      case HostBidRole.stageStart:
        return 0.85;
      case HostBidRole.stageFinish:
        return 1.0;
      case HostBidRole.mountainSummitFinish:
        return 1.25;
      case HostBidRole.individualTimeTrialHost:
        return 1.1;
      case HostBidRole.finalChampsElyseesFinish:
        return 1.4;
    }
  }
}

/// Status oferty przetargowej miasta gospodarza.
enum HostBidStatus {
  openForBidding,
  shortlisted,
  awarded,
  rejected,
  expired,
  withdrawn;

  String toJson() => name;

  static HostBidStatus fromJson(String value) {
    return HostBidStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => HostBidStatus.openForBidding,
    );
  }

  bool get isActiveForDecision =>
      this == HostBidStatus.openForBidding || this == HostBidStatus.shortlisted;
}

/// Kategoria praw telewizyjnych i dystrybucji sygnału wyścigowego.
enum TvBroadcastTier {
  freeToAirNational,
  panContinentalSports,
  globalStreamingOtt,
  payPerViewPremium,
  hostBroadcasterFeed;

  String toJson() => name;

  static TvBroadcastTier fromJson(String value) {
    return TvBroadcastTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TvBroadcastTier.panContinentalSports,
    );
  }

  String get displayNamePl {
    switch (this) {
      case TvBroadcastTier.freeToAirNational:
        return 'Telewizja Otwarta (FTA Publiczna)';
      case TvBroadcastTier.panContinentalSports:
        return 'Kanał Sportowy Pan-Kontynentalny';
      case TvBroadcastTier.globalStreamingOtt:
        return 'Globalna Platforma Streamingowa OTT';
      case TvBroadcastTier.payPerViewPremium:
        return 'Kanał Premium Pay-TV';
      case TvBroadcastTier.hostBroadcasterFeed:
        return 'Sygnał Światowy (Host Broadcaster)';
    }
  }

  String get displayNameEn {
    switch (this) {
      case TvBroadcastTier.freeToAirNational:
        return 'Free-To-Air National TV';
      case TvBroadcastTier.panContinentalSports:
        return 'Pan-Continental Sports Network';
      case TvBroadcastTier.globalStreamingOtt:
        return 'Global Streaming OTT';
      case TvBroadcastTier.payPerViewPremium:
        return 'Premium Pay-TV';
      case TvBroadcastTier.hostBroadcasterFeed:
        return 'World Host Broadcaster Feed';
    }
  }

  /// Współczynnik zasięgu masowego dla sponsorów i miast (0.5–1.5).
  double get sponsorReachMultiplier {
    switch (this) {
      case TvBroadcastTier.freeToAirNational:
        return 1.35;
      case TvBroadcastTier.panContinentalSports:
        return 1.25;
      case TvBroadcastTier.globalStreamingOtt:
        return 1.15;
      case TvBroadcastTier.payPerViewPremium:
        return 0.85;
      case TvBroadcastTier.hostBroadcasterFeed:
        return 1.45;
    }
  }
}

/// Terytorium licencyjne praw transmisji TV.
enum TvRightsTerritory {
  europeCore,
  franceBenelux,
  italySpain,
  northAmerica,
  asiaPacific,
  latinAmerica,
  globalWorldwide;

  String toJson() => name;

  static TvRightsTerritory fromJson(String value) {
    return TvRightsTerritory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TvRightsTerritory.europeCore,
    );
  }

  String get displayNamePl {
    switch (this) {
      case TvRightsTerritory.europeCore:
        return 'Europa Centralna i Zachodnia';
      case TvRightsTerritory.franceBenelux:
        return 'Francja i Beneluks';
      case TvRightsTerritory.italySpain:
        return 'Włochy i Półwysep Iberyjski';
      case TvRightsTerritory.northAmerica:
        return 'Ameryka Północna';
      case TvRightsTerritory.asiaPacific:
        return 'Azja i Pacyfik';
      case TvRightsTerritory.latinAmerica:
        return 'Ameryka Łacińska';
      case TvRightsTerritory.globalWorldwide:
        return 'Globalnie (Worldwide)';
    }
  }
}

/// Status kontraktu telewizyjnego.
enum TvContractStatus {
  negotiating,
  active,
  expiringSoon,
  expired,
  terminated;

  String toJson() => name;

  static TvContractStatus fromJson(String value) {
    return TvContractStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TvContractStatus.negotiating,
    );
  }
}

/// Kategoria operacji w księdze finansowej organizatora.
enum OrganizerCashflowCategory {
  hostCityFee,
  tvRightsInstallment,
  titleSponsorship,
  hospitalityVip,
  prizeMoneyPayout,
  appearanceFee,
  safetyAndLogistics,
  uciSanctioningFee,
  operatingOverhead;

  String toJson() => name;

  static OrganizerCashflowCategory fromJson(String value) {
    return OrganizerCashflowCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => OrganizerCashflowCategory.operatingOverhead,
    );
  }

  bool get isRevenue {
    switch (this) {
      case OrganizerCashflowCategory.hostCityFee:
      case OrganizerCashflowCategory.tvRightsInstallment:
      case OrganizerCashflowCategory.titleSponsorship:
      case OrganizerCashflowCategory.hospitalityVip:
        return true;
      case OrganizerCashflowCategory.prizeMoneyPayout:
      case OrganizerCashflowCategory.appearanceFee:
      case OrganizerCashflowCategory.safetyAndLogistics:
      case OrganizerCashflowCategory.uciSanctioningFee:
      case OrganizerCashflowCategory.operatingOverhead:
        return false;
    }
  }
}

/// Pojedynczy wpis w księdze przychodów i wydatków organizatora.
class OrganizerLedgerEntry {
  final String entryId;
  final String description;
  final OrganizerCashflowCategory category;
  final int amountEur;
  final int seasonYear;
  final String? relatedRaceId;

  const OrganizerLedgerEntry({
    required this.entryId,
    required this.description,
    required this.category,
    required this.amountEur,
    required this.seasonYear,
    this.relatedRaceId,
  });

  int get signedAmountEur => category.isRevenue ? amountEur : -amountEur;

  Map<String, dynamic> toJson() {
    return {
      'entryId': entryId,
      'description': description,
      'category': category.toJson(),
      'amountEur': amountEur,
      'seasonYear': seasonYear,
      'relatedRaceId': relatedRaceId,
    };
  }

  factory OrganizerLedgerEntry.fromJson(Map<String, dynamic> json) {
    return OrganizerLedgerEntry(
      entryId: json['entryId'] as String? ?? 'entry_unknown',
      description: json['description'] as String? ?? '',
      category: OrganizerCashflowCategory.fromJson(
        json['category'] as String? ?? 'operatingOverhead',
      ),
      amountEur: (json['amountEur'] as num?)?.toInt() ?? 0,
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      relatedRaceId: json['relatedRaceId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizerLedgerEntry &&
          runtimeType == other.runtimeType &&
          entryId == other.entryId &&
          description == other.description &&
          category == other.category &&
          amountEur == other.amountEur &&
          seasonYear == other.seasonYear &&
          relatedRaceId == other.relatedRaceId;

  @override
  int get hashCode => Object.hash(
        entryId,
        description,
        category,
        amountEur,
        seasonYear,
        relatedRaceId,
      );
}

/// Księga budżetowa syndykatu organizatora wyścigów.
class OrganizerBudgetLedger {
  final int liquidCashEur;
  final int reserveFundEur;
  final int annualOperatingOverheadEur;
  final int prizePoolCommitmentEur;
  final int appearanceFeesAllocatedEur;
  final int safetyInfrastructureBudgetEur;
  final int totalRevenueYtdEur;
  final int totalExpensesYtdEur;
  final List<OrganizerLedgerEntry> recentTransactions;

  const OrganizerBudgetLedger({
    required this.liquidCashEur,
    required this.reserveFundEur,
    required this.annualOperatingOverheadEur,
    required this.prizePoolCommitmentEur,
    required this.appearanceFeesAllocatedEur,
    required this.safetyInfrastructureBudgetEur,
    this.totalRevenueYtdEur = 0,
    this.totalExpensesYtdEur = 0,
    this.recentTransactions = const [],
  });

  int get netCashflowYtdEur => totalRevenueYtdEur - totalExpensesYtdEur;

  /// Środki dostępne po odliczeniu twardych rezerw i alokacji na nagrody/bezpieczeństwo.
  int get availableDiscretionaryBudgetEur {
    final committed = prizePoolCommitmentEur +
        appearanceFeesAllocatedEur +
        safetyInfrastructureBudgetEur;
    return math.max(0, liquidCashEur - committed);
  }

  int get totalLiquidityEur => liquidCashEur + reserveFundEur;

  bool canAfford(int amountEur) => liquidCashEur >= math.max(0, amountEur);

  OrganizerBudgetLedger recordTransaction(OrganizerLedgerEntry entry) {
    final absAmount = math.max(0, entry.amountEur);
    final isRev = entry.category.isRevenue;
    final updatedCash =
        isRev ? liquidCashEur + absAmount : liquidCashEur - absAmount;
    final updatedRev =
        isRev ? totalRevenueYtdEur + absAmount : totalRevenueYtdEur;
    final updatedExp =
        isRev ? totalExpensesYtdEur : totalExpensesYtdEur + absAmount;

    final updatedList = <OrganizerLedgerEntry>[
      entry,
      ...recentTransactions,
    ].take(40).toList(growable: false);

    return copyWith(
      liquidCashEur: updatedCash,
      totalRevenueYtdEur: updatedRev,
      totalExpensesYtdEur: updatedExp,
      recentTransactions: updatedList,
    );
  }

  OrganizerBudgetLedger copyWith({
    int? liquidCashEur,
    int? reserveFundEur,
    int? annualOperatingOverheadEur,
    int? prizePoolCommitmentEur,
    int? appearanceFeesAllocatedEur,
    int? safetyInfrastructureBudgetEur,
    int? totalRevenueYtdEur,
    int? totalExpensesYtdEur,
    List<OrganizerLedgerEntry>? recentTransactions,
  }) {
    return OrganizerBudgetLedger(
      liquidCashEur: liquidCashEur ?? this.liquidCashEur,
      reserveFundEur: reserveFundEur ?? this.reserveFundEur,
      annualOperatingOverheadEur:
          annualOperatingOverheadEur ?? this.annualOperatingOverheadEur,
      prizePoolCommitmentEur:
          prizePoolCommitmentEur ?? this.prizePoolCommitmentEur,
      appearanceFeesAllocatedEur:
          appearanceFeesAllocatedEur ?? this.appearanceFeesAllocatedEur,
      safetyInfrastructureBudgetEur:
          safetyInfrastructureBudgetEur ?? this.safetyInfrastructureBudgetEur,
      totalRevenueYtdEur: totalRevenueYtdEur ?? this.totalRevenueYtdEur,
      totalExpensesYtdEur: totalExpensesYtdEur ?? this.totalExpensesYtdEur,
      recentTransactions: recentTransactions ?? this.recentTransactions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'liquidCashEur': liquidCashEur,
      'reserveFundEur': reserveFundEur,
      'annualOperatingOverheadEur': annualOperatingOverheadEur,
      'prizePoolCommitmentEur': prizePoolCommitmentEur,
      'appearanceFeesAllocatedEur': appearanceFeesAllocatedEur,
      'safetyInfrastructureBudgetEur': safetyInfrastructureBudgetEur,
      'totalRevenueYtdEur': totalRevenueYtdEur,
      'totalExpensesYtdEur': totalExpensesYtdEur,
      'recentTransactions':
          recentTransactions.map((e) => e.toJson()).toList(growable: false),
    };
  }

  factory OrganizerBudgetLedger.fromJson(Map<String, dynamic> json) {
    final txRaw = json['recentTransactions'] as List<dynamic>? ?? const [];
    return OrganizerBudgetLedger(
      liquidCashEur: (json['liquidCashEur'] as num?)?.toInt() ?? 0,
      reserveFundEur: (json['reserveFundEur'] as num?)?.toInt() ?? 0,
      annualOperatingOverheadEur:
          (json['annualOperatingOverheadEur'] as num?)?.toInt() ?? 0,
      prizePoolCommitmentEur:
          (json['prizePoolCommitmentEur'] as num?)?.toInt() ?? 0,
      appearanceFeesAllocatedEur:
          (json['appearanceFeesAllocatedEur'] as num?)?.toInt() ?? 0,
      safetyInfrastructureBudgetEur:
          (json['safetyInfrastructureBudgetEur'] as num?)?.toInt() ?? 0,
      totalRevenueYtdEur: (json['totalRevenueYtdEur'] as num?)?.toInt() ?? 0,
      totalExpensesYtdEur: (json['totalExpensesYtdEur'] as num?)?.toInt() ?? 0,
      recentTransactions: txRaw
          .whereType<Map<String, dynamic>>()
          .map(OrganizerLedgerEntry.fromJson)
          .toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizerBudgetLedger &&
          runtimeType == other.runtimeType &&
          liquidCashEur == other.liquidCashEur &&
          reserveFundEur == other.reserveFundEur &&
          annualOperatingOverheadEur == other.annualOperatingOverheadEur &&
          prizePoolCommitmentEur == other.prizePoolCommitmentEur &&
          appearanceFeesAllocatedEur == other.appearanceFeesAllocatedEur &&
          safetyInfrastructureBudgetEur == other.safetyInfrastructureBudgetEur &&
          totalRevenueYtdEur == other.totalRevenueYtdEur &&
          totalExpensesYtdEur == other.totalExpensesYtdEur &&
          _listEquals(recentTransactions, other.recentTransactions);

  @override
  int get hashCode => Object.hash(
        liquidCashEur,
        reserveFundEur,
        annualOperatingOverheadEur,
        prizePoolCommitmentEur,
        appearanceFeesAllocatedEur,
        safetyInfrastructureBudgetEur,
        totalRevenueYtdEur,
        totalExpensesYtdEur,
        Object.hashAll(recentTransactions),
      );
}

/// Oferta przetargowa miasta gospodarza (`Host City Bid`).
class HostCityBid {
  final String bidId;
  final String raceId;
  final String cityName;
  final String countryCode;
  final String regionName;
  final HostBidRole role;
  final int targetStageNumber;
  final int bidFeeEur;
  final int localInfrastructureGrantEur;
  final int hospitalityRevenuePotentialEur;
  final double tourismExposureDemand;
  final double terrainFitScore;
  final double politicalStabilityIndex;
  final int crowdTurnoutForecast;
  final int deadlineDay;
  final HostBidStatus status;

  const HostCityBid({
    required this.bidId,
    required this.raceId,
    required this.cityName,
    required this.countryCode,
    required this.regionName,
    required this.role,
    required this.targetStageNumber,
    required this.bidFeeEur,
    required this.localInfrastructureGrantEur,
    required this.hospitalityRevenuePotentialEur,
    required this.tourismExposureDemand,
    required this.terrainFitScore,
    required this.politicalStabilityIndex,
    required this.crowdTurnoutForecast,
    required this.deadlineDay,
    this.status = HostBidStatus.openForBidding,
  });

  /// Łączna wartość ekonomiczna pakietu miasta dla organizatora.
  int get totalEconomicValueEur =>
      math.max<int>(0, bidFeeEur) +
      math.max<int>(0, localInfrastructureGrantEur) +
      math.max<int>(0, hospitalityRevenuePotentialEur);

  /// Złożony wskaźnik atrakcyjności oferty (0–100) uwzględniający finanse, profil trasy i kibiców.
  double get compositeBidScore {
    final financialNormalized =
        (totalEconomicValueEur / 6500000.0).clamp(0.0, 1.0) * 100.0;
    final crowdNormalized =
        (crowdTurnoutForecast / 250000.0).clamp(0.0, 1.0) * 100.0;
    final terrain = terrainFitScore.clamp(0.0, 100.0);
    final stability = politicalStabilityIndex.clamp(0.0, 100.0);

    final raw = (financialNormalized * 0.45) +
        (terrain * 0.25) +
        (crowdNormalized * 0.15) +
        (stability * 0.15);
    return (raw * (0.85 + 0.15 * role.prestigeWeight)).clamp(0.0, 100.0);
  }

  HostCityBid copyWith({
    String? bidId,
    String? raceId,
    String? cityName,
    String? countryCode,
    String? regionName,
    HostBidRole? role,
    int? targetStageNumber,
    int? bidFeeEur,
    int? localInfrastructureGrantEur,
    int? hospitalityRevenuePotentialEur,
    double? tourismExposureDemand,
    double? terrainFitScore,
    double? politicalStabilityIndex,
    int? crowdTurnoutForecast,
    int? deadlineDay,
    HostBidStatus? status,
  }) {
    return HostCityBid(
      bidId: bidId ?? this.bidId,
      raceId: raceId ?? this.raceId,
      cityName: cityName ?? this.cityName,
      countryCode: countryCode ?? this.countryCode,
      regionName: regionName ?? this.regionName,
      role: role ?? this.role,
      targetStageNumber: targetStageNumber ?? this.targetStageNumber,
      bidFeeEur: bidFeeEur ?? this.bidFeeEur,
      localInfrastructureGrantEur:
          localInfrastructureGrantEur ?? this.localInfrastructureGrantEur,
      hospitalityRevenuePotentialEur:
          hospitalityRevenuePotentialEur ?? this.hospitalityRevenuePotentialEur,
      tourismExposureDemand:
          tourismExposureDemand ?? this.tourismExposureDemand,
      terrainFitScore: terrainFitScore ?? this.terrainFitScore,
      politicalStabilityIndex:
          politicalStabilityIndex ?? this.politicalStabilityIndex,
      crowdTurnoutForecast: crowdTurnoutForecast ?? this.crowdTurnoutForecast,
      deadlineDay: deadlineDay ?? this.deadlineDay,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bidId': bidId,
      'raceId': raceId,
      'cityName': cityName,
      'countryCode': countryCode,
      'regionName': regionName,
      'role': role.toJson(),
      'targetStageNumber': targetStageNumber,
      'bidFeeEur': bidFeeEur,
      'localInfrastructureGrantEur': localInfrastructureGrantEur,
      'hospitalityRevenuePotentialEur': hospitalityRevenuePotentialEur,
      'tourismExposureDemand': tourismExposureDemand,
      'terrainFitScore': terrainFitScore,
      'politicalStabilityIndex': politicalStabilityIndex,
      'crowdTurnoutForecast': crowdTurnoutForecast,
      'deadlineDay': deadlineDay,
      'status': status.toJson(),
    };
  }

  factory HostCityBid.fromJson(Map<String, dynamic> json) {
    return HostCityBid(
      bidId: json['bidId'] as String? ?? 'bid_unknown',
      raceId: json['raceId'] as String? ?? 'race_unknown',
      cityName: json['cityName'] as String? ?? 'Unknown City',
      countryCode: json['countryCode'] as String? ?? 'FR',
      regionName: json['regionName'] as String? ?? '',
      role: HostBidRole.fromJson(json['role'] as String? ?? 'stageFinish'),
      targetStageNumber: (json['targetStageNumber'] as num?)?.toInt() ?? 1,
      bidFeeEur: (json['bidFeeEur'] as num?)?.toInt() ?? 0,
      localInfrastructureGrantEur:
          (json['localInfrastructureGrantEur'] as num?)?.toInt() ?? 0,
      hospitalityRevenuePotentialEur:
          (json['hospitalityRevenuePotentialEur'] as num?)?.toInt() ?? 0,
      tourismExposureDemand:
          (json['tourismExposureDemand'] as num?)?.toDouble() ?? 50.0,
      terrainFitScore: (json['terrainFitScore'] as num?)?.toDouble() ?? 50.0,
      politicalStabilityIndex:
          (json['politicalStabilityIndex'] as num?)?.toDouble() ?? 80.0,
      crowdTurnoutForecast:
          (json['crowdTurnoutForecast'] as num?)?.toInt() ?? 25000,
      deadlineDay: (json['deadlineDay'] as num?)?.toInt() ?? 30,
      status: HostBidStatus.fromJson(
        json['status'] as String? ?? 'openForBidding',
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HostCityBid &&
          runtimeType == other.runtimeType &&
          bidId == other.bidId &&
          raceId == other.raceId &&
          cityName == other.cityName &&
          countryCode == other.countryCode &&
          regionName == other.regionName &&
          role == other.role &&
          targetStageNumber == other.targetStageNumber &&
          bidFeeEur == other.bidFeeEur &&
          localInfrastructureGrantEur == other.localInfrastructureGrantEur &&
          hospitalityRevenuePotentialEur ==
              other.hospitalityRevenuePotentialEur &&
          tourismExposureDemand == other.tourismExposureDemand &&
          terrainFitScore == other.terrainFitScore &&
          politicalStabilityIndex == other.politicalStabilityIndex &&
          crowdTurnoutForecast == other.crowdTurnoutForecast &&
          deadlineDay == other.deadlineDay &&
          status == other.status;

  @override
  int get hashCode => Object.hash(
        bidId,
        raceId,
        cityName,
        countryCode,
        regionName,
        role,
        targetStageNumber,
        bidFeeEur,
        localInfrastructureGrantEur,
        hospitalityRevenuePotentialEur,
        tourismExposureDemand,
        terrainFitScore,
        politicalStabilityIndex,
        crowdTurnoutForecast,
        deadlineDay,
        status,
      );
}

/// Podpisana umowa z miastem gospodarzem etapu lub Grand Départ.
class HostCityContract {
  final String contractId;
  final String raceId;
  final String cityName;
  final String countryCode;
  final HostBidRole role;
  final int stageNumber;
  final int agreedFeeEur;
  final int infrastructureGrantEur;
  final int signedSeasonYear;
  final int contractLengthYears;
  final int remainingYears;
  final double satisfactionScore;

  const HostCityContract({
    required this.contractId,
    required this.raceId,
    required this.cityName,
    required this.countryCode,
    required this.role,
    required this.stageNumber,
    required this.agreedFeeEur,
    required this.infrastructureGrantEur,
    required this.signedSeasonYear,
    required this.contractLengthYears,
    required this.remainingYears,
    this.satisfactionScore = 80.0,
  });

  bool get isActive => remainingYears > 0;

  HostCityContract copyWith({
    String? contractId,
    String? raceId,
    String? cityName,
    String? countryCode,
    HostBidRole? role,
    int? stageNumber,
    int? agreedFeeEur,
    int? infrastructureGrantEur,
    int? signedSeasonYear,
    int? contractLengthYears,
    int? remainingYears,
    double? satisfactionScore,
  }) {
    return HostCityContract(
      contractId: contractId ?? this.contractId,
      raceId: raceId ?? this.raceId,
      cityName: cityName ?? this.cityName,
      countryCode: countryCode ?? this.countryCode,
      role: role ?? this.role,
      stageNumber: stageNumber ?? this.stageNumber,
      agreedFeeEur: agreedFeeEur ?? this.agreedFeeEur,
      infrastructureGrantEur:
          infrastructureGrantEur ?? this.infrastructureGrantEur,
      signedSeasonYear: signedSeasonYear ?? this.signedSeasonYear,
      contractLengthYears: contractLengthYears ?? this.contractLengthYears,
      remainingYears: remainingYears ?? this.remainingYears,
      satisfactionScore: satisfactionScore ?? this.satisfactionScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contractId': contractId,
      'raceId': raceId,
      'cityName': cityName,
      'countryCode': countryCode,
      'role': role.toJson(),
      'stageNumber': stageNumber,
      'agreedFeeEur': agreedFeeEur,
      'infrastructureGrantEur': infrastructureGrantEur,
      'signedSeasonYear': signedSeasonYear,
      'contractLengthYears': contractLengthYears,
      'remainingYears': remainingYears,
      'satisfactionScore': satisfactionScore,
    };
  }

  factory HostCityContract.fromJson(Map<String, dynamic> json) {
    return HostCityContract(
      contractId: json['contractId'] as String? ?? 'hc_unknown',
      raceId: json['raceId'] as String? ?? 'race_unknown',
      cityName: json['cityName'] as String? ?? 'Unknown City',
      countryCode: json['countryCode'] as String? ?? 'FR',
      role: HostBidRole.fromJson(json['role'] as String? ?? 'stageFinish'),
      stageNumber: (json['stageNumber'] as num?)?.toInt() ?? 1,
      agreedFeeEur: (json['agreedFeeEur'] as num?)?.toInt() ?? 0,
      infrastructureGrantEur:
          (json['infrastructureGrantEur'] as num?)?.toInt() ?? 0,
      signedSeasonYear: (json['signedSeasonYear'] as num?)?.toInt() ?? 2026,
      contractLengthYears: (json['contractLengthYears'] as num?)?.toInt() ?? 1,
      remainingYears: (json['remainingYears'] as num?)?.toInt() ?? 1,
      satisfactionScore:
          (json['satisfactionScore'] as num?)?.toDouble() ?? 80.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HostCityContract &&
          runtimeType == other.runtimeType &&
          contractId == other.contractId &&
          raceId == other.raceId &&
          cityName == other.cityName &&
          countryCode == other.countryCode &&
          role == other.role &&
          stageNumber == other.stageNumber &&
          agreedFeeEur == other.agreedFeeEur &&
          infrastructureGrantEur == other.infrastructureGrantEur &&
          signedSeasonYear == other.signedSeasonYear &&
          contractLengthYears == other.contractLengthYears &&
          remainingYears == other.remainingYears &&
          satisfactionScore == other.satisfactionScore;

  @override
  int get hashCode => Object.hash(
        contractId,
        raceId,
        cityName,
        countryCode,
        role,
        stageNumber,
        agreedFeeEur,
        infrastructureGrantEur,
        signedSeasonYear,
        contractLengthYears,
        remainingYears,
        satisfactionScore,
      );
}

/// Kontrakt na prawa do transmisji telewizyjnej i streamingowej wyścigu.
class TvRightsContract {
  final String contractId;
  final String raceId;
  final String broadcasterName;
  final TvRightsTerritory territory;
  final TvBroadcastTier tier;
  final TvContractStatus status;
  final int annualRightsFeeEur;
  final int viewershipBonusPerMillionEur;
  final double estimatedAvgViewersMillions;
  final double minimumLiveHoursPerStage;
  final bool helicopterRelayRequired;
  final bool onboardCamerasRequired;
  final int startSeasonYear;
  final int durationYears;
  final int remainingYears;

  const TvRightsContract({
    required this.contractId,
    required this.raceId,
    required this.broadcasterName,
    required this.territory,
    required this.tier,
    required this.status,
    required this.annualRightsFeeEur,
    required this.viewershipBonusPerMillionEur,
    required this.estimatedAvgViewersMillions,
    required this.minimumLiveHoursPerStage,
    required this.helicopterRelayRequired,
    required this.onboardCamerasRequired,
    required this.startSeasonYear,
    required this.durationYears,
    required this.remainingYears,
  });

  bool get isActive =>
      (status == TvContractStatus.active ||
          status == TvContractStatus.expiringSoon) &&
      remainingYears > 0;

  int get totalProjectedAnnualRevenueEur {
    final bonus =
        (estimatedAvgViewersMillions * viewershipBonusPerMillionEur).round();
    return math.max(0, annualRightsFeeEur) + math.max(0, bonus);
  }

  bool meetsUciLiveCoverageForTier(UciRaceClassificationTier raceTier) {
    return minimumLiveHoursPerStage >= raceTier.minLiveTvHoursPerStage;
  }

  TvRightsContract copyWith({
    String? contractId,
    String? raceId,
    String? broadcasterName,
    TvRightsTerritory? territory,
    TvBroadcastTier? tier,
    TvContractStatus? status,
    int? annualRightsFeeEur,
    int? viewershipBonusPerMillionEur,
    double? estimatedAvgViewersMillions,
    double? minimumLiveHoursPerStage,
    bool? helicopterRelayRequired,
    bool? onboardCamerasRequired,
    int? startSeasonYear,
    int? durationYears,
    int? remainingYears,
  }) {
    return TvRightsContract(
      contractId: contractId ?? this.contractId,
      raceId: raceId ?? this.raceId,
      broadcasterName: broadcasterName ?? this.broadcasterName,
      territory: territory ?? this.territory,
      tier: tier ?? this.tier,
      status: status ?? this.status,
      annualRightsFeeEur: annualRightsFeeEur ?? this.annualRightsFeeEur,
      viewershipBonusPerMillionEur:
          viewershipBonusPerMillionEur ?? this.viewershipBonusPerMillionEur,
      estimatedAvgViewersMillions:
          estimatedAvgViewersMillions ?? this.estimatedAvgViewersMillions,
      minimumLiveHoursPerStage:
          minimumLiveHoursPerStage ?? this.minimumLiveHoursPerStage,
      helicopterRelayRequired:
          helicopterRelayRequired ?? this.helicopterRelayRequired,
      onboardCamerasRequired:
          onboardCamerasRequired ?? this.onboardCamerasRequired,
      startSeasonYear: startSeasonYear ?? this.startSeasonYear,
      durationYears: durationYears ?? this.durationYears,
      remainingYears: remainingYears ?? this.remainingYears,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contractId': contractId,
      'raceId': raceId,
      'broadcasterName': broadcasterName,
      'territory': territory.toJson(),
      'tier': tier.toJson(),
      'status': status.toJson(),
      'annualRightsFeeEur': annualRightsFeeEur,
      'viewershipBonusPerMillionEur': viewershipBonusPerMillionEur,
      'estimatedAvgViewersMillions': estimatedAvgViewersMillions,
      'minimumLiveHoursPerStage': minimumLiveHoursPerStage,
      'helicopterRelayRequired': helicopterRelayRequired,
      'onboardCamerasRequired': onboardCamerasRequired,
      'startSeasonYear': startSeasonYear,
      'durationYears': durationYears,
      'remainingYears': remainingYears,
    };
  }

  factory TvRightsContract.fromJson(Map<String, dynamic> json) {
    return TvRightsContract(
      contractId: json['contractId'] as String? ?? 'tv_unknown',
      raceId: json['raceId'] as String? ?? 'race_unknown',
      broadcasterName: json['broadcasterName'] as String? ?? 'EuroSport',
      territory: TvRightsTerritory.fromJson(
        json['territory'] as String? ?? 'europeCore',
      ),
      tier: TvBroadcastTier.fromJson(
        json['tier'] as String? ?? 'panContinentalSports',
      ),
      status: TvContractStatus.fromJson(
        json['status'] as String? ?? 'active',
      ),
      annualRightsFeeEur: (json['annualRightsFeeEur'] as num?)?.toInt() ?? 0,
      viewershipBonusPerMillionEur:
          (json['viewershipBonusPerMillionEur'] as num?)?.toInt() ?? 0,
      estimatedAvgViewersMillions:
          (json['estimatedAvgViewersMillions'] as num?)?.toDouble() ?? 1.0,
      minimumLiveHoursPerStage:
          (json['minimumLiveHoursPerStage'] as num?)?.toDouble() ?? 2.0,
      helicopterRelayRequired:
          json['helicopterRelayRequired'] as bool? ?? false,
      onboardCamerasRequired: json['onboardCamerasRequired'] as bool? ?? false,
      startSeasonYear: (json['startSeasonYear'] as num?)?.toInt() ?? 2026,
      durationYears: (json['durationYears'] as num?)?.toInt() ?? 3,
      remainingYears: (json['remainingYears'] as num?)?.toInt() ?? 2,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TvRightsContract &&
          runtimeType == other.runtimeType &&
          contractId == other.contractId &&
          raceId == other.raceId &&
          broadcasterName == other.broadcasterName &&
          territory == other.territory &&
          tier == other.tier &&
          status == other.status &&
          annualRightsFeeEur == other.annualRightsFeeEur &&
          viewershipBonusPerMillionEur == other.viewershipBonusPerMillionEur &&
          estimatedAvgViewersMillions == other.estimatedAvgViewersMillions &&
          minimumLiveHoursPerStage == other.minimumLiveHoursPerStage &&
          helicopterRelayRequired == other.helicopterRelayRequired &&
          onboardCamerasRequired == other.onboardCamerasRequired &&
          startSeasonYear == other.startSeasonYear &&
          durationYears == other.durationYears &&
          remainingYears == other.remainingYears;

  @override
  int get hashCode => Object.hash(
        contractId,
        raceId,
        broadcasterName,
        territory,
        tier,
        status,
        annualRightsFeeEur,
        viewershipBonusPerMillionEur,
        estimatedAvgViewersMillions,
        minimumLiveHoursPerStage,
        helicopterRelayRequired,
        onboardCamerasRequired,
        startSeasonYear,
        durationYears,
        remainingYears,
      );
}

/// Ocena prestiżu UCI dla pojedynczego wyścigu w portfolio organizatora.
class UciPrestigeAssessment {
  final String raceId;
  final UciRaceClassificationTier currentTier;
  final double calculatedPrestigeScore;
  final bool meetsPrizePoolRequirement;
  final bool meetsTvCoverageRequirement;
  final bool promotionEligible;
  final bool relegationRisk;
  final UciRaceClassificationTier? recommendedTier;
  final List<String> complianceNotes;

  const UciPrestigeAssessment({
    required this.raceId,
    required this.currentTier,
    required this.calculatedPrestigeScore,
    required this.meetsPrizePoolRequirement,
    required this.meetsTvCoverageRequirement,
    required this.promotionEligible,
    required this.relegationRisk,
    this.recommendedTier,
    this.complianceNotes = const [],
  });
}

/// Pojedynczy wyścig należący do portfolio organizatora (np. Wielki Tour 2.UWT lub klasyk).
class ManagedRacePortfolioItem {
  final String raceId;
  final String raceName;
  final String countryCode;
  final UciRaceClassificationTier tier;
  final int stageCount;
  final double prestigeScore;
  final double globalViewershipIndex;
  final double courseQualityScore;
  final double safetyRatingScore;
  final double starPowerScore;
  final double uciComplianceScore;
  final String titleSponsorName;
  final int titleSponsorAnnualEur;
  final int prizePoolEur;
  final int consecutivelyHeldYears;
  final List<HostCityContract> hostCityContracts;
  final List<TvRightsContract> tvRightsContracts;

  const ManagedRacePortfolioItem({
    required this.raceId,
    required this.raceName,
    required this.countryCode,
    required this.tier,
    required this.stageCount,
    required this.prestigeScore,
    required this.globalViewershipIndex,
    required this.courseQualityScore,
    required this.safetyRatingScore,
    required this.starPowerScore,
    required this.uciComplianceScore,
    required this.titleSponsorName,
    required this.titleSponsorAnnualEur,
    required this.prizePoolEur,
    required this.consecutivelyHeldYears,
    this.hostCityContracts = const [],
    this.tvRightsContracts = const [],
  });

  int get annualTvRightsRevenueEur {
    return tvRightsContracts
        .where((c) => c.isActive)
        .fold(0, (sum, c) => sum + c.totalProjectedAnnualRevenueEur);
  }

  int get committedHostCityFeesEur {
    return hostCityContracts
        .where((c) => c.isActive)
        .fold(0, (sum, c) => sum + c.agreedFeeEur);
  }

  int get totalAnnualRevenueEur =>
      math.max(0, titleSponsorAnnualEur) +
      annualTvRightsRevenueEur +
      committedHostCityFeesEur;

  double get maxLiveTvHoursOffered {
    if (tvRightsContracts.isEmpty) return 0.0;
    return tvRightsContracts
        .where((c) => c.isActive)
        .fold<double>(0.0, (prev, c) => math.max(prev, c.minimumLiveHoursPerStage));
  }

  UciPrestigeAssessment evaluateUciPrestige() {
    final star = starPowerScore.clamp(0.0, 100.0);
    final course = courseQualityScore.clamp(0.0, 100.0);
    final safety = safetyRatingScore.clamp(0.0, 100.0);
    final viewership = globalViewershipIndex.clamp(0.0, 100.0);
    final compliance = uciComplianceScore.clamp(0.0, 100.0);

    final weightedPrestige = (star * 0.28) +
        (viewership * 0.24) +
        (course * 0.20) +
        (safety * 0.16) +
        (compliance * 0.12);

    final meetsPrize = prizePoolEur >= tier.minPrizePoolEur;
    final meetsTv = maxLiveTvHoursOffered >= tier.minLiveTvHoursPerStage;

    final notes = <String>[];
    if (!meetsPrize) {
      notes.add(
        'Pula nagród ($prizePoolEur EUR) poniżej minimum UCI (${tier.minPrizePoolEur} EUR).',
      );
    }
    if (!meetsTv) {
      notes.add(
        'Transmisja na żywo (${maxLiveTvHoursOffered.toStringAsFixed(1)}h) poniżej wymogu UCI (${tier.minLiveTvHoursPerStage.toStringAsFixed(1)}h).',
      );
    }
    if (safety < 65.0) {
      notes.add('Niski wskaźnik bezpieczeństwa trasy (${safety.toStringAsFixed(0)}/100).');
    }

    final nextUp = tier.nextHigherTier;
    final nextDown = tier.nextLowerTier;

    final promoEligible = nextUp != null &&
        weightedPrestige >= tier.prestigePromotionThreshold &&
        meetsPrize &&
        meetsTv &&
        safety >= 75.0;

    final relegRisk = nextDown != null &&
        (weightedPrestige < tier.prestigeRelegationFloor ||
            (!meetsPrize && !meetsTv));

    return UciPrestigeAssessment(
      raceId: raceId,
      currentTier: tier,
      calculatedPrestigeScore: weightedPrestige.clamp(0.0, 100.0),
      meetsPrizePoolRequirement: meetsPrize,
      meetsTvCoverageRequirement: meetsTv,
      promotionEligible: promoEligible,
      relegationRisk: relegRisk,
      recommendedTier: promoEligible
          ? nextUp
          : (relegRisk ? nextDown : tier),
      complianceNotes: notes,
    );
  }

  ManagedRacePortfolioItem copyWith({
    String? raceId,
    String? raceName,
    String? countryCode,
    UciRaceClassificationTier? tier,
    int? stageCount,
    double? prestigeScore,
    double? globalViewershipIndex,
    double? courseQualityScore,
    double? safetyRatingScore,
    double? starPowerScore,
    double? uciComplianceScore,
    String? titleSponsorName,
    int? titleSponsorAnnualEur,
    int? prizePoolEur,
    int? consecutivelyHeldYears,
    List<HostCityContract>? hostCityContracts,
    List<TvRightsContract>? tvRightsContracts,
  }) {
    return ManagedRacePortfolioItem(
      raceId: raceId ?? this.raceId,
      raceName: raceName ?? this.raceName,
      countryCode: countryCode ?? this.countryCode,
      tier: tier ?? this.tier,
      stageCount: stageCount ?? this.stageCount,
      prestigeScore: prestigeScore ?? this.prestigeScore,
      globalViewershipIndex:
          globalViewershipIndex ?? this.globalViewershipIndex,
      courseQualityScore: courseQualityScore ?? this.courseQualityScore,
      safetyRatingScore: safetyRatingScore ?? this.safetyRatingScore,
      starPowerScore: starPowerScore ?? this.starPowerScore,
      uciComplianceScore: uciComplianceScore ?? this.uciComplianceScore,
      titleSponsorName: titleSponsorName ?? this.titleSponsorName,
      titleSponsorAnnualEur:
          titleSponsorAnnualEur ?? this.titleSponsorAnnualEur,
      prizePoolEur: prizePoolEur ?? this.prizePoolEur,
      consecutivelyHeldYears:
          consecutivelyHeldYears ?? this.consecutivelyHeldYears,
      hostCityContracts: hostCityContracts ?? this.hostCityContracts,
      tvRightsContracts: tvRightsContracts ?? this.tvRightsContracts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'raceId': raceId,
      'raceName': raceName,
      'countryCode': countryCode,
      'tier': tier.toJson(),
      'stageCount': stageCount,
      'prestigeScore': prestigeScore,
      'globalViewershipIndex': globalViewershipIndex,
      'courseQualityScore': courseQualityScore,
      'safetyRatingScore': safetyRatingScore,
      'starPowerScore': starPowerScore,
      'uciComplianceScore': uciComplianceScore,
      'titleSponsorName': titleSponsorName,
      'titleSponsorAnnualEur': titleSponsorAnnualEur,
      'prizePoolEur': prizePoolEur,
      'consecutivelyHeldYears': consecutivelyHeldYears,
      'hostCityContracts':
          hostCityContracts.map((e) => e.toJson()).toList(growable: false),
      'tvRightsContracts':
          tvRightsContracts.map((e) => e.toJson()).toList(growable: false),
    };
  }

  factory ManagedRacePortfolioItem.fromJson(Map<String, dynamic> json) {
    final hcRaw = json['hostCityContracts'] as List<dynamic>? ?? const [];
    final tvRaw = json['tvRightsContracts'] as List<dynamic>? ?? const [];

    return ManagedRacePortfolioItem(
      raceId: json['raceId'] as String? ?? 'race_unknown',
      raceName: json['raceName'] as String? ?? 'Unnamed Race',
      countryCode: json['countryCode'] as String? ?? 'FR',
      tier: UciRaceClassificationTier.fromJson(
        json['tier'] as String? ?? 'uci2Pro',
      ),
      stageCount: (json['stageCount'] as num?)?.toInt() ?? 1,
      prestigeScore: (json['prestigeScore'] as num?)?.toDouble() ?? 50.0,
      globalViewershipIndex:
          (json['globalViewershipIndex'] as num?)?.toDouble() ?? 50.0,
      courseQualityScore:
          (json['courseQualityScore'] as num?)?.toDouble() ?? 60.0,
      safetyRatingScore:
          (json['safetyRatingScore'] as num?)?.toDouble() ?? 70.0,
      starPowerScore: (json['starPowerScore'] as num?)?.toDouble() ?? 55.0,
      uciComplianceScore:
          (json['uciComplianceScore'] as num?)?.toDouble() ?? 80.0,
      titleSponsorName: json['titleSponsorName'] as String? ?? 'None',
      titleSponsorAnnualEur:
          (json['titleSponsorAnnualEur'] as num?)?.toInt() ?? 0,
      prizePoolEur: (json['prizePoolEur'] as num?)?.toInt() ?? 50000,
      consecutivelyHeldYears:
          (json['consecutivelyHeldYears'] as num?)?.toInt() ?? 1,
      hostCityContracts: hcRaw
          .whereType<Map<String, dynamic>>()
          .map(HostCityContract.fromJson)
          .toList(growable: false),
      tvRightsContracts: tvRaw
          .whereType<Map<String, dynamic>>()
          .map(TvRightsContract.fromJson)
          .toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManagedRacePortfolioItem &&
          runtimeType == other.runtimeType &&
          raceId == other.raceId &&
          raceName == other.raceName &&
          countryCode == other.countryCode &&
          tier == other.tier &&
          stageCount == other.stageCount &&
          prestigeScore == other.prestigeScore &&
          globalViewershipIndex == other.globalViewershipIndex &&
          courseQualityScore == other.courseQualityScore &&
          safetyRatingScore == other.safetyRatingScore &&
          starPowerScore == other.starPowerScore &&
          uciComplianceScore == other.uciComplianceScore &&
          titleSponsorName == other.titleSponsorName &&
          titleSponsorAnnualEur == other.titleSponsorAnnualEur &&
          prizePoolEur == other.prizePoolEur &&
          consecutivelyHeldYears == other.consecutivelyHeldYears &&
          _listEquals(hostCityContracts, other.hostCityContracts) &&
          _listEquals(tvRightsContracts, other.tvRightsContracts);

  @override
  int get hashCode => Object.hash(
        raceId,
        raceName,
        countryCode,
        tier,
        stageCount,
        prestigeScore,
        globalViewershipIndex,
        courseQualityScore,
        safetyRatingScore,
        starPowerScore,
        uciComplianceScore,
        titleSponsorName,
        titleSponsorAnnualEur,
        prizePoolEur,
        consecutivelyHeldYears,
        Object.hashAll(hostCityContracts),
        Object.hashAll(tvRightsContracts),
      );
}

/// Wynik operacji na imperium organizatora wyścigów.
class OrganizerOperationResult {
  final bool success;
  final String message;
  final RaceOrganizerEmpireModel updatedEmpire;

  const OrganizerOperationResult({
    required this.success,
    required this.message,
    required this.updatedEmpire,
  });
}

/// Główny model trybu Promotor i Organizator Wyścigów (ASO / RCS Sport).
class RaceOrganizerEmpireModel {
  final String organizerId;
  final String syndicateName;
  final OrganizerSyndicateArchetype archetype;
  final String headquartersCountryCode;
  final int seasonYear;
  final double uciBoardInfluence;
  final OrganizerBudgetLedger budgetLedger;
  final List<ManagedRacePortfolioItem> managedRaces;
  final List<HostCityBid> pendingHostCityBids;

  const RaceOrganizerEmpireModel({
    required this.organizerId,
    required this.syndicateName,
    required this.archetype,
    required this.headquartersCountryCode,
    required this.seasonYear,
    required this.uciBoardInfluence,
    required this.budgetLedger,
    this.managedRaces = const [],
    this.pendingHostCityBids = const [],
  });

  /// Łączny roczny przychód ze wszystkich aktywnych kontraktów TV w portfolio.
  int get totalAnnualTvRevenueEur => managedRaces.fold(
        0,
        (sum, race) => sum + race.annualTvRightsRevenueEur,
      );

  /// Łączna wartość zakontraktowanych opłat miast gospodarzy.
  int get totalCommittedHostFeesEur => managedRaces.fold(
        0,
        (sum, race) => sum + race.committedHostCityFeesEur,
      );

  /// Średni prestiż UCI wszystkich wyścigów w portfolio (0–100).
  double get averageUciPrestige {
    if (managedRaces.isEmpty) return 0.0;
    final sum =
        managedRaces.fold<double>(0.0, (acc, r) => acc + r.prestigeScore);
    return sum / managedRaces.length;
  }

  /// Liczba wyścigów w najwyższej dywizji WorldTour (1.UWT / 2.UWT / Monument / GT).
  int get worldTourRaceCount =>
      managedRaces.where((r) => r.tier.isWorldTour).length;

  /// Szacowana wycena rynkowa imperium promotorskiego (EUR).
  int get empireValuationEur {
    final recurringAnnualRevenue = managedRaces.fold<int>(
      0,
      (sum, r) => sum + r.totalAnnualRevenueEur,
    );
    final prestigeMultiplier = 2.5 + (averageUciPrestige / 50.0);
    return math.max(
      0,
      budgetLedger.totalLiquidityEur +
          (recurringAnnualRevenue * prestigeMultiplier).round(),
    );
  }

  /// Przyznaje przetarg miasta gospodarza, odrzuca konkurencyjne oferty na ten sam etap/rolę i księguje opłatę.
  OrganizerOperationResult awardHostCityBid(
    String bidId, {
    int contractLengthYears = 1,
  }) {
    final targetIndex =
        pendingHostCityBids.indexWhere((b) => b.bidId == bidId);
    if (targetIndex == -1) {
      return OrganizerOperationResult(
        success: false,
        message: 'Nie znaleziono oferty przetargowej o ID: $bidId.',
        updatedEmpire: this,
      );
    }

    final bid = pendingHostCityBids[targetIndex];
    if (!bid.status.isActiveForDecision) {
      return OrganizerOperationResult(
        success: false,
        message:
            'Oferta miasta ${bid.cityName} nie jest już otwarta do rozstrzygnięcia.',
        updatedEmpire: this,
      );
    }

    final raceIndex = managedRaces.indexWhere((r) => r.raceId == bid.raceId);
    if (raceIndex == -1) {
      return OrganizerOperationResult(
        success: false,
        message:
            'Wyścig ${bid.raceId} nie należy do portfolio tego organizatora.',
        updatedEmpire: this,
      );
    }

    final safeLength = math.max(1, contractLengthYears);
    final newContract = HostCityContract(
      contractId: 'hc_${bid.raceId}_s${bid.targetStageNumber}_${bid.bidId}',
      raceId: bid.raceId,
      cityName: bid.cityName,
      countryCode: bid.countryCode,
      role: bid.role,
      stageNumber: bid.targetStageNumber,
      agreedFeeEur: bid.bidFeeEur,
      infrastructureGrantEur: bid.localInfrastructureGrantEur,
      signedSeasonYear: seasonYear,
      contractLengthYears: safeLength,
      remainingYears: safeLength,
      satisfactionScore: 85.0,
    );

    final updatedBids = pendingHostCityBids.map((b) {
      if (b.bidId == bid.bidId) {
        return b.copyWith(status: HostBidStatus.awarded);
      }
      final sameSlot = b.raceId == bid.raceId &&
          b.targetStageNumber == bid.targetStageNumber &&
          b.role == bid.role &&
          b.status.isActiveForDecision;
      if (sameSlot) {
        return b.copyWith(status: HostBidStatus.rejected);
      }
      return b;
    }).toList(growable: false);

    final targetRace = managedRaces[raceIndex];
    final updatedRace = targetRace.copyWith(
      hostCityContracts: [...targetRace.hostCityContracts, newContract],
      courseQualityScore: math.min(
        100.0,
        targetRace.courseQualityScore + (bid.terrainFitScore >= 80 ? 1.5 : 0.5),
      ),
    );

    final updatedRaces = List<ManagedRacePortfolioItem>.from(managedRaces);
    updatedRaces[raceIndex] = updatedRace;

    final updatedLedger = budgetLedger.recordTransaction(
      OrganizerLedgerEntry(
        entryId: 'tx_host_${bid.bidId}_$seasonYear',
        description:
            'Opłata przetargowa miasta ${bid.cityName} (${bid.role.displayNameEn})',
        category: OrganizerCashflowCategory.hostCityFee,
        amountEur: bid.bidFeeEur,
        seasonYear: seasonYear,
        relatedRaceId: bid.raceId,
      ),
    );

    return OrganizerOperationResult(
      success: true,
      message:
          'Przyznano przetarg miastu ${bid.cityName} (${bid.bidFeeEur} EUR).',
      updatedEmpire: copyWith(
        budgetLedger: updatedLedger,
        managedRaces: updatedRaces,
        pendingHostCityBids: updatedBids,
      ),
    );
  }

  /// Odrzuca pojedynczą ofertę miasta gospodarza.
  OrganizerOperationResult rejectHostCityBid(String bidId) {
    final idx = pendingHostCityBids.indexWhere((b) => b.bidId == bidId);
    if (idx == -1) {
      return OrganizerOperationResult(
        success: false,
        message: 'Nie znaleziono oferty o ID: $bidId.',
        updatedEmpire: this,
      );
    }

    final updatedBids = List<HostCityBid>.from(pendingHostCityBids);
    updatedBids[idx] = updatedBids[idx].copyWith(status: HostBidStatus.rejected);

    return OrganizerOperationResult(
      success: true,
      message: 'Odrzucono ofertę miasta ${updatedBids[idx].cityName}.',
      updatedEmpire: copyWith(pendingHostCityBids: updatedBids),
    );
  }

  /// Dodaje nową ofertę miasta gospodarza do puli przetargowej.
  RaceOrganizerEmpireModel submitHostCityBid(HostCityBid bid) {
    final existingIdx =
        pendingHostCityBids.indexWhere((b) => b.bidId == bid.bidId);
    final updatedBids = List<HostCityBid>.from(pendingHostCityBids);
    if (existingIdx >= 0) {
      updatedBids[existingIdx] = bid;
    } else {
      updatedBids.add(bid);
    }
    return copyWith(pendingHostCityBids: updatedBids);
  }

  /// Podpisuje lub odnawia kontrakt na prawa telewizyjne dla wyścigu z portfolio.
  OrganizerOperationResult signTvRightsContract(TvRightsContract contract) {
    final raceIndex =
        managedRaces.indexWhere((r) => r.raceId == contract.raceId);
    if (raceIndex == -1) {
      return OrganizerOperationResult(
        success: false,
        message: 'Wyścig ${contract.raceId} nie istnieje w portfolio.',
        updatedEmpire: this,
      );
    }

    final race = managedRaces[raceIndex];
    final existingContracts = List<TvRightsContract>.from(race.tvRightsContracts);
    final existingIdx = existingContracts
        .indexWhere((c) => c.contractId == contract.contractId);

    if (existingIdx >= 0) {
      existingContracts[existingIdx] = contract;
    } else {
      existingContracts.add(contract);
    }

    final reachBoost = contract.tier.sponsorReachMultiplier * 2.5;
    final updatedRace = race.copyWith(
      tvRightsContracts: existingContracts,
      globalViewershipIndex:
          math.min(100.0, race.globalViewershipIndex + reachBoost),
    );

    final updatedRaces = List<ManagedRacePortfolioItem>.from(managedRaces);
    updatedRaces[raceIndex] = updatedRace;

    final updatedLedger = budgetLedger.recordTransaction(
      OrganizerLedgerEntry(
        entryId: 'tx_tv_${contract.contractId}_$seasonYear',
        description:
            'Transza praw TV: ${contract.broadcasterName} (${contract.territory.name})',
        category: OrganizerCashflowCategory.tvRightsInstallment,
        amountEur: contract.annualRightsFeeEur,
        seasonYear: seasonYear,
        relatedRaceId: contract.raceId,
      ),
    );

    return OrganizerOperationResult(
      success: true,
      message:
          'Podpisano kontrakt TV z ${contract.broadcasterName} (${contract.annualRightsFeeEur} EUR/rok).',
      updatedEmpire: copyWith(
        budgetLedger: updatedLedger,
        managedRaces: updatedRaces,
      ),
    );
  }

  /// Przelicza ocenę prestiżu UCI dla wskazanego wyścigu i aktualizuje jego wynik.
  UciPrestigeAssessment? recalculateRacePrestige(String raceId) {
    final race = managedRaces
        .cast<ManagedRacePortfolioItem?>()
        .firstWhere((r) => r?.raceId == raceId, orElse: () => null);
    return race?.evaluateUciPrestige();
  }

  /// Zamyka rok budżetowy, rozlicza stałe koszty i przechodzi do kolejnego sezonu.
  RaceOrganizerEmpireModel advanceSeasonFinancials() {
    final nextYear = seasonYear + 1;
    var ledger = budgetLedger;

    final updatedRaces = managedRaces.map((race) {
      if (race.titleSponsorAnnualEur > 0) {
        ledger = ledger.recordTransaction(
          OrganizerLedgerEntry(
            entryId: 'tx_spon_${race.raceId}_$seasonYear',
            description: 'Sponsor tytularny ${race.titleSponsorName}',
            category: OrganizerCashflowCategory.titleSponsorship,
            amountEur: race.titleSponsorAnnualEur,
            seasonYear: seasonYear,
            relatedRaceId: race.raceId,
          ),
        );
      }

      ledger = ledger.recordTransaction(
        OrganizerLedgerEntry(
          entryId: 'tx_prize_${race.raceId}_$seasonYear',
          description: 'Wypłata puli nagród: ${race.raceName}',
          category: OrganizerCashflowCategory.prizeMoneyPayout,
          amountEur: race.prizePoolEur,
          seasonYear: seasonYear,
          relatedRaceId: race.raceId,
        ),
      );

      ledger = ledger.recordTransaction(
        OrganizerLedgerEntry(
          entryId: 'tx_uci_${race.raceId}_$seasonYear',
          description: 'Licencja UCI (${race.tier.uciCode}): ${race.raceName}',
          category: OrganizerCashflowCategory.uciSanctioningFee,
          amountEur: race.tier.uciSanctionFeeEur,
          seasonYear: seasonYear,
          relatedRaceId: race.raceId,
        ),
      );

      final updatedHostContracts = race.hostCityContracts
          .map(
            (c) => c.copyWith(
              remainingYears: math.max(0, c.remainingYears - 1),
            ),
          )
          .where((c) => c.remainingYears > 0)
          .toList(growable: false);

      final updatedTvContracts = race.tvRightsContracts.map((c) {
        final nextRem = math.max(0, c.remainingYears - 1);
        final nextStatus = nextRem == 0
            ? TvContractStatus.expired
            : (nextRem == 1
                ? TvContractStatus.expiringSoon
                : TvContractStatus.active);
        return c.copyWith(remainingYears: nextRem, status: nextStatus);
      }).toList(growable: false);

      final assessment = race.evaluateUciPrestige();
      return race.copyWith(
        prestigeScore: assessment.calculatedPrestigeScore,
        consecutivelyHeldYears: race.consecutivelyHeldYears + 1,
        hostCityContracts: updatedHostContracts,
        tvRightsContracts: updatedTvContracts,
      );
    }).toList(growable: false);

    if (ledger.annualOperatingOverheadEur > 0) {
      ledger = ledger.recordTransaction(
        OrganizerLedgerEntry(
          entryId: 'tx_overhead_$seasonYear',
          description: 'Koszty operacyjne centrali i personelu ($syndicateName)',
          category: OrganizerCashflowCategory.operatingOverhead,
          amountEur: ledger.annualOperatingOverheadEur,
          seasonYear: seasonYear,
        ),
      );
    }

    return copyWith(
      seasonYear: nextYear,
      budgetLedger: ledger,
      managedRaces: updatedRaces,
    );
  }

  /// Gotowy zestaw startowy dla trybu ASO / Grand Tour (2.UWT).
  factory RaceOrganizerEmpireModel.createStarterAsoPreset({
    int seasonYear = 2026,
  }) {
    return RaceOrganizerEmpireModel(
      organizerId: 'org_aso_global',
      syndicateName: 'Amaury Cycling Syndicate (ASO)',
      archetype: OrganizerSyndicateArchetype.asoGrandTourGiant,
      headquartersCountryCode: 'FR',
      seasonYear: seasonYear,
      uciBoardInfluence: 88.0,
      budgetLedger: const OrganizerBudgetLedger(
        liquidCashEur: 28500000,
        reserveFundEur: 12000000,
        annualOperatingOverheadEur: 14500000,
        prizePoolCommitmentEur: 2650000,
        appearanceFeesAllocatedEur: 1800000,
        safetyInfrastructureBudgetEur: 2400000,
      ),
      managedRaces: [
        ManagedRacePortfolioItem(
          raceId: 'race_grande_boucle_2uwt',
          raceName: 'Tour de France',
          countryCode: 'FR',
          tier: UciRaceClassificationTier.grandTour,
          stageCount: 21,
          prestigeScore: 98.5,
          globalViewershipIndex: 97.0,
          courseQualityScore: 94.0,
          safetyRatingScore: 89.0,
          starPowerScore: 96.0,
          uciComplianceScore: 95.0,
          titleSponsorName: 'LCL & Škoda',
          titleSponsorAnnualEur: 18500000,
          prizePoolEur: 2300000,
          consecutivelyHeldYears: 113,
          hostCityContracts: [
            HostCityContract(
              contractId: 'hc_gd_barcelona',
              raceId: 'race_grande_boucle_2uwt',
              cityName: 'Barcelona',
              countryCode: 'ES',
              role: HostBidRole.grandDepart,
              stageNumber: 1,
              agreedFeeEur: 6200000,
              infrastructureGrantEur: 1800000,
              signedSeasonYear: seasonYear,
              contractLengthYears: 1,
              remainingYears: 1,
              satisfactionScore: 92.0,
            ),
          ],
          tvRightsContracts: [
            TvRightsContract(
              contractId: 'tv_france_tv',
              raceId: 'race_grande_boucle_2uwt',
              broadcasterName: 'France Télévisions',
              territory: TvRightsTerritory.franceBenelux,
              tier: TvBroadcastTier.freeToAirNational,
              status: TvContractStatus.active,
              annualRightsFeeEur: 24000000,
              viewershipBonusPerMillionEur: 450000,
              estimatedAvgViewersMillions: 4.2,
              minimumLiveHoursPerStage: 5.5,
              helicopterRelayRequired: true,
              onboardCamerasRequired: true,
              startSeasonYear: seasonYear - 1,
              durationYears: 5,
              remainingYears: 4,
            ),
          ],
        ),
        const ManagedRacePortfolioItem(
          raceId: 'race_dauphine_2uwt',
          raceName: 'Critérium du Dauphiné',
          countryCode: 'FR',
          tier: UciRaceClassificationTier.uci2Uwt,
          stageCount: 8,
          prestigeScore: 86.0,
          globalViewershipIndex: 78.0,
          courseQualityScore: 85.0,
          safetyRatingScore: 84.0,
          starPowerScore: 88.0,
          uciComplianceScore: 91.0,
          titleSponsorName: 'Alpecin-Deceuninck Partner',
          titleSponsorAnnualEur: 2400000,
          prizePoolEur: 320000,
          consecutivelyHeldYears: 78,
        ),
      ],
      pendingHostCityBids: const [
        HostCityBid(
          bidId: 'bid_alpe_dhuez_s19',
          raceId: 'race_grande_boucle_2uwt',
          cityName: 'Alpe d\'Huez',
          countryCode: 'FR',
          regionName: 'Auvergne-Rhône-Alpes',
          role: HostBidRole.mountainSummitFinish,
          targetStageNumber: 19,
          bidFeeEur: 1850000,
          localInfrastructureGrantEur: 650000,
          hospitalityRevenuePotentialEur: 920000,
          tourismExposureDemand: 94.0,
          terrainFitScore: 98.0,
          politicalStabilityIndex: 95.0,
          crowdTurnoutForecast: 450000,
          deadlineDay: 45,
        ),
        HostCityBid(
          bidId: 'bid_grenoble_s1',
          raceId: 'race_dauphine_2uwt',
          cityName: 'Grenoble',
          countryCode: 'FR',
          regionName: 'Isère',
          role: HostBidRole.stageStart,
          targetStageNumber: 1,
          bidFeeEur: 340000,
          localInfrastructureGrantEur: 120000,
          hospitalityRevenuePotentialEur: 190000,
          tourismExposureDemand: 72.0,
          terrainFitScore: 84.0,
          politicalStabilityIndex: 90.0,
          crowdTurnoutForecast: 45000,
          deadlineDay: 30,
        ),
      ],
    );
  }

  RaceOrganizerEmpireModel copyWith({
    String? organizerId,
    String? syndicateName,
    OrganizerSyndicateArchetype? archetype,
    String? headquartersCountryCode,
    int? seasonYear,
    double? uciBoardInfluence,
    OrganizerBudgetLedger? budgetLedger,
    List<ManagedRacePortfolioItem>? managedRaces,
    List<HostCityBid>? pendingHostCityBids,
  }) {
    return RaceOrganizerEmpireModel(
      organizerId: organizerId ?? this.organizerId,
      syndicateName: syndicateName ?? this.syndicateName,
      archetype: archetype ?? this.archetype,
      headquartersCountryCode:
          headquartersCountryCode ?? this.headquartersCountryCode,
      seasonYear: seasonYear ?? this.seasonYear,
      uciBoardInfluence: uciBoardInfluence ?? this.uciBoardInfluence,
      budgetLedger: budgetLedger ?? this.budgetLedger,
      managedRaces: managedRaces ?? this.managedRaces,
      pendingHostCityBids: pendingHostCityBids ?? this.pendingHostCityBids,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organizerId': organizerId,
      'syndicateName': syndicateName,
      'archetype': archetype.toJson(),
      'headquartersCountryCode': headquartersCountryCode,
      'seasonYear': seasonYear,
      'uciBoardInfluence': uciBoardInfluence,
      'budgetLedger': budgetLedger.toJson(),
      'managedRaces':
          managedRaces.map((e) => e.toJson()).toList(growable: false),
      'pendingHostCityBids':
          pendingHostCityBids.map((e) => e.toJson()).toList(growable: false),
    };
  }

  factory RaceOrganizerEmpireModel.fromJson(Map<String, dynamic> json) {
    final racesRaw = json['managedRaces'] as List<dynamic>? ?? const [];
    final bidsRaw = json['pendingHostCityBids'] as List<dynamic>? ?? const [];

    return RaceOrganizerEmpireModel(
      organizerId: json['organizerId'] as String? ?? 'org_unknown',
      syndicateName: json['syndicateName'] as String? ?? 'Race Syndicate',
      archetype: OrganizerSyndicateArchetype.fromJson(
        json['archetype'] as String? ?? 'independentProSeries',
      ),
      headquartersCountryCode:
          json['headquartersCountryCode'] as String? ?? 'FR',
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      uciBoardInfluence:
          (json['uciBoardInfluence'] as num?)?.toDouble() ?? 50.0,
      budgetLedger: OrganizerBudgetLedger.fromJson(
        json['budgetLedger'] as Map<String, dynamic>? ?? const {},
      ),
      managedRaces: racesRaw
          .whereType<Map<String, dynamic>>()
          .map(ManagedRacePortfolioItem.fromJson)
          .toList(growable: false),
      pendingHostCityBids: bidsRaw
          .whereType<Map<String, dynamic>>()
          .map(HostCityBid.fromJson)
          .toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RaceOrganizerEmpireModel &&
          runtimeType == other.runtimeType &&
          organizerId == other.organizerId &&
          syndicateName == other.syndicateName &&
          archetype == other.archetype &&
          headquartersCountryCode == other.headquartersCountryCode &&
          seasonYear == other.seasonYear &&
          uciBoardInfluence == other.uciBoardInfluence &&
          budgetLedger == other.budgetLedger &&
          _listEquals(managedRaces, other.managedRaces) &&
          _listEquals(pendingHostCityBids, other.pendingHostCityBids);

  @override
  int get hashCode => Object.hash(
        organizerId,
        syndicateName,
        archetype,
        headquartersCountryCode,
        seasonYear,
        uciBoardInfluence,
        budgetLedger,
        Object.hashAll(managedRaces),
        Object.hashAll(pendingHostCityBids),
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
