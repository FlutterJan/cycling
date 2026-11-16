import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Poziom zagrożenia przekroczeniem limitu czasu OTL (Hors Délais).
enum OtlWarningSeverity {
  /// Zapas powyżej progu ostrzegawczego (>= 2 minuty).
  safe,

  /// Zapas spadł poniżej 2 minut — wymagana natychmiastowa reakcja taktyczna.
  warning,

  /// Zapas poniżej 45 sekund lub przekroczony limit — krytyczne ryzyko DNF/OTL.
  critical,

  /// Alert nieaktywny lub wyłączony z poziomu HUD.
  disabled;

  /// Etykieta statusu wyświetlana w nagłówku banera.
  String get badgeLabel {
    switch (this) {
      case OtlWarningSeverity.safe:
        return 'OTL SAFE';
      case OtlWarningSeverity.warning:
        return 'OTL WARNING';
      case OtlWarningSeverity.critical:
        return 'HORS DÉLAIS RISK';
      case OtlWarningSeverity.disabled:
        return 'OTL OFFLINE';
    }
  }

  /// Tytuł komunikatu dla dyrektora sportowego.
  String get headlinePl {
    switch (this) {
      case OtlWarningSeverity.safe:
        return 'Bezpieczny zapas do limitu czasu';
      case OtlWarningSeverity.warning:
        return 'Zagrożenie limitem czasu (OTL < 2:00)';
      case OtlWarningSeverity.critical:
        return 'KRYTYCZNY ALERT OTL — WYŚLIJ POMOC!';
      case OtlWarningSeverity.disabled:
        return 'Monitorowanie limitu czasu wyłączone';
    }
  }

  /// Kolor przewodni z palety [AppColors].
  Color get color {
    switch (this) {
      case OtlWarningSeverity.safe:
        return AppColors.statusSuccess;
      case OtlWarningSeverity.warning:
        return AppColors.amberWarning;
      case OtlWarningSeverity.critical:
        return AppColors.crimsonAlert;
      case OtlWarningSeverity.disabled:
        return AppColors.textSecondary;
    }
  }

  /// Czy alert powinien pulsować i przyciągać uwagę gracza.
  bool get isAlertActive =>
      this == OtlWarningSeverity.warning || this == OtlWarningSeverity.critical;
}

/// Stan rozkazu cofnięcia pomocników z grupy przed Grupetto.
enum OtlDropBackOrderStatus {
  /// Rozkaz gotowy do wydania przez gracza.
  available,

  /// Koledzy z drużyny cofają się, aby pomóc sprinterowi w Grupetto.
  dispatched,

  /// Brak dostępnych pomocników przed Grupetto (wszyscy już w grupie lub poza wyścigiem).
  noDomestiquesAvailable,

  /// Rozkaz zablokowany (np. wyłączony HUD lub bezpieczny zapas).
  disabled;

  /// Tekst etykiety statusu rozkazu.
  String get labelPl {
    switch (this) {
      case OtlDropBackOrderStatus.available:
        return 'Pomoc gotowa';
      case OtlDropBackOrderStatus.dispatched:
        return 'Koledzy w drodze';
      case OtlDropBackOrderStatus.noDomestiquesAvailable:
        return 'Brak pomocników';
      case OtlDropBackOrderStatus.disabled:
        return 'Rozkaz niedostępny';
    }
  }
}

/// Kandydat z drużyny gracza, który może cofnąć się z peletonu lub wcześniejszej grupy do Grupetto.
@immutable
class OtlDomestiqueCandidate {
  /// Unikalny identyfikator kolarza.
  final String riderId;

  /// Imię i nazwisko lub skrócone nazwisko kolarza (np. `K. Wiśniewski`).
  final String riderName;

  /// Rola taktyczna na etapie (np. `Rouleur`, `Domestique`, `Leadout`).
  final String roleLabel;

  /// Pozostała energia / świeżość kolarza w procentach (0..100).
  final int energyPercent;

  /// Przewaga czasowa nad Grupetto w sekundach.
  final double gapAheadSeconds;

  /// Szacowany zysk czasowy dla sprintera po cofnięciu się pomocnika (w sekundach).
  final double estimatedTimeGainSeconds;

  /// Czy kolarz jest aktualnie zaznaczony do wysłania rozkazu.
  final bool isSelected;

  /// Czy kolarz otrzymał już rozkaz cofnięcia się.
  final bool isDispatched;

  const OtlDomestiqueCandidate({
    required this.riderId,
    required this.riderName,
    this.roleLabel = 'Domestique',
    required this.energyPercent,
    required this.gapAheadSeconds,
    required this.estimatedTimeGainSeconds,
    this.isSelected = true,
    this.isDispatched = false,
  });

