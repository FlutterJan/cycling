import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// Typ punktu pomiarowego w jeździe indywidualnej lub drużynowej na czas (ITT/TTT).
enum IttSplitCheckpointType {
  /// 1. punkt pomiarowy (T1).
  split1,

  /// 2. punkt pomiarowy (T2).
  split2,

  /// 3. punkt pomiarowy (T3).
  split3,

  /// Linia mety (Finish).
  finish;

  /// Krótka etykieta wyświetlana na pigułkach punktów pomiarowych.
  String get shortLabel {
    switch (this) {
      case IttSplitCheckpointType.split1:
        return 'T1';
      case IttSplitCheckpointType.split2:
        return 'T2';
      case IttSplitCheckpointType.split3:
        return 'T3';
      case IttSplitCheckpointType.finish:
        return 'META';
    }
  }

  /// Pełny opis punktu pomiarowego w nagłówku porównania fotokomórki.
  String get fullLabel {
    switch (this) {
      case IttSplitCheckpointType.split1:
        return '1. PUNKT POMIAROWY';
      case IttSplitCheckpointType.split2:
        return '2. PUNKT POMIAROWY';
      case IttSplitCheckpointType.split3:
        return '3. PUNKT POMIAROWY';
      case IttSplitCheckpointType.finish:
        return 'LINIA METY';
    }
  }
}

/// Stan fotokomórki dla konkretnego punktu pomiarowego.
enum IttPhotocellStatus {
  /// Kolarz zbliża się do punktu pomiarowego; trwa odliczanie setnych części sekundy do lidera.
  upcoming,

  /// Kolarz przekroczył już czas lidera przed dotarciem do fotokomórki (bieżąca strata rośnie).
  overtimeApproaching,

  /// Kolarz przeciął fotokomórkę z lepszym lub równym czasem względem lidera (`-X.XX s`, zielone tło).
  crossedAhead,

  /// Kolarz przeciął fotokomórkę ze stratą względem lidera (`+X.XX s`, czerwone tło).
  crossedBehind,

  /// Pierwszy kolarz na punkcie pomiarowym — brak czasu odniesienia (ustanawia czas bazowy P1).
  firstReference,
}

/// Dane pojedynczego punktu pomiarowego (T1, T2, T3 lub Meta) dla HUD czasówki.
@immutable
class IttSplitCheckpointData {
  final IttSplitCheckpointType checkpoint;
  final String? customLabel;
  final double distanceKm;

  /// Najlepszy dotychczasowy czas na tym punkcie pomiarowym w sekundach (`null`, gdy nikt jeszcze nie przejechał).
  final double? bestTimeSeconds;
  final String? bestRiderName;
  final String? bestRiderTeamCode;

  /// Czas kolarza po przecięciu fotokomórki w sekundach (`null`, dopóki kolarz nie minął punktu).
  final double? riderSplitTimeSeconds;

  /// Tymczasowa pozycja kolarza na tym punkcie pomiarowym (1 = najlepszy czas).
  final int? rankAtCheckpoint;

  const IttSplitCheckpointData({
    required this.checkpoint,
    this.customLabel,
    required this.distanceKm,
    this.bestTimeSeconds,
    this.bestRiderName,
    this.bestRiderTeamCode,
    this.riderSplitTimeSeconds,
    this.rankAtCheckpoint,
  });

