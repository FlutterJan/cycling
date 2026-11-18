// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/team/sponsor_contract.dart';

/// Prestiżowe lokalizacje i etapy, na których drużyna organizuje obsługę gości VIP sponsora.
enum VipHospitalityStageVenue {
  parisRoubaixVelodrome,
  champsElyseesFinale,
  tourOfFlandersOudenaarde,
  giroMilanoDuomo,
  vueltaMadridCibeles,
  alpeDhuezSummit;

  String toJson() => name;

  static VipHospitalityStageVenue fromJson(String value) {
    return VipHospitalityStageVenue.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => VipHospitalityStageVenue.parisRoubaixVelodrome,
    );
  }

  String get title {
    switch (this) {
      case VipHospitalityStageVenue.parisRoubaixVelodrome:
        return 'Paris-Roubaix — Welodrom w Roubaix';
      case VipHospitalityStageVenue.champsElyseesFinale:
        return 'Tour de France — Champs-Élysées, Paryż';
      case VipHospitalityStageVenue.tourOfFlandersOudenaarde:
        return 'Ronde van Vlaanderen — Oudenaarde';
      case VipHospitalityStageVenue.giroMilanoDuomo:
        return "Giro d'Italia — Finał pod Duomo, Mediolan";
      case VipHospitalityStageVenue.vueltaMadridCibeles:
        return 'La Vuelta — Plaza de Cibeles, Madryt';
      case VipHospitalityStageVenue.alpeDhuezSummit:
        return "Etap Królewski — Szczyt Alpe d'Huez";
    }
  }

  String get shortLabel {
    switch (this) {
      case VipHospitalityStageVenue.parisRoubaixVelodrome:
        return 'Paris-Roubaix';
      case VipHospitalityStageVenue.champsElyseesFinale:
        return 'Champs-Élysées';
      case VipHospitalityStageVenue.tourOfFlandersOudenaarde:
        return 'Flandria';
      case VipHospitalityStageVenue.giroMilanoDuomo:
        return 'Mediolan';
      case VipHospitalityStageVenue.vueltaMadridCibeles:
        return 'Madryt';
      case VipHospitalityStageVenue.alpeDhuezSummit:
        return "Alpe d'Huez";
    }
  }

  String get hospitalityHighlight {
    switch (this) {
      case VipHospitalityStageVenue.parisRoubaixVelodrome:
        return 'Loża VIP na murawie betonowego welodromu i wjazd 2. wozem za peletonem przez sektor Carrefour de l\'Arbre.';
      case VipHospitalityStageVenue.champsElyseesFinale:
        return 'Prywatny taras z szampanem nad Łukiem Triumfalnym i runda honorowa w kolumnie technicznej.';
      case VipHospitalityStageVenue.tourOfFlandersOudenaarde:
        return 'Strefa biznesowa na mecie w Oudenaarde oraz przejazd wozu technicznego pod Oude Kwaremont.';
      case VipHospitalityStageVenue.giroMilanoDuomo:
        return 'Królewska loża przy Piazza del Duomo z degustacją włoskiej kuchni i prezentacją trofeum.';
      case VipHospitalityStageVenue.vueltaMadridCibeles:
        return 'Wieczorny bankiet VIP przy fontannie Cibeles podczas finałowego kryterium w Madrycie.';
      case VipHospitalityStageVenue.alpeDhuezSummit:
        return 'Ekskluzywny namiot wysokogórski na 21. zakręcie i przejazd w drugim wozie pod górę.';
    }
  }

  /// Prestiż lokalizacji w skali 1.0 - 1.5 wpływający na siłę efektu gościnności.
  double get prestigeMultiplier {
    switch (this) {
      case VipHospitalityStageVenue.champsElyseesFinale:
        return 1.45;
      case VipHospitalityStageVenue.parisRoubaixVelodrome:
        return 1.40;
      case VipHospitalityStageVenue.alpeDhuezSummit:
        return 1.32;
      case VipHospitalityStageVenue.tourOfFlandersOudenaarde:
        return 1.28;
      case VipHospitalityStageVenue.giroMilanoDuomo:
        return 1.25;
      case VipHospitalityStageVenue.vueltaMadridCibeles:
        return 1.18;
    }
  }

  /// Bazowy koszt wynajmu strefy VIP na danym etapie (EUR).
  int get baseVenueCostEur {
    switch (this) {
      case VipHospitalityStageVenue.champsElyseesFinale:
        return 32000;
      case VipHospitalityStageVenue.parisRoubaixVelodrome:
        return 26000;
      case VipHospitalityStageVenue.alpeDhuezSummit:
        return 24000;
      case VipHospitalityStageVenue.tourOfFlandersOudenaarde:
        return 22000;
      case VipHospitalityStageVenue.giroMilanoDuomo:
        return 21000;
      case VipHospitalityStageVenue.vueltaMadridCibeles:
        return 18500;
    }
  }

  int get defaultDistanceKm {
    switch (this) {
      case VipHospitalityStageVenue.parisRoubaixVelodrome:
        return 257;
      case VipHospitalityStageVenue.champsElyseesFinale:
        return 115;
      case VipHospitalityStageVenue.tourOfFlandersOudenaarde:
        return 271;
      case VipHospitalityStageVenue.giroMilanoDuomo:
        return 143;
      case VipHospitalityStageVenue.vueltaMadridCibeles:
        return 101;
      case VipHospitalityStageVenue.alpeDhuezSummit:
        return 165;
    }
  }
}

/// Pakiety atrakcji dostępnych dla gości VIP sponsora podczas dnia wyścigowego.
enum VipHospitalityExperiencePackage {
  finishLineVipLounge,
  secondTeamCarConvoy,
  teamBusLeaderMeetAndGreet,
  signedPodiumJerseyAndPhoto,
  fullExecutiveHospitalitySuite;

  String toJson() => name;

  static VipHospitalityExperiencePackage fromJson(String value) {
    return VipHospitalityExperiencePackage.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => VipHospitalityExperiencePackage.finishLineVipLounge,
    );
  }

  String get label {
    switch (this) {
      case VipHospitalityExperiencePackage.finishLineVipLounge:
        return 'Strefa VIP na Mecie';
      case VipHospitalityExperiencePackage.secondTeamCarConvoy:
        return 'Przejazd w 2. Wozie Technicznym';
      case VipHospitalityExperiencePackage.teamBusLeaderMeetAndGreet:
        return 'Spotkanie z Liderem w Autobusie';
      case VipHospitalityExperiencePackage.signedPodiumJerseyAndPhoto:
        return 'Koszulka z Autografami i Sesja Foto';
      case VipHospitalityExperiencePackage.fullExecutiveHospitalitySuite:
        return 'Pakiet Platynowy Executive';
    }
  }

  String get description {
    switch (this) {
      case VipHospitalityExperiencePackage.finishLineVipLounge:
        return 'Loża tuż za linią mety z cateringiem szefa kuchni, szampanem i podglądem telemetrii na żywo.';
      case VipHospitalityExperiencePackage.secondTeamCarConvoy:
        return 'Miejsce na tylnej kanapie 2. wozu technicznego za peletonem z nasłuchem radia wyścigowego DS.';
      case VipHospitalityExperiencePackage.teamBusLeaderMeetAndGreet:
        return 'Prywatny briefing z liderem drużyny i dyrektorem sportowym przed lub tuż po finiszu etapu.';
      case VipHospitalityExperiencePackage.signedPodiumJerseyAndPhoto:
        return 'Oprawiona koszulka startowa z podpisami składu oraz pamiątkowe zdjęcie na tle podium.';
      case VipHospitalityExperiencePackage.fullExecutiveHospitalitySuite:
        return 'Kompleksowa obsługa premium łącząca lożę VIP, konwój w 2. wozie oraz kolację z zarządem.';
    }
  }

  int get packageCostEur {
    switch (this) {
      case VipHospitalityExperiencePackage.finishLineVipLounge:
        return 8500;
      case VipHospitalityExperiencePackage.secondTeamCarConvoy:
        return 12000;
      case VipHospitalityExperiencePackage.teamBusLeaderMeetAndGreet:
        return 6000;
      case VipHospitalityExperiencePackage.signedPodiumJerseyAndPhoto:
        return 3500;
      case VipHospitalityExperiencePackage.fullExecutiveHospitalitySuite:
        return 24000;
    }
  }

  double get baseScoreContribution {
    switch (this) {
      case VipHospitalityExperiencePackage.finishLineVipLounge:
        return 18.0;
      case VipHospitalityExperiencePackage.secondTeamCarConvoy:
        return 26.0;
      case VipHospitalityExperiencePackage.teamBusLeaderMeetAndGreet:
        return 15.0;
      case VipHospitalityExperiencePackage.signedPodiumJerseyAndPhoto:
        return 10.0;
      case VipHospitalityExperiencePackage.fullExecutiveHospitalitySuite:
        return 34.0;
    }
  }

  IconData get icon {
    switch (this) {
      case VipHospitalityExperiencePackage.finishLineVipLounge:
        return Icons.wine_bar_rounded;
      case VipHospitalityExperiencePackage.secondTeamCarConvoy:
        return Icons.directions_car_filled_rounded;
      case VipHospitalityExperiencePackage.teamBusLeaderMeetAndGreet:
        return Icons.directions_bus_rounded;
      case VipHospitalityExperiencePackage.signedPodiumJerseyAndPhoto:
        return Icons.checkroom_rounded;
      case VipHospitalityExperiencePackage.fullExecutiveHospitalitySuite:
        return Icons.workspace_premium_rounded;
    }
  }
}

