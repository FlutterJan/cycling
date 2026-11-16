import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../models/career/pro_cyclist_career_state.dart';
import '../../services/career/ds_team_orders_mission_generator.dart';

/// Aktualny stan pracy tracker'a rozkazu Dyrektora Sportowego w trybie Be a Pro.
enum BeAProDsObjectiveHudStatus {
  /// Rozkaz aktywny — symulacja zlicza postęp i XP na żywo.
  active,

  /// Rozkaz został w 100% wykonany.
  completed,

  /// Ostrzeżenie — np. kolarz oddalił się od chronionego lidera powyżej limitu.
  warning,

  /// Brak aktywnego rozkazu lub HUD wyłączony.
  disabled;

  /// Etykieta statusu w nagłówku HUD.
  String get badgeLabel {
    switch (this) {
      case BeAProDsObjectiveHudStatus.active:
        return 'ROZKAZ AKTYWNY';
      case BeAProDsObjectiveHudStatus.completed:
        return 'CEL WYKONANY';
      case BeAProDsObjectiveHudStatus.warning:
        return 'UWAGA: LIDER DALEKO';
      case BeAProDsObjectiveHudStatus.disabled:
        return 'RADIO STANDBY';
    }
  }

  /// Kolor przewodni z palety [AppColors].
  Color get accentColor {
    switch (this) {
      case BeAProDsObjectiveHudStatus.active:
        return AppColors.goldAccent;
      case BeAProDsObjectiveHudStatus.completed:
        return AppColors.statusSuccess;
      case BeAProDsObjectiveHudStatus.warning:
        return AppColors.amberWarning;
      case BeAProDsObjectiveHudStatus.disabled:
        return AppColors.textSecondary;
    }
  }
}

/// Dane telemetryczne lokalizacji chronionego lidera drużyny w tłumie peletonu.
@immutable
class ProtectedLeaderBeaconData {
  /// Nazwisko i inicjał chronionego lidera (np. `M. Kowalski`).
  final String leaderName;

  /// Numer startowy lidera na koszulce.
  final int leaderNumber;

  /// Odległość w metrach od kolarza gracza do lidera drużyny.
  final double distanceMeters;

  /// Kąt kierunkowy w radianach względem osi jazdy gracza:
  /// `0.0` = dokładnie przed nami, `+pi/2` = po prawej, `-pi/2` = po lewej, `pi` = za nami.
  final double bearingAngleRadians;

  /// Różnica wysokości względem lidera w metrach (dla pochylenia strzałki 3D).
  final double elevationDeltaMeters;

  /// Maksymalny promień bezpiecznej ochrony lidera w metrach.
  final double protectionRadiusMeters;

  /// Nazwa grupy wyścigowej, w której jedzie lider (np. `Główny Peleton`).
  final String groupLabel;

  const ProtectedLeaderBeaconData({
    required this.leaderName,
    this.leaderNumber = 11,
    required this.distanceMeters,
    required this.bearingAngleRadians,
    this.elevationDeltaMeters = 0.0,
    this.protectionRadiusMeters = 8.0,
    this.groupLabel = 'Główny Peleton',
  });

  /// Czy gracz znajduje się w optymalnej strefie osłony lidera.
  bool get isInProtectionZone => distanceMeters <= protectionRadiusMeters;

  /// Czy lider jest zbyt daleko (> 2.5x promień ochrony).
  bool get isCriticallyFar => distanceMeters > protectionRadiusMeters * 2.5;

  /// Czytelny opis relatywnego kierunku w tłumie.
  String get directionHint {
    final normalized = _normalizeAngle(bearingAngleRadians);
    final absAngle = normalized.abs();
    if (absAngle <= math.pi / 6) {
      return 'Przed Tobą';
    } else if (absAngle >= 5 * math.pi / 6) {
      return 'Za Tobą';
    } else if (normalized > 0) {
      return normalized < math.pi / 2 ? 'Z przodu po prawej' : 'Z tyłu po prawej';
    } else {
      return normalized > -math.pi / 2
          ? 'Z przodu po lewej'
          : 'Z tyłu po lewej';
    }
  }

  static double _normalizeAngle(double radians) {
    var angle = radians % (2 * math.pi);
    if (angle > math.pi) angle -= 2 * math.pi;
    if (angle < -math.pi) angle += 2 * math.pi;
    return angle;
  }

