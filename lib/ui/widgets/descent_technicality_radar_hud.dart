import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../engine/peloton/descender_attack_and_supertuck_physics.dart';

/// Poziom ryzyka poślizgu podczas pokonywania technicznego zjazdu.
enum DescentSlipRiskLevel {
  /// Niskie ryzyko (< 20%) — pewna przyczepność, duży margines bezpieczeństwa.
  low('NISKIE', 'LOW', AppColors.statusSuccess),

  /// Umiarkowane ryzyko (20–44%) — szybkie wejścia w zakręty, wymagana uwaga.
  moderate('UMIARKOWANE', 'MODERATE', AppColors.amberWarning),

  /// Wysokie ryzyko (45–69%) — jazda na granicy przyczepności przed serpentyną.
  high('WYSOKIE', 'HIGH', AppColors.crimsonAlert),

  /// Krytyczne ryzyko (>= 70%) — skrajne ryzyko uślizgu koła i kraksy.
  critical('KRYTYCZNE', 'CRITICAL', AppColors.crimsonAlert);

  final String labelPl;
  final String labelEn;
  final Color color;

  const DescentSlipRiskLevel(this.labelPl, this.labelEn, this.color);

  /// Wyznacza poziom ryzyka na podstawie wartości procentowej [0..100].
  static DescentSlipRiskLevel fromPercent(double slipRiskPercent) {
    final double clamped = _sanitizePercent(slipRiskPercent);
    if (clamped >= 70.0) {
      return DescentSlipRiskLevel.critical;
    }
    if (clamped >= 45.0) {
      return DescentSlipRiskLevel.high;
    }
    if (clamped >= 20.0) {
      return DescentSlipRiskLevel.moderate;
    }
    return DescentSlipRiskLevel.low;
  }

  /// Czy poziom wymaga aktywacji pulsującego ostrzeżenia w HUD.
  bool get isAlertActive =>
      this == DescentSlipRiskLevel.high ||
      this == DescentSlipRiskLevel.critical;

  static double _sanitizePercent(double value) {
    if (value.isNaN || value.isInfinite) {
      return 0.0;
    }
    return value.clamp(0.0, 100.0);
  }
}

/// Dane pojedynczego nadchodzącego nawrotu 180° (hairpin) na zjeździe.
@immutable
class DescentHairpinTurnData {
  /// Numer kolejny nawrotu na zjeździe (np. 1, 2, 3...).
  final int hairpinNumber;

  /// Odległość do wierzchołka nawrotu w metrach.
  final double distanceAheadMeters;

  /// Promień łuku nawrotu w metrach (mniejszy = ostrzejszy zakręt 180°).
  final double radiusMeters;

  /// Zalecana bezpieczna prędkość wejścia w zakręt (km/h).
  final double recommendedEntrySpeedKmh;

  /// Czy na nawrocie występuje mokry/zacieniony fragment asfaltu.
  final bool isWetPatch;

  /// Kierunek nawrotu (`true` = w prawo, `false` = w lewo).
  final bool isRightTurn;

  const DescentHairpinTurnData({
    required this.hairpinNumber,
    required this.distanceAheadMeters,
    required this.radiusMeters,
    required this.recommendedEntrySpeedKmh,
    this.isWetPatch = false,
    this.isRightTurn = true,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'hairpinNumber': hairpinNumber,
        'distanceAheadMeters': distanceAheadMeters,
        'radiusMeters': radiusMeters,
        'recommendedEntrySpeedKmh': recommendedEntrySpeedKmh,
        'isWetPatch': isWetPatch,
        'isRightTurn': isRightTurn,
      };

  factory DescentHairpinTurnData.fromJson(Map<String, dynamic> json) {
    return DescentHairpinTurnData(
      hairpinNumber: (json['hairpinNumber'] as num?)?.toInt() ?? 1,
      distanceAheadMeters:
          (json['distanceAheadMeters'] as num?)?.toDouble() ?? 150.0,
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 12.0,
      recommendedEntrySpeedKmh:
          (json['recommendedEntrySpeedKmh'] as num?)?.toDouble() ?? 42.0,
      isWetPatch: json['isWetPatch'] as bool? ?? false,
      isRightTurn: json['isRightTurn'] as bool? ?? true,
    );
  }
}

/// Kompletna telemetria wskaźnika trudności zjazdu [DescentTechnicalityRadarHud].
@immutable
class DescentTechnicalityRadarData {
  /// Nazwa przełęczy lub sektora zjazdowego.
  final String descentName;

