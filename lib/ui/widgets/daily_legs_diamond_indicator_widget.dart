import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/events/daily_rider_day_form_variance_engine.dart';

/// Model danych prezentacyjnych dla wskaźnika dyspozycji dnia ("The Legs")
/// wyświetlanego na kartach kolarzy w HUD wyścigowym.
class DailyLegsIndicatorData {
  /// Identyfikator kolarza.
  final String riderId;

  /// Nazwa kolarza wyświetlana w szczegółach.
  final String riderName;

  /// Faza odkrywania dyspozycji dnia (`hidden` -> `sensing` -> `revealed`).
  final DayFormDiscoveryPhase discoveryPhase;

  /// Rzeczywista wartość dyspozycji w skali diamentów (`-3..+3`).
  ///
  /// Gdy [discoveryPhase] != [DayFormDiscoveryPhase.revealed], wartość jest ukryta
  /// przed graczem w UI i zastąpiona przez `?` lub wstępną tendencję.
  final int diamondScore;

  /// Wstępny kierunek odczuć w fazie [DayFormDiscoveryPhase.sensing].
  final DayFormSensingTrend? sensingTrend;

  /// Postęp odkrywania dyspozycji podczas rozgrzewki na starcie (`0.0..1.0`).
  final double discoveryProgress;

  /// Aktualny przejechany dystans etapu [km].
  final double currentKm;

  /// Dystans pełnego odkrycia dyspozycji [km] (domyślnie `25.0 km`).
  final double revealThresholdKm;

  /// Opcjonalne bazowe FTP kolarza [W] do wyliczenia delty szczytowych watów.
  final int? baseFtpWatts;

  /// Opcjonalna bazowa pojemność W' [J] do wyliczenia bonusu regeneracji.
  final double? baseWPrimeJoules;

  const DailyLegsIndicatorData({
    required this.riderId,
    required this.riderName,
    required this.discoveryPhase,
    required this.diamondScore,
    this.sensingTrend,
    this.discoveryProgress = 0.0,
    this.currentKm = 0.0,
    this.revealThresholdKm = 25.0,
    this.baseFtpWatts,
    this.baseWPrimeJoules,
  });

  /// Tworzy model prezentacyjny bezpośrednio ze stanu silnika
  /// [RiderDayFormState].
  factory DailyLegsIndicatorData.fromRiderDayFormState(
    RiderDayFormState state, {
    int? baseFtpWatts,
    double? baseWPrimeJoules,
  }) {
    return DailyLegsIndicatorData(
      riderId: state.riderId,
      riderName: state.riderName,
      discoveryPhase: state.discoveryPhase,
      diamondScore: state.actualDiamonds,
      sensingTrend: state.sensingTrend,
      discoveryProgress: state.discoveryProgress,
      currentKm: state.lastObservedKm,
      revealThresholdKm: state.revealThresholdKm,
      baseFtpWatts: baseFtpWatts,
      baseWPrimeJoules: baseWPrimeJoules,
    );
  }

  /// Bezpiecznie ograniczony wynik diamentowy w zakresie `-3..+3`.
  int get clampedDiamondScore =>
      diamondScore.clamp(kMinDayFormDiamonds, kMaxDayFormDiamonds);

  /// Czy dyspozycja dnia została w pełni odkryta po rozgrzewce.
  bool get isRevealed => discoveryPhase == DayFormDiscoveryPhase.revealed;

  /// Czy kolarz jest w fazie wstępnego wyczuwania nóg (`+?` / `-?` / `~0`).
  bool get isSensing => discoveryPhase == DayFormDiscoveryPhase.sensing;

  /// Mnożniki fizjologiczne wynikające z aktualnej dyspozycji.
  DayFormPerformanceModifiers get modifiers =>
      DayFormPerformanceModifiers.fromDiamonds(clampedDiamondScore);

  /// Skorygowane szczytowe FTP [W], jeśli podano [baseFtpWatts].
  int? get adjustedFtpWatts =>
      baseFtpWatts != null ? modifiers.applyToFtp(baseFtpWatts!) : null;

