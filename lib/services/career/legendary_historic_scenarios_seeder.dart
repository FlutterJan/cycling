import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/team/bike_manufacturer_deal.dart';
import '../../models/team/cycling_team.dart';
import '../generators/rider_procedural_generator.dart';

/// Poziom trudności Scenariusza Historycznego / Wyzwania Taktycznego.
enum HistoricScenarioDifficulty {
  veteran,
  legend,
  impossible;

  String toJson() => name;

  static HistoricScenarioDifficulty fromJson(String value) {
    return HistoricScenarioDifficulty.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => HistoricScenarioDifficulty.legend,
    );
  }

  String get label {
    switch (this) {
      case HistoricScenarioDifficulty.veteran:
        return 'Weteran';
      case HistoricScenarioDifficulty.legend:
        return 'Legenda';
      case HistoricScenarioDifficulty.impossible:
        return 'Hors Catégorie';
    }
  }

  Color get badgeColor {
    switch (this) {
      case HistoricScenarioDifficulty.veteran:
        return AppColors.statusSuccess;
      case HistoricScenarioDifficulty.legend:
        return AppColors.amberWarning;
      case HistoricScenarioDifficulty.impossible:
        return AppColors.crimsonAlert;
    }
  }
}

/// Kategoria taktyczna scenariusza historycznego.
enum HistoricScenarioCategory {
  mountainTimeTrial,
  crosswindAndCobbles,
  bonkDefense,
  flatTimeTrial,
  alpineStormRaid,
  echelonChase,
  gravelMonument,
  extremeWallClimb,
  sprintChaos,
  satelliteRelay;

  String toJson() => name;

  static HistoricScenarioCategory fromJson(String value) {
    return HistoricScenarioCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => HistoricScenarioCategory.mountainTimeTrial,
    );
  }

  String get label {
    switch (this) {
      case HistoricScenarioCategory.mountainTimeTrial:
        return 'Górska Czasówka';
      case HistoricScenarioCategory.crosswindAndCobbles:
        return 'Bruk i Wiatr';
      case HistoricScenarioCategory.bonkDefense:
        return 'Obrona w Kryzysie';
      case HistoricScenarioCategory.flatTimeTrial:
        return 'Czasówka Płaska';
      case HistoricScenarioCategory.alpineStormRaid:
        return 'Alpejski Rajd';
      case HistoricScenarioCategory.echelonChase:
        return 'Pogoń na Rantach';
      case HistoricScenarioCategory.gravelMonument:
        return 'Białe Szutry';
      case HistoricScenarioCategory.extremeWallClimb:
        return 'Ściana >20%';
      case HistoricScenarioCategory.sprintChaos:
        return 'Chaos Sprinterski';
      case HistoricScenarioCategory.satelliteRelay:
        return 'Stacja Przekaźnikowa';
    }
  }

  IconData get icon {
    switch (this) {
      case HistoricScenarioCategory.mountainTimeTrial:
      case HistoricScenarioCategory.flatTimeTrial:
        return Icons.timer_outlined;
      case HistoricScenarioCategory.crosswindAndCobbles:
      case HistoricScenarioCategory.echelonChase:
        return Icons.air_rounded;
      case HistoricScenarioCategory.bonkDefense:
        return Icons.battery_alert_rounded;
      case HistoricScenarioCategory.alpineStormRaid:
      case HistoricScenarioCategory.extremeWallClimb:
        return Icons.terrain_rounded;
      case HistoricScenarioCategory.gravelMonument:
        return Icons.landscape_rounded;
      case HistoricScenarioCategory.sprintChaos:
        return Icons.bolt_rounded;
      case HistoricScenarioCategory.satelliteRelay:
        return Icons.hub_outlined;
    }
  }
}

/// Typ warunku zwycięstwa w scenariuszu taktycznym.
enum ScenarioVictoryConditionType {
  winStage,
  gainTimeSeconds,
  defendJerseyWithGap,
  finishTopN,
  surviveBelowTimeLoss;

  String toJson() => name;

  static ScenarioVictoryConditionType fromJson(String value) {
    return ScenarioVictoryConditionType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ScenarioVictoryConditionType.winStage,
    );
  }
}

/// Medal przyznawany po ukończeniu scenariusza.
enum ScenarioMedalTier {
  none,
  bronze,
  silver,
  gold;

  String get label {
    switch (this) {
      case ScenarioMedalTier.none:
        return 'Nieukończono';
      case ScenarioMedalTier.bronze:
        return 'Brązowy Medal';
      case ScenarioMedalTier.silver:
        return 'Srebrny Medal';
      case ScenarioMedalTier.gold:
        return 'Złoty Medal (Legenda)';
    }
  }

  Color get color {
    switch (this) {
      case ScenarioMedalTier.none:
        return AppColors.textSecondary;
      case ScenarioMedalTier.bronze:
        return const Color(0xFFCD7F32);
      case ScenarioMedalTier.silver:
        return const Color(0xFFC0C0C0);
      case ScenarioMedalTier.gold:
        return AppColors.goldAccent;
    }
  }
}

/// Początkowy stan fizjologiczny i czasowy pojedynczego kolarza w scenariuszu.
class ScenarioInitialRiderCondition {
  final String riderId;
  final String displayName;
  final String roleLabel;
  final double startingGlycogenFraction;
  final double startingWPrimeFraction;
  final double startingFatigueFraction;
  final int startingTimeGapSeconds;
  final bool startsInBreakaway;

  const ScenarioInitialRiderCondition({
    required this.riderId,
    required this.displayName,
    required this.roleLabel,
    this.startingGlycogenFraction = 0.85,
    this.startingWPrimeFraction = 1.0,
    this.startingFatigueFraction = 0.25,
    this.startingTimeGapSeconds = 0,
    this.startsInBreakaway = false,
  });

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'displayName': displayName,
        'roleLabel': roleLabel,
        'startingGlycogenFraction': startingGlycogenFraction,
        'startingWPrimeFraction': startingWPrimeFraction,
        'startingFatigueFraction': startingFatigueFraction,
        'startingTimeGapSeconds': startingTimeGapSeconds,
        'startsInBreakaway': startsInBreakaway,
      };

  factory ScenarioInitialRiderCondition.fromJson(Map<String, dynamic> json) {
    return ScenarioInitialRiderCondition(
      riderId: json['riderId'] as String,
      displayName: json['displayName'] as String,
      roleLabel: json['roleLabel'] as String,
      startingGlycogenFraction:
          (json['startingGlycogenFraction'] as num).toDouble(),
      startingWPrimeFraction:
          (json['startingWPrimeFraction'] as num).toDouble(),
      startingFatigueFraction:
          (json['startingFatigueFraction'] as num).toDouble(),
      startingTimeGapSeconds: json['startingTimeGapSeconds'] as int,
      startsInBreakaway: json['startsInBreakaway'] as bool? ?? false,
    );
  }
}

/// Pojedynczy cel taktyczny (główny lub poboczny) w scenariuszu.
class HistoricScenarioObjective {
  final String id;
  final String title;
  final String description;
  final ScenarioVictoryConditionType conditionType;
  final int targetValue;
  final bool isPrimary;

  const HistoricScenarioObjective({
    required this.id,
    required this.title,
    required this.description,
    required this.conditionType,
    required this.targetValue,
    this.isPrimary = true,
  });

  /// Ewaluuje czy cel został spełniony na podstawie wyniku symulacji.
  bool isSatisfied(ScenarioSimulationResult result) {
    switch (conditionType) {
      case ScenarioVictoryConditionType.winStage:
        return result.leaderStageRank == 1;
      case ScenarioVictoryConditionType.gainTimeSeconds:
        return result.timeGainedOverRivalSeconds >= targetValue;
      case ScenarioVictoryConditionType.defendJerseyWithGap:
        return result.finalGcMarginSeconds >= targetValue;
      case ScenarioVictoryConditionType.finishTopN:
        return result.leaderStageRank > 0 &&
            result.leaderStageRank <= targetValue;
      case ScenarioVictoryConditionType.surviveBelowTimeLoss:
        return result.leaderTimeLossSeconds <= targetValue;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'conditionType': conditionType.toJson(),
        'targetValue': targetValue,
        'isPrimary': isPrimary,
      };

  factory HistoricScenarioObjective.fromJson(Map<String, dynamic> json) {
    return HistoricScenarioObjective(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      conditionType: ScenarioVictoryConditionType.fromJson(
        json['conditionType'] as String,
      ),
      targetValue: json['targetValue'] as int,
      isPrimary: json['isPrimary'] as bool? ?? true,
    );
  }
}

/// Wynik rozegranego scenariusza przekazany z silnika symulacji wyścigu.
class ScenarioSimulationResult {
  final String scenarioId;
  final int leaderStageRank;
  final int timeGainedOverRivalSeconds;
  final int finalGcMarginSeconds;
  final int leaderTimeLossSeconds;
  final int remainingDomestiquesCount;
  final bool leaderBonked;

