import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Akcent podświetlenia obramowania dla komponentów karbonowych i szklanych.
enum CarbonAccentTone {
  /// Burgundowy akcent drużynowy (`#8E4A49`).
  burgundy,

  /// Mistrzowski złoty akcent (`#D4AF37`).
  gold,
}

/// Zestaw tokenów wizualnych i fabryk pomocniczych dla luksusowych kontenerów
/// karbonowych, szklanych paneli HUD oraz animowanych kafelków statystyk.
class CustomCarbonAndGlassContainers {
  CustomCarbonAndGlassContainers._();

  /// Domyślne zaokrąglenie kart i paneli (16 px).
  static const double borderRadius = 16.0;

  /// Domyślna grubość obramowania (1 px).
  static const double borderWidth = 1.0;

  /// Domyślne rozmycie tła dla nakładek HUD 3D (`sigmaX = 14`, `sigmaY = 14`).
  static const double glassBlurSigma = 14.0;

  /// Kolor odbicia światła na górnej krawędzi karty karbonowej.
  static const Color topSpecularColor = Color(0xFF3A4154);

  /// Zwraca kolor akcentu z palety [AppColors] dla wybranego tonu.
  static Color resolveAccentColor(CarbonAccentTone tone) {
    switch (tone) {
      case CarbonAccentTone.burgundy:
        return AppColors.primaryAccent;
      case CarbonAccentTone.gold:
        return AppColors.goldAccent;
    }
  }

  /// Tworzy kartę z proceduralnym splotem włókna węglowego 3K.
  static Widget carbonCard({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    CarbonAccentTone accentTone = CarbonAccentTone.gold,
    Color? hoverBorderColor,
    VoidCallback? onTap,
    bool enabled = true,
    double borderRadius = borderRadius,
  }) {
    return CarbonFiberCard(
      key: key,
      padding: padding,
      accentTone: accentTone,
      hoverBorderColor: hoverBorderColor,
      onTap: onTap,
      enabled: enabled,
      borderRadius: borderRadius,
      child: child,
    );
  }