  OtlDomestiqueCandidate copyWith({
    String? riderId,
    String? riderName,
    String? roleLabel,
    int? energyPercent,
    double? gapAheadSeconds,
    double? estimatedTimeGainSeconds,
    bool? isSelected,
    bool? isDispatched,
  }) {
    return OtlDomestiqueCandidate(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      roleLabel: roleLabel ?? this.roleLabel,
      energyPercent: (energyPercent ?? this.energyPercent).clamp(0, 100),
      gapAheadSeconds: math.max(0.0, gapAheadSeconds ?? this.gapAheadSeconds),
      estimatedTimeGainSeconds: math.max(
        0.0,
        estimatedTimeGainSeconds ?? this.estimatedTimeGainSeconds,
      ),
      isSelected: isSelected ?? this.isSelected,
      isDispatched: isDispatched ?? this.isDispatched,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'roleLabel': roleLabel,
      'energyPercent': energyPercent,
      'gapAheadSeconds': gapAheadSeconds,
      'estimatedTimeGainSeconds': estimatedTimeGainSeconds,
      'isSelected': isSelected,
      'isDispatched': isDispatched,
    };
  }

  factory OtlDomestiqueCandidate.fromJson(Map<String, dynamic> json) {
    return OtlDomestiqueCandidate(
      riderId: json['riderId'] as String? ?? '',
      riderName: json['riderName'] as String? ?? 'Pomocnik',
      roleLabel: json['roleLabel'] as String? ?? 'Domestique',
      energyPercent: (json['energyPercent'] as num? ?? 70).toInt().clamp(0, 100),
      gapAheadSeconds: (json['gapAheadSeconds'] as num? ?? 60).toDouble(),
      estimatedTimeGainSeconds:
          (json['estimatedTimeGainSeconds'] as num? ?? 45).toDouble(),
      isSelected: json['isSelected'] as bool? ?? true,
      isDispatched: json['isDispatched'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OtlDomestiqueCandidate &&
        other.riderId == riderId &&
        other.riderName == riderName &&
        other.roleLabel == roleLabel &&
        other.energyPercent == energyPercent &&
        other.gapAheadSeconds == gapAheadSeconds &&
        other.estimatedTimeGainSeconds == estimatedTimeGainSeconds &&
        other.isSelected == isSelected &&
        other.isDispatched == isDispatched;
  }

  @override
  int get hashCode => Object.hash(
        riderId,
        riderName,
        roleLabel,
        energyPercent,
        gapAheadSeconds,
        estimatedTimeGainSeconds,
        isSelected,
        isDispatched,
      );
}

/// Niemutowalny model danych telemetrycznych ostrzeżenia o limicie czasu OTL w Grupetto.
@immutable
class OtlTimeCutWarningData {
  /// Nazwisko zagrożonego sprintera gracza jadącego w Grupetto.
  final String endangeredRiderName;

  /// Trzyliterowy kod drużyny (np. `PLM`).
  final String teamShortCode;

  /// Opis grupy, w której jedzie sprinter (np. `Grupetto (38 kolarzy)`).
  final String grupettoLabel;

  /// Przewidywany zapas czasowy do limitu OTL w sekundach (< 120s wyzwala alert; ujemny oznacza przekroczenie limitu).
  final double marginToOtlSeconds;

  /// Przewidywana strata czasowa na mecie do zwycięzcy etapu w sekundach.
  final double projectedFinishDelaySeconds;

  /// Wyliczony limit czasu OTL dla etapu w sekundach (np. +39:00 = 2340s).
  final double allowedOtlLimitSeconds;

  /// Pozostały dystans do mety w kilometrach.
  final double remainingKmToFinish;

  /// Aktualna średnia prędkość Grupetto (km/h).
  final double currentGrupettoSpeedKmh;

  /// Wymagana prędkość do zmieszczenia się w limicie OTL (km/h).
  final double requiredSpeedKmh;

  /// Próg ostrzegawczy zapasu OTL w sekundach (domyślnie 120s = 2 minuty).
  final double warningThresholdSeconds;

  /// Lista kolegów z drużyny mogących cofnąć się z peletonu do Grupetto.
  final List<OtlDomestiqueCandidate> availableDomestiques;

  /// Aktualny status rozkazu cofnięcia pomocników.
  final OtlDropBackOrderStatus orderStatus;

  /// Czy monitorowanie HUD jest aktywne.
  final bool isEnabled;

  const OtlTimeCutWarningData({
    required this.endangeredRiderName,
    this.teamShortCode = 'PRO',
    this.grupettoLabel = 'Grupetto',
    required this.marginToOtlSeconds,
    required this.projectedFinishDelaySeconds,
    required this.allowedOtlLimitSeconds,
    required this.remainingKmToFinish,
    required this.currentGrupettoSpeedKmh,
    required this.requiredSpeedKmh,
    this.warningThresholdSeconds = 120.0,
    this.availableDomestiques = const [],
    this.orderStatus = OtlDropBackOrderStatus.available,
    this.isEnabled = true,
  });

  /// Wyliczony poziom zagrożenia OTL.
  OtlWarningSeverity get severity {
    if (!isEnabled) return OtlWarningSeverity.disabled;
    if (marginToOtlSeconds < 45.0) return OtlWarningSeverity.critical;
    if (marginToOtlSeconds < warningThresholdSeconds) {
      return OtlWarningSeverity.warning;
    }
    return OtlWarningSeverity.safe;
  }

  /// Czy baner ostrzegawczy powinien zostać aktywnie wyświetlony.
  bool get shouldDisplayAlert =>
      isEnabled && marginToOtlSeconds < warningThresholdSeconds;

  /// Brakująca prędkość do bezpiecznego dowiezienia limitu OTL.
  double get speedDeficitKmh =>
      math.max(0.0, requiredSpeedKmh - currentGrupettoSpeedKmh);

  /// Identyfikatory aktualnie wybranych pomocników gotowych do cofnięcia.
  List<String> get selectedDomestiqueIds => availableDomestiques
      .where((d) => d.isSelected && !d.isDispatched)
      .map((d) => d.riderId)
      .toList(growable: false);

  /// Szacowany zysk czasowy (s) po wysłaniu wybranych lub już wysłanych pomocników.
  double get estimatedRecoverySeconds {
    final active = availableDomestiques
        .where((d) => d.isDispatched || d.isSelected)
        .toList(growable: false);
    if (active.isEmpty) return 0.0;
    return active.fold<double>(
      0.0,
      (sum, d) => sum + d.estimatedTimeGainSeconds,
    );
  }

  /// Prognozowany zapas czasowy do OTL (s) po wsparciu kolegów z drużyny.
  double get projectedMarginAfterHelpSeconds =>
      marginToOtlSeconds + estimatedRecoverySeconds;

  OtlTimeCutWarningData copyWith({
    String? endangeredRiderName,
    String? teamShortCode,
    String? grupettoLabel,
    double? marginToOtlSeconds,
    double? projectedFinishDelaySeconds,
    double? allowedOtlLimitSeconds,
    double? remainingKmToFinish,
    double? currentGrupettoSpeedKmh,
    double? requiredSpeedKmh,
    double? warningThresholdSeconds,
    List<OtlDomestiqueCandidate>? availableDomestiques,
    OtlDropBackOrderStatus? orderStatus,
    bool? isEnabled,
  }) {
    return OtlTimeCutWarningData(
      endangeredRiderName: endangeredRiderName ?? this.endangeredRiderName,
      teamShortCode: teamShortCode ?? this.teamShortCode,
      grupettoLabel: grupettoLabel ?? this.grupettoLabel,
      marginToOtlSeconds: marginToOtlSeconds ?? this.marginToOtlSeconds,
      projectedFinishDelaySeconds: math.max(
        0.0,
        projectedFinishDelaySeconds ?? this.projectedFinishDelaySeconds,
      ),
      allowedOtlLimitSeconds: math.max(
        60.0,
        allowedOtlLimitSeconds ?? this.allowedOtlLimitSeconds,
      ),
      remainingKmToFinish: math.max(
        0.0,
        remainingKmToFinish ?? this.remainingKmToFinish,
      ),
      currentGrupettoSpeedKmh: math.max(
        0.0,
        currentGrupettoSpeedKmh ?? this.currentGrupettoSpeedKmh,
      ),
      requiredSpeedKmh: math.max(
        0.0,
        requiredSpeedKmh ?? this.requiredSpeedKmh,
      ),
      warningThresholdSeconds: math.max(
        10.0,
        warningThresholdSeconds ?? this.warningThresholdSeconds,
      ),
      availableDomestiques: availableDomestiques ?? this.availableDomestiques,
      orderStatus: orderStatus ?? this.orderStatus,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'endangeredRiderName': endangeredRiderName,
      'teamShortCode': teamShortCode,
      'grupettoLabel': grupettoLabel,
      'marginToOtlSeconds': marginToOtlSeconds,
      'projectedFinishDelaySeconds': projectedFinishDelaySeconds,
      'allowedOtlLimitSeconds': allowedOtlLimitSeconds,
      'remainingKmToFinish': remainingKmToFinish,
      'currentGrupettoSpeedKmh': currentGrupettoSpeedKmh,
      'requiredSpeedKmh': requiredSpeedKmh,
      'warningThresholdSeconds': warningThresholdSeconds,
      'availableDomestiques':
          availableDomestiques.map((e) => e.toJson()).toList(),
      'orderStatus': orderStatus.name,
      'isEnabled': isEnabled,
    };
  }

  factory OtlTimeCutWarningData.fromJson(Map<String, dynamic> json) {
    final rawDomestiques = json['availableDomestiques'] as List<dynamic>? ?? [];
    final statusName = json['orderStatus'] as String? ?? 'available';
    final status = OtlDropBackOrderStatus.values.firstWhere(
      (e) => e.name == statusName,
      orElse: () => OtlDropBackOrderStatus.available,
    );

    return OtlTimeCutWarningData(
      endangeredRiderName:
          json['endangeredRiderName'] as String? ?? 'Sprinter',
      teamShortCode: json['teamShortCode'] as String? ?? 'PRO',
      grupettoLabel: json['grupettoLabel'] as String? ?? 'Grupetto',
      marginToOtlSeconds:
          (json['marginToOtlSeconds'] as num? ?? 90.0).toDouble(),
      projectedFinishDelaySeconds:
          (json['projectedFinishDelaySeconds'] as num? ?? 2250.0).toDouble(),
      allowedOtlLimitSeconds:
          (json['allowedOtlLimitSeconds'] as num? ?? 2340.0).toDouble(),
      remainingKmToFinish:
          (json['remainingKmToFinish'] as num? ?? 24.5).toDouble(),
      currentGrupettoSpeedKmh:
          (json['currentGrupettoSpeedKmh'] as num? ?? 33.4).toDouble(),
      requiredSpeedKmh:
          (json['requiredSpeedKmh'] as num? ?? 35.8).toDouble(),
      warningThresholdSeconds:
          (json['warningThresholdSeconds'] as num? ?? 120.0).toDouble(),
      availableDomestiques: rawDomestiques
          .whereType<Map<String, dynamic>>()
          .map(OtlDomestiqueCandidate.fromJson)
          .toList(growable: false),
      orderStatus: status,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  /// Przykładowy stan krytycznego zagrożenia OTL z dwoma pomocnikami w peletonie.
  factory OtlTimeCutWarningData.sampleWarning({
    double marginToOtlSeconds = 74.0,
    OtlDropBackOrderStatus orderStatus = OtlDropBackOrderStatus.available,
  }) {
    return OtlTimeCutWarningData(
      endangeredRiderName: 'K. Majewski',
      teamShortCode: 'PLM',
      grupettoLabel: 'Grupetto (36 kolarzy)',
      marginToOtlSeconds: marginToOtlSeconds,
      projectedFinishDelaySeconds: 2266.0,
      allowedOtlLimitSeconds: 2340.0,
      remainingKmToFinish: 18.4,
      currentGrupettoSpeedKmh: 34.2,
      requiredSpeedKmh: 36.5,
      availableDomestiques: const [
        OtlDomestiqueCandidate(
          riderId: 'dom-1',
          riderName: 'T. Zieliński',
          roleLabel: 'Rouleur',
          energyPercent: 78,
          gapAheadSeconds: 95,
          estimatedTimeGainSeconds: 58,
          isSelected: true,
        ),
        OtlDomestiqueCandidate(
          riderId: 'dom-2',
          riderName: 'P. Nowak',
          roleLabel: 'Leadout',
          energyPercent: 64,
          gapAheadSeconds: 120,
          estimatedTimeGainSeconds: 42,
          isSelected: true,
        ),
      ],
      orderStatus: orderStatus,
    );
  }

  /// Przykładowy stan bezpiecznego zapasu czasowego.
  factory OtlTimeCutWarningData.sampleSafe() {
    return const OtlTimeCutWarningData(
      endangeredRiderName: 'K. Majewski',
      teamShortCode: 'PLM',
      grupettoLabel: 'Grupetto (41 kolarzy)',
      marginToOtlSeconds: 245.0,
      projectedFinishDelaySeconds: 2095.0,
      allowedOtlLimitSeconds: 2340.0,
      remainingKmToFinish: 22.0,
      currentGrupettoSpeedKmh: 36.8,
      requiredSpeedKmh: 35.1,
      availableDomestiques: [],
      orderStatus: OtlDropBackOrderStatus.available,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OtlTimeCutWarningData) return false;
    if (other.availableDomestiques.length != availableDomestiques.length) {
      return false;
    }
    for (var i = 0; i < availableDomestiques.length; i++) {
      if (other.availableDomestiques[i] != availableDomestiques[i]) {
        return false;
      }
    }
    return other.endangeredRiderName == endangeredRiderName &&
        other.teamShortCode == teamShortCode &&
        other.grupettoLabel == grupettoLabel &&
        other.marginToOtlSeconds == marginToOtlSeconds &&
        other.projectedFinishDelaySeconds == projectedFinishDelaySeconds &&
        other.allowedOtlLimitSeconds == allowedOtlLimitSeconds &&
        other.remainingKmToFinish == remainingKmToFinish &&
        other.currentGrupettoSpeedKmh == currentGrupettoSpeedKmh &&
        other.requiredSpeedKmh == requiredSpeedKmh &&
        other.warningThresholdSeconds == warningThresholdSeconds &&
        other.orderStatus == orderStatus &&
        other.isEnabled == isEnabled;
  }

  @override
  int get hashCode => Object.hash(
        endangeredRiderName,
        teamShortCode,
        grupettoLabel,
        marginToOtlSeconds,
        projectedFinishDelaySeconds,
        allowedOtlLimitSeconds,
        remainingKmToFinish,
        currentGrupettoSpeedKmh,
        requiredSpeedKmh,
        warningThresholdSeconds,
        Object.hashAll(availableDomestiques),
        orderStatus,
        isEnabled,
      );
}

/// Pulsujący baner HUD ostrzegający o zbliżaniu się sprintera w Grupetto do limitu czasu OTL
/// wraz z przyciskiem wydania rozkazu cofnięcia kolegów z drużyny do pomocy.
class OtlTimeCutWarningBannerHud extends StatefulWidget {
  /// Dane telemetryczne dotyczące zagrożenia limitem OTL.
  final OtlTimeCutWarningData data;

  /// Callback wywoływany po wydaniu rozkazu cofnięcia wybranych pomocników.
  final ValueChanged<List<String>>? onDispatchDropBackOrder;

  /// Callback wywoływany przy anulowaniu wysłanego rozkazu.
  final VoidCallback? onCancelDropBackOrder;

  /// Callback przełączający wybór konkretnego pomocnika do cofnięcia.
  final ValueChanged<String>? onToggleDomestiqueSelection;

  /// Callback do skupienia kamery 3D na zagrożonym sprinterze.
  final VoidCallback? onFocusRiderIn3d;

  /// Callback zamykający / minimalizujący alert przez gracza.
  final VoidCallback? onDismiss;

  /// Czy wyświetlać dyskretny pasek monitorujący nawet gdy zapas >= progu 2 minut.
  final bool showWhenSafe;

  /// Czy sekcja wyboru pomocników ma być domyślnie rozwinięta.
  final bool initiallyExpanded;

  /// Czy włączyć animację pulsowania alertu (można wyłączyć w trybie oszczędnym).
  final bool enablePulseAnimation;

  const OtlTimeCutWarningBannerHud({
    super.key,
    required this.data,
    this.onDispatchDropBackOrder,
    this.onCancelDropBackOrder,
    this.onToggleDomestiqueSelection,
    this.onFocusRiderIn3d,
    this.onDismiss,
    this.showWhenSafe = false,
    this.initiallyExpanded = true,
    this.enablePulseAnimation = true,
  });

  @override
  State<OtlTimeCutWarningBannerHud> createState() =>
      _OtlTimeCutWarningBannerHudState();
}

class _OtlTimeCutWarningBannerHudState extends State<OtlTimeCutWarningBannerHud>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late bool _isExpanded;
  bool _isCardHovered = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    _syncPulseState();
  }

  @override
  void didUpdateWidget(covariant OtlTimeCutWarningBannerHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.severity != widget.data.severity ||
        oldWidget.enablePulseAnimation != widget.enablePulseAnimation ||
        oldWidget.data.isEnabled != widget.data.isEnabled) {
      _syncPulseState();
    }
  }

  void _syncPulseState() {
    final shouldPulse = widget.enablePulseAnimation &&
        widget.data.isEnabled &&
        widget.data.severity.isAlertActive;
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

  static String _formatSignedMargin(double seconds) {
    final isNegative = seconds < 0;
    final absSecs = seconds.abs().round();
    final mins = absSecs ~/ 60;
    final secs = absSecs % 60;
    final sign = isNegative ? '-' : '+';
    return '$sign${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  static String _formatClockDuration(double seconds) {
    final clamped = math.max(0, seconds.round());
    final mins = clamped ~/ 60;
    final secs = clamped % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  bool get _canDispatchOrder {
    final data = widget.data;
    if (!data.isEnabled) return false;
    if (data.orderStatus == OtlDropBackOrderStatus.dispatched ||
        data.orderStatus == OtlDropBackOrderStatus.noDomestiquesAvailable ||
        data.orderStatus == OtlDropBackOrderStatus.disabled) {
      return false;
    }
    return data.selectedDomestiqueIds.isNotEmpty &&
        widget.onDispatchDropBackOrder != null;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    if (!data.shouldDisplayAlert && !widget.showWhenSafe) {
      return const SizedBox.shrink();
    }

    final severity = data.severity;
    final accentColor = severity.color;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final isCompact = maxWidth < 520;
        final isTablet = maxWidth >= 520 && maxWidth < 860;

        return MouseRegion(
          onEnter: (_) => setState(() => _isCardHovered = true),
          onExit: (_) => setState(() => _isCardHovered = false),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final pulse =
                  severity.isAlertActive ? _pulseAnimation.value : 0.0;
              final borderAlpha =
                  severity.isAlertActive ? (0.45 + pulse * 0.45) : 0.55;
              final glowAlpha =
                  severity.isAlertActive ? (0.10 + pulse * 0.22) : 0.0;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: _isCardHovered
                      ? AppColors.surfaceLight
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: severity == OtlWarningSeverity.disabled
                        ? AppColors.cardBorder
                        : accentColor.withValues(alpha: borderAlpha),
                    width: severity.isAlertActive ? 1.4 : 1.0,
                  ),
                  boxShadow: [
                    if (glowAlpha > 0)
                      BoxShadow(
                        color: accentColor.withValues(alpha: glowAlpha),
                        blurRadius: 14 + pulse * 8,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: child,
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderRow(
                    data: data,
                    severity: severity,
                    accentColor: accentColor,
                    isCompact: isCompact,
                  ),
                  if (_isExpanded) ...[
                    Container(height: 1, color: AppColors.cardBorder),
                    Padding(
                      padding: EdgeInsets.all(isCompact ? 12 : 14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTelemetryStrip(
                            data: data,
                            severity: severity,
                            accentColor: accentColor,
                            isCompact: isCompact,
                            isTablet: isTablet,
                          ),
                          const SizedBox(height: 12),
                          _buildDomestiqueDispatchSection(
                            data: data,
                            accentColor: accentColor,
                            isCompact: isCompact,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderRow({
    required OtlTimeCutWarningData data,
    required OtlWarningSeverity severity,
    required Color accentColor,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: severity.isAlertActive ? 0.22 : 0.10),
            AppColors.surface,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _PulseBeaconDot(
            color: accentColor,
            isPulsing: widget.enablePulseAnimation && severity.isAlertActive,
            animation: _pulseAnimation,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Text(
                        severity.badgeLabel,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: accentColor,
                        ),
                      ),
                    ),
                    Text(
                      '${data.endangeredRiderName} (${data.teamShortCode})',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      data.grupettoLabel,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  severity.headlinePl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: severity.isAlertActive
                        ? accentColor
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _MarginCountdownChip(
            marginSeconds: data.marginToOtlSeconds,
            color: accentColor,
            formattedValue: _formatSignedMargin(data.marginToOtlSeconds),
          ),
          const SizedBox(width: 6),
          if (widget.onFocusRiderIn3d != null)
            _HudIconButton(
              icon: Icons.videocam_rounded,
              tooltip: 'Kamera na sprintera',
              enabled: data.isEnabled,
              onPressed: widget.onFocusRiderIn3d,
            ),
          _HudIconButton(
            icon: _isExpanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            tooltip: _isExpanded ? 'Zwiń szczegóły' : 'Rozwiń szczegóły',
            enabled: true,
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
          ),
          if (widget.onDismiss != null)
            _HudIconButton(
              icon: Icons.close_rounded,
              tooltip: 'Ukryj alert',
              enabled: true,
              onPressed: widget.onDismiss,
            ),
        ],
      ),
    );
  }

  Widget _buildTelemetryStrip({
    required OtlTimeCutWarningData data,
    required OtlWarningSeverity severity,
    required Color accentColor,
    required bool isCompact,
    required bool isTablet,
  }) {
    final metrics = [
      _OtlMetricBox(
        label: 'Do mety',
        value: '${data.remainingKmToFinish.toStringAsFixed(1)} km',
        icon: Icons.flag_rounded,
        valueColor: AppColors.textPrimary,
      ),
      _OtlMetricBox(
        label: 'Prędkość / Wymagana',
        value:
            '${data.currentGrupettoSpeedKmh.toStringAsFixed(1)} / ${data.requiredSpeedKmh.toStringAsFixed(1)} km/h',
        icon: Icons.speed_rounded,
        valueColor: data.speedDeficitKmh > 0.2
            ? accentColor
            : AppColors.statusSuccess,
      ),
      _OtlMetricBox(
        label: 'Strata / Limit OTL',
        value:
            '+${_formatClockDuration(data.projectedFinishDelaySeconds)} / +${_formatClockDuration(data.allowedOtlLimitSeconds)}',
        icon: Icons.timer_outlined,
        valueColor: AppColors.textPrimary,
      ),
      _OtlMetricBox(
        label: 'Po wsparciu ekipy',
        value: _formatSignedMargin(data.projectedMarginAfterHelpSeconds),
        icon: Icons.groups_rounded,
        valueColor: data.projectedMarginAfterHelpSeconds >=
                data.warningThresholdSeconds
            ? AppColors.statusSuccess
            : AppColors.goldAccent,
      ),
    ];

    if (isCompact) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: metrics
            .map(
              (m) => SizedBox(
                width: 162,
                child: m,
              ),
            )
            .toList(growable: false),
      );
    }

    if (isTablet) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: metrics
            .map(
              (m) => SizedBox(
                width: 210,
                child: m,
              ),
            )
            .toList(growable: false),
      );
    }

    return Row(
      children: [
        for (var i = 0; i < metrics.length; i++) ...[
          Expanded(child: metrics[i]),
          if (i < metrics.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildDomestiqueDispatchSection({
    required OtlTimeCutWarningData data,
    required Color accentColor,
    required bool isCompact,
  }) {
    final isDispatched =
        data.orderStatus == OtlDropBackOrderStatus.dispatched;
    final hasDomestiques = data.availableDomestiques.isNotEmpty &&
        data.orderStatus != OtlDropBackOrderStatus.noDomestiquesAvailable;

    return Container(
      padding: EdgeInsets.all(isCompact ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDispatched
              ? AppColors.statusSuccess.withValues(alpha: 0.45)
              : AppColors.cardBorder,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isDispatched
                    ? Icons.check_circle_outline_rounded
                    : Icons.campaign_rounded,
                size: 16,
                color: isDispatched
                    ? AppColors.statusSuccess
                    : AppColors.goldAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isDispatched
                      ? 'Rozkaz wysłany: koledzy cofają się z peletonu do Grupetto (+${data.estimatedRecoverySeconds.round()} s)'
                      : hasDomestiques
                          ? 'Wybierz pomocników do cofnięcia i holowania sprintera do mety:'
                          : 'Brak dostępnych pomocników przed Grupetto do wysłania wsparcia.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDispatched
                        ? AppColors.statusSuccess
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (hasDomestiques) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final rider in data.availableDomestiques)
                  _DomestiqueChipButton(
                    candidate: rider,
                    enabled: data.isEnabled &&
                        !isDispatched &&
                        widget.onToggleDomestiqueSelection != null,
                    onTap: () =>
                        widget.onToggleDomestiqueSelection?.call(rider.riderId),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (isCompact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPrimaryOrderButton(
                  data: data,
                  accentColor: accentColor,
                  isDispatched: isDispatched,
                ),
                if (isDispatched && widget.onCancelDropBackOrder != null) ...[
                  const SizedBox(height: 8),
                  _buildCancelOrderButton(data: data),
                ],
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildPrimaryOrderButton(
                    data: data,
                    accentColor: accentColor,
                    isDispatched: isDispatched,
                  ),
                ),
                if (isDispatched && widget.onCancelDropBackOrder != null) ...[
                  const SizedBox(width: 10),
                  _buildCancelOrderButton(data: data),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPrimaryOrderButton({
    required OtlTimeCutWarningData data,
    required Color accentColor,
    required bool isDispatched,
  }) {
    final selectedIds = data.selectedDomestiqueIds;
    final String label;
    if (isDispatched) {
      label = 'Koledzy w drodze do Grupetto';
    } else if (data.orderStatus ==
            OtlDropBackOrderStatus.noDomestiquesAvailable ||
        data.availableDomestiques.isEmpty) {
      label = 'Brak pomocników do cofnięcia';
    } else if (selectedIds.isEmpty) {
      label = 'Zaznacz min. 1 pomocnika';
    } else {
      label =
          'Cofnij kolegów (${selectedIds.length}) — odrobisz +${data.estimatedRecoverySeconds.round()} s';
    }

    return _TacticalActionButton(
      label: label,
      icon: isDispatched
          ? Icons.directions_bike_rounded
          : Icons.reply_all_rounded,
      accentColor: isDispatched ? AppColors.statusSuccess : accentColor,
      enabled: _canDispatchOrder,
      isCompleted: isDispatched,
      onPressed: () {
        if (_canDispatchOrder) {
          widget.onDispatchDropBackOrder?.call(selectedIds);
        }
      },
    );
  }

  Widget _buildCancelOrderButton({required OtlTimeCutWarningData data}) {
    return _TacticalActionButton(
      label: 'Odwołaj rozkaz',
      icon: Icons.undo_rounded,
      accentColor: AppColors.primaryAccent,
      enabled: data.isEnabled && widget.onCancelDropBackOrder != null,
      isSecondary: true,
      onPressed: widget.onCancelDropBackOrder,
    );
  }
}

class _PulseBeaconDot extends StatelessWidget {
  final Color color;
  final bool isPulsing;
  final Animation<double> animation;

  const _PulseBeaconDot({
    required this.color,
    required this.isPulsing,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = isPulsing ? animation.value : 0.0;
        return Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.14 + t * 0.20),
            border: Border.all(
              color: color.withValues(alpha: 0.45 + t * 0.45),
              width: 1.2,
            ),
          ),
          child: Container(
            width: 9 + t * 2,
            height: 9 + t * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        );
      },
    );
  }
}

class _MarginCountdownChip extends StatelessWidget {
  final double marginSeconds;
  final Color color;
  final String formattedValue;

  const _MarginCountdownChip({
    required this.marginSeconds,
    required this.color,
    required this.formattedValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.65)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'ZAPAS OTL',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            formattedValue,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _OtlMetricBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color valueColor;

  const _OtlMetricBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DomestiqueChipButton extends StatefulWidget {
  final OtlDomestiqueCandidate candidate;
  final bool enabled;
  final VoidCallback onTap;

  const _DomestiqueChipButton({
    required this.candidate,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_DomestiqueChipButton> createState() => _DomestiqueChipButtonState();
}

class _DomestiqueChipButtonState extends State<_DomestiqueChipButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.candidate;
    final active = c.isSelected || c.isDispatched;
    final highlightColor =
        c.isDispatched ? AppColors.statusSuccess : AppColors.goldAccent;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      child: GestureDetector(
        onTapDown:
            widget.enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp:
            widget.enabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _isPressed = false) : null,
        onTap: widget.enabled ? widget.onTap : null,
        child: MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.diagonal3Values(
              _isPressed ? 0.98 : 1.0,
              _isPressed ? 0.98 : 1.0,
              1.0,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: !widget.enabled && !c.isDispatched
                  ? AppColors.surface.withValues(alpha: 0.5)
                  : active
                      ? highlightColor.withValues(alpha: _isHovered ? 0.22 : 0.14)
                      : (_isHovered
                          ? AppColors.surfaceLight
                          : AppColors.surface),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isFocused
                    ? AppColors.accentBlue
                    : active
                        ? highlightColor.withValues(alpha: 0.75)
                        : AppColors.cardBorder,
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  c.isDispatched
                      ? Icons.check_circle_rounded
                      : (c.isSelected
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded),
                  size: 15,
                  color: active ? highlightColor : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      c.riderName,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: widget.enabled || c.isDispatched
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${c.roleLabel} • ${c.energyPercent}% • +${c.estimatedTimeGainSeconds.round()}s',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10.5,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TacticalActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool enabled;
  final bool isCompleted;
  final bool isSecondary;
  final VoidCallback? onPressed;

  const _TacticalActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.enabled,
    this.isCompleted = false,
    this.isSecondary = false,
    this.onPressed,
  });

  @override
  State<_TacticalActionButton> createState() => _TacticalActionButtonState();
}

class _TacticalActionButtonState extends State<_TacticalActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isCompleted
        ? AppColors.statusSuccess.withValues(alpha: 0.16)
        : !widget.enabled
            ? AppColors.surfaceLight.withValues(alpha: 0.45)
            : widget.isSecondary
                ? (_isHovered ? AppColors.surfaceLight : AppColors.surface)
                : widget.accentColor.withValues(
                    alpha: _isPressed
                        ? 0.92
                        : (_isHovered ? 0.30 : 0.22),
                  );

    final fg = widget.isCompleted
        ? AppColors.statusSuccess
        : !widget.enabled
            ? AppColors.textSecondary
            : AppColors.textPrimary;

    final borderColor = _isFocused
        ? AppColors.accentBlue
        : widget.isCompleted
            ? AppColors.statusSuccess.withValues(alpha: 0.65)
            : !widget.enabled
                ? AppColors.cardBorder
                : widget.accentColor.withValues(alpha: _isHovered ? 0.9 : 0.65);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      child: GestureDetector(
        onTapDown:
            widget.enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp:
            widget.enabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _isPressed = false) : null,
        onTap: widget.enabled ? widget.onPressed : null,
        child: MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.isCompleted
                      ? AppColors.statusSuccess
                      : (widget.enabled
                          ? widget.accentColor
                          : AppColors.textSecondary),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                      color: fg,
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

class _HudIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback? onPressed;

  const _HudIconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    this.onPressed,
  });

  @override
  State<_HudIconButton> createState() => _HudIconButtonState();
}

class _HudIconButtonState extends State<_HudIconButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        onShowFocusHighlight: (v) => setState(() => _isFocused = v),
        onShowHoverHighlight: (v) => setState(() => _isHovered = v),
        child: InkWell(
          onTap: widget.enabled ? widget.onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _isHovered && widget.enabled
                  ? AppColors.surfaceLight
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isFocused ? AppColors.accentBlue : Colors.transparent,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: widget.enabled
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }
}
