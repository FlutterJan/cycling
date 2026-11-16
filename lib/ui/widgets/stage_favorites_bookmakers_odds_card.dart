import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';

/// Kierunek ruchu kursu bukmacherskiego przed startem etapu.
enum BookmakerOddsTrend {
  /// Kurs spada (rosnące zaufanie rynku — wysoka forma TSB / mocny pociąg).
  shortening,

  /// Kurs stabilny.
  stable,

  /// Kurs rośnie (spadek formy / słabsze wsparcie drużyny).
  drifting,
}

/// Tryb prezentacji kolumny notowań na karcie faworytów.
enum OddsDisplayMode {
  /// Klasyczne kursy dziesiętne (np. `2.40`).
  decimalOdds,

  /// Implikowane prawdopodobieństwo zwycięstwa w procentach (np. `38.5%`).
  winProbability,
}

/// Dane wejściowe pojedynczego kandydata do wyliczenia faworytów etapu.
class StageFavoriteCandidateInput {
  final Rider rider;
  final CyclingTeam team;
  final List<Rider> teammates;
  final bool isPlayerTeam;

  const StageFavoriteCandidateInput({
    required this.rider,
    required this.team,
    this.teammates = const [],
    this.isPlayerTeam = false,
  });
}

/// Wynik analizy przedetapowej dla jednego z głównych faworytów dnia.
class StageFavoriteOddsEntry {
  final int rank;
  final Rider rider;
  final CyclingTeam team;
  final bool isPlayerTeam;

  /// Ocena gwiazdkowa w stylu *L'Équipe* / *ProCyclingStats* (1..5).
  final int stars;

  /// Złożony indeks szans etapowych (0..100).
  final double compositeScore;

  /// Dopasowanie profilu kolarza do trasy i pogody (0..100).
  final double routeFitScore;

  /// Wkład aktualnej formy TSB (0..100).
  final double formTsbScore;

  /// Siła pociągu / wsparcia drużynowego na dany typ etapu (0..100).
  final double trainSupportScore;

  /// Kurs dziesiętny bukmachera (np. 2.40).
  final double decimalOdds;

  /// Implikowane prawdopodobieństwo zwycięstwa w % (0..100).
  final double impliedProbabilityPercent;

  /// Ruch kursu przed startem.
  final BookmakerOddsTrend oddsTrend;

  /// Krótki opis siły wsparcia (np. `"Pociąg 4 os."`).
  final String trainSummary;

  /// Kluczowy parametr telemetryczny pod profil etapu (np. `"6.35 W/kg"`, `"1540 W"`, `"415 W"`).
  final String keyMetricLabel;

  const StageFavoriteOddsEntry({
    required this.rank,
    required this.rider,
    required this.team,
    required this.isPlayerTeam,
    required this.stars,
    required this.compositeScore,
    required this.routeFitScore,
    required this.formTsbScore,
    required this.trainSupportScore,
    required this.decimalOdds,
    required this.impliedProbabilityPercent,
    required this.oddsTrend,
    required this.trainSummary,
    required this.keyMetricLabel,
  });
}

/// Kalkulator przedetapowych faworytów (*L'Équipe* / *ProCyclingStats* 1–5★)
/// oraz kursów bukmacherskich na podstawie profilu trasy, TSB i składu pociągu.
class StageFavoritesBookmakersCalculator {
  StageFavoritesBookmakersCalculator._();

  /// Buduje listę wejściową z płaskiej listy kolarzy i mapy drużyn,
  /// automatycznie grupując kolegów z zespołu jako skład pociągu.
  static List<StageFavoriteCandidateInput> buildInputsFromRosters({
    required List<Rider> riders,
    required Map<String, CyclingTeam> teamsById,
    String? playerTeamId,
  }) {
    final ridersByTeam = <String, List<Rider>>{};
    final teamOfRider = <String, CyclingTeam>{};

    for (final team in teamsById.values) {
      for (final riderId in team.rosterRiderIds) {
        teamOfRider[riderId] = team;
      }
    }

    for (final rider in riders) {
      final team = teamOfRider[rider.id];
      if (team != null) {
        ridersByTeam.putIfAbsent(team.id, () => <Rider>[]).add(rider);
      }
    }

    final inputs = <StageFavoriteCandidateInput>[];
    for (final rider in riders) {
      final team = teamOfRider[rider.id];
      if (team == null) continue;
      final teamRiders = ridersByTeam[team.id] ?? const <Rider>[];
      final teammates = teamRiders.where((r) => r.id != rider.id).toList();
      inputs.add(
        StageFavoriteCandidateInput(
          rider: rider,
          team: team,
          teammates: teammates,
          isPlayerTeam: playerTeamId != null && team.id == playerTeamId,
        ),
      );
    }
    return inputs;
  }

