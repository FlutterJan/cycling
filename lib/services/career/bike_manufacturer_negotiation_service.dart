import 'dart:math' as math;
import '../../models/career/career_save.dart';
import '../../models/equipment/complete_bike.dart';
import '../../models/equipment/frame_model.dart';
import '../../models/team/bike_manufacturer_deal.dart';
import '../../models/team/cycling_team.dart';
import '../generators/fictional_brands_catalog.dart';

/// Szczebel relacji i formuła współpracy z producentem rowerów i komponentów.
enum ManufacturerDealTier {
  /// Zakup sprzętu ze zniżką flotową (Dywizja Continental / małe budżety)
  discountPurchase,

  /// Darmowa pula rowerów wyścigowych na sezon bez dopłaty gotówkowej (Dywizja ProTeam)
  freeEquipmentQuota,

  /// Pełny sponsoring fabryczny z wielomilionową dopłatą gotówkową i R&D (Dywizja WorldTour)
  factoryWorksSponsorship;

  String toJson() => name;

  static ManufacturerDealTier fromJson(String value) {
    return ManufacturerDealTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ManufacturerDealTier.discountPurchase,
    );
  }

  String get label {
    switch (this) {
      case ManufacturerDealTier.discountPurchase:
        return 'Zakup ze Zniżką Flotową (Continental)';
      case ManufacturerDealTier.freeEquipmentQuota:
        return 'Darmowa Pula Sprzętu (ProTeam)';
      case ManufacturerDealTier.factoryWorksSponsorship:
        return 'Sponsoring Fabryczny Works (WorldTour)';
    }
  }

  String get description {
    switch (this) {
      case ManufacturerDealTier.discountPurchase:
        return 'Zespół kupuje ramy i osprzęt ze zniżką 30-55%. Tańsze lub cięższe ramy od mniejszych marek.';
      case ManufacturerDealTier.freeEquipmentQuota:
        return 'Producent dostarcza pełną flotę bezpłatnych rowerów wyścigowych na sezon (35-65 sztuk).';
      case ManufacturerDealTier.factoryWorksSponsorship:
        return 'Elitarny status fabryczny: 90-130 darmowych maszyn oraz miliony euro dopłaty do budżetu rocznego.';
    }
  }
}

/// Spersonalizowana oferta współpracy technicznej dostępna na rynku producentów.
class ManufacturerOfferOption {
  final String brandId;
  final String brandName;
  final int brandPrestige; // 1-5 gwiazdek
  final String countryIso;
  final ManufacturerDealTier dealTier;
  final int annualCashContributionEur; // Dodatni dla WorldTour, 0 dla Continental
  final int teamPurchaseCostEur; // Koszt zakupu ponoszony przez zespół (Continental)
  final double discountRate; // np. 0.45 dla 45% zniżki
  final int freeBikesQuota;
  final int rdLevel; // 1-100
  final List<String> suppliedFrameIds;
  final List<String> suppliedWheelsetIds;
  final int contractDurationYears;
  final int minimumUciRanking;
  final bool isApplicableForPlayer;
  final String pitchDescription;

  const ManufacturerOfferOption({
    required this.brandId,
    required this.brandName,
    required this.brandPrestige,
    required this.countryIso,
    required this.dealTier,
    required this.annualCashContributionEur,
    required this.teamPurchaseCostEur,
    required this.discountRate,
    required this.freeBikesQuota,
    required this.rdLevel,
    required this.suppliedFrameIds,
    required this.suppliedWheelsetIds,
    required this.contractDurationYears,
    required this.minimumUciRanking,
    required this.isApplicableForPlayer,
    required this.pitchDescription,
  });

  Map<String, dynamic> toJson() {
    return {
      'brandId': brandId,
      'brandName': brandName,
      'brandPrestige': brandPrestige,
      'countryIso': countryIso,
      'dealTier': dealTier.toJson(),
      'annualCashContributionEur': annualCashContributionEur,
      'teamPurchaseCostEur': teamPurchaseCostEur,
      'discountRate': discountRate,
      'freeBikesQuota': freeBikesQuota,
      'rdLevel': rdLevel,
      'suppliedFrameIds': suppliedFrameIds,
      'suppliedWheelsetIds': suppliedWheelsetIds,
      'contractDurationYears': contractDurationYears,
      'minimumUciRanking': minimumUciRanking,
      'isApplicableForPlayer': isApplicableForPlayer,
      'pitchDescription': pitchDescription,
    };
  }

