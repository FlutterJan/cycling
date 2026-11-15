// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import '../rider/rider.dart';
import '../rider/rider_health.dart';

/// Typy protokołów regeneracyjnych stosowanych w peletonie WorldTour.
enum RecoveryProtocolType {
  /// Nogawki do drenażu limfatycznego / kompresji pneumatycznej (np. NormaTec, Therabody RecoveryAir).
  /// Sekwencyjny ucisk pneumatyczny przyspiesza powrót żylno-limfatyczny, zmniejsza obrzęk nóg
  /// i wypłukuje metabolity z mięśni bez dodatkowego obciążenia metabolicznego.
  pneumaticCompressionBoots,

  /// Krioterapia ogólnoustrojowa w komorze kriogenicznej (-110°C do -140°C przez 2.5-3 min).
  /// Błyskawiczny skurcz naczyń krwionośnych, redukcja kinazy kreatynowej (CK) i stanu zapalnego,
  /// potężne zbijanie ostrego zmęczenia (ATL) i bolesności powysiłkowej (DOMS).
  wholeBodyCryotherapy,

  /// Sesja w łagodnej komorze hiperbarycznej (HBOT 1.5 - 2.0 ATA, 100% tlenu).
  /// Zwiększa rozpuszczalność tlenu w osoczu krwi, przyspiesza regenerację mikrourazów
  /// włókien mięśniowych po ciężkich etapach górskich i redukuje stan zapalny.
  hyperbaricOxygenTherapy,

  /// Sauna sucha – protokół adaptacji cieplnej (Heat Acclimatization).
  /// 30-40 minut w 85-90°C bezpośrednio po treningu lub etapie. Stymuluje rozszerzenie
  /// objętości osocza krwi (+5-8%), obniża tętno i podnosi współczynnik `heatTolerance` kolarza.
  drySaunaHeatAcclimation,

  /// Specjalistyczne opatrunki hydrokoloidowe na szlify powypadkowe (Road Rash Care).
  /// Wilgotne środowisko gojenia ran po upadkach, ochrona przed zakażeniem,
  /// radykalne zniesienie bólu w nocy (lepszy sen) i skrócenie czasu gojenia szlifu.
  hydrocolloidRoadRashCare,

  /// Aktywny rozjazd tlenowy na trenażerze bezpośrednio po etapie (Cool-down).
  /// 15 minut w strefie Z1 (100-130W) na trenażerze w strefie mety. Wymusza przepływ krwi
  /// i zapobiega gwałtownemu zaleganiu mleczanu w kończynach.
  activeCoolDownRollers,

  /// Kąpiel w zimnej wodzie / basenie z lodem (Ice Bath, 10-12°C).
  /// Tradycyjna wazokonstrykcja, obniża temperaturę głęboką ciała i uśmierza ból mięśni.
  coldWaterImmersion,

  /// Fizjoterapia i terapia manualna (Masaż głęboki & Terapia powięziowa).
  /// Rozluźnianie napięć mięśniowo-powięziowych, obniżenie stężenia kinazy kreatynowej (CK)
  /// i bolesności powysiłkowej DOMS oraz przywracanie biomechaniki stawów.
  physiotherapyManualTherapy;

  String get displayName {
    switch (this) {
      case RecoveryProtocolType.pneumaticCompressionBoots:
        return 'Nogawki do drenażu limfatycznego (NormaTec / Kompresja)';
      case RecoveryProtocolType.wholeBodyCryotherapy:
        return 'Krioterapia ogólnoustrojowa (-110°C / Komora Krio)';
      case RecoveryProtocolType.hyperbaricOxygenTherapy:
        return 'Komora hiperbaryczna (HBOT 1.75 ATA 100% O2)';
      case RecoveryProtocolType.drySaunaHeatAcclimation:
        return 'Sauna sucha – Adaptacja cieplna (Heat Acclimation)';
      case RecoveryProtocolType.hydrocolloidRoadRashCare:
        return 'Opatrunki hydrokoloidowe na szlify (Road Rash Care)';
      case RecoveryProtocolType.activeCoolDownRollers:
        return 'Rozjazd na trenażerze po etapie (Active Cool-Down)';
      case RecoveryProtocolType.coldWaterImmersion:
        return 'Kąpiel w lodzie (Ice Bath 10-12°C)';
      case RecoveryProtocolType.physiotherapyManualTherapy:
        return 'Fizjoterapia i terapia manualna (Masaż głęboki & Terapia powięziowa)';
    }
  }

  String get shortName {
    switch (this) {
      case RecoveryProtocolType.pneumaticCompressionBoots:
        return 'Kompresja Pneumatyczna';
      case RecoveryProtocolType.wholeBodyCryotherapy:
        return 'Krioterapia (-110°C)';
      case RecoveryProtocolType.hyperbaricOxygenTherapy:
        return 'Komora Hiperbaryczna';
      case RecoveryProtocolType.drySaunaHeatAcclimation:
        return 'Sauna (Adaptacja Cieplna)';
      case RecoveryProtocolType.hydrocolloidRoadRashCare:
        return 'Opatrunki Hydrokoloidowe';
      case RecoveryProtocolType.activeCoolDownRollers:
        return 'Rozjazd na Trenażerze';
      case RecoveryProtocolType.coldWaterImmersion:
        return 'Kąpiel w Lodzie';
      case RecoveryProtocolType.physiotherapyManualTherapy:
        return 'Fizjoterapia & Masaż';
    }
  }

