import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../state/race_simulation_notifier.dart';

/// Perspektywa wyświetlania taktycznej minimapy 2D
enum MinimapPerspective {
  birdEyeRoad('Widok Szosy (Lot Ptaka)', Icons.navigation_outlined),
  elevationProfile('Przekrój Profilu (Pionowy)', Icons.show_chart_rounded),
  hybrid('Widok Hybrydowy (Szosa + Profil)', Icons.layers_outlined);

  final String label;
  final IconData icon;
  const MinimapPerspective(this.label, this.icon);
}

/// Zasięg okna trasy na minimapie
enum MinimapZoomRange {
  zoom2km('2 km (Finisz / Ciasne Nawroty)', 0.8, 1.2),
  zoom5km('5 km (Standard: -2 km / +3 km)', 2.0, 3.0),
  zoom10km('10 km (Makro Taktyczne)', 3.5, 6.5);

  final String label;
  final double pastKm;
  final double futureKm;
  const MinimapZoomRange(this.label, this.pastKm, this.futureKm);

  double get totalWindowKm => pastKm + futureKm;
}

/// Cel centrowania kamery minimapy
enum MinimapFocusTarget {
  playerLeader('Lider Zespołu Gracza', Icons.shield_outlined),
  raceLead('Czoło Wyścigu / Ucieczka', Icons.flash_on_outlined),
  selectedRider('Aktualnie Wybrany Kolarz', Icons.gps_fixed_outlined);

  final String label;
  final IconData icon;
  const MinimapFocusTarget(this.label, this.icon);
}

/// Punkt geometryczny i topograficzny trasy w oknie minimapy
class TacticalRoadPoint {
  final double km;
  final double elevationM;
  final double gradientPercent;
  final SegmentSurfaceType surfaceType;
  final double technicalDifficulty; // 1-100
  final double roadBearingDegrees;
  final double relativeWindAngleDegrees;
  final SegmentClassification sprintOrKom;
  final double roadWidthMeters; // np. 8.0m szeroka szosa, 3.5m zwężenie przed brukiem
  final bool isBrakingZone; // Strefa ostrego dohamowania przed zakrętem
  final bool isHairpin; // Ostry nawrót 180° / serpentyna
  final bool isPinchPoint; // Zwężenie jezdni
  final bool isCobblestones;

  const TacticalRoadPoint({
    required this.km,
    required this.elevationM,
    required this.gradientPercent,
    required this.surfaceType,
    required this.technicalDifficulty,
    required this.roadBearingDegrees,
    required this.relativeWindAngleDegrees,
    required this.sprintOrKom,
    required this.roadWidthMeters,
    required this.isBrakingZone,
    required this.isHairpin,
    required this.isPinchPoint,
    required this.isCobblestones,
  });
}

/// Reprezentacja pociągu drużyny gracza (Lead-out / Mountain train)
class PlayerTeamTrainInfo {
  final List<RiderPositionSnapshot> trainRiders;
  final double averageDraftingSavingsPercent;
  final double totalEstimatedWattsSaved;
  final bool isFormed;

  const PlayerTeamTrainInfo({
    required this.trainRiders,
    required this.averageDraftingSavingsPercent,
    required this.totalEstimatedWattsSaved,
    required this.isFormed,
  });

  int get trainLength => trainRiders.length;
}

/// Zaawansowany widżet interaktywnej minimapy taktycznej 2D podczas wyścigu kolarskiego.
///
/// Prezentuje:
/// - Okno trasy: 2 km wstecz (-2 km) i 3 km do przodu (+3 km) od pozycji akcji.
/// - Widok z lotu ptaka (Bird's-eye): zakręty, nawroty 180° na zjazdach, zwężenia drogi przed brukiem.
/// - Przekrój profilu (Longitudinal elevation cross-section) z nachyleniem % i premiami KOM/Sprint.
/// - Precyzyjne ułożenie pociągu drużyny gracza (Tactical Train) z linią aerodynamiczną i zyskiem draftu.
/// - Pozycje rywali i formacje wachlarzy (echelons) na wietrze bocznym.
class TacticalMinimap2dWidget extends ConsumerStatefulWidget {
  final RaceStage? stage;
  final List<RiderPositionSnapshot>? riderSnapshots;
  final List<String>? playerRiderIds;
  final String? selectedRiderId;
  final double? referenceKm;
  final String? playerTeamJerseyColorHex;
  final ValueChanged<String>? onRiderSelected;
  final MinimapPerspective initialPerspective;
  final bool isCompact;
  final double? width;
  final double? height;

  const TacticalMinimap2dWidget({
    super.key,
    this.stage,
    this.riderSnapshots,
    this.playerRiderIds,
    this.selectedRiderId,
    this.referenceKm,
    this.playerTeamJerseyColorHex,
    this.onRiderSelected,
    this.initialPerspective = MinimapPerspective.hybrid,
    this.isCompact = false,
    this.width,
    this.height,
  });

  @override
  ConsumerState<TacticalMinimap2dWidget> createState() => _TacticalMinimap2dWidgetState();
}

class _TacticalMinimap2dWidgetState extends ConsumerState<TacticalMinimap2dWidget> {
  late MinimapPerspective _perspective;
  MinimapZoomRange _zoom = MinimapZoomRange.zoom5km;
  final MinimapFocusTarget _focusTarget = MinimapFocusTarget.playerLeader;
  bool _isExpanded = false;
  String? _inspectedRiderId;

  @override
  void initState() {
    super.initState();
    _perspective = widget.initialPerspective;
    _isExpanded = !widget.isCompact;
  }

