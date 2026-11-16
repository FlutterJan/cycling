import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Poziom obciążenia termicznego kolarza na podstawie temperatury głębokiej ciała.
enum ThermoregulationThermalLevel {
  /// Normotermia i umiarkowany wysiłek (<= 38.0 °C).
  optimal,

  /// Podwyższona temperatura wysiłkowa (38.0 °C - 38.8 °C).
  elevated,

  /// Wysoki stres cieplny (> 38.8 °C do 39.2 °C) — kolor pomarańczowy.
  warning,

  /// Hipertermia krytyczna (> 39.2 °C) — kolor czerwony.
  critical;

  String get labelPl {
    switch (this) {
      case ThermoregulationThermalLevel.optimal:
        return 'Norma';
      case ThermoregulationThermalLevel.elevated:
        return 'Wysiłek';
      case ThermoregulationThermalLevel.warning:
        return 'Przegrzanie';
      case ThermoregulationThermalLevel.critical:
        return 'Hipertermia';
    }
  }
}

/// Poziom nawodnienia organizmu kolarza w trakcie etapu.
enum HydrationStatusLevel {
  /// Optymalne nawodnienie (>= 70%).
  optimal,

  /// Umiarkowane odwodnienie (40% - 69%).
  moderate,

  /// Krytyczne odwodnienie (< 40%).
  dehydrated;

  String get labelPl {
    switch (this) {
      case HydrationStatusLevel.optimal:
        return 'Optymalne';
      case HydrationStatusLevel.moderate:
        return 'Niskie';
      case HydrationStatusLevel.dehydrated:
        return 'Krytyczne';
    }
  }
}

/// Wskaźnik termoregulacji i nawodnienia dla karty kolarza w wyścigu 3D.
///
/// Prezentuje:
/// - temperaturę głęboką ciała z ikoną termometru zmieniającą kolor na
///   pomarańczowy (`#F59E0B`) powyżej `38.8 °C` i czerwony (`#EF4444`) powyżej `39.2 °C`,
/// - kroplę nawodnienia (`%`) z paskiem stanu płynów,
/// - szybkie przyciski taktyczne: `Lód na kark` oraz
///   `Rozepnij koszulkę (+Chłodzenie / +Opór CdA)`.
class ThermoregulationAndHydrationHudGauge extends StatelessWidget {
  /// Próg ostrzegawczy temperatury głębokiej ciała [°C].
  static const double warningTempThresholdCelsius = 38.8;

  /// Próg krytyczny hipertermii [°C].
  static const double criticalTempThresholdCelsius = 39.2;

  /// Dolna granica skali paska termicznego [°C].
  static const double minGaugeTempCelsius = 37.0;

  /// Górna granica skali paska termicznego [°C].
  static const double maxGaugeTempCelsius = 40.5;

  /// Bieżąca temperatura głęboka ciała kolarza [°C].
  final double coreTemperatureCelsius;

  /// Bieżący poziom nawodnienia [0.0 - 100.0 %].
  final double hydrationPercent;

  /// Czy woreczek z lodem na karku jest aktualnie aktywny.
  final bool isIceSockActive;

  /// Liczba dostępnych woreczków z lodem w wozie / u kolarza.
  final int iceSocksRemaining;

  /// Czy koszulka kolarza jest aktualnie rozpięta (+Chłodzenie / +Opór CdA).
  final bool isJerseyUnzipped;

  /// Czy cały wskaźnik i jego akcje są wyłączone (np. DNF kolarza).
  final bool isDisabled;

  /// Wymuszony tryb kompaktowy (np. wewnątrz wąskiej karty kolarza w HUD).
  final bool compact;

  /// Callback wywoływany po kliknięciu przycisku `Lód na kark`.
  final VoidCallback? onIceSockPressed;

  /// Callback wywoływany po kliknięciu przycisku `Rozepnij koszulkę`.
  final VoidCallback? onToggleJerseyZipper;

  /// Opcjonalny padding wewnętrzny kontenera.
  final EdgeInsetsGeometry? padding;

  const ThermoregulationAndHydrationHudGauge({
    super.key,
    required this.coreTemperatureCelsius,
    required this.hydrationPercent,
    this.isIceSockActive = false,
    this.iceSocksRemaining = 2,
    this.isJerseyUnzipped = false,
    this.isDisabled = false,
    this.compact = false,
    this.onIceSockPressed,
    this.onToggleJerseyZipper,
    this.padding,
  });

  /// Normalizuje temperaturę do bezpiecznego zakresu [35.0, 42.0] °C.
  static double sanitizeTemperature(double value) {
    if (value.isNaN || value.isInfinite) {
      return 37.4;
    }
    return value.clamp(35.0, 42.0);
  }

