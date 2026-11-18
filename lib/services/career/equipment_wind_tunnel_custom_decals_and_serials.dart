// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

/// Typ edycji mistrzowskiej lub specjalnej dla zserializowanej ramy rowerowej.
enum ChampionshipEditionType {
  standardTeamIssue,
  nationalChampion,
  worldChampionRainbow,
  olympicGold,
  grandTourYellowGold,
  monumentWinner,
  skunkworksCarbonRaw;

  String toJson() => name;

  static ChampionshipEditionType fromJson(String value) {
    return ChampionshipEditionType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ChampionshipEditionType.standardTeamIssue,
    );
  }

  String get label {
    switch (this) {
      case ChampionshipEditionType.standardTeamIssue:
        return 'Edycja Zespołowa';
      case ChampionshipEditionType.nationalChampion:
        return 'Mistrz Kraju';
      case ChampionshipEditionType.worldChampionRainbow:
        return 'Mistrz Świata UCI';
      case ChampionshipEditionType.olympicGold:
        return 'Złoto Olimpijskie';
      case ChampionshipEditionType.grandTourYellowGold:
        return 'Złota Edycja Wielkiego Touru';
      case ChampionshipEditionType.monumentWinner:
        return 'Edycja Zwycięzcy Monumentu';
      case ChampionshipEditionType.skunkworksCarbonRaw:
        return 'Surowy Karbon Tunelu Aero';
    }
  }

  String get shortCode {
    switch (this) {
      case ChampionshipEditionType.standardTeamIssue:
        return 'TM';
      case ChampionshipEditionType.nationalChampion:
        return 'NC';
      case ChampionshipEditionType.worldChampionRainbow:
        return 'WC';
      case ChampionshipEditionType.olympicGold:
        return 'OG';
      case ChampionshipEditionType.grandTourYellowGold:
        return 'GT';
      case ChampionshipEditionType.monumentWinner:
        return 'MN';
      case ChampionshipEditionType.skunkworksCarbonRaw:
        return 'SW';
    }
  }

  bool get isGoldMasterEdition {
    return this == ChampionshipEditionType.worldChampionRainbow ||
        this == ChampionshipEditionType.olympicGold ||
        this == ChampionshipEditionType.grandTourYellowGold ||
        this == ChampionshipEditionType.monumentWinner;
  }

  Color get primaryDecalColor {
    switch (this) {
      case ChampionshipEditionType.standardTeamIssue:
        return AppColors.primaryAccent;
      case ChampionshipEditionType.nationalChampion:
        return AppColors.crimsonAlert;
      case ChampionshipEditionType.worldChampionRainbow:
        return AppColors.textPrimary;
      case ChampionshipEditionType.olympicGold:
        return AppColors.goldAccent;
      case ChampionshipEditionType.grandTourYellowGold:
        return const Color(0xFFFACC15);
      case ChampionshipEditionType.monumentWinner:
        return AppColors.goldAccent;
      case ChampionshipEditionType.skunkworksCarbonRaw:
        return AppColors.cyanAccent;
    }
  }

  Color get accentDecalColor {
    switch (this) {
      case ChampionshipEditionType.standardTeamIssue:
        return AppColors.accentBlue;
      case ChampionshipEditionType.nationalChampion:
        return AppColors.textPrimary;
      case ChampionshipEditionType.worldChampionRainbow:
        return AppColors.goldAccent;
      case ChampionshipEditionType.olympicGold:
        return const Color(0xFFFFFBEB);
      case ChampionshipEditionType.grandTourYellowGold:
        return AppColors.goldAccent;
      case ChampionshipEditionType.monumentWinner:
        return AppColors.primaryAccent;
      case ChampionshipEditionType.skunkworksCarbonRaw:
        return AppColors.textSecondary;
    }
  }

  double get aeroCdABonus {
    switch (this) {
      case ChampionshipEditionType.standardTeamIssue:
        return 0.0;
      case ChampionshipEditionType.nationalChampion:
        return 0.0005;
      case ChampionshipEditionType.worldChampionRainbow:
        return 0.0012;
      case ChampionshipEditionType.olympicGold:
        return 0.0015;
      case ChampionshipEditionType.grandTourYellowGold:
        return 0.0010;
      case ChampionshipEditionType.monumentWinner:
        return 0.0008;
      case ChampionshipEditionType.skunkworksCarbonRaw:
        return 0.0024;
    }
  }

  int get riderMoraleBonus {
    switch (this) {
      case ChampionshipEditionType.standardTeamIssue:
        return 1;
      case ChampionshipEditionType.nationalChampion:
        return 3;
      case ChampionshipEditionType.worldChampionRainbow:
        return 6;
      case ChampionshipEditionType.olympicGold:
        return 7;
      case ChampionshipEditionType.grandTourYellowGold:
        return 6;
      case ChampionshipEditionType.monumentWinner:
        return 5;
      case ChampionshipEditionType.skunkworksCarbonRaw:
        return 4;
    }
  }

  double get prestigeMultiplier {
    switch (this) {
      case ChampionshipEditionType.standardTeamIssue:
        return 1.0;
      case ChampionshipEditionType.nationalChampion:
        return 1.45;
      case ChampionshipEditionType.worldChampionRainbow:
        return 2.4;
      case ChampionshipEditionType.olympicGold:
        return 2.8;
      case ChampionshipEditionType.grandTourYellowGold:
        return 2.5;
      case ChampionshipEditionType.monumentWinner:
        return 2.0;
      case ChampionshipEditionType.skunkworksCarbonRaw:
        return 1.65;
    }
  }

  double get upgradeCostEur {
    switch (this) {
      case ChampionshipEditionType.standardTeamIssue:
        return 1200;
      case ChampionshipEditionType.nationalChampion:
        return 3200;
      case ChampionshipEditionType.worldChampionRainbow:
        return 6800;
      case ChampionshipEditionType.olympicGold:
        return 8500;
      case ChampionshipEditionType.grandTourYellowGold:
        return 7400;
      case ChampionshipEditionType.monumentWinner:
        return 5200;
      case ChampionshipEditionType.skunkworksCarbonRaw:
        return 4500;
    }
  }
}

/// Technika wykończenia lakierniczego i nakładania kalkomanii (Decals).
enum DecalFinishStyle {
  matteStealthCarbon,
  glossMetallicGold,
  iridescentChameleon,
  brushedTitaniumLeaf;

  String toJson() => name;

  static DecalFinishStyle fromJson(String value) {
    return DecalFinishStyle.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DecalFinishStyle.matteStealthCarbon,
    );
  }

  String get label {
    switch (this) {
      case DecalFinishStyle.matteStealthCarbon:
        return 'Matowy Karbon + Laser';
      case DecalFinishStyle.glossMetallicGold:
        return 'Złoty Lakier Metaliczny 24k';
      case DecalFinishStyle.iridescentChameleon:
        return 'Kameleon Pryzmatyczny';
      case DecalFinishStyle.brushedTitaniumLeaf:
        return 'Szczotkowany Tytan & Złoto';
    }
  }

  int get weightDeltaGrams {
    switch (this) {
      case DecalFinishStyle.matteStealthCarbon:
        return -45;
      case DecalFinishStyle.glossMetallicGold:
        return 35;
      case DecalFinishStyle.iridescentChameleon:
        return 25;
      case DecalFinishStyle.brushedTitaniumLeaf:
        return 18;
    }
  }

  double get cdaDelta {
    switch (this) {
      case DecalFinishStyle.matteStealthCarbon:
        return -0.0004;
      case DecalFinishStyle.glossMetallicGold:
        return -0.0008;
      case DecalFinishStyle.iridescentChameleon:
        return -0.0006;
      case DecalFinishStyle.brushedTitaniumLeaf:
        return -0.0005;
    }
  }

  double get paintShopFeeEur {
    switch (this) {
      case DecalFinishStyle.matteStealthCarbon:
        return 1500;
      case DecalFinishStyle.glossMetallicGold:
        return 4200;
      case DecalFinishStyle.iridescentChameleon:
        return 3600;
      case DecalFinishStyle.brushedTitaniumLeaf:
        return 4800;
    }
  }
}

/// Aktualny status operacyjny zserializowanej ramy rowerowej.
enum SerialFrameStatus {
  inServiceCourse,
  assignedToRider,
  raceDeployed,
  museumArchived,
  retiredDamaged;