  /// Nazwisko atakującego zjazdowca (np. `"T. Pidcock"`).
  final String attackerName;

  /// Trzyliterowy kod drużyny atakującego (np. `"IGD"`).
  final String attackerTeamCode;

  /// Liczba nadchodzących nawrotów 180° (hairpins) do końca zjazdu.
  final int upcomingHairpinsCount;

  /// Dystans do najbliższego nawrotu 180° w metrach.
  final double nextHairpinDistanceMeters;

  /// Aktualne ryzyko poślizgu w procentach (`0.0` – `100.0`).
  final double slipRiskPercent;

  /// Aktualny zysk sekundowy atakującego zjazdowca względem grupy pościgowej.
  /// Wartość dodatnia oznacza zysk czasowy (`+18.4 s`), ujemna stratę (`-2.1 s`).
  final double timeGainSeconds;

  /// Aktualna prędkość zjazdowca w km/h.
  final double currentSpeedKmh;

  /// Średnie nachylenie zjazdu w procentach (np. `-8.6`).
  final double averageGradientPercent;

  /// Czy nawierzchnia jest mokra / śliska.
  final bool isWetRoad;

  /// Czy trwa aktywny atak zjazdowy.
  final bool hasActiveAttack;

  /// Aktualna pozycja aerodynamiczna na zjeździe.
  final DescenderAeroPosture aeroPosture;

  /// Aktualny poziom agresywności pokonywania zakrętów.
  final DescenderAttackAggression aggression;

  /// Aktualna faza ataku zjazdowego.
  final DescenderAttackPhase phase;

  /// Lista najbliższych nawrotów 180° do wizualizacji na radarze.
  final List<DescentHairpinTurnData> upcomingHairpins;

  const DescentTechnicalityRadarData({
    required this.descentName,
    required this.attackerName,
    required this.attackerTeamCode,
    required this.upcomingHairpinsCount,
    required this.nextHairpinDistanceMeters,
    required this.slipRiskPercent,
    required this.timeGainSeconds,
    required this.currentSpeedKmh,
    required this.averageGradientPercent,
    this.isWetRoad = false,
    this.hasActiveAttack = true,
    this.aeroPosture = DescenderAeroPosture.supertuckTopTube,
    this.aggression = DescenderAttackAggression.aggressive,
    this.phase = DescenderAttackPhase.supertuckChute,
    this.upcomingHairpins = const <DescentHairpinTurnData>[],
  });

  /// Zwraca bezpieczną, znormalizowaną wartość ryzyka poślizgu w zakresie 0–100%.
  double get normalizedSlipRiskPercent {
    if (slipRiskPercent.isNaN || slipRiskPercent.isInfinite) {
      return 0.0;
    }
    return slipRiskPercent.clamp(0.0, 100.0);
  }

  /// Zwraca bezpieczną liczbę nadchodzących nawrotów (>= 0).
  int get safeUpcomingHairpinsCount =>
      upcomingHairpinsCount < 0 ? 0 : upcomingHairpinsCount;

  /// Zwraca bezpieczny dystans do kolejnego nawrotu w metrach (>= 0).
  double get safeNextHairpinDistanceMeters {
    if (nextHairpinDistanceMeters.isNaN ||
        nextHairpinDistanceMeters.isInfinite ||
        nextHairpinDistanceMeters < 0.0) {
      return 0.0;
    }
    return nextHairpinDistanceMeters;
  }

  /// Zwraca bezpieczny zysk sekundowy (0.0 przy NaN/Infinite).
  double get safeTimeGainSeconds {
    if (timeGainSeconds.isNaN || timeGainSeconds.isInfinite) {
      return 0.0;
    }
    return timeGainSeconds;
  }

  /// Wyliczony poziom ryzyka poślizgu.
  DescentSlipRiskLevel get riskLevel =>
      DescentSlipRiskLevel.fromPercent(normalizedSlipRiskPercent);