  /// Normalizuje nawodnienie do bezpiecznego zakresu [0.0, 100.0] %.
  static double sanitizeHydration(double value) {
    if (value.isNaN || value.isInfinite) {
      return 100.0;
    }
    return value.clamp(0.0, 100.0);
  }

  /// Klasyfikuje strefę termiczną dla zadanej temperatury głębokiej ciała.
  static ThermoregulationThermalLevel classifyThermalLevel(double tempCelsius) {
    final double t = sanitizeTemperature(tempCelsius);
    if (t > criticalTempThresholdCelsius) {
      return ThermoregulationThermalLevel.critical;
    }
    if (t > warningTempThresholdCelsius) {
      return ThermoregulationThermalLevel.warning;
    }
    if (t > 38.0) {
      return ThermoregulationThermalLevel.elevated;
    }
    return ThermoregulationThermalLevel.optimal;
  }

  /// Zwraca kolor ikony termometru (pomarańczowy >38.8 °C, czerwony >39.2 °C).
  static Color thermometerColorForTemperature(double tempCelsius) {
    switch (classifyThermalLevel(tempCelsius)) {
      case ThermoregulationThermalLevel.optimal:
        return AppColors.statusSuccess;
      case ThermoregulationThermalLevel.elevated:
        return AppColors.accentBlue;
      case ThermoregulationThermalLevel.warning:
        return AppColors.amberWarning;
      case ThermoregulationThermalLevel.critical:
        return AppColors.crimsonAlert;
    }
  }

  /// Klasyfikuje stan nawodnienia na podstawie procentu płynów.
  static HydrationStatusLevel classifyHydrationLevel(double hydrationPercent) {
    final double h = sanitizeHydration(hydrationPercent);
    if (h < 40.0) {
      return HydrationStatusLevel.dehydrated;
    }
    if (h < 70.0) {
      return HydrationStatusLevel.moderate;
    }
    return HydrationStatusLevel.optimal;
  }