  const ScenarioSimulationResult({
    required this.scenarioId,
    required this.leaderStageRank,
    required this.timeGainedOverRivalSeconds,
    required this.finalGcMarginSeconds,
    required this.leaderTimeLossSeconds,
    required this.remainingDomestiquesCount,
    this.leaderBonked = false,
  });
}

/// Ocena końcowa scenariusza po mecie.
class ScenarioEvaluationOutcome {
  final String scenarioId;
  final bool isSuccess;
  final ScenarioMedalTier medal;
  final List<String> completedObjectiveIds;
  final List<String> failedObjectiveIds;
  final int scorePoints;
  final String summaryText;

  const ScenarioEvaluationOutcome({
    required this.scenarioId,
    required this.isSuccess,
    required this.medal,
    required this.completedObjectiveIds,
    required this.failedObjectiveIds,
    required this.scorePoints,
    required this.summaryText,
  });
}

/// Pełna definicja pojedynczego Scenariusza Historycznego / Wyzwania Taktycznego.
class HistoricScenarioDefinition {
  final String id;
  final String code;
  final String title;
  final String subtitle;
  final String historicalInspiration;
  final String yearLabel;
  final HistoricScenarioDifficulty difficulty;
  final HistoricScenarioCategory category;
  final String briefingStory;
  final String tacticalHint;
  final double startKm;
  final double totalDistanceKm;
  final int initialTimeGapSeconds;
  final WeatherCondition weatherCondition;
  final double windSpeedKmh;
  final double temperatureCelsius;
  final int availableDomestiquesCount;
  final List<HistoricScenarioObjective> objectives;
  final List<ScenarioInitialRiderCondition> initialConditions;

  const HistoricScenarioDefinition({
    required this.id,
    required this.code,
    required this.title,
    required this.subtitle,
    required this.historicalInspiration,
    required this.yearLabel,
    required this.difficulty,
    required this.category,
    required this.briefingStory,
    required this.tacticalHint,
    required this.startKm,
    required this.totalDistanceKm,
    required this.initialTimeGapSeconds,
    required this.weatherCondition,
    required this.windSpeedKmh,
    required this.temperatureCelsius,
    required this.availableDomestiquesCount,
    required this.objectives,
    required this.initialConditions,
  });

  double get playableDistanceKm =>
      math.max(1.0, totalDistanceKm - startKm);

  String get formattedGapLabel {
    if (initialTimeGapSeconds == 0) return '0:00 (Równy czas)';
    final absSec = initialTimeGapSeconds.abs();
    final min = absSec ~/ 60;
    final sec = absSec % 60;
    final formatted = '$min:${sec.toString().padLeft(2, '0')}';
    return initialTimeGapSeconds > 0
        ? '+$formatted straty'
        : '-$formatted przewagi';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'title': title,
        'subtitle': subtitle,
        'historicalInspiration': historicalInspiration,
        'yearLabel': yearLabel,
        'difficulty': difficulty.toJson(),
        'category': category.toJson(),
        'briefingStory': briefingStory,
        'tacticalHint': tacticalHint,
        'startKm': startKm,
        'totalDistanceKm': totalDistanceKm,
        'initialTimeGapSeconds': initialTimeGapSeconds,
        'weatherCondition': weatherCondition.toJson(),
        'windSpeedKmh': windSpeedKmh,
        'temperatureCelsius': temperatureCelsius,
        'availableDomestiquesCount': availableDomestiquesCount,
        'objectives': objectives.map((o) => o.toJson()).toList(),
        'initialConditions': initialConditions.map((c) => c.toJson()).toList(),
      };

