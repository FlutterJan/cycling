import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/events/race_radio_generator.dart';

/// Pasek powiadomień radia wyścigowego (Race Radio / DS Comms) wyświetlany na dole ekranu 3D.
class RaceRadioBanner extends StatelessWidget {
  final List<RaceRadioMessage> radioMessages;
  final VoidCallback? onTapViewAll;

  const RaceRadioBanner({
    super.key,
    required this.radioMessages,
    this.onTapViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (radioMessages.isEmpty) return const SizedBox.shrink();

    // Wyświetlamy najświeższy komunikat
    final latest = radioMessages.last;
    final Color priorityColor = _getPriorityColor(latest.priority);

    return Container(
      constraints: const BoxConstraints(maxWidth: 620),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: priorityColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: priorityColor.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ikona Radia z pulsującym kolorem priorytetu
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.radio,
              size: 16,
              color: priorityColor,
            ),
          ),
          const SizedBox(width: 10),

          // Znacznik kilometra
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.borderColor, width: 0.8),
            ),
            child: Text(
              'km ${latest.kilometerMark.toStringAsFixed(1)}',
              style: AppTheme.statNumberStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.goldAccent,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Nadawca i treść komunikatu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  latest.senderName.toUpperCase(),
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  latest.message,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          if (onTapViewAll != null)
            IconButton(
              onPressed: onTapViewAll,
              icon: const Icon(Icons.history, size: 18, color: AppColors.textSecondary),
              tooltip: 'Historia radia wyścigu',
            ),
        ],
      ),
    );
  }

  Color _getPriorityColor(RadioPriority priority) {
    switch (priority) {
      case RadioPriority.urgent:
        return AppColors.powerZone6; // Czerwony
      case RadioPriority.warning:
        return AppColors.powerZone5; // Pomarańczowy
      case RadioPriority.tactical:
        return AppColors.powerZone2; // Niebieski
      case RadioPriority.info:
        return AppColors.goldAccent; // Złoty
    }
  }
}