  String toJson() => name;

  static SerialFrameStatus fromJson(String value) {
    return SerialFrameStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SerialFrameStatus.inServiceCourse,
    );
  }

  String get label {
    switch (this) {
      case SerialFrameStatus.inServiceCourse:
        return 'W Bazie Serwisowej';
      case SerialFrameStatus.assignedToRider:
        return 'Przypisana Kolarzowi';
      case SerialFrameStatus.raceDeployed:
        return 'W Flocie Wyścigowej';
      case SerialFrameStatus.museumArchived:
        return 'Muzeum Klubowe';
      case SerialFrameStatus.retiredDamaged:
        return 'Wycofana (Kraksa)';
    }
  }

  Color get badgeColor {
    switch (this) {
      case SerialFrameStatus.inServiceCourse:
        return AppColors.accentBlue;
      case SerialFrameStatus.assignedToRider:
        return AppColors.statusSuccess;
      case SerialFrameStatus.raceDeployed:
        return AppColors.amberWarning;
      case SerialFrameStatus.museumArchived:
        return AppColors.goldAccent;
      case SerialFrameStatus.retiredDamaged:
        return AppColors.crimsonAlert;
    }
  }
}

/// Rekord pojedynczej ramy o unikalnym numerze seryjnym i indywidualnych kalkomaniach.
@immutable
class CustomFrameSerialRecord {
  const CustomFrameSerialRecord({
    required this.serialNumber,
    required this.frameModelId,
    required this.frameModelName,
    required this.manufacturerName,
    required this.editionType,
    required this.finishStyle,
    required this.status,
    required this.customTopTubeInscription,
    required this.nationalFlagCode,
    required this.windTunnelCdA,
    required this.frameWeightGrams,
    required this.kilometersRidden,
    required this.victoriesCount,
    required this.grandTourStagesWon,
    required this.monumentsWon,
    required this.commissionedDate,
    required this.estimatedCollectorValueEur,
    this.assignedRiderId,
    this.assignedRiderName,
  });

  final String serialNumber;
  final String frameModelId;
  final String frameModelName;
  final String manufacturerName;
  final ChampionshipEditionType editionType;
  final DecalFinishStyle finishStyle;
  final SerialFrameStatus status;
  final String? assignedRiderId;
  final String? assignedRiderName;
  final String customTopTubeInscription;
  final String nationalFlagCode;
  final double windTunnelCdA;
  final int frameWeightGrams;
  final double kilometersRidden;
  final int victoriesCount;
  final int grandTourStagesWon;
  final int monumentsWon;
  final DateTime commissionedDate;
  final double estimatedCollectorValueEur;

  bool get isGoldMasterEdition => editionType.isGoldMasterEdition;

  bool get canBeAssigned =>
      status == SerialFrameStatus.inServiceCourse ||
      status == SerialFrameStatus.assignedToRider;

  bool get canBeArchived =>
      status != SerialFrameStatus.museumArchived &&
      status != SerialFrameStatus.raceDeployed;

  CustomFrameSerialRecord copyWith({
    String? serialNumber,
    String? frameModelId,
    String? frameModelName,
    String? manufacturerName,
    ChampionshipEditionType? editionType,
    DecalFinishStyle? finishStyle,
    SerialFrameStatus? status,
    String? assignedRiderId,
    bool clearAssignedRider = false,
    String? assignedRiderName,
    String? customTopTubeInscription,
    String? nationalFlagCode,
    double? windTunnelCdA,
    int? frameWeightGrams,
    double? kilometersRidden,
    int? victoriesCount,
    int? grandTourStagesWon,
    int? monumentsWon,
    DateTime? commissionedDate,
    double? estimatedCollectorValueEur,
  }) {
    return CustomFrameSerialRecord(
      serialNumber: serialNumber ?? this.serialNumber,
      frameModelId: frameModelId ?? this.frameModelId,
      frameModelName: frameModelName ?? this.frameModelName,
      manufacturerName: manufacturerName ?? this.manufacturerName,
      editionType: editionType ?? this.editionType,
      finishStyle: finishStyle ?? this.finishStyle,
      status: status ?? this.status,
      assignedRiderId: clearAssignedRider
          ? null
          : (assignedRiderId ?? this.assignedRiderId),
      assignedRiderName: clearAssignedRider
          ? null
          : (assignedRiderName ?? this.assignedRiderName),
      customTopTubeInscription:
          customTopTubeInscription ?? this.customTopTubeInscription,
      nationalFlagCode: nationalFlagCode ?? this.nationalFlagCode,
      windTunnelCdA: windTunnelCdA ?? this.windTunnelCdA,
      frameWeightGrams: frameWeightGrams ?? this.frameWeightGrams,
      kilometersRidden: kilometersRidden ?? this.kilometersRidden,
      victoriesCount: victoriesCount ?? this.victoriesCount,
      grandTourStagesWon: grandTourStagesWon ?? this.grandTourStagesWon,
      monumentsWon: monumentsWon ?? this.monumentsWon,
      commissionedDate: commissionedDate ?? this.commissionedDate,
      estimatedCollectorValueEur:
          estimatedCollectorValueEur ?? this.estimatedCollectorValueEur,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'serialNumber': serialNumber,
      'frameModelId': frameModelId,
      'frameModelName': frameModelName,
      'manufacturerName': manufacturerName,
      'editionType': editionType.toJson(),
      'finishStyle': finishStyle.toJson(),
      'status': status.toJson(),
      'assignedRiderId': assignedRiderId,
      'assignedRiderName': assignedRiderName,
      'customTopTubeInscription': customTopTubeInscription,
      'nationalFlagCode': nationalFlagCode,
      'windTunnelCdA': windTunnelCdA,
      'frameWeightGrams': frameWeightGrams,
      'kilometersRidden': kilometersRidden,
      'victoriesCount': victoriesCount,
      'grandTourStagesWon': grandTourStagesWon,
      'monumentsWon': monumentsWon,
      'commissionedDate': commissionedDate.toIso8601String(),
      'estimatedCollectorValueEur': estimatedCollectorValueEur,
    };
  }

  factory CustomFrameSerialRecord.fromJson(Map<String, dynamic> json) {
    return CustomFrameSerialRecord(
      serialNumber: (json['serialNumber'] as String?) ?? 'PPM-26-TM-0000',
      frameModelId: (json['frameModelId'] as String?) ?? 'frame_default',
      frameModelName: (json['frameModelName'] as String?) ?? 'Pro Aero Carbon',
      manufacturerName:
          (json['manufacturerName'] as String?) ?? 'Atelier Carbon',
      editionType: ChampionshipEditionType.fromJson(
        (json['editionType'] as String?) ?? 'standardTeamIssue',
      ),
      finishStyle: DecalFinishStyle.fromJson(
        (json['finishStyle'] as String?) ?? 'matteStealthCarbon',
      ),
      status: SerialFrameStatus.fromJson(
        (json['status'] as String?) ?? 'inServiceCourse',
      ),
      assignedRiderId: json['assignedRiderId'] as String?,
      assignedRiderName: json['assignedRiderName'] as String?,
      customTopTubeInscription:
          (json['customTopTubeInscription'] as String?) ?? '',
      nationalFlagCode: (json['nationalFlagCode'] as String?) ?? 'POL',
      windTunnelCdA: ((json['windTunnelCdA'] as num?) ?? 0.215).toDouble(),
      frameWeightGrams: ((json['frameWeightGrams'] as num?) ?? 730).toInt(),
      kilometersRidden: ((json['kilometersRidden'] as num?) ?? 0).toDouble(),
      victoriesCount: ((json['victoriesCount'] as num?) ?? 0).toInt(),
      grandTourStagesWon: ((json['grandTourStagesWon'] as num?) ?? 0).toInt(),
      monumentsWon: ((json['monumentsWon'] as num?) ?? 0).toInt(),
      commissionedDate:
          DateTime.tryParse((json['commissionedDate'] as String?) ?? '') ??
          DateTime(2026, 1, 15),
      estimatedCollectorValueEur:
          ((json['estimatedCollectorValueEur'] as num?) ?? 12500).toDouble(),
    );
  }
}

