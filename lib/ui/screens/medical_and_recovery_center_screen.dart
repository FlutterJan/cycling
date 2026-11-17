// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/career/recovery_protocol_system.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_health.dart';
import '../../services/generators/rider_procedural_generator.dart';
import '../../state/career_controller.dart';
import '../widgets/nutrition_strategy_planner_panel.dart';
import '../widgets/rider_avatar_painter.dart';

/// Status laboratoryjny panelu morfologii i biomarkerów krwi kolarza.
enum BloodPanelStatus {
  optimal,
  nearUciLimit,
  lowFerritin,
  anemiaRisk,
  highViscosity;

  String get label {
    switch (this) {
      case BloodPanelStatus.optimal:
        return 'Optymalny';
      case BloodPanelStatus.nearUciLimit:
        return 'Granica UCI (50% Hct)';
      case BloodPanelStatus.lowFerritin:
        return 'Niska ferrytyna';
      case BloodPanelStatus.anemiaRisk:
        return 'Ryzyko anemii';
      case BloodPanelStatus.highViscosity:
        return 'Zagęszczenie krwi';
    }
  }

  Color get color {
    switch (this) {
      case BloodPanelStatus.optimal:
        return AppColors.statusSuccess;
      case BloodPanelStatus.nearUciLimit:
        return AppColors.crimsonAlert;
      case BloodPanelStatus.lowFerritin:
        return AppColors.amberWarning;
      case BloodPanelStatus.anemiaRisk:
        return AppColors.crimsonAlert;
      case BloodPanelStatus.highViscosity:
        return AppColors.amberWarning;
    }
  }
}

/// Stopień nasilenia mikrourazów mięśniowych (mikronaderwania miocytów i kinaza kreatynowa CK).
enum MuscleDamageSeverity {
  minimal,
  moderate,
  high,
  severe;

  String get label {
    switch (this) {
      case MuscleDamageSeverity.minimal:
        return 'Fizjologiczny (Brak mikrourazów)';
      case MuscleDamageSeverity.moderate:
        return 'Umiarkowane mikrourazy';
      case MuscleDamageSeverity.high:
        return 'Wysokie uszkodzenia włókien';
      case MuscleDamageSeverity.severe:
        return 'Krytyczne zniszczenie (Rabdomioliza)';
    }
  }

  Color get color {
    switch (this) {
      case MuscleDamageSeverity.minimal:
        return AppColors.statusSuccess;
      case MuscleDamageSeverity.moderate:
        return AppColors.goldAccent;
      case MuscleDamageSeverity.high:
        return AppColors.amberWarning;
      case MuscleDamageSeverity.severe:
        return AppColors.crimsonAlert;
    }
  }
}

/// Pełny profil medyczno-biologiczny kolarza w Centrum Odnowy Zespołu.
class RiderMedicalProfile {
  final Rider rider;
  final double systemicFatigueAtl;
  final double chronicFitnessCtl;
  final double tsb;
  final double creatineKinaseUL;
  final double domsSeverityPercent;
  final MuscleDamageSeverity muscleDamageLevel;
  final double hematocritPercent;
  final double hemoglobinGDL;
  final double ferritinNgMl;
  final double plasmaVolumeExpansionPercent;
  final BloodPanelStatus bloodStatus;
  final Injury? currentInjury;
  final DateTime lastBloodTestDate;
  final List<String> clinicalNotes;
  final List<RecoveryProtocolExecutionReport> recentTreatments;
  final bool isFitToRace;

  const RiderMedicalProfile({
    required this.rider,
    required this.systemicFatigueAtl,
    required this.chronicFitnessCtl,
    required this.tsb,
    required this.creatineKinaseUL,
    required this.domsSeverityPercent,
    required this.muscleDamageLevel,
    required this.hematocritPercent,
    required this.hemoglobinGDL,
    required this.ferritinNgMl,
    required this.plasmaVolumeExpansionPercent,
    required this.bloodStatus,
    required this.currentInjury,
    required this.lastBloodTestDate,
    required this.clinicalNotes,
    this.recentTreatments = const [],
    required this.isFitToRace,
  });

  /// Generuje realistyczny fizjologiczny profil medyczny dla kolarza
  factory RiderMedicalProfile.fromRider(
    Rider rider, {
    DateTime? bloodTestDate,
    double? customCk,
    double? customFerritin,
    List<RecoveryProtocolExecutionReport>? pastTreatments,
  }) {
    final atl = rider.health.acuteTrainingLoad;
    final ctl = rider.health.chronicTrainingLoad;
    final tsb = rider.health.trainingStressBalance;
    final injury = rider.health.currentInjury;

    // 1. Wyliczenie kinazy kreatynowej (CK w U/L) - biomarker mikrourazów mięśni
    double ck = customCk ?? (115.0 + math.max(0.0, (atl - 28.0) * 16.5));
    if (rider.specialization == RiderSpecialization.pureSprinter ||
        rider.specialization == RiderSpecialization.versatileSprinter) {
      ck += 175.0; // Większa frakcja włókien IIx podatnych na mikrourazy
    }
    if (injury != null) {
      ck += (injury.type == InjuryType.roadRash ? 350.0 : 650.0);
    }
    ck = ck.clamp(80.0, 2900.0);

    // 2. DOMS (Bolesność powysiłkowa)
    final doms = ((ck / 1900.0) * 100.0).clamp(5.0, 100.0);

    final MuscleDamageSeverity damageLevel;
    if (ck < 320.0) {
      damageLevel = MuscleDamageSeverity.minimal;
    } else if (ck < 750.0) {
      damageLevel = MuscleDamageSeverity.moderate;
    } else if (ck < 1400.0) {
      damageLevel = MuscleDamageSeverity.high;
    } else {
      damageLevel = MuscleDamageSeverity.severe;
    }

    // 3. Hematokryt (Hct %) - norma kolarska 41.0% do 49.5%, limit UCI 50.0%
    final heatTol = rider.skills.heatTolerance;
    final plasmaExp = (heatTol > 75) ? (heatTol - 75) * 0.40 : 0.0;
    double hct = 43.6 +
        ((rider.physiology.vo2Max - 70.0) * 0.075) +
        ((ctl - 75.0) * 0.038) -
        (plasmaExp * 0.35); // Hemodilucja po saunie/adaptacji obniża pozorny Hct
    hct = ((hct * 10.0).roundToDouble()) / 10.0;
    hct = hct.clamp(41.2, 49.8);

    // 4. Hemoglobina (Hb w g/dL)
    double hb = (hct / 3.0) + (rider.physiology.vo2Max * 0.015);
    hb = ((hb * 10.0).roundToDouble()) / 10.0;

    // 5. Ferrytyna (ng/mL) - rezerwy żelaza
    double ferritin = customFerritin ??
        (155.0 -
            ((ctl - 60.0) * 0.68) -
            (rider.physiology.weightKg < 64.0 ? 32.0 : 0.0));
    ferritin = ((ferritin * 10.0).roundToDouble()) / 10.0;
    ferritin = ferritin.clamp(28.0, 310.0);

    // 6. Kwalifikacja statusu krwi
    final BloodPanelStatus bStatus;
    if (hct >= 49.0) {
      bStatus = BloodPanelStatus.nearUciLimit;
    } else if (ferritin < 42.0) {
      bStatus = BloodPanelStatus.anemiaRisk;
    } else if (ferritin < 75.0) {
      bStatus = BloodPanelStatus.lowFerritin;
    } else if (hct > 48.0 && plasmaExp <= 0.0) {
      bStatus = BloodPanelStatus.highViscosity;
    } else {
      bStatus = BloodPanelStatus.optimal;
    }

    // 7. Notatki lekarskie
    final notes = <String>[];
    if (injury != null) {
      notes.add(
          'Aktywna kontuzja: ${injury.name} (${injury.daysRemaining} dni rekonwalescencji).');
    }
    if (ck >= 900.0) {
      notes.add(
          'Wysoka kinaza kreatynowa (${ck.toStringAsFixed(0)} U/L): mikrourazy włókien mięśniowych wymagają krioterapii lub hiperbarii.');
    }
    if (ferritin < 45.0) {
      notes.add(
          'Niski poziom ferrytyny (${ferritin.toStringAsFixed(0)} ng/mL): wdrożono suplementację żelazem glukonianem z witaminą C.');
    }
    if (hct >= 49.0) {
      notes.add(
          'Hematokryt ${hct.toStringAsFixed(1)}% na granicy limitu UCI (50.0%). Wymagane pilne nawodnienie roztworami hipotonicznymi.');
    }
    if (notes.isEmpty) {
      notes.add('Wszystkie parametry fizjologiczne i morfologia w optymalnej normie WorldTour.');
    }

    return RiderMedicalProfile(
      rider: rider,
      systemicFatigueAtl: atl,
      chronicFitnessCtl: ctl,
      tsb: tsb,
      creatineKinaseUL: ck,
      domsSeverityPercent: doms,
      muscleDamageLevel: damageLevel,
      hematocritPercent: hct,
      hemoglobinGDL: hb,
      ferritinNgMl: ferritin,
      plasmaVolumeExpansionPercent: plasmaExp,
      bloodStatus: bStatus,
      currentInjury: injury,
      lastBloodTestDate: bloodTestDate ?? DateTime.now().subtract(const Duration(days: 1)),
      clinicalNotes: notes,
      recentTreatments: pastTreatments ?? [],
      isFitToRace: rider.health.isFitToRace,
    );
  }

