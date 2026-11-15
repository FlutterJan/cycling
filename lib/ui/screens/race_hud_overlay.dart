import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/peloton/drafting_grid_system.dart';
import '../../engine/peloton/rider_race_state.dart';
import '../../engine/simulation/stage_simulation_loop.dart';
import '../../models/race/race_stage.dart';
import '../../state/race_simulation_notifier.dart';
import 'race_3d_viewport_widget.dart';
import '../widgets/tactical_minimap_2d_widget.dart';

// Stałe kolorystyczne profesjonalnego HUD wyścigowego (Zwift / TV Broadcast)
const Color _cyanAccent = Color(0xFF00E5FF);
const Color _emeraldGreen = Color(0xFF10B981);
const Color _amberWarning = Color(0xFFF59E0B);
const Color _crimsonAlert = Color(0xFFEF4444);
const Color _hudGlassSurface = Color(0xFF0F121C);

/// Profesjonalny interfejs nakładkowy (HUD) na ekran trójwymiarowego wyścigu kolarskiego.
///
/// Funkcjonalności:
/// 1. Górny pasek transmisyjny (TV Broadcast Bar):
///    - Dystans do mety, profil nachylenia drogi,
///    - Różnice czasowe między grupami (Ucieczka, Peleton, Grupetto),
///    - Kompas wiatru i wskaźnik wachlarzy (echelons),
///    - Kontrolki tempa symulacji (1x, 2x, 4x, 8x, Pauza, Skocz do akcji).
/// 2. Lewy panel kadry zespołu (Team Roster HUD):
///    - Karty 7-8 kolarzy drużyny gracza,
///    - Paski tętna z pulsowaniem i strefami HR,
///    - Waty na żywo (W oraz W/kg) z kolorowaniem stref mocy Coggana,
///    - Pasek zapasów glikogenu (żółty) i pojemności beztlenowej W' (czerwony),
///    - Liczniki i przyciski szybkiego użycia bidonów i żeli energetycznych,
///    - Szybkie przełączanie kamery 3D na klikniętego kolarza.
/// 3. Dolny panel kokpitu taktycznego (Tactical Orders Bar):
///    - Przyciski rozkazów dla wybranego kolarza: Utrzymuj koło, Daj zmianę z zadaną mocą,
///      Chroń lidera, ZAATAKUJ!, Zjedz żel, Jedź po bidony do wozu.
class RaceHudOverlay extends ConsumerStatefulWidget {
  /// Opcjonalne tło trójwymiarowe. Domyślnie osadza [Race3DViewportWidget].
  final Widget? background;
  final VoidCallback? onBack;
  final ValueChanged<String>? onRiderSelected;
  final ValueChanged<TacticalOrder>? onOrderIssued;

  const RaceHudOverlay({
    super.key,
    this.background,
    this.onBack,
    this.onRiderSelected,
    this.onOrderIssued,
  });

  @override
  ConsumerState<RaceHudOverlay> createState() => _RaceHudOverlayState();
}

class _RaceHudOverlayState extends ConsumerState<RaceHudOverlay> {
  // Czy lewy panel kolarzy jest zwinięty do kompaktowych ikon
  bool _isRosterCollapsed = false;

  // Wybrany poziom mocy na zmianie (waty lub preset)
  int _targetPullWatts = 420;