  DescentTechnicalityRadarData copyWith({
    String? descentName,
    String? attackerName,
    String? attackerTeamCode,
    int? upcomingHairpinsCount,
    double? nextHairpinDistanceMeters,
    double? slipRiskPercent,
    double? timeGainSeconds,
    double? currentSpeedKmh,
    double? averageGradientPercent,
    bool? isWetRoad,
    bool? hasActiveAttack,
    DescenderAeroPosture? aeroPosture,
    DescenderAttackAggression? aggression,
    DescenderAttackPhase? phase,
    List<DescentHairpinTurnData>? upcomingHairpins,
  }) {
    return DescentTechnicalityRadarData(
      descentName: descentName ?? this.descentName,
      attackerName: attackerName ?? this.attackerName,
      attackerTeamCode: attackerTeamCode ?? this.attackerTeamCode,
      upcomingHairpinsCount:
          upcomingHairpinsCount ?? this.upcomingHairpinsCount,
      nextHairpinDistanceMeters:
          nextHairpinDistanceMeters ?? this.nextHairpinDistanceMeters,
      slipRiskPercent: slipRiskPercent ?? this.slipRiskPercent,
      timeGainSeconds: timeGainSeconds ?? this.timeGainSeconds,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      averageGradientPercent:
          averageGradientPercent ?? this.averageGradientPercent,
      isWetRoad: isWetRoad ?? this.isWetRoad,
      hasActiveAttack: hasActiveAttack ?? this.hasActiveAttack,
      aeroPosture: aeroPosture ?? this.aeroPosture,
      aggression: aggression ?? this.aggression,
      phase: phase ?? this.phase,
      upcomingHairpins: upcomingHairpins ?? this.upcomingHairpins,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'descentName': descentName,
        'attackerName': attackerName,
        'attackerTeamCode': attackerTeamCode,
        'upcomingHairpinsCount': upcomingHairpinsCount,
        'nextHairpinDistanceMeters': nextHairpinDistanceMeters,
        'slipRiskPercent': slipRiskPercent,
        'timeGainSeconds': timeGainSeconds,
        'currentSpeedKmh': currentSpeedKmh,
        'averageGradientPercent': averageGradientPercent,
        'isWetRoad': isWetRoad,
        'hasActiveAttack': hasActiveAttack,
        'aeroPosture': aeroPosture.toJson(),
        'aggression': aggression.toJson(),
        'phase': phase.toJson(),
        'upcomingHairpins':
            upcomingHairpins.map((e) => e.toJson()).toList(growable: false),
      };

  factory DescentTechnicalityRadarData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawHairpins =
        json['upcomingHairpins'] as List<dynamic>? ?? const <dynamic>[];
    return DescentTechnicalityRadarData(
      descentName: json['descentName'] as String? ?? 'Zjazd Techniczny',
      attackerName: json['attackerName'] as String? ?? 'Brak ataku',
      attackerTeamCode: json['attackerTeamCode'] as String? ?? '---',
      upcomingHairpinsCount:
          (json['upcomingHairpinsCount'] as num?)?.toInt() ?? 0,
      nextHairpinDistanceMeters:
          (json['nextHairpinDistanceMeters'] as num?)?.toDouble() ?? 0.0,
      slipRiskPercent: (json['slipRiskPercent'] as num?)?.toDouble() ?? 0.0,
      timeGainSeconds: (json['timeGainSeconds'] as num?)?.toDouble() ?? 0.0,
      currentSpeedKmh: (json['currentSpeedKmh'] as num?)?.toDouble() ?? 0.0,
      averageGradientPercent:
          (json['averageGradientPercent'] as num?)?.toDouble() ?? 0.0,
      isWetRoad: json['isWetRoad'] as bool? ?? false,
      hasActiveAttack: json['hasActiveAttack'] as bool? ?? false,
      aeroPosture: DescenderAeroPosture.fromJson(
        json['aeroPosture'] as String? ?? 'drops',
      ),
      aggression: DescenderAttackAggression.fromJson(
        json['aggression'] as String? ?? 'aggressive',
      ),
      phase: DescenderAttackPhase.fromJson(
        json['phase'] as String? ?? 'inactive',
      ),
      upcomingHairpins: rawHairpins
          .whereType<Map<String, dynamic>>()
          .map(DescentHairpinTurnData.fromJson)
          .toList(growable: false),
    );
  }

