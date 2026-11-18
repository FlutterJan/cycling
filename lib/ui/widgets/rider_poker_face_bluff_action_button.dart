import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/peloton/bluffing_and_poker_face_body_language.dart';

/// Zestaw danych telemetrii dla przycisku taktycznego `Blefuj Kryzys / Poker Face`
/// w menu rozkazów 3D.
class RiderPokerFaceBluffButtonData {
  final String riderId;
  final String riderName;
  final PokerFaceTacticMode activeTactic;
  final BluffDetectionOutcome outcome;
  final BodyLanguageCue activeCue;
  final double mentalFocusRemaining;
  final double deceptionSuccessProbability;
  final double sandbagChargeSeconds;
  final bool counterAttackWindowActive;
  final double counterAttackBonusPct;
  final bool hasDarkMirroredSunglasses;
  final bool isClimbActive;
  final String? radioTacticalNote;

  const RiderPokerFaceBluffButtonData({
    required this.riderId,
    required this.riderName,
    this.activeTactic = PokerFaceTacticMode.authentic,
    this.outcome = BluffDetectionOutcome.fooledCompletely,
    this.activeCue = BodyLanguageCue.steadySeatedSpin,
    this.mentalFocusRemaining = 100.0,
    this.deceptionSuccessProbability = 0.75,
    this.sandbagChargeSeconds = 0.0,
    this.counterAttackWindowActive = false,
    this.counterAttackBonusPct = 0.0,
    this.hasDarkMirroredSunglasses = false,
    this.isClimbActive = true,
    this.radioTacticalNote,
  });

  factory RiderPokerFaceBluffButtonData.fromState(
    BluffingAndPokerFaceState state,
  ) {
    return RiderPokerFaceBluffButtonData(
      riderId: state.riderProfile.riderId,
      riderName: state.riderProfile.riderName,
      activeTactic: state.activeTactic,
      outcome: state.lastResult.overallOutcome,
      activeCue: state.lastResult.activeCue,
      mentalFocusRemaining: state.mentalFocusRemaining,
      deceptionSuccessProbability: state.lastResult.deceptionSuccessProbability,
      sandbagChargeSeconds: state.sandbagChargeSeconds,
      counterAttackWindowActive: state.counterAttackWindowActive,
      counterAttackBonusPct: state.counterAttackBonusPct,
      hasDarkMirroredSunglasses: state.riderProfile.hasDarkMirroredSunglasses,
      isClimbActive: state.isClimbActive,
      radioTacticalNote: state.lastResult.radioTacticalNote,
    );
  }

  bool get isBluffActive => activeTactic != PokerFaceTacticMode.authentic;

  bool get hasEnoughFocusToStartBluff => mentalFocusRemaining >= 6.0;
}

/// Przycisk taktyczny `Blefuj Kryzys / Poker Face` przeznaczony do menu rozkazów 3D.
///
/// Obsługuje szybkie włączenie/wyłączenie blefu jednym kliknięciem, rozwijany
/// selektor 4 trybów mowy ciała (`PokerFaceTacticMode`), przycisk natychmiastowego
/// kontrataku po połknięciu przynęty Sandbaggingu, przełącznik ciemnych okularów
/// oraz pełne stany `hover`, `active`, `disabled` i `focus` w palecie [AppColors].
class RiderPokerFaceBluffActionButton extends StatefulWidget {
  final RiderPokerFaceBluffButtonData data;
  final bool enabled;
  final bool initiallyExpanded;
  final bool compact;
  final ValueChanged<PokerFaceTacticMode>? onSelectTactic;
  final VoidCallback? onTriggerCounterAttack;
  final VoidCallback? onToggleSunglasses;

  const RiderPokerFaceBluffActionButton({
    super.key,
    required this.data,
    this.enabled = true,
    this.initiallyExpanded = false,
    this.compact = false,
    this.onSelectTactic,
    this.onTriggerCounterAttack,
    this.onToggleSunglasses,
  });

  @override
  State<RiderPokerFaceBluffActionButton> createState() =>
      _RiderPokerFaceBluffActionButtonState();
}