/// Rola zaproszonego gościa ze strony sponsora.
enum VipGuestRoleTier {
  sponsorCeo,
  boardMember,
  marketingDirector,
  keyClientGuest;

  String toJson() => name;

  static VipGuestRoleTier fromJson(String value) {
    return VipGuestRoleTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => VipGuestRoleTier.boardMember,
    );
  }

  String get label {
    switch (this) {
      case VipGuestRoleTier.sponsorCeo:
        return 'Prezes / CEO';
      case VipGuestRoleTier.boardMember:
        return 'Członek Zarządu';
      case VipGuestRoleTier.marketingDirector:
        return 'Dyrektor Marketingu';
      case VipGuestRoleTier.keyClientGuest:
        return 'Kluczowy Partner B2B';
    }
  }

  /// Waga wpływu danego gościa na decyzję o przedłużeniu kontraktu.
  double get renewalDecisionWeight {
    switch (this) {
      case VipGuestRoleTier.sponsorCeo:
        return 1.35;
      case VipGuestRoleTier.boardMember:
        return 1.15;
      case VipGuestRoleTier.marketingDirector:
        return 1.05;
      case VipGuestRoleTier.keyClientGuest:
        return 0.85;
    }
  }
}

/// Status zaproszenia i realizacji wydarzenia VIP.
enum VipInvitationStatus {
  drafted,
  invited,
  confirmed,
  inProgress,
  completed,
  disappointed,
  cancelled;

  String toJson() => name;

  static VipInvitationStatus fromJson(String value) {
    return VipInvitationStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => VipInvitationStatus.invited,
    );
  }

  String get label {
    switch (this) {
      case VipInvitationStatus.drafted:
        return 'Szkic';
      case VipInvitationStatus.invited:
        return 'Zaproszono';
      case VipInvitationStatus.confirmed:
        return 'Potwierdzono';
      case VipInvitationStatus.inProgress:
        return 'W trakcie etapu';
      case VipInvitationStatus.completed:
        return 'Zakończono sukcesem';
      case VipInvitationStatus.disappointed:
        return 'Poniżej oczekiwań';
      case VipInvitationStatus.cancelled:
        return 'Odwołano';
    }
  }

  bool get isFinalized =>
      this == VipInvitationStatus.completed ||
      this == VipInvitationStatus.disappointed ||
      this == VipInvitationStatus.cancelled;
}

/// Wrażenia gościa VIP z jazdy w drugim wozie technicznym za peletonem.
enum SecondTeamCarRideMood {
  thrilled,
  impressed,
  nervous,
  carsickOrDelayed;

  String toJson() => name;

  static SecondTeamCarRideMood fromJson(String value) {
    return SecondTeamCarRideMood.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SecondTeamCarRideMood.impressed,
    );
  }

  String get label {
    switch (this) {
      case SecondTeamCarRideMood.thrilled:
        return 'Zachwycony adrenaliną w konwoju';
      case SecondTeamCarRideMood.impressed:
        return 'Pod wrażeniem profesjonalizmu DS';
      case SecondTeamCarRideMood.nervous:
        return 'Zaniepokojony chaosem w kolumnie';
      case SecondTeamCarRideMood.carsickOrDelayed:
        return 'Zmęczony korkiem wozów i wstrząsami';
    }
  }

  double get scoreBonus {
    switch (this) {
      case SecondTeamCarRideMood.thrilled:
        return 14.0;
      case SecondTeamCarRideMood.impressed:
        return 9.0;
      case SecondTeamCarRideMood.nervous:
        return 1.5;
      case SecondTeamCarRideMood.carsickOrDelayed:
        return -5.5;
    }
  }
}

/// Poziom prognozowanego przedłużenia wieloletniego kontraktu sponsorskiego.
enum HospitalityRenewalTier {
  multiYearMegaExtension,
  standardMultiYearRenewal,
  conditionalOneYearOption,
  atRiskOfNonRenewal;

  String toJson() => name;

  static HospitalityRenewalTier fromJson(String value) {
    return HospitalityRenewalTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => HospitalityRenewalTier.conditionalOneYearOption,
    );
  }

  String get label {
    switch (this) {
      case HospitalityRenewalTier.multiYearMegaExtension:
        return 'Wieloletni Kontrakt Premium (3-4 lata)';
      case HospitalityRenewalTier.standardMultiYearRenewal:
        return 'Przedłużenie Wieloletnie (2 lata)';
      case HospitalityRenewalTier.conditionalOneYearOption:
        return 'Opcja Warunkowa (1 rok)';
      case HospitalityRenewalTier.atRiskOfNonRenewal:
        return 'Ryzyko Odejścia Sponsora';
    }
  }
}

/// Profil zaproszonego gościa VIP reprezentującego sponsora.
class VipSponsorGuestProfile {
  final String id;
  final String fullName;
  final String title;
  final String companyName;
  final String sponsorId;
  final VipGuestRoleTier roleTier;
  final SponsorIndustry industry;
  final VipHospitalityExperiencePackage personalPreference;
  final double patienceScore;
  final double affinityScore;

  const VipSponsorGuestProfile({
    required this.id,
    required this.fullName,
    required this.title,
    required this.companyName,
    required this.sponsorId,
    required this.roleTier,
    required this.industry,
    required this.personalPreference,
    this.patienceScore = 70.0,
    this.affinityScore = 65.0,
  });

  VipSponsorGuestProfile copyWith({
    String? id,
    String? fullName,
    String? title,
    String? companyName,
    String? sponsorId,
    VipGuestRoleTier? roleTier,
    SponsorIndustry? industry,
    VipHospitalityExperiencePackage? personalPreference,
    double? patienceScore,
    double? affinityScore,
  }) {
    return VipSponsorGuestProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      title: title ?? this.title,
      companyName: companyName ?? this.companyName,
      sponsorId: sponsorId ?? this.sponsorId,
      roleTier: roleTier ?? this.roleTier,
      industry: industry ?? this.industry,
      personalPreference: personalPreference ?? this.personalPreference,
      patienceScore: (patienceScore ?? this.patienceScore).clamp(0.0, 100.0),
      affinityScore: (affinityScore ?? this.affinityScore).clamp(0.0, 100.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'title': title,
      'companyName': companyName,
      'sponsorId': sponsorId,
      'roleTier': roleTier.toJson(),
      'industry': industry.toJson(),
      'personalPreference': personalPreference.toJson(),
      'patienceScore': patienceScore,
      'affinityScore': affinityScore,
    };
  }

  factory VipSponsorGuestProfile.fromJson(Map<String, dynamic> json) {
    return VipSponsorGuestProfile(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      title: json['title'] as String,
      companyName: json['companyName'] as String,
      sponsorId: json['sponsorId'] as String,
      roleTier: VipGuestRoleTier.fromJson(json['roleTier'] as String),
      industry: SponsorIndustry.fromJson(json['industry'] as String),
      personalPreference: VipHospitalityExperiencePackage.fromJson(
        json['personalPreference'] as String,
      ),
      patienceScore: (json['patienceScore'] as num?)?.toDouble() ?? 70.0,
      affinityScore: (json['affinityScore'] as num?)?.toDouble() ?? 65.0,
    );
  }
}

/// Telemetria i przebieg przejazdu gościa VIP w drugim wozie technicznym za peletonem.
class SecondTeamCarRideTelemetry {
  final int carNumber;
  final String driverName;
  final String sportsDirectorName;
  final double distanceCoveredKm;
  final int cobbleSectorsOrClimbsCount;
  final int radioCallsWitnessed;
  final int mechanicalAssistsObserved;
  final double dramaScore;
  final double comfortScore;
  final SecondTeamCarRideMood mood;
  final String highlightQuote;

  const SecondTeamCarRideTelemetry({
    this.carNumber = 2,
    required this.driverName,
    required this.sportsDirectorName,
    required this.distanceCoveredKm,
    required this.cobbleSectorsOrClimbsCount,
    required this.radioCallsWitnessed,
    required this.mechanicalAssistsObserved,
    required this.dramaScore,
    required this.comfortScore,
    required this.mood,
    required this.highlightQuote,
  });

  SecondTeamCarRideTelemetry copyWith({
    int? carNumber,
    String? driverName,
    String? sportsDirectorName,
    double? distanceCoveredKm,
    int? cobbleSectorsOrClimbsCount,
    int? radioCallsWitnessed,
    int? mechanicalAssistsObserved,
    double? dramaScore,
    double? comfortScore,
    SecondTeamCarRideMood? mood,
    String? highlightQuote,
  }) {
    return SecondTeamCarRideTelemetry(
      carNumber: carNumber ?? this.carNumber,
      driverName: driverName ?? this.driverName,
      sportsDirectorName: sportsDirectorName ?? this.sportsDirectorName,
      distanceCoveredKm: distanceCoveredKm ?? this.distanceCoveredKm,
      cobbleSectorsOrClimbsCount:
          cobbleSectorsOrClimbsCount ?? this.cobbleSectorsOrClimbsCount,
      radioCallsWitnessed: radioCallsWitnessed ?? this.radioCallsWitnessed,
      mechanicalAssistsObserved:
          mechanicalAssistsObserved ?? this.mechanicalAssistsObserved,
      dramaScore: (dramaScore ?? this.dramaScore).clamp(0.0, 100.0),
      comfortScore: (comfortScore ?? this.comfortScore).clamp(0.0, 100.0),
      mood: mood ?? this.mood,
      highlightQuote: highlightQuote ?? this.highlightQuote,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'carNumber': carNumber,
      'driverName': driverName,
      'sportsDirectorName': sportsDirectorName,
      'distanceCoveredKm': distanceCoveredKm,
      'cobbleSectorsOrClimbsCount': cobbleSectorsOrClimbsCount,
      'radioCallsWitnessed': radioCallsWitnessed,
      'mechanicalAssistsObserved': mechanicalAssistsObserved,
      'dramaScore': dramaScore,
      'comfortScore': comfortScore,
      'mood': mood.toJson(),
      'highlightQuote': highlightQuote,
    };
  }