  /// Przykładowe dane telemetryczne dla trybu podglądu i demonstracji.
  factory DescentTechnicalityRadarData.sample() {
    return const DescentTechnicalityRadarData(
      descentName: 'Col du Galibier — Serpentyny',
      attackerName: 'T. Pidcock',
      attackerTeamCode: 'IGD',
      upcomingHairpinsCount: 11,
      nextHairpinDistanceMeters: 165.0,
      slipRiskPercent: 54.0,
      timeGainSeconds: 22.8,
      currentSpeedKmh: 84.6,
      averageGradientPercent: -8.9,
      isWetRoad: true,
      hasActiveAttack: true,
      aeroPosture: DescenderAeroPosture.supertuckTopTube,
      aggression: DescenderAttackAggression.aggressive,
      phase: DescenderAttackPhase.lateBrakingEntry,
      upcomingHairpins: <DescentHairpinTurnData>[
        DescentHairpinTurnData(
          hairpinNumber: 1,
          distanceAheadMeters: 165.0,
          radiusMeters: 9.5,
          recommendedEntrySpeedKmh: 38.0,
          isWetPatch: true,
          isRightTurn: true,
        ),
        DescentHairpinTurnData(
          hairpinNumber: 2,
          distanceAheadMeters: 420.0,
          radiusMeters: 11.0,
          recommendedEntrySpeedKmh: 43.0,
          isWetPatch: false,
          isRightTurn: false,
        ),
        DescentHairpinTurnData(
          hairpinNumber: 3,
          distanceAheadMeters: 710.0,
          radiusMeters: 8.5,
          recommendedEntrySpeedKmh: 35.0,
          isWetPatch: true,
          isRightTurn: true,
        ),
      ],
    );
  }
}

/// Telewizyjny wskaźnik trudności zjazdu pokazujący liczbę nadchodzących
/// nawrotów 180° (hairpins), ryzyko poślizgu w procentach oraz aktualny zysk
/// sekundowy atakującego zjazdowca.
class DescentTechnicalityRadarHud extends StatefulWidget {
  final DescentTechnicalityRadarData data;

  /// Czy widget jest aktywny (przy `false` renderuje pełny stan `disabled`).
  final bool enabled;

  /// Czy sekcja szczegółów nawrotów i sterowania jest rozwinięta na starcie.
  final bool initiallyExpanded;

  /// Opcjonalny callback po zmianie poziomu agresji na zjeździe.
  final ValueChanged<DescenderAttackAggression>? onAggressionChanged;

  /// Opcjonalny callback po kliknięciu nagłówka / karty atakującego.
  final VoidCallback? onTapAttacker;

  /// Opcjonalny callback po rozwinięciu/zwinięciu szczegółów.
  final ValueChanged<bool>? onExpandChanged;

  const DescentTechnicalityRadarHud({
    super.key,
    required this.data,
    this.enabled = true,
    this.initiallyExpanded = true,
    this.onAggressionChanged,
    this.onTapAttacker,
    this.onExpandChanged,
  });