class _RiderPokerFaceBluffActionButtonState
    extends State<RiderPokerFaceBluffActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late bool _isExpanded;
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;
  PokerFaceTacticMode _preferredBluffMode =
      PokerFaceTacticMode.sandbaggingPlayDead;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    if (widget.data.isBluffActive) {
      _preferredBluffMode = widget.data.activeTactic;
    }
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _syncPulseAnimation();
  }

  @override
  void didUpdateWidget(covariant RiderPokerFaceBluffActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data.isBluffActive) {
      _preferredBluffMode = widget.data.activeTactic;
    }
    if (oldWidget.data.isBluffActive != widget.data.isBluffActive ||
        oldWidget.data.counterAttackWindowActive !=
            widget.data.counterAttackWindowActive ||
        oldWidget.enabled != widget.enabled) {
      _syncPulseAnimation();
    }
  }

  void _syncPulseAnimation() {
    final shouldPulse = widget.enabled &&
        widget.data.isClimbActive &&
        (widget.data.isBluffActive || widget.data.counterAttackWindowActive);
    if (shouldPulse) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
      }
      _pulseController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  bool get _canInteract {
    if (!widget.enabled || !widget.data.isClimbActive) return false;
    if (!widget.data.isBluffActive && !widget.data.hasEnoughFocusToStartBluff) {
      return false;
    }
    return true;
  }

  String? get _disabledReason {
    if (!widget.enabled) return 'Rozkaz chwilowo zablokowany';
    if (!widget.data.isClimbActive) return 'Dostępne tylko na podjeździe';
    if (!widget.data.isBluffActive && !widget.data.hasEnoughFocusToStartBluff) {
      return 'Zbyt niski fokus mentalny (<6%)';
    }
    return null;
  }

  Color _accentForMode(PokerFaceTacticMode mode) {
    switch (mode) {
      case PokerFaceTacticMode.authentic:
        return AppColors.textSecondary;
      case PokerFaceTacticMode.pokerFaceHideCrisis:
        return AppColors.cyanAccent;
      case PokerFaceTacticMode.sandbaggingPlayDead:
        return AppColors.goldAccent;
      case PokerFaceTacticMode.bluffShowOfStrength:
        return AppColors.primaryAccent;
    }
  }

  IconData _iconForMode(PokerFaceTacticMode mode) {
    switch (mode) {
      case PokerFaceTacticMode.authentic:
        return Icons.psychology_outlined;
      case PokerFaceTacticMode.pokerFaceHideCrisis:
        return Icons.visibility_off_rounded;
      case PokerFaceTacticMode.sandbaggingPlayDead:
        return Icons.theater_comedy_rounded;
      case PokerFaceTacticMode.bluffShowOfStrength:
        return Icons.bolt_rounded;
    }
  }

  Color _outcomeColor(BluffDetectionOutcome outcome) {
    switch (outcome) {
      case BluffDetectionOutcome.fooledCompletely:
        return AppColors.statusSuccess;
      case BluffDetectionOutcome.partiallySuspicious:
        return AppColors.amberWarning;
      case BluffDetectionOutcome.bluffSeenThrough:
        return AppColors.crimsonAlert;
      case BluffDetectionOutcome.counterAttackBaited:
        return AppColors.goldAccent;
    }
  }

  void _handlePrimaryTap() {
    if (!_canInteract) return;
    final nextMode = widget.data.isBluffActive
        ? PokerFaceTacticMode.authentic
        : _preferredBluffMode;
    widget.onSelectTactic?.call(nextMode);
  }

  void _handleSelectMode(PokerFaceTacticMode mode) {
    if (!widget.enabled || !widget.data.isClimbActive) return;
    if (mode != PokerFaceTacticMode.authentic &&
        !widget.data.hasEnoughFocusToStartBluff) {
      return;
    }
    if (mode != PokerFaceTacticMode.authentic) {
      _preferredBluffMode = mode;
    }
    widget.onSelectTactic?.call(mode);
  }

  @override
  Widget build(BuildContext context) {
    final activeMode = widget.data.activeTactic;
    final accent = widget.data.isBluffActive
        ? _accentForMode(activeMode)
        : AppColors.goldAccent;
    final focusPct = widget.data.mentalFocusRemaining.clamp(0.0, 100.0);
    final deceptionPct =
        (widget.data.deceptionSuccessProbability * 100.0).clamp(0.0, 100.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = widget.compact || constraints.maxWidth < 360;

        return FocusableActionDetector(
          enabled: _canInteract,
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
                _handlePrimaryTap();
                return null;
              },
            ),
          },
          child: MouseRegion(
            cursor: _canInteract
                ? SystemMouseCursors.click
                : SystemMouseCursors.forbidden,
            onEnter: (_) {
              if (!_isHovered) setState(() => _isHovered = true);
            },
            onExit: (_) {
              if (_isHovered || _isPressed) {
                setState(() {
                  _isHovered = false;
                  _isPressed = false;
                });
              }
            },
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final pulse = _pulseController.value;
                final borderColor = !_canInteract
                    ? AppTheme.borderColor.withValues(alpha: 0.6)
                    : _isFocused
                        ? AppColors.goldAccent
                        : widget.data.isBluffActive
                            ? accent.withValues(alpha: 0.65 + pulse * 0.35)
                            : _isHovered
                                ? accent.withValues(alpha: 0.75)
                                : AppTheme.borderColor;

                final bgColor = !_canInteract
                    ? AppColors.surface.withValues(alpha: 0.65)
                    : _isPressed
                        ? AppColors.surfaceLight
                        : _isHovered
                            ? AppColors.surfaceLight.withValues(alpha: 0.92)
                            : AppColors.surface;

                return AnimatedScale(
                  scale: _isPressed && _canInteract ? 0.985 : 1.0,
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOutCubic,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: borderColor,
                        width: _isFocused ? 2.0 : 1.0,
                      ),
                      boxShadow: widget.data.isBluffActive && _canInteract
                          ? [
                              BoxShadow(
                                color: accent.withValues(
                                  alpha: 0.14 + pulse * 0.14,
                                ),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: Opacity(
                        opacity: _canInteract ? 1.0 : 0.55,
                        child: Padding(
                          padding: EdgeInsets.all(isNarrow ? 12 : 14),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeaderRow(
                                isNarrow: isNarrow,
                                accent: accent,
                                focusPct: focusPct,
                                deceptionPct: deceptionPct,
                              ),
                              if (_disabledReason != null) ...[
                                const SizedBox(height: 8),
                                _buildDisabledBanner(_disabledReason!),
                              ] else ...[
                                const SizedBox(height: 10),
                                _buildFocusAndStatusStrip(
                                  isNarrow: isNarrow,
                                  accent: accent,
                                  focusPct: focusPct,
                                  deceptionPct: deceptionPct,
                                ),
                              ],
                              if (widget.data.counterAttackWindowActive &&
                                  _canInteract) ...[
                                const SizedBox(height: 10),
                                _buildCounterAttackBanner(isNarrow: isNarrow),
                              ],
                              AnimatedCrossFade(
                                firstChild: const SizedBox.shrink(),
                                secondChild: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: _buildExpandedModeSelector(
                                    isNarrow: isNarrow,
                                  ),
                                ),
                                crossFadeState: _isExpanded
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                duration: const Duration(milliseconds: 240),
                                sizeCurve: Curves.easeOutCubic,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderRow({
    required bool isNarrow,
    required Color accent,
    required double focusPct,
    required double deceptionPct,
  }) {
    final activeMode = widget.data.activeTactic;
    final isActive = widget.data.isBluffActive;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTapDown: (_) {
            if (_canInteract) setState(() => _isPressed = true);
          },
          onTapUp: (_) {
            if (_isPressed) setState(() => _isPressed = false);
          },
          onTapCancel: () {
            if (_isPressed) setState(() => _isPressed = false);
          },
          onTap: _handlePrimaryTap,
          child: Container(
            width: isNarrow ? 38 : 42,
            height: isNarrow ? 38 : 42,
            decoration: BoxDecoration(
              color: (isActive ? accent : AppColors.surfaceLight)
                  .withValues(alpha: isActive ? 0.20 : 1.0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? accent.withValues(alpha: 0.75)
                    : AppColors.cardBorder,
                width: 1.0,
              ),
            ),
            child: Icon(
              _iconForMode(activeMode),
              size: isNarrow ? 20 : 22,
              color: isActive ? accent : AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) {
              if (_canInteract) setState(() => _isPressed = true);
            },
            onTapUp: (_) {
              if (_isPressed) setState(() => _isPressed = false);
            },
            onTapCancel: () {
              if (_isPressed) setState(() => _isPressed = false);
            },
            onTap: _handlePrimaryTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Blefuj Kryzys / Poker Face',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: isNarrow ? 13 : 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildTagPill(
                      label: activeMode.shortTag,
                      color: accent,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isActive
                      ? activeMode.label
                      : 'Kliknij, aby zamaskować kryzys lub wciągnąć rywali w pułapkę',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    letterSpacing: -0.1,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Tooltip(
          message: _isExpanded ? 'Zwiń tryby blefu' : 'Wybierz tryb blefu',
          child: InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderColor, width: 1.0),
              ),
              child: AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFocusAndStatusStrip({
    required bool isNarrow,
    required Color accent,
    required double focusPct,
    required double deceptionPct,
  }) {
    final outcomeColor = _outcomeColor(widget.data.outcome);
    final focusColor = focusPct >= 45
        ? AppColors.statusSuccess
        : focusPct >= 20
            ? AppColors.amberWarning
            : AppColors.crimsonAlert;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: focusPct / 100.0,
            minHeight: 5,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(focusColor),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildMetricChip(
              icon: Icons.psychology_rounded,
              label: 'Fokus ${focusPct.round()}%',
              color: focusColor,
            ),
            _buildMetricChip(
              icon: Icons.shield_moon_rounded,
              label: 'Wiarygodność ${deceptionPct.round()}%',
              color: accent,
            ),
            if (!isNarrow || widget.data.isBluffActive)
              _buildMetricChip(
                icon: Icons.remove_red_eye_rounded,
                label: widget.data.outcome.label,
                color: outcomeColor,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDisabledBanner(String reason) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              reason,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterAttackBanner({required bool isNarrow}) {
    final bonus = widget.data.counterAttackBonusPct.toStringAsFixed(1);
    return InkWell(
      onTap: widget.onTriggerCounterAttack,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isNarrow ? 10 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.goldAccent.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.goldAccent.withValues(alpha: 0.85),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.flash_on_rounded,
              size: 18,
              color: AppColors.goldAccent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'OKNO KONTRATAKU! +$bonus% mocy zaskoczenia',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.goldAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'ATAKUJ',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.background,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedModeSelector({required bool isNarrow}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tryb mowy ciała na podjeździe',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (widget.onToggleSunglasses != null)
                InkWell(
                  onTap: _canInteract ? widget.onToggleSunglasses : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.data.hasDarkMirroredSunglasses
                          ? AppColors.cyanAccent.withValues(alpha: 0.16)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.data.hasDarkMirroredSunglasses
                            ? AppColors.cyanAccent.withValues(alpha: 0.7)
                            : AppTheme.borderColor,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.dark_mode_rounded,
                          size: 13,
                          color: widget.data.hasDarkMirroredSunglasses
                              ? AppColors.cyanAccent
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.data.hasDarkMirroredSunglasses
                              ? 'Lustrzanki ON'
                              : 'Lustrzanki OFF',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: widget.data.hasDarkMirroredSunglasses
                                ? AppColors.cyanAccent
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: PokerFaceTacticMode.values.map((mode) {
              final selected = widget.data.activeTactic == mode;
              final modeColor = _accentForMode(mode);
              final modeAllowed = _canInteract ||
                  (widget.enabled &&
                      widget.data.isClimbActive &&
                      mode == PokerFaceTacticMode.authentic);
              return InkWell(
                onTap: modeAllowed ? () => _handleSelectMode(mode) : null,
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 8 : 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? modeColor.withValues(alpha: 0.20)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? modeColor
                          : AppTheme.borderColor,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconForMode(mode),
                        size: 14,
                        color: selected ? modeColor : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        mode.shortTag,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            widget.data.activeTactic.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              height: 1.35,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagPill({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Wersja przycisku [RiderPokerFaceBluffActionButton] podpięta bezpośrednio
/// do kontrolera Riverpod [bluffingAndPokerFaceProvider] dla menu rozkazów 3D.
class RiderPokerFaceBluffCommandButton extends ConsumerWidget {
  final bool enabled;
  final bool initiallyExpanded;
  final bool compact;
  final ValueChanged<String>? onCounterAttackMessage;

  const RiderPokerFaceBluffCommandButton({
    super.key,
    this.enabled = true,
    this.initiallyExpanded = false,
    this.compact = false,
    this.onCounterAttackMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bluffState = ref.watch(bluffingAndPokerFaceProvider);
    final notifier = ref.read(bluffingAndPokerFaceProvider.notifier);

    return RiderPokerFaceBluffActionButton(
      data: RiderPokerFaceBluffButtonData.fromState(bluffState),
      enabled: enabled,
      initiallyExpanded: initiallyExpanded,
      compact: compact,
      onSelectTactic: notifier.selectTactic,
      onToggleSunglasses: notifier.toggleSunglasses,
      onTriggerCounterAttack: () {
        final msg = notifier.triggerCounterAttack();
        onCounterAttackMessage?.call(msg);
      },
    );
  }
}
