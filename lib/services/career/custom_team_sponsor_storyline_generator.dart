// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';

/// Archetyp wieloletniego wątku fabularnego dla drużyny gracza i sponsora.
enum StorylineArchetype {
  /// Rywalizacja dwóch konkurencyjnych miliarderów w peletonie.
  billionaireRivalry,

  /// Presja narodowa na wygranie domowego wyścigu dla sponsora.
  nationalHomeRacePressure,

  /// Powrót dawnego mistrza po ciężkiej kontuzji i odbudowa formy.
  fallenChampionComeback,

  /// Budowanie wieloletniej dynastii na wzór największych ekip w historii.
  historicDynastyBuilder;

  String toJson() => name;

  static StorylineArchetype fromJson(String value) {
    return StorylineArchetype.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => StorylineArchetype.billionaireRivalry,
    );
  }

  String get label {
    switch (this) {
      case StorylineArchetype.billionaireRivalry:
        return 'Wojna Miliarderów';
      case StorylineArchetype.nationalHomeRacePressure:
        return 'Presja Domowego Wyścigu';
      case StorylineArchetype.fallenChampionComeback:
        return 'Powrót Mistrza';
      case StorylineArchetype.historicDynastyBuilder:
        return 'Budowa Dynastii';
    }
  }

  String get shortTag {
    switch (this) {
      case StorylineArchetype.billionaireRivalry:
        return 'Miliarderzy';
      case StorylineArchetype.nationalHomeRacePressure:
        return 'Domowy Wyścig';
      case StorylineArchetype.fallenChampionComeback:
        return 'Powrót';
      case StorylineArchetype.historicDynastyBuilder:
        return 'Dynastia';
    }
  }

  IconData get icon {
    switch (this) {
      case StorylineArchetype.billionaireRivalry:
        return Icons.diamond_outlined;
      case StorylineArchetype.nationalHomeRacePressure:
        return Icons.flag_rounded;
      case StorylineArchetype.fallenChampionComeback:
        return Icons.healing_rounded;
      case StorylineArchetype.historicDynastyBuilder:
        return Icons.emoji_events_rounded;
    }
  }

  Color get accentColor {
    switch (this) {
      case StorylineArchetype.billionaireRivalry:
        return AppColors.accentBlue;
      case StorylineArchetype.nationalHomeRacePressure:
        return AppColors.primaryAccent;
      case StorylineArchetype.fallenChampionComeback:
        return AppColors.statusSuccess;
      case StorylineArchetype.historicDynastyBuilder:
        return AppColors.goldAccent;
    }
  }
}

/// Aktualny status wieloletniego wątku fabularnego.
enum StorylineStatus {
  active,
  paused,
  completed,
  failed;

  String toJson() => name;

  static StorylineStatus fromJson(String value) {
    return StorylineStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => StorylineStatus.active,
    );
  }

  String get label {
    switch (this) {
      case StorylineStatus.active:
        return 'Aktywny';
      case StorylineStatus.paused:
        return 'Wstrzymany';
      case StorylineStatus.completed:
        return 'Ukończony';
      case StorylineStatus.failed:
        return 'Niepowodzenie';
    }
  }

  Color get badgeColor {
    switch (this) {
      case StorylineStatus.active:
        return AppColors.accentBlue;
      case StorylineStatus.paused:
        return AppColors.amberWarning;
      case StorylineStatus.completed:
        return AppColors.statusSuccess;
      case StorylineStatus.failed:
        return AppColors.crimsonAlert;
    }
  }
}

/// Ton narracyjny rozdziału i relacji medialnych.
enum StorylineTone {
  dramatic,
  ambitious,
  redemption,
  legacy;

  String toJson() => name;

  static StorylineTone fromJson(String value) {
    return StorylineTone.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => StorylineTone.dramatic,
    );
  }
}

/// Konsekwencje podjętej decyzji strategicznej w ramach rozdziału fabularnego.
class StorylineChoiceEffect {
  final int budgetDeltaEur;
  final double sponsorSatisfactionDelta;
  final double teamMoraleDelta;
  final int prestigeDelta;
  final int dynastyPointsDelta;
  final double heatDelta;
  final String outcomeSummary;

  const StorylineChoiceEffect({
    this.budgetDeltaEur = 0,
    this.sponsorSatisfactionDelta = 0.0,
    this.teamMoraleDelta = 0.0,
    this.prestigeDelta = 0,
    this.dynastyPointsDelta = 0,
    this.heatDelta = 0.0,
    required this.outcomeSummary,
  });

  Map<String, dynamic> toJson() {
    return {
      'budgetDeltaEur': budgetDeltaEur,
      'sponsorSatisfactionDelta': sponsorSatisfactionDelta,
      'teamMoraleDelta': teamMoraleDelta,
      'prestigeDelta': prestigeDelta,
      'dynastyPointsDelta': dynastyPointsDelta,
      'heatDelta': heatDelta,
      'outcomeSummary': outcomeSummary,
    };
  }

  factory StorylineChoiceEffect.fromJson(Map<String, dynamic> json) {
    return StorylineChoiceEffect(
      budgetDeltaEur: (json['budgetDeltaEur'] as num?)?.toInt() ?? 0,
      sponsorSatisfactionDelta:
          (json['sponsorSatisfactionDelta'] as num?)?.toDouble() ?? 0.0,
      teamMoraleDelta: (json['teamMoraleDelta'] as num?)?.toDouble() ?? 0.0,
      prestigeDelta: (json['prestigeDelta'] as num?)?.toInt() ?? 0,
      dynastyPointsDelta: (json['dynastyPointsDelta'] as num?)?.toInt() ?? 0,
      heatDelta: (json['heatDelta'] as num?)?.toDouble() ?? 0.0,
      outcomeSummary: (json['outcomeSummary'] as String?) ?? '',
    );
  }
}

/// Opcja decyzji strategicznej dostępna dla gracza w bieżącym rozdziale.
class StorylineDecisionOption {
  final String id;
  final String title;
  final String description;
  final String strategicTag;
  final int requiresMinBudgetEur;
  final StorylineChoiceEffect effect;

  const StorylineDecisionOption({
    required this.id,
    required this.title,
    required this.description,
    required this.strategicTag,
    this.requiresMinBudgetEur = 0,
    required this.effect,
  });