  @override
  State<DescentTechnicalityRadarHud> createState() =>
      _DescentTechnicalityRadarHudState();
}

class _DescentTechnicalityRadarHudState
    extends State<DescentTechnicalityRadarHud>
    with SingleTickerProviderStateMixin {
  late final AnimationController _radarController;
  final FocusNode _cardFocusNode = FocusNode();

  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.enabled) {
      _radarController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant DescentTechnicalityRadarHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _radarController.repeat();
      } else {
        _radarController.stop();
      }
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    _cardFocusNode.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    if (!widget.enabled) {
      return;
    }
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onExpandChanged?.call(_isExpanded);
  }

  Color _resolveBorderColor(DescentSlipRiskLevel riskLevel) {
    if (!widget.enabled) {
      return AppColors.cardBorder.withValues(alpha: 0.45);
    }
    if (_isFocused) {
      return AppColors.goldAccent;
    }
    if (_isPressed) {
      return AppColors.accentBlue;
    }
    if (_isHovered) {
      return riskLevel.isAlertActive
          ? riskLevel.color.withValues(alpha: 0.85)
          : AppColors.accentBlue.withValues(alpha: 0.75);
    }
    if (riskLevel.isAlertActive) {
      return riskLevel.color.withValues(alpha: 0.55);
    }
    return AppColors.cardBorder;
  }

  @override
  Widget build(BuildContext context) {
    final DescentTechnicalityRadarData data = widget.data;
    final DescentSlipRiskLevel riskLevel = data.riskLevel;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 460.0;
        final bool isCompact = maxWidth < 400.0;
        final bool isWideDesktop = maxWidth >= 680.0;

        return FocusableActionDetector(
          focusNode: _cardFocusNode,
          enabled: widget.enabled,
          onShowFocusHighlight: (bool focused) {
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
              onInvoke: (ActivateIntent intent) {
                if (widget.onTapAttacker != null) {
                  widget.onTapAttacker!.call();
                } else {
                  _toggleExpanded();
                }
                return null;
              },
            ),
          },
          child: MouseRegion(
            cursor: widget.enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.forbidden,
            onEnter: (_) {
              if (widget.enabled && !_isHovered) {
                setState(() => _isHovered = true);
              }
            },
            onExit: (_) {
              if (_isHovered || _isPressed) {
                setState(() {
                  _isHovered = false;
                  _isPressed = false;
                });
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) {
                if (widget.enabled) {
                  setState(() => _isPressed = true);
                }
              },
              onTapUp: (_) {
                if (_isPressed) {
                  setState(() => _isPressed = false);
                }
              },
              onTapCancel: () {
                if (_isPressed) {
                  setState(() => _isPressed = false);
                }
              },
              onTap: widget.enabled
                  ? (widget.onTapAttacker ?? _toggleExpanded)
                  : null,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                opacity: widget.enabled ? 1.0 : 0.48,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
                  decoration: BoxDecoration(
                    color: _isPressed
                        ? AppColors.surfaceLight
                        : _isHovered && widget.enabled
                            ? const Color(0xFF1D212A)
                            : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _resolveBorderColor(riskLevel),
                      width: _isFocused ? 1.5 : 1.0,
                    ),
                    boxShadow: <BoxShadow>[
                      if (_isHovered && widget.enabled)
                        BoxShadow(
                          color: riskLevel.color.withValues(alpha: 0.14),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _buildHeader(data, riskLevel, isCompact),
                      const SizedBox(height: 12),
                      if (isWideDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            SizedBox(
                              width: 112,
                              height: 112,
                              child: _buildRadarDial(data, riskLevel),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildMetricsGrid(
                                data,
                                riskLevel,
                                isCompact: false,
                              ),
                            ),
                          ],
                        )
                      else ...<Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            SizedBox(
                              width: isCompact ? 84 : 98,
                              height: isCompact ? 84 : 98,
                              child: _buildRadarDial(data, riskLevel),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildAttackerBanner(
                                data,
                                riskLevel,
                                isCompact: isCompact,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildMetricsGrid(
                          data,
                          riskLevel,
                          isCompact: isCompact,
                        ),
                      ],
                      if (isWideDesktop) ...<Widget>[
                        const SizedBox(height: 10),
                        _buildAttackerBanner(
                          data,
                          riskLevel,
                          isCompact: false,
                        ),
                      ],
                      AnimatedSize(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: _isExpanded
                            ? Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    _buildHairpinsStrip(data, isCompact),
                                    if (widget.onAggressionChanged !=
                                        null) ...<Widget>[
                                      const SizedBox(height: 10),
                                      _buildAggressionSelector(data, isCompact),
                                    ],
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    DescentTechnicalityRadarData data,
    DescentSlipRiskLevel riskLevel,
    bool isCompact,
  ) {
    return Row(
      children: <Widget>[
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primaryAccent.withValues(alpha: 0.55),
            ),
          ),
          child: const Icon(
            Icons.radar_rounded,
            size: 16,
            color: AppColors.goldAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'RADAR TRUDNOŚCI ZJAZDU',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 10 : 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.goldAccent,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                data.descentName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _SlipRiskPill(
          riskLevel: riskLevel,
          isWetRoad: data.isWetRoad,
          isCompact: isCompact,
        ),
        const SizedBox(width: 6),
        _ExpandToggleButton(
          isExpanded: _isExpanded,
          enabled: widget.enabled,
          onPressed: _toggleExpanded,
        ),
      ],
    );
  }

  Widget _buildRadarDial(
    DescentTechnicalityRadarData data,
    DescentSlipRiskLevel riskLevel,
  ) {
    return AnimatedBuilder(
      animation: _radarController,
      builder: (BuildContext context, Widget? child) {
        return CustomPaint(
          painter: _DescentHairpinRadarPainter(
            sweepProgress: widget.enabled ? _radarController.value : 0.25,
            slipRiskRatio: data.normalizedSlipRiskPercent / 100.0,
            riskColor: riskLevel.color,
            upcomingHairpinsCount: data.safeUpcomingHairpinsCount,
            isWetRoad: data.isWetRoad,
            hasActiveAttack: data.hasActiveAttack,
            nextTurnRight: data.upcomingHairpins.isNotEmpty
                ? data.upcomingHairpins.first.isRightTurn
                : true,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '${data.safeUpcomingHairpinsCount}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: AppColors.textPrimary,
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
                const Text(
                  '180°',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: AppColors.accentBlue,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttackerBanner(
    DescentTechnicalityRadarData data,
    DescentSlipRiskLevel riskLevel, {
    required bool isCompact,
  }) {
    final bool isGaining = data.safeTimeGainSeconds > 0.05;
    final bool isLosing = data.safeTimeGainSeconds < -0.05;
    final Color deltaColor = !data.hasActiveAttack
        ? AppColors.textSecondary
        : isGaining
            ? AppColors.statusSuccess
            : isLosing
                ? AppColors.crimsonAlert
                : AppColors.textPrimary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 12,
        vertical: isCompact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: data.hasActiveAttack
              ? AppColors.goldAccent.withValues(alpha: 0.35)
              : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  data.attackerTeamCode,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data.hasActiveAttack
                      ? data.attackerName
                      : 'Brak aktywnego ataku',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isCompact ? 12 : 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _InlineTelemetryChip(
                icon: Icons.speed_rounded,
                label: '${data.currentSpeedKmh.toStringAsFixed(1)} km/h',
                color: AppColors.accentBlue,
              ),
              _InlineTelemetryChip(
                icon: Icons.trending_down_rounded,
                label: '${data.averageGradientPercent.toStringAsFixed(1)}%',
                color: AppColors.textSecondary,
              ),
              _InlineTelemetryChip(
                icon: Icons.air_rounded,
                label: data.aeroPosture.labelPl,
                color: deltaColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(
    DescentTechnicalityRadarData data,
    DescentSlipRiskLevel riskLevel, {
    required bool isCompact,
  }) {
    final double gain = data.safeTimeGainSeconds;
    final String gainFormatted = gain > 0
        ? '+${gain.toStringAsFixed(1)} s'
        : '${gain.toStringAsFixed(1)} s';
    final Color gainColor = !data.hasActiveAttack
        ? AppColors.textSecondary
        : gain > 0.05
            ? AppColors.statusSuccess
            : gain < -0.05
                ? AppColors.crimsonAlert
                : AppColors.textPrimary;

    final Widget hairpinsTile = _KpiMetricTile(
      label: 'NAWROTY 180°',
      value: '${data.safeUpcomingHairpinsCount}',
      subtitle: data.safeUpcomingHairpinsCount > 0
          ? 'Następny za ${data.safeNextHairpinDistanceMeters.round()} m'
          : 'Prosty zjazd do doliny',
      accentColor: AppColors.accentBlue,
      icon: Icons.u_turn_right_rounded,
      isCompact: isCompact,
    );

    final Widget slipTile = TweenAnimationBuilder<double>(
      tween: Tween<double>(end: data.normalizedSlipRiskPercent),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double animatedSlip, Widget? child) {
        return _KpiMetricTile(
          label: 'RYZYKO POŚLIZGU',
          value: '${animatedSlip.round()}%',
          subtitle: '${riskLevel.labelPl}${data.isWetRoad ? ' • Mokro' : ''}',
          accentColor: riskLevel.color,
          icon: Icons.warning_amber_rounded,
          isCompact: isCompact,
          progressRatio: animatedSlip / 100.0,
        );
      },
    );

    final Widget gainTile = TweenAnimationBuilder<double>(
      tween: Tween<double>(end: gain),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double animatedGain, Widget? child) {
        final String animatedText = animatedGain > 0.05
            ? '+${animatedGain.toStringAsFixed(1)} s'
            : '${animatedGain.toStringAsFixed(1)} s';
        return _KpiMetricTile(
          label: 'ZYSK ATAKUJĄCEGO',
          value: data.hasActiveAttack ? animatedText : gainFormatted,
          subtitle: data.hasActiveAttack
              ? data.aggression.labelPl
              : 'Neutralne tempo',
          accentColor: gainColor,
          icon: Icons.timer_outlined,
          isCompact: isCompact,
        );
      },
    );

    if (isCompact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: hairpinsTile),
              const SizedBox(width: 8),
              Expanded(child: slipTile),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: gainTile),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: hairpinsTile),
        const SizedBox(width: 8),
        Expanded(child: slipTile),
        const SizedBox(width: 8),
        Expanded(child: gainTile),
      ],
    );
  }

  Widget _buildHairpinsStrip(
    DescentTechnicalityRadarData data,
    bool isCompact,
  ) {
    if (data.upcomingHairpins.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Row(
          children: <Widget>[
            Icon(
              Icons.check_circle_outline_rounded,
              size: 16,
              color: AppColors.statusSuccess,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Brak ciasnych nawrotów 180° w najbliższym sektorze',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'NADCHODZĄCE SERPENTYNY 180°',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: data.upcomingHairpins.take(3).map(
              (DescentHairpinTurnData turn) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 8 : 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: turn.isWetPatch
                          ? AppColors.amberWarning.withValues(alpha: 0.6)
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        turn.isRightTurn
                            ? Icons.u_turn_right_rounded
                            : Icons.u_turn_left_rounded,
                        size: 15,
                        color: turn.isWetPatch
                            ? AppColors.amberWarning
                            : AppColors.accentBlue,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '#${turn.hairpinNumber} • ${turn.distanceAheadMeters.round()} m • max ${turn.recommendedEntrySpeedKmh.round()} km/h',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontFeatures: <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ).toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _buildAggressionSelector(
    DescentTechnicalityRadarData data,
    bool isCompact,
  ) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: DescenderAttackAggression.values.map(
        (DescenderAttackAggression mode) {
          final bool isSelected = data.aggression == mode;
          return _AggressionModeChip(
            mode: mode,
            selected: isSelected,
            enabled: widget.enabled,
            isCompact: isCompact,
            onSelected: () => widget.onAggressionChanged?.call(mode),
          );
        },
      ).toList(growable: false),
    );
  }
}

class _SlipRiskPill extends StatelessWidget {
  final DescentSlipRiskLevel riskLevel;
  final bool isWetRoad;
  final bool isCompact;

  const _SlipRiskPill({
    required this.riskLevel,
    required this.isWetRoad,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 7 : 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: riskLevel.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: riskLevel.color.withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            isWetRoad ? Icons.water_drop_rounded : Icons.tire_repair_rounded,
            size: 12,
            color: riskLevel.color,
          ),
          const SizedBox(width: 4),
          Text(
            riskLevel.labelPl,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 9.5 : 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: riskLevel.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandToggleButton extends StatefulWidget {
  final bool isExpanded;
  final bool enabled;
  final VoidCallback onPressed;

  const _ExpandToggleButton({
    required this.isExpanded,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_ExpandToggleButton> createState() => _ExpandToggleButtonState();
}

class _ExpandToggleButtonState extends State<_ExpandToggleButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (bool focused) {
        setState(() => _focused = focused);
      },
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: widget.enabled ? widget.onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _hovered && widget.enabled
                  ? AppColors.surfaceLight
                  : AppColors.background.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : AppColors.cardBorder,
              ),
            ),
            child: Icon(
              widget.isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: widget.enabled
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color accentColor;
  final IconData icon;
  final bool isCompact;
  final double? progressRatio;

  const _KpiMetricTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
    required this.isCompact,
    this.progressRatio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 9 : 11),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 13, color: accentColor),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 18 : 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: accentColor,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          if (progressRatio != null) ...<Widget>[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressRatio!.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
          ],
          const SizedBox(height: 5),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineTelemetryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InlineTelemetryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _AggressionModeChip extends StatefulWidget {
  final DescenderAttackAggression mode;
  final bool selected;
  final bool enabled;
  final bool isCompact;
  final VoidCallback onSelected;

  const _AggressionModeChip({
    required this.mode,
    required this.selected,
    required this.enabled,
    required this.isCompact,
    required this.onSelected,
  });

  @override
  State<_AggressionModeChip> createState() => _AggressionModeChipState();
}

class _AggressionModeChipState extends State<_AggressionModeChip> {
  bool _hovered = false;
  bool _focused = false;

  Color get _modeColor {
    switch (widget.mode) {
      case DescenderAttackAggression.controlled:
        return AppColors.statusSuccess;
      case DescenderAttackAggression.aggressive:
        return AppColors.goldAccent;
      case DescenderAttackAggression.kamikaze:
        return AppColors.crimsonAlert;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (bool focused) {
        setState(() => _focused = focused);
      },
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: widget.enabled ? widget.onSelected : null,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCompact ? 9 : 11,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: widget.selected
                  ? _modeColor.withValues(alpha: 0.2)
                  : _hovered && widget.enabled
                      ? AppColors.surfaceLight
                      : AppColors.background.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : widget.selected
                        ? _modeColor
                        : AppColors.cardBorder,
              ),
            ),
            child: Text(
              widget.mode.labelPl,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                color: widget.selected
                    ? _modeColor
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DescentHairpinRadarPainter extends CustomPainter {
  final double sweepProgress;
  final double slipRiskRatio;
  final Color riskColor;
  final int upcomingHairpinsCount;
  final bool isWetRoad;
  final bool hasActiveAttack;
  final bool nextTurnRight;

  _DescentHairpinRadarPainter({
    required this.sweepProgress,
    required this.slipRiskRatio,
    required this.riskColor,
    required this.upcomingHairpinsCount,
    required this.isWetRoad,
    required this.hasActiveAttack,
    required this.nextTurnRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) / 2 - 4;

    final Paint bgPaint = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    final Paint ringPaint = Paint()
      ..color = AppColors.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(center, radius * 0.66, ringPaint);

    // Łuk ryzyka poślizgu wokół tarczy radaru.
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);
    final Paint trackArcPaint = Paint()
      ..color = AppColors.surfaceLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, -math.pi * 0.75, math.pi * 1.5, false, trackArcPaint);

    final Paint riskArcPaint = Paint()
      ..color = riskColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      arcRect,
      -math.pi * 0.75,
      math.pi * 1.5 * slipRiskRatio.clamp(0.0, 1.0),
      false,
      riskArcPaint,
    );

    // Linia symbolizująca nadchodzący nawrót 180°.
    if (upcomingHairpinsCount > 0) {
      final double sign = nextTurnRight ? 1.0 : -1.0;
      final Path hairpinPath = Path()
        ..moveTo(center.dx - sign * radius * 0.34, center.dy + radius * 0.34)
        ..lineTo(center.dx - sign * radius * 0.34, center.dy - radius * 0.14)
        ..arcToPoint(
          Offset(center.dx + sign * radius * 0.34, center.dy - radius * 0.14),
          radius: Radius.circular(radius * 0.34),
          clockwise: nextTurnRight,
        )
        ..lineTo(center.dx + sign * radius * 0.34, center.dy + radius * 0.34);

      final Paint hairpinPaint = Paint()
        ..color = (isWetRoad ? AppColors.amberWarning : AppColors.accentBlue)
            .withValues(alpha: 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(hairpinPath, hairpinPaint);
    }

    // Animowany promień skanera radaru.
    if (hasActiveAttack) {
      final double angle = sweepProgress * 2 * math.pi - math.pi / 2;
      final Offset endPoint = Offset(
        center.dx + math.cos(angle) * (radius - 4),
        center.dy + math.sin(angle) * (radius - 4),
      );
      final Paint sweepPaint = Paint()
        ..color = riskColor.withValues(alpha: 0.45)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(center, endPoint, sweepPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DescentHairpinRadarPainter oldDelegate) {
    return oldDelegate.sweepProgress != sweepProgress ||
        oldDelegate.slipRiskRatio != slipRiskRatio ||
        oldDelegate.riskColor != riskColor ||
        oldDelegate.upcomingHairpinsCount != upcomingHairpinsCount ||
        oldDelegate.isWetRoad != isWetRoad ||
        oldDelegate.hasActiveAttack != hasActiveAttack ||
        oldDelegate.nextTurnRight != nextTurnRight;
  }
}
