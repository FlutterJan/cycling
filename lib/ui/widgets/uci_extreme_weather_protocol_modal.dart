import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/events/race_protest_and_course_reroute_engine.dart';
import '../../models/race/stage_segment.dart';

/// Zakładka nawigacji wewnątrz modalu oficjalnego komunikatu UCI.
enum UciProtocolModalTab {
  overview,
  routeComparison,
  cpaAndRules;

  String get labelPl {
    switch (this) {
      case UciProtocolModalTab.overview:
        return 'Komunikat';
      case UciProtocolModalTab.routeComparison:
        return 'Trasa i Profil';
      case UciProtocolModalTab.cpaAndRules:
        return 'CPA i Przepisy';
    }
  }
}

/// Rodzaj akcji zwróconej po zamknięciu modalu Protokołu Ekstremalnej Pogody UCI.
enum UciExtremeWeatherModalAction {
  acknowledged,
  rerouteConfirmed,
  voteSubmitted,
  dismissed,
}

/// Wynik interakcji użytkownika w modalu komunikatu UCI.
class UciExtremeWeatherModalResult {
  final UciExtremeWeatherModalAction action;
  final RiderProtestStance? selectedStance;
  final CourseRerouteAction appliedRerouteAction;
  final bool copiedToClipboard;

  const UciExtremeWeatherModalResult({
    required this.action,
    required this.appliedRerouteAction,
    this.selectedStance,
    this.copiedToClipboard = false,
  });
}

/// Kompletny model danych oficjalnego komunikatu UCI (Art. 2.2.029bis) o skróceniu
/// lub modyfikacji etapu z powodu śnieżycy, osuwiska lub innych ekstremalnych zjawisk.
class UciExtremeWeatherCommuniqueData {
  final String communiqueNumber;
  final String issuedAtLabel;
  final String commissairePresident;
  final String raceDirector;
  final String stageName;
  final double currentRaceKm;
  final UciProtocolEvaluationResult evaluation;
  final ReroutedStageResult? rerouteResult;
  final ExtremeWeatherTelemetryInput? telemetry;
  final PelotonProtestConsensus? protestConsensus;
  final RiderProtestStance? managerVoteStance;
  final bool isDecisionLocked;

  const UciExtremeWeatherCommuniqueData({
    required this.communiqueNumber,
    required this.issuedAtLabel,
    required this.commissairePresident,
    required this.raceDirector,
    required this.stageName,
    required this.currentRaceKm,
    required this.evaluation,
    this.rerouteResult,
    this.telemetry,
    this.protestConsensus,
    this.managerVoteStance,
    this.isDecisionLocked = false,
  });

  /// Buduje dane modalu bezpośrednio z wyników silnika `RaceProtestAndCourseRerouteEngine`.
  factory UciExtremeWeatherCommuniqueData.fromEngineResults({
    required UciProtocolEvaluationResult evaluation,
    ReroutedStageResult? rerouteResult,
    ExtremeWeatherTelemetryInput? telemetry,
    PelotonProtestConsensus? protestConsensus,
    RiderProtestStance? managerVoteStance,
    String communiqueNumber = 'UCI-EW-2026/04',
    String issuedAtLabel = '14:18 CET',
    String commissairePresident = 'Jean-Luc Mercier (UCI)',
    String raceDirector = 'Thierry Gouvenou',
    bool isDecisionLocked = false,
  }) {
    final stageName = rerouteResult?.originalStage.name ??
        telemetry?.stage.name ??
        'Etap Górski WorldTour';
    final currentKm = telemetry?.currentRaceKm ?? 0.0;

    return UciExtremeWeatherCommuniqueData(
      communiqueNumber: communiqueNumber,
      issuedAtLabel: issuedAtLabel,
      commissairePresident: commissairePresident,
      raceDirector: raceDirector,
      stageName: stageName,
      currentRaceKm: currentKm,
      evaluation: evaluation,
      rerouteResult: rerouteResult,
      telemetry: telemetry,
      protestConsensus: protestConsensus,
      managerVoteStance: managerVoteStance,
      isDecisionLocked: isDecisionLocked,
    );
  }

