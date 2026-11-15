// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/peloton/rider_race_state.dart';
import '../../engine/simulation/stage_replay_recorder.dart';
import '../../models/race/race_stage.dart';
import '../../models/rider/rider.dart';
import '../widgets/rider_avatar_painter.dart';

// ============================================================================
// 1. ROZKŁAD STREF MOCY Z1-Z7 (DR. ANDREW COGGAN POWER ZONES)
// ============================================================================

/// Model czasu i procentowego udziału kolarza w 7 strefach mocy.
class CogganPowerZonesAnalysis {
  final int ftpWatts;
  final Map<int, double> zoneSeconds;
  final double totalSeconds;

  const CogganPowerZonesAnalysis({
    required this.ftpWatts,
    required this.zoneSeconds,
    required this.totalSeconds,
  });

  /// Wylicza rozkład stref mocy z próbek telemetrycznych kolarza.
  factory CogganPowerZonesAnalysis.fromPoints(List<RiderTelemetryTrackPoint> points, {int ftpWatts = 400}) {
    final Map<int, double> secondsInZone = {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0, 5: 0.0, 6: 0.0, 7: 0.0};
    double totalSec = 0.0;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final double dt = (i > 0)
          ? math.max(0.1, p.timestampSeconds - points[i - 1].timestampSeconds)
          : 1.0;
      totalSec += dt;

      final double ratio = p.powerWatts / ftpWatts.toDouble();
      int zone = 1;
      if (ratio < 0.55) {
        zone = 1; // Active Recovery
      } else if (ratio < 0.75) {
        zone = 2; // Endurance
      } else if (ratio < 0.90) {
        zone = 3; // Tempo
      } else if (ratio < 1.05) {
        zone = 4; // Lactate Threshold / FTP
      } else if (ratio < 1.20) {
        zone = 5; // VO2 Max
      } else if (ratio < 1.50) {
        zone = 6; // Anaerobic Capacity
      } else {
        zone = 7; // Neuromuscular Sprint
      }

      secondsInZone[zone] = (secondsInZone[zone] ?? 0.0) + dt;
    }

    return CogganPowerZonesAnalysis(
      ftpWatts: ftpWatts,
      zoneSeconds: secondsInZone,
      totalSeconds: totalSec > 0 ? totalSec : 1.0,
    );
  }

  double getSeconds(int zone) => zoneSeconds[zone] ?? 0.0;

  double getPercentage(int zone) {
    if (totalSeconds <= 0) return 0.0;
    return ((zoneSeconds[zone] ?? 0.0) / totalSeconds) * 100.0;
  }

  String getPowerRangeLabel(int zone) {
    switch (zone) {
      case 1:
        return '< ${(ftpWatts * 0.55).round()} W';
      case 2:
        return '${(ftpWatts * 0.55).round()} - ${(ftpWatts * 0.75).round()} W';
      case 3:
        return '${(ftpWatts * 0.76).round()} - ${(ftpWatts * 0.90).round()} W';
      case 4:
        return '${(ftpWatts * 0.91).round()} - ${(ftpWatts * 1.05).round()} W';
      case 5:
        return '${(ftpWatts * 1.06).round()} - ${(ftpWatts * 1.20).round()} W';
      case 6:
        return '${(ftpWatts * 1.21).round()} - ${(ftpWatts * 1.50).round()} W';
      case 7:
        return '> ${(ftpWatts * 1.50).round()} W';
      default:
        return '';
    }
  }

  static String getZoneName(int zone) {
    switch (zone) {
      case 1:
        return 'Z1 Aktywna Regeneracja';
      case 2:
        return 'Z2 Wytrzymałość Tlenowa';
      case 3:
        return 'Z3 Tempo';
      case 4:
        return 'Z4 Próg Mleczanowy (FTP)';
      case 5:
        return 'Z5 Pułap Tlenowy (VO₂max)';
      case 6:
        return 'Z6 Pojemność Beztlenowa';
      case 7:
        return 'Z7 Moc Neuromięśniowa (Sprint)';
      default:
        return 'Strefa $zone';
    }
  }
}

// ============================================================================
// 2. GŁÓWNY EKRAN ANALIZY POWYŚCIGOWEJ (STRAVA STYLE STAGE ANALYSIS SCREEN)
// ============================================================================

