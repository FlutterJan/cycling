import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/equipment/complete_bike.dart';
import '../../models/equipment/frame_model.dart';
import '../../models/equipment/groupset_model.dart';
import '../../models/equipment/tire_model.dart';
import '../../models/equipment/wheelset_model.dart';
import 'bike_preview_painter.dart';
import 'custom_jersey_painter.dart';

/// Kategoria sukcesu odniesionego w historycznych barwach drużyny.
enum KitSuccessCategory {
  grandTour('Wielki Tour', Icons.emoji_events_rounded, AppColors.goldAccent),
  monument('Monument', Icons.workspace_premium_rounded, AppColors.amberWarning),
  worldTourStageRace(
    'Wyścig Etapowy WT',
    Icons.terrain_rounded,
    AppColors.accentBlue,
  ),
  classic('Klasyk', Icons.bolt_rounded, AppColors.cyanAccent),
  nationalChampionship(
    'Mistrzostwa Krajowe',
    Icons.flag_rounded,
    AppColors.statusSuccess,
  ),
  worldChampionship(
    'Mistrzostwa Świata',
    Icons.public_rounded,
    AppColors.goldAccent,
  ),
  uciTeamRanking(
    'Ranking UCI',
    Icons.leaderboard_rounded,
    AppColors.primaryAccent,
  );

  final String label;
  final IconData icon;
  final Color accentColor;

  const KitSuccessCategory(this.label, this.icon, this.accentColor);

  static KitSuccessCategory fromJson(String value) {
    return KitSuccessCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => KitSuccessCategory.classic,
    );
  }
}

/// Filtry prezentacji sezonów w galerii ewolucji koszulek.
enum KitGalleryFilterMode {
  all('Wszystkie'),
  majorTrophies('Złote trofea'),
  grandTours('Wielkie Toury'),
  monuments('Monumenty');

  final String label;
  const KitGalleryFilterMode(this.label);
}

/// Kolejność sortowania sezonów w galerii.
enum KitGallerySortOrder {
  newestFirst('Najnowsze'),
  oldestFirst('Chronologicznie'),
  mostWins('Najwięcej wygranych');

  final String label;
  const KitGallerySortOrder(this.label);
}

/// Pojedynczy sukces odniesiony przez drużynę w danym sezonie i barwach.
class SeasonKitSuccessEntry {
  final String id;
  final String raceName;
  final KitSuccessCategory category;
  final String riderName;
  final String achievementDetail;
  final bool isMajorTrophy;
  final int uciPoints;

  const SeasonKitSuccessEntry({
    required this.id,
    required this.raceName,
    required this.category,
    required this.riderName,
    required this.achievementDetail,
    this.isMajorTrophy = false,
    this.uciPoints = 0,
  });

  SeasonKitSuccessEntry copyWith({
    String? id,
    String? raceName,
    KitSuccessCategory? category,
    String? riderName,
    String? achievementDetail,
    bool? isMajorTrophy,
    int? uciPoints,
  }) {
    return SeasonKitSuccessEntry(
      id: id ?? this.id,
      raceName: raceName ?? this.raceName,
      category: category ?? this.category,
      riderName: riderName ?? this.riderName,
      achievementDetail: achievementDetail ?? this.achievementDetail,
      isMajorTrophy: isMajorTrophy ?? this.isMajorTrophy,
      uciPoints: uciPoints ?? this.uciPoints,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'raceName': raceName,
      'category': category.name,
      'riderName': riderName,
      'achievementDetail': achievementDetail,
      'isMajorTrophy': isMajorTrophy,
      'uciPoints': uciPoints,
    };
  }