/// Stan zarządzania indywidualnymi numerami seryjnymi ram oraz edycjami mistrzowskimi.
@immutable
class EquipmentWindTunnelDecalsState {
  const EquipmentWindTunnelDecalsState({
    required this.frames,
    required this.nextSequenceCounter,
    required this.availableBudgetEur,
    this.selectedSerialNumber,
    this.activeFilterEdition,
    this.activeFilterStatus,
    this.searchQuery = '',
    this.lastNotification,
    this.lastError,
  });

  final List<CustomFrameSerialRecord> frames;
  final String? selectedSerialNumber;
  final ChampionshipEditionType? activeFilterEdition;
  final SerialFrameStatus? activeFilterStatus;
  final String searchQuery;
  final int nextSequenceCounter;
  final double availableBudgetEur;
  final String? lastNotification;
  final String? lastError;

  CustomFrameSerialRecord? get selectedFrame {
    if (frames.isEmpty) return null;
    if (selectedSerialNumber != null) {
      for (final frame in frames) {
        if (frame.serialNumber == selectedSerialNumber) {
          return frame;
        }
      }
    }
    return frames.first;
  }

  List<CustomFrameSerialRecord> get filteredFrames {
    final normalizedQuery = searchQuery.trim().toLowerCase();
    return frames.where((frame) {
      if (activeFilterEdition != null &&
          frame.editionType != activeFilterEdition) {
        return false;
      }
      if (activeFilterStatus != null && frame.status != activeFilterStatus) {
        return false;
      }
      if (normalizedQuery.isNotEmpty) {
        final haystack = <String>[
          frame.serialNumber,
          frame.frameModelName,
          frame.manufacturerName,
          frame.customTopTubeInscription,
          frame.assignedRiderName ?? '',
          frame.nationalFlagCode,
        ].join(' ').toLowerCase();
        if (!haystack.contains(normalizedQuery)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  int get goldEditionsCount =>
      frames.where((f) => f.isGoldMasterEdition).length;

  int get assignedFramesCount =>
      frames.where((f) => f.status == SerialFrameStatus.assignedToRider).length;

  int get museumFramesCount =>
      frames.where((f) => f.status == SerialFrameStatus.museumArchived).length;

  double get totalFleetCollectorValueEur => frames.fold<double>(
    0.0,
    (sum, f) => sum + f.estimatedCollectorValueEur,
  );

  double get averageWindTunnelCdA {
    if (frames.isEmpty) return 0.0;
    final total = frames.fold<double>(0.0, (sum, f) => sum + f.windTunnelCdA);
    return total / frames.length;
  }

  EquipmentWindTunnelDecalsState copyWith({
    List<CustomFrameSerialRecord>? frames,
    String? selectedSerialNumber,
    ChampionshipEditionType? activeFilterEdition,
    bool clearFilterEdition = false,
    SerialFrameStatus? activeFilterStatus,
    bool clearFilterStatus = false,
    String? searchQuery,
    int? nextSequenceCounter,
    double? availableBudgetEur,
    String? lastNotification,
    bool clearNotification = false,
    String? lastError,
    bool clearError = false,
  }) {
    return EquipmentWindTunnelDecalsState(
      frames: frames ?? this.frames,
      selectedSerialNumber: selectedSerialNumber ?? this.selectedSerialNumber,
      activeFilterEdition: clearFilterEdition
          ? null
          : (activeFilterEdition ?? this.activeFilterEdition),
      activeFilterStatus: clearFilterStatus
          ? null
          : (activeFilterStatus ?? this.activeFilterStatus),
      searchQuery: searchQuery ?? this.searchQuery,
      nextSequenceCounter: nextSequenceCounter ?? this.nextSequenceCounter,
      availableBudgetEur: availableBudgetEur ?? this.availableBudgetEur,
      lastNotification: clearNotification
          ? null
          : (lastNotification ?? this.lastNotification),
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'frames': frames.map((f) => f.toJson()).toList(),
      'selectedSerialNumber': selectedSerialNumber,
      'activeFilterEdition': activeFilterEdition?.toJson(),
      'activeFilterStatus': activeFilterStatus?.toJson(),
      'searchQuery': searchQuery,
      'nextSequenceCounter': nextSequenceCounter,
      'availableBudgetEur': availableBudgetEur,
    };
  }

  factory EquipmentWindTunnelDecalsState.fromJson(Map<String, dynamic> json) {
    final rawFrames = (json['frames'] as List<dynamic>?) ?? const <dynamic>[];
    final parsedFrames = rawFrames
        .whereType<Map<String, dynamic>>()
        .map(CustomFrameSerialRecord.fromJson)
        .toList();

    return EquipmentWindTunnelDecalsState(
      frames: parsedFrames,
      selectedSerialNumber: json['selectedSerialNumber'] as String?,
      activeFilterEdition: json['activeFilterEdition'] is String
          ? ChampionshipEditionType.fromJson(
              json['activeFilterEdition'] as String,
            )
          : null,
      activeFilterStatus: json['activeFilterStatus'] is String
          ? SerialFrameStatus.fromJson(json['activeFilterStatus'] as String)
          : null,
      searchQuery: (json['searchQuery'] as String?) ?? '',
      nextSequenceCounter:
          ((json['nextSequenceCounter'] as num?) ?? (parsedFrames.length + 1))
              .toInt(),
      availableBudgetEur:
          ((json['availableBudgetEur'] as num?) ?? 450000).toDouble(),
    );
  }
}

/// Serwis odpowiedzialny za numerację seryjną ram, indywidualne kalkomanie tunelu aero
/// oraz tworzenie złotych edycji mistrzowskich rowerów.
class EquipmentWindTunnelCustomDecalsService {
  const EquipmentWindTunnelCustomDecalsService();

  /// Tworzy początkową flotę zserializowanych ram wraz ze złotymi edycjami mistrzowskimi.
  EquipmentWindTunnelDecalsState createInitialState({
    double initialBudgetEur = 450000,
    int seasonYear = 2026,
  }) {
    final initialFrames = <CustomFrameSerialRecord>[
      CustomFrameSerialRecord(
        serialNumber: generateSerialNumber(
          edition: ChampionshipEditionType.worldChampionRainbow,
          seasonYear: seasonYear,
          sequence: 1,
        ),
        frameModelId: 's5_wc_aero',
        frameModelName: 'Cervélo S5 Rainbow Gold',
        manufacturerName: 'Cervélo Atelier',
        editionType: ChampionshipEditionType.worldChampionRainbow,
        finishStyle: DecalFinishStyle.glossMetallicGold,
        status: SerialFrameStatus.assignedToRider,
        assignedRiderId: 'rider_leader_01',
        assignedRiderName: 'Kacper Majewski',
        customTopTubeInscription: 'ZURICH WC 24k • "ORZEŁ"',
        nationalFlagCode: 'POL',
        windTunnelCdA: 0.2078,
        frameWeightGrams: 755,
        kilometersRidden: 4820.5,
        victoriesCount: 7,
        grandTourStagesWon: 3,
        monumentsWon: 1,
        commissionedDate: DateTime(seasonYear, 1, 12),
        estimatedCollectorValueEur: calculateCollectorValuation(
          edition: ChampionshipEditionType.worldChampionRainbow,
          finishStyle: DecalFinishStyle.glossMetallicGold,
          victoriesCount: 7,
          grandTourStagesWon: 3,
          monumentsWon: 1,
          kilometersRidden: 4820.5,
        ),
      ),
      CustomFrameSerialRecord(
        serialNumber: generateSerialNumber(
          edition: ChampionshipEditionType.grandTourYellowGold,
          seasonYear: seasonYear,
          sequence: 2,
        ),
        frameModelId: 'dogma_gt_gold',
        frameModelName: 'Pinarello Dogma F Maillot Jaune',
        manufacturerName: 'Pinarello Lab',
        editionType: ChampionshipEditionType.grandTourYellowGold,
        finishStyle: DecalFinishStyle.brushedTitaniumLeaf,
        status: SerialFrameStatus.museumArchived,
        customTopTubeInscription: 'PARIS CHAMPS-ÉLYSÉES 2025',
        nationalFlagCode: 'SLO',
        windTunnelCdA: 0.2094,
        frameWeightGrams: 718,
        kilometersRidden: 3490.0,
        victoriesCount: 5,
        grandTourStagesWon: 4,
        monumentsWon: 0,
        commissionedDate: DateTime(seasonYear - 1, 7, 24),
        estimatedCollectorValueEur: calculateCollectorValuation(
          edition: ChampionshipEditionType.grandTourYellowGold,
          finishStyle: DecalFinishStyle.brushedTitaniumLeaf,
          victoriesCount: 5,
          grandTourStagesWon: 4,
          monumentsWon: 0,
          kilometersRidden: 3490.0,
        ),
      ),
      CustomFrameSerialRecord(
        serialNumber: generateSerialNumber(
          edition: ChampionshipEditionType.olympicGold,
          seasonYear: seasonYear,
          sequence: 3,
        ),
        frameModelId: 'shiv_tt_olympic',
        frameModelName: 'S-Works Shiv TT Olympic 24k',
        manufacturerName: 'Specialized Wind Tunnel',
        editionType: ChampionshipEditionType.olympicGold,
        finishStyle: DecalFinishStyle.glossMetallicGold,
        status: SerialFrameStatus.assignedToRider,
        assignedRiderId: 'rider_tt_02',
        assignedRiderName: 'Remco Verhoeven',
        customTopTubeInscription: 'GOLD MEDAL • 53.8 KM/H',
        nationalFlagCode: 'BEL',
        windTunnelCdA: 0.1942,
        frameWeightGrams: 895,
        kilometersRidden: 1640.0,
        victoriesCount: 4,
        grandTourStagesWon: 2,
        monumentsWon: 0,
        commissionedDate: DateTime(seasonYear, 2, 4),
        estimatedCollectorValueEur: calculateCollectorValuation(
          edition: ChampionshipEditionType.olympicGold,
          finishStyle: DecalFinishStyle.glossMetallicGold,
          victoriesCount: 4,
          grandTourStagesWon: 2,
          monumentsWon: 0,
          kilometersRidden: 1640.0,
        ),
      ),
      CustomFrameSerialRecord(
        serialNumber: generateSerialNumber(
          edition: ChampionshipEditionType.skunkworksCarbonRaw,
          seasonYear: seasonYear,
          sequence: 4,
        ),
        frameModelId: 'aeroad_cfr_raw',
        frameModelName: 'Canyon Aeroad CFR Raw Tunnel',
        manufacturerName: 'Canyon Engineering',
        editionType: ChampionshipEditionType.skunkworksCarbonRaw,
        finishStyle: DecalFinishStyle.matteStealthCarbon,
        status: SerialFrameStatus.inServiceCourse,
        customTopTubeInscription: 'CFD-REV-9 • NO CLEARCOAT',
        nationalFlagCode: 'GER',
        windTunnelCdA: 0.2055,
        frameWeightGrams: 675,
        kilometersRidden: 910.0,
        victoriesCount: 1,
        grandTourStagesWon: 0,
        monumentsWon: 0,
        commissionedDate: DateTime(seasonYear, 3, 1),
        estimatedCollectorValueEur: calculateCollectorValuation(
          edition: ChampionshipEditionType.skunkworksCarbonRaw,
          finishStyle: DecalFinishStyle.matteStealthCarbon,
          victoriesCount: 1,
          grandTourStagesWon: 0,
          monumentsWon: 0,
          kilometersRidden: 910.0,
        ),
      ),
    ];

    return EquipmentWindTunnelDecalsState(
      frames: initialFrames,
      selectedSerialNumber: initialFrames.first.serialNumber,
      nextSequenceCounter: 5,
      availableBudgetEur: initialBudgetEur,
    );
  }

  /// Generuje unikalny, deterministyczny numer seryjny ramy.
  String generateSerialNumber({
    required ChampionshipEditionType edition,
    required int seasonYear,
    required int sequence,
  }) {
    final shortYear = (seasonYear % 100).toString().padLeft(2, '0');
    final paddedSeq = sequence.toString().padLeft(4, '0');
    return 'PPM-$shortYear-${edition.shortCode}-$paddedSeq';
  }

  /// Wylicza wartość kolekcjonerską ramy w EUR na podstawie prestiżu edycji i historii zwycięstw.
  double calculateCollectorValuation({
    required ChampionshipEditionType edition,
    required DecalFinishStyle finishStyle,
    required int victoriesCount,
    required int grandTourStagesWon,
    required int monumentsWon,
    required double kilometersRidden,
  }) {
    const baseCarbonValue = 12500.0;
    final finishBonus = finishStyle.paintShopFeeEur * 0.85;
    final victoryBonus =
        victoriesCount * 3200.0 +
        grandTourStagesWon * 5800.0 +
        monumentsWon * 18500.0;
    final provenanceWearFactor =
        1.0 + math.min(0.25, kilometersRidden / 25000.0);
    final total =
        (baseCarbonValue * edition.prestigeMultiplier +
            finishBonus +
            victoryBonus) *
        provenanceWearFactor;
    return total.roundToDouble();
  }

  /// Rejestruje nową ramę z indywidualnym numerem seryjnym i kalkomanią.
  EquipmentWindTunnelDecalsState mintCustomSerialFrame({
    required EquipmentWindTunnelDecalsState state,
    required String frameModelId,
    required String frameModelName,
    required String manufacturerName,
    required ChampionshipEditionType editionType,
    required DecalFinishStyle finishStyle,
    required String customTopTubeInscription,
    required String nationalFlagCode,
    double baseWindTunnelCdA = 0.2120,
    int baseFrameWeightGrams = 735,
    int seasonYear = 2026,
    String? assignedRiderId,
    String? assignedRiderName,
  }) {
    final cleanModelName = frameModelName.trim();
    final cleanManufacturer = manufacturerName.trim();
    if (cleanModelName.isEmpty || cleanManufacturer.isEmpty) {
      return state.copyWith(
        lastError: 'Podaj nazwę modelu ramy oraz producenta.',
        clearNotification: true,
      );
    }

    final totalCost = editionType.upgradeCostEur + finishStyle.paintShopFeeEur;
    if (state.availableBudgetEur < totalCost) {
      return state.copyWith(
        lastError:
            'Niewystarczający budżet sprzętowy (wymagane ${Formatters.formatCurrency(totalCost)}).',
        clearNotification: true,
      );
    }

    final serial = generateSerialNumber(
      edition: editionType,
      seasonYear: seasonYear,
      sequence: state.nextSequenceCounter,
    );

    final sanitizedFlag = nationalFlagCode.trim().toUpperCase().isEmpty
        ? 'POL'
        : nationalFlagCode
              .trim()
              .toUpperCase()
              .substring(0, math.min(3, nationalFlagCode.trim().length));

    final cleanInscription = customTopTubeInscription.trim().isEmpty
        ? '${editionType.shortCode} #$serial'
        : customTopTubeInscription.trim();

    final effectiveCdA = math.max(
      0.1800,
      baseWindTunnelCdA - editionType.aeroCdABonus + finishStyle.cdaDelta,
    );
    final effectiveWeight = math.max(
      620,
      baseFrameWeightGrams + finishStyle.weightDeltaGrams,
    );

    final hasRider =
        assignedRiderId != null &&
        assignedRiderId.trim().isNotEmpty &&
        assignedRiderName != null &&
        assignedRiderName.trim().isNotEmpty;

    final record = CustomFrameSerialRecord(
      serialNumber: serial,
      frameModelId: frameModelId.trim().isEmpty
          ? 'custom_${state.nextSequenceCounter}'
          : frameModelId.trim(),
      frameModelName: cleanModelName,
      manufacturerName: cleanManufacturer,
      editionType: editionType,
      finishStyle: finishStyle,
      status: hasRider
          ? SerialFrameStatus.assignedToRider
          : SerialFrameStatus.inServiceCourse,
      assignedRiderId: hasRider ? assignedRiderId.trim() : null,
      assignedRiderName: hasRider ? assignedRiderName.trim() : null,
      customTopTubeInscription: cleanInscription,
      nationalFlagCode: sanitizedFlag,
      windTunnelCdA: double.parse(effectiveCdA.toStringAsFixed(4)),
      frameWeightGrams: effectiveWeight,
      kilometersRidden: 0.0,
      victoriesCount: 0,
      grandTourStagesWon: 0,
      monumentsWon: 0,
      commissionedDate: DateTime(seasonYear, 3, 15),
      estimatedCollectorValueEur: calculateCollectorValuation(
        edition: editionType,
        finishStyle: finishStyle,
        victoriesCount: 0,
        grandTourStagesWon: 0,
        monumentsWon: 0,
        kilometersRidden: 0.0,
      ),
    );

    return state.copyWith(
      frames: <CustomFrameSerialRecord>[record, ...state.frames],
      selectedSerialNumber: serial,
      nextSequenceCounter: state.nextSequenceCounter + 1,
      availableBudgetEur: state.availableBudgetEur - totalCost,
      lastNotification:
          'Nadano numer seryjny $serial (${editionType.label}). Koszt: ${Formatters.formatCurrency(totalCost)}.',
      clearError: true,
    );
  }

  /// Awansuje istniejącą ramę na Złotą Edycję Mistrzowską lub zmienia styl kalkomanii.
  EquipmentWindTunnelDecalsState upgradeToChampionshipEdition({
    required EquipmentWindTunnelDecalsState state,
    required String serialNumber,
    required ChampionshipEditionType targetEdition,
    required DecalFinishStyle targetFinish,
    String? customInscription,
    int seasonYear = 2026,
  }) {
    final index = state.frames.indexWhere(
      (f) => f.serialNumber == serialNumber,
    );
    if (index == -1) {
      return state.copyWith(
        lastError: 'Nie znaleziono ramy o numerze seryjnym $serialNumber.',
        clearNotification: true,
      );
    }

    final existing = state.frames[index];
    if (existing.status == SerialFrameStatus.museumArchived ||
        existing.status == SerialFrameStatus.retiredDamaged) {
      return state.copyWith(
        lastError:
            'Rama w statusie "${existing.status.label}" nie może zostać przemalowana.',
        clearNotification: true,
      );
    }

    final upgradeCost =
        (targetEdition.upgradeCostEur * 0.75) +
        (targetFinish.paintShopFeeEur * 0.65);

    if (state.availableBudgetEur < upgradeCost) {
      return state.copyWith(
        lastError:
            'Brak środków na lakiernię mistrzowską (${Formatters.formatCurrency(upgradeCost)}).',
        clearNotification: true,
      );
    }

    final cdaShift =
        (existing.editionType.aeroCdABonus - targetEdition.aeroCdABonus) +
        (targetFinish.cdaDelta - existing.finishStyle.cdaDelta);
    final updatedCdA = math.max(0.1800, existing.windTunnelCdA + cdaShift);
    final updatedWeight = math.max(
      620,
      existing.frameWeightGrams -
          existing.finishStyle.weightDeltaGrams +
          targetFinish.weightDeltaGrams,
    );

    final updatedInscription =
        (customInscription != null && customInscription.trim().isNotEmpty)
        ? customInscription.trim()
        : existing.customTopTubeInscription;

    final updatedSerial = targetEdition.isGoldMasterEdition
        ? generateSerialNumber(
            edition: targetEdition,
            seasonYear: seasonYear,
            sequence: state.nextSequenceCounter,
          )
        : existing.serialNumber;

    final updatedFrame = existing.copyWith(
      serialNumber: updatedSerial,
      editionType: targetEdition,
      finishStyle: targetFinish,
      customTopTubeInscription: updatedInscription,
      windTunnelCdA: double.parse(updatedCdA.toStringAsFixed(4)),
      frameWeightGrams: updatedWeight,
      estimatedCollectorValueEur: calculateCollectorValuation(
        edition: targetEdition,
        finishStyle: targetFinish,
        victoriesCount: existing.victoriesCount,
        grandTourStagesWon: existing.grandTourStagesWon,
        monumentsWon: existing.monumentsWon,
        kilometersRidden: existing.kilometersRidden,
      ),
    );

    final updatedList = List<CustomFrameSerialRecord>.from(state.frames);
    updatedList[index] = updatedFrame;

    return state.copyWith(
      frames: updatedList,
      selectedSerialNumber: updatedSerial,
      nextSequenceCounter: targetEdition.isGoldMasterEdition
          ? state.nextSequenceCounter + 1
          : state.nextSequenceCounter,
      availableBudgetEur: state.availableBudgetEur - upgradeCost,
      lastNotification:
          'Rama przemianowana na ${targetEdition.label} ($updatedSerial).',
      clearError: true,
    );
  }

  /// Przypisuje ramę konkretnemu kolarzowi lub zwalnia ją do bazy serwisowej.
  EquipmentWindTunnelDecalsState assignFrameToRider({
    required EquipmentWindTunnelDecalsState state,
    required String serialNumber,
    String? riderId,
    String? riderName,
  }) {
    final index = state.frames.indexWhere(
      (f) => f.serialNumber == serialNumber,
    );
    if (index == -1) {
      return state.copyWith(
        lastError: 'Nie znaleziono ramy $serialNumber.',
        clearNotification: true,
      );
    }

    final existing = state.frames[index];
    if (!existing.canBeAssigned) {
      return state.copyWith(
        lastError:
            'Nie można przypisać ramy ze statusem "${existing.status.label}".',
        clearNotification: true,
      );
    }

    final shouldAssign =
        riderId != null &&
        riderId.trim().isNotEmpty &&
        riderName != null &&
        riderName.trim().isNotEmpty;

    final updated = shouldAssign
        ? existing.copyWith(
            status: SerialFrameStatus.assignedToRider,
            assignedRiderId: riderId.trim(),
            assignedRiderName: riderName.trim(),
          )
        : existing.copyWith(
            status: SerialFrameStatus.inServiceCourse,
            clearAssignedRider: true,
          );

    final updatedList = List<CustomFrameSerialRecord>.from(state.frames);
    updatedList[index] = updated;

    return state.copyWith(
      frames: updatedList,
      lastNotification: shouldAssign
          ? 'Rama $serialNumber przypisana do kolarza ${riderName.trim()}.'
          : 'Rama $serialNumber wróciła do bazy serwisowej.',
      clearError: true,
    );
  }

  /// Rejestruje przebieg wyścigowy oraz zwycięstwa na danej ramie, podnosząc jej wartość.
  EquipmentWindTunnelDecalsState recordRaceUsage({
    required EquipmentWindTunnelDecalsState state,
    required String serialNumber,
    required double addedKilometers,
    int addedVictories = 0,
    int addedGrandTourStages = 0,
    int addedMonuments = 0,
  }) {
    if (addedKilometers < 0 ||
        addedVictories < 0 ||
        addedGrandTourStages < 0 ||
        addedMonuments < 0) {
      return state.copyWith(
        lastError: 'Wartości przebiegu i zwycięstw nie mogą być ujemne.',
        clearNotification: true,
      );
    }

    final index = state.frames.indexWhere(
      (f) => f.serialNumber == serialNumber,
    );
    if (index == -1) {
      return state.copyWith(
        lastError: 'Nie znaleziono ramy $serialNumber.',
        clearNotification: true,
      );
    }

    final existing = state.frames[index];
    final newKm = existing.kilometersRidden + addedKilometers;
    final newVictories = existing.victoriesCount + addedVictories;
    final newGtStages = existing.grandTourStagesWon + addedGrandTourStages;
    final newMonuments = existing.monumentsWon + addedMonuments;

    final updated = existing.copyWith(
      kilometersRidden: newKm,
      victoriesCount: newVictories,
      grandTourStagesWon: newGtStages,
      monumentsWon: newMonuments,
      estimatedCollectorValueEur: calculateCollectorValuation(
        edition: existing.editionType,
        finishStyle: existing.finishStyle,
        victoriesCount: newVictories,
        grandTourStagesWon: newGtStages,
        monumentsWon: newMonuments,
        kilometersRidden: newKm,
      ),
    );

    final updatedList = List<CustomFrameSerialRecord>.from(state.frames);
    updatedList[index] = updated;

    return state.copyWith(
      frames: updatedList,
      lastNotification:
          'Zaktualizowano telemetrię proweniencji dla $serialNumber (+${addedKilometers.toStringAsFixed(0)} km).',
      clearError: true,
    );
  }

  /// Archiwizuje legendarną ramę w Muzeum Klubowym, zwalniając przypisanie kolarza.
  EquipmentWindTunnelDecalsState archiveToClubMuseum({
    required EquipmentWindTunnelDecalsState state,
    required String serialNumber,
  }) {
    final index = state.frames.indexWhere(
      (f) => f.serialNumber == serialNumber,
    );
    if (index == -1) {
      return state.copyWith(
        lastError: 'Nie znaleziono ramy $serialNumber.',
        clearNotification: true,
      );
    }

    final existing = state.frames[index];
    if (!existing.canBeArchived) {
      return state.copyWith(
        lastError:
            'Rama w statusie "${existing.status.label}" nie może trafić teraz do muzeum.',
        clearNotification: true,
      );
    }

    final updated = existing.copyWith(
      status: SerialFrameStatus.museumArchived,
      clearAssignedRider: true,
      estimatedCollectorValueEur: (existing.estimatedCollectorValueEur * 1.15)
          .roundToDouble(),
    );

    final updatedList = List<CustomFrameSerialRecord>.from(state.frames);
    updatedList[index] = updated;

    return state.copyWith(
      frames: updatedList,
      lastNotification:
          'Rama $serialNumber została zarchiwizowana w Muzeum Klubowym (+15% wartości).',
      clearError: true,
    );
  }
}

/// Kontroler Riverpod zarządzający stanem numeracji seryjnej ram i edycji mistrzowskich.
class EquipmentWindTunnelDecalsNotifier
    extends StateNotifier<EquipmentWindTunnelDecalsState> {
  EquipmentWindTunnelDecalsNotifier(this._service)
    : super(_service.createInitialState());

  final EquipmentWindTunnelCustomDecalsService _service;

  void selectFrame(String serialNumber) {
    state = state.copyWith(
      selectedSerialNumber: serialNumber,
      clearError: true,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setEditionFilter(ChampionshipEditionType? edition) {
    if (edition == null) {
      state = state.copyWith(clearFilterEdition: true);
    } else {
      state = state.copyWith(activeFilterEdition: edition);
    }
  }

  void setStatusFilter(SerialFrameStatus? status) {
    if (status == null) {
      state = state.copyWith(clearFilterStatus: true);
    } else {
      state = state.copyWith(activeFilterStatus: status);
    }
  }

  void mintCustomSerialFrame({
    required String frameModelId,
    required String frameModelName,
    required String manufacturerName,
    required ChampionshipEditionType editionType,
    required DecalFinishStyle finishStyle,
    required String customTopTubeInscription,
    required String nationalFlagCode,
    String? assignedRiderId,
    String? assignedRiderName,
  }) {
    state = _service.mintCustomSerialFrame(
      state: state,
      frameModelId: frameModelId,
      frameModelName: frameModelName,
      manufacturerName: manufacturerName,
      editionType: editionType,
      finishStyle: finishStyle,
      customTopTubeInscription: customTopTubeInscription,
      nationalFlagCode: nationalFlagCode,
      assignedRiderId: assignedRiderId,
      assignedRiderName: assignedRiderName,
    );
  }

  void upgradeToChampionshipEdition({
    required String serialNumber,
    required ChampionshipEditionType targetEdition,
    required DecalFinishStyle targetFinish,
    String? customInscription,
  }) {
    state = _service.upgradeToChampionshipEdition(
      state: state,
      serialNumber: serialNumber,
      targetEdition: targetEdition,
      targetFinish: targetFinish,
      customInscription: customInscription,
    );
  }

  void assignFrameToRider({
    required String serialNumber,
    String? riderId,
    String? riderName,
  }) {
    state = _service.assignFrameToRider(
      state: state,
      serialNumber: serialNumber,
      riderId: riderId,
      riderName: riderName,
    );
  }

  void recordRaceUsage({
    required String serialNumber,
    required double addedKilometers,
    int addedVictories = 0,
    int addedGrandTourStages = 0,
    int addedMonuments = 0,
  }) {
    state = _service.recordRaceUsage(
      state: state,
      serialNumber: serialNumber,
      addedKilometers: addedKilometers,
      addedVictories: addedVictories,
      addedGrandTourStages: addedGrandTourStages,
      addedMonuments: addedMonuments,
    );
  }

  void archiveToClubMuseum(String serialNumber) {
    state = _service.archiveToClubMuseum(
      state: state,
      serialNumber: serialNumber,
    );
  }
}

final equipmentWindTunnelDecalsServiceProvider =
    Provider<EquipmentWindTunnelCustomDecalsService>(
      (ref) => const EquipmentWindTunnelCustomDecalsService(),
    );

final equipmentWindTunnelDecalsProvider =
    StateNotifierProvider<
      EquipmentWindTunnelDecalsNotifier,
      EquipmentWindTunnelDecalsState
    >((ref) {
      final service = ref.watch(equipmentWindTunnelDecalsServiceProvider);
      return EquipmentWindTunnelDecalsNotifier(service);
    });

/// Rysuje podgląd górnej rury ramy (Top Tube) z indywidualną kalkomanią, pasami mistrzowskimi i tabliczką seryjną.
class FrameDecalSerialPlatePainter extends CustomPainter {
  const FrameDecalSerialPlatePainter({required this.record});

  final CustomFrameSerialRecord record;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));

    // Tło karbonowe / złote wykończenie ramy
    final bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: record.isGoldMasterEdition
          ? <Color>[
              const Color(0xFF262010),
              const Color(0xFF171A21),
              const Color(0xFF2D2411),
            ]
          : <Color>[
              const Color(0xFF151820),
              const Color(0xFF1E232E),
              const Color(0xFF12151C),
            ],
    );
    canvas.drawRRect(rrect, Paint()..shader = bgGradient.createShader(rect));

    // Subtelna tekstura splotu karbonowego 3K
    final weavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1.0;
    for (double x = -size.height; x < size.width + size.height; x += 14) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        weavePaint,
      );
    }

    // Pasy mistrzowskie na rurze ramy
    final stripeTop = size.height * 0.22;
    final stripeHeight = size.height * 0.56;
    final stripeLeft = size.width * 0.05;
    final stripeWidth = size.width * 0.14;

    if (record.editionType == ChampionshipEditionType.worldChampionRainbow) {
      const uciColors = <Color>[
        Color(0xFF2563EB),
        Color(0xFFEF4444),
        Color(0xFF111827),
        Color(0xFFFACC15),
        Color(0xFF10B981),
      ];
      final bandHeight = stripeHeight / uciColors.length;
      for (int i = 0; i < uciColors.length; i++) {
        canvas.drawRect(
          Rect.fromLTWH(
            stripeLeft,
            stripeTop + i * bandHeight,
            stripeWidth,
            bandHeight,
          ),
          Paint()..color = uciColors[i],
        );
      }
    } else {
      final accentRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(stripeLeft, stripeTop, stripeWidth, stripeHeight),
        const Radius.circular(6),
      );
      canvas.drawRRect(
        accentRect,
        Paint()..color = record.editionType.primaryDecalColor,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          stripeLeft + stripeWidth * 0.68,
          stripeTop,
          stripeWidth * 0.16,
          stripeHeight,
        ),
        Paint()..color = record.editionType.accentDecalColor,
      );
    }

