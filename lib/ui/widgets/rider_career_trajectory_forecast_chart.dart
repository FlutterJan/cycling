import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/rider/rider.dart';
import '../../services/career/multi_season_rider_aging_and_decline_curve.dart';
import '../../services/career/scouting_and_youth_academy_service.dart';

/// Tryb metryki prezentowanej na wykresie 5-letniej prognozy kariery.
enum ForecastMetricMode {
  ovr,
  ftp,
  both;

  String get label {
    switch (this) {
      case ForecastMetricMode.ovr:
        return 'OVR';
      case ForecastMetricMode.ftp:
        return 'FTP (W)';
      case ForecastMetricMode.both:
        return 'OVR + FTP';
    }
  }

  String toJson() => name;

  static ForecastMetricMode fromJson(String value) {
    return ForecastMetricMode.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ForecastMetricMode.ovr,
    );
  }
}

/// Pojedynczy punkt sezonowy 5-letniej prognozy rozwoju kolarza z przedziałem ufności.
class CareerTrajectoryForecastPoint {
  final int seasonIndex;
  final int seasonYear;
  final int age;
  final CareerLifecyclePhase phase;
  final double projectedOvr;
  final double ovrLowerBound;
  final double ovrUpperBound;
  final int projectedFtpWatts;
  final int ftpLowerBound;
  final int ftpUpperBound;
  final double wattsPerKg;
  final double confidenceBandOvr;
  final int confidenceBandFtp;

  const CareerTrajectoryForecastPoint({
    required this.seasonIndex,
    required this.seasonYear,
    required this.age,
    required this.phase,
    required this.projectedOvr,
    required this.ovrLowerBound,
    required this.ovrUpperBound,
    required this.projectedFtpWatts,
    required this.ftpLowerBound,
    required this.ftpUpperBound,
    required this.wattsPerKg,
    required this.confidenceBandOvr,
    required this.confidenceBandFtp,
  });

  Map<String, dynamic> toJson() => {
        'seasonIndex': seasonIndex,
        'seasonYear': seasonYear,
        'age': age,
        'phase': phase.toJson(),
        'projectedOvr': projectedOvr,
        'ovrLowerBound': ovrLowerBound,
        'ovrUpperBound': ovrUpperBound,
        'projectedFtpWatts': projectedFtpWatts,
        'ftpLowerBound': ftpLowerBound,
        'ftpUpperBound': ftpUpperBound,
        'wattsPerKg': wattsPerKg,
        'confidenceBandOvr': confidenceBandOvr,
        'confidenceBandFtp': confidenceBandFtp,
      };

  factory CareerTrajectoryForecastPoint.fromJson(Map<String, dynamic> json) {
    return CareerTrajectoryForecastPoint(
      seasonIndex: (json['seasonIndex'] as num).toInt(),
      seasonYear: (json['seasonYear'] as num).toInt(),
      age: (json['age'] as num).toInt(),
      phase: CareerLifecyclePhase.fromJson(json['phase'] as String),
      projectedOvr: (json['projectedOvr'] as num).toDouble(),
      ovrLowerBound: (json['ovrLowerBound'] as num).toDouble(),
      ovrUpperBound: (json['ovrUpperBound'] as num).toDouble(),
      projectedFtpWatts: (json['projectedFtpWatts'] as num).toInt(),
      ftpLowerBound: (json['ftpLowerBound'] as num).toInt(),
      ftpUpperBound: (json['ftpUpperBound'] as num).toInt(),
      wattsPerKg: (json['wattsPerKg'] as num).toDouble(),
      confidenceBandOvr: (json['confidenceBandOvr'] as num).toDouble(),
      confidenceBandFtp: (json['confidenceBandFtp'] as num).toInt(),
    );
  }
}

/// Pełny zestaw danych 5-letniej prognozy kariery kolarza (Sezon 0 .. Sezon +5).
class RiderCareerTrajectoryForecastData {
  final String riderId;
  final String riderName;
  final RiderSpecialization specialization;
  final int currentAge;
  final int potential;
  final double scoutAccuracy; // 0.0 .. 1.0
  final ScoutingDiscoveryStage? discoveryStage;
  final List<CareerTrajectoryForecastPoint> points;
  final double peakProjectedOvr;
  final int peakProjectedFtp;
  final int peakSeasonYear;

  const RiderCareerTrajectoryForecastData({
    required this.riderId,
    required this.riderName,
    required this.specialization,
    required this.currentAge,
    required this.potential,
    required this.scoutAccuracy,
    this.discoveryStage,
    required this.points,
    required this.peakProjectedOvr,
    required this.peakProjectedFtp,
    required this.peakSeasonYear,
  });

  int get scoutAccuracyPercent => (scoutAccuracy.clamp(0.0, 1.0) * 100).round();

