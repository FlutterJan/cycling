import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../services/career/global_satellite_training_centers_service.dart';

/// Zakładki panelu zarządzania wybraną akademią na ekranie mapy globalnej.
enum AcademyNetworkMapTab {
  overview('Przegląd i Tryb', Icons.tune_rounded),
  scouting('Talenty U19/U23', Icons.person_search_rounded),
  altitudeCamps('Obozy Pro', Icons.terrain_rounded),
  logistics('Logistyka Sieci', Icons.hub_rounded);

  final String label;
  final IconData icon;
  const AcademyNetworkMapTab(this.label, this.icon);
}

/// Przykładowi kolarze kadry Pro dostępni do wysłania na obóz wysokogórski lub brukowy.
class AcademyCampRiderCandidate {
  final String id;
  final String name;
  final String roleLabel;

  const AcademyCampRiderCandidate({
    required this.id,
    required this.name,
    required this.roleLabel,
  });

  static const List<AcademyCampRiderCandidate> defaultRoster = [
    AcademyCampRiderCandidate(
      id: 'pro_leader_gc',
      name: 'M. Kowalski',
      roleLabel: 'Lider GC',
    ),
    AcademyCampRiderCandidate(
      id: 'pro_climber_1',
      name: 'L. Martínez',
      roleLabel: 'Góral',
    ),
    AcademyCampRiderCandidate(
      id: 'pro_cobbles_1',
      name: 'J. Vermeulen',
      roleLabel: 'Klasyki / Bruk',
    ),
    AcademyCampRiderCandidate(
      id: 'pro_tt_1',
      name: 'T. Lindqvist',
      roleLabel: 'Czasowiec ITT',
    ),
    AcademyCampRiderCandidate(
      id: 'pro_sprinter_1',
      name: 'A. Moretti',
      roleLabel: 'Sprinter',
    ),
  ];
}

/// Ekran mapy świata i zarządzania globalną siecią akademii treningowych.
///
/// Integruje się z [globalSatelliteTrainingCentersProvider] oraz obsługuje
/// responsywnie rozdzielczości 390x844, 1024x768 i 1600x900 z pełnymi stanami
/// hover, active, disabled oraz focus.
class GlobalAcademyNetworkMapScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const GlobalAcademyNetworkMapScreen({
    super.key,
    this.onBack,
  });

  @override
  ConsumerState<GlobalAcademyNetworkMapScreen> createState() =>
      _GlobalAcademyNetworkMapScreenState();
}

