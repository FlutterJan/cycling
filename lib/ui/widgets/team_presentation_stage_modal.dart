// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/equipment/complete_bike.dart';
import '../../models/rider/rider_appearance.dart';
import '../../services/career/pre_season_team_presentation_event.dart';
import 'bike_preview_painter.dart';
import 'rider_avatar_painter.dart';

/// Wpis lidera drużyny prezentowanego na scenie obok nowego roweru.
class StageLeaderPresentationEntry {
  final String id;
  final String name;
  final String roleLabel;
  final String nationalityIso;
  final int overallRating;
  final String quote;
  final RiderAppearance? appearance;
  final bool isNewSigning;
  final Color accentColor;

  const StageLeaderPresentationEntry({
    required this.id,
    required this.name,
    required this.roleLabel,
    required this.nationalityIso,
    required this.overallRating,
    required this.quote,
    this.appearance,
    this.isNewSigning = false,
    this.accentColor = AppColors.goldAccent,
  });

  factory StageLeaderPresentationEntry.fromJson(Map<String, dynamic> json) {
    return StageLeaderPresentationEntry(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Nieznany Kolarz',
      roleLabel: (json['roleLabel'] as String?) ?? 'Lider',
      nationalityIso: (json['nationalityIso'] as String?) ?? 'POL',
      overallRating: (json['overallRating'] as num?)?.toInt() ?? 80,
      quote: (json['quote'] as String?) ?? '',
      isNewSigning: (json['isNewSigning'] as bool?) ?? false,
      accentColor: Color(
        (json['accentColorValue'] as num?)?.toInt() ??
            AppColors.goldAccent.toARGB32(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'roleLabel': roleLabel,
      'nationalityIso': nationalityIso,
      'overallRating': overallRating,
      'quote': quote,
      'isNewSigning': isNewSigning,
      'accentColorValue': accentColor.toARGB32(),
    };
  }
}

/// Wynik deklaracji celów zatwierdzony w modalu Prezentacji Zespołu.
class TeamPresentationStageResult {
  final SeasonMainObjectiveCategory selectedObjective;
  final SeasonObjectiveAmbitionLevel ambitionLevel;
  final String officialStatement;
  final double expectedSponsorBoost;
  final double expectedMediaHype;
  final int expectedMoraleDelta;
  final DateTime confirmedAt;

  const TeamPresentationStageResult({
    required this.selectedObjective,
    required this.ambitionLevel,
    required this.officialStatement,
    required this.expectedSponsorBoost,
    required this.expectedMediaHype,
    required this.expectedMoraleDelta,
    required this.confirmedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'selectedObjective': selectedObjective.toJson(),
      'ambitionLevel': ambitionLevel.toJson(),
      'officialStatement': officialStatement,
      'expectedSponsorBoost': expectedSponsorBoost,
      'expectedMediaHype': expectedMediaHype,
      'expectedMoraleDelta': expectedMoraleDelta,
      'confirmedAt': confirmedAt.toIso8601String(),
    };
  }
}

/// Dane wejściowe potrzebne do wyświetlenia widowiskowego modalu sceny gali.
class TeamPresentationStageData {
  final String teamName;
  final String teamTla;
  final int seasonYear;
  final String sponsorName;
  final String bikeModelName;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final CompleteBike? bike;
  final List<StageLeaderPresentationEntry> leaders;
  final SeasonMainObjectiveCategory initialObjective;
  final SeasonObjectiveAmbitionLevel initialAmbition;

  const TeamPresentationStageData({
    required this.teamName,
    required this.teamTla,
    required this.seasonYear,
    required this.sponsorName,
    required this.bikeModelName,
    this.primaryColor = AppColors.primaryAccent,
    this.secondaryColor = const Color(0xFF1F2937),
    this.accentColor = AppColors.goldAccent,
    this.bike,
    this.leaders = const [],
    this.initialObjective = SeasonMainObjectiveCategory.grandTourStageHunts,
    this.initialAmbition = SeasonObjectiveAmbitionLevel.ambitious,
  });

  factory TeamPresentationStageData.sample() {
    return const TeamPresentationStageData(
      teamName: 'Vistula Pro Cycling',
      teamTla: 'VPC',
      seasonYear: 2026,
      sponsorName: 'Orlen Aero Tech',
      bikeModelName: 'Romet Aero Carbon SL-9',
      primaryColor: AppColors.primaryAccent,
      secondaryColor: Color(0xFF1A1F2B),
      accentColor: AppColors.goldAccent,
      leaders: [
        StageLeaderPresentationEntry(
          id: 'leader_gc',
          name: 'Marek Kowalski',
          roleLabel: 'Lider GC',
          nationalityIso: 'POL',
          overallRating: 87,
          quote:
              'W lipcu chcemy walczyć z najlepszymi w wysokich Alpach i dać kibicom powód do dumy.',
          isNewSigning: false,
          accentColor: AppColors.goldAccent,
          appearance: RiderAppearance(
            faceShapeIndex: 1,
            skinToneHex: '#E8B89A',
            hairStyleIndex: 2,
            hairColorHex: '#3B2F2F',
            facialHairIndex: 1,
            glassesModelId: 'aero_pro',
            glassesLensColorHex: '#D4AF37',
            helmetModelId: 'aero_road',
            shoeColorHex: '#FFFFFF',
            sockHeightProportion: 0.42,
            bodyBuildType: BodyBuildType.climberLean,
          ),
        ),
        StageLeaderPresentationEntry(
          id: 'leader_sprint',
          name: 'Lukas Van Der Berg',
          roleLabel: 'Główny Sprinter',
          nationalityIso: 'BEL',
          overallRating: 86,
          quote:
              'Nowy rower ma niesamowitą sztywność węzła suportu — na finiszach będziemy nie do zatrzymania.',
          isNewSigning: true,
          accentColor: AppColors.statusSuccess,
          appearance: RiderAppearance(
            faceShapeIndex: 2,
            skinToneHex: '#F0C7AC',
            hairStyleIndex: 4,
            hairColorHex: '#B68A4C',
            facialHairIndex: 0,
            glassesModelId: 'shield_xl',
            glassesLensColorHex: '#38BDF8',
            helmetModelId: 'aero_sprint',
            shoeColorHex: '#F3F4F6',
            sockHeightProportion: 0.45,
            bodyBuildType: BodyBuildType.sprinterMuscular,
          ),
        ),
        StageLeaderPresentationEntry(
          id: 'leader_classics',
          name: 'Matej Novak',
          roleLabel: 'Lider Klasyków',
          nationalityIso: 'SLO',
          overallRating: 85,
          quote:
              'Wiosenne bruki we Flandrii i Paryż-Roubaix to nasz priorytet od pierwszego kilometra.',
          isNewSigning: true,
          accentColor: AppColors.accentBlue,
          appearance: RiderAppearance(
            faceShapeIndex: 0,
            skinToneHex: '#E5B293',
            hairStyleIndex: 1,
            hairColorHex: '#252020',
            facialHairIndex: 2,
            glassesModelId: 'classic_half',
            glassesLensColorHex: '#10B981',
            helmetModelId: 'vented_pro',
            shoeColorHex: '#111827',
            sockHeightProportion: 0.40,
            bodyBuildType: BodyBuildType.allRounder,
          ),
        ),
      ],
    );
  }
}

/// Pomocnicza funkcja otwierająca [TeamPresentationStageModal] jako okno dialogowe.
Future<TeamPresentationStageResult?> showTeamPresentationStageModal(
  BuildContext context, {
  required TeamPresentationStageData data,
  ValueChanged<TeamPresentationStageResult>? onConfirmObjective,
  bool isConfirmEnabled = true,
}) {
  return showDialog<TeamPresentationStageResult>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.82),
    builder: (dialogContext) => TeamPresentationStageModal(
      data: data,
      isConfirmEnabled: isConfirmEnabled,
      onConfirmObjective: onConfirmObjective,
      onClose: () => Navigator.of(dialogContext).maybePop(),
    ),
  );
}