  UciExtremeWeatherCommuniqueData copyWith({
    String? communiqueNumber,
    String? issuedAtLabel,
    String? commissairePresident,
    String? raceDirector,
    String? stageName,
    double? currentRaceKm,
    UciProtocolEvaluationResult? evaluation,
    ReroutedStageResult? rerouteResult,
    ExtremeWeatherTelemetryInput? telemetry,
    PelotonProtestConsensus? protestConsensus,
    RiderProtestStance? managerVoteStance,
    bool? isDecisionLocked,
  }) {
    return UciExtremeWeatherCommuniqueData(
      communiqueNumber: communiqueNumber ?? this.communiqueNumber,
      issuedAtLabel: issuedAtLabel ?? this.issuedAtLabel,
      commissairePresident: commissairePresident ?? this.commissairePresident,
      raceDirector: raceDirector ?? this.raceDirector,
      stageName: stageName ?? this.stageName,
      currentRaceKm: currentRaceKm ?? this.currentRaceKm,
      evaluation: evaluation ?? this.evaluation,
      rerouteResult: rerouteResult ?? this.rerouteResult,
      telemetry: telemetry ?? this.telemetry,
      protestConsensus: protestConsensus ?? this.protestConsensus,
      managerVoteStance: managerVoteStance ?? this.managerVoteStance,
      isDecisionLocked: isDecisionLocked ?? this.isDecisionLocked,
    );
  }

  Map<String, dynamic> toJson() => {
        'communiqueNumber': communiqueNumber,
        'issuedAtLabel': issuedAtLabel,
        'commissairePresident': commissairePresident,
        'raceDirector': raceDirector,
        'stageName': stageName,
        'currentRaceKm': currentRaceKm,
        'evaluation': evaluation.toJson(),
        'managerVoteStance': managerVoteStance?.toJson(),
        'isDecisionLocked': isDecisionLocked,
      };

  factory UciExtremeWeatherCommuniqueData.fromJson(Map<String, dynamic> json) {
    return UciExtremeWeatherCommuniqueData(
      communiqueNumber:
          json['communiqueNumber'] as String? ?? 'UCI-EW-2026/00',
      issuedAtLabel: json['issuedAtLabel'] as String? ?? '12:00 CET',
      commissairePresident:
          json['commissairePresident'] as String? ?? 'Kolegium Sędziów UCI',
      raceDirector: json['raceDirector'] as String? ?? 'Dyrektor Wyścigu',
      stageName: json['stageName'] as String? ?? 'Etap',
      currentRaceKm: (json['currentRaceKm'] as num?)?.toDouble() ?? 0.0,
      evaluation: UciProtocolEvaluationResult.fromJson(
        Map<String, dynamic>.from(json['evaluation'] as Map? ?? const {}),
      ),
      managerVoteStance: json['managerVoteStance'] != null
          ? RiderProtestStance.fromJson(json['managerVoteStance'] as String)
          : null,
      isDecisionLocked: json['isDecisionLocked'] as bool? ?? false,
    );
  }

  /// Generuje sformatowany tekst oficjalnego komunikatu do skopiowania w schowku.
  String formatOfficialBulletinText() {
    final action = rerouteResult?.appliedAction ?? evaluation.recommendedAction;
    final buffer = StringBuffer()
      ..writeln('=== OFICJALNY KOMUNIKAT UCI ($communiqueNumber) ===')
      ..writeln('Podstawa prawna: Art. 2.2.029bis (Extreme Weather Protocol)')
      ..writeln('Etap: $stageName | Godzina: $issuedAtLabel')
      ..writeln('Alarm: ${evaluation.triggerLevel.labelPl}')
      ..writeln('Zagrożenie: ${evaluation.hazardType.labelPl}')
      ..writeln('Decyzja: ${action.labelPl}')
      ..writeln('Nagłówek: ${evaluation.communiqueHeadline}')
      ..writeln('Szczegóły: ${evaluation.communiqueDetails}');

    if (rerouteResult != null) {
      buffer
        ..writeln(
          'Dystans: ${rerouteResult!.originalDistanceKm.toStringAsFixed(1)} km '
          '-> ${rerouteResult!.newDistanceKm.toStringAsFixed(1)} km '
          '(${rerouteResult!.distanceDeltaKm.toStringAsFixed(1)} km)',
        )
        ..writeln(
          'Maks. wysokość: ${rerouteResult!.originalMaxElevationM.toStringAsFixed(0)} m '
          '-> ${rerouteResult!.newMaxElevationM.toStringAsFixed(0)} m',
        )
        ..writeln('Zasady GC: ${rerouteResult!.gcTimePolicyNote}');
    }

    buffer.writeln('Podpis: $commissairePresident / $raceDirector');
    return buffer.toString();
  }
}

