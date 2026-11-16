import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/rider/rider.dart';

/// Tryb prezentacji danych analitycznych kolarza
enum AnalyticsViewMode {
  /// Krzywa mocy w czasie (Power Duration Curve)
  powerDurationCurve,

  /// Radar atrybutów fizjologicznych i technicznych
  skillsRadar,

  /// Bezpośrednia tabela porównawcza Head-to-Head
  comparisonTable;

  String get label {
    switch (this) {
      case AnalyticsViewMode.powerDurationCurve:
        return 'Krzywa Mocy';
      case AnalyticsViewMode.skillsRadar:
        return 'Radar Atrybutów';
      case AnalyticsViewMode.comparisonTable:
        return 'Porównanie H2H';
    }
  }

  IconData get icon {
    switch (this) {
      case AnalyticsViewMode.powerDurationCurve:
        return Icons.show_chart;
      case AnalyticsViewMode.skillsRadar:
        return Icons.radar;
      case AnalyticsViewMode.comparisonTable:
        return Icons.compare_arrows;
    }
  }
}

/// Profesjonalny widget analityczny prezentujący Krzywą Mocy (Power Duration Curve)
/// oraz radar umiejętności kolarza z możliwością nałożenia drugiego zawodnika do porównania.
class PowerCurveChartWidget extends StatefulWidget {
  /// Główny analizowany kolarz (Kolarz A)
  final Rider riderA;

  /// Opcjonalny drugi kolarz do bezpośredniego porównania (Kolarz B)
  final Rider? riderB;

  /// Czy domyślnie pokazywać waty na kilogram (W/kg) zamiast watów bezwzględnych (W)
  final bool initialRelativeWKg;

  /// Kolor wykresu kolarza A (domyślnie złoty akcent)
  final Color colorA;

  /// Kolor wykresu kolarza B (domyślnie błękit cyan)
  final Color colorB;

  /// Wysokość całego widżetu
  final double height;

  /// Czy pokazywać przełącznik zakładek (Krzywa / Radar / Tabela)
  final bool showTabs;

  /// Czy pokazywać nagłówek z kartami kolarzy
  final bool showHeader;

  /// Opcjonalny callback wywoływany przy chęci wyboru/zmiany drugiego kolarza
  final VoidCallback? onSelectRiderB;

  const PowerCurveChartWidget({
    super.key,
    required this.riderA,
    this.riderB,
    this.initialRelativeWKg = false,
    this.colorA = const Color(0xFFF59E0B), // Amber / Złoto
    this.colorB = const Color(0xFF38BDF8), // Cyan / Błękit
    this.height = 420.0,
    this.showTabs = true,
    this.showHeader = true,
    this.onSelectRiderB,
  });

  @override
  State<PowerCurveChartWidget> createState() => _PowerCurveChartWidgetState();
}

class _PowerCurveChartWidgetState extends State<PowerCurveChartWidget> {
  late bool _useWKg;
  AnalyticsViewMode _viewMode = AnalyticsViewMode.powerDurationCurve;

  // Punkty czasowe krzywej mocy na osi X
  static const List<String> durationLabels = ['5s', '15s', '1m', '5m', '20m', '60m'];
  static const List<String> durationDescriptions = [
    'Sprint Max',
    'Zryw',
    'Beztlenowa',
    'VO2max',
    'Próg / Wspinaczka',
    'FTP / Wytrzymałość',
  ];

