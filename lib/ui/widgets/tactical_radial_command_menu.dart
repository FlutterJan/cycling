import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/peloton/rider_race_state.dart';

/// 8 rozkazów taktycznych dostępnych w kołowym menu rozkazów [TacticalRadialCommandMenu].
enum TacticalRadialCommandType {
  attack(
    label: 'Atakuj',
    shortLabel: 'Atakuj',
    description: 'Maksymalny zryw beztlenowy i próba oderwania się od grupy.',
    icon: Icons.bolt_rounded,
    accentColor: AppColors.crimsonAlert,
    tacticalOrder: TacticalOrder.attack,
    shortcutDigit: 1,
  ),
  holdPosition(
    label: 'Utrzymaj Pozycję',
    shortLabel: 'Pozycja',
    description: 'Jazda równym tempem w aktualnym szyku grupy.',
    icon: Icons.gps_fixed_rounded,
    accentColor: AppColors.accentBlue,
    tacticalOrder: TacticalOrder.holdPosition,
    shortcutDigit: 2,
  ),
  pullGroup(
    label: 'Daj Zmianę',
    shortLabel: 'Zmiana',
    description: 'Wyjście na czoło grupy i nadawanie mocnego tempa.',
    icon: Icons.speed_rounded,
    accentColor: AppColors.amberWarning,
    tacticalOrder: TacticalOrder.pullGroup,
    shortcutDigit: 3,
  ),
  followWheels(
    label: 'Siedź na Kole',
    shortLabel: 'Na Kole',
    description: 'Ścisłe pilnowanie koła i reakcja na ataki rywali.',
    icon: Icons.link_rounded,
    accentColor: AppColors.cyanAccent,
    tacticalOrder: TacticalOrder.followWheels,
    shortcutDigit: 4,
  ),
  protectLeader(
    label: 'Chroń Lidera',
    shortLabel: 'Chroń',
    description: 'Osłona lidera przed wiatrem i kontrola pozycji w peletonie.',
    icon: Icons.verified_user_rounded,
    accentColor: AppColors.goldAccent,
    tacticalOrder: TacticalOrder.protectLeader,
    shortcutDigit: 5,
  ),
  energyGel(
    label: 'Żel Energetyczny',
    shortLabel: 'Żel',
    description: 'Natychmiastowe spożycie żelu węglowodanowego (+glikogen).',
    icon: Icons.local_fire_department_rounded,
    accentColor: AppColors.statusSuccess,
    tacticalOrder: null,
    shortcutDigit: 6,
  ),
  fetchBidons(
    label: 'Wróć po Bidony',
    shortLabel: 'Bidony',
    description: 'Spłynięcie do wozu technicznego po wodę i zapasy dla ekipy.',
    icon: Icons.water_drop_rounded,
    accentColor: AppColors.accentBlue,
    tacticalOrder: TacticalOrder.fetchBidonsFromCar,
    shortcutDigit: 7,
  ),
  grupettoSaveEnergy(
    label: 'Spokojny Dojazd Grupetto',
    shortLabel: 'Grupetto',
    description: 'Głębokie chowanie się w grupie i maksymalna oszczędność sił.',
    icon: Icons.battery_saver_rounded,
    accentColor: AppColors.textSecondary,
    tacticalOrder: TacticalOrder.saveEnergy,
    shortcutDigit: 8,
  );

  final String label;
  final String shortLabel;
  final String description;
  final IconData icon;
  final Color accentColor;
  final TacticalOrder? tacticalOrder;
  final int shortcutDigit;

  const TacticalRadialCommandType({
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.tacticalOrder,
    required this.shortcutDigit,
  });

  bool get isEnergyGel => this == TacticalRadialCommandType.energyGel;
}

/// Kołowe menu rozkazów taktycznych otwierane po kliknięciu kolarza w widoku 3D.
///
/// Zawiera 8 wycinków koła z animacją sprężynową 200 ms, pełnymi stanami
/// `hover` / `active` / `disabled` / `focus`, obsługą klawiatury (strzałki, Tab,
/// Enter, Escape, 1–8) oraz responsywnym skalowaniem dla 390x844, 1024x768 i 1600x900.
class TacticalRadialCommandMenu extends StatefulWidget {
  final String riderId;
  final String riderName;
  final int bibNumber;
  final Offset anchorPosition;
  final TacticalOrder? activeOrder;
  final bool isPlayerRider;
  final int gelsLeft;
  final int bidonsLeft;
  final int currentWatts;
  final Set<TacticalRadialCommandType> disabledCommands;
  final ValueChanged<TacticalRadialCommandType>? onCommandSelected;
  final VoidCallback? onDismiss;
  final VoidCallback? onInspectRiderDetails;
  final Duration animationDuration;