  factory ManufacturerOfferOption.fromJson(Map<String, dynamic> json) {
    return ManufacturerOfferOption(
      brandId: json['brandId'] as String,
      brandName: json['brandName'] as String,
      brandPrestige: (json['brandPrestige'] as num).toInt(),
      countryIso: json['countryIso'] as String,
      dealTier: ManufacturerDealTier.fromJson(json['dealTier'] as String),
      annualCashContributionEur: (json['annualCashContributionEur'] as num).toInt(),
      teamPurchaseCostEur: (json['teamPurchaseCostEur'] as num).toInt(),
      discountRate: (json['discountRate'] as num).toDouble(),
      freeBikesQuota: (json['freeBikesQuota'] as num).toInt(),
      rdLevel: (json['rdLevel'] as num).toInt(),
      suppliedFrameIds: (json['suppliedFrameIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      suppliedWheelsetIds: (json['suppliedWheelsetIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      contractDurationYears: (json['contractDurationYears'] as num).toInt(),
      minimumUciRanking: (json['minimumUciRanking'] as num).toInt(),
      isApplicableForPlayer: json['isApplicableForPlayer'] as bool,
      pitchDescription: json['pitchDescription'] as String,
    );
  }

  @override
  String toString() =>
      'ManufacturerOfferOption($brandName, ${dealTier.name}, €$annualCashContributionEur/rok, Prestige: $brandPrestige★)';
}

/// Propozycja kontraktowa składana przez menedżera drużyny producentowi rowerów.
class ManufacturerNegotiationProposal {
  final String brandId;
  final ManufacturerDealTier requestedDealTier;
  final int contractYears;
  final int requestedAnnualCashEur;
  final int requestedBikesCount;
  final double proposedPurchaseDiscountRate;
  final bool windTunnelCommitment;

  const ManufacturerNegotiationProposal({
    required this.brandId,
    required this.requestedDealTier,
    required this.contractYears,
    required this.requestedAnnualCashEur,
    required this.requestedBikesCount,
    required this.proposedPurchaseDiscountRate,
    required this.windTunnelCommitment,
  });

  Map<String, dynamic> toJson() {
    return {
      'brandId': brandId,
      'requestedDealTier': requestedDealTier.toJson(),
      'contractYears': contractYears,
      'requestedAnnualCashEur': requestedAnnualCashEur,
      'requestedBikesCount': requestedBikesCount,
      'proposedPurchaseDiscountRate': proposedPurchaseDiscountRate,
      'windTunnelCommitment': windTunnelCommitment,
    };
  }

  factory ManufacturerNegotiationProposal.fromJson(Map<String, dynamic> json) {
    return ManufacturerNegotiationProposal(
      brandId: json['brandId'] as String,
      requestedDealTier:
          ManufacturerDealTier.fromJson(json['requestedDealTier'] as String),
      contractYears: (json['contractYears'] as num).toInt(),
      requestedAnnualCashEur: (json['requestedAnnualCashEur'] as num).toInt(),
      requestedBikesCount: (json['requestedBikesCount'] as num).toInt(),
      proposedPurchaseDiscountRate:
          (json['proposedPurchaseDiscountRate'] as num).toDouble(),
      windTunnelCommitment: json['windTunnelCommitment'] as bool,
    );
  }
}

/// Status decyzji zarządu i dyrekcji handlowej producenta sprzętu.
enum ManufacturerDecisionStatus {
  accepted,
  counterOffer,
  rejected;

  String toJson() => name;

  static ManufacturerDecisionStatus fromJson(String value) {
    return ManufacturerDecisionStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ManufacturerDecisionStatus.rejected,
    );
  }
}

/// Rezultat negocjacji kontraktu technicznego z producentem.
class ManufacturerNegotiationResult {
  final ManufacturerDecisionStatus status;
  final double overallScore; // 0.0 - 100.0 pkt
  final String commercialDirectorQuote;
  final String? rejectionReason;
  final BikeManufacturerDeal? resultingDeal;
  final ManufacturerDealTier resultingDealTier;
  final int finalPurchaseCostEur;

  // Cząstkowa ocena filarów negocjacyjnych
  final double divisionFitScore; // Waga 35%
  final double teamPrestigeScore; // Waga 30%
  final double financialRealismScore; // Waga 25%
  final double rdSynergyScore; // Waga 10%

  const ManufacturerNegotiationResult({
    required this.status,
    required this.overallScore,
    required this.commercialDirectorQuote,
    this.rejectionReason,
    this.resultingDeal,
    required this.resultingDealTier,
    required this.finalPurchaseCostEur,
    required this.divisionFitScore,
    required this.teamPrestigeScore,
    required this.financialRealismScore,
    required this.rdSynergyScore,
  });

  bool get isAccepted => status == ManufacturerDecisionStatus.accepted;
  bool get isCounterOffer => status == ManufacturerDecisionStatus.counterOffer;
  bool get isRejected => status == ManufacturerDecisionStatus.rejected;

  Map<String, dynamic> toJson() {
    return {
      'status': status.toJson(),
      'overallScore': overallScore,
      'commercialDirectorQuote': commercialDirectorQuote,
      'rejectionReason': rejectionReason,
      'resultingDeal': resultingDeal?.toJson(),
      'resultingDealTier': resultingDealTier.toJson(),
      'finalPurchaseCostEur': finalPurchaseCostEur,
      'divisionFitScore': divisionFitScore,
      'teamPrestigeScore': teamPrestigeScore,
      'financialRealismScore': financialRealismScore,
      'rdSynergyScore': rdSynergyScore,
    };
  }

  factory ManufacturerNegotiationResult.fromJson(Map<String, dynamic> json) {
    return ManufacturerNegotiationResult(
      status: ManufacturerDecisionStatus.fromJson(json['status'] as String),
      overallScore: (json['overallScore'] as num).toDouble(),
      commercialDirectorQuote: json['commercialDirectorQuote'] as String,
      rejectionReason: json['rejectionReason'] as String?,
      resultingDeal: json['resultingDeal'] != null
          ? BikeManufacturerDeal.fromJson(
              json['resultingDeal'] as Map<String, dynamic>)
          : null,
      resultingDealTier:
          ManufacturerDealTier.fromJson(json['resultingDealTier'] as String),
      finalPurchaseCostEur: (json['finalPurchaseCostEur'] as num).toInt(),
      divisionFitScore: (json['divisionFitScore'] as num).toDouble(),
      teamPrestigeScore: (json['teamPrestigeScore'] as num).toDouble(),
      financialRealismScore: (json['financialRealismScore'] as num).toDouble(),
      rdSynergyScore: (json['rdSynergyScore'] as num).toDouble(),
    );
  }
}

/// Rodzaje wspólnych kampanii badawczo-rozwojowych (R&D) w tunelu aerodynamicznym.
enum WindTunnelCampaignType {
  /// Cyfrowe modelowanie CFD opływu powietrza wokół ramy i widelca
  virtualCfdAeroModeling,