  String get category {
    switch (this) {
      case RecoveryProtocolType.pneumaticCompressionBoots:
        return 'Drenaż i Mikrokrążenie';
      case RecoveryProtocolType.wholeBodyCryotherapy:
        return 'Zimno & Układ Nerwowy';
      case RecoveryProtocolType.hyperbaricOxygenTherapy:
        return 'Dotlenienie Tkankowe';
      case RecoveryProtocolType.drySaunaHeatAcclimation:
        return 'Adaptacja Cieplna & Osocze';
      case RecoveryProtocolType.hydrocolloidRoadRashCare:
        return 'Leczenie Ran & Skóry';
      case RecoveryProtocolType.activeCoolDownRollers:
        return 'Metaboliczny Rozjazd';
      case RecoveryProtocolType.coldWaterImmersion:
        return 'Hydroterapia';
      case RecoveryProtocolType.physiotherapyManualTherapy:
        return 'Terapia Manualna & Mięśnie';
    }
  }
}

/// Definicja pojedynczego protokołu regeneracyjnego wraz z parametrami fizjologicznymi.
class RecoveryProtocol {
  final RecoveryProtocolType type;
  final String name;
  final String description;
  final String physiologicalMechanism;
  final int durationMinutes;
  final int costEur;

  /// Procentowa redukcja ostrego zmęczenia (ATL - Acute Training Load) [0.0% do 30.0%]
  final double atlReductionPercent;

  /// Wskaźnik wypłukiwania kwasu mlekowego i jonów H+ (zakwaszenia) [0.0 - 1.0]
  final double acidosisClearanceFactor;

  /// Redukcja bolesności mięśniowej (DOMS relief) [0.0% do 100.0%]
  final double domsReliefPercent;

  /// Wzrost tolerancji na upał (`heatTolerance` w `RiderSkills`)
  final double heatToleranceGain;

  /// Wzrost objętości osocza krwi [%] (efekt adaptacji cieplnej sauny)
  final double plasmaVolumeExpansionPercent;

  /// Liczba dni skrócenia kontuzji szlifu powypadkowego (`roadRash`)
  final int roadRashDaysReduction;

  /// Wpływ na jakość snu i odpoczynek nocny [%]
  final double sleepQualityBonusPercent;

  /// Czy protokół może być stosowany bezpośrednio w autobusie zespołu w strefie mety
  final bool isMobileBusCompatible;

  /// Wymagany poziom personelu medycznego drużyny (TeamStaff.doctorsLevel: 1-100)
  final int requiredDoctorSkill;

  /// Krótka nazwa protokołu
  String get shortName => type.shortName;

  /// Kategoria protokołu
  String get category => type.category;

  const RecoveryProtocol({
    required this.type,
    required this.name,
    required this.description,
    required this.physiologicalMechanism,
    required this.durationMinutes,
    required this.costEur,
    required this.atlReductionPercent,
    required this.acidosisClearanceFactor,
    required this.domsReliefPercent,
    this.heatToleranceGain = 0.0,
    this.plasmaVolumeExpansionPercent = 0.0,
    this.roadRashDaysReduction = 0,
    this.sleepQualityBonusPercent = 5.0,
    this.isMobileBusCompatible = false,
    this.requiredDoctorSkill = 20,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'name': name,
        'description': description,
        'physiologicalMechanism': physiologicalMechanism,
        'durationMinutes': durationMinutes,
        'costEur': costEur,
        'atlReductionPercent': atlReductionPercent,
        'acidosisClearanceFactor': acidosisClearanceFactor,
        'domsReliefPercent': domsReliefPercent,
        'heatToleranceGain': heatToleranceGain,
        'plasmaVolumeExpansionPercent': plasmaVolumeExpansionPercent,
        'roadRashDaysReduction': roadRashDaysReduction,
        'sleepQualityBonusPercent': sleepQualityBonusPercent,
        'isMobileBusCompatible': isMobileBusCompatible,
        'requiredDoctorSkill': requiredDoctorSkill,
      };

  factory RecoveryProtocol.fromJson(Map<String, dynamic> json) {
    final type = RecoveryProtocolType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => RecoveryProtocolType.pneumaticCompressionBoots,
    );
    return RecoveryProtocolSystem.getProtocol(type);
  }
}

/// Raport z wykonania protokołu regeneracyjnego dla kolarza.
class RecoveryProtocolExecutionReport {
  final String riderId;
  final String riderName;
  final RecoveryProtocol protocol;
  final double initialAtl;
  final double finalAtl;
  final double atlReduced;
  final double initialTsb;
  final double finalTsb;
  final double acidosisReducedPercent;
  final int initialHeatTolerance;
  final int finalHeatTolerance;
  final int heatToleranceDelta;
  final bool hadRoadRash;
  final int initialRoadRashDays;
  final int finalRoadRashDays;
  final bool isRoadRashFullyHealed;
  final int costEur;
  final String medicalSummary;
  final List<String> physiologicalNotes;

