import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/simulation/stage_simulation_loop.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';

/// Górny pasek statusowy HUD w trakcie symulacji wyścigu 3D.
class RaceTopHudBar extends StatelessWidget {
  final RaceStage stage;
  final double currentLeadKm;
  final double elapsedSeconds;
  final StageSegment? currentSegment;
  final SimulationTimeSpeed currentSpeed;
  final bool isPaused;
  final Function(SimulationTimeSpeed) onSpeedSelected;
  final VoidCallback onTogglePause;
  final VoidCallback onFastForwardToKeyMoment;

  const RaceTopHudBar({
    super.key,
    required this.stage,
    required this.currentLeadKm,
    required this.elapsedSeconds,
    this.currentSegment,
    required this.currentSpeed,
    required this.isPaused,
    required this.onSpeedSelected,
    required this.onTogglePause,
    required this.onFastForwardToKeyMoment,
  });

  @override
  Widget build(BuildContext context) {
    final double totalKm = stage.totalDistanceKm;
    final double remainingKm = (totalKm - currentLeadKm).clamp(0.0, totalKm);
    final double gradient = currentSegment?.gradientPercent ?? 0.0;
    final double elevation = currentSegment?.endElevationM ?? 100.0;
    final double windSpeed = stage.windSpeedKmh;

    final int hours = elapsedSeconds ~/ 3600;
    final int minutes = (elapsedSeconds % 3600) ~/ 60;
    final int seconds = (elapsedSeconds % 60).toInt();
    final String timeStr = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.92),
        border: const Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // 1. Nazwa wyścigu i numer etapu
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stage.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.primaryAccent, width: 0.8),
                      ),
                      child: Text(
                        'ETAP ${stage.stageNumber}',
                        style: const TextStyle(
                          color: AppColors.goldAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeStr,
                      style: AppTheme.statNumberStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Kilometraż (Ukończono / Do Mety)
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${currentLeadKm.toStringAsFixed(1)} km',
                      style: AppTheme.statNumberStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      ' / ${totalKm.toStringAsFixed(1)} km',
                      style: AppTheme.statNumberStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Do mety: ${remainingKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    color: AppColors.goldAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // 3. Profil wysokościowy (Wysokość i nachylenie terenu)
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Nachylenie
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: gradient > 3.0
                        ? AppColors.powerZone6.withValues(alpha: 0.2)
                        : (gradient < -2.0
                            ? AppColors.powerZone3.withValues(alpha: 0.2)
                            : AppColors.surfaceLight),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: gradient > 3.0
                          ? AppColors.powerZone6
                          : (gradient < -2.0 ? AppColors.powerZone3 : AppTheme.borderColor),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        gradient > 0
                            ? Icons.trending_up
                            : (gradient < 0 ? Icons.trending_down : Icons.trending_flat),
                        size: 14,
                        color: gradient > 3.0
                            ? AppColors.powerZone6
                            : (gradient < -2.0 ? AppColors.powerZone3 : AppColors.textPrimary),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${gradient >= 0 ? "+" : ""}${gradient.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: gradient > 3.0
                              ? AppColors.powerZone6
                              : (gradient < -2.0 ? AppColors.powerZone3 : AppColors.textPrimary),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Wysokość n.p.m.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${elevation.round()} m',
                      style: AppTheme.statNumberStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      'n.p.m.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                // Wiatr
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.air, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 2),
                    Text(
                      '${windSpeed.round()} km/h',
                      style: AppTheme.statNumberStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 4. Przyciski sterowania symulacją (Pause, 1x, 2x, 4x, 8x, Instant)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onTogglePause,
                icon: Icon(
                  isPaused ? Icons.play_arrow : Icons.pause,
                  color: isPaused ? AppColors.powerZone3 : AppColors.textPrimary,
                  size: 22,
                ),
                tooltip: isPaused ? 'Wznów' : 'Pauza',
              ),
              const SizedBox(width: 4),
              _buildSpeedButton(SimulationTimeSpeed.x1),
              _buildSpeedButton(SimulationTimeSpeed.x2),
              _buildSpeedButton(SimulationTimeSpeed.x4),
              _buildSpeedButton(SimulationTimeSpeed.x8),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                onPressed: onFastForwardToKeyMoment,
                icon: const Icon(Icons.fast_forward, size: 15, color: Colors.white),
                label: const Text('Do akcji'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(80, 32),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedButton(SimulationTimeSpeed speed) {
    final bool isSelected = currentSpeed == speed && !isPaused;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () => onSpeedSelected(speed),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryAccent : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppColors.goldAccent : AppTheme.borderColor,
              width: 1,
            ),
          ),
          child: Text(
            speed.label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

