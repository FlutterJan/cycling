// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/peloton/team_radio_voice_synthesis_and_chatter.dart';

/// Typ układu responsywnego dla szklanego dymka połączenia radiowego.
enum RadioBubbleLayoutTier {
  mobile,
  tablet,
  desktop,
}

/// Szklany dymek połączenia radiowego z animowaną falą głosową i przyciskami szybkiej decyzji.
///
/// Przeznaczony do wyświetlania w HUD wyścigu 3D jako interaktywne połączenie
/// między kolarzem na trasie a Dyrektorem Sportowym.
class InteractiveRadioCallBubbleHud extends StatefulWidget {
  final TeamRadioChatterEvent? event;
  final double currentElapsedSeconds;
  final bool isMuted;
  final bool isDisabled;
  final ValueChanged<RadioInitiativeOption>? onDecisionSelected;
  final VoidCallback? onDismiss;
  final VoidCallback? onToggleMute;
  final VoidCallback? onAcknowledge;

  const InteractiveRadioCallBubbleHud({
    super.key,
    required this.event,
    this.currentElapsedSeconds = 0.0,
    this.isMuted = false,
    this.isDisabled = false,
    this.onDecisionSelected,
    this.onDismiss,
    this.onToggleMute,
    this.onAcknowledge,
  });

  @override
  State<InteractiveRadioCallBubbleHud> createState() =>
      _InteractiveRadioCallBubbleHudState();
}

