import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/peloton/rider_race_state.dart';
import '../../engine/simulation/stage_results_calculator.dart';
import '../../engine/simulation/stage_simulation_loop.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../models/rider/rider.dart';
import '../../state/career_controller.dart';
import '../../state/race_simulation_notifier.dart';
import '../widgets/elevation_profile_chart.dart';
import '../widgets/key_moment_overlay.dart';
import '../widgets/race_radio_banner.dart';
import '../widgets/race_top_hud_bar.dart';
import '../widgets/rider_telemetry_hud.dart';
import '../widgets/tactical_minimap_2d_widget.dart';
import '../../engine/rendering3d/photo_finish_replay_widget.dart';
import 'race_3d_viewport_widget.dart';
import 'race_hud_overlay.dart';
import 'post_stage_podium_screen.dart';

const Color _cyanAccent = Color(0xFF00E5FF);

/// Tryby widoku kamery podczas trwania etapu
enum RaceCameraMode {
  /// Panoramiczny profil wysokościowy 2.5D z premiami górskimi i podziałem peletonu
  profile2D,

  /// Trójwymiarowa perspektywa szosy z horyzontem, kibicami i strugą aerodynamiczną
  road3D,

  /// Radar aerodynamiczny i taktyczny wachlarz (echelon) na wietrze bocznym
  aeroEchelon,

  /// Pełny profesjonalny HUD transmisyjny (Zwift Live HUD)
  hud3D;

  String get label {
    switch (this) {
      case RaceCameraMode.profile2D:
        return 'Profil 2.5D';
      case RaceCameraMode.road3D:
        return 'Kamera 3D';
      case RaceCameraMode.aeroEchelon:
        return 'Tunel Aero';
      case RaceCameraMode.hud3D:
        return 'HUD Zwift';
    }
  }

  IconData get icon {
    switch (this) {
      case RaceCameraMode.profile2D:
        return Icons.show_chart;
      case RaceCameraMode.road3D:
        return Icons.view_in_ar;
      case RaceCameraMode.aeroEchelon:
        return Icons.air;
      case RaceCameraMode.hud3D:
        return Icons.dashboard_customize_rounded;
    }
  }
}

/// Główny ekran interaktywnej symulacji wyścigu kolarskiego (Tryb 3D / HUD Live).
class RaceSimulationScreen extends ConsumerStatefulWidget {
  const RaceSimulationScreen({super.key});

  @override
  ConsumerState<RaceSimulationScreen> createState() => _RaceSimulationScreenState();
}

class _RaceSimulationScreenState extends ConsumerState<RaceSimulationScreen> {
  RaceCameraMode _cameraMode = RaceCameraMode.profile2D;
  bool _showMinimap = true;

