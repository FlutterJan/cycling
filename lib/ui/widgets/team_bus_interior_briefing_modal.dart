import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../engine/peloton/team_bus_pre_race_speech_buffs.dart';

/// Wyraz mimiki twarzy kolarza siedzącego w fotelu autobusu drużyny.
enum BusRiderFacialExpression {
  calmFocused,
  firedUp,
  relievedSmiling,
  tenseNervous,
  determinedCaptain;

  String get labelPl {
    switch (this) {
      case BusRiderFacialExpression.calmFocused:
        return 'Spokojne skupienie';
      case BusRiderFacialExpression.firedUp:
        return 'Pełna mobilizacja';
      case BusRiderFacialExpression.relievedSmiling:
        return 'Ulga i uśmiech';
      case BusRiderFacialExpression.tenseNervous:
        return 'Napięcie startowe';
      case BusRiderFacialExpression.determinedCaptain:
        return 'Determinacja lidera';
    }
  }

  Color get badgeColor {
    switch (this) {
      case BusRiderFacialExpression.calmFocused:
        return AppColors.accentBlue;
      case BusRiderFacialExpression.firedUp:
        return AppColors.goldAccent;
      case BusRiderFacialExpression.relievedSmiling:
        return AppColors.statusSuccess;
      case BusRiderFacialExpression.tenseNervous:
        return AppColors.amberWarning;
      case BusRiderFacialExpression.determinedCaptain:
        return AppColors.primaryAccent;
    }
  }

  IconData get icon {
    switch (this) {
      case BusRiderFacialExpression.calmFocused:
        return Icons.psychology_alt_rounded;
      case BusRiderFacialExpression.firedUp:
        return Icons.local_fire_department_rounded;
      case BusRiderFacialExpression.relievedSmiling:
        return Icons.sentiment_satisfied_alt_rounded;
      case BusRiderFacialExpression.tenseNervous:
        return Icons.bolt_rounded;
      case BusRiderFacialExpression.determinedCaptain:
        return Icons.military_tech_rounded;
    }
  }
}

/// Znacznik kluczowego punktu na tablicy profilu etapu w autobusie.
class BusStageBoardMarker {
  final double progress; // 0.0 .. 1.0
  final String label;
  final Color color;

  const BusStageBoardMarker({
    required this.progress,
    required this.label,
    this.color = AppColors.goldAccent,
  });

  Map<String, dynamic> toJson() => {
        'progress': progress,
        'label': label,
        'colorValue': color.toARGB32(),
      };