  /// Tworzy półprzezroczysty panel HUD 3D z rozmyciem tła i subtelnym szumem.
  static Widget glassHud({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    double blurSigma = glassBlurSigma,
    double borderRadius = borderRadius,
    CarbonAccentTone accentTone = CarbonAccentTone.burgundy,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return GlassmorphicHudPanel(
      key: key,
      padding: padding,
      blurSigma: blurSigma,
      borderRadius: borderRadius,
      accentTone: accentTone,
      onTap: onTap,
      enabled: enabled,
      child: child,
    );
  }

  /// Tworzy animowany kafelek statystyki z licznikiem [TweenAnimationBuilder].
  static Widget statBadge({
    Key? key,
    required String label,
    required double value,
    String unit = '',
    String prefix = '',
    int fractionDigits = 1,
    IconData? icon,
    Color? accentColor,
    double? trendDelta,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return AnimatedStatBadge(
      key: key,
      label: label,
      value: value,
      unit: unit,
      prefix: prefix,
      fractionDigits: fractionDigits,
      icon: icon,
      accentColor: accentColor,
      trendDelta: trendDelta,
      onTap: onTap,
      enabled: enabled,
    );
  }
}

/// Kontener z proceduralnie rysowaną w tle mikroteksturą włókna węglowego
/// (splot Carbon 3K pod kątem 45°), ciemnym lakierem `#181B22`, 1 px odbiciem
/// światła na górnej krawędzi (`#3A4154` -> przezroczystość) oraz płynnym
/// podświetleniem obramowania (`#8E4A49` lub `#D4AF37`) przy interakcji.
class CarbonFiberCard extends StatefulWidget {
  const CarbonFiberCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = CustomCarbonAndGlassContainers.borderRadius,
    this.accentTone = CarbonAccentTone.gold,
    this.hoverBorderColor,
    this.baseColor = AppColors.surface,
    this.weaveOpacity = 0.55,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.focusNode,
    this.semanticLabel,
    this.animationDuration = const Duration(milliseconds: 240),
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final CarbonAccentTone accentTone;
  final Color? hoverBorderColor;
  final Color baseColor;
  final double weaveOpacity;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final FocusNode? focusNode;
  final String? semanticLabel;
  final Duration animationDuration;

  @override
  State<CarbonFiberCard> createState() => _CarbonFiberCardState();
}

class _CarbonFiberCardState extends State<CarbonFiberCard> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  bool get _isInteractive =>
      widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  Color get _resolvedAccent =>
      widget.hoverBorderColor ??
      CustomCarbonAndGlassContainers.resolveAccentColor(widget.accentTone);

  void _handleHover(bool hovered) {
    if (!widget.enabled) return;
    if (_isHovered != hovered) {
      setState(() => _isHovered = hovered);
    }
  }

  void _handleFocus(bool focused) {
    if (!widget.enabled) return;
    if (_isFocused != focused) {
      setState(() => _isFocused = focused);
    }
  }

  void _handlePressed(bool pressed) {
    if (!_isInteractive) return;
    if (_isPressed != pressed) {
      setState(() => _isPressed = pressed);
    }
  }

  EdgeInsetsGeometry _responsivePadding(double maxWidth) {
    if (widget.padding != null) return widget.padding!;
    if (maxWidth < 420) {
      return const EdgeInsets.all(14);
    }
    if (maxWidth < 900) {
      return const EdgeInsets.all(18);
    }
    return const EdgeInsets.all(20);
  }

  @override
  Widget build(BuildContext context) {
    final bool activeHighlight =
        widget.enabled && (_isHovered || _isFocused || _isPressed);
    final Color effectiveBorderColor = !widget.enabled
        ? AppTheme.borderColor.withValues(alpha: 0.45)
        : activeHighlight
            ? _resolvedAccent
            : AppTheme.borderColor;
    final double effectiveBorderWidth = _isFocused ? 1.5 : 1.0;
    final double scale = _isPressed && _isInteractive ? 0.992 : 1.0;
    final Radius radius = Radius.circular(widget.borderRadius);

    return Semantics(
      label: widget.semanticLabel,
      button: _isInteractive,
      enabled: widget.enabled,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        focusNode: widget.focusNode,
        mouseCursor: _isInteractive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowHoverHighlight: _handleHover,
        onShowFocusHighlight: _handleFocus,
        shortcuts: _isInteractive
            ? const <ShortcutActivator, Intent>{
                SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
                SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
              }
            : null,
        actions: _isInteractive
            ? <Type, Action<Intent>>{
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    widget.onTap?.call();
                    return null;
                  },
                ),
              }
            : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _isInteractive ? widget.onTap : null,
          onLongPress: widget.enabled ? widget.onLongPress : null,
          onTapDown: _isInteractive ? (_) => _handlePressed(true) : null,
          onTapUp: _isInteractive ? (_) => _handlePressed(false) : null,
          onTapCancel: _isInteractive ? () => _handlePressed(false) : null,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final EdgeInsetsGeometry resolvedPadding =
                  _responsivePadding(constraints.maxWidth);

              return AnimatedScale(
                scale: scale,
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: widget.enabled ? 1.0 : 0.52,
                  duration: widget.animationDuration,
                  curve: Curves.easeOutCubic,
                  child: AnimatedContainer(
                    margin: widget.margin,
                    duration: widget.animationDuration,
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: widget.baseColor,
                      borderRadius: BorderRadius.all(radius),
                      border: Border.all(
                        color: effectiveBorderColor,
                        width: effectiveBorderWidth,
                      ),
                      boxShadow: activeHighlight
                          ? <BoxShadow>[
                              BoxShadow(
                                color: _resolvedAccent.withValues(
                                  alpha: _isPressed ? 0.28 : 0.18,
                                ),
                                blurRadius: _isFocused ? 18 : 14,
                                spreadRadius: 0,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x55000000),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(radius),
                      child: Stack(
                        fit: StackFit.passthrough,
                        children: <Widget>[
                          Positioned.fill(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: _CarbonWeave3KPainter(
                                  weaveOpacity: widget.weaveOpacity,
                                  highlightStrength:
                                      activeHighlight ? 0.14 : 0.0,
                                  accentColor: _resolvedAccent,
                                ),
                              ),
                            ),
                          ),
                          // 1 px odbicie światła na górnej krawędzi (#3A4154 -> transparent)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: 1.0,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: <Color>[
                                      CustomCarbonAndGlassContainers
                                          .topSpecularColor
                                          .withValues(alpha: 0.0),
                                      activeHighlight
                                          ? Color.lerp(
                                              CustomCarbonAndGlassContainers
                                                  .topSpecularColor,
                                              _resolvedAccent,
                                              0.45,
                                            )!
                                          : CustomCarbonAndGlassContainers
                                              .topSpecularColor,
                                      CustomCarbonAndGlassContainers
                                          .topSpecularColor
                                          .withValues(alpha: 0.0),
                                    ],
                                    stops: const <double>[0.0, 0.5, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: resolvedPadding,
                            child: widget.child,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CarbonWeave3KPainter extends CustomPainter {
  const _CarbonWeave3KPainter({
    required this.weaveOpacity,
    required this.highlightStrength,
    required this.accentColor,
  });

  final double weaveOpacity;
  final double highlightStrength;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // Subtelny winietowany lakier bazowy nad kolorem #181B22
    final Rect bounds = Offset.zero & size;
    final Paint lacquerGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          const Color(0xFF222630).withValues(alpha: 0.28 * weaveOpacity),
          Colors.transparent,
          const Color(0xFF0B0D11).withValues(alpha: 0.35 * weaveOpacity),
        ],
        stops: const <double>[0.0, 0.48, 1.0],
      ).createShader(bounds);
    canvas.drawRect(bounds, lacquerGradient);

    // Splot Carbon 3K obrócony o 45°
    canvas.save();
    final double cx = size.width * 0.5;
    final double cy = size.height * 0.5;
    canvas.translate(cx, cy);
    canvas.rotate(math.pi / 4.0);

    final double diagonal =
        math.sqrt(size.width * size.width + size.height * size.height);
    final double halfSpan = diagonal * 0.55;

    const double cellW = 7.0;
    const double cellH = 3.5;

    final Paint warpPaint = Paint()
      ..color = const Color(0xFF262B37).withValues(alpha: 0.55 * weaveOpacity);
    final Paint weftPaint = Paint()
      ..color = const Color(0xFF101318).withValues(alpha: 0.72 * weaveOpacity);
    final Paint fiberHighlight = Paint()
      ..color = const Color(0xFF3A4154).withValues(alpha: 0.18 * weaveOpacity);

    int rowIndex = 0;
    for (double y = -halfSpan; y < halfSpan; y += cellH) {
      // Przesunięcie skośnego splotu twill 2x2
      final double twillOffset = ((rowIndex % 4) * (cellW * 0.5));
      for (double x = -halfSpan - cellW * 2; x < halfSpan; x += cellW * 2) {
        final double drawX = x + twillOffset;
        final Rect warpRect = Rect.fromLTWH(drawX, y, cellW - 0.6, cellH - 0.5);
        final Rect weftRect =
            Rect.fromLTWH(drawX + cellW, y, cellW - 0.6, cellH - 0.5);

        canvas.drawRect(warpRect, warpPaint);
        canvas.drawRect(
          Rect.fromLTWH(warpRect.left, warpRect.top, warpRect.width, 0.7),
          fiberHighlight,
        );
        canvas.drawRect(weftRect, weftPaint);
      }
      rowIndex++;
    }
    canvas.restore();

    if (highlightStrength > 0) {
      final Paint hoverSheen = Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -1.0),
          radius: 1.25,
          colors: <Color>[
            accentColor.withValues(alpha: highlightStrength),
            Colors.transparent,
          ],
        ).createShader(bounds);
      canvas.drawRect(bounds, hoverSheen);
    }
  }