  String get confidenceTierLabel {
    if (scoutAccuracy >= 0.90) return 'Wysoka pewność (Lab / Własny)';
    if (scoutAccuracy >= 0.65) return 'Średnia pewność (Skaut)';
    return 'Niska pewność (Wstępny raport)';
  }

  Color get confidenceTierColor {
    if (scoutAccuracy >= 0.90) return AppColors.statusSuccess;
    if (scoutAccuracy >= 0.65) return AppColors.accentBlue;
    return AppColors.amberWarning;
  }

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'specialization': specialization.toJson(),
        'currentAge': currentAge,
        'potential': potential,
        'scoutAccuracy': scoutAccuracy,
        'discoveryStage': discoveryStage?.toJson(),
        'points': points.map((p) => p.toJson()).toList(),
        'peakProjectedOvr': peakProjectedOvr,
        'peakProjectedFtp': peakProjectedFtp,
        'peakSeasonYear': peakSeasonYear,
      };

  factory RiderCareerTrajectoryForecastData.fromJson(Map<String, dynamic> json) {
    final rawPoints = (json['points'] as List<dynamic>? ?? const [])
        .map((e) => CareerTrajectoryForecastPoint.fromJson(e as Map<String, dynamic>))
        .toList();
    return RiderCareerTrajectoryForecastData(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      specialization: RiderSpecialization.fromJson(json['specialization'] as String),
      currentAge: (json['currentAge'] as num).toInt(),
      potential: (json['potential'] as num).toInt(),
      scoutAccuracy: (json['scoutAccuracy'] as num).toDouble(),
      discoveryStage: json['discoveryStage'] != null
          ? ScoutingDiscoveryStage.fromJson(json['discoveryStage'] as String)
          : null,
      points: rawPoints,
      peakProjectedOvr: (json['peakProjectedOvr'] as num).toDouble(),
      peakProjectedFtp: (json['peakProjectedFtp'] as num).toInt(),
      peakSeasonYear: (json['peakSeasonYear'] as num).toInt(),
    );
  }
}

/// Kalkulator 5-letniej prognozy rozwoju OVR i FTP z przedziałem ufności skauta.
class RiderCareerTrajectoryForecastCalculator {
  RiderCareerTrajectoryForecastCalculator._();

  static const int forecastHorizonSeasons = 5;

  /// Mapuje etap odkrycia skautingowego na dokładność skauta (0.0 .. 1.0).
  static double accuracyForDiscoveryStage(ScoutingDiscoveryStage stage) {
    switch (stage) {
      case ScoutingDiscoveryStage.rawTalent:
        return 0.35;
      case ScoutingDiscoveryStage.scoutedByObserver:
        return 0.72;
      case ScoutingDiscoveryStage.laboratoryTested:
        return 0.96;
    }
  }

  /// Buduje prognozę 5-letnią dla znanego kolarza (profil kolarza / rynek transferowy).
  static RiderCareerTrajectoryForecastData buildFromRider({
    required Rider rider,
    required int startSeasonYear,
    double scoutAccuracy = 0.94,
    ScoutingDiscoveryStage? discoveryStage,
    int? randomSeed,
  }) {
    final double clampedAccuracy = scoutAccuracy.clamp(0.10, 1.0);
    final int seed = randomSeed ?? rider.id.hashCode;

    final MultiSeasonCareerTrajectoryReport report =
        MultiSeasonRiderAgingAndDeclineCurve.projectTrajectory(
      rider: rider,
      startSeasonYear: startSeasonYear,
      seasons: forecastHorizonSeasons,
      randomSeed: seed,
    );

    final double weight = rider.physiology.weightKg > 0 ? rider.physiology.weightKg : 70.0;
    final List<CareerTrajectoryForecastPoint> points = [];

    double peakOvr = 0;
    int peakFtp = 0;
    int peakYear = startSeasonYear;

    for (final snap in report.snapshots) {
      // Niepewność rośnie z horyzontem (Sezon 0 -> Sezon +5) i maleje wraz z dokładnością skauta.
      final double uncertaintyFactor = 1.0 - clampedAccuracy;
      final double horizonMultiplier = 1.0 + (snap.seasonIndex * 0.28);

      // Błąd OVR: od ±0.5 (100% dokładność w roku 0) do ±13.5 (niska dokładność w roku +5).
      final double bandOvr = (0.6 + uncertaintyFactor * 14.0) * horizonMultiplier * 0.65;
      final double baseOvr = snap.overallRating.toDouble();
      final double lowOvr = (baseOvr - bandOvr).clamp(35.0, 99.0);
      final double highOvr = (baseOvr + bandOvr).clamp(35.0, 99.0);

      // Błąd FTP (W): od ±4 W do ±60 W w zależności od dokładności skauta i horyzontu.
      final int bandFtp = ((4.0 + uncertaintyFactor * 52.0) * horizonMultiplier * 0.75).round();
      final int lowFtp = math.max(150, snap.ftpWatts - bandFtp);
      final int highFtp = math.min(580, snap.ftpWatts + bandFtp);

      if (baseOvr >= peakOvr) {
        peakOvr = baseOvr;
        peakYear = snap.seasonYear;
      }
      if (snap.ftpWatts > peakFtp) {
        peakFtp = snap.ftpWatts;
      }

      points.add(
        CareerTrajectoryForecastPoint(
          seasonIndex: snap.seasonIndex,
          seasonYear: snap.seasonYear,
          age: snap.age,
          phase: snap.phase,
          projectedOvr: baseOvr,
          ovrLowerBound: lowOvr,
          ovrUpperBound: highOvr,
          projectedFtpWatts: snap.ftpWatts,
          ftpLowerBound: lowFtp,
          ftpUpperBound: highFtp,
          wattsPerKg: double.parse((snap.ftpWatts / weight).toStringAsFixed(2)),
          confidenceBandOvr: double.parse(bandOvr.toStringAsFixed(1)),
          confidenceBandFtp: bandFtp,
        ),
      );
    }

    return RiderCareerTrajectoryForecastData(
      riderId: rider.id,
      riderName: rider.fullName,
      specialization: rider.specialization,
      currentAge: rider.age,
      potential: rider.potential,
      scoutAccuracy: clampedAccuracy,
      discoveryStage: discoveryStage,
      points: points,
      peakProjectedOvr: peakOvr,
      peakProjectedFtp: peakFtp,
      peakSeasonYear: peakYear,
    );
  }