  const TacticalRadialCommandMenu({
    super.key,
    required this.riderId,
    required this.riderName,
    required this.bibNumber,
    required this.anchorPosition,
    this.activeOrder,
    this.isPlayerRider = true,
    this.gelsLeft = 4,
    this.bidonsLeft = 2,
    this.currentWatts = 0,
    this.disabledCommands = const {},
    this.onCommandSelected,
    this.onDismiss,
    this.onInspectRiderDetails,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<TacticalRadialCommandMenu> createState() =>
      _TacticalRadialCommandMenuState();
}

class _TacticalRadialCommandMenuState extends State<TacticalRadialCommandMenu>
    with SingleTickerProviderStateMixin {
  static const int _sliceCount = 8;
  static const double _sliceSweep = (2 * math.pi) / _sliceCount;
  static const double _startAngleOffset = -math.pi / 2 - (_sliceSweep / 2);

  late final AnimationController _openController;
  late final Animation<double> _springScale;
  late final Animation<double> _fadeAnimation;
  late final FocusNode _menuFocusNode;

  int? _hoveredIndex;
  int? _pressedIndex;
  int? _focusedIndex;
  bool _isCenterHovered = false;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _menuFocusNode = FocusNode(debugLabel: 'TacticalRadialCommandMenuFocus');
    _openController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
      reverseDuration: const Duration(milliseconds: 150),
    );
    _springScale = CurvedAnimation(
      parent: _openController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _openController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeIn,
    );

    _openController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _menuFocusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant TacticalRadialCommandMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.riderId != widget.riderId ||
        oldWidget.anchorPosition != widget.anchorPosition) {
      _isDismissing = false;
      _hoveredIndex = null;
      _pressedIndex = null;
      _openController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _openController.dispose();
    _menuFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    if (_isDismissing) return;
    _isDismissing = true;
    await _openController.reverse();
    if (mounted) {
      widget.onDismiss?.call();
    }
  }

  bool _isCommandDisabled(TacticalRadialCommandType command) {
    if (!widget.isPlayerRider) return true;
    if (widget.disabledCommands.contains(command)) return true;
    if (command.isEnergyGel && widget.gelsLeft <= 0) return true;
    return false;
  }

  String _disabledReason(TacticalRadialCommandType command) {
    if (!widget.isPlayerRider) {
      return 'Kolarz rywala — brak połączenia radiowego';
    }
    if (command.isEnergyGel && widget.gelsLeft <= 0) {
      return 'Brak żeli energetycznych w kieszonkach';
    }
    return 'Polecenie niedostępne w tym momencie';
  }

  bool _isCommandActive(TacticalRadialCommandType command) {
    if (command.tacticalOrder == null || widget.activeOrder == null) {
      return false;
    }
    return command.tacticalOrder == widget.activeOrder;
  }

  void _executeCommand(TacticalRadialCommandType command) {
    if (_isCommandDisabled(command) || _isDismissing) return;
    widget.onCommandSelected?.call(command);
    _handleDismiss();
  }

  int? _hitTestSlice(
    Offset localPosition,
    double wheelSize,
    double innerRadius,
    double outerRadius,
  ) {
    final center = Offset(wheelSize / 2, wheelSize / 2);
    final delta = localPosition - center;
    final distance = delta.distance;

    if (distance < innerRadius || distance > outerRadius + 14.0) {
      return null;
    }

    double angle = math.atan2(delta.dy, delta.dx) - _startAngleOffset;
    angle = angle % (2 * math.pi);
    if (angle < 0) angle += 2 * math.pi;

    final index = (angle / _sliceSweep).floor().clamp(0, _sliceCount - 1);
    return index;
  }