  ProtectedLeaderBeaconData copyWith({
    String? leaderName,
    int? leaderNumber,
    double? distanceMeters,
    double? bearingAngleRadians,
    double? elevationDeltaMeters,
    double? protectionRadiusMeters,
    String? groupLabel,
  }) {
    return ProtectedLeaderBeaconData(
      leaderName: leaderName ?? this.leaderName,
      leaderNumber: leaderNumber ?? this.leaderNumber,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      bearingAngleRadians: bearingAngleRadians ?? this.bearingAngleRadians,
      elevationDeltaMeters: elevationDeltaMeters ?? this.elevationDeltaMeters,
      protectionRadiusMeters:
          protectionRadiusMeters ?? this.protectionRadiusMeters,
      groupLabel: groupLabel ?? this.groupLabel,
    );
  }
}

/// Niemutowalny model danych dla HUD rozkazu Dyrektora Sportowego w trybie Be a Pro.
@immutable
class BeAProDsObjectiveHudData {
  /// Identyfikator misji / rozkazu.
  final String missionId;

  /// Nazwisko Dyrektora Sportowego nadającego rozkaz przez radio.
  final String directorName;

  /// Rola kolarza w hierarchii drużyny Be a Pro.
  final BeAProRoleStatus roleStatus;

  /// Typ zadania taktycznego.
  final ProCyclistAssignmentType assignmentType;

  /// Faza etapu wyzwalająca rozkaz.
  final DsMissionTriggerPhase triggerPhase;

  /// Krótki tytuł rozkazu (np. `Osłona lidera na wietrze`).
  final String objectiveTitle;

  /// Komunikat głosowy DS z radia wyścigowego.
  final String radioOrderText;

  /// Nazwa mierzonego postępu (np. `Czas ciągnięcia peletonu`).
  final String progressLabel;

  /// Aktualna wartość postępu (np. `255.0` sekund dla `4:15`).
  final double currentValue;

  /// Docelowa wartość wykonania zadania (np. `300.0` sekund dla `5:00`).
  final double targetValue;

  /// Jednostka wyświetlana przy postępie (np. `min`, `km`, `pkt`).
  final String unitLabel;

  /// Jeśli `true`, wartości liczbowe formatowane są jako `M:SS / M:SS` (np. `4:15 / 5:00 min`).
  final bool formatAsDuration;

  /// Opcjonalna zadana moc docelowa w watach (np. `340 W`).
  final int? targetPowerWatts;

  /// Opcjonalna aktualna moc kolarza w watach (np. `348 W`).
  final int? currentPowerWatts;

  /// Punkty XP zdobyte do tej pory w czasie rzeczywistym na tym etapie.
  final int liveXpEarned;

  /// Dodatkowa premia XP za pełne ukończenie rozkazu.
  final int bonusXpOnCompletion;

  /// Aktualne tempo zdobywania XP na minutę.
  final double xpPerMinuteRate;

  /// Szacowana zmiana zaufania DS (`dsTrustScore`).
  final double dsTrustDeltaPreview;

  /// Bieżący status rozkazu w HUD.
  final BeAProDsObjectiveHudStatus status;

  /// Opcjonalny beacon chronionego lidera drużyny w peletonie.
  final ProtectedLeaderBeaconData? leaderBeacon;

  const BeAProDsObjectiveHudData({
    required this.missionId,
    required this.directorName,
    this.roleStatus = BeAProRoleStatus.youngDomestique,
    this.assignmentType = ProCyclistAssignmentType.protectLeader,
    this.triggerPhase = DsMissionTriggerPhase.earlyStage,
    required this.objectiveTitle,
    required this.radioOrderText,
    required this.progressLabel,
    required this.currentValue,
    required this.targetValue,
    this.unitLabel = 'min',
    this.formatAsDuration = true,
    this.targetPowerWatts,
    this.currentPowerWatts,
    required this.liveXpEarned,
    this.bonusXpOnCompletion = 0,
    this.xpPerMinuteRate = 0.0,
    this.dsTrustDeltaPreview = 0.0,
    this.status = BeAProDsObjectiveHudStatus.active,
    this.leaderBeacon,
  });

