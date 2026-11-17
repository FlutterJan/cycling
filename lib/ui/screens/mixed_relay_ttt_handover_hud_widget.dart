import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../models/career/womens_worldtour_and_mixed_relay_model.dart';

/// Taktyczny tryb tempa dla wybranej trójki w Sztafecie Mieszanej TTT.
enum MixedRelayTrioPaceMode {
  conservative,
  balanced,
  allOut;

  String get label {
    switch (this) {
      case MixedRelayTrioPaceMode.conservative:
        return 'Oszczędnie (92% FTP)';
      case MixedRelayTrioPaceMode.balanced:
        return 'Równe tempo (100% FTP)';
      case MixedRelayTrioPaceMode.allOut:
        return 'Pełny gaz (108% FTP)';
    }
  }

  String get shortLabel {
    switch (this) {
      case MixedRelayTrioPaceMode.conservative:
        return '92%';
      case MixedRelayTrioPaceMode.balanced:
        return '100%';
      case MixedRelayTrioPaceMode.allOut:
        return '108%';
    }
  }
}

/// Kalkulator pomocniczy dla HUD przekazania zmiany w Sztafecie Mieszanej TTT.
class MixedRelayHandoverHudCalculator {
  const MixedRelayHandoverHudCalculator._();

  /// Formatuje czas w sekundach do postaci `MM:SS.cc` lub `HH:MM:SS.c`.
  static String formatRaceClock(double seconds) {
    final safe = math.max(0.0, seconds);
    final totalCentis = (safe * 100).round();
    final centis = totalCentis % 100;
    final totalSecs = totalCentis ~/ 100;
    final secs = totalSecs % 60;
    final mins = (totalSecs ~/ 60) % 60;
    final hours = totalSecs ~/ 3600;

    final mm = mins.toString().padLeft(2, '0');
    final ss = secs.toString().padLeft(2, '0');
    final cc = centis.toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$mm:$ss.$cc';
    }
    return '$mm:$ss.$cc';
  }

  /// Formatuje dystans pozostały do bramki lub mety (`450 m` lub `12.4 km`).
  static String formatRemainingDistance(double meters) {
    final safe = math.max(0.0, meters);
    if (safe < 1000.0) {
      return '${safe.round()} m';
    }
    return '${(safe / 1000.0).toStringAsFixed(2)} km';
  }

  /// Identyfikuje `riderId` drugiego zawodnika/zawodniczki w trójce (wyznacza czas).
  static String? findSecondRiderId(List<MixedRelayRiderSlot> trio) {
    if (trio.length < 2) {
      return trio.isEmpty ? null : trio.first.riderId;
    }
    final sorted = List<MixedRelayRiderSlot>.from(trio)
      ..sort((a, b) => b.distanceMeters.compareTo(a.distanceMeters));
    return sorted[1].riderId;
  }

  /// Oblicza szacowany czas (w sekundach) do przekroczenia linii przekazania przez 2. mężczyznę.
  static double? estimateSecondsToHandover(
    MixedRelayTeamEntry team,
    MixedRelayCourseSpec course,
  ) {
    if (team.phase == MixedRelayPhase.womensLegActive ||
        team.phase == MixedRelayPhase.finished ||
        team.phase == MixedRelayPhase.disqualified) {
      return 0.0;
    }
    final secondDist = team.mensSecondRiderDistanceMeters;
    final remaining = math.max(0.0, course.handoverDistanceMeters - secondDist);
    if (remaining <= 0.0) return 0.0;

    final sorted = List<MixedRelayRiderSlot>.from(team.mensTrio)
      ..sort((a, b) => b.distanceMeters.compareTo(a.distanceMeters));
    final speedKmh = sorted.length >= 2
        ? sorted[1].currentSpeedKmh
        : (sorted.isNotEmpty ? sorted.first.currentSpeedKmh : 0.0);
    if (speedKmh <= 1.0) return null;
    final speedMs = speedKmh / 3.6;
    return remaining / speedMs;
  }

  /// Parsuje kolor hex drużyny z bezpiecznym fallbackiem.
  static Color parseTeamColor(String hex, {Color fallback = AppColors.goldAccent}) {
    final cleaned = hex.trim().replaceFirst('#', '');
    if (cleaned.length == 6) {
      final value = int.tryParse('FF$cleaned', radix: 16);
      if (value != null) return Color(value);
    } else if (cleaned.length == 8) {
      final value = int.tryParse(cleaned, radix: 16);
      if (value != null) return Color(value);
    }
    return fallback;
  }
}