  const RecoveryProtocolExecutionReport({
    required this.riderId,
    required this.riderName,
    required this.protocol,
    required this.initialAtl,
    required this.finalAtl,
    required this.atlReduced,
    required this.initialTsb,
    required this.finalTsb,
    required this.acidosisReducedPercent,
    required this.initialHeatTolerance,
    required this.finalHeatTolerance,
    required this.heatToleranceDelta,
    required this.hadRoadRash,
    required this.initialRoadRashDays,
    required this.finalRoadRashDays,
    required this.isRoadRashFullyHealed,
    required this.costEur,
    required this.medicalSummary,
    required this.physiologicalNotes,
  });

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'protocolType': protocol.type.name,
        'initialAtl': initialAtl,
        'finalAtl': finalAtl,
        'atlReduced': atlReduced,
        'initialTsb': initialTsb,
        'finalTsb': finalTsb,
        'acidosisReducedPercent': acidosisReducedPercent,
        'initialHeatTolerance': initialHeatTolerance,
        'finalHeatTolerance': finalHeatTolerance,
        'heatToleranceDelta': heatToleranceDelta,
        'hadRoadRash': hadRoadRash,
        'initialRoadRashDays': initialRoadRashDays,
        'finalRoadRashDays': finalRoadRashDays,
        'isRoadRashFullyHealed': isRoadRashFullyHealed,
        'costEur': costEur,
        'medicalSummary': medicalSummary,
        'physiologicalNotes': physiologicalNotes,
      };

  @override
  String toString() {
    return 'RecoveryReport($riderName: ${protocol.shortName}, '
        'ATL: ${initialAtl.toStringAsFixed(1)} -> ${finalAtl.toStringAsFixed(1)} (-${atlReduced.toStringAsFixed(1)}), '
        'TSB: ${finalTsb.toStringAsFixed(1)})';
  }
}

/// Infrastruktura odnowy biologicznej drużyny kolarskiej (Team Recovery Center & Mobile Bus).
class TeamRecoveryCenterFacilities {
  /// Posiadanie nogawek kompresyjnych dla całego składu
  final bool hasCompressionBoots;

  /// Komora do krioterapii ogólnoustrojowej w trucku serwisowym lub bazie
  final bool hasCryotherapyChamber;

  /// Łagodna komora hiperbaryczna (HBOT)
  final bool hasHyperbaricOxygenChamber;

  /// Sauna sucha w bazie treningowej / mobilna sauna w trucku zespołu
  final bool hasDrySaunaFacility;

  /// Zapas profesjonalnych opatrunków hydrokoloidowych na szlify
  final bool hasHydrocolloidDressingsStock;

  /// Liczba dostępnych mobilnych trenażerów do rozjazdu w autobusie
  final int mobileCoolDownRollersCount;

  /// Mobilny analizator krwi (np. Abbott i-STAT / panel hematokrytu i ferrytyny w busie)
  final bool hasPointOfCareBloodAnalyzer;

  /// Aparatura fizjoterapeutyczna i fala uderzeniowa (Indiba Activ Tecar & Shockwave)
  final bool hasPhysiotherapyTechSuite;

  const TeamRecoveryCenterFacilities({
    this.hasCompressionBoots = true,
    this.hasCryotherapyChamber = false,
    this.hasHyperbaricOxygenChamber = false,
    this.hasDrySaunaFacility = false,
    this.hasHydrocolloidDressingsStock = true,
    this.mobileCoolDownRollersCount = 4,
    this.hasPointOfCareBloodAnalyzer = false,
    this.hasPhysiotherapyTechSuite = false,
  });

  /// Pakiet podstawowy dla drużyny ProTeam / Continental
  factory TeamRecoveryCenterFacilities.standardProTeam() {
    return const TeamRecoveryCenterFacilities(
      hasCompressionBoots: true,
      hasCryotherapyChamber: false,
      hasHyperbaricOxygenChamber: false,
      hasDrySaunaFacility: false,
      hasHydrocolloidDressingsStock: true,
      mobileCoolDownRollersCount: 4,
      hasPointOfCareBloodAnalyzer: false,
      hasPhysiotherapyTechSuite: false,
    );
  }

  /// Najwyższy standard WorldTour (np. Jumbo-Visma, UAE Team Emirates, INEOS)
  factory TeamRecoveryCenterFacilities.worldTourElite() {
    return const TeamRecoveryCenterFacilities(
      hasCompressionBoots: true,
      hasCryotherapyChamber: true,
      hasHyperbaricOxygenChamber: true,
      hasDrySaunaFacility: true,
      hasHydrocolloidDressingsStock: true,
      mobileCoolDownRollersCount: 8,
      hasPointOfCareBloodAnalyzer: true,
      hasPhysiotherapyTechSuite: true,
    );
  }