    // Złota obwódka tabliczki numeru seryjnego
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = record.isGoldMasterEdition ? 1.5 : 1.0
      ..color = record.isGoldMasterEdition
          ? AppColors.goldAccent.withValues(alpha: 0.75)
          : AppColors.cardBorder;
    canvas.drawRRect(rrect, borderPaint);

    // Grawer numeru seryjnego na rurze
    final textPainter = TextPainter(
      text: TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: '${record.serialNumber}  •  ${record.nationalFlagCode}\n',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: record.isGoldMasterEdition
                  ? AppColors.goldAccent
                  : AppColors.accentBlue,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          TextSpan(
            text: record.customTopTubeInscription,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    )..layout(maxWidth: size.width * 0.72);

    textPainter.paint(
      canvas,
      Offset(
        stripeLeft + stripeWidth + 16,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant FrameDecalSerialPlatePainter oldDelegate) {
    return oldDelegate.record != record;
  }
}

/// Produkcyjny panel zarządzania indywidualnymi numerami seryjnymi ram oraz złotymi edycjami mistrzowskimi.
class EquipmentWindTunnelCustomDecalsPanel extends ConsumerStatefulWidget {
  const EquipmentWindTunnelCustomDecalsPanel({super.key});

  @override
  ConsumerState<EquipmentWindTunnelCustomDecalsPanel> createState() =>
      _EquipmentWindTunnelCustomDecalsPanelState();
}

class _EquipmentWindTunnelCustomDecalsPanelState
    extends ConsumerState<EquipmentWindTunnelCustomDecalsPanel> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _modelNameController = TextEditingController(
    text: 'S-Works Tarmac SL8',
  );
  final TextEditingController _manufacturerController = TextEditingController(
    text: 'Specialized Lab',
  );
  final TextEditingController _inscriptionController = TextEditingController(
    text: 'PARIS 2026 • AERO',
  );
  final TextEditingController _flagController = TextEditingController(
    text: 'POL',
  );
  final TextEditingController _riderController = TextEditingController(
    text: 'Michał Kowalski',
  );

  bool _showMintComposer = false;
  ChampionshipEditionType _draftEdition =
      ChampionshipEditionType.worldChampionRainbow;
  DecalFinishStyle _draftFinish = DecalFinishStyle.glossMetallicGold;

  @override
  void dispose() {
    _searchController.dispose();
    _modelNameController.dispose();
    _manufacturerController.dispose();
    _inscriptionController.dispose();
    _flagController.dispose();
    _riderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(equipmentWindTunnelDecalsProvider);
    final notifier = ref.read(equipmentWindTunnelDecalsProvider.notifier);
    final filtered = state.filteredFrames;
    final selected = state.selectedFrame;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1000;
          final isCompact = constraints.maxWidth < 600;

          return Padding(
            padding: EdgeInsets.all(isCompact ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildHeader(context, state, isCompact),
                const SizedBox(height: 16),
                _buildKpiStrip(state, isCompact),
                if (state.lastError != null || state.lastNotification != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildFeedbackBanner(state),
                  ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 260),
                  sizeCurve: Curves.easeOutCubic,
                  crossFadeState: _showMintComposer
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _buildMintComposer(notifier, state, isCompact),
                  ),
                ),
                const SizedBox(height: 16),
                _buildFilterBar(state, notifier, isCompact),
                const SizedBox(height: 16),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        flex: 5,
                        child: _buildSerialList(filtered, selected, notifier),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 6,
                        child: _buildDetailInspector(
                          selected,
                          state,
                          notifier,
                          isCompact,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _buildSerialList(filtered, selected, notifier),
                      const SizedBox(height: 16),
                      _buildDetailInspector(
                        selected,
                        state,
                        notifier,
                        isCompact,
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

  Widget _buildHeader(
    BuildContext context,
    EquipmentWindTunnelDecalsState state,
    bool isCompact,
  ) {
    final titleSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.goldAccent.withValues(alpha: 0.45),
                ),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.goldAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Numery Seryjne Ram & Złote Edycje Mistrzowskie',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 16 : 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Rejestr numerów seryjnych z tunelu aerodynamicznego, personalizowane kalkomanie oraz lakiernia 24k.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    final actionButton = _InteractiveActionButton(
      label: _showMintComposer ? 'Zamknij Kreator' : 'Nowa Rama / Serial',
      icon: _showMintComposer
          ? Icons.close_rounded
          : Icons.add_circle_outline_rounded,
      accentColor: AppColors.goldAccent,
      onPressed: () {
        setState(() {
          _showMintComposer = !_showMintComposer;
        });
      },
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          titleSection,
          const SizedBox(height: 12),
          actionButton,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(child: titleSection),
        const SizedBox(width: 16),
        actionButton,
      ],
    );
  }

  Widget _buildKpiStrip(EquipmentWindTunnelDecalsState state, bool isCompact) {
    final cards = <Widget>[
      _KpiStatCard(
        label: 'Zserializowane Ramy',
        value: '${state.frames.length}',
        accent: AppColors.accentBlue,
        icon: Icons.qr_code_2_rounded,
      ),
      _KpiStatCard(
        label: 'Złote Edycje Mistrzowskie',
        value: '${state.goldEditionsCount}',
        accent: AppColors.goldAccent,
        icon: Icons.emoji_events_rounded,
      ),
      _KpiStatCard(
        label: 'Wartość Kolekcjonerska',
        value: Formatters.formatCurrency(state.totalFleetCollectorValueEur),
        accent: AppColors.statusSuccess,
        icon: Icons.account_balance_rounded,
      ),
      _KpiStatCard(
        label: 'Budżet Lakierni',
        value: Formatters.formatCurrency(state.availableBudgetEur),
        accent: AppColors.primaryAccent,
        icon: Icons.payments_rounded,
      ),
    ];

    if (isCompact) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.95,
        children: cards,
      );
    }

