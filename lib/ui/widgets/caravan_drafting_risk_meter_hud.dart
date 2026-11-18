import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../engine/physics/drafting_behind_team_car_and_motos_solver.dart';

/// Akcja taktyczna dostępna z poziomu HUD ryzyka jazdy za wozami technicznymi.
enum CaravanTacticalAction {
  /// Utrzymaj pozycję w cieniu aerodynamicznym pojazdu.
  holdDraft('Trzymaj cień', 'Hold Draft', Icons.air_rounded),

  /// Opuść ślad aerodynamiczny i zredukuj ryzyko kary UCI.
  easeOutOfWake('Opuść cień', 'Exit Wake', Icons.logout_rounded),

  /// Przeskocz do kolejnego pojazdu w kolumnie (Car-Hopping).
  carHopNext('Skok do kolejnego', 'Hop Next Car', Icons.fast_forward_rounded);

  final String labelPl;
  final String labelEn;
  final IconData icon;

  const CaravanTacticalAction(this.labelPl, this.labelEn, this.icon);

  String label(String languageCode) => languageCode == 'en' ? labelEn : labelPl;
}

/// Kompletny model danych telemetrycznych dla wskaźnika [CaravanDraftingRiskMeterHud].
@immutable
class CaravanDraftingRiskHudData {
  /// Nazwisko kolarza wracającego za kolumną pojazdów.
  final String riderName;

  /// Trzyliterowy kod drużyny (np. `"ARK"`, `"IGD"`).
  final String riderTeamCode;

  /// Typ pojazdu, za którym jedzie kolarz.
  final CaravanVehicleType vehicleType;

  /// Kontekst regulaminowy manewru (powrót po kraksie, skok przez kolumnę, strefa finałowa).
  final CaravanDraftingContext context;

  /// Poziom ryzyka interwencji komisarza UCI.
  final CaravanPenaltyRiskLevel riskLevel;

  /// Skumulowana ekspozycja na karę UCI w procentach (`0.0` – `100.0`).
  final double penaltyExposurePercent;

  /// Chwilowe tempo narastania podejrzeń komisarza `[punkty/s]`.
  final double exposureRatePerSec;

  /// Prawdopodobieństwo nałożenia kary czasowej (`0.0` – `1.0`).
  final double timePenaltyProbability;

  /// Prognozowana kara czasowa w sekundach (`0`, `20`, `40`, `60`).
  final int projectedTimePenaltySeconds;

  /// Prognozowana grzywna finansowa w CHF (`0` lub `200`).
  final int projectedFineChf;

  /// Odległość podłużna od tylnego zderzaka pojazdu do przedniego koła kolarza `[m]`.
  final double longitudinalDistanceMeters;

  /// Przesunięcie poprzeczne względem osi pojazdu `[m]`.
  final double lateralOffsetMeters;

  /// Oszczędność mocy aerodynamicznej dzięki cieniowi `[W]`.
  final double aeroPowerSavedWatts;

  /// Procentowa redukcja oporu aerodynamicznego (`0.0` – `100.0`).
  final double dragReductionPercent;

  /// Aktualna prędkość kolarza `[km/h]`.
  final double riderSpeedKmh;

  /// Zysk prędkości przy tej samej mocy co solo `[km/h]`.
  final double isoPowerSpeedGainKmh;

  /// Czy w zasięgu wzroku (`< 60 m`) znajduje się komisarz UCI.
  final bool commissaireInSight;

  /// Czy kamera transmisji TV aktualnie śledzi kolarza.
  final bool isTvCameraFocused;

  /// Czy kolarz jest niebezpiecznie blisko zderzaka (`< 0.9 m` — ryzyko kolizji / Sticky Bottle).
  final bool isDangerouslyCloseToBumper;

  /// Pozostała strata do peletonu lub grupy docelowej `[m]`.
  final double remainingGapToPelotonMeters;

  /// Czas dotychczasowego przebywania w cieniu pojazdu `[s]`.
  final double exposureDurationSeconds;

  /// Czy kontroler HUD jest aktywny (odblokowany do wydawania rozkazów).
  final bool isEnabled;

  const CaravanDraftingRiskHudData({
    required this.riderName,
    required this.riderTeamCode,
    required this.vehicleType,
    required this.context,
    required this.riskLevel,
    required this.penaltyExposurePercent,
    required this.exposureRatePerSec,
    required this.timePenaltyProbability,
    required this.projectedTimePenaltySeconds,
    required this.projectedFineChf,
    required this.longitudinalDistanceMeters,
    this.lateralOffsetMeters = 0.0,
    required this.aeroPowerSavedWatts,
    required this.dragReductionPercent,
    required this.riderSpeedKmh,
    this.isoPowerSpeedGainKmh = 0.0,
    this.commissaireInSight = false,
    this.isTvCameraFocused = false,
    this.isDangerouslyCloseToBumper = false,
    this.remainingGapToPelotonMeters = 0.0,
    this.exposureDurationSeconds = 0.0,
    this.isEnabled = true,
  });