  /// Zwraca kolor kropli i paska nawodnienia.
  static Color hydrationColorForPercent(double hydrationPercent) {
    switch (classifyHydrationLevel(hydrationPercent)) {
      case HydrationStatusLevel.optimal:
        return AppColors.cyanAccent;
      case HydrationStatusLevel.moderate:
        return AppColors.amberWarning;
      case HydrationStatusLevel.dehydrated:
        return AppColors.crimsonAlert;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double safeTemp = sanitizeTemperature(coreTemperatureCelsius);
    final double safeHydration = sanitizeHydration(hydrationPercent);
    final ThermoregulationThermalLevel thermalLevel =
        classifyThermalLevel(safeTemp);
    final Color thermalColor = thermometerColorForTemperature(safeTemp);
    final Color hydrationColor = hydrationColorForPercent(safeHydration);

    final double tempProgress =
        ((safeTemp - minGaugeTempCelsius) /
                (maxGaugeTempCelsius - minGaugeTempCelsius))
            .clamp(0.0, 1.0);
    final double hydrationProgress = (safeHydration / 100.0).clamp(0.0, 1.0);

    final bool isOverheated =
        thermalLevel == ThermoregulationThermalLevel.warning ||
            thermalLevel == ThermoregulationThermalLevel.critical;

    final Color containerBorderColor = isDisabled
        ? AppTheme.borderColor.withValues(alpha: 0.6)
        : isOverheated
            ? thermalColor.withValues(alpha: 0.75)
            : AppTheme.borderColor;

    final bool canUseIceSock =
        !isDisabled && onIceSockPressed != null && (isIceSockActive || iceSocksRemaining > 0);
    final bool canToggleJersey = !isDisabled && onToggleJerseyZipper != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 320.0;
        final bool isNarrow = compact || availableWidth < 260.0;
        final bool isWide = availableWidth >= 340.0 && !compact;

        final EdgeInsetsGeometry resolvedPadding = padding ??
            EdgeInsets.all(isNarrow ? 8.0 : (isWide ? 12.0 : 10.0));

        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: resolvedPadding,
          decoration: BoxDecoration(
            color: isDisabled
                ? AppColors.surface.withValues(alpha: 0.65)
                : AppColors.surfaceLight.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: containerBorderColor,
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sekcja wskaźników: Termometr (°C) + Kropla nawodnienia (%)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _ThermalMetricBlock(
                      temperatureCelsius: safeTemp,
                      progress: tempProgress,
                      color: thermalColor,
                      level: thermalLevel,
                      showLevelTag: isWide,
                      isIceSockActive: isIceSockActive,
                      isNarrow: isNarrow,
                    ),
                  ),
                  SizedBox(width: isNarrow ? 8.0 : 12.0),
                  Expanded(
                    child: _HydrationMetricBlock(
                      hydrationPercent: safeHydration,
                      progress: hydrationProgress,
                      color: hydrationColor,
                      isNarrow: isNarrow,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isNarrow ? 7.0 : 9.0),

              // Sekcja szybkich przycisków: Lód na kark + Rozepnij koszulkę
              if (isNarrow)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ThermoregulationActionButton(
                      key: const ValueKey<String>('ice_sock_action_button'),
                      icon: Icons.ac_unit_rounded,
                      label: 'Lód na kark',
                      badgeText: isIceSockActive
                          ? 'AKTYWNY'
                          : (iceSocksRemaining > 0
                              ? 'x$iceSocksRemaining'
                              : 'BRAK'),
                      accentColor: AppColors.cyanAccent,
                      isActive: isIceSockActive,
                      isDisabled: !canUseIceSock,
                      tooltip: isIceSockActive
                          ? 'Chłodzenie woreczkiem z lodem aktywne (-0.4 °C)'
                          : (iceSocksRemaining > 0
                              ? 'Pobierz i przyłóż lód na kark (-0.4 °C)'
                              : 'Brak dostępnych woreczków z lodem'),
                      compact: true,
                      onPressed: canUseIceSock ? onIceSockPressed : null,
                    ),
                    const SizedBox(height: 5),
                    _ThermoregulationActionButton(
                      key: const ValueKey<String>('jersey_zipper_action_button'),
                      icon: isJerseyUnzipped
                          ? Icons.unfold_less_rounded
                          : Icons.air_rounded,
                      label: 'Rozepnij koszulkę',
                      sublabel: '(+Chłodzenie / +Opór CdA)',
                      badgeText: isJerseyUnzipped ? 'ROZPIĘTA' : null,
                      accentColor: AppColors.amberWarning,
                      isActive: isJerseyUnzipped,
                      isDisabled: !canToggleJersey,
                      tooltip: isJerseyUnzipped
                          ? 'Koszulka rozpięta: lepsze chłodzenie kosztem wyższego oporu CdA. Kliknij, aby zapiąć.'
                          : 'Rozepnij koszulkę: +Chłodzenie / +Opór CdA',
                      compact: true,
                      onPressed: canToggleJersey ? onToggleJerseyZipper : null,
                    ),
                  ],
                )
              else
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    Expanded(
                      flex: 4,
                      child: _ThermoregulationActionButton(
                        key: const ValueKey<String>('ice_sock_action_button'),
                        icon: Icons.ac_unit_rounded,
                        label: 'Lód na kark',
                        badgeText: isIceSockActive
                            ? 'AKTYWNY'
                            : (iceSocksRemaining > 0
                                ? 'x$iceSocksRemaining'
                                : 'BRAK'),
                        accentColor: AppColors.cyanAccent,
                        isActive: isIceSockActive,
                        isDisabled: !canUseIceSock,
                        tooltip: isIceSockActive
                            ? 'Chłodzenie woreczkiem z lodem aktywne (-0.4 °C)'
                            : (iceSocksRemaining > 0
                                ? 'Pobierz i przyłóż lód na kark (-0.4 °C)'
                                : 'Brak dostępnych woreczków z lodem'),
                        compact: false,
                        onPressed: canUseIceSock ? onIceSockPressed : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 6,
                      child: _ThermoregulationActionButton(
                        key: const ValueKey<String>(
                          'jersey_zipper_action_button',
                        ),
                        icon: isJerseyUnzipped
                            ? Icons.unfold_less_rounded
                            : Icons.air_rounded,
                        label: 'Rozepnij koszulkę',
                        sublabel: '(+Chłodzenie / +Opór CdA)',
                        badgeText: isJerseyUnzipped ? 'ON' : null,
                        accentColor: AppColors.amberWarning,
                        isActive: isJerseyUnzipped,
                        isDisabled: !canToggleJersey,
                        tooltip: isJerseyUnzipped
                            ? 'Koszulka rozpięta: +Chłodzenie / +Opór CdA. Kliknij, aby zapiąć.'
                            : 'Rozepnij koszulkę (+Chłodzenie / +Opór CdA)',
                        compact: false,
                        onPressed:
                            canToggleJersey ? onToggleJerseyZipper : null,
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

class _ThermalMetricBlock extends StatelessWidget {
  final double temperatureCelsius;
  final double progress;
  final Color color;
  final ThermoregulationThermalLevel level;
  final bool showLevelTag;
  final bool isIceSockActive;
  final bool isNarrow;

  const _ThermalMetricBlock({
    required this.temperatureCelsius,
    required this.progress,
    required this.color,
    required this.level,
    required this.showLevelTag,
    required this.isIceSockActive,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: color.withValues(alpha: 0.55),
                  width: 1.0,
                ),
              ),
              child: Icon(
                Icons.thermostat_rounded,
                key: const ValueKey<String>('thermoregulation_thermometer_icon'),
                color: color,
                size: isNarrow ? 13 : 15,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${temperatureCelsius.toStringAsFixed(1)}°C',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: color,
                  fontSize: isNarrow ? 11 : 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            if (isIceSockActive) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.ac_unit_rounded,
                color: AppColors.cyanAccent,
                size: 11,
              ),
            ],
            if (showLevelTag) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    level.labelPl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 5),
        _AnimatedTelemetryBar(
          value: progress,
          color: color,
        ),
      ],
    );
  }
}