  /// Etykieta punktu pomiarowego (własna lub domyślna `T1`/`T2`/`T3`/`META`).
  String get displayLabel {
    final String? trimmed = customLabel?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed.toUpperCase();
    }
    return checkpoint.shortLabel;
  }

  /// Czy kolarz przeciął już fotokomórkę tego punktu pomiarowego.
  bool get isCrossed =>
      riderSplitTimeSeconds != null &&
      !riderSplitTimeSeconds!.isNaN &&
      !riderSplitTimeSeconds!.isInfinite;

  /// Czy istnieje czas odniesienia (lidera) do porównania.
  bool get hasBenchmark =>
      bestTimeSeconds != null &&
      !bestTimeSeconds!.isNaN &&
      !bestTimeSeconds!.isInfinite &&
      bestTimeSeconds! > 0.0;

  /// Różnica czasu po przecięciu fotokomórki (`< 0` oznacza przewagę, `> 0` stratę).
  double? get deltaSeconds {
    if (!isCrossed || !hasBenchmark) return null;
    return riderSplitTimeSeconds! - bestTimeSeconds!;
  }

  /// Pozostały czas do najlepszego wyniku na tym punkcie (w sekundach).
  /// Wartość dodatnia = ile sekund zostało do czasu lidera; ujemna = czas lidera już minął.
  double? remainingToBestSeconds(double currentElapsedSeconds) {
    if (!hasBenchmark ||
        currentElapsedSeconds.isNaN ||
        currentElapsedSeconds.isInfinite) {
      return null;
    }
    return bestTimeSeconds! - math.max(0.0, currentElapsedSeconds);
  }

  /// Wyznacza bieżący stan fotokomórki na podstawie czasu stopera.
  IttPhotocellStatus resolveStatus(double currentElapsedSeconds) {
    if (isCrossed) {
      if (!hasBenchmark) {
        return IttPhotocellStatus.firstReference;
      }
      final double delta = deltaSeconds ?? 0.0;
      return delta <= 0.0
          ? IttPhotocellStatus.crossedAhead
          : IttPhotocellStatus.crossedBehind;
    }

    if (!hasBenchmark) {
      return IttPhotocellStatus.firstReference;
    }

    final double? remaining = remainingToBestSeconds(currentElapsedSeconds);
    if (remaining != null && remaining < 0.0) {
      return IttPhotocellStatus.overtimeApproaching;
    }
    return IttPhotocellStatus.upcoming;
  }
}

/// Pełny model telemetryczny dla telewizyjnego zegara czasówki [TvIttSplitTimerComparisonHud].
@immutable
class TvIttSplitTimerData {
  final String riderId;
  final String riderName;
  final String teamShortCode;
  final String nationalityIso;
  final int bibNumber;
  final bool isPlayerTeam;
  final bool isProvisionalLeader;
  final double currentElapsedSeconds;
  final double riderDistanceKm;
  final double totalStageDistanceKm;
  final double currentSpeedKmh;
  final double? currentPowerWatts;
  final List<IttSplitCheckpointData> checkpoints;

  const TvIttSplitTimerData({
    required this.riderId,
    required this.riderName,
    required this.teamShortCode,
    this.nationalityIso = 'INT',
    this.bibNumber = 1,
    this.isPlayerTeam = false,
    this.isProvisionalLeader = false,
    required this.currentElapsedSeconds,
    required this.riderDistanceKm,
    required this.totalStageDistanceKm,
    required this.currentSpeedKmh,
    this.currentPowerWatts,
    required this.checkpoints,
  });

  /// Bezpieczny dystans całkowity etapu.
  double get safeTotalDistanceKm =>
      (totalStageDistanceKm.isNaN ||
              totalStageDistanceKm.isInfinite ||
              totalStageDistanceKm <= 0.0)
          ? 1.0
          : totalStageDistanceKm;

  /// Postęp etapu w zakresie `0.0..1.0`.
  double get stageProgress {
    if (riderDistanceKm.isNaN || riderDistanceKm.isInfinite) return 0.0;
    return (riderDistanceKm / safeTotalDistanceKm).clamp(0.0, 1.0);
  }

  /// Wybiera domyślny punkt pomiarowy do wyświetlenia:
  /// 1. Najświeżej przecięty punkt, jeśli wszystkie lub ostatni właśnie przekroczono,
  ///    albo następny nadchodzący punkt pomiarowy.
  IttSplitCheckpointData? get defaultFocusCheckpoint {
    if (checkpoints.isEmpty) return null;
    for (final IttSplitCheckpointData cp in checkpoints) {
      if (!cp.isCrossed) {
        return cp;
      }
    }
    return checkpoints.last;
  }
}

/// Profesjonalny zegar pomiarowy dla jazdy na czas (ITT/TTT) w estetyce transmisji TV.
///
/// Prezentuje:
/// - stoper kolarza z dokładnością do setnych części sekundy (`MM:SS.CC`),
/// - odliczanie setnych części sekundy do najlepszego czasu na 1., 2. i 3. punkcie pomiarowym,
/// - zielone (`-X.XX s`) lub czerwone (`+X.XX s`) tło po przecięciu fotokomórki.
class TvIttSplitTimerComparisonHud extends StatefulWidget {
  final TvIttSplitTimerData data;
  final bool isEnabled;
  final bool initiallyExpanded;
  final IttSplitCheckpointType? selectedCheckpoint;
  final ValueChanged<IttSplitCheckpointType>? onCheckpointSelected;
  final VoidCallback? onRiderTap;
  final ValueChanged<bool>? onToggleExpanded;

