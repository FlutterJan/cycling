import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../engine/events/weather_radar_live_forecast_shift.dart';

/// Warstwy wizualne możliwe do przełączania na nakładce radaru Dopplera.
enum DopplerRadarOverlayLayer {
  sweepAndGrid('Siatka i Skan', Icons.radar_rounded),
  stormVectors('Wektory Frontów', Icons.air_rounded),
  dbzLegend('Skala dBZ', Icons.palette_outlined);

  final String labelPl;
  final IconData icon;

  const DopplerRadarOverlayLayer(this.labelPl, this.icon);
}

/// Zestaw metryk wyliczonych dla aktualnego stanu nakładki radaru Dopplera.
class DopplerRadarMinimapSummary {
  final double maxRouteDbz;
  final double maxPrecipitationMmH;
  final double maxWindGustKmh;
  final RadarPrecipitationIntensity pelotonIntensity;
  final StormFrontCell? primaryThreatCell;
  final int activeCellCount;

  const DopplerRadarMinimapSummary({
    required this.maxRouteDbz,
    required this.maxPrecipitationMmH,
    required this.maxWindGustKmh,
    required this.pelotonIntensity,
    required this.primaryThreatCell,
    required this.activeCellCount,
  });

  factory DopplerRadarMinimapSummary.fromState(
    WeatherRadarLiveState state, {
    required RadarForecastHorizon horizon,
  }) {
    final hoursAhead = horizon.minutesAhead / 60.0;
    double maxDbz = 0.0;
    double maxRain = 0.0;
    double maxGust = state.baseWindKmh;
    StormFrontCell? threat;
    double threatScore = -1.0;

    for (final cell in state.stormCells) {
      if (cell.peakIntensityDbz > maxDbz) {
        maxDbz = cell.peakIntensityDbz;
      }
      if (cell.precipitationMmPerHour > maxRain) {
        maxRain = cell.precipitationMmPerHour;
      }
      if (cell.windGustKmh > maxGust) {
        maxGust = cell.windGustKmh;
      }
      final score = cell.peakIntensityDbz +
          (cell.isDissipating ? -12.0 : 0.0) +
          cell.hailProbability * 25.0;
      if (score > threatScore) {
        threatScore = score;
        threat = cell;
      }
    }

    // Wyznacz intensywność opadów w pozycji peletonu przy zadanym horyzoncie.
    final pelotonPoint = _interpolateRoutePoint(
      state.routePoints,
      state.pelotonKm,
    );
    double pelotonDbz = 0.0;
    if (pelotonPoint != null) {
      for (final cell in state.stormCells) {
        final cx = cell.centerXKm + cell.velocityXKmPerHour * hoursAhead;
        final cy = cell.centerYKm + cell.velocityYKmPerHour * hoursAhead;
        final localDbz = _evaluateCellDbzAtPoint(
          cell: cell,
          cellX: cx,
          cellY: cy,
          px: pelotonPoint.xKm,
          py: pelotonPoint.yKm,
        );
        if (localDbz > pelotonDbz) {
          pelotonDbz = localDbz;
        }
      }
    }

    return DopplerRadarMinimapSummary(
      maxRouteDbz: maxDbz,
      maxPrecipitationMmH: maxRain,
      maxWindGustKmh: maxGust,
      pelotonIntensity: _dbzToIntensity(pelotonDbz),
      primaryThreatCell: threat,
      activeCellCount: state.stormCells.length,
    );
  }
}

RadarRoutePoint? _interpolateRoutePoint(
  List<RadarRoutePoint> points,
  double targetKm,
) {
  if (points.isEmpty) return null;
  if (targetKm <= points.first.routeKm) return points.first;
  if (targetKm >= points.last.routeKm) return points.last;

  for (int i = 0; i < points.length - 1; i++) {
    final a = points[i];
    final b = points[i + 1];
    if (targetKm >= a.routeKm && targetKm <= b.routeKm) {
      final span = (b.routeKm - a.routeKm).abs();
      final t = span < 1e-6 ? 0.0 : (targetKm - a.routeKm) / span;
      return RadarRoutePoint(
        routeKm: targetKm,
        xKm: a.xKm + (b.xKm - a.xKm) * t,
        yKm: a.yKm + (b.yKm - a.yKm) * t,
        elevationM: a.elevationM + (b.elevationM - a.elevationM) * t,
        roadBearingDegrees: b.roadBearingDegrees,
      );
    }
  }
  return points.last;
}