/// Widowiskowy modal Prezentacji Zespołu przed sezonem:
/// scena z ruchomymi reflektorami, liderzy drużyny stojący obok nowego roweru,
/// błyski aparatów fotoreporterów oraz interaktywna deklaracja celów na sezon.
class TeamPresentationStageModal extends StatefulWidget {
  final TeamPresentationStageData data;
  final ValueChanged<TeamPresentationStageResult>? onConfirmObjective;
  final VoidCallback? onClose;
  final bool isConfirmEnabled;

  const TeamPresentationStageModal({
    super.key,
    required this.data,
    this.onConfirmObjective,
    this.onClose,
    this.isConfirmEnabled = true,
  });

  @override
  State<TeamPresentationStageModal> createState() =>
      _TeamPresentationStageModalState();
}

class _TeamPresentationStageModalState extends State<TeamPresentationStageModal>
    with TickerProviderStateMixin {
  late final AnimationController _stageController;
  late final AnimationController _flashBurstController;
  late final TextEditingController _statementController;

  late SeasonMainObjectiveCategory _selectedObjective;
  late SeasonObjectiveAmbitionLevel _selectedAmbition;
  int _selectedLeaderIndex = 0;
  int _flashBurstSeed = 1;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedObjective = widget.data.initialObjective;
    _selectedAmbition = widget.data.initialAmbition;

    _stageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6800),
    )..repeat();

    _flashBurstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _statementController = TextEditingController(
      text: _buildDefaultStatement(_selectedObjective, _selectedAmbition),
    );
  }

  @override
  void dispose() {
    _stageController.dispose();
    _flashBurstController.dispose();
    _statementController.dispose();
    super.dispose();
  }

  String _buildDefaultStatement(
    SeasonMainObjectiveCategory objective,
    SeasonObjectiveAmbitionLevel ambition,
  ) {
    final team = widget.data.teamName;
    final year = widget.data.seasonYear;
    switch (ambition) {
      case SeasonObjectiveAmbitionLevel.conservative:
        return 'W sezonie $year zespół $team stawia na konsekwentną realizację celu: ${objective.label}.';
      case SeasonObjectiveAmbitionLevel.ambitious:
        return '$team wchodzi w sezon $year z odważnym planem — naszym głównym priorytetem jest ${objective.label}!';
      case SeasonObjectiveAmbitionLevel.allInGlory:
        return 'Nie boimy się wielkich deklaracji: w $year $team jedzie po pełną pulę i celuje w ${objective.label}!';
    }
  }

  double get _expectedSponsorBoost => double.parse(
        (_selectedObjective.baseSponsorAppeal *
                _selectedAmbition.sponsorMultiplier)
            .toStringAsFixed(1),
      );

  double get _expectedMediaHype => double.parse(
        (_selectedObjective.baseMediaAppeal * _selectedAmbition.mediaMultiplier)
            .toStringAsFixed(1),
      );

  int get _expectedMoraleDelta => _selectedAmbition.moraleDelta;

  void _triggerCameraFlashes() {
    setState(() {
      _flashBurstSeed += 1;
    });
    _flashBurstController.forward(from: 0.0);
  }

  void _selectObjective(SeasonMainObjectiveCategory category) {
    if (_isSubmitting) return;
    setState(() {
      _selectedObjective = category;
      _statementController.text =
          _buildDefaultStatement(_selectedObjective, _selectedAmbition);
    });
  }

  void _selectAmbition(SeasonObjectiveAmbitionLevel ambition) {
    if (_isSubmitting) return;
    setState(() {
      _selectedAmbition = ambition;
      _statementController.text =
          _buildDefaultStatement(_selectedObjective, _selectedAmbition);
    });
  }

  void _handleConfirm() {
    if (!widget.isConfirmEnabled || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });
    _triggerCameraFlashes();

    final statement = _statementController.text.trim().isEmpty
        ? _buildDefaultStatement(_selectedObjective, _selectedAmbition)
        : _statementController.text.trim();

    final result = TeamPresentationStageResult(
      selectedObjective: _selectedObjective,
      ambitionLevel: _selectedAmbition,
      officialStatement: statement,
      expectedSponsorBoost: _expectedSponsorBoost,
      expectedMediaHype: _expectedMediaHype,
      expectedMoraleDelta: _expectedMoraleDelta,
      confirmedAt: DateTime.now(),
    );

    widget.onConfirmObjective?.call(result);
    if (mounted) {
      Navigator.of(context).maybePop(result);
    }
  }

  void _handleClose() {
    if (_isSubmitting) return;
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final bool isCompact = width < 640;
          final bool isDesktop = width >= 960;
          final double modalMaxWidth = isDesktop ? 1040 : width;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: modalMaxWidth,
                maxHeight: constraints.maxHeight,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.45),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.72),
                      blurRadius: 36,
                      offset: const Offset(0, 18),
                    ),
                    BoxShadow(
                      color: AppColors.goldAccent.withValues(alpha: 0.08),
                      blurRadius: 40,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isCompact ? 14 : 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeaderBar(isCompact),
                        const SizedBox(height: 14),
                        _buildPresentationStage(isCompact),
                        const SizedBox(height: 14),
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: _buildObjectiveDeclarationCard(isCompact),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 5,
                                child: _buildStatementAndImpactCard(isCompact),
                              ),
                            ],
                          )
                        else ...[
                          _buildObjectiveDeclarationCard(isCompact),
                          const SizedBox(height: 14),
                          _buildStatementAndImpactCard(isCompact),
                        ],
                        const SizedBox(height: 16),
                        _buildFooterActions(isCompact),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderBar(bool isCompact) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: isCompact ? 38 : 44,
          height: isCompact ? 38 : 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.data.primaryColor,
                AppColors.goldAccent.withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.goldAccent.withValues(alpha: 0.65),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.data.teamTla,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0.6,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
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
                    'GALA PREZENTACJI ZESPOŁU ${widget.data.seasonYear}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 11 : 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: AppColors.goldAccent,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Text(
                      'LIVE PRESS',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cyanAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.data.teamName} × ${widget.data.sponsorName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 16 : 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _StageInteractiveIconButton(
          tooltip: 'Wyzwól błyski aparatów',
          icon: Icons.camera_alt_rounded,
          accentColor: AppColors.goldAccent,
          onPressed: _triggerCameraFlashes,
        ),
        const SizedBox(width: 8),
        _StageInteractiveIconButton(
          tooltip: 'Zamknij prezentację',
          icon: Icons.close_rounded,
          accentColor: AppColors.textSecondary,
          onPressed: _handleClose,
        ),
      ],
    );
  }

  Widget _buildPresentationStage(bool isCompact) {
    final double stageHeight = isCompact ? 270 : 320;
    final leaders = widget.data.leaders.take(3).toList();
    final StageLeaderPresentationEntry? activeLeader =
        leaders.isNotEmpty && _selectedLeaderIndex < leaders.length
            ? leaders[_selectedLeaderIndex]
            : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _triggerCameraFlashes,
              child: SizedBox(
                height: stageHeight,
                width: double.infinity,
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _stageController,
                    _flashBurstController,
                  ]),
                  builder: (context, child) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _PresentationStagePainter(
                              stagePhase: _stageController.value,
                              burstProgress: _flashBurstController.isAnimating
                                  ? _flashBurstController.value
                                  : 0.0,
                              burstSeed: _flashBurstSeed,
                              primaryColor: widget.data.primaryColor,
                              accentColor: widget.data.accentColor,
                              teamTla: widget.data.teamTla,
                              seasonYear: widget.data.seasonYear,
                              sponsorName: widget.data.sponsorName,
                            ),
                          ),
                        ),
                        // Warstwa liderów i nowego roweru na podeście sceny
                        Positioned.fill(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              isCompact ? 10 : 20,
                              isCompact ? 34 : 40,
                              isCompact ? 10 : 20,
                              isCompact ? 18 : 22,
                            ),
                            child: _buildStageLineup(
                              leaders: leaders,
                              isCompact: isCompact,
                            ),
                          ),
                        ),
                        // Nakładka błysków fleszy ponad sceną
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _CameraFlashOverlayPainter(
                                stagePhase: _stageController.value,
                                burstProgress: _flashBurstController.isAnimating
                                    ? _flashBurstController.value
                                    : 0.0,
                                burstSeed: _flashBurstSeed,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            // Pasek wypowiedzi wybranego lidera pod sceną
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12 : 16,
                vertical: 10,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                border: Border(
                  top: BorderSide(color: AppColors.cardBorder, width: 1),
                ),
              ),
              child: activeLeader != null
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mic_rounded,
                          size: 16,
                          color: activeLeader.accentColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.5,
                                height: 1.35,
                                color: AppColors.textPrimary,
                              ),
                              children: [
                                TextSpan(
                                  text: '${activeLeader.name} (${activeLeader.roleLabel}): ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: activeLeader.accentColor,
                                  ),
                                ),
                                TextSpan(
                                  text: '„${activeLeader.quote}”',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        const Icon(
                          Icons.directions_bike_rounded,
                          size: 16,
                          color: AppColors.goldAccent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Oficjalna prezentacja maszyny ${widget.data.bikeModelName} na sezon ${widget.data.seasonYear}. Kliknij scenę, aby wyzwolić błyski aparatów.',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageLineup({
    required List<StageLeaderPresentationEntry> leaders,
    required bool isCompact,
  }) {
    final Widget bikeShowcase = _buildBikeShowcase(isCompact);

    if (leaders.isEmpty) {
      return Center(child: bikeShowcase);
    }

    if (isCompact) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            flex: 5,
            child: Center(child: bikeShowcase),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 92,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < leaders.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _buildLeaderStageTile(
                      leader: leaders[i],
                      index: i,
                      isCompact: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    final leftLeaders = <Widget>[];
    final rightLeaders = <Widget>[];

    for (int i = 0; i < leaders.length; i++) {
      final tile = _buildLeaderStageTile(
        leader: leaders[i],
        index: i,
        isCompact: false,
      );
      if (i.isEven) {
        leftLeaders.add(tile);
      } else {
        rightLeaders.add(tile);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 4,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = 0; i < leftLeaders.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Flexible(child: leftLeaders[i]),
              ],
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 5,
          child: bikeShowcase,
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 4,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = 0; i < rightLeaders.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Flexible(child: rightLeaders[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBikeShowcase(bool isCompact) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Center(
            child: widget.data.bike != null
                ? BikePreviewWidget(
                    bike: widget.data.bike!,
                    showBackground: false,
                    showFloorReflection: true,
                    frameColorOverride: widget.data.primaryColor,
                  )
                : CustomPaint(
                    size: Size(isCompact ? 220 : 280, isCompact ? 115 : 155),
                    painter: _StageBikeShowcasePainter(
                      frameColor: widget.data.primaryColor,
                      accentColor: widget.data.accentColor,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.goldAccent.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Text(
            widget.data.bikeModelName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 10.5 : 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.goldAccent,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderStageTile({
    required StageLeaderPresentationEntry leader,
    required int index,
    required bool isCompact,
  }) {
    final bool isSelected = _selectedLeaderIndex == index;
    return _InteractiveStageTile(
      isSelected: isSelected,
      accentColor: leader.accentColor,
      onTap: () {
        setState(() {
          _selectedLeaderIndex = index;
        });
        _triggerCameraFlashes();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 6 : 10,
          vertical: isCompact ? 6 : 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                if (leader.appearance != null)
                  RiderAvatarWidget(
                    appearance: leader.appearance!,
                    size: isCompact ? 38 : 54,
                    showHelmet: false,
                    showGlasses: false,
                    showBorder: true,
                    borderColor: isSelected
                        ? leader.accentColor
                        : AppColors.cardBorder,
                    borderWidth: isSelected ? 2.0 : 1.2,
                  )
                else
                  Container(
                    width: isCompact ? 38 : 54,
                    height: isCompact ? 38 : 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceLight,
                      border: Border.all(
                        color: isSelected
                            ? leader.accentColor
                            : AppColors.cardBorder,
                        width: isSelected ? 2 : 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.person_rounded,
                      size: isCompact ? 20 : 28,
                      color: leader.accentColor,
                    ),
                  ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: leader.accentColor, width: 1),
                    ),
                    child: Text(
                      '${leader.overallRating}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 4 : 7),
            Text(
              leader.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: isCompact ? 10.5 : 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              leader.isNewSigning
                  ? 'NOWY • ${leader.roleLabel}'
                  : leader.roleLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: isCompact ? 9 : 10,
                fontWeight: FontWeight.w600,
                color: leader.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObjectiveDeclarationCard(bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.flag_rounded,
                size: 18,
                color: AppColors.goldAccent,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Deklaracja Celów na Nadchodzący Sezon',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SeasonMainObjectiveCategory.values.map((category) {
              final bool selected = _selectedObjective == category;
              return _InteractiveSelectionChip(
                label: category.label,
                selected: selected,
                enabled: !_isSubmitting,
                accentColor: AppColors.goldAccent,
                onTap: () => _selectObjective(category),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
            child: Text(
              _selectedObjective.subtitle,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Poziom Ambicji Konferencji',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SeasonObjectiveAmbitionLevel.values.map((ambition) {
              final bool selected = _selectedAmbition == ambition;
              final Color badgeColor = switch (ambition) {
                SeasonObjectiveAmbitionLevel.conservative =>
                  AppColors.statusSuccess,
                SeasonObjectiveAmbitionLevel.ambitious => AppColors.accentBlue,
                SeasonObjectiveAmbitionLevel.allInGlory =>
                  AppColors.goldAccent,
              };
              return _InteractiveSelectionChip(
                label: ambition.label,
                selected: selected,
                enabled: !_isSubmitting,
                accentColor: badgeColor,
                onTap: () => _selectAmbition(ambition),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatementAndImpactCard(bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.campaign_rounded,
                size: 18,
                color: AppColors.cyanAccent,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Oficjalne Oświadczenie dla Mediów',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        setState(() {
                          _statementController.text = _buildDefaultStatement(
                            _selectedObjective,
                            _selectedAmbition,
                          );
                        });
                      },
                icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                label: const Text('Szablon'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accentBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _statementController,
            enabled: !_isSubmitting,
            maxLines: 3,
            minLines: 2,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceLight,
              hintText: 'Wpisz deklarację celów dla prasy i sponsorów...',
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
              contentPadding: const EdgeInsets.all(12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.goldAccent,
                  width: 1.5,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.cardBorder.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Prognozowany Odbiór Gali',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ImpactMetricBox(
                  label: 'Sponsor',
                  value: '+$_expectedSponsorBoost',
                  color: AppColors.statusSuccess,
                  icon: Icons.handshake_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ImpactMetricBox(
                  label: 'Media Hype',
                  value: '+$_expectedMediaHype',
                  color: AppColors.accentBlue,
                  icon: Icons.tv_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ImpactMetricBox(
                  label: 'Morale',
                  value: '+$_expectedMoraleDelta',
                  color: AppColors.goldAccent,
                  icon: Icons.bolt_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Presja oczekiwań:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              for (int i = 1; i <= 5; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Icon(
                    Icons.star_rounded,
                    size: 15,
                    color: i <= _selectedObjective.pressureLevel
                        ? AppColors.amberWarning
                        : AppColors.cardBorder,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions(bool isCompact) {
    final bool canConfirm = widget.isConfirmEnabled && !_isSubmitting;

    final Widget cancelButton = OutlinedButton(
      onPressed: _isSubmitting ? null : _handleClose,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        disabledForegroundColor: AppColors.textSecondary.withValues(alpha: 0.45),
        side: const BorderSide(color: AppColors.cardBorder),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        'Zamknij Galę',
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );

    final Widget confirmButton = ElevatedButton.icon(
      onPressed: canConfirm ? _handleConfirm : null,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.surfaceLight;
          }
          if (states.contains(WidgetState.hovered)) {
            return const Color(0xFFE0BE4E);
          }
          return AppColors.goldAccent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.textSecondary.withValues(alpha: 0.5);
          }
          return AppColors.background;
        }),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        elevation: WidgetStateProperty.all(0),
      ),
      icon: _isSubmitting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.background,
              ),
            )
          : const Icon(Icons.campaign_rounded, size: 18),
      label: Text(
        _isSubmitting ? 'Ogłaszanie...' : 'Ogłoś Cele Sezonu',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
        ),
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          confirmButton,
          const SizedBox(height: 8),
          cancelButton,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        cancelButton,
        const SizedBox(width: 12),
        confirmButton,
      ],
    );
  }
}

class _StageInteractiveIconButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onPressed;

  const _StageInteractiveIconButton({
    required this.tooltip,
    required this.icon,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_StageInteractiveIconButton> createState() =>
      _StageInteractiveIconButtonState();
}

class _StageInteractiveIconButtonState
    extends State<_StageInteractiveIconButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: Focus(
        onFocusChange: (val) => setState(() => _focused = val),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _hovered ? AppColors.surfaceLight : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _focused || _hovered
                      ? widget.accentColor
                      : AppColors.cardBorder,
                  width: _focused ? 1.5 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                widget.icon,
                size: 18,
                color: _hovered ? widget.accentColor : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveStageTile extends StatefulWidget {
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;
  final Widget child;

  const _InteractiveStageTile({
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
    required this.child,
  });

  @override
  State<_InteractiveStageTile> createState() => _InteractiveStageTileState();
}

class _InteractiveStageTileState extends State<_InteractiveStageTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.isSelected || _hovered || _focused;
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.surfaceLight.withValues(alpha: 0.94)
                  : AppColors.background.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active ? widget.accentColor : AppColors.cardBorder,
                width: widget.isSelected ? 1.5 : 1.0,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: widget.accentColor.withValues(alpha: 0.24),
                        blurRadius: 16,
                      ),
                    ]
                  : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _InteractiveSelectionChip extends StatefulWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _InteractiveSelectionChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_InteractiveSelectionChip> createState() =>
      _InteractiveSelectionChipState();
}

class _InteractiveSelectionChipState extends State<_InteractiveSelectionChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.45)
        : (widget.selected || _focused || _hovered)
            ? widget.accentColor
            : AppColors.cardBorder;

    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: widget.enabled ? widget.onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: widget.selected
                  ? widget.accentColor.withValues(alpha: 0.16)
                  : (_hovered && widget.enabled)
                      ? AppColors.surfaceLight
                      : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: widget.selected ? 1.4 : 1.0,
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight:
                    widget.selected ? FontWeight.w700 : FontWeight.w500,
                color: !widget.enabled
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : widget.selected
                        ? widget.accentColor
                        : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImpactMetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _ImpactMetricBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rysuje scenę gali: kurtynę/ekran LED z tyłu, ruchome stożki reflektorów
/// oraz podest z podświetleniem pod rower i liderów drużyny.
class _PresentationStagePainter extends CustomPainter {
  final double stagePhase;
  final double burstProgress;
  final int burstSeed;
  final Color primaryColor;
  final Color accentColor;
  final String teamTla;
  final int seasonYear;
  final String sponsorName;

  const _PresentationStagePainter({
    required this.stagePhase,
    required this.burstProgress,
    required this.burstSeed,
    required this.primaryColor,
    required this.accentColor,
    required this.teamTla,
    required this.seasonYear,
    required this.sponsorName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect fullRect = Offset.zero & size;

    // 1. Tło areny i ściana LED
    final Paint bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0A0C10),
          Color(0xFF151923),
          Color(0xFF0F1115),
        ],
      ).createShader(fullRect);
    canvas.drawRect(fullRect, bgPaint);

    // Subtelna siatka ekranu LED na tylnej ścianie
    final Paint ledGridPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;
    for (double x = 24; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height * 0.78), ledGridPaint);
    }

    // Znak wodny drużyny i roku na tylnej ścianie
    final TextPainter watermarkPainter = TextPainter(
      text: TextSpan(
        text: '$teamTla • $seasonYear',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: size.width < 500 ? 34 : 52,
          fontWeight: FontWeight.w900,
          letterSpacing: 4.0,
          color: AppColors.textPrimary.withValues(alpha: 0.05),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    watermarkPainter.paint(
      canvas,
      Offset(
        (size.width - watermarkPainter.width) / 2,
        size.height * 0.16,
      ),
    );

    // 2. Belka oświetleniowa u góry i 4 ruchome reflektory
    final Paint trussPaint = Paint()..color = const Color(0xFF1F2430);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 10), trussPaint);

    final List<double> anchors = [0.16, 0.38, 0.62, 0.84];
    for (int i = 0; i < anchors.length; i++) {
      final double ox = size.width * anchors[i];
      final double sweep = math.sin(stagePhase * math.pi * 2 + i * 1.4) *
          (size.width * 0.09);
      final double targetX = size.width * (0.22 + i * 0.18) + sweep;
      final Color beamColor = i.isEven ? accentColor : primaryColor;

      final Path beam = Path()
        ..moveTo(ox - 8, 8)
        ..lineTo(ox + 8, 8)
        ..lineTo(targetX + 58, size.height * 0.88)
        ..lineTo(targetX - 58, size.height * 0.88)
        ..close();

      final Paint beamPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            beamColor.withValues(alpha: 0.24),
            beamColor.withValues(alpha: 0.07),
            beamColor.withValues(alpha: 0.0),
          ],
        ).createShader(fullRect);
      canvas.drawPath(beam, beamPaint);

      // Obudowa reflektora
      canvas.drawCircle(
        Offset(ox, 9),
        5,
        Paint()..color = beamColor.withValues(alpha: 0.85),
      );
    }

    // 3. Podest sceniczny (dolne 22% wysokości)
    final double deckTop = size.height * 0.78;
    final Rect deckRect = Rect.fromLTWH(0, deckTop, size.width, size.height - deckTop);
    final Paint deckPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF232834),
          Color(0xFF12151C),
        ],
      ).createShader(deckRect);
    canvas.drawRect(deckRect, deckPaint);

    // Złota listwa LED krawędzi podestu
    final Paint rimPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.72)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(0, deckTop), Offset(size.width, deckTop), rimPaint);

    // Centralny podświetlany krąg pod rowerem
    final Rect turntableRect = Rect.fromCenter(
      center: Offset(size.width / 2, deckTop + 14),
      width: size.width * 0.42,
      height: 22,
    );
    canvas.drawOval(
      turntableRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accentColor.withValues(alpha: 0.34),
            primaryColor.withValues(alpha: 0.14),
            Colors.transparent,
          ],
        ).createShader(turntableRect),
    );
  }

  @override
  bool shouldRepaint(covariant _PresentationStagePainter oldDelegate) {
    return oldDelegate.stagePhase != stagePhase ||
        oldDelegate.burstProgress != burstProgress ||
        oldDelegate.burstSeed != burstSeed ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor;
  }
}

