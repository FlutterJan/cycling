import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../engine/peloton/drafting_grid_system.dart';
import '../../engine/peloton/rider_race_state.dart';
import '../../engine/rendering3d/camera_rig_controller.dart';
import '../../engine/rendering3d/peloton_3d_canvas_engine.dart';
import '../../models/organizer/race_organizer_empire_model.dart';
import '../../models/race/stage_segment.dart';
import '../../services/organizer/course_safety_barriers_and_marshals_planner.dart';
import '../../services/organizer/star_rider_appearance_fee_negotiator.dart';
import '../../state/race_simulation_notifier.dart';

/// Sekcje głównego ekranu Dowództwa Organizatora Wyścigów.
enum OrganizerHqSection {
  overviewAndBroadcast(
    label: 'Przegląd & 3D',
    icon: Icons.live_tv_rounded,
  ),
  hostCityBiddingMap(
    label: 'Mapa Przetargów',
    icon: Icons.map_rounded,
  ),
  tvRightsAndFinance(
    label: 'Prawa TV & Budżet',
    icon: Icons.account_balance_rounded,
  ),
  starsAndSafety(
    label: 'Gwiazdy & Bezpieczeństwo',
    icon: Icons.shield_rounded,
  );

  final String label;
  final IconData icon;

  const OrganizerHqSection({
    required this.label,
    required this.icon,
  });
}

/// Filtr listy ofert przetargowych miast gospodarzy.
enum HostCityBidFilter {
  all('Wszystkie'),
  openOnly('Otwarte'),
  awarded('Przyznane'),
  rejected('Odrzucone');

  final String label;

  const HostCityBidFilter(this.label);
}

/// Znormalizowane współrzędne (0..1) miasta na mapie przetargów Europy.
class HostCityGeoCoordinate {
  final double nx;
  final double ny;
  final String regionLabel;

  const HostCityGeoCoordinate({
    required this.nx,
    required this.ny,
    required this.regionLabel,
  });

  static const Map<String, HostCityGeoCoordinate> _knownCities = {
    'barcelona': HostCityGeoCoordinate(nx: 0.42, ny: 0.77, regionLabel: 'Katalonia, ES'),
    'bilbao': HostCityGeoCoordinate(nx: 0.25, ny: 0.71, regionLabel: 'Kraj Basków, ES'),
    'madrid': HostCityGeoCoordinate(nx: 0.22, ny: 0.84, regionLabel: 'Madryt, ES'),
    'alpe d\'huez': HostCityGeoCoordinate(nx: 0.56, ny: 0.56, regionLabel: 'Alpy, FR'),
    'grenoble': HostCityGeoCoordinate(nx: 0.54, ny: 0.54, regionLabel: 'Isère, FR'),
    'paris': HostCityGeoCoordinate(nx: 0.43, ny: 0.34, regionLabel: 'Île-de-France, FR'),
    'nice': HostCityGeoCoordinate(nx: 0.58, ny: 0.65, regionLabel: 'Lazurowe Wybrzeże, FR'),
    'roubaix': HostCityGeoCoordinate(nx: 0.47, ny: 0.23, regionLabel: 'Haut-de-France, FR'),
    'lille': HostCityGeoCoordinate(nx: 0.46, ny: 0.24, regionLabel: 'Flandria FR, FR'),
    'copenhagen': HostCityGeoCoordinate(nx: 0.68, ny: 0.12, regionLabel: 'Zelandia, DK'),
    'florence': HostCityGeoCoordinate(nx: 0.71, ny: 0.67, regionLabel: 'Toskania, IT'),
    'siena': HostCityGeoCoordinate(nx: 0.72, ny: 0.70, regionLabel: 'Toskania, IT'),
    'milan': HostCityGeoCoordinate(nx: 0.66, ny: 0.58, regionLabel: 'Lombardia, IT'),
    'antwerp': HostCityGeoCoordinate(nx: 0.49, ny: 0.20, regionLabel: 'Flandria, BE'),
    'oudenaarde': HostCityGeoCoordinate(nx: 0.47, ny: 0.21, regionLabel: 'Flandria, BE'),
    'utrecht': HostCityGeoCoordinate(nx: 0.51, ny: 0.17, regionLabel: 'Holandia, NL'),
    'london': HostCityGeoCoordinate(nx: 0.36, ny: 0.20, regionLabel: 'Wielka Brytania, UK'),
  };

  static HostCityGeoCoordinate resolve(String cityName, String countryCode) {
    final normalized = cityName.trim().toLowerCase();
    for (final entry in _knownCities.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        return entry.value;
      }
    }
    switch (countryCode.toUpperCase()) {
      case 'FR':
        return const HostCityGeoCoordinate(nx: 0.47, ny: 0.46, regionLabel: 'Francja');
      case 'ES':
        return const HostCityGeoCoordinate(nx: 0.27, ny: 0.78, regionLabel: 'Hiszpania');
      case 'IT':
        return const HostCityGeoCoordinate(nx: 0.70, ny: 0.65, regionLabel: 'Włochy');
      case 'BE':
        return const HostCityGeoCoordinate(nx: 0.48, ny: 0.21, regionLabel: 'Belgia');
      case 'NL':
        return const HostCityGeoCoordinate(nx: 0.51, ny: 0.17, regionLabel: 'Holandia');
      case 'DK':
        return const HostCityGeoCoordinate(nx: 0.67, ny: 0.13, regionLabel: 'Dania');
      case 'CH':
        return const HostCityGeoCoordinate(nx: 0.60, ny: 0.50, regionLabel: 'Szwajcaria');
      default:
        return const HostCityGeoCoordinate(nx: 0.52, ny: 0.42, regionLabel: 'Europa');
    }
  }
}

/// Stan ekranu głównego Organizatora Wyścigów.
class RaceOrganizerHqState {
  final RaceOrganizerEmpireModel empire;
  final String? selectedRaceId;
  final String? selectedBidId;
  final OrganizerHqSection activeSection;
  final HostCityBidFilter bidFilter;
  final int contractLengthYears;
  final RaceCameraMode cameraMode;
  final bool isBroadcastPlaying;
  final String? statusBannerMessage;
  final bool isLastActionSuccess;
  final bool isReadOnly;

  const RaceOrganizerHqState({
    required this.empire,
    this.selectedRaceId,
    this.selectedBidId,
    this.activeSection = OrganizerHqSection.overviewAndBroadcast,
    this.bidFilter = HostCityBidFilter.all,
    this.contractLengthYears = 1,
    this.cameraMode = RaceCameraMode.heliCam,
    this.isBroadcastPlaying = true,
    this.statusBannerMessage,
    this.isLastActionSuccess = true,
    this.isReadOnly = false,
  });