  /// Buduje dane HUD bezpośrednio z wygenerowanej misji [DsTeamOrderMission].
  factory BeAProDsObjectiveHudData.fromMission({
    required DsTeamOrderMission mission,
    required BeAProRoleStatus roleStatus,
    required int liveXpEarned,
    double xpPerMinuteRate = 36.0,
    int? currentPowerWatts,
    ProtectedLeaderBeaconData? leaderBeacon,
    bool formatAsDuration = false,
    String unitLabel = 'pkt',
  }) {
    final bool isCompleted =
        mission.status == ProCyclistAssignmentStatus.completed ||
            (mission.targetValue > 0 &&
                mission.currentProgress >= mission.targetValue);

    final BeAProDsObjectiveHudStatus hudStatus;
    if (mission.status == ProCyclistAssignmentStatus.failed ||
        mission.status == ProCyclistAssignmentStatus.expired) {
      hudStatus = BeAProDsObjectiveHudStatus.disabled;
    } else if (isCompleted) {
      hudStatus = BeAProDsObjectiveHudStatus.completed;
    } else if (leaderBeacon != null && leaderBeacon.isCriticallyFar) {
      hudStatus = BeAProDsObjectiveHudStatus.warning;
    } else {
      hudStatus = BeAProDsObjectiveHudStatus.active;
    }

    return BeAProDsObjectiveHudData(
      missionId: mission.missionId,
      directorName: mission.directorName,
      roleStatus: roleStatus,
      assignmentType: mission.assignmentType,
      triggerPhase: mission.triggerPhase,
      objectiveTitle: mission.title,
      radioOrderText: mission.radioCallout,
      progressLabel: mission.targetMetricLabel,
      currentValue: mission.currentProgress,
      targetValue: mission.targetValue,
      unitLabel: unitLabel,
      formatAsDuration: formatAsDuration,
      targetPowerWatts: mission.targetPowerWatts,
      currentPowerWatts: currentPowerWatts,
      liveXpEarned: liveXpEarned,
      bonusXpOnCompletion: mission.rewardXp,
      xpPerMinuteRate: xpPerMinuteRate,
      dsTrustDeltaPreview: mission.rewardTrustDelta,
      status: hudStatus,
      leaderBeacon: leaderBeacon,
    );
  }