/// Wyświetla modal oficjalnego komunikatu UCI o skróceniu lub modyfikacji etapu.
Future<UciExtremeWeatherModalResult?> showUciExtremeWeatherProtocolModal({
  required BuildContext context,
  required UciExtremeWeatherCommuniqueData data,
  ValueChanged<RiderProtestStance>? onSubmitVote,
  ValueChanged<CourseRerouteAction>? onConfirmReroute,
  bool isReadOnly = false,
}) {
  return showDialog<UciExtremeWeatherModalResult>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        child: UciExtremeWeatherProtocolModal(
          data: data,
          onSubmitVote: onSubmitVote,
          onConfirmReroute: onConfirmReroute,
          isReadOnly: isReadOnly,
        ),
      );
    },
  );
}

/// Modal oficjalnego komunikatu UCI (Art. 2.2.029bis) o skróceniu etapu z powodu
/// śnieżycy, osuwiska lub innego ekstremalnego zagrożenia pogodowego.
class UciExtremeWeatherProtocolModal extends StatefulWidget {
  final UciExtremeWeatherCommuniqueData data;
  final ValueChanged<RiderProtestStance>? onSubmitVote;
  final ValueChanged<CourseRerouteAction>? onConfirmReroute;
  final VoidCallback? onClose;
  final bool isReadOnly;

  const UciExtremeWeatherProtocolModal({
    super.key,
    required this.data,
    this.onSubmitVote,
    this.onConfirmReroute,
    this.onClose,
    this.isReadOnly = false,
  });

  @override
  State<UciExtremeWeatherProtocolModal> createState() =>
      _UciExtremeWeatherProtocolModalState();
}