  factory HistoricScenarioDefinition.fromJson(Map<String, dynamic> json) {
    return HistoricScenarioDefinition(
      id: json['id'] as String,
      code: json['code'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      historicalInspiration: json['historicalInspiration'] as String,
      yearLabel: json['yearLabel'] as String,
      difficulty: HistoricScenarioDifficulty.fromJson(
        json['difficulty'] as String,
      ),
      category: HistoricScenarioCategory.fromJson(
        json['category'] as String,
      ),
      briefingStory: json['briefingStory'] as String,
      tacticalHint: json['tacticalHint'] as String,
      startKm: (json['startKm'] as num).toDouble(),
      totalDistanceKm: (json['totalDistanceKm'] as num).toDouble(),
      initialTimeGapSeconds: json['initialTimeGapSeconds'] as int,
      weatherCondition: WeatherCondition.fromJson(
        json['weatherCondition'] as String,
      ),
      windSpeedKmh: (json['windSpeedKmh'] as num).toDouble(),
      temperatureCelsius: (json['temperatureCelsius'] as num).toDouble(),
      availableDomestiquesCount: json['availableDomestiquesCount'] as int,
      objectives: (json['objectives'] as List<dynamic>)
          .map((e) =>
              HistoricScenarioObjective.fromJson(e as Map<String, dynamic>))
          .toList(),
      initialConditions: (json['initialConditions'] as List<dynamic>)
          .map((e) => ScenarioInitialRiderCondition.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Gotowy, grywalny pakiet scenariusza do uruchomienia w silniku wyścigu 3D.
class PlayableHistoricScenarioBundle {
  final HistoricScenarioDefinition definition;
  final RaceStage stage;
  final CyclingTeam playerTeam;
  final List<Rider> playerRoster;
  final List<Rider> rivalLeaders;

  const PlayableHistoricScenarioBundle({
    required this.definition,
    required this.stage,
    required this.playerTeam,
    required this.playerRoster,
    required this.rivalLeaders,
  });

  /// Ewaluuje wynik symulacji wobec celów głównych i pobocznych scenariusza.
  ScenarioEvaluationOutcome evaluateOutcome(ScenarioSimulationResult result) {
    final completed = <String>[];
    final failed = <String>[];
    bool allPrimaryPassed = true;
    int secondaryPassedCount = 0;

    for (final obj in definition.objectives) {
      if (obj.isSatisfied(result)) {
        completed.add(obj.id);
        if (!obj.isPrimary) secondaryPassedCount++;
      } else {
        failed.add(obj.id);
        if (obj.isPrimary) allPrimaryPassed = false;
      }
    }

    final ScenarioMedalTier medal;
    if (!allPrimaryPassed) {
      medal = ScenarioMedalTier.none;
    } else if (failed.isEmpty) {
      medal = ScenarioMedalTier.gold;
    } else if (secondaryPassedCount >= 1) {
      medal = ScenarioMedalTier.silver;
    } else {
      medal = ScenarioMedalTier.bronze;
    }

    final basePoints = switch (definition.difficulty) {
      HistoricScenarioDifficulty.veteran => 500,
      HistoricScenarioDifficulty.legend => 850,
      HistoricScenarioDifficulty.impossible => 1250,
    };
    final bonusPoints = secondaryPassedCount * 200;
    final score = allPrimaryPassed ? basePoints + bonusPoints : 0;

    final summary = allPrimaryPassed
        ? 'Wyzwanie "${definition.title}" zaliczone! Zdobyto ${medal.label} ($score pkt).'
        : 'Cel główny nie został osiągnięty. Przeanalizuj profil trasy i spróbuj innej taktyki.';

    return ScenarioEvaluationOutcome(
      scenarioId: definition.id,
      isSuccess: allPrimaryPassed,
      medal: medal,
      completedObjectiveIds: List<String>.unmodifiable(completed),
      failedObjectiveIds: List<String>.unmodifiable(failed),
      scorePoints: score,
      summaryText: summary,
    );
  }
}

/// Seeder 10 grywalnych Scenariuszy Historycznych i Wyzwań Taktycznych.
///
/// Każdy scenariusz generuje deterministycznie (na podstawie stałego seeda)
/// profil trasy `RaceStage` ze wszystkimi segmentami, drużynę gracza z
/// odpowiednią liczbą pomocników, rywali oraz początkowe stany fizjologiczne
/// (glikogen, W', zmęczenie, strata/przewaga czasowa).
class LegendaryHistoricScenariosSeeder {
  LegendaryHistoricScenariosSeeder._();

  /// Katalog wszystkich 10 grywalnych scenariuszy historycznych.
  static const List<HistoricScenarioDefinition> scenarios = [
    // 1. Górska czasówka — odrobienie 1:45 straty
    HistoricScenarioDefinition(
      id: 'hist_01_mountain_tt_comeback',
      code: 'HIST-01',
      title: 'Odrób 1:45 straty na ostatniej górskiej czasówce',
      subtitle: '36.2 km ITT • Finał na ścianie 8.5–20% • Zmiana roweru',
      historicalInspiration: 'La Planche des Belles Filles 2020',
      yearLabel: '2020',
      difficulty: HistoricScenarioDifficulty.impossible,
      category: HistoricScenarioCategory.mountainTimeTrial,
      briefingStory:
          'Przedostatni etap Wielkiego Touru. Tracisz 1:45 do lidera klasyfikacji '
          'generalnej. Pierwsze 30 km to szybki, pofałdowany dojazd pod stoki '
          'Wogezów, a finałowe 5.9 km to bezlitosna wspinaczka o nachyleniu do 20%.',
      tacticalHint:
          'Jedź na granicy LT2 przez płaską część na rowerze TT, zmień rower '
          'u podnóża podjazdu i rozładuj całe W\' na ostatnich 2 km.',
      startKm: 0.0,
      totalDistanceKm: 36.2,
      initialTimeGapSeconds: 105,
      weatherCondition: WeatherCondition.sunny,
      windSpeedKmh: 14.0,
      temperatureCelsius: 23.0,
      availableDomestiquesCount: 0,
      objectives: [
        HistoricScenarioObjective(
          id: 'obj_01_gap',
          title: 'Odrób minimum 1:46 do lidera GC',
          description: 'Przejmij żółtą koszulkę na mecie czasówki.',
          conditionType: ScenarioVictoryConditionType.gainTimeSeconds,
          targetValue: 106,
          isPrimary: true,
        ),
        HistoricScenarioObjective(
          id: 'obj_01_win',
          title: 'Wygraj etap ITT',
          description: 'Ustanów najlepszy czas dnia na szczycie.',
          conditionType: ScenarioVictoryConditionType.winStage,
          targetValue: 1,
          isPrimary: false,
        ),
      ],
      initialConditions: [
        ScenarioInitialRiderCondition(
          riderId: 'hist01_leader',
          displayName: 'Młody Pretendent GC',
          roleLabel: 'Lider ITT / Góral',
          startingGlycogenFraction: 0.92,
          startingWPrimeFraction: 1.0,
          startingFatigueFraction: 0.30,
          startingTimeGapSeconds: 105,
        ),
      ],
    ),

    // 2. Wiatr boczny i bruk z tylko 3 pomocnikami
    HistoricScenarioDefinition(
      id: 'hist_02_cobbles_crosswind_3_doms',
      code: 'HIST-02',
      title: 'Przetrwaj 50 km wiatru bocznego i bruku mając tylko 3 pomocników',
      subtitle: '50 km finału • Wiatr 58 km/h • 7 sektorów bruku 3★–5★',
      historicalInspiration: 'Flandria & Piekło Północy',
      yearLabel: '2016',
      difficulty: HistoricScenarioDifficulty.legend,
      category: HistoricScenarioCategory.crosswindAndCobbles,
      briefingStory:
          'Kraksa w pierwszej godzinie wyeliminowała połowę Twojej drużyny. '
          'Do mety pozostało 50 km przez otwarte poldery przy wietrze bocznym '
          '58 km/h i 7 sektorach mokrego bruku. Masz tylko 3 pomocników.',
      tacticalHint:
          'Utrzymuj lidera w top 12 peletonu przed każdym sektorem bruku. '
          'Poświęć dwóch pomocników do zamykania luk na rantach, trzeciego zachowaj na ostatnie 15 km.',
      startKm: 195.0,
      totalDistanceKm: 245.0,
      initialTimeGapSeconds: 0,
      weatherCondition: WeatherCondition.crosswindGale,
      windSpeedKmh: 58.0,
      temperatureCelsius: 11.0,
      availableDomestiquesCount: 3,
      objectives: [
        HistoricScenarioObjective(
          id: 'obj_02_top5',
          title: 'Ukończ w Top 5 klasyku',
          description: 'Dowieź lidera w czołowej piątce na welodrom.',
          conditionType: ScenarioVictoryConditionType.finishTopN,
          targetValue: 5,
          isPrimary: true,
        ),
        HistoricScenarioObjective(
          id: 'obj_02_win',
          title: 'Zwycięstwo na welodromie',
          description: 'Wygraj sprint z wyselekcjonowanej grupy faworytów.',
          conditionType: ScenarioVictoryConditionType.winStage,
          targetValue: 1,
          isPrimary: false,
        ),
      ],
      initialConditions: [
        ScenarioInitialRiderCondition(
          riderId: 'hist02_leader',
          displayName: 'Lider Klasyków',
          roleLabel: 'Kapitan na Bruki',
          startingGlycogenFraction: 0.65,
          startingWPrimeFraction: 0.90,
          startingFatigueFraction: 0.42,
        ),
        ScenarioInitialRiderCondition(
          riderId: 'hist02_dom1',
          displayName: 'Flamandzki Diesel #1',
          roleLabel: 'Pomocnik Rantowy',
          startingGlycogenFraction: 0.60,
          startingWPrimeFraction: 0.85,
          startingFatigueFraction: 0.48,
        ),
        ScenarioInitialRiderCondition(
          riderId: 'hist02_dom2',
          displayName: 'Flamandzki Diesel #2',
          roleLabel: 'Pomocnik Brukowy',
          startingGlycogenFraction: 0.58,
          startingWPrimeFraction: 0.85,
          startingFatigueFraction: 0.50,
        ),
        ScenarioInitialRiderCondition(
          riderId: 'hist02_dom3',
          displayName: 'Ochroniarz Wiatrowy',
          roleLabel: 'Ochrona Lidera',
          startingGlycogenFraction: 0.62,
          startingWPrimeFraction: 0.88,
          startingFatigueFraction: 0.45,
        ),
      ],
    ),

    // 3. Obrona koszulki z odciętym liderem na 15 km podjazdu HC
    HistoricScenarioDefinition(
      id: 'hist_03_bonk_hc_defense',
      code: 'HIST-03',
      title:
          'Obrona koszulki lidera z odciętym od prądu liderem na ostatnich 15 km podjazdu HC',
      subtitle: '15 km podjazdu HC (8.4%) • Przewaga 0:55 • Glikogen lidera 9%',
      historicalInspiration: 'Col du Galibier / Peyresourde Crisis',
      yearLabel: '2017',
      difficulty: HistoricScenarioDifficulty.impossible,
      category: HistoricScenarioCategory.bonkDefense,
      briefingStory:
          'Twój lider przegapił bufet w dolinie i właśnie dopada go "odcięcie prądu" '
          '(glikogen spadł do 9%) na początku finałowego podjazdu HC (15 km @ 8.4%). '
          'Masz tylko 55 sekund przewagi w GC i dwóch wyczerpanych górali u boku.',
      tacticalHint:
          'Natychmiast wyślij pomocnika do wozu po żele węglowodanowe, ustaw stałe '
          'tempo poniżej progu LT1, by nie wypalić resztek glikogenu i broń przewagi do szczytu.',
      startKm: 162.0,
      totalDistanceKm: 177.0,
      initialTimeGapSeconds: -55,
      weatherCondition: WeatherCondition.extremeHeat,
      windSpeedKmh: 12.0,
      temperatureCelsius: 33.5,
      availableDomestiquesCount: 2,
      objectives: [
        HistoricScenarioObjective(
          id: 'obj_03_defend',
          title: 'Zachowaj koszulkę lidera (przewaga > 0 s)',
          description: 'Nie pozwól rywalowi odrobić więcej niż 54 sekundy.',
          conditionType: ScenarioVictoryConditionType.defendJerseyWithGap,
          targetValue: 1,
          isPrimary: true,
        ),
        HistoricScenarioObjective(
          id: 'obj_03_limit',
          title: 'Strata na etapie poniżej 35 s',
          description: 'Odbuduj glikogen żelami i ogranicz stratę pod szczytem.',
          conditionType: ScenarioVictoryConditionType.surviveBelowTimeLoss,
          targetValue: 35,
          isPrimary: false,
        ),
      ],
      initialConditions: [
        ScenarioInitialRiderCondition(
          riderId: 'hist03_leader',
          displayName: 'Żółta Koszulka (Kryzys)',
          roleLabel: 'Lider GC — Bonking',
          startingGlycogenFraction: 0.09,
          startingWPrimeFraction: 0.22,
          startingFatigueFraction: 0.78,
          startingTimeGapSeconds: -55,
        ),
        ScenarioInitialRiderCondition(
          riderId: 'hist03_dom1',
          displayName: 'Góral Ratownik #1',
          roleLabel: 'Pacing & Bidony',
          startingGlycogenFraction: 0.52,
          startingWPrimeFraction: 0.75,
          startingFatigueFraction: 0.55,
        ),
        ScenarioInitialRiderCondition(
          riderId: 'hist03_dom2',
          displayName: 'Góral Ratownik #2',
          roleLabel: 'Osłona Wiatrowa',
          startingGlycogenFraction: 0.48,
          startingWPrimeFraction: 0.70,
          startingFatigueFraction: 0.60,
        ),
      ],
    ),

    // 4. 8-sekundowy finał ITT w Paryżu
    HistoricScenarioDefinition(
      id: 'hist_04_paris_itt_8_seconds',
      code: 'HIST-04',
      title: 'Finałowa czasówka o 8 sekund na Polach Elizejskich',
      subtitle: '24.5 km ITT • Techniczne zakręty w deszczu • Strata 0:50',
      historicalInspiration: 'Paryż 1989 (58 s na 24.5 km)',
      yearLabel: '1989',
      difficulty: HistoricScenarioDifficulty.legend,
      category: HistoricScenarioCategory.flatTimeTrial,
      briefingStory:
          'Ostatni dzień Wielkiego Touru to wyjątkowo indywidualna jazda na czas '
          'do Paryża. Tracisz 50 sekund, ale masz najniższe CdA w stawce i pełną '
          'dyspozycję dnia. Mokry bruk na zakrętach wymaga precyzyjnego hamowania.',
      tacticalHint:
          'Użyj pełnego sprzętu aero (dysk + 80 mm przód) i utrzymaj 106% FTP na długich prostych.',
      startKm: 0.0,
      totalDistanceKm: 24.5,
      initialTimeGapSeconds: 50,
      weatherCondition: WeatherCondition.lightRain,
      windSpeedKmh: 22.0,
      temperatureCelsius: 17.0,
      availableDomestiquesCount: 0,
      objectives: [
        HistoricScenarioObjective(
          id: 'obj_04_gap',
          title: 'Odrób min. 51 sekund i wygraj Tour',
          description: 'Przebij granicę 50 s straty na mecie przy Łuku Triumfalnym.',
          conditionType: ScenarioVictoryConditionType.gainTimeSeconds,
          targetValue: 51,
          isPrimary: true,
        ),
        HistoricScenarioObjective(
          id: 'obj_04_win',
          title: 'Zwycięstwo etapowe w Paryżu',
          description: 'Zajmij 1. miejsce na finałowym odcinku ITT.',
          conditionType: ScenarioVictoryConditionType.winStage,
          targetValue: 1,
          isPrimary: false,
        ),
      ],
      initialConditions: [
        ScenarioInitialRiderCondition(
          riderId: 'hist04_leader',
          displayName: 'Specjalista Aero ITT',
          roleLabel: 'Lider GC / Czasowiec',
          startingGlycogenFraction: 0.95,
          startingWPrimeFraction: 1.0,
          startingFatigueFraction: 0.35,
          startingTimeGapSeconds: 50,
        ),
      ],
    ),

    // 5. Samotny rajd 80 km przez Alpy w śnieżycy
    HistoricScenarioDefinition(
      id: 'hist_05_gavia_snow_raid',
      code: 'HIST-05',
      title: 'Samotny rajd 80 km przez Alpy w lodowatym deszczu',
      subtitle: '80 km • 2 przełęcze >2100 m n.p.m. • Temp. 2°C na szczytach',
      historicalInspiration: 'Passo Gavia 1988 / Colle delle Finestre 2018',
      yearLabel: '2018',
      difficulty: HistoricScenarioDifficulty.impossible,
      category: HistoricScenarioCategory.alpineStormRaid,
      briefingStory:
          'Tracisz 2:40 w klasyfikacji generalnej przed najcięższym górskim etapem. '
          'Zamiast czekać na finałowy podjazd, Twoja drużyna dyktuje mordercze tempo '
          'od podnóża przedostatniej przełęczy w temperaturze 2°C.',
      tacticalHint:
          'Załóż peleryny przeciwdeszczowe na zjeździe z 2600 m n.p.m., aby uniknąć '
          'wychłodzenia i skurczów mięśni przed finałową wspinaczką.',
      startKm: 105.0,
      totalDistanceKm: 185.0,
      initialTimeGapSeconds: 160,
      weatherCondition: WeatherCondition.heavyStorm,
      windSpeedKmh: 28.0,
      temperatureCelsius: 4.5,
      availableDomestiquesCount: 4,
      objectives: [
        HistoricScenarioObjective(
          id: 'obj_05_win',
          title: 'Wygraj etap po samotnym ataku',
          description: 'Przekrocz linię mety na 1. miejscu.',
          conditionType: ScenarioVictoryConditionType.winStage,
          targetValue: 1,
          isPrimary: true,
        ),
        HistoricScenarioObjective(
          id: 'obj_05_gap',
          title: 'Odrób pełne 2:40 (160 s) w GC',
          description: 'Zostaw lidera GC daleko za sobą na wysokich przełęczach.',
          conditionType: ScenarioVictoryConditionType.gainTimeSeconds,
          targetValue: 161,
          isPrimary: false,
        ),
      ],
      initialConditions: [
        ScenarioInitialRiderCondition(
          riderId: 'hist05_leader',
          displayName: 'Nieustraszony Góral',
          roleLabel: 'Lider Ataku',
          startingGlycogenFraction: 0.88,
          startingWPrimeFraction: 0.98,
          startingFatigueFraction: 0.30,
          startingTimeGapSeconds: 160,
        ),
        ScenarioInitialRiderCondition(
          riderId: 'hist05_dom1',
          displayName: 'Góral Tempo #1',
          roleLabel: 'Pociąg Górski',
          startingGlycogenFraction: 0.82,
          startingWPrimeFraction: 0.90,
          startingFatigueFraction: 0.35,
        ),
        ScenarioInitialRiderCondition(
          riderId: 'hist05_dom2',
          displayName: 'Góral Tempo #2',
          roleLabel: 'Pociąg Górski',
          startingGlycogenFraction: 0.82,
          startingWPrimeFraction: 0.90,
          startingFatigueFraction: 0.35,
        ),
        ScenarioInitialRiderCondition(
          riderId: 'hist05_dom3',
          displayName: 'Góral Tempo #3',
          roleLabel: 'Pociąg Górski',
          startingGlycogenFraction: 0.82,
          startingWPrimeFraction: 0.90,
          startingFatigueFraction: 0.35,
        ),
        ScenarioInitialRiderCondition(
          riderId: 'hist05_dom4',
          displayName: 'Góral Tempo #4',
          roleLabel: 'Pociąg Górski',
          startingGlycogenFraction: 0.82,
          startingWPrimeFraction: 0.90,
          startingFatigueFraction: 0.35,
        ),
      ],
    ),

    // 6. Pogoń w 2. rancie na hiszpańskiej równinie
    HistoricScenarioDefinition(
      id: 'hist_06_echelon_chase_65km',
      code: 'HIST-06',
      title: 'Złapany w drugim rancie — Pogoń 65 km po otwartej równinie',
      subtitle: '65 km płaskiego • Wiatr boczny 52 km/h • Strata 1:15 do 1. rantu',
      historicalInspiration: 'Wichury Kastylii i Doliny Rodanu',
      yearLabel: '2019',
      difficulty: HistoricScenarioDifficulty.veteran,
      category: HistoricScenarioCategory.echelonChase,
      briefingStory:
          'Chwila nieuwagi na rondzie i peleton pękł na 3 grupy. Twój lider GC '
          'został w 2. rancie ze stratą 1:15 do głównych rywali. Masz jednak '
          '5 mocnych pomocników gotowych do rotacji wachlarza.',
      tacticalHint:
          'Ustaw rotację 4 pomocników na 92% FTP i oszczędzaj lidera na kole, '
          'aż dołączysz do pierwszej grupy przed finałowym pagórkiem.',
      startKm: 110.0,
      totalDistanceKm: 175.0,
      initialTimeGapSeconds: 75,
      weatherCondition: WeatherCondition.crosswindGale,
      windSpeedKmh: 52.0,
      temperatureCelsius: 27.0,
      availableDomestiquesCount: 5,
      objectives: [
        HistoricScenarioObjective(
          id: 'obj_06_survive',
          title: 'Zredukuj stratę poniżej 20 sekund',
          description: 'Złap pierwszy rant lub zminimalizuj stratę na mecie.',
          conditionType: ScenarioVictoryConditionType.surviveBelowTimeLoss,
          targetValue: 20,
          isPrimary: true,
        ),
        HistoricScenarioObjective(
          id: 'obj_06_top10',
          title: 'Finiszuj w Top 10 etapu',
          description: 'Zakończ pogoń w czołowej grupie.',
          conditionType: ScenarioVictoryConditionType.finishTopN,
          targetValue: 10,
          isPrimary: false,
        ),
      ],
      initialConditions: [
        ScenarioInitialRiderCondition(
          riderId: 'hist06_leader',
          displayName: 'Lider GC w Rancie #2',
          roleLabel: 'Chroniony Lider',
          startingGlycogenFraction: 0.78,
          startingWPrimeFraction: 0.92,
          startingFatigueFraction: 0.34,
          startingTimeGapSeconds: 75,
        ),
        ScenarioInitialRiderCondition(
          riderId: 'hist06_dom1',
          displayName: 'Silnik Rantowy #1',
          roleLabel: 'Wachlarz Pościgowy',
          startingGlycogenFraction: 0.75,
          startingWPrimeFraction: 0.90,
          startingFatigueFraction: 0.36,
        ),
        ScenarioInitialRiderCondition(
          riderId: 'hist06_dom2',
          displayName: 'Silnik Rantowy #2',
          roleLabel: 'Wachlarz Pościgowy',
          startingGlycogenFraction: 0.75,
          startingWPrimeFraction: 0.90,
          startingFatigueFraction: 0.36,
        ),
        ScenarioInitialRiderCondition(
          riderId: 'hist06_dom3',
          displayName: 'Silnik Rantowy #3',
          roleLabel: 'Wachlarz Pościgowy',
          startingGlycogenFraction: 0.75,
          startingWPrimeFraction: 0.90,
          startingFatigueFraction: 0.36,
        ),
        ScenarioInitialRiderCondition(
          riderId: 'hist06_dom4',
          displayName: 'Silnik Rantowy #4',
          roleLabel: 'Wachlarz Pościgowy',
          startingGlycogenFraction: 0.75,
          startingWPrimeFraction: 0.90,
          startingFatigueFraction: 0.36,
        ),
        ScenarioInitialRiderCondition(
          riderId: 'hist06_dom5',
          displayName: 'Silnik Rantowy #5',
          roleLabel: 'Wachlarz Pościgowy',
          startingGlycogenFraction: 0.75,
          startingWPrimeFraction: 0.90,
          startingFatigueFraction: 0.36,
        ),
      ],
    ),

    // 7. Toskańskie białe szutry Strade Bianche
    HistoricScenarioDefinition(
      id: 'hist_07_toscan_gravel_sectors',
      code: 'HIST-07',
      title: 'Białe drogi Toskanii — Kontra na sektorze Monte Sante Marie',
      subtitle: '48 km finału • 4 sektory szutrowe do 18% • Upał 33°C',
      historicalInspiration: 'Strade Bianche Siena (Piazza del Campo)',
      yearLabel: '2024',
      difficulty: HistoricScenarioDifficulty.veteran,
      category: HistoricScenarioCategory.gravelMonument,
      briefingStory:
          'Kurz, upał 33°C i strome szutrowe ścianki wokół Sieny. Przed Tobą '
          'najtrudniejszy sektor Monte Sante Marie (11.5 km), a na końcu '
          'brukowany podjazd Via Santa Caterina (16%) na Piazza del Campo.',
      tacticalHint:
          'Pobierz lód na kark przed sektorem szutrowym i zaatakuj na najbardziej '
          'stromym odcinku Monte Sante Marie, zanim rywale zdążą zareagować.',
      startKm: 167.0,
      totalDistanceKm: 215.0,
      initialTimeGapSeconds: 0,
      weatherCondition: WeatherCondition.extremeHeat,
      windSpeedKmh: 16.0,
      temperatureCelsius: 33.0,
      availableDomestiquesCount: 3,
      objectives: [
        HistoricScenarioObjective(
          id: 'obj_07_win',
          title: 'Wygraj na Piazza del Campo',
          description: 'Zdobądź szutrowy klasyk w Sienie.',
          conditionType: ScenarioVictoryConditionType.winStage,
          targetValue: 1,
          isPrimary: true,
        ),
        HistoricScenarioObjective(
          id: 'obj_07_top3',
          title: 'Podium klasyku',
          description: 'Ukończ w pierwszej trójce mimo upału.',
          conditionType: ScenarioVictoryConditionType.finishTopN,
          targetValue: 3,
          isPrimary: false,
        ),
      ],
      initialConditions: [
        ScenarioInitialRiderCondition(
          riderId: 'hist07_leader',
          displayName: 'Puncher Szutrowy',
          roleLabel: 'Lider Klasyku',
          startingGlycogenFraction: 0.72,
          startingWPrimeFraction: 0.94,
          startingFatigueFraction: 0.38,
        ),
        ScenarioInitialRiderCondition(
          riderId: 'hist07_dom1',
          displayName: 'Pomocnik Toskański #1',
          roleLabel: 'Wsparcie Szutrowe',
          startingGlycogenFraction: 0.68,
          startingWPrimeFraction: 0.85,
          startingFatigueFraction: 0.42,
        ),
        ScenarioInitialRiderCondition(
          riderId: 'hist07_dom2',
          displayName: 'Pomocnik Toskański #2',
          roleLabel: 'Wsparcie Szutrowe',
          startingGlycogenFraction: 0.68,
          startingWPrimeFraction: 0.85,
          startingFatigueFraction: 0.42,
        ),
        ScenarioInitialRiderCondition(
          riderId: 'hist07_dom3',
          displayName: 'Pomocnik Toskański #3',
          roleLabel: 'Wsparcie Szutrowe',
          startingGlycogenFraction: 0.68,
          startingWPrimeFraction: 0.85,
          startingFatigueFraction: 0.42,
        ),
      ],
    ),

    // 8. Ściana Cueña les Cabres na Alto de l'Angliru
    HistoricScenarioDefinition(
      id: 'hist_08_angliru_wall_23pct',
      code: 'HIST-08',
      title: 'Piekło Asturii — Walka na 23.5% ściance Alto de l\'Angliru',
      subtitle: '18 km finału • Rampy 18–23.5% • Mgła i mokry asfalt',
      historicalInspiration: 'Alto de l\'Angliru (Cueña les Cabres)',
      yearLabel: '2023',
      difficulty: HistoricScenarioDifficulty.legend,
      category: HistoricScenarioCategory.extremeWallClimb,
      briefingStory:
          'Ostatnie 18 km etapu w Asturii. Po zjeździe z Cordal wjeżdżacie na '
          'mordercze Angliru. Na Cueña les Cabres nachylenie sięga 23.5%, a dwóch '
          'rywali z jednej drużyny próbuje Cię zgubić na zmianę.',
      tacticalHint:
          'Nie odpowiadaj na pierwsze szarpnięcie — jedź własnym rytmem przy '
          'optymalnej kadencji i wykorzystaj ostatnie 2 km na kontratak.',
      startKm: 106.0,
      totalDistanceKm: 124.0,
      initialTimeGapSeconds: 12,
      weatherCondition: WeatherCondition.lightRain,
      windSpeedKmh: 14.0,
      temperatureCelsius: 13.0,
      availableDomestiquesCount: 2,
      objectives: [
        HistoricScenarioObjective(
          id: 'obj_08_gain',
          title: 'Zdobądź koszulkę lidera (odrób >12 s)',
          description: 'Zyskaj minimum 13 sekund nad rywalem na szczycie.',
          conditionType: ScenarioVictoryConditionType.gainTimeSeconds,
          targetValue: 13,
          isPrimary: true,
        ),
        HistoricScenarioObjective(
          id: 'obj_08_win',
          title: 'Zwycięstwo na Angliru',
          description: 'Wygraj królewski etap w Asturii.',
          conditionType: ScenarioVictoryConditionType.winStage,
          targetValue: 1,
          isPrimary: false,
        ),
      ],
      initialConditions: [
        ScenarioInitialRiderCondition(
          riderId: 'hist08_leader',
          displayName: 'Lekki Góral GC',
          roleLabel: 'Lider Wspinaczki',
          startingGlycogenFraction: 0.74,
          startingWPrimeFraction: 0.90,
          startingFatigueFraction: 0.44,
          startingTimeGapSeconds: 12,
        ),
        ScenarioInitialRiderCondition(
          riderId: 'hist08_dom1',
          displayName: 'Wspinacz Pomocnik #1',
          roleLabel: 'Tempo Podnóże',
          startingGlycogenFraction: 0.66,
          startingWPrimeFraction: 0.80,
          startingFatigueFraction: 0.48,
        ),
        ScenarioInitialRiderCondition(
          riderId: 'hist08_dom2',
          displayName: 'Wspinacz Pomocnik #2',
          roleLabel: 'Ostatnie Koło',
          startingGlycogenFraction: 0.64,
          startingWPrimeFraction: 0.80,
          startingFatigueFraction: 0.50,
        ),
      ],
    ),

    // 9. Chaos sprinterski bez głównego rozprowadzającego
    HistoricScenarioDefinition(
      id: 'hist_09_sprint_without_leadout',
      code: 'HIST-09',
      title: 'Finisz na 74 km/h bez ostatniego rozprowadzającego',
      subtitle: '22 km płaskiego • Kraksa na rondzie • Zaimprowizuj pociąg',
      historicalInspiration: 'Wielkie Sprinty w Bordeaux i Châteauroux',
      yearLabel: '2021',
      difficulty: HistoricScenarioDifficulty.veteran,
      category: HistoricScenarioCategory.sprintChaos,
      briefingStory:
          'Na 22 km przed metą kraksa wykluczyła Twojego etatowego rozprowadzającego. '
          'Twój sprinter został tylko z dwoma pomocnikami na wietrznej prostej '
          'przeciwko kompletnemu pociągowi rywali.',
      tacticalHint:
          'Zamiast ciągnąć od 5 km, ustaw sprintera na kole pociągu rywala ("Sit On") '
          'i użyj procy aerodynamicznej na ostatnich 220 metrach.',
      startKm: 168.0,
      totalDistanceKm: 190.0,
      initialTimeGapSeconds: 0,
      weatherCondition: WeatherCondition.sunny,
      windSpeedKmh: 24.0,
      temperatureCelsius: 26.0,
      availableDomestiquesCount: 2,
      objectives: [
        HistoricScenarioObjective(
          id: 'obj_09_win',
          title: 'Wygraj sprint masowy',
          description: 'Przekrocz kreskę jako pierwszy dzięki slingshotowi.',
          conditionType: ScenarioVictoryConditionType.winStage,
          targetValue: 1,
          isPrimary: true,
        ),
        HistoricScenarioObjective(
          id: 'obj_09_top3',
          title: 'Pewne podium sprinterskie',
          description: 'Zajmij miejsce w Top 3 i obronę punktacji zielonej.',
          conditionType: ScenarioVictoryConditionType.finishTopN,
          targetValue: 3,
          isPrimary: false,
        ),
      ],
      initialConditions: [
        ScenarioInitialRiderCondition(
          riderId: 'hist09_sprinter',
          displayName: 'Błyskawica Peletonu',
          roleLabel: 'Czysty Sprinter',
          startingGlycogenFraction: 0.84,
          startingWPrimeFraction: 1.0,
          startingFatigueFraction: 0.28,
        ),
        ScenarioInitialRiderCondition(
          riderId: 'hist09_dom1',
          displayName: 'Silnik Płaski #1',
          roleLabel: 'Pozycjonowanie 5 km',
          startingGlycogenFraction: 0.72,
          startingWPrimeFraction: 0.88,
          startingFatigueFraction: 0.35,
        ),
        ScenarioInitialRiderCondition(
          riderId: 'hist09_dom2',
          displayName: 'Silnik Płaski #2',
          roleLabel: 'Awaryjny Lead-Out',
          startingGlycogenFraction: 0.74,
          startingWPrimeFraction: 0.90,
          startingFatigueFraction: 0.34,
        ),
      ],
    ),

    // 10. Taktyka Stacji Przekaźnikowej na Col du Galibier
    HistoricScenarioDefinition(
      id: 'hist_10_galibier_satellite_relay',
      code: 'HIST-10',
      title: 'Zasadzka Stacji Przekaźnikowej na Col du Galibier',
      subtitle: '62 km finału • Pomocnik w ucieczce +3:30 • Finał na Granon',
      historicalInspiration: 'Col du Galibier & Col du Granon 2022',
      yearLabel: '2022',
      difficulty: HistoricScenarioDifficulty.legend,
      category: HistoricScenarioCategory.satelliteRelay,
      briefingStory:
          'W porannej ucieczce 3:30 przed peletonem jedzie Twój mocny pomocnik. '
          'Na przedostatniej przełęczy Col du Galibier (2642 m n.p.m.) atakujesz '
          'liderem GC, aby w dolinie połączyć siły ze "stacją przekaźnikową".',
      tacticalHint:
          'Wstrzymaj satelitę na zjeździe z Galibier ("Wait for GC Leader"), '
          'wykorzystaj go w wietrznej dolinie i odpal finalny atak na Col du Granon.',
      startKm: 90.0,
      totalDistanceKm: 152.0,
      initialTimeGapSeconds: 45,
      weatherCondition: WeatherCondition.overcast,
      windSpeedKmh: 26.0,
      temperatureCelsius: 19.0,
      availableDomestiquesCount: 3,
      objectives: [
        HistoricScenarioObjective(
          id: 'obj_10_gap',
          title: 'Odrób minimum 1:00 (60 s) do lidera GC',
          description: 'Wykorzystaj stację przekaźnikową do zyskania minuty.',
          conditionType: ScenarioVictoryConditionType.gainTimeSeconds,
          targetValue: 60,
          isPrimary: true,
        ),
        HistoricScenarioObjective(
          id: 'obj_10_win',
          title: 'Wygraj królewski etap alpejski',
          description: 'Zamelduj się samotnie na szczycie Col du Granon.',
          conditionType: ScenarioVictoryConditionType.winStage,
          targetValue: 1,
          isPrimary: false,
        ),
      ],
      initialConditions: [
        ScenarioInitialRiderCondition(
          riderId: 'hist10_leader',
          displayName: 'Góral Strateg',
          roleLabel: 'Lider GC',
          startingGlycogenFraction: 0.80,
          startingWPrimeFraction: 0.96,
          startingFatigueFraction: 0.32,
          startingTimeGapSeconds: 45,
        ),
        ScenarioInitialRiderCondition(
          riderId: 'hist10_satellite',
          displayName: 'Stacja Przekaźnikowa',
          roleLabel: 'Pomocnik w Ucieczce (+3:30)',
          startingGlycogenFraction: 0.72,
          startingWPrimeFraction: 0.85,
          startingFatigueFraction: 0.40,
          startsInBreakaway: true,
        ),
        ScenarioInitialRiderCondition(
          riderId: 'hist10_dom1',
          displayName: 'Góral Wsparcia #1',
          roleLabel: 'Rozprowadzenie Galibier',
          startingGlycogenFraction: 0.76,
          startingWPrimeFraction: 0.88,
          startingFatigueFraction: 0.36,
        ),
        ScenarioInitialRiderCondition(
          riderId: 'hist10_dom2',
          displayName: 'Góral Wsparcia #2',
          roleLabel: 'Ochrona w Peletonie',
          startingGlycogenFraction: 0.78,
          startingWPrimeFraction: 0.90,
          startingFatigueFraction: 0.34,
        ),
      ],
    ),
  ];

  /// Zwraca definicję scenariusza po ID lub null, jeśli nie istnieje.
  static HistoricScenarioDefinition? findById(String id) {
    for (final s in scenarios) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Buduje kompletny, grywalny pakiet scenariusza (trasa + skład + rywale)
  /// gotowy do przekazania do `StageSimulationLoop`.
  static PlayableHistoricScenarioBundle buildPlayableScenario(
    String scenarioId, {
    int? seedOffset,
  }) {
    final def = findById(scenarioId);
    if (def == null) {
      throw ArgumentError.value(
        scenarioId,
        'scenarioId',
        'Nieznany scenariusz historyczny.',
      );
    }

    final baseSeed = _stableSeedFromId(def.id) + (seedOffset ?? 0);
    final rng = math.Random(baseSeed);

    final stage = _buildStageForScenario(def);
    const teamId = 'scenario_player_team';

    final playerRoster = _buildPlayerRoster(def, teamId, rng);
    final rivalLeaders = _buildRivalLeaders(def, rng);

    final playerTeam = CyclingTeam(
      id: teamId,
      name: 'Historic Challenge Squad (${def.code})',
      division: TeamDivision.worldTour,
      countryIso: 'POL',
      primaryJerseyColorHex: '#8E4A49',
      secondaryJerseyColorHex: '#D4AF37',
      accentJerseyColorHex: '#0F1115',
      cashBalanceEur: 25000000,
      monthlyBurnRateEur: 1200000,
      uciPointsSeason: 9500,
      rosterRiderIds: playerRoster.map((r) => r.id).toList(),
      staff: const TeamStaff(
        trainersLevel: 86,
        sportsDirectorsLevel: 88,
        doctorsLevel: 85,
        mechanicsLevel: 90,
        scoutsLevel: 82,
      ),
      bikeDeal: const BikeManufacturerDeal(
        manufacturerId: 'historic_works',
        manufacturerName: 'Apex Works Carbon',
        prestigeLevel: 5,
        annualCashContributionEur: 1500000,
        freeBikesQuota: 90,
        researchAndDevelopmentLevel: 92,
        suppliedFrameIds: ['frame_aero_pro', 'frame_climb_sl'],
        suppliedWheelsetIds: ['wheel_50mm_carbon', 'wheel_ultralight'],
        contractYearsLeft: 2,
        minimumUciRankingRequired: 18,
      ),
      sponsors: const [],
      inventoryBikes: const [],
    );

    return PlayableHistoricScenarioBundle(
      definition: def,
      stage: stage,
      playerTeam: playerTeam,
      playerRoster: List<Rider>.unmodifiable(playerRoster),
      rivalLeaders: List<Rider>.unmodifiable(rivalLeaders),
    );
  }

  static int _stableSeedFromId(String id) {
    var hash = 2166136261;
    for (final codeUnit in id.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7FFFFFFF;
    }
    return hash;
  }

  static List<Rider> _buildPlayerRoster(
    HistoricScenarioDefinition def,
    String teamId,
    math.Random rng,
  ) {
    final riders = <Rider>[];
    for (int i = 0; i < def.initialConditions.length; i++) {
      final cond = def.initialConditions[i];
      final isLeader = i == 0;
      final spec = _specializationForScenario(def.category, isLeader);
      final targetOvr = isLeader ? 91 : 81;
      final role = isLeader ? RiderRole.teamLeader : RiderRole.domestique;

      final generated = RiderProceduralGenerator.generateRider(
        id: cond.riderId,
        specialization: spec,
        targetOverallRating: targetOvr,
        teamId: teamId,
        role: role,
        random: rng,
      );

      final nameParts = cond.displayName.split(' ');
      final firstName = nameParts.first;
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : def.code;

      final adjustedAtl = (generated.health.chronicTrainingLoad +
              (cond.startingFatigueFraction - 0.30) * 50.0)
          .clamp(15.0, 140.0);

      riders.add(
        generated.copyWith(
          firstName: firstName,
          lastName: lastName,
          health: generated.health.copyWith(
            acuteTrainingLoad: adjustedAtl,
          ),
        ),
      );
    }
    return riders;
  }

  static List<Rider> _buildRivalLeaders(
    HistoricScenarioDefinition def,
    math.Random rng,
  ) {
    final spec = _specializationForScenario(def.category, true);
    return [
      RiderProceduralGenerator.generateRider(
        id: '${def.id}_rival_1',
        specialization: spec,
        targetOverallRating: 90,
        teamId: 'scenario_rival_team_a',
        role: RiderRole.teamLeader,
        random: rng,
      ),
      RiderProceduralGenerator.generateRider(
        id: '${def.id}_rival_2',
        specialization: spec,
        targetOverallRating: 88,
        teamId: 'scenario_rival_team_b',
        role: RiderRole.teamLeader,
        random: rng,
      ),
    ];
  }

  static RiderSpecialization _specializationForScenario(
    HistoricScenarioCategory category,
    bool isLeader,
  ) {
    switch (category) {
      case HistoricScenarioCategory.mountainTimeTrial:
      case HistoricScenarioCategory.bonkDefense:
      case HistoricScenarioCategory.alpineStormRaid:
      case HistoricScenarioCategory.extremeWallClimb:
      case HistoricScenarioCategory.satelliteRelay:
        return isLeader
            ? RiderSpecialization.gcClimber
            : RiderSpecialization.pureClimber;
      case HistoricScenarioCategory.crosswindAndCobbles:
        return isLeader
            ? RiderSpecialization.classicCobbles
            : RiderSpecialization.domestiqueEngine;
      case HistoricScenarioCategory.flatTimeTrial:
        return RiderSpecialization.timeTrialist;
      case HistoricScenarioCategory.echelonChase:
        return isLeader
            ? RiderSpecialization.gcClimber
            : RiderSpecialization.domestiqueEngine;
      case HistoricScenarioCategory.gravelMonument:
        return isLeader
            ? RiderSpecialization.puncher
            : RiderSpecialization.classicCobbles;
      case HistoricScenarioCategory.sprintChaos:
        return isLeader
            ? RiderSpecialization.pureSprinter
            : RiderSpecialization.domestiqueEngine;
    }
  }

  static RaceStage _buildStageForScenario(HistoricScenarioDefinition def) {
    final StageType stageType;
    final List<StageSegment> segments;

    switch (def.category) {
      case HistoricScenarioCategory.mountainTimeTrial:
        stageType = StageType.individualTimeTrial;
        segments = _buildSegmentsFromSpecs(const [
          _SegSpec(12.0, 0.5, SegmentSurfaceType.smoothAsphalt, 30, 90,
              SegmentClassification.none),
          _SegSpec(18.3, 1.2, SegmentSurfaceType.smoothAsphalt, 35, 110,
              SegmentClassification.intermediateSprint),
          _SegSpec(3.9, 8.6, SegmentSurfaceType.smoothAsphalt, 55, 85,
              SegmentClassification.none),
          _SegSpec(2.0, 13.5, SegmentSurfaceType.roughAsphalt, 65, 80,
              SegmentClassification.finishLine),
        ], def.windSpeedKmh);
      case HistoricScenarioCategory.crosswindAndCobbles:
        stageType = StageType.cobbleClassic;
        segments = _buildSegmentsFromSpecs(const [
          _SegSpec(10.0, 0.2, SegmentSurfaceType.smoothAsphalt, 45, 90,
              SegmentClassification.none),
          _SegSpec(3.5, 0.4, SegmentSurfaceType.cobblestonesSector4, 85, 85,
              SegmentClassification.none),
          _SegSpec(8.5, -0.1, SegmentSurfaceType.smoothAsphalt, 50, 95,
              SegmentClassification.none),
          _SegSpec(4.0, 0.5, SegmentSurfaceType.cobblestonesSector5, 92, 80,
              SegmentClassification.none),
          _SegSpec(9.0, 0.0, SegmentSurfaceType.roughAsphalt, 55, 90,
              SegmentClassification.none),
          _SegSpec(3.0, 0.8, SegmentSurfaceType.cobblestonesSector4, 88, 75,
              SegmentClassification.none),
          _SegSpec(12.0, 0.1, SegmentSurfaceType.smoothAsphalt, 40, 85,
              SegmentClassification.finishLine),
        ], def.windSpeedKmh);
      case HistoricScenarioCategory.bonkDefense:
        stageType = StageType.summitFinish;
        segments = _buildSegmentsFromSpecs(const [
          _SegSpec(5.0, 7.8, SegmentSurfaceType.smoothAsphalt, 45, 140,
              SegmentClassification.none),
          _SegSpec(5.0, 9.1, SegmentSurfaceType.smoothAsphalt, 55, 130,
              SegmentClassification.none),
          _SegSpec(5.0, 8.3, SegmentSurfaceType.smoothAsphalt, 60, 120,
              SegmentClassification.finishLine),
        ], def.windSpeedKmh, initialElevationM: 920.0);
      case HistoricScenarioCategory.flatTimeTrial:
        stageType = StageType.individualTimeTrial;
        segments = _buildSegmentsFromSpecs(const [
          _SegSpec(8.5, 0.3, SegmentSurfaceType.smoothAsphalt, 45, 100,
              SegmentClassification.none),
          _SegSpec(8.5, -0.2, SegmentSurfaceType.smoothAsphalt, 50, 120,
              SegmentClassification.intermediateSprint),
          _SegSpec(7.5, 0.1, SegmentSurfaceType.cobblestonesSector1, 65, 95,
              SegmentClassification.finishLine),
        ], def.windSpeedKmh);
      case HistoricScenarioCategory.alpineStormRaid:
        stageType = StageType.highMountain;
        segments = _buildSegmentsFromSpecs(const [
          _SegSpec(18.0, 8.2, SegmentSurfaceType.roughAsphalt, 70, 110,
              SegmentClassification.horsCategorie),
          _SegSpec(22.0, -6.5, SegmentSurfaceType.roughAsphalt, 85, 125,
              SegmentClassification.none),
          _SegSpec(20.0, 1.4, SegmentSurfaceType.smoothAsphalt, 40, 95,
              SegmentClassification.none),
          _SegSpec(20.0, 7.6, SegmentSurfaceType.smoothAsphalt, 60, 105,
              SegmentClassification.finishLine),
        ], def.windSpeedKmh, initialElevationM: 1150.0);
      case HistoricScenarioCategory.echelonChase:
        stageType = StageType.flat;
        segments = _buildSegmentsFromSpecs(const [
          _SegSpec(20.0, 0.1, SegmentSurfaceType.smoothAsphalt, 35, 90,
              SegmentClassification.none),
          _SegSpec(25.0, -0.1, SegmentSurfaceType.smoothAsphalt, 40, 88,
              SegmentClassification.intermediateSprint),
          _SegSpec(20.0, 0.4, SegmentSurfaceType.smoothAsphalt, 45, 92,
              SegmentClassification.finishLine),
        ], def.windSpeedKmh);
      case HistoricScenarioCategory.gravelMonument:
        stageType = StageType.hilly;
        segments = _buildSegmentsFromSpecs(const [
          _SegSpec(11.5, 4.8, SegmentSurfaceType.gravelStrade, 82, 100,
              SegmentClassification.cat2),
          _SegSpec(14.5, -1.5, SegmentSurfaceType.smoothAsphalt, 50, 115,
              SegmentClassification.none),
          _SegSpec(8.0, 5.2, SegmentSurfaceType.gravelStrade, 85, 95,
              SegmentClassification.cat3),
          _SegSpec(13.0, 0.8, SegmentSurfaceType.smoothAsphalt, 45, 105,
              SegmentClassification.none),
          _SegSpec(1.0, 12.4, SegmentSurfaceType.cobblestonesSector2, 78, 90,
              SegmentClassification.finishLine),
        ], def.windSpeedKmh);
      case HistoricScenarioCategory.extremeWallClimb:
        stageType = StageType.summitFinish;
        segments = _buildSegmentsFromSpecs(const [
          _SegSpec(5.5, -5.0, SegmentSurfaceType.roughAsphalt, 75, 120,
              SegmentClassification.none),
          _SegSpec(6.0, 8.5, SegmentSurfaceType.smoothAsphalt, 55, 105,
              SegmentClassification.none),
          _SegSpec(3.5, 15.8, SegmentSurfaceType.roughAsphalt, 70, 95,
              SegmentClassification.none),
          _SegSpec(3.0, 11.2, SegmentSurfaceType.roughAsphalt, 65, 90,
              SegmentClassification.finishLine),
        ], def.windSpeedKmh, initialElevationM: 640.0);
      case HistoricScenarioCategory.sprintChaos:
        stageType = StageType.flat;
        segments = _buildSegmentsFromSpecs(const [
          _SegSpec(12.0, 0.0, SegmentSurfaceType.smoothAsphalt, 40, 110,
              SegmentClassification.none),
          _SegSpec(7.0, -0.3, SegmentSurfaceType.smoothAsphalt, 50, 100,
              SegmentClassification.none),
          _SegSpec(3.0, 0.2, SegmentSurfaceType.smoothAsphalt, 55, 95,
              SegmentClassification.finishLine),
        ], def.windSpeedKmh);
      case HistoricScenarioCategory.satelliteRelay:
        stageType = StageType.summitFinish;
        segments = _buildSegmentsFromSpecs(const [
          _SegSpec(17.5, 7.4, SegmentSurfaceType.smoothAsphalt, 55, 110,
              SegmentClassification.horsCategorie),
          _SegSpec(21.0, -5.8, SegmentSurfaceType.smoothAsphalt, 70, 115,
              SegmentClassification.none),
          _SegSpec(12.0, 1.2, SegmentSurfaceType.smoothAsphalt, 35, 95,
              SegmentClassification.none),
          _SegSpec(11.5, 9.2, SegmentSurfaceType.roughAsphalt, 60, 100,
              SegmentClassification.finishLine),
        ], def.windSpeedKmh, initialElevationM: 1350.0);
    }

    return RaceStage(
      id: '${def.id}_stage',
      stageNumber: 1,
      name: def.title,
      stageType: stageType,
      segments: segments,
      baseTemperatureCelsius: def.temperatureCelsius,
      weatherCondition: def.weatherCondition,
      windSpeedKmh: def.windSpeedKmh,
    );
  }

  static List<StageSegment> _buildSegmentsFromSpecs(
    List<_SegSpec> specs,
    double windSpeedKmh, {
    double initialElevationM = 180.0,
  }) {
    final segments = <StageSegment>[];
    double currentKm = 0.0;
    double currentElev = initialElevationM;
    final windDir = windSpeedKmh > 40.0 ? 270.0 : 210.0;

    for (int i = 0; i < specs.length; i++) {
      final spec = specs[i];
      final deltaElev = spec.lengthKm * 1000.0 * (spec.gradientPercent / 100.0);
      final endElev = math.max(10.0, currentElev + deltaElev);

      segments.add(
        StageSegment(
          index: i,
          startKm: currentKm,
          lengthKm: spec.lengthKm,
          startElevationM: currentElev,
          endElevationM: endElev,
          surfaceType: spec.surface,
          technicalDifficulty: spec.technicalDifficulty,
          windDirectionDegrees: windDir,
          roadBearingDegrees: spec.roadBearing,
          sprintOrKomClassification: spec.classification,
        ),
      );

      currentKm += spec.lengthKm;
      currentElev = endElev;
    }

    return List<StageSegment>.unmodifiable(segments);
  }
}

class _SegSpec {
  final double lengthKm;
  final double gradientPercent;
  final SegmentSurfaceType surface;
  final double technicalDifficulty;
  final double roadBearing;
  final SegmentClassification classification;

  const _SegSpec(
    this.lengthKm,
    this.gradientPercent,
    this.surface,
    this.technicalDifficulty,
    this.roadBearing,
    this.classification,
  );
}

/// Responsywny panel UI wyboru i uruchamiania 10 Scenariuszy Historycznych.
///
/// Obsługuje layout `390x844` (mobile), `1024x768` (tablet) i `1600x900` (desktop),
/// pełne stany `hover` / `active` / `disabled` / `focus` oraz paletę `AppColors`.
class LegendaryHistoricScenariosPanel extends StatefulWidget {
  final Set<String> completedScenarioIds;
  final Map<String, ScenarioMedalTier> earnedMedalsByScenarioId;
  final String? initialSelectedScenarioId;
  final void Function(PlayableHistoricScenarioBundle bundle)? onLaunchScenario;

  const LegendaryHistoricScenariosPanel({
    super.key,
    this.completedScenarioIds = const {},
    this.earnedMedalsByScenarioId = const {},
    this.initialSelectedScenarioId,
    this.onLaunchScenario,
  });

  @override
  State<LegendaryHistoricScenariosPanel> createState() =>
      _LegendaryHistoricScenariosPanelState();
}

class _LegendaryHistoricScenariosPanelState
    extends State<LegendaryHistoricScenariosPanel> {
  HistoricScenarioDifficulty? _difficultyFilter;
  late String _selectedScenarioId;
  String? _hoveredScenarioId;
  bool _isLaunching = false;

  @override
  void initState() {
    super.initState();
    _selectedScenarioId = widget.initialSelectedScenarioId ??
        LegendaryHistoricScenariosSeeder.scenarios.first.id;
  }

  List<HistoricScenarioDefinition> get _filteredScenarios {
    if (_difficultyFilter == null) {
      return LegendaryHistoricScenariosSeeder.scenarios;
    }
    return LegendaryHistoricScenariosSeeder.scenarios
        .where((s) => s.difficulty == _difficultyFilter)
        .toList();
  }

  HistoricScenarioDefinition get _selectedScenario {
    return LegendaryHistoricScenariosSeeder.findById(_selectedScenarioId) ??
        LegendaryHistoricScenariosSeeder.scenarios.first;
  }

  void _handleLaunch() {
    if (_isLaunching || widget.onLaunchScenario == null) return;
    setState(() => _isLaunching = true);
    final bundle = LegendaryHistoricScenariosSeeder.buildPlayableScenario(
      _selectedScenario.id,
    );
    widget.onLaunchScenario!(bundle);
    if (mounted) {
      setState(() => _isLaunching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final isCompact = constraints.maxWidth < 520;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(isCompact),
              _buildFilterBar(isCompact),
              Expanded(
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _buildScenarioList(isCompact),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 6,
                            child: _buildScenarioDetail(_selectedScenario, isCompact),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 12 : 16,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildScenarioList(
                              isCompact,
                              shrinkWrap: true,
                            ),
                            const SizedBox(height: 16),
                            _buildScenarioDetail(
                              _selectedScenario,
                              isCompact,
                              scrollable: false,
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    final completedCount = widget.completedScenarioIds.length;
    final totalCount = LegendaryHistoricScenariosSeeder.scenarios.length;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 12 : 20,
        isCompact ? 12 : 16,
        isCompact ? 12 : 20,
        8,
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SCENARIUSZE HISTORYCZNE & WYZWANIA TAKTYCZNE',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 15 : 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                '10 legendarnych sytuacji wyścigowych do rozegrania w silniku 3D',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  size: 16,
                  color: AppColors.goldAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  'Ukończono: $completedCount / $totalCount',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isCompact) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 20,
        vertical: 6,
      ),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Wszystkie (10)',
            selected: _difficultyFilter == null,
            accentColor: AppColors.goldAccent,
            onTap: () => setState(() => _difficultyFilter = null),
          ),
          const SizedBox(width: 8),
          for (final diff in HistoricScenarioDifficulty.values) ...[
            _buildFilterChip(
              label: diff.label,
              selected: _difficultyFilter == diff,
              accentColor: diff.badgeColor,
              onTap: () => setState(() => _difficultyFilter = diff),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      focusColor: accentColor.withValues(alpha: 0.25),
      hoverColor: AppColors.surfaceLight,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withValues(alpha: 0.16)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accentColor : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? accentColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildScenarioList(bool isCompact, {bool shrinkWrap = false}) {
    final list = _filteredScenarios;
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        isCompact ? 0 : 20,
        8,
        isCompact ? 0 : 8,
        16,
      ),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = list[index];
        final isSelected = item.id == _selectedScenario.id;
        final isHovered = item.id == _hoveredScenarioId;
        final isCompleted = widget.completedScenarioIds.contains(item.id);
        final medal =
            widget.earnedMedalsByScenarioId[item.id] ?? ScenarioMedalTier.none;

        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredScenarioId = item.id),
          onExit: (_) => setState(() => _hoveredScenarioId = null),
          child: InkWell(
            onTap: () => setState(() => _selectedScenarioId = item.id),
            borderRadius: BorderRadius.circular(16),
            focusColor: AppColors.goldAccent.withValues(alpha: 0.2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.surfaceLight
                    : isHovered
                        ? AppColors.surfaceLight.withValues(alpha: 0.65)
                        : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.goldAccent
                      : isHovered
                          ? AppColors.textSecondary.withValues(alpha: 0.45)
                          : AppColors.cardBorder,
                  width: isSelected ? 1.4 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: item.difficulty.badgeColor
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.code} • ${item.difficulty.label}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: item.difficulty.badgeColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isCompleted || medal != ScenarioMedalTier.none) ...[
                            Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: medal != ScenarioMedalTier.none
                                  ? medal.color
                                  : AppColors.statusSuccess,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            item.yearLabel,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScenarioDetail(
    HistoricScenarioDefinition scenario,
    bool isCompact, {
    bool scrollable = true,
  }) {
    final canLaunch = widget.onLaunchScenario != null && !_isLaunching;

    final content = Container(
      margin: EdgeInsets.fromLTRB(
        isCompact ? 0 : 0,
        8,
        isCompact ? 0 : 20,
        16,
      ),
      padding: EdgeInsets.all(isCompact ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                scenario.category.icon,
                color: AppColors.goldAccent,
                size: 20,
              ),
              Text(
                '${scenario.category.label} • ${scenario.historicalInspiration}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.goldAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            scenario.title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 17 : 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _buildMetricPill(
                Icons.route_outlined,
                'Dystans: ${scenario.playableDistanceKm.toStringAsFixed(1)} km',
              ),
              _buildMetricPill(
                Icons.schedule_outlined,
                'Start: ${scenario.formattedGapLabel}',
              ),
              _buildMetricPill(
                Icons.air_rounded,
                'Wiatr: ${scenario.windSpeedKmh.round()} km/h',
              ),
              _buildMetricPill(
                Icons.groups_outlined,
                'Pomocnicy: ${scenario.availableDomestiquesCount}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'SYTUACJA TAKTYCZNA',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            scenario.briefingStory,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.45,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accentBlue.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 18,
                  color: AppColors.accentBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    scenario.tacticalHint,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'CELE WYZWANIA',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          for (final obj in scenario.objectives) ...[
            _buildObjectiveRow(obj),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canLaunch ? _handleLaunch : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: AppColors.textPrimary,
                disabledBackgroundColor: AppColors.surfaceLight,
                disabledForegroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(
                _isLaunching
                    ? 'Przygotowywanie scenariusza...'
                    : 'Uruchom Scenariusz (${scenario.code})',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (scrollable) {
      return SingleChildScrollView(child: content);
    }
    return content;
  }

  Widget _buildMetricPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectiveRow(HistoricScenarioObjective obj) {
    final badgeColor =
        obj.isPrimary ? AppColors.goldAccent : AppColors.accentBlue;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            obj.isPrimary ? Icons.star_rounded : Icons.flag_outlined,
            size: 16,
            color: badgeColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${obj.isPrimary ? "[Główny]" : "[Dodatkowy]"} ${obj.title}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  obj.description,
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
    );
  }
}