  factory SecondTeamCarRideTelemetry.fromJson(Map<String, dynamic> json) {
    return SecondTeamCarRideTelemetry(
      carNumber: (json['carNumber'] as num?)?.toInt() ?? 2,
      driverName: json['driverName'] as String,
      sportsDirectorName: json['sportsDirectorName'] as String,
      distanceCoveredKm: (json['distanceCoveredKm'] as num).toDouble(),
      cobbleSectorsOrClimbsCount:
          (json['cobbleSectorsOrClimbsCount'] as num).toInt(),
      radioCallsWitnessed: (json['radioCallsWitnessed'] as num).toInt(),
      mechanicalAssistsObserved:
          (json['mechanicalAssistsObserved'] as num).toInt(),
      dramaScore: (json['dramaScore'] as num).toDouble(),
      comfortScore: (json['comfortScore'] as num).toDouble(),
      mood: SecondTeamCarRideMood.fromJson(json['mood'] as String),
      highlightQuote: json['highlightQuote'] as String,
    );
  }
}

/// Rekord wydarzenia gościnności VIP sponsora na kluczowym etapie sezonu.
class VipHospitalityEventRecord {
  final String id;
  final int seasonYear;
  final String stageId;
  final String stageName;
  final VipHospitalityStageVenue venue;
  final DateTime eventDate;
  final String sponsorId;
  final String sponsorCompanyName;
  final List<VipSponsorGuestProfile> guests;
  final List<VipHospitalityExperiencePackage> selectedPackages;
  final int hospitalityBudgetEur;
  final VipInvitationStatus status;
  final int? teamStagePlacement;
  final bool wonStageOrPodium;
  final double hospitalityScore;
  final double sponsorSatisfactionDelta;
  final double renewalProbabilityDelta;
  final SecondTeamCarRideTelemetry? secondCarTelemetry;
  final String postEventSummary;
  final DateTime createdAt;

  const VipHospitalityEventRecord({
    required this.id,
    required this.seasonYear,
    required this.stageId,
    required this.stageName,
    required this.venue,
    required this.eventDate,
    required this.sponsorId,
    required this.sponsorCompanyName,
    required this.guests,
    required this.selectedPackages,
    required this.hospitalityBudgetEur,
    required this.status,
    this.teamStagePlacement,
    this.wonStageOrPodium = false,
    this.hospitalityScore = 0.0,
    this.sponsorSatisfactionDelta = 0.0,
    this.renewalProbabilityDelta = 0.0,
    this.secondCarTelemetry,
    this.postEventSummary = '',
    required this.createdAt,
  });

  bool get includesSecondTeamCar =>
      selectedPackages.contains(
        VipHospitalityExperiencePackage.secondTeamCarConvoy,
      ) ||
      selectedPackages.contains(
        VipHospitalityExperiencePackage.fullExecutiveHospitalitySuite,
      );