class _HydrationMetricBlock extends StatelessWidget {
  final double hydrationPercent;
  final double progress;
  final Color color;
  final bool isNarrow;

  const _HydrationMetricBlock({
    required this.hydrationPercent,
    required this.progress,
    required this.color,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: color.withValues(alpha: 0.55),
                  width: 1.0,
                ),
              ),
              child: Icon(
                Icons.water_drop_rounded,
                key: const ValueKey<String>('hydration_drop_icon'),
                color: color,
                size: isNarrow ? 13 : 15,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${hydrationPercent.round()}%',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: isNarrow ? 11 : 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        _AnimatedTelemetryBar(
          value: progress,
          color: color,
        ),
      ],
    );
  }
}

class _AnimatedTelemetryBar extends StatelessWidget {
  final double value;
  final Color color;

  const _AnimatedTelemetryBar({
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 5,
        color: AppColors.background.withValues(alpha: 0.75),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: value, end: value),
          builder: (context, animatedValue, _) {
            return FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: animatedValue.clamp(0.0, 1.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ThermoregulationActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? sublabel;
  final String? badgeText;
  final Color accentColor;
  final bool isActive;
  final bool isDisabled;
  final String tooltip;
  final bool compact;
  final VoidCallback? onPressed;

  const _ThermoregulationActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.sublabel,
    this.badgeText,
    required this.accentColor,
    required this.isActive,
    required this.isDisabled,
    required this.tooltip,
    required this.compact,
    required this.onPressed,
  });

  @override
  State<_ThermoregulationActionButton> createState() =>
      _ThermoregulationActionButtonState();
}

class _ThermoregulationActionButtonState
    extends State<_ThermoregulationActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  void _triggerPress() {
    if (widget.isDisabled || widget.onPressed == null) return;
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = !widget.isDisabled && widget.onPressed != null;

    final Color bgColor = !enabled
        ? AppColors.surface.withValues(alpha: 0.5)
        : widget.isActive
            ? widget.accentColor.withValues(alpha: _isHovered ? 0.28 : 0.20)
            : _isPressed
                ? widget.accentColor.withValues(alpha: 0.18)
                : _isHovered
                    ? AppColors.surfaceLight
                    : AppColors.surface;

    final Color borderColor = !enabled
        ? AppTheme.borderColor.withValues(alpha: 0.45)
        : _isFocused
            ? AppColors.goldAccent
            : widget.isActive
                ? widget.accentColor
                : _isHovered
                    ? widget.accentColor.withValues(alpha: 0.7)
                    : AppTheme.borderColor;

    final Color contentColor = !enabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : widget.isActive
            ? widget.accentColor
            : AppColors.textPrimary;

    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
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
              _triggerPress();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
          onTap: enabled ? _triggerPress : null,
          child: Semantics(
            button: true,
            enabled: enabled,
            toggled: widget.isActive,
            label: widget.sublabel != null
                ? '${widget.label} ${widget.sublabel}'
                : widget.label,
            child: AnimatedScale(
              scale: _isPressed && enabled ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.compact ? 7.0 : 9.0,
                  vertical: widget.compact ? 5.0 : 6.0,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: borderColor,
                    width: _isFocused ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Icon(
                      widget.icon,
                      size: widget.compact ? 13 : 14,
                      color: !enabled
                          ? AppColors.textSecondary.withValues(alpha: 0.45)
                          : widget.isActive || _isHovered
                              ? widget.accentColor
                              : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: contentColor,
                              fontSize: widget.compact ? 10 : 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (widget.sublabel != null)
                            Text(
                              widget.sublabel!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: !enabled
                                    ? AppColors.textSecondary
                                        .withValues(alpha: 0.45)
                                    : widget.isActive
                                        ? widget.accentColor
                                            .withValues(alpha: 0.9)
                                        : AppColors.textSecondary,
                                fontSize: widget.compact ? 8.5 : 9,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.2,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (widget.badgeText != null) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: !enabled
                              ? AppColors.background.withValues(alpha: 0.4)
                              : widget.isActive
                                  ? widget.accentColor.withValues(alpha: 0.25)
                                  : AppColors.background.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          widget.badgeText!,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: !enabled
                                ? AppColors.textSecondary.withValues(alpha: 0.5)
                                : widget.isActive
                                    ? widget.accentColor
                                    : AppColors.textSecondary,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
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
      ),
    );
  }
}