  @override
  Widget build(BuildContext context) {
    // 1. Pobieramy dane z parametrów lub z nadrzędnego Riverpod State
    final simUiState = ref.watch(raceSimulationProvider);

    final activeStage = widget.stage ?? simUiState.stage;
    final allRiders = widget.riderSnapshots ?? simUiState.riderPositions;
    final playerIds = widget.playerRiderIds ??
        (simUiState.simulationState?.playerRiderIds ??
            simUiState.playerRiderStates.map((r) => r.riderId).toList());
    final activeSelectedId = widget.selectedRiderId ?? simUiState.selectedRiderId;
    final teamColorHex = widget.playerTeamJerseyColorHex ??
        (simUiState.playerRidersPositions.isNotEmpty
            ? simUiState.playerRidersPositions.first.teamJerseyHexColor
            : '#D4AF37');

    if (activeStage == null || allRiders.isEmpty) {
      return Container(
        height: widget.height ?? 180,
        width: widget.width,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Center(
          child: Text(
            'Brak aktywnego etapu wyścigu dla minimapy taktycznej.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ),
      );
    }

    // 2. Określamy punkt odniesienia kilometrażu (Reference Km)
    double refKm = widget.referenceKm ?? simUiState.leadDistanceKm;
    if (_focusTarget == MinimapFocusTarget.playerLeader) {
      final leader = allRiders.where((r) => playerIds.contains(r.riderId)).toList();
      if (leader.isNotEmpty) {
        leader.sort((a, b) => b.distanceCoveredMeters.compareTo(a.distanceCoveredMeters));
        refKm = leader.first.kilometerMark;
      }
    } else if (_focusTarget == MinimapFocusTarget.selectedRider && activeSelectedId != null) {
      final sel = allRiders.where((r) => r.riderId == activeSelectedId).toList();
      if (sel.isNotEmpty) {
        refKm = sel.first.kilometerMark;
      }
    } else {
      refKm = simUiState.leadDistanceKm;
    }

    final double windowStartKm = math.max(0.0, refKm - _zoom.pastKm);
    final double windowEndKm = math.min(activeStage.totalDistanceKm, refKm + _zoom.futureKm);

    // 3. Generujemy punkty trasy i geometrię w oknie
    final roadPoints = _generateRoadGeometry(activeStage, windowStartKm, windowEndKm);

    // 4. Filtrujemy kolarzy znajdujących się w oknie [-pastKm, +futureKm]
    final ridersInWindow = allRiders.where((r) {
      return r.kilometerMark >= windowStartKm - 0.2 && r.kilometerMark <= windowEndKm + 0.2;
    }).toList();

    // 5. Wykrywamy pociąg drużyny gracza (Tactical Train)
    final playerTrain = _detectPlayerTrain(allRiders, playerIds);

    // 6. Pobieramy segment i warunki wiatru
    final currentSeg = simUiState.currentSegment;
    final windKmh = activeStage.windSpeedKmh;
    final windBearing = currentSeg?.windDirectionDegrees ?? 90.0;
    final roadBearing = currentSeg?.roadBearingDegrees ?? 0.0;

    final containerHeight = widget.height ?? (_isExpanded ? 320.0 : 210.0);

    return Container(
      width: widget.width,
      height: containerHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF0C0F17).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // GŁÓWNE PŁÓTNO MINIMAPY (CustomPainter)
            Positioned.fill(
              child: GestureDetector(
                onTapUp: (details) {
                  _handleMinimapTap(
                    details.localPosition,
                    roadPoints,
                    ridersInWindow,
                    windowStartKm,
                    windowEndKm,
                    playerIds,
                  );
                },
                child: CustomPaint(
                  painter: TacticalMinimapPainter(
                    roadPoints: roadPoints,
                    riders: ridersInWindow,
                    playerRiderIds: playerIds,
                    selectedRiderId: _inspectedRiderId ?? activeSelectedId,
                    playerTrain: playerTrain,
                    referenceKm: refKm,
                    windowStartKm: windowStartKm,
                    windowEndKm: windowEndKm,
                    stageTotalKm: activeStage.totalDistanceKm,
                    perspective: _perspective,
                    playerTeamJerseyColorHex: teamColorHex,
                    windSpeedKmh: windKmh,
                    windDirectionDegrees: windBearing,
                    roadBearingDegrees: roadBearing,
                  ),
                ),
              ),
            ),

            // GÓRNY PASEK KONTROLEK TAKTYCZNYCH
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildMinimapHeader(
                refKm: refKm,
                stageTotalKm: activeStage.totalDistanceKm,
                windKmh: windKmh,
                currentSegment: currentSeg,
                playerTrain: playerTrain,
              ),
            ),

            // DOLNY PASEK STATUSU ODCINKA I ZWĘŻEŃ
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildMinimapFooterBar(
                roadPoints: roadPoints,
                currentSegment: currentSeg,
                playerTrain: playerTrain,
              ),
            ),

            // PŁYWAJĄCY TOOLTIP INSPEKCJI KOLARZA (JEŚLI KLIKNIĘTO)
            if (_inspectedRiderId != null)
              Positioned(
                top: 50,
                right: 12,
                child: _buildInspectedRiderCard(
                  allRiders.firstWhere((r) => r.riderId == _inspectedRiderId, orElse: () => allRiders.first),
                  playerIds.contains(_inspectedRiderId),
                  () => setState(() => _inspectedRiderId = null),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // NAGŁÓWEK KONTROLEK MINIMAPY
  // ===========================================================================

  Widget _buildMinimapHeader({
    required double refKm,
    required double stageTotalKm,
    required double windKmh,
    required StageSegment? currentSegment,
    required PlayerTeamTrainInfo playerTrain,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.90),
        border: const Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tytuł i kilometraż
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.radar_rounded, size: 15, color: AppColors.goldAccent),
                      const SizedBox(width: 6),
                      const Text(
                        'RADAR 2D',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                          color: AppColors.goldAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Text(
                          '${refKm.toStringAsFixed(1)} km / ${stageTotalKm.toStringAsFixed(1)} km',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),

                  // Pigułka pociągu drużyny gracza
                  if (playerTrain.isFormed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.emeraldGreen, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.train_outlined, size: 12, color: AppColors.emeraldGreen),
                          const SizedBox(width: 4),
                          Text(
                            'POCIĄG: ${playerTrain.trainLength} (Aero +${playerTrain.averageDraftingSavingsPercent.toStringAsFixed(0)}%)',
                            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.emeraldGreen),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Przełącznik perspektyw (Szosa / Profil / Hybryda)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: MinimapPerspective.values.map((persp) {
                final isSelected = _perspective == persp;
                return InkWell(
                  onTap: () => setState(() => _perspective = persp),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.goldAccent : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      persp.icon,
                      size: 13,
                      color: isSelected ? Colors.black : AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 6),

          // Wybór zoomu (2km / 5km / 10km)
          DropdownButtonHideUnderline(
            child: DropdownButton<MinimapZoomRange>(
              value: _zoom,
              dropdownColor: AppColors.surface,
              style: const TextStyle(fontSize: 10, color: AppColors.textPrimary),
              icon: const Icon(Icons.arrow_drop_down, size: 14, color: AppColors.textSecondary),
              onChanged: (val) {
                if (val != null) setState(() => _zoom = val);
              },
              items: MinimapZoomRange.values.map((z) {
                return DropdownMenuItem(
                  value: z,
                  child: Text(z.name.replaceAll('zoom', '')),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 4),

          // Przycisk rozwijania wysokości
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                _isExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DOLNY PASEK STATUSU ODCINKA (ZWĘŻENIA, NAWROTY, NAWIERZCHNIA)
  // ===========================================================================

  Widget _buildMinimapFooterBar({
    required List<TacticalRoadPoint> roadPoints,
    required StageSegment? currentSegment,
    required PlayerTeamTrainInfo playerTrain,
  }) {
    // Sprawdzamy, czy w najbliższych 3 km jest ostre zwężenie lub nawrót
    final upcomingPinch = roadPoints.where((p) => p.isPinchPoint).toList();
    final upcomingHairpins = roadPoints.where((p) => p.isHairpin).toList();
    final upcomingCobbles = roadPoints.where((p) => p.isCobblestones).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.90),
        border: const Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          // Informacja o nachyleniu i nawierzchni
          if (currentSegment != null) ...[
            Text(
              '${currentSegment.surfaceType.name.toUpperCase()}  •  ${currentSegment.gradientPercent.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 8),
          ],

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Alerty taktyczne
                  if (upcomingHairpins.isNotEmpty)
                    _buildTacticalAlertBadge(
                      icon: Icons.turn_sharp_right,
                      label: 'NAWRÓT 180° za ${(upcomingHairpins.first.km - (roadPoints.isNotEmpty ? roadPoints.first.km : 0)).abs().toStringAsFixed(1)} km',
                      color: AppColors.crimsonAlert,
                    ),
                  if (upcomingPinch.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _buildTacticalAlertBadge(
                      icon: Icons.compress,
                      label: 'ZWĘŻENIE DROGI (8m ➔ 3.5m)',
                      color: AppColors.amberWarning,
                    ),
                  ],
                  if (upcomingCobbles.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _buildTacticalAlertBadge(
                      icon: Icons.grid_view_sharp,
                      label: 'SEKTOR BRUKU (PAVÉ)',
                      color: const Color(0xFFD97706),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalAlertBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // KARTA INSPEKCJI KLIKNIĘTEGO KOLARZA NA MINIMAPIE
  // ===========================================================================

  Widget _buildInspectedRiderCard(
    RiderPositionSnapshot rider,
    bool isPlayerRider,
    VoidCallback onClose,
  ) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPlayerRider ? AppColors.goldAccent : AppTheme.borderColor,
          width: isPlayerRider ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 6,
                backgroundColor: isPlayerRider ? AppColors.goldAccent : AppColors.cyanAccent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  rider.riderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              InkWell(
                onTap: onClose,
                child: const Icon(Icons.close, size: 14, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${rider.teamName}  •  #${rider.bibNumber}',
            style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
          ),
          const Divider(height: 10, color: AppTheme.borderColor),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Moc: ${rider.powerWatts}W (${rider.wattsPerKg.toStringAsFixed(1)} W/kg)',
                  style: const TextStyle(fontSize: 9.5, color: AppColors.textPrimary)),
              Text('${rider.speedKmh.toStringAsFixed(1)} km/h',
                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.cyanAccent)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tętno: ${rider.heartRateBpm} bpm',
                  style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary)),
              Text('Aero draft: -${rider.draftingSavingsPercent.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 9.5, color: AppColors.emeraldGreen)),
            ],
          ),
          if (isPlayerRider) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onRiderSelected?.call(rider.riderId);
                  onClose();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('WYBIERZ KOLARZA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // INTERAKCJA: KLIKNIĘCIE W MINIMAPĘ
  // ===========================================================================

  void _handleMinimapTap(
    Offset tapPos,
    List<TacticalRoadPoint> points,
    List<RiderPositionSnapshot> riders,
    double windowStartKm,
    double windowEndKm,
    List<String> playerIds,
  ) {
    if (riders.isEmpty) return;

    // Znajdujemy kolarza najbliższego punktowi dotknięcia na osi X
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;

    const double paddingX = 24.0;
    final double roadUsableWidth = size.width - (paddingX * 2);
    final double totalKm = windowEndKm - windowStartKm;
    if (totalKm <= 0) return;

    RiderPositionSnapshot? closestRider;
    double minDistancePixels = 24.0; // promień tolerancji trafienia w kolarza

    for (final rider in riders) {
      final double normX = ((rider.kilometerMark - windowStartKm) / totalKm).clamp(0.0, 1.0);
      final double riderPx = paddingX + (normX * roadUsableWidth);

      // Y zależy od trybu perspektywy
      double riderPy = size.height * 0.42;
      if (_perspective == MinimapPerspective.elevationProfile) {
        riderPy = size.height * 0.50;
      } else if (_perspective == MinimapPerspective.birdEyeRoad) {
        final roadCenterY = size.height * 0.50;
        riderPy = roadCenterY + (rider.lateralPositionRoad * 18.0);
      }

      final dist = (tapPos - Offset(riderPx, riderPy)).distance;
      if (dist < minDistancePixels) {
        minDistancePixels = dist;
        closestRider = rider;
      }
    }

    if (closestRider != null) {
      setState(() => _inspectedRiderId = closestRider!.riderId);
      widget.onRiderSelected?.call(closestRider.riderId);
    }
  }

  // ===========================================================================
  // GENEROWANIE DANYCH GEOMETRII SZOSY DLA OKNA 5 KM
  // ===========================================================================

  List<TacticalRoadPoint> _generateRoadGeometry(
    RaceStage stage,
    double startKm,
    double endKm,
  ) {
    final points = <TacticalRoadPoint>[];
    const double stepKm = 0.05; // próbkowanie co 50 metrów

    double cur = startKm;
    while (cur <= endKm) {
      final seg = _findSegmentAtKm(stage, cur);
      final nextSeg = _findSegmentAtKm(stage, cur + 0.15);

      final elev = _interpolateElevation(stage, cur);
      final grad = seg?.gradientPercent ?? 0.0;
      final surf = seg?.surfaceType ?? SegmentSurfaceType.smoothAsphalt;
      final diff = seg?.technicalDifficulty ?? 20.0;
      final bearing = seg?.roadBearingDegrees ?? 0.0;
      final windAngle = seg?.relativeWindAngleDegrees ?? 90.0;
      final sprintOrKom = seg?.sprintOrKomClassification ?? SegmentClassification.none;

      // Wykrywanie ostrych nawrotów 180° i ostrych łuków:
      // Zmiana azymutu szosy o > 120° lub wysoka trudność techniczna na zjeździe
      final bearingDiff = nextSeg != null ? (nextSeg.roadBearingDegrees - bearing).abs() : 0.0;
      final isHairpin = bearingDiff > 110.0 || (diff > 75.0 && grad < -3.0);

      // Strefa dohamowania: 150m przed ostrym nawrotem
      final isBraking = isHairpin || (diff > 80.0 && grad < -4.0);

      // Wykrywanie zwężeń drogi (np. z 8m do 3.5m przed brukiem lub mostkiem)
      final isCobbles = seg?.isCobblestone ?? false;
      final isPinch = isCobbles || (diff > 65.0);
      final roadWidth = isPinch ? 3.8 : 8.0;

      points.add(TacticalRoadPoint(
        km: cur,
        elevationM: elev,
        gradientPercent: grad,
        surfaceType: surf,
        technicalDifficulty: diff,
        roadBearingDegrees: bearing,
        relativeWindAngleDegrees: windAngle,
        sprintOrKom: sprintOrKom,
        roadWidthMeters: roadWidth,
        isBrakingZone: isBraking,
        isHairpin: isHairpin,
        isPinchPoint: isPinch,
        isCobblestones: isCobbles,
      ));

      cur += stepKm;
    }

    return points;
  }

  StageSegment? _findSegmentAtKm(RaceStage stage, double km) {
    for (final s in stage.segments) {
      if (km >= s.startKm && km <= s.endKm) return s;
    }
    return stage.segments.isNotEmpty ? stage.segments.last : null;
  }

  double _interpolateElevation(RaceStage stage, double km) {
    final seg = _findSegmentAtKm(stage, km);
    if (seg == null) return 0.0;
    final progress = ((km - seg.startKm) / seg.lengthKm).clamp(0.0, 1.0);
    return seg.startElevationM + (progress * (seg.endElevationM - seg.startElevationM));
  }

  // ===========================================================================
  // WYKRYWANIE POCIĄGU DRUŻYNY GRACZA (LEAD-OUT / MOUNTAIN TRAIN)
  // ===========================================================================

  PlayerTeamTrainInfo _detectPlayerTrain(
    List<RiderPositionSnapshot> allRiders,
    List<String> playerIds,
  ) {
    final playerRiders = allRiders.where((r) => playerIds.contains(r.riderId)).toList();
    if (playerRiders.length < 2) {
      return const PlayerTeamTrainInfo(
        trainRiders: [],
        averageDraftingSavingsPercent: 0.0,
        totalEstimatedWattsSaved: 0.0,
        isFormed: false,
      );
    }

    // Sortujemy kolarzy od czoła do ogona (malejący dystans)
    playerRiders.sort((a, b) => b.distanceCoveredMeters.compareTo(a.distanceCoveredMeters));

    final inTrain = <RiderPositionSnapshot>[];
    for (int i = 0; i < playerRiders.length - 1; i++) {
      final current = playerRiders[i];
      final next = playerRiders[i + 1];

      final distDiff = (current.distanceCoveredMeters - next.distanceCoveredMeters).abs();
      final lateralDiff = (current.lateralPositionRoad - next.lateralPositionRoad).abs();

      // Kolarze tworzą szyk pociągu, jeśli jadą w odległości < 16m i w podobnej linii bocznej
      if (distDiff < 16.0 && lateralDiff < 0.6) {
        if (!inTrain.contains(current)) inTrain.add(current);
        if (!inTrain.contains(next)) inTrain.add(next);
      }
    }

    final isFormed = inTrain.length >= 2;
    double avgSavings = 0.0;
    double wattsSaved = 0.0;

    if (isFormed) {
      avgSavings = inTrain.map((r) => r.draftingSavingsPercent).reduce((a, b) => a + b) / inTrain.length;
      wattsSaved = inTrain.fold(0.0, (sum, r) => sum + (r.powerWatts * (r.draftingSavingsPercent / 100.0)));
    }

    return PlayerTeamTrainInfo(
      trainRiders: inTrain,
      averageDraftingSavingsPercent: avgSavings,
      totalEstimatedWattsSaved: wattsSaved,
      isFormed: isFormed,
    );
  }
}

// =============================================================================
// GŁÓWNY CUSTOM PAINTER DLA MINIMAPY TAKTYCZNEJ 2D
// =============================================================================

class TacticalMinimapPainter extends CustomPainter {
  final List<TacticalRoadPoint> roadPoints;
  final List<RiderPositionSnapshot> riders;
  final List<String> playerRiderIds;
  final String? selectedRiderId;
  final PlayerTeamTrainInfo playerTrain;
  final double referenceKm;
  final double windowStartKm;
  final double windowEndKm;
  final double stageTotalKm;
  final MinimapPerspective perspective;
  final String playerTeamJerseyColorHex;
  final double windSpeedKmh;
  final double windDirectionDegrees;
  final double roadBearingDegrees;

  TacticalMinimapPainter({
    required this.roadPoints,
    required this.riders,
    required this.playerRiderIds,
    required this.selectedRiderId,
    required this.playerTrain,
    required this.referenceKm,
    required this.windowStartKm,
    required this.windowEndKm,
    required this.stageTotalKm,
    required this.perspective,
    required this.playerTeamJerseyColorHex,
    required this.windSpeedKmh,
    required this.windDirectionDegrees,
    required this.roadBearingDegrees,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (roadPoints.isEmpty) return;

    const double padX = 20.0;
    const double topPad = 32.0;
    const double bottomPad = 26.0;
    final double usableW = size.width - (padX * 2);
    final double totalWindowKm = math.max(0.1, windowEndKm - windowStartKm);

    // 1. Tło siatki współrzędnych i linii dystansu (-2km, -1km, 0km, +1km, +2km, +3km)
    _paintGridAndDistanceTicks(canvas, size, padX, topPad, bottomPad, usableW, totalWindowKm);

    // 2. Renderowanie w zależności od wybranej perspektywy
    if (perspective == MinimapPerspective.birdEyeRoad) {
      // Pełny widok szosy z lotu ptaka (Szerokość, zakręty, nawroty, zwężenia, formacje)
      final roadCenterY = (topPad + size.height - bottomPad) / 2.0;
      final roadHeight = size.height * 0.45;
      _paintBirdEyeRoadView(canvas, size, padX, roadCenterY, roadHeight, usableW, totalWindowKm);
      _paintRidersOnRoad(canvas, size, padX, roadCenterY, roadHeight, usableW, totalWindowKm);
    } else if (perspective == MinimapPerspective.elevationProfile) {
      // Przekrój profilu wysokościowego (-2 km do +3 km z gradientem %)
      _paintElevationProfileView(canvas, size, padX, topPad + 8, size.height - bottomPad - 8, usableW, totalWindowKm);
      _paintRidersOnProfile(canvas, size, padX, topPad + 8, size.height - bottomPad - 8, usableW, totalWindowKm);
    } else {
      // Widok hybrydowy (Góra 58% Szosa z zakrętami i pociągiem + Dół 42% Profil wysokości)
      final splitY = topPad + ((size.height - topPad - bottomPad) * 0.58);
      final roadCenterY = (topPad + splitY) / 2.0;
      final roadHeight = (splitY - topPad) * 0.72;

      _paintBirdEyeRoadView(canvas, size, padX, roadCenterY, roadHeight, usableW, totalWindowKm);
      _paintRidersOnRoad(canvas, size, padX, roadCenterY, roadHeight, usableW, totalWindowKm);

      // Linia podziału
      final dividerPaint = Paint()
        ..color = AppTheme.borderColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(padX, splitY), Offset(size.width - padX, splitY), dividerPaint);

      // Dolny mikroprofil wysokościowy
      _paintElevationProfileView(canvas, size, padX, splitY + 4, size.height - bottomPad - 2, usableW, totalWindowKm);
    }

    // 3. Wskaźnik kompasu wiatru i wachlarza w prawym dolnym rogu
    _paintWindCompass(canvas, size);
  }

  // ===========================================================================
  // 1. SIATKA WSPÓŁRZĘDNYCH I TYKI DYSTANSU
  // ===========================================================================

  void _paintGridAndDistanceTicks(
    Canvas canvas,
    Size size,
    double padX,
    double topPad,
    double bottomPad,
    double usableW,
    double totalKm,
  ) {
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final refNormX = ((referenceKm - windowStartKm) / totalKm).clamp(0.0, 1.0);
    final refPx = padX + (refNormX * usableW);

    // Główna linia referencyjna (Aktualna pozycja kolarza / czoła: 0 km)
    final refLinePaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(refPx, topPad), Offset(refPx, size.height - bottomPad), refLinePaint);

    // Etykieta pozycji 0 km
    _drawText(
      canvas,
      'POZYCJA',
      Offset(refPx, size.height - bottomPad + 3),
      const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.goldAccent),
      isCentered: true,
    );

    // Kreski dystansowe co 1 km
    int startInt = windowStartKm.floor();
    int endInt = windowEndKm.ceil();

    for (int k = startInt; k <= endInt; k++) {
      if (k < 0 || k > stageTotalKm) continue;
      final kmVal = k.toDouble();
      final normX = (kmVal - windowStartKm) / totalKm;
      if (normX < 0.0 || normX > 1.0) continue;

      final px = padX + (normX * usableW);
      if ((px - refPx).abs() < 20) continue; // nie nakładamy na linię referencyjną

      canvas.drawLine(Offset(px, topPad), Offset(px, size.height - bottomPad), tickPaint);

      final relDiff = kmVal - referenceKm;
      final String sign = relDiff > 0 ? '+${relDiff.toStringAsFixed(0)}k' : '${relDiff.toStringAsFixed(0)}k';
      final String label = (relDiff.abs() < 0.1) ? '0k' : sign;

      _drawText(
        canvas,
        label,
        Offset(px, size.height - bottomPad + 3),
        TextStyle(fontSize: 8, color: Colors.white.withValues(alpha: 0.35)),
        isCentered: true,
      );
    }
  }

  // ===========================================================================
  // 2. WIDOK Z LOTU PTAKA: SZOSA, ZAKRĘTY, NAWROTY 180°, ZWĘŻENIA
  // ===========================================================================

  void _paintBirdEyeRoadView(
    Canvas canvas,
    Size size,
    double padX,
    double roadCenterY,
    double roadBaseHeight,
    double usableW,
    double totalKm,
  ) {
    if (roadPoints.length < 2) return;

    // Rysujemy segmenty szosy z dynamiczną krzywizną i szerokością
    final roadPath = Path();
    final leftShoulderPath = Path();
    final rightShoulderPath = Path();

    // Wyliczamy punkty osi i szerokości drogi
    final List<Offset> centerOffsets = [];
    final List<double> roadHalfWidths = [];

    for (int i = 0; i < roadPoints.length; i++) {
      final pt = roadPoints[i];
      final normX = ((pt.km - windowStartKm) / totalKm).clamp(0.0, 1.0);
      final px = padX + (normX * usableW);

      // Krzywizna drogi (S-curves i nawroty 180°):
      // Wprowadzamy odchylenie Y na podstawie azymutu i trudności
      double py = roadCenterY;
      if (pt.isHairpin) {
        // Ostry nawrót 180° - serpentyna wychylająca szosę w górę lub w dół
        final wave = math.sin((pt.km * 18.0)) * (roadBaseHeight * 0.40);
        py += wave;
      } else if (pt.technicalDifficulty > 45.0) {
        final wave = math.sin(pt.km * 10.0) * (roadBaseHeight * 0.18);
        py += wave;
      }

      centerOffsets.add(Offset(px, py));

      // Szerokość drogi: normalna 8m (~roadBaseHeight * 0.38), zwężenie 3.5m (~roadBaseHeight * 0.18)
      final halfWidth = (pt.roadWidthMeters / 8.0) * (roadBaseHeight * 0.38);
      roadHalfWidths.add(halfWidth);
    }

    // Konstruujemy wielokąt szosy (lewa krawędź do przodu, prawa wstecz)
    for (int i = 0; i < centerOffsets.length; i++) {
      final c = centerOffsets[i];
      final hw = roadHalfWidths[i];
      final leftPoint = Offset(c.dx, c.dy - hw);
      if (i == 0) {
        roadPath.moveTo(leftPoint.dx, leftPoint.dy);
        leftShoulderPath.moveTo(leftPoint.dx, leftPoint.dy);
      } else {
        roadPath.lineTo(leftPoint.dx, leftPoint.dy);
        leftShoulderPath.lineTo(leftPoint.dx, leftPoint.dy);
      }
    }

    for (int i = centerOffsets.length - 1; i >= 0; i--) {
      final c = centerOffsets[i];
      final hw = roadHalfWidths[i];
      final rightPoint = Offset(c.dx, c.dy + hw);
      roadPath.lineTo(rightPoint.dx, rightPoint.dy);
      if (i == centerOffsets.length - 1) {
        rightShoulderPath.moveTo(rightPoint.dx, rightPoint.dy);
      } else {
        rightShoulderPath.lineTo(rightPoint.dx, rightPoint.dy);
      }
    }
    roadPath.close();

    // Wypełnienie nawierzchni szosy (ciemny grafit dla asfaltu)
    final asphaltPaint = Paint()
      ..color = const Color(0xFF1E2330)
      ..style = PaintingStyle.fill;
    canvas.drawPath(roadPath, asphaltPaint);

    // Krawędzie jezdni (Białe linie krawędziowe)
    final shoulderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(leftShoulderPath, shoulderPaint);
    canvas.drawPath(rightShoulderPath, shoulderPaint);

    // Oś jezdni (Przerywana linia środkowa)
    final centerLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < centerOffsets.length - 1; i += 2) {
      canvas.drawLine(centerOffsets[i], centerOffsets[i + 1], centerLinePaint);
    }

    // Rysujemy strefy specjalne: BRUK (Pavé), ZWĘŻENIA i NAWROTY 180°
    _paintSpecialRoadFeatures(canvas, roadPoints, centerOffsets, roadHalfWidths);
  }

  void _paintSpecialRoadFeatures(
    Canvas canvas,
    List<TacticalRoadPoint> points,
    List<Offset> centerOffsets,
    List<double> roadHalfWidths,
  ) {
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final c = centerOffsets[i];
      final hw = roadHalfWidths[i];

      // 1. Oznaczenie SEKTORA BRUKOWANEGO (Kostka Pavé)
      if (pt.isCobblestones) {
        final cobbleRect = Rect.fromCenter(center: c, width: 8, height: hw * 2);
        canvas.drawRect(
          cobbleRect,
          Paint()..color = const Color(0xFFD97706).withValues(alpha: 0.22),
        );
      }

      // 2. Oznaczenie ZWĘŻENIA DROGI (Pinch Point)
      if (pt.isPinchPoint && (i % 6 == 0)) {
        // Pasy ostrzegawcze na poboczach
        canvas.drawLine(
          Offset(c.dx, c.dy - hw - 2),
          Offset(c.dx + 4, c.dy - hw + 2),
          Paint()..color = AppColors.amberWarning..strokeWidth = 1.5,
        );
        canvas.drawLine(
          Offset(c.dx, c.dy + hw - 2),
          Offset(c.dx + 4, c.dy + hw + 2),
          Paint()..color = AppColors.amberWarning..strokeWidth = 1.5,
        );
      }

      // 3. Strefa dohamowania i ostry nawrót 180°
      if (pt.isHairpin && (i % 8 == 0)) {
        // Czerwona strefa dohamowania
        canvas.drawCircle(
          c,
          hw * 0.9,
          Paint()..color = AppColors.crimsonAlert.withValues(alpha: 0.28),
        );
        _drawText(
          canvas,
          '180°',
          Offset(c.dx, c.dy - hw - 11),
          const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.crimsonAlert),
          isCentered: true,
        );
      }
    }
  }

  // ===========================================================================
  // 3. KOLARZE NA SZOSIE: POCIĄG DRUŻYNY, RYFALE, WACHLARZ
  // ===========================================================================

  void _paintRidersOnRoad(
    Canvas canvas,
    Size size,
    double padX,
    double roadCenterY,
    double roadBaseHeight,
    double usableW,
    double totalKm,
  ) {
    final playerTeamColor = _parseColor(playerTeamJerseyColorHex, AppColors.goldAccent);

    // 1. Rysujemy POCIĄG DRUŻYNY GRACZA (Tactical Train Tether)
    if (playerTrain.isFormed && playerTrain.trainRiders.length >= 2) {
      final trainPoints = <Offset>[];

      for (final rider in playerTrain.trainRiders) {
        final normX = ((rider.kilometerMark - windowStartKm) / totalKm).clamp(0.0, 1.0);
        final px = padX + (normX * usableW);
        final py = roadCenterY + (rider.lateralPositionRoad * (roadBaseHeight * 0.32));
        trainPoints.add(Offset(px, py));
      }

      // Rysujemy świecącą linię pociągu (Tactical Train Tether)
      final tetherPath = Path();
      for (int i = 0; i < trainPoints.length; i++) {
        if (i == 0) {
          tetherPath.moveTo(trainPoints[i].dx, trainPoints[i].dy);
        } else {
          tetherPath.lineTo(trainPoints[i].dx, trainPoints[i].dy);
        }
      }

      // Poświata aero
      canvas.drawPath(
        tetherPath,
        Paint()
          ..color = AppColors.emeraldGreen.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Główna lina pociągu
      canvas.drawPath(
        tetherPath,
        Paint()
          ..color = AppColors.emeraldGreen
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    // 2. Rysujemy kolarzy rywali (Peleton / Ucieczka)
    for (final rider in riders) {
      if (playerRiderIds.contains(rider.riderId)) continue; // gracza rysujemy później na wierzchu

      final normX = ((rider.kilometerMark - windowStartKm) / totalKm).clamp(0.0, 1.0);
      final px = padX + (normX * usableW);
      final py = roadCenterY + (rider.lateralPositionRoad * (roadBaseHeight * 0.32));

      // Dyskretna kropka rywala
      final rivalColor = rider.groupIndex == 0 ? AppColors.cyanAccent : const Color(0xFF64748B);
      canvas.drawCircle(Offset(px, py), 2.5, Paint()..color = rivalColor.withValues(alpha: 0.85));
    }

    // 3. Rysujemy kolarzy drużyny gracza (wyróżnieni i powiększeni)
    for (final rider in riders) {
      if (!playerRiderIds.contains(rider.riderId)) continue;

      final normX = ((rider.kilometerMark - windowStartKm) / totalKm).clamp(0.0, 1.0);
      final px = padX + (normX * usableW);
      final py = roadCenterY + (rider.lateralPositionRoad * (roadBaseHeight * 0.32));
      final isSelected = rider.riderId == selectedRiderId;

      // Stożek osłony aerodynamicznej za kolarzem
      final slipstreamPaint = Paint()
        ..color = AppColors.emeraldGreen.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill;
      final conePath = Path()
        ..moveTo(px, py - 3)
        ..lineTo(px - 14, py - 8)
        ..lineTo(px - 14, py + 8)
        ..lineTo(px, py + 3)
        ..close();
      canvas.drawPath(conePath, slipstreamPaint);

      // Poświata kolarza gracza
      canvas.drawCircle(
        Offset(px, py),
        isSelected ? 8.5 : 6.0,
        Paint()..color = playerTeamColor.withValues(alpha: 0.35),
      );

      // Kolarz gracza
      canvas.drawCircle(
        Offset(px, py),
        isSelected ? 5.5 : 4.5,
        Paint()..color = playerTeamColor,
      );
      canvas.drawCircle(
        Offset(px, py),
        isSelected ? 5.5 : 4.5,
        Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.0,
      );

      // Numer bib kolarza gracza
      _drawText(
        canvas,
        '#${rider.bibNumber}',
        Offset(px, py - 11),
        TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : AppColors.goldAccent,
        ),
        isCentered: true,
      );
    }
  }

  // ===========================================================================
  // 4. PRZEKRÓJ PROFILU WYSOKOŚCIOWEGO
  // ===========================================================================

  void _paintElevationProfileView(
    Canvas canvas,
    Size size,
    double padX,
    double topY,
    double bottomY,
    double usableW,
    double totalKm,
  ) {
    if (roadPoints.length < 2) return;

    double minAlt = roadPoints.first.elevationM;
    double maxAlt = roadPoints.first.elevationM;
    for (final p in roadPoints) {
      if (p.elevationM < minAlt) minAlt = p.elevationM;
      if (p.elevationM > maxAlt) maxAlt = p.elevationM;
    }

    // Margines pionowy dla czytelności profilu
    minAlt = math.max(0.0, minAlt - 30.0);
    maxAlt = maxAlt + 40.0;
    final double altRange = math.max(50.0, maxAlt - minAlt);
    final double profileHeight = bottomY - topY;

    final profilePath = Path();
    final List<Offset> profileOffsets = [];

    for (int i = 0; i < roadPoints.length; i++) {
      final pt = roadPoints[i];
      final normX = ((pt.km - windowStartKm) / totalKm).clamp(0.0, 1.0);
      final px = padX + (normX * usableW);
      final normY = ((pt.elevationM - minAlt) / altRange).clamp(0.0, 1.0);
      final py = bottomY - (normY * profileHeight);

      profileOffsets.add(Offset(px, py));
      if (i == 0) {
        profilePath.moveTo(px, py);
      } else {
        profilePath.lineTo(px, py);
      }
    }

    // Zamknięcie obszaru profilu do dołu
    final filledAreaPath = Path.from(profilePath);
    filledAreaPath.lineTo(padX + usableW, bottomY);
    filledAreaPath.lineTo(padX, bottomY);
    filledAreaPath.close();

    // Kolorowanie gradientowe profilu
    final gradPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _getGradientColor(roadPoints.first.gradientPercent).withValues(alpha: 0.45),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(padX, topY, usableW, profileHeight));
    canvas.drawPath(filledAreaPath, gradPaint);

    // Linia wierzchu profilu
    final strokePaint = Paint()
      ..color = AppColors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(profilePath, strokePaint);

    // Oznaczenia premii KOM, Sprint i Mety na profilu
    for (final pt in roadPoints) {
      if (pt.sprintOrKom != SegmentClassification.none) {
        final normX = ((pt.km - windowStartKm) / totalKm).clamp(0.0, 1.0);
        final px = padX + (normX * usableW);
        final normY = ((pt.elevationM - minAlt) / altRange).clamp(0.0, 1.0);
        final py = bottomY - (normY * profileHeight);

        _drawKomOrSprintBanner(canvas, Offset(px, py), pt.sprintOrKom);
      }
    }
  }

  void _paintRidersOnProfile(
    Canvas canvas,
    Size size,
    double padX,
    double topY,
    double bottomY,
    double usableW,
    double totalKm,
  ) {
    if (roadPoints.isEmpty) return;

    double minAlt = roadPoints.first.elevationM;
    double maxAlt = roadPoints.first.elevationM;
    for (final p in roadPoints) {
      if (p.elevationM < minAlt) minAlt = p.elevationM;
      if (p.elevationM > maxAlt) maxAlt = p.elevationM;
    }
    minAlt = math.max(0.0, minAlt - 30.0);
    maxAlt = maxAlt + 40.0;
    final double altRange = math.max(50.0, maxAlt - minAlt);
    final double profileHeight = bottomY - topY;

    final playerTeamColor = _parseColor(playerTeamJerseyColorHex, AppColors.goldAccent);

    for (final rider in riders) {
      final isPlayer = playerRiderIds.contains(rider.riderId);
      final normX = ((rider.kilometerMark - windowStartKm) / totalKm).clamp(0.0, 1.0);
      final px = padX + (normX * usableW);
      final normY = ((rider.elevationMeters - minAlt) / altRange).clamp(0.0, 1.0);
      final py = bottomY - (normY * profileHeight);

      if (isPlayer) {
        canvas.drawCircle(Offset(px, py), 5.5, Paint()..color = playerTeamColor);
        canvas.drawCircle(Offset(px, py), 5.5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.2);
        _drawText(
          canvas,
          '#${rider.bibNumber}',
          Offset(px, py - 12),
          const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.goldAccent),
          isCentered: true,
        );
      } else {
        canvas.drawCircle(Offset(px, py), 2.5, Paint()..color = Colors.white.withValues(alpha: 0.6));
      }
    }
  }

  // ===========================================================================
  // 5. KOMPAS WIATRU I WACHLARZA (ECHELON)
  // ===========================================================================

  void _paintWindCompass(Canvas canvas, Size size) {
    final compassCenter = Offset(size.width - 24, size.height - 48);
    const radius = 12.0;

    // Tło kompasu
    canvas.drawCircle(
      compassCenter,
      radius,
      Paint()..color = AppColors.surfaceLight.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      compassCenter,
      radius,
      Paint()..color = AppTheme.borderColor..style = PaintingStyle.stroke..strokeWidth = 0.8,
    );

    // Kąt wiatru względem drogi (radiany)
    final relAngleRad = (windDirectionDegrees - roadBearingDegrees) * (math.pi / 180.0);
    final windVector = Offset(math.sin(relAngleRad) * 9.0, -math.cos(relAngleRad) * 9.0);

    // Strzałka wektora wiatru
    final arrowPaint = Paint()
      ..color = AppColors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawLine(compassCenter - (windVector * 0.4), compassCenter + windVector, arrowPaint);
    canvas.drawCircle(compassCenter + windVector, 1.5, Paint()..color = AppColors.cyanAccent);
  }

  void _drawKomOrSprintBanner(Canvas canvas, Offset pos, SegmentClassification classification) {
    final bool isSprint = classification == SegmentClassification.intermediateSprint;
    final color = isSprint ? AppColors.emeraldGreen : AppColors.crimsonAlert;
    final label = isSprint ? 'S' : 'KOM';

    // Maszt flagi
    canvas.drawLine(pos, Offset(pos.dx, pos.dy - 16), Paint()..color = Colors.white70..strokeWidth = 1.0);

    // Flaga
    final flagRect = Rect.fromLTWH(pos.dx, pos.dy - 16, 16, 9);
    canvas.drawRect(flagRect, Paint()..color = color);

    _drawText(
      canvas,
      label,
      Offset(pos.dx + 8, pos.dy - 15),
      const TextStyle(fontSize: 6.5, fontWeight: FontWeight.bold, color: Colors.white),
      isCentered: true,
    );
  }

  Color _getGradientColor(double grad) {
    if (grad < -2.0) return AppColors.cyanAccent; // zjazd
    if (grad < 3.0) return AppColors.emeraldGreen; // płasko
    if (grad < 7.0) return AppColors.amberWarning; // umiarkowany
    if (grad < 11.0) return const Color(0xFFF97316); // stromy
    return AppColors.crimsonAlert; // ściana
  }

  Color _parseColor(String hex, Color fallback) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return fallback;
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    TextStyle style, {
    bool isCentered = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    final drawPos = isCentered ? Offset(position.dx - (tp.width / 2), position.dy) : position;
    tp.paint(canvas, drawPos);
  }

  @override
  bool shouldRepaint(covariant TacticalMinimapPainter oldDelegate) {
    return oldDelegate.referenceKm != referenceKm ||
        oldDelegate.windowStartKm != windowStartKm ||
        oldDelegate.windowEndKm != windowEndKm ||
        oldDelegate.perspective != perspective ||
        oldDelegate.selectedRiderId != selectedRiderId ||
        oldDelegate.riders.length != riders.length ||
        oldDelegate.playerTrain.isFormed != playerTrain.isFormed ||
        oldDelegate.windSpeedKmh != windSpeedKmh;
  }
}