  /// Tworzy model HUD bezpośrednio z danych wejściowych i wyniku [DraftingBehindTeamCarAndMotosSolver].
  factory CaravanDraftingRiskHudData.fromSolver({
    required String riderName,
    required String riderTeamCode,
    required CaravanDraftingInput input,
    required CaravanDraftingResult result,
    double remainingGapToPelotonMeters = 0.0,
    bool isEnabled = true,
  }) {
    return CaravanDraftingRiskHudData(
      riderName: riderName,
      riderTeamCode: riderTeamCode,
      vehicleType: input.vehicleType,
      context: input.context,
      riskLevel: result.riskLevel,
      penaltyExposurePercent: _sanitize(result.updatedPenaltyExposure, 0.0, 100.0),
      exposureRatePerSec: _sanitize(result.penaltyExposureRatePerSec, -50.0, 50.0),
      timePenaltyProbability: _sanitize(result.timePenaltyProbability, 0.0, 1.0),
      projectedTimePenaltySeconds: result.projectedTimePenaltySeconds < 0
          ? 0
          : result.projectedTimePenaltySeconds,
      projectedFineChf: result.projectedFineChf < 0 ? 0 : result.projectedFineChf,
      longitudinalDistanceMeters:
          _sanitize(input.longitudinalDistanceMeters, 0.0, 40.0),
      lateralOffsetMeters: _sanitize(input.lateralOffsetMeters, -5.0, 5.0),
      aeroPowerSavedWatts: _sanitize(result.aeroPowerSavedWatts, 0.0, 1200.0),
      dragReductionPercent: _sanitize(result.dragReductionPercent, 0.0, 100.0),
      riderSpeedKmh: _sanitize(result.riderSpeedMs * 3.6, 0.0, 130.0),
      isoPowerSpeedGainKmh: _sanitize(result.isoPowerSpeedGainKmh, -20.0, 40.0),
      commissaireInSight: input.commissaireInSight,
      isTvCameraFocused: input.isTvCameraFocused,
      isDangerouslyCloseToBumper: result.isDangerouslyCloseToBumper,
      remainingGapToPelotonMeters:
          _sanitize(remainingGapToPelotonMeters, 0.0, 50000.0),
      exposureDurationSeconds:
          _sanitize(input.exposureDurationSeconds, 0.0, 3600.0),
      isEnabled: isEnabled,
    );
  }