  @override
  Widget build(BuildContext context) {
    final simUiState = ref.watch(raceSimulationProvider);
    final simController = ref.read(raceSimulationProvider.notifier);
    final careerUiState = ref.watch(careerProvider);
    final careerController = ref.read(careerProvider.notifier);

    final simState = simUiState.simulationState;

    if (simState == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.goldAccent),
              const SizedBox(height: 16),
              const Text(
                'Przygotowywanie trasy i peletonu...',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Wróć do bazy drużyny'),
              ),
            ],
          ),
        ),
      );
    }

    final currentRiderState = simUiState.selectedRiderState;
    final Rider? selectedRider = simUiState.selectedRiderId != null
        ? careerUiState.save?.getRiderById(simUiState.selectedRiderId!)
        : null;

    if (_cameraMode == RaceCameraMode.hud3D) {
      return RaceHudOverlay(
        onBack: () => setState(() => _cameraMode = RaceCameraMode.road3D),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Tło sceny wyścigu (Wizualizacja trasy 3D / 2.5D Elevation Track Canvas)
          Positioned.fill(
            child: _RaceTrackElevationCanvas(
              cameraMode: _cameraMode,
              stage: simState.stage,
              riderStates: simState.riderStates,
              playerRiderIds: simState.playerRiderIds,
              selectedRiderId: simUiState.selectedRiderId,
              currentLeadKm: simState.leadKilometerMark,
              currentSegment: simUiState.currentSegment,
              elapsedSeconds: simState.elapsedSeconds,
              onRiderTapped: (riderId) => simController.selectRider(riderId),
            ),
          ),

          // 2. Górny pasek statusowy HUD (Dystans, wysokość, wiatr, mnożniki czasu)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: RaceTopHudBar(
                stage: simState.stage,
                currentLeadKm: simState.leadKilometerMark,
                elapsedSeconds: simState.elapsedSeconds,
                currentSegment: simUiState.currentSegment,
                currentSpeed: simState.timeSpeed,
                isPaused: simUiState.isPaused,
                onSpeedSelected: (speed) => simController.setSimulationSpeed(speed),
                onTogglePause: () => simController.togglePause(),
                onFastForwardToKeyMoment: () => simController.simulateToNextKeyMoment(),
              ),
            ),
          ),

          // 2b. Przełącznik trybu kamery (Profil 2.5D, Szosa 3D, Echelon Aero)
          Positioned(
            top: 76,
            right: 16,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface.withAlpha(235),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...RaceCameraMode.values.map((mode) {
                      final isSelected = mode == _cameraMode;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: InkWell(
                          onTap: () => setState(() => _cameraMode = mode),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryAccent : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  mode.icon,
                                  size: 14,
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  mode.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 4),
                    Container(
                    margin: const EdgeInsets.only(left: 2),
                    decoration: BoxDecoration(
                      color: _showMinimap ? AppColors.goldAccent.withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.radar_rounded,
                        size: 16,
                        color: _showMinimap ? AppColors.goldAccent : AppColors.textSecondary,
                      ),
                      tooltip: _showMinimap ? 'Ukryj radar minimapy 2D' : 'Pokaż radar minimapy 2D',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () => setState(() => _showMinimap = !_showMinimap),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

          // 2.3. Pływająca minimapa taktyczna 2D (Lot ptaka, zakręty, nawroty 180°, zwężenia przed brukiem, pociąg)
          if (_showMinimap)
            Positioned(
              top: 126,
              right: 16,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  width: 360,
                  child: TacticalMinimap2dWidget(
                    isCompact: true,
                    onRiderSelected: (riderId) => simController.selectRider(riderId),
                  ),
                ),
              ),
            ),

          // 2.5. Baner awaryjny defektu lub kraksy w zespole gracza
          if (simUiState.activePlayerDefect != null)
            Positioned(
              top: 130,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 640),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1010).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'DEFEKT / KRAKSA: ${simUiState.activePlayerDefect!.victimRiderName} (${simUiState.activePlayerDefect!.description})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade900,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.swap_horiz, size: 16),
                            label: const Text('Rower pomocnika (~14s)'),
                            onPressed: () {
                              final playerTeammates = simUiState.playerRiderStates
                                  .where((r) => r.riderId != simUiState.activePlayerDefect!.victimRiderId)
                                  .toList();
                              if (playerTeammates.isNotEmpty) {
                                simController.resolveDefectWithTeammateBikeSwap(
                                  simUiState.activePlayerDefect!.victimRiderId,
                                  playerTeammates.last.riderId,
                                );
                              }
                            },
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.directions_car, size: 16),
                            label: const Text('Wóz drużyny (~40s)'),
                            onPressed: () {
                              simController.resolveDefectWithTeamCar(
                                simUiState.activePlayerDefect!.victimRiderId,
                              );
                            },
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.cyanAccent,
                              side: const BorderSide(color: Colors.cyanAccent),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.build, size: 16),
                            label: const Text('Neutral Shimano (~30s)'),
                            onPressed: () {
                              simController.resolveDefectWithNeutralService(
                                simUiState.activePlayerDefect!.victimRiderId,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 3. Pływająca karta telemetryczna wybranego kolarza (Dolny lewy róg)
          if (currentRiderState != null)
            Positioned(
              left: 16,
              bottom: 24,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pasek akcji żywieniowych i bidonów dla kolarza gracza
                    if (simUiState.selectedRider?.isPlayerRider == true)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Żel energetyczny (+30g)
                            InkWell(
                              onTap: (simUiState.selectedRider?.gelsLeft ?? 0) > 0
                                  ? () => simController.feedGelToRider(simUiState.selectedRiderId!)
                                  : null,
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.bolt, size: 15, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Żel (${simUiState.selectedRider?.gelsLeft ?? 0})',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: (simUiState.selectedRider?.gelsLeft ?? 0) > 0
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Bidon (+500ml)
                            InkWell(
                              onTap: (simUiState.selectedRider?.bidonsLeft ?? 0) > 0
                                  ? () => simController.giveBidonToRider(simUiState.selectedRiderId!)
                                  : null,
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.water_drop, size: 15, color: Colors.cyanAccent),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Bidon (${simUiState.selectedRider?.bidonsLeft ?? 0})',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: (simUiState.selectedRider?.bidonsLeft ?? 0) > 0
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Pomocnik po bidony z wozu
                            InkWell(
                              onTap: () => simController.sendDomestiqueForBidons(simUiState.selectedRiderId!),
                              borderRadius: BorderRadius.circular(6),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.directions_car, size: 15, color: AppColors.goldAccent),
                                    SizedBox(width: 4),
                                    Text(
                                      'Wóz',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.goldAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    RiderTelemetryHud(
                      riderState: currentRiderState,
                      rider: selectedRider,
                      onOrderSelected: (order) {
                        if (simUiState.selectedRiderId != null) {
                          simController.issueTacticalOrder(simUiState.selectedRiderId!, order);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

          // 4. Pasek komunikatów radia wyścigowego (Dolny prawy róg / środek)
          Positioned(
            bottom: 24,
            right: 16,
            child: SafeArea(
              top: false,
              child: RaceRadioBanner(
                radioMessages: simState.radioLog,
              ),
            ),
          ),

          // 5. Powiadomienie o kluczowym momencie (Key Moment Alert Modal)
          if (simUiState.activeNotification != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.65),
                child: KeyMomentOverlay(
                  trigger: simUiState.activeNotification!,
                  onDismiss: () => simController.dismissNotification(),
                  onTakeControl: () {
                    simController.dismissNotification();
                    simController.setSimulationSpeed(SimulationTimeSpeed.x1);
                  },
                ),
              ),
            ),

          // 6. Okno dialogowe oficjalnych wyników etapu UCI
          if (simUiState.stageSummaryReport != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.85),
                child: _StageFinishSummaryDialog(
                  report: simUiState.stageSummaryReport!,
                  simState: simState,
                  playerTeamId: simState.playerTeamId,
                  onCloseAndContinue: () async {
                    await careerController.completeStageAndApplyRecovery(
                      stageSummary: simUiState.stageSummaryReport!,
                      simulationState: simState,
                    );
                    if (context.mounted) {
                      Navigator.of(context).maybePop();
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Dynamiczny canvas przełączający pomiędzy trybami wizualizacji trasy
class _RaceTrackElevationCanvas extends StatelessWidget {
  final RaceCameraMode cameraMode;
  final RaceStage stage;
  final Map<String, RiderRaceState> riderStates;
  final List<String> playerRiderIds;
  final String? selectedRiderId;
  final double currentLeadKm;
  final StageSegment? currentSegment;
  final double elapsedSeconds;
  final Function(String) onRiderTapped;

  const _RaceTrackElevationCanvas({
    required this.cameraMode,
    required this.stage,
    required this.riderStates,
    required this.playerRiderIds,
    this.selectedRiderId,
    required this.currentLeadKm,
    this.currentSegment,
    required this.elapsedSeconds,
    required this.onRiderTapped,
  });

  @override
  Widget build(BuildContext context) {
    switch (cameraMode) {
      case RaceCameraMode.profile2D:
        return ElevationProfileChart(
          stage: stage,
          riderStates: riderStates,
          playerRiderIds: playerRiderIds,
          selectedRiderId: selectedRiderId,
          currentLeadKm: currentLeadKm,
          isLiveRace: true,
          showHeader: true,
          enableScrubber: true,
          onRiderSelected: onRiderTapped,
        );
      case RaceCameraMode.road3D:
        return Race3DViewportWidget(
          stage: stage,
          riderStates: riderStates,
          playerRiderIds: playerRiderIds,
          selectedRiderId: selectedRiderId,
          onRiderSelected: onRiderTapped,
          showCameraControls: true,
          showBroadcastHud: false,
        );
      case RaceCameraMode.hud3D:
        return const SizedBox.shrink();
      case RaceCameraMode.aeroEchelon:
        return CustomPaint(
          painter: _AeroEchelonPainter(
            stage: stage,
            riderStates: riderStates,
            playerRiderIds: playerRiderIds,
            selectedRiderId: selectedRiderId,
            currentLeadKm: currentLeadKm,
            currentSegment: currentSegment,
            elapsedSeconds: elapsedSeconds.round(),
          ),
          size: Size.infinite,
        );
    }
  }
}

/// 3. Painter Tunelu Aerodynamicznego i Taktycznego Echelonu na Wietrze Bocznym
class _AeroEchelonPainter extends CustomPainter {
  final RaceStage stage;
  final Map<String, RiderRaceState> riderStates;
  final List<String> playerRiderIds;
  final String? selectedRiderId;
  final double currentLeadKm;
  final StageSegment? currentSegment;
  final int elapsedSeconds;

  _AeroEchelonPainter({
    required this.stage,
    required this.riderStates,
    required this.playerRiderIds,
    this.selectedRiderId,
    required this.currentLeadKm,
    this.currentSegment,
    required this.elapsedSeconds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Ciemne tło siatki laboratoryjno-aerodynamicznej
    final bgPaint = Paint()..color = const Color(0xFF0C0E12);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final gridPaint = Paint()
      ..color = const Color(0xFF1E232F)
      ..strokeWidth = 0.8;
    for (double x = 0; x < w; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    final double windSpeed = stage.windSpeedKmh > 0 ? stage.windSpeedKmh : 32.0;
    const double windAngleDeg = 45.0;
    const double windRad = windAngleDeg * math.pi / 180.0;

    // 1. Radar Wiatru Bocznego (Top Left Compass)
    const compassCenter = Offset(80, 160);
    const compassRadius = 45.0;

    final compassBgPaint = Paint()
      ..color = AppColors.surfaceLight.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(compassCenter, compassRadius, compassBgPaint);

    final compassRingPaint = Paint()
      ..color = _cyanAccent.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(compassCenter, compassRadius, compassRingPaint);

    // Strzałka wektora wiatru
    const arrowLength = 32.0;
    final arrowEnd = Offset(
      compassCenter.dx + math.cos(windRad) * arrowLength,
      compassCenter.dy + math.sin(windRad) * arrowLength,
    );

    final arrowPaint = Paint()
      ..color = _cyanAccent
      ..strokeWidth = 3.0;
    canvas.drawLine(compassCenter, arrowEnd, arrowPaint);
    canvas.drawCircle(arrowEnd, 4.0, Paint()..color = _cyanAccent);

    final windText = TextPainter(
      text: TextSpan(
        text: 'WIATR: ${windSpeed.round()} km/h\nKĄT: ${windAngleDeg.round()}° (Boczny)',
        style: const TextStyle(color: _cyanAccent, fontSize: 10, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    windText.paint(canvas, Offset(compassCenter.dx - 45, compassCenter.dy + compassRadius + 10));

    // 2. Korytarz szosy pod kątem
    final roadCenter = Offset(w * 0.52, h * 0.52);
    const roadWidth = 260.0;
    const roadHeight = 440.0;

    final roadRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: roadCenter, width: roadWidth, height: roadHeight),
      const Radius.circular(16),
    );

    canvas.drawRRect(roadRect, Paint()..color = const Color(0xFF181B22));
    canvas.drawRRect(
      roadRect,
      Paint()
        ..color = AppColors.goldAccent.withAlpha(70)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );

    // 3. Pozycje kolarzy w formacji echelonu (Wachlarz)
    final List<MapEntry<String, RiderRaceState>> activeRiders = riderStates.entries.take(7).toList();

    for (int i = 0; i < activeRiders.length; i++) {
      final entry = activeRiders[i];
      final String rId = entry.key;
      final bool isPlayer = playerRiderIds.contains(rId);
      final bool isSelected = rId == selectedRiderId;

      // Kolarze ustawiają się po przekątnej (formacja wachlarza)
      const double echelonStepX = -26.0;
      const double echelonStepY = 50.0;

      final double riderX = (roadCenter.dx + 80.0) + (i * echelonStepX);
      final double riderY = (roadCenter.dy - 170.0) + (i * echelonStepY);

      final isGutter = (riderX - roadCenter.dx).abs() > (roadWidth * 0.45);

      // Stożek cienia aerodynamicznego za kolarzem
      const coneLength = 55.0;
      final conePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isGutter ? Colors.red.withValues(alpha: 0.3) : _cyanAccent.withValues(alpha: 0.4),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(riderX - 18, riderY, 36, coneLength));

      final conePath = Path()
        ..moveTo(riderX, riderY)
        ..lineTo(riderX - 18, riderY + coneLength)
        ..lineTo(riderX + 18, riderY + coneLength)
        ..close();
      canvas.drawPath(conePath, conePaint);

      // Kolarz
      final riderPaint = Paint()
        ..color = isSelected
            ? Colors.white
            : (isPlayer ? AppColors.goldAccent : const Color(0xFF3498DB));
      canvas.drawCircle(Offset(riderX, riderY), 8.0, riderPaint);

      if (isSelected) {
        canvas.drawCircle(
          Offset(riderX, riderY),
          12.0,
          Paint()
            ..color = AppColors.goldAccent
            ..strokeWidth = 2.0
            ..style = PaintingStyle.stroke,
        );
      }

      // Etykieta statusu w echelonie
      String statusLabel;
      Color statusColor;
      if (i == 0) {
        statusLabel = '🔥 Na zmianie (100% W)';
        statusColor = const Color(0xFFE74C3C);
      } else if (isGutter) {
        statusLabel = '⚠️ Rynsztok (Zero osłony)';
        statusColor = Colors.red;
      } else {
        statusLabel = '🛡️ Na kole (-40% W)';
        statusColor = AppColors.powerZone3;
      }

      final labelPainter = TextPainter(
        text: TextSpan(
          text: statusLabel,
          style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(canvas, Offset(riderX + 14, riderY - 6));
    }
  }

  @override
  bool shouldRepaint(covariant _AeroEchelonPainter oldDelegate) {
    return oldDelegate.currentLeadKm != currentLeadKm ||
        oldDelegate.selectedRiderId != selectedRiderId ||
        oldDelegate.elapsedSeconds != elapsedSeconds;
  }
}

/// Okno podsumowania oficjalnych wyników etapu (Zwycięzca, bonifikaty, punkty, koszulki).
class _StageFinishSummaryDialog extends StatelessWidget {
  final StageSummaryReport report;
  final StageSimulationState? simState;
  final String playerTeamId;
  final VoidCallback onCloseAndContinue;

  const _StageFinishSummaryDialog({
    required this.report,
    this.simState,
    required this.playerTeamId,
    required this.onCloseAndContinue,
  });

  @override
  Widget build(BuildContext context) {
    final top10 = report.results.take(10).toList();
    final bool isPhotoFinish = top10.length >= 2 &&
        PhotoFinishData.isPhotoFinishRequired(
          (top10[1].rawFinishTimeSeconds - top10[0].rawFinishTimeSeconds).abs(),
        );
    final double photoFinishGap = isPhotoFinish
        ? (top10[1].rawFinishTimeSeconds - top10[0].rawFinishTimeSeconds).abs()
        : 0.0;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 650),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.goldAccent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nagłówek
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OFICJALNE WYNIKI ETAPU UCI',
                        style: TextStyle(
                          color: AppColors.goldAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${report.stageNumber}. ${report.stageName}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emoji_events, color: AppColors.goldAccent, size: 24),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: AppTheme.borderColor),
              const SizedBox(height: 12),

              // Lista Top 10 kolarzy na mecie
              Expanded(
                child: ListView.separated(
                  itemCount: top10.length,
                  separatorBuilder: (_, __) => const Divider(color: AppTheme.borderColor, height: 1),
                  itemBuilder: (ctx, index) {
                    final res = top10[index];
                    final bool isPlayerRider = res.teamId == playerTeamId;

                    return Container(
                      color: isPlayerRider ? AppColors.goldAccent.withValues(alpha: 0.08) : Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        children: [
                          // Pozycja
                          SizedBox(
                            width: 28,
                            child: Text(
                              '#${res.rank}',
                              style: AppTheme.statNumberStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: res.rank == 1
                                    ? AppColors.goldAccent
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Nazwisko i drużyna
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  res.riderName,
                                  style: TextStyle(
                                    color: isPlayerRider ? AppColors.goldAccent : AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  res.teamId,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Bonifikata czasowa
                          if (res.timeBonusSeconds > 0)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.goldAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-${res.timeBonusSeconds}s',
                                style: const TextStyle(
                                  color: AppColors.goldAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          // Czas lub strata
                          Text(
                            res.rank == 1
                                ? _formatSeconds(res.officialFinishTimeSeconds)
                                : '+${res.gapToWinnerSeconds.toStringAsFixed(1)}s',
                            style: AppTheme.statNumberStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Przycisk Photo Finish w przypadku zaciętego finiszu (różnica < 0.15s)
              if (isPhotoFinish) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final stage = simState?.stage ??
                          RaceStage(
                            id: report.stageId,
                            stageNumber: report.stageNumber,
                            name: report.stageName,
                            stageType: report.stageType,
                            segments: const [],
                            baseTemperatureCelsius: 20.0,
                            weatherCondition: WeatherCondition.sunny,
                            windSpeedKmh: 15.0,
                          );
                      showPhotoFinishReplayDialog(
                        context,
                        data: PhotoFinishData.fromStageResults(
                          stage: stage,
                          results: report.results,
                        ),
                      );
                    },
                    icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                    label: Text(
                      'POWTÓRKA PHOTO FINISH (Δt = +${(photoFinishGap * 1000).toStringAsFixed(1)} ms)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF003B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Przyciski akcji
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => PostStagePodiumScreen(
                              stageReport: report,
                              simulationState: simState,
                              onContinue: onCloseAndContinue,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.emoji_events, color: AppColors.goldAccent),
                      label: const Text(
                        'Podium i klasyfikacje',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.goldAccent,
                        side: const BorderSide(color: AppColors.goldAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onCloseAndContinue,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text(
                        'Zastosuj i kontynuuj',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSeconds(double totalSec) {
    final int h = totalSec ~/ 3600;
    final int m = (totalSec % 3600) ~/ 60;
    final int s = (totalSec % 60).toInt();
    return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
  }
}