  /// Czy dany protokół może być zrealizowany w obecnej infrastrukturze zespołu
  bool canExecuteProtocol(RecoveryProtocolType type) {
    switch (type) {
      case RecoveryProtocolType.pneumaticCompressionBoots:
        return hasCompressionBoots;
      case RecoveryProtocolType.wholeBodyCryotherapy:
        return hasCryotherapyChamber;
      case RecoveryProtocolType.hyperbaricOxygenTherapy:
        return hasHyperbaricOxygenChamber;
      case RecoveryProtocolType.drySaunaHeatAcclimation:
        return hasDrySaunaFacility;
      case RecoveryProtocolType.hydrocolloidRoadRashCare:
        return hasHydrocolloidDressingsStock;
      case RecoveryProtocolType.activeCoolDownRollers:
        return mobileCoolDownRollersCount > 0;
      case RecoveryProtocolType.coldWaterImmersion:
        return true; // Dostępne w każdym hotelu/mobilnych wannach
      case RecoveryProtocolType.physiotherapyManualTherapy:
        return true; // Dostępne z personelem fizjoterapeutycznym i soigneurami zespołu
    }
  }

  TeamRecoveryCenterFacilities copyWith({
    bool? hasCompressionBoots,
    bool? hasCryotherapyChamber,
    bool? hasHyperbaricOxygenChamber,
    bool? hasDrySaunaFacility,
    bool? hasHydrocolloidDressingsStock,
    int? mobileCoolDownRollersCount,
    bool? hasPointOfCareBloodAnalyzer,
    bool? hasPhysiotherapyTechSuite,
  }) {
    return TeamRecoveryCenterFacilities(
      hasCompressionBoots: hasCompressionBoots ?? this.hasCompressionBoots,
      hasCryotherapyChamber:
          hasCryotherapyChamber ?? this.hasCryotherapyChamber,
      hasHyperbaricOxygenChamber:
          hasHyperbaricOxygenChamber ?? this.hasHyperbaricOxygenChamber,
      hasDrySaunaFacility: hasDrySaunaFacility ?? this.hasDrySaunaFacility,
      hasHydrocolloidDressingsStock:
          hasHydrocolloidDressingsStock ?? this.hasHydrocolloidDressingsStock,
      mobileCoolDownRollersCount:
          mobileCoolDownRollersCount ?? this.mobileCoolDownRollersCount,
      hasPointOfCareBloodAnalyzer:
          hasPointOfCareBloodAnalyzer ?? this.hasPointOfCareBloodAnalyzer,
      hasPhysiotherapyTechSuite:
          hasPhysiotherapyTechSuite ?? this.hasPhysiotherapyTechSuite,
    );
  }

  Map<String, dynamic> toJson() => {
        'hasCompressionBoots': hasCompressionBoots,
        'hasCryotherapyChamber': hasCryotherapyChamber,
        'hasHyperbaricOxygenChamber': hasHyperbaricOxygenChamber,
        'hasDrySaunaFacility': hasDrySaunaFacility,
        'hasHydrocolloidDressingsStock': hasHydrocolloidDressingsStock,
        'mobileCoolDownRollersCount': mobileCoolDownRollersCount,
        'hasPointOfCareBloodAnalyzer': hasPointOfCareBloodAnalyzer,
        'hasPhysiotherapyTechSuite': hasPhysiotherapyTechSuite,
      };

  factory TeamRecoveryCenterFacilities.fromJson(Map<String, dynamic> json) {
    return TeamRecoveryCenterFacilities(
      hasCompressionBoots: json['hasCompressionBoots'] as bool? ?? true,
      hasCryotherapyChamber: json['hasCryotherapyChamber'] as bool? ?? false,
      hasHyperbaricOxygenChamber:
          json['hasHyperbaricOxygenChamber'] as bool? ?? false,
      hasDrySaunaFacility: json['hasDrySaunaFacility'] as bool? ?? false,
      hasHydrocolloidDressingsStock:
          json['hasHydrocolloidDressingsStock'] as bool? ?? true,
      mobileCoolDownRollersCount:
          (json['mobileCoolDownRollersCount'] as num?)?.toInt() ?? 4,
      hasPointOfCareBloodAnalyzer:
          json['hasPointOfCareBloodAnalyzer'] as bool? ?? false,
      hasPhysiotherapyTechSuite:
          json['hasPhysiotherapyTechSuite'] as bool? ?? false,
    );
  }
}

/// Główny silnik zarządzania procedurami regeneracyjnymi kolarzy.
class RecoveryProtocolSystem {
  RecoveryProtocolSystem._();

