import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../engine/peloton/echelon_crosswind_engine.dart';

/// Poziom zagrożenia rozerwaniem peletonu na ranty przy wietrze bocznym.
enum EchelonRiskLevel {
  /// Niskie ryzyko — wiatr zbyt słaby lub niemal czołowy/tylny.
  low,

  /// Umiarkowane ryzyko — peleton czujny, możliwe pierwsze przyspieszenia.
  moderate,

  /// Wysokie ryzyko — strefa rantów aktywna ("CROSSWIND ZONE — ECHELON RISK HIGH").
  high,

  /// Ekstremalne ryzyko — pełne wachlarze i gwałtowne podziały w rynsztoku.
  extreme;

  /// Wyznacza poziom ryzyka na podstawie składowej bocznej wiatru i kąta natarcia.
  static EchelonRiskLevel fromCrosswind({
    required double crosswindSpeedKmh,
    required double attackAngleDegrees,
  }) {
    final double safeSpeed =
        crosswindSpeedKmh.isNaN || crosswindSpeedKmh.isInfinite
            ? 0.0
            : crosswindSpeedKmh.abs();
    final double absAngle =
        attackAngleDegrees.isNaN || attackAngleDegrees.isInfinite
            ? 0.0
            : attackAngleDegrees.abs();

    final bool isCrosswindGeometry = absAngle >= 28.0 && absAngle <= 152.0;
    if (!isCrosswindGeometry && safeSpeed < 22.0) {
      return EchelonRiskLevel.low;
    }
    if (safeSpeed >= 36.0) {
      return EchelonRiskLevel.extreme;
    }
    if (safeSpeed >= 24.0) {
      return EchelonRiskLevel.high;
    }
    if (safeSpeed >= 14.0) {
      return EchelonRiskLevel.moderate;
    }
    return EchelonRiskLevel.low;
  }

  /// Kolor przewodni poziomu ryzyka z palety [AppColors].
  Color get color {
    switch (this) {
      case EchelonRiskLevel.low:
        return AppColors.statusSuccess;
      case EchelonRiskLevel.moderate:
        return AppColors.amberWarning;
      case EchelonRiskLevel.high:
        return AppColors.crimsonAlert;
      case EchelonRiskLevel.extreme:
        return AppColors.crimsonAlert;
    }
  }

  /// Krótka etykieta statusu do wyświetlenia w pigułce telemetrycznej.
  String get shortLabel {
    switch (this) {
      case EchelonRiskLevel.low:
        return 'LOW';
      case EchelonRiskLevel.moderate:
        return 'MODERATE';
      case EchelonRiskLevel.high:
        return 'HIGH';
      case EchelonRiskLevel.extreme:
        return 'EXTREME';
    }
  }

  /// Czy dany poziom aktywuje telewizyjny alert wysokiego ryzyka rantów.
  bool get isHighRisk =>
      this == EchelonRiskLevel.high || this == EchelonRiskLevel.extreme;
}

/// Pojedynczy rant (grupa wachlarzowa) w schemacie podziału peletonu.
@immutable
class EchelonSplitRowData {
  /// Numer rantu (1 = czołowy wachlarz, 2 = drugi rant, 3 = trzeci rant).
  final int echelonNumber;

  /// Etykieta grupy (np. `RANT NR 1`, `ECHELON 1`).
  final String label;

  /// Liczba kolarzy w tym rancie.
  final int riderCount;

  /// Maksymalna pojemność wachlarza na szerokości szosy.
  final int capacity;

  /// Strata czasowa do rantu nr 1 w sekundach (`0.0` dla czoła).
  final double gapSeconds;

  /// Czy grupa jest dociśnięta do krawędzi szosy (rynsztok / gutter).
  final bool isGutterFormed;

  /// Liczba kolarzy drużyny gracza w tym rancie.
  final int playerRidersCount;

  /// Średnia oszczędność aerodynamiczna w rancie w procentach.
  final double averageDraftingSavingsPercent;

  /// Nazwiska kluczowych kolarzy (np. liderów GC) jadących w tym rancie.
  final List<String> notableRiderNames;

  const EchelonSplitRowData({
    required this.echelonNumber,
    required this.label,
    required this.riderCount,
    required this.capacity,
    required this.gapSeconds,
    this.isGutterFormed = false,
    this.playerRidersCount = 0,
    this.averageDraftingSavingsPercent = 0.0,
    this.notableRiderNames = const <String>[],
  });