  @override
  bool shouldRepaint(covariant _CarbonWeave3KPainter oldDelegate) {
    return oldDelegate.weaveOpacity != weaveOpacity ||
        oldDelegate.highlightStrength != highlightStrength ||
        oldDelegate.accentColor != accentColor;
  }
}

/// Półprzezroczysty panel HUD dla nakładek wyścigowych 3D z rozmyciem tła
/// (`ImageFilter.blur(sigmaX: 14, sigmaY: 14)`), subtelnym szumem mikroziarna
/// i zaokrągleniem 16 px.
class GlassmorphicHudPanel extends StatefulWidget {
  const GlassmorphicHudPanel({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.blurSigma = CustomCarbonAndGlassContainers.glassBlurSigma,
    this.borderRadius = CustomCarbonAndGlassContainers.borderRadius,
    this.tintColor = AppColors.surface,
    this.tintOpacity = 0.62,
    this.noiseOpacity = 0.035,
    this.accentTone = CarbonAccentTone.burgundy,
    this.hoverBorderColor,
    this.onTap,
    this.enabled = true,
    this.focusNode,
    this.semanticLabel,
    this.animationDuration = const Duration(milliseconds: 220),
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blurSigma;
  final double borderRadius;
  final Color tintColor;
  final double tintOpacity;
  final double noiseOpacity;
  final CarbonAccentTone accentTone;
  final Color? hoverBorderColor;
  final VoidCallback? onTap;
  final bool enabled;
  final FocusNode? focusNode;
  final String? semanticLabel;
  final Duration animationDuration;

  @override
  State<GlassmorphicHudPanel> createState() => _GlassmorphicHudPanelState();
}

class _GlassmorphicHudPanelState extends State<GlassmorphicHudPanel> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  bool get _isInteractive => widget.enabled && widget.onTap != null;

  Color get _resolvedAccent =>
      widget.hoverBorderColor ??
      CustomCarbonAndGlassContainers.resolveAccentColor(widget.accentTone);

  EdgeInsetsGeometry _responsivePadding(double maxWidth) {
    if (widget.padding != null) return widget.padding!;
    if (maxWidth < 420) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 10);
    }
    if (maxWidth < 900) {
      return const EdgeInsets.symmetric(horizontal: 14, vertical: 12);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  }