  /// Integracja monokokowego kokpitu aero i wewnętrzne prowadzenie przewodów
  integratedCockpitAndAeroShaping,

  /// Kompleksowa sesja tunelu aerodynamicznego dla maszyn TT i kasków łzawicowych
  ttSuperbikeAndHelmetAeroOptimization,

  /// Fabryczny program prototypowy Works: formy z włókna T1100 i redukcja oporu bocznego
  factoryWorksAeroEvolution;

  String toJson() => name;

  static WindTunnelCampaignType fromJson(String value) {
    return WindTunnelCampaignType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WindTunnelCampaignType.virtualCfdAeroModeling,
    );
  }

  String get title {
    switch (this) {
      case WindTunnelCampaignType.virtualCfdAeroModeling:
        return 'Modelowanie CFD i Symulacja Opływu Powietrza';
      case WindTunnelCampaignType.integratedCockpitAndAeroShaping:
        return 'Zintegrowany Kokpit Monocoque i Wewnętrzne Przewody';
      case WindTunnelCampaignType.ttSuperbikeAndHelmetAeroOptimization:
        return 'Ewolucja Maszyny Czasowej TT i Kasków Aero';
      case WindTunnelCampaignType.factoryWorksAeroEvolution:
        return 'Fabryczny Program Prototypowy Works (Włókna T1100)';
    }
  }

  int get baseCostEur {
    switch (this) {
      case WindTunnelCampaignType.virtualCfdAeroModeling:
        return 48000;
      case WindTunnelCampaignType.integratedCockpitAndAeroShaping:
        return 135000;
      case WindTunnelCampaignType.ttSuperbikeAndHelmetAeroOptimization:
        return 290000;
      case WindTunnelCampaignType.factoryWorksAeroEvolution:
        return 580000;
    }
  }

  int get durationDays {
    switch (this) {
      case WindTunnelCampaignType.virtualCfdAeroModeling:
        return 14;
      case WindTunnelCampaignType.integratedCockpitAndAeroShaping:
        return 21;
      case WindTunnelCampaignType.ttSuperbikeAndHelmetAeroOptimization:
        return 30;
      case WindTunnelCampaignType.factoryWorksAeroEvolution:
        return 45;
    }
  }

  /// Zysk aerodynamiczny (obniżenie współczynnika CdA ramy/kasku)
  double get cdaReduction {
    switch (this) {
      case WindTunnelCampaignType.virtualCfdAeroModeling:
        return 0.0035;
      case WindTunnelCampaignType.integratedCockpitAndAeroShaping:
        return 0.0070;
      case WindTunnelCampaignType.ttSuperbikeAndHelmetAeroOptimization:
        return 0.0135;
      case WindTunnelCampaignType.factoryWorksAeroEvolution:
        return 0.0185;
    }
  }

  /// Zysk na masie ramy (w gramach)
  int get weightReductionGrams {
    switch (this) {
      case WindTunnelCampaignType.virtualCfdAeroModeling:
        return 0;
      case WindTunnelCampaignType.integratedCockpitAndAeroShaping:
        return 25;
      case WindTunnelCampaignType.ttSuperbikeAndHelmetAeroOptimization:
        return 40;
      case WindTunnelCampaignType.factoryWorksAeroEvolution:
        return 75;
    }
  }

  /// Wymagany minimalny poziom tunelu aerodynamicznego w bazie drużyny
  int get minWindTunnelLevel {
    switch (this) {
      case WindTunnelCampaignType.virtualCfdAeroModeling:
        return 0;
      case WindTunnelCampaignType.integratedCockpitAndAeroShaping:
        return 1;
      case WindTunnelCampaignType.ttSuperbikeAndHelmetAeroOptimization:
        return 2;
      case WindTunnelCampaignType.factoryWorksAeroEvolution:
        return 3;
    }
  }

  /// Wymagany minimalny prestiż marki (gwiazdki)
  int get minBrandPrestige {
    switch (this) {
      case WindTunnelCampaignType.virtualCfdAeroModeling:
        return 1;
      case WindTunnelCampaignType.integratedCockpitAndAeroShaping:
        return 2;
      case WindTunnelCampaignType.ttSuperbikeAndHelmetAeroOptimization:
        return 3;
      case WindTunnelCampaignType.factoryWorksAeroEvolution:
        return 4;
    }
  }

  String get description {
    switch (this) {
      case WindTunnelCampaignType.virtualCfdAeroModeling:
        return 'Cyfrowa analiza CFD w klastrze obliczeniowym producenta. Precyzyjne wygładzenie stref wirów za widelcem i suportem.';
      case WindTunnelCampaignType.integratedCockpitAndAeroShaping:
        return 'Sesja z manekinem kolarza, integracja kierownicy z mostkiem w jeden profil i całkowite schowanie przewodów hydraulicznych.';
      case WindTunnelCampaignType.ttSuperbikeAndHelmetAeroOptimization:
        return 'Zaawansowane testy w pełnoskalowym tunelu aerodynamicznym dla rowerów czasowych TT oraz optymalizacja kształtu kasków łzawicowych.';
      case WindTunnelCampaignType.factoryWorksAeroEvolution:
        return 'Formy węglowe z kompozytu klasy kosmicznej Toray T1100, redukcja masy ramy o 75g i wybitna aerodynamika przy kącie wiatru 15°.';
    }
  }
}