  /// Wylicza maksymalnie [topCount] (domyślnie 5) głównych faworytów dnia.
  static List<StageFavoriteOddsEntry> calculateTopFavorites({
    required RaceStage stage,
    required List<StageFavoriteCandidateInput> candidates,
    int topCount = 5,
  }) {
    if (candidates.isEmpty || topCount <= 0) {
      return const [];
    }

    final eligible = candidates.where((c) {
      final injury = c.rider.health.currentInjury;
      final injuredOut = injury != null && !injury.trainingAllowed;
      final ill = c.rider.health.currentIllness != null &&
          c.rider.health.currentIllness!.trim().isNotEmpty;
      return !injuredOut && !ill;
    }).toList();

    final pool = eligible.isNotEmpty ? eligible : candidates;
    final scored = <_ScoredCandidate>[];

    for (final candidate in pool) {
      final routeResult = _evaluateRouteFit(stage, candidate.rider);
      final tsbScore = _evaluateTsbForm(candidate.rider.health.trainingStressBalance);
      final trainResult = _evaluateTrainSupport(
        stage: stage,
        leader: candidate.rider,
        team: candidate.team,
        teammates: candidate.teammates,
      );

      // Wagi zależne od charakteru etapu (ITT niemal bez pociągu, sprint mocno zależny od pociągu).
      final double wRoute;
      final double wForm;
      final double wTrain;
      switch (stage.stageType) {
        case StageType.individualTimeTrial:
          wRoute = 0.72;
          wForm = 0.23;
          wTrain = 0.05;
        case StageType.teamTimeTrial:
          wRoute = 0.42;
          wForm = 0.18;
          wTrain = 0.40;
        case StageType.flat:
          wRoute = 0.56;
          wForm = 0.20;
          wTrain = 0.24;
        case StageType.cobbleClassic:
        case StageType.hilly:
          wRoute = 0.62;
          wForm = 0.21;
          wTrain = 0.17;
        case StageType.highMountain:
        case StageType.summitFinish:
          wRoute = 0.64;
          wForm = 0.21;
          wTrain = 0.15;
      }

      final composite = (routeResult.score * wRoute +
              tsbScore * wForm +
              trainResult.score * wTrain)
          .clamp(1.0, 99.5);

      scored.add(
        _ScoredCandidate(
          input: candidate,
          compositeScore: composite,
          routeFitScore: routeResult.score,
          formTsbScore: tsbScore,
          trainSupportScore: trainResult.score,
          trainSummary: trainResult.summary,
          keyMetricLabel: routeResult.keyMetricLabel,
        ),
      );
    }

    scored.sort((a, b) => b.compositeScore.compareTo(a.compositeScore));

    // Przeliczamy prawdopodobieństwa w modelu softmax na pełnym peletonie kandydatów,
    // aby kursy oddawały realną konkurencję dnia.
    const double temperature = 7.5;
    final maxScore = scored.first.compositeScore;
    double expSum = 0.0;
    final expWeights = <double>[];
    for (final item in scored) {
      final w = math.exp((item.compositeScore - maxScore) / temperature);
      expWeights.add(w);
      expSum += w;
    }

    // Marża bukmacherska (~12% overround dla rynku zwycięzcy etapu).
    const double bookmakerOverround = 1.12;
    final limit = math.min(topCount, scored.length);
    final results = <StageFavoriteOddsEntry>[];

    for (var i = 0; i < limit; i++) {
      final item = scored[i];
      final rawProb = expSum > 0.0 ? (expWeights[i] / expSum) : (1.0 / scored.length);
      final impliedProb = (rawProb * 100.0).clamp(1.5, 78.0);
      final rawOdds = (1.0 / (rawProb * bookmakerOverround)).clamp(1.25, 65.0);
      final roundedOdds = _roundBookmakerOdds(rawOdds);
      final stars = _computeStars(
        rankIndex: i,
        score: item.compositeScore,
        topScore: maxScore,
      );
      final trend = _computeOddsTrend(
        tsb: item.input.rider.health.trainingStressBalance,
        trainScore: item.trainSupportScore,
      );

      results.add(
        StageFavoriteOddsEntry(
          rank: i + 1,
          rider: item.input.rider,
          team: item.input.team,
          isPlayerTeam: item.input.isPlayerTeam,
          stars: stars,
          compositeScore: item.compositeScore,
          routeFitScore: item.routeFitScore,
          formTsbScore: item.formTsbScore,
          trainSupportScore: item.trainSupportScore,
          decimalOdds: roundedOdds,
          impliedProbabilityPercent: impliedProb,
          oddsTrend: trend,
          trainSummary: item.trainSummary,
          keyMetricLabel: item.keyMetricLabel,
        ),
      );
    }

    return List<StageFavoriteOddsEntry>.unmodifiable(results);
  }

