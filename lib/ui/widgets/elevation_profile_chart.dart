import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/peloton/drafting_grid_system.dart';
import '../../engine/peloton/rider_race_state.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../state/race_simulation_notifier.dart';

/// Interaktywny widget profilu wysokościowego etapu w stylu oficjalnych grafik Tour de France.
/// Prezentuje wysokość n.p.m., kategoryzację podjazdów z kolorowaniem nachyleń:
/// - Zielony: < 4% (płasko / łagodnie)
/// - Niebieski: 4 - 7% (umiarkowane nachylenie)
/// - Czerwony: 7 - 10% (stromy podjazd)
/// - Czarny: > 10% (ekstremalna ściana)
/// Oznacza premie górskie (KOM) i lotne finisze (Sprint), a podczas aktywnego wyścigu
/// rysuje na żywo pozycje ucieczki, peletonu i kolarzy gracza.
class ElevationProfileChart extends StatefulWidget {
  final RaceStage stage;

  /// Opcjonalna lista snapshotów kolarzy w trakcie symulacji
  final List<RiderPositionSnapshot>? riderSnapshots;

  /// Alternatywna mapa stanów kolarzy
  final Map<String, RiderRaceState>? riderStates;

  /// Grupy na trasie (Ucieczka, Peleton, Grupetto)
  final List<PelotonGroup>? groups;

  /// Identyfikatory kolarzy gracza
  final List<String> playerRiderIds;

  /// Identyfikator aktualnie śledzonego kolarza
  final String? selectedRiderId;

  /// Aktualny kilometraż czoła wyścigu
  final double? currentLeadKm;

  /// Czy etap jest w trybie aktywnej symulacji wyścigu na żywo
  final bool isLiveRace;

  /// Wysokość widżetu (null = elastyczna do kontenera nadrzędnego)
  final double? height;

  /// Czy wyświetlać górny nagłówek etapu i legendę nachyleń
  final bool showHeader;

  /// Czy wyświetlać interaktywny wskaźnik scrubber z tooltipem
  final bool enableScrubber;

  /// Callback po dotknięciu kolarza na wykresie
  final ValueChanged<String>? onRiderSelected;

  /// Callback po przesunięciu wskaźnika kilometrażu
  final ValueChanged<double>? onKmScrubbed;

  const ElevationProfileChart({
    super.key,
    required this.stage,
    this.riderSnapshots,
    this.riderStates,
    this.groups,
    this.playerRiderIds = const [],
    this.selectedRiderId,
    this.currentLeadKm,
    this.isLiveRace = false,
    this.height,
    this.showHeader = true,
    this.enableScrubber = true,
    this.onRiderSelected,
    this.onKmScrubbed,
  });

  @override
  State<ElevationProfileChart> createState() => _ElevationProfileChartState();

  /// Zwraca oficjalny kolor nachylenia w standardzie Tour de France
  static Color getGradientColor(double gradientPercent,
      {SegmentSurfaceType? surface}) {
    if (surface != null && surface.name.toLowerCase().contains('cobble')) {
      return const Color(0xFF9CA3AF); // Szary pas brukowy (Cobblestones)
    }
    if (surface == SegmentSurfaceType.gravelStrade) {
      return const Color(0xFFD2A679); // Toskański szuter (Strade Bianche)
    }
    if (gradientPercent < 4.0) {
      return const Color(0xFF2ECC71); // Zielony < 4%
    } else if (gradientPercent < 7.0) {
      return const Color(0xFF3B82F6); // Niebieski 4 - 7%
    } else if (gradientPercent < 10.0) {
      return const Color(0xFFEF4444); // Czerwony 7 - 10%
    } else {
      return const Color(0xFF141416); // Czarny > 10% (Ekstremalna ściana)
    }
  }

  /// Zwraca czytelną etykietę nachylenia
  static String getGradientLabel(double gradientPercent) {
    if (gradientPercent < 4.0) return '< 4% Płasko';
    if (gradientPercent < 7.0) return '4 - 7% Średnio';
    if (gradientPercent < 10.0) return '7 - 10% Stromo';
    return '> 10% Ściana';
  }
}

class _ElevationProfileChartState extends State<ElevationProfileChart> {
  double? _scrubKm;
  bool _isScrubbing = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double effectiveHeight = widget.height ?? constraints.maxHeight;