  const TvIttSplitTimerComparisonHud({
    super.key,
    required this.data,
    this.isEnabled = true,
    this.initiallyExpanded = true,
    this.selectedCheckpoint,
    this.onCheckpointSelected,
    this.onRiderTap,
    this.onToggleExpanded,
  });

  /// Formatuje czas w sekundach do postaci `MM:SS.CC` (lub `H:MM:SS.CC` dla prób >= 1h).
  static String formatStopwatchHundredths(double rawSeconds) {
    final double safe = (rawSeconds.isNaN || rawSeconds.isInfinite)
        ? 0.0
        : math.max(0.0, rawSeconds);
    final int totalHundredths = (safe * 100.0).round();
    final int hundredths = totalHundredths % 100;
    final int totalSeconds = totalHundredths ~/ 100;
    final int seconds = totalSeconds % 60;
    final int totalMinutes = totalSeconds ~/ 60;
    final int minutes = totalMinutes % 60;
    final int hours = totalMinutes ~/ 60;

    final String secStr = seconds.toString().padLeft(2, '0');
    final String hunStr = hundredths.toString().padLeft(2, '0');
    if (hours > 0) {
      final String minStr = minutes.toString().padLeft(2, '0');
      return '$hours:$minStr:$secStr.$hunStr';
    }
    final String minStr = totalMinutes.toString().padLeft(2, '0');
    return '$minStr:$secStr.$hunStr';
  }

  /// Formatuje różnicę czasu po przecięciu fotokomórki w postaci `-X.XX s` lub `+X.XX s`.
  static String formatSplitDelta(double rawDeltaSeconds) {
    if (rawDeltaSeconds.isNaN || rawDeltaSeconds.isInfinite) {
      return '0.00 s';
    }
    final int roundedHundredths = (rawDeltaSeconds * 100.0).round();
    if (roundedHundredths == 0) {
      return '-0.00 s';
    }
    final String sign = roundedHundredths < 0 ? '-' : '+';
    final double absSeconds = roundedHundredths.abs() / 100.0;
    if (absSeconds >= 60.0) {
      final int mins = absSeconds ~/ 60;
      final double remSec = absSeconds - (mins * 60);
      return '$sign$mins\'${remSec.toStringAsFixed(2).padLeft(5, '0')}"';
    }
    return '$sign${absSeconds.toStringAsFixed(2)} s';
  }

  /// Formatuje odliczanie setnych części sekundy do najlepszego czasu na punkcie pomiarowym.
  /// Gdy [remainingSeconds] >= 0: zwraca `MM:SS.CC` (czas pozostały do pobicia rekordu).
  /// Gdy [remainingSeconds] < 0: zwraca `+X.XX s` (strata narastająca przed fotokomórką).
  static String formatCountdownToBest(double remainingSeconds) {
    if (remainingSeconds.isNaN || remainingSeconds.isInfinite) {
      return '00:00.00';
    }
    if (remainingSeconds < 0.0) {
      return formatSplitDelta(-remainingSeconds);
    }
    return formatStopwatchHundredths(remainingSeconds);
  }

  @override
  State<TvIttSplitTimerComparisonHud> createState() =>
      _TvIttSplitTimerComparisonHudState();
}