  /// Ułamek postępu w zakresie `0.0..1.0`.
  double get progressFraction {
    if (targetValue <= 0) return 0.0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  /// Sformatowany tekst postępu, np. `Czas ciągnięcia peletonu: 4:15 / 5:00 min`.
  String get formattedProgressText {
    if (formatAsDuration) {
      final currentStr = _formatSecondsAsMinSec(currentValue);
      final targetStr = _formatSecondsAsMinSec(targetValue);
      return '$progressLabel: $currentStr / $targetStr $unitLabel';
    }
    final curStr = currentValue == currentValue.roundToDouble()
        ? currentValue.toInt().toString()
        : currentValue.toStringAsFixed(1);
    final tgtStr = targetValue == targetValue.roundToDouble()
        ? targetValue.toInt().toString()
        : targetValue.toStringAsFixed(1);
    return '$progressLabel: $curStr / $tgtStr $unitLabel';
  }

  static String _formatSecondsAsMinSec(double totalSeconds) {
    final safeSeconds = math.max(0, totalSeconds.round());
    final minutes = safeSeconds ~/ 60;
    final seconds = safeSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  BeAProDsObjectiveHudData copyWith({
    String? missionId,
    String? directorName,
    BeAProRoleStatus? roleStatus,
    ProCyclistAssignmentType? assignmentType,
    DsMissionTriggerPhase? triggerPhase,
    String? objectiveTitle,
    String? radioOrderText,
    String? progressLabel,
    double? currentValue,
    double? targetValue,
    String? unitLabel,
    bool? formatAsDuration,
    int? targetPowerWatts,
    int? currentPowerWatts,
    int? liveXpEarned,
    int? bonusXpOnCompletion,
    double? xpPerMinuteRate,
    double? dsTrustDeltaPreview,
    BeAProDsObjectiveHudStatus? status,
    ProtectedLeaderBeaconData? leaderBeacon,
  }) {
    return BeAProDsObjectiveHudData(
      missionId: missionId ?? this.missionId,
      directorName: directorName ?? this.directorName,
      roleStatus: roleStatus ?? this.roleStatus,
      assignmentType: assignmentType ?? this.assignmentType,
      triggerPhase: triggerPhase ?? this.triggerPhase,
      objectiveTitle: objectiveTitle ?? this.objectiveTitle,
      radioOrderText: radioOrderText ?? this.radioOrderText,
      progressLabel: progressLabel ?? this.progressLabel,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue ?? this.targetValue,
      unitLabel: unitLabel ?? this.unitLabel,
      formatAsDuration: formatAsDuration ?? this.formatAsDuration,
      targetPowerWatts: targetPowerWatts ?? this.targetPowerWatts,
      currentPowerWatts: currentPowerWatts ?? this.currentPowerWatts,
      liveXpEarned: liveXpEarned ?? this.liveXpEarned,
      bonusXpOnCompletion: bonusXpOnCompletion ?? this.bonusXpOnCompletion,
      xpPerMinuteRate: xpPerMinuteRate ?? this.xpPerMinuteRate,
      dsTrustDeltaPreview: dsTrustDeltaPreview ?? this.dsTrustDeltaPreview,
      status: status ?? this.status,
      leaderBeacon: leaderBeacon ?? this.leaderBeacon,
    );
  }
}

/// Rysuje zieloną strzałkę kierunkową 3D w perspektywie, wskazującą pozycję
/// chronionego lidera drużyny w tłumie peletonu.
class Leader3dDirectionalArrowPainter extends CustomPainter {
  final double bearingAngleRadians;
  final double elevationDeltaMeters;
  final double pulsePhase;
  final Color primaryColor;
  final bool isDisabled;

  const Leader3dDirectionalArrowPainter({
    required this.bearingAngleRadians,
    required this.elevationDeltaMeters,
    required this.pulsePhase,
    required this.primaryColor,
    this.isDisabled = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.44;

    // 1. Płaszczyzna radaru 3D (eliptyczna perspektywa szosy w tłumie)
    canvas.save();
    canvas.translate(center.dx, center.dy + radius * 0.08);
    canvas.scale(1.0, 0.68); // Pochylenie 3D podłoża

    final outerRingPaint = Paint()
      ..color = primaryColor.withValues(alpha: isDisabled ? 0.14 : 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(Offset.zero, radius, outerRingPaint);

    if (!isDisabled) {
      final pulseRadius = radius * (0.58 + 0.38 * pulsePhase);
      final pulsePaint = Paint()
        ..color = primaryColor.withValues(alpha: (1.0 - pulsePhase) * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawCircle(Offset.zero, pulseRadius, pulsePaint);
    }

    // Siatka celownicza
    final gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(Offset.zero, radius * 0.56, gridPaint);
    canvas.drawLine(
      Offset(-radius, 0),
      Offset(radius, 0),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, -radius),
      Offset(0, radius),
      gridPaint,
    );

    // 2. Cień rzutowany strzałki 3D na płaszczyznę asfaltu
    canvas.save();
    canvas.rotate(bearingAngleRadians);
    final shadowPath = _buildArrowPath(radius * 0.76);
    canvas.translate(0, 4.5);
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
    );
    canvas.restore();

    // 3. Właściwa bryła strzałki 3D (ekstruzja boczna + górna powierzchnia z gradientem)
    final tiltScaleY =
        (1.0 - (elevationDeltaMeters.clamp(-5.0, 5.0) * 0.025)).clamp(0.82, 1.15);
    canvas.scale(1.0, tiltScaleY);
    canvas.rotate(bearingAngleRadians);

    final arrowLen = radius * 0.78;
    const baseDepthOffset = Offset(0, 3.6);

    // Ekstruzja dolnej ścianki 3D (ciemniejszy odcień)
    final extrudedPath = _buildArrowPath(arrowLen).shift(baseDepthOffset);
    final extrusionColor = Color.lerp(primaryColor, Colors.black, 0.52)!;
    canvas.drawPath(
      extrudedPath,
      Paint()
        ..color = extrusionColor.withValues(alpha: isDisabled ? 0.45 : 0.95)
        ..style = PaintingStyle.fill,
    );

    // Górna lśniąca powierzchnia strzałki 3D
    final topPath = _buildArrowPath(arrowLen);
    final highlightColor = Color.lerp(primaryColor, Colors.white, 0.35)!;
    final topShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        highlightColor.withValues(alpha: isDisabled ? 0.4 : 1.0),
        primaryColor.withValues(alpha: isDisabled ? 0.35 : 0.95),
      ],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: arrowLen));

    canvas.drawPath(
      topPath,
      Paint()
        ..shader = topShader
        ..style = PaintingStyle.fill,
    );

    // Krawędź obrysu 3D dla ostrości w tłumie
    canvas.drawPath(
      topPath,
      Paint()
        ..color = Colors.white.withValues(alpha: isDisabled ? 0.15 : 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    canvas.restore();
  }

  Path _buildArrowPath(double r) {
    return Path()
      ..moveTo(0, -r) // Grot strzałki
      ..lineTo(r * 0.56, r * 0.48) // Prawe skrzydło
      ..lineTo(0, r * 0.18) // Wcięcie ogona
      ..lineTo(-r * 0.56, r * 0.48) // Lewe skrzydło
      ..close();
  }

  @override
  bool shouldRepaint(covariant Leader3dDirectionalArrowPainter oldDelegate) {
    return oldDelegate.bearingAngleRadians != bearingAngleRadians ||
        oldDelegate.elevationDeltaMeters != elevationDeltaMeters ||
        oldDelegate.pulsePhase != pulsePhase ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.isDisabled != isDisabled;
  }
}

/// Dedykowany widget HUD dla trybu Be a Pro wyświetlający na żywo:
/// - aktualny rozkaz Dyrektora Sportowego,
/// - pasek postępu wykonania zadania (np. `Czas ciągnięcia peletonu: 4:15 / 5:00 min`),
/// - odległość w metrach od chronionego lidera drużyny z zieloną strzałką kierunkową 3D,
/// - licznik zdobywanych w czasie rzeczywistym punktów XP.
class BeAProDsObjectiveHudTracker extends StatefulWidget {
  final BeAProDsObjectiveHudData data;

  /// Czy widget ma reagować na interakcje użytkownika.
  final bool enabled;

  /// Callback po kliknięciu przycisku odtworzenia / potwierdzenia radia DS.
  final VoidCallback? onAcknowledgeRadioOrder;

  /// Callback po kliknięciu przycisku namierzenia / centrowania kamery na liderze.
  final VoidCallback? onLocateLeader;

  /// Opcjonalny callback po przełączeniu zwinięcia/rozwinięcia szczegółów.
  final ValueChanged<bool>? onToggleExpanded;

  /// Początkowy stan rozwinięcia treści rozkazu.
  final bool initiallyExpanded;

  const BeAProDsObjectiveHudTracker({
    super.key,
    required this.data,
    this.enabled = true,
    this.onAcknowledgeRadioOrder,
    this.onLocateLeader,
    this.onToggleExpanded,
    this.initiallyExpanded = true,
  });

  @override
  State<BeAProDsObjectiveHudTracker> createState() =>
      _BeAProDsObjectiveHudTrackerState();
}

class _BeAProDsObjectiveHudTrackerState
    extends State<BeAProDsObjectiveHudTracker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _isHovered = false;
  bool _isFocused = false;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (_shouldAnimatePulse) {
      _pulseController.repeat();
    }
  }

