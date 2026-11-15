import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// Typ grupy obserwowanej w małym oknie Picture-in-Picture (CAM 2).
enum PipCameraTargetType {
  /// Walka w ucieczce przed peletonem.
  breakaway(
    badgeLabel: 'UCIECZKA',
    shortLabel: 'BREAKAWAY',
    icon: Icons.bolt_rounded,
    accentColor: AppColors.goldAccent,
  ),

  /// Pogoń po kraksie lub defekcie kluczowego kolarza.
  crashChase(
    badgeLabel: 'POGOŃ PO KRAKSIE',
    shortLabel: 'CRASH CHASE',
    icon: Icons.warning_amber_rounded,
    accentColor: AppColors.crimsonAlert,
  ),

  /// Kontratak między peletonem a czołówką.
  counterAttack(
    badgeLabel: 'KONTRATAK',
    shortLabel: 'COUNTER',
    icon: Icons.flash_on_rounded,
    accentColor: AppColors.accentBlue,
  ),

  /// Grupetto walczące o zmieszczenie się w limicie czasu.
  grupetto(
    badgeLabel: 'GRUPETTO',
    shortLabel: 'GRUPETTO',
    icon: Icons.groups_rounded,
    accentColor: AppColors.amberWarning,
  );

  final String badgeLabel;
  final String shortLabel;
  final IconData icon;
  final Color accentColor;

  const PipCameraTargetType({
    required this.badgeLabel,
    required this.shortLabel,
    required this.icon,
    required this.accentColor,
  });
}

/// Kąt kamery 3D w oknie Picture-in-Picture.
enum PipCameraAngle {
  /// Motocykl TV jadący tuż przed grupą.
  motoFront(
    code: 'MOTO 2',
    label: 'Motocykl z przodu',
    icon: Icons.two_wheeler_rounded,
  ),

  /// Ujęcie z helikoptera nad grupą.
  helicopterOverhead(
    code: 'HELI 2',
    label: 'Helikopter z góry',
    icon: Icons.flight_rounded,
  ),

  /// Dynamiczne ujęcie zza pleców grupy.
  chaseTail(
    code: 'CHASE 2',
    label: 'Kamera z tyłu',
    icon: Icons.videocam_rounded,
  );

  final String code;
  final String label;
  final IconData icon;

  const PipCameraAngle({
    required this.code,
    required this.label,
    required this.icon,
  });

  /// Zwraca kolejny kąt kamery w cyklu.
  PipCameraAngle get next {
    const List<PipCameraAngle> values = PipCameraAngle.values;
    return values[(index + 1) % values.length];
  }
}

/// Próbka pojedynczego kolarza widocznego w podglądzie 3D Picture-in-Picture.
@immutable
class PipBreakawayRiderSample {
  /// Unikalny identyfikator kolarza.
  final String riderId;

  /// Nazwisko lub skrót kolarza (np. "KWIATKOWSKI").
  final String riderName;

  /// Trzyliterowy kod drużyny (np. "IGD", "TVL").
  final String teamShortCode;

  /// Kolor koszulki drużynowej.
  final Color jerseyColor;

  /// Czy kolarz należy do drużyny gracza (złota obwódka).
  final bool isPlayerRider;

  /// Pozycja poprzeczna na szosie w metrach (`-3.5` .. `+3.5`).
  final double lateralOffsetMeters;

  /// Odległość wzdłużna w grupie w metrach (`0.0` = czoło kadru, dodatnia = dalej).
  final double longitudinalOffsetMeters;

  /// Aktualna prędkość w km/h.
  final double speedKmh;

  /// Aktualna moc w watach.
  final int watts;

  /// Kadencja pedałowania (RPM).
  final double cadenceRpm;

  /// Czy kolarz jest w trakcie aktywnego ataku.
  final bool isAttacking;

  /// Czy kolarz wraca po kraksie / ma widoczne otarcia lub defekt.
  final bool hasCrashDamage;

  const PipBreakawayRiderSample({
    required this.riderId,
    required this.riderName,
    required this.teamShortCode,
    required this.jerseyColor,
    this.isPlayerRider = false,
    this.lateralOffsetMeters = 0.0,
    this.longitudinalOffsetMeters = 4.0,
    this.speedKmh = 44.0,
    this.watts = 360,
    this.cadenceRpm = 92.0,
    this.isAttacking = false,
    this.hasCrashDamage = false,
  });
}

/// Komplet danych telemetrycznych i wizualnych dla okna [TvPictureInPictureBreakawayCam].
@immutable
class TvPipBreakawayFeedData {
  /// Typ grupy prezentowanej w podglądzie PiP.
  final PipCameraTargetType targetType;

  /// Aktualny kąt kamery 3D w podglądzie PiP.
  final PipCameraAngle cameraAngle;

  /// Etykieta kanału podglądu (np. "CAM 2 • UCIECZKA").
  final String feedLabel;