  RiderMedicalProfile copyWith({
    Rider? rider,
    double? systemicFatigueAtl,
    double? chronicFitnessCtl,
    double? tsb,
    double? creatineKinaseUL,
    double? domsSeverityPercent,
    MuscleDamageSeverity? muscleDamageLevel,
    double? hematocritPercent,
    double? hemoglobinGDL,
    double? ferritinNgMl,
    double? plasmaVolumeExpansionPercent,
    BloodPanelStatus? bloodStatus,
    Injury? currentInjury,
    bool clearInjury = false,
    DateTime? lastBloodTestDate,
    List<String>? clinicalNotes,
    List<RecoveryProtocolExecutionReport>? recentTreatments,
    bool? isFitToRace,
  }) {
    return RiderMedicalProfile(
      rider: rider ?? this.rider,
      systemicFatigueAtl: systemicFatigueAtl ?? this.systemicFatigueAtl,
      chronicFitnessCtl: chronicFitnessCtl ?? this.chronicFitnessCtl,
      tsb: tsb ?? this.tsb,
      creatineKinaseUL: creatineKinaseUL ?? this.creatineKinaseUL,
      domsSeverityPercent: domsSeverityPercent ?? this.domsSeverityPercent,
      muscleDamageLevel: muscleDamageLevel ?? this.muscleDamageLevel,
      hematocritPercent: hematocritPercent ?? this.hematocritPercent,
      hemoglobinGDL: hemoglobinGDL ?? this.hemoglobinGDL,
      ferritinNgMl: ferritinNgMl ?? this.ferritinNgMl,
      plasmaVolumeExpansionPercent:
          plasmaVolumeExpansionPercent ?? this.plasmaVolumeExpansionPercent,
      bloodStatus: bloodStatus ?? this.bloodStatus,
      currentInjury: clearInjury ? null : (currentInjury ?? this.currentInjury),
      lastBloodTestDate: lastBloodTestDate ?? this.lastBloodTestDate,
      clinicalNotes: clinicalNotes ?? this.clinicalNotes,
      recentTreatments: recentTreatments ?? this.recentTreatments,
      isFitToRace: isFitToRace ?? this.isFitToRace,
    );
  }
}

/// Model pozycji wyposażenia medycznego w katalogu inwestycji.
class MedicalEquipmentItem {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final int costEur;
  final IconData icon;
  final String category;
  final List<String> benefits;
  final bool Function(TeamRecoveryCenterFacilities f) isPurchased;
  final TeamRecoveryCenterFacilities Function(TeamRecoveryCenterFacilities f) onPurchase;

  const MedicalEquipmentItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.costEur,
    required this.icon,
    required this.category,
    required this.benefits,
    required this.isPurchased,
    required this.onPurchase,
  });
}

/// Ekran Centrum Medycznego i Regeneracji drużyny (Medical & Recovery Center).
class MedicalAndRecoveryCenterScreen extends ConsumerStatefulWidget {
  final String? initialRiderId;
  final bool showAppBar;

  const MedicalAndRecoveryCenterScreen({
    super.key,
    this.initialRiderId,
    this.showAppBar = true,
  });

  @override
  ConsumerState<MedicalAndRecoveryCenterScreen> createState() =>
      _MedicalAndRecoveryCenterScreenState();
}

enum _MedicalRosterFilter {
  all,
  highFatigue,
  muscleDamage,
  bloodAnomalies,
  injured;

  String get label {
    switch (this) {
      case _MedicalRosterFilter.all:
        return 'Wszyscy';
      case _MedicalRosterFilter.highFatigue:
        return 'Zmęczenie (ATL > 65)';
      case _MedicalRosterFilter.muscleDamage:
        return 'Mikrourazy (CK > 600)';
      case _MedicalRosterFilter.bloodAnomalies:
        return 'Anomalie Krwi';
      case _MedicalRosterFilter.injured:
        return 'Kontuzje & Szlify';
    }
  }
}

