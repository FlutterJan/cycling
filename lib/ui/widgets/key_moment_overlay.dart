import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/simulation/key_moments_detector.dart';

/// Modalne powiadomienie o kluczowym momencie wyścigu (Key Moment Alert)
/// zatrzymujące szybką symulację i wzywające gracza do bezpośredniego dowodzenia w 3D.
class KeyMomentOverlay extends StatelessWidget {
  final KeyMomentTrigger trigger;
  final VoidCallback onDismiss;
  final VoidCallback onTakeControl;

  const KeyMomentOverlay({
    super.key,
    required this.trigger,
    required this.onDismiss,
    required this.onTakeControl,
  });

  @override
  Widget build(BuildContext context) {
    final Color alertColor = _getAlertColor(trigger.type);
    final IconData alertIcon = _getAlertIcon(trigger.type);

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 440,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: alertColor, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: alertColor.withValues(alpha: 0.35),
                blurRadius: 28,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Ikona zdarzenia i etykieta typu
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: alertColor.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: alertColor, width: 1.5),
                ),
                child: Icon(alertIcon, size: 36, color: alertColor),
              ),
              const SizedBox(height: 14),

              Text(
                trigger.type.label.toUpperCase(),
                style: TextStyle(
                  color: alertColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),

              // 2. Tytuł kluczowego momentu
              Text(
                trigger.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),

              // Znacznik kilometra
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Text(
                  'KILOMETR ${trigger.kilometerMark.toStringAsFixed(1)} ETAPU',
                  style: AppTheme.statNumberStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 3. Opis taktyczny
              Text(
                trigger.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // 4. Przyciski akcji
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDismiss,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Ignoruj'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onTakeControl,
                      icon: const Icon(Icons.videocam, size: 18),
                      label: const Text('Przejmij kontrolę 3D'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: alertColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
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

  Color _getAlertColor(KeyMomentType type) {
    switch (type) {
      case KeyMomentType.playerRiderIncident:
        return AppColors.powerZone6; // Czerwony alarm (kraksa/defekt)
      case KeyMomentType.gcLeaderAttack:
        return AppColors.powerZone5; // Pomarańczowy (atak faworyta)
      case KeyMomentType.challengingCobbles:
        return AppColors.goldAccent; // Złoty (bruk Arenberg/Kwaremont)
      case KeyMomentType.severeCrosswindEchelon:
        return AppColors.powerZone2; // Błękitny (ranty na wietrze)
      case KeyMomentType.decisiveClimb:
        return AppColors.powerZone7; // Fioletowy (królewski podjazd)
      case KeyMomentType.breakawayFormation:
      case KeyMomentType.finaleFinal5Km:
        return AppColors.primaryAccent;
    }
  }

  IconData _getAlertIcon(KeyMomentType type) {
    switch (type) {
      case KeyMomentType.playerRiderIncident:
        return Icons.warning_rounded;
      case KeyMomentType.gcLeaderAttack:
        return Icons.bolt;
      case KeyMomentType.challengingCobbles:
        return Icons.grid_view;
      case KeyMomentType.severeCrosswindEchelon:
        return Icons.air;
      case KeyMomentType.decisiveClimb:
        return Icons.terrain;
      case KeyMomentType.breakawayFormation:
        return Icons.directions_bike;
      case KeyMomentType.finaleFinal5Km:
        return Icons.flag;
    }
  }
}