  CaravanDraftingRiskHudData copyWith({
    String? riderName,
    String? riderTeamCode,
    CaravanVehicleType? vehicleType,
    CaravanDraftingContext? context,
    CaravanPenaltyRiskLevel? riskLevel,
    double? penaltyExposurePercent,
    double? exposureRatePerSec,
    double? timePenaltyProbability,
    int? projectedTimePenaltySeconds,
    int? projectedFineChf,
    double? longitudinalDistanceMeters,
    double? lateralOffsetMeters,
    double? aeroPowerSavedWatts,
    double? dragReductionPercent,
    double? riderSpeedKmh,
    double? isoPowerSpeedGainKmh,
    bool? commissaireInSight,
    bool? isTvCameraFocused,
    bool? isDangerouslyCloseToBumper,
    double? remainingGapToPelotonMeters,
    double? exposureDurationSeconds,
    bool? isEnabled,
  }) {
    return CaravanDraftingRiskHudData(
      riderName: riderName ?? this.riderName,
      riderTeamCode: riderTeamCode ?? this.riderTeamCode,
      vehicleType: vehicleType ?? this.vehicleType,
      context: context ?? this.context,
      riskLevel: riskLevel ?? this.riskLevel,
      penaltyExposurePercent:
          penaltyExposurePercent ?? this.penaltyExposurePercent,
      exposureRatePerSec: exposureRatePerSec ?? this.exposureRatePerSec,
      timePenaltyProbability:
          timePenaltyProbability ?? this.timePenaltyProbability,
      projectedTimePenaltySeconds:
          projectedTimePenaltySeconds ?? this.projectedTimePenaltySeconds,
      projectedFineChf: projectedFineChf ?? this.projectedFineChf,
      longitudinalDistanceMeters:
          longitudinalDistanceMeters ?? this.longitudinalDistanceMeters,
      lateralOffsetMeters: lateralOffsetMeters ?? this.lateralOffsetMeters,
      aeroPowerSavedWatts: aeroPowerSavedWatts ?? this.aeroPowerSavedWatts,
      dragReductionPercent: dragReductionPercent ?? this.dragReductionPercent,
      riderSpeedKmh: riderSpeedKmh ?? this.riderSpeedKmh,
      isoPowerSpeedGainKmh: isoPowerSpeedGainKmh ?? this.isoPowerSpeedGainKmh,
      commissaireInSight: commissaireInSight ?? this.commissaireInSight,
      isTvCameraFocused: isTvCameraFocused ?? this.isTvCameraFocused,
      isDangerouslyCloseToBumper:
          isDangerouslyCloseToBumper ?? this.isDangerouslyCloseToBumper,
      remainingGapToPelotonMeters:
          remainingGapToPelotonMeters ?? this.remainingGapToPelotonMeters,
      exposureDurationSeconds:
          exposureDurationSeconds ?? this.exposureDurationSeconds,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'riderName': riderName,
        'riderTeamCode': riderTeamCode,
        'vehicleType': vehicleType.name,
        'context': context.name,
        'riskLevel': riskLevel.name,
        'penaltyExposurePercent': penaltyExposurePercent,
        'exposureRatePerSec': exposureRatePerSec,
        'timePenaltyProbability': timePenaltyProbability,
        'projectedTimePenaltySeconds': projectedTimePenaltySeconds,
        'projectedFineChf': projectedFineChf,
        'longitudinalDistanceMeters': longitudinalDistanceMeters,
        'lateralOffsetMeters': lateralOffsetMeters,
        'aeroPowerSavedWatts': aeroPowerSavedWatts,
        'dragReductionPercent': dragReductionPercent,
        'riderSpeedKmh': riderSpeedKmh,
        'isoPowerSpeedGainKmh': isoPowerSpeedGainKmh,
        'commissaireInSight': commissaireInSight,
        'isTvCameraFocused': isTvCameraFocused,
        'isDangerouslyCloseToBumper': isDangerouslyCloseToBumper,
        'remainingGapToPelotonMeters': remainingGapToPelotonMeters,
        'exposureDurationSeconds': exposureDurationSeconds,
        'isEnabled': isEnabled,
      };

  factory CaravanDraftingRiskHudData.fromJson(Map<String, dynamic> json) {
    final String vehicleName =
        json['vehicleType'] as String? ?? CaravanVehicleType.teamSupportCar.name;
    final String contextName = json['context'] as String? ??
        CaravanDraftingContext.mechanicalOrCrashReturn.name;
    final String riskName =
        json['riskLevel'] as String? ?? CaravanPenaltyRiskLevel.clean.name;

    return CaravanDraftingRiskHudData(
      riderName: json['riderName'] as String? ?? 'Rider',
      riderTeamCode: json['riderTeamCode'] as String? ?? 'PRO',
      vehicleType: CaravanVehicleType.values.firstWhere(
        (v) => v.name == vehicleName,
        orElse: () => CaravanVehicleType.teamSupportCar,
      ),
      context: CaravanDraftingContext.values.firstWhere(
        (c) => c.name == contextName,
        orElse: () => CaravanDraftingContext.mechanicalOrCrashReturn,
      ),
      riskLevel: CaravanPenaltyRiskLevel.values.firstWhere(
        (r) => r.name == riskName,
        orElse: () => CaravanPenaltyRiskLevel.clean,
      ),
      penaltyExposurePercent: _sanitize(
        (json['penaltyExposurePercent'] as num?)?.toDouble() ?? 0.0,
        0.0,
        100.0,
      ),
      exposureRatePerSec: _sanitize(
        (json['exposureRatePerSec'] as num?)?.toDouble() ?? 0.0,
        -50.0,
        50.0,
      ),
      timePenaltyProbability: _sanitize(
        (json['timePenaltyProbability'] as num?)?.toDouble() ?? 0.0,
        0.0,
        1.0,
      ),
      projectedTimePenaltySeconds:
          (json['projectedTimePenaltySeconds'] as num?)?.toInt() ?? 0,
      projectedFineChf: (json['projectedFineChf'] as num?)?.toInt() ?? 0,
      longitudinalDistanceMeters: _sanitize(
        (json['longitudinalDistanceMeters'] as num?)?.toDouble() ?? 3.0,
        0.0,
        40.0,
      ),
      lateralOffsetMeters: _sanitize(
        (json['lateralOffsetMeters'] as num?)?.toDouble() ?? 0.0,
        -5.0,
        5.0,
      ),
      aeroPowerSavedWatts: _sanitize(
        (json['aeroPowerSavedWatts'] as num?)?.toDouble() ?? 0.0,
        0.0,
        1200.0,
      ),
      dragReductionPercent: _sanitize(
        (json['dragReductionPercent'] as num?)?.toDouble() ?? 0.0,
        0.0,
        100.0,
      ),
      riderSpeedKmh: _sanitize(
        (json['riderSpeedKmh'] as num?)?.toDouble() ?? 45.0,
        0.0,
        130.0,
      ),
      isoPowerSpeedGainKmh: _sanitize(
        (json['isoPowerSpeedGainKmh'] as num?)?.toDouble() ?? 0.0,
        -20.0,
        40.0,
      ),
      commissaireInSight: json['commissaireInSight'] as bool? ?? false,
      isTvCameraFocused: json['isTvCameraFocused'] as bool? ?? false,
      isDangerouslyCloseToBumper:
          json['isDangerouslyCloseToBumper'] as bool? ?? false,
      remainingGapToPelotonMeters: _sanitize(
        (json['remainingGapToPelotonMeters'] as num?)?.toDouble() ?? 0.0,
        0.0,
        50000.0,
      ),
      exposureDurationSeconds: _sanitize(
        (json['exposureDurationSeconds'] as num?)?.toDouble() ?? 0.0,
        0.0,
        3600.0,
      ),
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  /// Bezpieczna wartość ekspozycji w przedziale `[0.0, 100.0]`.
  double get safeExposurePercent => _sanitize(penaltyExposurePercent, 0.0, 100.0);

  /// Czy poziom ryzyka wymaga pulsującego ostrzeżenia w HUD.
  bool get isHighRiskAlert =>
      isEnabled &&
      (riskLevel == CaravanPenaltyRiskLevel.fineAndPoints ||
          riskLevel == CaravanPenaltyRiskLevel.timePenaltyRisk ||
          isDangerouslyCloseToBumper);

  static double _sanitize(double value, double min, double max) {
    if (value.isNaN || value.isInfinite) {
      return min;
    }
    return value.clamp(min, max).toDouble();
  }
}

/// Wskaźnik HUD ryzyka kary sędziowskiej UCI podczas powrotu za wozami technicznymi.
///
/// Prezentuje:
/// - zegar ekspozycji na karę UCI (`0–100%`) z podziałem na progi ostrzeżeń,
/// - wizualizację pozycji kolarza w tunelu aerodynamicznym za pojazdem,
/// - status obecności komisarza UCI, kamer TV i ryzyka `Sticky Bottle` (`< 0.9 m`),
/// - prognozowaną karę czasową (`+20s+`) i grzywnę (`200 CHF`),
/// - szybkie przyciski taktyczne z pełnymi stanami `hover`/`active`/`disabled`/`focus`.
class CaravanDraftingRiskMeterHud extends StatefulWidget {
  final CaravanDraftingRiskHudData data;
  final ValueChanged<CaravanTacticalAction>? onActionSelected;
  final VoidCallback? onDismissAlert;
  final String languageCode;
  final bool initiallyExpanded;
  final CaravanTacticalAction? activeAction;

  const CaravanDraftingRiskMeterHud({
    super.key,
    required this.data,
    this.onActionSelected,
    this.onDismissAlert,
    this.languageCode = 'pl',
    this.initiallyExpanded = true,
    this.activeAction,
  });

  @override
  State<CaravanDraftingRiskMeterHud> createState() =>
      _CaravanDraftingRiskMeterHudState();
}

class _CaravanDraftingRiskMeterHudState
    extends State<CaravanDraftingRiskMeterHud>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late bool _isExpanded;
  bool _isCardHovered = false;
  CaravanTacticalAction? _selectedAction;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _selectedAction = widget.activeAction;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _syncPulseAnimation();
  }

  @override
  void didUpdateWidget(covariant CaravanDraftingRiskMeterHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeAction != oldWidget.activeAction) {
      _selectedAction = widget.activeAction;
    }
    if (widget.data.isHighRiskAlert != oldWidget.data.isHighRiskAlert) {
      _syncPulseAnimation();
    }
  }