/// Dzielony interfejs HUD przekazania zmiany między trójką męską a kobiecą
/// w Drużynowej Sztafecie Mieszanej (UCI Mixed Relay TTT).
class MixedRelayTttHandoverHudWidget extends StatefulWidget {
  final MixedRelayRaceState raceState;
  final String? selectedTeamId;
  final bool isReadOnly;
  final MixedRelayTrioPaceMode mensPaceMode;
  final MixedRelayTrioPaceMode womensPaceMode;
  final ValueChanged<String>? onSelectTeam;
  final ValueChanged<MixedRelayRiderSlot>? onToggleRiderPull;
  final ValueChanged<bool>? onTriggerWomenLaunch;
  final ValueChanged<MixedRelayTrioPaceMode>? onMensPaceChanged;
  final ValueChanged<MixedRelayTrioPaceMode>? onWomensPaceChanged;
  final VoidCallback? onClose;

  const MixedRelayTttHandoverHudWidget({
    super.key,
    required this.raceState,
    this.selectedTeamId,
    this.isReadOnly = false,
    this.mensPaceMode = MixedRelayTrioPaceMode.balanced,
    this.womensPaceMode = MixedRelayTrioPaceMode.balanced,
    this.onSelectTeam,
    this.onToggleRiderPull,
    this.onTriggerWomenLaunch,
    this.onMensPaceChanged,
    this.onWomensPaceChanged,
    this.onClose,
  });

  @override
  State<MixedRelayTttHandoverHudWidget> createState() =>
      _MixedRelayTttHandoverHudWidgetState();
}