  /// Buduje prognozę 5-letnią dla adepta ze skautingu, szanując "Mgłę Wojny" (widełki skauta).
  static RiderCareerTrajectoryForecastData buildFromProspect({
    required ScoutedProspect prospect,
    required int startSeasonYear,
    double? overrideScoutAccuracy,
    int? randomSeed,
  }) {
    final double accuracy = (overrideScoutAccuracy ??
            accuracyForDiscoveryStage(prospect.discoveryStage))
        .clamp(0.10, 1.0);
    final bool isLabTested =
        prospect.discoveryStage == ScoutingDiscoveryStage.laboratoryTested;

    final Rider baseRider = prospect.trueRider;
    final MultiSeasonCareerTrajectoryReport trueReport =
        MultiSeasonRiderAgingAndDeclineCurve.projectTrajectory(
      rider: baseRider,
      startSeasonYear: startSeasonYear,
      seasons: forecastHorizonSeasons,
      randomSeed: randomSeed ?? prospect.id.hashCode,
    );

    // Jeśli talent nie przeszedł jeszcze badań w laboratorium, kotwiczymy krzywą na środku
    // estymacji skautingowej, żeby nie zdradzać ukrytych dokładnych statystyk przed badaniem.
    final int estMidFtp =
        ((prospect.estimatedMinFtpWatts + prospect.estimatedMaxFtpWatts) / 2).round();
    final int estHalfFtpSpread =
        ((prospect.estimatedMaxFtpWatts - prospect.estimatedMinFtpWatts) / 2).round();
    final int estMidPotential =
        ((prospect.estimatedMinPotential + prospect.estimatedMaxPotential) / 2).round();
    final int estHalfPotentialSpread =
        ((prospect.estimatedMaxPotential - prospect.estimatedMinPotential) / 2).round();

    final int ftpShift = isLabTested ? 0 : (estMidFtp - baseRider.physiology.ftpWatts);
    final double ovrShift =
        isLabTested ? 0.0 : ((estMidPotential - baseRider.potential) * 0.35);

    final double weight =
        baseRider.physiology.weightKg > 0 ? baseRider.physiology.weightKg : 68.0;
    final List<CareerTrajectoryForecastPoint> points = [];

    double peakOvr = 0;
    int peakFtp = 0;
    int peakYear = startSeasonYear;

    for (final snap in trueReport.snapshots) {
      final double uncertaintyFactor = 1.0 - accuracy;
      final double horizonMultiplier = 1.0 + (snap.seasonIndex * 0.30);

      final double projOvr = (snap.overallRating + ovrShift).clamp(40.0, 99.0);
      final double baseSpreadOvr = isLabTested
          ? 0.8
          : math.max(2.0, estHalfPotentialSpread * 0.45);
      final double bandOvr =
          (baseSpreadOvr + uncertaintyFactor * 9.0) * horizonMultiplier;

      final int projFtp = (snap.ftpWatts + ftpShift).clamp(160, 540);
      final int baseSpreadFtp = isLabTested ? 4 : math.max(8, estHalfFtpSpread);
      final int bandFtp =
          ((baseSpreadFtp + uncertaintyFactor * 26.0) * horizonMultiplier).round();

      final double lowOvr = (projOvr - bandOvr).clamp(35.0, 99.0);
      final double highOvr = (projOvr + bandOvr).clamp(35.0, 99.0);
      final int lowFtp = math.max(150, projFtp - bandFtp);
      final int highFtp = math.min(580, projFtp + bandFtp);

      if (projOvr >= peakOvr) {
        peakOvr = projOvr;
        peakYear = snap.seasonYear;
      }
      if (projFtp > peakFtp) {
        peakFtp = projFtp;
      }

      points.add(
        CareerTrajectoryForecastPoint(
          seasonIndex: snap.seasonIndex,
          seasonYear: snap.seasonYear,
          age: snap.age,
          phase: snap.phase,
          projectedOvr: double.parse(projOvr.toStringAsFixed(1)),
          ovrLowerBound: double.parse(lowOvr.toStringAsFixed(1)),
          ovrUpperBound: double.parse(highOvr.toStringAsFixed(1)),
          projectedFtpWatts: projFtp,
          ftpLowerBound: lowFtp,
          ftpUpperBound: highFtp,
          wattsPerKg: double.parse((projFtp / weight).toStringAsFixed(2)),
          confidenceBandOvr: double.parse(bandOvr.toStringAsFixed(1)),
          confidenceBandFtp: bandFtp,
        ),
      );
    }

    return RiderCareerTrajectoryForecastData(
      riderId: prospect.id,
      riderName: prospect.fullName,
      specialization:
          prospect.probableSpecialization ?? baseRider.specialization,
      currentAge: prospect.age,
      potential: isLabTested ? baseRider.potential : estMidPotential,
      scoutAccuracy: accuracy,
      discoveryStage: prospect.discoveryStage,
      points: points,
      peakProjectedOvr: peakOvr,
      peakProjectedFtp: peakFtp,
      peakSeasonYear: peakYear,
    );
  }
}