  ManagedRacePortfolioItem? get selectedRace {
    if (empire.managedRaces.isEmpty) return null;
    if (selectedRaceId == null) return empire.managedRaces.first;
    return empire.managedRaces.cast<ManagedRacePortfolioItem?>().firstWhere(
          (r) => r?.raceId == selectedRaceId,
          orElse: () => empire.managedRaces.first,
        );
  }

  HostCityBid? get selectedBid {
    if (empire.pendingHostCityBids.isEmpty) return null;
    if (selectedBidId == null) return empire.pendingHostCityBids.first;
    return empire.pendingHostCityBids.cast<HostCityBid?>().firstWhere(
          (b) => b?.bidId == selectedBidId,
          orElse: () => empire.pendingHostCityBids.first,
        );
  }

  List<HostCityBid> get filteredBids {
    return empire.pendingHostCityBids.where((bid) {
      switch (bidFilter) {
        case HostCityBidFilter.all:
          return true;
        case HostCityBidFilter.openOnly:
          return bid.status.isActiveForDecision;
        case HostCityBidFilter.awarded:
          return bid.status == HostBidStatus.awarded;
        case HostCityBidFilter.rejected:
          return bid.status == HostBidStatus.rejected ||
              bid.status == HostBidStatus.expired ||
              bid.status == HostBidStatus.withdrawn;
      }
    }).toList(growable: false);
  }

  RaceOrganizerHqState copyWith({
    RaceOrganizerEmpireModel? empire,
    String? selectedRaceId,
    bool clearSelectedRace = false,
    String? selectedBidId,
    bool clearSelectedBid = false,
    OrganizerHqSection? activeSection,
    HostCityBidFilter? bidFilter,
    int? contractLengthYears,
    RaceCameraMode? cameraMode,
    bool? isBroadcastPlaying,
    String? statusBannerMessage,
    bool clearStatusBanner = false,
    bool? isLastActionSuccess,
    bool? isReadOnly,
  }) {
    return RaceOrganizerHqState(
      empire: empire ?? this.empire,
      selectedRaceId:
          clearSelectedRace ? null : (selectedRaceId ?? this.selectedRaceId),
      selectedBidId:
          clearSelectedBid ? null : (selectedBidId ?? this.selectedBidId),
      activeSection: activeSection ?? this.activeSection,
      bidFilter: bidFilter ?? this.bidFilter,
      contractLengthYears: contractLengthYears ?? this.contractLengthYears,
      cameraMode: cameraMode ?? this.cameraMode,
      isBroadcastPlaying: isBroadcastPlaying ?? this.isBroadcastPlaying,
      statusBannerMessage: clearStatusBanner
          ? null
          : (statusBannerMessage ?? this.statusBannerMessage),
      isLastActionSuccess: isLastActionSuccess ?? this.isLastActionSuccess,
      isReadOnly: isReadOnly ?? this.isReadOnly,
    );
  }
}

/// Kontroler stanu ekranu Organizatora Wyścigów.
class RaceOrganizerHqNotifier extends StateNotifier<RaceOrganizerHqState> {
  RaceOrganizerHqNotifier({
    RaceOrganizerEmpireModel? initialEmpire,
    bool isReadOnly = false,
  }) : super(_createInitialState(initialEmpire, isReadOnly));

  static RaceOrganizerHqState _createInitialState(
    RaceOrganizerEmpireModel? initialEmpire,
    bool isReadOnly,
  ) {
    final empire =
        initialEmpire ?? RaceOrganizerEmpireModel.createStarterAsoPreset();
    return RaceOrganizerHqState(
      empire: empire,
      selectedRaceId:
          empire.managedRaces.isNotEmpty ? empire.managedRaces.first.raceId : null,
      selectedBidId: empire.pendingHostCityBids.isNotEmpty
          ? empire.pendingHostCityBids.first.bidId
          : null,
      isReadOnly: isReadOnly,
    );
  }

  void setEmpire(RaceOrganizerEmpireModel empire, {bool? isReadOnly}) {
    state = state.copyWith(
      empire: empire,
      selectedRaceId:
          empire.managedRaces.isNotEmpty ? empire.managedRaces.first.raceId : null,
      clearSelectedRace: empire.managedRaces.isEmpty,
      selectedBidId: empire.pendingHostCityBids.isNotEmpty
          ? empire.pendingHostCityBids.first.bidId
          : null,
      clearSelectedBid: empire.pendingHostCityBids.isEmpty,
      isReadOnly: isReadOnly,
      clearStatusBanner: true,
    );
  }

  void selectRace(String raceId) {
    state = state.copyWith(selectedRaceId: raceId, clearStatusBanner: true);
  }

  void selectBid(String? bidId) {
    state = state.copyWith(
      selectedBidId: bidId,
      clearSelectedBid: bidId == null,
      clearStatusBanner: true,
    );
  }

  void setSection(OrganizerHqSection section) {
    state = state.copyWith(activeSection: section);
  }

  void setBidFilter(HostCityBidFilter filter) {
    state = state.copyWith(bidFilter: filter);
  }

  void setContractLengthYears(int years) {
    state = state.copyWith(contractLengthYears: years.clamp(1, 3));
  }

  void setCameraMode(RaceCameraMode mode) {
    state = state.copyWith(cameraMode: mode);
  }

  void toggleBroadcastPlayback() {
    state = state.copyWith(isBroadcastPlaying: !state.isBroadcastPlaying);
  }

  void dismissStatusBanner() {
    state = state.copyWith(clearStatusBanner: true);
  }

  void awardSelectedBid() {
    if (state.isReadOnly) return;
    final bid = state.selectedBid;
    if (bid == null) return;
    final result = state.empire.awardHostCityBid(
      bid.bidId,
      contractLengthYears: state.contractLengthYears,
    );
    state = state.copyWith(
      empire: result.updatedEmpire,
      statusBannerMessage: result.message,
      isLastActionSuccess: result.success,
    );
  }

  void rejectSelectedBid() {
    if (state.isReadOnly) return;
    final bid = state.selectedBid;
    if (bid == null) return;
    final result = state.empire.rejectHostCityBid(bid.bidId);
    state = state.copyWith(
      empire: result.updatedEmpire,
      statusBannerMessage: result.message,
      isLastActionSuccess: result.success,
    );
  }