/// Zaawansowany ekran szczegółowej analizy telemetrycznej etapu dla kolarzy drużyny gracza.
///
/// Wzorowany na platformach Garmin Connect, TrainingPeaks, Strava oraz WKO5.
/// Zawiera interaktywne nałożone wykresy wysokości, mocy (W), tętna (bpm), zapasu W' (kJ)
/// oraz kadencji z całego etapu, strefy mocy Z1-Z7, Normalized Power (NP), TSS i eksport .FIT.
class StravaStyleStageAnalysisScreen extends StatefulWidget {
  final StageReplayRecorder? recorder;
  final List<RiderTelemetryLog>? logs;
  final List<Rider>? playerRiders;
  final RaceStage? stage;
  final String stageName;
  final String? initialSelectedRiderId;
  final VoidCallback? onClose;
  final void Function(ReplayClip clip)? onReplayClipSelected;

  const StravaStyleStageAnalysisScreen({
    super.key,
    this.recorder,
    this.logs,
    this.playerRiders,
    this.stage,
    this.stageName = 'Królewski Etap Górski • Alpe d\'Huez',
    this.initialSelectedRiderId,
    this.onClose,
    this.onReplayClipSelected,
  });

  @override
  State<StravaStyleStageAnalysisScreen> createState() => _StravaStyleStageAnalysisScreenState();
}

class _StravaStyleStageAnalysisScreenState extends State<StravaStyleStageAnalysisScreen> {
  late List<RiderTelemetryLog> _riderLogs;
  late String _selectedRiderId;

  // Przełączniki widoczności serii na wykresie
  bool _showElevation = true;
  bool _showPower = true;
  bool _showHeartRate = true;
  bool _showWPrime = true;
  bool _showCadence = false;

  // Interaktywny kursor scrubbera (0.0 do 1.0 wzdłuż osi dystansu)
  double? _scrubFraction;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (widget.logs != null && widget.logs!.isNotEmpty) {
      _riderLogs = widget.logs!;
    } else if (widget.recorder != null && widget.recorder!.riderLogs.isNotEmpty) {
      _riderLogs = widget.recorder!.riderLogs.values.toList();
    } else {
      // Fallback: generowanie realistycznej demonstracyjnej telemetrii zespołu
      _riderLogs = _generateDemoRiderLogs();
    }