/// Raport techniczny po przeprowadzeniu wspólnych testów w tunelu aerodynamicznym.
class WindTunnelTestReport {
  final WindTunnelCampaignType campaignType;
  final bool isSuccess;
  final double cdaDelta;
  final int weightDeltaGrams;
  final int costEur;
  final String chiefAerodynamicistQuote;
  final List<String> upgradedFrameNames;
  final DateTime date;

  const WindTunnelTestReport({
    required this.campaignType,
    required this.isSuccess,
    required this.cdaDelta,
    required this.weightDeltaGrams,
    required this.costEur,
    required this.chiefAerodynamicistQuote,
    required this.upgradedFrameNames,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'campaignType': campaignType.toJson(),
      'isSuccess': isSuccess,
      'cdaDelta': cdaDelta,
      'weightDeltaGrams': weightDeltaGrams,
      'costEur': costEur,
      'chiefAerodynamicistQuote': chiefAerodynamicistQuote,
      'upgradedFrameNames': upgradedFrameNames,
      'date': date.toIso8601String(),
    };
  }

  factory WindTunnelTestReport.fromJson(Map<String, dynamic> json) {
    return WindTunnelTestReport(
      campaignType:
          WindTunnelCampaignType.fromJson(json['campaignType'] as String),
      isSuccess: json['isSuccess'] as bool,
      cdaDelta: (json['cdaDelta'] as num).toDouble(),
      weightDeltaGrams: (json['weightDeltaGrams'] as num).toInt(),
      costEur: (json['costEur'] as num).toInt(),
      chiefAerodynamicistQuote: json['chiefAerodynamicistQuote'] as String,
      upgradedFrameNames: (json['upgradedFrameNames'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      date: DateTime.parse(json['date'] as String),
    );
  }
}

/// Zaawansowany serwis negocjacji z producentami rowerów i osprzętu oraz wspólnego tunelu aerodynamicznego R&D.
class BikeManufacturerNegotiationService {
  BikeManufacturerNegotiationService._();

  // ===========================================================================
  // 1. GENEROWANIE OFERT RYNKOWYCH DLA DYWIZJI ZESPOŁU (MARKET OFFERS)
  // ===========================================================================

  /// Zwraca oferty dopasowane do aktualnej dywizji i pozycji rankingowej zespołu gracza.
  ///
  /// - Continental: małe budżety muszą kupować ramy ze zniżką lub brać cięższe konstrukcje.
  /// - ProTeam: darmowa pula rowerów i umiarkowane wsparcie gotówkowe.
  /// - WorldTour: topowi producenci oferują 90-130 darmowych maszyn i miliony euro dopłaty do budżetu!
  static List<ManufacturerOfferOption> getAvailableManufacturerOffers(
      CareerSave save) {
    final playerTeam = save.playerTeam;
    final int uciPoints = playerTeam.uciPointsSeason;
    final List<ManufacturerOfferOption> offers = [];

    for (final brand in FictionalBrandsCatalog.allBrands) {
      ManufacturerDealTier tier;
      int cashContribution = 0;
      int purchaseCost = 0;
      double discount = 0.0;
      int freeBikes = 0;
      bool isApplicable = true;
      String pitchDesc = '';

      switch (playerTeam.division) {
        case TeamDivision.continental:
          if (brand.prestige >= 5) {
            // Topowe marki WorldTour (np. Aethel, Veloce, Kronos) nie dają darmowych rowerów Continental!
            tier = ManufacturerDealTier.discountPurchase;
            discount = 0.30; // Zniżka 30%
            purchaseCost = 95000;
            cashContribution = 0;
            freeBikes = 0;
            pitchDesc =
                'Prestiżowa manufaktura oferuje zakup ram ze zniżką flotową 30%. Zespół musi sfinansować sprzęt z budżetu.';
          } else if (brand.prestige >= 3) {
            // Średnie marki
            tier = ManufacturerDealTier.discountPurchase;
            discount = 0.45; // Zniżka 45%
            purchaseCost = 55000;
            cashContribution = 0;
            freeBikes = 0;
            pitchDesc =
                'Solidna marka sprzętowa oferuje pakiet ze zniżką 45%. Ramy wyścigowe o bardzo dobrym stosunku sztywności do ceny.';
          } else {
            // Mniejsze/budżetowe firmy (prestige 1-2, np. cięższe ramy 1050g)
            tier = ManufacturerDealTier.freeEquipmentQuota;
            discount = 1.0;
            purchaseCost = 0;
            cashContribution = 0;
            freeBikes = 18; // Mała pula darmowych rowerów
            pitchDesc =
                'Mniejszy producent dostarcza 18 darmowych kompletnych rowerów. Konstrukcje są nieco cięższe (+250g), lecz nie obciążają budżetu.';
          }
          break;

        case TeamDivision.proTeam:
          if (brand.prestige >= 5) {
            tier = ManufacturerDealTier.freeEquipmentQuota;
            freeBikes = 45;
            cashContribution = 150000;
            pitchDesc =
                'Topowa marka dostarcza 45 darmowych rowerów z symboliczną dopłatą promocyjną €150k. Wymaga walki o dzikie karty na Grand Toury.';
          } else if (brand.prestige >= 3) {
            tier = ManufacturerDealTier.factoryWorksSponsorship;
            freeBikes = 60;
            cashContribution = 550000;
            pitchDesc =
                'Ambitny producent oferuje pełną flotę 60 maszyn oraz solidny zastrzyk gotówki €550k/rok za ekspozycję w ProSeries.';
          } else {
            tier = ManufacturerDealTier.factoryWorksSponsorship;
            freeBikes = 65;
            cashContribution = 750000;
            pitchDesc =
                'Mniejsza marka oferuje status głównego partnera technicznego, 65 rowerów oraz aż €750k/rok dopłaty do budżetu.';
          }
          break;

        case TeamDivision.worldTour:
          // W elicie producenci sami walczą o podpis zespołu i dopłacają miliony euro!
          tier = ManufacturerDealTier.factoryWorksSponsorship;
          if (brand.prestige >= 5) {
            freeBikes = 110;
            cashContribution = 3200000; // €3.2M rocznie do budżetu!
            pitchDesc =
                'Elitarny kontrakt fabryczny: 110 topowych maszyn Aero, Climbing i TT oraz potężne €3.20M rocznie wypłacane do budżetu drużyny!';
          } else if (brand.prestige >= 4) {
            freeBikes = 100;
            cashContribution = 2400000; // €2.4M rocznie
            pitchDesc =
                'Sponsoring fabryczny: 100 rowerów najwyższej specyfikacji, pełny dostęp do R&D oraz €2.40M rocznej dopłaty gotówkowej.';
          } else {
            freeBikes = 90;
            cashContribution = 1800000;
            pitchDesc =
                'Partnerstwo fabryczne: 90 kompletnych rowerów oraz €1.80M rocznie. Producent gwarantuje priorytet w tunelu aerodynamicznym.';
          }
          break;
      }

      final int minRanking = playerTeam.division == TeamDivision.worldTour
          ? 18
          : (playerTeam.division == TeamDivision.proTeam ? 35 : 65);

      offers.add(
        ManufacturerOfferOption(
          brandId: brand.id,
          brandName: brand.name,
          brandPrestige: brand.prestige,
          countryIso: brand.countryIso,
          dealTier: tier,
          annualCashContributionEur: cashContribution,
          teamPurchaseCostEur: purchaseCost,
          discountRate: discount,
          freeBikesQuota: freeBikes,
          rdLevel: (brand.prestige * 18) + 10,
          suppliedFrameIds: brand.frames.map((f) => f.id).toList(),
          suppliedWheelsetIds: brand.wheelsets.map((w) => w.id).toList(),
          contractDurationYears: 2,
          minimumUciRanking: minRanking,
          isApplicableForPlayer: isApplicable,
          pitchDescription: pitchDesc,
        ),
      );
    }

    return offers;
  }

  // ===========================================================================
  // 2. NEGOCJACJE I OCENA PROPOZYCJI KONTRAKTOWEJ (EVALUATE PROPOSAL)
  // ===========================================================================

  /// Przeprowadza ocenę propozycji menedżera przez zarząd producenta sprzętu.
  static ManufacturerNegotiationResult evaluateProposal({
    required CareerSave currentSave,
    required ManufacturerNegotiationProposal proposal,
  }) {
    final playerTeam = currentSave.playerTeam;
    final brand = FictionalBrandsCatalog.getBrand(proposal.brandId) ??
        FictionalBrandsCatalog.allBrands.first;

    // -------------------------------------------------------------------------
    // FILAR 1: DOPASOWANIE DYWIZJI (Waga 35%)
    // -------------------------------------------------------------------------
    double divisionFitScore = 20.0;

    if (playerTeam.division == TeamDivision.continental) {
      if (brand.prestige >= 5) {
        if (proposal.requestedDealTier ==
                ManufacturerDealTier.factoryWorksSponsorship ||
            proposal.requestedAnnualCashEur > 0) {
          // BŁĄD NEGOCJACYJNY: Zespół Continental żądający milionów od Aethel/Veloce!
          return ManufacturerNegotiationResult(
            status: ManufacturerDecisionStatus.rejected,
            overallScore: 22.0,
            commercialDirectorQuote:
                'Z całym szacunkiem, nasza manufaktura dostarcza rowery dla zwycięzców Tour de France. Drużyna z trzeciej ligi Continental nie może liczyć na darmowy sponsoring fabryczny ani milionowe dopłaty.',
            rejectionReason:
                'Zbyt niski szczebel rozgrywkowy (Continental) wobec prestiżu 5★ marki.',
            resultingDealTier: proposal.requestedDealTier,
            finalPurchaseCostEur: 0,
            divisionFitScore: 5.0,
            teamPrestigeScore: 8.0,
            financialRealismScore: 5.0,
            rdSynergyScore: 4.0,
          );
        } else if (proposal.requestedDealTier ==
            ManufacturerDealTier.discountPurchase) {
          divisionFitScore = 32.0; // Zaakceptowano zakup ze zniżką
        }
      } else {
        divisionFitScore = 30.0;
      }
    } else if (playerTeam.division == TeamDivision.proTeam) {
      divisionFitScore = brand.prestige <= 4 ? 35.0 : 28.0;
    } else {
      // WorldTour
      divisionFitScore = 35.0; // Topowa elita pasuje do każdej marki
    }

    // -------------------------------------------------------------------------
    // FILAR 2: PRESTIŻ I PUNKTY UCI ZESPOŁU (Waga 30%)
    // -------------------------------------------------------------------------
    double teamPrestigeScore = 15.0;
    final int uciPoints = playerTeam.uciPointsSeason;

    if (playerTeam.division == TeamDivision.worldTour) {
      teamPrestigeScore = 24.0 + (uciPoints / 1200.0).clamp(0.0, 6.0);
    } else if (playerTeam.division == TeamDivision.proTeam) {
      teamPrestigeScore = 16.0 + (uciPoints / 600.0).clamp(0.0, 8.0);
    } else {
      teamPrestigeScore = 12.0 + (uciPoints / 250.0).clamp(0.0, 8.0);
    }

    // Dodatkowy bonus za posiadanie w kadrze supergwiazdy (W/kg > 5.9 lub sprint > 1600W)
    final bool hasStarRider = currentSave.playerRoster.any((r) =>
        (r.physiology.criticalPowerWatts / r.physiology.weightKg) >= 5.9 ||
        r.powerProfile.p5sWatts >= 1600);
    if (hasStarRider) {
      teamPrestigeScore = (teamPrestigeScore + 4.0).clamp(0.0, 30.0);
    }

    // -------------------------------------------------------------------------
    // FILAR 3: REALIZM FINANSOWY I ŻĄDANYCH ROWERÓW (Waga 25%)
    // -------------------------------------------------------------------------
    double financialScore = 15.0;
    int expectedCash = 0;
    int expectedBikes = 30;

    switch (playerTeam.division) {
      case TeamDivision.continental:
        expectedCash = 0;
        expectedBikes = 20;
        break;
      case TeamDivision.proTeam:
        expectedCash = (brand.prestige * 120000);
        expectedBikes = 50;
        break;
      case TeamDivision.worldTour:
        expectedCash = (brand.prestige * 650000);
        expectedBikes = 100;
        break;
    }

    if (proposal.requestedAnnualCashEur <= expectedCash &&
        proposal.requestedBikesCount <= expectedBikes + 15) {
      financialScore = 25.0;
    } else if (proposal.requestedAnnualCashEur <= expectedCash * 1.35) {
      financialScore = 17.0;
    } else {
      financialScore = 6.0;
    }

    // -------------------------------------------------------------------------
    // FILAR 4: SYNERGIA BADAWCZO-ROZWOJOWA R&D (Waga 10%)
    // -------------------------------------------------------------------------
    double rdSynergyScore = 4.0;
    if (proposal.windTunnelCommitment) rdSynergyScore += 3.0;
    if (currentSave.windTunnelLevel >= 2) rdSynergyScore += 3.0;

    // -------------------------------------------------------------------------
    // ŁĄCZNY WYNIK I DECYZJA
    // -------------------------------------------------------------------------
    final double overallScore = (divisionFitScore +
            teamPrestigeScore +
            financialScore +
            rdSynergyScore)
        .clamp(0.0, 100.0);

    // Wyliczenie kosztu początkowego zakupu
    int purchaseCost = 0;
    if (proposal.requestedDealTier == ManufacturerDealTier.discountPurchase) {
      final double discount = proposal.proposedPurchaseDiscountRate.clamp(0.20, 0.60);
      final int basePricePerBike = brand.prestige >= 5 ? 6500 : 3800;
      purchaseCost = (basePricePerBike * proposal.requestedBikesCount * (1.0 - discount)).round();
    }

    if (overallScore >= 68.0) {
      // 1. ZAAKCEPTOWANA
      final resultingDeal = BikeManufacturerDeal(
        manufacturerId: brand.id,
        manufacturerName: brand.name,
        prestigeLevel: brand.prestige,
        annualCashContributionEur: proposal.requestedAnnualCashEur,
        freeBikesQuota: proposal.requestedBikesCount,
        researchAndDevelopmentLevel: (brand.prestige * 18) + 12,
        suppliedFrameIds: brand.frames.map((f) => f.id).toList(),
        suppliedWheelsetIds: brand.wheelsets.map((w) => w.id).toList(),
        contractYearsLeft: proposal.contractYears,
        minimumUciRankingRequired: playerTeam.division == TeamDivision.worldTour ? 18 : 35,
      );

      final quote = playerTeam.division == TeamDivision.worldTour
          ? 'Nasz zarząd z dumą podpisuje tę umowę. Przekazujemy pełną flotę maszyn wyścigowych oraz przelewamy €${(proposal.requestedAnnualCashEur / 1000000).toStringAsFixed(2)}M rocznie do budżetu. Do zobaczenia na podium Tour de France!'
          : (proposal.requestedDealTier == ManufacturerDealTier.discountPurchase
              ? 'Akceptujemy warunki zakupu ze zniżką ${(proposal.proposedPurchaseDiscountRate * 100).round()}%. Wasza młodzieżowa kadra otrzyma profesjonalne ramy przygotowane do rywalizacji.'
              : 'Warunki zostały zaakceptowane. Dostarczamy ${proposal.requestedBikesCount} bezpłatnych rowerów wyścigowych na nadchodzący sezon!');

      return ManufacturerNegotiationResult(
        status: ManufacturerDecisionStatus.accepted,
        overallScore: overallScore,
        commercialDirectorQuote: quote,
        resultingDeal: resultingDeal,
        resultingDealTier: proposal.requestedDealTier,
        finalPurchaseCostEur: purchaseCost,
        divisionFitScore: divisionFitScore,
        teamPrestigeScore: teamPrestigeScore,
        financialRealismScore: financialScore,
        rdSynergyScore: rdSynergyScore,
      );
    } else if (overallScore >= 45.0) {
      // 2. KONTROFERTA
      final int counterCash = (expectedCash * 0.85 / 50000).round() * 50000;
      final int counterBikes = (expectedBikes * 0.90).round();

      final resultingDeal = BikeManufacturerDeal(
        manufacturerId: brand.id,
        manufacturerName: brand.name,
        prestigeLevel: brand.prestige,
        annualCashContributionEur: counterCash,
        freeBikesQuota: counterBikes,
        researchAndDevelopmentLevel: (brand.prestige * 18) + 10,
        suppliedFrameIds: brand.frames.map((f) => f.id).toList(),
        suppliedWheelsetIds: brand.wheelsets.map((w) => w.id).toList(),
        contractYearsLeft: proposal.contractYears,
        minimumUciRankingRequired: 20,
      );

      final quote =
          'Projekt jest obiecujący, jednak żądany budżet lub liczba rowerów przewyższają nasze ramy promocyjne. Oferujemy kontrofertę: $counterBikes maszyn wyścigowych oraz €${(counterCash / 1000000).toStringAsFixed(2)}M rocznie.';

      return ManufacturerNegotiationResult(
        status: ManufacturerDecisionStatus.counterOffer,
        overallScore: overallScore,
        commercialDirectorQuote: quote,
        resultingDeal: resultingDeal,
        resultingDealTier: proposal.requestedDealTier,
        finalPurchaseCostEur: purchaseCost,
        divisionFitScore: divisionFitScore,
        teamPrestigeScore: teamPrestigeScore,
        financialRealismScore: financialScore,
        rdSynergyScore: rdSynergyScore,
      );
    } else {
      // 3. ODRZUCENIE
      return ManufacturerNegotiationResult(
        status: ManufacturerDecisionStatus.rejected,
        overallScore: overallScore,
        commercialDirectorQuote:
            'Niestety, obecny profil marketingowy waszego zespołu nie uzasadnia alokacji naszych zasobów inżynieryjnych. Dziękujemy za rozmowy.',
        rejectionReason:
            'Niewystarczająca rozpoznawalność medialna lub nierealistyczne żądania budżetowe.',
        resultingDealTier: proposal.requestedDealTier,
        finalPurchaseCostEur: 0,
        divisionFitScore: divisionFitScore,
        teamPrestigeScore: teamPrestigeScore,
        financialRealismScore: financialScore,
        rdSynergyScore: rdSynergyScore,
      );
    }
  }

  // ===========================================================================
  // 3. PODPISANIE KONTRAKTU I DOSTARCZENIE FLOTY ROWERÓW (SIGN DEAL)
  // ===========================================================================

  /// Podpisuje oficjalny kontrakt z producentem, aktualizuje flotę rowerów i finanse klubu.
  static CareerSave signManufacturerDeal({
    required CareerSave currentSave,
    required BikeManufacturerDeal deal,
    required ManufacturerDealTier dealTier,
    int initialPurchaseCostEur = 0,
  }) {
    final playerTeam = currentSave.playerTeam;

    // 1. Składamy nową flotę rowerów wyścigowych z komponentów nowej marki
    final brandId = deal.manufacturerId;
    final List<CompleteBike> newFlotilla = [
      FictionalBrandsCatalog.assembleBike(
        brandId: brandId,
        frameCategory: FrameCategory.aero,
        cockpitWidthMm: 380,
        hoodInwardTiltDegrees: 12.0,
        slammedStem: true,
      ),
      FictionalBrandsCatalog.assembleBike(
        brandId: brandId,
        frameCategory: FrameCategory.lightweightClimbing,
        cockpitWidthMm: 400,
        hoodInwardTiltDegrees: 6.0,
        slammedStem: true,
      ),
      FictionalBrandsCatalog.assembleBike(
        brandId: brandId,
        frameCategory: FrameCategory.timeTrial,
        cockpitWidthMm: 380,
        hoodInwardTiltDegrees: 0.0,
        slammedStem: true,
      ),
    ];

    // 2. Obsługa finansowa
    int updatedCash = playerTeam.cashBalanceEur;
    List<CareerFinanceLedgerEntry> updatedLedger = currentSave.financeLedger;

    if (dealTier == ManufacturerDealTier.discountPurchase &&
        initialPurchaseCostEur > 0) {
      // Zespół kupuje rowery ze zniżką
      updatedCash -= initialPurchaseCostEur;
      final purchaseEntry = CareerFinanceLedgerEntry(
        id: 'bike_purch_${DateTime.now().millisecondsSinceEpoch}',
        date: currentSave.currentDate,
        category: FinanceCategory.equipmentUpgrade,
        amountEur: -initialPurchaseCostEur,
        description:
            'Zakup floty rowerów wyścigowych ze zniżką: ${deal.manufacturerName} (${deal.freeBikesQuota} sztuk)',
      );
      updatedLedger = [purchaseEntry, ...updatedLedger];
    } else if (deal.annualCashContributionEur > 0) {
      // Sponsoring fabryczny: pierwsza rata miesięczna wpływa od razu na konto
      final int upfrontTranche =
          (deal.annualCashContributionEur / 12.0).round();
      updatedCash += upfrontTranche;
      final incomeEntry = CareerFinanceLedgerEntry(
        id: 'bike_spons_${DateTime.now().millisecondsSinceEpoch}',
        date: currentSave.currentDate,
        category: FinanceCategory.sponsorPayout,
        amountEur: upfrontTranche,
        description:
            'Pierwsza transza sponsorska producenta rowerów: ${deal.manufacturerName}',
      );
      updatedLedger = [incomeEntry, ...updatedLedger];
    }

    // 3. Aktualizacja danych drużyny
    final updatedTeams = currentSave.teams.map((t) {
      if (t.id == currentSave.playerTeamId) {
        return t.copyWith(
          bikeDeal: deal,
          inventoryBikes: newFlotilla,
          cashBalanceEur: updatedCash,
        );
      }
      return t;
    }).toList();

    return currentSave.copyWith(
      teams: updatedTeams,
      financeLedger: updatedLedger,
      lastSavedAt: DateTime.now(),
    );
  }

  // ===========================================================================
  // 4. WSPÓLNE TESTY W TUNELU AERODYNAMICZNYM (WIND TUNNEL R&D)
  // ===========================================================================

  /// Przeprowadza zaawansowaną sesję badawczą w tunelu aerodynamicznym z producentem rowerów,
  /// trwale obniżając współczynnik oporu aerodynamicznego CdA oraz wagę ram na kolejny sezon.
  static ({CareerSave updatedSave, WindTunnelTestReport report})
      conductWindTunnelTest({
    required CareerSave currentSave,
    required WindTunnelCampaignType campaignType,
  }) {
    final playerTeam = currentSave.playerTeam;
    final int cost = campaignType.baseCostEur;

    // Weryfikacja budżetu
    if (playerTeam.cashBalanceEur < cost) {
      throw StateError(
          'Niewystarczające środki w budżecie drużyny (€$cost wymagane).');
    }

    // Weryfikacja poziomu tunelu w bazie
    if (currentSave.windTunnelLevel < campaignType.minWindTunnelLevel) {
      throw StateError(
          'Wymagany poziom tunelu aerodynamicznego w bazie: ${campaignType.minWindTunnelLevel}.');
    }

    final double cdaImprovement = campaignType.cdaReduction;
    final int weightImprovement = campaignType.weightReductionGrams;

    // Modyfikujemy ramy we flocie rowerów zespołu
    final List<CompleteBike> upgradedBikes = [];
    final List<String> upgradedNames = [];

    for (final bike in playerTeam.inventoryBikes) {
      final oldFrame = bike.frame;
      // Obniżamy CdA (staje się jeszcze bardziej ujemny, np. -0.0210 -> -0.0275)
      final double newCda = oldFrame.aeroCdaModifier - cdaImprovement;
      final int newWeight =
          math.max(620, oldFrame.weightGrams - weightImprovement);

      final upgradedFrame = oldFrame.copyWith(
        aeroCdaModifier: newCda,
        weightGrams: newWeight,
        name: '${oldFrame.name} (Aero Evo)',
      );

      upgradedNames.add(upgradedFrame.name);

      upgradedBikes.add(
        bike.copyWith(
          frame: upgradedFrame,
          name: '${bike.name} [WindTunnel R&D]',
        ),
      );
    }

    // Wpis finansowy
    final newLedgerEntry = CareerFinanceLedgerEntry(
      id: 'aero_test_${DateTime.now().millisecondsSinceEpoch}',
      date: currentSave.currentDate,
      category: FinanceCategory.facilityUpgrade,
      amountEur: -cost,
      description:
          'Wspólne testy aerodynamiczne z ${playerTeam.bikeDeal.manufacturerName}: ${campaignType.title}',
    );

    final updatedTeams = currentSave.teams.map((t) {
      if (t.id == currentSave.playerTeamId) {
        return t.copyWith(
          inventoryBikes: upgradedBikes,
          cashBalanceEur: t.cashBalanceEur - cost,
        );
      }
      return t;
    }).toList();

    final updatedSave = currentSave.copyWith(
      teams: updatedTeams,
      financeLedger: [newLedgerEntry, ...currentSave.financeLedger],
      lastSavedAt: DateTime.now(),
    );

    final String quote = campaignType ==
            WindTunnelCampaignType.factoryWorksAeroEvolution
        ? 'Dzięki formom z włókna T1100 i obróbce CFD w skali 1:1 uzyskaliśmy zysk -${(cdaImprovement * 1000).toStringAsFixed(1)} mCda oraz odchudziliśmy ramę o ${weightImprovement}g. Przy 50 km/h kolarz zaoszczędzi ponad 14 Watów!'
        : 'Zakończono kalibrację opływu strugi powietrza. Nowy profil kokpitu i ramy redukuje opory o -${(cdaImprovement * 1000).toStringAsFixed(1)} mCda.';

    final report = WindTunnelTestReport(
      campaignType: campaignType,
      isSuccess: true,
      cdaDelta: -cdaImprovement,
      weightDeltaGrams: -weightImprovement,
      costEur: cost,
      chiefAerodynamicistQuote: quote,
      upgradedFrameNames: upgradedNames,
      date: currentSave.currentDate,
    );

    return (updatedSave: updatedSave, report: report);
  }

  // ===========================================================================
  // 5. CAŁOŚCIOWY WSKAŹNIK TECHNOLOGICZNY SPRZĘTU (EQUIPMENT PROWESS)
  // ===========================================================================

  /// Oblicza łączny wskaźnik technologiczny sprzętu zespołu (0 - 100 pkt)
  /// uwzględniający średnią masę ram, modyfikator aero CdA oraz poziom R&D producenta.
  static double calculateTeamEquipmentProwess(CyclingTeam team) {
    if (team.inventoryBikes.isEmpty) return 50.0;

    double score = 50.0;

    // 1. Poziom R&D producenta (waga 40%)
    score += (team.bikeDeal.researchAndDevelopmentLevel / 100.0) * 25.0;

    // 2. Prestiż marki (waga 25%)
    score += (team.bikeDeal.prestigeLevel / 5.0) * 15.0;

    // 3. Parametry fizyczne ram (waga 35%)
    double avgWeight = 0.0;
    double avgCda = 0.0;

    for (final b in team.inventoryBikes) {
      avgWeight += b.frame.weightGrams;
      avgCda += b.frame.aeroCdaModifier;
    }
    avgWeight /= team.inventoryBikes.length;
    avgCda /= team.inventoryBikes.length;

    // Im lżejsza rama, tym wyższa nota (np. 700g = +10 pkt, 1050g = 0 pkt)
    score += ((1050 - avgWeight) / 35.0).clamp(0.0, 10.0);

    // Im bardziej ujemny modyfikator CdA, tym wyższa nota
    score += ((-avgCda) / 0.002).clamp(0.0, 10.0);

    return score.clamp(10.0, 100.0);
  }
}