  @override
  void initState() {
    super.initState();
    _useWKg = widget.initialRelativeWKg;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Nagłówek kolarzy i opcjonalny selektor porównania
          if (widget.showHeader) _buildRidersHeader(),

          // 2. Belka zakładek widoku i przełącznik W vs W/kg
          _buildControlToolbar(),

          // 3. Główny obszar wykresu (Krzywa Mocy / Radar / Tabela)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: _buildActiveView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRidersHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF141822),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: Color(0xFF222634))),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          // Kolarz A (Główny)
          _buildRiderBadge(
            rider: widget.riderA,
            color: widget.colorA,
            isPrimary: true,
          ),

          // Znacznik VS i Kolarz B
          if (widget.riderB != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Text(
                'VS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            _buildRiderBadge(
              rider: widget.riderB!,
              color: widget.colorB,
              isPrimary: false,
            ),
          ] else if (widget.onSelectRiderB != null) ...[
            OutlinedButton.icon(
              onPressed: widget.onSelectRiderB,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.goldAccent),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              icon: const Icon(Icons.person_add, size: 14, color: AppColors.goldAccent),
              label: const Text(
                'Porównaj z rywalem',
                style: TextStyle(color: AppColors.goldAccent, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRiderBadge({
    required Rider rider,
    required Color color,
    required bool isPrimary,
  }) {
    final double weight = rider.physiology.weightKg > 0 ? rider.physiology.weightKg : 70.0;
    final double wKgFtp = rider.physiology.ftpWatts / weight;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      rider.fullName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                Text(
                  rider.nationalityIso.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              '${weight.toStringAsFixed(1)} kg • FTP ${rider.physiology.ftpWatts}W (${wKgFtp.toStringAsFixed(2)} W/kg)',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
        ),
      ],
    );
  }

  Widget _buildControlToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF161A24),
        border: Border(bottom: BorderSide(color: Color(0xFF222634))),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          // Przełącznik widoków (Krzywa / Radar / Tabela)
          if (widget.showTabs)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: AnalyticsViewMode.values.map((mode) {
                final isSelected = mode == _viewMode;
                return InkWell(
                  onTap: () => setState(() => _viewMode = mode),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryAccent : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : Colors.white12,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          mode.icon,
                          size: 13,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          mode.label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            )
          else
            const SizedBox.shrink(),

          // Przełącznik jednostki: Waty [W] vs W/kg (widoczny przy krzywej mocy)
          if (_viewMode == AnalyticsViewMode.powerDurationCurve)
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildUnitTogglePill('Waty [W]', !_useWKg, () => setState(() => _useWKg = false)),
                  _buildUnitTogglePill('W/kg', _useWKg, () => setState(() => _useWKg = true)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnitTogglePill(String title, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.textSecondary,
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveView() {
    switch (_viewMode) {
      case AnalyticsViewMode.powerDurationCurve:
        return _buildLineChart();
      case AnalyticsViewMode.skillsRadar:
        return _buildRadarChart();
      case AnalyticsViewMode.comparisonTable:
        return _buildComparisonTable();
    }
  }

  // ==========================================
  // 1. WYKRES KRZYWEJ MOCY (POWER DURATION CURVE)
  // ==========================================
  Widget _buildLineChart() {
    final spotsA = _getSpots(widget.riderA, _useWKg);
    final spotsB = widget.riderB != null ? _getSpots(widget.riderB!, _useWKg) : null;

    double maxY = 0.0;
    for (final s in spotsA) {
      if (s.y > maxY) maxY = s.y;
    }
    if (spotsB != null) {
      for (final s in spotsB) {
        if (s.y > maxY) maxY = s.y;
      }
    }
    maxY = _useWKg ? (maxY * 1.15).ceilToDouble() : (maxY * 1.12).ceilToDouble();

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => const Color(0xFF161A24),
            tooltipBorder: const BorderSide(color: Color(0xFF2A2E3D), width: 1.5),
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final isA = spot.barIndex == 0;
                final rider = isA ? widget.riderA : widget.riderB!;
                final color = isA ? widget.colorA : widget.colorB;
                final idx = spot.x.toInt().clamp(0, durationLabels.length - 1);
                final durName = durationLabels[idx];
                final desc = durationDescriptions[idx];

                final valStr = _useWKg ? '${spot.y.toStringAsFixed(2)} W/kg' : '${spot.y.round()} W';

                return LineTooltipItem(
                  '$durName ($desc)\n${rider.lastName}: $valStr',
                  TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _useWKg ? 3.0 : 250.0,
          verticalInterval: 1.0,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withValues(alpha: 0.06),
            strokeWidth: 1.0,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.white.withValues(alpha: 0.06),
            strokeWidth: 1.0,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1.0,
              getTitlesWidget: (value, meta) {
                final int idx = value.toInt();
                if (idx < 0 || idx >= durationLabels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    durationLabels[idx],
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: _useWKg ? 38 : 46,
              interval: _useWKg ? 4.0 : 300.0,
              getTitlesWidget: (value, meta) {
                final str = _useWKg ? '${value.toInt()}' : '${value.toInt()}W';
                return Text(
                  str,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white10),
        ),
        minX: 0,
        maxX: 5,
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          // Linia Kolarza A
          LineChartBarData(
            spots: spotsA,
            isCurved: true,
            curveSmoothness: 0.35,
            color: widget.colorA,
            barWidth: 3.2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4.5,
                color: widget.colorA,
                strokeColor: Colors.black,
                strokeWidth: 1.8,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.colorA.withValues(alpha: 0.25),
                  widget.colorA.withValues(alpha: 0.01),
                ],
              ),
            ),
          ),

          // Linia Kolarza B (jeśli obecny)
          if (spotsB != null)
            LineChartBarData(
              spots: spotsB,
              isCurved: true,
              curveSmoothness: 0.35,
              color: widget.colorB,
              barWidth: 3.0,
              dashArray: [6, 4],
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4.0,
                  color: widget.colorB,
                  strokeColor: Colors.black,
                  strokeWidth: 1.5,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.colorB.withValues(alpha: 0.18),
                    widget.colorB.withValues(alpha: 0.00),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<FlSpot> _getSpots(Rider rider, bool relative) {
    final p = rider.powerProfile;
    final double w = math.max(45.0, rider.physiology.weightKg);

    double val(int watts) => relative ? (watts / w) : watts.toDouble();

    return [
      FlSpot(0, val(p.watts5s)),
      FlSpot(1, val(p.watts15s)),
      FlSpot(2, val(p.watts1m)),
      FlSpot(3, val(p.watts5m)),
      FlSpot(4, val(p.watts20m)),
      FlSpot(5, val(p.watts60m)),
    ];
  }

  // ==========================================
  // 2. RADAR STATYSTYK KOLARZA (SKILLS RADAR)
  // ==========================================
  Widget _buildRadarChart() {
    final List<String> radarCategories = [
      'Sprint (5s)',
      'Wspinaczka (20m)',
      'Jazda na Czas (TT)',
      'Beztlenowość (1m)',
      'Zjazdy i Technika',
      'Bruki i Odporność',
    ];

    final scoresA = _computeRadarScores(widget.riderA);
    final scoresB = widget.riderB != null ? _computeRadarScores(widget.riderB!) : null;

    final entriesA = scoresA.map((val) => RadarEntry(value: val)).toList();
    final entriesB = scoresB?.map((val) => RadarEntry(value: val)).toList();

    return RadarChart(
      RadarChartData(
        radarTouchData: RadarTouchData(enabled: true),
        dataSets: [
          RadarDataSet(
            fillColor: widget.colorA.withValues(alpha: 0.24),
            borderColor: widget.colorA,
            borderWidth: 2.4,
            entryRadius: 3.5,
            dataEntries: entriesA,
          ),
          if (entriesB != null)
            RadarDataSet(
              fillColor: widget.colorB.withValues(alpha: 0.20),
              borderColor: widget.colorB,
              borderWidth: 2.2,
              entryRadius: 3.0,
              dataEntries: entriesB,
            ),
        ],
        radarBackgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        radarBorderData: const BorderSide(color: Colors.white12, width: 1.0),
        titlePositionPercentageOffset: 0.22,
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
        getTitle: (index, angle) {
          final idx = index.clamp(0, radarCategories.length - 1);
          return RadarChartTitle(text: radarCategories[idx]);
        },
        tickCount: 4,
        ticksTextStyle: const TextStyle(color: Colors.white24, fontSize: 8),
        tickBorderData: const BorderSide(color: Colors.white10, width: 1.0),
        gridBorderData: const BorderSide(color: Colors.white12, width: 1.0),
      ),
    );
  }

  List<double> _computeRadarScores(Rider r) {
    final double weight = math.max(45.0, r.physiology.weightKg);

    // 1. Sprint (5s / 15s)
    final double sprintScore = ((r.powerProfile.watts5s / 1600.0) * 100.0).clamp(15.0, 99.0);

    // 2. Wspinaczka (20m W/kg)
    final double climbScore = (((r.powerProfile.watts20m / weight) / 6.6) * 100.0).clamp(15.0, 99.0);

    // 3. Jazda na czas (60m bezwzględna moc + aerodynamika)
    final double ttScore = (((r.powerProfile.watts60m / 460.0) * 60.0) +
            (r.skills.timeTrialPositioning * 0.4))
        .clamp(15.0, 99.0);

    // 4. Beztlenowość (1m W/kg + VO2max)
    final double anaerobicScore =
        (((r.powerProfile.watts1m / weight) / 11.5) * 55.0 + (r.physiology.vo2Max / 88.0) * 45.0)
            .clamp(15.0, 99.0);

    // 5. Zjazdy i technika
    final double handlingScore =
        (r.skills.descending * 0.6 + r.skills.bikeHandling * 0.4).clamp(15.0, 99.0);

    // 6. Bruki i odporność
    final double cobblesScore = (r.skills.cobbles * 0.5 +
            r.skills.draftingEfficiency * 0.3 +
            r.skills.rainResistance * 0.2)
        .clamp(15.0, 99.0);

    return [
      sprintScore,
      climbScore,
      ttScore,
      anaerobicScore,
      handlingScore,
      cobblesScore,
    ];
  }

  // ==========================================
  // 3. TABELA PORÓWNAWCZA (HEAD-TO-HEAD)
  // ==========================================
  Widget _buildComparisonTable() {
    final rA = widget.riderA;
    final rB = widget.riderB;

    final double wA = math.max(45.0, rA.physiology.weightKg);
    final double wB = rB != null ? math.max(45.0, rB.physiology.weightKg) : 70.0;

    final List<_MetricComparisonRow> rows = [
      _MetricComparisonRow(
        title: 'Moc 5s (Sprint)',
        valA: '${rA.powerProfile.watts5s} W (${(rA.powerProfile.watts5s / wA).toStringAsFixed(1)} W/kg)',
        valB: rB != null
            ? '${rB.powerProfile.watts5s} W (${(rB.powerProfile.watts5s / wB).toStringAsFixed(1)} W/kg)'
            : '—',
        scoreA: rA.powerProfile.watts5s.toDouble(),
        scoreB: rB?.powerProfile.watts5s.toDouble(),
      ),
      _MetricComparisonRow(
        title: 'Moc 15s (Zryw)',
        valA: '${rA.powerProfile.watts15s} W (${(rA.powerProfile.watts15s / wA).toStringAsFixed(1)} W/kg)',
        valB: rB != null
            ? '${rB.powerProfile.watts15s} W (${(rB.powerProfile.watts15s / wB).toStringAsFixed(1)} W/kg)'
            : '—',
        scoreA: rA.powerProfile.watts15s.toDouble(),
        scoreB: rB?.powerProfile.watts15s.toDouble(),
      ),
      _MetricComparisonRow(
        title: 'Moc 1m (Atak)',
        valA: '${rA.powerProfile.watts1m} W (${(rA.powerProfile.watts1m / wA).toStringAsFixed(1)} W/kg)',
        valB: rB != null
            ? '${rB.powerProfile.watts1m} W (${(rB.powerProfile.watts1m / wB).toStringAsFixed(1)} W/kg)'
            : '—',
        scoreA: rA.powerProfile.watts1m.toDouble(),
        scoreB: rB?.powerProfile.watts1m.toDouble(),
      ),
      _MetricComparisonRow(
        title: 'Moc 5m (VO2max)',
        valA: '${rA.powerProfile.watts5m} W (${(rA.powerProfile.watts5m / wA).toStringAsFixed(1)} W/kg)',
        valB: rB != null
            ? '${rB.powerProfile.watts5m} W (${(rB.powerProfile.watts5m / wB).toStringAsFixed(1)} W/kg)'
            : '—',
        scoreA: (rA.powerProfile.watts5m / wA),
        scoreB: rB != null ? (rB.powerProfile.watts5m / wB) : null,
      ),
      _MetricComparisonRow(
        title: 'Moc 20m (Wspinaczka)',
        valA: '${rA.powerProfile.watts20m} W (${(rA.powerProfile.watts20m / wA).toStringAsFixed(2)} W/kg)',
        valB: rB != null
            ? '${rB.powerProfile.watts20m} W (${(rB.powerProfile.watts20m / wB).toStringAsFixed(2)} W/kg)'
            : '—',
        scoreA: (rA.powerProfile.watts20m / wA),
        scoreB: rB != null ? (rB.powerProfile.watts20m / wB) : null,
      ),
      _MetricComparisonRow(
        title: 'FTP / 60m (Próg)',
        valA: '${rA.physiology.ftpWatts} W (${(rA.physiology.ftpWatts / wA).toStringAsFixed(2)} W/kg)',
        valB: rB != null
            ? '${rB.physiology.ftpWatts} W (${(rB.physiology.ftpWatts / wB).toStringAsFixed(2)} W/kg)'
            : '—',
        scoreA: (rA.physiology.ftpWatts / wA),
        scoreB: rB != null ? (rB.physiology.ftpWatts / wB) : null,
      ),
      _MetricComparisonRow(
        title: 'VO2 Max',
        valA: '${rA.physiology.vo2Max.toStringAsFixed(1)} ml/kg/min',
        valB: rB != null ? '${rB.physiology.vo2Max.toStringAsFixed(1)} ml/kg/min' : '—',
        scoreA: rA.physiology.vo2Max,
        scoreB: rB?.physiology.vo2Max,
      ),
      _MetricComparisonRow(
        title: 'Pojemność beztlenowa W\'',
        valA: '${(rA.physiology.wPrimeJoules / 1000.0).toStringAsFixed(1)} kJ',
        valB: rB != null ? '${(rB.physiology.wPrimeJoules / 1000.0).toStringAsFixed(1)} kJ' : '—',
        scoreA: rA.physiology.wPrimeJoules.toDouble(),
        scoreB: rB?.physiology.wPrimeJoules.toDouble(),
      ),
      _MetricComparisonRow(
        title: 'Masa ciała',
        valA: '${rA.physiology.weightKg.toStringAsFixed(1)} kg',
        valB: rB != null ? '${rB.physiology.weightKg.toStringAsFixed(1)} kg' : '—',
        scoreA: -rA.physiology.weightKg, // Mniejsza waga w górach bywa zaletą
        scoreB: rB != null ? -rB.physiology.weightKg : null,
      ),
    ];

    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
      itemBuilder: (context, idx) {
        final r = rows[idx];
        final bool aBetter = r.scoreB != null && r.scoreA > r.scoreB!;
        final bool bBetter = r.scoreB != null && r.scoreB! > r.scoreA;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  r.title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    if (aBetter)
                      const Icon(Icons.check_circle, size: 12, color: AppColors.goldAccent),
                    const SizedBox(width: 4),
                    Text(
                      r.valA,
                      style: TextStyle(
                        color: aBetter ? Colors.white : AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: aBetter ? FontWeight.w900 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    if (bBetter)
                      const Icon(Icons.check_circle, size: 12, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 4),
                    Text(
                      r.valB,
                      style: TextStyle(
                        color: bBetter ? Colors.white : AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: bBetter ? FontWeight.w900 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricComparisonRow {
  final String title;
  final String valA;
  final String valB;
  final double scoreA;
  final double? scoreB;

  const _MetricComparisonRow({
    required this.title,
    required this.valA,
    required this.valB,
    required this.scoreA,
    this.scoreB,
  });
}