class _TvIttSplitTimerComparisonHudState
    extends State<TvIttSplitTimerComparisonHud>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  IttSplitCheckpointType? _internalSelectedCheckpoint;
  bool _isHeaderHovered = false;
  bool _isHeaderPressed = false;
  bool _isHeaderFocused = false;
  bool _isExpandHovered = false;
  bool _isExpandFocused = false;

  late final AnimationController _photocellFlashController;
  late final Animation<double> _photocellFlashAnimation;
  IttPhotocellStatus? _lastObservedStatus;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _internalSelectedCheckpoint = widget.selectedCheckpoint;
    _photocellFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _photocellFlashAnimation = CurvedAnimation(
      parent: _photocellFlashController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant TvIttSplitTimerComparisonHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCheckpoint != oldWidget.selectedCheckpoint &&
        widget.selectedCheckpoint != null) {
      _internalSelectedCheckpoint = widget.selectedCheckpoint;
    }

    final IttSplitCheckpointData? active = _resolveActiveCheckpoint();
    if (active != null) {
      final IttPhotocellStatus currentStatus =
          active.resolveStatus(widget.data.currentElapsedSeconds);
      final bool justCrossed =
          (_lastObservedStatus == IttPhotocellStatus.upcoming ||
              _lastObservedStatus == IttPhotocellStatus.overtimeApproaching) &&
          (currentStatus == IttPhotocellStatus.crossedAhead ||
              currentStatus == IttPhotocellStatus.crossedBehind ||
              currentStatus == IttPhotocellStatus.firstReference);
      if (justCrossed) {
        _photocellFlashController.forward(from: 0.0);
      }
      _lastObservedStatus = currentStatus;
    }
  }

  @override
  void dispose() {
    _photocellFlashController.dispose();
    super.dispose();
  }

  IttSplitCheckpointData? _resolveActiveCheckpoint() {
    final List<IttSplitCheckpointData> cps = widget.data.checkpoints;
    if (cps.isEmpty) return null;

    final IttSplitCheckpointType? targetType =
        widget.selectedCheckpoint ?? _internalSelectedCheckpoint;
    if (targetType != null) {
      for (final IttSplitCheckpointData cp in cps) {
        if (cp.checkpoint == targetType) {
          return cp;
        }
      }
    }
    return widget.data.defaultFocusCheckpoint;
  }

  void _selectCheckpoint(IttSplitCheckpointType type) {
    if (!widget.isEnabled) return;
    setState(() {
      _internalSelectedCheckpoint = type;
    });
    widget.onCheckpointSelected?.call(type);
  }

  void _toggleExpanded() {
    if (!widget.isEnabled) return;
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onToggleExpanded?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 640.0;
        final bool isMobile = maxWidth < 520.0;
        final bool isDesktopWide = maxWidth >= 820.0;

        final IttSplitCheckpointData? activeCheckpoint =
            _resolveActiveCheckpoint();
        final IttPhotocellStatus activeStatus = activeCheckpoint != null
            ? activeCheckpoint.resolveStatus(widget.data.currentElapsedSeconds)
            : IttPhotocellStatus.firstReference;

        final Color containerBorderColor = _resolveOuterBorderColor(activeStatus);

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          opacity: widget.isEnabled ? 1.0 : 0.55,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: containerBorderColor,
                width: _isHeaderFocused ? 1.5 : 1.0,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildHeaderBar(isMobile: isMobile),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: _isExpanded
                        ? Padding(
                            padding: EdgeInsets.fromLTRB(
                              isMobile ? 12 : 16,
                              isMobile ? 10 : 12,
                              isMobile ? 12 : 16,
                              isMobile ? 12 : 14,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                if (isMobile)
                                  _buildMobileBody(
                                    activeCheckpoint: activeCheckpoint,
                                    activeStatus: activeStatus,
                                  )
                                else
                                  _buildWideBody(
                                    isDesktopWide: isDesktopWide,
                                    activeCheckpoint: activeCheckpoint,
                                    activeStatus: activeStatus,
                                  ),
                                const SizedBox(height: 10),
                                _buildCheckpointsStrip(
                                  isMobile: isMobile,
                                  activeCheckpoint: activeCheckpoint,
                                ),
                              ],
                            ),
                          )
                        : _buildCollapsedSummaryStrip(
                            activeCheckpoint: activeCheckpoint,
                            activeStatus: activeStatus,
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

  Color _resolveOuterBorderColor(IttPhotocellStatus status) {
    if (_isHeaderFocused) return AppColors.goldAccent;
    switch (status) {
      case IttPhotocellStatus.crossedAhead:
        return AppColors.statusSuccess.withValues(alpha: 0.75);
      case IttPhotocellStatus.crossedBehind:
        return AppColors.crimsonAlert.withValues(alpha: 0.75);
      case IttPhotocellStatus.overtimeApproaching:
        return AppColors.amberWarning.withValues(alpha: 0.6);
      case IttPhotocellStatus.firstReference:
        return AppColors.goldAccent.withValues(alpha: 0.55);
      case IttPhotocellStatus.upcoming:
        return AppColors.cardBorder;
    }
  }

  Widget _buildHeaderBar({required bool isMobile}) {
    final TvIttSplitTimerData d = widget.data;
    final Color headerBg = _isHeaderPressed
        ? AppColors.surfaceLight
        : (_isHeaderHovered
            ? AppColors.surfaceLight.withValues(alpha: 0.85)
            : AppColors.background.withValues(alpha: 0.92));

    return Focus(
      canRequestFocus: widget.isEnabled && widget.onRiderTap != null,
      onFocusChange: (bool focused) {
        setState(() => _isHeaderFocused = focused);
      },
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (!widget.isEnabled || widget.onRiderTap == null) {
          return KeyEventResult.ignored;
        }
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onRiderTap?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: widget.isEnabled && widget.onRiderTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) {
          if (widget.isEnabled) setState(() => _isHeaderHovered = true);
        },
        onExit: (_) {
          if (widget.isEnabled) {
            setState(() {
              _isHeaderHovered = false;
              _isHeaderPressed = false;
            });
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            if (widget.isEnabled && widget.onRiderTap != null) {
              setState(() => _isHeaderPressed = true);
            }
          },
          onTapUp: (_) {
            if (widget.isEnabled) setState(() => _isHeaderPressed = false);
          },
          onTapCancel: () {
            if (widget.isEnabled) setState(() => _isHeaderPressed = false);
          },
          onTap: widget.isEnabled ? widget.onRiderTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: headerBg,
              border: const Border(
                bottom: BorderSide(color: AppColors.cardBorder, width: 1.0),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.primaryAccent.withValues(alpha: 0.7),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.goldAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'ITT CHRONO',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: isMobile ? 10 : 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: AppColors.goldAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    '#${d.bibNumber}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      fontFeatures: <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          d.riderName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: isMobile ? 12.5 : 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: d.isPlayerTeam
                                ? AppColors.goldAccent
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        d.teamShortCode.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isMobile) ...<Widget>[
                  _buildHeaderMetricChip(
                    label: '${d.currentSpeedKmh.toStringAsFixed(1)} km/h',
                    color: AppColors.accentBlue,
                  ),
                  if (d.currentPowerWatts != null) ...<Widget>[
                    const SizedBox(width: 6),
                    _buildHeaderMetricChip(
                      label: '${d.currentPowerWatts!.round()} W',
                      color: AppColors.goldAccent,
                    ),
                  ],
                  const SizedBox(width: 8),
                ],
                _buildExpandToggleButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderMetricChip({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildExpandToggleButton() {
    return Focus(
      canRequestFocus: widget.isEnabled,
      onFocusChange: (bool focused) {
        setState(() => _isExpandFocused = focused);
      },
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (!widget.isEnabled) return KeyEventResult.ignored;
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          _toggleExpanded();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: widget.isEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) {
          if (widget.isEnabled) setState(() => _isExpandHovered = true);
        },
        onExit: (_) {
          if (widget.isEnabled) setState(() => _isExpandHovered = false);
        },
        child: Tooltip(
          message: _isExpanded ? 'Zwiń zegar czasówki' : 'Rozwiń zegar czasówki',
          child: GestureDetector(
            onTap: widget.isEnabled ? _toggleExpanded : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _isExpandHovered
                    ? AppColors.surfaceLight
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isExpandFocused
                      ? AppColors.goldAccent
                      : AppColors.cardBorder,
                ),
              ),
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                turns: _isExpanded ? 0.0 : 0.5,
                child: const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedSummaryStrip({
    required IttSplitCheckpointData? activeCheckpoint,
    required IttPhotocellStatus activeStatus,
  }) {
    final String stopwatch = TvIttSplitTimerComparisonHud.formatStopwatchHundredths(
      widget.data.currentElapsedSeconds,
    );
    final String statusText = _resolveCollapsedDeltaText(
      activeCheckpoint: activeCheckpoint,
      activeStatus: activeStatus,
    );
    final Color statusBg = _resolvePhotocellBackgroundColor(activeStatus);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: <Widget>[
          Text(
            stopwatch,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const Spacer(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _resolvePhotocellBorderColor(activeStatus),
              ),
            ),
            child: Text(
              statusText,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _resolveCollapsedDeltaText({
    required IttSplitCheckpointData? activeCheckpoint,
    required IttPhotocellStatus activeStatus,
  }) {
    if (activeCheckpoint == null) return 'BRAK PUNKTÓW';
    final String tag = activeCheckpoint.displayLabel;
    if (activeCheckpoint.isCrossed) {
      if (activeStatus == IttPhotocellStatus.firstReference) {
        return '$tag • P1 BAZA';
      }
      final double delta = activeCheckpoint.deltaSeconds ?? 0.0;
      return '$tag ${TvIttSplitTimerComparisonHud.formatSplitDelta(delta)}';
    }
    final double? rem =
        activeCheckpoint.remainingToBestSeconds(widget.data.currentElapsedSeconds);
    if (rem == null) return '$tag • BAZA';
    return '$tag ${TvIttSplitTimerComparisonHud.formatCountdownToBest(rem)}';
  }

  Widget _buildMobileBody({
    required IttSplitCheckpointData? activeCheckpoint,
    required IttPhotocellStatus activeStatus,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildStopwatchCard(isMobile: true),
        const SizedBox(height: 10),
        _buildPhotocellComparisonCard(
          isMobile: true,
          activeCheckpoint: activeCheckpoint,
          activeStatus: activeStatus,
        ),
      ],
    );
  }

  Widget _buildWideBody({
    required bool isDesktopWide,
    required IttSplitCheckpointData? activeCheckpoint,
    required IttPhotocellStatus activeStatus,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            flex: isDesktopWide ? 4 : 5,
            child: _buildStopwatchCard(isMobile: false),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: isDesktopWide ? 6 : 7,
            child: _buildPhotocellComparisonCard(
              isMobile: false,
              activeCheckpoint: activeCheckpoint,
              activeStatus: activeStatus,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopwatchCard({required bool isMobile}) {
    final TvIttSplitTimerData d = widget.data;
    final String formattedTime =
        TvIttSplitTimerComparisonHud.formatStopwatchHundredths(
      d.currentElapsedSeconds,
    );
    final double safeDist =
        d.riderDistanceKm.isNaN || d.riderDistanceKm.isInfinite
            ? 0.0
            : math.max(0.0, d.riderDistanceKm);

    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.timer_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              const Expanded(
                child: Text(
                  'CZAS PRZEJAZDU',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '${safeDist.toStringAsFixed(1)} / ${d.safeTotalDistanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formattedTime,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: isMobile ? 28 : 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                height: 1.05,
                color: AppColors.textPrimary,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: d.stageProgress,
              minHeight: 5,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                d.isProvisionalLeader
                    ? AppColors.goldAccent
                    : AppColors.accentBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotocellComparisonCard({
    required bool isMobile,
    required IttSplitCheckpointData? activeCheckpoint,
    required IttPhotocellStatus activeStatus,
  }) {
    if (activeCheckpoint == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Center(
          child: Text(
            'Brak zdefiniowanych punktów pomiarowych na trasie.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final Color bgColor = _resolvePhotocellBackgroundColor(activeStatus);
    final Color borderColor = _resolvePhotocellBorderColor(activeStatus);
    final bool isCrossed = activeCheckpoint.isCrossed;

    final String headerTitle = isCrossed
        ? 'FOTOKOMÓRKA • ${activeCheckpoint.checkpoint.fullLabel}'
        : 'ODLICZANIE DO LIDERA • ${activeCheckpoint.checkpoint.fullLabel}';

    final String mainValueText;
    final String subCaptionText;
    final Color mainTextColor;

    if (isCrossed) {
      if (activeStatus == IttPhotocellStatus.firstReference) {
        mainValueText =
            TvIttSplitTimerComparisonHud.formatStopwatchHundredths(
          activeCheckpoint.riderSplitTimeSeconds ?? 0.0,
        );
        subCaptionText = 'NOWY CZAS BAZOWY (P1)';
        mainTextColor = AppColors.goldAccent;
      } else {
        final double delta = activeCheckpoint.deltaSeconds ?? 0.0;
        mainValueText = TvIttSplitTimerComparisonHud.formatSplitDelta(delta);
        final int? rank = activeCheckpoint.rankAtCheckpoint;
        final String rankStr = rank != null ? 'P$rank • ' : '';
        subCaptionText =
            '${rankStr}CZAS: ${TvIttSplitTimerComparisonHud.formatStopwatchHundredths(activeCheckpoint.riderSplitTimeSeconds ?? 0.0)}';
        mainTextColor = Colors.white;
      }
    } else {
      final double? remaining = activeCheckpoint.remainingToBestSeconds(
        widget.data.currentElapsedSeconds,
      );
      if (remaining == null) {
        mainValueText = 'PIERWSZY NA TRASIE';
        subCaptionText =
            'PUNKT ${activeCheckpoint.displayLabel} NA ${activeCheckpoint.distanceKm.toStringAsFixed(1)} km';
        mainTextColor = AppColors.goldAccent;
      } else if (remaining >= 0.0) {
        mainValueText =
            TvIttSplitTimerComparisonHud.formatCountdownToBest(remaining);
        final String leaderTag = activeCheckpoint.bestRiderName != null
            ? '${activeCheckpoint.bestRiderName} (${TvIttSplitTimerComparisonHud.formatStopwatchHundredths(activeCheckpoint.bestTimeSeconds!)})'
            : TvIttSplitTimerComparisonHud.formatStopwatchHundredths(
                activeCheckpoint.bestTimeSeconds!,
              );
        subCaptionText = 'DO POBICIA: $leaderTag';
        mainTextColor = remaining <= 5.0
            ? AppColors.goldAccent
            : AppColors.cyanAccent;
      } else {
        mainValueText =
            TvIttSplitTimerComparisonHud.formatCountdownToBest(remaining);
        final double distLeft = math.max(
          0.0,
          activeCheckpoint.distanceKm - widget.data.riderDistanceKm,
        );
        subCaptionText =
            'STRATA PRZED FOTOKOMÓRKĄ • POZOSTAŁO ${distLeft.toStringAsFixed(2)} km';
        mainTextColor = AppColors.amberWarning;
      }
    }

    return AnimatedBuilder(
      animation: _photocellFlashAnimation,
      builder: (BuildContext context, Widget? child) {
        final double flashAlpha =
            (1.0 - _photocellFlashAnimation.value) * 0.35;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(isMobile ? 10 : 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: isCrossed
                ? <BoxShadow>[
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.25 + flashAlpha),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                isCrossed
                    ? (activeStatus == IttPhotocellStatus.crossedAhead
                        ? Icons.check_circle_rounded
                        : (activeStatus == IttPhotocellStatus.crossedBehind
                            ? Icons.warning_amber_rounded
                            : Icons.flag_rounded))
                    : Icons.sensors_rounded,
                size: 14,
                color: isCrossed ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  headerTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: isCrossed
                        ? Colors.white.withValues(alpha: 0.92)
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '${activeCheckpoint.distanceKm.toStringAsFixed(1)} km',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isCrossed
                      ? Colors.white.withValues(alpha: 0.9)
                      : AppColors.textSecondary,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              mainValueText,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: isMobile ? 26 : 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                height: 1.05,
                color: mainTextColor,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subCaptionText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isCrossed
                  ? Colors.white.withValues(alpha: 0.92)
                  : AppColors.textSecondary,
              fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _resolvePhotocellBackgroundColor(IttPhotocellStatus status) {
    switch (status) {
      case IttPhotocellStatus.crossedAhead:
        return AppColors.statusSuccess.withValues(alpha: 0.88);
      case IttPhotocellStatus.crossedBehind:
        return AppColors.crimsonAlert.withValues(alpha: 0.88);
      case IttPhotocellStatus.overtimeApproaching:
        return AppColors.crimsonAlert.withValues(alpha: 0.16);
      case IttPhotocellStatus.firstReference:
        return AppColors.goldAccent.withValues(alpha: 0.14);
      case IttPhotocellStatus.upcoming:
        return AppColors.surfaceLight;
    }
  }

  Color _resolvePhotocellBorderColor(IttPhotocellStatus status) {
    switch (status) {
      case IttPhotocellStatus.crossedAhead:
        return AppColors.statusSuccess;
      case IttPhotocellStatus.crossedBehind:
        return AppColors.crimsonAlert;
      case IttPhotocellStatus.overtimeApproaching:
        return AppColors.amberWarning;
      case IttPhotocellStatus.firstReference:
        return AppColors.goldAccent;
      case IttPhotocellStatus.upcoming:
        return AppColors.cardBorder;
    }
  }

  Widget _buildCheckpointsStrip({
    required bool isMobile,
    required IttSplitCheckpointData? activeCheckpoint,
  }) {
    final List<IttSplitCheckpointData> cps = widget.data.checkpoints;
    if (cps.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints stripConstraints) {
        final double spacing = isMobile ? 6.0 : 8.0;
        final int count = cps.length;
        final double itemWidth = math.max(
          82.0,
          (stripConstraints.maxWidth - (spacing * (count - 1))) / count,
        );

        final bool needsHorizontalScroll =
            (itemWidth * count) + (spacing * (count - 1)) >
                stripConstraints.maxWidth + 0.5;

        final List<Widget> tiles = <Widget>[
          for (int i = 0; i < count; i++) ...<Widget>[
            SizedBox(
              width: needsHorizontalScroll ? 104.0 : itemWidth,
              child: _CheckpointSplitTile(
                checkpoint: cps[i],
                currentElapsedSeconds: widget.data.currentElapsedSeconds,
                isSelected: activeCheckpoint?.checkpoint == cps[i].checkpoint,
                isEnabled: widget.isEnabled,
                onTap: () => _selectCheckpoint(cps[i].checkpoint),
              ),
            ),
            if (i < count - 1) SizedBox(width: spacing),
          ],
        ];

        if (needsHorizontalScroll) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: tiles),
          );
        }
        return Row(children: tiles);
      },
    );
  }
}

class _CheckpointSplitTile extends StatefulWidget {
  final IttSplitCheckpointData checkpoint;
  final double currentElapsedSeconds;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _CheckpointSplitTile({
    required this.checkpoint,
    required this.currentElapsedSeconds,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  State<_CheckpointSplitTile> createState() => _CheckpointSplitTileState();
}

class _CheckpointSplitTileState extends State<_CheckpointSplitTile> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final IttPhotocellStatus status =
        widget.checkpoint.resolveStatus(widget.currentElapsedSeconds);
    final bool isCrossed = widget.checkpoint.isCrossed;

    Color tileBg;
    Color tileBorder;
    Color valueColor;

    if (status == IttPhotocellStatus.crossedAhead) {
      tileBg = AppColors.statusSuccess.withValues(
        alpha: _isPressed ? 0.95 : (_isHovered ? 0.9 : 0.78),
      );
      tileBorder = widget.isSelected || _isFocused
          ? Colors.white
          : AppColors.statusSuccess;
      valueColor = Colors.white;
    } else if (status == IttPhotocellStatus.crossedBehind) {
      tileBg = AppColors.crimsonAlert.withValues(
        alpha: _isPressed ? 0.95 : (_isHovered ? 0.9 : 0.78),
      );
      tileBorder = widget.isSelected || _isFocused
          ? Colors.white
          : AppColors.crimsonAlert;
      valueColor = Colors.white;
    } else if (widget.isSelected) {
      tileBg = _isPressed
          ? AppColors.surfaceLight
          : AppColors.primaryAccent.withValues(alpha: 0.24);
      tileBorder = _isFocused ? AppColors.goldAccent : AppColors.primaryAccent;
      valueColor = AppColors.textPrimary;
    } else {
      tileBg = _isPressed
          ? AppColors.surfaceLight
          : (_isHovered
              ? AppColors.surfaceLight.withValues(alpha: 0.85)
              : AppColors.background.withValues(alpha: 0.85));
      tileBorder = _isFocused ? AppColors.goldAccent : AppColors.cardBorder;
      valueColor = status == IttPhotocellStatus.overtimeApproaching
          ? AppColors.amberWarning
          : AppColors.cyanAccent;
    }

    final String valueLabel;
    if (isCrossed) {
      if (status == IttPhotocellStatus.firstReference) {
        valueLabel = 'P1 BAZA';
      } else {
        valueLabel = TvIttSplitTimerComparisonHud.formatSplitDelta(
          widget.checkpoint.deltaSeconds ?? 0.0,
        );
      }
    } else {
      final double? remaining = widget.checkpoint
          .remainingToBestSeconds(widget.currentElapsedSeconds);
      valueLabel = remaining == null
          ? 'OCZEKUJE'
          : TvIttSplitTimerComparisonHud.formatCountdownToBest(remaining);
    }

    return Focus(
      canRequestFocus: widget.isEnabled,
      onFocusChange: (bool focused) => setState(() => _isFocused = focused),
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (!widget.isEnabled) return KeyEventResult.ignored;
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: widget.isEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) {
          if (widget.isEnabled) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (widget.isEnabled) {
            setState(() {
              _isHovered = false;
              _isPressed = false;
            });
          }
        },
        child: GestureDetector(
          onTapDown: (_) {
            if (widget.isEnabled) setState(() => _isPressed = true);
          },
          onTapUp: (_) {
            if (widget.isEnabled) setState(() => _isPressed = false);
          },
          onTapCancel: () {
            if (widget.isEnabled) setState(() => _isPressed = false);
          },
          onTap: widget.isEnabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: tileBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: tileBorder,
                width: widget.isSelected || _isFocused ? 1.4 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      widget.checkpoint.displayLabel,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isCrossed
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${widget.checkpoint.distanceKm.toStringAsFixed(1)}k',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: isCrossed
                            ? Colors.white.withValues(alpha: 0.88)
                            : AppColors.textSecondary,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    valueLabel,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: valueColor,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