    return Row(
      children: <Widget>[
        for (int i = 0; i < cards.length; i++) ...<Widget>[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildFeedbackBanner(EquipmentWindTunnelDecalsState state) {
    final isError = state.lastError != null;
    final color = isError ? AppColors.crimsonAlert : AppColors.statusSuccess;
    final message = isError ? state.lastError! : state.lastNotification!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMintComposer(
    EquipmentWindTunnelDecalsNotifier notifier,
    EquipmentWindTunnelDecalsState state,
    bool isCompact,
  ) {
    final totalCost =
        _draftEdition.upgradeCostEur + _draftFinish.paintShopFeeEur;
    final canAfford = state.availableBudgetEur >= totalCost;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Rejestracja Nowego Numeru Seryjnego & Kalkomanii',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              SizedBox(
                width: isCompact ? double.infinity : 230,
                child: _buildTextField(
                  controller: _modelNameController,
                  label: 'Model Ramy',
                ),
              ),
              SizedBox(
                width: isCompact ? double.infinity : 200,
                child: _buildTextField(
                  controller: _manufacturerController,
                  label: 'Producent / Atelier',
                ),
              ),
              SizedBox(
                width: isCompact ? double.infinity : 240,
                child: _buildTextField(
                  controller: _inscriptionController,
                  label: 'Grawer / Inskrypcja Górnej Rury',
                ),
              ),
              SizedBox(
                width: isCompact ? 120 : 100,
                child: _buildTextField(
                  controller: _flagController,
                  label: 'Flaga (3 lit.)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ChampionshipEditionType.values.map((edition) {
              final selected = _draftEdition == edition;
              return _InteractiveFilterChip(
                label: edition.label,
                selected: selected,
                accent: edition.primaryDecalColor,
                onTap: () => setState(() => _draftEdition = edition),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DecalFinishStyle.values.map((finish) {
              final selected = _draftFinish == finish;
              return _InteractiveFilterChip(
                label: finish.label,
                selected: selected,
                accent: AppColors.goldAccent,
                onTap: () => setState(() => _draftFinish = finish),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Koszt wykonania: ${Formatters.formatCurrency(totalCost)}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: canAfford
                        ? AppColors.textPrimary
                        : AppColors.crimsonAlert,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
              _InteractiveActionButton(
                label: 'Nadaj Serial & Lakieruj',
                icon: Icons.verified_rounded,
                accentColor: AppColors.statusSuccess,
                enabled: canAfford,
                onPressed: () {
                  notifier.mintCustomSerialFrame(
                    frameModelId:
                        'custom_${_modelNameController.text.trim().toLowerCase().replaceAll(' ', '_')}',
                    frameModelName: _modelNameController.text,
                    manufacturerName: _manufacturerController.text,
                    editionType: _draftEdition,
                    finishStyle: _draftFinish,
                    customTopTubeInscription: _inscriptionController.text,
                    nationalFlagCode: _flagController.text,
                  );
                  setState(() {
                    _showMintComposer = false;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
    EquipmentWindTunnelDecalsState state,
    EquipmentWindTunnelDecalsNotifier notifier,
    bool isCompact,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildTextField(
            controller: _searchController,
            label: 'Szukaj po numerze seryjnym, kolarzu, modelu lub fladze...',
            prefixIcon: Icons.search_rounded,
            onChanged: notifier.setSearchQuery,
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _InteractiveFilterChip(
                  label: 'Wszystkie edycje',
                  selected: state.activeFilterEdition == null,
                  accent: AppColors.accentBlue,
                  onTap: () => notifier.setEditionFilter(null),
                ),
                const SizedBox(width: 8),
                for (final edition
                    in ChampionshipEditionType.values) ...<Widget>[
                  _InteractiveFilterChip(
                    label: edition.label,
                    selected: state.activeFilterEdition == edition,
                    accent: edition.primaryDecalColor,
                    onTap: () => notifier.setEditionFilter(
                      state.activeFilterEdition == edition ? null : edition,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSerialList(
    List<CustomFrameSerialRecord> frames,
    CustomFrameSerialRecord? selected,
    EquipmentWindTunnelDecalsNotifier notifier,
  ) {
    if (frames.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Center(
          child: Text(
            'Brak ram spełniających kryteria filtrowania.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < frames.length; i++) ...<Widget>[
            _SerialFrameListTile(
              record: frames[i],
              isSelected: selected?.serialNumber == frames[i].serialNumber,
              onTap: () => notifier.selectFrame(frames[i].serialNumber),
            ),
            if (i < frames.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailInspector(
    CustomFrameSerialRecord? record,
    EquipmentWindTunnelDecalsState state,
    EquipmentWindTunnelDecalsNotifier notifier,
    bool isCompact,
  ) {
    if (record == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Center(
          child: Text(
            'Wybierz ramę z listy, aby otworzyć inspekcję lakierni.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final goldUpgradeCost =
        (ChampionshipEditionType.worldChampionRainbow.upgradeCostEur * 0.75) +
        (DecalFinishStyle.glossMetallicGold.paintShopFeeEur * 0.65);
    final canUpgradeToGold =
        record.status != SerialFrameStatus.museumArchived &&
        record.status != SerialFrameStatus.retiredDamaged &&
        state.availableBudgetEur >= goldUpgradeCost;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: record.isGoldMasterEdition
              ? AppColors.goldAccent.withValues(alpha: 0.6)
              : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      record.frameModelName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${record.manufacturerName} • ${record.editionType.label}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: record.status.badgeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: record.status.badgeColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  record.status.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: record.status.badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 92,
            child: CustomPaint(
              painter: FrameDecalSerialPlatePainter(record: record),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _MetricChip(
                label: 'Tunel Aero CdA',
                value: record.windTunnelCdA.toStringAsFixed(4),
                color: AppColors.cyanAccent,
              ),
              _MetricChip(
                label: 'Waga Ramy',
                value: '${record.frameWeightGrams} g',
                color: AppColors.textPrimary,
              ),
              _MetricChip(
                label: 'Przebieg',
                value: '${record.kilometersRidden.toStringAsFixed(0)} km',
                color: AppColors.accentBlue,
              ),
              _MetricChip(
                label: 'Zwycięstwa / GT / Mon.',
                value:
                    '${record.victoriesCount} / ${record.grandTourStagesWon} / ${record.monumentsWon}',
                color: AppColors.goldAccent,
              ),
              _MetricChip(
                label: 'Wartość Kolekcjonerska',
                value: Formatters.formatCurrency(record.estimatedCollectorValueEur),
                color: AppColors.statusSuccess,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!isCompact)
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildTextField(
                    controller: _riderController,
                    label: 'Kolarz do przypisania',
                  ),
                ),
                const SizedBox(width: 10),
                _InteractiveActionButton(
                  label: record.assignedRiderName == null
                      ? 'Przypisz'
                      : 'Zwolnij',
                  icon: record.assignedRiderName == null
                      ? Icons.person_add_alt_1_rounded
                      : Icons.person_remove_rounded,
                  accentColor: AppColors.accentBlue,
                  enabled: record.canBeAssigned,
                  onPressed: () {
                    if (record.assignedRiderName == null) {
                      notifier.assignFrameToRider(
                        serialNumber: record.serialNumber,
                        riderId: 'rider_custom',
                        riderName: _riderController.text,
                      );
                    } else {
                      notifier.assignFrameToRider(
                        serialNumber: record.serialNumber,
                      );
                    }
                  },
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildTextField(
                  controller: _riderController,
                  label: 'Kolarz do przypisania',
                ),
                const SizedBox(height: 8),
                _InteractiveActionButton(
                  label: record.assignedRiderName == null
                      ? 'Przypisz Kolarzowi'
                      : 'Zwolnij do Bazy',
                  icon: record.assignedRiderName == null
                      ? Icons.person_add_alt_1_rounded
                      : Icons.person_remove_rounded,
                  accentColor: AppColors.accentBlue,
                  enabled: record.canBeAssigned,
                  onPressed: () {
                    if (record.assignedRiderName == null) {
                      notifier.assignFrameToRider(
                        serialNumber: record.serialNumber,
                        riderId: 'rider_custom',
                        riderName: _riderController.text,
                      );
                    } else {
                      notifier.assignFrameToRider(
                        serialNumber: record.serialNumber,
                      );
                    }
                  },
                ),
              ],
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _InteractiveActionButton(
                label: 'Złota Edycja Mistrzowska 24k',
                icon: Icons.auto_awesome_rounded,
                accentColor: AppColors.goldAccent,
                enabled: canUpgradeToGold,
                onPressed: () {
                  notifier.upgradeToChampionshipEdition(
                    serialNumber: record.serialNumber,
                    targetEdition:
                        ChampionshipEditionType.worldChampionRainbow,
                    targetFinish: DecalFinishStyle.glossMetallicGold,
                    customInscription: '${record.nationalFlagCode} GOLD 24k',
                  );
                },
              ),
              _InteractiveActionButton(
                label: '+150 km & Wygrana',
                icon: Icons.add_road_rounded,
                accentColor: AppColors.statusSuccess,
                enabled: record.status != SerialFrameStatus.museumArchived,
                onPressed: () {
                  notifier.recordRaceUsage(
                    serialNumber: record.serialNumber,
                    addedKilometers: 150,
                    addedVictories: 1,
                  );
                },
              ),
              _InteractiveActionButton(
                label: 'Archiwizuj w Muzeum',
                icon: Icons.museum_rounded,
                accentColor: AppColors.primaryAccent,
                enabled: record.canBeArchived,
                onPressed: () {
                  notifier.archiveToClubMuseum(record.serialNumber);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? prefixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: AppColors.textSecondary)
            : null,
        filled: true,
        fillColor: AppColors.surfaceLight,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.goldAccent, width: 1.4),
        ),
      ),
    );
  }
}

class _KpiStatCard extends StatelessWidget {
  const _KpiStatCard({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SerialFrameListTile extends StatefulWidget {
  const _SerialFrameListTile({
    required this.record,
    required this.isSelected,
    required this.onTap,
  });

  final CustomFrameSerialRecord record;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_SerialFrameListTile> createState() => _SerialFrameListTileState();
}

class _SerialFrameListTileState extends State<_SerialFrameListTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected
        ? AppColors.goldAccent
        : _focused
        ? AppColors.accentBlue
        : _hovered
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : AppColors.cardBorder;

    return FocusableActionDetector(
      onShowHoverHighlight: (value) => setState(() => _hovered = value),
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.goldAccent.withValues(alpha: 0.14),
          highlightColor: AppColors.goldAccent.withValues(alpha: 0.08),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.surfaceLight
                  : (_hovered
                        ? AppColors.surfaceLight.withValues(alpha: 0.65)
                        : AppColors.background),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: widget.isSelected ? 1.4 : 1.0,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 8,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.record.editionType.primaryDecalColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.record.serialNumber,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: widget.record.isGoldMasterEdition
                              ? AppColors.goldAccent
                              : AppColors.accentBlue,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.record.frameModelName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        widget.record.assignedRiderName ??
                            widget.record.status.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                  Formatters.formatCurrency(widget.record.estimatedCollectorValueEur),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onPressed;
  final bool enabled;

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
    final effectiveAccent = widget.enabled
        ? widget.accentColor
        : AppColors.textSecondary;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.enabled ? widget.onPressed : null,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: !widget.enabled
                  ? AppColors.surfaceLight.withValues(alpha: 0.4)
                  : _pressed
                  ? effectiveAccent.withValues(alpha: 0.28)
                  : _hovered
                  ? effectiveAccent.withValues(alpha: 0.2)
                  : effectiveAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused
                    ? AppColors.textPrimary
                    : effectiveAccent.withValues(
                        alpha: widget.enabled ? 0.65 : 0.25,
                      ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(widget.icon, size: 16, color: effectiveAccent),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
      ),
    );
  }
}

class _InteractiveFilterChip extends StatefulWidget {
  const _InteractiveFilterChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_InteractiveFilterChip> createState() => _InteractiveFilterChipState();
}

class _InteractiveFilterChipState extends State<_InteractiveFilterChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: widget.selected
                  ? widget.accent.withValues(alpha: 0.2)
                  : _hovered
                  ? AppColors.surfaceLight
                  : AppColors.background,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _focused
                    ? AppColors.textPrimary
                    : widget.selected
                    ? widget.accent
                    : AppColors.cardBorder,
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                color: widget.selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