  @override
  Widget build(BuildContext context) {
    final simState = ref.watch(raceSimulationProvider);
    final simController = ref.watch(raceSimulationProvider.notifier);

    final activeStage = simState.simulationState?.stage ?? _generateFallbackStage();
    final playerRiders = simState.playerRidersPositions.isNotEmpty
        ? simState.playerRidersPositions
        : _generateFallbackPlayerSnapshots();

    final selectedRiderId = simState.selectedRiderId ??
        (playerRiders.isNotEmpty ? playerRiders.first.riderId : null);

    final selectedSnapshot = playerRiders.firstWhere(
      (r) => r.riderId == selectedRiderId,
      orElse: () => playerRiders.first,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 0. Widok tła trójwymiarowego (Zwift / MyWhoosh 3D Viewport)
          Positioned.fill(
            child: widget.background ??
                const Race3DViewportWidget(
                  showCameraControls: false,
                  showBroadcastHud: false,
                ),
          ),

          // 1. Górny pasek statusowy HUD (Dystans, Różnice czasowe, Kompas wiatru, Prędkość)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: _buildTopBroadcastBar(
                stage: activeStage,
                simState: simState,
                simController: simController,
              ),
            ),
          ),

          // 2. Lewy panel kadry zespołu (Karty 7-8 kolarzy z W, W/kg, HR, Glikogen, W', Bidony/Żele)
          Positioned(
            top: 84,
            bottom: 106,
            left: 12,
            child: SafeArea(
              child: _buildLeftTeamRosterPanel(
                playerRiders: playerRiders,
                selectedRiderId: selectedRiderId,
                simController: simController,
              ),
            ),
          ),

          // 3. Prawa taktyczna minimapa 2D (Zakręty, nawroty 180°, zwężenia, pociąg)
          Positioned(
            top: 84,
            right: 12,
            child: SafeArea(
              child: SizedBox(
                width: 360,
                child: TacticalMinimap2dWidget(
                  isCompact: true,
                  onRiderSelected: (riderId) {
                    simController.selectRider(riderId);
                    widget.onRiderSelected?.call(riderId);
                  },
                ),
              ),
            ),
          ),

          // 4. Dolny panel rozkazów taktycznych dla wybranego kolarza
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: SafeArea(
              top: false,
              child: _buildBottomTacticalOrdersPanel(
                selectedSnapshot: selectedSnapshot,
                simController: simController,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. GÓRNY PASEK STATUSOWY HUD (TOP BROADCAST BAR)
  // ===========================================================================

  Widget _buildTopBroadcastBar({
    required RaceStage stage,
    required ActiveRaceSimulationState simState,
    required RaceSimulationNotifier simController,
  }) {
    final double distRemainingKm = simState.distanceRemainingKm;
    final double totalDistKm = stage.totalDistanceKm > 0 ? stage.totalDistanceKm : 160.0;
    final double progressFraction = ((totalDistKm - distRemainingKm) / totalDistKm).clamp(0.0, 1.0);

    final currentSeg = (simState.simulationState != null &&
            simState.simulationState!.currentSegmentIndex < stage.segments.length)
        ? stage.segments[simState.simulationState!.currentSegmentIndex]
        : null;

    final double gradient = currentSeg?.gradientPercent ?? 4.2;
    final double windSpeed = stage.windSpeedKmh > 0 ? stage.windSpeedKmh : 18.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _hudGlassSurface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Przycisk wyjścia / pauzy
          if (widget.onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary, size: 18),
              onPressed: widget.onBack,
              tooltip: 'Opuść symulację etapu',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (widget.onBack != null) const SizedBox(width: 10),

          // Nazwa wyścigu i numer etapu
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: _crimsonAlert),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'LIVE BROADCAST',
                    style: TextStyle(
                      color: _crimsonAlert,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Etap #${stage.stageNumber}: ${stage.name}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Dystans do mety z paskiem postępu
          _buildStageDistanceProgressPill(distRemainingKm, progressFraction, gradient),
          const SizedBox(width: 14),

          // Różnice czasowe między grupami (Time Gaps Banner)
          Expanded(
            child: _buildTimeGapsBanner(simState),
          ),
          const SizedBox(width: 14),

          // Kompas wiatru
          _buildWindCompassIndicator(windSpeed),
          const SizedBox(width: 14),

          // Kontrolki prędkości symulacji (1x, 2x, 4x, Pauza, Skocz do akcji)
          _buildSimulationSpeedControls(simState, simController),
        ],
      ),
    );
  }

  Widget _buildStageDistanceProgressPill(double distRemainingKm, double progress, double gradient) {
    Color gradientColor = _emeraldGreen;
    if (gradient >= 8.0) {
      gradientColor = _crimsonAlert;
    } else if (gradient >= 5.0) {
      gradientColor = _amberWarning;
    } else if (gradient < -2.0) {
      gradientColor = _cyanAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flag_rounded, color: AppColors.goldAccent, size: 14),
              const SizedBox(width: 4),
              Text(
                '${distRemainingKm.toStringAsFixed(1)} km do mety',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: gradientColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '${gradient >= 0 ? "+" : ""}${gradient.toStringAsFixed(1)}%',
                  style: TextStyle(color: gradientColor, fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 140,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.goldAccent),
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeGapsBanner(ActiveRaceSimulationState simState) {
    final double gapSec = simState.breakawayGapSeconds;
    final int gapMin = (gapSec / 60.0).floor();
    final int gapRemainderSec = (gapSec % 60.0).round();

    final String gapStr = gapSec > 0
        ? '+${gapMin}m ${gapRemainderSec.toString().padLeft(2, '0')}s'
        : '0m 00s';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ucieczka
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _amberWarning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flash_on_rounded, color: _amberWarning, size: 12),
                SizedBox(width: 4),
                Text('UCIECZKA', style: TextStyle(color: _amberWarning, fontSize: 10, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Przewaga czasowa
          Text(
            gapStr,
            style: const TextStyle(
              color: AppColors.goldAccent,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),

          // Peleton
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _cyanAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.groups_rounded, color: _cyanAccent, size: 12),
                SizedBox(width: 4),
                Text('PELETON', style: TextStyle(color: _cyanAccent, fontSize: 10, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindCompassIndicator(double windSpeedKmh) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: 1.25, // Wiatr z ukosa
            child: const Icon(Icons.navigation_rounded, color: _cyanAccent, size: 16),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${windSpeedKmh.round()} km/h',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.w800),
              ),
              const Text(
                'Boczny wiatr',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationSpeedControls(
    ActiveRaceSimulationState simState,
    RaceSimulationNotifier simController,
  ) {
    final currentSpeed = simState.timeSpeed;
    final bool isPaused = simState.isPaused;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Przycisk Pauza/Wznów
        IconButton(
          onPressed: () => simController.togglePause(),
          icon: Icon(
            isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            color: isPaused ? _emeraldGreen : AppColors.goldAccent,
            size: 20,
          ),
          tooltip: isPaused ? 'Wznów wyścig' : 'Wstrzymaj wyścig',
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 6),

        // Selektory prędkości 1x, 2x, 4x
        ...[
          (SimulationTimeSpeed.x1, '1x'),
          (SimulationTimeSpeed.x2, '2x'),
          (SimulationTimeSpeed.x4, '4x'),
        ].map((item) {
          final isSelected = currentSpeed == item.$1 && !isPaused;
          return Padding(
            padding: const EdgeInsets.only(left: 4),
            child: InkWell(
              onTap: () {
                if (isPaused) simController.resume();
                simController.setSimulationSpeed(item.$1);
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.goldAccent : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.$2,
                  style: TextStyle(
                    color: isSelected ? Colors.black : AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 8),

        // Przycisk "Skocz do kluczowego momentu"
        ElevatedButton.icon(
          onPressed: () => simController.simulateToNextKeyMoment(),
          icon: const Icon(Icons.bolt_rounded, color: Colors.black, size: 14),
          label: const Text('KLUCZOWY MOMENT ⏩'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.goldAccent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. LEWY PANEL KADRY ZESPOŁU (TEAM ROSTER HUD)
  // ===========================================================================

  Widget _buildLeftTeamRosterPanel({
    required List<RiderPositionSnapshot> playerRiders,
    required String? selectedRiderId,
    required RaceSimulationNotifier simController,
  }) {
    final double panelWidth = _isRosterCollapsed ? 58.0 : 270.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: panelWidth,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _hudGlassSurface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nagłówek panelu kolarzy z przyciskiem zwijania
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!_isRosterCollapsed) ...[
                const Row(
                  children: [
                    Icon(Icons.directions_bike_rounded, color: AppColors.goldAccent, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'KADRA DRUŻYNY (7-8)',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
              IconButton(
                icon: Icon(
                  _isRosterCollapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                onPressed: () {
                  setState(() {
                    _isRosterCollapsed = !_isRosterCollapsed;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: _isRosterCollapsed ? 'Rozwiń telemetrię kolarzy' : 'Zwiń panel',
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 6),

          // Przewijana lista kart kolarzy
          Expanded(
            child: ListView.separated(
              itemCount: playerRiders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (ctx, idx) {
                final rider = playerRiders[idx];
                final bool isSelected = rider.riderId == selectedRiderId;

                return _isRosterCollapsed
                    ? _buildCollapsedRiderIcon(rider, isSelected, simController)
                    : _buildFullRiderCard(rider, isSelected, simController);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedRiderIcon(
    RiderPositionSnapshot rider,
    bool isSelected,
    RaceSimulationNotifier simController,
  ) {
    final int hrZone = _calculateHeartRateZone(rider.heartRateBpm);
    final Color zoneColor = AppColors.getPowerZoneColor(hrZone);

    return InkWell(
      onTap: () {
        simController.selectRider(rider.riderId);
        widget.onRiderSelected?.call(rider.riderId);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldAccent.withValues(alpha: 0.2) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.goldAccent : Colors.transparent),
        ),
        child: Column(
          children: [
            Text(
              '#${rider.bibNumber}',
              style: TextStyle(
                color: isSelected ? AppColors.goldAccent : AppColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: zoneColor),
            ),
            const SizedBox(height: 2),
            Text(
              '${rider.powerWatts}W',
              style: const TextStyle(color: _cyanAccent, fontSize: 9, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullRiderCard(
    RiderPositionSnapshot rider,
    bool isSelected,
    RaceSimulationNotifier simController,
  ) {
    final int hrZone = _calculateHeartRateZone(rider.heartRateBpm);
    final Color zoneColor = AppColors.getPowerZoneColor(hrZone);

    final double glycogenPercent = (rider.glycogenPercentage / 100.0).clamp(0.0, 1.0);
    final double wPrimePercent = (rider.wPrimePercentage / 100.0).clamp(0.0, 1.0);

    return InkWell(
      onTap: () {
        simController.selectRider(rider.riderId);
        widget.onRiderSelected?.call(rider.riderId);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldAccent.withValues(alpha: 0.15) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.goldAccent : Colors.white10,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linia 1: Numer, Imię, Ikona kamery i Wskaźnik strefy HR
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '#${rider.bibNumber}',
                    style: TextStyle(
                      color: isSelected ? AppColors.goldAccent : AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    rider.riderName,
                    style: TextStyle(
                      color: isSelected ? AppColors.goldAccent : AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.videocam_rounded, color: AppColors.goldAccent, size: 14),
                const SizedBox(width: 4),
                // Wskaźnik strefy HR z pulsem
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_rounded, color: zoneColor, size: 10),
                    const SizedBox(width: 2),
                    Text(
                      '${rider.heartRateBpm}',
                      style: TextStyle(color: zoneColor, fontSize: 9, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 5),

            // Linia 2: Waty na żywo (W oraz W/kg) i prędkość
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${rider.powerWatts} W',
                  style: TextStyle(color: zoneColor, fontSize: 13, fontWeight: FontWeight.w900),
                ),
                Text(
                  '${rider.wattsPerKg.toStringAsFixed(1)} W/kg',
                  style: const TextStyle(color: _cyanAccent, fontSize: 11, fontWeight: FontWeight.w800),
                ),
                Text(
                  '${rider.speedKmh.toStringAsFixed(1)} km/h',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 5),

            // Linia 3: Pasek glikogenu (Żółty)
            Row(
              children: [
                const SizedBox(
                  width: 48,
                  child: Text('Glikogen:', style: TextStyle(color: AppColors.textSecondary, fontSize: 8)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: glycogenPercent,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        glycogenPercent < 0.2 ? _crimsonAlert : _amberWarning,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${rider.glycogenPercentage.round()}%',
                  style: TextStyle(
                    color: glycogenPercent < 0.2 ? _crimsonAlert : _amberWarning,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),

            // Linia 4: Pasek beztlenowy W' (Czerwony)
            Row(
              children: [
                const SizedBox(
                  width: 48,
                  child: Text("Bateria W':", style: TextStyle(color: AppColors.textSecondary, fontSize: 8)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: wPrimePercent,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(_crimsonAlert),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${rider.wPrimePercentage.round()}%',
                  style: const TextStyle(color: _crimsonAlert, fontSize: 8, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Linia 5: Zasoby odżywcze (Bidony/Żele) i aktywny rozkaz
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Przyciski szybkiego użycia bidonu i żelu
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => simController.giveBidonToRider(rider.riderId),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: _cyanAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_drink_rounded, color: _cyanAccent, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              'x${rider.bidonsLeft}',
                              style: const TextStyle(color: _cyanAccent, fontSize: 9, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => simController.feedGelToRider(rider.riderId),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: _amberWarning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.battery_charging_full_rounded, color: _amberWarning, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              'x${rider.gelsLeft}',
                              style: const TextStyle(color: _amberWarning, fontSize: 9, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Aktywny rozkaz taktyczny kolarza
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    rider.activeTacticalOrder.label,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 8, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. DOLNY PANEL ROZKAZÓW TAKTYCZNYCH (TACTICAL ORDERS COCKPIT)
  // ===========================================================================

  Widget _buildBottomTacticalOrdersPanel({
    required RiderPositionSnapshot selectedSnapshot,
    required RaceSimulationNotifier simController,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _hudGlassSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pasek kontekstowy kolarza
          Row(
            children: [
              const Icon(Icons.sports_rounded, color: AppColors.goldAccent, size: 14),
              const SizedBox(width: 6),
              Text(
                'ROZKAZY DLA: #${selectedSnapshot.bibNumber} ${selectedSnapshot.riderName.toUpperCase()}',
                style: const TextStyle(
                  color: AppColors.goldAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '• Aktualny rozkaz: ${selectedSnapshot.activeTacticalOrder.label}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
              const Spacer(),
              if (selectedSnapshot.isDrafting)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _cyanAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.air_rounded, color: _cyanAccent, size: 11),
                      const SizedBox(width: 4),
                      Text(
                        'DRAFTING: -${(selectedSnapshot.draftingSavingsPercent * 100).round()}% W',
                        style: const TextStyle(color: _cyanAccent, fontSize: 9, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Przyciski rozkazów taktycznych
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // 1. Utrzymuj koło / pozycję
                _buildTacticalActionButton(
                  icon: Icons.directions_bike_rounded,
                  label: 'Utrzymuj Koło',
                  color: const Color(0xFF38BDF8),
                  isSelected: selectedSnapshot.activeTacticalOrder == TacticalOrder.holdPosition ||
                      selectedSnapshot.activeTacticalOrder == TacticalOrder.followWheels,
                  onTap: () {
                    simController.orderRiderHoldPosition(selectedSnapshot.riderId);
                    widget.onOrderIssued?.call(TacticalOrder.holdPosition);
                  },
                ),
                const SizedBox(width: 6),

                // 2. Daj zmianę na czele
                _buildTacticalActionButton(
                  icon: Icons.fast_forward_rounded,
                  label: 'Daj Zmianę ($_targetPullWatts W)',
                  color: _emeraldGreen,
                  isSelected: selectedSnapshot.activeTacticalOrder == TacticalOrder.pullGroup,
                  onTap: () => _showPullWattsModal(selectedSnapshot.riderId, simController),
                ),
                const SizedBox(width: 6),

                // 3. Chroń lidera
                _buildTacticalActionButton(
                  icon: Icons.shield_rounded,
                  label: 'Chroń Lidera',
                  color: const Color(0xFF818CF8),
                  isSelected: selectedSnapshot.activeTacticalOrder == TacticalOrder.protectLeader,
                  onTap: () {
                    simController.orderRiderProtectLeader(selectedSnapshot.riderId);
                    widget.onOrderIssued?.call(TacticalOrder.protectLeader);
                  },
                ),
                const SizedBox(width: 6),

                // 4. ZAATAKUJ!
                _buildAttackActionButton(
                  riderId: selectedSnapshot.riderId,
                  simController: simController,
                ),
                const SizedBox(width: 6),

                // 5. Zjedz żel
                _buildTacticalActionButton(
                  icon: Icons.battery_charging_full_rounded,
                  label: 'Zjedz Żel (+30g)',
                  color: _amberWarning,
                  isSelected: false,
                  onTap: () => simController.feedGelToRider(selectedSnapshot.riderId),
                ),
                const SizedBox(width: 6),

                // 6. Jedź po bidony do wozu
                _buildTacticalActionButton(
                  icon: Icons.local_drink_rounded,
                  label: 'Do Wozu po Bidony',
                  color: _cyanAccent,
                  isSelected: selectedSnapshot.activeTacticalOrder == TacticalOrder.fetchBidonsFromCar,
                  onTap: () => simController.sendDomestiqueForBidons(selectedSnapshot.riderId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.25) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : Colors.white12, width: isSelected ? 1.5 : 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? color : AppColors.textSecondary, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.textPrimary,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttackActionButton({
    required String riderId,
    required RaceSimulationNotifier simController,
  }) {
    return InkWell(
      onTap: () {
        simController.orderRiderAttack(riderId);
        widget.onOrderIssued?.call(TacticalOrder.attack);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFF59E0B)],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, color: Colors.white, size: 15),
            SizedBox(width: 4),
            Text(
              'ZAATAKUJ! 💥',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPullWattsModal(String riderId, RaceSimulationNotifier simController) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _hudGlassSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.speed_rounded, color: _emeraldGreen, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'DAJ ZMIANĘ NA CZELE PELETONU',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Presety mocy
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildWattPresetChip('Tempo Z3 (350W)', 350, setModalState),
                      _buildWattPresetChip('Próg FTP (420W)', 420, setModalState),
                      _buildWattPresetChip('Full Gas (500W)', 500, setModalState),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Suwak mocy
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Moc zadana:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Text(
                        '$_targetPullWatts W',
                        style: const TextStyle(color: _emeraldGreen, fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  Slider(
                    value: _targetPullWatts.toDouble(),
                    min: 280,
                    max: 600,
                    divisions: 32,
                    activeColor: _emeraldGreen,
                    onChanged: (val) {
                      setModalState(() {
                        _targetPullWatts = val.round();
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  // Przycisk zatwierdzenia
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {});
                        simController.orderRiderPullGroup(riderId);
                        widget.onOrderIssued?.call(TacticalOrder.pullGroup);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _emeraldGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'WYJDŹ NA PROWADZENIE',
                        style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWattPresetChip(String label, int watts, StateSetter setModalState) {
    final bool isSelected = _targetPullWatts == watts;
    return InkWell(
      onTap: () {
        setModalState(() {
          _targetPullWatts = watts;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _emeraldGreen : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.textPrimary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  int _calculateHeartRateZone(int hrBpm) {
    if (hrBpm < 125) return 1;
    if (hrBpm < 145) return 2;
    if (hrBpm < 162) return 3;
    if (hrBpm < 174) return 4;
    if (hrBpm < 186) return 5;
    if (hrBpm < 196) return 6;
    return 7;
  }

  // ===========================================================================
  // MOCKOWE DANE DEMO DLA TESTOWANIA / PREVIEW
  // ===========================================================================

  RaceStage _generateFallbackStage() {
    return const RaceStage(
      id: 'hud_sample_stage',
      stageNumber: 14,
      name: 'Bourg d\'Oisans > Alpe d\'Huez',
      stageType: StageType.summitFinish,
      segments: [],
      baseTemperatureCelsius: 21.0,
      weatherCondition: WeatherCondition.sunny,
      windSpeedKmh: 16.0,
    );
  }

  List<RiderPositionSnapshot> _generateFallbackPlayerSnapshots() {
    return [
      const RiderPositionSnapshot(
        riderId: 'rider_pogacar',
        riderName: 'Tadej Pogacar',
        bibNumber: 1,
        teamId: 'team_uae',
        teamName: 'UAE Team Emirates',
        teamJerseyHexColor: '#D4AF37',
        isPlayerRider: true,
        distanceCoveredMeters: 135400.0,
        kilometerMark: 135.4,
        elevationMeters: 1850.0,
        currentGradientPercent: 8.5,
        currentSegmentIndex: 4,
        speedMs: 6.5,
        speedKmh: 23.4,
        powerWatts: 440,
        wattsPerKg: 6.6,
        cadenceRpm: 92,
        heartRateBpm: 174,
        wPrimePercentage: 84.0,
        wPrimeJoules: 20160.0,
        glycogenPercentage: 72.0,
        glycogenGrams: 468.0,
        hydrationPercent: 88.0,
        bidonsLeft: 2,
        gelsLeft: 2,
        activeTacticalOrder: TacticalOrder.holdPosition,
        groupIndex: 0,
        groupType: GroupType.breakaway,
        timeGapToLeaderSeconds: 0.0,
        lateralPositionRoad: 0.0,
        lateralOffsetRoadMeters: 0.2,
        isDrafting: true,
        draftingSavingsPercent: 0.28,
        isPulling: false,
        hasDefect: false,
        isCrashed: false,
        isDnf: false,
      ),
      const RiderPositionSnapshot(
        riderId: 'rider_majka',
        riderName: 'Rafal Majka',
        bibNumber: 2,
        teamId: 'team_uae',
        teamName: 'UAE Team Emirates',
        teamJerseyHexColor: '#38BDF8',
        isPlayerRider: true,
        distanceCoveredMeters: 135395.0,
        kilometerMark: 135.39,
        elevationMeters: 1848.0,
        currentGradientPercent: 8.5,
        currentSegmentIndex: 4,
        speedMs: 6.5,
        speedKmh: 23.4,
        powerWatts: 410,
        wattsPerKg: 6.0,
        cadenceRpm: 88,
        heartRateBpm: 178,
        wPrimePercentage: 62.0,
        wPrimeJoules: 14880.0,
        glycogenPercentage: 58.0,
        glycogenGrams: 377.0,
        hydrationPercent: 75.0,
        bidonsLeft: 1,
        gelsLeft: 1,
        activeTacticalOrder: TacticalOrder.protectLeader,
        groupIndex: 0,
        groupType: GroupType.breakaway,
        timeGapToLeaderSeconds: 0.5,
        lateralPositionRoad: -0.4,
        lateralOffsetRoadMeters: -0.6,
        isDrafting: false,
        draftingSavingsPercent: 0.0,
        isPulling: true,
        hasDefect: false,
        isCrashed: false,
        isDnf: false,
      ),
      const RiderPositionSnapshot(
        riderId: 'rider_soler',
        riderName: 'Marc Soler',
        bibNumber: 3,
        teamId: 'team_uae',
        teamName: 'UAE Team Emirates',
        teamJerseyHexColor: '#8B5CF6',
        isPlayerRider: true,
        distanceCoveredMeters: 135380.0,
        kilometerMark: 135.38,
        elevationMeters: 1845.0,
        currentGradientPercent: 8.5,
        currentSegmentIndex: 4,
        speedMs: 6.4,
        speedKmh: 23.0,
        powerWatts: 380,
        wattsPerKg: 5.3,
        cadenceRpm: 86,
        heartRateBpm: 170,
        wPrimePercentage: 75.0,
        wPrimeJoules: 18000.0,
        glycogenPercentage: 65.0,
        glycogenGrams: 422.0,
        hydrationPercent: 82.0,
        bidonsLeft: 2,
        gelsLeft: 2,
        activeTacticalOrder: TacticalOrder.pullGroup,
        groupIndex: 0,
        groupType: GroupType.breakaway,
        timeGapToLeaderSeconds: 1.2,
        lateralPositionRoad: 0.2,
        lateralOffsetRoadMeters: 0.4,
        isDrafting: true,
        draftingSavingsPercent: 0.32,
        isPulling: false,
        hasDefect: false,
        isCrashed: false,
        isDnf: false,
      ),
      const RiderPositionSnapshot(
        riderId: 'rider_wellens',
        riderName: 'Tim Wellens',
        bibNumber: 4,
        teamId: 'team_uae',
        teamName: 'UAE Team Emirates',
        teamJerseyHexColor: '#10B981',
        isPlayerRider: true,
        distanceCoveredMeters: 135320.0,
        kilometerMark: 135.32,
        elevationMeters: 1840.0,
        currentGradientPercent: 8.5,
        currentSegmentIndex: 4,
        speedMs: 6.3,
        speedKmh: 22.7,
        powerWatts: 360,
        wattsPerKg: 4.9,
        cadenceRpm: 85,
        heartRateBpm: 168,
        wPrimePercentage: 80.0,
        wPrimeJoules: 19200.0,
        glycogenPercentage: 70.0,
        glycogenGrams: 455.0,
        hydrationPercent: 78.0,
        bidonsLeft: 1,
        gelsLeft: 1,
        activeTacticalOrder: TacticalOrder.holdPosition,
        groupIndex: 1,
        groupType: GroupType.peloton,
        timeGapToLeaderSeconds: 8.0,
        lateralPositionRoad: -0.2,
        lateralOffsetRoadMeters: -0.3,
        isDrafting: true,
        draftingSavingsPercent: 0.35,
        isPulling: false,
        hasDefect: false,
        isCrashed: false,
        isDnf: false,
      ),
    ];
  }
}