  void signNewTvPackage({
    required TvBroadcastTier tier,
    required TvRightsTerritory territory,
  }) {
    if (state.isReadOnly) return;
    final race = state.selectedRace;
    if (race == null) return;
    final contract = TvRightsContract(
      contractId: 'tv_${race.raceId}_${territory.name}_${state.empire.seasonYear}',
      raceId: race.raceId,
      broadcasterName: _broadcasterNameFor(territory, tier),
      territory: territory,
      tier: tier,
      status: TvContractStatus.active,
      annualRightsFeeEur: _feeForPackage(race.tier, tier),
      viewershipBonusPerMillionEur: 220000,
      estimatedAvgViewersMillions: race.tier.isWorldTour ? 2.4 : 0.9,
      minimumLiveHoursPerStage: math.max(race.tier.minLiveTvHoursPerStage, 3.5),
      helicopterRelayRequired: true,
      onboardCamerasRequired: tier == TvBroadcastTier.globalStreamingOtt ||
          tier == TvBroadcastTier.hostBroadcasterFeed,
      startSeasonYear: state.empire.seasonYear,
      durationYears: 3,
      remainingYears: 3,
    );
    final result = state.empire.signTvRightsContract(contract);
    state = state.copyWith(
      empire: result.updatedEmpire,
      statusBannerMessage: result.message,
      isLastActionSuccess: result.success,
    );
  }

  void advanceSeason() {
    if (state.isReadOnly) return;
    final nextEmpire = state.empire.advanceSeasonFinancials();
    state = state.copyWith(
      empire: nextEmpire,
      statusBannerMessage:
          'Zamknięto rok budżetowy. Rozpoczęto sezon ${nextEmpire.seasonYear}.',
      isLastActionSuccess: true,
    );
  }

  static String _broadcasterNameFor(
    TvRightsTerritory territory,
    TvBroadcastTier tier,
  ) {
    switch (territory) {
      case TvRightsTerritory.europeCore:
        return 'Eurosport / Discovery+ Europe';
      case TvRightsTerritory.franceBenelux:
        return tier == TvBroadcastTier.freeToAirNational
            ? 'France TV / Sporza'
            : 'EuroCycling+ Benelux';
      case TvRightsTerritory.italySpain:
        return 'RAI Sport / RTVE Teledeporte';
      case TvRightsTerritory.northAmerica:
        return 'Peacock / NBC Cycling';
      case TvRightsTerritory.asiaPacific:
        return 'J Sports / SBS Cycling';
      case TvRightsTerritory.latinAmerica:
        return 'ESPN / Claro Sports LatAm';
      case TvRightsTerritory.globalWorldwide:
        return 'UCI WorldStream OTT';
    }
  }

  static int _feeForPackage(
    UciRaceClassificationTier raceTier,
    TvBroadcastTier broadcastTier,
  ) {
    final base = raceTier == UciRaceClassificationTier.grandTour
        ? 4800000
        : (raceTier.isWorldTour ? 1450000 : 420000);
    return (base * broadcastTier.sponsorReachMultiplier).round();
  }
}

/// Provider stanu ekranu Organizatora Wyścigów.
final raceOrganizerHqProvider =
    StateNotifierProvider<RaceOrganizerHqNotifier, RaceOrganizerHqState>(
  (ref) => RaceOrganizerHqNotifier(),
);

/// Główny ekran trybu Organizatora Wyścigów z mapą przetargów miast i transmisją 3D własnego wyścigu.
class RaceOrganizerHqDashboardScreen extends ConsumerStatefulWidget {
  final RaceOrganizerEmpireModel? initialEmpire;
  final bool isReadOnly;
  final VoidCallback? onBack;

  const RaceOrganizerHqDashboardScreen({
    super.key,
    this.initialEmpire,
    this.isReadOnly = false,
    this.onBack,
  });

  @override
  ConsumerState<RaceOrganizerHqDashboardScreen> createState() =>
      _RaceOrganizerHqDashboardScreenState();
}