  void _syncPulseAnimation() {
    if (widget.data.isHighRiskAlert) {
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

  Color _riskColor(CaravanPenaltyRiskLevel level) {
    switch (level) {
      case CaravanPenaltyRiskLevel.clean:
        return AppColors.statusSuccess;
      case CaravanPenaltyRiskLevel.warning:
        return AppColors.amberWarning;
      case CaravanPenaltyRiskLevel.fineAndPoints:
        return AppColors.powerZone5;
      case CaravanPenaltyRiskLevel.timePenaltyRisk:
        return AppColors.crimsonAlert;
    }
  }

  String _riskLabel(CaravanPenaltyRiskLevel level) {
    return widget.languageCode == 'en' ? level.labelEn : level.labelPl;
  }

  String _vehicleLabel(CaravanVehicleType type) {
    return widget.languageCode == 'en' ? type.labelEn : type.labelPl;
  }

  String _contextLabel(CaravanDraftingContext context) {
    return widget.languageCode == 'en' ? context.labelEn : context.labelPl;
  }

  String _t(String pl, String en) => widget.languageCode == 'en' ? en : pl;

  void _handleActionTap(CaravanTacticalAction action) {
    if (!widget.data.isEnabled) {
      return;
    }
    setState(() {
      _selectedAction = action;
    });
    widget.onActionSelected?.call(action);
  }

  @override
  Widget build(BuildContext context) {
    final CaravanDraftingRiskHudData data = widget.data;
    final Color activeRiskColor = _riskColor(data.riskLevel);
    final bool isEn = widget.languageCode == 'en';

    return MouseRegion(
      onEnter: (_) => setState(() => _isCardHovered = true),
      onExit: (_) => setState(() => _isCardHovered = false),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (BuildContext context, Widget? child) {
          final double pulse =
              data.isHighRiskAlert ? _pulseController.value : 0.0;
          final Color borderColor = !data.isEnabled
              ? AppColors.cardBorder.withValues(alpha: 0.45)
              : data.isHighRiskAlert
                  ? Color.lerp(
                      activeRiskColor.withValues(alpha: 0.45),
                      activeRiskColor,
                      0.35 + 0.65 * pulse,
                    )!
                  : _isCardHovered
                      ? AppColors.accentBlue.withValues(alpha: 0.55)
                      : AppColors.cardBorder;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: data.isEnabled
                  ? AppColors.surface
                  : AppColors.surface.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: data.isHighRiskAlert ? 1.5 : 1.0,
              ),
              boxShadow: data.isHighRiskAlert
                  ? <BoxShadow>[
                      BoxShadow(
                        color: activeRiskColor.withValues(
                          alpha: 0.08 + 0.14 * pulse,
                        ),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: Opacity(
              opacity: data.isEnabled ? 1.0 : 0.62,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double width = constraints.maxWidth.isFinite
                        ? constraints.maxWidth
                        : 400.0;
                    final bool isCompact = width < 460;
                    final bool isWide = width >= 860;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _buildHeader(
                          data: data,
                          riskColor: activeRiskColor,
                          isCompact: isCompact,
                          isEn: isEn,
                        ),
                        if (_isExpanded) ...<Widget>[
                          const SizedBox(height: 12),
                          if (isWide)
                            _buildWideBody(
                              data: data,
                              riskColor: activeRiskColor,
                              pulse: pulse,
                            )
                          else if (isCompact)
                            _buildCompactBody(
                              data: data,
                              riskColor: activeRiskColor,
                              pulse: pulse,
                            )
                          else
                            _buildMediumBody(
                              data: data,
                              riskColor: activeRiskColor,
                              pulse: pulse,
                            ),
                          const SizedBox(height: 12),
                          _buildActionBar(isCompact: isCompact),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader({
    required CaravanDraftingRiskHudData data,
    required Color riskColor,
    required bool isCompact,
    required bool isEn,
  }) {
    final String safeRider =
        data.riderName.trim().isEmpty ? 'Rider' : data.riderName.trim();
    final String safeCode =
        data.riderTeamCode.trim().isEmpty ? 'PRO' : data.riderTeamCode.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: riskColor.withValues(alpha: 0.45)),
          ),
          child: Icon(
            data.vehicleType.isMotorbike
                ? Icons.two_wheeler_rounded
                : Icons.directions_car_rounded,
            color: riskColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      _t('RYZYKO KARY ZA WOZEM', 'CARAVAN DRAFTING RISK'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.textSecondary,
                      ),
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
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      safeCode,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '$safeRider · ${_vehicleLabel(data.vehicleType)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (!isCompact) ...<Widget>[
          _RiskStatusBadge(
            label: _riskLabel(data.riskLevel),
            color: riskColor,
          ),
          const SizedBox(width: 6),
        ],
        if (widget.onDismissAlert != null) ...<Widget>[
          _HudIconButton(
            icon: Icons.notifications_off_outlined,
            tooltip: _t('Wycisz alarm', 'Mute alert'),
            enabled: data.isEnabled,
            onPressed: widget.onDismissAlert,
          ),
          const SizedBox(width: 4),
        ],
        _HudIconButton(
          icon: _isExpanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          tooltip: _isExpanded
              ? _t('Zwiń HUD', 'Collapse HUD')
              : _t('Rozwiń HUD', 'Expand HUD'),
          enabled: true,
          onPressed: () => setState(() => _isExpanded = !_isExpanded),
        ),
      ],
    );
  }

  Widget _buildCompactBody({
    required CaravanDraftingRiskHudData data,
    required Color riskColor,
    required double pulse,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _buildGaugeBox(
              data: data,
              riskColor: riskColor,
              pulse: pulse,
              size: 104,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _RiskStatusBadge(
                    label: _riskLabel(data.riskLevel),
                    color: riskColor,
                  ),
                  const SizedBox(height: 8),
                  _buildMetricRow(
                    label: _t('Dystans', 'Distance'),
                    value: '${data.longitudinalDistanceMeters.toStringAsFixed(1)} m',
                    valueColor: data.isDangerouslyCloseToBumper
                        ? AppColors.crimsonAlert
                        : AppColors.textPrimary,
                  ),
                  const SizedBox(height: 4),
                  _buildMetricRow(
                    label: _t('Zysk aero', 'Aero saved'),
                    value: '-${data.aeroPowerSavedWatts.round()} W',
                    valueColor: AppColors.cyanAccent,
                  ),
                  const SizedBox(height: 4),
                  _buildMetricRow(
                    label: _t('Prognoza kary', 'Proj. penalty'),
                    value: _formatProjectedPenalty(data),
                    valueColor: data.projectedTimePenaltySeconds > 0
                        ? AppColors.crimsonAlert
                        : data.projectedFineChf > 0
                            ? AppColors.amberWarning
                            : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildProximityStrip(data: data, riskColor: riskColor),
        const SizedBox(height: 8),
        _buildFlagsWrap(data: data),
      ],
    );
  }

  Widget _buildMediumBody({
    required CaravanDraftingRiskHudData data,
    required Color riskColor,
    required double pulse,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildGaugeBox(
          data: data,
          riskColor: riskColor,
          pulse: pulse,
          size: 136,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildTelemetryGrid(data: data),
              const SizedBox(height: 10),
              _buildProximityStrip(data: data, riskColor: riskColor),
              const SizedBox(height: 8),
              _buildFlagsWrap(data: data),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWideBody({
    required CaravanDraftingRiskHudData data,
    required Color riskColor,
    required double pulse,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildGaugeBox(
          data: data,
          riskColor: riskColor,
          pulse: pulse,
          size: 144,
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildTelemetryGrid(data: data),
              const SizedBox(height: 10),
              _buildProximityStrip(data: data, riskColor: riskColor),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  _t('OCENA SĘDZIOWSKA UCI', 'UCI COMMISSAIRE STATUS'),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _contextLabel(data.context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildMetricRow(
                  label: _t('Prawdopodobieństwo', 'Probability'),
                  value: '${(data.timePenaltyProbability * 100).round()}%',
                  valueColor: riskColor,
                ),
                const SizedBox(height: 4),
                _buildMetricRow(
                  label: _t('Tempo ekspozycji', 'Exposure rate'),
                  value:
                      '${data.exposureRatePerSec >= 0 ? '+' : ''}${data.exposureRatePerSec.toStringAsFixed(1)}/s',
                  valueColor: data.exposureRatePerSec > 0
                      ? AppColors.amberWarning
                      : AppColors.statusSuccess,
                ),
                const SizedBox(height: 8),
                _buildFlagsWrap(data: data),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGaugeBox({
    required CaravanDraftingRiskHudData data,
    required Color riskColor,
    required double pulse,
    required double size,
  }) {
    final double exposure = data.safeExposurePercent;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: exposure),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double animatedExposure, Widget? _) {
        return SizedBox(
          width: size,
          height: size * 0.84,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              CustomPaint(
                size: Size(size, size * 0.84),
                painter: CaravanRiskArcMeterPainter(
                  exposurePercent: animatedExposure,
                  riskColor: riskColor,
                  pulsePhase: pulse,
                  isHighRisk: data.isHighRiskAlert,
                ),
              ),
              Positioned(
                bottom: 6,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '${animatedExposure.round()}%',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: size < 130 ? 20 : 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: riskColor,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    Text(
                      _t('EKSPOZYCJA', 'EXPOSURE'),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: AppColors.textSecondary,
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

  Widget _buildTelemetryGrid({required CaravanDraftingRiskHudData data}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _TelemetryChip(
          label: _t('Zysk mocy', 'Power saved'),
          value: '-${data.aeroPowerSavedWatts.round()} W',
          subValue: '-${data.dragReductionPercent.round()}% CdA',
          accentColor: AppColors.cyanAccent,
        ),
        _TelemetryChip(
          label: _t('Prędkość', 'Speed'),
          value: '${data.riderSpeedKmh.toStringAsFixed(1)} km/h',
          subValue: data.isoPowerSpeedGainKmh > 0.1
              ? '+${data.isoPowerSpeedGainKmh.toStringAsFixed(1)} km/h'
              : null,
          accentColor: AppColors.accentBlue,
        ),
        _TelemetryChip(
          label: _t('Prognoza UCI', 'UCI Penalty'),
          value: _formatProjectedPenalty(data),
          subValue: data.remainingGapToPelotonMeters > 0
              ? '${_t('Do grupy', 'To group')}: ${data.remainingGapToPelotonMeters.round()} m'
              : null,
          accentColor: data.projectedTimePenaltySeconds > 0
              ? AppColors.crimsonAlert
              : data.projectedFineChf > 0
                  ? AppColors.amberWarning
                  : AppColors.statusSuccess,
        ),
      ],
    );
  }

  Widget _buildProximityStrip({
    required CaravanDraftingRiskHudData data,
    required Color riskColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: data.isDangerouslyCloseToBumper
              ? AppColors.crimsonAlert.withValues(alpha: 0.7)
              : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Text(
                  _t('POZYCJA W STRUDZE POJAZDU', 'WAKE PROXIMITY'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${data.longitudinalDistanceMeters.toStringAsFixed(1)} m',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: data.isDangerouslyCloseToBumper
                      ? AppColors.crimsonAlert
                      : AppColors.textPrimary,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 24,
            child: CustomPaint(
              painter: CaravanWakeProximityPainter(
                distanceMeters: data.longitudinalDistanceMeters,
                maxDisplayMeters: 12.0,
                riskColor: riskColor,
                isDangerouslyClose: data.isDangerouslyCloseToBumper,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlagsWrap({required CaravanDraftingRiskHudData data}) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        _IndicatorPill(
          icon: Icons.gavel_rounded,
          label: _t('Komisarz <60m', 'Commissaire <60m'),
          active: data.commissaireInSight,
          activeColor: AppColors.crimsonAlert,
        ),
        _IndicatorPill(
          icon: Icons.videocam_rounded,
          label: _t('Kamera TV', 'TV Camera'),
          active: data.isTvCameraFocused,
          activeColor: AppColors.amberWarning,
        ),
        if (data.isDangerouslyCloseToBumper)
          _IndicatorPill(
            icon: Icons.warning_amber_rounded,
            label: _t('Zderzak <0.9m!', 'Bumper <0.9m!'),
            active: true,
            activeColor: AppColors.crimsonAlert,
          ),
      ],
    );
  }

  Widget _buildActionBar({required bool isCompact}) {
    const List<CaravanTacticalAction> actions = CaravanTacticalAction.values;
    if (isCompact) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: actions
            .map(
              (CaravanTacticalAction action) => _HudTacticalButton(
                action: action,
                label: action.label(widget.languageCode),
                isSelected: _selectedAction == action,
                isEnabled: widget.data.isEnabled,
                onTap: () => _handleActionTap(action),
              ),
            )
            .toList(),
      );
    }

    return Row(
      children: actions.asMap().entries.map((entry) {
        final int idx = entry.key;
        final CaravanTacticalAction action = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: idx == actions.length - 1 ? 0 : 8),
            child: _HudTacticalButton(
              action: action,
              label: action.label(widget.languageCode),
              isSelected: _selectedAction == action,
              isEnabled: widget.data.isEnabled,
              onTap: () => _handleActionTap(action),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetricRow({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  String _formatProjectedPenalty(CaravanDraftingRiskHudData data) {
    if (data.projectedTimePenaltySeconds > 0 && data.projectedFineChf > 0) {
      return '+${data.projectedTimePenaltySeconds}s / ${data.projectedFineChf} CHF';
    }
    if (data.projectedTimePenaltySeconds > 0) {
      return '+${data.projectedTimePenaltySeconds}s';
    }
    if (data.projectedFineChf > 0) {
      return '${data.projectedFineChf} CHF';
    }
    return _t('Brak kary', 'No penalty');
  }
}

/// Rysuje półkolisty zegar ekspozycji na karę sędziowską UCI (0–100%).
class CaravanRiskArcMeterPainter extends CustomPainter {
  final double exposurePercent;
  final Color riskColor;
  final double pulsePhase;
  final bool isHighRisk;

  const CaravanRiskArcMeterPainter({
    required this.exposurePercent,
    required this.riskColor,
    required this.pulsePhase,
    required this.isHighRisk,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = math.max(8.0, size.width * 0.085);
    final Offset center = Offset(size.width / 2, size.height * 0.62);
    final double radius =
        math.min(size.width / 2, size.height * 0.62) - strokeWidth;
    if (radius <= 0) {
      return;
    }

    const double startAngle = math.pi * 0.82;
    const double sweepTotal = math.pi * 1.36;
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);

    // Tło toru łuku
    final Paint trackPaint = Paint()
      ..color = AppColors.surfaceLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, startAngle, sweepTotal, false, trackPaint);

    // Subtelne strefy progowe na obrzeżu zewnętrznym
    final List<(double, double, Color)> zones = <(double, double, Color)>[
      (0.0, 0.30, AppColors.statusSuccess.withValues(alpha: 0.35)),
      (0.30, 0.60, AppColors.amberWarning.withValues(alpha: 0.35)),
      (0.60, 0.85, AppColors.powerZone5.withValues(alpha: 0.40)),
      (0.85, 1.0, AppColors.crimsonAlert.withValues(alpha: 0.48)),
    ];
    final Rect zoneRect = Rect.fromCircle(
      center: center,
      radius: radius + strokeWidth * 0.68,
    );
    for (final (double from, double to, Color color) in zones) {
      final Paint zonePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        zoneRect,
        startAngle + sweepTotal * from,
        sweepTotal * (to - from) - 0.02,
        false,
        zonePaint,
      );
    }

    // Aktywny łuk postępu ekspozycji
    final double clampedFraction = (exposurePercent / 100.0).clamp(0.0, 1.0);
    if (clampedFraction > 0.005) {
      final Paint activePaint = Paint()
        ..color = riskColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        arcRect,
        startAngle,
        sweepTotal * clampedFraction,
        false,
        activePaint,
      );
    }

    // Pulsująca aureola przy wysokim ryzyku
    if (isHighRisk) {
      final Paint pulsePaint = Paint()
        ..color = riskColor.withValues(alpha: 0.14 + 0.18 * pulsePhase)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4.0
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        arcRect,
        startAngle,
        sweepTotal * clampedFraction,
        false,
        pulsePaint,
      );
    }

    // Wskazówka iglicowa na końcu łuku
    final double needleAngle = startAngle + sweepTotal * clampedFraction;
    final Offset tip = Offset(
      center.dx + (radius - strokeWidth * 0.15) * math.cos(needleAngle),
      center.dy + (radius - strokeWidth * 0.15) * math.sin(needleAngle),
    );
    final Paint dotPaint = Paint()..color = AppColors.textPrimary;
    canvas.drawCircle(tip, strokeWidth * 0.34, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CaravanRiskArcMeterPainter oldDelegate) {
    return oldDelegate.exposurePercent != exposurePercent ||
        oldDelegate.riskColor != riskColor ||
        oldDelegate.pulsePhase != pulsePhase ||
        oldDelegate.isHighRisk != isHighRisk;
  }
}

/// Rysuje pasek odległości kolarza od zderzaka pojazdu w tunelu aerodynamicznym.
class CaravanWakeProximityPainter extends CustomPainter {
  final double distanceMeters;
  final double maxDisplayMeters;
  final Color riskColor;
  final bool isDangerouslyClose;

  const CaravanWakeProximityPainter({
    required this.distanceMeters,
    required this.maxDisplayMeters,
    required this.riskColor,
    required this.isDangerouslyClose,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double trackTop = size.height * 0.32;
    final double trackHeight = size.height * 0.36;
    const double carWidth = 24.0;
    const double laneLeft = carWidth + 6.0;
    final double laneWidth = math.max(10.0, size.width - laneLeft - 6.0);

    // Sylwetka pojazdu po lewej
    final RRect carRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.18, carWidth, size.height * 0.64),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      carRect,
      Paint()..color = AppColors.surfaceLight,
    );
    canvas.drawRRect(
      carRect,
      Paint()
        ..color = AppColors.goldAccent.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Tor odległości
    final RRect laneRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(laneLeft, trackTop, laneWidth, trackHeight),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      laneRect,
      Paint()..color = AppColors.surfaceLight,
    );

    // Strefa niebezpieczna < 0.9m
    final double dangerFraction = (0.9 / maxDisplayMeters).clamp(0.0, 1.0);
    final RRect dangerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(laneLeft, trackTop, laneWidth * dangerFraction, trackHeight),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      dangerRect,
      Paint()..color = AppColors.crimsonAlert.withValues(alpha: 0.55),
    );

    // Pozycja kolarza
    final double riderFraction =
        (distanceMeters / maxDisplayMeters).clamp(0.0, 1.0);
    final double riderX = laneLeft + laneWidth * riderFraction;
    final Offset riderCenter = Offset(riderX, size.height * 0.5);

    canvas.drawCircle(
      riderCenter,
      6.5,
      Paint()
        ..color = isDangerouslyClose ? AppColors.crimsonAlert : riskColor,
    );
    canvas.drawCircle(
      riderCenter,
      2.6,
      Paint()..color = AppColors.textPrimary,
    );
  }

  @override
  bool shouldRepaint(covariant CaravanWakeProximityPainter oldDelegate) {
    return oldDelegate.distanceMeters != distanceMeters ||
        oldDelegate.riskColor != riskColor ||
        oldDelegate.isDangerouslyClose != isDangerouslyClose;
  }
}

class _RiskStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _RiskStatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _TelemetryChip extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final Color accentColor;

  const _TelemetryChip({
    required this.label,
    required this.value,
    this.subValue,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 108),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: accentColor,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          if (subValue != null) ...<Widget>[
            const SizedBox(height: 1),
            Text(
              subValue!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: AppColors.textSecondary,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IndicatorPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;

  const _IndicatorPill({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color fgColor = active ? activeColor : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? activeColor.withValues(alpha: 0.14)
            : AppColors.surfaceLight.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active
              ? activeColor.withValues(alpha: 0.55)
              : AppColors.cardBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: fgColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: fgColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HudTacticalButton extends StatefulWidget {
  final CaravanTacticalAction action;
  final String label;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _HudTacticalButton({
    required this.action,
    required this.label,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  State<_HudTacticalButton> createState() => _HudTacticalButtonState();
}

class _HudTacticalButtonState extends State<_HudTacticalButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.isEnabled;
    final Color baseBg = widget.isSelected
        ? AppColors.primaryAccent.withValues(alpha: 0.28)
        : AppColors.surfaceLight;
    final Color bg = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : _isPressed
            ? AppColors.primaryAccent.withValues(alpha: 0.42)
            : _isHovered
                ? AppColors.cardBorder.withValues(alpha: 0.85)
                : baseBg;

    final Color borderColor = !enabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : _isFocused
            ? AppColors.goldAccent
            : widget.isSelected
                ? AppColors.primaryAccent
                : _isHovered
                    ? AppColors.accentBlue.withValues(alpha: 0.7)
                    : AppColors.cardBorder;

    final Color fgColor = !enabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : widget.isSelected
            ? AppColors.textPrimary
            : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: enabled,
      mouseCursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onShowHoverHighlight: (bool value) => setState(() => _isHovered = value),
      onShowFocusHighlight: (bool value) => setState(() => _isFocused = value),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent _) {
            if (enabled) {
              widget.onTap();
            }
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel:
            enabled ? () => setState(() => _isPressed = false) : null,
        onTap: enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                widget.action.icon,
                size: 15,
                color: widget.isSelected && enabled
                    ? AppColors.goldAccent
                    : fgColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight:
                        widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: fgColor,
                  ),
                ),
              ),
            ],
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
    required this.onPressed,
  });

  @override
  State<_HudIconButton> createState() => _HudIconButtonState();
}

class _HudIconButtonState extends State<_HudIconButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.enabled && widget.onPressed != null;
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: active,
        mouseCursor:
            active ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
        onShowFocusHighlight: (bool v) => setState(() => _focused = v),
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (ActivateIntent _) {
              if (active) {
                widget.onPressed?.call();
              }
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTapDown: active ? (_) => setState(() => _pressed = true) : null,
          onTapUp: active ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: active ? () => setState(() => _pressed = false) : null,
          onTap: active ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: !active
                  ? AppColors.surfaceLight.withValues(alpha: 0.35)
                  : _pressed
                      ? AppColors.primaryAccent.withValues(alpha: 0.4)
                      : _hovered
                          ? AppColors.cardBorder
                          : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : _hovered && active
                        ? AppColors.accentBlue.withValues(alpha: 0.6)
                        : AppColors.cardBorder,
                width: _focused ? 1.6 : 1.0,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 17,
              color: active
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