class _InteractiveRadioCallBubbleHudState
    extends State<InteractiveRadioCallBubbleHud>
    with TickerProviderStateMixin {
  late final AnimationController _waveController;
  late final AnimationController _pulseController;
  late final AnimationController _entranceController;
  late final Animation<double> _entranceAnimation;

  String? _hoveredHeaderAction;
  String? _pressedHeaderAction;
  String? _focusedHeaderAction;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    if (widget.event != null) {
      _entranceController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant InteractiveRadioCallBubbleHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.event != null && oldWidget.event?.id != widget.event?.id) {
      _entranceController.forward(from: 0.0);
    } else if (widget.event == null && oldWidget.event != null) {
      _entranceController.reverse();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  RadioBubbleLayoutTier _resolveLayoutTier(double width) {
    if (width < 600) return RadioBubbleLayoutTier.mobile;
    if (width < 1150) return RadioBubbleLayoutTier.tablet;
    return RadioBubbleLayoutTier.desktop;
  }

  double _resolveMaxBubbleWidth(double availableWidth, RadioBubbleLayoutTier tier) {
    switch (tier) {
      case RadioBubbleLayoutTier.mobile:
        return math.max(260.0, availableWidth - 16.0);
      case RadioBubbleLayoutTier.tablet:
        return math.min(480.0, availableWidth - 24.0);
      case RadioBubbleLayoutTier.desktop:
        return math.min(540.0, availableWidth - 32.0);
    }
  }

  double? _computeRemainingFraction(TeamRadioChatterEvent event) {
    final expiresAt = event.decisionExpiresAtSeconds;
    if (expiresAt == null) return null;
    final totalWindow = math.max(10.0, expiresAt - event.elapsedSeconds);
    final remaining = (expiresAt - widget.currentElapsedSeconds).clamp(0.0, totalWindow);
    return (remaining / totalWindow).clamp(0.0, 1.0);
  }

  KeyEventResult _handleBubbleKeyEvent(
    FocusNode node,
    KeyEvent keyEvent,
    TeamRadioChatterEvent event,
  ) {
    if (widget.isDisabled || keyEvent is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (keyEvent.logicalKey == LogicalKeyboardKey.escape) {
      widget.onDismiss?.call();
      return KeyEventResult.handled;
    }

    final digitKeys = <LogicalKeyboardKey>[
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
    ];
    for (int i = 0; i < digitKeys.length; i++) {
      if (keyEvent.logicalKey == digitKeys[i] && i < event.options.length) {
        widget.onDecisionSelected?.call(event.options[i]);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    if (event == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final tier = _resolveLayoutTier(availableWidth);
        final maxBubbleWidth = _resolveMaxBubbleWidth(availableWidth, tier);
        final urgencyColor = event.urgency.color;
        final remainingFraction = _computeRemainingFraction(event);

        return Focus(
          onKeyEvent: (node, keyEvent) => _handleBubbleKeyEvent(node, keyEvent, event),
          child: FadeTransition(
            opacity: _entranceAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(_entranceAnimation),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxBubbleWidth,
                  minWidth: math.min(260.0, maxBubbleWidth),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.surfaceLight.withValues(alpha: 0.84),
                            AppColors.surface.withValues(alpha: 0.90),
                            AppColors.background.withValues(alpha: 0.94),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: urgencyColor.withValues(
                            alpha: widget.isDisabled ? 0.25 : 0.60,
                          ),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: urgencyColor.withValues(alpha: 0.16),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Opacity(
                        opacity: widget.isDisabled ? 0.62 : 1.0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (remainingFraction != null)
                              _buildCountdownBar(remainingFraction, urgencyColor),
                            Padding(
                              padding: EdgeInsets.all(
                                tier == RadioBubbleLayoutTier.mobile ? 12 : 14,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildHeader(event, urgencyColor, tier),
                                  const SizedBox(height: 10),
                                  _buildWaveformCard(event, urgencyColor, tier),
                                  const SizedBox(height: 10),
                                  _buildDialogueSection(event, tier),
                                  const SizedBox(height: 12),
                                  _buildDecisionActions(event, urgencyColor, tier),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCountdownBar(double fraction, Color urgencyColor) {
    final barColor = fraction < 0.28 ? AppColors.crimsonAlert : urgencyColor;
    return SizedBox(
      height: 3,
      child: Stack(
        children: [
          Container(color: AppTheme.borderColor.withValues(alpha: 0.6)),
          FractionallySizedBox(
            widthFactor: fraction,
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [barColor, AppColors.goldAccent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    TeamRadioChatterEvent event,
    Color urgencyColor,
    RadioBubbleLayoutTier tier,
  ) {
    final isCompact = tier == RadioBubbleLayoutTier.mobile;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final pulseScale =
                widget.isMuted || widget.isDisabled ? 1.0 : 1.0 + (_pulseController.value * 0.12);
            return Transform.scale(
              scale: pulseScale,
              child: Container(
                width: isCompact ? 34 : 38,
                height: isCompact ? 34 : 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: urgencyColor.withValues(alpha: 0.18),
                  border: Border.all(
                    color: urgencyColor.withValues(alpha: 0.7),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  widget.isMuted
                      ? Icons.headset_off_rounded
                      : Icons.headset_mic_rounded,
                  size: isCompact ? 17 : 19,
                  color: widget.isMuted ? AppColors.textSecondary : urgencyColor,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    event.riderName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  _buildTagPill(
                    label: event.scenario.label.toUpperCase(),
                    color: urgencyColor,
                  ),
                  if (!isCompact)
                    _buildTagPill(
                      label: event.tone.label,
                      color: AppColors.accentBlue,
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 8,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    event.teamName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      letterSpacing: -0.1,
                    ),
                  ),
                  Text(
                    event.formattedKm,
                    style: AppTheme.statNumberStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldAccent,
                    ),
                  ),
                  Text(
                    event.formattedTime,
                    style: AppTheme.statNumberStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onToggleMute != null)
              _buildHeaderIconButton(
                id: 'mute',
                icon: widget.isMuted
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                tooltip: widget.isMuted ? 'Włącz dźwięk radia' : 'Wycisz radio',
                activeColor:
                    widget.isMuted ? AppColors.amberWarning : AppColors.textSecondary,
                onTap: widget.isDisabled ? null : widget.onToggleMute,
              ),
            if (widget.onDismiss != null) ...[
              const SizedBox(width: 4),
              _buildHeaderIconButton(
                id: 'dismiss',
                icon: Icons.close_rounded,
                tooltip: 'Zamknij dymek radia (Esc)',
                activeColor: AppColors.textSecondary,
                onTap: widget.isDisabled ? null : widget.onDismiss,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTagPill({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required String id,
    required IconData icon,
    required String tooltip,
    required Color activeColor,
    required VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;
    final isHovered = _hoveredHeaderAction == id;
    final isPressed = _pressedHeaderAction == id;
    final isFocused = _focusedHeaderAction == id;

    return Tooltip(
      message: tooltip,
      child: Focus(
        canRequestFocus: !isDisabled,
        onFocusChange: (focused) {
          setState(() {
            _focusedHeaderAction = focused ? id : (_focusedHeaderAction == id ? null : _focusedHeaderAction);
          });
        },
        onKeyEvent: (node, keyEvent) {
          if (!isDisabled &&
              keyEvent is KeyDownEvent &&
              (keyEvent.logicalKey == LogicalKeyboardKey.enter ||
                  keyEvent.logicalKey == LogicalKeyboardKey.space)) {
            onTap();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: MouseRegion(
          cursor: isDisabled
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hoveredHeaderAction = id),
          onExit: (_) => setState(() {
            if (_hoveredHeaderAction == id) _hoveredHeaderAction = null;
            if (_pressedHeaderAction == id) _pressedHeaderAction = null;
          }),
          child: GestureDetector(
            onTapDown: isDisabled
                ? null
                : (_) => setState(() => _pressedHeaderAction = id),
            onTapUp: isDisabled
                ? null
                : (_) => setState(() => _pressedHeaderAction = null),
            onTapCancel: () => setState(() => _pressedHeaderAction = null),
            onTap: onTap,
            child: AnimatedScale(
              scale: isPressed ? 0.92 : 1.0,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isHovered
                      ? AppColors.surfaceLight
                      : AppColors.background.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isFocused
                        ? AppColors.goldAccent
                        : isHovered
                            ? AppColors.textSecondary.withValues(alpha: 0.6)
                            : AppTheme.borderColor,
                    width: isFocused ? 1.5 : 1.0,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: isDisabled
                      ? AppColors.textSecondary.withValues(alpha: 0.4)
                      : isHovered
                          ? AppColors.textPrimary
                          : activeColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaveformCard(
    TeamRadioChatterEvent event,
    Color urgencyColor,
    RadioBubbleLayoutTier tier,
  ) {
    final profile = event.voiceProfile;
    final waveformHeight = tier == RadioBubbleLayoutTier.mobile ? 32.0 : 40.0;
    final staticPercent = (profile.rfStaticLevel * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: waveformHeight,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, _) {
                return CustomPaint(
                  painter: RadioVoiceWaveformPainter(
                    bars: profile.waveformBars,
                    phase: _waveController.value,
                    primaryColor: widget.isMuted
                        ? AppColors.textSecondary.withValues(alpha: 0.45)
                        : urgencyColor,
                    secondaryColor: widget.isMuted
                        ? AppColors.textSecondary.withValues(alpha: 0.25)
                        : AppColors.goldAccent,
                    speechRateMultiplier: profile.speechRateMultiplier,
                    rfStaticLevel: profile.rfStaticLevel,
                    isMuted: widget.isMuted || widget.isDisabled,
                  ),
                );
              },
            ),
          ),
          if (tier != RadioBubbleLayoutTier.mobile) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isMuted ? 'AUDIO WYCISZONE' : 'LIVE KANAŁ DS • RX',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: widget.isMuted
                        ? AppColors.amberWarning
                        : AppColors.cyanAccent,
                    letterSpacing: 0.4,
                  ),
                ),
                Flexible(
                  child: Text(
                    '${profile.pitchHz.round()} Hz • ${profile.speechRateMultiplier.toStringAsFixed(2)}x • RF $staticPercent%',
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.statNumberStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDialogueSection(
    TeamRadioChatterEvent event,
    RadioBubbleLayoutTier tier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          event.headline,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.goldAccent,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '„${event.dialogueText}”',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: tier == RadioBubbleLayoutTier.mobile ? 12.5 : 13.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
            height: 1.38,
            letterSpacing: -0.15,
          ),
        ),
        if (event.dsPromptQuestion != null &&
            event.dsPromptQuestion!.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.record_voice_over_rounded,
                size: 14,
                color: AppColors.cyanAccent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.dsPromptQuestion!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cyanAccent,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDecisionActions(
    TeamRadioChatterEvent event,
    Color urgencyColor,
    RadioBubbleLayoutTier tier,
  ) {
    if (event.isResolved && event.selectedOption != null) {
      final selected = event.selectedOption!;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.statusSuccess.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.statusSuccess.withValues(alpha: 0.55),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: AppColors.statusSuccess,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Decyzja DS: ${selected.label} — ${selected.tacticalSummary}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (event.options.isEmpty) {
      const ackOption = RadioInitiativeOption(
        id: 'ack_default',
        decisionType: RadioInitiativeDecisionType.acknowledge,
        label: 'Przyjęto — kontynuuj plan',
        dsResponseText: 'Przyjęto, trzymaj się planu etapowego.',
        tacticalSummary: 'Potwierdzenie odbioru komunikatu',
        isRecommended: true,
      );
      return _RadioQuickDecisionButton(
        option: ackOption,
        shortcutIndex: 1,
        showShortcutHint: tier == RadioBubbleLayoutTier.desktop,
        accentColor: urgencyColor,
        isDisabled: widget.isDisabled,
        onPressed: () {
          if (widget.onAcknowledge != null) {
            widget.onAcknowledge!();
          } else {
            widget.onDecisionSelected?.call(ackOption);
          }
        },
      );
    }

    if (tier == RadioBubbleLayoutTier.mobile) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < event.options.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _RadioQuickDecisionButton(
              option: event.options[i],
              shortcutIndex: i + 1,
              showShortcutHint: false,
              accentColor: urgencyColor,
              isDisabled: widget.isDisabled,
              onPressed: () => widget.onDecisionSelected?.call(event.options[i]),
            ),
          ],
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < event.options.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _RadioQuickDecisionButton(
            option: event.options[i],
            shortcutIndex: i + 1,
            showShortcutHint: tier == RadioBubbleLayoutTier.desktop,
            accentColor: urgencyColor,
            isDisabled: widget.isDisabled,
            onPressed: () => widget.onDecisionSelected?.call(event.options[i]),
          ),
        ],
      ],
    );
  }
}

class _RadioQuickDecisionButton extends StatefulWidget {
  final RadioInitiativeOption option;
  final int shortcutIndex;
  final bool showShortcutHint;
  final Color accentColor;
  final bool isDisabled;
  final VoidCallback onPressed;

  const _RadioQuickDecisionButton({
    required this.option,
    required this.shortcutIndex,
    required this.showShortcutHint,
    required this.accentColor,
    required this.isDisabled,
    required this.onPressed,
  });

  @override
  State<_RadioQuickDecisionButton> createState() =>
      _RadioQuickDecisionButtonState();
}

class _RadioQuickDecisionButtonState extends State<_RadioQuickDecisionButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  Color _decisionColor(RadioInitiativeDecisionType type) {
    switch (type) {
      case RadioInitiativeDecisionType.approveInitiative:
        return AppColors.statusSuccess;
      case RadioInitiativeDecisionType.holdPosition:
        return AppColors.amberWarning;
      case RadioInitiativeDecisionType.counterOrder:
        return AppColors.accentBlue;
      case RadioInitiativeDecisionType.acknowledge:
        return AppColors.goldAccent;
    }
  }

  IconData _decisionIcon(RadioInitiativeDecisionType type) {
    switch (type) {
      case RadioInitiativeDecisionType.approveInitiative:
        return Icons.bolt_rounded;
      case RadioInitiativeDecisionType.holdPosition:
        return Icons.pan_tool_alt_rounded;
      case RadioInitiativeDecisionType.counterOrder:
        return Icons.swap_horiz_rounded;
      case RadioInitiativeDecisionType.acknowledge:
        return Icons.check_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final option = widget.option;
    final badgeColor = _decisionColor(option.decisionType);
    final isDisabled = widget.isDisabled;

    final Color bgColor;
    if (isDisabled) {
      bgColor = AppColors.surface.withValues(alpha: 0.45);
    } else if (_isPressed) {
      bgColor = badgeColor.withValues(alpha: 0.24);
    } else if (_isHovered) {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.95);
    } else if (option.isRecommended) {
      bgColor = badgeColor.withValues(alpha: 0.12);
    } else {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.65);
    }

    final Color borderColor;
    if (isDisabled) {
      borderColor = AppTheme.borderColor.withValues(alpha: 0.5);
    } else if (_isFocused) {
      borderColor = AppColors.goldAccent;
    } else if (_isHovered || _isPressed) {
      borderColor = badgeColor;
    } else if (option.isRecommended) {
      borderColor = badgeColor.withValues(alpha: 0.65);
    } else {
      borderColor = AppTheme.borderColor;
    }

    return Focus(
      canRequestFocus: !isDisabled,
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      onKeyEvent: (node, keyEvent) {
        if (!isDisabled &&
            keyEvent is KeyDownEvent &&
            (keyEvent.logicalKey == LogicalKeyboardKey.enter ||
                keyEvent.logicalKey == LogicalKeyboardKey.space)) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: isDisabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: GestureDetector(
          onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
          onTapUp: isDisabled ? null : (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: isDisabled ? null : widget.onPressed,
          child: AnimatedScale(
            scale: _isPressed && !isDisabled ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: _isFocused ? 1.6 : 1.0,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _decisionIcon(option.decisionType),
                      size: 16,
                      color: isDisabled
                          ? AppColors.textSecondary.withValues(alpha: 0.5)
                          : badgeColor,
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
                            Expanded(
                              child: Text(
                                option.label,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDisabled
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                  letterSpacing: -0.15,
                                ),
                              ),
                            ),
                            if (option.isRecommended)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.goldAccent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppColors.goldAccent.withValues(alpha: 0.6),
                                    width: 0.7,
                                  ),
                                ),
                                child: const Text(
                                  'POLECANE',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.goldAccent,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${option.tacticalSummary} • ${option.staminaCostHint}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.showShortcutHint && widget.shortcutIndex <= 3) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.borderColor, width: 0.8),
                      ),
                      child: Text(
                        '${widget.shortcutIndex}',
                        style: AppTheme.statNumberStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rysownik animowanej fali głosowej radia wyścigowego na podstawie profilu syntezy.
class RadioVoiceWaveformPainter extends CustomPainter {
  final List<double> bars;
  final double phase;
  final Color primaryColor;
  final Color secondaryColor;
  final double speechRateMultiplier;
  final double rfStaticLevel;
  final bool isMuted;

  const RadioVoiceWaveformPainter({
    required this.bars,
    required this.phase,
    required this.primaryColor,
    required this.secondaryColor,
    required this.speechRateMultiplier,
    required this.rfStaticLevel,
    required this.isMuted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final effectiveBars = bars.isEmpty
        ? const <double>[0.25, 0.55, 0.8, 0.45, 0.9, 0.6, 0.35, 0.7, 0.5, 0.3]
        : bars;
    final count = effectiveBars.length;
    final centerY = size.height / 2;

    // Linia odniesienia fali
    final baselinePaint = Paint()
      ..color = AppTheme.borderColor.withValues(alpha: 0.55)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), baselinePaint);

    final slotWidth = size.width / count;
    final barWidth = math.max(2.0, math.min(5.0, slotWidth * 0.58));

    for (int i = 0; i < count; i++) {
      final baseAmp = effectiveBars[i].clamp(0.08, 1.0);
      final double animatedAmp;
      if (isMuted) {
        animatedAmp = 0.12 + (baseAmp * 0.14);
      } else {
        final wave = math.sin((phase * math.pi * 2 * speechRateMultiplier) + (i * 0.65));
        final staticJitter =
            rfStaticLevel * 0.14 * math.cos((phase * math.pi * 6) + (i * 1.7));
        animatedAmp = (baseAmp * (0.62 + 0.38 * wave.abs()) + staticJitter.abs())
            .clamp(0.10, 1.0);
      }

      final barHeight = math.max(4.0, animatedAmp * (size.height - 4.0));
      final x = (i * slotWidth) + (slotWidth - barWidth) / 2;
      final top = centerY - barHeight / 2;

      final t = count <= 1 ? 0.5 : i / (count - 1);
      final color = Color.lerp(primaryColor, secondaryColor, t) ?? primaryColor;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );
      final paint = Paint()
        ..color = color.withValues(alpha: isMuted ? 0.4 : 0.92)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant RadioVoiceWaveformPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.isMuted != isMuted ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.bars != bars;
  }
}

/// Warstwa HUD podpięta pod `teamRadioChatterProvider`, wyświetlająca aktywny dymek
/// połączenia radiowego z obsługą decyzji DS i wyciszenia.
class InteractiveRadioCallBubbleOverlay extends ConsumerWidget {
  final double currentElapsedSeconds;
  final bool isDisabled;
  final ValueChanged<RadioDecisionResolution>? onDecisionResolved;

  const InteractiveRadioCallBubbleOverlay({
    super.key,
    required this.currentElapsedSeconds,
    this.isDisabled = false,
    this.onDecisionResolved,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radioState = ref.watch(teamRadioChatterProvider);
    final notifier = ref.read(teamRadioChatterProvider.notifier);
    final active = radioState.activeInitiative;

    if (active == null) {
      return const SizedBox.shrink();
    }

    return InteractiveRadioCallBubbleHud(
      event: active,
      currentElapsedSeconds: currentElapsedSeconds,
      isMuted: radioState.isMuted,
      isDisabled: isDisabled,
      onToggleMute: notifier.toggleMute,
      onDismiss: notifier.dismissActiveInitiative,
      onDecisionSelected: (option) {
        final resolution = notifier.decideActiveInitiative(
          option.id,
          currentElapsedSeconds: currentElapsedSeconds,
        );
        if (resolution != null) {
          onDecisionResolved?.call(resolution);
        }
      },
    );
  }
}