        return Container(
          height: effectiveHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF0F1116),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Górny nagłówek etapu i oficjalna legenda nachyleń Tour de France
              if (widget.showHeader) _buildStageHeader(),

              // 2. Interaktywny profil wysokościowy (Canvas)
              Expanded(
                child: GestureDetector(
                  onPanDown: widget.enableScrubber ? _handleScrubStart : null,
                  onPanUpdate:
                      widget.enableScrubber ? _handleScrubUpdate : null,
                  onPanEnd: widget.enableScrubber ? _handleScrubEnd : null,
                  onPanCancel:
                      widget.enableScrubber ? _handleScrubCancel : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CustomPaint(
                      painter: _ElevationProfilePainter(
                        stage: widget.stage,
                        riderSnapshots: widget.riderSnapshots,
                        riderStates: widget.riderStates,
                        groups: widget.groups,
                        playerRiderIds: widget.playerRiderIds,
                        selectedRiderId: widget.selectedRiderId,
                        currentLeadKm: widget.currentLeadKm,
                        isLiveRace: widget.isLiveRace,
                        scrubKm: _scrubKm,
                        isScrubbing: _isScrubbing,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),

              // 3. Pasek podsumowania profilu lub aktywny wskaźnik scrubber
              _buildBottomInfoBar(),
            ],
          ),
        );
      },
    );
  }

  void _handleScrubStart(DragDownDetails details) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localX = details.localPosition.dx;
    final totalKm =
        widget.stage.totalDistanceKm > 0 ? widget.stage.totalDistanceKm : 100.0;
    final km = (localX / box.size.width * totalKm).clamp(0.0, totalKm);

    setState(() {
      _scrubKm = km;
      _isScrubbing = true;
    });
    widget.onKmScrubbed?.call(km);
  }

  void _handleScrubUpdate(DragUpdateDetails details) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localX = details.localPosition.dx;
    final totalKm =
        widget.stage.totalDistanceKm > 0 ? widget.stage.totalDistanceKm : 100.0;
    final km = (localX / box.size.width * totalKm).clamp(0.0, totalKm);

    setState(() {
      _scrubKm = km;
      _isScrubbing = true;
    });
    widget.onKmScrubbed?.call(km);
  }

  void _handleScrubEnd(DragEndDetails details) {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isScrubbing) {
        setState(() => _isScrubbing = false);
      }
    });
  }

  void _handleScrubCancel() {
    setState(() => _isScrubbing = false);
  }

  Widget _buildStageHeader() {
    final stage = widget.stage;
    final double totalGain = stage.totalElevationGainM;
    final double maxAlt = stage.maxElevationM;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF141822),
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        border: Border(bottom: BorderSide(color: Color(0xFF222634))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nazwa etapu i dystans
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'ETAP ${stage.stageNumber}: ${stage.name}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: AppColors.goldAccent.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '${stage.totalDistanceKm.toStringAsFixed(1)} KM',
                        style: const TextStyle(
                          color: AppColors.goldAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Przewyższenie: +${totalGain.round()} m D+',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 10),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Max: ${maxAlt.round()} m n.p.m.',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 10),
                    ),
                    if (stage.isSummitFinish) ...[
                      const SizedBox(width: 8),
                      const Text(
                        '• Finałowa wspinaczka ⛰️',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Oficjalna legenda nachyleń Tour de France
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLegendPill('< 4%', const Color(0xFF2ECC71)),
              const SizedBox(width: 4),
              _buildLegendPill('4-7%', const Color(0xFF3B82F6)),
              const SizedBox(width: 4),
              _buildLegendPill('7-10%', const Color(0xFFEF4444)),
              const SizedBox(width: 4),
              _buildLegendPill('> 10%', const Color(0xFF141416),
                  hasBorder: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendPill(String label, Color color, {bool hasBorder = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border:
            hasBorder ? Border.all(color: Colors.redAccent, width: 1.0) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: hasBorder
              ? Colors.white
              : (color.computeLuminance() > 0.4 ? Colors.black : Colors.white),
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildBottomInfoBar() {
    if (_isScrubbing && _scrubKm != null) {
      final data = _getElevationAtKm(widget.stage, _scrubKm!);
      final gradColor = ElevationProfileChart.getGradientColor(data.gradient);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: const BoxDecoration(
          color: Color(0xFF141822),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
          border: Border(top: BorderSide(color: Color(0xFF222634))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.touch_app,
                    size: 14, color: AppColors.goldAccent),
                const SizedBox(width: 6),
                Text(
                  'KM ${_scrubKm!.toStringAsFixed(1)} / ${widget.stage.totalDistanceKm.toStringAsFixed(1)} KM',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Text(
                  'Wysokość: ${data.elevation.round()} m n.p.m.',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: gradColor,
                    borderRadius: BorderRadius.circular(4),
                    border: data.gradient > 10.0
                        ? Border.all(color: Colors.redAccent)
                        : null,
                  ),
                  child: Text(
                    '${data.gradient.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: data.gradient > 10.0 ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  ElevationProfileChart.getGradientLabel(data.gradient),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Standardowy dolny pasek z podsumowaniem premii
    final komCount = widget.stage.segments.where((s) => s.isKom).length;
    final sprintCount =
        widget.stage.segments.where((s) => s.isIntermediateSprint).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: const BoxDecoration(
        color: Color(0xFF141822),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
        border: Border(top: BorderSide(color: Color(0xFF222634))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Premie górskie: $komCount',
                style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 10),
              Text(
                'Lotne finisze: $sprintCount',
                style: const TextStyle(
                    color: Color(0xFF2ECC71),
                    fontSize: 10,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const Flexible(
            child: Text(
              'Dotknij i przeciągnij palcem, by sprawdzić nachylenie trasy',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 9.5),
            ),
          ),
        ],
      ),
    );
  }

  static ({double elevation, double gradient}) _getElevationAtKm(
      RaceStage stage, double km) {
    if (stage.segments.isEmpty) return (elevation: 50.0, gradient: 0.0);
    for (final seg in stage.segments) {
      if (km >= seg.startKm && km <= seg.endKm) {
        final len = math.max(0.01, seg.lengthKm);
        final progress = ((km - seg.startKm) / len).clamp(0.0, 1.0);
        final elev = seg.startElevationM +
            progress * (seg.endElevationM - seg.startElevationM);
        return (elevation: elev, gradient: seg.gradientPercent);
      }
    }
    return (
      elevation: stage.segments.last.endElevationM,
      gradient: stage.segments.last.gradientPercent
    );
  }
}

/// Wejściowy silnik wektorowy rysujący pełny profil 2D, premie, siatkę i kolarzy
class _ElevationProfilePainter extends CustomPainter {
  final RaceStage stage;
  final List<RiderPositionSnapshot>? riderSnapshots;
  final Map<String, RiderRaceState>? riderStates;
  final List<PelotonGroup>? groups;
  final List<String> playerRiderIds;
  final String? selectedRiderId;
  final double? currentLeadKm;
  final bool isLiveRace;
  final double? scrubKm;
  final bool isScrubbing;

  _ElevationProfilePainter({
    required this.stage,
    this.riderSnapshots,
    this.riderStates,
    this.groups,
    this.playerRiderIds = const [],
    this.selectedRiderId,
    this.currentLeadKm,
    this.isLiveRace = false,
    this.scrubKm,
    this.isScrubbing = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Obszar roboczy wykresu z marginesami na etykiety
    const double marginLeft = 38.0;
    const double marginRight = 16.0;
    const double marginTop = 30.0;
    const double marginBottom = 28.0;

    final double chartWidth = w - marginLeft - marginRight;
    final double chartHeight = h - marginTop - marginBottom;
    final double baselineY = marginTop + chartHeight;

    final double totalKm =
        stage.totalDistanceKm > 0 ? stage.totalDistanceKm : 100.0;
    final double minAlt = math.max(0.0, stage.minElevationM * 0.85);
    final double maxAlt =
        stage.maxElevationM > 0 ? stage.maxElevationM * 1.15 : 2000.0;
    final double altRange = math.max(200.0, maxAlt - minAlt);

    double xFromKm(double km) =>
        marginLeft + (km.clamp(0.0, totalKm) / totalKm) * chartWidth;
    double yFromAlt(double alt) =>
        baselineY - (((alt - minAlt) / altRange) * chartHeight);

    // 1. Poziome linie siatki wysokości n.p.m.
    _drawAltitudeGrid(canvas, minAlt, maxAlt, marginLeft, chartWidth, yFromAlt);

    // 2. Pionowe linie siatki kilometrowej
    _drawDistanceGrid(canvas, totalKm, marginLeft, baselineY, chartHeight,
        marginTop, xFromKm);

    // 3. Kolorowe segmenty nachyleń profilu (Tour de France gradient fills)
    _drawElevationSegments(canvas, baselineY, xFromKm, yFromAlt);

    // 4. Znaczniki premii górskich (KOM) i lotnych sprintów
    _drawStageMilestones(canvas, xFromKm, yFromAlt, baselineY);

    // 5. Linia mety (Finish Gate)
    _drawFinishLine(canvas, totalKm, xFromKm, baselineY, marginTop);

    // 6. Aktywne znaczniki wyścigu na żywo (Ucieczka, Peleton, Kolarze gracza)
    if (isLiveRace) {
      _drawLiveRaceTrack(
          canvas, xFromKm, yFromAlt, totalKm, baselineY, marginTop);
    }

    // 7. Interaktywny wskaźnik Scrubber
    if (isScrubbing && scrubKm != null) {
      _drawScrubberIndicator(
          canvas, scrubKm!, xFromKm, yFromAlt, baselineY, marginTop);
    }
  }

  void _drawAltitudeGrid(
    Canvas canvas,
    double minAlt,
    double maxAlt,
    double marginLeft,
    double chartWidth,
    double Function(double) yFromAlt,
  ) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1.0;

    final double altStep = maxAlt > 1800 ? 500.0 : 250.0;
    final double startAlt = (minAlt / altStep).ceil() * altStep;

    for (double alt = startAlt; alt <= maxAlt; alt += altStep) {
      final double y = yFromAlt(alt);
      canvas.drawLine(
          Offset(marginLeft, y), Offset(marginLeft + chartWidth, y), gridPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${alt.toInt()}m',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(4, y - 6));
    }
  }

  void _drawDistanceGrid(
    Canvas canvas,
    double totalKm,
    double marginLeft,
    double baselineY,
    double chartHeight,
    double marginTop,
    double Function(double) xFromKm,
  ) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    final double stepKm = totalKm > 150 ? 50.0 : 25.0;

    for (double km = stepKm; km < totalKm; km += stepKm) {
      final double x = xFromKm(km);
      canvas.drawLine(Offset(x, marginTop), Offset(x, baselineY), gridPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${km.toInt()}k',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.30),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(x - 8, baselineY + 5));
    }
  }

  void _drawElevationSegments(
    Canvas canvas,
    double baselineY,
    double Function(double) xFromKm,
    double Function(double) yFromAlt,
  ) {
    if (stage.segments.isEmpty) return;

    for (final seg in stage.segments) {
      final double x1 = xFromKm(seg.startKm);
      final double x2 = xFromKm(seg.endKm);
      final double y1 = yFromAlt(seg.startElevationM);
      final double y2 = yFromAlt(seg.endElevationM);

      final Color gradColor = ElevationProfileChart.getGradientColor(
        seg.gradientPercent,
        surface: seg.surfaceType,
      );

      // Wypełnienie obszaru pod segmentem (Vertical Fade Gradient)
      final fillPath = Path()
        ..moveTo(x1, baselineY)
        ..lineTo(x1, y1)
        ..lineTo(x2, y2)
        ..lineTo(x2, baselineY)
        ..close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            gradColor.withValues(alpha: 0.48),
            gradColor.withValues(alpha: 0.04),
          ],
        ).createShader(Rect.fromLTRB(x1, math.min(y1, y2), x2, baselineY));

      canvas.drawPath(fillPath, fillPaint);

      // Górna krawędź szosy o grubości 3.2px
      final roadLinePaint = Paint()
        ..color = gradColor
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), roadLinePaint);

      // Ostrzegawczy czerwony obrys dla ścian powyżej 10% nachylenia
      if (seg.gradientPercent >= 10.0) {
        final wallBorderPaint = Paint()
          ..color = Colors.redAccent
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
            Offset(x1, y1 - 2.0), Offset(x2, y2 - 2.0), wallBorderPaint);
      }
    }
  }

  void _drawStageMilestones(
    Canvas canvas,
    double Function(double) xFromKm,
    double Function(double) yFromAlt,
    double baselineY,
  ) {
    for (final seg in stage.segments) {
      final double flagX = xFromKm(seg.endKm);
      final double flagY = yFromAlt(seg.endElevationM);

      // A. Premia górska (KOM)
      if (seg.isKom) {
        final String category = seg.climbCategory ?? 'KOM';
        final isHc = category == 'HC';

        // Maszt flagi
        final polePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..strokeWidth = 1.4;
        canvas.drawLine(
            Offset(flagX, flagY), Offset(flagX, flagY - 26), polePaint);

        // Flaga górska w grochy (Polka-dot flag)
        final flagPath = Path()
          ..moveTo(flagX, flagY - 26)
          ..lineTo(flagX + 18, flagY - 19)
          ..lineTo(flagX, flagY - 12)
          ..close();

        final flagPaint = Paint()
          ..color = isHc ? const Color(0xFF7C3AED) : const Color(0xFFDC2626);
        canvas.drawPath(flagPath, flagPaint);

        // Kategoria podjazdu na fladze
        final textPainter = TextPainter(
          text: TextSpan(
            text: category,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(canvas, Offset(flagX + 2.5, flagY - 23));
      }

      // B. Lotny sprint finiszowy (Intermediate Sprint)
      if (seg.isIntermediateSprint) {
        final sprintPaint = Paint()
          ..color = const Color(0xFF10B981)
          ..strokeWidth = 1.6;
        canvas.drawLine(
            Offset(flagX, flagY), Offset(flagX, flagY - 22), sprintPaint);

        // Zielona tarcza sprintu "S"
        canvas.drawCircle(Offset(flagX, flagY - 25), 6.5,
            Paint()..color = const Color(0xFF10B981));

        final sprintText = TextPainter(
          text: const TextSpan(
            text: 'S',
            style: TextStyle(
                color: Colors.white,
                fontSize: 8.5,
                fontWeight: FontWeight.w900),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        sprintText.paint(canvas, Offset(flagX - 3.2, flagY - 30));
      }
    }
  }

  void _drawFinishLine(
    Canvas canvas,
    double totalKm,
    double Function(double) xFromKm,
    double baselineY,
    double marginTop,
  ) {
    final double finishX = xFromKm(totalKm);

    // Złota brama mety
    final finishPaint = Paint()
      ..color = AppColors.goldAccent
      ..strokeWidth = 2.4;

    canvas.drawLine(Offset(finishX, marginTop - 10), Offset(finishX, baselineY),
        finishPaint);

    final finishText = TextPainter(
      text: const TextSpan(
        text: '🏁 META',
        style: TextStyle(
          color: AppColors.goldAccent,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    finishText.paint(canvas, Offset(finishX - 22, marginTop - 22));
  }

  void _drawLiveRaceTrack(
    Canvas canvas,
    double Function(double) xFromKm,
    double Function(double) yFromAlt,
    double totalKm,
    double baselineY,
    double marginTop,
  ) {
    // A. Laser czoła wyścigu (Lead kilometer mark)
    if (currentLeadKm != null && currentLeadKm! > 0) {
      final double leadX = xFromKm(currentLeadKm!);
      final laserPaint = Paint()
        ..color = AppColors.goldAccent.withValues(alpha: 0.35)
        ..strokeWidth = 1.5;
      canvas.drawLine(
          Offset(leadX, marginTop), Offset(leadX, baselineY), laserPaint);
    }

    // B. Grupy na trasie (Ucieczka, Peleton, Grupetto)
    if (groups != null && groups!.isNotEmpty) {
      for (final grp in groups!) {
        final double grpKm = grp.distanceCoveredKm;
        final double gx = xFromKm(grpKm);
        final double gy = yFromAlt(_getAltAtKm(grpKm));

        Color grpColor = Colors.blueAccent;

        if (grp.type == GroupType.breakaway || grp.type == GroupType.solo) {
          grpColor = Colors.amber;
        } else if (grp.type == GroupType.grupetto) {
          grpColor = Colors.grey;
        }

        // Pionowy znacznik grupy
        canvas.drawCircle(Offset(gx, gy), 4.5, Paint()..color = grpColor);
        canvas.drawCircle(Offset(gx, gy), 2.0, Paint()..color = Colors.white);
      }
    }

    // C. Kolarze gracza (Player Riders)
    final Set<String> playerSet = Set<String>.from(playerRiderIds);

    if (riderSnapshots != null && riderSnapshots!.isNotEmpty) {
      for (final snap in riderSnapshots!) {
        if (!snap.isPlayerRider && !playerSet.contains(snap.riderId)) continue;

        final double rx = xFromKm(snap.kilometerMark);
        final double ry = yFromAlt(snap.elevationMeters);
        final bool isSelected = snap.riderId == selectedRiderId;

        // Pulsujący reticle dla wybranego zawodnika
        if (isSelected) {
          canvas.drawCircle(
            Offset(rx, ry),
            8.5,
            Paint()
              ..color = AppColors.goldAccent.withValues(alpha: 0.4)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0,
          );
        }

        // Znacznik kolarza gracza
        final jerseyColor =
            _parseHexColor(snap.teamJerseyHexColor, AppColors.goldAccent);
        canvas.drawCircle(Offset(rx, ry), 5.0, Paint()..color = jerseyColor);
        canvas.drawCircle(
          Offset(rx, ry),
          5.0,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );

        // Numer startowy lub gwiazdka lidera
        canvas.drawCircle(Offset(rx, ry), 1.8, Paint()..color = Colors.white);
      }
    } else if (riderStates != null) {
      for (final id in playerRiderIds) {
        final rState = riderStates![id];
        if (rState == null) continue;

        final double rKm = rState.distanceCoveredKm;
        final double rx = xFromKm(rKm);
        final double ry = yFromAlt(_getAltAtKm(rKm));
        final bool isSelected = id == selectedRiderId;

        if (isSelected) {
          canvas.drawCircle(
            Offset(rx, ry),
            8.0,
            Paint()
              ..color = AppColors.goldAccent.withValues(alpha: 0.4)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.8,
          );
        }

        canvas.drawCircle(
            Offset(rx, ry), 4.8, Paint()..color = AppColors.goldAccent);
        canvas.drawCircle(Offset(rx, ry), 1.8, Paint()..color = Colors.black);
      }
    }
  }

  void _drawScrubberIndicator(
    Canvas canvas,
    double sKm,
    double Function(double) xFromKm,
    double Function(double) yFromAlt,
    double baselineY,
    double marginTop,
  ) {
    final double sx = xFromKm(sKm);
    final double sy = yFromAlt(_getAltAtKm(sKm));

    // Pionowa linia scrubbera
    final scrubLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 1.4;

    canvas.drawLine(
        Offset(sx, marginTop - 8), Offset(sx, baselineY), scrubLinePaint);

    // Kropka na profilu trasy
    canvas.drawCircle(
        Offset(sx, sy), 5.5, Paint()..color = AppColors.goldAccent);
    canvas.drawCircle(Offset(sx, sy), 3.0, Paint()..color = Colors.black);
  }

  double _getAltAtKm(double km) {
    if (stage.segments.isEmpty) return 100.0;
    for (final seg in stage.segments) {
      if (km >= seg.startKm && km <= seg.endKm) {
        final len = math.max(0.01, seg.lengthKm);
        final prog = ((km - seg.startKm) / len).clamp(0.0, 1.0);
        return seg.startElevationM +
            prog * (seg.endElevationM - seg.startElevationM);
      }
    }
    return stage.segments.last.endElevationM;
  }

  static Color _parseHexColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      String clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) clean = 'FF$clean';
      return Color(int.parse(clean, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  bool shouldRepaint(covariant _ElevationProfilePainter oldDelegate) {
    return oldDelegate.stage != stage ||
        oldDelegate.currentLeadKm != currentLeadKm ||
        oldDelegate.selectedRiderId != selectedRiderId ||
        oldDelegate.scrubKm != scrubKm ||
        oldDelegate.isScrubbing != isScrubbing ||
        oldDelegate.riderSnapshots != riderSnapshots;
  }
}