  factory SeasonKitSuccessEntry.fromJson(Map<String, dynamic> json) {
    return SeasonKitSuccessEntry(
      id: json['id'] as String? ?? '',
      raceName: json['raceName'] as String? ?? '',
      category: KitSuccessCategory.fromJson(
        json['category'] as String? ?? 'classic',
      ),
      riderName: json['riderName'] as String? ?? '',
      achievementDetail: json['achievementDetail'] as String? ?? '',
      isMajorTrophy: json['isMajorTrophy'] as bool? ?? false,
      uciPoints: (json['uciPoints'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SeasonKitSuccessEntry &&
        other.id == id &&
        other.raceName == raceName &&
        other.category == category &&
        other.riderName == riderName &&
        other.achievementDetail == achievementDetail &&
        other.isMajorTrophy == isMajorTrophy &&
        other.uciPoints == uciPoints;
  }

  @override
  int get hashCode => Object.hash(
        id,
        raceName,
        category,
        riderName,
        achievementDetail,
        isMajorTrophy,
        uciPoints,
      );
}

/// Pełny archiwalny wpis jednego ukończonego sezonu: wzór koszulki, rower oraz lista sukcesów.
class TeamSeasonKitRecord {
  final int seasonYear;
  final String teamName;
  final String teamTla;
  final String divisionLabel;
  final String titleSponsorName;
  final String? secondarySponsorName;
  final String bikeManufacturerName;
  final JerseyPattern jerseyPattern;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color? sponsorTextColor;
  final Color? frameColorOverride;
  final Color? barTapeColorOverride;
  final bool isTanWall;
  final CompleteBike bike;
  final List<SeasonKitSuccessEntry> successes;
  final int totalWinsCount;
  final int? uciRankPosition;
  final int uciPointsTotal;
  final String seasonSummaryNote;
  final DateTime archivedAt;

  const TeamSeasonKitRecord({
    required this.seasonYear,
    required this.teamName,
    required this.teamTla,
    required this.divisionLabel,
    required this.titleSponsorName,
    this.secondarySponsorName,
    required this.bikeManufacturerName,
    required this.jerseyPattern,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    this.sponsorTextColor,
    this.frameColorOverride,
    this.barTapeColorOverride,
    this.isTanWall = false,
    required this.bike,
    required this.successes,
    required this.totalWinsCount,
    this.uciRankPosition,
    required this.uciPointsTotal,
    this.seasonSummaryNote = '',
    required this.archivedAt,
  });

  int get majorSuccessesCount =>
      successes.where((entry) => entry.isMajorTrophy).length;

  bool get hasGrandTourSuccess => successes.any(
        (entry) => entry.category == KitSuccessCategory.grandTour,
      );

  bool get hasMonumentSuccess => successes.any(
        (entry) => entry.category == KitSuccessCategory.monument,
      );

  TeamSeasonKitRecord copyWith({
    int? seasonYear,
    String? teamName,
    String? teamTla,
    String? divisionLabel,
    String? titleSponsorName,
    String? secondarySponsorName,
    String? bikeManufacturerName,
    JerseyPattern? jerseyPattern,
    Color? primaryColor,
    Color? secondaryColor,
    Color? accentColor,
    Color? sponsorTextColor,
    Color? frameColorOverride,
    Color? barTapeColorOverride,
    bool? isTanWall,
    CompleteBike? bike,
    List<SeasonKitSuccessEntry>? successes,
    int? totalWinsCount,
    int? uciRankPosition,
    int? uciPointsTotal,
    String? seasonSummaryNote,
    DateTime? archivedAt,
  }) {
    return TeamSeasonKitRecord(
      seasonYear: seasonYear ?? this.seasonYear,
      teamName: teamName ?? this.teamName,
      teamTla: teamTla ?? this.teamTla,
      divisionLabel: divisionLabel ?? this.divisionLabel,
      titleSponsorName: titleSponsorName ?? this.titleSponsorName,
      secondarySponsorName: secondarySponsorName ?? this.secondarySponsorName,
      bikeManufacturerName: bikeManufacturerName ?? this.bikeManufacturerName,
      jerseyPattern: jerseyPattern ?? this.jerseyPattern,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      sponsorTextColor: sponsorTextColor ?? this.sponsorTextColor,
      frameColorOverride: frameColorOverride ?? this.frameColorOverride,
      barTapeColorOverride: barTapeColorOverride ?? this.barTapeColorOverride,
      isTanWall: isTanWall ?? this.isTanWall,
      bike: bike ?? this.bike,
      successes: successes ?? this.successes,
      totalWinsCount: totalWinsCount ?? this.totalWinsCount,
      uciRankPosition: uciRankPosition ?? this.uciRankPosition,
      uciPointsTotal: uciPointsTotal ?? this.uciPointsTotal,
      seasonSummaryNote: seasonSummaryNote ?? this.seasonSummaryNote,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seasonYear': seasonYear,
      'teamName': teamName,
      'teamTla': teamTla,
      'divisionLabel': divisionLabel,
      'titleSponsorName': titleSponsorName,
      'secondarySponsorName': secondarySponsorName,
      'bikeManufacturerName': bikeManufacturerName,
      'jerseyPattern': jerseyPattern.name,
      'primaryColorArgb': primaryColor.toARGB32(),
      'secondaryColorArgb': secondaryColor.toARGB32(),
      'accentColorArgb': accentColor.toARGB32(),
      'sponsorTextColorArgb': sponsorTextColor?.toARGB32(),
      'frameColorOverrideArgb': frameColorOverride?.toARGB32(),
      'barTapeColorOverrideArgb': barTapeColorOverride?.toARGB32(),
      'isTanWall': isTanWall,
      'bike': bike.toJson(),
      'successes': successes.map((e) => e.toJson()).toList(),
      'totalWinsCount': totalWinsCount,
      'uciRankPosition': uciRankPosition,
      'uciPointsTotal': uciPointsTotal,
      'seasonSummaryNote': seasonSummaryNote,
      'archivedAt': archivedAt.toIso8601String(),
    };
  }

  factory TeamSeasonKitRecord.fromJson(Map<String, dynamic> json) {
    final patternName = json['jerseyPattern'] as String? ?? 'chestStripe';
    final pattern = JerseyPattern.values.firstWhere(
      (e) => e.name.toLowerCase() == patternName.toLowerCase(),
      orElse: () => JerseyPattern.chestStripe,
    );

    final successesRaw = (json['successes'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(SeasonKitSuccessEntry.fromJson)
        .toList();

    return TeamSeasonKitRecord(
      seasonYear: (json['seasonYear'] as num).toInt(),
      teamName: json['teamName'] as String? ?? 'Pro Peloton Team',
      teamTla: json['teamTla'] as String? ?? 'PPT',
      divisionLabel: json['divisionLabel'] as String? ?? 'UCI WorldTour',
      titleSponsorName: json['titleSponsorName'] as String? ?? 'VeloTech',
      secondarySponsorName: json['secondarySponsorName'] as String?,
      bikeManufacturerName:
          json['bikeManufacturerName'] as String? ?? 'Aether Cycles',
      jerseyPattern: pattern,
      primaryColor: Color(
        (json['primaryColorArgb'] as num?)?.toInt() ?? 0xFF8E4A49,
      ),
      secondaryColor: Color(
        (json['secondaryColorArgb'] as num?)?.toInt() ?? 0xFF181B22,
      ),
      accentColor: Color(
        (json['accentColorArgb'] as num?)?.toInt() ?? 0xFFD4AF37,
      ),
      sponsorTextColor: json['sponsorTextColorArgb'] != null
          ? Color((json['sponsorTextColorArgb'] as num).toInt())
          : null,
      frameColorOverride: json['frameColorOverrideArgb'] != null
          ? Color((json['frameColorOverrideArgb'] as num).toInt())
          : null,
      barTapeColorOverride: json['barTapeColorOverrideArgb'] != null
          ? Color((json['barTapeColorOverrideArgb'] as num).toInt())
          : null,
      isTanWall: json['isTanWall'] as bool? ?? false,
      bike: CompleteBike.fromJson(
        json['bike'] as Map<String, dynamic>,
      ),
      successes: successesRaw,
      totalWinsCount: (json['totalWinsCount'] as num?)?.toInt() ?? 0,
      uciRankPosition: (json['uciRankPosition'] as num?)?.toInt(),
      uciPointsTotal: (json['uciPointsTotal'] as num?)?.toInt() ?? 0,
      seasonSummaryNote: json['seasonSummaryNote'] as String? ?? '',
      archivedAt: DateTime.tryParse(json['archivedAt'] as String? ?? '') ??
          DateTime(2026, 10, 20),
    );
  }
}

/// Narzędzie archiwizacji ukończonych sezonów oraz generator domyślnej historii ewolucji barw.
class TeamKitEvolutionArchive {
  TeamKitEvolutionArchive._();

  /// Zapisuje lub aktualizuje wpis ukończonego sezonu w archiwum, zachowując porządek chronologiczny.
  static List<TeamSeasonKitRecord> archiveCompletedSeason({
    required List<TeamSeasonKitRecord> existingArchive,
    required TeamSeasonKitRecord completedSeasonRecord,
  }) {
    final updated = List<TeamSeasonKitRecord>.from(existingArchive);
    final existingIndex = updated.indexWhere(
      (item) => item.seasonYear == completedSeasonRecord.seasonYear,
    );
    if (existingIndex >= 0) {
      updated[existingIndex] = completedSeasonRecord;
    } else {
      updated.add(completedSeasonRecord);
    }
    updated.sort((a, b) => a.seasonYear.compareTo(b.seasonYear));
    return List.unmodifiable(updated);
  }

  /// Tworzy realistyczną, 4-sezonową historię ewolucji koszulek, rowerów i sukcesów drużyny.
  static List<TeamSeasonKitRecord> buildDemoArchive() {
    return [
      TeamSeasonKitRecord(
        seasonYear: 2026,
        teamName: 'Vistula Pro Cycling',
        teamTla: 'VPC',
        divisionLabel: 'UCI Continental',
        titleSponsorName: 'Vistula Energy',
        secondarySponsorName: 'Kraków Tech',
        bikeManufacturerName: 'Romet Carbon Works',
        jerseyPattern: JerseyPattern.solid,
        primaryColor: const Color(0xFF1E293B),
        secondaryColor: const Color(0xFF8E4A49),
        accentColor: const Color(0xFFF3F4F6),
        sponsorTextColor: Colors.white,
        frameColorOverride: const Color(0xFF8E4A49),
        barTapeColorOverride: const Color(0xFF11141B),
        isTanWall: false,
        totalWinsCount: 9,
        uciRankPosition: 29,
        uciPointsTotal: 1420,
        seasonSummaryNote:
            'Debiutancki sezon na klasycznym granacie z burgundowym akcentem i pierwszą ramą all-round.',
        archivedAt: DateTime(2026, 10, 18),
        bike: const CompleteBike(
          id: 'bike_2026_vpc',
          name: 'RCW Strada Pro 2026',
          cockpitWidthMm: 400,
          hoodInwardTiltDegrees: 4.0,
          slammedStem: false,
          frame: FrameModel(
            id: 'frame_2026',
            brandId: 'romet',
            name: 'RCW Strada SL',
            category: FrameCategory.allRounder,
            weightGrams: 890,
            aeroCdaModifier: -0.004,
            stiffnessToWeightIndex: 1.55,
            comfortCompliance: 0.72,
            priceEur: 4200,
            mesh3dAssetPath: 'assets/3d/bikes/frame_allround.glb',
            primaryColorHex: '#8E4A49',
          ),
          wheelset: WheelsetModel(
            id: 'wheel_2026',
            brandId: 'dt',
            name: 'Alloy-Carbon 38mm',
            rimDepthMm: 38,
            weightGrams: 1480,
            aeroCdaModifier: -0.004,
            crosswindStabilityPenalty: 0.15,
            momentOfInertia: 0.088,
            hubEngagementDragWatts: 2.1,
            priceEur: 1900,
          ),
          groupset: GroupsetModel(
            id: 'grp_2026',
            brandId: 'shimano',
            name: 'Ultegra Di2 12s',
            weightGrams: 2350,
            isElectronic: true,
            speedCount: 12,
            mechanicalEfficiency: 0.980,
            priceEur: 2400,
          ),
          tire: TireModel(
            id: 'tire_2026',
            brandId: 'conti',
            name: 'Grand Prix 5000 S TR 28',
            widthMm: 28,
            weightGrams: 275,
            rollingResistanceCrr: 0.0038,
            punctureResistanceIndex: 3.4,
            wetGripIndex: 4.1,
            isTubeless: true,
            priceEur: 85,
          ),
        ),
        successes: const [
          SeasonKitSuccessEntry(
            id: 'suc_2026_1',
            raceName: 'Tour of Małopolska',
            category: KitSuccessCategory.worldTourStageRace,
            riderName: 'M. Kowalski',
            achievementDetail: '1. miejsce GC + 2 etapy górskie',
            isMajorTrophy: false,
            uciPoints: 210,
          ),
          SeasonKitSuccessEntry(
            id: 'suc_2026_2',
            raceName: 'Mistrzostwa Polski',
            category: KitSuccessCategory.nationalChampionship,
            riderName: 'K. Zieliński',
            achievementDetail: 'Złoty medal ze startu wspólnego',
            isMajorTrophy: true,
            uciPoints: 180,
          ),
        ],
      ),
      TeamSeasonKitRecord(
        seasonYear: 2027,
        teamName: 'Vistula-Nordic Bank',
        teamTla: 'VNB',
        divisionLabel: 'UCI ProTeam',
        titleSponsorName: 'Nordic Bank',
        secondarySponsorName: 'Vistula Energy',
        bikeManufacturerName: 'Aether Cycles',
        jerseyPattern: JerseyPattern.chestStripe,
        primaryColor: const Color(0xFF0F172A),
        secondaryColor: const Color(0xFF38BDF8),
        accentColor: const Color(0xFFD4AF37),
        sponsorTextColor: Colors.white,
        frameColorOverride: const Color(0xFF38BDF8),
        barTapeColorOverride: Colors.white,
        isTanWall: true,
        totalWinsCount: 17,
        uciRankPosition: 16,
        uciPointsTotal: 4860,
        seasonSummaryNote:
            'Awans do ProTeam i kontrakt z Nordic Bank — wprowadzenie błękitnego pasa na piersi oraz kół 50 mm.',
        archivedAt: DateTime(2027, 10, 21),
        bike: const CompleteBike(
          id: 'bike_2027_vnb',
          name: 'Aether Veloce Aero 2027',
          cockpitWidthMm: 380,
          hoodInwardTiltDegrees: 8.0,
          slammedStem: true,
          frame: FrameModel(
            id: 'frame_2027',
            brandId: 'aether',
            name: 'Aether Veloce R2',
            category: FrameCategory.aero,
            weightGrams: 785,
            aeroCdaModifier: -0.013,
            stiffnessToWeightIndex: 1.88,
            comfortCompliance: 0.65,
            priceEur: 6400,
            mesh3dAssetPath: 'assets/3d/bikes/frame_aero.glb',
            primaryColorHex: '#38BDF8',
          ),
          wheelset: WheelsetModel(
            id: 'wheel_2027',
            brandId: 'aether_wheels',
            name: 'AeroBlade 50 Carbon',
            rimDepthMm: 50,
            weightGrams: 1360,
            aeroCdaModifier: -0.009,
            crosswindStabilityPenalty: 0.34,
            momentOfInertia: 0.082,
            hubEngagementDragWatts: 1.4,
            priceEur: 3100,
          ),
          groupset: GroupsetModel(
            id: 'grp_2027',
            brandId: 'shimano',
            name: 'Dura-Ace Di2 12s',
            weightGrams: 2140,
            isElectronic: true,
            speedCount: 12,
            mechanicalEfficiency: 0.984,
            priceEur: 3900,
          ),
          tire: TireModel(
            id: 'tire_2027',
            brandId: 'vittoria',
            name: 'Corsa Pro Tan-Wall 28',
            widthMm: 28,
            weightGrams: 260,
            rollingResistanceCrr: 0.0034,
            punctureResistanceIndex: 3.1,
            wetGripIndex: 4.3,
            isTubeless: true,
            priceEur: 95,
          ),
        ),
        successes: const [
          SeasonKitSuccessEntry(
            id: 'suc_2027_1',
            raceName: 'Tour de Pologne',
            category: KitSuccessCategory.worldTourStageRace,
            riderName: 'M. Kowalski',
            achievementDetail: '2. miejsce GC + zwycięstwo na etapie w Karpaczu',
            isMajorTrophy: true,
            uciPoints: 460,
          ),
          SeasonKitSuccessEntry(
            id: 'suc_2027_2',
            raceName: 'Kuurne-Bruxelles-Kuurne',
            category: KitSuccessCategory.classic,
            riderName: 'L. Van Der Berg',
            achievementDetail: 'Zwycięstwo po finiszu z 12-osobowej grupy',
            isMajorTrophy: false,
            uciPoints: 200,
          ),
          SeasonKitSuccessEntry(
            id: 'suc_2027_3',
            raceName: 'Vuelta a España (Dzika Karta)',
            category: KitSuccessCategory.grandTour,
            riderName: 'M. Kowalski',
            achievementDetail: 'Wygrana etapowa na Angliru + 5 dni w góralu',
            isMajorTrophy: true,
            uciPoints: 520,
          ),
        ],
      ),
      TeamSeasonKitRecord(
        seasonYear: 2028,
        teamName: 'Team Aether-Nordic',
        teamTla: 'TAN',
        divisionLabel: 'UCI WorldTour',
        titleSponsorName: 'Aether Corp',
        secondarySponsorName: 'Nordic Bank',
        bikeManufacturerName: 'Aether Cycles',
        jerseyPattern: JerseyPattern.chevron,
        primaryColor: const Color(0xFF8E4A49),
        secondaryColor: const Color(0xFF181B22),
        accentColor: const Color(0xFFD4AF37),
        sponsorTextColor: Colors.white,
        frameColorOverride: const Color(0xFF8E4A49),
        barTapeColorOverride: const Color(0xFFD4AF37),
        isTanWall: true,
        totalWinsCount: 28,
        uciRankPosition: 5,
        uciPointsTotal: 11240,
        seasonSummaryNote:
            'Wejście do elity WorldTour w królewskim burgundzie i szewronie V — pierwszy Monument i podium Grand Touru.',
        archivedAt: DateTime(2028, 10, 22),
        bike: const CompleteBike(
          id: 'bike_2028_tan',
          name: 'Aether Kronos Works SL 2028',
          cockpitWidthMm: 370,
          hoodInwardTiltDegrees: 11.0,
          slammedStem: true,
          frame: FrameModel(
            id: 'frame_2028',
            brandId: 'aether',
            name: 'Aether Kronos Works',
            category: FrameCategory.aero,
            weightGrams: 720,
            aeroCdaModifier: -0.017,
            stiffnessToWeightIndex: 2.18,
            comfortCompliance: 0.71,
            priceEur: 8900,
            mesh3dAssetPath: 'assets/3d/bikes/frame_aero.glb',
            primaryColorHex: '#8E4A49',
          ),
          wheelset: WheelsetModel(
            id: 'wheel_2028',
            brandId: 'aether_wheels',
            name: 'Kronos Disc-55 Ceramic',
            rimDepthMm: 55,
            weightGrams: 1290,
            aeroCdaModifier: -0.011,
            crosswindStabilityPenalty: 0.36,
            momentOfInertia: 0.078,
            hubEngagementDragWatts: 1.0,
            priceEur: 4200,
          ),
          groupset: GroupsetModel(
            id: 'grp_2028',
            brandId: 'sram',
            name: 'RED AXS E1 12s',
            weightGrams: 2065,
            isElectronic: true,
            speedCount: 12,
            mechanicalEfficiency: 0.985,
            priceEur: 4400,
          ),
          tire: TireModel(
            id: 'tire_2028',
            brandId: 'vittoria',
            name: 'Corsa Pro Speed Tan-Wall 28',
            widthMm: 28,
            weightGrams: 245,
            rollingResistanceCrr: 0.0031,
            punctureResistanceIndex: 3.0,
            wetGripIndex: 4.4,
            isTubeless: true,
            priceEur: 105,
          ),
        ),
        successes: const [
          SeasonKitSuccessEntry(
            id: 'suc_2028_1',
            raceName: 'Paris-Roubaix',
            category: KitSuccessCategory.monument,
            riderName: 'L. Van Der Berg',
            achievementDetail: '1. miejsce — samotny atak w Carrefour de l\'Arbre',
            isMajorTrophy: true,
            uciPoints: 800,
          ),
          SeasonKitSuccessEntry(
            id: 'suc_2028_2',
            raceName: 'Giro d\'Italia',
            category: KitSuccessCategory.grandTour,
            riderName: 'M. Kowalski',
            achievementDetail: '3. miejsce GC + Maglia Ciclamino (2 etapy)',
            isMajorTrophy: true,
            uciPoints: 950,
          ),
          SeasonKitSuccessEntry(
            id: 'suc_2028_3',
            raceName: 'Critérium du Dauphiné',
            category: KitSuccessCategory.worldTourStageRace,
            riderName: 'M. Kowalski',
            achievementDetail: 'Zwycięstwo w klasyfikacji generalnej',
            isMajorTrophy: false,
            uciPoints: 500,
          ),
        ],
      ),
      TeamSeasonKitRecord(
        seasonYear: 2029,
        teamName: 'Aether Imperial Racing',
        teamTla: 'AIR',
        divisionLabel: 'UCI WorldTour #1',
        titleSponsorName: 'Aether Imperial',
        secondarySponsorName: 'Solaris Cloud',
        bikeManufacturerName: 'Aether Cycles',
        jerseyPattern: JerseyPattern.gradient,
        primaryColor: const Color(0xFF181B22),
        secondaryColor: const Color(0xFFD4AF37),
        accentColor: const Color(0xFF8E4A49),
        sponsorTextColor: Colors.white,
        frameColorOverride: const Color(0xFFD4AF37),
        barTapeColorOverride: const Color(0xFF181B22),
        isTanWall: true,
        totalWinsCount: 41,
        uciRankPosition: 1,
        uciPointsTotal: 18450,
        seasonSummaryNote:
            'Złota era zespołu: limitowane malowanie Gold-Carbon i historyczny dublet Tour de France + Il Lombardia.',
        archivedAt: DateTime(2029, 10, 25),
        bike: const CompleteBike(
          id: 'bike_2029_air',
          name: 'Aether Imperial Gold Lab 2029',
          cockpitWidthMm: 360,
          hoodInwardTiltDegrees: 13.0,
          slammedStem: true,
          frame: FrameModel(
            id: 'frame_2029',
            brandId: 'aether',
            name: 'Aether Imperial 0G',
            category: FrameCategory.lightweightClimbing,
            weightGrams: 640,
            aeroCdaModifier: -0.015,
            stiffnessToWeightIndex: 2.38,
            comfortCompliance: 0.78,
            priceEur: 11500,
            mesh3dAssetPath: 'assets/3d/bikes/frame_climbing.glb',
            primaryColorHex: '#D4AF37',
          ),
          wheelset: WheelsetModel(
            id: 'wheel_2029',
            brandId: 'aether_wheels',
            name: 'Imperial Hyper 45/55',
            rimDepthMm: 50,
            weightGrams: 1195,
            aeroCdaModifier: -0.012,
            crosswindStabilityPenalty: 0.28,
            momentOfInertia: 0.072,
            hubEngagementDragWatts: 0.8,
            priceEur: 4900,
          ),
          groupset: GroupsetModel(
            id: 'grp_2029',
            brandId: 'shimano',
            name: 'Dura-Ace Lab Works 12s',
            weightGrams: 1995,
            isElectronic: true,
            speedCount: 12,
            mechanicalEfficiency: 0.986,
            priceEur: 5200,
          ),
          tire: TireModel(
            id: 'tire_2029',
            brandId: 'vittoria',
            name: 'Corsa Pro Gold Edition Tan-Wall 28',
            widthMm: 28,
            weightGrams: 235,
            rollingResistanceCrr: 0.0029,
            punctureResistanceIndex: 3.3,
            wetGripIndex: 4.5,
            isTubeless: true,
            priceEur: 120,
          ),
        ),
        successes: const [
          SeasonKitSuccessEntry(
            id: 'suc_2029_1',
            raceName: 'Tour de France',
            category: KitSuccessCategory.grandTour,
            riderName: 'M. Kowalski',
            achievementDetail: '1. miejsce GC (Maillot Jaune) + 4 wygrane etapy',
            isMajorTrophy: true,
            uciPoints: 1800,
          ),
          SeasonKitSuccessEntry(
            id: 'suc_2029_2',
            raceName: 'Il Lombardia',
            category: KitSuccessCategory.monument,
            riderName: 'M. Kowalski',
            achievementDetail: '1. miejsce — rekordowy podjazd pod Passo di Ganda',
            isMajorTrophy: true,
            uciPoints: 800,
          ),
          SeasonKitSuccessEntry(
            id: 'suc_2029_3',
            raceName: 'Ranking Drużynowy UCI',
            category: KitSuccessCategory.uciTeamRanking,
            riderName: 'Cały Zespół',
            achievementDetail: '1. miejsce na świecie (18 450 pkt UCI)',
            isMajorTrophy: true,
            uciPoints: 18450,
          ),
        ],
      ),
    ];
  }
}

/// Galeria historycznych koszulek drużyny, rowerów zespołu oraz sukcesów z każdego ukończonego sezonu.
class TeamKitEvolutionGalleryWidget extends StatefulWidget {
  /// Lista zarchiwizowanych sezonów (wzory koszulek, rowery i sukcesy).
  final List<TeamSeasonKitRecord> seasonRecords;

  /// Domyślnie wybrany rok sezonu (null = najnowszy w przefiltrowanej liście).
  final int? initialSelectedSeasonYear;

  /// Opcjonalna akcja archiwizacji bieżącego ukończonego sezonu.
  final VoidCallback? onArchiveCurrentSeason;

  /// Czy bieżący sezon został już zarchiwizowany (wyłącza przycisk archiwizacji).
  final bool isCurrentSeasonArchived;

  /// Callback wywoływany po wybraniu konkretnego sezonu w galerii.
  final ValueChanged<TeamSeasonKitRecord>? onSeasonSelected;

  const TeamKitEvolutionGalleryWidget({
    super.key,
    required this.seasonRecords,
    this.initialSelectedSeasonYear,
    this.onArchiveCurrentSeason,
    this.isCurrentSeasonArchived = false,
    this.onSeasonSelected,
  });

  @override
  State<TeamKitEvolutionGalleryWidget> createState() =>
      _TeamKitEvolutionGalleryWidgetState();
}

class _TeamKitEvolutionGalleryWidgetState
    extends State<TeamKitEvolutionGalleryWidget> {
  KitGalleryFilterMode _filterMode = KitGalleryFilterMode.all;
  KitGallerySortOrder _sortOrder = KitGallerySortOrder.newestFirst;
  bool _showJerseyBackView = false;
  bool _isCompareMode = false;
  int? _selectedSeasonYear;
  int? _compareSeasonYear;
  int? _hoveredSeasonYear;

  @override
  void initState() {
    super.initState();
    _selectedSeasonYear = widget.initialSelectedSeasonYear;
    _syncSelectionWithRecords();
  }

  @override
  void didUpdateWidget(covariant TeamKitEvolutionGalleryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seasonRecords != widget.seasonRecords ||
        oldWidget.initialSelectedSeasonYear !=
            widget.initialSelectedSeasonYear) {
      if (widget.initialSelectedSeasonYear != null &&
          oldWidget.initialSelectedSeasonYear !=
              widget.initialSelectedSeasonYear) {
        _selectedSeasonYear = widget.initialSelectedSeasonYear;
      }
      _syncSelectionWithRecords();
    }
  }

  List<TeamSeasonKitRecord> get _visibleRecords {
    final filtered = widget.seasonRecords.where((record) {
      switch (_filterMode) {
        case KitGalleryFilterMode.all:
          return true;
        case KitGalleryFilterMode.majorTrophies:
          return record.majorSuccessesCount > 0;
        case KitGalleryFilterMode.grandTours:
          return record.hasGrandTourSuccess;
        case KitGalleryFilterMode.monuments:
          return record.hasMonumentSuccess;
      }
    }).toList();

    filtered.sort((a, b) {
      switch (_sortOrder) {
        case KitGallerySortOrder.newestFirst:
          return b.seasonYear.compareTo(a.seasonYear);
        case KitGallerySortOrder.oldestFirst:
          return a.seasonYear.compareTo(b.seasonYear);
        case KitGallerySortOrder.mostWins:
          final winDiff = b.totalWinsCount.compareTo(a.totalWinsCount);
          return winDiff != 0 ? winDiff : b.seasonYear.compareTo(a.seasonYear);
      }
    });

    return filtered;
  }

  void _syncSelectionWithRecords() {
    final visible = _visibleRecords;
    if (visible.isEmpty) {
      _selectedSeasonYear = null;
      _compareSeasonYear = null;
      return;
    }

    if (_selectedSeasonYear == null ||
        !visible.any((r) => r.seasonYear == _selectedSeasonYear)) {
      _selectedSeasonYear = visible.first.seasonYear;
    }

    if (_compareSeasonYear == null ||
        _compareSeasonYear == _selectedSeasonYear ||
        !visible.any((r) => r.seasonYear == _compareSeasonYear)) {
      final fallback = visible.firstWhere(
        (r) => r.seasonYear != _selectedSeasonYear,
        orElse: () => visible.first,
      );
      _compareSeasonYear = fallback.seasonYear;
    }
  }

  TeamSeasonKitRecord? _findRecordByYear(
    List<TeamSeasonKitRecord> records,
    int? year,
  ) {
    if (records.isEmpty || year == null) return null;
    for (final r in records) {
      if (r.seasonYear == year) return r;
    }
    return records.first;
  }

  void _selectSeason(TeamSeasonKitRecord record) {
    setState(() {
      _selectedSeasonYear = record.seasonYear;
      if (_isCompareMode && _compareSeasonYear == record.seasonYear) {
        final visible = _visibleRecords;
        final other = visible.firstWhere(
          (r) => r.seasonYear != record.seasonYear,
          orElse: () => record,
        );
        _compareSeasonYear = other.seasonYear;
      }
    });
    widget.onSeasonSelected?.call(record);
  }

  @override
  Widget build(BuildContext context) {
    final visibleRecords = _visibleRecords;
    final activeRecord = _findRecordByYear(visibleRecords, _selectedSeasonYear);
    final compareRecord = _findRecordByYear(visibleRecords, _compareSeasonYear);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth = constraints.maxWidth;
          final bool isCompact = maxWidth < 640;
          final bool isDesktop = maxWidth >= 960;
          final double padding = isCompact ? 14 : 20;

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(isCompact: isCompact),
                const SizedBox(height: 16),
                _buildControlsToolbar(
                  isCompact: isCompact,
                  canCompare: visibleRecords.length >= 2,
                ),
                const SizedBox(height: 16),
                if (widget.seasonRecords.isEmpty)
                  _buildEmptyArchiveState(isCompact: isCompact)
                else if (visibleRecords.isEmpty)
                  _buildEmptyFilterState()
                else ...[
                  _buildSeasonTimelineStrip(
                    records: visibleRecords,
                    activeYear: activeRecord?.seasonYear,
                    isCompact: isCompact,
                  ),
                  const SizedBox(height: 18),
                  if (_isCompareMode &&
                      activeRecord != null &&
                      compareRecord != null &&
                      visibleRecords.length >= 2)
                    _buildComparisonView(
                      primary: activeRecord,
                      secondary: compareRecord,
                      availableRecords: visibleRecords,
                      isCompact: isCompact,
                    )
                  else if (activeRecord != null)
                    _buildSeasonShowcase(
                      record: activeRecord,
                      isCompact: isCompact,
                      isDesktop: isDesktop,
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader({required bool isCompact}) {
    final totalSeasons = widget.seasonRecords.length;
    final totalWins = widget.seasonRecords.fold<int>(
      0,
      (sum, item) => sum + item.totalWinsCount,
    );
    final totalMajorTrophies = widget.seasonRecords.fold<int>(
      0,
      (sum, item) => sum + item.majorSuccessesCount,
    );

    final titleBlock = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isCompact ? 40 : 46,
          height: isCompact ? 40 : 46,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.goldAccent.withValues(alpha: 0.55),
            ),
          ),
          child: const Icon(
            Icons.checkroom_rounded,
            color: AppColors.goldAccent,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Galeria Ewolucji Barw i Rowerów',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 17 : 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Archiwum koszulek, maszyn wyścigowych i sukcesów z każdego ukończonego sezonu.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  letterSpacing: -0.2,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final statsAndAction = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _MetricPill(
          icon: Icons.calendar_month_rounded,
          label: '$totalSeasons sez.',
          accentColor: AppColors.accentBlue,
        ),
        _MetricPill(
          icon: Icons.flag_rounded,
          label: '$totalWins zw.',
          accentColor: AppColors.statusSuccess,
        ),
        _MetricPill(
          icon: Icons.emoji_events_rounded,
          label: '$totalMajorTrophies trofeów',
          accentColor: AppColors.goldAccent,
        ),
        if (widget.onArchiveCurrentSeason != null)
          _GalleryActionButton(
            icon: widget.isCurrentSeasonArchived
                ? Icons.inventory_2_rounded
                : Icons.archive_rounded,
            label: widget.isCurrentSeasonArchived
                ? 'Sezon zapisany'
                : 'Zapisz obecny sezon',
            isPrimary: true,
            isDisabled: widget.isCurrentSeasonArchived,
            onPressed: widget.isCurrentSeasonArchived
                ? null
                : widget.onArchiveCurrentSeason,
          ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: 12),
          statsAndAction,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 16),
        statsAndAction,
      ],
    );
  }

  Widget _buildControlsToolbar({
    required bool isCompact,
    required bool canCompare,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: KitGalleryFilterMode.values.map((mode) {
              final selected = _filterMode == mode;
              return _InteractiveFilterChip(
                label: mode.label,
                isSelected: selected,
                onTap: () {
                  setState(() {
                    _filterMode = mode;
                    _syncSelectionWithRecords();
                  });
                },
              );
            }).toList(),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _GalleryActionButton(
                icon: _showJerseyBackView
                    ? Icons.flip_to_front_rounded
                    : Icons.flip_to_back_rounded,
                label: _showJerseyBackView ? 'Widok: Tył' : 'Widok: Przód',
                isSelected: _showJerseyBackView,
                onPressed: () {
                  setState(() {
                    _showJerseyBackView = !_showJerseyBackView;
                  });
                },
              ),
              _GalleryActionButton(
                icon: Icons.compare_arrows_rounded,
                label: _isCompareMode ? 'Zakończ porównanie' : 'Porównaj sezony',
                isSelected: _isCompareMode,
                isDisabled: !canCompare,
                onPressed: canCompare
                    ? () {
                        setState(() {
                          _isCompareMode = !_isCompareMode;
                          _syncSelectionWithRecords();
                        });
                      }
                    : null,
              ),
              _SortDropdownChip(
                value: _sortOrder,
                onChanged: (next) {
                  setState(() {
                    _sortOrder = next;
                    _syncSelectionWithRecords();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonTimelineStrip({
    required List<TeamSeasonKitRecord> records,
    required int? activeYear,
    required bool isCompact,
  }) {
    return SizedBox(
      height: isCompact ? 134 : 144,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: records.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final record = records[index];
          final bool isSelected = record.seasonYear == activeYear;
          final bool isHovered = _hoveredSeasonYear == record.seasonYear;

          return _SeasonTimelineCard(
            record: record,
            isSelected: isSelected,
            isHovered: isHovered,
            isCompact: isCompact,
            onHoverChanged: (hovering) {
              setState(() {
                _hoveredSeasonYear = hovering ? record.seasonYear : null;
              });
            },
            onTap: () => _selectSeason(record),
          );
        },
      ),
    );
  }

  Widget _buildSeasonShowcase({
    required TeamSeasonKitRecord record,
    required bool isCompact,
    required bool isDesktop,
  }) {
    final visualCard = _buildVisualKitAndBikeCard(
      record: record,
      isCompact: isCompact,
    );
    final palmaresCard = _buildPalmaresAndSuccessesCard(
      record: record,
      isCompact: isCompact,
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: visualCard),
          const SizedBox(width: 16),
          Expanded(flex: 5, child: palmaresCard),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        visualCard,
        const SizedBox(height: 16),
        palmaresCard,
      ],
    );
  }

  Widget _buildVisualKitAndBikeCard({
    required TeamSeasonKitRecord record,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Górna belka sezonu
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.goldAccent.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Text(
                      'SEZON ${record.seasonYear}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.goldAccent,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Text(
                    record.teamName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  record.divisionLabel,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Główna ekspozycja: Koszulka + Rower
          LayoutBuilder(
            builder: (context, box) {
              final bool stackPreview = box.maxWidth < 500;
              final jerseyWidget = _buildJerseyStageBox(
                record: record,
                height: stackPreview ? 220 : 240,
              );
              final bikeWidget = _buildBikeStageBox(
                record: record,
                height: stackPreview ? 225 : 240,
              );

              if (stackPreview) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    jerseyWidget,
                    const SizedBox(height: 12),
                    bikeWidget,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: jerseyWidget),
                  const SizedBox(width: 12),
                  Expanded(flex: 6, child: bikeWidget),
                ],
              );
            },
          ),

          const SizedBox(height: 14),

          // Pasek palety barw + specyfikacja wzoru
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _ColorSwatchChip(
                      label: 'Główny',
                      color: record.primaryColor,
                    ),
                    _ColorSwatchChip(
                      label: 'Drugi',
                      color: record.secondaryColor,
                    ),
                    _ColorSwatchChip(
                      label: 'Akcent',
                      color: record.accentColor,
                    ),
                  ],
                ),
                Text(
                  'Wzór: ${record.jerseyPattern.label}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          if (record.seasonSummaryNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              record.seasonSummaryNote,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                height: 1.45,
                letterSpacing: -0.1,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJerseyStageBox({
    required TeamSeasonKitRecord record,
    required double height,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surfaceLight,
            AppColors.background,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showJerseyBackView ? 'KOSZULKA (TYŁ)' : 'KOSZULKA (PRZÓD)',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                record.teamTla,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.goldAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                child: AspectRatio(
                  key: ValueKey('${record.seasonYear}_$_showJerseyBackView'),
                  aspectRatio: 1.0,
                  child: CustomPaint(
                    painter: TeamJerseyPainter(
                      primaryColor: record.primaryColor,
                      secondaryColor: record.secondaryColor,
                      accentColor: record.accentColor,
                      pattern: record.jerseyPattern,
                      sponsorName: record.titleSponsorName,
                      secondarySponsorName: record.secondarySponsorName,
                      teamName: record.teamName,
                      teamTla: record.teamTla,
                      sponsorTextColor: record.sponsorTextColor,
                      isBackView: _showJerseyBackView,
                      startNumber: _showJerseyBackView ? 1 : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBikeStageBox({
    required TeamSeasonKitRecord record,
    required double height,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  record.bike.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                record.bikeManufacturerName,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: BikePreviewWidget(
              bike: record.bike,
              showBackground: false,
              showSpecsPill: false,
              showFloorReflection: true,
              isTanWallOverride: record.isTanWall,
              frameColorOverride: record.frameColorOverride,
              barTapeColorOverride: record.barTapeColorOverride,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                '${record.bike.totalWeightKg.toStringAsFixed(2)} kg',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                'Stożek ${record.bike.wheelset.rimDepthMm} mm',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                record.bike.groupset.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPalmaresAndSuccessesCard({
    required TeamSeasonKitRecord record,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Sukcesy w tych barwach',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${record.successes.length} osiągnięć',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Podsumowanie statystyczne sezonu
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SeasonStatBox(
                label: 'Zwycięstwa',
                value: '${record.totalWinsCount}',
                accentColor: AppColors.statusSuccess,
              ),
              _SeasonStatBox(
                label: 'Punkty UCI',
                value: '${record.uciPointsTotal}',
                accentColor: AppColors.accentBlue,
              ),
              _SeasonStatBox(
                label: 'Ranking UCI',
                value: record.uciRankPosition != null
                    ? '#${record.uciRankPosition}'
                    : '—',
                accentColor: AppColors.goldAccent,
              ),
              _SeasonStatBox(
                label: 'Sponsor',
                value: record.titleSponsorName,
                accentColor: AppColors.primaryAccent,
              ),
            ],
          ),

          const SizedBox(height: 14),
          if (record.successes.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Text(
                'Brak odnotowanych trofeów w tym sezonie — barwy zapisały się w historii jako sezon budowania składu.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Column(
              children: record.successes.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SuccessEntryTile(entry: entry),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildComparisonView({
    required TeamSeasonKitRecord primary,
    required TeamSeasonKitRecord secondary,
    required List<TeamSeasonKitRecord> availableRecords,
    required bool isCompact,
  }) {
    final leftPane = _ComparisonSeasonColumn(
      label: 'SEZON A',
      record: primary,
      availableRecords: availableRecords,
      showBackView: _showJerseyBackView,
      onChanged: (nextYear) {
        final found = _findRecordByYear(availableRecords, nextYear);
        if (found != null) {
          setState(() => _selectedSeasonYear = found.seasonYear);
        }
      },
    );

    final rightPane = _ComparisonSeasonColumn(
      label: 'SEZON B',
      record: secondary,
      availableRecords: availableRecords,
      showBackView: _showJerseyBackView,
      onChanged: (nextYear) {
        final found = _findRecordByYear(availableRecords, nextYear);
        if (found != null) {
          setState(() => _compareSeasonYear = found.seasonYear);
        }
      },
    );

    final int winDelta = secondary.totalWinsCount - primary.totalWinsCount;
    final int pointsDelta = secondary.uciPointsTotal - primary.uciPointsTotal;
    final double weightDelta =
        secondary.bike.totalWeightKg - primary.bike.totalWeightKg;

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Porównanie Ewolucji Między Sezonami',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _DeltaPill(
                    label: 'Zwycięstwa',
                    value: '${winDelta >= 0 ? '+' : ''}$winDelta',
                    isPositive: winDelta >= 0,
                  ),
                  _DeltaPill(
                    label: 'Pkt UCI',
                    value: '${pointsDelta >= 0 ? '+' : ''}$pointsDelta',
                    isPositive: pointsDelta >= 0,
                  ),
                  _DeltaPill(
                    label: 'Masa roweru',
                    value:
                        '${weightDelta >= 0 ? '+' : ''}${weightDelta.toStringAsFixed(2)} kg',
                    isPositive: weightDelta <= 0,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isCompact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                leftPane,
                const SizedBox(height: 14),
                rightPane,
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: leftPane),
                const SizedBox(width: 14),
                Expanded(child: rightPane),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyArchiveState({required bool isCompact}) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 20 : 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.checkroom_outlined,
            size: 42,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Brak zarchiwizowanych sezonów',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Po ukończeniu pierwszego sezonu w tym miejscu zapisze się wzór koszulki, rower drużynowy oraz lista zdobytych trofeów.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          if (widget.onArchiveCurrentSeason != null) ...[
            const SizedBox(height: 16),
            _GalleryActionButton(
              icon: Icons.archive_rounded,
              label: 'Zarchiwizuj bieżący sezon',
              isPrimary: true,
              isDisabled: widget.isCurrentSeasonArchived,
              onPressed: widget.isCurrentSeasonArchived
                  ? null
                  : widget.onArchiveCurrentSeason,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.filter_list_off_rounded,
            size: 36,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 10),
          const Text(
            'Brak sezonów spełniających wybrane kryteria filtra.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _GalleryActionButton(
            icon: Icons.refresh_rounded,
            label: 'Pokaż wszystkie sezony',
            isPrimary: true,
            onPressed: () {
              setState(() {
                _filterMode = KitGalleryFilterMode.all;
                _syncSelectionWithRecords();
              });
            },
          ),
        ],
      ),
    );
  }
}

class _SeasonTimelineCard extends StatelessWidget {
  final TeamSeasonKitRecord record;
  final bool isSelected;
  final bool isHovered;
  final bool isCompact;
  final ValueChanged<bool> onHoverChanged;
  final VoidCallback onTap;

  const _SeasonTimelineCard({
    required this.record,
    required this.isSelected,
    required this.isHovered,
    required this.isCompact,
    required this.onHoverChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isSelected
        ? AppColors.goldAccent
        : isHovered
            ? AppColors.primaryAccent
            : AppColors.cardBorder;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          focusColor: AppColors.goldAccent.withValues(alpha: 0.16),
          hoverColor: AppColors.surfaceLight.withValues(alpha: 0.5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            width: isCompact ? 164 : 186,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.surfaceLight
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 1.6 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.goldAccent.withValues(alpha: 0.16),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 58,
                  height: 68,
                  child: CustomPaint(
                    painter: TeamJerseyPainter(
                      primaryColor: record.primaryColor,
                      secondaryColor: record.secondaryColor,
                      accentColor: record.accentColor,
                      pattern: record.jerseyPattern,
                      sponsorName: record.titleSponsorName,
                      teamTla: record.teamTla,
                      sponsorTextColor: record.sponsorTextColor,
                      showShadow: false,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${record.seasonYear}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? AppColors.goldAccent
                              : AppColors.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        record.titleSponsorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.statusSuccess.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${record.totalWinsCount} zw.',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.statusSuccess,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
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

class _ComparisonSeasonColumn extends StatelessWidget {
  final String label;
  final TeamSeasonKitRecord record;
  final List<TeamSeasonKitRecord> availableRecords;
  final bool showBackView;
  final ValueChanged<int> onChanged;

  const _ComparisonSeasonColumn({
    required this.label,
    required this.record,
    required this.availableRecords,
    required this.showBackView,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.goldAccent,
                ),
              ),
              DropdownButton<int>(
                value: record.seasonYear,
                dropdownColor: AppColors.surface,
                underline: const SizedBox.shrink(),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                items: availableRecords.map((item) {
                  return DropdownMenuItem<int>(
                    value: item.seasonYear,
                    child: Text('${item.seasonYear} • ${item.teamTla}'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) onChanged(val);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 130,
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: CustomPaint(
                        painter: TeamJerseyPainter(
                          primaryColor: record.primaryColor,
                          secondaryColor: record.secondaryColor,
                          accentColor: record.accentColor,
                          pattern: record.jerseyPattern,
                          sponsorName: record.titleSponsorName,
                          teamTla: record.teamTla,
                          sponsorTextColor: record.sponsorTextColor,
                          isBackView: showBackView,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 6,
                  child: BikePreviewWidget(
                    bike: record.bike,
                    showBackground: false,
                    showSpecsPill: false,
                    showFloorReflection: true,
                    isTanWallOverride: record.isTanWall,
                    frameColorOverride: record.frameColorOverride,
                    barTapeColorOverride: record.barTapeColorOverride,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${record.teamName} • ${record.bike.name}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Masa: ${record.bike.totalWeightKg.toStringAsFixed(2)} kg • Stożek: ${record.bike.wheelset.rimDepthMm} mm • Zwycięstwa: ${record.totalWinsCount}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessEntryTile extends StatefulWidget {
  final SeasonKitSuccessEntry entry;

  const _SuccessEntryTile({required this.entry});

  @override
  State<_SuccessEntryTile> createState() => _SuccessEntryTileState();
}

class _SuccessEntryTileState extends State<_SuccessEntryTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final Color badgeColor = entry.isMajorTrophy
        ? AppColors.goldAccent
        : entry.category.accentColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.surfaceLight : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: entry.isMajorTrophy
                ? AppColors.goldAccent.withValues(alpha: _hovered ? 0.8 : 0.45)
                : (_hovered ? AppColors.primaryAccent : AppColors.cardBorder),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                entry.category.icon,
                color: badgeColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.raceName,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (entry.uciPoints > 0)
                        Text(
                          '+${entry.uciPoints} pkt',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentBlue,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entry.achievementDetail,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.category.label} • ${entry.riderName}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: badgeColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractiveFilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _InteractiveFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_InteractiveFilterChip> createState() => _InteractiveFilterChipState();
}

class _InteractiveFilterChipState extends State<_InteractiveFilterChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        focusColor: AppColors.goldAccent.withValues(alpha: 0.2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primaryAccent.withValues(alpha: 0.24)
                : (_hovered ? AppColors.surfaceLight : AppColors.background),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.goldAccent
                  : (_hovered ? AppColors.primaryAccent : AppColors.cardBorder),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w600,
              color: widget.isSelected
                  ? AppColors.goldAccent
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onPressed;

  const _GalleryActionButton({
    required this.icon,
    required this.label,
    this.isPrimary = false,
    this.isSelected = false,
    this.isDisabled = false,
    required this.onPressed,
  });

  @override
  State<_GalleryActionButton> createState() => _GalleryActionButtonState();
}

class _GalleryActionButtonState extends State<_GalleryActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.isDisabled || widget.onPressed == null;
    final Color bg = disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.isPrimary
            ? AppColors.primaryAccent
            : widget.isSelected
                ? AppColors.goldAccent.withValues(alpha: 0.16)
                : (_hovered ? AppColors.surfaceLight : AppColors.background);

    final Color fg = disabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : widget.isPrimary
            ? Colors.white
            : (widget.isSelected
                ? AppColors.goldAccent
                : AppColors.textPrimary);

    final Color border = disabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : widget.isSelected
            ? AppColors.goldAccent
            : (_hovered ? AppColors.primaryAccent : AppColors.cardBorder);

    return MouseRegion(
      cursor:
          disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: disabled ? null : widget.onPressed,
        borderRadius: BorderRadius.circular(10),
        focusColor: AppColors.goldAccent.withValues(alpha: 0.2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 15, color: fg),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortDropdownChip extends StatelessWidget {
  final KitGallerySortOrder value;
  final ValueChanged<KitGallerySortOrder> onChanged;

  const _SortDropdownChip({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<KitGallerySortOrder>(
          value: value,
          isDense: true,
          dropdownColor: AppColors.surface,
          icon: const Icon(
            Icons.sort_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          items: KitGallerySortOrder.values.map((order) {
            return DropdownMenuItem<KitGallerySortOrder>(
              value: order,
              child: Text(order.label),
            );
          }).toList(),
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;

  const _MetricPill({
    required this.icon,
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accentColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorSwatchChip extends StatelessWidget {
  final String label;
  final Color color;

  const _ColorSwatchChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final hex = color
        .toARGB32()
        .toRadixString(16)
        .padLeft(8, '0')
        .substring(2)
        .toUpperCase();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label #$hex',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _SeasonStatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _SeasonStatBox({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
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
              color: accentColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeltaPill extends StatelessWidget {
  final String label;
  final String value;
  final bool isPositive;

  const _DeltaPill({
    required this.label,
    required this.value,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isPositive ? AppColors.statusSuccess : AppColors.crimsonAlert;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