  bool get _isHudDisabled =>
      !widget.enabled || widget.data.status == BeAProDsObjectiveHudStatus.disabled;

  bool get _shouldAnimatePulse =>
      !_isHudDisabled &&
      widget.data.status != BeAProDsObjectiveHudStatus.completed;

  @override
  void didUpdateWidget(covariant BeAProDsObjectiveHudTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldAnimatePulse && !_pulseController.isAnimating) {
      _pulseController.repeat();
    } else if (!_shouldAnimatePulse && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleToggleExpanded() {
    if (_isHudDisabled) return;
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onToggleExpanded?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.data.status.accentColor;
    final borderColor = _isHudDisabled
        ? AppColors.cardBorder
        : _isFocused
            ? AppColors.goldAccent
            : _isHovered
                ? statusColor.withValues(alpha: 0.78)
                : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (focused) {
        if (_isFocused != focused) {
          setState(() => _isFocused = focused);
        }
      },
      onShowHoverHighlight: (hovered) {
        if (_isHovered != hovered) {
          setState(() => _isHovered = hovered);
        }
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _handleToggleExpanded();
            return null;
          },
        ),
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        opacity: _isHudDisabled ? 0.62 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (!_isHudDisabled && (_isHovered || _isFocused))
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.14),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 460;
              final isWide = constraints.maxWidth >= 780;
              return Padding(
                padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(statusColor, isCompact),
                    const SizedBox(height: 10),
                    if (isWide)
                      _buildWideBody(statusColor)
                    else
                      _buildStackedBody(statusColor, isCompact),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color statusColor, bool isCompact) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primaryAccent.withValues(alpha: 0.55),
            ),
          ),
          child: const Icon(
            Icons.headset_mic_rounded,
            size: 16,
            color: AppColors.goldAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'RADIO DS • ${widget.data.directorName.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (!isCompact) ...[
                    const SizedBox(width: 8),
                    _buildRolePill(),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                widget.data.objectiveTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildStatusBadge(statusColor),
        const SizedBox(width: 6),
        _HudIconButton(
          tooltip: _isExpanded ? 'Zwiń szczegóły rozkazu' : 'Rozwiń szczegóły',
          icon: _isExpanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          enabled: !_isHudDisabled,
          onPressed: _handleToggleExpanded,
        ),
      ],
    );
  }

  Widget _buildRolePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        widget.data.roleStatus.label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.accentBlue,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.48)),
      ),
      child: Text(
        widget.data.status.badgeLabel,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: statusColor,
        ),
      ),
    );
  }

  Widget _buildWideBody(Color statusColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isExpanded) ...[
                _buildRadioOrderQuote(),
                const SizedBox(height: 10),
              ],
              _buildObjectiveProgressCard(statusColor),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildLeaderBeaconCard(isCompact: false),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _buildXpCounterCard(isCompact: false),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStackedBody(Color statusColor, bool isCompact) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isExpanded) ...[
          _buildRadioOrderQuote(),
          const SizedBox(height: 10),
        ],
        _buildObjectiveProgressCard(statusColor),
        const SizedBox(height: 10),
        if (isCompact) ...[
          _buildLeaderBeaconCard(isCompact: true),
          const SizedBox(height: 8),
          _buildXpCounterCard(isCompact: true),
        ] else
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildLeaderBeaconCard(isCompact: false),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _buildXpCounterCard(isCompact: false),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRadioOrderQuote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.graphic_eq_rounded,
              size: 16,
              color: AppColors.cyanAccent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '„${widget.data.radioOrderText}”',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.35,
                letterSpacing: -0.1,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (widget.onAcknowledgeRadioOrder != null) ...[
            const SizedBox(width: 8),
            _HudActionButton(
              label: 'Przyjąłem',
              icon: Icons.check_rounded,
              accentColor: AppColors.goldAccent,
              enabled: !_isHudDisabled,
              onPressed: widget.onAcknowledgeRadioOrder,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildObjectiveProgressCard(Color statusColor) {
    final progress = widget.data.progressFraction;
    final percentText = '${(progress * 100).round()}%';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.data.formattedProgressText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                percentText,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 8,
              color: AppColors.surfaceLight,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: progress),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                builder: (context, animatedProgress, _) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: animatedProgress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            statusColor.withValues(alpha: 0.8),
                            statusColor,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (widget.data.targetPowerWatts != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  size: 14,
                  color: AppColors.amberWarning,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.data.currentPowerWatts != null
                        ? 'Moc: ${widget.data.currentPowerWatts} W / Cel: ${widget.data.targetPowerWatts} W'
                        : 'Cel mocy: ${widget.data.targetPowerWatts} W',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      fontFeatures: [FontFeature.tabularFigures()],
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

  Widget _buildLeaderBeaconCard({required bool isCompact}) {
    final beacon = widget.data.leaderBeacon;
    if (beacon == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.explore_off_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Brak przypisanego lidera do ochrony na tym etapie.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Zielona strzałka kierunkowa 3D (lub ostrzeżenie gdy lider bardzo daleko)
    final arrowColor = beacon.isCriticallyFar
        ? AppColors.amberWarning
        : AppColors.statusSuccess;

    return Container(
      padding: EdgeInsets.all(isCompact ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: beacon.isInProtectionZone && !_isHudDisabled
              ? AppColors.statusSuccess.withValues(alpha: 0.45)
              : AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return SizedBox(
                width: isCompact ? 54 : 62,
                height: isCompact ? 54 : 62,
                child: CustomPaint(
                  painter: Leader3dDirectionalArrowPainter(
                    bearingAngleRadians: beacon.bearingAngleRadians,
                    elevationDeltaMeters: beacon.elevationDeltaMeters,
                    pulsePhase: _pulseController.value,
                    primaryColor: arrowColor,
                    isDisabled: _isHudDisabled,
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
                Text(
                  'LIDER #${beacon.leaderNumber} • ${beacon.leaderName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${beacon.distanceMeters.toStringAsFixed(1)} m',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: arrowColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        beacon.directionHint,
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
                const SizedBox(height: 3),
                Text(
                  beacon.isInProtectionZone
                      ? 'W strefie osłony (${beacon.groupLabel})'
                      : 'Zbliż się poniżej ${beacon.protectionRadiusMeters.toStringAsFixed(0)} m',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: beacon.isInProtectionZone
                        ? AppColors.statusSuccess
                        : AppColors.amberWarning,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onLocateLeader != null) ...[
            const SizedBox(width: 6),
            _HudIconButton(
              tooltip: 'Centruj kamerę na liderze',
              icon: Icons.my_location_rounded,
              enabled: !_isHudDisabled,
              onPressed: widget.onLocateLeader,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildXpCounterCard({required bool isCompact}) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(
                Icons.stars_rounded,
                size: 14,
                color: AppColors.goldAccent,
              ),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  'LIVE XP',
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
            ],
          ),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0.0,
              end: widget.data.liveXpEarned.toDouble(),
            ),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            builder: (context, animatedXp, _) {
              return Text(
                '+${animatedXp.round()} XP',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.goldAccent,
                ),
              );
            },
          ),
          const SizedBox(height: 3),
          Text(
            '+${widget.data.xpPerMinuteRate.toStringAsFixed(0)} XP/min • Premia +${widget.data.bonusXpOnCompletion}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              fontFeatures: [FontFeature.tabularFigures()],
              color: AppColors.textSecondary,
            ),
          ),
          if (widget.data.dsTrustDeltaPreview > 0) ...[
            const SizedBox(height: 2),
            Text(
              'Zaufanie DS: +${widget.data.dsTrustDeltaPreview.toStringAsFixed(1)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
                color: AppColors.statusSuccess,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HudActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool enabled;
  final VoidCallback? onPressed;

  const _HudActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_HudActionButton> createState() => _HudActionButtonState();
}

class _HudActionButtonState extends State<_HudActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && widget.onPressed != null;
    final bgColor = !active
        ? AppColors.surface
        : _pressed
            ? widget.accentColor.withValues(alpha: 0.28)
            : _hovered
                ? widget.accentColor.withValues(alpha: 0.18)
                : widget.accentColor.withValues(alpha: 0.10);

    return FocusableActionDetector(
      enabled: active,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: GestureDetector(
        onTapDown: active ? (_) => setState(() => _pressed = true) : null,
        onTapUp: active ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: active ? () => setState(() => _pressed = false) : null,
        onTap: active ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : active
                      ? widget.accentColor.withValues(alpha: 0.55)
                      : AppColors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 13,
                color: active ? widget.accentColor : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: active ? AppColors.textPrimary : AppColors.textSecondary,
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
  final String tooltip;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onPressed;

  const _HudIconButton({
    required this.tooltip,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_HudIconButton> createState() => _HudIconButtonState();
}

class _HudIconButtonState extends State<_HudIconButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && widget.onPressed != null;
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: active,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
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
                  ? AppColors.surface
                  : _pressed
                      ? AppColors.primaryAccent.withValues(alpha: 0.35)
                      : _hovered
                          ? AppColors.surfaceLight
                          : AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : _hovered && active
                        ? AppColors.goldAccent.withValues(alpha: 0.65)
                        : AppColors.cardBorder,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: active ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