  static _RouteEvaluation _evaluateRouteFit(RaceStage stage, Rider rider) {
    final weight = rider.physiology.weightKg > 0 ? rider.physiology.weightKg : 70.0;
    final wKg20m = rider.powerProfile.watts20m / weight;
    final wKg5m = rider.powerProfile.watts5m / weight;
    final wKg1m = rider.powerProfile.watts1m / weight;

    final climbScore = ((wKg20m - 3.6) / (6.6 - 3.6) * 55.0 + 44.0).clamp(25.0, 99.0);
    final vo2Score = ((wKg5m - 4.5) / (8.0 - 4.5) * 55.0 + 44.0).clamp(25.0, 99.0);
    final punchScore = ((wKg1m - 6.5) / (12.0 - 6.5) * 55.0 + 44.0).clamp(25.0, 99.0);
    final sprintScore = ((rider.powerProfile.watts5s - 900.0) / (1750.0 - 900.0) * 55.0 + 44.0)
        .clamp(25.0, 99.0);
    final ttScore = ((rider.powerProfile.watts60m - 280.0) / (460.0 - 280.0) * 44.0 +
            rider.skills.timeTrialPositioning * 0.34 +
            rider.skills.aeroPositioning * 0.22)
        .clamp(25.0, 99.0);
    final cobbleScore =
        (rider.skills.cobbles * 0.65 + rider.skills.bikeHandling * 0.35).clamp(25.0, 99.0);

    final hasCobbles = stage.segments.any((s) => s.isCobblestone);
    final hasGravel = stage.segments.any((s) => s.surfaceType == SegmentSurfaceType.gravelStrade);
    final isHighAltitude = stage.maxElevationM >= 2000.0;

    double baseScore;
    String keyMetricLabel;

    switch (stage.stageType) {
      case StageType.flat:
        baseScore = sprintScore * 0.62 +
            rider.skills.draftingEfficiency * 0.20 +
            rider.skills.bikeHandling * 0.18;
        if (rider.specialization == RiderSpecialization.pureSprinter) {
          baseScore += 5.5;
        } else if (rider.specialization == RiderSpecialization.versatileSprinter) {
          baseScore += 3.0;
        }
        keyMetricLabel = '${rider.powerProfile.watts5s.round()} W (5s)';

      case StageType.hilly:
        baseScore = punchScore * 0.44 +
            vo2Score * 0.28 +
            rider.skills.raceIq * 0.16 +
            sprintScore * 0.12;
        if (rider.specialization == RiderSpecialization.puncher) {
          baseScore += 5.0;
        } else if (rider.specialization == RiderSpecialization.versatileSprinter) {
          baseScore += 2.5;
        }
        if (hasGravel) {
          baseScore = baseScore * 0.85 + rider.skills.bikeHandling * 0.15;
        }
        keyMetricLabel = '${wKg1m.toStringAsFixed(1)} W/kg (1m)';

      case StageType.highMountain:
      case StageType.summitFinish:
        baseScore = climbScore * 0.56 +
            vo2Score * 0.26 +
            rider.skills.descending * 0.10 +
            rider.skills.raceIq * 0.08;
        if (rider.specialization == RiderSpecialization.gcClimber ||
            rider.specialization == RiderSpecialization.pureClimber) {
          baseScore += 5.0;
        }
        if (isHighAltitude) {
          baseScore += (rider.physiology.vo2Max - 75.0).clamp(-3.0, 4.0);
        }
        keyMetricLabel = '${wKg20m.toStringAsFixed(2)} W/kg';

      case StageType.cobbleClassic:
        baseScore = cobbleScore * 0.54 +
            punchScore * 0.22 +
            rider.skills.raceIq * 0.14 +
            sprintScore * 0.10;
        if (rider.specialization == RiderSpecialization.classicCobbles) {
          baseScore += 6.0;
        }
        if (hasCobbles) {
          baseScore += (rider.skills.cobbles - 70) * 0.08;
        }
        keyMetricLabel = 'Bruk ${rider.skills.cobbles}/99';

      case StageType.individualTimeTrial:
      case StageType.teamTimeTrial:
        baseScore = ttScore * 0.82 + climbScore * 0.18;
        if (rider.specialization == RiderSpecialization.timeTrialist) {
          baseScore += 5.5;
        } else if (rider.specialization == RiderSpecialization.gcClimber) {
          baseScore += 2.0;
        }
        keyMetricLabel = '${rider.powerProfile.watts60m.round()} W (TT)';
    }

    // Modyfikatory pogodowe
    switch (stage.weatherCondition) {
      case WeatherCondition.lightRain:
      case WeatherCondition.heavyStorm:
        baseScore += (rider.skills.rainResistance - 65) * 0.09;
      case WeatherCondition.crosswindGale:
        baseScore += (rider.skills.draftingEfficiency - 65) * 0.10;
      case WeatherCondition.extremeHeat:
        baseScore += (rider.skills.heatTolerance - 65) * 0.09;
      case WeatherCondition.sunny:
      case WeatherCondition.overcast:
        break;
    }
    if (stage.windSpeedKmh >= 30.0) {
      baseScore += (rider.skills.draftingEfficiency - 65) * 0.07;
    }

    return _RouteEvaluation(
      score: baseScore.clamp(15.0, 99.5),
      keyMetricLabel: keyMetricLabel,
    );
  }