class _MixedRelayTttHandoverHudWidgetState
    extends State<MixedRelayTttHandoverHudWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _gatePulseController;
  String? _activeTeamId;
  String? _selectedRiderId;

  @override
  void initState() {
    super.initState();
    _gatePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _activeTeamId = widget.selectedTeamId ??
        (widget.raceState.teams.isNotEmpty
            ? widget.raceState.teams.first.teamId
            : null);
  }

  @override
  void didUpdateWidget(covariant MixedRelayTttHandoverHudWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTeamId != null &&
        widget.selectedTeamId != oldWidget.selectedTeamId) {
      _activeTeamId = widget.selectedTeamId;
    } else if (_activeTeamId == null && widget.raceState.teams.isNotEmpty) {
      _activeTeamId = widget.raceState.teams.first.teamId;
    }
  }

  @override
  void dispose() {
    _gatePulseController.dispose();
    super.dispose();
  }

  MixedRelayTeamEntry? get _currentTeam {
    if (widget.raceState.teams.isEmpty) return null;
    if (_activeTeamId != null) {
      for (final team in widget.raceState.teams) {
        if (team.teamId == _activeTeamId) return team;
      }
    }
    return widget.raceState.teams.first;
  }

  void _handleSelectTeam(String teamId) {
    if (widget.isReadOnly && widget.onSelectTeam == null) return;
    setState(() {
      _activeTeamId = teamId;
      _selectedRiderId = null;
    });
    widget.onSelectTeam?.call(teamId);
  }

  @override
  Widget build(BuildContext context) {
    final team = _currentTeam;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: 'Inter',
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final isCompact = constraints.maxWidth < 520;
            if (team == null) {
              return _EmptyMixedRelayState(
                course: widget.raceState.course,
                onClose: widget.onClose,
              );
            }

            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(team, isCompact),
                const SizedBox(height: 12),
                _buildTeamSelectorAndCourseBar(team, isCompact),
                const SizedBox(height: 14),
                if (isWide)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildTrioPanel(
                            team: team,
                            isFemaleLeg: false,
                            isCompact: isCompact,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: _buildHandoverGatePanel(team, isCompact),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 5,
                          child: _buildTrioPanel(
                            team: team,
                            isFemaleLeg: true,
                            isCompact: isCompact,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  _buildTrioPanel(
                    team: team,
                    isFemaleLeg: false,
                    isCompact: isCompact,
                  ),
                  const SizedBox(height: 12),
                  _buildHandoverGatePanel(team, isCompact),
                  const SizedBox(height: 12),
                  _buildTrioPanel(
                    team: team,
                    isFemaleLeg: true,
                    isCompact: isCompact,
                  ),
                ],
                const SizedBox(height: 14),
                _buildLeaderboardStrip(team, isCompact),
              ],
            );

            return SingleChildScrollView(
              padding: EdgeInsets.all(isCompact ? 12 : 16),
              child: content,
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(MixedRelayTeamEntry team, bool isCompact) {
    final course = widget.raceState.course;
    final teamColor = MixedRelayHandoverHudCalculator.parseTeamColor(
      team.primaryColorHex,
    );
    final phaseColor = _phaseBadgeColor(team.phase);

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isCompact ? 318 : 540),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: teamColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: teamColor.withValues(alpha: 0.7)),
                  ),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    color: teamColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (widget.raceState.isWorldChampionship)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.goldAccent.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.goldAccent.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'UCI MIXED RELAY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.goldAccent,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          Text(
                            course.eventName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isCompact ? 14 : 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${course.locationCity} (${course.countryIso}) • ${(course.totalDistanceMeters / 1000).toStringAsFixed(1)} km • Zmiana @ ${(course.handoverDistanceMeters / 1000).toStringAsFixed(1)} km • Wiatr ${course.windSpeedKmh.toStringAsFixed(0)} km/h',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: phaseColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: phaseColor.withValues(alpha: 0.65)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: phaseColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        team.phase.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: phaseColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 15,
                      color: AppColors.cyanAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      MixedRelayHandoverHudCalculator.formatRaceClock(
                        team.totalElapsedSeconds,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onClose != null)
                _HudIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Zamknij panel sztafety',
                  enabled: true,
                  onTap: widget.onClose!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSelectorAndCourseBar(
    MixedRelayTeamEntry team,
    bool isCompact,
  ) {
    final course = widget.raceState.course;
    final totalProgress = widget.raceState.totalCourseProgressPct(team);
    final handoverRatio = course.totalDistanceMeters > 0
        ? (course.handoverDistanceMeters / course.totalDistanceMeters)
            .clamp(0.05, 0.95)
        : 0.5;

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.raceState.teams.length > 1) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.raceState.teams.map((entry) {
                  final selected = entry.teamId == team.teamId;
                  final color = MixedRelayHandoverHudCalculator.parseTeamColor(
                    entry.primaryColorHex,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _HudSelectableChip(
                      label: '${entry.countryIso} • ${entry.nationOrClubName}',
                      accentColor: color,
                      selected: selected,
                      enabled: !widget.isReadOnly || widget.onSelectTeam != null,
                      onTap: () => _handleSelectTeam(entry.teamId),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            children: [
              const Text(
                'POSTĘP TRASY SZTAFETY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${(totalProgress * 100).toStringAsFixed(1)}% • Kara: +${team.penaltySeconds.toStringAsFixed(0)} s',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: team.penaltySeconds > 0
                      ? AppColors.crimsonAlert
                      : AppColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 22,
            child: CustomPaint(
              painter: _MixedRelayCourseProgressPainter(
                progress: totalProgress,
                handoverRatio: handoverRatio,
                phase: team.phase,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            children: [
              const Text(
                'START (MĘŻCZYŹNI)',
                style: TextStyle(fontSize: 10, color: AppColors.accentBlue),
              ),
              Text(
                'BRAMKA ${(course.handoverDistanceMeters / 1000).toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldAccent,
                ),
              ),
              const Text(
                'META (KOBIETY)',
                style: TextStyle(fontSize: 10, color: AppColors.primaryAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrioPanel({
    required MixedRelayTeamEntry team,
    required bool isFemaleLeg,
    required bool isCompact,
  }) {
    final trio = isFemaleLeg ? team.womensTrio : team.mensTrio;
    final legType =
        isFemaleLeg ? MixedRelayLegType.womensTrio : MixedRelayLegType.mensTrio;
    final legColor =
        isFemaleLeg ? AppColors.primaryAccent : AppColors.accentBlue;
    final isLegActive = isFemaleLeg
        ? (team.phase == MixedRelayPhase.womensLegActive ||
            team.phase == MixedRelayPhase.handoverWindowOpen)
        : (team.phase == MixedRelayPhase.mensLegActive ||
            team.phase == MixedRelayPhase.handoverApproaching);
    final isLegFinished = isFemaleLeg
        ? team.phase == MixedRelayPhase.finished
        : (team.phase == MixedRelayPhase.handoverWindowOpen ||
            team.phase == MixedRelayPhase.womensLegActive ||
            team.phase == MixedRelayPhase.finished);

    final secondRiderId =
        MixedRelayHandoverHudCalculator.findSecondRiderId(trio);
    final targetDist = isFemaleLeg
        ? widget.raceState.course.womensLegDistanceMeters
        : widget.raceState.course.mensLegDistanceMeters;
    final secondDist = isFemaleLeg
        ? team.womensSecondRiderDistanceMeters
        : team.mensSecondRiderDistanceMeters;
    final remaining = math.max(0.0, targetDist - secondDist);
    final activeCount =
        isFemaleLeg ? team.womensActiveCount : team.mensActiveCount;
    final currentPace = isFemaleLeg ? widget.womensPaceMode : widget.mensPaceMode;
    final paceCallback =
        isFemaleLeg ? widget.onWomensPaceChanged : widget.onMensPaceChanged;

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLegActive
              ? legColor.withValues(alpha: 0.8)
              : const Color(0xFF2A2F3D),
          width: isLegActive ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: legColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: legColor.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFemaleLeg ? Icons.female_rounded : Icons.male_rounded,
                      size: 14,
                      color: legColor,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        legType.label.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: legColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _StatusTag(
                label: isLegFinished
                    ? 'UKOŃCZONO'
                    : (isLegActive ? 'NA TRASIE' : 'OCZEKUJE'),
                color: isLegFinished
                    ? AppColors.statusSuccess
                    : (isLegActive ? legColor : AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                'Aktywni: $activeCount / ${trio.length} (min. 2)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: activeCount < 2
                      ? AppColors.crimsonAlert
                      : AppColors.textSecondary,
                ),
              ),
              Text(
                isFemaleLeg
                    ? 'Do mety: ${MixedRelayHandoverHudCalculator.formatRemainingDistance(remaining)}'
                    : 'Do bramki: ${MixedRelayHandoverHudCalculator.formatRemainingDistance(remaining)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (trio.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Text(
                'Brak zgłoszonych zawodników w tej zmianie.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            )
          else
            ...trio.map(
              (rider) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RiderSlotCard(
                  rider: rider,
                  isSecondTimeRider: rider.riderId == secondRiderId,
                  isSelected: _selectedRiderId == rider.riderId,
                  accentColor: legColor,
                  enabled: !widget.isReadOnly &&
                      isLegActive &&
                      !rider.isDropped &&
                      !rider.finishedLeg,
                  onTap: () {
                    setState(() {
                      _selectedRiderId = rider.riderId;
                    });
                    widget.onToggleRiderPull?.call(rider);
                  },
                ),
              ),
            ),
          const SizedBox(height: 4),
          const Text(
            'TEMPO ZMIANY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: MixedRelayTrioPaceMode.values.map((mode) {
              final selected = currentPace == mode;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: mode == MixedRelayTrioPaceMode.allOut ? 0 : 6,
                  ),
                  child: _HudSelectableChip(
                    label: mode.shortLabel,
                    accentColor: legColor,
                    selected: selected,
                    enabled: !widget.isReadOnly && paceCallback != null && !isLegFinished,
                    onTap: () => paceCallback?.call(mode),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHandoverGatePanel(MixedRelayTeamEntry team, bool isCompact) {
    final course = widget.raceState.course;
    final remainingToGate = math.max(
      0.0,
      course.handoverDistanceMeters - team.mensSecondRiderDistanceMeters,
    );
    final etaSeconds = MixedRelayHandoverHudCalculator.estimateSecondsToHandover(
      team,
      course,
    );
    final canTriggerLaunch = !widget.isReadOnly &&
        widget.onTriggerWomenLaunch != null &&
        (team.phase == MixedRelayPhase.mensLegActive ||
            team.phase == MixedRelayPhase.handoverApproaching ||
            team.phase == MixedRelayPhase.handoverWindowOpen);
    final isWindowOpen = team.phase == MixedRelayPhase.handoverWindowOpen;
    final isApproaching = team.phase == MixedRelayPhase.handoverApproaching;
    final handover = team.handoverEvent;

    final gateColor = isWindowOpen
        ? AppColors.statusSuccess
        : (isApproaching ? AppColors.amberWarning : AppColors.cyanAccent);

    return AnimatedBuilder(
      animation: _gatePulseController,
      builder: (context, child) {
        final pulse = isWindowOpen || isApproaching
            ? 0.45 + 0.45 * _gatePulseController.value
            : 0.35;
        return Container(
          padding: EdgeInsets.all(isCompact ? 12 : 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: gateColor.withValues(alpha: pulse),
              width: isWindowOpen ? 2.0 : 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'STREFA PRZEKAZANIA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.goldAccent,
                      letterSpacing: 0.4,
                    ),
                  ),
                  _StatusTag(
                    label: isWindowOpen
                        ? 'ZIELONE ŚWIATŁO'
                        : (isApproaching ? 'UWAGA: STREFY 500M' : 'FOTOKOMÓRKA'),
                    color: gateColor,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 132,
                child: CustomPaint(
                  painter: MixedRelayHandoverGatePainter(
                    team: team,
                    course: course,
                    pulseValue: _gatePulseController.value,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    _TelemetryMetricRow(
                      label: '2. kolarz do bramki',
                      value: MixedRelayHandoverHudCalculator
                          .formatRemainingDistance(remainingToGate),
                      valueColor: gateColor,
                    ),
                    const SizedBox(height: 6),
                    _TelemetryMetricRow(
                      label: 'Szacowany czas otwarcia',
                      value: etaSeconds == null
                          ? '—'
                          : '${etaSeconds.toStringAsFixed(1)} s',
                      valueColor: AppColors.textPrimary,
                    ),
                    if (team.mensLegSplitSeconds != null) ...[
                      const SizedBox(height: 6),
                      _TelemetryMetricRow(
                        label: 'Czas 1. zmiany (M)',
                        value: MixedRelayHandoverHudCalculator.formatRaceClock(
                          team.mensLegSplitSeconds!,
                        ),
                        valueColor: AppColors.accentBlue,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (handover != null)
                _HandoverEvaluationCard(handover: handover)
              else
                _HandoverLaunchButton(
                  isWindowOpen: isWindowOpen,
                  isApproaching: isApproaching,
                  enabled: canTriggerLaunch,
                  onTap: () {
                    final isFalseStart = !isWindowOpen;
                    widget.onTriggerWomenLaunch?.call(isFalseStart);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardStrip(MixedRelayTeamEntry activeTeam, bool isCompact) {
    final sorted = widget.raceState.leaderboardSorted;
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'KLASYFIKACJA SZTAFET NA ŻYWO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(sorted.length, (index) {
              final entry = sorted[index];
              final isSelected = entry.teamId == activeTeam.teamId;
              final progressPct =
                  (widget.raceState.totalCourseProgressPct(entry) * 100)
                      .toStringAsFixed(0);
              final timeText = entry.phase == MixedRelayPhase.finished
                  ? MixedRelayHandoverHudCalculator.formatRaceClock(
                      entry.effectiveTotalTimeSeconds,
                    )
                  : (entry.phase == MixedRelayPhase.disqualified
                      ? 'DSQ'
                      : '$progressPct%');
              return _HudSelectableChip(
                label: '${index + 1}. ${entry.countryIso} ($timeText)',
                accentColor: isSelected
                    ? AppColors.goldAccent
                    : MixedRelayHandoverHudCalculator.parseTeamColor(
                        entry.primaryColorHex,
                      ),
                selected: isSelected,
                enabled: !widget.isReadOnly || widget.onSelectTeam != null,
                onTap: () => _handleSelectTeam(entry.teamId),
              );
            }),
          ),
        ],
      ),
    );
  }

  Color _phaseBadgeColor(MixedRelayPhase phase) {
    switch (phase) {
      case MixedRelayPhase.preStart:
        return AppColors.textSecondary;
      case MixedRelayPhase.mensLegActive:
        return AppColors.accentBlue;
      case MixedRelayPhase.handoverApproaching:
        return AppColors.amberWarning;
      case MixedRelayPhase.handoverWindowOpen:
        return AppColors.statusSuccess;
      case MixedRelayPhase.womensLegActive:
        return AppColors.primaryAccent;
      case MixedRelayPhase.finished:
        return AppColors.goldAccent;
      case MixedRelayPhase.disqualified:
        return AppColors.crimsonAlert;
    }
  }
}

class _EmptyMixedRelayState extends StatelessWidget {
  final MixedRelayCourseSpec course;
  final VoidCallback? onClose;

  const _EmptyMixedRelayState({
    required this.course,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.groups_2_outlined,
            size: 40,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            course.eventName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Brak drużyn zgłoszonych do Sztafety Mieszanej TTT.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          if (onClose != null) ...[
            const SizedBox(height: 14),
            _HudSelectableChip(
              label: 'Zamknij',
              accentColor: AppColors.primaryAccent,
              selected: true,
              enabled: true,
              onTap: onClose!,
            ),
          ],
        ],
      ),
    );
  }
}

class _RiderSlotCard extends StatefulWidget {
  final MixedRelayRiderSlot rider;
  final bool isSecondTimeRider;
  final bool isSelected;
  final Color accentColor;
  final bool enabled;
  final VoidCallback onTap;

  const _RiderSlotCard({
    required this.rider,
    required this.isSecondTimeRider,
    required this.isSelected,
    required this.accentColor,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_RiderSlotCard> createState() => _RiderSlotCardState();
}

class _RiderSlotCardState extends State<_RiderSlotCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.rider;
    final borderColor = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : (_focused
            ? AppColors.goldAccent
            : (widget.isSelected || _hovered
                ? widget.accentColor
                : AppColors.cardBorder));

    final bgColor = r.isDropped
        ? AppColors.crimsonAlert.withValues(alpha: 0.08)
        : (_pressed
            ? AppColors.surfaceLight.withValues(alpha: 0.9)
            : (_hovered ? AppColors.surfaceLight : const Color(0xFF1C2029)));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.enabled) widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _focused || widget.isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Opacity(
            opacity: r.isDropped ? 0.65 : 1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            r.nationalityIso,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              r.fullName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.isSecondTimeRider && !r.isDropped)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.goldAccent.withValues(alpha: 0.7),
                          ),
                        ),
                        child: const Text(
                          '2. CZAS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.goldAccent,
                          ),
                        ),
                      ),
                    if (r.isPulling && !r.isDropped)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: widget.accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ZMIANA',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: widget.accentColor,
                          ),
                        ),
                      ),
                    if (r.isDropped)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.crimsonAlert.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ODPADŁ',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.crimsonAlert,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${r.currentPowerWatts.round()} W • ${r.currentSpeedKmh.toStringAsFixed(1)} km/h',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      "W': ${(r.wPrimeRemainingPct * 100).round()}%",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: r.wPrimeRemainingPct < 0.2
                            ? AppColors.crimsonAlert
                            : AppColors.statusSuccess,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: r.wPrimeRemainingPct.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: AppColors.background,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      r.wPrimeRemainingPct < 0.2
                          ? AppColors.crimsonAlert
                          : (r.wPrimeRemainingPct < 0.45
                              ? AppColors.amberWarning
                              : AppColors.statusSuccess),
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

class _HandoverLaunchButton extends StatefulWidget {
  final bool isWindowOpen;
  final bool isApproaching;
  final bool enabled;
  final VoidCallback onTap;

  const _HandoverLaunchButton({
    required this.isWindowOpen,
    required this.isApproaching,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_HandoverLaunchButton> createState() => _HandoverLaunchButtonState();
}

class _HandoverLaunchButtonState extends State<_HandoverLaunchButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isWindowOpen
        ? AppColors.statusSuccess
        : (widget.isApproaching
            ? AppColors.amberWarning
            : AppColors.primaryAccent);
    final label = widget.isWindowOpen
        ? 'WYPUŚĆ TRÓJKĘ KOBIECĄ!'
        : 'WCZESNY START (RYZYKO FALSTARTU +15s)';

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.enabled) widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: !widget.enabled
                ? AppColors.surfaceLight.withValues(alpha: 0.5)
                : (_pressed
                    ? baseColor.withValues(alpha: 0.9)
                    : (_hovered
                        ? baseColor.withValues(alpha: 0.35)
                        : baseColor.withValues(alpha: 0.22))),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: !widget.enabled
                  ? AppColors.cardBorder
                  : (_focused ? AppColors.goldAccent : baseColor),
              width: _focused ? 2.0 : 1.3,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isWindowOpen
                    ? Icons.flag_circle_rounded
                    : Icons.warning_amber_rounded,
                size: 18,
                color: !widget.enabled
                    ? AppColors.textSecondary
                    : (_pressed ? AppColors.background : baseColor),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: !widget.enabled
                        ? AppColors.textSecondary
                        : (_pressed ? AppColors.background : AppColors.textPrimary),
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

class _HandoverEvaluationCard extends StatelessWidget {
  final MixedRelayHandoverEvent handover;

  const _HandoverEvaluationCard({required this.handover});

  @override
  Widget build(BuildContext context) {
    final isPenalty = handover.falseStartPenaltySeconds > 0.0;
    final color = isPenalty
        ? AppColors.crimsonAlert
        : (handover.gateReactionDelaySeconds <= 0.25
            ? AppColors.statusSuccess
            : AppColors.goldAccent);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                handover.qualityRatingLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                '${handover.handoverQualityScore.round()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '2. kolarz: ${handover.mensSecondRiderName} • Reakcja bramki: ${handover.gateReactionDelaySeconds.toStringAsFixed(2)} s',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          if (isPenalty) ...[
            const SizedBox(height: 4),
            Text(
              'Kara za falstart: +${handover.falseStartPenaltySeconds.toStringAsFixed(0)} s',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.crimsonAlert,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TelemetryMetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _TelemetryMetricRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _HudSelectableChip extends StatefulWidget {
  final String label;
  final Color accentColor;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _HudSelectableChip({
    required this.label,
    required this.accentColor,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_HudSelectableChip> createState() => _HudSelectableChipState();
}

class _HudSelectableChipState extends State<_HudSelectableChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : (_focused
            ? AppColors.goldAccent
            : (widget.selected || _hovered
                ? widget.accentColor
                : AppColors.cardBorder));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.enabled) widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: !widget.enabled
                ? AppColors.surfaceLight.withValues(alpha: 0.45)
                : (_pressed
                    ? widget.accentColor.withValues(alpha: 0.28)
                    : (widget.selected
                        ? widget.accentColor.withValues(alpha: 0.18)
                        : (_hovered
                            ? AppColors.surfaceLight
                            : AppColors.background))),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: _focused || widget.selected ? 1.4 : 1.0,
            ),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w600,
              color: !widget.enabled
                  ? AppColors.textSecondary.withValues(alpha: 0.6)
                  : (widget.selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary),
              fontFeatures: const [FontFeature.tabularFigures()],
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
  final VoidCallback onTap;

  const _HudIconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
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
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (widget.enabled) widget.onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTapDown:
              widget.enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp:
              widget.enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _pressed
                  ? AppColors.primaryAccent.withValues(alpha: 0.35)
                  : (_hovered ? AppColors.surfaceLight : AppColors.background),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : (_hovered ? AppColors.textSecondary : AppColors.cardBorder),
              ),
            ),
            child: Icon(
              widget.icon,
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

/// Rysuje wizualizację strefy przekazania zmiany: 3 kolarzy zbliżających się
/// do fotokomórki oraz bramkę startową trójki kobiecej.
class MixedRelayHandoverGatePainter extends CustomPainter {
  final MixedRelayTeamEntry team;
  final MixedRelayCourseSpec course;
  final double pulseValue;

  const MixedRelayHandoverGatePainter({
    required this.team,
    required this.course,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bgPaint = Paint()..color = const Color(0xFF13161D);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      bgPaint,
    );

    final gateX = size.width * 0.62;
    final roadTop = size.height * 0.28;
    final roadBottom = size.height * 0.78;
    final roadMidY = (roadTop + roadBottom) * 0.5;

    // Asfaltowa nawierzchnia strefy przekazania
    final roadPaint = Paint()..color = const Color(0xFF1E232E);
    canvas.drawRect(
      Rect.fromLTRB(8, roadTop, size.width - 8, roadBottom),
      roadPaint,
    );

    // Linia osi drogi
    final dashPaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 1.2;
    for (double x = 14; x < size.width - 14; x += 14) {
      canvas.drawLine(Offset(x, roadMidY), Offset(x + 7, roadMidY), dashPaint);
    }

    // Linia fotokomórki bramki
    final isOpen = team.phase == MixedRelayPhase.handoverWindowOpen ||
        team.phase == MixedRelayPhase.womensLegActive ||
        team.phase == MixedRelayPhase.finished;
    final gateColor = isOpen
        ? AppColors.statusSuccess
        : (team.phase == MixedRelayPhase.handoverApproaching
            ? AppColors.amberWarning
            : AppColors.crimsonAlert);

    final gatePaint = Paint()
      ..color = gateColor.withValues(alpha: 0.7 + 0.3 * pulseValue)
      ..strokeWidth = 3.0;
    canvas.drawLine(Offset(gateX, roadTop - 8), Offset(gateX, roadBottom + 8), gatePaint);

    // Sygnalizator świetlny nad bramką
    canvas.drawCircle(
      Offset(gateX, roadTop - 16),
      6,
      Paint()..color = gateColor,
    );

    // Pozycje trójki męskiej zbliżającej się z lewej do bramki
    final secondId =
        MixedRelayHandoverHudCalculator.findSecondRiderId(team.mensTrio);
    final approachZone = math.max(100.0, course.handoverApproachZoneMeters);
    for (var i = 0; i < team.mensTrio.length; i++) {
      final rider = team.mensTrio[i];
      final deltaToGate = course.handoverDistanceMeters - rider.distanceMeters;
      final normalized = (1.0 - (deltaToGate / approachZone)).clamp(0.05, 1.15);
      final rx = 18 + normalized * (gateX - 18);
      final ry = roadTop + 14 + i * ((roadBottom - roadTop - 28) / 2);
      final isSecond = rider.riderId == secondId;

      canvas.drawCircle(
        Offset(rx.clamp(16.0, size.width - 16.0), ry),
        isSecond ? 6.5 : 4.8,
        Paint()
          ..color = rider.isDropped
              ? AppColors.crimsonAlert
              : (isSecond ? AppColors.goldAccent : AppColors.accentBlue),
      );
    }

    // Pozycje trójki kobiecej na rampie startowej po prawej od bramki
    for (var i = 0; i < team.womensTrio.length; i++) {
      final rider = team.womensTrio[i];
      final legProgress = course.womensLegDistanceMeters > 0
          ? (rider.distanceMeters / course.womensLegDistanceMeters)
              .clamp(0.0, 1.0)
          : 0.0;
      final wx = gateX + 18 + legProgress * (size.width - gateX - 30);
      final wy = roadTop + 14 + i * ((roadBottom - roadTop - 28) / 2);
      canvas.drawCircle(
        Offset(wx.clamp(gateX + 12, size.width - 14.0), wy),
        5.2,
        Paint()
          ..color = rider.isDropped
              ? AppColors.crimsonAlert
              : AppColors.primaryAccent,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MixedRelayHandoverGatePainter oldDelegate) {
    return oldDelegate.team != team ||
        oldDelegate.course != course ||
        oldDelegate.pulseValue != pulseValue;
  }
}

class _MixedRelayCourseProgressPainter extends CustomPainter {
  final double progress;
  final double handoverRatio;
  final MixedRelayPhase phase;

  const _MixedRelayCourseProgressPainter({
    required this.progress,
    required this.handoverRatio,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackY = size.height * 0.5;
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, trackY - 4, size.width, 8),
      const Radius.circular(4),
    );
    canvas.drawRRect(trackRect, Paint()..color = AppColors.surfaceLight);

    final fillWidth = (size.width * progress.clamp(0.0, 1.0));
    if (fillWidth > 0) {
      final fillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, trackY - 4, fillWidth, 8),
        const Radius.circular(4),
      );
      final fillColor = phase == MixedRelayPhase.womensLegActive ||
              phase == MixedRelayPhase.finished
          ? AppColors.primaryAccent
          : AppColors.accentBlue;
      canvas.drawRRect(fillRect, Paint()..color = fillColor);
    }

    // Znacznik bramki przekazania zmiany
    final gateX = size.width * handoverRatio.clamp(0.05, 0.95);
    canvas.drawLine(
      Offset(gateX, 2),
      Offset(gateX, size.height - 2),
      Paint()
        ..color = AppColors.goldAccent
        ..strokeWidth = 2.0,
    );
    canvas.drawCircle(
      Offset(gateX, trackY),
      5,
      Paint()..color = AppColors.goldAccent,
    );
  }

  @override
  bool shouldRepaint(covariant _MixedRelayCourseProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.handoverRatio != handoverRatio ||
        oldDelegate.phase != phase;
  }
}