  factory BusStageBoardMarker.fromJson(Map<String, dynamic> json) {
    return BusStageBoardMarker(
      progress: ((json['progress'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0),
      label: json['label'] as String? ?? 'KOM',
      color: json['colorValue'] != null
          ? Color((json['colorValue'] as num).toInt())
          : AppColors.goldAccent,
    );
  }
}

/// Dane wejściowe dla klimatycznego modalu wnętrza autobusu drużyny przed startem.
class TeamBusInteriorBriefingData {
  final String teamName;
  final String raceName;
  final String stageName;
  final String stageTypeLabel;
  final double distanceKm;
  final int elevationGainM;
  final String weatherLabel;
  final int temperatureC;
  final List<double> elevationSamplesM;
  final List<BusStageBoardMarker> keyMarkers;
  final List<PreRaceBusRiderProfile> squad;
  final Color primaryTeamColor;
  final Color accentTeamColor;
  final ManagerSpeechTone initialTone;
  final LeaderOneOnOneTopic? initialLeaderTopic;

  const TeamBusInteriorBriefingData({
    required this.teamName,
    required this.raceName,
    required this.stageName,
    required this.stageTypeLabel,
    required this.distanceKm,
    required this.elevationGainM,
    required this.weatherLabel,
    required this.temperatureC,
    required this.elevationSamplesM,
    required this.keyMarkers,
    required this.squad,
    this.primaryTeamColor = AppColors.primaryAccent,
    this.accentTeamColor = AppColors.goldAccent,
    this.initialTone = ManagerSpeechTone.calmTacticalAnalysis,
    this.initialLeaderTopic,
  });

  factory TeamBusInteriorBriefingData.demo() {
    return const TeamBusInteriorBriefingData(
      teamName: 'Bora-Veloce Pro Cycling',
      raceName: 'Tour de France — Etap 14',
      stageName: 'Pau → Saint-Lary-Soulan (Pla d\'Adet)',
      stageTypeLabel: 'Górski • HC',
      distanceKm: 151.9,
      elevationGainM: 4040,
      weatherLabel: 'Słonecznie, wiatr SW 14 km/h',
      temperatureC: 24,
      elevationSamplesM: [
        210,
        245,
        290,
        330,
        410,
        520,
        780,
        1180,
        1620,
        2115,
        1420,
        890,
        740,
        1040,
        1569,
        1110,
        830,
        1120,
        1480,
        1680,
      ],
      keyMarkers: [
        BusStageBoardMarker(
          progress: 0.48,
          label: 'Col du Tourmalet (HC)',
          color: AppColors.crimsonAlert,
        ),
        BusStageBoardMarker(
          progress: 0.72,
          label: 'Hourquette d\'Ancizan (2)',
          color: AppColors.amberWarning,
        ),
        BusStageBoardMarker(
          progress: 0.98,
          label: 'Pla d\'Adet (META HC)',
          color: AppColors.goldAccent,
        ),
      ],
      squad: TeamBusPreRaceSpeechBuffs.defaultDemoSquad,
    );
  }

  Map<String, dynamic> toJson() => {
        'teamName': teamName,
        'raceName': raceName,
        'stageName': stageName,
        'stageTypeLabel': stageTypeLabel,
        'distanceKm': distanceKm,
        'elevationGainM': elevationGainM,
        'weatherLabel': weatherLabel,
        'temperatureC': temperatureC,
        'elevationSamplesM': elevationSamplesM,
        'keyMarkers': keyMarkers.map((m) => m.toJson()).toList(),
        'squad': squad.map((r) => r.toJson()).toList(),
        'primaryTeamColor': primaryTeamColor.toARGB32(),
        'accentTeamColor': accentTeamColor.toARGB32(),
        'initialTone': initialTone.name,
        'initialLeaderTopic': initialLeaderTopic?.name,
      };

  factory TeamBusInteriorBriefingData.fromJson(Map<String, dynamic> json) {
    final toneName =
        json['initialTone'] as String? ?? ManagerSpeechTone.calmTacticalAnalysis.name;
    final parsedTone = ManagerSpeechTone.values.firstWhere(
      (t) => t.name == toneName,
      orElse: () => ManagerSpeechTone.calmTacticalAnalysis,
    );
    final topicName = json['initialLeaderTopic'] as String?;
    final parsedTopic = topicName == null
        ? null
        : LeaderOneOnOneTopic.values.firstWhere(
            (t) => t.name == topicName,
            orElse: () => LeaderOneOnOneTopic.trustYourInstincts,
          );

    return TeamBusInteriorBriefingData(
      teamName: json['teamName'] as String? ?? 'Pro Cycling Team',
      raceName: json['raceName'] as String? ?? 'Wyścig Etapowy',
      stageName: json['stageName'] as String? ?? 'Start → Meta',
      stageTypeLabel: json['stageTypeLabel'] as String? ?? 'Etap',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 160.0,
      elevationGainM: (json['elevationGainM'] as num?)?.toInt() ?? 1500,
      weatherLabel: json['weatherLabel'] as String? ?? 'Bezchmurnie',
      temperatureC: (json['temperatureC'] as num?)?.toInt() ?? 21,
      elevationSamplesM: (json['elevationSamplesM'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [100, 150, 120, 220, 180],
      keyMarkers: (json['keyMarkers'] as List<dynamic>?)
              ?.map((e) => BusStageBoardMarker.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      squad: (json['squad'] as List<dynamic>?)
              ?.map((e) => PreRaceBusRiderProfile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      primaryTeamColor: json['primaryTeamColor'] != null
          ? Color((json['primaryTeamColor'] as num).toInt())
          : AppColors.primaryAccent,
      accentTeamColor: json['accentTeamColor'] != null
          ? Color((json['accentTeamColor'] as num).toInt())
          : AppColors.goldAccent,
      initialTone: parsedTone,
      initialLeaderTopic: parsedTopic,
    );
  }
}

/// Wyświetla modal wnętrza autobusu drużyny przed wyjściem na linię startu.
Future<TeamBusSpeechBuffSummary?> showTeamBusInteriorBriefingModal(
  BuildContext context, {
  TeamBusInteriorBriefingData? data,
  bool isDisabled = false,
}) {
  return showDialog<TeamBusSpeechBuffSummary>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: TeamBusInteriorBriefingModal(
          data: data ?? TeamBusInteriorBriefingData.demo(),
          isDisabled: isDisabled,
          onConfirm: (summary) => Navigator.of(dialogContext).pop(summary),
          onClose: () => Navigator.of(dialogContext).pop(),
        ),
      );
    },
  );
}

/// Klimatyczny modal wnętrza autobusu zespołu wyświetlany przed wyjściem na linię startu:
/// kolarze siedzący w fotelach z założonymi słuchawkami, tablica z narysowanym profilem etapu,
/// wybór przemowy motywacyjnej oraz reakcje mimiki i morale poszczególnych zawodników.
class TeamBusInteriorBriefingModal extends StatefulWidget {
  final TeamBusInteriorBriefingData data;
  final bool isDisabled;
  final ValueChanged<TeamBusSpeechBuffSummary>? onConfirm;
  final VoidCallback? onClose;

  const TeamBusInteriorBriefingModal({
    super.key,
    required this.data,
    this.isDisabled = false,
    this.onConfirm,
    this.onClose,
  });

  /// Wylicza wyraz mimiki twarzy konkretnego kolarza na podstawie reakcji na przemowę.
  static BusRiderFacialExpression resolveExpression({
    required RiderPreRaceSpeechBuff buff,
    required ManagerSpeechTone tone,
  }) {
    if (buff.pelotonStressResilienceDelta < -0.02 ||
        buff.initialMoraleDelta < 0) {
      return BusRiderFacialExpression.tenseNervous;
    }
    if (buff.role == BusRiderRole.leader &&
        tone == ManagerSpeechTone.demandFullSacrificeForLeader) {
      return BusRiderFacialExpression.determinedCaptain;
    }
    if (tone == ManagerSpeechTone.relieveYouthPressure &&
        buff.initialMoraleDelta >= 12.0) {
      return BusRiderFacialExpression.relievedSmiling;
    }
    if (buff.initialMoraleDelta >= 12.0 ||
        tone == ManagerSpeechTone.emotionalAllInMobilization) {
      return BusRiderFacialExpression.firedUp;
    }
    return BusRiderFacialExpression.calmFocused;
  }

  @override
  State<TeamBusInteriorBriefingModal> createState() =>
      _TeamBusInteriorBriefingModalState();
}

class _TeamBusInteriorBriefingModalState
    extends State<TeamBusInteriorBriefingModal>
    with SingleTickerProviderStateMixin {
  late ManagerSpeechTone _selectedTone;
  LeaderOneOnOneTopic? _selectedLeaderTopic;
  String? _selectedRiderId;
  bool _briefingLocked = false;
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _selectedTone = widget.data.initialTone;
    _selectedLeaderTopic = widget.data.initialLeaderTopic;
    _selectedRiderId =
        widget.data.squad.isNotEmpty ? widget.data.squad.first.riderId : null;
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant TeamBusInteriorBriefingModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.squad != widget.data.squad) {
      final exists = widget.data.squad.any((r) => r.riderId == _selectedRiderId);
      if (!exists) {
        _selectedRiderId = widget.data.squad.isNotEmpty
            ? widget.data.squad.first.riderId
            : null;
      }
    }
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  bool get _controlsDisabled => widget.isDisabled || _briefingLocked;

  TeamBusSpeechBuffSummary get _currentSummary =>
      TeamBusPreRaceSpeechBuffs.evaluateBriefing(
        tone: _selectedTone,
        leaderTopic: _selectedLeaderTopic,
        squad: widget.data.squad,
        isBriefingLocked: _briefingLocked,
      );

  void _selectTone(ManagerSpeechTone tone) {
    if (_controlsDisabled) return;
    setState(() {
      _selectedTone = tone;
    });
  }

  void _selectLeaderTopic(LeaderOneOnOneTopic? topic) {
    if (_controlsDisabled) return;
    setState(() {
      _selectedLeaderTopic = _selectedLeaderTopic == topic ? null : topic;
    });
  }

  void _confirmAndExitBus() {
    if (_controlsDisabled) return;
    setState(() {
      _briefingLocked = true;
    });
    final lockedSummary = TeamBusPreRaceSpeechBuffs.evaluateBriefing(
      tone: _selectedTone,
      leaderTopic: _selectedLeaderTopic,
      squad: widget.data.squad,
      isBriefingLocked: true,
    );
    widget.onConfirm?.call(lockedSummary);
  }

  @override
  Widget build(BuildContext context) {
    final summary = _currentSummary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 1200;
        final double height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 820;
        final bool isMobile = width < 720;
        final bool isDesktop = width >= 1120;

        final double maxModalWidth = isDesktop
            ? math.min(width, 1380)
            : (isMobile ? width : math.min(width, 980));
        final double maxModalHeight = isMobile
            ? height
            : math.min(height, isDesktop ? 840 : 760);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxModalWidth,
              maxHeight: maxModalHeight,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF2A2F3D),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.65),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  _buildHeaderBar(isMobile: isMobile),
                  Expanded(
                    child: isMobile
                        ? _buildMobileBody(summary)
                        : _buildWideBody(summary, isDesktop: isDesktop),
                  ),
                  _buildFooterBar(summary, isMobile: isMobile),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderBar({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 20,
        vertical: isMobile ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          bottom: BorderSide(color: Color(0xFF2A2F3D), width: 1),
        ),
        gradient: LinearGradient(
          colors: [
            widget.data.primaryTeamColor.withValues(alpha: 0.22),
            AppColors.surface,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: widget.data.primaryTeamColor.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.data.accentTeamColor.withValues(alpha: 0.6),
              ),
            ),
            child: Icon(
              Icons.directions_bus_filled_rounded,
              color: widget.data.accentTeamColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'AUTOBUS DRUŻYNY • ODPRAWA PRZEDSTARTOWA',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: isMobile ? 11 : 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.goldAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_briefingLocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.statusSuccess.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.statusSuccess.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Text(
                          'GOTOWI DO STARTU',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.statusSuccess,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.data.teamName} — ${widget.data.raceName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _InteractiveIconButton(
            icon: Icons.close_rounded,
            tooltip: 'Zamknij odprawę',
            isDisabled: widget.isDisabled,
            onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBody(TeamBusSpeechBuffSummary summary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBusInteriorScene(summary, isCompact: true, maxColumns: 2),
          const SizedBox(height: 12),
          _buildSpeechConsole(summary, isCompact: true),
        ],
      ),
    );
  }

  Widget _buildWideBody(
    TeamBusSpeechBuffSummary summary, {
    required bool isDesktop,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: isDesktop ? 7 : 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildBusInteriorScene(
              summary,
              isCompact: false,
              maxColumns: isDesktop ? 3 : 2,
            ),
          ),
        ),
        Container(
          width: 1,
          color: const Color(0xFF2A2F3D),
        ),
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildSpeechConsole(summary, isCompact: false),
          ),
        ),
      ],
    );
  }

  Widget _buildBusInteriorScene(
    TeamBusSpeechBuffSummary summary, {
    required bool isCompact,
    required int maxColumns,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ambientController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _TeamBusCabinBackdropPainter(
                    ambientPhase: _ambientController.value,
                    primaryTeamColor: widget.data.primaryTeamColor,
                    accentTeamColor: widget.data.accentTeamColor,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isCompact ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildWhiteboardStageProfile(isCompact: isCompact),
                const SizedBox(height: 14),
                _buildBusSeatsSection(
                  summary,
                  isCompact: isCompact,
                  maxColumns: maxColumns,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteboardStageProfile({required bool isCompact}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13161D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3A4154), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(isCompact ? 10 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.primaryAccent.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  widget.data.stageTypeLabel,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.data.stageName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isCompact ? 12 : 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _MiniTelemetryChip(
                icon: Icons.straighten_rounded,
                label: '${widget.data.distanceKm.toStringAsFixed(1)} km',
              ),
              _MiniTelemetryChip(
                icon: Icons.terrain_rounded,
                label: '+${widget.data.elevationGainM} m',
              ),
              _MiniTelemetryChip(
                icon: Icons.thermostat_rounded,
                label: '${widget.data.temperatureC}°C • ${widget.data.weatherLabel}',
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: isCompact ? 98 : 118,
            child: CustomPaint(
              painter: _BusStageProfileBoardPainter(
                elevationSamplesM: widget.data.elevationSamplesM,
                markers: widget.data.keyMarkers,
                accentColor: _selectedTone.accentColor,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusSeatsSection(
    TeamBusSpeechBuffSummary summary, {
    required bool isCompact,
    required int maxColumns,
  }) {
    if (widget.data.squad.isEmpty || summary.riderBuffs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A2F3D)),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.event_seat_outlined,
              color: AppColors.textSecondary,
              size: 28,
            ),
            SizedBox(height: 8),
            Text(
              'Brak kolarzy przypisanych do autobusu na ten etap.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final RiderPreRaceSpeechBuff selectedBuff = summary.riderBuffs.firstWhere(
      (b) => b.riderId == _selectedRiderId,
      orElse: () => summary.riderBuffs.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.headphones_rounded,
              size: 16,
              color: AppColors.goldAccent,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Kolarze w fotelach (${summary.riderBuffs.length}) — słuchawki i reakcje na odprawę',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, gridConstraints) {
            final double availW = gridConstraints.maxWidth;
            final int cols = availW < 340 ? 1 : maxColumns;
            const double spacing = 10;
            final double cardWidth =
                ((availW - spacing * (cols - 1)) / cols).clamp(140.0, 420.0);

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (int i = 0; i < summary.riderBuffs.length; i++)
                  SizedBox(
                    width: cardWidth,
                    child: _BusRiderSeatCard(
                      index: i,
                      buff: summary.riderBuffs[i],
                      expression: TeamBusInteriorBriefingModal.resolveExpression(
                        buff: summary.riderBuffs[i],
                        tone: _selectedTone,
                      ),
                      isSelected:
                          summary.riderBuffs[i].riderId == selectedBuff.riderId,
                      isDisabled: widget.isDisabled,
                      ambientAnimation: _ambientController,
                      teamPrimaryColor: widget.data.primaryTeamColor,
                      teamAccentColor: widget.data.accentTeamColor,
                      onTap: () {
                        if (widget.isDisabled) return;
                        setState(() {
                          _selectedRiderId = summary.riderBuffs[i].riderId;
                        });
                      },
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        _buildSelectedRiderReactionBanner(selectedBuff),
      ],
    );
  }

  Widget _buildSelectedRiderReactionBanner(RiderPreRaceSpeechBuff buff) {
    final expression = TeamBusInteriorBriefingModal.resolveExpression(
      buff: buff,
      tone: _selectedTone,
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: expression.badgeColor.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            expression.icon,
            color: expression.badgeColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${buff.riderName} (${buff.role.labelPl})',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      expression.labelPl,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: expression.badgeColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  buff.reactionQuotePl,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechConsole(
    TeamBusSpeechBuffSummary summary, {
    required bool isCompact,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '1. WYBIERZ PRZEMOWĘ MOTYWACYJNĄ',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
            color: AppColors.goldAccent,
          ),
        ),
        const SizedBox(height: 8),
        for (final tone in ManagerSpeechTone.values) ...[
          _SpeechOptionTile(
            tone: tone,
            isSelected: _selectedTone == tone,
            isDisabled: _controlsDisabled,
            onTap: () => _selectTone(tone),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        const Text(
          '2. ROZMOWA 1-NA-1 Z LIDEREM (OPCJONALNIE)',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
            color: AppColors.goldAccent,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final topic in LeaderOneOnOneTopic.values)
              _LeaderTopicChip(
                topic: topic,
                isSelected: _selectedLeaderTopic == topic,
                isDisabled: _controlsDisabled,
                onTap: () => _selectLeaderTopic(topic),
              ),
          ],
        ),
        if (_selectedLeaderTopic != null) ...[
          const SizedBox(height: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.goldAccent.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedLeaderTopic!.promptPl,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Odpowiedź lidera: ${_selectedLeaderTopic!.leaderReplyPl}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppColors.goldAccent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedLeaderTopic!.effectSummaryPl,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusSuccess,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _buildTeamSummaryCard(summary),
      ],
    );
  }

  Widget _buildTeamSummaryCard(TeamBusSpeechBuffSummary summary) {
    final String moraleStr =
        '${summary.avgInitialMoraleDelta >= 0 ? '+' : ''}${summary.avgInitialMoraleDelta.toStringAsFixed(1)}';
    final String hrStr =
        '${summary.avgRestingHrDeltaBpm >= 0 ? '+' : ''}${summary.avgRestingHrDeltaBpm.toStringAsFixed(1)} BPM';
    final String stressStr =
        '${summary.avgStressResilienceDelta >= 0 ? '+' : ''}${(summary.avgStressResilienceDelta * 100).toStringAsFixed(0)}%';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WPŁYW ODPRAWY NA DRUŻYNĘ',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SummaryMetricTile(
                  label: 'Śr. Morale',
                  value: moraleStr,
                  color: summary.avgInitialMoraleDelta >= 0
                      ? AppColors.statusSuccess
                      : AppColors.crimsonAlert,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryMetricTile(
                  label: 'Śr. Tętno',
                  value: hrStr,
                  color: summary.avgRestingHrDeltaBpm <= 0
                      ? AppColors.accentBlue
                      : AppColors.amberWarning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryMetricTile(
                  label: 'Odporność',
                  value: stressStr,
                  color: summary.avgStressResilienceDelta >= 0
                      ? AppColors.goldAccent
                      : AppColors.crimsonAlert,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterBar(
    TeamBusSpeechBuffSummary summary, {
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 10 : 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: Color(0xFF2A2F3D), width: 1),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Text(
            _selectedTone.tacticalSummaryPl,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              _ActionPillButton(
                label: 'Anuluj',
                isPrimary: false,
                isDisabled: widget.isDisabled,
                onPressed:
                    widget.onClose ?? () => Navigator.of(context).maybePop(),
              ),
              _ActionPillButton(
                label: _briefingLocked
                    ? 'Odprawa zatwierdzona'
                    : 'Wyjdź na linię startu',
                icon: _briefingLocked
                    ? Icons.check_circle_rounded
                    : Icons.flag_rounded,
                isPrimary: true,
                isDisabled: _controlsDisabled,
                onPressed: _confirmAndExitBus,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniTelemetryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniTelemetryChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFeatures: [FontFeature.tabularFigures()],
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryMetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2E3440)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BusRiderSeatCard extends StatefulWidget {
  final int index;
  final RiderPreRaceSpeechBuff buff;
  final BusRiderFacialExpression expression;
  final bool isSelected;
  final bool isDisabled;
  final Animation<double> ambientAnimation;
  final Color teamPrimaryColor;
  final Color teamAccentColor;
  final VoidCallback onTap;

  const _BusRiderSeatCard({
    required this.index,
    required this.buff,
    required this.expression,
    required this.isSelected,
    required this.isDisabled,
    required this.ambientAnimation,
    required this.teamPrimaryColor,
    required this.teamAccentColor,
    required this.onTap,
  });

  @override
  State<_BusRiderSeatCard> createState() => _BusRiderSeatCardState();
}

class _BusRiderSeatCardState extends State<_BusRiderSeatCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = widget.isSelected
        ? AppColors.goldAccent
        : (_focused
            ? AppColors.accentBlue
            : (_hovered ? const Color(0xFF475069) : const Color(0xFF2A2F3D)));

    final String moraleDeltaStr =
        '${widget.buff.initialMoraleDelta >= 0 ? '+' : ''}${widget.buff.initialMoraleDelta.toStringAsFixed(0)}';
    final String hrDeltaStr =
        '${widget.buff.restingHeartRateDeltaBpm >= 0 ? '+' : ''}${widget.buff.restingHeartRateDeltaBpm}';

    return Opacity(
      opacity: widget.isDisabled ? 0.55 : 1.0,
      child: FocusableActionDetector(
        enabled: !widget.isDisabled,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        child: GestureDetector(
          onTapDown: widget.isDisabled
              ? null
              : (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.isDisabled ? null : widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? AppColors.surfaceLight
                    : AppColors.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: borderColor,
                  width: widget.isSelected || _focused ? 1.5 : 1.0,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.goldAccent.withValues(alpha: 0.16),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.buff.riderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: widget.buff.role == BusRiderRole.leader
                              ? AppColors.goldAccent.withValues(alpha: 0.18)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          widget.buff.role.labelPl,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: widget.buff.role == BusRiderRole.leader
                                ? AppColors.goldAccent
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 74,
                    child: AnimatedBuilder(
                      animation: widget.ambientAnimation,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _BusRiderSeatAvatarPainter(
                            seed: widget.index,
                            expression: widget.expression,
                            pulse: widget.ambientAnimation.value,
                            teamPrimaryColor: widget.teamPrimaryColor,
                            teamAccentColor: widget.teamAccentColor,
                          ),
                          child: const SizedBox.expand(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: widget.expression.badgeColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.expression.icon,
                          size: 11,
                          color: widget.expression.badgeColor,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            widget.expression.labelPl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: widget.expression.badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Morale $moraleDeltaStr',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: widget.buff.initialMoraleDelta >= 0
                              ? AppColors.statusSuccess
                              : AppColors.crimsonAlert,
                        ),
                      ),
                      Text(
                        '$hrDeltaStr BPM',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: widget.buff.restingHeartRateDeltaBpm <= 0
                              ? AppColors.accentBlue
                              : AppColors.amberWarning,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeechOptionTile extends StatefulWidget {
  final ManagerSpeechTone tone;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _SpeechOptionTile({
    required this.tone,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_SpeechOptionTile> createState() => _SpeechOptionTileState();
}

class _SpeechOptionTileState extends State<_SpeechOptionTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = widget.isSelected
        ? widget.tone.accentColor
        : (_focused
            ? AppColors.goldAccent
            : (_hovered ? const Color(0xFF475069) : const Color(0xFF2A2F3D)));

    return Opacity(
      opacity: widget.isDisabled ? 0.55 : 1.0,
      child: FocusableActionDetector(
        enabled: !widget.isDisabled,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        child: GestureDetector(
          onTapDown: widget.isDisabled
              ? null
              : (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.isDisabled ? null : widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.985 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? widget.tone.accentColor.withValues(alpha: 0.14)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: borderColor,
                  width: widget.isSelected || _focused ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.tone.accentColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.tone.icon,
                      size: 18,
                      color: widget.tone.accentColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tone.labelPl,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.tone.quotePl,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderTopicChip extends StatefulWidget {
  final LeaderOneOnOneTopic topic;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _LeaderTopicChip({
    required this.topic,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_LeaderTopicChip> createState() => _LeaderTopicChipState();
}

class _LeaderTopicChipState extends State<_LeaderTopicChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = widget.isSelected
        ? AppColors.goldAccent
        : (_focused
            ? AppColors.accentBlue
            : (_hovered ? const Color(0xFF475069) : const Color(0xFF2A2F3D)));

    return Opacity(
      opacity: widget.isDisabled ? 0.55 : 1.0,
      child: FocusableActionDetector(
        enabled: !widget.isDisabled,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        child: InkWell(
          onTap: widget.isDisabled ? null : widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.goldAccent.withValues(alpha: 0.16)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.topic.icon,
                  size: 14,
                  color: widget.isSelected
                      ? AppColors.goldAccent
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.topic.labelPl,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight:
                          widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: widget.isSelected
                          ? AppColors.goldAccent
                          : AppColors.textPrimary,
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

class _ActionPillButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isPrimary;
  final bool isDisabled;
  final VoidCallback onPressed;

  const _ActionPillButton({
    required this.label,
    this.icon,
    required this.isPrimary,
    required this.isDisabled,
    required this.onPressed,
  });

  @override
  State<_ActionPillButton> createState() => _ActionPillButtonState();
}

class _ActionPillButtonState extends State<_ActionPillButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = widget.isPrimary
        ? (widget.isDisabled
            ? AppColors.surfaceLight
            : (_hovered ? const Color(0xFFA25857) : AppColors.primaryAccent))
        : (_hovered ? AppColors.surfaceLight : AppColors.background);

    final Color borderColor = _focused
        ? AppColors.goldAccent
        : (widget.isPrimary
            ? AppColors.goldAccent.withValues(alpha: widget.isDisabled ? 0.2 : 0.6)
            : const Color(0xFF2A2F3D));

    return Opacity(
      opacity: widget.isDisabled ? 0.55 : 1.0,
      child: FocusableActionDetector(
        enabled: !widget.isDisabled,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        child: GestureDetector(
          onTapDown: widget.isDisabled
              ? null
              : (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.isDisabled ? null : widget.onPressed,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: _focused ? 1.5 : 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 16,
                      color: widget.isPrimary
                          ? AppColors.goldAccent
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: widget.isPrimary
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isDisabled;
  final VoidCallback onPressed;

  const _InteractiveIconButton({
    required this.icon,
    required this.tooltip,
    required this.isDisabled,
    required this.onPressed,
  });

  @override
  State<_InteractiveIconButton> createState() => _InteractiveIconButtonState();
}

class _InteractiveIconButtonState extends State<_InteractiveIconButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: !widget.isDisabled,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        child: InkWell(
          onTap: widget.isDisabled ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _hovered ? AppColors.surfaceLight : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused ? AppColors.goldAccent : const Color(0xFF2A2F3D),
              ),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: widget.isDisabled
                  ? AppColors.textSecondary.withValues(alpha: 0.4)
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Rysuje klimatyczne wnętrze luksusowego autobusu drużyny (okna, listwy LED, sufit).
class _TeamBusCabinBackdropPainter extends CustomPainter {
  final double ambientPhase;
  final Color primaryTeamColor;
  final Color accentTeamColor;

  const _TeamBusCabinBackdropPainter({
    required this.ambientPhase,
    required this.primaryTeamColor,
    required this.accentTeamColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF141820),
          Color(0xFF181B22),
          Color(0xFF11141A),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Przyciemnione okna po bokach autobusu
    final windowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF202A3B).withValues(alpha: 0.42),
          const Color(0xFF0E131B).withValues(alpha: 0.65),
        ],
      ).createShader(Offset.zero & size);

    const double margin = 12;
    final leftWindow = RRect.fromRectAndRadius(
      Rect.fromLTWH(margin, 20, size.width * 0.16, size.height * 0.45),
      const Radius.circular(12),
    );
    final rightWindow = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width - margin - size.width * 0.16,
        20,
        size.width * 0.16,
        size.height * 0.45,
      ),
      const Radius.circular(12),
    );
    canvas.drawRRect(leftWindow, windowPaint);
    canvas.drawRRect(rightWindow, windowPaint);

    // Subtelne paski oświetlenia LED pod sufitem autobusu
    final double ledAlpha = 0.28 + 0.18 * math.sin(ambientPhase * math.pi);
    final ledPaint = Paint()
      ..color = accentTeamColor.withValues(alpha: ledAlpha)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      const Offset(20, 8),
      Offset(size.width - 20, 8),
      ledPaint,
    );

    // Akcentowa linia drużyny przy podłodze
    final floorAccent = Paint()
      ..color = primaryTeamColor.withValues(alpha: 0.25)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(16, size.height - 6),
      Offset(size.width - 16, size.height - 6),
      floorAccent,
    );
  }

  @override
  bool shouldRepaint(covariant _TeamBusCabinBackdropPainter oldDelegate) {
    return oldDelegate.ambientPhase != ambientPhase ||
        oldDelegate.primaryTeamColor != primaryTeamColor ||
        oldDelegate.accentTeamColor != accentTeamColor;
  }
}

/// Rysuje narysowany na tablicy taktycznej profil wysokościowy etapu.
class _BusStageProfileBoardPainter extends CustomPainter {
  final List<double> elevationSamplesM;
  final List<BusStageBoardMarker> markers;
  final Color accentColor;

  const _BusStageProfileBoardPainter({
    required this.elevationSamplesM,
    required this.markers,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final samples = elevationSamplesM.length >= 2
        ? elevationSamplesM
        : const [100.0, 220.0, 180.0, 340.0, 260.0];

    final double minEle = samples.reduce(math.min);
    final double maxEle = samples.reduce(math.max);
    final double eleRange = math.max(1.0, maxEle - minEle);

    const double padTop = 18;
    const double padBottom = 14;
    final double plotH = math.max(12.0, size.height - padTop - padBottom);

    // Siatka tablicy taktycznej
    final gridPaint = Paint()
      ..color = const Color(0xFF2A2F3D).withValues(alpha: 0.65)
      ..strokeWidth = 0.8;
    for (int i = 1; i <= 3; i++) {
      final double y = padTop + (plotH * i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final Path linePath = Path();
    final Path fillPath = Path();

    for (int i = 0; i < samples.length; i++) {
      final double t = i / (samples.length - 1);
      final double x = t * size.width;
      final double norm = (samples[i] - minEle) / eleRange;
      final double y = padTop + plotH * (1.0 - norm * 0.88);
      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height - padBottom);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height - padBottom);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withValues(alpha: 0.42),
          AppColors.primaryAccent.withValues(alpha: 0.14),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, strokePaint);

    // Znaczniki podjazdów / premii na tablicy
    for (final marker in markers) {
      final double x = (marker.progress * size.width).clamp(16.0, size.width - 16.0);
      final double samplePos = marker.progress * (samples.length - 1);
      final int idx = samplePos.floor().clamp(0, samples.length - 1);
      final double norm = (samples[idx] - minEle) / eleRange;
      final double y = padTop + plotH * (1.0 - norm * 0.88);

      final pinPaint = Paint()
        ..color = marker.color.withValues(alpha: 0.75)
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(x, y), Offset(x, 12), pinPaint);
      canvas.drawCircle(Offset(x, y), 3.2, Paint()..color = marker.color);

      final tp = TextPainter(
        text: TextSpan(
          text: marker.label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: marker.color,
          ),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 110);

      final double labelX = (x - tp.width / 2).clamp(2.0, size.width - tp.width - 2);
      tp.paint(canvas, Offset(labelX, 0));
    }
  }

  @override
  bool shouldRepaint(covariant _BusStageProfileBoardPainter oldDelegate) {
    return oldDelegate.elevationSamplesM != elevationSamplesM ||
        oldDelegate.markers != markers ||
        oldDelegate.accentColor != accentColor;
  }
}

/// Rysuje kolarza siedzącego w fotelu autobusu ze słuchawkami na uszach i dynamiczną mimiką.
class _BusRiderSeatAvatarPainter extends CustomPainter {
  final int seed;
  final BusRiderFacialExpression expression;
  final double pulse;
  final Color teamPrimaryColor;
  final Color teamAccentColor;

  const _BusRiderSeatAvatarPainter({
    required this.seed,
    required this.expression,
    required this.pulse,
    required this.teamPrimaryColor,
    required this.teamAccentColor,
  });

  static const List<Color> _skinTones = [
    Color(0xFFEBC3A2),
    Color(0xFFDDAE88),
    Color(0xFFF2D0B6),
    Color(0xFFC68E63),
  ];

  static const List<Color> _hairColors = [
    Color(0xFF2B221C),
    Color(0xFF5A3E2B),
    Color(0xFF9C723C),
    Color(0xFF1D1E22),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // Zagłówek i oparcie fotela w autobusie
    final seatRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 4), width: 52, height: 64),
      const Radius.circular(14),
    );
    canvas.drawRRect(
      seatRect,
      Paint()..color = const Color(0xFF1E222B),
    );
    canvas.drawRRect(
      seatRect,
      Paint()
        ..color = teamAccentColor.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Ramiona i koszulka drużynowa
    final jerseyPath = Path()
      ..moveTo(cx - 22, size.height)
      ..quadraticBezierTo(cx - 18, cy + 12, cx, cy + 12)
      ..quadraticBezierTo(cx + 18, cy + 12, cx + 22, size.height)
      ..close();
    canvas.drawPath(jerseyPath, Paint()..color = teamPrimaryColor);

    // Pasek kołnierzyka
    canvas.drawLine(
      Offset(cx - 8, cy + 14),
      Offset(cx + 8, cy + 14),
      Paint()
        ..color = teamAccentColor
        ..strokeWidth = 2.0,
    );

    // Głowa kolarza
    final skin = _skinTones[seed % _skinTones.length];
    final hair = _hairColors[seed % _hairColors.length];
    final Offset headCenter = Offset(cx, cy - 5);
    canvas.drawCircle(headCenter, 15, Paint()..color = skin);

    // Włosy
    final hairPath = Path()
      ..addArc(
        Rect.fromCircle(center: headCenter, radius: 15.5),
        math.pi,
        math.pi,
      );
    canvas.drawPath(hairPath, Paint()..color = hair);

    // Słuchawki nauszne (pałąk + nauszniki z diodą LED)
    final headbandPaint = Paint()
      ..color = const Color(0xFF0E1014)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: headCenter, radius: 17.5),
      math.pi * 1.05,
      math.pi * 0.9,
      false,
      headbandPaint,
    );

    final earLeft = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 16, cy - 3), width: 6, height: 13),
      const Radius.circular(3),
    );
    final earRight = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + 16, cy - 3), width: 6, height: 13),
      const Radius.circular(3),
    );
    final earPaint = Paint()..color = const Color(0xFF151820);
    canvas.drawRRect(earLeft, earPaint);
    canvas.drawRRect(earRight, earPaint);

    final ledPaint = Paint()
      ..color = expression.badgeColor.withValues(alpha: 0.55 + 0.35 * pulse)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(earLeft, ledPaint);
    canvas.drawRRect(earRight, ledPaint);

    // Oczy i brwi wg mimiki
    final eyePaint = Paint()..color = const Color(0xFF1A1C22);
    final browPaint = Paint()
      ..color = hair
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx - 5, cy - 5), 1.5, eyePaint);
    canvas.drawCircle(Offset(cx + 5, cy - 5), 1.5, eyePaint);

    switch (expression) {
      case BusRiderFacialExpression.calmFocused:
        canvas.drawLine(Offset(cx - 8, cy - 9), Offset(cx - 2, cy - 9), browPaint);
        canvas.drawLine(Offset(cx + 2, cy - 9), Offset(cx + 8, cy - 9), browPaint);
        break;
      case BusRiderFacialExpression.firedUp:
      case BusRiderFacialExpression.determinedCaptain:
        canvas.drawLine(Offset(cx - 8, cy - 10), Offset(cx - 2, cy - 8), browPaint);
        canvas.drawLine(Offset(cx + 8, cy - 10), Offset(cx + 2, cy - 8), browPaint);
        break;
      case BusRiderFacialExpression.relievedSmiling:
        canvas.drawLine(Offset(cx - 8, cy - 9.5), Offset(cx - 2, cy - 10.5), browPaint);
        canvas.drawLine(Offset(cx + 2, cy - 10.5), Offset(cx + 8, cy - 9.5), browPaint);
        break;
      case BusRiderFacialExpression.tenseNervous:
        canvas.drawLine(Offset(cx - 8, cy - 8), Offset(cx - 2, cy - 10), browPaint);
        canvas.drawLine(Offset(cx + 2, cy - 10), Offset(cx + 8, cy - 8), browPaint);
        break;
    }

    // Usta wg mimiki
    final mouthPaint = Paint()
      ..color = const Color(0xFF3A241E)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path();
    switch (expression) {
      case BusRiderFacialExpression.calmFocused:
        mouthPath.moveTo(cx - 4, cy + 2);
        mouthPath.quadraticBezierTo(cx, cy + 3.2, cx + 4, cy + 2);
        break;
      case BusRiderFacialExpression.firedUp:
      case BusRiderFacialExpression.relievedSmiling:
        mouthPath.moveTo(cx - 5, cy + 1);
        mouthPath.quadraticBezierTo(cx, cy + 5.5, cx + 5, cy + 1);
        break;
      case BusRiderFacialExpression.determinedCaptain:
        mouthPath.moveTo(cx - 4.5, cy + 2.5);
        mouthPath.lineTo(cx + 4.5, cy + 2.5);
        break;
      case BusRiderFacialExpression.tenseNervous:
        mouthPath.moveTo(cx - 4.5, cy + 3);
        mouthPath.quadraticBezierTo(cx, cy + 1.0, cx + 4.5, cy + 3);
        break;
    }
    canvas.drawPath(mouthPath, mouthPaint);
  }

  @override
  bool shouldRepaint(covariant _BusRiderSeatAvatarPainter oldDelegate) {
    return oldDelegate.seed != seed ||
        oldDelegate.expression != expression ||
        oldDelegate.pulse != pulse ||
        oldDelegate.teamPrimaryColor != teamPrimaryColor ||
        oldDelegate.teamAccentColor != teamAccentColor;
  }
}