  /// Konwertuje [EchelonFormation] z silnika wiatru bocznego na dane HUD.
  factory EchelonSplitRowData.fromFormation(
    EchelonFormation formation, {
    Set<String> playerTeamRiderIds = const <String>{},
    Map<String, String> riderNamesById = const <String, String>{},
  }) {
    final int playerCount = playerTeamRiderIds.isEmpty
        ? 0
        : formation.riderIds
            .where((String id) => playerTeamRiderIds.contains(id))
            .length;
    final List<String> notable = formation.riderIds
        .take(3)
        .map((String id) => riderNamesById[id] ?? id)
        .toList(growable: false);

    return EchelonSplitRowData(
      echelonNumber: formation.echelonIndex,
      label: 'RANT NR ${formation.echelonIndex}',
      riderCount: formation.riderCount,
      capacity: formation.capacity,
      gapSeconds: formation.gapToLeadEchelonSeconds,
      isGutterFormed: formation.isGutterFormed,
      playerRidersCount: playerCount,
      averageDraftingSavingsPercent: formation.averageDraftingSavingsPercent,
      notableRiderNames: notable,
    );
  }

  /// Formatuje stratę sekundową w stylu transmisji TV (np. `0.0s`, `+18.4s`, `+1'12"`).
  String get formattedGap {
    final double safeGap =
        gapSeconds.isNaN || gapSeconds.isInfinite ? 0.0 : math.max(0.0, gapSeconds);
    if (echelonNumber <= 1 && safeGap < 0.05) {
      return 'CZOŁO';
    }
    if (safeGap < 60.0) {
      return '+${safeGap.toStringAsFixed(1)}s';
    }
    final int totalSeconds = safeGap.round();
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    final String secStr = seconds.toString().padLeft(2, '0');
    return "+$minutes'$secStr\"";
  }
}

/// Pełny model danych dla telewizyjnego radaru wiatru bocznego [TvEchelonCrosswindRadarHud].
@immutable
class TvEchelonCrosswindRadarData {
  /// Nazwa sektora / lokalizacji trasy.
  final String sectorName;

  /// Prędkość całkowita wiatru w km/h.
  final double windSpeedKmh;

  /// Kierunek napływu wiatru w stopniach kompasu (`0` = N, `90` = E, `180` = S, `270` = W).
  final double windDirectionDegrees;

  /// Kierunek jazdy szosy w stopniach kompasu (`0` = N, `90` = E, `180` = S, `270` = W).
  final double roadHeadingDegrees;

  /// Opcjonalne nadpisanie składowej bocznej wiatru [km/h].
  final double? crosswindSpeedKmhOverride;

  /// Szerokość jezdni w metrach.
  final double roadWidthMeters;

  /// Czy podział na wachlarze jest aktualnie aktywny w symulacji.
  final bool isEchelonActive;

  /// Opcjonalne nadpisanie poziomu ryzyka.
  final EchelonRiskLevel? riskOverride;

  /// Lista rantów (typowo nr 1, 2 i 3) ze stratami sekundowymi.
  final List<EchelonSplitRowData> echelons;

  const TvEchelonCrosswindRadarData({
    required this.sectorName,
    required this.windSpeedKmh,
    required this.windDirectionDegrees,
    required this.roadHeadingDegrees,
    this.crosswindSpeedKmhOverride,
    this.roadWidthMeters = 6.5,
    this.isEchelonActive = true,
    this.riskOverride,
    required this.echelons,
  });

  /// Tworzy model HUD bezpośrednio z wyniku [CrosswindEchelonResult].
  factory TvEchelonCrosswindRadarData.fromCrosswindResult(
    CrosswindEchelonResult result, {
    String sectorName = 'OPEN EXPOSED SECTOR',
    required double windSpeedKmh,
    required double windDirectionDegrees,
    required double roadHeadingDegrees,
    double roadWidthMeters = 6.5,
    Set<String> playerTeamRiderIds = const <String>{},
    Map<String, String> riderNamesById = const <String, String>{},
  }) {
    final List<EchelonSplitRowData> rows = result.echelons
        .take(3)
        .map(
          (EchelonFormation f) => EchelonSplitRowData.fromFormation(
            f,
            playerTeamRiderIds: playerTeamRiderIds,
            riderNamesById: riderNamesById,
          ),
        )
        .toList(growable: false);

    return TvEchelonCrosswindRadarData(
      sectorName: sectorName,
      windSpeedKmh: windSpeedKmh,
      windDirectionDegrees: windDirectionDegrees,
      roadHeadingDegrees: roadHeadingDegrees,
      crosswindSpeedKmhOverride: result.crosswindSpeedKmh,
      roadWidthMeters: roadWidthMeters,
      isEchelonActive: result.isEchelonActive,
      echelons: rows,
    );
  }