  @override
  Widget build(BuildContext context) {
    final bool activeHighlight =
        widget.enabled && (_isHovered || _isFocused || _isPressed);
    final BorderRadius radius = BorderRadius.circular(widget.borderRadius);
    final Color borderColor = !widget.enabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : activeHighlight
            ? _resolvedAccent.withValues(alpha: 0.9)
            : const Color(0xFF3A4154).withValues(alpha: 0.65);

    return Semantics(
      label: widget.semanticLabel,
      button: _isInteractive,
      enabled: widget.enabled,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        focusNode: widget.focusNode,
        mouseCursor: _isInteractive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowHoverHighlight: (bool value) {
          if (!widget.enabled) return;
          if (_isHovered != value) setState(() => _isHovered = value);
        },
        onShowFocusHighlight: (bool value) {
          if (!widget.enabled) return;
          if (_isFocused != value) setState(() => _isFocused = value);
        },
        shortcuts: _isInteractive
            ? const <ShortcutActivator, Intent>{
                SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
                SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
              }
            : null,
        actions: _isInteractive
            ? <Type, Action<Intent>>{
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    widget.onTap?.call();
                    return null;
                  },
                ),
              }
            : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _isInteractive ? widget.onTap : null,
          onTapDown: _isInteractive
              ? (_) => setState(() => _isPressed = true)
              : null,
          onTapUp: _isInteractive
              ? (_) => setState(() => _isPressed = false)
              : null,
          onTapCancel: _isInteractive
              ? () => setState(() => _isPressed = false)
              : null,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final EdgeInsetsGeometry resolvedPadding =
                  _responsivePadding(constraints.maxWidth);