  VipHospitalityEventRecord copyWith({
    String? id,
    int? seasonYear,
    String? stageId,
    String? stageName,
    VipHospitalityStageVenue? venue,
    DateTime? eventDate,
    String? sponsorId,
    String? sponsorCompanyName,
    List<VipSponsorGuestProfile>? guests,
    List<VipHospitalityExperiencePackage>? selectedPackages,
    int? hospitalityBudgetEur,
    VipInvitationStatus? status,
    int? teamStagePlacement,
    bool? wonStageOrPodium,
    double? hospitalityScore,
    double? sponsorSatisfactionDelta,
    double? renewalProbabilityDelta,
    SecondTeamCarRideTelemetry? secondCarTelemetry,
    String? postEventSummary,
    DateTime? createdAt,
  }) {
    return VipHospitalityEventRecord(
      id: id ?? this.id,
      seasonYear: seasonYear ?? this.seasonYear,
      stageId: stageId ?? this.stageId,
      stageName: stageName ?? this.stageName,
      venue: venue ?? this.venue,
      eventDate: eventDate ?? this.eventDate,
      sponsorId: sponsorId ?? this.sponsorId,
      sponsorCompanyName: sponsorCompanyName ?? this.sponsorCompanyName,
      guests: guests ?? this.guests,
      selectedPackages: selectedPackages ?? this.selectedPackages,
      hospitalityBudgetEur: hospitalityBudgetEur ?? this.hospitalityBudgetEur,
      status: status ?? this.status,
      teamStagePlacement: teamStagePlacement ?? this.teamStagePlacement,
      wonStageOrPodium: wonStageOrPodium ?? this.wonStageOrPodium,
      hospitalityScore:
          (hospitalityScore ?? this.hospitalityScore).clamp(0.0, 100.0),
      sponsorSatisfactionDelta:
          sponsorSatisfactionDelta ?? this.sponsorSatisfactionDelta,
      renewalProbabilityDelta:
          renewalProbabilityDelta ?? this.renewalProbabilityDelta,
      secondCarTelemetry: secondCarTelemetry ?? this.secondCarTelemetry,
      postEventSummary: postEventSummary ?? this.postEventSummary,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seasonYear': seasonYear,
      'stageId': stageId,
      'stageName': stageName,
      'venue': venue.toJson(),
      'eventDate': eventDate.toIso8601String(),
      'sponsorId': sponsorId,
      'sponsorCompanyName': sponsorCompanyName,
      'guests': guests.map((g) => g.toJson()).toList(),
      'selectedPackages': selectedPackages.map((p) => p.toJson()).toList(),
      'hospitalityBudgetEur': hospitalityBudgetEur,
      'status': status.toJson(),
      'teamStagePlacement': teamStagePlacement,
      'wonStageOrPodium': wonStageOrPodium,
      'hospitalityScore': hospitalityScore,
      'sponsorSatisfactionDelta': sponsorSatisfactionDelta,
      'renewalProbabilityDelta': renewalProbabilityDelta,
      'secondCarTelemetry': secondCarTelemetry?.toJson(),
      'postEventSummary': postEventSummary,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory VipHospitalityEventRecord.fromJson(Map<String, dynamic> json) {
    return VipHospitalityEventRecord(
      id: json['id'] as String,
      seasonYear: (json['seasonYear'] as num).toInt(),
      stageId: json['stageId'] as String,
      stageName: json['stageName'] as String,
      venue: VipHospitalityStageVenue.fromJson(json['venue'] as String),
      eventDate: DateTime.parse(json['eventDate'] as String),
      sponsorId: json['sponsorId'] as String,
      sponsorCompanyName: json['sponsorCompanyName'] as String,
      guests: (json['guests'] as List<dynamic>)
          .map(
            (e) => VipSponsorGuestProfile.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      selectedPackages: (json['selectedPackages'] as List<dynamic>)
          .map((e) => VipHospitalityExperiencePackage.fromJson(e as String))
          .toList(),
      hospitalityBudgetEur: (json['hospitalityBudgetEur'] as num).toInt(),
      status: VipInvitationStatus.fromJson(json['status'] as String),
      teamStagePlacement: (json['teamStagePlacement'] as num?)?.toInt(),
      wonStageOrPodium: json['wonStageOrPodium'] as bool? ?? false,
      hospitalityScore: (json['hospitalityScore'] as num?)?.toDouble() ?? 0.0,
      sponsorSatisfactionDelta:
          (json['sponsorSatisfactionDelta'] as num?)?.toDouble() ?? 0.0,
      renewalProbabilityDelta:
          (json['renewalProbabilityDelta'] as num?)?.toDouble() ?? 0.0,
      secondCarTelemetry: json['secondCarTelemetry'] == null
          ? null
          : SecondTeamCarRideTelemetry.fromJson(
              json['secondCarTelemetry'] as Map<String, dynamic>,
            ),
      postEventSummary: json['postEventSummary'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Podsumowanie wpływu gościnności VIP na przedłużenie wieloletniego kontraktu sponsorskiego.
class SponsorRenewalImpactSummary {
  final String sponsorId;
  final String sponsorCompanyName;
  final double currentSatisfaction;
  final double projectedSatisfaction;
  final int completedVipEventsCount;
  final int successfulVipEventsCount;
  final double averageHospitalityScore;
  final int secondCarRidesCompleted;
  final double renewalProbabilityPercent;
  final int recommendedContractYears;
  final double projectedAnnualBudgetBonusPercent;
  final HospitalityRenewalTier renewalTier;
  final String executiveSummary;

  const SponsorRenewalImpactSummary({
    required this.sponsorId,
    required this.sponsorCompanyName,
    required this.currentSatisfaction,
    required this.projectedSatisfaction,
    required this.completedVipEventsCount,
    required this.successfulVipEventsCount,
    required this.averageHospitalityScore,
    required this.secondCarRidesCompleted,
    required this.renewalProbabilityPercent,
    required this.recommendedContractYears,
    required this.projectedAnnualBudgetBonusPercent,
    required this.renewalTier,
    required this.executiveSummary,
  });

  Map<String, dynamic> toJson() {
    return {
      'sponsorId': sponsorId,
      'sponsorCompanyName': sponsorCompanyName,
      'currentSatisfaction': currentSatisfaction,
      'projectedSatisfaction': projectedSatisfaction,
      'completedVipEventsCount': completedVipEventsCount,
      'successfulVipEventsCount': successfulVipEventsCount,
      'averageHospitalityScore': averageHospitalityScore,
      'secondCarRidesCompleted': secondCarRidesCompleted,
      'renewalProbabilityPercent': renewalProbabilityPercent,
      'recommendedContractYears': recommendedContractYears,
      'projectedAnnualBudgetBonusPercent': projectedAnnualBudgetBonusPercent,
      'renewalTier': renewalTier.toJson(),
      'executiveSummary': executiveSummary,
    };
  }

  factory SponsorRenewalImpactSummary.fromJson(Map<String, dynamic> json) {
    return SponsorRenewalImpactSummary(
      sponsorId: json['sponsorId'] as String,
      sponsorCompanyName: json['sponsorCompanyName'] as String,
      currentSatisfaction: (json['currentSatisfaction'] as num).toDouble(),
      projectedSatisfaction: (json['projectedSatisfaction'] as num).toDouble(),
      completedVipEventsCount:
          (json['completedVipEventsCount'] as num).toInt(),
      successfulVipEventsCount:
          (json['successfulVipEventsCount'] as num).toInt(),
      averageHospitalityScore:
          (json['averageHospitalityScore'] as num).toDouble(),
      secondCarRidesCompleted:
          (json['secondCarRidesCompleted'] as num).toInt(),
      renewalProbabilityPercent:
          (json['renewalProbabilityPercent'] as num).toDouble(),
      recommendedContractYears:
          (json['recommendedContractYears'] as num).toInt(),
      projectedAnnualBudgetBonusPercent:
          (json['projectedAnnualBudgetBonusPercent'] as num).toDouble(),
      renewalTier: HospitalityRenewalTier.fromJson(
        json['renewalTier'] as String,
      ),
      executiveSummary: json['executiveSummary'] as String,
    );
  }
}

/// Wynik pojedynczej operacji w systemie gościnności VIP.
class HospitalityOperationResult {
  final bool success;
  final String message;
  final VipHospitalityEventRecord? eventRecord;
  final SponsorRenewalImpactSummary? renewalSummary;
  final int budgetSpentEur;

  const HospitalityOperationResult({
    required this.success,
    required this.message,
    this.eventRecord,
    this.renewalSummary,
    this.budgetSpentEur = 0,
  });
}

/// Główny serwis obsługi gości VIP sponsora na kluczowych etapach sezonu.
///
/// Obsługuje zaproszenia prezesów i zarządu do strefy VIP na mecie takich klasyków
/// jak *Paris-Roubaix* czy *Champs-Élysées*, symulację przejazdu w drugim wozie
/// technicznym za peletonem oraz ocenę wpływu udanej gościnności na przedłużenie
/// wieloletniego kontraktu sponsorskiego.
class TeamSponsorHospitalityVipEvents {
  const TeamSponsorHospitalityVipEvents();

  /// Wylicza całkowity koszt organizacji pakietu VIP dla danej liczby gości.
  int calculatePackageCostEur({
    required VipHospitalityStageVenue venue,
    required List<VipHospitalityExperiencePackage> packages,
    required int guestCount,
  }) {
    if (packages.isEmpty || guestCount <= 0) {
      return 0;
    }

    final int clampedGuests = guestCount.clamp(1, 12);
    final int packagesCost = packages.fold<int>(
      0,
      (sum, pkg) => sum + pkg.packageCostEur,
    );

    // Dodatkowy koszt cateringu i akredytacji za każdego kolejnego gościa powyżej 1.
    final int perGuestSurcharge = (clampedGuests - 1) * 2400;
    return venue.baseVenueCostEur + packagesCost + perGuestSurcharge;
  }

  /// Tworzy i wysyła zaproszenie VIP do wybranych przedstawicieli sponsora.
  HospitalityOperationResult createVipInvitation({
    required String eventId,
    required int seasonYear,
    required String stageId,
    required String stageName,
    required VipHospitalityStageVenue venue,
    required DateTime eventDate,
    required String sponsorId,
    required String sponsorCompanyName,
    required List<VipSponsorGuestProfile> guests,
    required List<VipHospitalityExperiencePackage> selectedPackages,
    required int availableTeamBudgetEur,
    DateTime? now,
  }) {
    if (guests.isEmpty) {
      return const HospitalityOperationResult(
        success: false,
        message: 'Wybierz co najmniej jednego gościa VIP sponsora.',
      );
    }

    if (selectedPackages.isEmpty) {
      return const HospitalityOperationResult(
        success: false,
        message: 'Wybierz przynajmniej jeden pakiet atrakcji VIP.',
      );
    }

    final int totalCost = calculatePackageCostEur(
      venue: venue,
      packages: selectedPackages,
      guestCount: guests.length,
    );

    if (totalCost > availableTeamBudgetEur) {
      return HospitalityOperationResult(
        success: false,
        message:
            'Niewystarczający budżet drużyny (${Formatters.formatCurrency(availableTeamBudgetEur)} < ${Formatters.formatCurrency(totalCost)}).',
      );
    }

    // Jeśli na liście jest Prezes lub Członek Zarządu o wysokim affinity, zaproszenie od razu ma status confirmed.
    final double avgAffinity =
        guests.fold<double>(0.0, (sum, g) => sum + g.affinityScore) /
            guests.length;
    final VipInvitationStatus initialStatus = avgAffinity >= 60.0
        ? VipInvitationStatus.confirmed
        : VipInvitationStatus.invited;

    final VipHospitalityEventRecord record = VipHospitalityEventRecord(
      id: eventId,
      seasonYear: seasonYear,
      stageId: stageId,
      stageName: stageName,
      venue: venue,
      eventDate: eventDate,
      sponsorId: sponsorId,
      sponsorCompanyName: sponsorCompanyName,
      guests: List<VipSponsorGuestProfile>.unmodifiable(guests),
      selectedPackages: List<VipHospitalityExperiencePackage>.unmodifiable(
        selectedPackages,
      ),
      hospitalityBudgetEur: totalCost,
      status: initialStatus,
      createdAt: now ?? DateTime.now(),
    );

    return HospitalityOperationResult(
      success: true,
      message:
          'Wysłano zaproszenie VIP na ${venue.shortLabel} dla ${guests.length} gości (${Formatters.formatCurrency(totalCost)}).',
      eventRecord: record,
      budgetSpentEur: totalCost,
    );
  }

  /// Symuluje przejażdżkę gościa VIP w drugim wozie technicznym za peletonem.
  HospitalityOperationResult simulateSecondTeamCarRide({
    required VipHospitalityEventRecord event,
    String driverName = 'Marcin Kowalczyk',
    String sportsDirectorName = 'Laurent Delacroix',
    int seed = 42,
    double weatherSeverity = 0.25,
    bool hadFrequentPunctures = false,
  }) {
    if (event.status.isFinalized) {
      return const HospitalityOperationResult(
        success: false,
        message: 'Wydarzenie VIP zostało już zakończone.',
      );
    }

    if (!event.includesSecondTeamCar) {
      return const HospitalityOperationResult(
        success: false,
        message:
            'To wydarzenie nie obejmuje przejazdu w 2. wozie technicznym.',
      );
    }

    final math.Random rng = math.Random(seed ^ event.id.hashCode);
    final double clampedWeather = weatherSeverity.clamp(0.0, 1.0);
    final double baseDistance = event.venue.defaultDistanceKm.toDouble();
    final double coveredKm =
        (baseDistance * (0.62 + rng.nextDouble() * 0.30)).clamp(55.0, 260.0);

    final int sectorsOrClimbs = switch (event.venue) {
      VipHospitalityStageVenue.parisRoubaixVelodrome => 18 + rng.nextInt(10),
      VipHospitalityStageVenue.tourOfFlandersOudenaarde => 11 + rng.nextInt(6),
      VipHospitalityStageVenue.alpeDhuezSummit => 4 + rng.nextInt(3),
      _ => 2 + rng.nextInt(4),
    };

    final int radioCalls = 14 + rng.nextInt(18);
    final int mechanicalAssists =
        (hadFrequentPunctures ? 4 : 1) + rng.nextInt(4);

    final double dramaScore = (52.0 +
            sectorsOrClimbs * 1.4 +
            mechanicalAssists * 4.5 +
            clampedWeather * 18.0 +
            rng.nextDouble() * 10.0)
        .clamp(25.0, 99.0);

    final double cobbleShakePenalty =
        event.venue == VipHospitalityStageVenue.parisRoubaixVelodrome
            ? 14.0
            : 4.0;
    final double comfortScore = (86.0 -
            cobbleShakePenalty -
            clampedWeather * 16.0 -
            (hadFrequentPunctures ? 8.0 : 0.0) +
            rng.nextDouble() * 8.0)
        .clamp(30.0, 98.0);

    final SecondTeamCarRideMood mood;
    if (dramaScore >= 76.0 && comfortScore >= 56.0) {
      mood = SecondTeamCarRideMood.thrilled;
    } else if (comfortScore >= 52.0) {
      mood = SecondTeamCarRideMood.impressed;
    } else if (comfortScore >= 38.0) {
      mood = SecondTeamCarRideMood.nervous;
    } else {
      mood = SecondTeamCarRideMood.carsickOrDelayed;
    }

    final String quote = _buildSecondCarQuote(
      venue: event.venue,
      mood: mood,
      mechanicalAssists: mechanicalAssists,
    );

    final SecondTeamCarRideTelemetry telemetry = SecondTeamCarRideTelemetry(
      carNumber: 2,
      driverName: driverName,
      sportsDirectorName: sportsDirectorName,
      distanceCoveredKm: double.parse(coveredKm.toStringAsFixed(1)),
      cobbleSectorsOrClimbsCount: sectorsOrClimbs,
      radioCallsWitnessed: radioCalls,
      mechanicalAssistsObserved: mechanicalAssists,
      dramaScore: double.parse(dramaScore.toStringAsFixed(1)),
      comfortScore: double.parse(comfortScore.toStringAsFixed(1)),
      mood: mood,
      highlightQuote: quote,
    );

    final VipHospitalityEventRecord updated = event.copyWith(
      status: VipInvitationStatus.inProgress,
      secondCarTelemetry: telemetry,
    );

    return HospitalityOperationResult(
      success: true,
      message:
          'Przejazd w 2. wozie technicznym zakończony: ${mood.label} (${telemetry.distanceCoveredKm.toStringAsFixed(0)} km w konwoju).',
      eventRecord: updated,
    );
  }

  /// Rozlicza wydarzenie VIP po zakończeniu etapu i wylicza wpływ na relację ze sponsorem.
  HospitalityOperationResult resolveHospitalityEvent({
    required VipHospitalityEventRecord event,
    required int teamStagePlacement,
    bool wonStageOrPodium = false,
    bool hadMajorCrashOrDns = false,
  }) {
    if (event.status == VipInvitationStatus.cancelled) {
      return const HospitalityOperationResult(
        success: false,
        message: 'Nie można rozliczyć odwołanego wydarzenia VIP.',
      );
    }

    final int clampedPlacement = teamStagePlacement.clamp(1, 180);

    // 1. Bazowa punktacja z wybranych pakietów atrakcji.
    double packageScore = event.selectedPackages.fold<double>(
      0.0,
      (sum, pkg) => sum + pkg.baseScoreContribution,
    );
    packageScore = packageScore.clamp(10.0, 52.0);

    // 2. Dopasowanie pakietów do preferencji zaproszonych gości.
    int matchedPreferences = 0;
    double weightedDecisionFactor = 0.0;
    for (final VipSponsorGuestProfile guest in event.guests) {
      weightedDecisionFactor += guest.roleTier.renewalDecisionWeight;
      if (event.selectedPackages.contains(guest.personalPreference) ||
          event.selectedPackages.contains(
            VipHospitalityExperiencePackage.fullExecutiveHospitalitySuite,
          )) {
        matchedPreferences++;
      }
    }
    final double avgDecisionWeight = event.guests.isEmpty
        ? 1.0
        : weightedDecisionFactor / event.guests.length;
    final double preferenceBonus = event.guests.isEmpty
        ? 0.0
        : (matchedPreferences / event.guests.length) * 14.0;

    // 3. Premia za wynik sportowy drużyny w obecności VIP-ów.
    final double sportResultScore;
    if (wonStageOrPodium || clampedPlacement <= 3) {
      sportResultScore = 24.0;
    } else if (clampedPlacement <= 10) {
      sportResultScore = 16.0;
    } else if (clampedPlacement <= 25) {
      sportResultScore = 8.0;
    } else {
      sportResultScore = hadMajorCrashOrDns ? -10.0 : 2.0;
    }

    // 4. Premia/kara z telemetrii przejazdu w 2. wozie technicznym.
    final double secondCarBonus =
        event.secondCarTelemetry?.mood.scoreBonus ?? 0.0;

    // 5. Połączenie całości z mnożnikiem prestiżu etapu.
    final double rawScore =
        (packageScore + preferenceBonus + sportResultScore + secondCarBonus) *
            (0.85 + (event.venue.prestigeMultiplier - 1.0) * 0.55);
    final double finalScore = rawScore.clamp(15.0, 100.0);

    final bool isSuccess = finalScore >= 62.0;
    final double satisfactionDelta = isSuccess
        ? ((finalScore - 50.0) * 0.30 * avgDecisionWeight).clamp(2.5, 18.0)
        : ((finalScore - 65.0) * 0.28).clamp(-12.0, -1.0);

    final double renewalDelta = isSuccess
        ? ((finalScore - 52.0) * 0.36 * avgDecisionWeight).clamp(3.0, 22.0)
        : ((finalScore - 62.0) * 0.25).clamp(-9.0, -1.0);

    final String summary = _buildPostEventSummary(
      event: event,
      finalScore: finalScore,
      placement: clampedPlacement,
      wonStageOrPodium: wonStageOrPodium,
      satisfactionDelta: satisfactionDelta,
      renewalDelta: renewalDelta,
    );

    final VipHospitalityEventRecord resolved = event.copyWith(
      status: isSuccess
          ? VipInvitationStatus.completed
          : VipInvitationStatus.disappointed,
      teamStagePlacement: clampedPlacement,
      wonStageOrPodium: wonStageOrPodium || clampedPlacement <= 3,
      hospitalityScore: double.parse(finalScore.toStringAsFixed(1)),
      sponsorSatisfactionDelta:
          double.parse(satisfactionDelta.toStringAsFixed(1)),
      renewalProbabilityDelta:
          double.parse(renewalDelta.toStringAsFixed(1)),
      postEventSummary: summary,
    );

    return HospitalityOperationResult(
      success: true,
      message: isSuccess
          ? 'Gościnność VIP na ${event.venue.shortLabel} oceniona na ${resolved.hospitalityScore.toStringAsFixed(0)}/100 pkt!'
          : 'Goście VIP na ${event.venue.shortLabel} byli rozczarowani (${resolved.hospitalityScore.toStringAsFixed(0)}/100 pkt).',
      eventRecord: resolved,
    );
  }

  /// Ocenia skumulowany wpływ wydarzeń VIP na przedłużenie wieloletniego kontraktu sponsorskiego.
  SponsorRenewalImpactSummary evaluateSponsorContractRenewalImpact({
    required SponsorContract contract,
    required List<VipHospitalityEventRecord> events,
  }) {
    final List<VipHospitalityEventRecord> sponsorEvents = events
        .where(
          (e) =>
              e.sponsorId == contract.id &&
              (e.status == VipInvitationStatus.completed ||
                  e.status == VipInvitationStatus.disappointed),
        )
        .toList();

    if (sponsorEvents.isEmpty) {
      final double baseProb =
          (contract.sponsorSatisfaction * 0.72).clamp(15.0, 88.0);
      return SponsorRenewalImpactSummary(
        sponsorId: contract.id,
        sponsorCompanyName: contract.companyName,
        currentSatisfaction: contract.sponsorSatisfaction,
        projectedSatisfaction: contract.sponsorSatisfaction,
        completedVipEventsCount: 0,
        successfulVipEventsCount: 0,
        averageHospitalityScore: 0.0,
        secondCarRidesCompleted: 0,
        renewalProbabilityPercent: double.parse(baseProb.toStringAsFixed(1)),
        recommendedContractYears: baseProb >= 65.0 ? 2 : 1,
        projectedAnnualBudgetBonusPercent: 0.0,
        renewalTier: baseProb >= 65.0
            ? HospitalityRenewalTier.standardMultiYearRenewal
            : HospitalityRenewalTier.conditionalOneYearOption,
        executiveSummary:
            'Brak zrealizowanych wydarzeń VIP dla ${contract.companyName}. Zaproś zarząd na Paris-Roubaix lub Champs-Élysées, aby zwiększyć szanse na wieloletnie przedłużenie.',
      );
    }

    final int completedCount = sponsorEvents.length;
    final int successfulCount = sponsorEvents
        .where((e) => e.status == VipInvitationStatus.completed)
        .length;
    final int secondCarCount =
        sponsorEvents.where((e) => e.secondCarTelemetry != null).length;

    final double avgScore = sponsorEvents.fold<double>(
          0.0,
          (sum, e) => sum + e.hospitalityScore,
        ) /
        completedCount;

    final double totalSatisfactionDelta = sponsorEvents.fold<double>(
      0.0,
      (sum, e) => sum + e.sponsorSatisfactionDelta,
    );
    final double totalRenewalDelta = sponsorEvents.fold<double>(
      0.0,
      (sum, e) => sum + e.renewalProbabilityDelta,
    );

    final double projectedSatisfaction =
        (contract.sponsorSatisfaction + totalSatisfactionDelta)
            .clamp(0.0, 100.0);

    final double baseProb = contract.sponsorSatisfaction * 0.62;
    final double renewalProb =
        (baseProb + totalRenewalDelta + (secondCarCount * 2.5))
            .clamp(5.0, 99.0);

    final HospitalityRenewalTier tier;
    final int recommendedYears;
    final double budgetBonusPercent;

    if (renewalProb >= 84.0 && avgScore >= 78.0) {
      tier = HospitalityRenewalTier.multiYearMegaExtension;
      recommendedYears = 3;
      budgetBonusPercent = 14.5;
    } else if (renewalProb >= 65.0) {
      tier = HospitalityRenewalTier.standardMultiYearRenewal;
      recommendedYears = 2;
      budgetBonusPercent = 6.0;
    } else if (renewalProb >= 45.0) {
      tier = HospitalityRenewalTier.conditionalOneYearOption;
      recommendedYears = 1;
      budgetBonusPercent = 0.0;
    } else {
      tier = HospitalityRenewalTier.atRiskOfNonRenewal;
      recommendedYears = 1;
      budgetBonusPercent = -5.0;
    }

    return SponsorRenewalImpactSummary(
      sponsorId: contract.id,
      sponsorCompanyName: contract.companyName,
      currentSatisfaction: contract.sponsorSatisfaction,
      projectedSatisfaction:
          double.parse(projectedSatisfaction.toStringAsFixed(1)),
      completedVipEventsCount: completedCount,
      successfulVipEventsCount: successfulCount,
      averageHospitalityScore: double.parse(avgScore.toStringAsFixed(1)),
      secondCarRidesCompleted: secondCarCount,
      renewalProbabilityPercent: double.parse(renewalProb.toStringAsFixed(1)),
      recommendedContractYears: recommendedYears,
      projectedAnnualBudgetBonusPercent: budgetBonusPercent,
      renewalTier: tier,
      executiveSummary:
          'Zrealizowano $completedCount wydarzeń VIP ($successfulCount udanych, śr. ${avgScore.toStringAsFixed(0)} pkt). Szansa na $recommendedYears-letnie przedłużenie kontraktu ${contract.companyName} wynosi ${renewalProb.toStringAsFixed(0)}%.',
    );
  }

  /// Aktualizuje kontrakt sponsorski o efekt udanej gościnności VIP.
  SponsorContract applyRenewalImpactToContract({
    required SponsorContract contract,
    required SponsorRenewalImpactSummary summary,
    bool executeMultiYearRenewal = false,
  }) {
    final double updatedSatisfaction =
        summary.projectedSatisfaction.clamp(0.0, 100.0);

    if (!executeMultiYearRenewal) {
      return contract.copyWith(sponsorSatisfaction: updatedSatisfaction);
    }

    final double multiplier =
        1.0 + (summary.projectedAnnualBudgetBonusPercent / 100.0);
    final int updatedBudget = (contract.annualBudgetEur * multiplier).round();
    final int updatedYears = math.max(
      contract.contractDurationYears,
      summary.recommendedContractYears,
    );

    return contract.copyWith(
      sponsorSatisfaction: updatedSatisfaction,
      annualBudgetEur: updatedBudget,
      contractDurationYears: updatedYears,
    );
  }

  String _buildSecondCarQuote({
    required VipHospitalityStageVenue venue,
    required SecondTeamCarRideMood mood,
    required int mechanicalAssists,
  }) {
    switch (mood) {
      case SecondTeamCarRideMood.thrilled:
        return '„Niesamowite! Jechaliśmy w 2. wozie tuż za peletonem na ${venue.shortLabel}, widziałem $mechanicalAssists błyskawiczne zmiany kół i słyszałem radio DS na żywo!”';
      case SecondTeamCarRideMood.impressed:
        return '„Pełen profesjonalizm konwoju technicznego na ${venue.shortLabel}. Organizacja zespołu z bliska robi ogromne wrażenie na naszym zarządzie.”';
      case SecondTeamCarRideMood.nervous:
        return '„Dużo nerwowych manewrów w kolumnie wozów na ${venue.shortLabel}. Czuć napięcie wyścigu, choć momentami było bardzo ciasno.”';
      case SecondTeamCarRideMood.carsickOrDelayed:
        return '„Utknęliśmy w korku wozów na wąskich drogach ${venue.shortLabel} — po dwóch godzinach wstrząsów goście marzyli o powrocie do strefy VIP.”';
    }
  }

  String _buildPostEventSummary({
    required VipHospitalityEventRecord event,
    required double finalScore,
    required int placement,
    required bool wonStageOrPodium,
    required double satisfactionDelta,
    required double renewalDelta,
  }) {
    final String resultLabel = wonStageOrPodium
        ? 'podium (#$placement)'
        : '$placement. miejsce drużyny';
    final String signSat = satisfactionDelta >= 0 ? '+' : '';
    final String signRen = renewalDelta >= 0 ? '+' : '';

    return '${event.venue.title}: $resultLabel. Ocena gościnności ${finalScore.toStringAsFixed(0)}/100 pkt '
        '(satysfakcja $signSat${satisfactionDelta.toStringAsFixed(1)}, '
        'szansa przedłużenia $signRen${renewalDelta.toStringAsFixed(1)}%).';
  }
}

/// Stan Riverpod dla systemu gościnności VIP sponsora.
class TeamSponsorHospitalityState {
  final SponsorContract activeContract;
  final int availableTeamBudgetEur;
  final List<VipSponsorGuestProfile> availableGuests;
  final List<VipHospitalityEventRecord> events;
  final VipHospitalityStageVenue selectedVenue;
  final Set<VipHospitalityExperiencePackage> selectedPackages;
  final Set<String> selectedGuestIds;
  final int totalHospitalitySpentEur;
  final String? lastOperationMessage;
  final bool lastOperationSuccess;

  const TeamSponsorHospitalityState({
    required this.activeContract,
    required this.availableTeamBudgetEur,
    required this.availableGuests,
    required this.events,
    this.selectedVenue = VipHospitalityStageVenue.parisRoubaixVelodrome,
    this.selectedPackages = const {
      VipHospitalityExperiencePackage.finishLineVipLounge,
      VipHospitalityExperiencePackage.secondTeamCarConvoy,
    },
    this.selectedGuestIds = const {},
    this.totalHospitalitySpentEur = 0,
    this.lastOperationMessage,
    this.lastOperationSuccess = true,
  });

  factory TeamSponsorHospitalityState.initial() {
    const SponsorContract defaultContract = SponsorContract(
      id: 'sponsor_title_nordic_fin',
      companyName: 'NordicFin Capital',
      industry: SponsorIndustry.finance,
      sponsorTier: SponsorTier.titlePrimary,
      annualBudgetEur: 14500000,
      contractDurationYears: 2,
      sponsorSatisfaction: 72.0,
      objectives: [
        SponsorObjective(
          id: 'obj_roubaix_top5',
          description: 'Top 5 w Paris-Roubaix',
          bonusPaymentEur: 350000,
          importance: ObjectiveImportance.high,
          isCompleted: false,
          currentProgress: 0.0,
          targetProgress: 1.0,
        ),
      ],
    );

    final List<VipSponsorGuestProfile> guests = [
      const VipSponsorGuestProfile(
        id: 'vip_ceo_henrik',
        fullName: 'Henrik Lindqvist',
        title: 'Prezes Zarządu (CEO)',
        companyName: 'NordicFin Capital',
        sponsorId: 'sponsor_title_nordic_fin',
        roleTier: VipGuestRoleTier.sponsorCeo,
        industry: SponsorIndustry.finance,
        personalPreference: VipHospitalityExperiencePackage.secondTeamCarConvoy,
        patienceScore: 76.0,
        affinityScore: 74.0,
      ),
      const VipSponsorGuestProfile(
        id: 'vip_cmo_claire',
        fullName: 'Claire Moreau',
        title: 'Dyrektor Marketingu Globalnego',
        companyName: 'NordicFin Capital',
        sponsorId: 'sponsor_title_nordic_fin',
        roleTier: VipGuestRoleTier.marketingDirector,
        industry: SponsorIndustry.finance,
        personalPreference: VipHospitalityExperiencePackage.finishLineVipLounge,
        patienceScore: 82.0,
        affinityScore: 68.0,
      ),
      const VipSponsorGuestProfile(
        id: 'vip_board_tomasz',
        fullName: 'Tomasz Zieliński',
        title: 'Członek Rady Nadzorczej',
        companyName: 'NordicFin Capital',
        sponsorId: 'sponsor_title_nordic_fin',
        roleTier: VipGuestRoleTier.boardMember,
        industry: SponsorIndustry.finance,
        personalPreference:
            VipHospitalityExperiencePackage.teamBusLeaderMeetAndGreet,
        patienceScore: 70.0,
        affinityScore: 64.0,
      ),
    ];

    final VipHospitalityEventRecord sampleCompletedEvent =
        VipHospitalityEventRecord(
      id: 'vip_evt_champs_prev',
      seasonYear: 2026,
      stageId: 'tdf_stage_21',
      stageName: 'Etap 21 — Champs-Élysées',
      venue: VipHospitalityStageVenue.champsElyseesFinale,
      eventDate: DateTime(2026, 7, 26),
      sponsorId: 'sponsor_title_nordic_fin',
      sponsorCompanyName: 'NordicFin Capital',
      guests: [guests.first, guests[1]],
      selectedPackages: const [
        VipHospitalityExperiencePackage.finishLineVipLounge,
        VipHospitalityExperiencePackage.secondTeamCarConvoy,
      ],
      hospitalityBudgetEur: 54900,
      status: VipInvitationStatus.completed,
      teamStagePlacement: 2,
      wonStageOrPodium: true,
      hospitalityScore: 91.5,
      sponsorSatisfactionDelta: 14.2,
      renewalProbabilityDelta: 16.5,
      secondCarTelemetry: const SecondTeamCarRideTelemetry(
        carNumber: 2,
        driverName: 'Marcin Kowalczyk',
        sportsDirectorName: 'Laurent Delacroix',
        distanceCoveredKm: 92.4,
        cobbleSectorsOrClimbsCount: 8,
        radioCallsWitnessed: 21,
        mechanicalAssistsObserved: 2,
        dramaScore: 84.0,
        comfortScore: 82.0,
        mood: SecondTeamCarRideMood.thrilled,
        highlightQuote:
            '„Niesamowite! Jechaliśmy w 2. wozie tuż za peletonem na Champs-Élysées i słyszeliśmy radio DS podczas rozprowadzania sprintu!”',
      ),
      postEventSummary:
          'Tour de France — Champs-Élysées, Paryż: podium (#2). Ocena gościnności 92/100 pkt (satysfakcja +14.2, szansa przedłużenia +16.5%).',
      createdAt: DateTime(2026, 7, 20),
    );

    return TeamSponsorHospitalityState(
      activeContract: defaultContract,
      availableTeamBudgetEur: 1250000,
      availableGuests: guests,
      events: [sampleCompletedEvent],
      selectedGuestIds: {'vip_ceo_henrik'},
      totalHospitalitySpentEur: 54900,
    );
  }

  TeamSponsorHospitalityState copyWith({
    SponsorContract? activeContract,
    int? availableTeamBudgetEur,
    List<VipSponsorGuestProfile>? availableGuests,
    List<VipHospitalityEventRecord>? events,
    VipHospitalityStageVenue? selectedVenue,
    Set<VipHospitalityExperiencePackage>? selectedPackages,
    Set<String>? selectedGuestIds,
    int? totalHospitalitySpentEur,
    String? lastOperationMessage,
    bool? lastOperationSuccess,
  }) {
    return TeamSponsorHospitalityState(
      activeContract: activeContract ?? this.activeContract,
      availableTeamBudgetEur:
          availableTeamBudgetEur ?? this.availableTeamBudgetEur,
      availableGuests: availableGuests ?? this.availableGuests,
      events: events ?? this.events,
      selectedVenue: selectedVenue ?? this.selectedVenue,
      selectedPackages: selectedPackages ?? this.selectedPackages,
      selectedGuestIds: selectedGuestIds ?? this.selectedGuestIds,
      totalHospitalitySpentEur:
          totalHospitalitySpentEur ?? this.totalHospitalitySpentEur,
      lastOperationMessage: lastOperationMessage ?? this.lastOperationMessage,
      lastOperationSuccess: lastOperationSuccess ?? this.lastOperationSuccess,
    );
  }
}

/// Notifier zarządzający stanem wydarzeń VIP sponsora w interfejsie kariery.
class TeamSponsorHospitalityNotifier
    extends StateNotifier<TeamSponsorHospitalityState> {
  final TeamSponsorHospitalityVipEvents _service;

  TeamSponsorHospitalityNotifier(this._service)
      : super(TeamSponsorHospitalityState.initial());

  void selectVenue(VipHospitalityStageVenue venue) {
    state = state.copyWith(selectedVenue: venue);
  }

  void togglePackage(VipHospitalityExperiencePackage package) {
    final Set<VipHospitalityExperiencePackage> updated = Set.of(
      state.selectedPackages,
    );
    if (updated.contains(package)) {
      updated.remove(package);
    } else {
      updated.add(package);
    }
    state = state.copyWith(selectedPackages: updated);
  }

  void toggleGuest(String guestId) {
    final Set<String> updated = Set.of(state.selectedGuestIds);
    if (updated.contains(guestId)) {
      updated.remove(guestId);
    } else {
      updated.add(guestId);
    }
    state = state.copyWith(selectedGuestIds: updated);
  }

  int get currentDraftCostEur => _service.calculatePackageCostEur(
        venue: state.selectedVenue,
        packages: state.selectedPackages.toList(),
        guestCount: state.selectedGuestIds.length,
      );

  SponsorRenewalImpactSummary get renewalSummary =>
      _service.evaluateSponsorContractRenewalImpact(
        contract: state.activeContract,
        events: state.events,
      );

  void sendVipInvitation() {
    final List<VipSponsorGuestProfile> selectedGuests = state.availableGuests
        .where((g) => state.selectedGuestIds.contains(g.id))
        .toList();

    final String eventId =
        'vip_evt_${state.selectedVenue.name}_${DateTime.now().millisecondsSinceEpoch}';

    final HospitalityOperationResult result = _service.createVipInvitation(
      eventId: eventId,
      seasonYear: 2026,
      stageId: 'stage_${state.selectedVenue.name}',
      stageName: state.selectedVenue.title,
      venue: state.selectedVenue,
      eventDate: DateTime(2026, 4, 12),
      sponsorId: state.activeContract.id,
      sponsorCompanyName: state.activeContract.companyName,
      guests: selectedGuests,
      selectedPackages: state.selectedPackages.toList(),
      availableTeamBudgetEur: state.availableTeamBudgetEur,
    );

    if (!result.success || result.eventRecord == null) {
      state = state.copyWith(
        lastOperationMessage: result.message,
        lastOperationSuccess: false,
      );
      return;
    }

    state = state.copyWith(
      events: [result.eventRecord!, ...state.events],
      availableTeamBudgetEur:
          state.availableTeamBudgetEur - result.budgetSpentEur,
      totalHospitalitySpentEur:
          state.totalHospitalitySpentEur + result.budgetSpentEur,
      lastOperationMessage: result.message,
      lastOperationSuccess: true,
    );
  }

  void runSecondTeamCarExperience(String eventId) {
    final int idx = state.events.indexWhere((e) => e.id == eventId);
    if (idx == -1) return;

    final HospitalityOperationResult result =
        _service.simulateSecondTeamCarRide(
      event: state.events[idx],
      seed: idx + state.events.length + 17,
    );

    if (!result.success || result.eventRecord == null) {
      state = state.copyWith(
        lastOperationMessage: result.message,
        lastOperationSuccess: false,
      );
      return;
    }

    final List<VipHospitalityEventRecord> updatedEvents = List.of(state.events);
    updatedEvents[idx] = result.eventRecord!;

    state = state.copyWith(
      events: updatedEvents,
      lastOperationMessage: result.message,
      lastOperationSuccess: true,
    );
  }

  void completeVipEvent(
    String eventId, {
    int teamStagePlacement = 3,
    bool wonStageOrPodium = true,
  }) {
    final int idx = state.events.indexWhere((e) => e.id == eventId);
    if (idx == -1) return;

    final HospitalityOperationResult result = _service.resolveHospitalityEvent(
      event: state.events[idx],
      teamStagePlacement: teamStagePlacement,
      wonStageOrPodium: wonStageOrPodium,
    );

    if (!result.success || result.eventRecord == null) {
      state = state.copyWith(
        lastOperationMessage: result.message,
        lastOperationSuccess: false,
      );
      return;
    }

    final List<VipHospitalityEventRecord> updatedEvents = List.of(state.events);
    updatedEvents[idx] = result.eventRecord!;

    final SponsorRenewalImpactSummary summary =
        _service.evaluateSponsorContractRenewalImpact(
      contract: state.activeContract,
      events: updatedEvents,
    );
    final SponsorContract updatedContract =
        _service.applyRenewalImpactToContract(
      contract: state.activeContract,
      summary: summary,
    );

    state = state.copyWith(
      events: updatedEvents,
      activeContract: updatedContract,
      lastOperationMessage: result.message,
      lastOperationSuccess: true,
    );
  }

  void lockMultiYearRenewal() {
    final SponsorRenewalImpactSummary summary = renewalSummary;
    final SponsorContract updatedContract =
        _service.applyRenewalImpactToContract(
      contract: state.activeContract,
      summary: summary,
      executeMultiYearRenewal: true,
    );

    state = state.copyWith(
      activeContract: updatedContract,
      lastOperationMessage:
          'Przedłużono kontrakt z ${updatedContract.companyName} na ${updatedContract.contractDurationYears} lata (${Formatters.formatCompactCurrency(updatedContract.annualBudgetEur)}/rok)!',
      lastOperationSuccess: true,
    );
  }
}

final teamSponsorHospitalityServiceProvider =
    Provider<TeamSponsorHospitalityVipEvents>((ref) {
  return const TeamSponsorHospitalityVipEvents();
});

final teamSponsorHospitalityProvider = StateNotifierProvider<
    TeamSponsorHospitalityNotifier, TeamSponsorHospitalityState>((ref) {
  final service = ref.watch(teamSponsorHospitalityServiceProvider);
  return TeamSponsorHospitalityNotifier(service);
});

/// Produkcyjny panel UI obsługi gości VIP sponsora na najważniejszych etapach.
///
/// Responsywny dla `390x844` (mobile), `1024x768` (tablet) i `1600x900` (desktop),
/// z pełnymi stanami `hover` / `active` / `disabled` / `focus`.
class TeamSponsorHospitalityVipPanel extends ConsumerWidget {
  const TeamSponsorHospitalityVipPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TeamSponsorHospitalityState state = ref.watch(
      teamSponsorHospitalityProvider,
    );
    final TeamSponsorHospitalityNotifier notifier = ref.read(
      teamSponsorHospitalityProvider.notifier,
    );
    final SponsorRenewalImpactSummary renewal = notifier.renewalSummary;
    final int draftCostEur = notifier.currentDraftCostEur;

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isCompact = constraints.maxWidth < 720;
          final bool isWideDesktop = constraints.maxWidth >= 1220;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isCompact ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(
                  state: state,
                  renewal: renewal,
                  isCompact: isCompact,
                ),
                if (state.lastOperationMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildStatusBanner(
                    message: state.lastOperationMessage!,
                    isSuccess: state.lastOperationSuccess,
                  ),
                ],
                const SizedBox(height: 20),
                if (isWideDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildInvitationBuilderCard(
                          state: state,
                          notifier: notifier,
                          draftCostEur: draftCostEur,
                          isCompact: isCompact,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            _buildRenewalImpactCard(
                              contract: state.activeContract,
                              renewal: renewal,
                              onLockRenewal: notifier.lockMultiYearRenewal,
                            ),
                            const SizedBox(height: 20),
                            _buildEventsListCard(
                              events: state.events,
                              onRunSecondCar:
                                  notifier.runSecondTeamCarExperience,
                              onCompleteEvent: (id) =>
                                  notifier.completeVipEvent(id),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildInvitationBuilderCard(
                        state: state,
                        notifier: notifier,
                        draftCostEur: draftCostEur,
                        isCompact: isCompact,
                      ),
                      const SizedBox(height: 20),
                      _buildRenewalImpactCard(
                        contract: state.activeContract,
                        renewal: renewal,
                        onLockRenewal: notifier.lockMultiYearRenewal,
                      ),
                      const SizedBox(height: 20),
                      _buildEventsListCard(
                        events: state.events,
                        onRunSecondCar: notifier.runSecondTeamCarExperience,
                        onCompleteEvent: (id) => notifier.completeVipEvent(id),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard({
    required TeamSponsorHospitalityState state,
    required SponsorRenewalImpactSummary renewal,
    required bool isCompact,
  }) {
    final List<_KpiChipData> kpis = [
      _KpiChipData(
        label: 'Sponsor Tytularny',
        value: state.activeContract.companyName,
        accent: AppColors.goldAccent,
      ),
      _KpiChipData(
        label: 'Szansa Przedłużenia',
        value: '${renewal.renewalProbabilityPercent.toStringAsFixed(0)}%',
        accent: renewal.renewalProbabilityPercent >= 65
            ? AppColors.statusSuccess
            : AppColors.amberWarning,
      ),
      _KpiChipData(
        label: 'Przejazdy 2. Wozem',
        value: '${renewal.secondCarRidesCompleted}',
        accent: AppColors.accentBlue,
      ),
      _KpiChipData(
        label: 'Budżet Zespołu',
        value: Formatters.formatCompactCurrency(state.availableTeamBudgetEur),
        accent: AppColors.textPrimary,
      ),
    ];

    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryAccent.withValues(alpha: 0.6),
                  ),
                ),
                child: const Icon(
                  Icons.diamond_rounded,
                  color: AppColors.goldAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gościnność VIP Sponsora & Konwój 2. Wozu',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Zapraszaj zarząd sponsora na Paris-Roubaix i Champs-Élysées, aby budować wieloletnie kontrakty.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isCompact ? 12 : 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: kpis
                .map(
                  (kpi) => Container(
                    constraints: BoxConstraints(
                      minWidth: isCompact ? 140 : 165,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          kpi.label,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          kpi.value,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: kpi.accent,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner({
    required String message,
    required bool isSuccess,
  }) {
    final Color tone =
        isSuccess ? AppColors.statusSuccess : AppColors.crimsonAlert;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.warning_rounded,
            color: tone,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationBuilderCard({
    required TeamSponsorHospitalityState state,
    required TeamSponsorHospitalityNotifier notifier,
    required int draftCostEur,
    required bool isCompact,
  }) {
    final bool canSend = state.selectedGuestIds.isNotEmpty &&
        state.selectedPackages.isNotEmpty &&
        draftCostEur <= state.availableTeamBudgetEur;

    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '1. Wybierz Etap & Strefę VIP',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: VipHospitalityStageVenue.values.map((venue) {
              final bool isSelected = state.selectedVenue == venue;
              return _InteractiveSelectionChip(
                label: venue.shortLabel,
                selected: isSelected,
                accentColor: AppColors.goldAccent,
                onTap: () => notifier.selectVenue(venue),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            state.selectedVenue.hospitalityHighlight,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '2. Atrakcje VIP & Przejazd w 2. Wozie',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: VipHospitalityExperiencePackage.values.map((pkg) {
              final bool selected = state.selectedPackages.contains(pkg);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _InteractivePackageTile(
                  package: pkg,
                  selected: selected,
                  onTap: () => notifier.togglePackage(pkg),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            '3. Zaproszeni Przedstawiciele Sponsora',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.availableGuests.map((guest) {
              final bool selected = state.selectedGuestIds.contains(guest.id);
              return _InteractiveSelectionChip(
                label: '${guest.fullName} (${guest.roleTier.label})',
                selected: selected,
                accentColor: AppColors.accentBlue,
                onTap: () => notifier.toggleGuest(guest.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Szacowany koszt pakietu VIP',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.formatCurrency(draftCostEur),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldAccent,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                _InteractiveActionButton(
                  label: 'Wyślij Zaproszenie',
                  icon: Icons.send_rounded,
                  enabled: canSend,
                  accentColor: AppColors.primaryAccent,
                  onPressed: notifier.sendVipInvitation,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRenewalImpactCard({
    required SponsorContract contract,
    required SponsorRenewalImpactSummary renewal,
    required VoidCallback onLockRenewal,
  }) {
    final bool canRenew = renewal.renewalProbabilityPercent >= 60.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Wpływ na Kontrakt Wieloletni',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  '${renewal.recommendedContractYears} lata (+${renewal.projectedAnnualBudgetBonusPercent.toStringAsFixed(1)}%)',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (renewal.renewalProbabilityPercent / 100.0).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.surfaceLight,
              color: renewal.renewalProbabilityPercent >= 75
                  ? AppColors.statusSuccess
                  : AppColors.amberWarning,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            renewal.executiveSummary,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: _InteractiveActionButton(
              label: 'Podpisz Przedłużenie (${contract.companyName})',
              icon: Icons.verified_rounded,
              enabled: canRenew,
              accentColor: AppColors.statusSuccess,
              onPressed: onLockRenewal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsListCard({
    required List<VipHospitalityEventRecord> events,
    required void Function(String eventId) onRunSecondCar,
    required void Function(String eventId) onCompleteEvent,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kalendarz i Historia Wydarzeń VIP',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            const Text(
              'Brak zaplanowanych wydarzeń VIP w tym sezonie.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          else
            Column(
              children: events.map((event) {
                final bool canRideSecondCar = event.includesSecondTeamCar &&
                    event.secondCarTelemetry == null &&
                    !event.status.isFinalized;
                final bool canComplete = !event.status.isFinalized;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.venue.title,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            event.status.label,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: event.status ==
                                      VipInvitationStatus.completed
                                  ? AppColors.statusSuccess
                                  : AppColors.goldAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Goście: ${event.guests.map((g) => g.fullName).join(', ')} • ${Formatters.formatCurrency(event.hospitalityBudgetEur)}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (event.secondCarTelemetry != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '2. Wóz Techniczny (${event.secondCarTelemetry!.distanceCoveredKm.toStringAsFixed(0)} km): ${event.secondCarTelemetry!.highlightQuote}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.accentBlue,
                          ),
                        ),
                      ],
                      if (event.postEventSummary.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          event.postEventSummary,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                      if (canRideSecondCar || canComplete) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (canRideSecondCar)
                              _InteractiveActionButton(
                                label: 'Przejazd 2. Wozem',
                                icon: Icons.directions_car_filled_rounded,
                                enabled: true,
                                accentColor: AppColors.accentBlue,
                                onPressed: () => onRunSecondCar(event.id),
                              ),
                            if (canComplete)
                              _InteractiveActionButton(
                                label: 'Rozlicz Etap VIP',
                                icon: Icons.flag_rounded,
                                enabled: true,
                                accentColor: AppColors.goldAccent,
                                onPressed: () => onCompleteEvent(event.id),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _KpiChipData {
  final String label;
  final String value;
  final Color accent;

  const _KpiChipData({
    required this.label,
    required this.value,
    required this.accent,
  });
}

class _InteractiveSelectionChip extends StatefulWidget {
  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _InteractiveSelectionChip({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_InteractiveSelectionChip> createState() =>
      _InteractiveSelectionChipState();
}

class _InteractiveSelectionChipState extends State<_InteractiveSelectionChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = widget.selected || _focused
        ? widget.accentColor
        : _hovered
            ? widget.accentColor.withValues(alpha: 0.6)
            : AppColors.cardBorder;

    final Color bgColor = widget.selected
        ? widget.accentColor.withValues(alpha: _pressed ? 0.28 : 0.18)
        : _hovered
            ? AppColors.surfaceLight
            : AppColors.background;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color:
                  widget.selected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractivePackageTile extends StatefulWidget {
  final VipHospitalityExperiencePackage package;
  final bool selected;
  final VoidCallback onTap;

  const _InteractivePackageTile({
    required this.package,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_InteractivePackageTile> createState() =>
      _InteractivePackageTileState();
}

class _InteractivePackageTileState extends State<_InteractivePackageTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = widget.selected || _focused
        ? AppColors.goldAccent
        : _hovered
            ? AppColors.goldAccent.withValues(alpha: 0.5)
            : AppColors.cardBorder;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.goldAccent.withValues(alpha: _pressed ? 0.18 : 0.10)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(
                widget.package.icon,
                color: widget.selected
                    ? AppColors.goldAccent
                    : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.package.label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.package.description,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Formatters.formatCompactCurrency(widget.package.packageCostEur),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: widget.selected
                      ? AppColors.goldAccent
                      : AppColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = !widget.enabled
        ? AppColors.surfaceLight
        : _pressed
            ? widget.accentColor.withValues(alpha: 0.75)
            : _hovered
                ? widget.accentColor.withValues(alpha: 0.92)
                : widget.accentColor;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.textPrimary
                  : widget.enabled
                      ? widget.accentColor
                      : AppColors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: widget.enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
