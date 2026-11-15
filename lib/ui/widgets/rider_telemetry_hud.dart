import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/peloton/rider_race_state.dart';
import '../../models/rider/rider.dart';
import 'rider_avatar_painter.dart';

/// Pływająca karta telemetryczna wybranego kolarza na ekranie wyścigu 3D (HUD).
class RiderTelemetryHud extends StatelessWidget {
  final RiderRaceState riderState;
  final Rider? rider;
  final Function(TacticalOrder) onOrderSelected;

  const RiderTelemetryHud({
    super.key,
    required this.riderState,
    this.rider,
    required this.onOrderSelected,
  });

  @override
  Widget build(BuildContext context) {
    final double weightKg = rider?.physiology.weightKg ?? 70.0;
    final double currentWatts = riderState.currentPowerWatts;
    final double wKg = weightKg > 0 ? (currentWatts / weightKg) : 0.0;
    final int hrZone = riderState.heartRateZone.clamp(1, 7);
    final Color zoneColor = AppColors.getPowerZoneColor(hrZone);

    // Procent pozostałej baterii W' (0.0 - 1.0)
    final double wPrimeCapacity = rider?.physiology.wPrimeJoules.toDouble() ?? 20000.0;
    final double wPrimePercent = wPrimeCapacity > 0
        ? (riderState.wPrimeBalanceJoules / wPrimeCapacity).clamp(0.0, 1.0)
        : 1.0;

    // Procent pozostałego glikogenu (0.0 - 1.0)
    final double glycogenCapacity = rider?.physiology.glycogenCapacityGrams ?? 500.0;
    final double glycogenPercent = glycogenCapacity > 0
        ? (riderState.glycogenRemainingGrams / glycogenCapacity).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Nagłówek kolarza (Awatar 3D, Imię, nazwisko, narodowość i prędkość)
          Row(
            children: [
              if (rider != null) ...[
                RiderAvatarWidget.fromRider(
                  rider: rider!,
                  size: 40,
                  showBorder: true,
                  borderColor: zoneColor,
                ),
                const SizedBox(width: 10),
              ] else ...[
                Container(
                  width: 10,
                  height: 38,
                  decoration: BoxDecoration(
                    color: zoneColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rider != null ? '${rider!.firstName} ${rider!.lastName}' : riderState.riderId,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          rider?.nationalityIso.toUpperCase() ?? 'UCI',
                          style: const TextStyle(
                            color: AppColors.goldAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${riderState.currentSpeedKmh.toStringAsFixed(1)} km/h',
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
              // Wskaźnik draftingu / tunelu aerodynamicznego
              if (riderState.draftingSavingsPercent > 0.05)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.powerZone2.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.powerZone2, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.air, size: 13, color: AppColors.powerZone2),
                      const SizedBox(width: 4),
                      Text(
                        '-${(riderState.draftingSavingsPercent * 100).round()}%',
                        style: const TextStyle(
                          color: AppColors.powerZone2,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.borderColor),
          const SizedBox(height: 12),

          // 2. Kluczowe metryki (Moc W, W/kg, Tętno HR, Kadencja)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Moc
              _buildMetricItem(
                label: 'MOC',
                value: '${currentWatts.round()} W',
                subValue: '${wKg.toStringAsFixed(1)} W/kg',
                valueColor: AppColors.textPrimary,
              ),
              // Tętno
              _buildMetricItem(
                label: 'TĘTNO',
                value: '${riderState.heartRateBpm.round()} bpm',
                subValue: 'Strefa Z$hrZone',
                valueColor: zoneColor,
              ),
              // Kadencja
              _buildMetricItem(
                label: 'KADENCJA',
                value: '${riderState.cadenceRpm.round()} rpm',
                subValue: 'Obr./min',
                valueColor: AppColors.textPrimary,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 3. Paski stanu baterii W' i glikogenu
          // Pasek W' (Rezerwa beztlenowa)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bateria W\' (Beztlenowa)',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${(wPrimePercent * 100).round()}%',
                    style: TextStyle(
                      color: wPrimePercent < 0.25 ? AppColors.powerZone6 : AppColors.goldAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: wPrimePercent,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    wPrimePercent < 0.25 ? AppColors.powerZone6 : AppColors.goldAccent,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Pasek Glikogenu
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Glikogen (Paliwo)',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${riderState.glycogenRemainingGrams.round()} g',
                    style: TextStyle(
                      color: glycogenPercent < 0.15 ? AppColors.powerZone6 : AppColors.powerZone3,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: glycogenPercent,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    glycogenPercent < 0.15 ? AppColors.powerZone6 : AppColors.powerZone3,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 4. Panel rozkazów taktycznych
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showTacticalOrdersMenu(context),
                  icon: const Icon(Icons.sports, size: 16, color: AppColors.goldAccent),
                  label: Text(
                    _getOrderLabel(riderState.activeTacticalOrder),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    side: const BorderSide(color: AppColors.primaryAccent, width: 1),
                    backgroundColor: AppColors.primaryAccent.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required String subValue,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTheme.statNumberStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
        Text(
          subValue,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getOrderLabel(TacticalOrder order) {
    return 'Rozkaz: ${order.label}';
  }

  void _showTacticalOrdersMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wydaj rozkaz taktyczny (DS Radio)',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.flash_on, color: AppColors.powerZone6),
                  title: const Text('Atakuj! (Maksymalna moc beztlenowa)'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onOrderSelected(TacticalOrder.attack);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.speed, color: AppColors.goldAccent),
                  title: const Text('Mocne tempo na czele grupy'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onOrderSelected(TacticalOrder.pullGroup);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shield, color: AppColors.powerZone2),
                  title: const Text('Osłaniaj lidera w peletonie'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onOrderSelected(TacticalOrder.protectLeader);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.battery_charging_full, color: AppColors.powerZone3),
                  title: const Text('Schowaj się za kołem i oszczędzaj siły'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onOrderSelected(TacticalOrder.saveEnergy);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.local_drink, color: Colors.amber),
                  title: const Text('Cofnij się do samochodu po bidony'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onOrderSelected(TacticalOrder.fetchBidonsFromCar);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