  /// Katalog wszystkich 7 protokołów regeneracyjnych WorldTour
  static final Map<RecoveryProtocolType, RecoveryProtocol> _protocols = {
    RecoveryProtocolType.pneumaticCompressionBoots: const RecoveryProtocol(
      type: RecoveryProtocolType.pneumaticCompressionBoots,
      name: 'Nogawki do drenażu limfatycznego (NormaTec / Kompresja)',
      description:
          'Sekwencyjny ucisk pneumatyczny na kończyny dolne. Zmniejsza opuchliznę nóg i przyspiesza usuwanie resztek mleczanu.',
      physiologicalMechanism:
          'Wspomaganie powrotu żylno-limfatycznego poprzez pulsacyjną falę ciśnienia (30-100 mmHg). '
          'Redukcja objawów "ciężkich nóg" i obniżenie ostrego zmęczenia ATL o 10%.',
      durationMinutes: 30,
      costEur: 15,
      atlReductionPercent: 10.0,
      acidosisClearanceFactor: 0.45,
      domsReliefPercent: 25.0,
      sleepQualityBonusPercent: 10.0,
      isMobileBusCompatible: true,
      requiredDoctorSkill: 25,
    ),
    RecoveryProtocolType.wholeBodyCryotherapy: const RecoveryProtocol(
      type: RecoveryProtocolType.wholeBodyCryotherapy,
      name: 'Krioterapia ogólnoustrojowa (-110°C do -140°C)',
      description:
          '3-minutowa ekspozycja w kriokomorze. Błyskawiczny skurcz naczyń, wyrzut endorfin i tłumienie kinazy kreatynowej.',
      physiologicalMechanism:
          'Mocna wazokonstrykcja obwodowa, a po wyjściu reaktywne przekrwienie (hiperemia). '
          'Radykalne zbijanie kinazy kreatynowej (CK) i mediatorów stanu zapalnego (IL-6, TNF-alfa). Zmniejsza ATL o 18%.',
      durationMinutes: 3,
      costEur: 75,
      atlReductionPercent: 18.0,
      acidosisClearanceFactor: 0.60,
      domsReliefPercent: 40.0,
      sleepQualityBonusPercent: 15.0,
      isMobileBusCompatible: false,
      requiredDoctorSkill: 60,
    ),
    RecoveryProtocolType.hyperbaricOxygenTherapy: const RecoveryProtocol(
      type: RecoveryProtocolType.hyperbaricOxygenTherapy,
      name: 'Komora hiperbaryczna (HBOT 1.75 ATA 100% O2)',
      description:
          'Dotlenienie tkanek pod podwyższonym ciśnieniem. Błyskawiczna regeneracja mikrourazów mięśni i biogeneza mitochondriów.',
      physiologicalMechanism:
          'Nasycenie osocza tlenem fizycznie rozpuszczonym (prawo Henry\'ego). '
          'Pobudzenie angiogenezy, syntezy kolagenu oraz usuwanie obrzęków wewnątrzkomórkowych. Obniża ATL aż o 22%.',
      durationMinutes: 60,
      costEur: 150,
      atlReductionPercent: 22.0,
      acidosisClearanceFactor: 0.70,
      domsReliefPercent: 50.0,
      sleepQualityBonusPercent: 20.0,
      isMobileBusCompatible: false,
      requiredDoctorSkill: 75,
    ),
    RecoveryProtocolType.drySaunaHeatAcclimation: const RecoveryProtocol(
      type: RecoveryProtocolType.drySaunaHeatAcclimation,
      name: 'Sauna sucha – Adaptacja cieplna (Heat Acclimation)',
      description:
          '30-40 min w 85-90°C po wysiłku. Zwiększa objętość osocza krwi (+5-8%) i podnosi wskaźnik Heat Tolerance.',
      physiologicalMechanism:
          'Hipertermia kontrolowana stymuluje uwalnianie białek szoku cieplnego (HSP70) i retencję sodu przez aldosteron. '
          'Długoterminowo rozszerza objętość osocza o 6%, obniża tętno wysiłkowe i podnosi tolerancję upałów (+2 punkty do Heat Tolerance).',
      durationMinutes: 35,
      costEur: 30,
      atlReductionPercent: -3.0, // Przejściowy wydatek energetyczny dodaje minimalnie zmęczenia
      acidosisClearanceFactor: 0.20,
      domsReliefPercent: 15.0,
      heatToleranceGain: 2.0,
      plasmaVolumeExpansionPercent: 6.0,
      sleepQualityBonusPercent: 5.0,
      isMobileBusCompatible: false,
      requiredDoctorSkill: 40,
    ),
    RecoveryProtocolType.hydrocolloidRoadRashCare: const RecoveryProtocol(
      type: RecoveryProtocolType.hydrocolloidRoadRashCare,
      name: 'Opatrunki hydrokoloidowe na szlify (Road Rash Care)',
      description:
          'Wilgotne leczenie otarć powypadkowych. Uśmierza ból, zapobiega przywieraniu do pościeli i przyspiesza gojenie o 2-3 dni.',
      physiologicalMechanism:
          'Opatrunki poliuretanowo-hydrokoloidowe utrzymują optymalne wilgotne środowisko rany, stymulując migrację keratynocytów '
          'i naskórkowanie bez tworzenia twardego strupa pękającego podczas pedałowania. Skraca czas leczenia o 2 dni.',
      durationMinutes: 20,
      costEur: 45,
      atlReductionPercent: 8.0, // Zniesienie bólu obniża wyczerpanie układu nerwowego
      acidosisClearanceFactor: 0.10,
      domsReliefPercent: 10.0,
      roadRashDaysReduction: 2,
      sleepQualityBonusPercent: 30.0, // Kolarz może spać bez bólu i przyklejania się
      isMobileBusCompatible: true,
      requiredDoctorSkill: 35,
    ),
    RecoveryProtocolType.activeCoolDownRollers: const RecoveryProtocol(
      type: RecoveryProtocolType.activeCoolDownRollers,
      name: 'Rozjazd na trenażerze po etapie (Active Cool-Down)',
      description:
          '15 minut w strefie Z1 (100-130W) w strefie mety. Wymusza przepływ krwi i zapobiega zaleganiu mleczanu.',
      physiologicalMechanism:
          'Praca mięśni nóg jako pompy mięśniowej utrzymuje powrót krwi do serca, przyspiesza utlenianie mleczanu '
          'przez serce i mięśnie wolnokurczliwe (utlenianie do pirogronianu).',
      durationMinutes: 15,
      costEur: 0,
      atlReductionPercent: 5.0,
      acidosisClearanceFactor: 0.35,
      domsReliefPercent: 15.0,
      sleepQualityBonusPercent: 5.0,
      isMobileBusCompatible: true,
      requiredDoctorSkill: 10,
    ),
    RecoveryProtocolType.coldWaterImmersion: const RecoveryProtocol(
      type: RecoveryProtocolType.coldWaterImmersion,
      name: 'Kąpiel w lodzie (Ice Bath 10-12°C)',
      description:
          '10-12 min zanurzenia w zimnej wodzie. Natychmiastowe obniżenie temperatury głębokiej i obrzęków.',
      physiologicalMechanism:
          'Wazokonstrykcja i redukcja przewodnictwa nerwowego uśmierzają ból mięśniowy i zmniejszają mikrowylewy.',
      durationMinutes: 12,
      costEur: 20,
      atlReductionPercent: 12.0,
      acidosisClearanceFactor: 0.50,
      domsReliefPercent: 30.0,
      sleepQualityBonusPercent: 10.0,
      isMobileBusCompatible: false,
      requiredDoctorSkill: 30,
    ),
    RecoveryProtocolType.physiotherapyManualTherapy: const RecoveryProtocol(
      type: RecoveryProtocolType.physiotherapyManualTherapy,
      name: 'Fizjoterapia i terapia manualna (Masaż głęboki & Powięziowy)',
      description:
          'Głęboki masaż powięziowy soigneurów, drenaż manualny i rozluźnianie punktów spustowych nóg po etapie.',
      physiologicalMechanism:
          'Mechaniczne rozluźnienie napięć powięziowych, obniżenie powysiłkowej kinazy kreatynowej (CK) o 35% oraz bolesności DOMS o 45%. '
          'Przywraca optymalną biomechanikę stawu kolanowego i biodrowego.',
      durationMinutes: 45,
      costEur: 80,
      atlReductionPercent: 14.0,
      acidosisClearanceFactor: 0.65,
      domsReliefPercent: 45.0,
      sleepQualityBonusPercent: 20.0,
      isMobileBusCompatible: true,
      requiredDoctorSkill: 35,
    ),
  };