  /// Etykieta głównej kamery (np. "CAM 1 • LIDER PELETONU").
  final String mainCameraLabel;

  /// Różnica czasowa do peletonu w sekundach (dodatnia = przewaga, ujemna = strata).
  final double gapToPelotonSeconds;

  /// Dystans do peletonu w metrach.
  final double gapDistanceMeters;

  /// Średnia prędkość obserwowanej grupy w km/h.
  final double groupSpeedKmh;

  /// Aktualne nachylenie terenu w procentach.
  final double roadGradientPercent;

  /// Lista kolarzy widocznych w scenie 3D okna PiP.
  final List<PipBreakawayRiderSample> riders;

  /// Nazwisko wyróżnionego kolarza w grupie (np. inicjatora ataku lub poszkodowanego).
  final String? highlightRiderName;

  /// Moc wyróżnionego kolarza w watach.
  final int? highlightRiderWatts;

  /// Czy transmisja live z kamery 2 jest aktywna.
  final bool isLiveSignalActive;

  /// Czy w obserwowanej grupie jedzie przynajmniej jeden kolarz gracza.
  final bool isPlayerInGroup;

  /// Jakość sygnału transmisji z motocykla/helikoptera (`0.0` .. `100.0`).
  final double signalQualityPercent;

  const TvPipBreakawayFeedData({
    required this.targetType,
    this.cameraAngle = PipCameraAngle.motoFront,
    this.feedLabel = 'CAM 2 • UCIECZKA',
    this.mainCameraLabel = 'CAM 1 • PELETON',
    this.gapToPelotonSeconds = 0.0,
    this.gapDistanceMeters = 0.0,
    this.groupSpeedKmh = 42.0,
    this.roadGradientPercent = 0.0,
    this.riders = const <PipBreakawayRiderSample>[],
    this.highlightRiderName,
    this.highlightRiderWatts,
    this.isLiveSignalActive = true,
    this.isPlayerInGroup = false,
    this.signalQualityPercent = 96.0,
  });

  /// Tworzy kopię danych z nadpisanymi wybranymi polami.
  TvPipBreakawayFeedData copyWith({
    PipCameraTargetType? targetType,
    PipCameraAngle? cameraAngle,
    String? feedLabel,
    String? mainCameraLabel,
    double? gapToPelotonSeconds,
    double? gapDistanceMeters,
    double? groupSpeedKmh,
    double? roadGradientPercent,
    List<PipBreakawayRiderSample>? riders,
    String? highlightRiderName,
    int? highlightRiderWatts,
    bool? isLiveSignalActive,
    bool? isPlayerInGroup,
    double? signalQualityPercent,
  }) {
    return TvPipBreakawayFeedData(
      targetType: targetType ?? this.targetType,
      cameraAngle: cameraAngle ?? this.cameraAngle,
      feedLabel: feedLabel ?? this.feedLabel,
      mainCameraLabel: mainCameraLabel ?? this.mainCameraLabel,
      gapToPelotonSeconds: gapToPelotonSeconds ?? this.gapToPelotonSeconds,
      gapDistanceMeters: gapDistanceMeters ?? this.gapDistanceMeters,
      groupSpeedKmh: groupSpeedKmh ?? this.groupSpeedKmh,
      roadGradientPercent: roadGradientPercent ?? this.roadGradientPercent,
      riders: riders ?? this.riders,
      highlightRiderName: highlightRiderName ?? this.highlightRiderName,
      highlightRiderWatts: highlightRiderWatts ?? this.highlightRiderWatts,
      isLiveSignalActive: isLiveSignalActive ?? this.isLiveSignalActive,
      isPlayerInGroup: isPlayerInGroup ?? this.isPlayerInGroup,
      signalQualityPercent: signalQualityPercent ?? this.signalQualityPercent,
    );
  }
}

/// Okienko Picture-in-Picture (PiP) w prawym górnym rogu widoku 3D.
///
/// Pozwala jednocześnie śledzić główną kamerę na liderze w peletonie oraz
/// mały podgląd 3D na walkę w ucieczce, kontratak lub pogoń po kraksie.
class TvPictureInPictureBreakawayCam extends StatefulWidget {
  /// Dane telemetryczne i kolarze dla kamery Picture-in-Picture.
  final TvPipBreakawayFeedData data;

  /// Callback zamiany kamery głównej (CAM 1) z kamerą PiP (CAM 2).
  final VoidCallback? onSwapCameras;

  /// Callback zmiany obserwowanego typu grupy (ucieczka / pogoń po kraksie / itp.).
  final ValueChanged<PipCameraTargetType>? onSelectTargetType;

  /// Callback zmiany kąta kamery 3D w oknie PiP.
  final ValueChanged<PipCameraAngle>? onChangeCameraAngle;

  /// Callback powiększenia/zmniejszenia okna PiP.
  final ValueChanged<bool>? onExpandedChanged;