  /// Przykładowe dane demonstracyjne wysokiej jakości (aktywne ranty nr 1, 2 i 3).
  factory TvEchelonCrosswindRadarData.demo() {
    return const TvEchelonCrosswindRadarData(
      sectorName: 'ZEELAND POLDER — KM 138.4',
      windSpeedKmh: 44.0,
      windDirectionDegrees: 295.0,
      roadHeadingDegrees: 15.0,
      roadWidthMeters: 6.0,
      isEchelonActive: true,
      echelons: <EchelonSplitRowData>[
        EchelonSplitRowData(
          echelonNumber: 1,
          label: 'RANT NR 1',
          riderCount: 16,
          capacity: 10,
          gapSeconds: 0.0,
          isGutterFormed: true,
          playerRidersCount: 3,
          averageDraftingSavingsPercent: 34.5,
          notableRiderNames: <String>['Vingegaard', 'Van der Poel', 'Philipsen'],
        ),
        EchelonSplitRowData(
          echelonNumber: 2,
          label: 'RANT NR 2',
          riderCount: 38,
          capacity: 10,
          gapSeconds: 24.6,
          isGutterFormed: true,
          playerRidersCount: 2,
          averageDraftingSavingsPercent: 27.0,
          notableRiderNames: <String>['Ganna', 'Pedersen'],
        ),
        EchelonSplitRowData(
          echelonNumber: 3,
          label: 'RANT NR 3',
          riderCount: 94,
          capacity: 10,
          gapSeconds: 68.2,
          isGutterFormed: false,
          playerRidersCount: 1,
          averageDraftingSavingsPercent: 19.5,
          notableRiderNames: <String>['Grupetto'],
        ),
      ],
    );
  }

  /// Znormalizowany kąt natarcia wiatru na oś szosy w zakresie `-180°..+180°`.
  /// Dodatni oznacza wiatr z prawej burty, ujemny z lewej burty.
  double get signedAttackAngleDegrees {
    final double w = windDirectionDegrees.isNaN || windDirectionDegrees.isInfinite
        ? 0.0
        : windDirectionDegrees;
    final double r = roadHeadingDegrees.isNaN || roadHeadingDegrees.isInfinite
        ? 0.0
        : roadHeadingDegrees;
    double diff = (w - r) % 360.0;
    if (diff > 180.0) diff -= 360.0;
    if (diff < -180.0) diff += 360.0;
    return diff;
  }

  /// Bezwzględny kąt natarcia wiatru na szosę (`0°` = wiatr czołowy, `90°` = pełny boczny).
  double get attackAngleDegrees => signedAttackAngleDegrees.abs();

  /// Składowa boczna prędkości wiatru [km/h].
  double get crosswindSpeedKmh {
    if (crosswindSpeedKmhOverride != null &&
        !crosswindSpeedKmhOverride!.isNaN &&
        !crosswindSpeedKmhOverride!.isInfinite) {
      return crosswindSpeedKmhOverride!.abs();
    }
    final double safeWind =
        windSpeedKmh.isNaN || windSpeedKmh.isInfinite ? 0.0 : windSpeedKmh.abs();
    final double rad = attackAngleDegrees * math.pi / 180.0;
    return safeWind * math.sin(rad).abs();
  }

  /// Składowa czołowa/tylna wiatru [km/h] (dodatnia = w twarz, ujemna = w plecy).
  double get headwindComponentKmh {
    final double safeWind =
        windSpeedKmh.isNaN || windSpeedKmh.isInfinite ? 0.0 : windSpeedKmh.abs();
    final double rad = attackAngleDegrees * math.pi / 180.0;
    return safeWind * math.cos(rad);
  }

  /// Strona natarcia wiatru (`P` = prawa, `L` = lewa, `C` = osiowy).
  String get windSideCode {
    final double angle = signedAttackAngleDegrees;
    if (angle.abs() < 8.0 || angle.abs() > 172.0) return 'OSIOWY';
    return angle >= 0.0 ? 'PRAWA BURTA' : 'LEWA BURTA';
  }

  /// Wyznaczony poziom ryzyka rozerwania peletonu.
  EchelonRiskLevel get riskLevel =>
      riskOverride ??
      EchelonRiskLevel.fromCrosswind(
        crosswindSpeedKmh: crosswindSpeedKmh,
        attackAngleDegrees: attackAngleDegrees,
      );

  /// Czy należy wyświetlić baner alertu `CROSSWIND ZONE — ECHELON RISK HIGH`.
  bool get showHighRiskAlert => riskLevel.isHighRisk;
}

/// Telewizyjny radar wiatru bocznego w stylu transmisji Tour de France / Eurosport.
///
/// Prezentuje:
/// - animowaną różę wiatrów z osią szosy, kątem natarcia i strugami wiatru,
/// - alert `CROSSWIND ZONE — ECHELON RISK HIGH` przy zagrożeniu rantami,
/// - schemat podziału peletonu na ranty nr 1, 2 i 3 ze stratami sekundowymi.
class TvEchelonCrosswindRadarHud extends StatefulWidget {
  final TvEchelonCrosswindRadarData data;
  final bool isEnabled;
  final int? selectedEchelonNumber;
  final ValueChanged<EchelonSplitRowData>? onEchelonSelected;
  final VoidCallback? onToggleCompact;
  final bool initiallyCompact;