  /// Wylicza ocenę formy na podstawie wskaźnika TSB = CTL - ATL.
  /// Szczyt formy to przedział +5..+22.
  static double _evaluateTsbForm(double tsb) {
    if (tsb >= 5.0 && tsb <= 22.0) {
      // Optimum szczytu formy: 82..98 pkt
      final centerDistance = (tsb - 13.5).abs();
      return (98.0 - centerDistance * 1.4).clamp(80.0, 98.0);
    }
    if (tsb > 22.0) {
      // Lekka utrata rytmu startowego przy bardzo wysokim TSB
      return (86.0 - (tsb - 22.0) * 0.9).clamp(55.0, 86.0);
    }
    if (tsb >= -10.0) {
      // Zakres bazowy -10..+5 -> 65..82
      return (65.0 + ((tsb + 10.0) / 15.0) * 17.0).clamp(62.0, 82.0);
    }
    // Narastające zmęczenie poniżej -10
    return (65.0 + (tsb + 10.0) * 1.35).clamp(20.0, 65.0);
  }

  static _TrainEvaluation _evaluateTrainSupport({
    required RaceStage stage,
    required Rider leader,
    required CyclingTeam team,
    required List<Rider> teammates,
  }) {
    final activeTeammates = teammates.where((r) {
      final injury = r.health.currentInjury;
      return injury == null || injury.trainingAllowed;
    }).toList();

    if (stage.stageType == StageType.individualTimeTrial) {
      final staffBoost = (team.staff.mechanicsLevel * 0.55 +
              team.staff.sportsDirectorsLevel * 0.45)
          .clamp(35.0, 98.0);
      return _TrainEvaluation(
        score: staffBoost,
        summary: 'Sztab TT ${staffBoost.round()}/100',
      );
    }

    if (activeTeammates.isEmpty) {
      return const _TrainEvaluation(
        score: 28.0,
        summary: 'Bez pociągu (solo)',
      );
    }

    final helperScores = <double>[];
    for (final mate in activeTeammates) {
      double s;
      switch (stage.stageType) {
        case StageType.flat:
          s = (mate.skills.draftingEfficiency * 0.35 +
                  mate.skills.bikeHandling * 0.25 +
                  mate.overallRating * 0.40)
              .clamp(30.0, 98.0);
          if (mate.specialization == RiderSpecialization.versatileSprinter ||
              mate.specialization == RiderSpecialization.domestiqueEngine) {
            s += 4.0;
          }
        case StageType.highMountain:
        case StageType.summitFinish:
          final wKg20m = mate.powerProfile.watts20m /
              (mate.physiology.weightKg > 0 ? mate.physiology.weightKg : 70.0);
          final climb = ((wKg20m - 3.6) / (6.4 - 3.6) * 55.0 + 40.0).clamp(30.0, 96.0);
          s = (climb * 0.65 + mate.overallRating * 0.35).clamp(30.0, 96.0);
        case StageType.cobbleClassic:
        case StageType.hilly:
          s = (mate.skills.cobbles * 0.40 +
                  mate.skills.raceIq * 0.25 +
                  mate.overallRating * 0.35)
              .clamp(30.0, 96.0);
        case StageType.teamTimeTrial:
          s = (mate.powerProfile.watts60m / 4.4 * 0.6 +
                  mate.skills.timeTrialPositioning * 0.4)
              .clamp(30.0, 98.0);
        case StageType.individualTimeTrial:
          s = mate.overallRating.toDouble();
      }
      helperScores.add(s.clamp(25.0, 99.0));
    }

    helperScores.sort((a, b) => b.compareTo(a));
    final topHelpers = helperScores.take(4).toList();
    final avgHelper = topHelpers.reduce((a, b) => a + b) / topHelpers.length;
    final depthBonus = math.min(activeTeammates.length, 6) * 2.2;
    final totalScore = (avgHelper * 0.86 + depthBonus).clamp(30.0, 98.0);

    return _TrainEvaluation(
      score: totalScore,
      summary: 'Pociąg ${activeTeammates.length} os.',
    );
  }