  /// Callback zminimalizowania/przywrócenia okna PiP.
  final ValueChanged<bool>? onMinimizedChanged;

  /// Czy widget ma sam wyrównywać się do prawego górnego rogu (domyślnie `true`).
  final bool alignTopRight;

  /// Czy okno PiP jest domyślnie powiększone.
  final bool initialExpanded;

  /// Czy okno PiP jest domyślnie zminimalizowane do pigułki.
  final bool initialMinimized;

  /// Czy interakcje użytkownika w oknie PiP są aktywne.
  final bool enabled;

  /// Zewnętrzne marginesy względem krawędzi widoku 3D.
  final EdgeInsetsGeometry margin;

  const TvPictureInPictureBreakawayCam({
    super.key,
    required this.data,
    this.onSwapCameras,
    this.onSelectTargetType,
    this.onChangeCameraAngle,
    this.onExpandedChanged,
    this.onMinimizedChanged,
    this.alignTopRight = true,
    this.initialExpanded = false,
    this.initialMinimized = false,
    this.enabled = true,
    this.margin = const EdgeInsets.only(top: 12.0, right: 12.0),
  });

  @override
  State<TvPictureInPictureBreakawayCam> createState() =>
      _TvPictureInPictureBreakawayCamState();
}

class _TvPictureInPictureBreakawayCamState
    extends State<TvPictureInPictureBreakawayCam>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sceneController;
  late bool _isExpanded;
  late bool _isMinimized;
  bool _isCardHovered = false;
  bool _isCardFocused = false;
  bool _isSwapPressed = false;
  double _swapRotationTurns = 0.0;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
    _isMinimized = widget.initialMinimized;
    _sceneController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _sceneController.dispose();
    super.dispose();
  }

  void _handleSwapCameras() {
    if (!widget.enabled || widget.onSwapCameras == null) {
      return;
    }
    setState(() {
      _swapRotationTurns += 0.5;
    });
    widget.onSwapCameras?.call();
  }

  void _handleToggleExpanded() {
    if (!widget.enabled) {
      return;
    }
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onExpandedChanged?.call(_isExpanded);
  }

  void _handleToggleMinimized() {
    if (!widget.enabled) {
      return;
    }
    setState(() {
      _isMinimized = !_isMinimized;
    });
    widget.onMinimizedChanged?.call(_isMinimized);
  }

  void _handleCycleTargetType() {
    if (!widget.enabled || widget.onSelectTargetType == null) {
      return;
    }
    const List<PipCameraTargetType> types = PipCameraTargetType.values;
    final int nextIndex = (widget.data.targetType.index + 1) % types.length;
    widget.onSelectTargetType?.call(types[nextIndex]);
  }

  void _handleCycleCameraAngle() {
    if (!widget.enabled || widget.onChangeCameraAngle == null) {
      return;
    }
    widget.onChangeCameraAngle?.call(widget.data.cameraAngle.next);
  }

  String _formatGap(double gapSeconds) {
    final double safe =
        gapSeconds.isNaN || gapSeconds.isInfinite ? 0.0 : gapSeconds;
    final String sign = safe >= 0 ? '+' : '-';
    final int totalSeconds = safe.abs().round();
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    if (minutes > 0) {
      return '$sign$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '$sign${seconds}s';
  }

  String _formatSpeed(double speedKmh) {
    final double safe =
        speedKmh.isNaN || speedKmh.isInfinite ? 0.0 : speedKmh.clamp(0.0, 120.0);
    return '${safe.toStringAsFixed(1)} km/h';
  }

  String _formatGradient(double gradient) {
    final double safe =
        gradient.isNaN || gradient.isInfinite ? 0.0 : gradient.clamp(-30.0, 35.0);
    final String sign = safe > 0.05 ? '+' : '';
    return '$sign${safe.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final bool isMobile = maxWidth < 600.0;
        final bool isTablet = maxWidth >= 600.0 && maxWidth < 1200.0;

        final double targetWidth;
        final double targetHeight;
        if (_isMinimized) {
          targetWidth = isMobile ? 168.0 : 210.0;
          targetHeight = 40.0;
        } else if (isMobile) {
          targetWidth = _isExpanded ? math.min(maxWidth - 24.0, 260.0) : 186.0;
          targetHeight = _isExpanded ? 172.0 : 128.0;
        } else if (isTablet) {
          targetWidth = _isExpanded ? 328.0 : 254.0;
          targetHeight = _isExpanded ? 214.0 : 164.0;
        } else {
          targetWidth = _isExpanded ? 384.0 : 296.0;
          targetHeight = _isExpanded ? 244.0 : 186.0;
        }

        final Widget cardContent = Padding(
          padding: widget.margin,
          child: FocusableActionDetector(
            enabled: widget.enabled,
            onShowFocusHighlight: (bool focused) {
              if (_isCardFocused != focused) {
                setState(() => _isCardFocused = focused);
              }
            },
            shortcuts: const <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.keyS):
                  _SwapPipCameraIntent(),
              SingleActivator(LogicalKeyboardKey.keyM):
                  _ToggleMinimizePipIntent(),
            },
            actions: <Type, Action<Intent>>{
              _SwapPipCameraIntent: CallbackAction<_SwapPipCameraIntent>(
                onInvoke: (_) {
                  _handleSwapCameras();
                  return null;
                },
              ),
              _ToggleMinimizePipIntent:
                  CallbackAction<_ToggleMinimizePipIntent>(
                onInvoke: (_) {
                  _handleToggleMinimized();
                  return null;
                },
              ),
            },
            child: MouseRegion(
              onEnter: (_) => setState(() => _isCardHovered = true),
              onExit: (_) => setState(() => _isCardHovered = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                width: targetWidth,
                height: targetHeight,
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: _resolveBorderColor(),
                    width: _isCardFocused ? 1.5 : 1.0,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.52),
                      blurRadius: _isCardHovered ? 22.0 : 14.0,
                      offset: const Offset(0, 6),
                    ),
                    if (widget.data.isPlayerInGroup || _isCardHovered)
                      BoxShadow(
                        color: widget.data.targetType.accentColor
                            .withValues(alpha: _isCardHovered ? 0.22 : 0.12),
                        blurRadius: 16.0,
                        spreadRadius: 0.5,
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: _isMinimized
                      ? _buildMinimizedPill(isMobile: isMobile)
                      : _buildExpandedPipWindow(
                          isMobile: isMobile,
                          isCompact: !_isExpanded && isMobile,
                        ),
                ),
              ),
            ),
          ),
        );

        if (widget.alignTopRight) {
          return Align(
            alignment: Alignment.topRight,
            child: cardContent,
          );
        }
        return cardContent;
      },
    );
  }

  Color _resolveBorderColor() {
    if (!widget.enabled) {
      return AppColors.cardBorder.withValues(alpha: 0.5);
    }
    if (_isCardFocused) {
      return AppColors.goldAccent;
    }
    if (_isCardHovered) {
      return widget.data.targetType.accentColor.withValues(alpha: 0.85);
    }
    if (widget.data.targetType == PipCameraTargetType.crashChase) {
      return AppColors.crimsonAlert.withValues(alpha: 0.65);
    }
    return const Color(0xFF2A2F3D);
  }

  Widget _buildMinimizedPill({required bool isMobile}) {
    final Color accent = widget.data.targetType.accentColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: Row(
        children: <Widget>[
          _LivePulseDot(
            controller: _sceneController,
            active: widget.data.isLiveSignalActive,
            color: accent,
          ),
          const SizedBox(width: 6.0),
          Expanded(
            child: Text(
              isMobile
                  ? '${widget.data.cameraAngle.code} ${_formatGap(widget.data.gapToPelotonSeconds)}'
                  : '${widget.data.targetType.shortLabel} • ${_formatGap(widget.data.gapToPelotonSeconds)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
          _PipIconButton(
            tooltip: 'Przywróć okno PiP',
            icon: Icons.open_in_full_rounded,
            enabled: widget.enabled,
            onPressed: _handleToggleMinimized,
            size: 24.0,
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedPipWindow({
    required bool isMobile,
    required bool isCompact,
  }) {
    final Color accent = widget.data.targetType.accentColor;
    final bool canSwap = widget.enabled && widget.onSwapCameras != null;
    final bool canSwitchTarget =
        widget.enabled && widget.onSelectTargetType != null;
    final bool canCycleAngle =
        widget.enabled && widget.onChangeCameraAngle != null;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // Warstwa 3D sceny ucieczki / pogoni
        AnimatedBuilder(
          animation: _sceneController,
          builder: (BuildContext context, _) {
            return CustomPaint(
              painter: _PipMini3dScenePainter(
                data: widget.data,
                animationProgress: _sceneController.value,
              ),
              isComplex: true,
              willChange: true,
            );
          },
        ),

        // Winieta TV i czytelność nakładki
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                AppColors.background.withValues(alpha: 0.76),
                Colors.transparent,
                AppColors.background.withValues(alpha: 0.86),
              ],
              stops: const <double>[0.0, 0.45, 1.0],
            ),
          ),
        ),

        // Górny pasek transmisji CAM 2 + kontrolki
        Positioned(
          top: 6.0,
          left: 8.0,
          right: 6.0,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Row(
                  children: <Widget>[
                    Flexible(
                      flex: 3,
                      child: _PipTargetChip(
                        targetType: widget.data.targetType,
                        compact: isCompact,
                        enabled: canSwitchTarget,
                        onTap: _handleCycleTargetType,
                        controller: _sceneController,
                        isLive: widget.data.isLiveSignalActive,
                      ),
                    ),
                    if (!isCompact) ...<Widget>[
                      const SizedBox(width: 5.0),
                      Flexible(
                        flex: 2,
                        child: _PipAngleChip(
                          angle: widget.data.cameraAngle,
                          enabled: canCycleAngle,
                          onTap: _handleCycleCameraAngle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4.0),
              _PipIconButton(
                tooltip: canSwap
                    ? 'Zamień z główną kamerą (S)'
                    : 'Zamiana kamer niedostępna',
                icon: Icons.swap_horiz_rounded,
                enabled: canSwap,
                isActive: _isSwapPressed,
                rotationTurns: _swapRotationTurns,
                accentColor: AppColors.goldAccent,
                onPressed: _handleSwapCameras,
                onHighlightChanged: (bool active) {
                  if (_isSwapPressed != active) {
                    setState(() => _isSwapPressed = active);
                  }
                },
                size: isMobile ? 22.0 : 25.0,
              ),
              const SizedBox(width: 4.0),
              _PipIconButton(
                tooltip: _isExpanded ? 'Kompaktowy podgląd' : 'Powiększ podgląd',
                icon: _isExpanded
                    ? Icons.close_fullscreen_rounded
                    : Icons.open_in_full_rounded,
                enabled: widget.enabled,
                onPressed: _handleToggleExpanded,
                size: isMobile ? 22.0 : 25.0,
              ),
              const SizedBox(width: 4.0),
              _PipIconButton(
                tooltip: 'Minimalizuj (M)',
                icon: Icons.minimize_rounded,
                enabled: widget.enabled,
                onPressed: _handleToggleMinimized,
                size: isMobile ? 22.0 : 25.0,
              ),
            ],
          ),
        ),

        // Dolny pasek telemetrii ucieczki / pogoni
        Positioned(
          left: 8.0,
          right: 8.0,
          bottom: 6.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (widget.data.highlightRiderName != null && !isCompact)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 3.0,
                        height: 11.0,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(2.0),
                        ),
                      ),
                      const SizedBox(width: 5.0),
                      Expanded(
                        child: Text(
                          widget.data.highlightRiderName!.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (widget.data.highlightRiderWatts != null)
                        Text(
                          '${widget.data.highlightRiderWatts} W',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: accent,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 6.0 : 8.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: AppColors.cardBorder.withValues(alpha: 0.9),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(
                      flex: 2,
                      child: _TelemetryTag(
                        label: 'GAP',
                        value: _formatGap(widget.data.gapToPelotonSeconds),
                        valueColor: accent,
                        compact: isCompact,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Flexible(
                      flex: 3,
                      child: _TelemetryTag(
                        label: isCompact ? '' : 'V',
                        value: _formatSpeed(widget.data.groupSpeedKmh),
                        valueColor: AppColors.textPrimary,
                        compact: isCompact,
                      ),
                    ),
                    if (!isMobile || _isExpanded) ...<Widget>[
                      const SizedBox(width: 6.0),
                      Flexible(
                        flex: 2,
                        child: _TelemetryTag(
                          label: 'SLOPE',
                          value: _formatGradient(widget.data.roadGradientPercent),
                          valueColor: widget.data.roadGradientPercent >= 6.0
                              ? AppColors.amberWarning
                              : AppColors.textSecondary,
                          compact: isCompact,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SwapPipCameraIntent extends Intent {
  const _SwapPipCameraIntent();
}

class _ToggleMinimizePipIntent extends Intent {
  const _ToggleMinimizePipIntent();
}

class _LivePulseDot extends StatelessWidget {
  final AnimationController controller;
  final bool active;
  final Color color;

  const _LivePulseDot({
    required this.controller,
    required this.active,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (!active) {
      return Container(
        width: 7.0,
        height: 7.0,
        decoration: const BoxDecoration(
          color: AppColors.textSecondary,
          shape: BoxShape.circle,
        ),
      );
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        final double pulse =
            0.5 + 0.5 * math.sin(controller.value * 2 * math.pi * 2.0);
        return Container(
          width: 7.0,
          height: 7.0,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.55 + 0.45 * pulse),
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: color.withValues(alpha: 0.45 * pulse),
                blurRadius: 6.0,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PipTargetChip extends StatefulWidget {
  final PipCameraTargetType targetType;
  final bool compact;
  final bool enabled;
  final VoidCallback onTap;
  final AnimationController controller;
  final bool isLive;

  const _PipTargetChip({
    required this.targetType,
    required this.compact,
    required this.enabled,
    required this.onTap,
    required this.controller,
    required this.isLive,
  });

  @override
  State<_PipTargetChip> createState() => _PipTargetChipState();
}

class _PipTargetChipState extends State<_PipTargetChip> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.targetType.accentColor;
    final Color bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.5)
        : _pressed
            ? accent.withValues(alpha: 0.28)
            : _hovered
                ? accent.withValues(alpha: 0.2)
                : AppColors.surface.withValues(alpha: 0.9);

    return Tooltip(
      message: widget.enabled
          ? 'Przełącz obiekt podglądu (${widget.targetType.badgeLabel})'
          : widget.targetType.badgeLabel,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        onShowFocusHighlight: (bool focused) {
          if (_focused != focused) {
            setState(() => _focused = focused);
          }
        },
        child: MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.enabled ? widget.onTap : null,
            onTapDown: widget.enabled
                ? (_) => setState(() => _pressed = true)
                : null,
            onTapUp: widget.enabled
                ? (_) => setState(() => _pressed = false)
                : null,
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 6.0 : 7.0,
                vertical: 3.0,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: _focused
                      ? AppColors.goldAccent
                      : accent.withValues(alpha: widget.enabled ? 0.7 : 0.35),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _LivePulseDot(
                    controller: widget.controller,
                    active: widget.isLive,
                    color: accent,
                  ),
                  const SizedBox(width: 5.0),
                  Icon(
                    widget.targetType.icon,
                    size: 11.5,
                    color: accent,
                  ),
                  const SizedBox(width: 4.0),
                  Flexible(
                    child: Text(
                      widget.compact
                          ? widget.targetType.shortLabel
                          : widget.targetType.badgeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: widget.enabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
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

class _PipAngleChip extends StatefulWidget {
  final PipCameraAngle angle;
  final bool enabled;
  final VoidCallback onTap;

  const _PipAngleChip({
    required this.angle,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_PipAngleChip> createState() => _PipAngleChipState();
}

class _PipAngleChipState extends State<_PipAngleChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.enabled
          ? 'Zmień kąt kamery (${widget.angle.label})'
          : widget.angle.label,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        onShowFocusHighlight: (bool focused) {
          if (_focused != focused) {
            setState(() => _focused = focused);
          }
        },
        child: MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.enabled ? widget.onTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
              decoration: BoxDecoration(
                color: _hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.95)
                    : AppColors.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: _focused
                      ? AppColors.goldAccent
                      : AppColors.cardBorder,
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    widget.angle.icon,
                    size: 11.0,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 3.5),
                  Flexible(
                    child: Text(
                      widget.angle.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
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

class _PipIconButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final bool enabled;
  final bool isActive;
  final double rotationTurns;
  final Color accentColor;
  final VoidCallback onPressed;
  final ValueChanged<bool>? onHighlightChanged;
  final double size;

  const _PipIconButton({
    required this.tooltip,
    required this.icon,
    required this.enabled,
    required this.onPressed,
    this.isActive = false,
    this.rotationTurns = 0.0,
    this.accentColor = AppColors.textPrimary,
    this.onHighlightChanged,
    this.size = 24.0,
  });

  @override
  State<_PipIconButton> createState() => _PipIconButtonState();
}

class _PipIconButtonState extends State<_PipIconButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.isActive || _pressed;
    final Color bg = !widget.enabled
        ? AppColors.surface.withValues(alpha: 0.35)
        : active
            ? AppColors.primaryAccent.withValues(alpha: 0.85)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.surface.withValues(alpha: 0.84);

    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        onShowFocusHighlight: (bool focused) {
          if (_focused != focused) {
            setState(() => _focused = focused);
          }
        },
        child: MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.enabled ? widget.onPressed : null,
            onTapDown: widget.enabled
                ? (_) {
                    setState(() => _pressed = true);
                    widget.onHighlightChanged?.call(true);
                  }
                : null,
            onTapUp: widget.enabled
                ? (_) {
                    setState(() => _pressed = false);
                    widget.onHighlightChanged?.call(false);
                  }
                : null,
            onTapCancel: () {
              setState(() => _pressed = false);
              widget.onHighlightChanged?.call(false);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(7.0),
                border: Border.all(
                  color: _focused
                      ? AppColors.goldAccent
                      : _hovered && widget.enabled
                          ? widget.accentColor.withValues(alpha: 0.8)
                          : AppColors.cardBorder,
                  width: 1.0,
                ),
              ),
              child: AnimatedRotation(
                turns: widget.rotationTurns,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: Icon(
                  widget.icon,
                  size: widget.size * 0.58,
                  color: widget.enabled
                      ? (_hovered ? widget.accentColor : AppColors.textPrimary)
                      : AppColors.textSecondary.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TelemetryTag extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool compact;

  const _TelemetryTag({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (label.isNotEmpty) ...<Widget>[
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 9.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4.0),
          ],
          Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: compact ? 10.0 : 11.0,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: valueColor,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lekki, perspektywiczny renderer 3D dla okna podglądu Picture-in-Picture.
class _PipMini3dScenePainter extends CustomPainter {
  final TvPipBreakawayFeedData data;
  final double animationProgress;

  const _PipMini3dScenePainter({
    required this.data,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final double horizonFactor = _resolveHorizonFactor();
    final double horizonY = size.height * horizonFactor;

    // 1. Niebo i odległe pasmo górskie
    _paintSkyAndMountains(canvas, size, horizonY);

    // 2. Teren i perspektywiczna wstęga szosy
    _paintRoadPerspective(canvas, size, horizonY);

    // 3. Kolarze 3D w grupie posortowani od najdalszych do najbliższych
    _paintRiders3d(canvas, size, horizonY);

    // 4. Skanline / subtelny efekt kamery TV przy słabszym sygnale
    if (!data.isLiveSignalActive || data.signalQualityPercent < 70.0) {
      _paintSignalInterference(canvas, size);
    }
  }

  double _resolveHorizonFactor() {
    final double base = switch (data.cameraAngle) {
      PipCameraAngle.motoFront => 0.34,
      PipCameraAngle.helicopterOverhead => 0.18,
      PipCameraAngle.chaseTail => 0.38,
    };
    final double slopeShift = (data.roadGradientPercent * 0.004).clamp(-0.08, 0.08);
    return (base - slopeShift).clamp(0.14, 0.48);
  }

  void _paintSkyAndMountains(Canvas canvas, Size size, double horizonY) {
    final Rect skyRect = Rect.fromLTWH(0, 0, size.width, horizonY + 4.0);
    final Paint skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          const Color(0xFF0F1115),
          data.targetType == PipCameraTargetType.crashChase
              ? const Color(0xFF28171B)
              : const Color(0xFF1A2232),
        ],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    // Sylwetki szczytów w tle
    final Path ridge = Path()
      ..moveTo(0, horizonY)
      ..lineTo(size.width * 0.16, horizonY - size.height * 0.10)
      ..lineTo(size.width * 0.34, horizonY - size.height * 0.03)
      ..lineTo(size.width * 0.56, horizonY - size.height * 0.13)
      ..lineTo(size.width * 0.78, horizonY - size.height * 0.05)
      ..lineTo(size.width, horizonY - size.height * 0.09)
      ..lineTo(size.width, horizonY + 2.0)
      ..lineTo(0, horizonY + 2.0)
      ..close();
    canvas.drawPath(
      ridge,
      Paint()..color = const Color(0xFF181B22).withValues(alpha: 0.92),
    );
  }

  void _paintRoadPerspective(Canvas canvas, Size size, double horizonY) {
    // Tło terenu pod horyzontem
    final Rect groundRect = Rect.fromLTWH(
      0,
      horizonY,
      size.width,
      size.height - horizonY,
    );
    canvas.drawRect(
      groundRect,
      Paint()..color = const Color(0xFF14181E),
    );

    final double vanishX = size.width * 0.5;
    final double topHalfWidth = data.cameraAngle == PipCameraAngle.helicopterOverhead
        ? size.width * 0.14
        : size.width * 0.06;
    final double bottomHalfWidth =
        data.cameraAngle == PipCameraAngle.helicopterOverhead
            ? size.width * 0.48
            : size.width * 0.54;

    // Wstęga asfaltu
    final Path roadPath = Path()
      ..moveTo(vanishX - topHalfWidth, horizonY)
      ..lineTo(vanishX + topHalfWidth, horizonY)
      ..lineTo(vanishX + bottomHalfWidth, size.height)
      ..lineTo(vanishX - bottomHalfWidth, size.height)
      ..close();

    final Paint roadPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFF222630),
          Color(0xFF1B1F28),
        ],
      ).createShader(groundRect);
    canvas.drawPath(roadPath, roadPaint);

    // Krawędzie szosy
    final Paint edgePaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(vanishX - topHalfWidth, horizonY),
      Offset(vanishX - bottomHalfWidth, size.height),
      edgePaint,
    );
    canvas.drawLine(
      Offset(vanishX + topHalfWidth, horizonY),
      Offset(vanishX + bottomHalfWidth, size.height),
      edgePaint,
    );

    // Animowane przerywane pasy na osi jezdni + słupki pobocza
    final double speedNorm = (data.groupSpeedKmh / 45.0).clamp(0.4, 1.8);
    final double scroll = (animationProgress * 6.0 * speedNorm) % 1.0;
    final Paint dashPaint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.42)
      ..strokeCap = StrokeCap.round;

    const int segments = 7;
    for (int i = 0; i < segments; i++) {
      final double t0 = ((i + scroll) / segments).clamp(0.0, 1.0);
      final double t1 = ((i + 0.45 + scroll) / segments).clamp(0.0, 1.0);
      if (t1 <= t0) {
        continue;
      }
      final double p0 = math.pow(t0, 1.85).toDouble();
      final double p1 = math.pow(t1, 1.85).toDouble();
      final double y0 = horizonY + (size.height - horizonY) * p0;
      final double y1 = horizonY + (size.height - horizonY) * p1;
      dashPaint.strokeWidth = 1.0 + 1.8 * p1;
      canvas.drawLine(Offset(vanishX, y0), Offset(vanishX, y1), dashPaint);

      // Słupki kilometrowe po obu stronach szosy dla poczucia prędkości 3D
      final double halfW =
          topHalfWidth + (bottomHalfWidth - topHalfWidth) * p1;
      final double postH = 2.0 + 7.0 * p1;
      final Paint postPaint = Paint()
        ..color = AppColors.cardBorder.withValues(alpha: 0.7)
        ..strokeWidth = 1.0 + p1;
      canvas.drawLine(
        Offset(vanishX - halfW - 3.0, y1),
        Offset(vanishX - halfW - 3.0, y1 - postH),
        postPaint,
      );
      canvas.drawLine(
        Offset(vanishX + halfW + 3.0, y1),
        Offset(vanishX + halfW + 3.0, y1 - postH),
        postPaint,
      );
    }
  }

  void _paintRiders3d(Canvas canvas, Size size, double horizonY) {
    if (data.riders.isEmpty) {
      return;
    }

    final List<PipBreakawayRiderSample> sorted =
        List<PipBreakawayRiderSample>.from(data.riders)
          ..sort(
            (PipBreakawayRiderSample a, PipBreakawayRiderSample b) =>
                b.longitudinalOffsetMeters
                    .compareTo(a.longitudinalOffsetMeters),
          );

    final double vanishX = size.width * 0.5;
    final double roadSpanH = size.height - horizonY;

    for (int i = 0; i < sorted.length; i++) {
      final PipBreakawayRiderSample rider = sorted[i];
      // Odległość wzdłużna 0..30m rzutowana na głębię widoku
      final double depthNorm =
          (1.0 - (rider.longitudinalOffsetMeters / 28.0)).clamp(0.18, 0.92);
      final double persp = math.pow(depthNorm, 1.45).toDouble();
      final double y = horizonY + roadSpanH * (0.22 + 0.66 * persp);

      final double roadHalfW = size.width * (0.08 + 0.40 * persp);
      final double x = vanishX +
          (rider.lateralOffsetMeters / 4.2).clamp(-1.0, 1.0) * roadHalfW;
      final double scale = (0.45 + 0.75 * persp) *
          (data.cameraAngle == PipCameraAngle.helicopterOverhead ? 0.85 : 1.0);

      _drawSingleRider3d(
        canvas: canvas,
        center: Offset(x, y),
        scale: scale,
        rider: rider,
        phaseOffset: i * 0.7,
      );
    }
  }

  void _drawSingleRider3d({
    required Canvas canvas,
    required Offset center,
    required double scale,
    required PipBreakawayRiderSample rider,
    required double phaseOffset,
  }) {
    final double cadenceFactor = (rider.cadenceRpm / 90.0).clamp(0.5, 1.5);
    final double sway = math.sin(
          animationProgress * 2 * math.pi * 4.0 * cadenceFactor + phaseOffset,
        ) *
        1.4 *
        scale;

    // Cień na asfalcie
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + 2.0 * scale, center.dy + 2.5 * scale),
        width: 14.0 * scale,
        height: 5.0 * scale,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );

    // Koło roweru
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - 3.5 * scale),
        width: 4.5 * scale,
        height: 9.0 * scale,
      ),
      Paint()
        ..color = const Color(0xFF0F1115)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * scale,
    );

    // Złota poświata lidera / gracza lub alert ataku/kraksy
    if (rider.isPlayerRider || rider.isAttacking || rider.hasCrashDamage) {
      final Color ringColor = rider.hasCrashDamage
          ? AppColors.crimsonAlert
          : rider.isPlayerRider
              ? AppColors.goldAccent
              : AppColors.accentBlue;
      canvas.drawCircle(
        Offset(center.dx + sway, center.dy - 11.0 * scale),
        9.5 * scale,
        Paint()..color = ringColor.withValues(alpha: 0.24),
      );
    }

    // Tułów / koszulka kolarza
    final RRect torsoRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx + sway, center.dy - 10.5 * scale),
        width: 9.2 * scale,
        height: 10.0 * scale,
      ),
      Radius.circular(3.5 * scale),
    );
    canvas.drawRRect(
      torsoRect,
      Paint()..color = rider.jerseyColor,
    );

    if (rider.isPlayerRider) {
      canvas.drawRRect(
        torsoRect,
        Paint()
          ..color = AppColors.goldAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 * scale,
      );
    }

    // Kask
    canvas.drawCircle(
      Offset(center.dx + sway, center.dy - 17.5 * scale),
      3.4 * scale,
      Paint()
        ..color = rider.isPlayerRider
            ? AppColors.goldAccent
            : AppColors.textPrimary,
    );
  }

  void _paintSignalInterference(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;
    final double offset = (animationProgress * 40.0) % 6.0;
    for (double y = offset; y < size.height; y += 6.0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PipMini3dScenePainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.data != data;
  }
}