class _UciExtremeWeatherProtocolModalState
    extends State<UciExtremeWeatherProtocolModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  UciProtocolModalTab _activeTab = UciProtocolModalTab.overview;
  RiderProtestStance? _selectedStance;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _selectedStance = widget.data.managerVoteStance;
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );
    _entranceController.forward();
  }

  @override
  void didUpdateWidget(covariant UciExtremeWeatherProtocolModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.managerVoteStance != widget.data.managerVoteStance) {
      _selectedStance = widget.data.managerVoteStance;
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  CourseRerouteAction get _effectiveAction =>
      widget.data.rerouteResult?.appliedAction ??
      widget.data.evaluation.recommendedAction;

  Color get _levelColor => widget.data.evaluation.triggerLevel.badgeColor;

  void _closeWith(UciExtremeWeatherModalResult result) {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(result);
    }
  }

  Future<void> _copyBulletin() async {
    final text = widget.data.formatOfficialBulletinText();
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final eval = widget.data.evaluation;
    final reroute = widget.data.rerouteResult;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : 1024.0;
            final maxH = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : 768.0;
            final isCompact = maxW < 640;
            final isWide = maxW >= 960;
            final modalWidth = math.min(maxW, isWide ? 1040.0 : 840.0);
            final modalMaxHeight = math.min(maxH, isCompact ? maxH : 820.0);

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: modalWidth,
                  maxHeight: modalMaxHeight,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _levelColor.withValues(alpha: 0.65),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTopOfficialBanner(eval, isCompact),
                        _buildTabBar(isCompact),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(isCompact ? 12 : 20),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 240),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeOutCubic,
                              child: _buildActiveTabContent(
                                eval: eval,
                                reroute: reroute,
                                isCompact: isCompact,
                                isWide: isWide,
                              ),
                            ),
                          ),
                        ),
                        _buildFooterActions(isCompact),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopOfficialBanner(
    UciProtocolEvaluationResult eval,
    bool isCompact,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 20,
        vertical: isCompact ? 12 : 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _levelColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _levelColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Icon(
                      eval.hazardType.icon,
                      color: _levelColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OFICJALNY KOMUNIKAT UCI • ART. 2.2.029bis',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: isCompact ? 10 : 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.goldAccent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.data.communiqueNumber} • ${widget.data.stageName}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: isCompact ? 13 : 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: _buildStatusPill(
                      label: eval.triggerLevel.labelPl,
                      color: _levelColor,
                      isCompact: isCompact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _InteractiveIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Zamknij komunikat',
                    onTap: () => _closeWith(
                      UciExtremeWeatherModalResult(
                        action: UciExtremeWeatherModalAction.dismissed,
                        appliedRerouteAction: _effectiveAction,
                        selectedStance: _selectedStance,
                        copiedToClipboard: _copied,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _buildMetaTag(
                Icons.schedule_rounded,
                'Wydano: ${widget.data.issuedAtLabel}',
              ),
              _buildMetaTag(
                Icons.route_rounded,
                'Kilometr wyścigu: ${widget.data.currentRaceKm.toStringAsFixed(1)} km',
              ),
              _buildMetaTag(
                Icons.gavel_rounded,
                'Przewodniczący Jury: ${widget.data.commissairePresident}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill({
    required String label,
    required Color color,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: isCompact ? 10 : 11,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaTag(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(bool isCompact) {
    return Container(
      color: AppColors.surface.withValues(alpha: 0.65),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 20,
        vertical: 8,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: UciProtocolModalTab.values.map((tab) {
            final selected = tab == _activeTab;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _InteractivePillButton(
                label: tab.labelPl,
                selected: selected,
                accentColor: AppColors.goldAccent,
                onTap: () => setState(() => _activeTab = tab),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent({
    required UciProtocolEvaluationResult eval,
    required ReroutedStageResult? reroute,
    required bool isCompact,
    required bool isWide,
  }) {
    switch (_activeTab) {
      case UciProtocolModalTab.overview:
        return Column(
          key: const ValueKey('tab_overview'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeadlineBulletinCard(eval, isCompact),
            const SizedBox(height: 14),
            if (widget.data.telemetry != null) ...[
              _buildTelemetryGrid(widget.data.telemetry!, isCompact),
              const SizedBox(height: 14),
            ],
            if (reroute != null) ...[
              _buildRouteDeltaCards(reroute, isCompact, isWide),
              const SizedBox(height: 14),
              _buildGcPolicyAndKomCard(reroute, isCompact),
            ] else
              _buildPendingRerouteNotice(eval, isCompact),
          ],
        );
      case UciProtocolModalTab.routeComparison:
        return Column(
          key: const ValueKey('tab_route_comparison'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (reroute != null) ...[
              _buildRouteDeltaCards(reroute, isCompact, isWide),
              const SizedBox(height: 14),
              _buildElevationComparisonCard(reroute, isCompact),
              const SizedBox(height: 14),
              _buildGcPolicyAndKomCard(reroute, isCompact),
            ] else
              _buildEmptyRouteCard(isCompact),
          ],
        );
      case UciProtocolModalTab.cpaAndRules:
        return Column(
          key: const ValueKey('tab_cpa_rules'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTriggeredRulesCard(eval, isCompact),
            const SizedBox(height: 14),
            _buildCpaConsensusAndVoteCard(eval, isCompact),
          ],
        );
    }
  }

  Widget _buildHeadlineBulletinCard(
    UciProtocolEvaluationResult eval,
    bool isCompact,
  ) {
    final headline = eval.communiqueHeadline.isNotEmpty
        ? eval.communiqueHeadline
        : '${eval.hazardType.labelPl} — ${_effectiveAction.labelPl}';
    final details = eval.communiqueDetails.isNotEmpty
        ? eval.communiqueDetails
        : _effectiveAction.descriptionPl;

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _levelColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  headline,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isCompact ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Text(
                  'Ryzyko ${eval.severityScore.toStringAsFixed(0)}/100',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _levelColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            details,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.45,
              letterSpacing: -0.2,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.alt_route_rounded,
                  size: 16,
                  color: AppColors.goldAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Decyzja Kolegium: ${_effectiveAction.labelPl}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryGrid(
    ExtremeWeatherTelemetryInput telemetry,
    bool isCompact,
  ) {
    final items = <({String label, String value, Color color, IconData icon})>[
      (
        label: 'Temp. szczyt',
        value: '${telemetry.summitTemperatureCelsius.toStringAsFixed(1)}°C',
        color: telemetry.summitTemperatureCelsius <= 1.0
            ? AppColors.accentBlue
            : AppColors.textPrimary,
        icon: Icons.ac_unit_rounded,
      ),
      (
        label: 'Temp. dolina',
        value: '${telemetry.airTemperatureCelsius.toStringAsFixed(1)}°C',
        color: telemetry.airTemperatureCelsius >= 38.0
            ? AppColors.crimsonAlert
            : AppColors.textPrimary,
        icon: Icons.thermostat_rounded,
      ),
      (
        label: 'Porywy wiatru',
        value: '${telemetry.windGustKmh.toStringAsFixed(0)} km/h',
        color: telemetry.windGustKmh >= 60.0
            ? AppColors.amberWarning
            : AppColors.textPrimary,
        icon: Icons.air_rounded,
      ),
      (
        label: 'Opad / Widoczność',
        value:
            '${telemetry.precipitationMmPerHour.toStringAsFixed(1)} mm/h • ${telemetry.visibilityMeters.toStringAsFixed(0)} m',
        color: telemetry.visibilityMeters < 150
            ? AppColors.amberWarning
            : AppColors.textPrimary,
        icon: Icons.visibility_rounded,
      ),
      if (telemetry.hasLandslideReport)
        (
          label: 'Osuwisko',
          value: telemetry.landslideKm != null
              ? 'km ${telemetry.landslideKm!.toStringAsFixed(1)} (ZABLOKOWANE)'
              : 'ZGŁOSZONE NA TRASIE',
          color: AppColors.crimsonAlert,
          icon: Icons.landslide_rounded,
        ),
      if (telemetry.iceOnRoadSurface)
        (
          label: 'Nawierzchnia',
          value: 'Oblodzenie jezdni',
          color: AppColors.accentBlue,
          icon: Icons.warning_amber_rounded,
        ),
    ];

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TELEMETRIA POGODOWA I DROGOWA',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items.map((item) {
              return Container(
                width: isCompact ? double.infinity : 220,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(item.icon, size: 16, color: item.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            item.value,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: item.color,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteDeltaCards(
    ReroutedStageResult reroute,
    bool isCompact,
    bool isWide,
  ) {
    final deltaDist = reroute.distanceDeltaKm;
    final deltaAlt = reroute.newMaxElevationM - reroute.originalMaxElevationM;

    final originalCard = _buildRouteSummaryBox(
      title: 'TRASA PIERWOTNA',
      distanceLabel: '${reroute.originalDistanceKm.toStringAsFixed(1)} km',
      maxAltLabel: '${reroute.originalMaxElevationM.toStringAsFixed(0)} m n.p.m.',
      segmentsCount: reroute.originalStage.segments.length,
      borderColor: AppTheme.borderColor,
      accentColor: AppColors.textSecondary,
    );

    final newCard = _buildRouteSummaryBox(
      title: reroute.isStageCancelled
          ? 'ETAP ODWOŁANY'
          : 'NOWA TRASA (ZMODYFIKOWANA)',
      distanceLabel: reroute.isStageCancelled
          ? '0.0 km (Stop)'
          : '${reroute.newDistanceKm.toStringAsFixed(1)} km (${deltaDist >= 0 ? '+' : ''}${deltaDist.toStringAsFixed(1)} km)',
      maxAltLabel:
          '${reroute.newMaxElevationM.toStringAsFixed(0)} m n.p.m. (${deltaAlt >= 0 ? '+' : ''}${deltaAlt.toStringAsFixed(0)} m)',
      segmentsCount: reroute.reroutedStage.segments.length,
      borderColor: _levelColor.withValues(alpha: 0.6),
      accentColor: AppColors.goldAccent,
    );

    if (isCompact) {
      return Column(
        children: [
          originalCard,
          const SizedBox(height: 10),
          newCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: originalCard),
        const SizedBox(width: 12),
        Expanded(child: newCard),
      ],
    );
  }

  Widget _buildRouteSummaryBox({
    required String title,
    required String distanceLabel,
    required String maxAltLabel,
    required int segmentsCount,
    required Color borderColor,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            distanceLabel,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Maks. wysokość: $maxAltLabel • $segmentsCount odcinków',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElevationComparisonCard(
    ReroutedStageResult reroute,
    bool isCompact,
  ) {
    final hasSegments = reroute.originalStage.segments.isNotEmpty;
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            children: [
              const Text(
                'PORÓWNANIE PROFILU WYSOKOŚCIOWEGO',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary,
                ),
              ),
              Wrap(
                spacing: 12,
                children: [
                  _buildLegendDot('Pierwotna trasa', AppColors.crimsonAlert),
                  _buildLegendDot('Nowa trasa UCI', AppColors.goldAccent),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasSegments)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Brak segmentów wysokościowych do wyświetlenia.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: isCompact ? 150 : 190,
              width: double.infinity,
              child: CustomPaint(
                painter: UciReroutedElevationProfilePainter(
                  originalSegments: reroute.originalStage.segments,
                  reroutedSegments: reroute.reroutedStage.segments,
                  isStageCancelled: reroute.isStageCancelled,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildGcPolicyAndKomCard(
    ReroutedStageResult reroute,
    bool isCompact,
  ) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ZASADY KLASYFIKACJI GC I PREMIE GÓRSKIE',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reroute.gcTimePolicyNote,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (reroute.cancelledKomPrimes.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Anulowane premie górskie KOM:',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: reroute.cancelledKomPrimes.map((kom) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.crimsonAlert.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.crimsonAlert.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    kom,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.crimsonAlert,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (reroute.neutralizedSegmentIndices.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Zneutralizowane odcinki: ${reroute.neutralizedSegmentIndices.map((i) => '#${i + 1}').join(', ')}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.amberWarning,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingRerouteNotice(
    UciProtocolEvaluationResult eval,
    bool isCompact,
  ) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.accentBlue,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Kolegium Sędziów rekomenduje akcję: ${eval.recommendedAction.labelPl}. '
              'Po zatwierdzeniu zostanie wygenerowana zmodyfikowana trasa etapu.',
              style: const TextStyle(
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

  Widget _buildEmptyRouteCard(bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: const Center(
        child: Text(
          'Zmiana trasy nie została jeszcze wygenerowana dla tego komunikatu.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTriggeredRulesCard(
    UciProtocolEvaluationResult eval,
    bool isCompact,
  ) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'URUCHOMIONE KRYTERIA PROTOKOŁU UCI',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          if (eval.triggeredRules.isEmpty)
            const Text(
              'Brak przekroczonych progów bezpieczeństwa na trasie.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          else
            ...eval.triggeredRules.map((rule) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: _levelColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        rule,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCpaConsensusAndVoteCard(
    UciProtocolEvaluationResult eval,
    bool isCompact,
  ) {
    final consensus = widget.data.protestConsensus;
    final pressure = (consensus?.protestPressure ?? eval.protestPressure)
        .clamp(0.0, 1.0);
    final stance = consensus?.consensusStance ?? eval.pelotonStance;
    final canVote = !widget.isReadOnly && !widget.data.isDecisionLocked;

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'STANOWISKO PELETONU (CPA) I GŁOS DRUŻYNY',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                'Presja ${(pressure * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: pressure >= 0.6
                      ? AppColors.crimsonAlert
                      : AppColors.amberWarning,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pressure,
              minHeight: 8,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                pressure >= 0.65
                    ? AppColors.crimsonAlert
                    : AppColors.amberWarning,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Konsensus CPA: ${stance.labelPl}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: RiderProtestStance.values.map((option) {
              final isSelected = _selectedStance == option;
              return _InteractivePillButton(
                label: option.labelPl,
                selected: isSelected,
                disabled: !canVote,
                accentColor: AppColors.accentBlue,
                onTap: () {
                  setState(() => _selectedStance = option);
                  widget.onSubmitVote?.call(option);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions(bool isCompact) {
    final canConfirmReroute = !widget.isReadOnly &&
        !widget.data.isDecisionLocked &&
        widget.onConfirmReroute != null &&
        widget.data.evaluation.recommendedAction != CourseRerouteAction.none;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 20,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _InteractiveActionButton(
            label: _copied ? 'Skopiowano komunikat' : 'Kopiuj komunikat',
            icon: _copied ? Icons.check_rounded : Icons.content_copy_rounded,
            isPrimary: false,
            onTap: _copyBulletin,
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              if (canConfirmReroute)
                _InteractiveActionButton(
                  label: 'Zastosuj: ${widget.data.evaluation.recommendedAction.labelPl}',
                  icon: Icons.alt_route_rounded,
                  isPrimary: true,
                  accentColor: AppColors.primaryAccent,
                  onTap: () {
                    final action = widget.data.evaluation.recommendedAction;
                    widget.onConfirmReroute?.call(action);
                    _closeWith(
                      UciExtremeWeatherModalResult(
                        action: UciExtremeWeatherModalAction.rerouteConfirmed,
                        appliedRerouteAction: action,
                        selectedStance: _selectedStance,
                        copiedToClipboard: _copied,
                      ),
                    );
                  },
                ),
              _InteractiveActionButton(
                label: 'Potwierdź przyjęcie',
                icon: Icons.verified_rounded,
                isPrimary: !canConfirmReroute,
                accentColor: AppColors.goldAccent,
                onTap: () => _closeWith(
                  UciExtremeWeatherModalResult(
                    action: UciExtremeWeatherModalAction.acknowledged,
                    appliedRerouteAction: _effectiveAction,
                    selectedStance: _selectedStance,
                    copiedToClipboard: _copied,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rysuje porównawczy profil wysokościowy: pierwotna trasa vs nowa trasa UCI.
class UciReroutedElevationProfilePainter extends CustomPainter {
  final List<StageSegment> originalSegments;
  final List<StageSegment> reroutedSegments;
  final bool isStageCancelled;

  const UciReroutedElevationProfilePainter({
    required this.originalSegments,
    required this.reroutedSegments,
    required this.isStageCancelled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (originalSegments.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    const padL = 8.0;
    const padR = 8.0;
    const padT = 12.0;
    const padB = 14.0;
    final chartW = math.max(1.0, size.width - padL - padR);
    final chartH = math.max(1.0, size.height - padT - padB);

    final origTotalDist = math.max(
      1.0,
      originalSegments.fold<double>(0.0, (s, e) => s + e.lengthKm),
    );

    double minElev = double.infinity;
    double maxElev = -double.infinity;
    for (final seg in [...originalSegments, ...reroutedSegments]) {
      minElev = math.min(minElev, math.min(seg.startElevationM, seg.endElevationM));
      maxElev = math.max(maxElev, math.max(seg.startElevationM, seg.endElevationM));
    }
    if (!minElev.isFinite || !maxElev.isFinite) {
      minElev = 0;
      maxElev = 1000;
    }
    final elevSpan = math.max(100.0, maxElev - minElev);

    // Siatka pozioma
    final gridPaint = Paint()
      ..color = AppTheme.borderColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.0;
    for (int i = 0; i <= 3; i++) {
      final y = padT + (chartH * i / 3.0);
      canvas.drawLine(Offset(padL, y), Offset(padL + chartW, y), gridPaint);
    }

    Offset toPoint(double km, double elev) {
      final x = padL + (km / origTotalDist).clamp(0.0, 1.0) * chartW;
      final y = padT + (1.0 - ((elev - minElev) / elevSpan).clamp(0.0, 1.0)) * chartH;
      return Offset(x, y);
    }

    // Pierwotna trasa (czerwony kontur + półprzezroczyste wypełnienie)
    final origPath = Path();
    final origFill = Path();
    double kmAcc = 0.0;
    final firstOrig = toPoint(0.0, originalSegments.first.startElevationM);
    origPath.moveTo(firstOrig.dx, firstOrig.dy);
    origFill.moveTo(firstOrig.dx, padT + chartH);
    origFill.lineTo(firstOrig.dx, firstOrig.dy);

    for (final seg in originalSegments) {
      kmAcc += seg.lengthKm;
      final pt = toPoint(kmAcc, seg.endElevationM);
      origPath.lineTo(pt.dx, pt.dy);
      origFill.lineTo(pt.dx, pt.dy);
    }
    origFill.lineTo(padL + chartW, padT + chartH);
    origFill.close();

    canvas.drawPath(
      origFill,
      Paint()..color = AppColors.crimsonAlert.withValues(alpha: 0.12),
    );
    canvas.drawPath(
      origPath,
      Paint()
        ..color = AppColors.crimsonAlert.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // Nowa trasa (złoty profil)
    if (!isStageCancelled && reroutedSegments.isNotEmpty) {
      final newPath = Path();
      final newFill = Path();
      double newKmAcc = 0.0;
      final firstNew = toPoint(0.0, reroutedSegments.first.startElevationM);
      newPath.moveTo(firstNew.dx, firstNew.dy);
      newFill.moveTo(firstNew.dx, padT + chartH);
      newFill.lineTo(firstNew.dx, firstNew.dy);

      late Offset lastNewPt;
      for (final seg in reroutedSegments) {
        newKmAcc += seg.lengthKm;
        lastNewPt = toPoint(newKmAcc, seg.endElevationM);
        newPath.lineTo(lastNewPt.dx, lastNewPt.dy);
        newFill.lineTo(lastNewPt.dx, lastNewPt.dy);
      }
      newFill.lineTo(lastNewPt.dx, padT + chartH);
      newFill.close();

      canvas.drawPath(
        newFill,
        Paint()..color = AppColors.goldAccent.withValues(alpha: 0.22),
      );
      canvas.drawPath(
        newPath,
        Paint()
          ..color = AppColors.goldAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );

      // Znacznik nowej mety
      canvas.drawCircle(
        lastNewPt,
        4.5,
        Paint()..color = AppColors.goldAccent,
      );
    }
  }

  @override
  bool shouldRepaint(covariant UciReroutedElevationProfilePainter oldDelegate) {
    return oldDelegate.originalSegments != originalSegments ||
        oldDelegate.reroutedSegments != reroutedSegments ||
        oldDelegate.isStageCancelled != isStageCancelled;
  }
}

class _InteractivePillButton extends StatefulWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _InteractivePillButton({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
    this.disabled = false,
  });

  @override
  State<_InteractivePillButton> createState() => _InteractivePillButtonState();
}

class _InteractivePillButtonState extends State<_InteractivePillButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.selected
            ? widget.accentColor.withValues(alpha: 0.22)
            : _pressed
                ? AppColors.surfaceLight
                : _hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.85)
                    : AppColors.surface;
    final borderColor = widget.disabled
        ? AppTheme.borderColor.withValues(alpha: 0.5)
        : widget.selected || _focused
            ? widget.accentColor
            : _hovered
                ? widget.accentColor.withValues(alpha: 0.55)
                : AppTheme.borderColor;
    final textColor = widget.disabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : widget.selected
            ? widget.accentColor
            : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: !widget.disabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: widget.disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.disabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: -0.2,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final Color accentColor;
  final VoidCallback? onTap;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    this.accentColor = AppColors.goldAccent,
    this.onTap,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    final bgColor = disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.isPrimary
            ? (_pressed
                ? widget.accentColor.withValues(alpha: 0.78)
                : _hovered
                    ? widget.accentColor.withValues(alpha: 0.92)
                    : widget.accentColor)
            : (_pressed || _hovered
                ? AppColors.surfaceLight
                : AppColors.background);

    final fgColor = disabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : widget.isPrimary
            ? (widget.accentColor == AppColors.goldAccent
                ? Colors.black
                : Colors.white)
            : AppColors.textPrimary;

    final borderColor = disabled
        ? AppTheme.borderColor.withValues(alpha: 0.5)
        : _focused
            ? AppColors.goldAccent
            : widget.isPrimary
                ? widget.accentColor
                : AppTheme.borderColor;

    return FocusableActionDetector(
      enabled: !disabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: fgColor),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
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

class _InteractiveIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _InteractiveIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
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
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.surfaceLight : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused ? AppColors.goldAccent : AppTheme.borderColor,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