  /// Lista wszystkich dostępnych protokołów
  static List<RecoveryProtocol> get allProtocols => _protocols.values.toList();

  /// Pobiera protokół według jego typu
  static RecoveryProtocol getProtocol(RecoveryProtocolType type) {
    return _protocols[type] ?? _protocols[RecoveryProtocolType.pneumaticCompressionBoots]!;
  }

  /// Stosuje wybrany protokół regeneracyjny na kolarzu i zwraca zaktualizowanego kolarza ([Rider])
  /// wraz ze szczegółowym raportem medycznym ([RecoveryProtocolExecutionReport]).
  static (Rider updatedRider, RecoveryProtocolExecutionReport report) applyProtocol({
    required Rider rider,
    required RecoveryProtocolType protocolType,
    int teamDoctorSkillLevel = 70,
  }) {
    final protocol = getProtocol(protocolType);

    // 1. Bieżące parametry zdrowotne i zmęczenie
    final double initialAtl = rider.health.acuteTrainingLoad;
    final double initialCtl = rider.health.chronicTrainingLoad;
    final double initialTsb = rider.health.trainingStressBalance;
    final int initialHeatTolerance = rider.skills.heatTolerance;

    // Sprawdzenie szlifu powypadkowego (RoadRash)
    final bool hadRoadRash =
        rider.health.currentInjury?.type == InjuryType.roadRash;
    final int initialRoadRashDays =
        hadRoadRash ? (rider.health.currentInjury?.daysRemaining ?? 0) : 0;

    // 2. Modyfikator skuteczności zależny od umiejętności lekarzy drużyny (0.85 - 1.25)
    final double doctorSkillFactor =
        0.85 + ((teamDoctorSkillLevel - 20) / 80.0) * 0.40;

    // 3. Obliczenie redukcji ostrego zmęczenia (ATL)
    double effectiveAtlReduction = 0.0;
    if (protocol.atlReductionPercent > 0) {
      effectiveAtlReduction =
          initialAtl * (protocol.atlReductionPercent / 100.0) * doctorSkillFactor;
    } else if (protocol.atlReductionPercent < 0) {
      // Sauna powoduje chwilowy wydatek i minimalny wzrost zmęczenia (+3%)
      effectiveAtlReduction =
          initialAtl * (protocol.atlReductionPercent / 100.0);
    }

    final double finalAtl =
        math.max(5.0, initialAtl - effectiveAtlReduction);
    final double atlReduced = initialAtl - finalAtl;
    final double finalTsb = initialCtl - finalAtl;

    // 4. Adaptacja cieplna (Sauna): podnosi wskaźnik heatTolerance
    int heatToleranceDelta = 0;
    int finalHeatTolerance = initialHeatTolerance;

    if (protocol.heatToleranceGain > 0) {
      // Wzrost o 1 do 2 punktów, max 99
      final double gain = protocol.heatToleranceGain * doctorSkillFactor;
      heatToleranceDelta = gain.round().clamp(1, 3);
      finalHeatTolerance = (initialHeatTolerance + heatToleranceDelta).clamp(1, 99);
    }

    // 5. Leczenie szlifów (Opatrunki hydrokoloidowe)
    int finalRoadRashDays = initialRoadRashDays;
    bool isRoadRashFullyHealed = false;
    Injury? updatedInjury = rider.health.currentInjury;

    if (hadRoadRash && protocol.roadRashDaysReduction > 0) {
      final daysReduction =
          (protocol.roadRashDaysReduction * (doctorSkillFactor >= 1.0 ? 1 : 1))
              .round();
      finalRoadRashDays = math.max(0, initialRoadRashDays - daysReduction);

      if (finalRoadRashDays <= 0) {
        isRoadRashFullyHealed = true;
        updatedInjury = null; // Szlif całkowicie wyleczony!
      } else {
        updatedInjury = rider.health.currentInjury?.copyWith(
          daysRemaining: finalRoadRashDays,
        );
      }
    }

    // 6. Generowanie uwag i podsumowania medycznego
    final physiologicalNotes = <String>[];
    String medicalSummary = '';

    switch (protocolType) {
      case RecoveryProtocolType.pneumaticCompressionBoots:
        medicalSummary =
            'Drenaż limfatyczny udrożnił powrót żylny. Zmęczenie ATL spadło o ${atlReduced.toStringAsFixed(1)} pkt, '
            'nogi odzyskały lekkość.';
        physiologicalNotes.add('Spadek ciśnienia hydrostatycznego w łydkach o 45%.');
        physiologicalNotes.add('Szybsze wypłukanie resztek jonów H+ i mleczanu.');
        break;

      case RecoveryProtocolType.wholeBodyCryotherapy:
        medicalSummary =
            'Krioterapia (-110°C) zbiła stan zapalny i kinazę kreatynową. Wyraźny spadek zmęczenia (ATL -${atlReduced.toStringAsFixed(1)}).';
        physiologicalNotes.add('Ekspresowe obniżenie temperatury powierzchownej tkanek.');
        physiologicalNotes.add('Silny wyrzut noradrenaliny i endorfin zmniejsza bolesność mięśni.');
        break;

      case RecoveryProtocolType.hyperbaricOxygenTherapy:
        medicalSummary =
            'Komora hiperbaryczna (HBOT) maksymalnie natleniła uszkodzone włókna mięśniowe. ATL zredukowane o ${atlReduced.toStringAsFixed(1)} pkt!';
        physiologicalNotes.add('Nasycenie osocza tlenem rozpuszczonym wzrosło 4-krotnie.');
        physiologicalNotes.add('Stymulacja syntezy ATP w mitochondriach komórek mięśniowych.');
        break;

      case RecoveryProtocolType.drySaunaHeatAcclimation:
        medicalSummary =
            'Sesja sauny suchej: tolerancja upałów (Heat Tolerance) wzrosła z $initialHeatTolerance do $finalHeatTolerance pkt! '
            'Zwiększono objętość osocza krwi.';
        physiologicalNotes.add('Rozszerzenie objętości osocza o +6% pod gorące etapy Touru.');
        physiologicalNotes.add('Wyrzut białek szoku cieplnego HSP70 zabezpiecza przed przegrzaniem.');
        break;

      case RecoveryProtocolType.hydrocolloidRoadRashCare:
        if (hadRoadRash) {
          medicalSummary = isRoadRashFullyHealed
              ? 'Opatrunki hydrokoloidowe całkowicie wyleczyły szlif powypadkowy! Brak bólu i pełna mobilność.'
              : 'Opatrunki hydrokoloidowe zabezpieczyły ranę: czas gojenia szlifu skrócony do $finalRoadRashDays dni (o ${protocol.roadRashDaysReduction} dni szybciej!).';
          physiologicalNotes.add('Wilgotne środowisko rany przyspiesza naskórkowanie 2-krotnie.');
          physiologicalNotes.add('Całkowite zniesienie pieczenia i bólu kontaktowego podczas snu.');
        } else {
          medicalSummary =
              'Zastosowano profilaktyczną pielęgnację skóry i mikrourazów kolarza.';
        }
        break;

      case RecoveryProtocolType.activeCoolDownRollers:
        medicalSummary =
            '15 minut rozjazdu na trenażerze po etapie: kwas mlekowy został szybko utleniony do pirogronianu.';
        physiologicalNotes.add('Płynne przejście z wysokiego rzutu serca do spoczynku bez zasłabnięć.');
        break;

      case RecoveryProtocolType.coldWaterImmersion:
        medicalSummary =
            'Kąpiel w lodzie (11°C): temperatura mięśniowa obniżona, bolesność DOMS zredukowana o 30%.';
        physiologicalNotes.add('Wazokonstrykcja ogranicza obrzęki mikronaczyniowe w czworogłowych.');
        break;

      case RecoveryProtocolType.physiotherapyManualTherapy:
        medicalSummary =
            'Terapia manualna i masaż głęboki: rozluźniono powięź i pasma biodrowo-piszczelowe. Zmęczenie ATL spadło o ${atlReduced.toStringAsFixed(1)} pkt.';
        physiologicalNotes.add('Spadek powysiłkowego stężenia kinazy kreatynowej (CK) o 35%.');
        physiologicalNotes.add('Bolesność mięśniowa (DOMS) zredukowana o 45%, przywrócona ruchomość bioder.');
        break;
    }

    // 7. Konstrukcja zaktualizowanego modelu kolarza ([Rider])
    final updatedHealth = rider.health.copyWith(
      acuteTrainingLoadAtl: finalAtl,
      currentInjury: updatedInjury,
      clearInjury: isRoadRashFullyHealed,
    );

    final updatedPhysiology = rider.physiology.copyWith(
      acuteFatigueAtl: finalAtl,
    );

    final updatedSkills = rider.skills.copyWith(
      heatTolerance: finalHeatTolerance,
    );

    final updatedRider = rider.copyWith(
      health: updatedHealth,
      physiology: updatedPhysiology,
      skills: updatedSkills,
    );

    final report = RecoveryProtocolExecutionReport(
      riderId: rider.id,
      riderName: rider.fullName,
      protocol: protocol,
      initialAtl: _roundToOneDecimal(initialAtl),
      finalAtl: _roundToOneDecimal(finalAtl),
      atlReduced: _roundToOneDecimal(atlReduced),
      initialTsb: _roundToOneDecimal(initialTsb),
      finalTsb: _roundToOneDecimal(finalTsb),
      acidosisReducedPercent: _roundToOneDecimal(protocol.acidosisClearanceFactor * 100.0),
      initialHeatTolerance: initialHeatTolerance,
      finalHeatTolerance: finalHeatTolerance,
      heatToleranceDelta: heatToleranceDelta,
      hadRoadRash: hadRoadRash,
      initialRoadRashDays: initialRoadRashDays,
      finalRoadRashDays: finalRoadRashDays,
      isRoadRashFullyHealed: isRoadRashFullyHealed,
      costEur: protocol.costEur,
      medicalSummary: medicalSummary,
      physiologicalNotes: physiologicalNotes,
    );

    return (updatedRider, report);
  }