    if (widget.initialSelectedRiderId != null &&
        _riderLogs.any((l) => l.riderId == widget.initialSelectedRiderId)) {
      _selectedRiderId = widget.initialSelectedRiderId!;
    } else {
      _selectedRiderId = _riderLogs.first.riderId;
    }
  }

  RiderTelemetryLog get _currentLog =>
      _riderLogs.firstWhere((l) => l.riderId == _selectedRiderId, orElse: () => _riderLogs.first);

  Rider? _findRiderModel(String riderId) {
    if (widget.playerRiders == null) return null;
    for (final r in widget.playerRiders!) {
      if (r.id == riderId) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final log = _currentLog;
    final summary = log.computeFitSummary(stageName: widget.stageName);
    final zones = CogganPowerZonesAnalysis.fromPoints(log.points, ftpWatts: log.ftpWatts);
    final riderModel = _findRiderModel(log.riderId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(summary),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Poziomy selektor kolarzy drużyny
            _buildRiderSelectorBar(),

            // 2. Główna przewijana zawartość analizy telemetrycznej
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Karta nagłówkowa kolarza i profilu
                    _buildRiderHeroCard(log, summary, riderModel),
                    const SizedBox(height: 16),

                    // Kafelki kluczowych metryk (NP, IF, TSS, Praca, Tętno, VAM)
                    _buildKeyMetricsGrid(summary, log),
                    const SizedBox(height: 20),

                    // Główny interaktywny wykres telemetrii (Moc, Tętno, W', Wysokość, Kadencja)
                    _buildInteractiveTelemetryChartCard(log),
                    const SizedBox(height: 24),

                    // Dolna sekcja: Rozkład Stref Mocy Z1-Z7 oraz Krzywa Szczytowa (Peak Power)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isWide = constraints.maxWidth >= 720;
                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: _buildPowerZonesCard(zones)),
                              const SizedBox(width: 16),
                              Expanded(flex: 4, child: _buildPeakPowerCurveCard(summary)),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildPowerZonesCard(zones),
                              const SizedBox(height: 16),
                              _buildPeakPowerCurveCard(summary),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // WIDŻETY: PASKI, KARTY, WYKRESY
  // ============================================================================

  PreferredSizeWidget _buildAppBar(FitActivitySummary summary) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
        onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
        tooltip: 'Wróć',
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFC4C02).withValues(alpha: 0.15), // Strava Orange
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFC4C02).withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insights_rounded, color: Color(0xFFFC4C02), size: 16),
                SizedBox(width: 6),
                Text(
                  'STRAVA / GARMIN FIT',
                  style: TextStyle(
                    color: Color(0xFFFC4C02),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.stageName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        // Przycisk pobrania pliku .FIT
        OutlinedButton.icon(
          onPressed: () => _showFitExportDialog(summary),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.accentBlue),
            foregroundColor: AppColors.accentBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          icon: const Icon(Icons.file_download_outlined, size: 18),
          label: const Text('Eksport .FIT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),

        // Przycisk powtórki 3D (jeśli dostępny rejestrator z finiszem)
        if (widget.recorder != null && widget.recorder!.hasFinalKmReplay)
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              onPressed: () {
                final clip = widget.recorder!.buildFinalKilometerClip();
                if (clip != null && widget.onReplayClipSelected != null) {
                  widget.onReplayClipSelected!(clip);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.play_circle_filled_rounded, size: 18),
              label: const Text('Finisz 3D', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }

  /// Pasek poziomego wyboru kolarzy z drużyny gracza.
  Widget _buildRiderSelectorBar() {
    return Container(
      height: 74,
      width: double.infinity,
      color: AppColors.surface.withValues(alpha: 0.95),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        scrollDirection: Axis.horizontal,
        itemCount: _riderLogs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final log = _riderLogs[index];
          final bool isSelected = log.riderId == _selectedRiderId;
          final riderModel = _findRiderModel(log.riderId);

          return InkWell(
            onTap: () {
              setState(() {
                _selectedRiderId = log.riderId;
                _scrubFraction = null;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.surfaceLight : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.accentBlue : AppTheme.borderColor,
                  width: isSelected ? 1.8 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: isSelected ? AppColors.accentBlue : AppColors.cardBorder,
                    child: riderModel != null
                        ? ClipOval(
                            child: RiderAvatarWidget(
                              appearance: riderModel.appearance,
                              size: 32,
                            ),
                          )
                        : Text(
                            '#${log.bibNumber}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.riderName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      Text(
                        'FTP ${log.ftpWatts} W • #${log.bibNumber}',
                        style: TextStyle(
                          color: isSelected ? AppColors.cyanAccent : AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Karta nagłówkowa wybranego kolarza z kluczowymi informacjami.
  Widget _buildRiderHeroCard(RiderTelemetryLog log, FitActivitySummary summary, Rider? rider) {
    final double weightKg = rider?.physiology.weightKg ?? 70.0;
    final double wPerKg = weightKg > 0 ? (summary.avgPowerWatts / weightKg) : 0.0;
    final double npWPerKg = weightKg > 0 ? (summary.normalizedPowerWatts / weightKg) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Portret kolarza
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.goldAccent, width: 2.0),
            ),
            child: ClipOval(
              child: rider != null
                  ? RiderAvatarWidget(appearance: rider.appearance, size: 64)
                  : const Icon(Icons.directions_bike_rounded, color: AppColors.goldAccent, size: 36),
            ),
          ),
          const SizedBox(width: 16),

          // Dane kolarza i zespołu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        log.riderName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#${log.bibNumber}',
                        style: const TextStyle(
                          color: AppColors.accentBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${log.teamName} • ${rider?.specialization.displayName ?? "Zawodnik"}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _buildPillTag('FTP', '${log.ftpWatts} W (${(log.ftpWatts / weightKg).toStringAsFixed(1)} W/kg)', AppColors.goldAccent),
                    _buildPillTag('NP', '${summary.normalizedPowerWatts} W (${npWPerKg.toStringAsFixed(1)} W/kg)', AppColors.powerZone7),
                    _buildPillTag('Śr. Moc', '${summary.avgPowerWatts} W (${wPerKg.toStringAsFixed(1)} W/kg)', AppColors.cyanAccent),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillTag(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  /// Kafelki 8 kluczowych metryk (Normalized Power, TSS, IF, Dystans, Kalorie, Tętno itd.).
  Widget _buildKeyMetricsGrid(FitActivitySummary summary, RiderTelemetryLog log) {
    final String timeStr = _formatDuration(summary.totalTimeSeconds);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = (constraints.maxWidth - 36) / 4;
        final bool useCompact = cardWidth < 140;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildMetricTile('DYSTANS', '${summary.totalDistanceKm.toStringAsFixed(1)} km', 'Czas: $timeStr', Icons.route_rounded, AppColors.cyanAccent, useCompact ? null : cardWidth),
            _buildMetricTile('NORMALIZED POWER', '${summary.normalizedPowerWatts} W', 'IF: ${summary.intensityFactor.toStringAsFixed(2)} • VI: ${summary.variabilityIndex.toStringAsFixed(2)}', Icons.bolt_rounded, AppColors.powerZone7, useCompact ? null : cardWidth),
            _buildMetricTile('TSS (OBCIĄŻENIE)', summary.trainingStressScore.toStringAsFixed(0), _getTssLoadLabel(summary.trainingStressScore), Icons.fitness_center_rounded, AppColors.powerZone5, useCompact ? null : cardWidth),
            _buildMetricTile('PRACA & KALORIE', '${summary.totalWorkKj.toStringAsFixed(0)} kJ', '${summary.caloriesKcal} kcal spalonych', Icons.local_fire_department_rounded, AppColors.crimsonAlert, useCompact ? null : cardWidth),
            _buildMetricTile('ŚREDNIA PRĘDKOŚĆ', '${summary.avgSpeedKmh.toStringAsFixed(1)} km/h', 'Max: ${summary.maxSpeedKmh.toStringAsFixed(1)} km/h', Icons.speed_rounded, AppColors.accentBlue, useCompact ? null : cardWidth),
            _buildMetricTile('TĘTNO ŚREDNIE', '${summary.avgHeartRateBpm} bpm', 'Max: ${summary.maxHeartRateBpm} bpm', Icons.favorite_rounded, const Color(0xFFEF4444), useCompact ? null : cardWidth),
            _buildMetricTile('ŚREDNIA KADENCJA', '${summary.avgCadenceRpm} RPM', 'Max: ${summary.maxCadenceRpm} RPM', Icons.sync_rounded, AppColors.emeraldGreen, useCompact ? null : cardWidth),
            _buildMetricTile('PRZEWYŻSZENIE', '+${summary.elevationGainMeters.toStringAsFixed(0)} m', summary.vamMetersPerHour > 100 ? 'VAM: ${summary.vamMetersPerHour.toStringAsFixed(0)} m/h' : '-${summary.elevationLossMeters.toStringAsFixed(0)} m', Icons.terrain_rounded, AppColors.goldAccent, useCompact ? null : cardWidth),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile(String label, String mainValue, String subValue, IconData icon, Color color, double? width) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            mainValue,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getTssLoadLabel(double tss) {
    if (tss >= 300) return 'Ekstremalny wysiłek';
    if (tss >= 200) return 'Bardzo wysokie obciążenie';
    if (tss >= 150) return 'Wysokie obciążenie';
    if (tss >= 100) return 'Umiarkowane zmęczenie';
    return 'Lekki wysiłek';
  }

  // ============================================================================
  // GŁÓWNY MULTI-SERIES WYKRES TELEMETRII (MOC, TĘTNO, W', WYSOKOŚĆ, KADENCJA)
  // ============================================================================

  Widget _buildInteractiveTelemetryChartCard(RiderTelemetryLog log) {
    if (log.points.isEmpty) {
      return const SizedBox.shrink();
    }

    final int pointCount = log.points.length;
    final int scrubIndex = _scrubFraction != null
        ? (_scrubFraction! * (pointCount - 1)).round().clamp(0, pointCount - 1)
        : pointCount - 1;
    final RiderTelemetryTrackPoint activePoint = log.points[scrubIndex];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nagłówek wykresu i przełączniki serii
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.timeline_rounded, color: AppColors.cyanAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'TELEMETRIA Z CAŁEGO ETAPU',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Text(
                'Przesuń palcem, by badać parametry',
                style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.8), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Przełączniki widoczności poszczególnych linii wykresu
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSeriesToggleChip('Wysokość', _showElevation, const Color(0xFF64748B), (v) => setState(() => _showElevation = v)),
              _buildSeriesToggleChip('Moc [W]', _showPower, AppColors.powerZone7, (v) => setState(() => _showPower = v)),
              _buildSeriesToggleChip('Tętno [bpm]', _showHeartRate, const Color(0xFFEF4444), (v) => setState(() => _showHeartRate = v)),
              _buildSeriesToggleChip('Zapas W\' [kJ]', _showWPrime, AppColors.goldAccent, (v) => setState(() => _showWPrime = v)),
              _buildSeriesToggleChip('Kadencja [RPM]', _showCadence, AppColors.emeraldGreen, (v) => setState(() => _showCadence = v)),
            ],
          ),
          const SizedBox(height: 14),

          // Dynamiczny odczyt w punkcie kursora scrubbera
          _buildScrubberLiveReadout(activePoint),
          const SizedBox(height: 12),

          // Płótno Canvas z nałożonymi krzywymi telemetrycznymi i obsługą gestów dotykowych
          SizedBox(
            height: 240,
            width: double.infinity,
            child: GestureDetector(
              onHorizontalDragStart: (details) => _handleScrubUpdate(details.localPosition.dx),
              onHorizontalDragUpdate: (details) => _handleScrubUpdate(details.localPosition.dx),
              onHorizontalDragEnd: (_) {},
              onTapDown: (details) => _handleScrubUpdate(details.localPosition.dx),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomPaint(
                  painter: _MultiSeriesTelemetryChartPainter(
                    points: log.points,
                    showElevation: _showElevation,
                    showPower: _showPower,
                    showHeartRate: _showHeartRate,
                    showWPrime: _showWPrime,
                    showCadence: _showCadence,
                    scrubFraction: _scrubFraction,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Oś dolna z kilometrami
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('0.0 km', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
              Text(
                '${(log.points.last.distanceKm * 0.25).toStringAsFixed(1)} km',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
              Text(
                '${(log.points.last.distanceKm * 0.50).toStringAsFixed(1)} km',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
              Text(
                '${(log.points.last.distanceKm * 0.75).toStringAsFixed(1)} km',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
              Text(
                'META: ${log.points.last.distanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(color: AppColors.goldAccent, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleScrubUpdate(double localX) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    // Ograniczenie proporcji do zakresu [0.0, 1.0]
    final width = MediaQuery.of(context).size.width - 64; // Estymowana szerokość
    if (width > 0) {
      setState(() {
        _scrubFraction = (localX / width).clamp(0.0, 1.0);
      });
    }
  }

  Widget _buildSeriesToggleChip(String label, bool isEnabled, Color color, ValueChanged<bool> onChanged) {
    return FilterChip(
      selected: isEnabled,
      onSelected: onChanged,
      label: Text(label),
      labelStyle: TextStyle(
        color: isEnabled ? Colors.white : AppColors.textMuted,
        fontSize: 11,
        fontWeight: isEnabled ? FontWeight.w700 : FontWeight.w500,
      ),
      selectedColor: color.withValues(alpha: 0.25),
      backgroundColor: AppColors.surfaceLight,
      checkmarkColor: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isEnabled ? color : AppTheme.borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }

  /// Pasek odczytu wartości w punkcie wskazywanym przez kursor scrubbera.
  Widget _buildScrubberLiveReadout(RiderTelemetryTrackPoint point) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        children: [
          _buildLiveValue('KM', '${point.distanceKm.toStringAsFixed(1)} km', Colors.white),
          _buildLiveValue('CZAS', _formatDuration(point.timestampSeconds), AppColors.textSecondary),
          if (_showPower) _buildLiveValue('MOC', '${point.powerWatts} W', AppColors.powerZone7),
          if (_showHeartRate) _buildLiveValue('HR', '${point.heartRateBpm} bpm', const Color(0xFFEF4444)),
          if (_showWPrime) _buildLiveValue('W\'', '${(point.wPrimeJoules / 1000.0).toStringAsFixed(1)} kJ', AppColors.goldAccent),
          if (_showCadence) _buildLiveValue('KADENCJA', '${point.cadenceRpm} RPM', AppColors.emeraldGreen),
          if (_showElevation) _buildLiveValue('WYSOKOŚĆ', '${point.elevationMeters.toStringAsFixed(0)} m (${point.gradientPercent.toStringAsFixed(1)}%)', const Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  Widget _buildLiveValue(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
      ],
    );
  }

  // ============================================================================
  // ROZKŁAD STREF MOCY Z1-Z7 ORAZ KRZYWA MOCY SZCZYTOWEJ (PEAK POWER)
  // ============================================================================

  Widget _buildPowerZonesCard(CogganPowerZonesAnalysis zones) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bar_chart_rounded, color: AppColors.goldAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'STREFY MOCY COGGANA (Z1-Z7)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Text(
                'FTP: ${zones.ftpWatts} W',
                style: const TextStyle(color: AppColors.goldAccent, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Paski dla każdej ze stref Z1-Z7
          for (int z = 1; z <= 7; z++) ...[
            _buildZoneRow(
              zone: z,
              name: CogganPowerZonesAnalysis.getZoneName(z),
              range: zones.getPowerRangeLabel(z),
              seconds: zones.getSeconds(z),
              percentage: zones.getPercentage(z),
              color: AppColors.getPowerZoneColor(z),
            ),
            if (z < 7) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildZoneRow({
    required int zone,
    required String name,
    required String range,
    required double seconds,
    required double percentage,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withValues(alpha: 0.8)),
                  ),
                  child: Text(
                    'Z$zone',
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  range,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                const SizedBox(width: 10),
                Text(
                  _formatDuration(seconds),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    textAlign: TextAlign.end,
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Pasek postępu strefy
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (percentage / 100.0).clamp(0.0, 1.0),
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  /// Karta krzywej szczytowej mocy (Mean Maximal Power - MMP).
  Widget _buildPeakPowerCurveCard(FitActivitySummary summary) {
    final Map<String, int> curve = summary.peakPowerCurve;
    final List<String> intervals = ['1s', '5s', '15s', '30s', '1m', '3m', '5m', '10m', '20m'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.show_chart_rounded, color: AppColors.powerZone7, size: 20),
              SizedBox(width: 8),
              Text(
                'KRZYWA SZCZYTOWEJ MOCY (MMP)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Maksymalna średnia moc utrzymana w zadanym oknie czasowym (WKO5 / Intervals.icu)',
            style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.8), fontSize: 11),
          ),
          const SizedBox(height: 14),

          // Tabela szczytowych wartości
          for (final duration in intervals) ...[
            if (curve.containsKey(duration)) ...[
              _buildMmpRow(duration, curve[duration]!),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildMmpRow(String duration, int watts) {
    const int maxDisplay = 1300;
    final double ratio = (watts / maxDisplay).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 38,
          child: Text(
            duration,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: AppColors.surfaceLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.powerZone7),
              minHeight: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(
            '$watts W',
            textAlign: TextAlign.end,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // EKSPORT PLIKU .FIT I POWIADOMIENIA
  // ============================================================================

  void _showFitExportDialog(FitActivitySummary summary) {
    final log = _currentLog;
    final fitBytes = FitFileExporter.generateFitBinary(log, stageName: widget.stageName);
    final csvStr = FitFileExporter.exportToCsv(log);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.file_download_done_rounded, color: AppColors.accentBlue, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Eksport Pliku Telemetrii',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Wygenerowano binarny plik Garmin .FIT (Protokół 2.0) oraz plik CSV zgodny ze Strava, TrainingPeaks, GoldenCheetah i WKO5 dla kolarza ${log.riderName}.',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: [
                    _buildDialogFileRow('Plik aktywności Garmin FIT:', '${(fitBytes.lengthInBytes / 1024).toStringAsFixed(1)} KB (.fit)'),
                    const Divider(color: AppTheme.borderColor, height: 16),
                    _buildDialogFileRow('Arkusz surowej telemetrii CSV:', '${(csvStr.length / 1024).toStringAsFixed(1)} KB (.csv)'),
                    const Divider(color: AppTheme.borderColor, height: 16),
                    _buildDialogFileRow('Liczba zarejestrowanych próbek:', '${log.sampleCount} rekordów sekundowych'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.statusSuccess,
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Plik "${log.riderName.replaceAll(" ", "_")}_${widget.stageName.replaceAll(" ", "_")}.fit" zapisany pomyślnie!',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Zapisz Plik .FIT na Dysku', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDialogFileRow(String title, String detail) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(detail, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }

  String _formatDuration(double seconds) {
    final int sec = seconds.round();
    final int hours = sec ~/ 3600;
    final int minutes = (sec % 3600) ~/ 60;
    final int remainingSec = sec % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSec.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${remainingSec.toString().padLeft(2, '0')}';
    }
  }

  // ============================================================================
  // GENERATOR DANYCH DEMO (FALLBACK DO TESTÓW I PREVIEW)
  // ============================================================================

  static List<RiderTelemetryLog> _generateDemoRiderLogs() {
    final logPogacar = RiderTelemetryLog(
      riderId: 'rider_pogacar',
      riderName: 'Tadej Pogačar',
      bibNumber: 1,
      teamId: 'team_uae',
      teamName: 'UAE Team Emirates',
      isPlayerRider: true,
      ftpWatts: 425,
      maxHrBpm: 200,
    );

    final logVingegaard = RiderTelemetryLog(
      riderId: 'rider_vingegaard',
      riderName: 'Jonas Vingegaard',
      bibNumber: 2,
      teamId: 'team_visma',
      teamName: 'Team Visma | Lease a Bike',
      isPlayerRider: true,
      ftpWatts: 420,
      maxHrBpm: 196,
    );

    final logVanAert = RiderTelemetryLog(
      riderId: 'rider_vanaert',
      riderName: 'Wout van Aert',
      bibNumber: 3,
      teamId: 'team_visma',
      teamName: 'Team Visma | Lease a Bike',
      isPlayerRider: true,
      ftpWatts: 440,
      maxHrBpm: 194,
    );

    // Generujemy 120 punktów (np. 120 km etapu górskiego)
    for (int i = 0; i <= 120; i++) {
      final double km = i.toDouble();
      final double sec = i * 90.0; // ~3 godziny
      final double elev = 500.0 + (math.sin(i / 15.0) * 400.0) + (i > 90 ? (i - 90) * 35.0 : 0.0);
      final double grad = i > 90 ? 8.5 : (math.cos(i / 15.0) * 4.0);

      // Pogačar: mocny atak na finałowym podjeździe (km 90-120)
      final int wattsPogacar = (i > 95 && i < 115)
          ? 475 + (i % 5) * 15
          : (i >= 115 ? 850 : 280 + (i % 7) * 10);
      final int hrPogacar = (i > 95) ? 182 + (i % 4) : 142 + (i % 5);
      final double wPrimePog = math.max(2000.0, 22000.0 - (i > 95 ? (i - 95) * 800.0 : 0.0));

      logPogacar.addPoint(RiderTelemetryTrackPoint(
        timestampSeconds: sec,
        distanceMeters: km * 1000.0,
        speedMs: i > 90 ? 6.5 : 12.5,
        powerWatts: wattsPogacar,
        cadenceRpm: 92,
        heartRateBpm: hrPogacar,
        elevationMeters: elev,
        gradientPercent: grad,
        wPrimeJoules: wPrimePog,
        wPrimePercentage: wPrimePog / 22000.0,
        glycogenGrams: math.max(100.0, 500.0 - (i * 3.0)),
        lateralPositionRoad: 0.0,
        isDrafting: i < 95,
        draftingSavingsPercent: i < 95 ? 32.0 : 0.0,
        activeTacticalOrder: i >= 95 ? TacticalOrder.attack : TacticalOrder.holdPosition,
      ));

      // Vingegaard
      final int wattsVin = (i > 95 && i < 115) ? 465 + (i % 4) * 12 : 275 + (i % 6) * 10;
      logVingegaard.addPoint(RiderTelemetryTrackPoint(
        timestampSeconds: sec,
        distanceMeters: km * 1000.0,
        speedMs: i > 90 ? 6.4 : 12.5,
        powerWatts: wattsVin,
        cadenceRpm: 90,
        heartRateBpm: (i > 95) ? 180 : 140,
        elevationMeters: elev,
        gradientPercent: grad,
        wPrimeJoules: 19000.0,
        wPrimePercentage: 0.9,
        glycogenGrams: 450.0,
        lateralPositionRoad: 0.1,
        isDrafting: true,
        draftingSavingsPercent: 32.0,
        activeTacticalOrder: TacticalOrder.followWheels,
      ));

      // Van Aert: tempo w dolinie i pociąg
      final int wattsWva = (i <= 90) ? 380 + (i % 8) * 10 : 250;
      logVanAert.addPoint(RiderTelemetryTrackPoint(
        timestampSeconds: sec,
        distanceMeters: km * 1000.0,
        speedMs: 12.0,
        powerWatts: wattsWva,
        cadenceRpm: 88,
        heartRateBpm: 155,
        elevationMeters: elev,
        gradientPercent: grad,
        wPrimeJoules: 24000.0,
        wPrimePercentage: 0.95,
        glycogenGrams: 460.0,
        lateralPositionRoad: -0.2,
        isDrafting: false,
        draftingSavingsPercent: 0.0,
        activeTacticalOrder: TacticalOrder.pullGroup,
      ));
    }

    return [logPogacar, logVingegaard, logVanAert];
  }
}

// ============================================================================
// 3. MULTI-SERIES TELEMETRY CANVAS PAINTER
// ============================================================================

/// Wektorowy painter rysujący nałożone krzywe telemetryczne z całego etapu.
class _MultiSeriesTelemetryChartPainter extends CustomPainter {
  final List<RiderTelemetryTrackPoint> points;
  final bool showElevation;
  final bool showPower;
  final bool showHeartRate;
  final bool showWPrime;
  final bool showCadence;
  final double? scrubFraction;

  _MultiSeriesTelemetryChartPainter({
    required this.points,
    required this.showElevation,
    required this.showPower,
    required this.showHeartRate,
    required this.showWPrime,
    required this.showCadence,
    this.scrubFraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final double w = size.width;
    final double h = size.height;

    // Rysowanie siatki tła
    final Paint gridPaint = Paint()
      ..color = const Color(0xFF2E3440).withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 4; i++) {
      final double y = h * (i / 5.0);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // 1. Seria wysokościowa (Profil trasy jako cieniowane tło z gradientem)
    if (showElevation) {
      _paintElevationProfile(canvas, size);
    }

    // 2. Seria Mocy [W] (Fiolet / Akcent Coggan Z7)
    if (showPower) {
      _paintCurveSeries(
        canvas: canvas,
        size: size,
        getValue: (p) => p.powerWatts.toDouble(),
        minValue: 0.0,
        maxValue: 1000.0,
        color: AppColors.powerZone7,
        strokeWidth: 2.0,
      );
    }

    // 3. Seria Tętna [bpm] (Czerwona)
    if (showHeartRate) {
      _paintCurveSeries(
        canvas: canvas,
        size: size,
        getValue: (p) => p.heartRateBpm.toDouble(),
        minValue: 100.0,
        maxValue: 205.0,
        color: const Color(0xFFEF4444),
        strokeWidth: 1.8,
      );
    }

    // 4. Seria W' Balance [kJ] (Złota / Bursztynowa)
    if (showWPrime) {
      _paintCurveSeries(
        canvas: canvas,
        size: size,
        getValue: (p) => p.wPrimeJoules / 1000.0,
        minValue: 0.0,
        maxValue: 25.0,
        color: AppColors.goldAccent,
        strokeWidth: 1.8,
      );
    }

    // 5. Seria Kadencji [RPM] (Szmaragdowa)
    if (showCadence) {
      _paintCurveSeries(
        canvas: canvas,
        size: size,
        getValue: (p) => p.cadenceRpm.toDouble(),
        minValue: 50.0,
        maxValue: 125.0,
        color: AppColors.emeraldGreen,
        strokeWidth: 1.5,
      );
    }

    // 6. Linia kursora scrubbera (Crosshair)
    if (scrubFraction != null) {
      final double scrubX = (scrubFraction! * w).clamp(0.0, w);

      final Paint scrubberPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5;

      canvas.drawLine(Offset(scrubX, 0), Offset(scrubX, h), scrubberPaint);

      // Kropka na szczycie kursora
      final Paint dotPaint = Paint()..color = AppColors.cyanAccent;
      canvas.drawCircle(Offset(scrubX, 6), 4.0, dotPaint);
    }
  }

  void _paintElevationProfile(Canvas canvas, Size size) {
    double minAlt = points.first.elevationMeters;
    double maxAlt = points.first.elevationMeters;

    for (final p in points) {
      if (p.elevationMeters < minAlt) minAlt = p.elevationMeters;
      if (p.elevationMeters > maxAlt) maxAlt = p.elevationMeters;
    }

    final double altRange = math.max(50.0, maxAlt - minAlt);
    final Path areaPath = Path();
    final Path linePath = Path();

    final double dx = size.width / math.max(1, points.length - 1);

    areaPath.moveTo(0, size.height);

    for (int i = 0; i < points.length; i++) {
      final double x = i * dx;
      final double normalizedAlt = (points[i].elevationMeters - minAlt) / altRange;
      final double y = size.height - (normalizedAlt * (size.height * 0.70)) - 10.0;

      if (i == 0) {
        areaPath.lineTo(x, y);
        linePath.moveTo(x, y);
      } else {
        areaPath.lineTo(x, y);
        linePath.lineTo(x, y);
      }
    }

    areaPath.lineTo(size.width, size.height);
    areaPath.close();

    // Wypełnienie gradientem
    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF475569).withValues(alpha: 0.35),
          const Color(0xFF1E293B).withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(areaPath, fillPaint);

    final Paint borderPaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(linePath, borderPaint);
  }

  void _paintCurveSeries({
    required Canvas canvas,
    required Size size,
    required double Function(RiderTelemetryTrackPoint) getValue,
    required double minValue,
    required double maxValue,
    required Color color,
    required double strokeWidth,
  }) {
    final double range = math.max(1.0, maxValue - minValue);
    final Path path = Path();
    final double dx = size.width / math.max(1, points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final double x = i * dx;
      final double val = getValue(points[i]).clamp(minValue, maxValue);
      final double normalized = (val - minValue) / range;
      final double y = size.height - (normalized * (size.height * 0.85)) - 10.0;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MultiSeriesTelemetryChartPainter oldDelegate) {
    return oldDelegate.scrubFraction != scrubFraction ||
        oldDelegate.showElevation != showElevation ||
        oldDelegate.showPower != showPower ||
        oldDelegate.showHeartRate != showHeartRate ||
        oldDelegate.showWPrime != showWPrime ||
        oldDelegate.showCadence != showCadence ||
        oldDelegate.points != points;
  }
}