class _RaceOrganizerHqDashboardScreenState
    extends ConsumerState<RaceOrganizerHqDashboardScreen> {
  late final Peloton3dCanvasEngine _broadcastEngine;
  late List<RiderPositionSnapshot> _broadcastSnapshots;
  late StageSegment _broadcastSegment;
  late String _broadcastSegmentLabel;

  @override
  void initState() {
    super.initState();
    _broadcastEngine = Peloton3dCanvasEngine(
      cameraRig: CameraRigController(initialMode: RaceCameraMode.heliCam),
    );
    _broadcastSegmentLabel = 'Col de la Madeleine (HC)';
    _broadcastSegment = _buildShowcaseSegment('Tour de France');
    _broadcastSnapshots = _buildBroadcastSnapshots('race_grande_boucle_2uwt');

    if (widget.initialEmpire != null || widget.isReadOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final notifier = ref.read(raceOrganizerHqProvider.notifier);
        notifier.setEmpire(
          widget.initialEmpire ?? RaceOrganizerEmpireModel.createStarterAsoPreset(),
          isReadOnly: widget.isReadOnly,
        );
      });
    }
  }

  StageSegment _buildShowcaseSegment(String raceName) {
    final isMountain = raceName.toLowerCase().contains('tour') ||
        raceName.toLowerCase().contains('dauphin');
    _broadcastSegmentLabel =
        isMountain ? 'Col de la Madeleine (HC)' : 'Sektor Finałowy';
    return StageSegment(
      index: 0,
      startKm: 142.0,
      lengthKm: 26.0,
      startElevationM: isMountain ? 520.0 : 120.0,
      endElevationM: isMountain ? 2000.0 : 185.0,
      surfaceType: SegmentSurfaceType.smoothAsphalt,
      technicalDifficulty: isMountain ? 62.0 : 35.0,
      windDirectionDegrees: 225.0,
      roadBearingDegrees: 90.0,
      sprintOrKomClassification: isMountain
          ? SegmentClassification.horsCategorie
          : SegmentClassification.none,
    );
  }

  List<RiderPositionSnapshot> _buildBroadcastSnapshots(String raceId) {
    final seed = raceId.hashCode.abs() % 100;
    const jerseyColors = [
      '#D4AF37',
      '#8E4A49',
      '#38BDF8',
      '#10B981',
      '#F59E0B',
      '#E5E7EB',
    ];
    final riders = <RiderPositionSnapshot>[];
    for (var i = 0; i < 20; i++) {
      final isBreakaway = i < 4;
      final baseDist = isBreakaway ? 14850.0 - i * 4.5 : 14680.0 - i * 3.2;
      final lateral = ((i % 5) - 2) * 0.38;
      riders.add(
        RiderPositionSnapshot(
          riderId: 'org_rider_${seed}_$i',
          riderName: isBreakaway ? 'Atakujący #${i + 1}' : 'Peleton #${i + 1}',
          bibNumber: i + 1,
          teamId: 'team_${i % 6}',
          teamName: 'Pro Team ${(i % 6) + 1}',
          teamJerseyHexColor: jerseyColors[i % jerseyColors.length],
          isPlayerRider: i == 0,
          distanceCoveredMeters: baseDist,
          kilometerMark: baseDist / 1000.0,
          elevationMeters: 1420.0 + (i < 4 ? 18.0 : 0.0),
          currentGradientPercent: 7.4,
          currentSegmentIndex: 0,
          speedMs: isBreakaway ? 7.6 : 7.2,
          speedKmh: isBreakaway ? 27.4 : 25.9,
          powerWatts: isBreakaway ? 415 : 355,
          wattsPerKg: isBreakaway ? 6.2 : 5.3,
          cadenceRpm: 84,
          heartRateBpm: isBreakaway ? 178 : 164,
          wPrimePercentage: 0.78,
          wPrimeJoules: 16500,
          glycogenPercentage: 0.72,
          glycogenGrams: 340,
          hydrationPercent: 0.85,
          bidonsLeft: 2,
          gelsLeft: 3,
          activeTacticalOrder:
              isBreakaway ? TacticalOrder.attack : TacticalOrder.holdPosition,
          groupIndex: isBreakaway ? 0 : 1,
          groupType: isBreakaway ? GroupType.breakaway : GroupType.peloton,
          timeGapToLeaderSeconds: isBreakaway ? i * 1.1 : 34.0 + i * 0.4,
          lateralPositionRoad: lateral.clamp(-1.0, 1.0),
          lateralOffsetRoadMeters: lateral * 2.4,
          isDrafting: i > 0,
          draftingSavingsPercent: i > 0 ? 28.0 : 0.0,
          isPulling: i == 0 || i == 4,
        ),
      );
    }
    return riders;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(raceOrganizerHqProvider);
    final notifier = ref.read(raceOrganizerHqProvider.notifier);

    ref.listen<RaceOrganizerHqState>(raceOrganizerHqProvider, (prev, next) {
      if (prev?.cameraMode != next.cameraMode) {
        _broadcastEngine.switchCameraMode(next.cameraMode);
      }
      if (prev?.selectedRaceId != next.selectedRaceId &&
          next.selectedRace != null) {
        setState(() {
          _broadcastSegment = _buildShowcaseSegment(next.selectedRace!.raceName);
          _broadcastSnapshots =
              _buildBroadcastSnapshots(next.selectedRace!.raceId);
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 700;
            final isDesktop = width >= 1250;

            return Column(
              children: [
                _buildTopHeader(context, state, notifier, isMobile),
                if (state.statusBannerMessage != null)
                  _buildStatusBanner(state, notifier),
                _buildSectionNavBar(state, notifier, isMobile),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 12 : 20),
                    child: _buildActiveContent(
                      context,
                      state,
                      notifier,
                      isMobile: isMobile,
                      isDesktop: isDesktop,
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

  Widget _buildTopHeader(
    BuildContext context,
    RaceOrganizerHqState state,
    RaceOrganizerHqNotifier notifier,
    bool isMobile,
  ) {
    final empire = state.empire;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.onBack != null) ...[
                _OrganizerInteractiveIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Powrót',
                  onTap: widget.onBack,
                ),
                const SizedBox(width: 10),
              ],
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.45),
                  ),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.goldAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      empire.syndicateName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _StatusPill(
                          label: empire.archetype.displayNamePl,
                          color: AppColors.goldAccent,
                        ),
                        _StatusPill(
                          label: 'Sezon ${empire.seasonYear}',
                          color: AppColors.accentBlue,
                        ),
                        if (state.isReadOnly)
                          const _StatusPill(
                            label: 'Tylko Podgląd',
                            color: AppColors.amberWarning,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 12),
                _OrganizerActionButton(
                  label: 'Zamknij Rok (${empire.seasonYear})',
                  icon: Icons.fast_forward_rounded,
                  isPrimary: true,
                  disabled: state.isReadOnly,
                  onTap: notifier.advanceSeason,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _HeaderKpiTile(
                label: 'Gotówka Operacyjna',
                value: Formatters.formatCurrency(empire.budgetLedger.liquidCashEur),
                accent: AppColors.statusSuccess,
              ),
              _HeaderKpiTile(
                label: 'Wycena Imperium',
                value: Formatters.formatCurrency(empire.empireValuationEur),
                accent: AppColors.goldAccent,
              ),
              _HeaderKpiTile(
                label: 'Przychód TV / rok',
                value: Formatters.formatCurrency(empire.totalAnnualTvRevenueEur),
                accent: AppColors.accentBlue,
              ),
              _HeaderKpiTile(
                label: 'Wpływy UCI / WT',
                value:
                    '${empire.uciBoardInfluence.toStringAsFixed(0)} pkt • ${empire.worldTourRaceCount} WT',
                accent: AppColors.primaryAccent,
              ),
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: _OrganizerActionButton(
                label: 'Zamknij Rok (${empire.seasonYear})',
                icon: Icons.fast_forward_rounded,
                isPrimary: true,
                disabled: state.isReadOnly,
                onTap: notifier.advanceSeason,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBanner(
    RaceOrganizerHqState state,
    RaceOrganizerHqNotifier notifier,
  ) {
    final color = state.isLastActionSuccess
        ? AppColors.statusSuccess
        : AppColors.crimsonAlert;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        border: Border(
          bottom: BorderSide(color: color.withValues(alpha: 0.45)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            state.isLastActionSuccess
                ? Icons.check_circle_outline_rounded
                : Icons.error_outline_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              state.statusBannerMessage ?? '',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _OrganizerInteractiveIconButton(
            icon: Icons.close_rounded,
            tooltip: 'Zamknij komunikat',
            onTap: notifier.dismissStatusBanner,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionNavBar(
    RaceOrganizerHqState state,
    RaceOrganizerHqNotifier notifier,
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: OrganizerHqSection.values.map((section) {
            final selected = state.activeSection == section;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _OrganizerFilterChip(
                label: section.label,
                icon: section.icon,
                selected: selected,
                onTap: () => notifier.setSection(section),
              ),
            );
          }).toList(growable: false),
        ),
      ),
    );
  }

  Widget _buildActiveContent(
    BuildContext context,
    RaceOrganizerHqState state,
    RaceOrganizerHqNotifier notifier, {
    required bool isMobile,
    required bool isDesktop,
  }) {
    switch (state.activeSection) {
      case OrganizerHqSection.overviewAndBroadcast:
        return _buildOverviewAndBroadcastSection(
          context,
          state,
          notifier,
          isMobile: isMobile,
          isDesktop: isDesktop,
        );
      case OrganizerHqSection.hostCityBiddingMap:
        return _buildHostCityBiddingSection(
          context,
          state,
          notifier,
          isMobile: isMobile,
          isDesktop: isDesktop,
        );
      case OrganizerHqSection.tvRightsAndFinance:
        return _buildTvAndFinanceSection(
          context,
          state,
          notifier,
          isMobile: isMobile,
        );
      case OrganizerHqSection.starsAndSafety:
        return _buildStarsAndSafetySection(isMobile: isMobile);
    }
  }

  Widget _buildOverviewAndBroadcastSection(
    BuildContext context,
    RaceOrganizerHqState state,
    RaceOrganizerHqNotifier notifier, {
    required bool isMobile,
    required bool isDesktop,
  }) {
    final broadcastCard = _buildLive3dBroadcastCard(state, notifier, isMobile);
    final portfolioCard = _buildRacePortfolioCard(state, notifier);
    final prestigeCard = _buildUciPrestigeCard(state);
    final quickMapCard = _buildHostCityMapCard(
      state,
      notifier,
      compact: true,
    );

    if (isDesktop) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: broadcastCard),
              const SizedBox(width: 16),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    portfolioCard,
                    const SizedBox(height: 16),
                    prestigeCard,
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          quickMapCard,
        ],
      );
    }

    return Column(
      children: [
        broadcastCard,
        const SizedBox(height: 14),
        portfolioCard,
        const SizedBox(height: 14),
        prestigeCard,
        const SizedBox(height: 14),
        quickMapCard,
      ],
    );
  }

  Widget _buildLive3dBroadcastCard(
    RaceOrganizerHqState state,
    RaceOrganizerHqNotifier notifier,
    bool isMobile,
  ) {
    final race = state.selectedRace;
    final hasHeliRelay = race?.tvRightsContracts.any(
          (c) => c.isActive && c.helicopterRelayRequired,
        ) ??
        false;
    final viewersM = race?.tvRightsContracts.fold<double>(
          0.0,
          (sum, c) => sum + (c.isActive ? c.estimatedAvgViewersMillions : 0.0),
        ) ??
        0.0;

    return _SectionCard(
      title: 'Transmisja 3D Własnego Wyścigu',
      subtitle: race != null
          ? '${race.raceName} • ${race.tier.uciCode} • $_broadcastSegmentLabel'
          : 'Brak aktywnego wyścigu w portfolio',
      trailing: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _StatusPill(
            label: state.isBroadcastPlaying ? 'LIVE 3D' : 'PAUZA',
            color: state.isBroadcastPlaying
                ? AppColors.crimsonAlert
                : AppColors.amberWarning,
          ),
          _OrganizerActionButton(
            label: state.isBroadcastPlaying ? 'Wstrzymaj' : 'Wznów 3D',
            icon: state.isBroadcastPlaying
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            onTap: notifier.toggleBroadcastPlayback,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: isMobile ? 230 : 320,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: state.isBroadcastPlaying
                        ? Peloton3dViewportWidget(
                            engine: _broadcastEngine,
                            snapshots: _broadcastSnapshots,
                            focusRiderId: _broadcastSnapshots.first.riderId,
                            activeSegment: _broadcastSegment,
                            windSpeedKmh: 18.0,
                            showCameraControls: false,
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: CustomPaint(
                              painter: Peloton3dCanvasPainter(
                                engine: _broadcastEngine,
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: state.isBroadcastPlaying
                                ? AppColors.crimsonAlert
                                : AppColors.amberWarning,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          race != null
                              ? '${race.raceName.toUpperCase()} • KM 148.5'
                              : 'SYGNAŁ TESTOWY',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.goldAccent.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      'Widownia: ${viewersM.toStringAsFixed(1)}M • ${hasHeliRelay ? 'Heli-Relay ON' : 'Naziemna'}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldAccent,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Kamera Realizatora:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              ...RaceCameraMode.values.map((mode) {
                return _OrganizerFilterChip(
                  label: mode.shortLabel,
                  selected: state.cameraMode == mode,
                  onTap: () => notifier.setCameraMode(mode),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRacePortfolioCard(
    RaceOrganizerHqState state,
    RaceOrganizerHqNotifier notifier,
  ) {
    final races = state.empire.managedRaces;
    return _SectionCard(
      title: 'Portfolio Wyścigów',
      subtitle: '${races.length} zarządzane imprezy w kalendarzu UCI',
      child: races.isEmpty
          ? const _EmptyPlaceholderBox(
              icon: Icons.directions_bike_rounded,
              message: 'Brak wyścigów w portfolio organizatora.',
            )
          : Column(
              children: races.map((race) {
                final selected = state.selectedRace?.raceId == race.raceId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SelectableRaceTile(
                    race: race,
                    selected: selected,
                    onTap: () => notifier.selectRace(race.raceId),
                  ),
                );
              }).toList(growable: false),
            ),
    );
  }

  Widget _buildUciPrestigeCard(RaceOrganizerHqState state) {
    final race = state.selectedRace;
    if (race == null) {
      return const _SectionCard(
        title: 'Audyt Prestiżu UCI',
        subtitle: 'Wybierz wyścig z portfolio',
        child: _EmptyPlaceholderBox(
          icon: Icons.verified_rounded,
          message: 'Brak wybranego wyścigu do oceny UCI.',
        ),
      );
    }

    final assessment = race.evaluateUciPrestige();
    return _SectionCard(
      title: 'Audyt Prestiżu UCI (${race.tier.uciCode})',
      subtitle: 'Ocena licencyjna i wymogi awansu',
      trailing: _StatusPill(
        label: assessment.promotionEligible
            ? 'Awans Możliwy'
            : (assessment.relegationRisk ? 'Ryzyko Spadku' : 'Stabilny'),
        color: assessment.promotionEligible
            ? AppColors.statusSuccess
            : (assessment.relegationRisk
                ? AppColors.crimsonAlert
                : AppColors.accentBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _ProgressScoreBar(
                  label: 'Wynik Prestiżu',
                  value: assessment.calculatedPrestigeScore,
                  color: AppColors.goldAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProgressScoreBar(
                  label: 'Bezpieczeństwo',
                  value: race.safetyRatingScore,
                  color: AppColors.statusSuccess,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _ComplianceChip(
                label: 'Pula nagród: ${Formatters.formatCurrency(race.prizePoolEur)}',
                ok: assessment.meetsPrizePoolRequirement,
              ),
              _ComplianceChip(
                label: 'TV: ${race.maxLiveTvHoursOffered.toStringAsFixed(1)}h / etap',
                ok: assessment.meetsTvCoverageRequirement,
              ),
            ],
          ),
          if (assessment.complianceNotes.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...assessment.complianceNotes.map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $note',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.amberWarning,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHostCityBiddingSection(
    BuildContext context,
    RaceOrganizerHqState state,
    RaceOrganizerHqNotifier notifier, {
    required bool isMobile,
    required bool isDesktop,
  }) {
    final mapCard = _buildHostCityMapCard(state, notifier, compact: false);
    final inspectorCard = _buildHostBidInspectorCard(state, notifier);

    if (isDesktop || !isMobile) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: mapCard),
          const SizedBox(width: 16),
          Expanded(flex: 5, child: inspectorCard),
        ],
      );
    }

    return Column(
      children: [
        mapCard,
        const SizedBox(height: 14),
        inspectorCard,
      ],
    );
  }

  Widget _buildHostCityMapCard(
    RaceOrganizerHqState state,
    RaceOrganizerHqNotifier notifier, {
    required bool compact,
  }) {
    final bids = state.filteredBids;
    final contracts = state.empire.managedRaces
        .expand((r) => r.hostCityContracts)
        .toList(growable: false);

    return _SectionCard(
      title: 'Mapa Przetargów Miast Gospodarzy',
      subtitle:
          '${bids.length} ofert w widoku • ${contracts.length} podpisanych kontraktów miast',
      trailing: compact
          ? _OrganizerActionButton(
              label: 'Pełna Mapa',
              icon: Icons.open_in_full_rounded,
              onTap: () =>
                  notifier.setSection(OrganizerHqSection.hostCityBiddingMap),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HostCityBidFilter.values.map((filter) {
              return _OrganizerFilterChip(
                label: filter.label,
                selected: state.bidFilter == filter,
                onTap: () => notifier.setBidFilter(filter),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, mapConstraints) {
              final mapWidth = mapConstraints.maxWidth;
              final mapHeight = compact ? 230.0 : 320.0;
              return GestureDetector(
                onTapDown: (details) {
                  _handleMapTap(
                    details.localPosition,
                    Size(mapWidth, mapHeight),
                    bids,
                    notifier,
                  );
                },
                child: Container(
                  height: mapHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CustomPaint(
                      painter: HostCityBiddingMapPainter(
                        bids: bids,
                        contracts: contracts,
                        selectedBidId: state.selectedBid?.bidId,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _MapLegendItem(color: AppColors.goldAccent, label: 'Otwarty Przetarg'),
              _MapLegendItem(color: AppColors.statusSuccess, label: 'Kontrakt Podpisany'),
              _MapLegendItem(color: AppColors.textSecondary, label: 'Odrzucony'),
            ],
          ),
          if (bids.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: bids.map((bid) {
                final isSelected = state.selectedBid?.bidId == bid.bidId;
                return _OrganizerFilterChip(
                  label:
                      '${bid.cityName} (${bid.countryCode}) • ${Formatters.formatCurrency(bid.bidFeeEur)}',
                  selected: isSelected,
                  onTap: () => notifier.selectBid(bid.bidId),
                );
              }).toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }

  void _handleMapTap(
    Offset localPos,
    Size size,
    List<HostCityBid> bids,
    RaceOrganizerHqNotifier notifier,
  ) {
    HostCityBid? closest;
    double bestDist = 34.0;
    for (final bid in bids) {
      final coord = HostCityGeoCoordinate.resolve(bid.cityName, bid.countryCode);
      final pinPos = Offset(coord.nx * size.width, coord.ny * size.height);
      final dist = (pinPos - localPos).distance;
      if (dist < bestDist) {
        bestDist = dist;
        closest = bid;
      }
    }
    if (closest != null) {
      notifier.selectBid(closest.bidId);
    }
  }

  Widget _buildHostBidInspectorCard(
    RaceOrganizerHqState state,
    RaceOrganizerHqNotifier notifier,
  ) {
    final bid = state.selectedBid;
    if (bid == null) {
      return const _SectionCard(
        title: 'Inspektor Oferty Miasta',
        subtitle: 'Wybierz pinezkę na mapie lub z listy',
        child: _EmptyPlaceholderBox(
          icon: Icons.location_city_rounded,
          message: 'Brak aktywnych ofert przetargowych spełniających filtr.',
        ),
      );
    }

    final canDecide = !state.isReadOnly && bid.status.isActiveForDecision;
    return _SectionCard(
      title: '${bid.cityName} (${bid.countryCode})',
      subtitle: '${bid.regionName} • Etap ${bid.targetStageNumber} • ${bid.role.displayNamePl}',
      trailing: _StatusPill(
        label: _bidStatusLabel(bid.status),
        color: _bidStatusColor(bid.status),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _HeaderKpiTile(
                label: 'Opłata Miasta',
                value: Formatters.formatCurrency(bid.bidFeeEur),
                accent: AppColors.goldAccent,
              ),
              _HeaderKpiTile(
                label: 'Wartość Łączna',
                value: Formatters.formatCurrency(bid.totalEconomicValueEur),
                accent: AppColors.statusSuccess,
              ),
              _HeaderKpiTile(
                label: 'Ocena Oferty',
                value: '${bid.compositeBidScore.toStringAsFixed(1)} / 100',
                accent: AppColors.accentBlue,
              ),
              _HeaderKpiTile(
                label: 'Kibice (prognoza)',
                value: '${(bid.crowdTurnoutForecast / 1000).toStringAsFixed(0)} tys.',
                accent: AppColors.primaryAccent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ProgressScoreBar(
            label: 'Dopasowanie Trasy (${bid.terrainFitScore.toStringAsFixed(0)}/100)',
            value: bid.terrainFitScore,
            color: AppColors.accentBlue,
          ),
          const SizedBox(height: 12),
          const Text(
            'Długość Kontraktu Miasta:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [1, 2, 3].map((years) {
              return _OrganizerFilterChip(
                label: '$years ${years == 1 ? 'rok' : 'lata'}',
                selected: state.contractLengthYears == years,
                disabled: !canDecide,
                onTap: () => notifier.setContractLengthYears(years),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _OrganizerActionButton(
                label: 'Przyznaj Przetarg',
                icon: Icons.gavel_rounded,
                isPrimary: true,
                disabled: !canDecide,
                onTap: notifier.awardSelectedBid,
              ),
              _OrganizerActionButton(
                label: 'Odrzuć Ofertę',
                icon: Icons.close_rounded,
                disabled: !canDecide,
                onTap: notifier.rejectSelectedBid,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTvAndFinanceSection(
    BuildContext context,
    RaceOrganizerHqState state,
    RaceOrganizerHqNotifier notifier, {
    required bool isMobile,
  }) {
    final race = state.selectedRace;
    final ledger = state.empire.budgetLedger;
    final contracts = race?.tvRightsContracts ?? const <TvRightsContract>[];

    return Column(
      children: [
        _SectionCard(
          title: 'Kontrakty Praw Telewizyjnych (${race?.raceName ?? 'Brak'})',
          subtitle: 'Dystrybucja sygnału HD/4K, helikopter transmisyjny i kamery pokładowe',
          trailing: _OrganizerActionButton(
            label: 'Podpisz Pakiet Pan-EU',
            icon: Icons.tv_rounded,
            isPrimary: true,
            disabled: state.isReadOnly || race == null,
            onTap: () => notifier.signNewTvPackage(
              tier: TvBroadcastTier.panContinentalSports,
              territory: TvRightsTerritory.europeCore,
            ),
          ),
          child: contracts.isEmpty
              ? const _EmptyPlaceholderBox(
                  icon: Icons.tv_off_rounded,
                  message: 'Brak aktywnych kontraktów TV dla wybranego wyścigu.',
                )
              : Column(
                  children: contracts.map((c) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.podcasts_rounded,
                            color: AppColors.accentBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.broadcasterName,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${c.minimumLiveHoursPerStage.toStringAsFixed(1)}h/etap • Pozostało ${c.remainingYears} lat',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${Formatters.formatCurrency(c.totalProjectedAnnualRevenueEur)}/rok',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldAccent,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(growable: false),
                ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Księga Przepływów Organizatora',
          subtitle:
              'Rezerwa: ${Formatters.formatCurrency(ledger.reserveFundEur)} • Koszty stałe: ${Formatters.formatCurrency(ledger.annualOperatingOverheadEur)}/rok',
          child: ledger.recentTransactions.isEmpty
              ? const _EmptyPlaceholderBox(
                  icon: Icons.receipt_long_rounded,
                  message: 'Brak zaksięgowanych operacji finansowych w tym sezonie.',
                )
              : Column(
                  children: ledger.recentTransactions.take(8).map((tx) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            tx.category.isRevenue
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 16,
                            color: tx.category.isRevenue
                                ? AppColors.statusSuccess
                                : AppColors.crimsonAlert,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tx.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${tx.category.isRevenue ? '+' : '-'}${Formatters.formatCurrency(tx.amountEur)}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: tx.category.isRevenue
                                  ? AppColors.statusSuccess
                                  : AppColors.crimsonAlert,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(growable: false),
                ),
        ),
      ],
    );
  }

  Widget _buildStarsAndSafetySection({required bool isMobile}) {
    return Column(
      children: [
        _SectionCard(
          title: 'Negocjacje Gwiazd Peletonu (Appearance Fees)',
          subtitle: 'Zapraszanie liderów GC i sprinterów do wyścigów organizatora',
          child: SizedBox(
            height: isMobile ? 460 : 520,
            child: const StarRiderAppearanceFeeNegotiatorPanel(),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Planowanie Barier i Marshali na Trasie',
          subtitle: 'Audyt stref niebezpiecznych Boplan Air-Cushion i obsady sędziów',
          child: SizedBox(
            height: isMobile ? 460 : 520,
            child: const CourseSafetyBarriersAndMarshalsPanel(),
          ),
        ),
      ],
    );
  }

  static String _bidStatusLabel(HostBidStatus status) {
    switch (status) {
      case HostBidStatus.openForBidding:
        return 'Otwarty';
      case HostBidStatus.shortlisted:
        return 'Finałowa Lista';
      case HostBidStatus.awarded:
        return 'Przyznany';
      case HostBidStatus.rejected:
        return 'Odrzucony';
      case HostBidStatus.expired:
        return 'Wygasły';
      case HostBidStatus.withdrawn:
        return 'Wycofany';
    }
  }

  static Color _bidStatusColor(HostBidStatus status) {
    switch (status) {
      case HostBidStatus.openForBidding:
        return AppColors.goldAccent;
      case HostBidStatus.shortlisted:
        return AppColors.accentBlue;
      case HostBidStatus.awarded:
        return AppColors.statusSuccess;
      case HostBidStatus.rejected:
      case HostBidStatus.expired:
      case HostBidStatus.withdrawn:
        return AppColors.textSecondary;
    }
  }
}

/// Wektorowa mapa przetargów miast gospodarzy dla Europy Zachodniej i Południowej.
class HostCityBiddingMapPainter extends CustomPainter {
  final List<HostCityBid> bids;
  final List<HostCityContract> contracts;
  final String? selectedBidId;

  const HostCityBiddingMapPainter({
    required this.bids,
    required this.contracts,
    this.selectedBidId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = AppColors.background;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final gridPaint = Paint()
      ..color = AppTheme.borderColor.withValues(alpha: 0.4)
      ..strokeWidth = 0.8;
    for (var i = 1; i < 6; i++) {
      final dx = size.width * (i / 6.0);
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
      final dy = size.height * (i / 6.0);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    // Stylizowany kontur lądowy Europy Zachodniej (Pireneje, Francja, Benelux, Alpy, Włochy)
    final landPath = Path()
      ..moveTo(size.width * 0.14, size.height * 0.88)
      ..lineTo(size.width * 0.16, size.height * 0.68)
      ..lineTo(size.width * 0.32, size.height * 0.66)
      ..lineTo(size.width * 0.30, size.height * 0.42)
      ..lineTo(size.width * 0.36, size.height * 0.28)
      ..lineTo(size.width * 0.49, size.height * 0.14)
      ..lineTo(size.width * 0.69, size.height * 0.08)
      ..lineTo(size.width * 0.78, size.height * 0.25)
      ..lineTo(size.width * 0.72, size.height * 0.48)
      ..lineTo(size.width * 0.84, size.height * 0.76)
      ..lineTo(size.width * 0.70, size.height * 0.84)
      ..lineTo(size.width * 0.56, size.height * 0.64)
      ..lineTo(size.width * 0.42, size.height * 0.74)
      ..lineTo(size.width * 0.28, size.height * 0.92)
      ..close();

    canvas.drawPath(
      landPath,
      Paint()..color = AppColors.surfaceLight.withValues(alpha: 0.65),
    );
    canvas.drawPath(
      landPath,
      Paint()
        ..color = AppTheme.borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Pasma górskie (Alpy i Pireneje)
    final mountainPaint = Paint()
      ..color = AppColors.primaryAccent.withValues(alpha: 0.28)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.52, size.height * 0.58),
      Offset(size.width * 0.64, size.height * 0.47),
      mountainPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.26, size.height * 0.72),
      Offset(size.width * 0.42, size.height * 0.75),
      mountainPaint,
    );

    // Podpisane kontrakty miast
    for (final contract in contracts) {
      final coord =
          HostCityGeoCoordinate.resolve(contract.cityName, contract.countryCode);
      final pos = Offset(coord.nx * size.width, coord.ny * size.height);
      _drawPin(
        canvas,
        pos,
        contract.cityName,
        AppColors.statusSuccess,
        isSelected: false,
        isAwarded: true,
      );
    }

    // Oferty przetargowe
    for (final bid in bids) {
      final coord = HostCityGeoCoordinate.resolve(bid.cityName, bid.countryCode);
      final pos = Offset(coord.nx * size.width, coord.ny * size.height);
      final color = bid.status == HostBidStatus.awarded
          ? AppColors.statusSuccess
          : (bid.status.isActiveForDecision
              ? AppColors.goldAccent
              : AppColors.textSecondary);
      _drawPin(
        canvas,
        pos,
        bid.cityName,
        color,
        isSelected: bid.bidId == selectedBidId,
        isAwarded: bid.status == HostBidStatus.awarded,
      );
    }
  }

  void _drawPin(
    Canvas canvas,
    Offset pos,
    String label,
    Color color, {
    required bool isSelected,
    required bool isAwarded,
  }) {
    if (isSelected) {
      canvas.drawCircle(
        pos,
        15,
        Paint()..color = color.withValues(alpha: 0.24),
      );
      canvas.drawCircle(
        pos,
        15,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    canvas.drawCircle(
      pos,
      isSelected ? 7.5 : 6.0,
      Paint()..color = color,
    );
    canvas.drawCircle(
      pos,
      isSelected ? 7.5 : 6.0,
      Paint()
        ..color = AppColors.background
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: isAwarded ? '★ $label' : label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final labelOffset = Offset(pos.dx + 10, pos.dy - tp.height / 2);
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        labelOffset.dx - 4,
        labelOffset.dy - 2,
        tp.width + 8,
        tp.height + 4,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      bgRect,
      Paint()..color = AppColors.background.withValues(alpha: 0.85),
    );
    tp.paint(canvas, labelOffset);
  }

  @override
  bool shouldRepaint(covariant HostCityBiddingMapPainter oldDelegate) {
    return oldDelegate.bids != bids ||
        oldDelegate.contracts != contracts ||
        oldDelegate.selectedBidId != selectedBidId;
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackTrailing = constraints.maxWidth < 460 && trailing != null;
          final headerText = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (stackTrailing) ...[
                headerText,
                const SizedBox(height: 10),
                trailing!,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: headerText),
                    if (trailing != null) ...[
                      const SizedBox(width: 12),
                      trailing!,
                    ],
                  ],
                ),
              const SizedBox(height: 14),
              child,
            ],
          );
        },
      ),
    );
  }
}

class _HeaderKpiTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _HeaderKpiTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _SelectableRaceTile extends StatefulWidget {
  final ManagedRacePortfolioItem race;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableRaceTile({
    required this.race,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SelectableRaceTile> createState() => _SelectableRaceTileState();
}

class _SelectableRaceTileState extends State<_SelectableRaceTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.selected
        ? AppColors.goldAccent
        : (_focused
            ? AppColors.accentBlue
            : (_hovered
                ? AppColors.goldAccent.withValues(alpha: 0.5)
                : AppTheme.borderColor));

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.surfaceLight.withValues(alpha: 0.85)
                : (widget.selected
                    ? AppColors.primaryAccent.withValues(alpha: 0.18)
                    : AppColors.surfaceLight),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: widget.selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.race.raceName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.race.tier.uciCode} • ${widget.race.stageCount} et. • Sponsor: ${widget.race.titleSponsorName}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${widget.race.prestigeScore.toStringAsFixed(1)} pkt',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressScoreBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ProgressScoreBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = (value / 100.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)}%',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: normalized,
            minHeight: 7,
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _ComplianceChip extends StatelessWidget {
  final String label;
  final bool ok;

  const _ComplianceChip({
    required this.label,
    required this.ok,
  });

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppColors.statusSuccess : AppColors.amberWarning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _MapLegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _EmptyPlaceholderBox extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyPlaceholderBox({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 28),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrganizerActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool disabled;

  const _OrganizerActionButton({
    required this.label,
    required this.icon,
    this.onTap,
    this.isPrimary = false,
    this.disabled = false,
  });

  @override
  State<_OrganizerActionButton> createState() => _OrganizerActionButtonState();
}

class _OrganizerActionButtonState extends State<_OrganizerActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.disabled && widget.onTap != null;
    final baseBg = widget.isPrimary
        ? AppColors.primaryAccent
        : AppColors.surfaceLight;
    final bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : (_pressed
            ? baseBg.withValues(alpha: 0.8)
            : (_hovered ? baseBg.withValues(alpha: 0.92) : baseBg));
    final borderColor = !enabled
        ? AppTheme.borderColor.withValues(alpha: 0.5)
        : (_focused
            ? AppColors.goldAccent
            : (_hovered ? AppColors.goldAccent.withValues(alpha: 0.7) : AppTheme.borderColor));

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
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

class _OrganizerFilterChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  const _OrganizerFilterChip({
    required this.label,
    this.icon,
    required this.selected,
    this.disabled = false,
    this.onTap,
  });

  @override
  State<_OrganizerFilterChip> createState() => _OrganizerFilterChipState();
}

class _OrganizerFilterChipState extends State<_OrganizerFilterChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.disabled && widget.onTap != null;
    final bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.35)
        : (widget.selected
            ? AppColors.goldAccent.withValues(alpha: 0.2)
            : (_pressed || _hovered
                ? AppColors.surfaceLight
                : AppColors.surface));
    final borderColor = !enabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : (widget.selected
            ? AppColors.goldAccent
            : (_focused
                ? AppColors.accentBlue
                : (_hovered ? AppColors.textSecondary : AppTheme.borderColor)));

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 15,
                  color: widget.selected
                      ? AppColors.goldAccent
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                    color: !enabled
                        ? AppColors.textSecondary.withValues(alpha: 0.6)
                        : (widget.selected
                            ? AppColors.goldAccent
                            : AppColors.textPrimary),
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

class _OrganizerInteractiveIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _OrganizerInteractiveIconButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  @override
  State<_OrganizerInteractiveIconButton> createState() =>
      _OrganizerInteractiveIconButtonState();
}

class _OrganizerInteractiveIconButtonState
    extends State<_OrganizerInteractiveIconButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.surfaceLight : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _focused ? AppColors.goldAccent : Colors.transparent,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