/// Warstwa błysków aparatów fotoreporterów (automatycznych i wyzwalanych kliknięciem).
class _CameraFlashOverlayPainter extends CustomPainter {
  final double stagePhase;
  final double burstProgress;
  final int burstSeed;

  const _CameraFlashOverlayPainter({
    required this.stagePhase,
    required this.burstProgress,
    required this.burstSeed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Subtelne ciągłe błyski w strefie prasy (dół sceny)
    for (int i = 0; i < 4; i++) {
      final double localPhase = (stagePhase * 3.0 + i * 0.27) % 1.0;
      if (localPhase < 0.14) {
        final double intensity = math.sin((localPhase / 0.14) * math.pi);
        final Offset pos = Offset(
          size.width * (0.12 + ((i * 0.24 + (stagePhase * 0.15)) % 0.76)),
          size.height * (0.84 + (i % 2) * 0.08),
        );
        _drawFlashStar(canvas, pos, 26 * intensity, intensity * 0.85);
      }
    }

    // 2. Silna salwa fleszy po kliknięciu użytkownika / zmianie lidera
    if (burstProgress > 0.0 && burstProgress < 1.0) {
      final math.Random rng = math.Random(burstSeed);
      final double envelope = math.sin(burstProgress * math.pi);
      for (int i = 0; i < 7; i++) {
        final double fx = size.width * (0.08 + rng.nextDouble() * 0.84);
        final double fy = size.height * (0.70 + rng.nextDouble() * 0.25);
        final double radius = (32 + rng.nextDouble() * 34) * envelope;
        _drawFlashStar(canvas, Offset(fx, fy), radius, envelope);
      }

      // Delikatny błysk atmosferyczny na całej scenie
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: 0.08 * envelope),
      );
    }
  }

  void _drawFlashStar(
    Canvas canvas,
    Offset center,
    double radius,
    double alpha,
  ) {
    if (radius <= 1 || alpha <= 0.01) return;
    final Rect glowRect = Rect.fromCircle(center: center, radius: radius);
    final Paint glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0)),
          AppColors.cyanAccent.withValues(alpha: (alpha * 0.45).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
      ).createShader(glowRect);
    canvas.drawCircle(center, radius, glowPaint);

    // Krzyżowe promienie obiektywu
    final Paint rayPaint = Paint()
      ..color = Colors.white.withValues(alpha: (alpha * 0.9).clamp(0.0, 1.0))
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - radius * 0.85, center.dy),
      Offset(center.dx + radius * 0.85, center.dy),
      rayPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.85),
      Offset(center.dx, center.dy + radius * 0.85),
      rayPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CameraFlashOverlayPainter oldDelegate) {
    return oldDelegate.stagePhase != stagePhase ||
        oldDelegate.burstProgress != burstProgress ||
        oldDelegate.burstSeed != burstSeed;
  }
}