  /// Rekomenduje optymalne protokoły regeneracyjne dla danego kolarza na podstawie
  /// obciążenia etapu (TSS), obecności szlifów powypadkowych oraz nadchodzącej fali upałów.
  static List<RecoveryProtocolType> recommendProtocols({
    required Rider rider,
    double stageTss = 180.0,
    bool hadCrash = false,
    bool upcomingHotStage = false,
    double upcomingTemperatureCelsius = 22.0,
  }) {
    final recommendations = <RecoveryProtocolType>[];

    // 1. Zawsze po ciężkim etapie: aktywny rozjazd w strefie mety
    if (stageTss >= 140.0) {
      recommendations.add(RecoveryProtocolType.activeCoolDownRollers);
    }

    // 2. Jeśli kolarz zaliczył kraksę i ma szlify powypadkowe (Road Rash)
    final hasRoadRash =
        hadCrash || rider.health.currentInjury?.type == InjuryType.roadRash;
    if (hasRoadRash) {
      recommendations.add(RecoveryProtocolType.hydrocolloidRoadRashCare);
    }

    // 3. Po ekstremalnym etapie górskim (TSS > 250 lub wysokie zmęczenie ATL > 70)
    if (stageTss >= 250.0 || rider.health.acuteTrainingLoad >= 70.0) {
      // Wybór między krioterapią a komorą hiperbaryczną
      recommendations.add(RecoveryProtocolType.hyperbaricOxygenTherapy);
      recommendations.add(RecoveryProtocolType.wholeBodyCryotherapy);
    } else if (stageTss >= 160.0) {
      // Standardowy etap wyścigowy: nogawki kompresyjne w autobusie
      recommendations.add(RecoveryProtocolType.pneumaticCompressionBoots);
    }

    // 4. Nadchodząca fala upałów (etap > 30°C np. Ventoux / Vuelta), a kolarz ma niskie heatTolerance
    if ((upcomingHotStage || upcomingTemperatureCelsius >= 30.0) &&
        rider.skills.heatTolerance < 85) {
      recommendations.add(RecoveryProtocolType.drySaunaHeatAcclimation);
    }

    // 5. Wysokie mikrourazy / zmęczenie lub uraz stawowo-mięśniowy: fizjoterapia manualna
    if (rider.health.acuteTrainingLoad >= 65.0 || rider.health.currentInjury != null) {
      recommendations.add(RecoveryProtocolType.physiotherapyManualTherapy);
    }

    return recommendations.toSet().toList(); // Unikalne rekomendacje
  }

  static double _roundToOneDecimal(double val) {
    return (val * 10.0).round() / 10.0;
  }
}