  bool _hitTestCenter(Offset localPosition, double wheelSize, double innerRadius) {
    final center = Offset(wheelSize / 2, wheelSize / 2);
    return (localPosition - center).distance < innerRadius;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      _handleDismiss();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.tab) {
      setState(() {
        _focusedIndex = ((_focusedIndex ?? -1) + 1) % _sliceCount;
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _focusedIndex =
            ((_focusedIndex ?? 0) - 1 + _sliceCount) % _sliceCount;
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      final idx = _focusedIndex ?? _hoveredIndex;
      if (idx != null) {
        final cmd = TacticalRadialCommandType.values[idx];
        _executeCommand(cmd);
        return KeyEventResult.handled;
      }
    }

    final digitKeys = <LogicalKeyboardKey>[
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
    ];
    final numpadKeys = <LogicalKeyboardKey>[
      LogicalKeyboardKey.numpad1,
      LogicalKeyboardKey.numpad2,
      LogicalKeyboardKey.numpad3,
      LogicalKeyboardKey.numpad4,
      LogicalKeyboardKey.numpad5,
      LogicalKeyboardKey.numpad6,
      LogicalKeyboardKey.numpad7,
      LogicalKeyboardKey.numpad8,
    ];

    final dIdx = digitKeys.indexOf(key);
    final nIdx = numpadKeys.indexOf(key);
    final targetIdx = dIdx >= 0 ? dIdx : nIdx;
    if (targetIdx >= 0 && targetIdx < _sliceCount) {
      setState(() => _focusedIndex = targetIdx);
      _executeCommand(TacticalRadialCommandType.values[targetIdx]);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double vw = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final double vh = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;

        final bool isCompact = vw < 520.0 || vh < 520.0;
        final bool isMedium = !isCompact && vw < 1150.0;

        final double outerRadius = isCompact
            ? 136.0
            : (isMedium ? 162.0 : 178.0);
        final double innerRadius = isCompact
            ? 46.0
            : (isMedium ? 54.0 : 60.0);
        final double wheelSize = (outerRadius + 16.0) * 2;
        const double infoPillHeight = 68.0;
        final double margin = isCompact ? 12.0 : 20.0;

        final double minX = (wheelSize / 2) + margin;
        final double maxX = math.max(minX, vw - (wheelSize / 2) - margin);
        final double minY = (wheelSize / 2) + margin;
        final double maxY = math.max(
          minY,
          vh - (wheelSize / 2) - infoPillHeight - margin,
        );

        final double centerX = widget.anchorPosition.dx.clamp(minX, maxX);
        final double centerY = widget.anchorPosition.dy.clamp(minY, maxY);

        final int? highlightedIndex = _hoveredIndex ?? _focusedIndex;
        final TacticalRadialCommandType? highlightedCommand =
            highlightedIndex != null
                ? TacticalRadialCommandType.values[highlightedIndex]
                : null;

        final double pillWidth = math.min(
          isCompact ? vw - (margin * 2) : 340.0,
          vw - 24.0,
        );
        final double pillLeft = (centerX - pillWidth / 2).clamp(
          12.0,
          math.max(12.0, vw - pillWidth - 12.0),
        );
        final double pillTop = (centerY + outerRadius + 12.0).clamp(
          12.0,
          math.max(12.0, vh - infoPillHeight - 8.0),
        );

        return Focus(
          focusNode: _menuFocusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: Semantics(
            label: 'Kołowe menu rozkazów taktycznych dla ${widget.riderName}',
            child: Stack(
              children: [
                // Półprzezroczyste tło zamykające menu po kliknięciu poza kołem
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _handleDismiss,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        color: AppColors.background.withValues(alpha: 0.42),
                      ),
                    ),
                  ),
                ),

                // Kołowe menu rozkazów (8 wycinków + centrum)
                Positioned(
                  left: centerX - wheelSize / 2,
                  top: centerY - wheelSize / 2,
                  width: wheelSize,
                  height: wheelSize,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _springScale,
                      child: MouseRegion(
                        cursor: _hoveredIndex != null &&
                                !_isCommandDisabled(
                                  TacticalRadialCommandType
                                      .values[_hoveredIndex!],
                                )
                            ? SystemMouseCursors.click
                            : (_isCenterHovered
                                ? SystemMouseCursors.click
                                : SystemMouseCursors.basic),
                        onHover: (event) {
                          final idx = _hitTestSlice(
                            event.localPosition,
                            wheelSize,
                            innerRadius,
                            outerRadius,
                          );
                          final centerHit = _hitTestCenter(
                            event.localPosition,
                            wheelSize,
                            innerRadius,
                          );
                          if (idx != _hoveredIndex ||
                              centerHit != _isCenterHovered) {
                            setState(() {
                              _hoveredIndex = idx;
                              _isCenterHovered = centerHit;
                            });
                          }
                        },
                        onExit: (_) {
                          if (_hoveredIndex != null || _isCenterHovered) {
                            setState(() {
                              _hoveredIndex = null;
                              _pressedIndex = null;
                              _isCenterHovered = false;
                            });
                          }
                        },
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapDown: (details) {
                            final idx = _hitTestSlice(
                              details.localPosition,
                              wheelSize,
                              innerRadius,
                              outerRadius,
                            );
                            if (idx != null) {
                              setState(() {
                                _pressedIndex = idx;
                                _focusedIndex = idx;
                              });
                            }
                          },
                          onTapCancel: () {
                            if (_pressedIndex != null) {
                              setState(() => _pressedIndex = null);
                            }
                          },
                          onTapUp: (details) {
                            final idx = _hitTestSlice(
                              details.localPosition,
                              wheelSize,
                              innerRadius,
                              outerRadius,
                            );
                            setState(() => _pressedIndex = null);
                            if (idx != null) {
                              _executeCommand(
                                TacticalRadialCommandType.values[idx],
                              );
                            } else if (_hitTestCenter(
                              details.localPosition,
                              wheelSize,
                              innerRadius,
                            )) {
                              _handleDismiss();
                            } else {
                              _handleDismiss();
                            }
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CustomPaint(
                                size: Size(wheelSize, wheelSize),
                                painter: _RadialCommandWheelPainter(
                                  innerRadius: innerRadius,
                                  outerRadius: outerRadius,
                                  hoveredIndex: _hoveredIndex,
                                  pressedIndex: _pressedIndex,
                                  focusedIndex: _focusedIndex,
                                  activeOrder: widget.activeOrder,
                                  isCommandDisabled: _isCommandDisabled,
                                  isCommandActive: _isCommandActive,
                                ),
                              ),

                              // Etykiety i ikony 8 wycinków
                              for (int i = 0; i < _sliceCount; i++)
                                _buildSliceContent(
                                  index: i,
                                  wheelSize: wheelSize,
                                  innerRadius: innerRadius,
                                  outerRadius: outerRadius,
                                  isCompact: isCompact,
                                ),

                              // Centralny hub kolarza
                              Center(
                                child: _buildCenterHub(
                                  innerRadius: innerRadius,
                                  isCompact: isCompact,
                                  highlightedCommand: highlightedCommand,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Dolna karta podglądu rozkazu (opis + skrót klawiszowy / powód blokady)
                Positioned(
                  left: pillLeft,
                  top: pillTop,
                  width: pillWidth,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildCommandDetailCard(
                      highlightedCommand: highlightedCommand,
                      isCompact: isCompact,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliceContent({
    required int index,
    required double wheelSize,
    required double innerRadius,
    required double outerRadius,
    required bool isCompact,
  }) {
    final command = TacticalRadialCommandType.values[index];
    final bool disabled = _isCommandDisabled(command);
    final bool hovered = _hoveredIndex == index;
    final bool focused = _focusedIndex == index;
    final bool active = _isCommandActive(command);
    final bool pressed = _pressedIndex == index;

    final double midAngle = _startAngleOffset + (index + 0.5) * _sliceSweep;
    final double baseMidRadius = (innerRadius + outerRadius) / 2;
    final double popOffset = hovered ? 5.0 : (pressed ? -2.0 : 0.0);
    final double r = baseMidRadius + popOffset;

    final double x = (wheelSize / 2) + r * math.cos(midAngle);
    final double y = (wheelSize / 2) + r * math.sin(midAngle);

    final Color fgColor = disabled
        ? AppColors.textSecondary.withValues(alpha: 0.35)
        : (hovered || focused || active
            ? AppColors.textPrimary
            : AppColors.textPrimary.withValues(alpha: 0.9));

    final Color iconColor = disabled
        ? AppColors.textSecondary.withValues(alpha: 0.35)
        : (hovered || active ? command.accentColor : command.accentColor.withValues(alpha: 0.92));

    final double slotWidth = isCompact ? 62.0 : 76.0;
    final double slotHeight = isCompact ? 48.0 : 54.0;

    return Positioned(
      left: x - slotWidth / 2,
      top: y - slotHeight / 2,
      width: slotWidth,
      height: slotHeight,
      child: IgnorePointer(
        child: AnimatedScale(
          scale: pressed ? 0.92 : (hovered ? 1.07 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    command.icon,
                    size: isCompact ? 19.0 : 22.0,
                    color: iconColor,
                  ),
                  if (command.isEnergyGel)
                    Positioned(
                      right: -10,
                      top: -5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: widget.gelsLeft > 0
                              ? AppColors.statusSuccess
                              : AppColors.crimsonAlert,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.gelsLeft}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                command.shortLabel,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 10.0 : 11.0,
                  fontWeight: (hovered || active || focused)
                      ? FontWeight.w700
                      : FontWeight.w600,
                  letterSpacing: -0.2,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterHub({
    required double innerRadius,
    required bool isCompact,
    required TacticalRadialCommandType? highlightedCommand,
  }) {
    final double hubDiameter = (innerRadius * 2) - 8.0;
    final Color borderColor = highlightedCommand != null
        ? (_isCommandDisabled(highlightedCommand)
            ? AppColors.crimsonAlert.withValues(alpha: 0.7)
            : highlightedCommand.accentColor)
        : (widget.isPlayerRider ? AppColors.goldAccent : AppColors.cardBorder);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      width: hubDiameter,
      height: hubDiameter,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _isCenterHovered ? AppColors.surfaceLight : AppColors.surface,
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.85),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#${widget.bibNumber}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 10.0 : 11.0,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: widget.isPlayerRider
                  ? AppColors.goldAccent
                  : AppColors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 1),
          Text(
            _shortRiderName(widget.riderName),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 10.5 : 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.currentWatts > 0 ? '${widget.currentWatts} W' : 'ESC',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 9.5 : 10.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandDetailCard({
    required TacticalRadialCommandType? highlightedCommand,
    required bool isCompact,
  }) {
    final bool hasHighlight = highlightedCommand != null;
    final bool isDisabled =
        hasHighlight && _isCommandDisabled(highlightedCommand);

    final String title = hasHighlight
        ? highlightedCommand.label
        : (widget.isPlayerRider
            ? 'Wybierz rozkaz taktyczny'
            : '${widget.riderName} (Rywal)');

    final String subtitle = hasHighlight
        ? (isDisabled
            ? _disabledReason(highlightedCommand)
            : highlightedCommand.description)
        : (widget.isPlayerRider
            ? 'Kliknij wycinek lub użyj klawiszy 1–8 • Bidony: ${widget.bidonsLeft} • Żele: ${widget.gelsLeft}'
            : 'Możesz obserwować telemetrykę, ale nie wydasz rozkazu rywalowi.');

    final Color accent = hasHighlight
        ? (isDisabled
            ? AppColors.crimsonAlert
            : highlightedCommand.accentColor)
        : AppColors.goldAccent;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12.0 : 14.0,
        vertical: isCompact ? 8.0 : 10.0,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasHighlight
              ? accent.withValues(alpha: 0.65)
              : AppTheme.borderColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.7),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.5)),
            ),
            child: Icon(
              hasHighlight
                  ? highlightedCommand.icon
                  : Icons.radio_button_checked_rounded,
              size: 16,
              color: accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (hasHighlight) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Text(
                          '${highlightedCommand.shortcutDigit}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.0,
                    letterSpacing: -0.1,
                    color: isDisabled
                        ? AppColors.crimsonAlert
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onInspectRiderDetails != null) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: 'Szczegóły kolarza',
              child: InkWell(
                onTap: () {
                  widget.onInspectRiderDetails?.call();
                  _handleDismiss();
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: const Icon(
                    Icons.analytics_outlined,
                    size: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _shortRiderName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) return fullName;
    return parts.last;
  }
}

class _RadialCommandWheelPainter extends CustomPainter {
  static const int _sliceCount = 8;
  static const double _sliceSweep = (2 * math.pi) / _sliceCount;
  static const double _startAngleOffset = -math.pi / 2 - (_sliceSweep / 2);
  static const double _gapRadians = 0.030;

  final double innerRadius;
  final double outerRadius;
  final int? hoveredIndex;
  final int? pressedIndex;
  final int? focusedIndex;
  final TacticalOrder? activeOrder;
  final bool Function(TacticalRadialCommandType) isCommandDisabled;
  final bool Function(TacticalRadialCommandType) isCommandActive;

  const _RadialCommandWheelPainter({
    required this.innerRadius,
    required this.outerRadius,
    required this.hoveredIndex,
    required this.pressedIndex,
    required this.focusedIndex,
    required this.activeOrder,
    required this.isCommandDisabled,
    required this.isCommandActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Zewnętrzna delikatna poświata tła koła
    final backdropPaint = Paint()
      ..color = AppColors.background.withValues(alpha: 0.72)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerRadius + 4.0, backdropPaint);

    for (int i = 0; i < _sliceCount; i++) {
      final command = TacticalRadialCommandType.values[i];
      final bool disabled = isCommandDisabled(command);
      final bool hovered = hoveredIndex == i;
      final bool pressed = pressedIndex == i;
      final bool focused = focusedIndex == i;
      final bool active = isCommandActive(command);

      final double sliceInner = innerRadius + 2.0;
      final double sliceOuter =
          outerRadius + (hovered && !disabled ? 6.0 : (pressed ? -2.0 : 0.0));

      final double startAngle = _startAngleOffset + i * _sliceSweep + _gapRadians / 2;
      const double sweepAngle = _sliceSweep - _gapRadians;

      final path = _buildSectorPath(
        center: center,
        innerR: sliceInner,
        outerR: sliceOuter,
        startAngle: startAngle,
        sweepAngle: sweepAngle,
      );

      Color fillColor;
      if (disabled) {
        fillColor = AppColors.background.withValues(alpha: 0.82);
      } else if (pressed) {
        fillColor = Color.lerp(
          AppColors.surfaceLight,
          command.accentColor,
          0.38,
        )!;
      } else if (hovered) {
        fillColor = Color.lerp(
          AppColors.surfaceLight,
          command.accentColor,
          0.22,
        )!;
      } else if (active) {
        fillColor = Color.lerp(
          AppColors.surface,
          command.accentColor,
          0.18,
        )!;
      } else {
        fillColor = AppColors.surface.withValues(alpha: 0.94);
      }

      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      Color borderColor;
      double borderWidth = 1.0;
      if (disabled) {
        borderColor = AppColors.cardBorder.withValues(alpha: 0.65);
      } else if (focused) {
        borderColor = AppColors.accentBlue;
        borderWidth = 2.0;
      } else if (hovered || pressed) {
        borderColor = command.accentColor;
        borderWidth = 1.8;
      } else if (active) {
        borderColor = AppColors.goldAccent;
        borderWidth = 1.5;
      } else {
        borderColor = AppTheme.borderColor;
      }

      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;
      canvas.drawPath(path, borderPaint);

      // Kropka aktywnego rozkazu na zewnętrznej krawędzi wycinka
      if (active && !disabled) {
        final double midAngle = startAngle + sweepAngle / 2;
        final dotCenter = Offset(
          center.dx + (sliceOuter - 7.0) * math.cos(midAngle),
          center.dy + (sliceOuter - 7.0) * math.sin(midAngle),
        );
        canvas.drawCircle(
          dotCenter,
          3.0,
          Paint()..color = AppColors.goldAccent,
        );
      }
    }
  }

  Path _buildSectorPath({
    required Offset center,
    required double innerR,
    required double outerR,
    required double startAngle,
    required double sweepAngle,
  }) {
    final outerRect = Rect.fromCircle(center: center, radius: outerR);
    final innerRect = Rect.fromCircle(center: center, radius: innerR);

    final path = Path()
      ..moveTo(
        center.dx + innerR * math.cos(startAngle),
        center.dy + innerR * math.sin(startAngle),
      )
      ..lineTo(
        center.dx + outerR * math.cos(startAngle),
        center.dy + outerR * math.sin(startAngle),
      )
      ..arcTo(outerRect, startAngle, sweepAngle, false)
      ..lineTo(
        center.dx + innerR * math.cos(startAngle + sweepAngle),
        center.dy + innerR * math.sin(startAngle + sweepAngle),
      )
      ..arcTo(innerRect, startAngle + sweepAngle, -sweepAngle, false)
      ..close();

    return path;
  }

  @override
  bool shouldRepaint(covariant _RadialCommandWheelPainter oldDelegate) {
    return oldDelegate.innerRadius != innerRadius ||
        oldDelegate.outerRadius != outerRadius ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.pressedIndex != pressedIndex ||
        oldDelegate.focusedIndex != focusedIndex ||
        oldDelegate.activeOrder != activeOrder;
  }
}