class _MedicalAndRecoveryCenterScreenState
    extends ConsumerState<MedicalAndRecoveryCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Lista profili medycznych kolarzy
  List<RiderMedicalProfile> _medicalProfiles = [];
  int _selectedRiderIndex = 0;

  // Filtrowanie i wyszukiwanie
  _MedicalRosterFilter _currentFilter = _MedicalRosterFilter.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Infrastruktura i zaplecze odnowy biologicznej
  TeamRecoveryCenterFacilities _facilities =
      TeamRecoveryCenterFacilities.standardProTeam();
  int _medicalCenterLevel = 2; // 1-5
  int _doctorsLevel = 75; // 1-100
  int _cashBalanceEur = 480000;

  // Aktywny protokół regeneracyjny w Zakładce 2
  RecoveryProtocolType _selectedProtocol =
      RecoveryProtocolType.pneumaticCompressionBoots;

  // Ostatni raport z zabiegu
  RecoveryProtocolExecutionReport? _lastReport;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeData() {
    final careerState = ref.read(careerControllerProvider);
    final save = careerState.save;

    List<Rider> teamRiders = [];
    if (save != null) {
      _medicalCenterLevel = save.medicalCenterLevel;
      final playerTeam = save.playerTeam;
      _doctorsLevel = playerTeam.staff.doctorsLevel;
      _cashBalanceEur = playerTeam.cashBalanceEur;

      final rosterIds = playerTeam.rosterRiderIds;
      teamRiders = save.riders.where((r) => rosterIds.contains(r.id)).toList();
      if (teamRiders.isEmpty) {
        teamRiders = save.riders.take(12).toList();
      }

      // Jeżeli poziom centrum medycznego jest wysoki, dostosuj bazowe zaplecze
      if (_medicalCenterLevel >= 4) {
        _facilities = TeamRecoveryCenterFacilities.worldTourElite();
      } else if (_medicalCenterLevel >= 2) {
        _facilities = _facilities.copyWith(
          hasCompressionBoots: true,
          hasHydrocolloidDressingsStock: true,
          mobileCoolDownRollersCount: 6,
          hasPointOfCareBloodAnalyzer: true,
        );
      }
    } else {
      teamRiders = _generateDemoSquad();
      _facilities = _facilities.copyWith(
        hasCompressionBoots: true,
        hasHydrocolloidDressingsStock: true,
        hasPointOfCareBloodAnalyzer: true,
      );
    }

    _medicalProfiles = teamRiders
        .map((r) => RiderMedicalProfile.fromRider(r))
        .toList();

    // Jeśli podano initialRiderId, wybierz tego kolarza
    if (widget.initialRiderId != null) {
      final index = _medicalProfiles
          .indexWhere((p) => p.rider.id == widget.initialRiderId);
      if (index >= 0) {
        _selectedRiderIndex = index;
      }
    }
  }

  List<Rider> _generateDemoSquad() {
    // Generujemy reprezentatywną kadrę z różnymi stanami fizjologicznymi
    final r1 = RiderProceduralGenerator.generateRider(
      specialization: RiderSpecialization.gcClimber,
      targetOverallRating: 91,
    ).copyWith(
      firstName: 'Tadej',
      lastName: 'Pogačar',
      health: const RiderHealth(
        acuteTrainingLoad: 88.0,
        chronicTrainingLoad: 95.0,
      ),
    );

    final r2 = RiderProceduralGenerator.generateRider(
      specialization: RiderSpecialization.pureSprinter,
      targetOverallRating: 88,
    ).copyWith(
      firstName: 'Jasper',
      lastName: 'Philipsen',
      health: const RiderHealth(
        acuteTrainingLoad: 72.0,
        chronicTrainingLoad: 82.0,
        currentInjury: Injury(
          name: 'Asfaltowy szlif biodra i łokcia (Kraksa)',
          type: InjuryType.roadRash,
          daysRemaining: 4,
          trainingAllowed: true,
        ),
      ),
    );

    final r3 = RiderProceduralGenerator.generateRider(
      specialization: RiderSpecialization.pureClimber,
      targetOverallRating: 87,
    ).copyWith(
      firstName: 'Sepp',
      lastName: 'Kuss',
      health: const RiderHealth(
        acuteTrainingLoad: 68.0,
        chronicTrainingLoad: 86.0,
      ),
    );

    final r4 = RiderProceduralGenerator.generateRider(
      specialization: RiderSpecialization.timeTrialist,
      targetOverallRating: 89,
    ).copyWith(
      firstName: 'Filippo',
      lastName: 'Ganna',
      health: const RiderHealth(
        acuteTrainingLoad: 42.0,
        chronicTrainingLoad: 88.0,
      ),
    );

    final r5 = RiderProceduralGenerator.generateRider(
      specialization: RiderSpecialization.puncher,
      targetOverallRating: 84,
    ).copyWith(
      firstName: 'Julian',
      lastName: 'Alaphilippe',
      health: const RiderHealth(
        acuteTrainingLoad: 79.0,
        chronicTrainingLoad: 81.0,
      ),
    );

    final r6 = RiderProceduralGenerator.generateRider(
      specialization: RiderSpecialization.domestiqueEngine,
      targetOverallRating: 82,
    ).copyWith(
      firstName: 'Michał',
      lastName: 'Kwiatkowski',
      health: const RiderHealth(
        acuteTrainingLoad: 58.0,
        chronicTrainingLoad: 84.0,
      ),
    );

    return [r1, r2, r3, r4, r5, r6];
  }

  List<RiderMedicalProfile> get _filteredProfiles {
    return _medicalProfiles.where((profile) {
      // Filtr tekstu
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = profile.rider.fullName.toLowerCase();
        final country = profile.rider.countryIso.toLowerCase();
        if (!name.contains(query) && !country.contains(query)) {
          return false;
        }
      }

      // Filtr kategorii
      switch (_currentFilter) {
        case _MedicalRosterFilter.all:
          return true;
        case _MedicalRosterFilter.highFatigue:
          return profile.systemicFatigueAtl >= 65.0;
        case _MedicalRosterFilter.muscleDamage:
          return profile.creatineKinaseUL >= 600.0 ||
              profile.domsSeverityPercent >= 40.0;
        case _MedicalRosterFilter.bloodAnomalies:
          return profile.bloodStatus != BloodPanelStatus.optimal;
        case _MedicalRosterFilter.injured:
          return profile.currentInjury != null || !profile.isFitToRace;
      }
    }).toList();
  }

  void _applySelectedProtocolToRider(RiderMedicalProfile profile) {
    if (!_facilities.canExecuteProtocol(_selectedProtocol)) {
      _showFacilityLockedDialog(_selectedProtocol);
      return;
    }

    final protocol = RecoveryProtocolSystem.getProtocol(_selectedProtocol);

    // Sprawdzenie budżetu drużyny
    if (protocol.costEur > _cashBalanceEur) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Brak wystarczających funduszy (€${protocol.costEur} wymagane, stan: €$_cashBalanceEur).'),
          backgroundColor: AppColors.crimsonAlert,
        ),
      );
      return;
    }

    // Wykonanie protokołu przez silnik
    final (updatedRider, report) = RecoveryProtocolSystem.applyProtocol(
      rider: profile.rider,
      protocolType: _selectedProtocol,
      teamDoctorSkillLevel: _doctorsLevel,
    );

    // Obliczenie nowego CK po regeneracji
    double newCk = profile.creatineKinaseUL;
    if (_selectedProtocol == RecoveryProtocolType.wholeBodyCryotherapy) {
      newCk = math.max(120.0, newCk * 0.45);
    } else if (_selectedProtocol == RecoveryProtocolType.hyperbaricOxygenTherapy) {
      newCk = math.max(120.0, newCk * 0.40);
    } else if (_selectedProtocol == RecoveryProtocolType.physiotherapyManualTherapy) {
      newCk = math.max(120.0, newCk * 0.65);
    } else if (_selectedProtocol == RecoveryProtocolType.pneumaticCompressionBoots) {
      newCk = math.max(120.0, newCk * 0.75);
    }

    final updatedProfile = RiderMedicalProfile.fromRider(
      updatedRider,
      customCk: newCk,
      customFerritin: profile.ferritinNgMl,
      pastTreatments: [report, ...profile.recentTreatments],
    );

    setState(() {
      _cashBalanceEur = math.max(0, _cashBalanceEur - protocol.costEur);
      _lastReport = report;

      // Aktualizujemy profil na liście
      final index =
          _medicalProfiles.indexWhere((p) => p.rider.id == profile.rider.id);
      if (index >= 0) {
        _medicalProfiles[index] = updatedProfile;
      }
    });

    // Zapis do Riverpod CareerController
    final notifier = ref.read(careerControllerProvider.notifier);
    notifier.updateRider(updatedRider);

    _showProtocolExecutionOutcomeDialog(report, updatedProfile);
  }

  void _conductMassTeamRecovery() {
    final availableType = _facilities.hasCompressionBoots
        ? RecoveryProtocolType.pneumaticCompressionBoots
        : RecoveryProtocolType.activeCoolDownRollers;

    final protocol = RecoveryProtocolSystem.getProtocol(availableType);
    final totalCost = protocol.costEur * _medicalProfiles.length;

    if (totalCost > _cashBalanceEur) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Brak wystarczających funduszy na masowy zabieg (€$totalCost).'),
          backgroundColor: AppColors.crimsonAlert,
        ),
      );
      return;
    }

    double totalAtlSaved = 0.0;
    final updatedList = <RiderMedicalProfile>[];

    for (final profile in _medicalProfiles) {
      final (updatedRider, report) = RecoveryProtocolSystem.applyProtocol(
        rider: profile.rider,
        protocolType: availableType,
        teamDoctorSkillLevel: _doctorsLevel,
      );
      totalAtlSaved += report.atlReduced;

      final updatedProfile = RiderMedicalProfile.fromRider(
        updatedRider,
        customCk: math.max(120.0, profile.creatineKinaseUL * 0.75),
        customFerritin: profile.ferritinNgMl,
        pastTreatments: [report, ...profile.recentTreatments],
      );
      updatedList.add(updatedProfile);

      ref.read(careerControllerProvider.notifier).updateRider(updatedRider);
    }

    setState(() {
      _cashBalanceEur = math.max(0, _cashBalanceEur - totalCost);
      _medicalProfiles = updatedList;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Zrealizowano masowy zabieg (${protocol.shortName}) dla ${_medicalProfiles.length} kolarzy. '
          'Łączna redukcja zmęczenia: -${totalAtlSaved.toStringAsFixed(1)} ATL!',
        ),
        backgroundColor: AppColors.statusSuccess,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _conductBloodTestForRider(RiderMedicalProfile profile) {
    final hasAnalyzer = _facilities.hasPointOfCareBloodAnalyzer;
    final cost = hasAnalyzer ? 15 : 120;

    if (cost > _cashBalanceEur) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Brak funduszy na analizę krwi (€$cost).'),
          backgroundColor: AppColors.crimsonAlert,
        ),
      );
      return;
    }

    final updatedProfile = RiderMedicalProfile.fromRider(
      profile.rider,
      bloodTestDate: DateTime.now(),
    );

    setState(() {
      _cashBalanceEur = math.max(0, _cashBalanceEur - cost);
      final idx =
          _medicalProfiles.indexWhere((p) => p.rider.id == profile.rider.id);
      if (idx >= 0) {
        _medicalProfiles[idx] = updatedProfile;
      }
    });

    _showBloodAnalysisDialog(updatedProfile, wasPointOfCare: hasAnalyzer);
  }

  void _upgradeMedicalCenter() {
    if (_medicalCenterLevel >= 5) return;
    final upgradeCost = _getMedicalCenterUpgradeCost(_medicalCenterLevel);

    if (upgradeCost > _cashBalanceEur) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Brak środków na rozbudowę kliniki (€$upgradeCost).'),
          backgroundColor: AppColors.crimsonAlert,
        ),
      );
      return;
    }

    setState(() {
      _cashBalanceEur -= upgradeCost;
      _medicalCenterLevel += 1;
      _doctorsLevel = math.min(100, _doctorsLevel + 4);

      if (_medicalCenterLevel >= 4) {
        _facilities = _facilities.copyWith(
          hasCryotherapyChamber: true,
          hasHyperbaricOxygenChamber: true,
          hasDrySaunaFacility: true,
          hasPointOfCareBloodAnalyzer: true,
          hasPhysiotherapyTechSuite: true,
        );
      }
    });

    final save = ref.read(careerControllerProvider).save;
    if (save != null) {
      ref.read(careerControllerProvider.notifier).saveCurrentGame();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Klinika Medyczna rozbudowana do Poziomu $_medicalCenterLevel! Personel medyczny zyskał bonus do skuteczności.',
        ),
        backgroundColor: AppColors.statusSuccess,
      ),
    );
  }

  int _getMedicalCenterUpgradeCost(int currentLevel) {
    switch (currentLevel) {
      case 1:
        return 45000;
      case 2:
        return 95000;
      case 3:
        return 180000;
      case 4:
        return 350000;
      default:
        return 500000;
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Material(
      color: AppColors.background,
      child: Container(
        color: AppColors.background,
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTab1MedicalRoster(),
                  _buildTab2Protocols(),
                  _buildTab3FacilitiesAndInvestments(),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!widget.showAppBar) {
      return body;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Centrum Medyczne & Odnowa Biologiczna',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Masowy Drenaż Limfatyczny po Etapie',
            icon: const Icon(Icons.flash_on_rounded, color: AppColors.goldAccent),
            onPressed: _conductMassTeamRecovery,
          ),
          IconButton(
            tooltip: 'Informacje medyczne',
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: _showMedicalLegendDialog,
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildHeader() {
    final injuredCount = _medicalProfiles.where((p) => p.currentInjury != null).length;
    final highFatigueCount = _medicalProfiles.where((p) => p.systemicFatigueAtl >= 65.0).length;
    final avgAtl = _medicalProfiles.isEmpty
        ? 0.0
        : _medicalProfiles.map((p) => p.systemicFatigueAtl).reduce((a, b) => a + b) /
            _medicalProfiles.length;
    final avgHct = _medicalProfiles.isEmpty
        ? 0.0
        : _medicalProfiles.map((p) => p.hematocritPercent).reduce((a, b) => a + b) /
            _medicalProfiles.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder.withValues(alpha: 0.6)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 900;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryAccent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.health_and_safety_rounded,
                      color: AppColors.primaryAccent,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DZIAŁ MEDYCYNY SPORTOWEJ & REGENERACJI',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Klinika poziom $_medicalCenterLevel/5 • Lekarze poziom $_doctorsLevel/100 • Budżet: €${_formatCurrency(_cashBalanceEur)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isCompact)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.bolt_rounded, size: 18),
                      label: const Text('Masowy Drenaż Zespołu'),
                      onPressed: _conductMassTeamRecovery,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              // KPI Stat Pockets
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildKpiChip(
                    label: 'Średnie ATL (Zmęczenie)',
                    value: '${avgAtl.toStringAsFixed(1)} pkt',
                    color: avgAtl > 65.0 ? AppColors.amberWarning : AppColors.statusSuccess,
                    icon: Icons.speed_rounded,
                  ),
                  _buildKpiChip(
                    label: 'Kolarze z wysokim ATL',
                    value: '$highFatigueCount / ${_medicalProfiles.length}',
                    color: highFatigueCount > 2 ? AppColors.amberWarning : AppColors.textPrimary,
                    icon: Icons.battery_alert_rounded,
                  ),
                  _buildKpiChip(
                    label: 'Aktywne Kontuzje',
                    value: '$injuredCount',
                    color: injuredCount > 0 ? AppColors.crimsonAlert : AppColors.statusSuccess,
                    icon: Icons.healing_rounded,
                  ),
                  _buildKpiChip(
                    label: 'Średni Hematokryt (Hct)',
                    value: '${avgHct.toStringAsFixed(1)}%',
                    color: avgHct > 48.5 ? AppColors.amberWarning : AppColors.accentBlue,
                    icon: Icons.bloodtype_rounded,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildKpiChip({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
            ),
          ),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primaryAccent,
        indicatorWeight: 3,
        labelColor: AppColors.primaryAccent,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
        tabs: const [
          Tab(
            icon: Icon(Icons.medical_services_outlined, size: 20),
            text: 'Wykaz Medyczny Kolarzy',
          ),
          Tab(
            icon: Icon(Icons.spa_outlined, size: 20),
            text: 'Protokoły Odnowy & Zabiegi',
          ),
          Tab(
            icon: Icon(Icons.precision_manufacturing_outlined, size: 20),
            text: 'Inwestycje & Sprzęt Kliniki',
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: WYKAZ MEDYCZNY KOLARZY (ROSTER & BIOMARKERS)
  // ===========================================================================

  Widget _buildTab1MedicalRoster() {
    final filtered = _filteredProfiles;

    return Column(
      children: [
        // Filter bar & search
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight.withValues(alpha: 0.6),
            border: Border(bottom: BorderSide(color: AppColors.cardBorder.withValues(alpha: 0.5))),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              final searchField = SizedBox(
                width: isWide ? 280 : double.infinity,
                height: 40,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    hintText: 'Szukaj kolarza lub narodowości...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.cardBorder.withValues(alpha: 0.5)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.cardBorder.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              );

              final filterChips = Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _MedicalRosterFilter.values.map((filter) {
                  final isSelected = _currentFilter == filter;
                  return ChoiceChip(
                    label: Text(filter.label),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        _currentFilter = filter;
                      });
                    },
                    selectedColor: AppColors.primaryAccent.withValues(alpha: 0.25),
                    backgroundColor: AppColors.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primaryAccent : AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primaryAccent
                          : AppColors.cardBorder.withValues(alpha: 0.6),
                    ),
                  );
                }).toList(),
              );

              if (isWide) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: filterChips),
                    const SizedBox(width: 16),
                    searchField,
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    searchField,
                    const SizedBox(height: 10),
                    filterChips,
                  ],
                );
              }
            },
          ),
        ),

        // Roster Cards List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      const Text(
                        'Brak kolarzy spełniających wybrane kryteria.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final profile = filtered[index];
                    return _buildRiderMedicalCard(profile);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRiderMedicalCard(RiderMedicalProfile profile) {
    final rider = profile.rider;
    final injury = profile.currentInjury;
    final isInjured = injury != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isInjured
              ? AppColors.crimsonAlert.withValues(alpha: 0.7)
              : (profile.systemicFatigueAtl > 75.0
                  ? AppColors.amberWarning.withValues(alpha: 0.6)
                  : AppColors.cardBorder.withValues(alpha: 0.5)),
          width: isInjured ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Name + Specialization + Race Clearance Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RiderAvatarWidget(
                  appearance: rider.appearance,
                  size: 46,
                  showHelmet: false,
                  showGlasses: false,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              rider.fullName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              rider.countryIso,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${rider.specialization.displayName} • ${rider.age} lat • W/kg: ${rider.physiology.wattsPerKg.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Injury or Fit-to-Race badge
                if (isInjured)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.crimsonAlert.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.crimsonAlert),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 14, color: AppColors.crimsonAlert),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${injury.name} (${injury.daysRemaining}d)',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.crimsonAlert,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.statusSuccess.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.statusSuccess.withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 14, color: AppColors.statusSuccess),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Zdolny do rywalizacji',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.statusSuccess,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: AppColors.surfaceLight, height: 1),
            const SizedBox(height: 14),

            // 4 Metrics Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 650;
                final colWidth = isWide
                    ? (constraints.maxWidth - 36) / 4
                    : (constraints.maxWidth - 12) / 2;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    // Metric 1: Systemic Fatigue (ATL / TSB)
                    SizedBox(
                      width: colWidth,
                      child: _buildMetricTile(
                        title: 'Zmęczenie Układowe (ATL)',
                        value: '${profile.systemicFatigueAtl.toStringAsFixed(1)} pkt',
                        subtext: 'TSB: ${profile.tsb > 0 ? '+' : ''}${profile.tsb.toStringAsFixed(1)} (Świeżość)',
                        progress: (profile.systemicFatigueAtl / 100.0).clamp(0.0, 1.0),
                        progressColor: profile.systemicFatigueAtl > 75.0
                            ? AppColors.crimsonAlert
                            : (profile.systemicFatigueAtl > 50.0
                                ? AppColors.amberWarning
                                : AppColors.statusSuccess),
                        icon: Icons.battery_charging_full_rounded,
                      ),
                    ),

                    // Metric 2: Muscle Damage (CK & DOMS)
                    SizedBox(
                      width: colWidth,
                      child: _buildMetricTile(
                        title: 'Kinaza Kreatynowa (CK)',
                        value: '${profile.creatineKinaseUL.toStringAsFixed(0)} U/L',
                        subtext: 'Bolesność DOMS: ${profile.domsSeverityPercent.toStringAsFixed(0)}%',
                        progress: (profile.creatineKinaseUL / 2000.0).clamp(0.0, 1.0),
                        progressColor: profile.muscleDamageLevel.color,
                        icon: Icons.fitness_center_rounded,
                      ),
                    ),

                    // Metric 3: Hematocrit (Hct)
                    SizedBox(
                      width: colWidth,
                      child: _buildMetricTile(
                        title: 'Hematokryt (Hct)',
                        value: '${profile.hematocritPercent.toStringAsFixed(1)}%',
                        subtext: 'Hb: ${profile.hemoglobinGDL.toStringAsFixed(1)} g/dL (Limit UCI 50%)',
                        progress: ((profile.hematocritPercent - 40.0) / 10.0).clamp(0.0, 1.0),
                        progressColor: profile.bloodStatus.color,
                        icon: Icons.bloodtype_rounded,
                      ),
                    ),

                    // Metric 4: Ferritin (Iron Storage)
                    SizedBox(
                      width: colWidth,
                      child: _buildMetricTile(
                        title: 'Ferrytyna (Żelazo)',
                        value: '${profile.ferritinNgMl.toStringAsFixed(0)} ng/mL',
                        subtext: profile.ferritinNgMl < 45.0
                            ? 'Niedobór żelaza!'
                            : (profile.ferritinNgMl < 80.0
                                ? 'Umiarkowany poziom'
                                : 'Optymalne zapasy'),
                        progress: (profile.ferritinNgMl / 250.0).clamp(0.0, 1.0),
                        progressColor: profile.ferritinNgMl < 45.0
                            ? AppColors.crimsonAlert
                            : (profile.ferritinNgMl < 80.0
                                ? AppColors.goldAccent
                                : AppColors.statusSuccess),
                        icon: Icons.opacity_rounded,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 14),

            // Bottom Actions Bar
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.cardBorder.withValues(alpha: 0.6)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.biotech_rounded, size: 16, color: AppColors.accentBlue),
                  label: const Text('Badanie Krwi', style: TextStyle(fontSize: 12)),
                  onPressed: () => _conductBloodTestForRider(profile),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.cardBorder.withValues(alpha: 0.6)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.assignment_outlined, size: 16),
                  label: const Text('Diagnoza', style: TextStyle(fontSize: 12)),
                  onPressed: () => _showClinicalNotesDialog(profile),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  icon: const Icon(Icons.healing_rounded, size: 16),
                  label: const Text('Zastosuj Protokół', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    final idx = _medicalProfiles.indexOf(profile);
                    setState(() {
                      _selectedRiderIndex = idx >= 0 ? idx : 0;
                    });
                    _tabController.animateTo(1);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtext,
    required double progress,
    required Color progressColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: progressColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: progressColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtext,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: PROTOKOŁY REGENERACYJNE (TREATMENTS & RECOVERY CENTER)
  // ===========================================================================

  Widget _buildTab2Protocols() {
    if (_medicalProfiles.isEmpty) {
      return const Center(child: Text('Brak kolarzy w kadrze.'));
    }

    final currentProfile = _medicalProfiles[_selectedRiderIndex];
    final allProtocols = RecoveryProtocolSystem.allProtocols;
    final recommendedTypes = RecoveryProtocolSystem.recommendProtocols(
      rider: currentProfile.rider,
      stageTss: currentProfile.systemicFatigueAtl > 70 ? 260.0 : 170.0,
      hadCrash: currentProfile.currentInjury?.type == InjuryType.roadRash,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_lastReport != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.statusSuccess.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.statusSuccess.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.statusSuccess, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ostatnio wykonany zabieg (${_lastReport!.protocol.shortName}): ${_lastReport!.riderName} (ATL -${_lastReport!.atlReduced} pkt).',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          // Rider Selector Strip
          const Text(
            'WYBIERZ ZAWODNIKA DO ZABIEGU REGENERACYJNEGO',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _medicalProfiles.length,
              itemBuilder: (context, idx) {
                final prof = _medicalProfiles[idx];
                final isSelected = idx == _selectedRiderIndex;
                final isInj = prof.currentInjury != null;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRiderIndex = idx;
                    });
                  },
                  child: Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryAccent.withValues(alpha: 0.18)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryAccent
                            : (isInj
                                ? AppColors.crimsonAlert.withValues(alpha: 0.6)
                                : AppColors.cardBorder.withValues(alpha: 0.5)),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        RiderAvatarWidget(
                          appearance: prof.rider.appearance,
                          size: 38,
                          showHelmet: false,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                prof.rider.fullName,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.primaryAccent
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ATL: ${prof.systemicFatigueAtl.toStringAsFixed(0)} • CK: ${prof.creatineKinaseUL.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                              if (isInj)
                                Text(
                                  prof.currentInjury!.name,
                                  style: const TextStyle(
                                    color: AppColors.crimsonAlert,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Banner z zaleceniem lekarskim dla wybranego kolarza
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.medical_information_rounded,
                    color: AppColors.primaryAccent, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zalecenie Lekarza Zespołowego dla ${currentProfile.rider.fullName}:',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        recommendedTypes.isEmpty
                            ? 'Stan fizjologiczny stabilny. Standardowy rozjazd lub kompresja wystarczą.'
                            : 'Zalecane procedury: ${recommendedTypes.map((t) => t.shortName).join(" • ")}',
                        style: const TextStyle(
                          color: AppColors.goldAccent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'KATALOG PROCEDUR ODNOWY BIOLOGICZNEJ',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Grid of 8 protocols
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 750;
              final itemWidth = isWide
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: allProtocols.map((protocol) {
                  final isRecommended = recommendedTypes.contains(protocol.type);
                  final isUnlocked = _facilities.canExecuteProtocol(protocol.type);
                  final isSelected = _selectedProtocol == protocol.type;

                  return SizedBox(
                    width: itemWidth,
                    child: _buildProtocolCard(
                      protocol: protocol,
                      isRecommended: isRecommended,
                      isUnlocked: isUnlocked,
                      isSelected: isSelected,
                      currentProfile: currentProfile,
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          NutritionStrategyplannerPanel(
            initialRiders: [
              for (final prof in _medicalProfiles)
                RiderNutritionPlanEntry.fromRider(prof.rider),
            ],
            contextTitle: 'KLINICZNY PLAN ŻYWIENIA & TOLERANCJI ŻOŁĄDKOWEJ',
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolCard({
    required RecoveryProtocol protocol,
    required bool isRecommended,
    required bool isUnlocked,
    required bool isSelected,
    required RiderMedicalProfile currentProfile,
  }) {
    return Card(
      color: isSelected
          ? AppColors.primaryAccent.withValues(alpha: 0.12)
          : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected
              ? AppColors.primaryAccent
              : (isRecommended
                  ? AppColors.goldAccent.withValues(alpha: 0.7)
                  : AppColors.cardBorder.withValues(alpha: 0.5)),
          width: isSelected ? 2.0 : (isRecommended ? 1.5 : 1.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category + Badges (Recommended / Locked)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    protocol.category.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isRecommended)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.goldAccent),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: 12, color: AppColors.goldAccent),
                            SizedBox(width: 4),
                            Text(
                              'Rekomendowany',
                              style: TextStyle(
                                color: AppColors.goldAccent,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!isUnlocked) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.amberWarning.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.amberWarning),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline, size: 12, color: AppColors.amberWarning),
                            SizedBox(width: 4),
                            Text(
                              'Wymaga sprzętu',
                              style: TextStyle(
                                color: AppColors.amberWarning,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),
            Text(
              protocol.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              protocol.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 12),
            // Key Benefits Tags
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (protocol.atlReductionPercent > 0)
                  _buildBenefitPill(
                      '-${protocol.atlReductionPercent.toStringAsFixed(0)}% ATL Zmęczenia',
                      AppColors.statusSuccess),
                if (protocol.domsReliefPercent > 0)
                  _buildBenefitPill(
                      '-${protocol.domsReliefPercent.toStringAsFixed(0)}% Bólu DOMS',
                      AppColors.accentBlue),
                if (protocol.heatToleranceGain > 0)
                  _buildBenefitPill(
                      '+${protocol.heatToleranceGain.toStringAsFixed(0)} Heat Tolerance',
                      AppColors.amberWarning),
                if (protocol.roadRashDaysReduction > 0)
                  _buildBenefitPill(
                      '-${protocol.roadRashDaysReduction} dni gojenia szlifu',
                      AppColors.crimsonAlert),
                if (protocol.isMobileBusCompatible)
                  _buildBenefitPill('W autobusie po etapie', AppColors.goldAccent),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(color: AppColors.surfaceLight, height: 1),
            const SizedBox(height: 12),

            // Cost & Duration + Action Button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Czas: ${protocol.durationMinutes} min • Koszt: €${protocol.costEur}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                      Text(
                        'Wymagany personel: ${protocol.requiredDoctorSkill}/100',
                        style: TextStyle(
                          color: _doctorsLevel >= protocol.requiredDoctorSkill
                              ? AppColors.textSecondary
                              : AppColors.amberWarning,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isUnlocked)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected
                          ? AppColors.primaryAccent
                          : AppColors.surfaceLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedProtocol = protocol.type;
                      });
                      _applySelectedProtocolToRider(currentProfile);
                    },
                    child: Text(
                      isSelected ? 'Wykonaj Zabieg' : 'Wybierz & Wykonaj',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  )
                else
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.amberWarning,
                      side: const BorderSide(color: AppColors.amberWarning),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      _tabController.animateTo(2);
                    },
                    child: const Text('Kup w Inwestycjach', style: TextStyle(fontSize: 11.5)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 3: INWESTYCJE W SPRZĘT & KLINIKĘ (FACILITIES & EQUIPMENT)
  // ===========================================================================

  Widget _buildTab3FacilitiesAndInvestments() {
    final equipmentCatalog = _getMedicalEquipmentCatalog();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medical Clinic Level Card
          Card(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppColors.cardBorder.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.apartment_rounded,
                            color: AppColors.goldAccent, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CENTRUM MEDYCZNE ZESPOŁU: POZIOM $_medicalCenterLevel / 5',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _getMedicalCenterLevelDescription(_medicalCenterLevel),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_medicalCenterLevel < 5)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.goldAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                          label: Text(
                            'Rozbuduj (€${_formatCurrency(_getMedicalCenterUpgradeCost(_medicalCenterLevel))})',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                          onPressed: _upgradeMedicalCenter,
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.statusSuccess.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.statusSuccess),
                          ),
                          child: const Text(
                            'MAKSYMALNY POZIOM',
                            style: TextStyle(
                              color: AppColors.statusSuccess,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _medicalCenterLevel / 5.0,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.goldAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 22),
          const Text(
            'KATALOG INWESTYCJI W APARATURĘ I SPRZĘT REGENERACYJNY',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Equipment Items List
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 750;
              final colWidth = isWide
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: equipmentCatalog.map((item) {
                  final owned = item.isPurchased(_facilities);
                  return SizedBox(
                    width: colWidth,
                    child: _buildEquipmentItemCard(item, owned),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          NutritionStrategyplannerPanel(
            initialRiders: [
              for (final prof in _medicalProfiles)
                RiderNutritionPlanEntry.fromRider(prof.rider),
            ],
            contextTitle: 'KLINICZNY PLAN ŻYWIENIA & TOLERANCJI ŻOŁĄDKOWEJ',
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentItemCard(MedicalEquipmentItem item, bool owned) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: owned
              ? AppColors.statusSuccess.withValues(alpha: 0.5)
              : AppColors.cardBorder.withValues(alpha: 0.5),
          width: owned ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: owned
                        ? AppColors.statusSuccess.withValues(alpha: 0.15)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    size: 22,
                    color: owned ? AppColors.statusSuccess : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (owned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.statusSuccess.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.statusSuccess),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check, size: 12, color: AppColors.statusSuccess),
                        SizedBox(width: 4),
                        Text(
                          'Na wyposażeniu',
                          style: TextStyle(
                            color: AppColors.statusSuccess,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: item.benefits.map((b) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_right_rounded,
                          size: 16, color: AppColors.goldAccent),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          b,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            const Divider(color: AppColors.surfaceLight, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cena: €${_formatCurrency(item.costEur)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                if (!owned)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _purchaseEquipment(item),
                    child: const Text('Kup dla Drużyny', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _purchaseEquipment(MedicalEquipmentItem item) {
    if (item.costEur > _cashBalanceEur) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Brak środków na zakup ${item.title} (€${item.costEur}).'),
          backgroundColor: AppColors.crimsonAlert,
        ),
      );
      return;
    }

    setState(() {
      _cashBalanceEur -= item.costEur;
      _facilities = item.onPurchase(_facilities);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Zakupiono ${item.title}! Protokół został natychmiast odblokowany w Centrum Odnowy.',
        ),
        backgroundColor: AppColors.statusSuccess,
      ),
    );
  }

  List<MedicalEquipmentItem> _getMedicalEquipmentCatalog() {
    return [
      MedicalEquipmentItem(
        id: 'compression_boots_fleet',
        title: 'Nogawki Kompresyjne NormaTec Pro (Flota)',
        subtitle: 'Mobilny drenaż limfatyczny dla 8 kolarzy',
        description:
            'Zestaw sekwencyjnych nogawek pneumatycznych z dedykowanymi kompresorami akumulatorowymi do busa.',
        costEur: 6000,
        icon: Icons.airline_seat_legroom_extra_rounded,
        category: 'Drenaż',
        benefits: [
          'Dostępne od zaraz w autobusie po przekroczeniu linii mety',
          'Obniża ostre zmęczenie ATL o 10% bez wysiłku sercowo-naczyniowego',
        ],
        isPurchased: (f) => f.hasCompressionBoots,
        onPurchase: (f) => f.copyWith(hasCompressionBoots: true),
      ),
      MedicalEquipmentItem(
        id: 'cryo_cabin_truck',
        title: 'Mobilna Komora Krioterapii (-110°C)',
        subtitle: 'Zabudowa w ciężarówce technicznej zespołu',
        description:
            'Ekspresowa krioterapia ogólnoustrojowa ciekłym azotem. Tłumi stan zapalny i kinazę kreatynową.',
        costEur: 65000,
        icon: Icons.ac_unit_rounded,
        category: 'Krioterapia',
        benefits: [
          'Redukcja kinazy kreatynowej (CK) o 55% po etapach górskich',
          'Radykalne zbijanie ATL o 18% w zaledwie 3 minuty',
        ],
        isPurchased: (f) => f.hasCryotherapyChamber,
        onPurchase: (f) => f.copyWith(hasCryotherapyChamber: true),
      ),
      MedicalEquipmentItem(
        id: 'hbot_chamber',
        title: 'Łagodna Komora Hiperbaryczna (HBOT 1.75 ATA)',
        subtitle: '100% tlenu medycznego pod ciśnieniem',
        description:
            'Maksymalna regeneracja tkanek i angiogeneza. Kluczowa broń na 3-tygodniowych Grand Tourach.',
        costEur: 85000,
        icon: Icons.bubble_chart_rounded,
        category: 'Hiperbaria',
        benefits: [
          'Najwyższa skuteczność: redukcja ATL aż o 22%',
          'Redukcja bolesności DOMS o 50% i przyspieszona biogeneza mitochondriów',
        ],
        isPurchased: (f) => f.hasHyperbaricOxygenChamber,
        onPurchase: (f) => f.copyWith(hasHyperbaricOxygenChamber: true),
      ),
      MedicalEquipmentItem(
        id: 'dry_sauna_module',
        title: 'Moduł Sauny Suchej w Bazie Treningowej',
        subtitle: 'Adaptacja cieplna (Heat Acclimation Chamber)',
        description:
            'Komora termiczna 85-90°C. Stymuluje ekspansję osocza (+6%) pod upały na Tour de France i Vuelcie.',
        costEur: 35000,
        icon: Icons.whatshot_rounded,
        category: 'Termoregulacja',
        benefits: [
          'Zwiększa statystykę Heat Tolerance o +2 punkty',
          'Ekspansja objętości osocza zabezpiecza kolarza przed udarem cieplnym',
        ],
        isPurchased: (f) => f.hasDrySaunaFacility,
        onPurchase: (f) => f.copyWith(hasDrySaunaFacility: true),
      ),
      MedicalEquipmentItem(
        id: 'hydrocolloid_dressings_pack',
        title: 'Zapas Opatrunków Hydrokoloidowych na Sezon',
        subtitle: 'Zaawansowane leczenie szlifów (Road Rash)',
        description:
            'Zapas wilgotnych opatrunków poliuretanowo-hydrokoloidowych na rany powypadkowe.',
        costEur: 4000,
        icon: Icons.healing_rounded,
        category: 'Dermatologia',
        benefits: [
          'Skraca gojenie szlifów o 2 dni na każdy zabieg',
          'Eliminuje ból przy kontakcie z pościelą (+30% jakości snu)',
        ],
        isPurchased: (f) => f.hasHydrocolloidDressingsStock,
        onPurchase: (f) => f.copyWith(hasHydrocolloidDressingsStock: true),
      ),
      MedicalEquipmentItem(
        id: 'point_of_care_analyzer',
        title: 'Mobilny Analizator Krwi i-STAT (w Autobusie)',
        subtitle: 'Natychmiastowy pomiar Hct, Hb, ferrytyny i gazometrii',
        description:
            'Kasetkowy analizator kropelki krwi z palca. Wyniki w 2 minuty bez wysyłania próbek do laboratorium.',
        costEur: 25000,
        icon: Icons.biotech_rounded,
        category: 'Diagnostyka',
        benefits: [
          'Błyskawiczne wykrywanie odwodnienia i niebezpiecznego hematokrytu >49%',
          'Redukuje koszt badania krwi z €120 do symbolicznych €15',
        ],
        isPurchased: (f) => f.hasPointOfCareBloodAnalyzer,
        onPurchase: (f) => f.copyWith(hasPointOfCareBloodAnalyzer: true),
      ),
      MedicalEquipmentItem(
        id: 'physiotherapy_tech_suite',
        title: 'Kombajn Fizjoterapeutyczny (Indiba Tecar & Fala)',
        subtitle: 'Terapia powięziowa i rozbijanie punktów spustowych',
        description:
            'Aparatura do radiofrekwencji monopolarnej Tecar oraz fali uderzeniowej dla soigneurów.',
        costEur: 30000,
        icon: Icons.accessibility_new_rounded,
        category: 'Fizjoterapia',
        benefits: [
          'Rozluźnia pasma biodrowo-piszczelowe i czworogłowe',
          'Zmniejsza ryzyko kontuzji przeciążeniowych kolan (Knee Tendinitis)',
        ],
        isPurchased: (f) => f.hasPhysiotherapyTechSuite,
        onPurchase: (f) => f.copyWith(hasPhysiotherapyTechSuite: true),
      ),
      MedicalEquipmentItem(
        id: 'bus_rollers_fleet',
        title: 'Flota 8 Mobilnych Trenażerów do Autobusu',
        subtitle: 'Zestaw do aktywnego rozjazdu bezpośrednio na mecie',
        description:
            'Lekkie trenażery rolkowe z oporem magnetycznym rozstawiane przy wejściu do autokaru.',
        costEur: 12000,
        icon: Icons.pedal_bike_rounded,
        category: 'Metabolizm',
        benefits: [
          'Wypłukuje kwas mlekowy w strefie mety zanim kolarz wsiądzie do busa',
          'Całkowicie bezpłatne procedury rozjazdowe po każdym etapie',
        ],
        isPurchased: (f) => f.mobileCoolDownRollersCount >= 8,
        onPurchase: (f) => f.copyWith(mobileCoolDownRollersCount: 8),
      ),
    ];
  }

  String _getMedicalCenterLevelDescription(int level) {
    switch (level) {
      case 1:
        return 'Podstawowy gabinet lekarski (Standard UCI Continental)';
      case 2:
        return 'Mobilne studio regeneracji w autobusie (Standard ProTeam)';
      case 3:
        return 'Zaawansowana stacja fizjoterapii i drenażu w ciężarówce technicznej';
      case 4:
        return 'Klinika WorldTour z komorą krioterapii i aparaturą laboratoryjną';
      case 5:
        return 'Elitarne Centrum Regeneracji (Standard UAE Emirates / Visma-Lease a Bike)';
      default:
        return '';
    }
  }

  // ===========================================================================
  // DIALOGS & OUTCOMES
  // ===========================================================================

  void _showProtocolExecutionOutcomeDialog(
    RecoveryProtocolExecutionReport report,
    RiderMedicalProfile updatedProfile,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: AppColors.statusSuccess, size: 24),
              SizedBox(width: 10),
              Text(
                'Zabieg Wykonany Pomyślnie',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${report.riderName} • ${report.protocol.shortName}',
                  style: const TextStyle(
                    color: AppColors.primaryAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _buildDeltaRow('Ostre zmęczenie (ATL):',
                          '${report.initialAtl} -> ${report.finalAtl} (-${report.atlReduced} pkt)'),
                      const SizedBox(height: 6),
                      _buildDeltaRow('Świeżość (TSB):',
                          '${report.initialTsb > 0 ? "+" : ""}${report.initialTsb} -> ${report.finalTsb > 0 ? "+" : ""}${report.finalTsb}'),
                      if (report.heatToleranceDelta > 0) ...[
                        const SizedBox(height: 6),
                        _buildDeltaRow('Heat Tolerance:',
                            '${report.initialHeatTolerance} -> ${report.finalHeatTolerance} (+${report.heatToleranceDelta})'),
                      ],
                      if (report.hadRoadRash) ...[
                        const SizedBox(height: 6),
                        _buildDeltaRow('Gojenie szlifu:',
                            report.isRoadRashFullyHealed
                                ? 'Całkowicie wyleczony!'
                                : '${report.initialRoadRashDays}d -> ${report.finalRoadRashDays}d'),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  report.medicalSummary,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: report.physiologicalNotes.map((note) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: AppColors.goldAccent)),
                          Expanded(
                            child: Text(
                              note,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Zamknij', style: TextStyle(color: AppColors.primaryAccent)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeltaRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  void _showBloodAnalysisDialog(RiderMedicalProfile profile, {required bool wasPointOfCare}) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.biotech_rounded, color: AppColors.accentBlue, size: 24),
              SizedBox(width: 10),
              Text(
                'Raport Badań Morfologii Krwi',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile.rider.fullName} • ${wasPointOfCare ? "Szybki analizator i-STAT w busie" : "Laboratorium zewnętrzne"}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _buildDeltaRow('Hematokryt (Hct):',
                          '${profile.hematocritPercent.toStringAsFixed(1)}% (Norma 41-49.5%, UCI max 50%)'),
                      const SizedBox(height: 6),
                      _buildDeltaRow('Hemoglobina (Hb):',
                          '${profile.hemoglobinGDL.toStringAsFixed(1)} g/dL'),
                      const SizedBox(height: 6),
                      _buildDeltaRow('Ferrytyna (magazyn żelaza):',
                          '${profile.ferritinNgMl.toStringAsFixed(0)} ng/mL (Norma 80-250)'),
                      const SizedBox(height: 6),
                      _buildDeltaRow('Status panelu krwi:', profile.bloodStatus.label),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Komentarz Lekarza Medycyny Sportowej:',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.clinicalNotes.join('\n'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: AppColors.primaryAccent)),
            ),
          ],
        );
      },
    );
  }

  void _showClinicalNotesDialog(RiderMedicalProfile profile) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Karta Medyczna: ${profile.rider.fullName}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wiek: ${profile.rider.age} lat • ${profile.rider.specialization.displayName}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Diagnoza i Zalecenia:',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: profile.clinicalNotes.map((note) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.arrow_right_rounded,
                              size: 16, color: AppColors.goldAccent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              note,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Zamknij', style: TextStyle(color: AppColors.primaryAccent)),
            ),
          ],
        );
      },
    );
  }

  void _showFacilityLockedDialog(RecoveryProtocolType protocolType) {
    final protocol = RecoveryProtocolSystem.getProtocol(protocolType);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_rounded, color: AppColors.amberWarning, size: 24),
              SizedBox(width: 10),
              Text(
                'Procedura Zablokowana',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: Text(
            'Drużyna nie posiada wymaganego sprzętu do wykonania procedury: ${protocol.name}.\n\n'
            'Przejdź do zakładki "Inwestycje & Sprzęt Kliniki", aby sfinansować odpowiednie zaplecze medyczne.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Anuluj', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _tabController.animateTo(2);
              },
              child: const Text('Przejdź do Inwestycji'),
            ),
          ],
        );
      },
    );
  }

  void _showMedicalLegendDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Fizjologia & Parametry Laboratoryjne',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          content: const SingleChildScrollView(
            child: SizedBox(
              width: 440,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• Zmęczenie układowe (ATL): 7-dniowe ostre obciążenie treningowe. Wartości >75 oznaczają wysokie wyczerpanie układu krążenia i OUN.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Kinaza kreatynowa (CK w U/L): Enzym uwalniany z uszkodzonych włókien mięśniowych po wysiłku. Wartości >800 U/L sygnalizują silne mikrourazy wymagające krioterapii lub hiperbarii.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Hematokryt (Hct %): Procentowa objętość erytrocytów we krwi. UCI ustanawia limit 50.0% w celu ochrony zdrowia przed zagęszczeniem krwi.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Ferrytyna (ng/mL): Wskaźnik zapasów żelaza w ustroju. Wartości <45 ng/mL niosą ryzyko anemii wysiłkowej i spadku VO2max.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Opatrunki hydrokoloidowe: Utrzymują wilgotne środowisko rany szlifu powypadkowego (Road Rash), eliminują bolesne przywieranie w nocy i przyspieszają gojenie o 2 dni na aplikację.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Zamknij', style: TextStyle(color: AppColors.primaryAccent)),
            ),
          ],
        );
      },
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }
}