              return AnimatedOpacity(
                opacity: widget.enabled ? 1.0 : 0.52,
                duration: widget.animationDuration,
                curve: Curves.easeOutCubic,
                child: Container(
                  margin: widget.margin,
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x4D000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: radius,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: widget.blurSigma,
                        sigmaY: widget.blurSigma,
                      ),
                      child: AnimatedContainer(
                        duration: widget.animationDuration,
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          border: Border.all(
                            color: borderColor,
                            width: _isFocused ? 1.5 : 1.0,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              widget.tintColor.withValues(
                                alpha: (widget.tintOpacity +
                                        (activeHighlight ? 0.08 : 0.0))
                                    .clamp(0.0, 0.95),
                              ),
                              AppColors.background.withValues(
                                alpha: (widget.tintOpacity + 0.12)
                                    .clamp(0.0, 0.96),
                              ),
                            ],
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.passthrough,
                          children: <Widget>[
                            Positioned.fill(
                              child: IgnorePointer(
                                child: RepaintBoundary(
                                  child: CustomPaint(
                                    painter: _FrostedNoisePainter(
                                      opacity: widget.noiseOpacity,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Subtelny refleks na górnej krawędzi szkła
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: 1.0,
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: <Color>[
                                        Colors.transparent,
                                        Colors.white.withValues(alpha: 0.22),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: resolvedPadding,
                              child: widget.child,
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
      ),
    );
  }
}

class _FrostedNoisePainter extends CustomPainter {
  const _FrostedNoisePainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || opacity <= 0) return;

    final Paint lightGrain = Paint()
      ..color = Colors.white.withValues(alpha: opacity);
    final Paint darkGrain = Paint()
      ..color = Colors.black.withValues(alpha: opacity * 1.15);

    // Deterministyczny wzór mikroziarna bez alokacji ciężkich buforów
    const double step = 6.0;
    int seed = 1337;
    for (double y = 1.0; y < size.height; y += step) {
      for (double x = 1.0; x < size.width; x += step) {
        seed = (seed * 1664525 + 1013904223) & 0x7FFFFFFF;
        final int bucket = seed & 7;
        if (bucket == 0) {
          canvas.drawRect(Rect.fromLTWH(x, y, 1.2, 1.2), lightGrain);
        } else if (bucket == 1) {
          canvas.drawRect(Rect.fromLTWH(x + 2, y + 2, 1.1, 1.1), darkGrain);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FrostedNoisePainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}

/// Kafelek statystyki (np. `6.4 W/kg`, `FTP 415W`) z animowanym licznikiem
/// [TweenAnimationBuilder], który przy zmianie wartości płynnie przelicza
/// cyfry z zachowaniem stałej szerokości znaków (`tabularFigures`).
class AnimatedStatBadge extends StatefulWidget {
  const AnimatedStatBadge({
    super.key,
    required this.label,
    required this.value,
    this.unit = '',
    this.prefix = '',
    this.fractionDigits = 1,
    this.icon,
    this.accentColor,
    this.trendDelta,
    this.duration = const Duration(milliseconds: 320),
    this.curve = Curves.easeOutCubic,
    this.onTap,
    this.enabled = true,
    this.focusNode,
    this.borderRadius = CustomCarbonAndGlassContainers.borderRadius,
  });

  final String label;
  final double value;
  final String unit;
  final String prefix;
  final int fractionDigits;
  final IconData? icon;
  final Color? accentColor;
  final double? trendDelta;
  final Duration duration;
  final Curve curve;
  final VoidCallback? onTap;
  final bool enabled;
  final FocusNode? focusNode;
  final double borderRadius;

  @override
  State<AnimatedStatBadge> createState() => _AnimatedStatBadgeState();
}

class _AnimatedStatBadgeState extends State<AnimatedStatBadge> {
  double _previousValue = 0.0;
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  bool get _isInteractive => widget.enabled && widget.onTap != null;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant AnimatedStatBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.accentColor ?? AppColors.goldAccent;
    final bool activeHighlight =
        widget.enabled && (_isHovered || _isFocused || _isPressed);
    final Color borderColor = !widget.enabled
        ? AppTheme.borderColor.withValues(alpha: 0.45)
        : activeHighlight
            ? accent
            : AppTheme.borderColor;

    return Semantics(
      label:
          '${widget.label}: ${widget.prefix}${widget.value.toStringAsFixed(widget.fractionDigits)} ${widget.unit}',
      button: _isInteractive,
      enabled: widget.enabled,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        focusNode: widget.focusNode,
        mouseCursor: _isInteractive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowHoverHighlight: (bool v) {
          if (!widget.enabled) return;
          if (_isHovered != v) setState(() => _isHovered = v);
        },
        onShowFocusHighlight: (bool v) {
          if (!widget.enabled) return;
          if (_isFocused != v) setState(() => _isFocused = v);
        },
        shortcuts: _isInteractive
            ? const <ShortcutActivator, Intent>{
                SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
                SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
              }
            : null,
        actions: _isInteractive
            ? <Type, Action<Intent>>{
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    widget.onTap?.call();
                    return null;
                  },
                ),
              }
            : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _isInteractive ? widget.onTap : null,
          onTapDown: _isInteractive
              ? (_) => setState(() => _isPressed = true)
              : null,
          onTapUp: _isInteractive
              ? (_) => setState(() => _isPressed = false)
              : null,
          onTapCancel: _isInteractive
              ? () => setState(() => _isPressed = false)
              : null,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool isCompact = constraints.maxWidth < 155;
              final EdgeInsets padding = isCompact
                  ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 11);

              return AnimatedOpacity(
                opacity: widget.enabled ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: padding,
                  decoration: BoxDecoration(
                    color: _isPressed
                        ? AppColors.surfaceLight
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: Border.all(
                      color: borderColor,
                      width: _isFocused ? 1.5 : 1.0,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        AppColors.surfaceLight.withValues(
                          alpha: activeHighlight ? 0.55 : 0.25,
                        ),
                        AppColors.surface,
                      ],
                    ),
                    boxShadow: activeHighlight
                        ? <BoxShadow>[
                            BoxShadow(
                              color: accent.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (widget.icon != null) ...<Widget>[
                            Icon(
                              widget.icon,
                              size: isCompact ? 13 : 15,
                              color: accent,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              widget.label.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.7,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          if (widget.trendDelta != null &&
                              widget.trendDelta != 0) ...<Widget>[
                            const SizedBox(width: 6),
                            _TrendPill(delta: widget.trendDelta!),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: _previousValue,
                          end: widget.value,
                        ),
                        duration: widget.duration,
                        curve: widget.curve,
                        builder: (
                          BuildContext context,
                          double animatedValue,
                          Widget? child,
                        ) {
                          final String formatted = animatedValue
                              .toStringAsFixed(widget.fractionDigits);
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: <Widget>[
                              if (widget.prefix.isNotEmpty) ...<Widget>[
                                Text(
                                  widget.prefix,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: isCompact ? 13 : 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Flexible(
                                child: Text(
                                  formatted,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: isCompact ? 18 : 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: AppColors.textPrimary,
                                    fontFeatures: const <FontFeature>[
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                              if (widget.unit.isNotEmpty) ...<Widget>[
                                const SizedBox(width: 4),
                                Text(
                                  widget.unit,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: isCompact ? 11 : 12.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.1,
                                    color: accent,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.delta});

  final double delta;

  @override
  Widget build(BuildContext context) {
    final bool positive = delta > 0;
    final Color color =
        positive ? AppColors.statusSuccess : AppColors.crimsonAlert;
    final String sign = positive ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Text(
        '$sign${delta.toStringAsFixed(delta.truncateToDouble() == delta ? 0 : 1)}',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: color,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