class _GlobalAcademyNetworkMapScreenState
    extends ConsumerState<GlobalAcademyNetworkMapScreen>
    with SingleTickerProviderStateMixin {
  AcademyNetworkMapTab _activeTab = AcademyNetworkMapTab.overview;
  SatelliteAcademyRegionId? _hoveredRegion;
  bool _showConnectionArcs = true;
  bool _showAltitudeGrid = true;
  int _selectedRiderIndex = 0;
  int _selectedCampDays = 14;
  AcademyCampIntensity _selectedIntensity = AcademyCampIntensity.standardBlock;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(globalSatelliteTrainingCentersProvider);
    final notifier = ref.read(globalSatelliteTrainingCentersProvider.notifier);
    final summary = const GlobalSatelliteTrainingCentersService()
        .computeNetworkSummary(state.nodes);
    final selectedNode = state.selectedNode;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isCompact = width < 760;
            final isDesktop = width >= 1120;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopHeader(
                  context: context,
                  state: state,
                  notifier: notifier,
                  summary: summary,
                  isCompact: isCompact,
                ),
                Expanded(
                  child: isDesktop
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 12,
                                child: _buildMapColumn(
                                  state: state,
                                  notifier: notifier,
                                  isCompact: false,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 9,
                                child: _buildInspectorPanel(
                                  state: state,
                                  notifier: notifier,
                                  summary: summary,
                                  selectedNode: selectedNode,
                                  isCompact: false,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            isCompact ? 12 : 16,
                            10,
                            isCompact ? 12 : 16,
                            20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: isCompact ? 300 : 380,
                                child: _buildMapColumn(
                                  state: state,
                                  notifier: notifier,
                                  isCompact: isCompact,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildInspectorPanel(
                                state: state,
                                notifier: notifier,
                                summary: summary,
                                selectedNode: selectedNode,
                                isCompact: isCompact,
                                shrinkWrapScroll: true,
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopHeader({
    required BuildContext context,
    required GlobalSatelliteTrainingCentersState state,
    required GlobalSatelliteTrainingCentersNotifier notifier,
    required GlobalSatelliteAcademyNetworkSummary summary,
    required bool isCompact,
  }) {
    final dateText =
        '${state.currentDate.day.toString().padLeft(2, '0')}.${state.currentDate.month.toString().padLeft(2, '0')}.${state.currentDate.year}';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 20,
        vertical: isCompact ? 10 : 14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NetworkIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Powrót',
                    onPressed: _handleBack,
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryAccent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.public_rounded,
                      color: AppColors.goldAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Globalna Sieć Akademii Treningowych',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: isCompact ? 16 : 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mapa satelickich baz wysokogórskich, obozów Pro i skautingu U19/U23',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: isCompact ? 11.5 : 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: AppColors.accentBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dateText,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _NetworkActionButton(
                    label: '+7 dni',
                    icon: Icons.fast_forward_rounded,
                    color: AppColors.accentBlue,
                    compact: true,
                    onPressed: () => notifier.advanceDays(7),
                  ),
                  _NetworkActionButton(
                    label: '+14 dni',
                    icon: Icons.skip_next_rounded,
                    color: AppColors.goldAccent,
                    compact: true,
                    onPressed: () => notifier.advanceDays(14),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _HeaderKpiPill(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Budżet Klubu',
                  value: Formatters.formatCurrency(state.teamBudgetEur),
                  accent: AppColors.goldAccent,
                ),
                const SizedBox(width: 8),
                _HeaderKpiPill(
                  icon: Icons.apartment_rounded,
                  label: 'Aktywne Bazy',
                  value: '${summary.activeCenters}/${summary.totalCenters}',
                  accent: AppColors.statusSuccess,
                ),
                const SizedBox(width: 8),
                _HeaderKpiPill(
                  icon: Icons.person_search_rounded,
                  label: 'Talenty U19/U23',
                  value: '${summary.totalProspectsInPipeline}',
                  accent: AppColors.accentBlue,
                ),
                const SizedBox(width: 8),
                _HeaderKpiPill(
                  icon: Icons.directions_bike_rounded,
                  label: 'Kolarze na Obozach',
                  value: '${summary.totalActiveCampRiders}',
                  accent: AppColors.amberWarning,
                ),
                const SizedBox(width: 8),
                _HeaderKpiPill(
                  icon: Icons.terrain_rounded,
                  label: 'Pokrycie Hipoksji',
                  value: '${summary.altitudeCoverageScore.toStringAsFixed(0)}%',
                  accent: AppColors.cyanAccent,
                ),
                const SizedBox(width: 8),
                _HeaderKpiPill(
                  icon: Icons.payments_rounded,
                  label: 'Utrzymanie / rok',
                  value: Formatters.formatCurrency(summary.totalAnnualUpkeepEur),
                  accent: AppColors.primaryAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapColumn({
    required GlobalSatelliteTrainingCentersState state,
    required GlobalSatelliteTrainingCentersNotifier notifier,
    required bool isCompact,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              border: Border(
                bottom: BorderSide(color: AppColors.cardBorder, width: 1),
              ),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.radar_rounded,
                      size: 16,
                      color: AppColors.cyanAccent,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Mapa Satelitarna Sieci Akademii',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _MapLayerToggleChip(
                      label: 'Łącza HQ',
                      icon: Icons.timeline_rounded,
                      active: _showConnectionArcs,
                      onTap: () {
                        setState(() {
                          _showConnectionArcs = !_showConnectionArcs;
                        });
                      },
                    ),
                    _MapLayerToggleChip(
                      label: 'Siatka Geo',
                      icon: Icons.grid_on_rounded,
                      active: _showAltitudeGrid,
                      onTap: () {
                        setState(() {
                          _showAltitudeGrid = !_showAltitudeGrid;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: WorldAcademyNetworkMapPainter(
                          nodes: state.nodes,
                          selectedRegion: state.selectedRegion,
                          hoveredRegion: _hoveredRegion,
                          showConnectionArcs: _showConnectionArcs,
                          showAltitudeGrid: _showAltitudeGrid,
                          pulseProgress: _pulseController.value,
                        ),
                      );
                    },
                  ),
                ),
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, mapConstraints) {
                      final mapW = mapConstraints.maxWidth;
                      final mapH = mapConstraints.maxHeight;
                      return Stack(
                        children: [
                          _buildHqBeacon(mapW, mapH),
                          for (final region in SatelliteAcademyRegionId.values)
                            _buildAcademyPin(
                              region: region,
                              node: state.nodes[region]!,
                              isSelected: state.selectedRegion == region,
                              isHovered: _hoveredRegion == region,
                              mapWidth: mapW,
                              mapHeight: mapH,
                              isCompact: isCompact,
                              onSelect: () => notifier.selectRegion(region),
                              onHoverChanged: (hovering) {
                                setState(() {
                                  _hoveredRegion = hovering ? region : null;
                                });
                              },
                            ),
                        ],
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: _MapLegendBar(isCompact: isCompact),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              border: Border(
                top: BorderSide(color: AppColors.cardBorder, width: 1),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final region in SatelliteAcademyRegionId.values) ...[
                    _QuickRegionSelectorChip(
                      region: region,
                      node: state.nodes[region]!,
                      isSelected: state.selectedRegion == region,
                      onTap: () => notifier.selectRegion(region),
                    ),
                    if (region != SatelliteAcademyRegionId.values.last)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHqBeacon(double mapWidth, double mapHeight) {
    final pos = WorldAcademyNetworkMapPainter.projectGeo(
      latitude: 49.5,
      longitude: 5.5,
      width: mapWidth,
      height: mapHeight,
    );
    return Positioned(
      left: (pos.dx - 16).clamp(8.0, math.max(8.0, mapWidth - 36)),
      top: (pos.dy - 16).clamp(8.0, math.max(8.0, mapHeight - 36)),
      child: IgnorePointer(
        child: Tooltip(
          message: 'Baza Główna Klubu (Service Course HQ)',
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.92),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryAccent, width: 1.5),
            ),
            child: const Icon(
              Icons.home_work_rounded,
              size: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAcademyPin({
    required SatelliteAcademyRegionId region,
    required SatelliteAcademyNode node,
    required bool isSelected,
    required bool isHovered,
    required double mapWidth,
    required double mapHeight,
    required bool isCompact,
    required VoidCallback onSelect,
    required ValueChanged<bool> onHoverChanged,
  }) {
    final projected = WorldAcademyNetworkMapPainter.projectGeo(
      latitude: region.latitude,
      longitude: region.longitude,
      width: mapWidth,
      height: mapHeight,
    );

    final pinWidth = isCompact ? 112.0 : 134.0;
    final pinHeight = isCompact ? 46.0 : 52.0;

    // Lekkie przesunięcie dla dwóch blisko położonych europejskich baz
    // (Flandria vs Sierra Nevada), aby etykiety nigdy nie nachodziły na siebie.
    final verticalOffset = region == SatelliteAcademyRegionId.flandersKortrijk
        ? -pinHeight - 4
        : region == SatelliteAcademyRegionId.sierraNevadaGranada
            ? 8.0
            : -pinHeight / 2;

    final left = (projected.dx - pinWidth / 2)
        .clamp(8.0, math.max(8.0, mapWidth - pinWidth - 8.0))
        .toDouble();
    final top = (projected.dy + verticalOffset)
        .clamp(8.0, math.max(8.0, mapHeight - pinHeight - 8.0))
        .toDouble();

    return Positioned(
      left: left,
      top: top,
      width: pinWidth,
      height: pinHeight,
      child: _WorldMapAcademyPin(
        region: region,
        node: node,
        isSelected: isSelected,
        isHovered: isHovered,
        compact: isCompact,
        onTap: onSelect,
        onHoverChanged: onHoverChanged,
      ),
    );
  }

  Widget _buildInspectorPanel({
    required GlobalSatelliteTrainingCentersState state,
    required GlobalSatelliteTrainingCentersNotifier notifier,
    required GlobalSatelliteAcademyNetworkSummary summary,
    required SatelliteAcademyNode selectedNode,
    required bool isCompact,
    bool shrinkWrapScroll = false,
  }) {
    final bodyContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: shrinkWrapScroll ? MainAxisSize.min : MainAxisSize.max,
      children: [
        if (state.lastFeedbackMessage != null) ...[
          _FeedbackNoticeBanner(
            message: state.lastFeedbackMessage!,
            isError: state.isFeedbackError,
          ),
          const SizedBox(height: 10),
        ],
        _SelectedAcademyHeaderCard(
          node: selectedNode,
          teamBudgetEur: state.teamBudgetEur,
          isCompact: isCompact,
          onUnlockOrUpgrade: () =>
              notifier.unlockOrUpgradeRegion(selectedNode.regionId),
          onMaintain: () => notifier.maintainAcademy(selectedNode.regionId),
          onScout: () => notifier.scoutProspect(selectedNode.regionId),
        ),
        const SizedBox(height: 10),
        _AcademyTabSelector(
          activeTab: _activeTab,
          onTabSelected: (tab) {
            setState(() {
              _activeTab = tab;
            });
          },
        ),
        const SizedBox(height: 10),
        if (shrinkWrapScroll)
          _buildTabBody(
            state: state,
            notifier: notifier,
            summary: summary,
            node: selectedNode,
            isCompact: isCompact,
          )
        else
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(right: 2),
              child: _buildTabBody(
                state: state,
                notifier: notifier,
                summary: summary,
                node: selectedNode,
                isCompact: isCompact,
              ),
            ),
          ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: bodyContent,
    );
  }

  Widget _buildTabBody({
    required GlobalSatelliteTrainingCentersState state,
    required GlobalSatelliteTrainingCentersNotifier notifier,
    required GlobalSatelliteAcademyNetworkSummary summary,
    required SatelliteAcademyNode node,
    required bool isCompact,
  }) {
    switch (_activeTab) {
      case AcademyNetworkMapTab.overview:
        return _OverviewAndFocusTab(
          node: node,
          onSelectFocus: (mode) => notifier.setFocusMode(node.regionId, mode),
        );
      case AcademyNetworkMapTab.scouting:
        return _ScoutingProspectsTab(
          node: node,
          teamBudgetEur: state.teamBudgetEur,
          onScoutNew: () => notifier.scoutProspect(node.regionId),
          onPromote: (prospectId) =>
              notifier.promoteProspect(node.regionId, prospectId),
        );
      case AcademyNetworkMapTab.altitudeCamps:
        return _AltitudeCampsTab(
          node: node,
          selectedRiderIndex: _selectedRiderIndex,
          selectedCampDays: _selectedCampDays,
          selectedIntensity: _selectedIntensity,
          onRiderChanged: (idx) => setState(() => _selectedRiderIndex = idx),
          onDaysChanged: (days) => setState(() => _selectedCampDays = days),
          onIntensityChanged: (intensity) =>
              setState(() => _selectedIntensity = intensity),
          onEnrollRider: () {
            final rider =
                AcademyCampRiderCandidate.defaultRoster[_selectedRiderIndex];
            notifier.enrollRiderInCamp(
              region: node.regionId,
              riderId: rider.id,
              riderName: rider.name,
              durationDays: _selectedCampDays,
              intensity: _selectedIntensity,
            );
          },
        );
      case AcademyNetworkMapTab.logistics:
        return _NetworkLogisticsTab(
          nodes: state.nodes,
          summary: summary,
          selectedRegion: state.selectedRegion,
          onSelectRegion: notifier.selectRegion,
        );
    }
  }
}

/// Rysuje stylizowaną mapę świata, siatkę współrzędnych, kontynenty oraz łuki połączeń HQ -> Akademie.
class WorldAcademyNetworkMapPainter extends CustomPainter {
  final Map<SatelliteAcademyRegionId, SatelliteAcademyNode> nodes;
  final SatelliteAcademyRegionId selectedRegion;
  final SatelliteAcademyRegionId? hoveredRegion;
  final bool showConnectionArcs;
  final bool showAltitudeGrid;
  final double pulseProgress;

  const WorldAcademyNetworkMapPainter({
    required this.nodes,
    required this.selectedRegion,
    required this.hoveredRegion,
    required this.showConnectionArcs,
    required this.showAltitudeGrid,
    required this.pulseProgress,
  });

  /// Projekcja równoodległościowa (equirectangular) dla obszaru od -120°..+145° lon i -55°..+72° lat.
  static Offset projectGeo({
    required double latitude,
    required double longitude,
    required double width,
    required double height,
  }) {
    const minLon = -125.0;
    const maxLon = 155.0;
    const minLat = -56.0;
    const maxLat = 72.0;

    final nx = ((longitude - minLon) / (maxLon - minLon)).clamp(0.0, 1.0);
    final ny = 1.0 - ((latitude - minLat) / (maxLat - minLat)).clamp(0.0, 1.0);

    return Offset(nx * width, ny * height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bgRect = Offset.zero & size;
    final oceanPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0C0F14),
          Color(0xFF10151E),
          Color(0xFF0D1016),
        ],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, oceanPaint);

    if (showAltitudeGrid) {
      _paintGraticule(canvas, size);
    }

    _paintContinents(canvas, size);

    final hqPos = projectGeo(
      latitude: 49.5,
      longitude: 5.5,
      width: size.width,
      height: size.height,
    );

    if (showConnectionArcs) {
      for (final region in SatelliteAcademyRegionId.values) {
        final node = nodes[region];
        if (node == null) continue;
        final targetPos = projectGeo(
          latitude: region.latitude,
          longitude: region.longitude,
          width: size.width,
          height: size.height,
        );
        _paintConnectionArc(
          canvas: canvas,
          from: hqPos,
          to: targetPos,
          node: node,
          isSelected: region == selectedRegion,
        );
      }
    }

    for (final region in SatelliteAcademyRegionId.values) {
      final node = nodes[region];
      if (node == null) continue;
      final targetPos = projectGeo(
        latitude: region.latitude,
        longitude: region.longitude,
        width: size.width,
        height: size.height,
      );
      _paintBeaconPulse(
        canvas: canvas,
        center: targetPos,
        node: node,
        isSelected: region == selectedRegion,
        isHovered: region == hoveredRegion,
      );
    }
  }

  void _paintGraticule(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.35)
      ..strokeWidth = 0.8;

    for (var lat = -40.0; lat <= 60.0; lat += 20.0) {
      final p1 = projectGeo(
        latitude: lat,
        longitude: -125.0,
        width: size.width,
        height: size.height,
      );
      final p2 = projectGeo(
        latitude: lat,
        longitude: 155.0,
        width: size.width,
        height: size.height,
      );
      canvas.drawLine(p1, p2, gridPaint);
    }

    for (var lon = -100.0; lon <= 140.0; lon += 40.0) {
      final p1 = projectGeo(
        latitude: 72.0,
        longitude: lon,
        width: size.width,
        height: size.height,
      );
      final p2 = projectGeo(
        latitude: -56.0,
        longitude: lon,
        width: size.width,
        height: size.height,
      );
      canvas.drawLine(p1, p2, gridPaint);
    }

    // Równik subtelnie wyróżniony
    final eq1 = projectGeo(
      latitude: 0,
      longitude: -125,
      width: size.width,
      height: size.height,
    );
    final eq2 = projectGeo(
      latitude: 0,
      longitude: 155,
      width: size.width,
      height: size.height,
    );
    canvas.drawLine(
      eq1,
      eq2,
      Paint()
        ..color = AppColors.accentBlue.withValues(alpha: 0.16)
        ..strokeWidth = 1.0,
    );
  }

  void _paintContinents(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = const Color(0xFF1A1F29)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final polygons = <List<List<double>>>[
      // Ameryka Północna
      [
        [68, -122],
        [70, -95],
        [62, -74],
        [48, -56],
        [36, -75],
        [25, -81],
        [20, -90],
        [15, -84],
        [10, -79],
        [18, -104],
        [32, -117],
        [49, -124],
      ],
      // Ameryka Południowa
      [
        [11, -76],
        [10, -62],
        [4, -51],
        [-5, -35],
        [-18, -39],
        [-34, -54],
        [-52, -68],
        [-54, -73],
        [-38, -74],
        [-18, -71],
        [-4, -81],
        [6, -78],
      ],
      // Europa
      [
        [36, -9],
        [43, -9],
        [44, -2],
        [49, -4],
        [52, 4],
        [55, 8],
        [60, 5],
        [70, 22],
        [68, 42],
        [55, 48],
        [45, 38],
        [41, 28],
        [38, 22],
        [40, 15],
        [44, 12],
        [43, 4],
        [37, -2],
      ],
      // Afryka
      [
        [35, -6],
        [37, 10],
        [32, 32],
        [15, 41],
        [11, 51],
        [-2, 42],
        [-14, 40],
        [-26, 33],
        [-34, 20],
        [-22, 14],
        [-6, 12],
        [4, 9],
        [5, -8],
        [15, -17],
        [27, -13],
      ],
      // Azja
      [
        [68, 45],
        [72, 95],
        [66, 145],
        [52, 142],
        [40, 129],
        [30, 122],
        [20, 108],
        [8, 104],
        [12, 98],
        [22, 90],
        [8, 77],
        [24, 67],
        [25, 56],
        [30, 48],
        [40, 36],
        [45, 42],
        [55, 48],
      ],
      // Australia
      [
        [-12, 130],
        [-12, 143],
        [-25, 153],
        [-37, 150],
        [-38, 140],
        [-33, 125],
        [-34, 115],
        [-21, 114],
      ],
    ];

    for (final poly in polygons) {
      final path = Path();
      for (var i = 0; i < poly.length; i++) {
        final pt = projectGeo(
          latitude: poly[i][0],
          longitude: poly[i][1],
          width: size.width,
          height: size.height,
        );
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      path.close();
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, borderPaint);
    }
  }

  void _paintConnectionArc({
    required Canvas canvas,
    required Offset from,
    required Offset to,
    required SatelliteAcademyNode node,
    required bool isSelected,
  }) {
    final midX = (from.dx + to.dx) / 2;
    final distance = (to - from).distance;
    final ctrlY = math.min(from.dy, to.dy) - math.min(72.0, distance * 0.22);
    final control = Offset(midX, math.max(12.0, ctrlY));

    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);

    final Color arcColor;
    final double strokeWidth;
    if (!node.isBuilt) {
      arcColor = AppColors.textSecondary.withValues(alpha: 0.25);
      strokeWidth = 1.0;
    } else if (isSelected) {
      arcColor = AppColors.goldAccent.withValues(alpha: 0.85);
      strokeWidth = 2.0;
    } else {
      arcColor = node.regionId.accentColor.withValues(alpha: 0.55);
      strokeWidth = 1.4;
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = arcColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  void _paintBeaconPulse({
    required Canvas canvas,
    required Offset center,
    required SatelliteAcademyNode node,
    required bool isSelected,
    required bool isHovered,
  }) {
    final accent =
        node.isBuilt ? node.regionId.accentColor : AppColors.textSecondary;

    if (node.isBuilt || isSelected || isHovered) {
      final radius = 8.0 + pulseProgress * (isSelected ? 20.0 : 14.0);
      final alpha = (1.0 - pulseProgress) * (isSelected ? 0.55 : 0.30);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = (isSelected ? AppColors.goldAccent : accent)
              .withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2.0 : 1.2,
      );
    }

    canvas.drawCircle(
      center,
      isSelected ? 5.5 : 4.2,
      Paint()..color = isSelected ? AppColors.goldAccent : accent,
    );
  }

  @override
  bool shouldRepaint(covariant WorldAcademyNetworkMapPainter oldDelegate) {
    return oldDelegate.selectedRegion != selectedRegion ||
        oldDelegate.hoveredRegion != hoveredRegion ||
        oldDelegate.showConnectionArcs != showConnectionArcs ||
        oldDelegate.showAltitudeGrid != showAltitudeGrid ||
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.nodes != nodes;
  }
}

class _WorldMapAcademyPin extends StatefulWidget {
  final SatelliteAcademyRegionId region;
  final SatelliteAcademyNode node;
  final bool isSelected;
  final bool isHovered;
  final bool compact;
  final VoidCallback onTap;
  final ValueChanged<bool> onHoverChanged;

  const _WorldMapAcademyPin({
    required this.region,
    required this.node,
    required this.isSelected,
    required this.isHovered,
    required this.compact,
    required this.onTap,
    required this.onHoverChanged,
  });

  @override
  State<_WorldMapAcademyPin> createState() => _WorldMapAcademyPinState();
}

class _WorldMapAcademyPinState extends State<_WorldMapAcademyPin> {
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final accent = node.isBuilt
        ? widget.region.accentColor
        : AppColors.textSecondary;
    final borderColor = widget.isSelected
        ? AppColors.goldAccent
        : _isFocused
            ? AppColors.accentBlue
            : widget.isHovered
                ? accent
                : AppColors.cardBorder;

    return FocusableActionDetector(
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      onShowHoverHighlight: (hovered) => widget.onHoverChanged(hovered),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed
              ? 0.96
              : (widget.isSelected || widget.isHovered ? 1.03 : 1.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.surfaceLight.withValues(alpha: 0.96)
                  : AppColors.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: widget.isSelected || _isFocused ? 1.6 : 1.0,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.goldAccent.withValues(alpha: 0.22),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: node.status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        widget.region.shortLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: widget.compact ? 10.5 : 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      node.isBuilt ? 'T${node.tier}' : 'LOCK',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: node.isBuilt
                            ? AppColors.goldAccent
                            : AppColors.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.region.altitudeMeters}m',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9.5,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        node.isBuilt
                            ? '${node.availableProspectCount}U · ${node.activeCampRiderCount}C'
                            : 'Niezbud.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: node.isBuilt
                              ? accent
                              : AppColors.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
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

class _SelectedAcademyHeaderCard extends StatelessWidget {
  final SatelliteAcademyNode node;
  final double teamBudgetEur;
  final bool isCompact;
  final VoidCallback onUnlockOrUpgrade;
  final VoidCallback onMaintain;
  final VoidCallback onScout;

  const _SelectedAcademyHeaderCard({
    required this.node,
    required this.teamBudgetEur,
    required this.isCompact,
    required this.onUnlockOrUpgrade,
    required this.onMaintain,
    required this.onScout,
  });

  @override
  Widget build(BuildContext context) {
    final region = node.regionId;
    final canUpgrade = node.tier < 4 && teamBudgetEur >= node.nextUpgradeCostEur;
    final upgradeLabel = !node.isBuilt
        ? 'Zbuduj (${Formatters.formatCurrency(node.nextUpgradeCostEur)})'
        : node.tier >= 4
            ? 'Max Tier 4'
            : 'Rozbuduj T${node.tier + 1} (${Formatters.formatCurrency(node.nextUpgradeCostEur)})';

    final canMaintain = node.isBuilt && node.facilityCondition < 98.0;
    final canScout = node.isBuilt &&
        node.availableProspectCount < node.maxProspectSlots &&
        teamBudgetEur >=
            GlobalSatelliteTrainingCentersService.manualScoutingCostEur;

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: node.isBuilt
              ? region.accentColor.withValues(alpha: 0.45)
              : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: region.accentColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            region.countryCode,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: region.accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            region.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${region.cityLabel} · ${region.altitudeMeters} m n.p.m.',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: node.status.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: node.status.color.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  node.status.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: node.status.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _MiniStatLabel(
                label: 'Poziom',
                value: 'Tier ${node.tier}/4',
                color: AppColors.goldAccent,
              ),
              _MiniStatLabel(
                label: 'Stan Bazy',
                value: '${node.facilityCondition.toStringAsFixed(0)}%',
                color: node.facilityCondition >= 75
                    ? AppColors.statusSuccess
                    : AppColors.amberWarning,
              ),
              _MiniStatLabel(
                label: 'Efektywność',
                value: node.isBuilt
                    ? 'x${node.efficiencyMultiplier.toStringAsFixed(2)}'
                    : '—',
                color: AppColors.accentBlue,
              ),
              _MiniStatLabel(
                label: 'Reputacja',
                value: '${node.reputationScore.toStringAsFixed(0)}/100',
                color: AppColors.textPrimary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _NetworkActionButton(
                label: upgradeLabel,
                icon: node.isBuilt
                    ? Icons.upgrade_rounded
                    : Icons.add_business_rounded,
                color: AppColors.goldAccent,
                enabled: canUpgrade,
                onPressed: onUnlockOrUpgrade,
              ),
              _NetworkActionButton(
                label: 'Skautuj U19/U23',
                icon: Icons.person_add_alt_1_rounded,
                color: AppColors.accentBlue,
                enabled: canScout,
                onPressed: onScout,
              ),
              _NetworkActionButton(
                label: 'Konserwacja',
                icon: Icons.build_circle_outlined,
                color: AppColors.statusSuccess,
                enabled: canMaintain,
                onPressed: onMaintain,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewAndFocusTab extends StatelessWidget {
  final SatelliteAcademyNode node;
  final ValueChanged<SatelliteAcademyFocusMode> onSelectFocus;

  const _OverviewAndFocusTab({
    required this.node,
    required this.onSelectFocus,
  });

  @override
  Widget build(BuildContext context) {
    final region = node.regionId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                region.specialtyTitle,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: region.accentColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                region.specialtyDescription,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _InfoTag(
                    icon: Icons.sports_rounded,
                    label:
                        'Trener: ${node.headCoachName} (${node.headCoachRating})',
                  ),
                  _InfoTag(
                    icon: Icons.flag_rounded,
                    label: 'Kraje: ${region.primaryNationalities.join(', ')}',
                  ),
                  _InfoTag(
                    icon: Icons.groups_rounded,
                    label:
                        'Limity: ${node.maxProspectSlots} U23 · ${node.maxCampCapacity} Pro',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Tryb Priorytetowy Akademii',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        for (final mode in SatelliteAcademyFocusMode.values) ...[
          _FocusModeOptionCard(
            mode: mode,
            isSelected: node.focusMode == mode,
            enabled: node.isBuilt,
            onTap: () => onSelectFocus(mode),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ScoutingProspectsTab extends StatelessWidget {
  final SatelliteAcademyNode node;
  final double teamBudgetEur;
  final VoidCallback onScoutNew;
  final ValueChanged<String> onPromote;

  const _ScoutingProspectsTab({
    required this.node,
    required this.teamBudgetEur,
    required this.onScoutNew,
    required this.onPromote,
  });

  @override
  Widget build(BuildContext context) {
    if (!node.isBuilt) {
      return const _EmptyAcademyNotice(
        icon: Icons.lock_outline_rounded,
        title: 'Akademia Niezbudowana',
        description:
            'Zbuduj bazę w tym regionie, aby uruchomić regionalny skauting talentów U19/U23.',
      );
    }

    final available =
        node.prospects.where((p) => !p.isSignedToProRoster).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Odkryte Talenty (${available.length}/${node.maxProspectSlots})',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              'Koszt skautingu: ${Formatters.formatCurrency(GlobalSatelliteTrainingCentersService.manualScoutingCostEur)}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                color: AppColors.textSecondary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (available.isEmpty)
          _EmptyAcademyNotice(
            icon: Icons.person_search_rounded,
            title: 'Brak Aktywnych Talentów',
            description:
                'Uruchom skauting lokalny, aby wyszukać juniorów o wysokim potencjale W/kg.',
            actionLabel: 'Skautuj Pierwszy Talent',
            actionEnabled: teamBudgetEur >=
                GlobalSatelliteTrainingCentersService.manualScoutingCostEur,
            onAction: onScoutNew,
          )
        else
          for (final prospect in available) ...[
            _ProspectCard(
              prospect: prospect,
              onPromote: () => onPromote(prospect.id),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _AltitudeCampsTab extends StatelessWidget {
  final SatelliteAcademyNode node;
  final int selectedRiderIndex;
  final int selectedCampDays;
  final AcademyCampIntensity selectedIntensity;
  final ValueChanged<int> onRiderChanged;
  final ValueChanged<int> onDaysChanged;
  final ValueChanged<AcademyCampIntensity> onIntensityChanged;
  final VoidCallback onEnrollRider;

  const _AltitudeCampsTab({
    required this.node,
    required this.selectedRiderIndex,
    required this.selectedCampDays,
    required this.selectedIntensity,
    required this.onRiderChanged,
    required this.onDaysChanged,
    required this.onIntensityChanged,
    required this.onEnrollRider,
  });

  @override
  Widget build(BuildContext context) {
    if (!node.isBuilt) {
      return const _EmptyAcademyNotice(
        icon: Icons.terrain_rounded,
        title: 'Obozy Niedostępne',
        description:
            'Zbuduj akademię, aby wysyłać kolarzy kadry Pro na zgrupowania wysokogórskie i specjalistyczne.',
      );
    }

    final hasSpace = node.activeCampRiderCount < node.maxCampCapacity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Wyślij Kolarza Pro na Obóz',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Miejsca: ${node.activeCampRiderCount}/${node.maxCampCapacity}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentBlue,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0;
                      i < AcademyCampRiderCandidate.defaultRoster.length;
                      i++)
                    _SelectablePillChip(
                      label:
                          '${AcademyCampRiderCandidate.defaultRoster[i].name} (${AcademyCampRiderCandidate.defaultRoster[i].roleLabel})',
                      isSelected: selectedRiderIndex == i,
                      onTap: () => onRiderChanged(i),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Czas:',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  for (final days in const [7, 14, 21])
                    _SelectablePillChip(
                      label: '$days dni',
                      isSelected: selectedCampDays == days,
                      onTap: () => onDaysChanged(days),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Intensywność:',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  for (final intensity in AcademyCampIntensity.values)
                    _SelectablePillChip(
                      label: intensity.label,
                      isSelected: selectedIntensity == intensity,
                      onTap: () => onIntensityChanged(intensity),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _NetworkActionButton(
                label: hasSpace
                    ? 'Rozpocznij Zgrupowanie ($selectedCampDays dni)'
                    : 'Brak Wolnych Miejsc w Bazie',
                icon: Icons.flight_takeoff_rounded,
                color: AppColors.statusSuccess,
                enabled: hasSpace,
                onPressed: onEnrollRider,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Aktywne i Ukończone Zgrupowania (${node.activeStints.length})',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 8),
        if (node.activeStints.isEmpty)
          const _EmptyAcademyNotice(
            icon: Icons.directions_bike_rounded,
            title: 'Brak Aktywnych Zgrupowań',
            description:
                'Wybierz kolarza powyżej, aby rozpocząć blok adaptacji wysokościowej lub treningu specjalistycznego.',
          )
        else
          for (final stint in node.activeStints) ...[
            _TrainingStintCard(stint: stint),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _NetworkLogisticsTab extends StatelessWidget {
  final Map<SatelliteAcademyRegionId, SatelliteAcademyNode> nodes;
  final GlobalSatelliteAcademyNetworkSummary summary;
  final SatelliteAcademyRegionId selectedRegion;
  final ValueChanged<SatelliteAcademyRegionId> onSelectRegion;

  const _NetworkLogisticsTab({
    required this.nodes,
    required this.summary,
    required this.selectedRegion,
    required this.onSelectRegion,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _MiniStatLabel(
                label: 'Prestiż Sieci',
                value: '${summary.networkPrestigeScore.toStringAsFixed(0)}/100',
                color: AppColors.goldAccent,
              ),
              _MiniStatLabel(
                label: 'Średni Tier',
                value: summary.averageTier.toStringAsFixed(1),
                color: AppColors.accentBlue,
              ),
              _MiniStatLabel(
                label: 'Elitarne Bazy',
                value: '${summary.eliteCenters}',
                color: AppColors.statusSuccess,
              ),
              _MiniStatLabel(
                label: 'Absolwenci w Pro',
                value: '${summary.totalGraduatesPromoted}',
                color: AppColors.cyanAccent,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        for (final region in SatelliteAcademyRegionId.values) ...[
          _LogisticsRegionRowCard(
            node: nodes[region]!,
            isSelected: region == selectedRegion,
            onTap: () => onSelectRegion(region),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _LogisticsRegionRowCard extends StatefulWidget {
  final SatelliteAcademyNode node;
  final bool isSelected;
  final VoidCallback onTap;

  const _LogisticsRegionRowCard({
    required this.node,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_LogisticsRegionRowCard> createState() =>
      _LogisticsRegionRowCardState();
}

class _LogisticsRegionRowCardState extends State<_LogisticsRegionRowCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final region = node.regionId;
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isSelected || _hovered
                ? AppColors.surfaceLight
                : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.goldAccent
                  : _focused
                      ? AppColors.accentBlue
                      : AppColors.cardBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 36,
                decoration: BoxDecoration(
                  color: node.isBuilt
                      ? region.accentColor
                      : AppColors.textSecondary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      region.label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${region.altitudeMeters}m · ${node.status.label} · ${node.availableProspectCount} U23 · ${node.activeCampRiderCount} Pro',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                node.isBuilt
                    ? Formatters.formatCurrency(node.annualBudgetEur)
                    : 'Zablok.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: node.isBuilt
                      ? AppColors.goldAccent
                      : AppColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProspectCard extends StatelessWidget {
  final SatelliteAcademyProspect prospect;
  final VoidCallback onPromote;

  const _ProspectCard({
    required this.prospect,
    required this.onPromote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  prospect.nationalityIso,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentBlue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${prospect.fullName} (${prospect.age} l.)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'OVR ${prospect.currentOvr} · POT ${prospect.potential}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${prospect.specialization.displayName} · ${prospect.ftpWatts} W (${prospect.wPerKg.toStringAsFixed(2)} W/kg) · VO2 ${prospect.vo2Max.toStringAsFixed(1)} · Pewność ${prospect.scoutingConfidence}%',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          _NetworkActionButton(
            label: 'Awansuj do Kadry Pro',
            icon: Icons.arrow_circle_up_rounded,
            color: AppColors.statusSuccess,
            compact: true,
            onPressed: onPromote,
          ),
        ],
      ),
    );
  }
}

class _TrainingStintCard extends StatelessWidget {
  final ActiveAcademyTrainingStint stint;

  const _TrainingStintCard({required this.stint});

  @override
  Widget build(BuildContext context) {
    final progress = stint.progressRatio;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: stint.isCompleted
              ? AppColors.statusSuccess.withValues(alpha: 0.45)
              : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  stint.riderName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                stint.isCompleted
                    ? 'Ukończono'
                    : '${stint.daysCompleted}/${stint.durationDays} dni',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: stint.isCompleted
                      ? AppColors.statusSuccess
                      : AppColors.accentBlue,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(
                stint.isCompleted
                    ? AppColors.statusSuccess
                    : AppColors.accentBlue,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${stint.intensity.label} · +${stint.altitudeGainPercent.toStringAsFixed(1)}% hipoksja · +${stint.ftpGainWatts.toStringAsFixed(1)} W FTP',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusModeOptionCard extends StatefulWidget {
  final SatelliteAcademyFocusMode mode;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _FocusModeOptionCard({
    required this.mode,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_FocusModeOptionCard> createState() => _FocusModeOptionCardState();
}

class _FocusModeOptionCardState extends State<_FocusModeOptionCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : widget.isSelected
            ? AppColors.goldAccent
            : _focused
                ? AppColors.accentBlue
                : _hovered
                    ? AppColors.textSecondary
                    : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: Opacity(
          opacity: widget.enabled ? 1.0 : 0.48,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.goldAccent.withValues(alpha: 0.10)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(
                  widget.isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 18,
                  color: widget.isSelected
                      ? AppColors.goldAccent
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.mode.label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.mode.description,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
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
    );
  }
}

class _AcademyTabSelector extends StatelessWidget {
  final AcademyNetworkMapTab activeTab;
  final ValueChanged<AcademyNetworkMapTab> onTabSelected;

  const _AcademyTabSelector({
    required this.activeTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final tab in AcademyNetworkMapTab.values)
          _SelectablePillChip(
            label: tab.label,
            icon: tab.icon,
            isSelected: activeTab == tab,
            onTap: () => onTabSelected(tab),
          ),
      ],
    );
  }
}

class _QuickRegionSelectorChip extends StatefulWidget {
  final SatelliteAcademyRegionId region;
  final SatelliteAcademyNode node;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickRegionSelectorChip({
    required this.region,
    required this.node,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_QuickRegionSelectorChip> createState() =>
      _QuickRegionSelectorChipState();
}

class _QuickRegionSelectorChipState extends State<_QuickRegionSelectorChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.node.isBuilt
        ? widget.region.accentColor
        : AppColors.textSecondary;
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? accent.withValues(alpha: 0.16)
                : _hovered
                    ? AppColors.surface
                    : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSelected
                  ? accent
                  : _focused
                      ? AppColors.accentBlue
                      : AppColors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: widget.node.status.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.region.shortLabel,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: widget.isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapLayerToggleChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _MapLayerToggleChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  State<_MapLayerToggleChip> createState() => _MapLayerToggleChipState();
}

class _MapLayerToggleChipState extends State<_MapLayerToggleChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: widget.active
                ? AppColors.accentBlue.withValues(alpha: 0.16)
                : _hovered
                    ? AppColors.surface
                    : AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : widget.active
                      ? AppColors.accentBlue
                      : AppColors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 13,
                color: widget.active
                    ? AppColors.accentBlue
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.active
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapLegendBar extends StatelessWidget {
  final bool isCompact;

  const _MapLegendBar({required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Wrap(
        spacing: 10,
        runSpacing: 4,
        children: [
          _LegendItem(color: AppColors.statusSuccess, label: 'Operacyjna'),
          _LegendItem(color: AppColors.goldAccent, label: 'Elitarna'),
          _LegendItem(color: AppColors.textSecondary, label: 'Niezbudowana'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _HeaderKpiPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _HeaderKpiPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final bool compact;
  final VoidCallback onPressed;

  const _NetworkActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.enabled = true,
    this.compact = false,
    required this.onPressed,
  });

  @override
  State<_NetworkActionButton> createState() => _NetworkActionButtonState();
}

class _NetworkActionButtonState extends State<_NetworkActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown:
            widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp:
            widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onPressed : null,
        child: Opacity(
          opacity: widget.enabled ? 1.0 : 0.42,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 10 : 12,
                vertical: widget.compact ? 7 : 9,
              ),
              decoration: BoxDecoration(
                color: _hovered
                    ? widget.color.withValues(alpha: 0.24)
                    : widget.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _focused
                      ? AppColors.textPrimary
                      : widget.color.withValues(alpha: _hovered ? 0.9 : 0.55),
                  width: _focused ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 15, color: widget.color),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      widget.label,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NetworkIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _NetworkIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<_NetworkIconButton> createState() => _NetworkIconButtonState();
}

class _NetworkIconButtonState extends State<_NetworkIconButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        mouseCursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _hovered ? AppColors.surfaceLight : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused ? AppColors.goldAccent : AppColors.cardBorder,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectablePillChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectablePillChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SelectablePillChip> createState() => _SelectablePillChipState();
}

class _SelectablePillChipState extends State<_SelectablePillChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.goldAccent.withValues(alpha: 0.16)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.goldAccent
                  : _focused
                      ? AppColors.accentBlue
                      : AppColors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 13.5,
                  color: widget.isSelected
                      ? AppColors.goldAccent
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight:
                      widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: widget.isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStatLabel extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStatLabel({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11.5,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.accentBlue),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackNoticeBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const _FeedbackNoticeBanner({
    required this.message,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.crimsonAlert : AppColors.statusSuccess;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAcademyNotice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final bool actionEnabled;
  final VoidCallback? onAction;

  const _EmptyAcademyNotice({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.actionEnabled = true,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            _NetworkActionButton(
              label: actionLabel!,
              icon: Icons.person_add_alt_1_rounded,
              color: AppColors.accentBlue,
              enabled: actionEnabled,
              onPressed: onAction!,
            ),
          ],
        ],
      ),
    );
  }
}