  static int _computeStars({
    required int rankIndex,
    required double score,
    required double topScore,
  }) {
    final gap = topScore - score;
    if (rankIndex == 0) {
      return score >= 68.0 ? 5 : 4;
    }
    if (rankIndex == 1) {
      if (gap <= 2.2 && score >= 74.0) return 5;
      return 4;
    }
    if (rankIndex == 2) {
      if (gap <= 4.0 && score >= 70.0) return 4;
      return 3;
    }
    if (rankIndex == 3) {
      if (gap <= 6.5 && score >= 66.0) return 3;
      return 2;
    }
    return gap <= 9.0 && score >= 62.0 ? 2 : 1;
  }

  static BookmakerOddsTrend _computeOddsTrend({
    required double tsb,
    required double trainScore,
  }) {
    if (tsb >= 6.0 && trainScore >= 68.0) {
      return BookmakerOddsTrend.shortening;
    }
    if (tsb <= -14.0 || trainScore < 45.0) {
      return BookmakerOddsTrend.drifting;
    }
    return BookmakerOddsTrend.stable;
  }

  static double _roundBookmakerOdds(double value) {
    if (value < 5.0) {
      return (value * 20).round() / 20.0;
    }
    if (value < 15.0) {
      return (value * 4).round() / 4.0;
    }
    return (value * 2).round() / 2.0;
  }
}

class _ScoredCandidate {
  final StageFavoriteCandidateInput input;
  final double compositeScore;
  final double routeFitScore;
  final double formTsbScore;
  final double trainSupportScore;
  final String trainSummary;
  final String keyMetricLabel;

  const _ScoredCandidate({
    required this.input,
    required this.compositeScore,
    required this.routeFitScore,
    required this.formTsbScore,
    required this.trainSupportScore,
    required this.trainSummary,
    required this.keyMetricLabel,
  });
}

class _RouteEvaluation {
  final double score;
  final String keyMetricLabel;

  const _RouteEvaluation({
    required this.score,
    required this.keyMetricLabel,
  });
}

class _TrainEvaluation {
  final double score;
  final String summary;

  const _TrainEvaluation({
    required this.score,
    required this.summary,
  });
}

/// Karta faworytów i kursów przedetapowych w stylu *L'Équipe* / *ProCyclingStats*.
///
/// Automatycznie wylicza 5 głównych faworytów dnia na podstawie profilu trasy,
/// aktualnej formy TSB oraz składu pociągu drużynowego.
class StageFavoritesBookmakersOddsCard extends StatefulWidget {
  final RaceStage stage;
  final List<StageFavoriteCandidateInput> candidates;
  final int maxFavorites;
  final bool enabled;
  final ValueChanged<StageFavoriteOddsEntry>? onFavoriteSelected;
  final VoidCallback? onRefreshOdds;

  const StageFavoritesBookmakersOddsCard({
    super.key,
    required this.stage,
    required this.candidates,
    this.maxFavorites = 5,
    this.enabled = true,
    this.onFavoriteSelected,
    this.onRefreshOdds,
  });

  @override
  State<StageFavoritesBookmakersOddsCard> createState() =>
      _StageFavoritesBookmakersOddsCardState();
}