/// Wektorowy rysunek szosowego roweru aero na scenie, używany gdy brak obiektu [CompleteBike].
class _StageBikeShowcasePainter extends CustomPainter {
  final Color frameColor;
  final Color accentColor;

  const _StageBikeShowcasePainter({
    required this.frameColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double wheelR = math.min(w * 0.17, h * 0.34);
    final Offset rearHub = Offset(w * 0.24, h * 0.66);
    final Offset frontHub = Offset(w * 0.76, h * 0.66);
    final Offset bottomBracket = Offset(w * 0.46, h * 0.68);
    final Offset seatCluster = Offset(w * 0.39, h * 0.36);
    final Offset headTubeTop = Offset(w * 0.67, h * 0.34);
    final Offset headTubeBottom = Offset(w * 0.69, h * 0.42);

    // Cień pod kołami
    final Paint floorShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, rearHub.dy + wheelR + 4),
        width: w * 0.72,
        height: 10,
      ),
      floorShadow,
    );

    // Koła z głębokim stożkiem karbonowym i oponą tan-wall
    for (final center in [rearHub, frontHub]) {
      canvas.drawCircle(
        center,
        wheelR,
        Paint()
          ..color = const Color(0xFF111318)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.5,
      );
      canvas.drawCircle(
        center,
        wheelR - 3.5,
        Paint()
          ..color = const Color(0xFFB48A5A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
      canvas.drawCircle(
        center,
        wheelR - 8,
        Paint()
          ..color = const Color(0xFF232833)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7.0,
      );
      canvas.drawCircle(
        center,
        5,
        Paint()..color = accentColor,
      );
    }

    // Rama aero
    final Paint framePaint = Paint()
      ..color = frameColor
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Paint stayPaint = Paint()
      ..color = frameColor
      ..strokeWidth = 3.8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(rearHub, bottomBracket, stayPaint);
    canvas.drawLine(rearHub, seatCluster, stayPaint);
    canvas.drawLine(bottomBracket, seatCluster, framePaint);
    canvas.drawLine(seatCluster, headTubeTop, framePaint);
    canvas.drawLine(bottomBracket, headTubeBottom, framePaint);
    canvas.drawLine(headTubeTop, headTubeBottom, framePaint);
    canvas.drawLine(headTubeBottom, frontHub, framePaint);

    // Sztyca i siodełko
    final Offset saddleBase = Offset(seatCluster.dx - 4, seatCluster.dy - 14);
    canvas.drawLine(seatCluster, saddleBase, stayPaint);
    canvas.drawLine(
      Offset(saddleBase.dx - 14, saddleBase.dy),
      Offset(saddleBase.dx + 14, saddleBase.dy),
      Paint()
        ..color = const Color(0xFF111318)
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round,
    );

    // Mostek i kierownica baranek
    final Offset stemEnd = Offset(headTubeTop.dx + 14, headTubeTop.dy - 8);
    canvas.drawLine(
      Offset(headTubeTop.dx, headTubeTop.dy - 5),
      stemEnd,
      Paint()
        ..color = const Color(0xFF111318)
        ..strokeWidth = 4.2
        ..strokeCap = StrokeCap.round,
    );
    final Path dropBar = Path()
      ..moveTo(stemEnd.dx, stemEnd.dy)
      ..quadraticBezierTo(
        stemEnd.dx + 18,
        stemEnd.dy + 2,
        stemEnd.dx + 14,
        stemEnd.dy + 18,
      )
      ..quadraticBezierTo(
        stemEnd.dx + 10,
        stemEnd.dy + 25,
        stemEnd.dx - 2,
        stemEnd.dy + 22,
      );
    canvas.drawPath(
      dropBar,
      Paint()
        ..color = const Color(0xFF111318)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round,
    );

    // Korba
    canvas.drawCircle(
      bottomBracket,
      9,
      Paint()..color = const Color(0xFF2D3340),
    );
    canvas.drawCircle(
      bottomBracket,
      3.5,
      Paint()..color = accentColor,
    );
  }

  @override
  bool shouldRepaint(covariant _StageBikeShowcasePainter oldDelegate) {
    return oldDelegate.frameColor != frameColor ||
        oldDelegate.accentColor != accentColor;
  }
}