double _evaluateCellDbzAtPoint({
  required StormFrontCell cell,
  required double cellX,
  required double cellY,
  required double px,
  required double py,
}) {
  final dx = px - cellX;
  final dy = py - cellY;
  final angleRad = -cell.orientationDeg * math.pi / 180.0;
  final cosA = math.cos(angleRad);
  final sinA = math.sin(angleRad);
  final rx = dx * cosA - dy * sinA;
  final ry = dx * sinA + dy * cosA;

  final majorR = math.max(2.0, cell.radiusKm * cell.elongationRatio);
  final minorR = math.max(2.0, cell.radiusKm);
  final normDistSq = (rx * rx) / (majorR * majorR) + (ry * ry) / (minorR * minorR);
  if (normDistSq >= 1.0) return 0.0;

  final falloff = 1.0 - normDistSq;
  final attenuation = cell.isDissipating ? 0.72 : 1.0;
  return cell.peakIntensityDbz * falloff * attenuation;
}

RadarPrecipitationIntensity _dbzToIntensity(double dbz) {
  if (dbz < 18.0) return RadarPrecipitationIntensity.none;
  if (dbz < 30.0) return RadarPrecipitationIntensity.lightShower;
  if (dbz < 42.0) return RadarPrecipitationIntensity.moderateRain;
  if (dbz < 52.0) return RadarPrecipitationIntensity.heavyDownpour;
  return RadarPrecipitationIntensity.torrentialHail;
}

/// Nakładka radaru opadów Dopplera na mapie trasy wyścigu.
///
/// Prezentuje dwuwymiarową trasę wyścigu z pozycją peletonu i ucieczki,
/// wielowarstwowe komórki opadów Dopplera (dBZ), wektory przemieszczania
/// frontów burzowych oraz interaktywny wybór horyzontu prognozy (`Teraz`,
/// `+15 min`, `+30 min`, `+60 min`).
class LiveWeatherDopplerRadarMinimap extends ConsumerStatefulWidget {
  final WeatherRadarLiveState? radarState;
  final RadarForecastHorizon? initialHorizon;
  final bool isCompact;
  final bool enabled;
  final bool animateSweep;
  final ValueChanged<RadarForecastHorizon>? onHorizonChanged;
  final ValueChanged<StormFrontCell?>? onCellSelected;
  final VoidCallback? onToggleExpand;

  const LiveWeatherDopplerRadarMinimap({
    super.key,
    this.radarState,
    this.initialHorizon,
    this.isCompact = false,
    this.enabled = true,
    this.animateSweep = true,
    this.onHorizonChanged,
    this.onCellSelected,
    this.onToggleExpand,
  });

  @override
  ConsumerState<LiveWeatherDopplerRadarMinimap> createState() =>
      _LiveWeatherDopplerRadarMinimapState();
}