  /// Procentowa zmiana regeneracji W' (`+4.0%` za każdy diament, w zakresie `-12%..+12%`).
  double get wPrimeRecoveryDeltaPercent =>
      (modifiers.recoveryMultiplier - 1.0) * 100.0;

  /// Procentowa zmiana szczytowych watów / FTP (`+1.8%` za każdy diament).
  double get peakWattsDeltaPercent => (modifiers.ftpMultiplier - 1.0) * 100.0;

  /// Procentowa zmiana pojemności beztlenowej W' (`+3.5%` za każdy diament).
  double get wPrimeCapacityDeltaPercent =>
      (modifiers.wPrimeMultiplier - 1.0) * 100.0;

  /// Czy przy negatywnej dyspozycji (`-1 / -2 / -3`) wymagana jest oszczędna jazda na kole.
  bool get requiresDraftingConservation =>
      isRevealed && clampedDiamondScore < 0;

  /// Sformatowana etykieta badge'a (`?`, `+?`, `-?`, `~0`, `+1..+3`, `0`, `-1..-3`).
  String get badgeLabel {
    if (!isRevealed) {
      if (isSensing && sensingTrend != null) {
        switch (sensingTrend!) {
          case DayFormSensingTrend.positive:
            return '+?';
          case DayFormSensingTrend.negative:
            return '-?';
          case DayFormSensingTrend.neutral:
            return '~0';
        }
      }
      return '?';
    }
    return RiderDayFormState.formatDiamondScore(clampedDiamondScore);
  }

  /// Krótki opis taktyczny widoczny na karcie i w tooltipie/szczegółach.
  String get tacticalSummaryPl {
    if (!isRevealed) {
      if (isSensing) {
        return sensingTrend?.labelPl ?? 'Rozgrzewka w toku';
      }
      return 'Rozgrzewka (? przed odkryciem)';
    }
    if (clampedDiamondScore >= 3) {
      return 'Dzień konia! Maks. regeneracja W\' i szczytowe waty';
    }
    if (clampedDiamondScore > 0) {
      return 'Dobra noga: bonus do regeneracji W\' i szczytowych watów';
    }
    if (clampedDiamondScore == 0) {
      return 'Dyspozycja bazowa: parametry nominalne';
    }
    return 'Słabszy dzień: oszczędna jazda na kole';
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'discoveryPhase': discoveryPhase.toJson(),
      'diamondScore': diamondScore,
      'sensingTrend': sensingTrend?.toJson(),
      'discoveryProgress': discoveryProgress,
      'currentKm': currentKm,
      'revealThresholdKm': revealThresholdKm,
      'baseFtpWatts': baseFtpWatts,
      'baseWPrimeJoules': baseWPrimeJoules,
    };
  }

  factory DailyLegsIndicatorData.fromJson(Map<String, dynamic> json) {
    return DailyLegsIndicatorData(
      riderId: json['riderId'] as String? ?? '',
      riderName: json['riderName'] as String? ?? 'Kolarz',
      discoveryPhase: DayFormDiscoveryPhase.fromJson(
        json['discoveryPhase'] as String? ?? 'hidden',
      ),
      diamondScore: (json['diamondScore'] as num?)?.toInt() ?? 0,
      sensingTrend: json['sensingTrend'] != null
          ? DayFormSensingTrend.fromJson(json['sensingTrend'] as String)
          : null,
      discoveryProgress:
          (json['discoveryProgress'] as num?)?.toDouble().clamp(0.0, 1.0) ??
              0.0,
      currentKm: (json['currentKm'] as num?)?.toDouble() ?? 0.0,
      revealThresholdKm:
          (json['revealThresholdKm'] as num?)?.toDouble() ?? 25.0,
      baseFtpWatts: (json['baseFtpWatts'] as num?)?.toInt(),
      baseWPrimeJoules: (json['baseWPrimeJoules'] as num?)?.toDouble(),
    );
  }
}