class _StageFavoritesBookmakersOddsCardState
    extends State<StageFavoritesBookmakersOddsCard> {
  OddsDisplayMode _displayMode = OddsDisplayMode.decimalOdds;
  String? _expandedRiderId;

  @override
  Widget build(BuildContext context) {
    final favorites = StageFavoritesBookmakersCalculator.calculateTopFavorites(
      stage: widget.stage,
      candidates: widget.candidates,
      topCount: widget.maxFavorites,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final isCompact = width < 520.0;
        final isWide = width >= 900.0;

        return Opacity(
          opacity: widget.enabled ? 1.0 : 0.55,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.cardBorder,
                width: 1.0,
              ),
            ),
            padding: EdgeInsets.all(isCompact ? 14.0 : 18.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(isCompact: isCompact),
                const SizedBox(height: 12),
                _buildStageMetaStrip(isCompact: isCompact),
                const SizedBox(height: 12),
                if (favorites.isEmpty)
                  _buildEmptyState()
                else
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < favorites.length; i++) ...[
                        _FavoriteRowTile(
                          entry: favorites[i],
                          displayMode: _displayMode,
                          isCompact: isCompact,
                          isWide: isWide,
                          enabled: widget.enabled,
                          isExpanded: _expandedRiderId == favorites[i].rider.id,
                          onTap: () {
                            if (!widget.enabled) return;
                            setState(() {
                              final id = favorites[i].rider.id;
                              _expandedRiderId = _expandedRiderId == id ? null : id;
                            });
                            widget.onFavoriteSelected?.call(favorites[i]);
                          },
                        ),
                        if (i < favorites.length - 1) const SizedBox(height: 8),
                      ],
                    ],
                  ),
                const SizedBox(height: 12),
                _buildFooterLegend(isCompact: isCompact),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader({required bool isCompact}) {
    final titleBlock = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.goldAccent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.goldAccent.withValues(alpha: 0.45),
              width: 1.0,
            ),
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: AppColors.goldAccent,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        const Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'FAWORYCI I KURSY PRZEDETAPOWE',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                "Notowania L'Équipe / ProCyclingStats • Top 5",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _OddsModePillButton(
          label: 'Kurs 1.x',
          selected: _displayMode == OddsDisplayMode.decimalOdds,
          enabled: widget.enabled,
          onTap: () => setState(() => _displayMode = OddsDisplayMode.decimalOdds),
        ),
        const SizedBox(width: 6),
        _OddsModePillButton(
          label: 'Szansa %',
          selected: _displayMode == OddsDisplayMode.winProbability,
          enabled: widget.enabled,
          onTap: () => setState(() => _displayMode = OddsDisplayMode.winProbability),
        ),
        if (widget.onRefreshOdds != null) ...[
          const SizedBox(width: 6),
          _ActionIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Przelicz kursy',
            enabled: widget.enabled,
            onTap: widget.onRefreshOdds!,
          ),
        ],
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleBlock,
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerLeft, child: controls),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 12),
        controls,
      ],
    );
  }

  Widget _buildStageMetaStrip({required bool isCompact}) {
    final stageLabel = 'Etap ${widget.stage.stageNumber}: ${widget.stage.name}';
    final typeLabel = _stageTypeLabel(widget.stage.stageType);
    final distanceLabel = '${widget.stage.totalDistanceKm.toStringAsFixed(1)} km';
    final elevationLabel = '+${widget.stage.totalElevationGainM.round()} m';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Wrap(
        spacing: isCompact ? 8 : 14,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _stageTypeIcon(widget.stage.stageType),
                size: 14,
                color: AppColors.primaryAccent,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isCompact ? 220 : 360),
                child: Text(
                  stageLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          _MetaTagChip(label: typeLabel, color: AppColors.primaryAccent),
          _MetaTagChip(label: distanceLabel, color: AppColors.accentBlue),
          _MetaTagChip(label: elevationLabel, color: AppColors.goldAccent),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.groups_outlined,
            size: 28,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 8),
          Text(
            'Brak zgłoszonych kolarzy do wyliczenia kursów',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Dodaj listy startowe drużyn, aby zobaczyć gwiazdki faworytów i notowania.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLegend({required bool isCompact}) {
    return Wrap(
      spacing: isCompact ? 10 : 16,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: const [
        _LegendItem(
          color: AppColors.goldAccent,
          label: '★★★★★ Główny faworyt',
        ),
        _LegendItem(
          color: AppColors.statusSuccess,
          label: '▼ Kurs spada (forma / pociąg)',
        ),
        _LegendItem(
          color: AppColors.crimsonAlert,
          label: '▲ Kurs rośnie (zmęczenie)',
        ),
      ],
    );
  }

  static String _stageTypeLabel(StageType type) {
    switch (type) {
      case StageType.flat:
        return 'Płaski';
      case StageType.hilly:
        return 'Pagórkowaty';
      case StageType.highMountain:
        return 'Wysokogórski';
      case StageType.summitFinish:
        return 'Meta na szczycie';
      case StageType.individualTimeTrial:
        return 'Jazda na czas (ITT)';
      case StageType.teamTimeTrial:
        return 'Drużynowa (TTT)';
      case StageType.cobbleClassic:
        return 'Klasyk brukowany';
    }
  }

  static IconData _stageTypeIcon(StageType type) {
    switch (type) {
      case StageType.flat:
        return Icons.bolt_rounded;
      case StageType.hilly:
        return Icons.waves_rounded;
      case StageType.highMountain:
      case StageType.summitFinish:
        return Icons.terrain_rounded;
      case StageType.individualTimeTrial:
      case StageType.teamTimeTrial:
        return Icons.timer_outlined;
      case StageType.cobbleClassic:
        return Icons.grid_view_rounded;
    }
  }
}

class _FavoriteRowTile extends StatefulWidget {
  final StageFavoriteOddsEntry entry;
  final OddsDisplayMode displayMode;
  final bool isCompact;
  final bool isWide;
  final bool enabled;
  final bool isExpanded;
  final VoidCallback onTap;

  const _FavoriteRowTile({
    required this.entry,
    required this.displayMode,
    required this.isCompact,
    required this.isWide,
    required this.enabled,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  State<_FavoriteRowTile> createState() => _FavoriteRowTileState();
}

class _FavoriteRowTileState extends State<_FavoriteRowTile> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final isTopFavorite = entry.rank == 1;
    final highlightPlayer = entry.isPlayerTeam;

    final Color borderColor;
    if (!widget.enabled) {
      borderColor = AppColors.cardBorder;
    } else if (_isFocused) {
      borderColor = AppColors.accentBlue;
    } else if (_isHovered || widget.isExpanded) {
      borderColor = isTopFavorite
          ? AppColors.goldAccent.withValues(alpha: 0.75)
          : AppColors.primaryAccent.withValues(alpha: 0.75);
    } else if (highlightPlayer) {
      borderColor = AppColors.goldAccent.withValues(alpha: 0.42);
    } else {
      borderColor = AppColors.cardBorder;
    }

    final Color backgroundColor;
    if (_isPressed && widget.enabled) {
      backgroundColor = AppColors.surfaceLight;
    } else if ((_isHovered || widget.isExpanded) && widget.enabled) {
      backgroundColor = AppColors.surfaceLight.withValues(alpha: 0.85);
    } else if (highlightPlayer) {
      backgroundColor = AppColors.goldAccent.withValues(alpha: 0.06);
    } else {
      backgroundColor = AppColors.background.withValues(alpha: 0.55);
    }

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      shortcuts: const <ShortcutActivator, Intent>{},
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: widget.enabled ? () => setState(() => _isPressed = false) : null,
        onTap: widget.enabled ? widget.onTap : null,
        child: MouseRegion(
          cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCompact ? 10 : 12,
              vertical: 10,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMainRow(),
                AnimatedSize(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  child: widget.isExpanded
                      ? _buildExpandedBreakdown()
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainRow() {
    final entry = widget.entry;
    final tsb = entry.rider.health.trainingStressBalance;
    final tsbColor = tsb >= 5.0
        ? AppColors.statusSuccess
        : (tsb >= -10.0 ? AppColors.amberWarning : AppColors.crimsonAlert);

    return Row(
      children: [
        _RankBadge(rank: entry.rank, isTop: entry.rank == 1),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _CountryCodeTag(iso: entry.rider.nationalityIso),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      entry.rider.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      entry.team.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: entry.isPlayerTeam ? FontWeight.w600 : FontWeight.w400,
                        color: entry.isPlayerTeam
                            ? AppColors.goldAccent
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (!widget.isCompact) ...[
                    const SizedBox(width: 8),
                    Text(
                      '• ${entry.keyMetricLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (widget.isWide) ...[
          const SizedBox(width: 12),
          _MiniStatusPill(
            label: 'TSB ${tsb >= 0 ? '+' : ''}${tsb.round()}',
            color: tsbColor,
          ),
          const SizedBox(width: 8),
          _MiniStatusPill(
            label: entry.trainSummary,
            color: AppColors.accentBlue,
          ),
        ],
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            _StarsRatingRow(stars: entry.stars),
            const SizedBox(height: 4),
            _OddsValueBadge(
              decimalOdds: entry.decimalOdds,
              impliedProb: entry.impliedProbabilityPercent,
              displayMode: widget.displayMode,
              trend: entry.oddsTrend,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandedBreakdown() {
    final entry = widget.entry;
    final tsb = entry.rider.health.trainingStressBalance;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RAPORT SKAUTINGU PRZEDETAPOWEGO',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Indeks: ${entry.compositeScore.toStringAsFixed(1)}/100',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _FactorProgressBar(
              label: 'Profil trasy (${entry.keyMetricLabel})',
              score: entry.routeFitScore,
              color: AppColors.primaryAccent,
            ),
            const SizedBox(height: 6),
            _FactorProgressBar(
              label: 'Forma TSB (${tsb >= 0 ? '+' : ''}${tsb.round()})',
              score: entry.formTsbScore,
              color: AppColors.statusSuccess,
            ),
            const SizedBox(height: 6),
            _FactorProgressBar(
              label: 'Skład pociągu (${entry.trainSummary})',
              score: entry.trainSupportScore,
              color: AppColors.accentBlue,
            ),
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  final bool isTop;

  const _RankBadge({required this.rank, required this.isTop});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isTop
            ? AppColors.goldAccent.withValues(alpha: 0.20)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTop ? AppColors.goldAccent : AppColors.cardBorder,
          width: 1.0,
        ),
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: isTop ? AppColors.goldAccent : AppColors.textPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _CountryCodeTag extends StatelessWidget {
  final String iso;

  const _CountryCodeTag({required this.iso});

  @override
  Widget build(BuildContext context) {
    final code = iso.trim().isEmpty ? 'UCI' : iso.trim().toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Text(
        code,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _StarsRatingRow extends StatelessWidget {
  final int stars;

  const _StarsRatingRow({required this.stars});

  @override
  Widget build(BuildContext context) {
    final clamped = stars.clamp(1, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < clamped;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_border_rounded,
          size: 14,
          color: filled ? AppColors.goldAccent : AppColors.textSecondary.withValues(alpha: 0.4),
        );
      }),
    );
  }
}

class _OddsValueBadge extends StatelessWidget {
  final double decimalOdds;
  final double impliedProb;
  final OddsDisplayMode displayMode;
  final BookmakerOddsTrend trend;

  const _OddsValueBadge({
    required this.decimalOdds,
    required this.impliedProb,
    required this.displayMode,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final valueText = displayMode == OddsDisplayMode.decimalOdds
        ? decimalOdds.toStringAsFixed(2)
        : '${impliedProb.toStringAsFixed(1)}%';

    final IconData? trendIcon;
    final Color trendColor;
    switch (trend) {
      case BookmakerOddsTrend.shortening:
        trendIcon = Icons.arrow_drop_down_rounded;
        trendColor = AppColors.statusSuccess;
      case BookmakerOddsTrend.drifting:
        trendIcon = Icons.arrow_drop_up_rounded;
        trendColor = AppColors.crimsonAlert;
      case BookmakerOddsTrend.stable:
        trendIcon = null;
        trendColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trendIcon != null) ...[
            Icon(trendIcon, size: 15, color: trendColor),
            const SizedBox(width: 1),
          ],
          Text(
            valueText,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
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

class _MiniStatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniStatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _FactorProgressBar extends StatelessWidget {
  final String label;
  final double score;
  final Color color;

  const _FactorProgressBar({
    required this.label,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (score / 100.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
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
            const SizedBox(width: 8),
            Text(
              '${score.round()}%',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _OddsModePillButton extends StatefulWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _OddsModePillButton({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_OddsModePillButton> createState() => _OddsModePillButtonState();
}

class _OddsModePillButtonState extends State<_OddsModePillButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.selected
        ? AppColors.primaryAccent
        : (_hovered && widget.enabled ? AppColors.surfaceLight : AppColors.background);
    final borderColor = _focused
        ? AppColors.accentBlue
        : (widget.selected ? AppColors.primaryAccent : AppColors.cardBorder);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: MouseRegion(
          cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: widget.selected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_ActionIconButton> createState() => _ActionIconButtonState();
}

class _ActionIconButtonState extends State<_ActionIconButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        child: GestureDetector(
          onTap: widget.enabled ? widget.onTap : null,
          child: MouseRegion(
            cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _hovered && widget.enabled
                    ? AppColors.surfaceLight
                    : AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _focused ? AppColors.accentBlue : AppColors.cardBorder,
                  width: 1.0,
                ),
              ),
              child: Icon(
                widget.icon,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaTagChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaTagChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