/// Interaktywny wykres prognozy rozwoju 5-letniego (OVR i FTP) z przedziałem ufności skauta.
class RiderCareerTrajectoryForecastChart extends StatefulWidget {
  final Rider? rider;
  final ScoutedProspect? prospect;
  final RiderCareerTrajectoryForecastData? forecastData;
  final double? scoutAccuracy;
  final int startSeasonYear;
  final ForecastMetricMode initialMetricMode;
  final bool enabled;
  final bool compact;
  final bool allowAccuracySimulation;
  final ValueChanged<CareerTrajectoryForecastPoint>? onPointSelected;

  const RiderCareerTrajectoryForecastChart({
    super.key,
    this.rider,
    this.prospect,
    this.forecastData,
    this.scoutAccuracy,
    this.startSeasonYear = 2026,
    this.initialMetricMode = ForecastMetricMode.both,
    this.enabled = true,
    this.compact = false,
    this.allowAccuracySimulation = false,
    this.onPointSelected,
  });

  @override
  State<RiderCareerTrajectoryForecastChart> createState() =>
      _RiderCareerTrajectoryForecastChartState();
}

class _RiderCareerTrajectoryForecastChartState
    extends State<RiderCareerTrajectoryForecastChart>
    with SingleTickerProviderStateMixin {
  late ForecastMetricMode _metricMode;
  late AnimationController _revealController;
  late Animation<double> _revealAnimation;
  double? _simulatedAccuracy;
  int? _hoveredIndex;
  int? _selectedIndex;
  bool _chartFocused = false;

  @override
  void initState() {
    super.initState();
    _metricMode = widget.initialMetricMode;
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutCubic,
    );
    _revealController.forward();
  }

  @override
  void didUpdateWidget(covariant RiderCareerTrajectoryForecastChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rider?.id != widget.rider?.id ||
        oldWidget.prospect?.id != widget.prospect?.id ||
        oldWidget.prospect?.discoveryStage != widget.prospect?.discoveryStage ||
        oldWidget.forecastData?.riderId != widget.forecastData?.riderId ||
        oldWidget.scoutAccuracy != widget.scoutAccuracy) {
      _hoveredIndex = null;
      _selectedIndex = null;
      _revealController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  RiderCareerTrajectoryForecastData? _resolveForecastData() {
    if (widget.forecastData != null) {
      return widget.forecastData;
    }
    if (widget.prospect != null) {
      return RiderCareerTrajectoryForecastCalculator.buildFromProspect(
        prospect: widget.prospect!,
        startSeasonYear: widget.startSeasonYear,
        overrideScoutAccuracy: _simulatedAccuracy ?? widget.scoutAccuracy,
      );
    }
    if (widget.rider != null) {
      return RiderCareerTrajectoryForecastCalculator.buildFromRider(
        rider: widget.rider!,
        startSeasonYear: widget.startSeasonYear,
        scoutAccuracy: _simulatedAccuracy ?? widget.scoutAccuracy ?? 0.94,
      );
    }
    return null;
  }

  void _selectIndex(int index, List<CareerTrajectoryForecastPoint> points) {
    if (!widget.enabled || index < 0 || index >= points.length) return;
    setState(() {
      _selectedIndex = index;
    });
    widget.onPointSelected?.call(points[index]);
  }

  @override
  Widget build(BuildContext context) {
    final data = _resolveForecastData();

    if (data == null || data.points.isEmpty) {
      return _buildEmptyState();
    }

    final int activeIndex =
        (_hoveredIndex ?? _selectedIndex ?? (data.points.length - 1))
            .clamp(0, data.points.length - 1);
    final CareerTrajectoryForecastPoint activePoint = data.points[activeIndex];

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.55,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 520;
          final bool isDesktop = constraints.maxWidth >= 900;
          final double chartHeight = widget.compact
              ? (isMobile ? 190 : 215)
              : (isMobile ? 225 : (isDesktop ? 275 : 245));

          return Container(
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _chartFocused ? AppColors.goldAccent : AppTheme.borderColor,
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(data, isMobile),
                const SizedBox(height: 12),
                if (widget.allowAccuracySimulation) ...[
                  _buildAccuracySlider(data, isMobile),
                  const SizedBox(height: 10),
                ],
                _buildLegendRow(data, isMobile),
                const SizedBox(height: 10),
                _buildInteractiveChart(
                  data: data,
                  activeIndex: activeIndex,
                  chartHeight: chartHeight,
                ),
                const SizedBox(height: 12),
                _buildSeasonInspectorStrip(
                  data: data,
                  point: activePoint,
                  isMobile: isMobile,
                  isDesktop: isDesktop,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: const Row(
        children: [
          Icon(Icons.timeline_rounded, color: AppColors.textSecondary, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Brak danych kolarza do wygenerowania 5-letniej prognozy rozwoju.',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(RiderCareerTrajectoryForecastData data, bool isMobile) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_graph_rounded, color: AppColors.goldAccent, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'PROGNOZA ROZWOJU 5-LETNIEGO (OVR & FTP)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${data.riderName} • ${data.currentAge} lat',
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: data.confidenceTierColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: data.confidenceTierColor.withValues(alpha: 0.45),
                  width: 1.0,
                ),
              ),
              child: Text(
                'Skaut: ${data.scoutAccuracyPercent}%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: data.confidenceTierColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [ui.FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ],
    );

    final modeSelector = Wrap(
      spacing: 6,
      runSpacing: 6,
      children: ForecastMetricMode.values.map((mode) {
        return _ForecastModeChip(
          label: mode.label,
          selected: _metricMode == mode,
          enabled: widget.enabled,
          onTap: () {
            if (!widget.enabled) return;
            setState(() => _metricMode = mode);
          },
        );
      }).toList(),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: 10),
          modeSelector,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 12),
        modeSelector,
      ],
    );
  }

  Widget _buildAccuracySlider(
    RiderCareerTrajectoryForecastData data,
    bool isMobile,
  ) {
    final double currentVal = _simulatedAccuracy ?? data.scoutAccuracy;
    final labelRow = Row(
      mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
      children: [
        const Icon(Icons.radar_rounded, size: 15, color: AppColors.accentBlue),
        const SizedBox(width: 8),
        if (isMobile)
          const Expanded(
            child: Text(
              'Dokładność skauta:',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          )
        else
          const Text(
            'Dokładność skauta:',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (isMobile)
          Text(
            '${(currentVal * 100).round()}%',
            style: TextStyle(
              fontFamily: 'Inter',
              color: data.confidenceTierColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              fontFeatures: const [ui.FontFeature.tabularFigures()],
            ),
          ),
      ],
    );

    final sliderWidget = SliderTheme(
      data: SliderThemeData(
        activeTrackColor: data.confidenceTierColor,
        inactiveTrackColor: AppTheme.borderColor,
        thumbColor: data.confidenceTierColor,
        overlayColor: data.confidenceTierColor.withValues(alpha: 0.16),
        trackHeight: 3,
      ),
      child: Slider(
        value: currentVal.clamp(0.20, 1.0),
        min: 0.20,
        max: 1.0,
        divisions: 16,
        onChanged: widget.enabled
            ? (val) => setState(() => _simulatedAccuracy = val)
            : null,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                labelRow,
                sliderWidget,
              ],
            )
          : Row(
              children: [
                labelRow,
                Expanded(child: sliderWidget),
                Text(
                  '${(currentVal * 100).round()}%',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: data.confidenceTierColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [ui.FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLegendRow(RiderCareerTrajectoryForecastData data, bool isMobile) {
    return Wrap(
      spacing: isMobile ? 10 : 16,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (_metricMode != ForecastMetricMode.ftp)
          const _LegendItem(
            color: AppColors.goldAccent,
            label: 'Prognoza OVR',
            isBand: false,
          ),
        if (_metricMode != ForecastMetricMode.ovr)
          const _LegendItem(
            color: AppColors.accentBlue,
            label: 'Prognoza FTP (W)',
            isBand: false,
          ),
        _LegendItem(
          color: _metricMode == ForecastMetricMode.ftp
              ? AppColors.accentBlue
              : AppColors.goldAccent,
          label: 'Przedział ufności (±${100 - data.scoutAccuracyPercent}% niepewności)',
          isBand: true,
        ),
      ],
    );
  }

  Widget _buildInteractiveChart({
    required RiderCareerTrajectoryForecastData data,
    required int activeIndex,
    required double chartHeight,
  }) {
    return Focus(
      onFocusChange: (focused) => setState(() => _chartFocused = focused),
      onKeyEvent: (node, event) {
        if (!widget.enabled || event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _selectIndex(
            math.min(data.points.length - 1, activeIndex + 1),
            data.points,
          );
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _selectIndex(math.max(0, activeIndex - 1), data.points);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          return MouseRegion(
            cursor: widget.enabled
                ? SystemMouseCursors.precise
                : SystemMouseCursors.basic,
            onExit: (_) => setState(() => _hoveredIndex = null),
            onHover: (event) {
              if (!widget.enabled) return;
              final idx = _hitTestSeasonIndex(
                event.localPosition.dx,
                width,
                data.points.length,
              );
              if (idx != _hoveredIndex) {
                setState(() => _hoveredIndex = idx);
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                if (!widget.enabled) return;
                final idx = _hitTestSeasonIndex(
                  details.localPosition.dx,
                  width,
                  data.points.length,
                );
                _selectIndex(idx, data.points);
              },
              onHorizontalDragUpdate: (details) {
                if (!widget.enabled) return;
                final idx = _hitTestSeasonIndex(
                  details.localPosition.dx,
                  width,
                  data.points.length,
                );
                if (idx != _selectedIndex) {
                  _selectIndex(idx, data.points);
                }
              },
              child: Container(
                height: chartHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor, width: 1.0),
                ),
                child: AnimatedBuilder(
                  animation: _revealAnimation,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _CareerTrajectoryForecastPainter(
                        points: data.points,
                        metricMode: _metricMode,
                        activeIndex: activeIndex,
                        revealProgress: _revealAnimation.value,
                        scoutAccuracy: data.scoutAccuracy,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  int _hitTestSeasonIndex(double localX, double totalWidth, int count) {
    if (count <= 1) return 0;
    const double leftPad = 46.0;
    const double rightPad = 24.0;
    final double usableWidth = math.max(1.0, totalWidth - leftPad - rightPad);
    final double ratio = ((localX - leftPad) / usableWidth).clamp(0.0, 1.0);
    return (ratio * (count - 1)).round().clamp(0, count - 1);
  }

  Widget _buildSeasonInspectorStrip({
    required RiderCareerTrajectoryForecastData data,
    required CareerTrajectoryForecastPoint point,
    required bool isMobile,
    required bool isDesktop,
  }) {
    final tiles = [
      _InspectorMetricTile(
        label: 'SEZON / WIEK',
        value: '${point.seasonYear} (${point.age} l.)',
        subValue: point.phase.displayName,
        accent: point.phase.accentColor,
      ),
      _InspectorMetricTile(
        label: 'PROGNOZA OVR',
        value: point.projectedOvr.toStringAsFixed(0),
        subValue:
            'Przedział: ${point.ovrLowerBound.toStringAsFixed(0)}–${point.ovrUpperBound.toStringAsFixed(0)} (±${point.confidenceBandOvr.toStringAsFixed(1)})',
        accent: AppColors.goldAccent,
      ),
      _InspectorMetricTile(
        label: 'PROGNOZA FTP',
        value: '${point.projectedFtpWatts} W',
        subValue:
            'Przedział: ${point.ftpLowerBound}–${point.ftpUpperBound} W (${point.wattsPerKg.toStringAsFixed(2)} W/kg)',
        accent: AppColors.accentBlue,
      ),
      _InspectorMetricTile(
        label: 'SZCZYT KARIERY (5L)',
        value: '${data.peakProjectedOvr.toStringAsFixed(0)} OVR / ${data.peakProjectedFtp} W',
        subValue: 'Szczyt w sezonie ${data.peakSeasonYear}',
        accent: AppColors.statusSuccess,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            Expanded(child: tiles[i]),
            if (i < tiles.length - 1) const SizedBox(width: 10),
          ],
        ],
      );
    }

    // 2x2 grid na tablet i mobile (390x844 i 1024x768) bez ryzyka overflow
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: tiles[0]),
            const SizedBox(width: 8),
            Expanded(child: tiles[1]),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: tiles[2]),
            const SizedBox(width: 8),
            Expanded(child: tiles[3]),
          ],
        ),
      ],
    );
  }
}

class _ForecastModeChip extends StatefulWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _ForecastModeChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_ForecastModeChip> createState() => _ForecastModeChipState();
}

class _ForecastModeChipState extends State<_ForecastModeChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = widget.selected
        ? AppColors.primaryAccent.withValues(alpha: 0.35)
        : (_pressed
            ? AppColors.surfaceLight
            : (_hovered ? AppColors.surfaceLight.withValues(alpha: 0.85) : AppColors.background));

    final Color borderColor = widget.selected
        ? AppColors.goldAccent
        : (_focused ? AppColors.accentBlue : AppTheme.borderColor);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              color: widget.selected ? AppColors.goldAccent : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: widget.selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isBand;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.isBand,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: isBand ? 10 : 3,
          decoration: BoxDecoration(
            color: isBand ? color.withValues(alpha: 0.25) : color,
            borderRadius: BorderRadius.circular(2),
            border: isBand
                ? Border.all(color: color.withValues(alpha: 0.65), width: 1)
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _InspectorMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final Color accent;

  const _InspectorMetricTile({
    required this.label,
    required this.value,
    required this.subValue,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              color: accent,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFeatures: [ui.FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 10,
              fontFeatures: [ui.FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CareerTrajectoryForecastPainter extends CustomPainter {
  final List<CareerTrajectoryForecastPoint> points;
  final ForecastMetricMode metricMode;
  final int activeIndex;
  final double revealProgress;
  final double scoutAccuracy;

  _CareerTrajectoryForecastPainter({
    required this.points,
    required this.metricMode,
    required this.activeIndex,
    required this.revealProgress,
    required this.scoutAccuracy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.width <= 0 || size.height <= 0) return;

    const double leftPad = 46.0;
    const double rightPad = 24.0;
    const double topPad = 18.0;
    const double bottomPad = 32.0;

    final double plotWidth = math.max(1.0, size.width - leftPad - rightPad);
    final double plotHeight = math.max(1.0, size.height - topPad - bottomPad);

    // Wyznaczanie zakresów osi Y
    double minOvr = 100.0;
    double maxOvr = 40.0;
    double minFtp = 600.0;
    double maxFtp = 150.0;

    for (final p in points) {
      minOvr = math.min(minOvr, p.ovrLowerBound);
      maxOvr = math.max(maxOvr, p.ovrUpperBound);
      minFtp = math.min(minFtp, p.ftpLowerBound.toDouble());
      maxFtp = math.max(maxFtp, p.ftpUpperBound.toDouble());
    }

    minOvr = (minOvr - 4.0).clamp(30.0, 90.0);
    maxOvr = (maxOvr + 4.0).clamp(minOvr + 10.0, 100.0);
    minFtp = (minFtp - 20.0).clamp(120.0, 480.0);
    maxFtp = (maxFtp + 20.0).clamp(minFtp + 40.0, 580.0);

    double xForIndex(int i) {
      if (points.length <= 1) return leftPad + plotWidth / 2;
      return leftPad + (i / (points.length - 1)) * plotWidth;
    }

    double yForOvr(double ovr) {
      final norm = ((ovr - minOvr) / (maxOvr - minOvr)).clamp(0.0, 1.0);
      return topPad + plotHeight * (1.0 - norm);
    }

    double yForFtp(double ftp) {
      final norm = ((ftp - minFtp) / (maxFtp - minFtp)).clamp(0.0, 1.0);
      return topPad + plotHeight * (1.0 - norm);
    }

    // Siatka pozioma i etykiety osi Y
    final gridPaint = Paint()
      ..color = AppTheme.borderColor.withValues(alpha: 0.55)
      ..strokeWidth = 1.0;

    const int gridRows = 4;
    for (int r = 0; r <= gridRows; r++) {
      final double y = topPad + (r / gridRows) * plotHeight;
      canvas.drawLine(Offset(leftPad, y), Offset(leftPad + plotWidth, y), gridPaint);

      final double frac = 1.0 - (r / gridRows);
      final String yLabel = metricMode == ForecastMetricMode.ftp
          ? '${(minFtp + frac * (maxFtp - minFtp)).round()}W'
          : '${(minOvr + frac * (maxOvr - minOvr)).round()}';

      final tp = TextPainter(
        text: TextSpan(
          text: yLabel,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textSecondary,
            fontSize: 10,
            fontFeatures: [ui.FontFeature.tabularFigures()],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 6, y - tp.height / 2));
    }

    // Etykiety osi X (Sezon i wiek)
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final double x = xForIndex(i);
      final bool isActive = i == activeIndex;
      final label = i == 0 ? '${p.seasonYear}' : '+${p.seasonIndex} (${p.age}l)';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontFamily: 'Inter',
            color: isActive ? AppColors.goldAccent : AppColors.textSecondary,
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontFeatures: const [ui.FontFeature.tabularFigures()],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, topPad + plotHeight + 8));
    }

    // Clip animacji odsłaniania od lewej do prawej
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(
        0,
        0,
        leftPad + plotWidth * revealProgress + rightPad,
        size.height,
      ),
    );

    if (metricMode == ForecastMetricMode.ftp || metricMode == ForecastMetricMode.both) {
      _drawConfidenceBandAndLine(
        canvas: canvas,
        points: points,
        xForIndex: xForIndex,
        yForUpper: (p) => yForFtp(p.ftpUpperBound.toDouble()),
        yForLower: (p) => yForFtp(p.ftpLowerBound.toDouble()),
        yForMain: (p) => yForFtp(p.projectedFtpWatts.toDouble()),
        color: AppColors.accentBlue,
        bandAlpha: 0.14 + (1.0 - scoutAccuracy) * 0.12,
      );
    }

    if (metricMode == ForecastMetricMode.ovr || metricMode == ForecastMetricMode.both) {
      _drawConfidenceBandAndLine(
        canvas: canvas,
        points: points,
        xForIndex: xForIndex,
        yForUpper: (p) => yForOvr(p.ovrUpperBound),
        yForLower: (p) => yForOvr(p.ovrLowerBound),
        yForMain: (p) => yForOvr(p.projectedOvr),
        color: AppColors.goldAccent,
        bandAlpha: 0.18 + (1.0 - scoutAccuracy) * 0.12,
      );
    }

    canvas.restore();

    // Linia krzyżowa i podświetlony punkt aktywny
    final double activeX = xForIndex(activeIndex);
    final crosshairPaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.45)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(activeX, topPad),
      Offset(activeX, topPad + plotHeight),
      crosshairPaint,
    );

    final activePoint = points[activeIndex];
    if (metricMode != ForecastMetricMode.ovr) {
      _drawNode(
        canvas,
        Offset(activeX, yForFtp(activePoint.projectedFtpWatts.toDouble())),
        AppColors.accentBlue,
      );
    }
    if (metricMode != ForecastMetricMode.ftp) {
      _drawNode(
        canvas,
        Offset(activeX, yForOvr(activePoint.projectedOvr)),
        AppColors.goldAccent,
      );
    }
  }

  void _drawConfidenceBandAndLine({
    required Canvas canvas,
    required List<CareerTrajectoryForecastPoint> points,
    required double Function(int) xForIndex,
    required double Function(CareerTrajectoryForecastPoint) yForUpper,
    required double Function(CareerTrajectoryForecastPoint) yForLower,
    required double Function(CareerTrajectoryForecastPoint) yForMain,
    required Color color,
    required double bandAlpha,
  }) {
    if (points.length < 2) return;

    // 1. Wypełnienie przedziału ufności (polygon upper -> reverse lower)
    final bandPath = Path()..moveTo(xForIndex(0), yForUpper(points[0]));
    for (int i = 1; i < points.length; i++) {
      bandPath.lineTo(xForIndex(i), yForUpper(points[i]));
    }
    for (int i = points.length - 1; i >= 0; i--) {
      bandPath.lineTo(xForIndex(i), yForLower(points[i]));
    }
    bandPath.close();

    final bandPaint = Paint()
      ..color = color.withValues(alpha: bandAlpha.clamp(0.08, 0.35))
      ..style = PaintingStyle.fill;
    canvas.drawPath(bandPath, bandPaint);

    // 2. Krawędzie górna i dolna przedziału ufności
    final boundPaint = Paint()
      ..color = color.withValues(alpha: 0.40)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final upperPath = Path()..moveTo(xForIndex(0), yForUpper(points[0]));
    final lowerPath = Path()..moveTo(xForIndex(0), yForLower(points[0]));
    for (int i = 1; i < points.length; i++) {
      upperPath.lineTo(xForIndex(i), yForUpper(points[i]));
      lowerPath.lineTo(xForIndex(i), yForLower(points[i]));
    }
    canvas.drawPath(upperPath, boundPaint);
    canvas.drawPath(lowerPath, boundPaint);

    // 3. Główna krzywa prognozy (gładki spline)
    final linePath = Path()..moveTo(xForIndex(0), yForMain(points[0]));
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = Offset(xForIndex(i), yForMain(points[i]));
      final p1 = Offset(xForIndex(i + 1), yForMain(points[i + 1]));
      final midX = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(linePath, linePaint);

    // Węzły sezonowe
    final dotPaint = Paint()..color = color;
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(Offset(xForIndex(i), yForMain(points[i])), 3.2, dotPaint);
    }
  }

  void _drawNode(Canvas canvas, Offset center, Color color) {
    canvas.drawCircle(
      center,
      7.0,
      Paint()..color = color.withValues(alpha: 0.25),
    );
    canvas.drawCircle(
      center,
      4.5,
      Paint()..color = color,
    );
    canvas.drawCircle(
      center,
      2.0,
      Paint()..color = AppColors.background,
    );
  }

  @override
  bool shouldRepaint(covariant _CareerTrajectoryForecastPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.metricMode != metricMode ||
        oldDelegate.activeIndex != activeIndex ||
        oldDelegate.revealProgress != revealProgress ||
        oldDelegate.scoutAccuracy != scoutAccuracy;
  }
}