/// Wskaźnik dyspozycji dnia ("The Legs") dla kart kolarzy w HUD wyścigowym.
///
/// Przechodzi od szarego znaku zapytania `?` na starcie, przez fazę wstępnych
/// odczuć w trakcie rozgrzewki, aż do pełnego odkrycia:
/// - zielonych diamentów `+1 / +2 / +3` (bonus do regeneracji $W'$ i szczytowych watów),
/// - neutralnego `0`,
/// - lub czerwonych diamentów `-1 / -2` (wymagających oszczędnej jazdy na kole).
class DailyLegsDiamondIndicatorWidget extends StatefulWidget {
  /// Dane dyspozycji dnia kolarza.
  final DailyLegsIndicatorData data;

  /// Wymuszony tryb kompaktowy (np. wewnątrz wąskiej karty kolarza w HUD).
  final bool compact;

  /// Czy wskaźnik jest wyłączony (np. kolarz DNF lub wyścig zakończony).
  final bool isDisabled;

  /// Czy szczegóły (rozbicie bonusów W'/FTP i przycisk jazdy na kole) są domyślnie rozwinięte.
  final bool initiallyExpanded;

  /// Callback wywoływany po kliknięciu lub aktywacji klawiaturą wskaźnika.
  final VoidCallback? onTap;

  /// Callback szybkiego rozkazu przejścia do jazdy na kole przy negatywnych diamentach.
  final VoidCallback? onDraftOrderPressed;

  const DailyLegsDiamondIndicatorWidget({
    super.key,
    required this.data,
    this.compact = false,
    this.isDisabled = false,
    this.initiallyExpanded = false,
    this.onTap,
    this.onDraftOrderPressed,
  });

  @override
  State<DailyLegsDiamondIndicatorWidget> createState() =>
      _DailyLegsDiamondIndicatorWidgetState();
}