class _LiveWeatherDopplerRadarMinimapState
    extends ConsumerState<LiveWeatherDopplerRadarMinimap>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweepController;
  late RadarForecastHorizon _horizon;
  late bool _isExpanded;
  String? _selectedCellId;
  bool _showGridAndSweep = true;
  bool _showVectors = true;
  bool _showLegend = true;

  @override
  void initState() {
    super.initState();
    _horizon = widget.initialHorizon ??
        widget.radarState?.selectedHorizon ??
        RadarForecastHorizon.now;
    _isExpanded = !widget.isCompact;
    _selectedCellId = widget.radarState?.selectedCellId;
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    if (widget.animateSweep && widget.enabled) {
      _sweepController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant LiveWeatherDopplerRadarMinimap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.radarState?.selectedCellId != oldWidget.radarState?.selectedCellId &&
        widget.radarState?.selectedCellId != null) {
      _selectedCellId = widget.radarState?.selectedCellId;
    }
    if (widget.animateSweep != oldWidget.animateSweep ||
        widget.enabled != oldWidget.enabled) {
      if (widget.animateSweep && widget.enabled) {
        if (!_sweepController.isAnimating) {
          _sweepController.repeat();
        }
      } else {
        _sweepController.stop();
      }
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  WeatherRadarLiveState _resolveState() {
    if (widget.radarState != null) {
      return widget.radarState!;
    }
    return ref.watch(weatherRadarLiveProvider);
  }

  void _selectHorizon(RadarForecastHorizon next) {
    if (!widget.enabled) return;
    setState(() {
      _horizon = next;
    });
    if (widget.radarState == null) {
      ref.read(weatherRadarLiveProvider.notifier).selectHorizon(next);
    }
    widget.onHorizonChanged?.call(next);
  }

  void _selectCell(StormFrontCell? cell) {
    if (!widget.enabled) return;
    setState(() {
      _selectedCellId = cell?.id == _selectedCellId ? null : cell?.id;
    });
    if (widget.radarState == null) {
      ref.read(weatherRadarLiveProvider.notifier).selectStormCell(_selectedCellId);
    }
    widget.onCellSelected?.call(
      _selectedCellId == null ? null : cell,
    );
  }

  void _toggleLayer(DopplerRadarOverlayLayer layer) {
    if (!widget.enabled) return;
    setState(() {
      switch (layer) {
        case DopplerRadarOverlayLayer.sweepAndGrid:
          _showGridAndSweep = !_showGridAndSweep;
          break;
        case DopplerRadarOverlayLayer.stormVectors:
          _showVectors = !_showVectors;
          break;
        case DopplerRadarOverlayLayer.dbzLegend:
          _showLegend = !_showLegend;
          break;
      }
    });
  }

  bool _isLayerActive(DopplerRadarOverlayLayer layer) {
    switch (layer) {
      case DopplerRadarOverlayLayer.sweepAndGrid:
        return _showGridAndSweep;
      case DopplerRadarOverlayLayer.stormVectors:
        return _showVectors;
      case DopplerRadarOverlayLayer.dbzLegend:
        return _showLegend;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _resolveState();
    final summary = DopplerRadarMinimapSummary.fromState(
      state,
      horizon: _horizon,
    );
    final activeCell = _findSelectedCell(state) ?? summary.primaryThreatCell;
    final alertColor = _alertLevelColor(state.alertLevel);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      opacity: widget.enabled ? 1.0 : 0.52,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 420.0;
          final isNarrow = maxWidth < 380.0;
          final canvasHeight = _isExpanded
              ? (isNarrow ? 190.0 : 230.0)
              : (isNarrow ? 132.0 : 156.0);

          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: state.alertLevel == WeatherShiftAlertLevel.imminent ||
                        state.alertLevel == WeatherShiftAlertLevel.activeImpact
                    ? alertColor.withValues(alpha: 0.65)
                    : AppColors.cardBorder,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.32),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Padding(
                padding: EdgeInsets.all(isNarrow ? 10.0 : 14.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(
                      state: state,
                      alertColor: alertColor,
                      isNarrow: isNarrow,
                    ),
                    const SizedBox(height: 10),
                    _buildRadarViewport(
                      state: state,
                      activeCell: activeCell,
                      height: canvasHeight,
                    ),
                    const SizedBox(height: 10),
                    _buildHorizonSelector(isNarrow: isNarrow),
                    if (_isExpanded) ...[
                      const SizedBox(height: 8),
                      _buildLayerToggles(isNarrow: isNarrow),
                      if (_showLegend) ...[
                        const SizedBox(height: 8),
                        _buildDbzLegend(isNarrow: isNarrow),
                      ],
                      const SizedBox(height: 8),
                      _buildTelemetryFooter(
                        state: state,
                        summary: summary,
                        activeCell: activeCell,
                        isNarrow: isNarrow,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  StormFrontCell? _findSelectedCell(WeatherRadarLiveState state) {
    final id = _selectedCellId;
    if (id == null) return null;
    for (final c in state.stormCells) {
      if (c.id == id) return c;
    }
    return null;
  }

  Widget _buildHeader({
    required WeatherRadarLiveState state,
    required Color alertColor,
    required bool isNarrow,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.cyanAccent.withValues(alpha: 0.35),
              width: 1.0,
            ),
          ),
          child: const Icon(
            Icons.radar_rounded,
            size: 16,
            color: AppColors.cyanAccent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'RADAR DOPPLERA',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                state.stageName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: alertColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: alertColor.withValues(alpha: 0.45),
              width: 1.0,
            ),
          ),
          child: Text(
            state.alertLevel.labelPl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isNarrow ? 10 : 11,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: alertColor,
            ),
          ),
        ),
        const SizedBox(width: 6),
        _RadarInteractiveIconButton(
          icon: _isExpanded
              ? Icons.unfold_less_rounded
              : Icons.unfold_more_rounded,
          tooltip: _isExpanded ? 'Zwiń panel radaru' : 'Rozwiń panel radaru',
          enabled: widget.enabled,
          onPressed: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
            widget.onToggleExpand?.call();
          },
        ),
      ],
    );
  }

  Widget _buildRadarViewport({
    required WeatherRadarLiveState state,
    required StormFrontCell? activeCell,
    required double height,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: LayoutBuilder(
          builder: (context, box) {
            final size = Size(box.maxWidth, box.maxHeight);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: widget.enabled
                  ? (details) => _handleRadarTap(
                        details.localPosition,
                        size,
                        state,
                      )
                  : null,
              child: AnimatedBuilder(
                animation: _sweepController,
                builder: (context, _) {
                  return CustomPaint(
                    size: size,
                    painter: DopplerRadarMinimapPainter(
                      state: state,
                      horizon: _horizon,
                      sweepAngleRad: _sweepController.value * math.pi * 2.0,
                      selectedCellId: _selectedCellId ?? activeCell?.id,
                      showGridAndSweep: _showGridAndSweep,
                      showVectors: _showVectors,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleRadarTap(
    Offset localPos,
    Size size,
    WeatherRadarLiveState state,
  ) {
    if (state.stormCells.isEmpty) return;
    final transform = _RadarViewportTransform.fromPoints(
      points: state.routePoints,
      cells: state.stormCells,
      size: size,
    );
    final hoursAhead = _horizon.minutesAhead / 60.0;
    StormFrontCell? closest;
    double bestDist = 36.0;

    for (final cell in state.stormCells) {
      final cx = cell.centerXKm + cell.velocityXKmPerHour * hoursAhead;
      final cy = cell.centerYKm + cell.velocityYKmPerHour * hoursAhead;
      final screenOffset = transform.toScreen(cx, cy);
      final dist = (screenOffset - localPos).distance;
      if (dist < bestDist) {
        bestDist = dist;
        closest = cell;
      }
    }

    if (closest != null) {
      _selectCell(closest);
    }
  }

  Widget _buildHorizonSelector({required bool isNarrow}) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: RadarForecastHorizon.values.map((h) {
        final selected = h == _horizon;
        return _RadarInteractivePill(
          label: h.labelPl,
          selected: selected,
          enabled: widget.enabled,
          accentColor: AppColors.goldAccent,
          compact: isNarrow,
          onTap: () => _selectHorizon(h),
        );
      }).toList(growable: false),
    );
  }

  Widget _buildLayerToggles({required bool isNarrow}) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: DopplerRadarOverlayLayer.values.map((layer) {
        final active = _isLayerActive(layer);
        return _RadarInteractivePill(
          label: layer.labelPl,
          icon: layer.icon,
          selected: active,
          enabled: widget.enabled,
          accentColor: AppColors.cyanAccent,
          compact: isNarrow,
          onTap: () => _toggleLayer(layer),
        );
      }).toList(growable: false),
    );
  }

  Widget _buildDbzLegend({required bool isNarrow}) {
    const stops = [
      ('20 dBZ', AppColors.statusSuccess),
      ('35 dBZ', AppColors.accentBlue),
      ('45 dBZ', AppColors.amberWarning),
      ('55+ dBZ', AppColors.crimsonAlert),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Wrap(
        spacing: isNarrow ? 8 : 12,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Odbiciowość:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: AppColors.textSecondary,
            ),
          ),
          for (final stop in stops)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: stop.$2,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  stop.$1,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTelemetryFooter({
    required WeatherRadarLiveState state,
    required DopplerRadarMinimapSummary summary,
    required StormFrontCell? activeCell,
    required bool isNarrow,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: isNarrow ? 10 : 14,
            runSpacing: 6,
            children: [
              _TelemetryDatum(
                label: 'Peleton',
                value:
                    '${state.pelotonKm.toStringAsFixed(1)}/${state.stageDistanceKm.toStringAsFixed(0)} km',
                valueColor: AppColors.cyanAccent,
              ),
              _TelemetryDatum(
                label: 'Opady (peleton)',
                value: summary.pelotonIntensity.labelPl,
                valueColor: summary.pelotonIntensity.radarColor,
              ),
              _TelemetryDatum(
                label: 'Max dBZ',
                value: '${summary.maxRouteDbz.toStringAsFixed(0)} dBZ',
                valueColor: AppColors.amberWarning,
              ),
              _TelemetryDatum(
                label: 'Porywy',
                value: '${summary.maxWindGustKmh.toStringAsFixed(0)} km/h',
                valueColor: AppColors.textPrimary,
              ),
            ],
          ),
          if (activeCell != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.goldAccent.withValues(alpha: 0.35),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.32),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      activeCell.frontType.shortTag,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${activeCell.name} • ${activeCell.precipitationMmPerHour.toStringAsFixed(1)} mm/h • -${activeCell.temperatureDropC.toStringAsFixed(1)}°C',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _alertLevelColor(WeatherShiftAlertLevel level) {
    switch (level) {
      case WeatherShiftAlertLevel.clear:
        return AppColors.statusSuccess;
      case WeatherShiftAlertLevel.approaching:
        return AppColors.accentBlue;
      case WeatherShiftAlertLevel.imminent:
        return AppColors.amberWarning;
      case WeatherShiftAlertLevel.activeImpact:
        return AppColors.crimsonAlert;
      case WeatherShiftAlertLevel.clearing:
        return AppColors.cyanAccent;
    }
  }
}

class _TelemetryDatum extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _TelemetryDatum({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _RadarInteractivePill extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final bool enabled;
  final Color accentColor;
  final bool compact;
  final VoidCallback onTap;

  const _RadarInteractivePill({
    required this.label,
    this.icon,
    required this.selected,
    required this.enabled,
    required this.accentColor,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_RadarInteractivePill> createState() => _RadarInteractivePillState();
}

class _RadarInteractivePillState extends State<_RadarInteractivePill> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? widget.accentColor.withValues(alpha: 0.18)
        : (_hovered
            ? AppColors.surfaceLight
            : AppColors.background.withValues(alpha: 0.6));
    final borderColor = _focused
        ? AppColors.cyanAccent
        : (widget.selected
            ? widget.accentColor
            : (_hovered ? AppColors.textSecondary : AppColors.cardBorder));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) {
          if (widget.enabled) setState(() => _hovered = true);
        },
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: widget.enabled
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapUp: widget.enabled
              ? (_) {
                  setState(() => _pressed = false);
                  widget.onTap();
                }
              : null,
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 8 : 10,
                vertical: widget.compact ? 4 : 5,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: borderColor,
                  width: _focused ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: widget.compact ? 12 : 13,
                      color: widget.selected
                          ? widget.accentColor
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: widget.compact ? 10 : 11,
                      fontWeight:
                          widget.selected ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: -0.2,
                      color: widget.selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
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

class _RadarInteractiveIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  const _RadarInteractiveIconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_RadarInteractiveIconButton> createState() =>
      _RadarInteractiveIconButtonState();
}

class _RadarInteractiveIconButtonState
    extends State<_RadarInteractiveIconButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        child: MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: (_) {
            if (widget.enabled) setState(() => _hovered = true);
          },
          onExit: (_) => setState(() {
            _hovered = false;
            _pressed = false;
          }),
          child: GestureDetector(
            onTapDown: widget.enabled
                ? (_) => setState(() => _pressed = true)
                : null,
            onTapUp: widget.enabled
                ? (_) {
                    setState(() => _pressed = false);
                    widget.onPressed();
                  }
                : null,
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.92 : 1.0,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _hovered
                      ? AppColors.surfaceLight
                      : AppColors.background.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _focused
                        ? AppColors.cyanAccent
                        : (_hovered
                            ? AppColors.goldAccent
                            : AppColors.cardBorder),
                    width: _focused ? 1.5 : 1.0,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  size: 16,
                  color: _hovered
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarViewportTransform {
  final double centerX;
  final double centerY;
  final double scalePxPerKm;
  final Size size;

  const _RadarViewportTransform({
    required this.centerX,
    required this.centerY,
    required this.scalePxPerKm,
    required this.size,
  });

  factory _RadarViewportTransform.fromPoints({
    required List<RadarRoutePoint> points,
    required List<StormFrontCell> cells,
    required Size size,
  }) {
    double minX = -40.0;
    double maxX = 40.0;
    double minY = -25.0;
    double maxY = 25.0;

    if (points.isNotEmpty) {
      minX = points.first.xKm;
      maxX = points.first.xKm;
      minY = points.first.yKm;
      maxY = points.first.yKm;
      for (final p in points) {
        if (p.xKm < minX) minX = p.xKm;
        if (p.xKm > maxX) maxX = p.xKm;
        if (p.yKm < minY) minY = p.yKm;
        if (p.yKm > maxY) maxY = p.yKm;
      }
    }

    for (final c in cells) {
      final r = c.radiusKm * 0.65;
      if (c.centerXKm - r < minX) minX = c.centerXKm - r;
      if (c.centerXKm + r > maxX) maxX = c.centerXKm + r;
      if (c.centerYKm - r < minY) minY = c.centerYKm - r;
      if (c.centerYKm + r > maxY) maxY = c.centerYKm + r;
    }

    final spanX = math.max(24.0, maxX - minX);
    final spanY = math.max(24.0, maxY - minY);
    final usableW = math.max(40.0, size.width - 36.0);
    final usableH = math.max(40.0, size.height - 36.0);
    final scale = math.min(usableW / spanX, usableH / spanY);

    return _RadarViewportTransform(
      centerX: (minX + maxX) * 0.5,
      centerY: (minY + maxY) * 0.5,
      scalePxPerKm: scale,
      size: size,
    );
  }

  Offset toScreen(double xKm, double yKm) {
    final sx = size.width * 0.5 + (xKm - centerX) * scalePxPerKm;
    final sy = size.height * 0.5 - (yKm - centerY) * scalePxPerKm;
    return Offset(sx, sy);
  }
}

/// CustomPainter renderujący siatkę Dopplera, wielopasmowe komórki opadów,
/// polilinię trasy z kolorowaniem intensywności oraz pozycje grup wyścigowych.
class DopplerRadarMinimapPainter extends CustomPainter {
  final WeatherRadarLiveState state;
  final RadarForecastHorizon horizon;
  final double sweepAngleRad;
  final String? selectedCellId;
  final bool showGridAndSweep;
  final bool showVectors;

  const DopplerRadarMinimapPainter({
    required this.state,
    required this.horizon,
    required this.sweepAngleRad,
    required this.selectedCellId,
    this.showGridAndSweep = true,
    this.showVectors = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 4 || size.height <= 4) return;

    final transform = _RadarViewportTransform.fromPoints(
      points: state.routePoints,
      cells: state.stormCells,
      size: size,
    );
    final hoursAhead = horizon.minutesAhead / 60.0;

    // 1. Siatka radarowa i pierścienie zasięgu.
    if (showGridAndSweep) {
      _paintRadarGrid(canvas, size, transform);
    }

    // 2. Komórki opadów Dopplera (od najsłabszego pasma do rdzenia dBZ).
    for (final cell in state.stormCells) {
      _paintStormCell(
        canvas: canvas,
        transform: transform,
        cell: cell,
        hoursAhead: hoursAhead,
        isSelected: cell.id == selectedCellId,
      );
    }

    // 3. Skanująca wiązka Dopplera.
    if (showGridAndSweep) {
      _paintSweepBeam(canvas, size);
    }

    // 4. Trasa wyścigu z kolorowaniem lokalnej intensywności opadów.
    _paintRoutePolyline(
      canvas: canvas,
      transform: transform,
      hoursAhead: hoursAhead,
    );

    // 5. Znaczniki startu, mety, ucieczki i peletonu.
    _paintRaceMarkers(canvas, transform);
  }

  void _paintRadarGrid(
    Canvas canvas,
    Size size,
    _RadarViewportTransform transform,
  ) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Krzyż główny
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      gridPaint,
    );

    // Koncentryczne okręgi zasięgu co 20 km
    const ringKms = [20.0, 40.0, 60.0];
    for (final km in ringKms) {
      final rPx = km * transform.scalePxPerKm;
      if (rPx > 12 && rPx < math.max(size.width, size.height)) {
        canvas.drawCircle(center, rPx, gridPaint);
      }
    }

    // Kierunki świata N / E / S / W
    _drawText(
      canvas,
      'N',
      Offset(center.dx + 4, 4),
      color: AppColors.textSecondary.withValues(alpha: 0.75),
      fontSize: 9,
    );
    _drawText(
      canvas,
      'E',
      Offset(size.width - 13, center.dy + 3),
      color: AppColors.textSecondary.withValues(alpha: 0.75),
      fontSize: 9,
    );
  }

  void _paintSweepBeam(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radius = math.sqrt(size.width * size.width + size.height * size.height) *
        0.55;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0.0,
        endAngle: math.pi * 0.35,
        colors: [
          AppColors.cyanAccent.withValues(alpha: 0.0),
          AppColors.cyanAccent.withValues(alpha: 0.14),
        ],
        transform: GradientRotation(sweepAngleRad - math.pi * 0.35),
      ).createShader(rect);

    canvas.drawCircle(center, radius, sweepPaint);

    final beamEnd = Offset(
      center.dx + math.cos(sweepAngleRad) * radius,
      center.dy + math.sin(sweepAngleRad) * radius,
    );
    canvas.drawLine(
      center,
      beamEnd,
      Paint()
        ..color = AppColors.cyanAccent.withValues(alpha: 0.4)
        ..strokeWidth = 1.1,
    );
  }

  void _paintStormCell({
    required Canvas canvas,
    required _RadarViewportTransform transform,
    required StormFrontCell cell,
    required double hoursAhead,
    required bool isSelected,
  }) {
    final nowScreen = transform.toScreen(cell.centerXKm, cell.centerYKm);
    final advectedX = cell.centerXKm + cell.velocityXKmPerHour * hoursAhead;
    final advectedY = cell.centerYKm + cell.velocityYKmPerHour * hoursAhead;
    final centerScreen = transform.toScreen(advectedX, advectedY);

    // Jeśli prognoza w przyszłość, pokaż ścieżkę przesunięcia od pozycji "Teraz".
    if (hoursAhead > 0.01) {
      canvas.drawLine(
        nowScreen,
        centerScreen,
        Paint()
          ..color = AppColors.textSecondary.withValues(alpha: 0.42)
          ..strokeWidth = 1.0,
      );
      canvas.drawCircle(
        nowScreen,
        3.0,
        Paint()..color = AppColors.textSecondary.withValues(alpha: 0.55),
      );
    }

    final majorPx =
        math.max(10.0, cell.radiusKm * cell.elongationRatio * transform.scalePxPerKm);
    final minorPx = math.max(8.0, cell.radiusKm * transform.scalePxPerKm);
    final rotRad = -cell.orientationDeg * math.pi / 180.0;

    canvas.save();
    canvas.translate(centerScreen.dx, centerScreen.dy);
    canvas.rotate(rotRad);

    final alphaBoost = cell.isDissipating ? 0.55 : 1.0;

    // Pasmo 1: Lekki opad (20+ dBZ)
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: majorPx * 2.0, height: minorPx * 2.0),
      Paint()
        ..color = AppColors.statusSuccess.withValues(alpha: 0.22 * alphaBoost),
    );

    // Pasmo 2: Umiarkowany opad (32+ dBZ)
    if (cell.peakIntensityDbz >= 30.0) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: majorPx * 1.42,
          height: minorPx * 1.42,
        ),
        Paint()
          ..color = AppColors.accentBlue.withValues(alpha: 0.30 * alphaBoost),
      );
    }

    // Pasmo 3: Ulewa (42+ dBZ)
    if (cell.peakIntensityDbz >= 42.0) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: majorPx * 0.92,
          height: minorPx * 0.92,
        ),
        Paint()
          ..color = AppColors.amberWarning.withValues(alpha: 0.42 * alphaBoost),
      );
    }

    // Pasmo 4: Rdzeń burzowy / Grad (52+ dBZ)
    if (cell.peakIntensityDbz >= 52.0) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: majorPx * 0.5,
          height: minorPx * 0.5,
        ),
        Paint()
          ..color = AppColors.crimsonAlert.withValues(alpha: 0.56 * alphaBoost),
      );
    }

    if (isSelected) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: majorPx * 2.04,
          height: minorPx * 2.04,
        ),
        Paint()
          ..color = AppColors.goldAccent.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    canvas.restore();

    // Wektor przemieszczania się frontu
    if (showVectors && cell.speedKmPerHour > 0.5) {
      final vxScreen = cell.velocityXKmPerHour * transform.scalePxPerKm * 0.45;
      final vyScreen = -cell.velocityYKmPerHour * transform.scalePxPerKm * 0.45;
      final tip = Offset(
        centerScreen.dx + vxScreen,
        centerScreen.dy + vyScreen,
      );
      final vecPaint = Paint()
        ..color = AppColors.textPrimary.withValues(alpha: 0.78)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(centerScreen, tip, vecPaint);
      canvas.drawCircle(tip, 2.2, Paint()..color = AppColors.goldAccent);
    }
  }

  void _paintRoutePolyline({
    required Canvas canvas,
    required _RadarViewportTransform transform,
    required double hoursAhead,
  }) {
    final points = state.routePoints;
    if (points.length < 2) return;

    // Ciemna obwódka kontrastowa pod trasą
    final outlinePath = Path();
    final first = transform.toScreen(points.first.xKm, points.first.yKm);
    outlinePath.moveTo(first.dx, first.dy);
    for (int i = 1; i < points.length; i++) {
      final p = transform.toScreen(points[i].xKm, points[i].yKm);
      outlinePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      outlinePath,
      Paint()
        ..color = AppColors.background.withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Segmenty trasy kolorowane lokalnym opadem
    for (int i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final midX = (a.xKm + b.xKm) * 0.5;
      final midY = (a.yKm + b.yKm) * 0.5;

      double localDbz = 0.0;
      for (final cell in state.stormCells) {
        final cx = cell.centerXKm + cell.velocityXKmPerHour * hoursAhead;
        final cy = cell.centerYKm + cell.velocityYKmPerHour * hoursAhead;
        final dbz = _evaluateCellDbzAtPoint(
          cell: cell,
          cellX: cx,
          cellY: cy,
          px: midX,
          py: midY,
        );
        if (dbz > localDbz) localDbz = dbz;
      }

      final intensity = _dbzToIntensity(localDbz);
      final segColor = intensity == RadarPrecipitationIntensity.none
          ? AppColors.textPrimary.withValues(alpha: 0.78)
          : intensity.radarColor;

      canvas.drawLine(
        transform.toScreen(a.xKm, a.yKm),
        transform.toScreen(b.xKm, b.yKm),
        Paint()
          ..color = segColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintRaceMarkers(Canvas canvas, _RadarViewportTransform transform) {
    if (state.routePoints.isEmpty) return;

    final start = state.routePoints.first;
    final finish = state.routePoints.last;
    final startPx = transform.toScreen(start.xKm, start.yKm);
    final finishPx = transform.toScreen(finish.xKm, finish.yKm);

    // Start
    canvas.drawCircle(
      startPx,
      4.0,
      Paint()..color = AppColors.textSecondary,
    );

    // Meta
    canvas.drawCircle(
      finishPx,
      5.0,
      Paint()..color = AppColors.goldAccent,
    );
    canvas.drawCircle(
      finishPx,
      2.5,
      Paint()..color = AppColors.background,
    );

    // Ucieczka
    final breakawayPt = _interpolateRoutePoint(
      state.routePoints,
      state.breakawayKm,
    );
    if (breakawayPt != null) {
      final bPx = transform.toScreen(breakawayPt.xKm, breakawayPt.yKm);
      canvas.drawCircle(
        bPx,
        5.5,
        Paint()..color = AppColors.amberWarning.withValues(alpha: 0.35),
      );
      canvas.drawCircle(
        bPx,
        3.2,
        Paint()..color = AppColors.amberWarning,
      );
    }

    // Peleton
    final pelotonPt = _interpolateRoutePoint(
      state.routePoints,
      state.pelotonKm,
    );
    if (pelotonPt != null) {
      final pPx = transform.toScreen(pelotonPt.xKm, pelotonPt.yKm);
      canvas.drawCircle(
        pPx,
        7.5,
        Paint()..color = AppColors.cyanAccent.withValues(alpha: 0.28),
      );
      canvas.drawCircle(
        pPx,
        4.2,
        Paint()..color = AppColors.cyanAccent,
      );
      canvas.drawCircle(
        pPx,
        4.2,
        Paint()
          ..color = AppColors.background
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required Color color,
    required double fontSize,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant DopplerRadarMinimapPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.horizon != horizon ||
        oldDelegate.sweepAngleRad != sweepAngleRad ||
        oldDelegate.selectedCellId != selectedCellId ||
        oldDelegate.showGridAndSweep != showGridAndSweep ||
        oldDelegate.showVectors != showVectors;
  }
}