  bool isAffordable(int currentBudgetEur) =>
      currentBudgetEur >= requiresMinBudgetEur;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'strategicTag': strategicTag,
      'requiresMinBudgetEur': requiresMinBudgetEur,
      'effect': effect.toJson(),
    };
  }

  factory StorylineDecisionOption.fromJson(Map<String, dynamic> json) {
    return StorylineDecisionOption(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      strategicTag: (json['strategicTag'] as String?) ?? '',
      requiresMinBudgetEur:
          (json['requiresMinBudgetEur'] as num?)?.toInt() ?? 0,
      effect: StorylineChoiceEffect.fromJson(
        (json['effect'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

/// Pojedynczy rozdział wieloletniego wątku fabularnego (przypisany do sezonu).
class StorylineChapter {
  final int chapterIndex;
  final int seasonYearOffset;
  final String title;
  final String headline;
  final String narrativeBody;
  final String pressQuote;
  final String pressSource;
  final String targetRaceName;
  final String targetMilestone;
  final bool isCompleted;
  final bool isFailed;
  final String? selectedOptionId;
  final List<StorylineDecisionOption> options;
  final DateTime? resolvedAt;

  const StorylineChapter({
    required this.chapterIndex,
    required this.seasonYearOffset,
    required this.title,
    required this.headline,
    required this.narrativeBody,
    required this.pressQuote,
    required this.pressSource,
    required this.targetRaceName,
    required this.targetMilestone,
    this.isCompleted = false,
    this.isFailed = false,
    this.selectedOptionId,
    required this.options,
    this.resolvedAt,
  });

  bool get isResolved => isCompleted || isFailed;

  StorylineChapter copyWith({
    int? chapterIndex,
    int? seasonYearOffset,
    String? title,
    String? headline,
    String? narrativeBody,
    String? pressQuote,
    String? pressSource,
    String? targetRaceName,
    String? targetMilestone,
    bool? isCompleted,
    bool? isFailed,
    String? selectedOptionId,
    List<StorylineDecisionOption>? options,
    DateTime? resolvedAt,
  }) {
    return StorylineChapter(
      chapterIndex: chapterIndex ?? this.chapterIndex,
      seasonYearOffset: seasonYearOffset ?? this.seasonYearOffset,
      title: title ?? this.title,
      headline: headline ?? this.headline,
      narrativeBody: narrativeBody ?? this.narrativeBody,
      pressQuote: pressQuote ?? this.pressQuote,
      pressSource: pressSource ?? this.pressSource,
      targetRaceName: targetRaceName ?? this.targetRaceName,
      targetMilestone: targetMilestone ?? this.targetMilestone,
      isCompleted: isCompleted ?? this.isCompleted,
      isFailed: isFailed ?? this.isFailed,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      options: options ?? this.options,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chapterIndex': chapterIndex,
      'seasonYearOffset': seasonYearOffset,
      'title': title,
      'headline': headline,
      'narrativeBody': narrativeBody,
      'pressQuote': pressQuote,
      'pressSource': pressSource,
      'targetRaceName': targetRaceName,
      'targetMilestone': targetMilestone,
      'isCompleted': isCompleted,
      'isFailed': isFailed,
      'selectedOptionId': selectedOptionId,
      'options': options.map((o) => o.toJson()).toList(),
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  factory StorylineChapter.fromJson(Map<String, dynamic> json) {
    return StorylineChapter(
      chapterIndex: (json['chapterIndex'] as num?)?.toInt() ?? 1,
      seasonYearOffset: (json['seasonYearOffset'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?) ?? '',
      headline: (json['headline'] as String?) ?? '',
      narrativeBody: (json['narrativeBody'] as String?) ?? '',
      pressQuote: (json['pressQuote'] as String?) ?? '',
      pressSource: (json['pressSource'] as String?) ?? '',
      targetRaceName: (json['targetRaceName'] as String?) ?? '',
      targetMilestone: (json['targetMilestone'] as String?) ?? '',
      isCompleted: (json['isCompleted'] as bool?) ?? false,
      isFailed: (json['isFailed'] as bool?) ?? false,
      selectedOptionId: json['selectedOptionId'] as String?,
      options: ((json['options'] as List<dynamic>?) ?? const [])
          .map((e) => StorylineDecisionOption.fromJson(
              e as Map<String, dynamic>))
          .toList(),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'] as String)
          : null,
    );
  }
}

/// Pełny wieloletni wątek fabularny w karierze drużyny własnej.
class CareerStorylineArc {
  final String id;
  final StorylineArchetype archetype;
  final String title;
  final String subtitle;
  final int seasonStart;
  final int currentSeason;
  final int totalPlannedSeasons;
  final int currentChapterIndex;
  final StorylineStatus status;
  final StorylineTone tone;
  final double heatIntensity;
  final String sponsorName;
  final String rivalEntityName;
  final String featuredRiderName;
  final String homeCountryCode;
  final String homeRaceName;
  final List<StorylineChapter> chapters;
  final int cumulativeBudgetDeltaEur;
  final int cumulativePrestigeDelta;
  final int dynastyPoints;

  const CareerStorylineArc({
    required this.id,
    required this.archetype,
    required this.title,
    required this.subtitle,
    required this.seasonStart,
    required this.currentSeason,
    required this.totalPlannedSeasons,
    required this.currentChapterIndex,
    required this.status,
    required this.tone,
    required this.heatIntensity,
    required this.sponsorName,
    required this.rivalEntityName,
    required this.featuredRiderName,
    required this.homeCountryCode,
    required this.homeRaceName,
    required this.chapters,
    this.cumulativeBudgetDeltaEur = 0,
    this.cumulativePrestigeDelta = 0,
    this.dynastyPoints = 0,
  });

  StorylineChapter? get activeChapter {
    if (chapters.isEmpty) return null;
    final idx = currentChapterIndex.clamp(0, chapters.length - 1);
    return chapters[idx];
  }

  int get completedChaptersCount =>
      chapters.where((chapter) => chapter.isCompleted).length;

  double get completionRatio {
    if (chapters.isEmpty) return 0.0;
    return (completedChaptersCount / chapters.length).clamp(0.0, 1.0);
  }

  CareerStorylineArc copyWith({
    String? id,
    StorylineArchetype? archetype,
    String? title,
    String? subtitle,
    int? seasonStart,
    int? currentSeason,
    int? totalPlannedSeasons,
    int? currentChapterIndex,
    StorylineStatus? status,
    StorylineTone? tone,
    double? heatIntensity,
    String? sponsorName,
    String? rivalEntityName,
    String? featuredRiderName,
    String? homeCountryCode,
    String? homeRaceName,
    List<StorylineChapter>? chapters,
    int? cumulativeBudgetDeltaEur,
    int? cumulativePrestigeDelta,
    int? dynastyPoints,
  }) {
    return CareerStorylineArc(
      id: id ?? this.id,
      archetype: archetype ?? this.archetype,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      seasonStart: seasonStart ?? this.seasonStart,
      currentSeason: currentSeason ?? this.currentSeason,
      totalPlannedSeasons: totalPlannedSeasons ?? this.totalPlannedSeasons,
      currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
      status: status ?? this.status,
      tone: tone ?? this.tone,
      heatIntensity: heatIntensity ?? this.heatIntensity,
      sponsorName: sponsorName ?? this.sponsorName,
      rivalEntityName: rivalEntityName ?? this.rivalEntityName,
      featuredRiderName: featuredRiderName ?? this.featuredRiderName,
      homeCountryCode: homeCountryCode ?? this.homeCountryCode,
      homeRaceName: homeRaceName ?? this.homeRaceName,
      chapters: chapters ?? this.chapters,
      cumulativeBudgetDeltaEur:
          cumulativeBudgetDeltaEur ?? this.cumulativeBudgetDeltaEur,
      cumulativePrestigeDelta:
          cumulativePrestigeDelta ?? this.cumulativePrestigeDelta,
      dynastyPoints: dynastyPoints ?? this.dynastyPoints,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'archetype': archetype.toJson(),
      'title': title,
      'subtitle': subtitle,
      'seasonStart': seasonStart,
      'currentSeason': currentSeason,
      'totalPlannedSeasons': totalPlannedSeasons,
      'currentChapterIndex': currentChapterIndex,
      'status': status.toJson(),
      'tone': tone.toJson(),
      'heatIntensity': heatIntensity,
      'sponsorName': sponsorName,
      'rivalEntityName': rivalEntityName,
      'featuredRiderName': featuredRiderName,
      'homeCountryCode': homeCountryCode,
      'homeRaceName': homeRaceName,
      'chapters': chapters.map((c) => c.toJson()).toList(),
      'cumulativeBudgetDeltaEur': cumulativeBudgetDeltaEur,
      'cumulativePrestigeDelta': cumulativePrestigeDelta,
      'dynastyPoints': dynastyPoints,
    };
  }

  factory CareerStorylineArc.fromJson(Map<String, dynamic> json) {
    return CareerStorylineArc(
      id: (json['id'] as String?) ?? '',
      archetype: StorylineArchetype.fromJson(
        (json['archetype'] as String?) ?? '',
      ),
      title: (json['title'] as String?) ?? '',
      subtitle: (json['subtitle'] as String?) ?? '',
      seasonStart: (json['seasonStart'] as num?)?.toInt() ?? 2026,
      currentSeason: (json['currentSeason'] as num?)?.toInt() ?? 2026,
      totalPlannedSeasons:
          (json['totalPlannedSeasons'] as num?)?.toInt() ?? 3,
      currentChapterIndex:
          (json['currentChapterIndex'] as num?)?.toInt() ?? 0,
      status: StorylineStatus.fromJson((json['status'] as String?) ?? ''),
      tone: StorylineTone.fromJson((json['tone'] as String?) ?? ''),
      heatIntensity: (json['heatIntensity'] as num?)?.toDouble() ?? 0.5,
      sponsorName: (json['sponsorName'] as String?) ?? '',
      rivalEntityName: (json['rivalEntityName'] as String?) ?? '',
      featuredRiderName: (json['featuredRiderName'] as String?) ?? '',
      homeCountryCode: (json['homeCountryCode'] as String?) ?? 'PL',
      homeRaceName: (json['homeRaceName'] as String?) ?? '',
      chapters: ((json['chapters'] as List<dynamic>?) ?? const [])
          .map((e) => StorylineChapter.fromJson(e as Map<String, dynamic>))
          .toList(),
      cumulativeBudgetDeltaEur:
          (json['cumulativeBudgetDeltaEur'] as num?)?.toInt() ?? 0,
      cumulativePrestigeDelta:
          (json['cumulativePrestigeDelta'] as num?)?.toInt() ?? 0,
      dynastyPoints: (json['dynastyPoints'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Kontekst drużyny i kariery używany do wygenerowania spersonalizowanych wątków.
class StorylineGenerationContext {
  final String teamName;
  final String teamCountryCode;
  final String sponsorName;
  final String sponsorBillionaireName;
  final int currentSeason;
  final int teamBudgetEur;
  final int teamPrestige;
  final String rivalTeamName;
  final String rivalBillionaireName;
  final String featuredRiderName;
  final int featuredRiderAge;
  final bool hadRecentMajorInjury;
  final String? homeRaceNameOverride;
  final int seed;

  const StorylineGenerationContext({
    required this.teamName,
    required this.teamCountryCode,
    required this.sponsorName,
    this.sponsorBillionaireName = 'Aleksander Vance',
    required this.currentSeason,
    required this.teamBudgetEur,
    this.teamPrestige = 68,
    this.rivalTeamName = 'Apex Horizon Global',
    this.rivalBillionaireName = 'Henrik Lindqvist',
    this.featuredRiderName = 'Kacper Kowalski',
    this.featuredRiderAge = 29,
    this.hadRecentMajorInjury = true,
    this.homeRaceNameOverride,
    this.seed = 202601,
  });
}

/// Dane wejściowe podsumowania sezonu do ewaluacji postępu wieloletnich wątków.
class StorylineSeasonProgressInput {
  final int seasonYear;
  final int grandToursWon;
  final int monumentsWon;
  final bool homeRaceWon;
  final bool homeRacePodium;
  final int featuredRiderWins;
  final bool beatRivalTeamInMajorRace;
  final int uciTeamRank;
  final int currentBudgetEur;

  const StorylineSeasonProgressInput({
    required this.seasonYear,
    this.grandToursWon = 0,
    this.monumentsWon = 0,
    this.homeRaceWon = false,
    this.homeRacePodium = false,
    this.featuredRiderWins = 0,
    this.beatRivalTeamInMajorRace = false,
    this.uciTeamRank = 10,
    this.currentBudgetEur = 12000000,
  });
}

/// Wynik operacji fabularnej (podjęcia decyzji lub zakończenia sezonu).
class StorylineProgressionResult {
  final CareerStorylineArc updatedArc;
  final StorylineChapter? unlockedChapter;
  final StorylineChoiceEffect? appliedEffect;
  final String newsHeadline;
  final bool isArcFinished;

  const StorylineProgressionResult({
    required this.updatedArc,
    this.unlockedChapter,
    this.appliedEffect,
    required this.newsHeadline,
    required this.isArcFinished,
  });
}

/// Zbiorcze podsumowanie aktywnych wątków fabularnych w karierze.
class CareerStorylineSummary {
  final int activeCount;
  final int completedCount;
  final int failedCount;
  final int totalDynastyPoints;
  final String dynastyTierLabel;
  final double averageHeatIntensity;

  const CareerStorylineSummary({
    required this.activeCount,
    required this.completedCount,
    required this.failedCount,
    required this.totalDynastyPoints,
    required this.dynastyTierLabel,
    required this.averageHeatIntensity,
  });
}

/// Generator i menedżer wieloletnich wątków fabularnych dla kariery własnej drużyny.
class CustomTeamSponsorStorylineGenerator {
  static const Map<String, String> _countryHomeRaces = {
    'PL': 'Tour de Pologne',
    'FR': 'Tour de France',
    'IT': 'Giro d\'Italia',
    'ES': 'La Vuelta a España',
    'BE': 'Ronde van Vlaanderen',
    'NL': 'Amstel Gold Race',
    'GB': 'Tour of Britain',
    'DE': 'Eschborn-Frankfurt',
    'CH': 'Tour de Suisse',
    'DK': 'PostNord Danmark Rundt',
    'SI': 'Tour of Slovenia',
    'CO': 'Tour Colombia',
    'US': 'Maryland Cycling Classic',
  };

  static const List<String> _historicalDynastyBenchmarks = [
    'Molteni (Era Eddy\'ego Merckxa)',
    'Banesto (Dominacja Miguela Induraina)',
    'Team Sky / Ineos (Maszyna Marginal Gains)',
    'Quick-Step Wolfpack (Królestwo Bruku)',
    'Visma-Lease a Bike (Potrójna Korona Grand Tourów)',
  ];

  const CustomTeamSponsorStorylineGenerator();

  /// Rozwiązuje nazwę prestiżowego domowego wyścigu na podstawie kodu kraju.
  String resolveHomeRaceName(String countryCode, {String? override}) {
    if (override != null && override.trim().isNotEmpty) {
      return override.trim();
    }
    return _countryHomeRaces[countryCode.toUpperCase()] ??
        'Grand Prix Narodowe';
  }

  /// Generuje pakiet startowych wieloletnich wątków fabularnych na otwarcie kariery.
  List<CareerStorylineArc> generateInitialStorylines(
    StorylineGenerationContext context, {
    int maxArcs = 4,
  }) {
    final capped = maxArcs.clamp(1, StorylineArchetype.values.length);
    final orderedArchetypes = <StorylineArchetype>[
      StorylineArchetype.billionaireRivalry,
      StorylineArchetype.nationalHomeRacePressure,
      if (context.hadRecentMajorInjury || context.featuredRiderAge >= 28)
        StorylineArchetype.fallenChampionComeback,
      StorylineArchetype.historicDynastyBuilder,
      if (!context.hadRecentMajorInjury && context.featuredRiderAge < 28)
        StorylineArchetype.fallenChampionComeback,
    ];

    final result = <CareerStorylineArc>[];
    for (var i = 0; i < capped; i++) {
      result.add(generateArcForArchetype(orderedArchetypes[i], context));
    }
    return result;
  }

  /// Generuje kompletny wieloletni wątek fabularny dla wskazanego archetypu.
  CareerStorylineArc generateArcForArchetype(
    StorylineArchetype archetype,
    StorylineGenerationContext context,
  ) {
    final rng = math.Random(context.seed ^ archetype.index * 9973);
    final homeRace = resolveHomeRaceName(
      context.teamCountryCode,
      override: context.homeRaceNameOverride,
    );

    switch (archetype) {
      case StorylineArchetype.billionaireRivalry:
        return _buildBillionaireRivalryArc(context, homeRace, rng);
      case StorylineArchetype.nationalHomeRacePressure:
        return _buildNationalHomeRaceArc(context, homeRace, rng);
      case StorylineArchetype.fallenChampionComeback:
        return _buildFallenChampionComebackArc(context, homeRace, rng);
      case StorylineArchetype.historicDynastyBuilder:
        return _buildHistoricDynastyArc(context, homeRace, rng);
    }
  }

  CareerStorylineArc _buildBillionaireRivalryArc(
    StorylineGenerationContext ctx,
    String homeRace,
    math.Random rng,
  ) {
    final rivalTeam = ctx.rivalTeamName;
    final rivalOwner = ctx.rivalBillionaireName;
    final owner = ctx.sponsorBillionaireName;
    final id = 'arc_billionaire_${ctx.currentSeason}_${rng.nextInt(9000) + 1000}';

    return CareerStorylineArc(
      id: id,
      archetype: StorylineArchetype.billionaireRivalry,
      title: 'Starcie Tytanów: $owner vs $rivalOwner',
      subtitle:
          'Dwuletnia wojna budżetowa i prestiżowa z ekipą $rivalTeam o dominację w WorldTourze.',
      seasonStart: ctx.currentSeason,
      currentSeason: ctx.currentSeason,
      totalPlannedSeasons: 3,
      currentChapterIndex: 0,
      status: StorylineStatus.active,
      tone: StorylineTone.dramatic,
      heatIntensity: 0.72,
      sponsorName: ctx.sponsorName,
      rivalEntityName: '$rivalOwner ($rivalTeam)',
      featuredRiderName: ctx.featuredRiderName,
      homeCountryCode: ctx.teamCountryCode.toUpperCase(),
      homeRaceName: homeRace,
      chapters: [
        StorylineChapter(
          chapterIndex: 1,
          seasonYearOffset: 0,
          title: 'Sezon 1: Pierwsza Salwa na Rynku',
          headline:
              '$rivalOwner rzuca wyzwanie ${ctx.sponsorName}: "Peleton ma miejsce tylko dla jednego imperium"',
          narrativeBody:
              'Właściciel $rivalTeam publicznie zakwestionował ambicje ${ctx.teamName} podczas konferencji przedsezonowej. $owner domaga się natychmiastowej odpowiedzi — sportowej lub technologicznej.',
          pressQuote:
              '"Pieniądze kupują wagę karbonu, ale nie serce na Tourmalet. Zobaczymy, czy ${ctx.teamName} wytrzyma nasze tempo."',
          pressSource: 'L\'Équipe Cycling Desk',
          targetRaceName: 'Critérium du Dauphiné',
          targetMilestone: 'Wyprzedź $rivalTeam w klasyfikacji drużynowej wyścigu WT',
          options: [
            const StorylineDecisionOption(
              id: 'bill_s1_aero',
              title: 'Inwestycja w Tunel Aero i R&D',
              description:
                  'Przeznacz 650 000 EUR na prototypowy pakiet aerodynamiczny przed lipcem.',
              strategicTag: 'Technologia',
              requiresMinBudgetEur: 650000,
              effect: StorylineChoiceEffect(
                budgetDeltaEur: -650000,
                sponsorSatisfactionDelta: 8.0,
                teamMoraleDelta: 5.0,
                prestigeDelta: 6,
                dynastyPointsDelta: 15,
                heatDelta: 0.10,
                outcomeSummary:
                    'Nowe ramy i kombinezony dają przewagę na czasówkach i podgrzewają rywalizację.',
              ),
            ),
            const StorylineDecisionOption(
              id: 'bill_s1_media',
              title: 'Ostra Kontrofensywa Medialna',
              description:
                  'Przyjmij rękawicę na konferencji prasowej bez wydawania rezerw finansowych.',
              strategicTag: 'Presja Medialna',
              requiresMinBudgetEur: 0,
              effect: StorylineChoiceEffect(
                budgetDeltaEur: 250000,
                sponsorSatisfactionDelta: 5.0,
                teamMoraleDelta: 3.0,
                prestigeDelta: 4,
                dynastyPointsDelta: 10,
                heatDelta: 0.14,
                outcomeSummary:
                    'Sponsor docenia bezkompromisową postawę i dopłaca premię za ekspozycję TV.',
              ),
            ),
          ],
        ),
        StorylineChapter(
          chapterIndex: 2,
          seasonYearOffset: 1,
          title: 'Sezon 2: Wojna Podjazdów i Transferów',
          headline:
              'Pojedynek miliarderów wchodzi w fazę krytyczną przed Wielkim Tourem',
          narrativeBody:
              '$rivalTeam próbuje podkupić kluczowych pomocników ${ctx.teamName}. Zarząd ${ctx.sponsorName} jest gotów uruchomić fundusz wojenny, jeśli udowodnisz sportową wyższość.',
          pressQuote:
              '"To już nie jest wyścig kolarski — to szachy o miliardowy wizerunek obu korporacji."',
          pressSource: 'CyclingNews Insider',
          targetRaceName: 'Tour de France',
          targetMilestone: 'Finiszuj przed liderem $rivalTeam w Top 5 GC',
          options: [
            StorylineDecisionOption(
              id: 'bill_s2_warchest',
              title: 'Uruchom Fundusz Lojalnościowy',
              description:
                  'Zabezpiecz kontrakty kluczowych gregario premią 900 000 EUR.',
              strategicTag: 'Ochrona Składu',
              requiresMinBudgetEur: 900000,
              effect: StorylineChoiceEffect(
                budgetDeltaEur: -900000,
                sponsorSatisfactionDelta: 10.0,
                teamMoraleDelta: 12.0,
                prestigeDelta: 8,
                dynastyPointsDelta: 20,
                heatDelta: 0.08,
                outcomeSummary:
                    'Szatnia zostaje zjednoczona, a próba przejęcia ze strony $rivalOwner kończy się fiaskiem.',
              ),
            ),
            const StorylineDecisionOption(
              id: 'bill_s2_raid',
              title: 'Agresywna Taktyka na Trasie',
              description:
                  'Nakaż bezlitosne tempo na wiatrach i zjazdach przeciwko rywalowi.',
              strategicTag: 'Agresja Sportowa',
              requiresMinBudgetEur: 0,
              effect: StorylineChoiceEffect(
                budgetDeltaEur: 0,
                sponsorSatisfactionDelta: 6.0,
                teamMoraleDelta: 6.0,
                prestigeDelta: 7,
                dynastyPointsDelta: 18,
                heatDelta: 0.12,
                outcomeSummary:
                    'Peleton mówi tylko o bezpardonowej walce obu drużyn na każdym etapie.',
              ),
            ),
          ],
        ),
        StorylineChapter(
          chapterIndex: 3,
          seasonYearOffset: 2,
          title: 'Sezon 3: Ostateczne Rozstrzygnięcie',
          headline:
              'Finał trylogii: Kto zostanie niekwestionowanym hegemonem peletonu?',
          narrativeBody:
              'Po dwóch latach zażartej walki $owner i $rivalOwner stawiają wszystko na jedną kartę w decydującym sezonie cyklu WorldTour.',
          pressQuote:
              '"Zwycięzca tego sezonu przejmie tron na lata. Przegrany będzie musiał tłumaczyć się przed radą nadzorczą."',
          pressSource: 'VeloNews Magazine',
          targetRaceName: 'Ranking WorldTour UCI',
          targetMilestone: 'Wyprzedź $rivalTeam w końcowym rankingu UCI lub wygraj Grand Tour',
          options: [
            StorylineDecisionOption(
              id: 'bill_s3_allin',
              title: 'Kontrakt Mistrzowski "All-In"',
              description:
                  'Zainwestuj 1 200 000 EUR w szczyt formy i obóz wysokogórski dla całej ósemki.',
              strategicTag: 'Szczyt Formy',
              requiresMinBudgetEur: 1200000,
              effect: StorylineChoiceEffect(
                budgetDeltaEur: -1200000,
                sponsorSatisfactionDelta: 15.0,
                teamMoraleDelta: 14.0,
                prestigeDelta: 15,
                dynastyPointsDelta: 35,
                heatDelta: 0.05,
                outcomeSummary:
                    'Perfekcyjne przygotowanie cementuje dominację ${ctx.teamName} nad imperium $rivalOwner.',
              ),
            ),
            const StorylineDecisionOption(
              id: 'bill_s3_truce',
              title: 'Profesjonalna Dominacja Bez Rozgłosu',
              description:
                  'Zignoruj prowokacje i dowieź wynik żelazną dyscypliną taktyczną.',
              strategicTag: 'Dyscyplina',
              requiresMinBudgetEur: 0,
              effect: StorylineChoiceEffect(
                budgetDeltaEur: 400000,
                sponsorSatisfactionDelta: 12.0,
                teamMoraleDelta: 8.0,
                prestigeDelta: 12,
                dynastyPointsDelta: 28,
                heatDelta: -0.10,
                outcomeSummary:
                    'Spokój i konsekwencja przynoszą szacunek całego peletonu oraz premię sponsorską.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  CareerStorylineArc _buildNationalHomeRaceArc(
    StorylineGenerationContext ctx,
    String homeRace,
    math.Random rng,
  ) {
    final country = ctx.teamCountryCode.toUpperCase();
    final id = 'arc_national_${ctx.currentSeason}_${rng.nextInt(9000) + 1000}';

    return CareerStorylineArc(
      id: id,
      archetype: StorylineArchetype.nationalHomeRacePressure,
      title: 'Duma Narodu: Podbój $homeRace',
      subtitle:
          'Krajowe media i ${ctx.sponsorName} oczekują triumfu przed własną publicznością ($country).',
      seasonStart: ctx.currentSeason,
      currentSeason: ctx.currentSeason,
      totalPlannedSeasons: 3,
      currentChapterIndex: 0,
      status: StorylineStatus.active,
      tone: StorylineTone.ambitious,
      heatIntensity: 0.65,
      sponsorName: ctx.sponsorName,
      rivalEntityName: 'Presja Mediów ($country)',
      featuredRiderName: ctx.featuredRiderName,
      homeCountryCode: country,
      homeRaceName: homeRace,
      chapters: [
        StorylineChapter(
          chapterIndex: 1,
          seasonYearOffset: 0,
          title: 'Sezon 1: Budowanie Domowej Twierdzy',
          headline:
              'Kibice czekają na rodzimego zwycięzcę w $homeRace',
          narrativeBody:
              'Zarząd ${ctx.sponsorName} jasno komunikuje: rynek krajowy to fundament naszej umowy. Potrzebujemy podium lub wygranej etapowej w $homeRace już w tym roku.',
          pressQuote:
              '"Na naszych szosach musimy jechać z przodu. Tłumy przy barierkach niosą, ale też rozliczają z każdego błędu."',
          pressSource: 'Przegląd Kolarski $country',
          targetRaceName: homeRace,
          targetMilestone: 'Zdobądź podium etapowe lub Top 5 GC w $homeRace',
          options: [
            StorylineDecisionOption(
              id: 'nat_s1_recon',
              title: 'Szczegółowy Rekonesans Tras Domowych',
              description:
                  'Wyślij liderów na 10-dniowy rekonesans kluczowych etapów (280 000 EUR).',
              strategicTag: 'Rekonesans',
              requiresMinBudgetEur: 280000,
              effect: StorylineChoiceEffect(
                budgetDeltaEur: -280000,
                sponsorSatisfactionDelta: 9.0,
                teamMoraleDelta: 6.0,
                prestigeDelta: 5,
                dynastyPointsDelta: 14,
                heatDelta: 0.08,
                outcomeSummary:
                    'Kolarze znają każdy zakręt finałowych kilometrów $homeRace.',
              ),
            ),
            const StorylineDecisionOption(
              id: 'nat_s1_fan_event',
              title: 'Otwarty Trening z Kibicami i Sponsorem',
              description:
                  'Zorganizuj wydarzenie PR przed startem, zyskując wsparcie sponsora.',
              strategicTag: 'Wizerunek',
              requiresMinBudgetEur: 0,
              effect: StorylineChoiceEffect(
                budgetDeltaEur: 200000,
                sponsorSatisfactionDelta: 7.0,
                teamMoraleDelta: 8.0,
                prestigeDelta: 4,
                dynastyPointsDelta: 10,
                heatDelta: 0.12,
                outcomeSummary:
                    'Fala entuzjazmu kibiców podnosi morale, choć oczekiwania mediów rosną.',
              ),
            ),
          ],
        ),
        StorylineChapter(
          chapterIndex: 2,
          seasonYearOffset: 1,
          title: 'Sezon 2: Pod Presją Oczekiwań',
          headline:
              'Tytuły w gazetach nie biorą jeńców: $homeRace celem numer jeden',
          narrativeBody:
              'Po zeszłorocznym przetarciu ${ctx.sponsorName} stawia sprawę jasno — czas na walkę o najwyższy stopień podium w $homeRace.',
          pressQuote:
              '"Druga lokata nikogo już nie urządza. Sponsor chce zdjęcia w koszulce lidera na mecie."',
          pressSource: 'EuroSport National Studio',
          targetRaceName: homeRace,
          targetMilestone: 'Zakończ $homeRace na podium klasyfikacji generalnej',
          options: [
            StorylineDecisionOption(
              id: 'nat_s2_peak',
              title: 'Dedukcja Szczytu Formy na Domowy Wyścig',
              description:
                  'Przesuń zgrupowanie wysokościowe idealnie pod termin $homeRace (450 000 EUR).',
              strategicTag: 'Periodyzacja',
              requiresMinBudgetEur: 450000,
              effect: const StorylineChoiceEffect(
                budgetDeltaEur: -450000,
                sponsorSatisfactionDelta: 11.0,
                teamMoraleDelta: 9.0,
                prestigeDelta: 8,
                dynastyPointsDelta: 22,
                heatDelta: 0.06,
                outcomeSummary:
                    'Liderzy meldują się na starcie z życiową dyspozycją fizjologiczną.',
              ),
            ),
            const StorylineDecisionOption(
              id: 'nat_s2_dual',
              title: 'Podwójne Liderowanie na Wyścigu',
              description:
                  'Wystaw dwóch liderów o różnych profilach, by rozegrać taktyczną przewagę.',
              strategicTag: 'Taktyka',
              requiresMinBudgetEur: 0,
              effect: StorylineChoiceEffect(
                budgetDeltaEur: 0,
                sponsorSatisfactionDelta: 6.0,
                teamMoraleDelta: 4.0,
                prestigeDelta: 6,
                dynastyPointsDelta: 16,
                heatDelta: 0.10,
                outcomeSummary:
                    'Elastyczność taktyczna zaskakuje rywali na decydujących podjazdach.',
              ),
            ),
          ],
        ),
        StorylineChapter(
          chapterIndex: 3,
          seasonYearOffset: 2,
          title: 'Sezon 3: Koronacja przed Własną Publicznością',
          headline:
              'Historyczna szansa na triumf ${ctx.teamName} w $homeRace',
          narrativeBody:
              'Trzeci rok projektu ma przynieść upragnione zwycięstwo generalne i wpisanie nazwy ${ctx.sponsorName} złotymi zgłoskami w historię $homeRace.',
          pressQuote:
              '"Jeśli uniosą puchar przed własnym narodem, przedłużenie kontraktu sponsora będzie czystą formalnością."',
          pressSource: 'Kronika Kolarska',
          targetRaceName: homeRace,
          targetMilestone: 'Wygraj klasyfikację generalną $homeRace',
          options: [
            const StorylineDecisionOption(
              id: 'nat_s3_bonus',
              title: 'Ekstra Premia Zwycięska dla Drużyny',
              description:
                  'Zadeklaruj 500 000 EUR premii dla wszystkich kolarzy i sztabu za wygraną.',
              strategicTag: 'Motywacja',
              requiresMinBudgetEur: 500000,
              effect: StorylineChoiceEffect(
                budgetDeltaEur: -500000,
                sponsorSatisfactionDelta: 16.0,
                teamMoraleDelta: 15.0,
                prestigeDelta: 14,
                dynastyPointsDelta: 32,
                heatDelta: -0.05,
                outcomeSummary:
                    'Zespół jedzie jak jeden organizm, realizując marzenie kibiców i sponsora.',
              ),
            ),
            const StorylineDecisionOption(
              id: 'nat_s3_youth',
              title: 'Daj Szansę Młodemu Krajowemu Talentowi',
              description:
                  'Postaw na wychowanka z akademii U23 jako wolnego elektronu wspierającego lidera.',
              strategicTag: 'Wychowankowie',
              requiresMinBudgetEur: 0,
              effect: StorylineChoiceEffect(
                budgetDeltaEur: 300000,
                sponsorSatisfactionDelta: 12.0,
                teamMoraleDelta: 10.0,
                prestigeDelta: 11,
                dynastyPointsDelta: 25,
                heatDelta: 0.04,
                outcomeSummary:
                    'Media zachwycają się nową generacją domowego kolarstwa.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  CareerStorylineArc _buildFallenChampionComebackArc(
    StorylineGenerationContext ctx,
    String homeRace,
    math.Random rng,
  ) {
    final rider = ctx.featuredRiderName;
    final id = 'arc_comeback_${ctx.currentSeason}_${rng.nextInt(9000) + 1000}';

    return CareerStorylineArc(
      id: id,
      archetype: StorylineArchetype.fallenChampionComeback,
      title: 'Powrót Feniksa: Droga $rider',
      subtitle:
          'Wieloletnia odbudowa dawnego mistrza po poważnej kontuzji i powrót na szczyt WorldTouru.',
      seasonStart: ctx.currentSeason,
      currentSeason: ctx.currentSeason,
      totalPlannedSeasons: 3,
      currentChapterIndex: 0,
      status: StorylineStatus.active,
      tone: StorylineTone.redemption,
      heatIntensity: 0.58,
      sponsorName: ctx.sponsorName,
      rivalEntityName: 'Wątpliwości Lekarzy i Mediów',
      featuredRiderName: rider,
      homeCountryCode: ctx.teamCountryCode.toUpperCase(),
      homeRaceName: homeRace,
      chapters: [
        StorylineChapter(
          chapterIndex: 1,
          seasonYearOffset: 0,
          title: 'Sezon 1: Cierpliwa Rehabilitacja i Powrót do Peletonu',
          headline:
              'Czy $rider odzyska dawne waty po dramatycznej kraksie?',
          narrativeBody:
              'Eksperci wróżą koniec wielkiej kariery, lecz ${ctx.teamName} wierzy w charakter mistrza. Pierwszy rok to walka o symetrię pedałowania, wytrzymałość bazową i pierwsze zwycięstwo.',
          pressQuote:
              '"Najtrudniejsza góra w życiu $rider nie leży w Alpach — to powrót do zaufania własnemu ciału."',
          pressSource: 'Peloton Medical Review',
          targetRaceName: 'Wyścigi ProSeries / Etapowe',
          targetMilestone: 'Zdobądź przynajmniej 1 zwycięstwo zawodowe z udziałem $rider',
          options: [
            const StorylineDecisionOption(
              id: 'comb_s1_lab',
              title: 'Specjalistyczna Biomechanika i Fizjoterapia',
              description:
                  'Sfinansuj całoroczny program analizy L/R i komory hiperbarycznej (350 000 EUR).',
              strategicTag: 'Medycyna Sportowa',
              requiresMinBudgetEur: 350000,
              effect: StorylineChoiceEffect(
                budgetDeltaEur: -350000,
                sponsorSatisfactionDelta: 6.0,
                teamMoraleDelta: 10.0,
                prestigeDelta: 6,
                dynastyPointsDelta: 16,
                heatDelta: 0.05,
                outcomeSummary:
                    'Balans lewej i prawej nogi wraca do 49.8% / 50.2%, a VO2max znów rośnie.',
              ),
            ),
            StorylineDecisionOption(
              id: 'comb_s1_mentor',
              title: 'Rola Mentora i Spokojny Kalendarz',
              description:
                  'Zdejmij presję wyników i pozwól $rider prowadzić młodych kolarzy w mniejszych wyścigach.',
              strategicTag: 'Cierpliwość',
              requiresMinBudgetEur: 0,
              effect: const StorylineChoiceEffect(
                budgetDeltaEur: 0,
                sponsorSatisfactionDelta: 4.0,
                teamMoraleDelta: 9.0,
                prestigeDelta: 4,
                dynastyPointsDelta: 12,
                heatDelta: -0.05,
                outcomeSummary:
                    'Brak presji pozwala spokojnie odbudować bazę tlenową i pewność siebie w grupie.',
              ),
            ),
          ],
        ),
        StorylineChapter(
          chapterIndex: 2,
          seasonYearOffset: 1,
          title: 'Sezon 2: Druga Młodość w Wysokich Górach',
          headline:
              '$rider znów atakuje faworytów na najcięższych podjazdach!',
          narrativeBody:
              'Po przepracowanej zimie dawny mistrz znów melduje się w czołówce WorldTouru. Teraz czas udowodnić, że potrafi wygrywać na najwyższym szczeblu.',
          pressQuote:
              '"To najpiękniejsza historia tego sezonu — nikt nie spodziewał się takiego powrotu."',
          pressSource: 'Cycling Weekly',
          targetRaceName: 'Monument lub Grand Tour',
          targetMilestone: 'Zanotuj minimum 2 zwycięstwa lub podium etapu WorldTour',
          options: [
            StorylineDecisionOption(
              id: 'comb_s2_altitude',
              title: 'Dedykowany Obóz na Teide dla $rider',
              description:
                  'Wyślij lidera z dwoma pomocnikami na 3-tygodniowy obóz na wulkanie (420 000 EUR).',
              strategicTag: 'Wysokogórski Szczyt',
              requiresMinBudgetEur: 420000,
              effect: const StorylineChoiceEffect(
                budgetDeltaEur: -420000,
                sponsorSatisfactionDelta: 10.0,
                teamMoraleDelta: 11.0,
                prestigeDelta: 10,
                dynastyPointsDelta: 24,
                heatDelta: 0.10,
                outcomeSummary:
                    'Hematokryt i wydolność na wysokości >2000 m przywracają mistrzowski błysk.',
              ),
            ),
            const StorylineDecisionOption(
              id: 'comb_s2_stagehunt',
              title: 'Polowanie na Etapy i Koszulkę Górską',
              description:
                  'Zmień cel z generalki na spektakularne ataki z ucieczek na górskich etapach.',
              strategicTag: 'Wolny Elektron',
              requiresMinBudgetEur: 0,
              effect: StorylineChoiceEffect(
                budgetDeltaEur: 150000,
                sponsorSatisfactionDelta: 8.0,
                teamMoraleDelta: 8.0,
                prestigeDelta: 8,
                dynastyPointsDelta: 18,
                heatDelta: 0.08,
                outcomeSummary:
                    'Kibice na całym świecie oklaskują heroiczną jazdę i wielką waleczność.',
              ),
            ),
          ],
        ),
        StorylineChapter(
          chapterIndex: 3,
          seasonYearOffset: 2,
          title: 'Sezon 3: Ostateczna Koronacja Powrotu',
          headline:
              'Klamra historii: $rider przed szansą na wielki triumf na miarę legendy',
          narrativeBody:
              'Trzy lata po wypadku, który miał zakończyć karierę, $rider staje na starcie jako pełnoprawny lider z misją zwieńczenia powrotu historycznym trofeum.',
          pressQuote:
              '"Jeśli sięgnie po zwycięstwo, będzie to najbardziej wzruszający triumf dekady."',
          pressSource: 'La Gazzetta dello Sport',
          targetRaceName: 'Grand Tour / Mistrzostwa Świata',
          targetMilestone: 'Zdobądź trofeum klasy Monument, Grand Tour lub podium MŚ',
          options: [
            StorylineDecisionOption(
              id: 'comb_s3_legacy_contract',
              title: 'Przedłużenie Kontraktu Legendy i Wsparcie',
              description:
                  'Zaoferuj 600 000 EUR gwarancji ambasadorskiej dla ${ctx.sponsorName}.',
              strategicTag: 'Dziedzictwo',
              requiresMinBudgetEur: 600000,
              effect: StorylineChoiceEffect(
                budgetDeltaEur: -600000,
                sponsorSatisfactionDelta: 15.0,
                teamMoraleDelta: 14.0,
                prestigeDelta: 16,
                dynastyPointsDelta: 35,
                heatDelta: 0.05,
                outcomeSummary:
                    'Powrót stulecia staje się wizytówką ${ctx.sponsorName} na całym świecie.',
              ),
            ),
            const StorylineDecisionOption(
              id: 'comb_s3_pass_torch',
              title: 'Przekazanie Pałeczki Nowemu Pokoleniu',
              description:
                  'Wykorzystaj powrót mistrza, by wykreować duet liderów na kolejne lata.',
              strategicTag: 'Sukcesja',
              requiresMinBudgetEur: 0,
              effect: StorylineChoiceEffect(
                budgetDeltaEur: 250000,
                sponsorSatisfactionDelta: 12.0,
                teamMoraleDelta: 12.0,
                prestigeDelta: 13,
                dynastyPointsDelta: 28,
                heatDelta: 0.0,
                outcomeSummary:
                    'Harmonia między doświadczeniem a młodością buduje siłę ekipy na lata.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  CareerStorylineArc _buildHistoricDynastyArc(
    StorylineGenerationContext ctx,
    String homeRace,
    math.Random rng,
  ) {
    final benchmark = _historicalDynastyBenchmarks[
        rng.nextInt(_historicalDynastyBenchmarks.length)];
    final id = 'arc_dynasty_${ctx.currentSeason}_${rng.nextInt(9000) + 1000}';

    return CareerStorylineArc(
      id: id,
      archetype: StorylineArchetype.historicDynastyBuilder,
      title: 'Architektura Dynastii: Śladem $benchmark',
      subtitle:
          'Czteroletni plan stworzenia hegemonii WorldTour, która zapisze ${ctx.teamName} w Hall of Fame.',
      seasonStart: ctx.currentSeason,
      currentSeason: ctx.currentSeason,
      totalPlannedSeasons: 4,
      currentChapterIndex: 0,
      status: StorylineStatus.active,
      tone: StorylineTone.legacy,
      heatIntensity: 0.50,
      sponsorName: ctx.sponsorName,
      rivalEntityName: 'Historia Kolarstwa ($benchmark)',
      featuredRiderName: ctx.featuredRiderName,
      homeCountryCode: ctx.teamCountryCode.toUpperCase(),
      homeRaceName: homeRace,
      chapters: [
        StorylineChapter(
          chapterIndex: 1,
          seasonYearOffset: 0,
          title: 'Rok I: Fundamenty Systemu',
          headline:
              '${ctx.teamName} wdraża długofalową filozofię na wzór $benchmark',
          narrativeBody:
              'Wielkie dynastie nie rodzą się w jeden lipiec. Pierwszy etap to zbudowanie kultury treningowej, bazy Service Course i miejsca w Top 8 rankingu UCI.',
          pressQuote:
              '"To projekt liczony nie na jeden kontrakt sponsorski, lecz na całą dekadę kolarstwa."',
          pressSource: 'Rouleur Journal',
          targetRaceName: 'Sezon WorldTour',
          targetMilestone: 'Zakończ sezon w Top 8 rankingu drużynowego UCI',
          options: [
            const StorylineDecisionOption(
              id: 'dyn_s1_academy',
              title: 'Inwestycja w Akademię U23 i Skauting',
              description:
                  'Przeznacz 550 000 EUR na budowę zaplecza przyszłych mistrzów.',
              strategicTag: 'Akademia',
              requiresMinBudgetEur: 550000,
              effect: StorylineChoiceEffect(
                budgetDeltaEur: -550000,
                sponsorSatisfactionDelta: 7.0,
                teamMoraleDelta: 6.0,
                prestigeDelta: 7,
                dynastyPointsDelta: 20,
                heatDelta: 0.05,
                outcomeSummary:
                    'Młode talenty z całego świata ustawiają się w kolejce do programu rozwojowego.',
              ),
            ),
            const StorylineDecisionOption(
              id: 'dyn_s1_science',
              title: 'Standaryzacja Protokołów Żywienia i Regeneracji',
              description:
                  'Wdróż autorski model 110g CHO/h oraz ketonów bez wielkich kosztów kapitałowych.',
              strategicTag: 'Marginal Gains',
              requiresMinBudgetEur: 0,
              effect: StorylineChoiceEffect(
                budgetDeltaEur: 0,
                sponsorSatisfactionDelta: 5.0,
                teamMoraleDelta: 7.0,
                prestigeDelta: 5,
                dynastyPointsDelta: 15,
                heatDelta: 0.05,
                outcomeSummary:
                    'Spadek liczby kontuzji i stabilniejsza forma w trzecim tygodniu wyścigów.',
              ),
            ),
          ],
        ),
        StorylineChapter(
          chapterIndex: 2,
          seasonYearOffset: 1,
          title: 'Rok II: Pierwsze Wielkie Trofea',
          headline:
              'Czas przekuć fundamenty w Monumenty i Wielkie Toury',
          narrativeBody:
              'Drużyna okrzepła w elicie. Aby porównania do $benchmark nie były na wyrost, potrzebny jest pierwszy triumf w Monumencie lub Wielkim Tourze.',
          pressQuote:
              '"Peleton zaczyna patrzeć na pociągi ${ctx.teamName} z respektem należnym największym."',
          pressSource: 'ProCyclingStats Editorial',
          targetRaceName: 'Monumenty i Grand Toury',
          targetMilestone: 'Wygraj minimum 1 Monument lub Grand Tour',
          options: [
            const StorylineDecisionOption(
              id: 'dyn_s2_supertrain',
              title: 'Budowa Górskiego Pociągu Marzeń',
              description:
                  'Zainwestuj 850 000 EUR w specjalistyczne kontrakty i zgrupowania dla górali.',
              strategicTag: 'Dominacja Górska',
              requiresMinBudgetEur: 850000,
              effect: StorylineChoiceEffect(
                budgetDeltaEur: -850000,
                sponsorSatisfactionDelta: 12.0,
                teamMoraleDelta: 10.0,
                prestigeDelta: 12,
                dynastyPointsDelta: 28,
                heatDelta: 0.10,
                outcomeSummary:
                    'Ekipa narzuca tempo nie do wytrzymania na przełęczach Hors Catégorie.',
              ),
            ),
            const StorylineDecisionOption(
              id: 'dyn_s2_classics',
              title: 'Ofensywa na Wiosennych Klasykach',
              description:
                  'Skoncentruj kalendarz na brukowanych i ardeńskich Monumentach.',
              strategicTag: 'Łowcy Monumentów',
              requiresMinBudgetEur: 0,
              effect: StorylineChoiceEffect(
                budgetDeltaEur: 200000,
                sponsorSatisfactionDelta: 9.0,
                teamMoraleDelta: 8.0,
                prestigeDelta: 9,
                dynastyPointsDelta: 22,
                heatDelta: 0.08,
                outcomeSummary:
                    'Agresywna jazda od Flandrii po Liège przynosi ogromną ekspozycję telewizyjną.',
              ),
            ),
          ],
        ),
        const StorylineChapter(
          chapterIndex: 3,
          seasonYearOffset: 2,
          title: 'Rok III: Obrona Tronu i Numer 1 UCI',
          headline:
              'Najtrudniej jest utrzymać się na szczycie, gdy cały peleton poluje na ciebie',
          narrativeBody:
              'Rywale kopiują wasze rozwiązania sprzętowe i taktyczne. Trzeci sezon to test głębi składu i dojrzałości całej organizacji.',
          pressQuote:
              '"Każda wielka ekipa przechodzi kryzys trzeciego roku. Tylko dynastie wychodzą z niego silniejsze."',
          pressSource: 'L\'Équipe Magazine',
          targetRaceName: 'Ranking WorldTour UCI',
          targetMilestone: 'Utrzymaj Top 3 rankingu UCI oraz wygraj Grand Tour',
          options: [
            StorylineDecisionOption(
              id: 'dyn_s3_rnd',
              title: 'Ekskluzywne Partnerstwo Technologiczne',
              description:
                  'Podpisz umowę na prototypowy osprzęt i opony nowej generacji (700 000 EUR).',
              strategicTag: 'Innowacja',
              requiresMinBudgetEur: 700000,
              effect: StorylineChoiceEffect(
                budgetDeltaEur: -700000,
                sponsorSatisfactionDelta: 14.0,
                teamMoraleDelta: 10.0,
                prestigeDelta: 14,
                dynastyPointsDelta: 32,
                heatDelta: 0.08,
                outcomeSummary:
                    'Przewaga technologiczna utrzymuje drużynę o krok przed peletonem.',
              ),
            ),
            StorylineDecisionOption(
              id: 'dyn_s3_rotation',
              title: 'Inteligentna Rotacja Liderów',
              description:
                  'Rozłóż ciężar kalendarza na dwóch równorzędnych liderów bez obciążania budżetu.',
              strategicTag: 'Głębia Składu',
              requiresMinBudgetEur: 0,
              effect: StorylineChoiceEffect(
                budgetDeltaEur: 350000,
                sponsorSatisfactionDelta: 11.0,
                teamMoraleDelta: 9.0,
                prestigeDelta: 11,
                dynastyPointsDelta: 26,
                heatDelta: 0.04,
                outcomeSummary:
                    'Świeżość liderów w drugiej połowie sezonu procentuje serią zwycięstw.',
              ),
            ),
          ],
        ),
        StorylineChapter(
          chapterIndex: 4,
          seasonYearOffset: 3,
          title: 'Rok IV: Nieśmiertelność w Hall of Fame',
          headline:
              'Ostatni krok do wpisania ${ctx.teamName} obok $benchmark',
          narrativeBody:
              'Czwarty sezon zamyka wieloletni cykl. Triumf w tym roku zapewni drużynie status historycznej dynastii oraz długoterminowe przedłużenie umowy przez ${ctx.sponsorName}.',
          pressQuote:
              '"Patrzymy na drużynę kompletną. To już nie jest sezon — to epoka ${ctx.teamName}."',
          pressSource: 'Vélo d\'Or Gala Special',
          targetRaceName: 'Potrójna Korona / Ranking #1 UCI',
          targetMilestone: 'Zdobądź 1. miejsce w rankingu UCI lub 2+ wielkie tytuły',
          options: [
            StorylineDecisionOption(
              id: 'dyn_s4_golden_era',
              title: 'Manifest Złotej Ery (${ctx.sponsorName} 2030)',
              description:
                  'Zainwestuj 1 000 000 EUR w perfekcyjny obóz i sztab na finałowy atak.',
              strategicTag: 'Złota Era',
              requiresMinBudgetEur: 1000000,
              effect: StorylineChoiceEffect(
                budgetDeltaEur: -1000000,
                sponsorSatisfactionDelta: 20.0,
                teamMoraleDelta: 16.0,
                prestigeDelta: 20,
                dynastyPointsDelta: 45,
                heatDelta: 0.10,
                outcomeSummary:
                    'Nazwa ${ctx.teamName} trafia do panteonu największych ekip w dziejach kolarstwa.',
              ),
            ),
            const StorylineDecisionOption(
              id: 'dyn_s4_sustainable',
              title: 'Zrównoważony Model Dynastii',
              description:
                  'Połącz walkę o trofea z dodatnim bilansem finansowym i kontraktem wieloletnim.',
              strategicTag: 'Stabilność',
              requiresMinBudgetEur: 0,
              effect: StorylineChoiceEffect(
                budgetDeltaEur: 800000,
                sponsorSatisfactionDelta: 16.0,
                teamMoraleDelta: 12.0,
                prestigeDelta: 16,
                dynastyPointsDelta: 38,
                heatDelta: 0.0,
                outcomeSummary:
                    'Sponsor podpisuje rekordowe przedłużenie umowy, widząc stabilną potęgę.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Aplikuje decyzję gracza w aktywnym rozdziale danego wątku fabularnego.
  StorylineProgressionResult applyDecision(
    CareerStorylineArc arc,
    String optionId, {
    int currentBudgetEur = 100000000,
    DateTime? decidedAt,
  }) {
    if (arc.status != StorylineStatus.active) {
      return StorylineProgressionResult(
        updatedArc: arc,
        newsHeadline: 'Wątek "${arc.title}" jest już zamknięty (${arc.status.label}).',
        isArcFinished: arc.status == StorylineStatus.completed ||
            arc.status == StorylineStatus.failed,
      );
    }

    final chapter = arc.activeChapter;
    if (chapter == null) {
      return StorylineProgressionResult(
        updatedArc: arc,
        newsHeadline: 'Brak aktywnego rozdziału dla wątku "${arc.title}".',
        isArcFinished: false,
      );
    }

    final optionIndex =
        chapter.options.indexWhere((element) => element.id == optionId);
    if (optionIndex == -1) {
      return StorylineProgressionResult(
        updatedArc: arc,
        newsHeadline: 'Nieznana opcja decyzji ($optionId) w wątku "${arc.title}".',
        isArcFinished: false,
      );
    }

    final chosen = chapter.options[optionIndex];
    if (!chosen.isAffordable(currentBudgetEur)) {
      return StorylineProgressionResult(
        updatedArc: arc,
        newsHeadline:
            'Niewystarczający budżet na opcję "${chosen.title}" (wymagane ${chosen.requiresMinBudgetEur} EUR).',
        isArcFinished: false,
      );
    }

    final updatedChapter = chapter.copyWith(
      selectedOptionId: chosen.id,
      isCompleted: true,
      resolvedAt: decidedAt ?? DateTime(arc.currentSeason, 3, 15),
    );

    final updatedChapters = List<StorylineChapter>.from(arc.chapters);
    final idx = arc.currentChapterIndex.clamp(0, updatedChapters.length - 1);
    updatedChapters[idx] = updatedChapter;

    final hasNextChapter = idx + 1 < updatedChapters.length;
    final nextIndex = hasNextChapter ? idx + 1 : idx;
    final nextStatus =
        hasNextChapter ? StorylineStatus.active : StorylineStatus.completed;

    final updatedArc = arc.copyWith(
      chapters: updatedChapters,
      currentChapterIndex: nextIndex,
      currentSeason:
          hasNextChapter ? arc.currentSeason + 1 : arc.currentSeason,
      status: nextStatus,
      heatIntensity:
          (arc.heatIntensity + chosen.effect.heatDelta).clamp(0.0, 1.0),
      cumulativeBudgetDeltaEur:
          arc.cumulativeBudgetDeltaEur + chosen.effect.budgetDeltaEur,
      cumulativePrestigeDelta:
          arc.cumulativePrestigeDelta + chosen.effect.prestigeDelta,
      dynastyPoints: arc.dynastyPoints + chosen.effect.dynastyPointsDelta,
    );

    return StorylineProgressionResult(
      updatedArc: updatedArc,
      unlockedChapter: hasNextChapter ? updatedChapters[nextIndex] : null,
      appliedEffect: chosen.effect,
      newsHeadline:
          '${arc.sponsorName}: ${chosen.title} — ${chosen.effect.outcomeSummary}',
      isArcFinished: !hasNextChapter,
    );
  }

  /// Ewaluuje postęp sportowy wątku na zakończenie sezonu i odblokowuje kolejny rozdział.
  StorylineProgressionResult evaluateSeasonProgress(
    CareerStorylineArc arc,
    StorylineSeasonProgressInput input,
  ) {
    if (arc.status != StorylineStatus.active) {
      return StorylineProgressionResult(
        updatedArc: arc,
        newsHeadline: 'Wątek "${arc.title}" nie jest aktywny.',
        isArcFinished: arc.status == StorylineStatus.completed ||
            arc.status == StorylineStatus.failed,
      );
    }

    final chapter = arc.activeChapter;
    if (chapter == null) {
      return StorylineProgressionResult(
        updatedArc: arc,
        newsHeadline: 'Brak rozdziału do ewaluacji.',
        isArcFinished: false,
      );
    }

    final milestoneMet = _didMeetSeasonMilestone(arc, chapter, input);
    final updatedChapter = chapter.copyWith(
      isCompleted: milestoneMet,
      isFailed: !milestoneMet,
      resolvedAt: DateTime(input.seasonYear, 10, 20),
    );

    final updatedChapters = List<StorylineChapter>.from(arc.chapters);
    final idx = arc.currentChapterIndex.clamp(0, updatedChapters.length - 1);
    updatedChapters[idx] = updatedChapter;

    final hasNext = idx + 1 < updatedChapters.length;
    final isFinalFailure = !milestoneMet && !hasNext;
    final nextStatus = !hasNext
        ? (milestoneMet ? StorylineStatus.completed : StorylineStatus.failed)
        : StorylineStatus.active;

    final dynastyBonus = milestoneMet ? 25 : 0;
    final prestigeBonus = milestoneMet ? 8 : -4;
    final heatDelta = milestoneMet ? 0.08 : -0.10;

    final updatedArc = arc.copyWith(
      chapters: updatedChapters,
      currentChapterIndex: hasNext ? idx + 1 : idx,
      currentSeason: hasNext ? input.seasonYear + 1 : input.seasonYear,
      status: nextStatus,
      heatIntensity: (arc.heatIntensity + heatDelta).clamp(0.0, 1.0),
      cumulativePrestigeDelta: arc.cumulativePrestigeDelta + prestigeBonus,
      dynastyPoints: arc.dynastyPoints + dynastyBonus,
    );

    final headline = milestoneMet
        ? 'Cel sezonu ${input.seasonYear} zrealizowany w wątku "${arc.title}"!'
        : (isFinalFailure
            ? 'Nie udało się domknąć finałowego celu w wątku "${arc.title}".'
            : 'Potknięcie w sezonie ${input.seasonYear} komplikuje wątek "${arc.title}".');

    return StorylineProgressionResult(
      updatedArc: updatedArc,
      unlockedChapter: hasNext ? updatedChapters[idx + 1] : null,
      newsHeadline: headline,
      isArcFinished: !hasNext,
    );
  }

  bool _didMeetSeasonMilestone(
    CareerStorylineArc arc,
    StorylineChapter chapter,
    StorylineSeasonProgressInput input,
  ) {
    switch (arc.archetype) {
      case StorylineArchetype.billionaireRivalry:
        return input.beatRivalTeamInMajorRace ||
            input.grandToursWon > 0 ||
            input.uciTeamRank <= 3;
      case StorylineArchetype.nationalHomeRacePressure:
        if (chapter.chapterIndex >= 3) {
          return input.homeRaceWon;
        }
        return input.homeRaceWon || input.homeRacePodium;
      case StorylineArchetype.fallenChampionComeback:
        if (chapter.chapterIndex >= 3) {
          return input.monumentsWon > 0 ||
              input.grandToursWon > 0 ||
              input.featuredRiderWins >= 3;
        }
        return input.featuredRiderWins >= 1;
      case StorylineArchetype.historicDynastyBuilder:
        if (chapter.chapterIndex == 1) {
          return input.uciTeamRank <= 8;
        }
        if (chapter.chapterIndex == 2) {
          return input.monumentsWon > 0 || input.grandToursWon > 0;
        }
        if (chapter.chapterIndex == 3) {
          return input.uciTeamRank <= 3 &&
              (input.grandToursWon > 0 || input.monumentsWon > 0);
        }
        return input.uciTeamRank == 1 ||
            (input.grandToursWon + input.monumentsWon) >= 2;
    }
  }

  /// Zwraca historyczną rangę dynastii na podstawie zdobytych punktów fabularnych.
  String computeDynastyTierLabel(int dynastyPoints) {
    if (dynastyPoints >= 140) return 'Nieśmiertelna Dynastia WorldTour';
    if (dynastyPoints >= 95) return 'Złota Era Dominacji';
    if (dynastyPoints >= 55) return 'Pretendent do Tronu';
    if (dynastyPoints >= 25) return 'Rosnąca Potęga';
    return 'Nowy Projekt';
  }

  /// Tworzy zbiorcze podsumowanie wszystkich wątków fabularnych w karierze.
  CareerStorylineSummary summarizeStorylines(List<CareerStorylineArc> arcs) {
    var active = 0;
    var completed = 0;
    var failed = 0;
    var totalDynasty = 0;
    var heatSum = 0.0;

    for (final arc in arcs) {
      switch (arc.status) {
        case StorylineStatus.active:
        case StorylineStatus.paused:
          active++;
          break;
        case StorylineStatus.completed:
          completed++;
          break;
        case StorylineStatus.failed:
          failed++;
          break;
      }
      totalDynasty += arc.dynastyPoints;
      heatSum += arc.heatIntensity;
    }

    return CareerStorylineSummary(
      activeCount: active,
      completedCount: completed,
      failedCount: failed,
      totalDynastyPoints: totalDynasty,
      dynastyTierLabel: computeDynastyTierLabel(totalDynasty),
      averageHeatIntensity: arcs.isEmpty ? 0.0 : heatSum / arcs.length,
    );
  }
}

/// Stan Riverpod dla generatora i menedżera wieloletnich wątków fabularnych.
class CustomTeamSponsorStorylineState {
  final List<CareerStorylineArc> arcs;
  final String? selectedArcId;
  final StorylineArchetype? filterArchetype;
  final int availableBudgetEur;
  final String? lastNotification;

  const CustomTeamSponsorStorylineState({
    this.arcs = const [],
    this.selectedArcId,
    this.filterArchetype,
    this.availableBudgetEur = 5000000,
    this.lastNotification,
  });

  List<CareerStorylineArc> get filteredArcs {
    if (filterArchetype == null) return arcs;
    return arcs.where((a) => a.archetype == filterArchetype).toList();
  }

  CareerStorylineArc? get selectedArc {
    final list = filteredArcs;
    if (list.isEmpty) return null;
    if (selectedArcId == null) return list.first;
    return list.firstWhere(
      (a) => a.id == selectedArcId,
      orElse: () => list.first,
    );
  }

  CustomTeamSponsorStorylineState copyWith({
    List<CareerStorylineArc>? arcs,
    String? selectedArcId,
    bool clearSelectedArcId = false,
    StorylineArchetype? filterArchetype,
    bool clearFilter = false,
    int? availableBudgetEur,
    String? lastNotification,
  }) {
    return CustomTeamSponsorStorylineState(
      arcs: arcs ?? this.arcs,
      selectedArcId:
          clearSelectedArcId ? null : (selectedArcId ?? this.selectedArcId),
      filterArchetype:
          clearFilter ? null : (filterArchetype ?? this.filterArchetype),
      availableBudgetEur: availableBudgetEur ?? this.availableBudgetEur,
      lastNotification: lastNotification ?? this.lastNotification,
    );
  }
}

/// Notifier zarządzający wieloletnimi wątkami fabularnymi w karierze własnej.
class CustomTeamSponsorStorylineNotifier
    extends StateNotifier<CustomTeamSponsorStorylineState> {
  final CustomTeamSponsorStorylineGenerator _generator;

  CustomTeamSponsorStorylineNotifier({
    CustomTeamSponsorStorylineGenerator? generator,
    StorylineGenerationContext? initialContext,
  })  : _generator = generator ?? const CustomTeamSponsorStorylineGenerator(),
        super(const CustomTeamSponsorStorylineState()) {
    if (initialContext != null) {
      initializeFromContext(initialContext);
    }
  }

  void initializeFromContext(StorylineGenerationContext context) {
    final generated = _generator.generateInitialStorylines(context);
    state = state.copyWith(
      arcs: generated,
      selectedArcId: generated.isNotEmpty ? generated.first.id : null,
      availableBudgetEur: context.teamBudgetEur,
      lastNotification: 'Wygenerowano ${generated.length} wieloletnie wątki fabularne.',
    );
  }

  void selectArc(String arcId) {
    state = state.copyWith(selectedArcId: arcId);
  }

  void setFilter(StorylineArchetype? archetype) {
    if (archetype == null) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(filterArchetype: archetype);
    }
  }

  void addArcForArchetype(
    StorylineArchetype archetype,
    StorylineGenerationContext context,
  ) {
    final newArc = _generator.generateArcForArchetype(archetype, context);
    state = state.copyWith(
      arcs: [...state.arcs, newArc],
      selectedArcId: newArc.id,
      lastNotification: 'Dodano nowy wątek: ${newArc.title}.',
    );
  }

  void makeDecision(String arcId, String optionId) {
    final idx = state.arcs.indexWhere((a) => a.id == arcId);
    if (idx == -1) return;

    final result = _generator.applyDecision(
      state.arcs[idx],
      optionId,
      currentBudgetEur: state.availableBudgetEur,
    );

    final nextArcs = List<CareerStorylineArc>.from(state.arcs);
    nextArcs[idx] = result.updatedArc;

    final budgetDelta = result.appliedEffect?.budgetDeltaEur ?? 0;
    state = state.copyWith(
      arcs: nextArcs,
      availableBudgetEur: math.max(0, state.availableBudgetEur + budgetDelta),
      lastNotification: result.newsHeadline,
    );
  }

  void evaluateSeason(String arcId, StorylineSeasonProgressInput input) {
    final idx = state.arcs.indexWhere((a) => a.id == arcId);
    if (idx == -1) return;

    final result = _generator.evaluateSeasonProgress(state.arcs[idx], input);
    final nextArcs = List<CareerStorylineArc>.from(state.arcs);
    nextArcs[idx] = result.updatedArc;

    state = state.copyWith(
      arcs: nextArcs,
      lastNotification: result.newsHeadline,
    );
  }
}

/// Globalny provider wieloletnich wątków fabularnych dla kariery własnej drużyny.
final customTeamSponsorStorylineProvider = StateNotifierProvider<
    CustomTeamSponsorStorylineNotifier, CustomTeamSponsorStorylineState>((ref) {
  return CustomTeamSponsorStorylineNotifier(
    initialContext: const StorylineGenerationContext(
      teamName: 'Veloce Orlen Pro Cycling',
      teamCountryCode: 'PL',
      sponsorName: 'Orlen Aero Tech',
      currentSeason: 2026,
      teamBudgetEur: 8500000,
    ),
  );
});

/// Produkcyjny, responsywny panel zarządzania wieloletnimi wątkami fabularnymi kariery.
class CustomTeamSponsorStorylinePanel extends StatefulWidget {
  final List<CareerStorylineArc> arcs;
  final int availableBudgetEur;
  final String? selectedArcId;
  final StorylineArchetype? filterArchetype;
  final String? statusMessage;
  final ValueChanged<String>? onSelectArc;
  final ValueChanged<StorylineArchetype?>? onFilterChanged;
  final void Function(String arcId, String optionId)? onDecisionSelected;
  final ValueChanged<String>? onEvaluateSeason;
  final VoidCallback? onGenerateNewArc;
  final bool enabled;

  const CustomTeamSponsorStorylinePanel({
    super.key,
    required this.arcs,
    required this.availableBudgetEur,
    this.selectedArcId,
    this.filterArchetype,
    this.statusMessage,
    this.onSelectArc,
    this.onFilterChanged,
    this.onDecisionSelected,
    this.onEvaluateSeason,
    this.onGenerateNewArc,
    this.enabled = true,
  });

  @override
  State<CustomTeamSponsorStorylinePanel> createState() =>
      _CustomTeamSponsorStorylinePanelState();
}

class _CustomTeamSponsorStorylinePanelState
    extends State<CustomTeamSponsorStorylinePanel> {
  static const _generator = CustomTeamSponsorStorylineGenerator();

  String? _hoveredId;
  String? _focusedId;
  String? _pressedId;

  List<CareerStorylineArc> get _visibleArcs {
    if (widget.filterArchetype == null) return widget.arcs;
    return widget.arcs
        .where((arc) => arc.archetype == widget.filterArchetype)
        .toList();
  }

  CareerStorylineArc? get _activeArc {
    final list = _visibleArcs;
    if (list.isEmpty) return null;
    if (widget.selectedArcId == null) return list.first;
    return list.firstWhere(
      (a) => a.id == widget.selectedArcId,
      orElse: () => list.first,
    );
  }

  String _formatEur(int amount) {
    final abs = amount.abs();
    final sign = amount < 0 ? '-' : '';
    if (abs >= 1000000) {
      return '$sign${(abs / 1000000).toStringAsFixed(2)}M €';
    }
    if (abs >= 1000) {
      return '$sign${(abs / 1000).toStringAsFixed(0)}k €';
    }
    return '$sign$abs €';
  }

  @override
  Widget build(BuildContext context) {
    final summary = _generator.summarizeStorylines(widget.arcs);
    final selected = _activeArc;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 640;
          final isDesktop = constraints.maxWidth >= 1100;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isCompact ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(summary, isCompact),
                const SizedBox(height: 14),
                _buildFilterBar(isCompact),
                if (widget.statusMessage != null &&
                    widget.statusMessage!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildStatusBanner(widget.statusMessage!),
                ],
                const SizedBox(height: 16),
                if (_visibleArcs.isEmpty)
                  _buildEmptyState()
                else if (isDesktop && selected != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 380,
                        child: _buildArcList(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildArcDetailCard(selected, isCompact: false),
                      ),
                    ],
                  )
                else ...[
                  _buildArcList(),
                  if (selected != null) ...[
                    const SizedBox(height: 16),
                    _buildArcDetailCard(selected, isCompact: isCompact),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(CareerStorylineSummary summary, bool isCompact) {
    final titleRow = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.goldAccent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.goldAccent.withValues(alpha: 0.45),
            ),
          ),
          child: const Icon(
            Icons.auto_stories_rounded,
            color: AppColors.goldAccent,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Wieloletnie Wątki Fabularne Kariery',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Ranga Dynastii: ${summary.dynastyTierLabel} (${summary.totalDynastyPoints} pkt)',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.goldAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final actionButton = _buildActionButton(
      id: 'btn_generate_arc',
      label: 'Nowy Wątek',
      icon: Icons.add_circle_outline_rounded,
      accent: AppColors.primaryAccent,
      enabled: widget.enabled && widget.onGenerateNewArc != null,
      onTap: widget.onGenerateNewArc,
    );

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCompact) ...[
            titleRow,
            const SizedBox(height: 12),
            actionButton,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: titleRow),
                const SizedBox(width: 12),
                actionButton,
              ],
            ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetricPill(
                'Aktywne',
                '${summary.activeCount}',
                AppColors.accentBlue,
              ),
              _buildMetricPill(
                'Ukończone',
                '${summary.completedCount}',
                AppColors.statusSuccess,
              ),
              _buildMetricPill(
                'Budżet Operacyjny',
                _formatEur(widget.availableBudgetEur),
                AppColors.goldAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isCompact) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            id: 'filter_all',
            label: 'Wszystkie (${widget.arcs.length})',
            selected: widget.filterArchetype == null,
            accent: AppColors.goldAccent,
            onTap: () => widget.onFilterChanged?.call(null),
          ),
          const SizedBox(width: 8),
          for (final archetype in StorylineArchetype.values) ...[
            _buildFilterChip(
              id: 'filter_${archetype.name}',
              label: archetype.shortTag,
              icon: archetype.icon,
              selected: widget.filterArchetype == archetype,
              accent: archetype.accentColor,
              onTap: () => widget.onFilterChanged?.call(archetype),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String id,
    required String label,
    IconData? icon,
    required bool selected,
    required Color accent,
    required VoidCallback? onTap,
  }) {
    final isHovered = _hoveredId == id;
    final isFocused = _focusedId == id;
    final isEnabled = widget.enabled && onTap != null;

    return FocusableActionDetector(
      enabled: isEnabled,
      onShowFocusHighlight: (focused) =>
          setState(() => _focusedId = focused ? id : null),
      onShowHoverHighlight: (hovered) =>
          setState(() => _hoveredId = hovered ? id : null),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.18)
                : (isHovered ? AppColors.surfaceLight : AppColors.surface),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFocused
                  ? AppColors.cyanAccent
                  : (selected ? accent : AppColors.cardBorder),
              width: isFocused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: selected ? accent : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.newspaper_rounded,
            size: 16,
            color: AppColors.accentBlue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 36,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 10),
          Text(
            'Brak wątków fabularnych dla wybranego filtra',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Zmień filtr lub wygeneruj nowy wieloletni wątek sponsorski.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArcList() {
    final selectedId = _activeArc?.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _visibleArcs.length; i++) ...[
          _buildArcSelectorCard(
            _visibleArcs[i],
            isSelected: _visibleArcs[i].id == selectedId,
          ),
          if (i + 1 < _visibleArcs.length) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildArcSelectorCard(
    CareerStorylineArc arc, {
    required bool isSelected,
  }) {
    final cardId = 'arc_${arc.id}';
    final isHovered = _hoveredId == cardId;
    final isFocused = _focusedId == cardId;
    final isPressed = _pressedId == cardId;
    final accent = arc.archetype.accentColor;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (focused) =>
          setState(() => _focusedId = focused ? cardId : null),
      onShowHoverHighlight: (hovered) =>
          setState(() => _hoveredId = hovered ? cardId : null),
      child: GestureDetector(
        onTapDown: (_) {
          if (widget.enabled) setState(() => _pressedId = cardId);
        },
        onTapUp: (_) => setState(() => _pressedId = null),
        onTapCancel: () => setState(() => _pressedId = null),
        onTap: widget.enabled ? () => widget.onSelectArc?.call(arc.id) : null,
        child: AnimatedScale(
          scale: isPressed ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.surfaceLight
                  : (isHovered
                      ? AppColors.surfaceLight.withValues(alpha: 0.7)
                      : AppColors.surface),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFocused
                    ? AppColors.cyanAccent
                    : (isSelected ? accent : AppColors.cardBorder),
                width: isSelected || isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(arc.archetype.icon, size: 16, color: accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        arc.archetype.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: arc.status.badgeColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        arc.status.label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: arc.status.badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  arc.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sezon ${arc.currentSeason} • Rozdział ${arc.currentChapterIndex + 1}/${arc.chapters.length}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: arc.completionRatio,
                    minHeight: 5,
                    backgroundColor: AppColors.background,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArcDetailCard(
    CareerStorylineArc arc, {
    required bool isCompact,
  }) {
    final chapter = arc.activeChapter;
    final accent = arc.archetype.accentColor;

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      arc.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      arc.subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetricPill('Sponsor', arc.sponsorName, AppColors.goldAccent),
              _buildMetricPill('Rywal / Cel', arc.rivalEntityName, accent),
              _buildMetricPill(
                'Napięcie',
                '${(arc.heatIntensity * 100).round()}%',
                AppColors.amberWarning,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildChapterStepper(arc, accent),
          if (chapter != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    chapter.headline,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    chapter.narrativeBody,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chapter.pressQuote,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '— ${chapter.pressSource}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.goldAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.flag_circle_outlined,
                        size: 16,
                        color: AppColors.statusSuccess,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Cel (${chapter.targetRaceName}): ${chapter.targetMilestone}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.statusSuccess,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Decyzje Strategiczne Zarządu',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            for (final option in chapter.options) ...[
              _buildDecisionOptionCard(arc, chapter, option),
              const SizedBox(height: 10),
            ],
            if (arc.status == StorylineStatus.active &&
                widget.onEvaluateSeason != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: _buildActionButton(
                  id: 'btn_eval_${arc.id}',
                  label: 'Rozlicz Cel Sezonowy',
                  icon: Icons.verified_outlined,
                  accent: AppColors.statusSuccess,
                  enabled: widget.enabled,
                  onTap: () => widget.onEvaluateSeason?.call(arc.id),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildChapterStepper(CareerStorylineArc arc, Color accent) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < arc.chapters.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: i == arc.currentChapterIndex
                  ? accent.withValues(alpha: 0.18)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: arc.chapters[i].isCompleted
                    ? AppColors.statusSuccess
                    : (arc.chapters[i].isFailed
                        ? AppColors.crimsonAlert
                        : (i == arc.currentChapterIndex
                            ? accent
                            : AppColors.cardBorder)),
              ),
            ),
            child: Text(
              'Rozdział ${i + 1} (${arc.seasonStart + arc.chapters[i].seasonYearOffset})',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: i == arc.currentChapterIndex
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDecisionOptionCard(
    CareerStorylineArc arc,
    StorylineChapter chapter,
    StorylineDecisionOption option,
  ) {
    final optionCardId = 'opt_${arc.id}_${option.id}';
    final isHovered = _hoveredId == optionCardId;
    final isFocused = _focusedId == optionCardId;
    final isPressed = _pressedId == optionCardId;
    final isAffordable = option.isAffordable(widget.availableBudgetEur);
    final isArcActive = arc.status == StorylineStatus.active && !chapter.isResolved;
    final canSelect = widget.enabled && isArcActive && isAffordable;
    final isChosen = chapter.selectedOptionId == option.id;

    return FocusableActionDetector(
      enabled: canSelect,
      onShowFocusHighlight: (focused) =>
          setState(() => _focusedId = focused ? optionCardId : null),
      onShowHoverHighlight: (hovered) =>
          setState(() => _hoveredId = hovered ? optionCardId : null),
      child: GestureDetector(
        onTapDown: (_) {
          if (canSelect) setState(() => _pressedId = optionCardId);
        },
        onTapUp: (_) => setState(() => _pressedId = null),
        onTapCancel: () => setState(() => _pressedId = null),
        onTap: canSelect
            ? () => widget.onDecisionSelected?.call(arc.id, option.id)
            : null,
        child: AnimatedScale(
          scale: isPressed ? 0.99 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isChosen
                  ? AppColors.statusSuccess.withValues(alpha: 0.14)
                  : (canSelect && isHovered
                      ? AppColors.surfaceLight
                      : AppColors.background),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isFocused
                    ? AppColors.cyanAccent
                    : (isChosen
                        ? AppColors.statusSuccess
                        : (!isAffordable
                            ? AppColors.crimsonAlert.withValues(alpha: 0.45)
                            : AppColors.cardBorder)),
                width: isFocused || isChosen ? 1.5 : 1.0,
              ),
            ),
            child: Opacity(
              opacity: (widget.enabled && isAffordable) ? 1.0 : 0.55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          option.title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          option.strategicTag,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.goldAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    option.description,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      if (option.requiresMinBudgetEur > 0)
                        Text(
                          'Koszt: ${_formatEur(option.requiresMinBudgetEur)}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isAffordable
                                ? AppColors.amberWarning
                                : AppColors.crimsonAlert,
                          ),
                        )
                      else if (option.effect.budgetDeltaEur > 0)
                        Text(
                          'Premia: +${_formatEur(option.effect.budgetDeltaEur)}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.statusSuccess,
                          ),
                        ),
                      Text(
                        'Prestiż: +${option.effect.prestigeDelta} • Dynastia: +${option.effect.dynastyPointsDelta} pkt',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.accentBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String id,
    required String label,
    required IconData icon,
    required Color accent,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    final isHovered = _hoveredId == id;
    final isFocused = _focusedId == id;
    final isPressed = _pressedId == id;

    return FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (focused) =>
          setState(() => _focusedId = focused ? id : null),
      onShowHoverHighlight: (hovered) =>
          setState(() => _hoveredId = hovered ? id : null),
      child: GestureDetector(
        onTapDown: (_) {
          if (enabled) setState(() => _pressedId = id);
        },
        onTapUp: (_) => setState(() => _pressedId = null),
        onTapCancel: () => setState(() => _pressedId = null),
        onTap: enabled ? onTap : null,
        child: AnimatedScale(
          scale: isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: enabled
                  ? (isHovered
                      ? accent.withValues(alpha: 0.28)
                      : accent.withValues(alpha: 0.18))
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFocused
                    ? AppColors.cyanAccent
                    : (enabled ? accent : AppColors.cardBorder),
                width: isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Opacity(
              opacity: enabled ? 1.0 : 0.45,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: enabled ? accent : AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