class _DailyLegsDiamondIndicatorWidgetState
    extends State<DailyLegsDiamondIndicatorWidget> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant DailyLegsDiamondIndicatorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _isExpanded = widget.initiallyExpanded;
    }
  }

  Color _resolveAccentColor() {
    final data = widget.data;
    if (!data.isRevealed) {
      if (data.isSensing && data.sensingTrend != null) {
        switch (data.sensingTrend!) {
          case DayFormSensingTrend.positive:
            return AppColors.statusSuccess.withValues(alpha: 0.78);
          case DayFormSensingTrend.negative:
            return AppColors.crimsonAlert.withValues(alpha: 0.78);
          case DayFormSensingTrend.neutral:
            return AppColors.amberWarning;
        }
      }
      return AppColors.textSecondary;
    }

    final int score = data.clampedDiamondScore;
    if (score > 0) return AppColors.statusSuccess;
    if (score < 0) return AppColors.crimsonAlert;
    return AppColors.textSecondary;
  }

  void _handleActivate() {
    if (widget.isDisabled) return;
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = _resolveAccentColor();
    final bool isInteractive = !widget.isDisabled;
    final double opacity = widget.isDisabled ? 0.45 : 1.0;

    final Color borderColor = _isFocused
        ? AppColors.goldAccent
        : _isHovered && isInteractive
            ? accentColor.withValues(alpha: 0.85)
            : widget.data.isRevealed
                ? accentColor.withValues(alpha: 0.42)
                : AppTheme.borderColor;

    final Color backgroundColor = _isPressed && isInteractive
        ? AppColors.surfaceLight
        : _isHovered && isInteractive
            ? AppColors.surfaceLight.withValues(alpha: 0.92)
            : AppColors.surface;

    return Opacity(
      opacity: opacity,
      child: FocusableActionDetector(
        enabled: isInteractive,
        mouseCursor: isInteractive
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onShowHoverHighlight: (hovered) {
          if (_isHovered != hovered) {
            setState(() => _isHovered = hovered);
          }
        },
        onShowFocusHighlight: (focused) {
          if (_isFocused != focused) {
            setState(() => _isFocused = focused);
          }
        },
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _handleActivate();
              return null;
            },
          ),
        },
        child: Semantics(
          button: isInteractive,
          enabled: isInteractive,
          label:
              'Dyspozycja dnia ${widget.data.riderName}: ${widget.data.badgeLabel}',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isInteractive ? _handleActivate : null,
            onTapDown: isInteractive
                ? (_) => setState(() => _isPressed = true)
                : null,
            onTapUp: isInteractive
                ? (_) => setState(() => _isPressed = false)
                : null,
            onTapCancel: isInteractive
                ? () => setState(() => _isPressed = false)
                : null,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool useCompactLayout =
                    widget.compact || constraints.maxWidth < 250;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: useCompactLayout ? 8 : 12,
                    vertical: useCompactLayout ? 6 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: borderColor,
                      width: _isFocused ? 1.5 : 1.0,
                    ),
                    boxShadow: _isHovered && isInteractive
                        ? [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.14),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderRow(
                        accentColor: accentColor,
                        useCompactLayout: useCompactLayout,
                      ),
                      if (!widget.data.isRevealed) ...[
                        SizedBox(height: useCompactLayout ? 4 : 6),
                        _buildWarmupProgressBar(
                          accentColor: accentColor,
                          useCompactLayout: useCompactLayout,
                        ),
                      ],
                      AnimatedSize(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: _isExpanded
                            ? Padding(
                                padding: EdgeInsets.only(
                                  top: useCompactLayout ? 6 : 8,
                                ),
                                child: _buildExpandedDetails(
                                  accentColor: accentColor,
                                  useCompactLayout: useCompactLayout,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow({
    required Color accentColor,
    required bool useCompactLayout,
  }) {
    return Row(
      children: [
        _buildDiamondVisualOrQuestionMark(
          accentColor: accentColor,
          useCompactLayout: useCompactLayout,
        ),
        SizedBox(width: useCompactLayout ? 6 : 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.data.isRevealed
                          ? 'DYSPOZYCJA DNIA'
                          : 'ROZGRZEWKA / NOGI',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textSecondary,
                        fontSize: useCompactLayout ? 8.5 : 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _buildScorePill(
                    accentColor: accentColor,
                    useCompactLayout: useCompactLayout,
                  ),
                ],
              ),
              SizedBox(height: useCompactLayout ? 2 : 3),
              Text(
                widget.data.tacticalSummaryPl,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: widget.data.requiresDraftingConservation
                      ? AppColors.crimsonAlert
                      : AppColors.textPrimary,
                  fontSize: useCompactLayout ? 10 : 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
                maxLines: useCompactLayout ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        AnimatedRotation(
          turns: _isExpanded ? 0.5 : 0.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: useCompactLayout ? 16 : 18,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDiamondVisualOrQuestionMark({
    required Color accentColor,
    required bool useCompactLayout,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1.0).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: !widget.data.isRevealed
          ? Container(
              key: ValueKey<String>(
                'unknown_${widget.data.discoveryPhase.name}_${widget.data.sensingTrend?.name ?? 'none'}',
              ),
              width: useCompactLayout ? 28 : 34,
              height: useCompactLayout ? 28 : 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.55),
                ),
              ),
              child: Text(
                widget.data.badgeLabel,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: accentColor,
                  fontSize: useCompactLayout ? 13 : 15,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            )
          : _buildRevealedDiamondsCluster(
              key: ValueKey<int>(widget.data.clampedDiamondScore),
              accentColor: accentColor,
              useCompactLayout: useCompactLayout,
            ),
    );
  }

  Widget _buildRevealedDiamondsCluster({
    required Key key,
    required Color accentColor,
    required bool useCompactLayout,
  }) {
    final int score = widget.data.clampedDiamondScore;
    final int diamondCount = score == 0 ? 1 : score.abs().clamp(1, 3);
    final double iconSize = useCompactLayout ? 11.5 : 13.5;

    return Container(
      key: key,
      padding: EdgeInsets.symmetric(
        horizontal: useCompactLayout ? 5 : 7,
        vertical: useCompactLayout ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(diamondCount, (index) {
          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 1.5),
            child: Icon(
              score == 0 ? Icons.remove_rounded : Icons.diamond_rounded,
              size: iconSize,
              color: accentColor,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildScorePill({
    required Color accentColor,
    required bool useCompactLayout,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: useCompactLayout ? 5 : 6,
        vertical: 1.5,
      ),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accentColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        widget.data.badgeLabel,
        style: TextStyle(
          fontFamily: 'Inter',
          color: accentColor,
          fontSize: useCompactLayout ? 9.5 : 10.5,
          fontWeight: FontWeight.w800,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildWarmupProgressBar({
    required Color accentColor,
    required bool useCompactLayout,
  }) {
    final double clampedProgress =
        widget.data.discoveryProgress.clamp(0.0, 1.0);
    final String kmText =
        '${widget.data.currentKm.toStringAsFixed(0)}/${widget.data.revealThresholdKm.toStringAsFixed(0)} km';

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: clampedProgress),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: useCompactLayout ? 4 : 5,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          kmText,
          style: TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textSecondary,
            fontSize: useCompactLayout ? 8.5 : 9.5,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedDetails({
    required Color accentColor,
    required bool useCompactLayout,
  }) {
    final data = widget.data;
    if (!data.isRevealed) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(useCompactLayout ? 7 : 9),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Text(
          'Dyspozycja dnia zostanie w pełni potwierdzona po rozgrzewce na trasie (do ${data.revealThresholdKm.toStringAsFixed(0)} km).',
          style: TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textSecondary,
            fontSize: useCompactLayout ? 9.5 : 11,
            height: 1.35,
          ),
        ),
      );
    }

    final String wPrimeRegenStr = _formatSignedPercent(
      data.wPrimeRecoveryDeltaPercent,
    );
    final String peakWattsStr = _formatSignedPercent(
      data.peakWattsDeltaPercent,
    );
    final String wPrimeCapStr = _formatSignedPercent(
      data.wPrimeCapacityDeltaPercent,
    );
    final int? adjustedFtp = data.adjustedFtpWatts;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(useCompactLayout ? 7 : 9),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildMetricChip(
                label: 'Regeneracja W\'',
                value: wPrimeRegenStr,
                color: accentColor,
                compact: useCompactLayout,
              ),
              _buildMetricChip(
                label: 'Szczytowe waty',
                value: adjustedFtp != null
                    ? '$peakWattsStr ($adjustedFtp W)'
                    : peakWattsStr,
                color: accentColor,
                compact: useCompactLayout,
              ),
              _buildMetricChip(
                label: 'Pojemność W\'',
                value: wPrimeCapStr,
                color: accentColor,
                compact: useCompactLayout,
              ),
            ],
          ),
          if (data.requiresDraftingConservation) ...[
            const SizedBox(height: 8),
            _buildDraftingConservationAction(useCompactLayout),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required String value,
    required Color color,
    required bool compact,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: compact ? 8 : 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              color: color,
              fontSize: compact ? 9.5 : 11,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftingConservationAction(bool compact) {
    final bool canTrigger = !widget.isDisabled && widget.onDraftOrderPressed != null;
    return Row(
      children: [
        Icon(
          Icons.shield_outlined,
          size: compact ? 13 : 15,
          color: AppColors.crimsonAlert,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            'Zalecana oszczędna jazda na kole w peletonie',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.crimsonAlert,
              fontSize: compact ? 9.5 : 10.5,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.onDraftOrderPressed != null) ...[
          const SizedBox(width: 6),
          TextButton(
            onPressed: canTrigger ? widget.onDraftOrderPressed : null,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              backgroundColor: AppColors.primaryAccent.withValues(alpha: 0.85),
              disabledBackgroundColor: AppColors.surfaceLight,
              disabledForegroundColor: AppColors.textSecondary,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 10,
                vertical: compact ? 4 : 6,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: canTrigger
                      ? AppColors.goldAccent.withValues(alpha: 0.6)
                      : AppTheme.borderColor,
                ),
              ),
            ),
            child: Text(
              'Na koło',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: compact ? 9.5 : 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatSignedPercent(double value) {
    if (value.abs() < 0.05) return '0.0%';
    final String sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(1)}%';
  }
}