  const TvEchelonCrosswindRadarHud({
    super.key,
    required this.data,
    this.isEnabled = true,
    this.selectedEchelonNumber,
    this.onEchelonSelected,
    this.onToggleCompact,
    this.initiallyCompact = false,
  });

  @override
  State<TvEchelonCrosswindRadarHud> createState() =>
      _TvEchelonCrosswindRadarHudState();
}

class _TvEchelonCrosswindRadarHudState extends State<TvEchelonCrosswindRadarHud>
    with SingleTickerProviderStateMixin {
  late final AnimationController _radarLoopController;
  late bool _isCompact;
  int? _internalSelectedEchelon;

  bool _headerButtonHovered = false;
  bool _headerButtonPressed = false;
  bool _headerButtonFocused = false;

  int? get _effectiveSelectedEchelon =>
      widget.selectedEchelonNumber ?? _internalSelectedEchelon;

  @override
  void initState() {
    super.initState();
    _isCompact = widget.initiallyCompact;
    _radarLoopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.isEnabled) {
      _radarLoopController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant TvEchelonCrosswindRadarHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEnabled && !_radarLoopController.isAnimating) {
      _radarLoopController.repeat();
    } else if (!widget.isEnabled && _radarLoopController.isAnimating) {
      _radarLoopController.stop();
    }
  }

  @override
  void dispose() {
    _radarLoopController.dispose();
    super.dispose();
  }

  void _handleToggleCompact() {
    if (!widget.isEnabled) return;
    setState(() {
      _isCompact = !_isCompact;
    });
    widget.onToggleCompact?.call();
  }

  void _handleSelectEchelon(EchelonSplitRowData row) {
    if (!widget.isEnabled) return;
    setState(() {
      _internalSelectedEchelon =
          _internalSelectedEchelon == row.echelonNumber ? null : row.echelonNumber;
    });
    widget.onEchelonSelected?.call(row);
  }

  @override
  Widget build(BuildContext context) {
    final EchelonRiskLevel risk = widget.data.riskLevel;
    final Color accentColor = risk.isHighRisk
        ? AppColors.crimsonAlert
        : (risk == EchelonRiskLevel.moderate
            ? AppColors.amberWarning
            : AppColors.cyanAccent);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      opacity: widget.isEnabled ? 1.0 : 0.52,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 460.0;
          final bool isNarrow = maxWidth < 380.0;
          final bool isWide = maxWidth >= 560.0 && !_isCompact;

          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: risk.isHighRisk
                    ? AppColors.crimsonAlert.withValues(alpha: 0.65)
                    : AppColors.cardBorder,
                width: 1.0,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                if (risk.isHighRisk && widget.isEnabled)
                  BoxShadow(
                    color: AppColors.crimsonAlert.withValues(alpha: 0.16),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildHeader(isNarrow: isNarrow, accentColor: accentColor),
                  _buildAlertBanner(risk: risk, isNarrow: isNarrow),
                  Padding(
                    padding: EdgeInsets.all(isNarrow ? 10.0 : 12.0),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(
                                width: 196,
                                child: _buildWindRoseSection(
                                  compassSize: 152,
                                  isNarrow: false,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildEchelonSchematicSection(
                                  isNarrow: false,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              _buildWindRoseSection(
                                compassSize: isNarrow ? 124.0 : 140.0,
                                isNarrow: isNarrow,
                              ),
                              if (!_isCompact) ...<Widget>[
                                const SizedBox(height: 10),
                                _buildEchelonSchematicSection(
                                  isNarrow: isNarrow,
                                ),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader({
    required bool isNarrow,
    required Color accentColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 10.0 : 12.0,
        vertical: 9.0,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: AppColors.cardBorder.withValues(alpha: 0.9),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: widget.isEnabled ? accentColor : AppColors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'CROSSWIND RADAR',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isNarrow ? 10.5 : 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.goldAccent,
                  ),
                ),
                Text(
                  widget.data.sectorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _buildCompactToggleButton(),
        ],
      ),
    );
  }

  Widget _buildCompactToggleButton() {
    final bool enabled = widget.isEnabled;
    final Color bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.35)
        : _headerButtonPressed
            ? AppColors.primaryAccent.withValues(alpha: 0.45)
            : _headerButtonHovered
                ? AppColors.surfaceLight
                : AppColors.surface;
    final Color borderColor = _headerButtonFocused
        ? AppColors.goldAccent
        : (_headerButtonHovered && enabled
            ? AppColors.goldAccent.withValues(alpha: 0.6)
            : AppColors.cardBorder);

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (bool hovered) {
        if (mounted) setState(() => _headerButtonHovered = hovered);
      },
      onShowFocusHighlight: (bool focused) {
        if (mounted) setState(() => _headerButtonFocused = focused);
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent _) {
            _handleToggleCompact();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: enabled
              ? (_) => setState(() => _headerButtonPressed = true)
              : null,
          onTapUp: enabled
              ? (_) => setState(() => _headerButtonPressed = false)
              : null,
          onTapCancel: enabled
              ? () => setState(() => _headerButtonPressed = false)
              : null,
          onTap: enabled ? _handleToggleCompact : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  _isCompact
                      ? Icons.unfold_more_rounded
                      : Icons.unfold_less_rounded,
                  size: 14,
                  color: enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _isCompact ? 'RANTY' : 'ZWIŃ',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertBanner({
    required EchelonRiskLevel risk,
    required bool isNarrow,
  }) {
    final bool isHigh = widget.data.showHighRiskAlert;
    final String bannerText = isHigh
        ? 'CROSSWIND ZONE — ECHELON RISK HIGH'
        : (risk == EchelonRiskLevel.moderate
            ? 'CROSSWIND WATCH — ECHELON RISK MODERATE'
            : 'CROSSWIND MONITOR — PELOTON COMPACT');

    return AnimatedBuilder(
      animation: _radarLoopController,
      builder: (BuildContext context, Widget? child) {
        final double pulse = isHigh && widget.isEnabled
            ? 0.5 + 0.5 * math.sin(_radarLoopController.value * math.pi * 2.0)
            : 0.0;
        final Color baseColor = risk.color;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 10.0 : 12.0,
            vertical: 6.5,
          ),
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: isHigh ? 0.16 + 0.10 * pulse : 0.12),
            border: Border(
              bottom: BorderSide(
                color: baseColor.withValues(alpha: isHigh ? 0.55 : 0.32),
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                isHigh
                    ? Icons.warning_amber_rounded
                    : Icons.air_rounded,
                size: 15,
                color: baseColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  bannerText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isNarrow ? 10.0 : 11.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isHigh ? AppColors.textPrimary : baseColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: baseColor.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: baseColor.withValues(alpha: 0.55),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  risk.shortLabel,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: baseColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWindRoseSection({
    required double compassSize,
    required bool isNarrow,
  }) {
    final TvEchelonCrosswindRadarData d = widget.data;
    final String angleFormatted = '${d.attackAngleDegrees.toStringAsFixed(0)}°';
    final String crosswindFormatted =
        '${d.crosswindSpeedKmh.toStringAsFixed(1)} km/h';
    final String totalWindFormatted =
        '${d.windSpeedKmh.toStringAsFixed(0)} km/h';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AnimatedBuilder(
            animation: _radarLoopController,
            builder: (BuildContext context, Widget? child) {
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  end: d.windDirectionDegrees,
                ),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (BuildContext context, double animatedWindDir, _) {
                  return SizedBox(
                    width: compassSize,
                    height: compassSize,
                    child: CustomPaint(
                      painter: _CrosswindRadarCompassPainter(
                        windDirectionDegrees: animatedWindDir,
                        roadHeadingDegrees: d.roadHeadingDegrees,
                        windSpeedKmh: d.windSpeedKmh,
                        crosswindSpeedKmh: d.crosswindSpeedKmh,
                        riskLevel: d.riskLevel,
                        animationProgress: _radarLoopController.value,
                        isEnabled: widget.isEnabled,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: <Widget>[
              _TelemetryMiniStat(
                label: 'KĄT NATARCIA',
                value: angleFormatted,
                highlightColor: d.riskLevel.color,
              ),
              _TelemetryMiniStat(
                label: 'BOCZNY',
                value: crosswindFormatted,
                highlightColor: AppColors.cyanAccent,
              ),
              _TelemetryMiniStat(
                label: 'WIATR',
                value: totalWindFormatted,
                highlightColor: AppColors.textPrimary,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${d.windSideCode} • SZOSA ${d.roadWidthMeters.toStringAsFixed(1)} m',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isNarrow ? 9.5 : 10.0,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEchelonSchematicSection({required bool isNarrow}) {
    final List<EchelonSplitRowData> rows = widget.data.echelons.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.call_split_rounded,
                size: 14,
                color: AppColors.goldAccent,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'PODZIAŁ PELETONU — RANTY',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                widget.data.isEchelonActive ? 'AKTYWNE' : 'ZWARTY',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: widget.data.isEchelonActive
                      ? AppColors.crimsonAlert
                      : AppColors.statusSuccess,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Brak aktywnego podziału peletonu na ranty.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...rows.map((EchelonSplitRowData row) {
              final bool isSelected =
                  _effectiveSelectedEchelon == row.echelonNumber;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: row == rows.last ? 0.0 : 6.0,
                ),
                child: _EchelonSplitRowCard(
                  row: row,
                  isSelected: isSelected,
                  isEnabled: widget.isEnabled,
                  isNarrow: isNarrow,
                  onTap: () => _handleSelectEchelon(row),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _TelemetryMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color highlightColor;

  const _TelemetryMiniStat({
    required this.label,
    required this.value,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.cardBorder.withValues(alpha: 0.85),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              color: highlightColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _EchelonSplitRowCard extends StatefulWidget {
  final EchelonSplitRowData row;
  final bool isSelected;
  final bool isEnabled;
  final bool isNarrow;
  final VoidCallback onTap;

  const _EchelonSplitRowCard({
    required this.row,
    required this.isSelected,
    required this.isEnabled,
    required this.isNarrow,
    required this.onTap,
  });

  @override
  State<_EchelonSplitRowCard> createState() => _EchelonSplitRowCardState();
}

class _EchelonSplitRowCardState extends State<_EchelonSplitRowCard> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  Color _badgeColorForEchelon(int echelonNumber) {
    switch (echelonNumber) {
      case 1:
        return AppColors.goldAccent;
      case 2:
        return AppColors.amberWarning;
      default:
        return AppColors.crimsonAlert;
    }
  }

  @override
  Widget build(BuildContext context) {
    final EchelonSplitRowData row = widget.row;
    final Color badgeColor = _badgeColorForEchelon(row.echelonNumber);
    final bool enabled = widget.isEnabled;

    final Color backgroundColor = !enabled
        ? AppColors.surface.withValues(alpha: 0.45)
        : _isPressed
            ? AppColors.primaryAccent.withValues(alpha: 0.25)
            : widget.isSelected
                ? AppColors.surfaceLight
                : _isHovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.85)
                    : AppColors.surface;

    final Color borderColor = !enabled
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : _isFocused
            ? AppColors.goldAccent
            : widget.isSelected
                ? AppColors.goldAccent
                : _isHovered
                    ? badgeColor.withValues(alpha: 0.65)
                    : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (bool hovered) {
        if (mounted) setState(() => _isHovered = hovered);
      },
      onShowFocusHighlight: (bool focused) {
        if (mounted) setState(() => _isFocused = focused);
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent _) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown:
              enabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp:
              enabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel:
              enabled ? () => setState(() => _isPressed = false) : null,
          onTap: enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isNarrow ? 8.0 : 10.0,
              vertical: 7.5,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: widget.isSelected || _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.7),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        '#${row.echelonNumber}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                          color: badgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  row.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (row.isGutterFormed) ...<Widget>[
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.crimsonAlert
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'GUTTER',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 8.0,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.crimsonAlert,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${row.riderCount} kol. • oszcz. ${row.averageDraftingSavingsPercent.toStringAsFixed(0)}%'
                            '${row.playerRidersCount > 0 ? ' • EKIPA: ${row.playerRidersCount}' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              fontFeatures: <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Mini wizualizacja diagonalna wachlarza
                    SizedBox(
                      width: 34,
                      height: 18,
                      child: CustomPaint(
                        painter: _EchelonFormationMiniPainter(
                          riderCount: row.riderCount,
                          accentColor: badgeColor,
                          isGutter: row.isGutterFormed,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: row.echelonNumber == 1
                            ? AppColors.goldAccent.withValues(alpha: 0.16)
                            : AppColors.crimsonAlert.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        row.formattedGap,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.0,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                          color: row.echelonNumber == 1
                              ? AppColors.goldAccent
                              : AppColors.crimsonAlert,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.isSelected &&
                    row.notableRiderNames.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'W rancie: ${row.notableRiderNames.join(', ')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rysuje mini-schemat diagonalnej linii wachlarza dla danego rantu.
class _EchelonFormationMiniPainter extends CustomPainter {
  final int riderCount;
  final Color accentColor;
  final bool isGutter;

  const _EchelonFormationMiniPainter({
    required this.riderCount,
    required this.accentColor,
    required this.isGutter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint roadEdgePaint = Paint()
      ..color = isGutter
          ? AppColors.crimsonAlert.withValues(alpha: 0.65)
          : AppColors.cardBorder
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(0, size.height - 2),
      Offset(size.width, size.height - 2),
      roadEdgePaint,
    );

    final int dots = riderCount.clamp(2, 6);
    final Paint dotPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < dots; i++) {
      final double t = dots <= 1 ? 0.5 : i / (dots - 1);
      final double x = 4.0 + t * (size.width - 8.0);
      final double y = 3.0 + t * (size.height - 8.0);
      canvas.drawCircle(Offset(x, y), i == 0 ? 2.2 : 1.7, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EchelonFormationMiniPainter oldDelegate) {
    return oldDelegate.riderCount != riderCount ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isGutter != isGutter;
  }
}

/// Painter animowanej róży wiatrów z kierunkiem szosy, kątem natarcia i strugami wiatru.
class _CrosswindRadarCompassPainter extends CustomPainter {
  final double windDirectionDegrees;
  final double roadHeadingDegrees;
  final double windSpeedKmh;
  final double crosswindSpeedKmh;
  final EchelonRiskLevel riskLevel;
  final double animationProgress;
  final bool isEnabled;

  const _CrosswindRadarCompassPainter({
    required this.windDirectionDegrees,
    required this.roadHeadingDegrees,
    required this.windSpeedKmh,
    required this.crosswindSpeedKmh,
    required this.riskLevel,
    required this.animationProgress,
    required this.isEnabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2.0, size.height / 2.0);
    final double radius = math.min(size.width, size.height) / 2.0 - 6.0;
    if (radius <= 8.0) return;

    // 1. Tło tarczy radaru
    final Paint bgPaint = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Koncentryczne okręgi siatki radarowej
    final Paint gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, gridPaint);
    canvas.drawCircle(center, radius * 0.66, gridPaint);
    canvas.drawCircle(center, radius * 0.33, gridPaint);

    // 2. Pulsująca fala radarowa
    if (isEnabled) {
      final double waveRadius = radius * (0.25 + 0.75 * animationProgress);
      final Paint wavePaint = Paint()
        ..color = riskLevel.color.withValues(
          alpha: (1.0 - animationProgress) * 0.25,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, waveRadius, wavePaint);
    }

    // 3. Podziałka kątowa róży wiatrów co 15°
    for (int deg = 0; deg < 360; deg += 15) {
      final double rad = (deg - 90.0) * math.pi / 180.0;
      final bool isMajor = deg % 90 == 0;
      final bool isMedium = deg % 45 == 0;
      final double tickLen = isMajor ? 7.0 : (isMedium ? 5.0 : 3.0);
      final Paint tickPaint = Paint()
        ..color = isMajor
            ? AppColors.goldAccent.withValues(alpha: 0.85)
            : AppColors.textSecondary.withValues(alpha: 0.45)
        ..strokeWidth = isMajor ? 1.5 : 1.0;
      final Offset p1 = Offset(
        center.dx + (radius - tickLen) * math.cos(rad),
        center.dy + (radius - tickLen) * math.sin(rad),
      );
      final Offset p2 = Offset(
        center.dx + radius * math.cos(rad),
        center.dy + radius * math.sin(rad),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Kierunki świata N / E / S / W
    _drawCardinalLabel(canvas, center, radius - 14.0, -90.0, 'N', true);
    _drawCardinalLabel(canvas, center, radius - 14.0, 0.0, 'E', false);
    _drawCardinalLabel(canvas, center, radius - 14.0, 90.0, 'S', false);
    _drawCardinalLabel(canvas, center, radius - 14.0, 180.0, 'W', false);

    // 4. Oś szosy (wstęga asfaltu przechodząca przez środek radaru)
    final double roadRad = (roadHeadingDegrees - 90.0) * math.pi / 180.0;
    final double windRad = (windDirectionDegrees - 90.0) * math.pi / 180.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(roadRad + math.pi / 2.0);

    const double roadHalfWidth = 9.0;
    final double roadHalfLen = radius * 0.78;
    final Rect roadRect = Rect.fromCenter(
      center: Offset.zero,
      width: roadHalfWidth * 2.0,
      height: roadHalfLen * 2.0,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(roadRect, const Radius.circular(4)),
      Paint()..color = AppColors.surfaceLight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(roadRect, const Radius.circular(4)),
      Paint()
        ..color = AppColors.textSecondary.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Przerywana linia osi jezdni
    final Paint dashPaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.6)
      ..strokeWidth = 1.0;
    for (double y = -roadHalfLen + 6; y < roadHalfLen - 6; y += 9.0) {
      canvas.drawLine(Offset(0, y), Offset(0, y + 4.5), dashPaint);
    }

    // Strzałka kierunku jazdy peletonu (ku górze w lokalnym układzie szosy)
    final Path headingArrow = Path()
      ..moveTo(0, -roadHalfLen - 5)
      ..lineTo(-4.5, -roadHalfLen + 3)
      ..lineTo(4.5, -roadHalfLen + 3)
      ..close();
    canvas.drawPath(
      headingArrow,
      Paint()..color = AppColors.goldAccent,
    );
    canvas.restore();

    // 5. Wycinek kąta natarcia między szosą a wektorem wiatru
    double angleDiff = (windDirectionDegrees - roadHeadingDegrees) % 360.0;
    if (angleDiff > 180.0) angleDiff -= 360.0;
    if (angleDiff < -180.0) angleDiff += 360.0;
    final double sweepRad = angleDiff * math.pi / 180.0;

    final Paint sectorPaint = Paint()
      ..color = riskLevel.color.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.52),
      roadRad,
      sweepRad,
      true,
      sectorPaint,
    );

    // 6. Animowane strugi wiatru napływające z kierunku [windRad] ku środkowi
    final double flowX = -math.cos(windRad);
    final double flowY = -math.sin(windRad);
    final double perpX = -flowY;
    final double perpY = flowX;

    final Paint streamPaint = Paint()
      ..color = riskLevel.color.withValues(alpha: 0.85)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    for (int lane = -1; lane <= 1; lane++) {
      final double laneOffset = lane * 14.0;
      final double phase = (animationProgress + (lane + 1) * 0.25) % 1.0;
      final double startDist = radius * 0.92 - phase * (radius * 1.45);
      const double segLen = 14.0;

      final Offset pStart = Offset(
        center.dx +
            math.cos(windRad) * startDist +
            perpX * laneOffset,
        center.dy +
            math.sin(windRad) * startDist +
            perpY * laneOffset,
      );
      final Offset pEnd = Offset(
        pStart.dx + flowX * segLen,
        pStart.dy + flowY * segLen,
      );

      // Rysujemy strugę tylko wewnątrz koła radaru
      if ((pStart - center).distance <= radius * 0.94 &&
          (pEnd - center).distance <= radius * 0.94) {
        canvas.drawLine(pStart, pEnd, streamPaint);
      }
    }

    // 7. Główny wektor napływu wiatru (wyraźna strzałka na obwodzie)
    final Offset outerWindPoint = Offset(
      center.dx + (radius - 2.0) * math.cos(windRad),
      center.dy + (radius - 2.0) * math.sin(windRad),
    );
    final Offset innerWindPoint = Offset(
      center.dx + (radius * 0.38) * math.cos(windRad),
      center.dy + (radius * 0.38) * math.sin(windRad),
    );
    canvas.drawLine(
      outerWindPoint,
      innerWindPoint,
      Paint()
        ..color = riskLevel.color
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    // Grot strzałki wiatru skierowany do środka
    final double arrowAngle = math.atan2(
      innerWindPoint.dy - outerWindPoint.dy,
      innerWindPoint.dx - outerWindPoint.dx,
    );
    const double headSize = 7.5;
    final Path windArrowHead = Path()
      ..moveTo(innerWindPoint.dx, innerWindPoint.dy)
      ..lineTo(
        innerWindPoint.dx - headSize * math.cos(arrowAngle - 0.45),
        innerWindPoint.dy - headSize * math.sin(arrowAngle - 0.45),
      )
      ..lineTo(
        innerWindPoint.dx - headSize * math.cos(arrowAngle + 0.45),
        innerWindPoint.dy - headSize * math.sin(arrowAngle + 0.45),
      )
      ..close();
    canvas.drawPath(windArrowHead, Paint()..color = riskLevel.color);

    // Punkt centralny peletonu
    canvas.drawCircle(
      center,
      4.0,
      Paint()..color = AppColors.textPrimary,
    );
    canvas.drawCircle(
      center,
      2.2,
      Paint()..color = AppColors.goldAccent,
    );
  }

  void _drawCardinalLabel(
    Canvas canvas,
    Offset center,
    double dist,
    double angleDeg,
    String text,
    bool isNorth,
  ) {
    final double rad = angleDeg * math.pi / 180.0;
    final Offset pos = Offset(
      center.dx + dist * math.cos(rad),
      center.dy + dist * math.sin(rad),
    );
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9.0,
          fontWeight: FontWeight.w800,
          color: isNorth ? AppColors.goldAccent : AppColors.textSecondary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2.0, tp.height / 2.0));
  }

  @override
  bool shouldRepaint(covariant _CrosswindRadarCompassPainter oldDelegate) {
    return oldDelegate.windDirectionDegrees != windDirectionDegrees ||
        oldDelegate.roadHeadingDegrees != roadHeadingDegrees ||
        oldDelegate.windSpeedKmh != windSpeedKmh ||
        oldDelegate.crosswindSpeedKmh != crosswindSpeedKmh ||
        oldDelegate.riskLevel != riskLevel ||
        oldDelegate.animationProgress != animationProgress ||
        oldDelegate.isEnabled != isEnabled;
  }
}
